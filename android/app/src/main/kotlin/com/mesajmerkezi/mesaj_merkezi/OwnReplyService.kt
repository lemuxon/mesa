package com.mesajmerkezi.mesaj_merkezi

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.content.Intent
import android.content.res.ColorStateList
import android.content.res.Configuration
import android.graphics.Path
import android.graphics.PixelFormat
import android.graphics.Rect
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.view.accessibility.AccessibilityWindowInfo
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView

/**
 * WhatsApp'ta yazılan yanıtları Mesa'ya ekleyen, Mesa'dan yazılanları da
 * WhatsApp'ta gönderen isteğe bağlı erişilebilirlik servisi ([OwnReplies]).
 * Sistem yalnızca WhatsApp ve WhatsApp Business olaylarını iletir
 * (res/xml/own_replies.xml); kullanıcı Android'in Erişilebilirlik ayarından
 * açar ve kapatır.
 *
 * WhatsApp 2.26 sohbet ekranı (paketindeki düzenden, 2026-11-26): kutu boşken
 * yalnızca mikrofon düğmesi (voice_note_btn, dokunmayı kendisi işler) var;
 * metin yazılınca send_container içinde ayrı bir "send" düğmesi
 * (ImageButton) oluşur ve erişilebilir tıklamayla gönderir. Boş kutu metin
 * yerine ipucunu ("Mesaj") bildirir; gönderim bu yüzden mesajın sohbet
 * listesinde belirmesinden de doğrulanır.
 */
class OwnReplyService : AccessibilityService() {

    private val tracker = ReplyTracker()
    private val main = Handler(Looper.getMainLooper())

    /** En son açık görülen sohbet; aynı sohbet için tekrar okundu yazılmasın. */
    private var openChat: String? = null
    private var windowCheck: Runnable? = null
    private var lastSendCheck = 0L

    /** Gönder'e basılan, sonucu beklenen mesaj. */
    private var sending: OwnReplies.PendingSend? = null

    /** Kutuda Mesa'nın metni görüldüğü an; Gönder düğmesi bu süre içinde belirmeli. */
    private var matchedAt = 0L

    /** WhatsApp'ı gizleyen, Mesa'nın görüntüsünü gösteren örtü. */
    private var overlay: View? = null
    private var overlayParams: WindowManager.LayoutParams? = null
    private val giveUp = Runnable { onTimeout() }

    override fun onServiceConnected() {
        instance = this
        Log.i(TAG, "WhatsApp yanıt servisi bağlandı")
    }

    override fun onUnbind(intent: Intent?): Boolean {
        instance = null
        removeOverlay()
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        instance = null
        main.removeCallbacksAndMessages(null)
        removeOverlay()
        super.onDestroy()
    }

    override fun onInterrupt() = Unit

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        event ?: return
        val packageName = event.packageName?.toString() ?: return
        if (packageName !in OwnReplies.packages) return
        val ids = ChatIds(packageName)
        try {
            when (event.eventType) {
                AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED -> onText(event, ids)
                AccessibilityEvent.TYPE_VIEW_CLICKED -> onClick(event, ids)
                AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> onWindow(ids)
                AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> maybeAutoSend(ids)
            }
        } catch (e: RuntimeException) {
            // WhatsApp'ın ekranı habersiz değişebilir; servis düşmemeli.
            Log.w(TAG, "WhatsApp olayı işlenemedi: ${e.javaClass.simpleName}")
        }
    }

    // ---- WhatsApp'ta yazılan yanıtları yakalama ----

    private fun onText(event: AccessibilityEvent, ids: ChatIds) {
        val node = event.source ?: return
        if (node.viewIdResourceName != ids.entry) return
        val before = event.beforeText?.toString()
        // Boş kutu metin yerine ipucunu ("Mesaj") bildirir; boşalma olaydan anlaşılır.
        val cleared = event.addedCount == 0 && !before.isNullOrEmpty() && event.removedCount >= before.length
        val text = if (cleared || isEmptyEntry(node)) "" else node.text?.toString() ?: event.text.joinToString("")
        val candidate = tracker.onTextChanged(text, before, event.removedCount, event.addedCount)
        if (candidate != null) {
            Log.i(TAG, "WhatsApp: kutu boşaldı, gönderim doğrulanıyor")
            main.postDelayed({ verify(ids, candidate, attempt = 1) }, VERIFY_DELAY_MS)
        } else if (text.isNotBlank()) {
            maybeAutoSend(ids)
        }
    }

    private fun onClick(event: AccessibilityEvent, ids: ChatIds) {
        if (event.source?.viewIdResourceName != ids.send) return
        val text = tracker.onSendClicked() ?: return
        record(ids, text)
    }

    private fun verify(ids: ChatIds, text: String, attempt: Int) {
        val root = appRoot(ids)
        val shown = root != null && listedNearBottom(root, ids, text)
        if (!shown && attempt == 1) {
            main.postDelayed({ verify(ids, text, attempt = 2) }, VERIFY_DELAY_MS)
            return
        }
        Log.i(TAG, "WhatsApp: gönderilen metin listede " + if (shown) "görüldü" else "görülmedi")
        if (tracker.onVerified(text, shown)) record(ids, text, root)
    }

    private fun record(ids: ChatIds, text: String, root: AccessibilityNodeInfo? = appRoot(ids)) {
        val title = chatTitle(root, ids) ?: run {
            Log.i(TAG, "WhatsApp yanıtı: sohbet adı okunamadı")
            return
        }
        val app = applicationContext
        Hub.io.execute { OwnReplies.record(app, ids.packageName, title, text) }
    }

    /** Yeni ekran: sohbet açıldıysa (başlık görünüyorsa) Mesa'da okundu sayılır. */
    private fun onWindow(ids: ChatIds) {
        tracker.reset()
        windowCheck?.let(main::removeCallbacks)
        // Ekran çizilmeden başlık henüz yok; kısa bir süre sonra bakılır.
        val check = Runnable {
            val title = chatTitle(appRoot(ids), ids)
            if (title != openChat) {
                openChat = title
                if (title != null) {
                    val app = applicationContext
                    Hub.io.execute { OwnReplies.opened(app, ids.packageName, title) }
                }
            }
            maybeAutoSend(ids)
        }
        windowCheck = check
        main.postDelayed(check, WINDOW_DELAY_MS)
        // Otomatik gönderim okundu bilgisini beklemez: sohbet çizilir çizilmez denenir.
        if (OwnReplies.pendingSend != null) main.postDelayed({ maybeAutoSend(ids) }, AUTO_WINDOW_DELAY_MS)
    }

    // ---- Mesa'dan yazılan mesajı WhatsApp'ta gönderme ----

    /**
     * Mesa mesajı WhatsApp'a vermek üzere (ana iş parçacığı, WhatsApp
     * açılmadan önce): ekran Mesa'nın görüntüsüyle örtülür.
     */
    internal fun beginAutoSend(shot: ScreenShot.Shot?) {
        val start = Runnable {
            matchedAt = 0L
            showOverlay(shot)
            main.removeCallbacks(giveUp)
            main.postDelayed(giveUp, OwnReplies.AUTO_SEND_WINDOW_MS)
        }
        // Örtü, WhatsApp açılmadan önce ekranda olmalı.
        if (Looper.myLooper() == Looper.getMainLooper()) start.run() else main.post(start)
    }

    private fun maybeAutoSend(ids: ChatIds) {
        if (sending != null) return
        val pending = OwnReplies.pendingSend ?: return
        // İçerik olayları sık gelir; ekran en fazla 80 ms'de bir okunur.
        val tick = SystemClock.uptimeMillis()
        if (tick - lastSendCheck < 80) return
        lastSendCheck = tick
        val root = appRoot(ids) ?: return
        val entry = root.findAccessibilityNodeInfosByViewId(ids.entry).firstOrNull()
        val entryText = entry?.let { if (isEmptyEntry(it)) "" else it.text?.toString() }
        val now = System.currentTimeMillis()
        when (OwnReplies.autoSendStep(pending, ids.packageName, chatTitle(root, ids), entryText, now)) {
            OwnReplies.Step.WAIT -> Unit
            OwnReplies.Step.EXPIRED -> onTimeout()
            OwnReplies.Step.FILL -> {
                // Eski bir taslak ya da paylaşımın eklemediği metin: kutu tam olarak Mesa'nın metni olur.
                setEntryText(entry, pending.text)
                main.postDelayed({ maybeAutoSend(ids) }, 120)
            }
            OwnReplies.Step.PRESS -> {
                // Metin yazılınca WhatsApp "send" düğmesini oluşturur; kısa bir süre beklenir.
                val ready = sendButton(root, ids) != null
                if (matchedAt == 0L) matchedAt = now
                if (!ready && now - matchedAt < SEND_BUTTON_WAIT_MS) {
                    main.postDelayed({ maybeAutoSend(ids) }, 100)
                    return
                }
                OwnReplies.pendingSend = null
                sending = pending
                // Basmadan önce: kutu boşalınca yakalanan metin ikinci kez kaydedilmesin.
                OwnReplies.markSending(pending.key, pending.text)
                tracker.onAutoSend(pending.text)
                // Erişilebilir tıklama düğmenin yerine bakmaz: beklemeden basılır.
                press(ids, pending, attempt = 1)
            }
        }
    }

    /**
     * Üç deneme: "send" düğmesine erişilebilir tıklama, düğmenin yerine
     * dokunma, klavyenin Gönder eylemi. Örtü hiç kalkmaz.
     */
    private fun press(ids: ChatIds, pending: OwnReplies.PendingSend, attempt: Int) {
        // Süre dolup bittiyse geciken denemeler durur.
        if (sending !== pending) return
        val root = appRoot(ids)
        if (root == null || Names.title(chatTitle(root, ids)) != pending.title) {
            finish(pending, sent = false, how = "sohbet ekrandan çıktı")
            return
        }
        val send = sendButton(root, ids)
        val how = when (attempt) {
            1 -> when {
                send != null && send.isClickable && send.performAction(AccessibilityNodeInfo.ACTION_CLICK) -> "tıklama"
                tap(send ?: fallbackButton(root, ids)) -> "dokunma"
                else -> "düğme yok"
            }
            2 -> if (tap(send ?: fallbackButton(root, ids))) "dokunma" else "düğme yok"
            else -> when {
                imeEnter(root, ids) -> "klavye eylemi"
                tap(send ?: fallbackButton(root, ids)) -> "dokunma"
                else -> "düğme yok"
            }
        }
        Log.i(TAG, "Otomatik gönderim: deneme $attempt ($how, gönder düğmesi ${if (send != null) "var" else "yok"})")
        pressedAt = SystemClock.uptimeMillis()
        main.postDelayed({ confirm(ids, pending, attempt) }, CONFIRM_POLL_MS)
    }

    /** Son basış anı; sonuç bundan sonra 100 ms'de bir yoklanır. */
    private var pressedAt = 0L

    private fun confirm(ids: ChatIds, pending: OwnReplies.PendingSend, attempt: Int) {
        if (sending !== pending) return
        // WhatsApp ekranı yoksa gönderildiği doğrulanamaz.
        val root = appRoot(ids) ?: return finish(pending, sent = false, how = "WhatsApp ekranı kayboldu")
        val entry = root.findAccessibilityNodeInfosByViewId(ids.entry).firstOrNull()?.also { it.refresh() }
        val empty = entry != null && isEmptyEntry(entry)
        val stillInBox = entry != null && !empty && OwnReplies.sameMessage(entry.text, pending.text)
        val sent = !stillInBox && (empty || listedNearBottom(root, ids, pending.text))
        val waited = SystemClock.uptimeMillis() - pressedAt
        when {
            sent -> finish(pending, sent = true, how = "deneme $attempt, $waited ms")
            // WhatsApp kutuyu genelde hemen boşaltır; biraz daha yoklanır.
            waited < CONFIRM_MAX_MS -> main.postDelayed({ confirm(ids, pending, attempt) }, CONFIRM_POLL_MS)
            // Dokunma denemesinden önce düzen otursun.
            attempt < 3 -> main.postDelayed({ press(ids, pending, attempt + 1) }, SETTLE_MS)
            else -> {
                Log.w(TAG, "Otomatik gönderim başarısız; ${describeSendArea(root, ids)}")
                // Taslak WhatsApp'ta kalmasın; mesaj Mesa'nın yazma alanına geri konur.
                if (stillInBox) setEntryText(entry, "")
                finish(pending, sent = false, how = "üç deneme")
            }
        }
    }

    private fun onTimeout() {
        val pending = sending ?: OwnReplies.pendingSend
        OwnReplies.pendingSend = null
        if (pending == null) {
            removeOverlay()
            return
        }
        finish(pending, sent = false, how = "süre doldu")
    }

    /** Sonuç kaydedilir, Mesa öne gelir, örtü Mesa çizildikten sonra kalkar. */
    private fun finish(pending: OwnReplies.PendingSend, sent: Boolean, how: String) {
        sending = null
        matchedAt = 0L
        main.removeCallbacks(giveUp)
        OwnReplies.markResult(pending.key, sent)
        if (sent) {
            Log.i(TAG, "Mesa'dan yazılan mesaj WhatsApp'ta gönderildi ($how)")
        } else {
            OwnReplies.clearSending(pending.key)
            Log.w(TAG, "Mesa'dan yazılan mesaj gönderilemedi ($how)")
        }
        if (pending.returnToMesa) {
            // Başlatıcıdaki simgeye dokunmak gibi: Mesa kaldığı yerden öne gelir.
            packageManager.getLaunchIntentForPackage(this.packageName)
                ?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED)
                ?.let(::startActivity)
            // Örtü, Mesa'nın ekranı çizilince kalkar ([onMesaDisplayed]); haber gelmezse bu süre sonunda.
            awaitingMesa = true
            main.postDelayed(liftOverlay, OVERLAY_FALLBACK_MS)
        } else {
            main.postDelayed(liftOverlay, OVERLAY_LINGER_MS)
        }
    }

    private var awaitingMesa = false
    private val liftOverlay = Runnable {
        awaitingMesa = false
        removeOverlay()
    }

    /** Mesa'nın Flutter ekranı yeniden çizildi (MainActivity bildirir): örtü kalkabilir. */
    internal fun onMesaDisplayed() {
        main.post {
            if (!awaitingMesa) return@post
            awaitingMesa = false
            main.removeCallbacks(liftOverlay)
            // Çizilen kare ekrana gelsin diye birkaç kare beklenir.
            main.postDelayed(liftOverlay, 48)
        }
    }

    /** Görünür "send" düğmesi (metin yazılınca oluşur). */
    private fun sendButton(root: AccessibilityNodeInfo, ids: ChatIds): AccessibilityNodeInfo? =
        root.findAccessibilityNodeInfosByViewId(ids.send).firstOrNull { it.isVisibleToUser }

    /** "send" yoksa düğmenin yeri: mikrofon düğmesi ya da kabı. */
    private fun fallbackButton(root: AccessibilityNodeInfo, ids: ChatIds): AccessibilityNodeInfo? =
        ids.fallbackTargets.firstNotNullOfOrNull { id ->
            root.findAccessibilityNodeInfosByViewId(id).firstOrNull { it.isVisibleToUser }
        }

    /** Düğmenin ekrandaki yerine dokunur; o an örtü dokunmayı geçirir. */
    private fun tap(node: AccessibilityNodeInfo?): Boolean {
        node ?: return false
        val bounds = Rect().also(node::getBoundsInScreen)
        if (bounds.isEmpty) return false
        val tap = Path().apply { moveTo(bounds.exactCenterX(), bounds.exactCenterY()) }
        val gesture = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(tap, 0, TAP_MS))
            .build()
        setOverlayTouchable(false)
        val callback = object : GestureResultCallback() {
            override fun onCompleted(gestureDescription: GestureDescription?) {
                setOverlayTouchable(true)
            }

            override fun onCancelled(gestureDescription: GestureDescription?) {
                Log.w(TAG, "Otomatik gönderim: dokunuş iptal edildi")
                setOverlayTouchable(true)
            }
        }
        val dispatched = dispatchGesture(gesture, callback, main)
        if (!dispatched) setOverlayTouchable(true)
        return dispatched
    }

    /** Klavyedeki Gönder eylemi (Android 11+); WhatsApp'ta "Enter ile gönder" açıksa gönderir. */
    private fun imeEnter(root: AccessibilityNodeInfo, ids: ChatIds): Boolean {
        if (Build.VERSION.SDK_INT < 30) return false
        val entry = root.findAccessibilityNodeInfosByViewId(ids.entry).firstOrNull() ?: return false
        entry.performAction(AccessibilityNodeInfo.ACTION_FOCUS)
        return entry.performAction(AccessibilityNodeInfo.AccessibilityAction.ACTION_IME_ENTER.id)
    }

    private fun setEntryText(entry: AccessibilityNodeInfo?, text: String) {
        val args = Bundle().apply {
            putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, text)
        }
        entry?.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args)
    }

    /** Metin, sohbet listesinin en alttaki birkaç mesajından birinde mi. */
    private fun listedNearBottom(root: AccessibilityNodeInfo, ids: ChatIds, text: String): Boolean =
        root.findAccessibilityNodeInfosByViewId(ids.messageText)
            .sortedByDescending { Rect().also(it::getBoundsInScreen).top }
            .take(3)
            .any { OwnReplies.sameMessage(it.text, text) }

    /** Tanı için Gönder bölgesi ve kutunun durumu: kimlik, bayraklar, yer. Metin YAZILMAZ. */
    private fun describeSendArea(root: AccessibilityNodeInfo, ids: ChatIds): String {
        val out = mutableListOf<String>()
        root.findAccessibilityNodeInfosByViewId(ids.entry).firstOrNull()?.let { e ->
            val hint = if (Build.VERSION.SDK_INT >= 26) "ipucu=${e.hintText?.length} gösteriliyor=${e.isShowingHintText}" else ""
            out += "kutu: uzunluk=${e.text?.length ?: 0} $hint odak=${e.isFocused}"
        }
        val area = root.findAccessibilityNodeInfosByViewId(ids.buttons).firstOrNull()
            ?: root.findAccessibilityNodeInfosByViewId(ids.sendContainer).firstOrNull()
        fun walk(node: AccessibilityNodeInfo, depth: Int) {
            if (depth > 4 || out.size > 20) return
            val r = Rect().also(node::getBoundsInScreen)
            val name = node.viewIdResourceName?.substringAfter(":id/")
                ?: node.className?.toString()?.substringAfterLast('.')
            out += "$name t=${node.isClickable} g=${node.isVisibleToUser} ${r.toShortString()}"
            for (i in 0 until node.childCount) node.getChild(i)?.let { walk(it, depth + 1) }
        }
        area?.let { walk(it, 0) } ?: out.add("gönder bölgesi yok")
        return out.joinToString(" | ")
    }

    // ---- Örtü ----

    private fun showOverlay(shot: ScreenShot.Shot?) {
        if (overlay != null) return
        val night = resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK ==
            Configuration.UI_MODE_NIGHT_YES
        val density = resources.displayMetrics.density
        fun dp(v: Int) = (v * density).toInt()
        val root = FrameLayout(this)
        if (shot != null) {
            // Mesa'nın görüntüsü; kenarlar görüntünün üst rengiyle doldurulur.
            val bitmap = shot.bitmap
            root.setBackgroundColor(bitmap.getPixel(bitmap.width / 2, minOf(dp(4), bitmap.height - 1)))
            root.addView(
                ImageView(this).apply {
                    setImageBitmap(bitmap)
                    scaleType = ImageView.ScaleType.FIT_XY
                },
                FrameLayout.LayoutParams(bitmap.width, bitmap.height).apply {
                    leftMargin = shot.x
                    topMargin = shot.y
                },
            )
        } else {
            root.setBackgroundColor(if (night) 0xFF121316.toInt() else 0xFFF6F7FA.toInt())
        }
        val chip = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            background = GradientDrawable().apply {
                cornerRadius = dp(22).toFloat()
                setColor(0xEE202124.toInt())
            }
            setPadding(dp(16), dp(10), dp(18), dp(10))
            addView(
                ProgressBar(context, null, android.R.attr.progressBarStyleSmall).apply {
                    indeterminateTintList = ColorStateList.valueOf(0xFFFFFFFF.toInt())
                },
                LinearLayout.LayoutParams(dp(18), dp(18)),
            )
            addView(
                TextView(context).apply {
                    text = getString(R.string.auto_send_progress)
                    setTextColor(0xFFFFFFFF.toInt())
                    textSize = 14f
                    setPadding(dp(10), 0, 0, 0)
                },
            )
        }
        root.addView(
            chip,
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
                Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL,
            ).apply { bottomMargin = dp(150) },
        )
        // Kullanıcının dokunuşları alttaki WhatsApp'a gitmesin.
        root.setOnTouchListener { _, _ -> true }
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.OPAQUE,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            if (Build.VERSION.SDK_INT >= 28) {
                layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
            }
        }
        try {
            getSystemService(WindowManager::class.java).addView(root, params)
            overlay = root
            overlayParams = params
        } catch (e: RuntimeException) {
            Log.w(TAG, "Gönderim örtüsü gösterilemedi: ${e.javaClass.simpleName}")
        }
    }

    /** Servisin dokunuşu sırasında örtü dokunmayı alttaki WhatsApp'a geçirir. */
    private fun setOverlayTouchable(touchable: Boolean) {
        val view = overlay ?: return
        val params = overlayParams ?: return
        val flag = WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE
        params.flags = if (touchable) params.flags and flag.inv() else params.flags or flag
        try {
            getSystemService(WindowManager::class.java).updateViewLayout(view, params)
        } catch (e: RuntimeException) {
            Log.w(TAG, "Gönderim örtüsü güncellenemedi: ${e.javaClass.simpleName}")
        }
    }

    private fun removeOverlay() {
        val view = overlay ?: return
        overlay = null
        overlayParams = null
        try {
            getSystemService(WindowManager::class.java).removeView(view)
        } catch (e: RuntimeException) {
            Log.w(TAG, "Gönderim örtüsü kaldırılamadı: ${e.javaClass.simpleName}")
        }
    }

    // ---- Ekran okuma ----

    /** WhatsApp penceresinin kökü (örtü açıkken etkin pencere de WhatsApp olmayabilir). */
    private fun appRoot(ids: ChatIds): AccessibilityNodeInfo? {
        rootInActiveWindow?.takeIf { it.packageName?.toString() == ids.packageName }?.let { return it }
        return windows.asSequence()
            .filter { it.type == AccessibilityWindowInfo.TYPE_APPLICATION }
            .mapNotNull { it.root }
            .firstOrNull { it.packageName?.toString() == ids.packageName }
    }

    /** Boş kutu: Android metin yerine ipucunu ("Mesaj") bildirir. */
    private fun isEmptyEntry(node: AccessibilityNodeInfo): Boolean {
        val text = node.text?.toString().orEmpty()
        if (text.isBlank()) return true
        if (Build.VERSION.SDK_INT >= 26) {
            if (node.isShowingHintText) return true
            if (node.hintText?.toString() == text) return true
        }
        return false
    }

    private fun chatTitle(root: AccessibilityNodeInfo?, ids: ChatIds): String? =
        root?.findAccessibilityNodeInfosByViewId(ids.title)
            ?.firstNotNullOfOrNull { it.text?.toString()?.takeIf(String::isNotBlank) }

    /** WhatsApp sohbet ekranının öğe kimlikleri (iki uygulamada da aynı adlar). */
    private class ChatIds(val packageName: String) {
        val entry = "$packageName:id/entry"
        val send = "$packageName:id/send"
        val title = "$packageName:id/conversation_contact_name"
        val messageText = "$packageName:id/message_text"
        val buttons = "$packageName:id/buttons"
        val sendContainer = "$packageName:id/send_container"

        /** "send" henüz yokken düğmenin yeri (2.26: voice_note_btn ve kapları). */
        val fallbackTargets = listOf(
            "$packageName:id/voice_note_btn",
            "$packageName:id/send_container",
            "$packageName:id/conversation_entry_action_button",
        )
    }

    companion object {
        private const val TAG = "MesajMerkezi"
        private const val VERIFY_DELAY_MS = 800L
        private const val WINDOW_DELAY_MS = 400L
        private const val AUTO_WINDOW_DELAY_MS = 100L
        private const val SETTLE_MS = 200L
        private const val SEND_BUTTON_WAIT_MS = 1_500L
        private const val CONFIRM_POLL_MS = 100L
        private const val CONFIRM_MAX_MS = 1_000L
        private const val TAP_MS = 100L
        private const val OVERLAY_LINGER_MS = 700L
        private const val OVERLAY_FALLBACK_MS = 1_200L

        /** Bağlı servis; Mesa göndermeden önce örtüyü açtırır. */
        @Volatile
        var instance: OwnReplyService? = null
            private set
    }
}
