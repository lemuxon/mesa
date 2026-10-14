package com.mesajmerkezi.mesaj_merkezi

import android.annotation.SuppressLint
import android.app.Activity
import android.app.DownloadManager
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.MutableContextWrapper
import android.graphics.Bitmap
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import android.view.ViewGroup
import android.webkit.CookieManager
import android.webkit.GeolocationPermissions
import android.webkit.JsPromptResult
import android.webkit.JsResult
import android.webkit.PermissionRequest
import android.webkit.RenderProcessGoneDetail
import android.webkit.URLUtil
import android.webkit.ValueCallback
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.Toast
import androidx.annotation.MainThread
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.webkit.ProfileStore
import androidx.webkit.WebViewCompat
import androidx.webkit.WebViewFeature
import org.json.JSONException
import org.json.JSONObject
import java.lang.ref.WeakReference
import java.util.concurrent.ConcurrentHashMap

/** Açık servis ekranının WebHost'tan beklediği geri çağrılar. */
interface WebHostUi {
    fun onProgress(id: String, progress: Int)

    /** Servis listesi, okunmamış sayıları ya da görünümler değişti. */
    fun onServicesChanged()

    fun showFileChooser(
        callback: ValueCallback<Array<Uri>>,
        params: WebChromeClient.FileChooserParams,
    ): Boolean
}

/**
 * Web servislerinin gömülü tarayıcıları (Ferdium'daki sekmeler gibi).
 *
 * Görünümler uygulama bağlamıyla oluşturulur ve ekran kapansa da yaşar;
 * ConnectionService ön planda kaldıkça siteler arka planda bağlı kalır ve
 * yeni mesajda bildirim gönderir. Görünümler yalnızca ana iş parçacığında
 * kullanılır. Her servisin çerezleri ayrı bir profilde tutulur (aynı
 * servisten iki hesap da açılabilir).
 */
object WebHost {

    private const val TAG = "MesajMerkezi"
    private const val DEDUPE_MS = 30_000L
    private const val CROSS_SOURCE_MS = 3 * 60_000L
    private const val TITLE_ALERT_DELAY_MS = 6_000L
    private const val LOAD_GRACE_MS = 45_000L
    private const val CRASH_WINDOW_MS = 10 * 60_000L
    private const val UNREAD_NOTIFICATION_ID = 8
    private const val ALERT_PREFS = "web_alerts"

    private val main = Handler(Looper.getMainLooper())
    private lateinit var appContext: Context

    private val views = HashMap<String, WebView>()
    private val unread = ConcurrentHashMap<String, Int>()
    private val lastSiteNotification = ConcurrentHashMap<String, Long>()

    /** Görünümün oluşturulduğu an; sayfa yüklenirken başlık sayısız görünür. */
    private val createdAt = ConcurrentHashMap<String, Long>()
    private val recent = ConcurrentHashMap<String, Long>()
    private val crashes = ArrayDeque<Long>()

    /** Sohbet anahtarı → sitedeki son bildirimin kimliği (dokununca sitede o sohbet açılsın). */
    private val clickIds = ConcurrentHashMap<String, String>()

    /** Profili silinmekte olan servisler; silme bitene kadar görünümü açılmaz. */
    private val deleting = HashSet<String>()

    /** Oluşturucu süreç arka arkaya çöktü; kullanıcı bir servisi açana kadar arka planda yüklenmez. */
    private var backgroundPaused = false

    /** Kullanıcının şu an ekranda baktığı servis. */
    @Volatile
    var visibleService: String? = null
        private set

    private var ui: WeakReference<WebHostUi>? = null

    /** Flutter tarafına: liste, okunmamış sayısı ya da simge değişti. */
    @Volatile
    var onChanged: (() -> Unit)? = null

    @Suppress("DEPRECATION")
    private fun init(context: Context) {
        if (::appContext.isInitialized) return
        appContext = context.applicationContext
        // Tarayıcı site simgelerini yalnızca bu (eski) veritabanı açıldıysa indirir.
        main.post {
            try {
                android.webkit.WebIconDatabase.getInstance()
                    .open(appContext.getDir("web_icon_db", Context.MODE_PRIVATE).absolutePath)
            } catch (e: RuntimeException) {
                Log.i(TAG, "Site simgesi veritabanı açılamadı")
            }
        }
    }

    fun profilesSupported() = WebViewFeature.isFeatureSupported(WebViewFeature.MULTI_PROFILE)

    private fun profileName(id: String) = "servis_$id"

    // ---- Görünümlerin yaşam döngüsü ----

    /**
     * Arka planda açık kalması gereken servisleri yükler, listeden çıkanları
     * ve artık arka planda tutulmayanları (ekranda değilse) kapatır.
     */
    @MainThread
    fun sync(context: Context) {
        init(context)
        val services = WebServices.all(appContext)
        val wanted = services.filter { it.background && !backgroundPaused }.map { it.id }.toMutableSet()
        visibleService?.let { wanted += it }
        for (id in views.keys.toList()) if (id !in wanted) destroy(id)
        for (service in services) {
            if (service.id in wanted && service.id !in views) create(service)
        }
    }

    @MainThread
    fun attach(activity: Activity, host: WebHostUi, container: ViewGroup, id: String): WebView? {
        init(activity)
        val service = WebServices.get(appContext, id) ?: return null
        backgroundPaused = false
        val view = views[id] ?: create(service) ?: return null
        val parent = view.parent as? ViewGroup
        if (parent !== container) {
            parent?.removeView(view)
            container.addView(view, ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)
        }
        (view.context as? MutableContextWrapper)?.baseContext = activity
        ui = WeakReference(host)
        setVisible(id)
        return view
    }

    /**
     * Ekran önde ya da arkada: arkadayken site bildirimleri gösterilir.
     * Bakılmayan sayfalar duraklatılır (animasyon, medya; bağlantı ve betik
     * sürer, bildirimler gelmeye devam eder). Hepsi aynı tarayıcı sürecini
     * paylaştığı için bakılan sayfa böylece daha akıcı çalışır; bakılan
     * sayfada ekran dışı içerik de önceden çizilir (kaydırma takılmasın).
     */
    @MainThread
    fun setVisible(id: String?) {
        visibleService = id
        for ((viewId, view) in views) {
            val visible = viewId == id
            if (visible) view.onResume() else view.onPause()
            view.settings.offscreenPreRaster = visible
        }
        if (id != null) {
            cancelUnreadNotification(id)
            // Bakılan sayıya yeniden uyarı verilmesin.
            setAlerted(id, unread[id] ?: 0)
        }
    }

    @MainThread
    fun detach(id: String) {
        val view = views[id] ?: return
        (view.parent as? ViewGroup)?.removeView(view)
        (view.context as? MutableContextWrapper)?.baseContext = appContext
        if (visibleService == id) visibleService = null
        flushCookies(id)
    }

    /** Servis ekranı kapandı: arka planda tutulmayan görünümler kapanır. */
    @MainThread
    fun release(host: WebHostUi) {
        if (ui?.get() === host) ui = null
        if (::appContext.isInitialized) sync(appContext)
    }

    fun view(id: String): WebView? = views[id]

    /** Web servislerinin önbelleği (oturumlar, çerezler kalır). Ana iş parçacığında. */
    @MainThread
    fun clearCaches() {
        views.values.forEach { it.clearCache(true) }
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun create(service: WebService): WebView? {
        if (service.id in deleting) return null
        val view = try {
            WebView(MutableContextWrapper(appContext))
        } catch (e: RuntimeException) {
            // Sistem tarayıcı bileşeni güncelleniyor ya da devre dışı.
            Log.w(TAG, "Web görünümü oluşturulamadı", e)
            return null
        }
        if (profilesSupported()) {
            ProfileStore.getInstance().getOrCreateProfile(profileName(service.id))
            WebViewCompat.setProfile(view, profileName(service.id))
        }
        configure(view, service)
        views[service.id] = view
        createdAt[service.id] = SystemClock.elapsedRealtime()
        view.loadUrl(service.url)
        if (visibleService != service.id) view.onPause()
        Log.i(TAG, "Web servisi açıldı: ${service.catalogId ?: "site"}")
        changed()
        return view
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun configure(view: WebView, service: WebService) {
        val id = service.id
        val defaultAgent = WebSettings.getDefaultUserAgent(appContext)
        with(view.settings) {
            javaScriptEnabled = true
            domStorageEnabled = true
            allowFileAccess = false
            allowContentAccess = false
            // Discord'un yükleme animasyonu bir video; dokunuş şartı onu oynat
            // düğmeli boş kutuya çeviriyordu (2026-10-11). Video ağır sitelerde
            // (otomatik oynatma kapalı) hem bu ayar hem sayfa betiği engeller.
            mediaPlaybackRequiresUserGesture = !service.autoplay
            javaScriptCanOpenWindowsAutomatically = false
            setSupportMultipleWindows(false)
            // Yakınlaştırma yalnızca ekrana sığdırılan masaüstü sayfasında; telefon
            // sitelerinde dokunma ve kaydırma gecikmesiz kalır.
            setSupportZoom(service.wide)
            builtInZoomControls = service.wide
            displayZoomControls = false
            useWideViewPort = service.wide
            loadWithOverviewMode = service.wide
            textZoom = service.zoom
            userAgentString = if (service.desktop) WebAgents.desktop(defaultAgent) else WebAgents.mobile(defaultAgent)
        }
        CookieManager.getInstance().setAcceptThirdPartyCookies(view, true)
        // Görünüm ekranda değilken de sitenin bağlantısı kopmasın.
        if (Build.VERSION.SDK_INT >= 26) view.setRendererPriorityPolicy(WebView.RENDERER_PRIORITY_IMPORTANT, false)

        val rules = WebCatalog.originRules(service.hosts)
        try {
            if (WebViewFeature.isFeatureSupported(WebViewFeature.WEB_MESSAGE_LISTENER)) {
                WebViewCompat.addWebMessageListener(view, WebScripts.BRIDGE, rules) { _, message, _, isMainFrame, _ ->
                    if (isMainFrame) onBridgeMessage(id, message.data)
                }
            }
            if (WebViewFeature.isFeatureSupported(WebViewFeature.DOCUMENT_START_SCRIPT)) {
                val script = buildString {
                    append(WebScripts.notificationShim)
                    // Simgesi hazır serviste sayfa her açılışta simge aramasın.
                    if (!WebIcons.hasGoodIcon(appContext, id)) append('\n').append(WebScripts.iconFinder)
                    if (!service.autoplay) append('\n').append(WebScripts.noAutoplay)
                    if (service.desktop) append('\n').append(WebScripts.desktopPlatform)
                    if (service.wide) append('\n').append(WebScripts.wideViewport)
                }
                WebViewCompat.addDocumentStartJavaScript(view, script, rules)
            }
        } catch (e: IllegalArgumentException) {
            // Kullanıcının girdiği adres köken kuralına uymuyor: site açılır, bildirim gelmez.
            Log.w(TAG, "Web köprüsü kurulamadı: ${service.catalogId ?: "site"}", e)
        }
        view.webViewClient = Client(id)
        view.webChromeClient = Chrome(id)
        view.setDownloadListener { url, userAgent, contentDisposition, mimeType, _ ->
            download(view.context, id, url, userAgent, contentDisposition, mimeType)
        }
    }

    @MainThread
    private fun destroy(id: String) {
        val view = views.remove(id) ?: return
        flushCookies(id)
        (view.parent as? ViewGroup)?.removeView(view)
        view.stopLoading()
        view.destroy()
        unread.remove(id)
        if (visibleService == id) visibleService = null
        changed()
    }

    /** Servisin oturumunu kapatır (çerezleri ve site verisi silinir). Desteklenmiyorsa false. */
    @MainThread
    fun logout(context: Context, id: String): Boolean {
        init(context)
        if (!profilesSupported()) return false
        destroy(id)
        // Profil silinemiyor: sitenin arka plan bileşeni (service worker) onu
        // kullanımda tutuyor (2026-10-11 cihazda). Çerezler ve site verisi silinir.
        clearProfileData(id)
        cancelUnreadNotification(id)
        setAlerted(id, 0)
        main.postDelayed({
            sync(appContext)
            ui?.get()?.onServicesChanged()
        }, 300)
        return true
    }

    private fun clearProfileData(id: String) {
        try {
            val profile = ProfileStore.getInstance().getProfile(profileName(id)) ?: return
            profile.cookieManager.removeAllCookies(null)
            profile.cookieManager.flush()
            profile.webStorage.deleteAllData()
        } catch (e: RuntimeException) {
            Log.w(TAG, "Web oturumu temizlenemedi", e)
        }
    }

    /** Servisi listeden çıkarır; oturumu ve sitenin verileri de silinir. */
    @MainThread
    fun remove(context: Context, id: String) {
        init(context)
        WebServices.remove(appContext, id)
        destroy(id)
        if (profilesSupported()) {
            clearProfileData(id)
            deleting += id
            deleteProfile(id, retries = 3) { deleting -= id }
        }
        cancelUnreadNotification(id)
        setAlerted(id, 0)
        ConnectionService.refresh(appContext)
        changed()
    }

    // Görünüm yeni kapatıldıysa profil bir süre daha kullanımda sayılabiliyor.
    private fun deleteProfile(id: String, retries: Int, then: () -> Unit) {
        main.postDelayed({
            try {
                ProfileStore.getInstance().deleteProfile(profileName(id))
                then()
            } catch (e: IllegalStateException) {
                // Veriler zaten silindi; boş profil bir sonraki açılışta silinir.
                if (retries > 0) deleteProfile(id, retries - 1, then) else then()
            }
        }, 500)
    }

    /** Ayar değişti (masaüstü görünüm, yazı boyutu…): görünüm yeniden kurulur. */
    @MainThread
    fun reload(context: Context, id: String) {
        init(context)
        val view = views[id] ?: return sync(appContext)
        val parent = view.parent as? ViewGroup
        val activity = (view.context as? MutableContextWrapper)?.baseContext as? Activity
        destroy(id)
        val service = WebServices.get(appContext, id) ?: return
        val fresh = create(service) ?: return
        if (parent != null && activity != null) {
            (fresh.context as MutableContextWrapper).baseContext = activity
            parent.addView(fresh, ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)
            visibleService = id
        }
        ui?.get()?.onServicesChanged()
    }

    private fun flushCookies(id: String) {
        try {
            cookies(id).flush()
        } catch (e: RuntimeException) {
            Log.w(TAG, "Çerezler kaydedilemedi", e)
        }
    }

    private fun cookies(id: String): CookieManager =
        if (profilesSupported()) {
            ProfileStore.getInstance().getProfile(profileName(id))?.cookieManager ?: CookieManager.getInstance()
        } else {
            CookieManager.getInstance()
        }

    // Tüm görünümler aynı oluşturucu süreci paylaşır; süreç kapanınca hepsi gider.
    private fun onRendererGone() {
        if (views.isEmpty()) return
        Log.w(TAG, "Web oluşturucu süreci kapandı; servisler yeniden açılacak")
        for (id in views.keys.toList()) destroy(id)
        val now = SystemClock.elapsedRealtime()
        crashes.addLast(now)
        while (crashes.isNotEmpty() && now - crashes.first() > CRASH_WINDOW_MS) crashes.removeFirst()
        if (crashes.size >= 3) {
            Log.w(TAG, "Web servisleri arka arkaya kapandı; arka planda yükleme durduruldu")
            backgroundPaused = true
        }
        main.postDelayed({
            sync(appContext)
            ui?.get()?.onServicesChanged()
        }, 3_000L * crashes.size)
    }

    // ---- Okunmamış sayısı ve bildirimler ----

    fun unreadOf(id: String) = unread[id] ?: 0

    fun isLoaded(id: String) = views.containsKey(id)

    fun clickIdFor(key: String): String? = clickIds[key]

    /** Flutter'a gönderilen servis listesi. Ana iş parçacığında çağrılmalı. */
    fun describe(context: Context): List<Map<String, Any?>> {
        init(context)
        return WebServices.all(appContext).map { s ->
            mapOf(
                "id" to s.id,
                "catalogId" to s.catalogId,
                "name" to s.name,
                "url" to s.url,
                "color" to s.color,
                "desktop" to s.desktop,
                "wide" to s.wide,
                "background" to s.background,
                "notify" to s.notify,
                "zoom" to s.zoom,
                "autoplay" to s.autoplay,
                "unread" to (unread[s.id] ?: 0),
                "loaded" to views.containsKey(s.id),
                "iconVersion" to WebIcons.version(appContext, s.id),
            )
        }
    }

    private fun onTitle(id: String, title: String?) {
        val count = WebTitles.unread(title)
        if (unread.put(id, count) != count) changed()
        val service = WebServices.get(appContext, id) ?: return
        if (count == 0) {
            // Sayfa yüklenirken başlık bir an "Discord" olur; o an sıfırlanırsa
            // yükleme bitince aynı okunmamışlar için yeniden bildirim çalar
            // (2026-10-11 cihazda, uygulama güncellenince).
            val loading = SystemClock.elapsedRealtime() - (createdAt[id] ?: 0L) < LOAD_GRACE_MS
            if (!loading) {
                setAlerted(id, 0)
                cancelUnreadNotification(id)
            }
            return
        }
        if (!service.notify || visibleService == id || !WebTitles.shouldAlert(alerted(id), count)) return
        val changedAt = SystemClock.elapsedRealtime()
        main.postDelayed({
            val now = unread[id] ?: 0
            if (now == 0 || visibleService == id) return@postDelayed
            // Site bu mesaj için kendi bildirimini gönderdiyse sayaç bildirimi gereksiz.
            val siteNotified = (lastSiteNotification[id] ?: 0L) >= changedAt - 2_000
            if (!siteNotified && WebTitles.shouldAlert(alerted(id), now)) showUnreadNotification(service, now)
            setAlerted(id, now)
        }, TITLE_ALERT_DELAY_MS)
    }

    private fun onBridgeMessage(id: String, data: String?) {
        val json = try {
            JSONObject(data ?: return)
        } catch (e: JSONException) {
            return
        }
        when (json.optString("type")) {
            "icon" -> {
                val data = json.optString("data")
                if (data.isNotEmpty()) {
                    WebIcons.saveHdData(appContext, id, data) { changed() }
                } else {
                    WebIcons.downloadHd(appContext, id, json.optString("url")) { changed() }
                }
            }
            "iconTrace" -> Log.i(
                TAG,
                "Simge adımı başarısız: ${tag(id)} ${json.optString("step")} ${json.optString("reason").take(80)}",
            )
            // İçeriksiz tanılama: betik sayfada çalışıyor mu, site hangi izni görüyor.
            "ready" -> Log.i(TAG, "Web köprüsü hazır: ${tag(id)} (izin=${json.optString("permission")})")
            "notification" -> onSiteNotification(
                id,
                json.optString("id"),
                json.optString("title"),
                json.optString("body"),
            )
        }
    }

    /** Site yeni mesaj için bildirim gösterdi: gelen kutusuna yazılır, bildirimi gösterilir. */
    private fun onSiteNotification(id: String, clickId: String, rawTitle: String, rawBody: String) {
        lastSiteNotification[id] = SystemClock.elapsedRealtime()
        Log.i(TAG, "Web sitesi bildirim gönderdi: ${tag(id)} (metin=${rawBody.isNotBlank()})")
        val service = WebServices.get(appContext, id) ?: return
        if (!service.notify || !AppSettings.isCaptured(appContext, service.packageName)) return
        val title = Names.title(rawTitle)?.takeIf { it.isNotBlank() } ?: service.name
        val body = rawBody.trim()
        val now = System.currentTimeMillis()
        recent.entries.removeIf { now - it.value > DEDUPE_MS }
        if (recent.putIfAbsent("$id\u0000$title\u0000$body", now) != null) return
        // Sohbetler'e yalnızca mesajlar girer; arkadaşlık isteği, beğeni gibi
        // site bildirimleri yalnızca bildirim olarak gösterilir.
        val names = listOfNotNull(service.name, service.catalog?.name)
        if (!MessageFilter.isWebMessage(title, body, names)) {
            if (visibleService != id) {
                showPlainNotification(
                    service,
                    title,
                    body.ifEmpty { Lang.str(appContext, R.string.web_new_notification) },
                    0,
                    clickId.ifEmpty { null },
                )
            }
            return
        }

        val key = WebServices.keyFor(id, title)
        if (clickId.isNotEmpty()) clickIds[key] = clickId
        val conversation = CapturedConversation(
            key = key,
            packageName = service.packageName,
            title = title,
            isGroup = false,
            messages = listOf(
                CapturedMessage(sender = null, text = body, time = now, outgoing = false, fromFallback = false)
            ),
            replyAction = null,
        )
        val visible = visibleService == id
        Hub.io.execute {
            val store = Hub.store(appContext)
            // Aynı mesaj telefondaki uygulamanın bildiriminden de geldiyse ikinci kez yazılmaz.
            if (store.hasRecentIncoming(body, now - CROSS_SOURCE_MS, key)) return@execute
            val result = store.ingest(conversation)
            if (result.newIncoming.isEmpty()) return@execute
            val fired = try {
                RuleRunner.run(appContext, store, conversation, result.newIncoming)
            } catch (e: RuntimeException) {
                Log.w(TAG, "Kurallar uygulanamadı (web)", e)
                emptySet()
            }
            if (visible) {
                store.markRead(key)
            } else if (RuleAction.MUTE !in fired) {
                UnifiedNotifier.show(appContext, key, alert = true, important = RuleAction.IMPORTANT in fired)
            }
            Log.i(TAG, "Web bildirimi alındı: ${service.catalogId ?: "site"}")
            Hub.notifyChanged(key)
        }
    }

    private fun showUnreadNotification(service: WebService, count: Int) {
        showPlainNotification(
            service,
            service.name,
            if (count > 0) {
                Lang.plural(appContext, R.plurals.web_unread, count)
            } else {
                Lang.str(appContext, R.string.web_new_unread)
            },
            count.coerceAtLeast(0),
            null,
        )
        Log.i(TAG, "Web okunmamış bildirimi: ${service.catalogId ?: "site"}")
    }

    /** Gelen kutusuna girmeyen, servisin sayfasını açan sade bildirim (servis başına bir tane). */
    private fun showPlainNotification(service: WebService, title: String, text: String, number: Int, clickId: String?) {
        if (!UnifiedNotifier.canPost(appContext)) return
        val manager = NotificationManagerCompat.from(appContext)
        UnifiedNotifier.ensureChannels(appContext, manager)
        val notification = NotificationCompat.Builder(appContext, UnifiedNotifier.CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setColor(service.color)
            .setSubText(service.name)
            .setContentTitle(title)
            .setContentText(text)
            .setStyle(NotificationCompat.BigTextStyle().bigText(text))
            .setLargeIcon(WebIcons.bitmap(appContext, service.id))
            .setCategory(NotificationCompat.CATEGORY_SOCIAL)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .apply { if (number > 0) setNumber(number) }
            .setContentIntent(WebServiceActivity.pendingIntent(appContext, service.id, clickId))
            .build()
        @SuppressLint("MissingPermission") // canPost yukarıda kontrol edildi.
        manager.notify(unreadTag(service.id), UNREAD_NOTIFICATION_ID, notification)
    }

    private fun cancelUnreadNotification(id: String) {
        if (!::appContext.isInitialized) return
        NotificationManagerCompat.from(appContext).cancel(unreadTag(id), UNREAD_NOTIFICATION_ID)
    }

    private fun unreadTag(id: String) = "web-unread|$id"

    /** Kayıtlarda servis adı (kullanıcı sitesinin adresi yazılmaz). */
    private fun tag(id: String) = WebServices.get(appContext, id)?.catalogId ?: "site"

    // Uygulama yeniden başlayınca aynı okunmamışlar için tekrar uyarı verilmesin diye kalıcı.
    private fun alerted(id: String) =
        appContext.getSharedPreferences(ALERT_PREFS, Context.MODE_PRIVATE).getInt(id, 0)

    private fun setAlerted(id: String, count: Int) {
        if (!::appContext.isInitialized) return
        appContext.getSharedPreferences(ALERT_PREFS, Context.MODE_PRIVATE).edit().putInt(id, count).apply()
    }

    private fun changed() {
        main.post {
            onChanged?.invoke()
            ui?.get()?.onServicesChanged()
        }
    }

    // ---- Bağlantılar ve indirmeler ----

    private fun isWebScheme(uri: Uri) = uri.scheme?.lowercase().let { it == "https" || it == "http" }

    private fun openExternal(context: Context, uri: Uri) {
        val intent = Intent(Intent.ACTION_VIEW, uri)
            .addCategory(Intent.CATEGORY_BROWSABLE)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            context.startActivity(intent)
        } catch (e: ActivityNotFoundException) {
            Log.i(TAG, "Bağlantıyı açacak uygulama yok: ${uri.scheme}")
        }
    }

    private fun download(
        context: Context,
        id: String,
        url: String,
        userAgent: String,
        contentDisposition: String?,
        mimeType: String?,
    ) {
        val uri = Uri.parse(url)
        // Şifresiz (http) indirme yolda değiştirilebilir; yalnızca https.
        if (uri.scheme?.lowercase() != "https") {
            Toast.makeText(context, Lang.str(context, R.string.web_cannot_download), Toast.LENGTH_SHORT).show()
            return
        }
        // Android 10 öncesinde İndirilenler klasörüne yazmak depolama izni ister.
        if (Build.VERSION.SDK_INT < 29) return openExternal(context, uri)
        val name = URLUtil.guessFileName(url, contentDisposition, mimeType)
        val request = DownloadManager.Request(uri)
            .setMimeType(mimeType)
            .addRequestHeader("User-Agent", userAgent)
            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
            .setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, name)
        cookies(id).getCookie(url)?.let { request.addRequestHeader("Cookie", it) }
        try {
            context.getSystemService(DownloadManager::class.java).enqueue(request)
            Toast.makeText(context, Lang.str(context, R.string.web_downloading, name), Toast.LENGTH_SHORT).show()
        } catch (e: RuntimeException) {
            Toast.makeText(context, Lang.str(context, R.string.web_download_failed), Toast.LENGTH_SHORT).show()
        }
    }

    /**
     * Sayfa yüklendikten sonra simge bağlantısını doğrudan okur. Discord simgeyi
     * resmin kendisini taşıyan data: adresine çeviriyor; sayfa içi zamanlayıcıya
     * güvenmeden alınır (2026-10-11: Discord sayfasında betiğin araması hiç sonuç vermedi).
     */
    private fun probeIcon(view: WebView, id: String) {
        if (WebIcons.hasGoodIcon(appContext, id)) {
            Log.i(TAG, "Simge hazır: ${tag(id)} ${WebIcons.version(appContext, id)}")
            return
        }
        Log.i(TAG, "Simge aranıyor: ${tag(id)}")
        val probe = "(function(){var b=null,bs=-1;document.querySelectorAll('link[rel]').forEach(function(l){" +
            "var r=(l.getAttribute('rel')||'').toLowerCase();if(r.indexOf('icon')<0||!l.href)return;" +
            "var m=/(\\d+)x/.exec(l.getAttribute('sizes')||'');var s=m?parseInt(m[1],10):(r.indexOf('apple')>=0?180:32);" +
            "if(l.href.indexOf('data:image/')===0)s+=1000;if(s>bs){bs=s;b=l.href;}});return b||'';})()"
        view.evaluateJavascript(probe) { raw ->
            val href = try {
                org.json.JSONTokener(raw).nextValue() as? String
            } catch (e: org.json.JSONException) {
                null
            }.orEmpty()
            Log.i(TAG, "Simge bağlantısı: ${tag(id)} ${href.substringBefore(':').take(10)} (${href.length})")
            if (href.startsWith("data:image/")) WebIcons.saveHdData(appContext, id, href) { changed() }
        }
    }

    private class Client(private val id: String) : WebViewClient() {

        override fun onPageFinished(view: WebView, url: String?) {
            // Yalnızca ilk yol parçası (kanal/mesaj kimliği yazılmaz).
            val section = android.net.Uri.parse(url ?: "").pathSegments.firstOrNull() ?: "/"
            Log.i(TAG, "Sayfa yüklendi: ${tag(id)} /$section")
            // Tek sayfalık uygulamalar simgeyi yüklemeden sonra ekler.
            main.postDelayed({ if (views[id] === view) probeIcon(view, id) }, 8_000)
        }

        override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
            val url = request.url
            when (url.scheme?.lowercase()) {
                "http", "https" -> {
                    if (!request.isForMainFrame) return false
                    val service = WebServices.get(view.context, id) ?: return false
                    if (WebCatalog.isAllowedHost(url.host, service.hosts)) return false
                }
                "about", "data", "blob", "javascript" -> return false
                // "Uygulamada aç" bağlantıları: niyetin kendisi çalıştırılmaz (sayfa
                // istediği uygulama bileşenini açabilirdi); yalnızca web adresine düşülür.
                "intent" -> {
                    val fallback = try {
                        Intent.parseUri(url.toString(), Intent.URI_INTENT_SCHEME)
                            .getStringExtra("browser_fallback_url")
                    } catch (e: java.net.URISyntaxException) {
                        null
                    }?.let(Uri::parse)
                    if (fallback != null && isWebScheme(fallback) && visibleService == id) {
                        openExternal(view.context, fallback)
                    }
                    return true
                }
                // Telefondaki dosyalara giden bağlantılar hiç açılmaz.
                "file", "content" -> return true
            }
            // Başka sitelere giden bağlantılar (ve mailto:, tel:) telefonun tarayıcısında açılır.
            if (visibleService == id) openExternal(view.context, url)
            return true
        }

        override fun onRenderProcessGone(view: WebView, detail: RenderProcessGoneDetail): Boolean {
            main.post { onRendererGone() }
            return true
        }
    }

    private class Chrome(private val id: String) : WebChromeClient() {

        // Kapak resmi olmayan videoda tarayıcının gri "oynat" kutusu yerine boşluk.
        override fun getDefaultVideoPoster(): Bitmap? = Bitmap.createBitmap(1, 1, Bitmap.Config.ARGB_8888)

        override fun onProgressChanged(view: WebView, newProgress: Int) {
            if (visibleService == id) ui?.get()?.onProgress(id, newProgress)
        }

        override fun onReceivedTitle(view: WebView, title: String?) = onTitle(id, title)

        override fun onReceivedIcon(view: WebView, icon: Bitmap?) {
            if (icon != null) WebIcons.saveFavicon(appContext, id, icon) { changed() }
        }

        override fun onShowFileChooser(
            webView: WebView,
            filePathCallback: ValueCallback<Array<Uri>>,
            fileChooserParams: FileChooserParams,
        ): Boolean {
            val host = ui?.get()
            if (visibleService == id && host != null && host.showFileChooser(filePathCallback, fileChooserParams)) {
                return true
            }
            filePathCallback.onReceiveValue(null)
            return true
        }

        // Kamera, mikrofon ve konum istekleri reddedilir (uygulamada bu izinler yok).
        override fun onPermissionRequest(request: PermissionRequest) = request.deny()

        override fun onGeolocationPermissionsShowPrompt(
            origin: String?,
            callback: GeolocationPermissions.Callback,
        ) = callback.invoke(origin, false, false)

        // Arka plandayken pencere açılamaz (etkinlik yok); site beklemesin diye iptal edilir.
        override fun onJsAlert(view: WebView, url: String?, message: String?, result: JsResult) =
            dialogOnlyInForeground(result)

        override fun onJsConfirm(view: WebView, url: String?, message: String?, result: JsResult) =
            dialogOnlyInForeground(result)

        override fun onJsPrompt(
            view: WebView,
            url: String?,
            message: String?,
            defaultValue: String?,
            result: JsPromptResult,
        ) = dialogOnlyInForeground(result)

        override fun onJsBeforeUnload(view: WebView, url: String?, message: String?, result: JsResult) =
            dialogOnlyInForeground(result)

        private fun dialogOnlyInForeground(result: JsResult): Boolean {
            if (visibleService == id) return false
            result.cancel()
            return true
        }
    }
}
