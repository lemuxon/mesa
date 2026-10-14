package com.mesajmerkezi.mesaj_merkezi

import android.Manifest
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import android.service.notification.NotificationListenerService
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

// Uygulama kilidi (local_auth) biyometrik pencere için FragmentActivity ister.
class MainActivity : FlutterFragmentActivity() {

    private companion object {
        const val TAG = "MesajMerkezi"
    }

    private val listenerComponent by lazy { ComponentName(this, MessageListenerService::class.java) }

    // Sonuç dinleyicileri etkinlik oluşturulurken kaydedilmeli.
    private val media = MediaTools(this)

    // ---- Yedek: dosyanın yerini kullanıcı seçer (Drive, İndirilenler…) ----
    private var pendingBackupUri: ((Uri?) -> Unit)? = null
    private val createBackupDocument = registerForActivityResult(
        androidx.activity.result.contract.ActivityResultContracts.CreateDocument("application/octet-stream")
    ) { uri ->
        pendingBackupUri?.invoke(uri)
        pendingBackupUri = null
    }
    private val openBackupDocument = registerForActivityResult(
        androidx.activity.result.contract.ActivityResultContracts.OpenDocument()
    ) { uri ->
        pendingBackupUri?.invoke(uri)
        pendingBackupUri = null
    }

    /** Yedek alınır; iptal edilirse null, hata olursa yarım dosya silinir. */
    private fun createBackup(password: String, result: MethodChannel.Result) {
        val day = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.ROOT).format(java.util.Date())
        pendingBackupUri = { uri ->
            if (uri == null) {
                result.success(null)
            } else {
                Thread {
                    try {
                        val out = contentResolver.openOutputStream(uri, "w") ?: error(Lang.str(this, R.string.file_write_failed))
                        val summary = Backup.export(this, out, password.toCharArray())
                        runOnUiThread { result.success(summary.toMap()) }
                    } catch (e: Exception) {
                        Log.w(TAG, "Yedek alınamadı: ${e.javaClass.simpleName}")
                        try {
                            android.provider.DocumentsContract.deleteDocument(contentResolver, uri)
                        } catch (ignored: Exception) {
                            // Silinemedi: kullanıcı yarım dosyayı görebilir.
                        }
                        runOnUiThread { result.error("BACKUP", e.message, null) }
                    }
                }.start()
            }
        }
        createBackupDocument.launch("mesa-$day.mmyedek")
    }

    private fun restoreBackup(uri: String, password: String, result: MethodChannel.Result) {
        Thread {
            try {
                val input = contentResolver.openInputStream(Uri.parse(uri)) ?: error(Lang.str(this, R.string.file_open_failed))
                val summary = input.use { Backup.restore(this, it, password.toCharArray()) }
                runOnUiThread { result.success(summary.toMap()) }
            } catch (e: WrongPasswordException) {
                runOnUiThread { result.error("WRONG_PASSWORD", e.message, null) }
            } catch (e: CorruptBackupException) {
                runOnUiThread { result.error("CORRUPT", Lang.str(this, e.reason), null) }
            } catch (e: Exception) {
                Log.w(TAG, "Yedek geri yüklenemedi: ${e.javaClass.simpleName}")
                runOnUiThread { result.error("RESTORE", e.message, null) }
            }
        }.start()
    }

    private fun Backup.Summary.toMap() = mapOf("messages" to messages, "files" to files, "bytes" to bytes)

    /** Telegram'da açık sohbet (kapatılınca TDLib'e bildirilir). */
    private var openTelegramChats: Set<String> = emptySet()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, "mesaj_merkezi/core").setMethodCallHandler(::onCall)
        EventChannel(messenger, "mesaj_merkezi/events").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    Hub.onChanged = { key -> events.success(key) }
                }

                override fun onCancel(arguments: Any?) {
                    Hub.onChanged = null
                }
            }
        )
        EventChannel(messenger, "mesaj_merkezi/listener_status").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    Hub.onListenerStatus = { connected -> events.success(connected) }
                }

                override fun onCancel(arguments: Any?) {
                    Hub.onListenerStatus = null
                }
            }
        )
        EventChannel(messenger, "mesaj_merkezi/telegram").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    Hub.onTelegramState = { events.success(telegramStatus()) }
                }

                override fun onCancel(arguments: Any?) {
                    Hub.onTelegramState = null
                }
            }
        )
        EventChannel(messenger, "mesaj_merkezi/presence").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    Presence.onChanged = { state -> events.success(state) }
                }

                override fun onCancel(arguments: Any?) {
                    Presence.onChanged = null
                }
            }
        )
        EventChannel(messenger, "mesaj_merkezi/open").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    openSink = events
                }

                override fun onCancel(arguments: Any?) {
                    openSink = null
                }
            }
        )
        WebChannel(this).register(messenger)
        Hub.io.execute {
            Maintenance.purgeIfDue(this)
            MediaTools.cleanOutbox(this)
        }
        // Süreç yeniden başladıysa Telegram ve web servisleri geri gelsin.
        if (ConnectionService.needed(this)) ConnectionService.refresh(this)
    }

    /** Birleşik bildirime dokunulunca açılacak sohbet (uygulama kapalıyken). */
    private var launchConversation: String? = null
    private var openSink: EventChannel.EventSink? = null

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        launchConversation = intent?.getStringExtra(UnifiedNotifier.EXTRA_KEY)
        AppLock.install(application)
        super.onCreate(savedInstanceState)
    }

    override fun onResume() {
        super.onResume()
        AppLock.applyRecentsPrivacy(this)
    }

    // Okunanlar ana ekran bileşenine de yansısın.
    override fun onPause() {
        MessagesWidget.refresh(this)
        super.onPause()
    }

    // Uygulama açıkken bildirime dokunuldu.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val key = intent.getStringExtra(UnifiedNotifier.EXTRA_KEY) ?: return
        openSink?.success(key) ?: run { launchConversation = key }
    }

    private fun onCall(call: MethodCall, result: MethodChannel.Result) {
        val store = Hub.store(this)
        when (call.method) {
            "getListenerStatus" -> {
                val enabled = isListenerEnabled()
                // Güncellemeden sonra sistem servisi bazen yeniden bağlamıyor.
                if (enabled && !Hub.listenerConnected) {
                    NotificationListenerService.requestRebind(listenerComponent)
                }
                result.success(
                    mapOf(
                        "enabled" to enabled,
                        "connected" to Hub.listenerConnected,
                        "xiaomi" to isXiaomi(),
                    )
                )
            }
            // ---- Uygulama kilidi (yerel ekranlar da uysun) ----
            "appLockSetEnabled" -> {
                AppLock.setEnabled(this, call.argument<Boolean>("value") ?: false)
                AppLock.applyRecentsPrivacy(this)
                result.success(null)
            }
            "appLockIsLocked" -> result.success(AppLock.isLocked(this))
            "appLockChanged" -> {
                if (call.argument<Boolean>("locked") == true) AppLock.state.lock() else AppLock.state.unlock()
                result.success(null)
            }
            "rebindListener" -> {
                rebindListener()
                result.success(null)
            }
            "openListenerSettings" -> {
                startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                result.success(null)
            }
            "openAutostartSettings" -> {
                openAutostartSettings()
                result.success(null)
            }
            "openAppSettings" -> {
                openAppSettings()
                result.success(null)
            }
            "health" -> result.success(health())
            "openBatterySettings" -> {
                openBatterySettings()
                result.success(null)
            }
            "openNotificationSettings" -> {
                openNotificationSettings()
                result.success(null)
            }
            "getConversations" -> background(result) {
                val archived = call.argument<Boolean>("archived") ?: false
                store.conversations(archived).map { it + ("canReply" to Hub.canReply(it["key"] as String)) }
            }
            "archivedCount" -> background(result) { store.archivedCount() }
            "setPinned" -> background(result) {
                store.setPinned(call.argument<String>("key")!!, call.argument<Boolean>("value")!!)
            }
            "setArchived" -> background(result) {
                store.setArchived(call.argument<String>("key")!!, call.argument<Boolean>("value")!!)
            }
            "markAllRead" -> background(result) { store.markAllRead() }
            "search" -> background(result) { store.search(call.argument<String>("query").orEmpty()) }
            "getSettings" -> result.success(AppSettings.toMap(this))
            "updateSettings" -> {
                val wasUnified = AppSettings.unifiedNotifications(this)
                val keptBefore = AppSettings.keepSourcePackages(this)
                AppSettings.update(this, call.arguments as Map<*, *>)
                // Birleşik bildirimler yeni açıldıysa ya da bir uygulamanın kendi
                // bildirimi artık kalmayacaksa çubuktakiler hemen dönüştürülür.
                val unified = AppSettings.unifiedNotifications(this)
                if (unified && (!wasUnified || !AppSettings.keepSourcePackages(this).containsAll(keptBefore))) {
                    MessageListenerService.reprocessActiveNotifications()
                }
                // Saklama süresi kısaldıysa eski mesajlar hemen silinsin.
                background(result) { Maintenance.purgeIfDue(this, force = true) }
            }
            "requestNotificationPermission" -> {
                requestNotificationPermission()
                result.success(null)
            }
            "takeLaunchConversation" -> {
                result.success(launchConversation)
                launchConversation = null
            }
            "setActiveConversation" -> {
                // Tek sohbet ("key") ya da kişi ekranında kişinin tüm sohbetleri ("keys").
                val keys = call.argument<List<String>>("keys")?.toSet()
                    ?: setOfNotNull(call.argument<String>("key"))
                UnifiedNotifier.activeConversations = keys
                keys.forEach { UnifiedNotifier.cancel(this, it) }
                // Telegram'da açık sohbetler: "yazıyor" bilgisi eksiksiz gelsin.
                val telegram = keys.filter(TelegramClient::isTelegramKey).toSet()
                (openTelegramChats - telegram).forEach { TelegramClient.setChatOpen(it, false) }
                (telegram - openTelegramChats).forEach { TelegramClient.setChatOpen(it, true) }
                openTelegramChats = telegram
                result.success(null)
            }
            // ---- Kişiler ----
            "media" -> background(result) { store.media(call.argument<List<String>>("keys").orEmpty()) }
            "personSuggestions" -> background(result) { store.personSuggestions() }
            "mergePeople" -> background(result) {
                store.mergePeople(call.argument<List<String>>("keys")!!, call.argument<String>("name"))
            }
            "unmergePerson" -> background(result) { store.unmergePerson(call.argument<String>("key")!!) }
            "renamePerson" -> background(result) {
                store.renamePerson(call.argument<Number>("id")!!.toLong(), call.argument<String>("name")!!)
            }
            "dismissPersonSuggestion" -> background(result) {
                store.dismissPersonSuggestion(call.argument<String>("a")!!, call.argument<String>("b")!!)
            }
            "replyMode" -> result.success(
                Hub.replyMode(this, call.argument<String>("key")!!, call.argument<String>("package")!!)
            )
            // Kaynak uygulamada hazır açılıp orada gönderilen mesaj buraya da yazılır.
            "recordSentViaApp" -> background(result) {
                val key = call.argument<String>("key")!!
                store.recordOutgoing(key, call.argument<String>("text")!!).also { Hub.notifyChanged(key) }
            }
            "deleteMessage" -> background(result) {
                val key = call.argument<String>("key")!!
                store.deleteMessage(call.argument<String>("id")!!)
                Hub.notifyChanged(key)
            }
            "shareKinds" -> result.success(MediaTools.shareKinds(this, call.argument<String>("package")!!))
            "sendViaApp" -> {
                val key = call.argument<String>("key")!!
                val packageName = call.argument<String>("package")!!
                val text = call.argument<String>("text")
                Hub.io.execute {
                    val shortcut = store.conversation(key)?.get("shortcutId") as String?
                    runOnUiThread {
                        result.success(MediaTools.shareToConversation(this, packageName, shortcut, text, emptyList()))
                    }
                }
            }
            "pickMedia" -> media.pick(call.argument<String>("source") ?: "gallery") { items -> result.success(items) }
            "micPermission" -> media.requestMic { granted -> result.success(granted) }
            "startRecording" -> result.success(media.startRecording())
            "stopRecording" -> result.success(media.stopRecording(call.argument<Boolean>("cancel") ?: false))
            "sendMedia" -> sendMedia(call, result)
            // ---- Kaydedilenler, yanıt bekleyenler, hatırlatma, planlı mesaj, özet ----
            "starMessage" -> background(result) {
                store.setStarred(call.argument<String>("id")!!, call.argument<Boolean>("value")!!)
            }
            "starred" -> background(result) { store.starred() }
            "waiting" -> background(result) { store.waiting(System.currentTimeMillis()) }
            "dismissWaiting" -> background(result) { store.dismissWaiting(call.argument<String>("key")!!) }
            "snooze" -> background(result) {
                Reminders.snooze(this, call.argument<String>("key")!!, call.argument<Number>("until")!!.toLong())
            }
            "unsnooze" -> background(result) {
                val key = call.argument<String>("key")!!
                Reminders.unsnooze(this, key)
                Hub.notifyChanged(key)
            }
            "snoozed" -> background(result) { store.snoozed() }
            "scheduleMessage" -> background(result) {
                Reminders.schedule(
                    this,
                    call.argument<String>("key")!!,
                    call.argument<String>("text")!!,
                    call.argument<Number>("at")!!.toLong(),
                )
            }
            "scheduledMessages" -> background(result) { store.scheduled(call.argument<String>("key")) }
            "cancelScheduled" -> background(result) {
                Reminders.cancelScheduled(this, call.argument<Number>("id")!!.toLong())
            }
            "stats" -> background(result) {
                store.stats(System.currentTimeMillis(), call.argument<Int>("days") ?: 7)
            }
            "presence" -> result.success(Presence.all())
            "telegramTyping" -> {
                TelegramClient.sendTyping(call.argument<String>("key")!!)
                result.success(null)
            }
            "appIcon" -> {
                val packageName = call.argument<String>("package")!!
                background(result) { AvatarCache.appIconPng(this, packageName) }
            }
            "downloadMedia" -> {
                val id = call.argument<String>("id")!!
                TelegramPicker.async({
                    val (ref, kind) = store.mediaSource(id) ?: return@async null
                    if (!ref.startsWith(TelegramClient.REMOTE_SCHEME)) return@async null
                    TelegramClient.downloadRemote(ref)?.let { mapOf("path" to it, "kind" to kind) }
                }) { media -> runOnUiThread { result.success(media) } }
            }
            "telegramResend" -> TelegramClient.resend(call.argument<String>("id")!!) { ok ->
                runOnUiThread { result.success(ok) }
            }
            "telegramDeleteFailed" -> {
                TelegramClient.deleteFailed(call.argument<String>("id")!!)
                result.success(null)
            }
            "createBackup" -> createBackup(call.argument<String>("password")!!, result)
            "pickBackupFile" -> {
                pendingBackupUri = { uri -> result.success(uri?.toString()) }
                openBackupDocument.launch(arrayOf("*/*"))
            }
            "restoreBackup" -> restoreBackup(
                call.argument<String>("uri")!!,
                call.argument<String>("password")!!,
                result,
            )
            "storageUsage" -> background(result) { Storage.usage(this) }
            // Telegram temizliği uzun sürebilir: mesaj işleyen kuyruğun dışında.
            "cleanStorage" -> TelegramPicker.async({ Storage.clean(this) }) { freed ->
                runOnUiThread { result.success(freed ?: 0L) }
            }
            // Bildirimler, bileşen ve web servisi ekranı Flutter'daki dili kullansın.
            "setLanguage" -> {
                Lang.set(this, call.argument<String>("code"))
                MessagesWidget.refresh(this)
                if (ConnectionService.needed(this)) ConnectionService.refresh(this)
                result.success(null)
            }
            "setQuickReplies" -> {
                AppSettings.setQuickReplies(this, call.argument<List<String>>("replies").orEmpty())
                result.success(null)
            }
            "pinWidget" -> result.success(MessagesWidget.requestPin(this))
            "uploadProgress" -> result.success(TelegramClient.uploadProgress(call.argument<String>("id")!!))
            "downloadProgress" -> background(result) {
                val (ref, _) = store.mediaSource(call.argument<String>("id")!!) ?: return@background null
                TelegramClient.downloadProgress(ref)
            }
            "openInSourceApp" -> {
                val key = call.argument<String>("key")!!
                val packageName = call.argument<String>("package")!!
                result.success(Hub.openInSourceApp(this, key, packageName))
            }
            "getMessages" -> background(result) { store.messages(call.argument<String>("key")!!) }
            "canReply" -> result.success(Hub.canReply(call.argument<String>("key")!!))
            "markRead" -> {
                val key = call.argument<String>("key")!!
                // Telegram'da karşı taraf "görüldü" görsün.
                TelegramClient.markViewed(key)
                background(result) { store.markRead(key) }
            }
            "deleteConversation" -> background(result) {
                val key = call.argument<String>("key")!!
                store.deleteConversation(key)
                UnifiedNotifier.cancel(this, key)
                UnifiedNotifier.removeShortcut(this, key)
            }
            "sendReply" -> {
                val key = call.argument<String>("key")!!
                val text = call.argument<String>("text")!!
                try {
                    Hub.sendReply(this, key, text)
                } catch (e: NoReplyActionException) {
                    result.error("NO_REPLY_ACTION", null, null)
                    return
                }
                background(result) {
                    if (Hub.recordsOwnReplies(key)) store.recordOutgoing(key, text)
                    Hub.notifyChanged(key)
                }
            }
            "getRules" -> background(result) { store.ruleMaps() }
            "saveRule" -> background(result) {
                store.saveRule(Rule.fromMap(call.arguments as Map<*, *>))
            }
            "deleteRule" -> background(result) {
                store.deleteRule(call.argument<Number>("id")!!.toLong())
            }
            "telegramStatus" -> result.success(telegramStatus())
            "telegramConnect" -> {
                TelegramPrefs.setEnabled(this, true)
                requestNotificationPermission()
                ConnectionService.refresh(this)
                result.success(null)
            }
            "telegramSubmit" -> {
                val value = call.argument<String>("value")!!.trim()
                val done: (String?) -> Unit = { error -> runOnUiThread { result.success(error) } }
                when (call.argument<String>("step")) {
                    "phone" -> TelegramClient.submitPhone(value, done)
                    "code" -> TelegramClient.submitCode(value, done)
                    "emailCode" -> TelegramClient.submitEmailCode(value, done)
                    "password" -> TelegramClient.submitPassword(value, done)
                    else -> result.notImplemented()
                }
            }
            "telegramLogout" -> TelegramClient.logOut { error -> runOnUiThread { result.success(error) } }
            "telegramStickerSets" -> TelegramPicker.async(TelegramPicker::stickerSets) { sets ->
                runOnUiThread { result.success(sets) }
            }
            "telegramStickers" -> {
                val setId = call.argument<String>("setId")!!
                TelegramPicker.async({ TelegramPicker.stickers(setId) }) { stickers ->
                    runOnUiThread { result.success(stickers) }
                }
            }
            "telegramGifs" -> {
                val key = call.argument<String>("key")!!
                val query = call.argument<String>("query").orEmpty()
                TelegramPicker.async({ TelegramPicker.gifs(key, query) }) { gifs ->
                    runOnUiThread { result.success(gifs) }
                }
            }
            "telegramSendPick" -> {
                val key = call.argument<String>("key")!!
                val token = call.argument<String>("token")!!
                TelegramPicker.async({ TelegramPicker.send(key, token) }) { sent ->
                    runOnUiThread { result.success(sent == true) }
                }
            }
            "telegramLoadHistory" -> {
                TelegramClient.loadHistory(call.argument<String>("key")!!)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    /**
     * Medyayı gönderir: Telegram'a doğrudan (TDLib yükler), diğer uygulamalara
     * sohbet hazır açılarak (kullanıcı orada gönderir). Sonuç: "sent", "shared", "failed".
     */
    private fun sendMedia(call: MethodCall, result: MethodChannel.Result) {
        val key = call.argument<String>("key")!!
        val packageName = call.argument<String>("package")!!
        val caption = call.argument<String>("caption")?.trim()?.takeIf { it.isNotEmpty() }
        val items = call.argument<List<Map<String, Any?>>>("items").orEmpty()
        val outbox = MediaTools.outbox(this).canonicalPath
        // Yalnızca uygulamanın gönderim klasöründeki dosyalar gönderilir.
        val files = items.mapNotNull { item ->
            val file = java.io.File(item["path"] as String? ?: return@mapNotNull null)
            if (file.canonicalPath.startsWith(outbox) && file.exists()) file to item else null
        }
        val kinds = items.joinToString(",") { it["kind"] as String? ?: "?" }
        if (files.isEmpty()) {
            Log.w(TAG, "Medya gönderilemedi: dosya bulunamadı ($kinds)")
            return result.success("failed")
        }
        if (TelegramClient.isTelegramKey(key)) {
            try {
                files.forEachIndexed { i, (file, item) ->
                    TelegramClient.sendMedia(
                        key,
                        file.absolutePath,
                        item["kind"] as String? ?: "file",
                        (item["duration"] as Number?)?.toInt() ?: 0,
                        if (i == files.lastIndex) caption else null,
                    )
                }
                Log.i(TAG, "Medya Telegram'a gönderildi ($kinds)")
                result.success("sent")
            } catch (e: NoReplyActionException) {
                Log.w(TAG, "Medya gönderilemedi: Telegram bağlı değil ($kinds)")
                result.success("failed")
            }
            return
        }
        Hub.io.execute {
            val shortcut = store().conversation(key)?.get("shortcutId") as String?
            runOnUiThread {
                val list = files.map { it.first }
                result.success(
                    when {
                        !MediaTools.canShare(this, packageName, list) -> "unsupported"
                        MediaTools.shareToConversation(this, packageName, shortcut, caption, list) -> "shared"
                        else -> "failed"
                    }
                )
            }
        }
    }

    private fun store() = Hub.store(this)

    private fun telegramStatus(): Map<String, Any?> = mapOf(
        "configured" to TelegramConfig.isConfigured,
        "enabled" to TelegramPrefs.enabled(this),
        "state" to TelegramClient.state.name,
        "hint" to TelegramClient.hint,
    )

    /** Android 13+: ön plan servisinin "Telegram'a bağlı" bildirimi için. */
    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= 33) {
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1)
        }
    }

    /** Ayarlar'daki "Sistem durumu": mesajların eksiksiz gelmesi için gerekenler. */
    private fun health(): Map<String, Any?> = mapOf(
        "listenerEnabled" to isListenerEnabled(),
        "listenerConnected" to Hub.listenerConnected,
        "notificationsAllowed" to NotificationManagerCompat.from(this).areNotificationsEnabled(),
        "batteryUnrestricted" to getSystemService(android.os.PowerManager::class.java)
            .isIgnoringBatteryOptimizations(packageName),
        "micAllowed" to (
            androidx.core.content.ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) ==
                PackageManager.PERMISSION_GRANTED
            ),
        "xiaomi" to isXiaomi(),
    )

    /** Pil kısıtlaması: uygulama arka planda kapatılmasın (Telegram, web servisleri, kurallar). */
    @android.annotation.SuppressLint("BatteryLife")
    private fun openBatterySettings() {
        val direct = Intent(
            Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
            Uri.parse("package:$packageName"),
        )
        try {
            startActivity(direct)
        } catch (e: ActivityNotFoundException) {
            try {
                startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
            } catch (e: ActivityNotFoundException) {
                openAppSettings()
            }
        }
    }

    private fun openNotificationSettings() {
        if (Build.VERSION.SDK_INT >= 26) {
            try {
                startActivity(
                    Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                        .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                )
                return
            } catch (e: ActivityNotFoundException) {
                // Uygulama ayarlarıyla devam.
            }
        }
        openAppSettings()
    }

    private fun isListenerEnabled() =
        NotificationManagerCompat.getEnabledListenerPackages(this).contains(packageName)

    // Redmi ve POCO cihazlar da üretici olarak "Xiaomi" bildirir.
    private fun isXiaomi() = Build.MANUFACTURER.equals("Xiaomi", ignoreCase = true)

    /**
     * Servis bileşenini kapatıp açar. Paket değişikliği sayılır ve sistem
     * dinleyicileri yeniden bağlar; yalnızca requestRebind bazı MIUI
     * sürümlerinde yetmiyor (2026-10-09, Redmi Note 11 Pro, Android 13).
     * Bağlıyken çağrılmamalı: bileşen kapanınca bağlantı da düşer.
     */
    private fun rebindListener() {
        if (Hub.listenerConnected) return
        packageManager.setComponentEnabledSetting(
            listenerComponent,
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
            PackageManager.DONT_KILL_APP,
        )
        packageManager.setComponentEnabledSetting(
            listenerComponent,
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP,
        )
        NotificationListenerService.requestRebind(listenerComponent)
    }

    /** MIUI'nin otomatik başlatma listesi; bulunamazsa uygulama ayarları. */
    private fun openAutostartSettings() {
        val autostart = Intent().setComponent(
            ComponentName(
                "com.miui.securitycenter",
                "com.miui.permcenter.autostart.AutoStartManagementActivity",
            )
        )
        try {
            startActivity(autostart)
        } catch (e: ActivityNotFoundException) {
            openAppSettings()
        } catch (e: SecurityException) {
            openAppSettings()
        }
    }

    private fun openAppSettings() {
        startActivity(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", packageName, null))
        )
    }

    /** Veritabanı işini ana iş parçacığı dışında yapar, sonucu ana iş parçacığında döner. */
    private fun background(result: MethodChannel.Result, block: () -> Any?) {
        Hub.io.execute {
            try {
                val value = block().takeUnless { it is Unit }
                runOnUiThread { result.success(value) }
            } catch (e: Exception) {
                runOnUiThread { result.error("STORE_ERROR", e.message, null) }
            }
        }
    }
}
