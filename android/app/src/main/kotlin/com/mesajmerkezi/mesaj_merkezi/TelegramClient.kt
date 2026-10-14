package com.mesajmerkezi.mesaj_merkezi

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.os.Build
import android.util.Log
import org.drinkless.tdlib.Client
import org.drinkless.tdlib.TdApi
import java.io.File
import java.util.concurrent.ConcurrentHashMap

/**
 * Telegram hesabına TDLib (resmi istemci kütüphanesi) ile doğrudan bağlantı.
 * Bildirim üretmeyen sessiz grupların mesajları da gelir. [ConnectionService]
 * içinde yaşar; arayüz kapalıyken de çalışır.
 *
 * Gizlilik: okundu bilgisi gönderilmez (viewMessages çağrılmaz), çevrimiçi
 * görünülmez ("online" seçeneği kapalı), mesajlar yalnızca yerel depoya yazılır.
 */
object TelegramClient {

    enum class State {
        /** api_id/api_hash derlemeye verilmemiş. */
        UNCONFIGURED,
        STOPPED,
        STARTING,
        WAIT_PHONE,
        WAIT_CODE,
        WAIT_EMAIL_CODE,
        WAIT_PASSWORD,
        READY,
        LOGGING_OUT,

        /** Bu sürümün desteklemediği bir giriş adımı (ör. yeni hesap kaydı). */
        UNSUPPORTED,
    }

    const val KEY_PREFIX = "tg|"
    const val PACKAGE = "org.telegram.messenger"
    private const val TAG = "MesajMerkezi"

    private const val MEDIA_SCHEME = "tdlib-file:"
    const val REMOTE_SCHEME = "tdlib-remote:"
    private const val MAX_MEDIA_BYTES = 8L * 1024 * 1024

    /** Sohbet açılınca indirilen geçmiş. */
    private const val HISTORY_LIMIT = 50

    @Volatile
    var state = State.STOPPED
        private set

    /** Giriş adımına dair açıklama: kodun nereye gittiği, şifre ipucu vb. */
    @Volatile
    var hint: String? = null
        private set

    /** Arayüz durumu dinler (ana iş parçacığında çağrılır). */
    @Volatile
    var onState: (() -> Unit)? = null

    @Volatile
    private var client: Client? = null
    private lateinit var appContext: Context

    /** Seçili dilde metin (bağlantı kurulduktan sonra; TelegramText ve seçici de kullanır). */
    internal fun text(@androidx.annotation.StringRes id: Int, vararg args: Any): String = Lang.str(appContext, id, *args)

    // TDLib, bir nesneye başvuran mesajdan önce updateNewChat / updateUser
    // göndermeyi garanti eder; önbellek yeterli.
    private val chats = ConcurrentHashMap<Long, TdApi.Chat>()
    private val users = ConcurrentHashMap<Long, TdApi.User>()

    /** Telegram'ın genel sessiz ayarları: kişiler / gruplar / kanallar. */
    private val scopeMuteFor = ConcurrentHashMap<String, Int>()

    /** Otomatik yanıt olarak gönderilip henüz sunucudan dönmemiş metinler. */
    private val pendingAuto = ConcurrentHashMap.newKeySet<String>()

    fun isTelegramKey(key: String) = key.startsWith(KEY_PREFIX)

    val isReady get() = state == State.READY

    private fun keyOf(chatId: Long) = KEY_PREFIX + chatId

    fun chatIdOf(key: String) = key.removePrefix(KEY_PREFIX).toLong()

    @Synchronized
    fun start(context: Context) {
        appContext = context.applicationContext
        if (!TelegramConfig.isConfigured) {
            setState(State.UNCONFIGURED)
            return
        }
        if (client != null) return
        Client.execute(TdApi.SetLogVerbosityLevel(1))
        setState(State.STARTING)
        client = Client.create(
            { update -> onUpdate(update) },
            { e -> Log.w(TAG, "TDLib güncellemesi işlenemedi", e) },
            { e -> Log.w(TAG, "TDLib hatası", e) },
        )
        watchNetwork()
    }

    // ---- Ağ ----

    private var networkCallback: ConnectivityManager.NetworkCallback? = null

    @Volatile
    private var lastNetworkType: String? = null

    /**
     * Telefonun ağı değişince (uçak modu kapandı, Wi-Fi'den mobile geçildi)
     * TDLib'e hemen bildirilir; bildirilmezse bağlantıyı kendi bekleme
     * süresiyle yeniden dener ve bekleyen mesajlar onlarca saniye "gönderiliyor"
     * kalır (2026-10-11 cihazda: uçak modu sonrası 55 sn).
     */
    private fun watchNetwork() {
        if (networkCallback != null) return
        val manager = appContext.getSystemService(ConnectivityManager::class.java) ?: return
        val callback = object : ConnectivityManager.NetworkCallback() {
            // Yeni ağ: tür aynı olsa da bağlantılar yeniden açılsın.
            override fun onAvailable(network: Network) =
                reportNetwork(manager.getNetworkCapabilities(network), force = true)

            override fun onCapabilitiesChanged(network: Network, capabilities: NetworkCapabilities) =
                reportNetwork(capabilities, force = false)

            override fun onLost(network: Network) = reportNetwork(null, force = true)
        }
        try {
            manager.registerDefaultNetworkCallback(callback)
            networkCallback = callback
        } catch (e: RuntimeException) {
            Log.w(TAG, "Ağ değişiklikleri izlenemiyor", e)
        }
    }

    private fun unwatchNetwork() {
        val callback = networkCallback ?: return
        networkCallback = null
        lastNetworkType = null
        try {
            appContext.getSystemService(ConnectivityManager::class.java)?.unregisterNetworkCallback(callback)
        } catch (e: RuntimeException) {
            // Zaten kaldırılmış.
        }
    }

    private fun reportNetwork(capabilities: NetworkCapabilities?, force: Boolean) {
        val type: TdApi.NetworkType = when {
            capabilities == null -> TdApi.NetworkTypeNone()
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) ||
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> TdApi.NetworkTypeWiFi()
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) ->
                if (capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_ROAMING)) {
                    TdApi.NetworkTypeMobile()
                } else {
                    TdApi.NetworkTypeMobileRoaming()
                }
            else -> TdApi.NetworkTypeOther()
        }
        val name = type.javaClass.simpleName
        // Android ağı önce "bağlı", birkaç saniye sonra "internete çıkıyor"
        // (doğrulandı) sayar; ilk bildirimde açılan bağlantı boşa gidebiliyor
        // (2026-10-11: Wi-Fi geldikten 15 sn sonra gönderildi). Doğrulanınca
        // bağlantılar bir kez daha yenilenir.
        val validated = capabilities?.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED) == true
        val key = "$name:$validated"
        // Yetenek değişiklikleri (sinyal, hız) sık gelir; yalnızca tür ya da doğrulama değişince bildirilir.
        if (!force && key == lastNetworkType) return
        val previous = lastNetworkType
        lastNetworkType = key
        // Yalnızca doğrulandı: bağlantı zaten kurulduysa yeniden açmaya gerek yok.
        if (!force && previous == "$name:false" && validated && connectionState == "Ready") return
        send(TdApi.SetNetworkType().apply { this.type = type })
        Log.i(TAG, "Telegram'a ağ bildirildi: ${name.removePrefix("NetworkType")}${if (validated) " (doğrulandı)" else ""}")
    }

    @Volatile
    private var connectionState: String? = null

    /** İçeriksiz: Telegram sunucusuna bağlantının durumu (yalnızca değişince). */
    private fun onConnectionState(state: TdApi.ConnectionState) {
        val name = state.javaClass.simpleName.removePrefix("ConnectionState")
        if (name == connectionState) return
        connectionState = name
        Log.i(TAG, "Telegram bağlantısı: $name")
    }

    // ---- Giriş ----

    /** [done] hata metniyle (ya da başarıda null ile) çağrılır. */
    fun submitPhone(phone: String, done: (String?) -> Unit) =
        send(TdApi.SetAuthenticationPhoneNumber().apply { phoneNumber = phone }, done)

    fun submitCode(code: String, done: (String?) -> Unit) =
        send(TdApi.CheckAuthenticationCode().apply { this.code = code }, done)

    fun submitEmailCode(code: String, done: (String?) -> Unit) = send(
        TdApi.CheckAuthenticationEmailCode().apply {
            this.code = TdApi.EmailAddressAuthenticationCode().apply { this.code = code }
        },
        done,
    )

    fun submitPassword(password: String, done: (String?) -> Unit) =
        send(TdApi.CheckAuthenticationPassword().apply { this.password = password }, done)

    /** Oturumu Telegram tarafında da kapatır; bu cihaz "Etkin oturumlar"dan düşer. */
    fun logOut(done: (String?) -> Unit) {
        TelegramPrefs.setEnabled(appContext, false)
        send(TdApi.LogOut(), done)
    }

    // ---- Mesajlar ----

    /** Gönderilen mesaj sunucudan updateMessageSendSucceeded ile döner ve öyle kaydedilir. */
    fun sendText(key: String, text: String, auto: Boolean) {
        if (!isReady) throw NoReplyActionException()
        val chatId = chatIdOf(key)
        if (auto) pendingAuto += autoKey(chatId, text)
        send(
            TdApi.SendMessage().apply {
                this.chatId = chatId
                inputMessageContent = TdApi.InputMessageText().apply {
                    this.text = TdApi.FormattedText().apply {
                        this.text = text
                        entities = emptyArray()
                    }
                }
            }
        ) { error -> if (error != null) Log.w(TAG, "Telegram mesajı gönderilemedi: $error") }
    }

    /**
     * Fotoğraf, video, sesli mesaj ya da dosya gönderir. [path] uygulamanın
     * kendi klasöründe olmalı (TDLib dosyayı oradan yükler). Mesaj, yükleme
     * bitince updateMessageSendSucceeded ile gelir ve öyle kaydedilir.
     */
    fun sendMedia(key: String, path: String, kind: String, durationSec: Int, caption: String?) {
        if (!isReady) throw NoReplyActionException()
        val file = TdApi.InputFileLocal().apply { this.path = path }
        val text = caption?.takeIf { it.isNotBlank() }?.let { c ->
            TdApi.FormattedText().apply {
                this.text = c
                entities = emptyArray()
            }
        }
        val content: TdApi.InputMessageContent = when (kind) {
            "photo" -> TdApi.InputMessagePhoto().apply {
                photo = TdApi.InputPhoto().apply {
                    photo = file
                    addedStickerFileIds = IntArray(0)
                }
                this.caption = text
            }
            "video" -> TdApi.InputMessageVideo().apply {
                video = TdApi.InputVideo().apply {
                    video = file
                    addedStickerFileIds = IntArray(0)
                    duration = durationSec
                    supportsStreaming = true
                }
                this.caption = text
            }
            "voice" -> TdApi.InputMessageVoiceNote().apply {
                voiceNote = TdApi.InputVoiceNote().apply {
                    voiceNote = file
                    duration = durationSec
                    waveform = ByteArray(0)
                }
                this.caption = text
            }
            else -> TdApi.InputMessageDocument().apply {
                document = TdApi.InputDocument().apply { document = file }
                this.caption = text
            }
        }
        send(
            TdApi.SendMessage().apply {
                chatId = chatIdOf(key)
                inputMessageContent = content
            }
        ) { error -> if (error != null) Log.w(TAG, "Telegram medyası gönderilemedi: $error") }
    }

    /**
     * Telegram sunucusunda bekleyen planlı mesaj (telefon kapalı olsa da
     * gider). [done] sunucudaki mesaj kimliğiyle (iptal için) ya da null ile.
     */
    fun sendScheduled(key: String, text: String, at: Long, done: (Long?) -> Unit) {
        if (!isReady) return done(null)
        val request = TdApi.SendMessage().apply {
            chatId = chatIdOf(key)
            options = TdApi.MessageSendOptions().apply {
                schedulingState = TdApi.MessageSchedulingStateSendAtDate().apply { sendDate = (at / 1000).toInt() }
            }
            inputMessageContent = TdApi.InputMessageText().apply {
                this.text = TdApi.FormattedText().apply {
                    this.text = text
                    entities = emptyArray()
                }
            }
        }
        callAsync(request) { result ->
            if (result is TdApi.Error) Log.w(TAG, "Telegram planlı mesajı kurulamadı: ${result.message}")
            done((result as? TdApi.Message)?.id)
        }
    }

    /** Planlı mesajı iptal: sunucudaki bekleyen mesaj silinir. */
    // Gönderilmekte olan mesajların başlangıcı (geçici kimlik → an): içeriksiz süre kaydı.
    private val sendingSince = ConcurrentHashMap<Long, Long>()

    /**
     * [ttlSeconds] süredir açılmamış medyayı Telegram önbelleğinden siler
     * (gerekirse yeniden iner). Profil fotoğrafları, çıkartmalar ve küçük
     * önizlemeler kalır. Engelleyici: TDLib iş parçacığından çağrılmamalı.
     */
    fun optimizeStorage(ttlSeconds: Int): Boolean {
        if (!isReady) return false
        val result = call(
            TdApi.OptimizeStorage().apply {
                // Boyut ve sayı sınırı yok: yalnızca eskilik ölçüt.
                size = 1L shl 40
                ttl = ttlSeconds
                count = Int.MAX_VALUE
                immunityDelay = 60 * 60
                fileTypes = arrayOf(
                    TdApi.FileTypePhoto(),
                    TdApi.FileTypeVideo(),
                    TdApi.FileTypeVideoNote(),
                    TdApi.FileTypeAnimation(),
                    TdApi.FileTypeVoiceNote(),
                    TdApi.FileTypeAudio(),
                    TdApi.FileTypeDocument(),
                )
                chatIds = LongArray(0)
                excludeChatIds = LongArray(0)
                returnDeletedFileStatistics = false
                chatLimit = 0
            },
            timeoutSeconds = 120,
        )
        val ok = result is TdApi.StorageStatistics
        Log.i(TAG, "Telegram önbelleği temizlendi (${ttlSeconds / 86400} günden eski): ${if (ok) "tamam" else "başarısız"}")
        return ok
    }

    /** Gönderilemeyen mesajı yeniden gönderir; TDLib yeni (gönderiliyor) mesaj döner. */
    fun resend(rowId: String, done: (Boolean) -> Unit) {
        val chatId = TelegramIds.chatId(rowId)
        val messageId = TelegramIds.messageId(rowId)
        val current = client
        if (!isReady || chatId == null || messageId == null || current == null) return done(false)
        current.send(
            TdApi.ResendMessages().apply {
                this.chatId = chatId
                messageIds = longArrayOf(messageId)
                quote = null
                paidMessageStarCount = 0
            }
        ) { result ->
            val sent = (result as? TdApi.Messages)?.messages?.filterNotNull().orEmpty()
            if (sent.isEmpty()) {
                Log.w(TAG, "Telegram mesajı yeniden gönderilemedi: ${(result as? TdApi.Error)?.let(::describeError)}")
            } else {
                Log.i(TAG, "Telegram mesajı yeniden gönderiliyor")
                ingest(chatId, sent, replaces = rowId)
            }
            done(sent.isNotEmpty())
        }
    }

    /** Gönderilemeyen mesajı Telegram'dan ve listeden siler (karşıya hiç gitmedi). */
    fun deleteFailed(rowId: String) {
        val chatId = TelegramIds.chatId(rowId) ?: return
        val messageId = TelegramIds.messageId(rowId) ?: return
        if (isReady) {
            send(
                TdApi.DeleteMessages().apply {
                    this.chatId = chatId
                    messageIds = longArrayOf(messageId)
                    revoke = false
                }
            )
        }
        Hub.io.execute {
            Hub.store(appContext).deleteMessage(rowId)
            Hub.notifyChanged(keyOf(chatId))
        }
    }

    fun deleteMessages(key: String, ids: LongArray) {
        if (!isReady || !isTelegramKey(key)) return
        send(
            TdApi.DeleteMessages().apply {
                chatId = chatIdOf(key)
                messageIds = ids
                revoke = true
            }
        )
    }

    /** Sohbet açıldı: Telegram'a son mesajın okunduğu bildirilir (karşı taraf "görüldü" görür). */
    fun markViewed(key: String) {
        if (!isReady || !isTelegramKey(key)) return
        // Gizli okuma: karşı taraf "görüldü" görmez.
        if (AppSettings.telegramGhostRead(appContext)) return
        val chatId = chatIdOf(key)
        val last = chats[chatId]?.lastMessage?.id ?: return
        send(
            TdApi.ViewMessages().apply {
                this.chatId = chatId
                messageIds = longArrayOf(last)
                forceRead = true
            }
        )
    }

    /** Sohbet ekranı açık/kapalı: açıkken TDLib "yazıyor" bilgisini eksiksiz gönderir. */
    fun setChatOpen(key: String, open: Boolean) {
        if (!isReady || !isTelegramKey(key)) return
        val chatId = chatIdOf(key)
        send(if (open) TdApi.OpenChat().apply { this.chatId = chatId } else TdApi.CloseChat().apply { this.chatId = chatId })
    }

    /** Kullanıcı Mesa'da yazıyor: karşı tarafta "yazıyor…" görünür. */
    fun sendTyping(key: String) {
        if (!isReady || !isTelegramKey(key)) return
        if (AppSettings.telegramGhostRead(appContext)) return
        send(
            TdApi.SendChatAction().apply {
                chatId = chatIdOf(key)
                businessConnectionId = ""
                action = TdApi.ChatActionTyping()
            }
        )
    }

    /**
     * Sohbetin son mesajlarını indirir. TDLib yerel veritabanı boşken ilk
     * istekte az mesaj döndürebilir; hedefe ulaşana ya da geçmiş bitene kadar sürer.
     */
    fun loadHistory(key: String) {
        if (!isReady || !isTelegramKey(key)) return
        loadHistoryPage(chatIdOf(key), fromMessageId = 0, loaded = 0)
    }

    private fun loadHistoryPage(chatId: Long, fromMessageId: Long, loaded: Int) {
        val request = TdApi.GetChatHistory().apply {
            this.chatId = chatId
            this.fromMessageId = fromMessageId
            offset = 0
            limit = HISTORY_LIMIT - loaded
            onlyLocal = false
        }
        client?.send(request) { result ->
            val messages = (result as? TdApi.Messages)?.messages.orEmpty().filterNotNull()
            if (messages.isEmpty()) return@send
            ingest(chatId, messages)
            val total = loaded + messages.size
            if (total < HISTORY_LIMIT) loadHistoryPage(chatId, messages.last().id, total)
        }
    }

    // ---- TDLib güncellemeleri ----

    private fun onUpdate(update: TdApi.Object) {
        when (update) {
            is TdApi.UpdateAuthorizationState -> onAuthorizationState(update.authorizationState)
            is TdApi.UpdateUser -> {
                users[update.user.id] = update.user
                onUserStatus(update.user.id, update.user.status)
            }
            is TdApi.UpdateUserStatus -> onUserStatus(update.userId, update.status)
            is TdApi.UpdateChatAction -> onChatAction(update.chatId, update.senderId, update.action)
            is TdApi.UpdateChatReadOutbox -> onReadOutbox(update.chatId, update.lastReadOutboxMessageId)
            is TdApi.UpdateNewChat -> {
                chats[update.chat.id] = update.chat
                if (update.chat.lastReadOutboxMessageId > 0) {
                    onReadOutbox(update.chat.id, update.chat.lastReadOutboxMessageId, notify = false)
                }
                downloadAvatar(update.chat.id, update.chat.photo)
                // İlk yüklemede her sohbetin son mesajı sohbet nesnesiyle gelir;
                // updateChatLastMessage yalnızca sonradan değişince gönderilir.
                update.chat.lastMessage?.let { message ->
                    if (message.sendingState == null) ingest(update.chat.id, listOf(message))
                }
            }
            is TdApi.UpdateChatPhoto -> {
                chats[update.chatId]?.photo = update.photo
                downloadAvatar(update.chatId, update.photo)
            }
            is TdApi.UpdateChatNotificationSettings ->
                chats[update.chatId]?.notificationSettings = update.notificationSettings
            is TdApi.UpdateScopeNotificationSettings ->
                scopeMuteFor[update.scope.javaClass.simpleName] = update.notificationSettings.muteFor
            is TdApi.UpdateChatTitle -> {
                chats[update.chatId]?.title = update.title
                val title = Names.title(update.title) ?: return
                Hub.io.execute {
                    Hub.store(appContext).renameConversation(keyOf(update.chatId), title)
                    Hub.notifyChanged(keyOf(update.chatId))
                }
            }
            // Gönderilmekte olan mesaj geçici kimliğiyle "gönderiliyor" olarak hemen
            // görünür; sunucu onaylayınca (ya da reddedince) kesin kimliğiyle değişir.
            // Planlı mesajlar zamanı gelip gönderilince kaydedilir.
            is TdApi.UpdateNewMessage ->
                if (update.message.schedulingState == null) {
                    if (update.message.sendingState is TdApi.MessageSendingStatePending) {
                        sendingSince[update.message.id] = android.os.SystemClock.elapsedRealtime()
                        Log.i(TAG, "Telegram mesajı gönderiliyor (${sendingSince.size} bekliyor)")
                        trackUpload(update.message)
                    }
                    ingest(update.message.chatId, listOf(update.message))
                }
            is TdApi.UpdateDeleteMessages -> if (update.isPermanent && !update.fromCache) {
                // Gönderen sildi: metin korunur, "silindi" işaretlenir.
                val ids = update.messageIds.map { TelegramIds.of(update.chatId, it) }
                Hub.io.execute {
                    Hub.store(appContext).markDeleted(ids)
                    Hub.notifyChanged(keyOf(update.chatId))
                }
            }
            is TdApi.UpdateMessageSendSucceeded -> {
                untrackUpload(update.message.chatId, update.oldMessageId)
                val waited = sendingSince.remove(update.oldMessageId)
                    ?.let { (android.os.SystemClock.elapsedRealtime() - it) / 1000 }
                Log.i(TAG, "Telegram mesajı gönderildi${waited?.let { " ($it sn sonra)" }.orEmpty()}")
                ingest(
                    update.message.chatId,
                    listOf(update.message),
                    replaces = TelegramIds.of(update.message.chatId, update.oldMessageId),
                )
            }
            is TdApi.UpdateMessageSendFailed -> {
                untrackUpload(update.message.chatId, update.oldMessageId)
                sendingSince.remove(update.oldMessageId)
                Log.w(TAG, "Telegram mesajı gönderilemedi: ${describeError(update.error)}")
                ingest(
                    update.message.chatId,
                    listOf(update.message),
                    replaces = TelegramIds.of(update.message.chatId, update.oldMessageId),
                )
            }
            is TdApi.UpdateFile -> onFile(update.file)
            is TdApi.UpdateConnectionState -> onConnectionState(update.state)
            is TdApi.UpdateChatLastMessage -> update.lastMessage?.let { message ->
                if (message.sendingState == null) ingest(message.chatId, listOf(message))
            }
        }
    }

    /** Özel sohbetin kimliği karşıdaki kullanıcının kimliğiyle aynıdır. */
    private fun onUserStatus(userId: Long, status: TdApi.UserStatus?) {
        if (!chats.containsKey(userId)) return
        when (status) {
            is TdApi.UserStatusOnline -> Presence.setOnline(keyOf(userId), true, null)
            is TdApi.UserStatusOffline -> Presence.setOnline(keyOf(userId), false, status.wasOnline * 1000L)
            null -> Unit
            else -> Presence.setOnline(keyOf(userId), false, null)
        }
    }

    private fun onChatAction(chatId: Long, sender: TdApi.MessageSender, action: TdApi.ChatAction) {
        val verb = when (action) {
            is TdApi.ChatActionTyping -> text(R.string.tg_typing)
            is TdApi.ChatActionRecordingVoiceNote -> text(R.string.tg_recording_voice)
            is TdApi.ChatActionUploadingVoiceNote -> text(R.string.tg_sending_voice)
            is TdApi.ChatActionUploadingPhoto -> text(R.string.tg_sending_photo)
            is TdApi.ChatActionUploadingVideo, is TdApi.ChatActionRecordingVideo -> text(R.string.tg_sending_video)
            is TdApi.ChatActionRecordingVideoNote, is TdApi.ChatActionUploadingVideoNote ->
                text(R.string.tg_recording_video_note)
            is TdApi.ChatActionUploadingDocument -> text(R.string.tg_sending_file)
            is TdApi.ChatActionChoosingSticker -> text(R.string.tg_choosing_sticker)
            else -> null
        }
        val chat = chats[chatId]
        val isGroup = chat?.type is TdApi.ChatTypeBasicGroup || chat?.type is TdApi.ChatTypeSupergroup
        // Grupta kimin yazdığı da söylenir.
        val text = verb?.let { v -> if (isGroup) senderName(sender)?.let { "$it $v" } ?: v else v }
        Presence.setTyping(keyOf(chatId), text)
    }

    private fun onReadOutbox(chatId: Long, lastRead: Long, notify: Boolean = true) {
        val key = keyOf(chatId)
        Hub.io.execute {
            Hub.store(appContext).setReadOutbox(key, lastRead)
            if (notify) Hub.notifyChanged(key)
        }
    }

    private fun onAuthorizationState(authState: TdApi.AuthorizationState) {
        when (authState) {
            is TdApi.AuthorizationStateWaitTdlibParameters -> send(tdlibParameters()) { error ->
                if (error != null) Log.w(TAG, "TDLib parametreleri reddedildi: $error")
            }
            is TdApi.AuthorizationStateWaitPhoneNumber -> setState(State.WAIT_PHONE)
            is TdApi.AuthorizationStateWaitCode -> {
                hint = describeCodeType(authState.codeInfo.type)
                setState(State.WAIT_CODE)
            }
            is TdApi.AuthorizationStateWaitEmailCode -> {
                hint = text(R.string.tg_hint_email, authState.codeInfo.emailAddressPattern)
                setState(State.WAIT_EMAIL_CODE)
            }
            is TdApi.AuthorizationStateWaitPassword -> {
                hint = authState.passwordHint.takeIf { it.isNotBlank() }?.let { text(R.string.tg_hint_password, it) }
                setState(State.WAIT_PASSWORD)
            }
            is TdApi.AuthorizationStateReady -> {
                hint = null
                TelegramPrefs.setLoggedIn(appContext, true)
                setState(State.READY)
                send(
                    TdApi.SetOption().apply {
                        name = "online"
                        value = TdApi.OptionValueBoolean().apply { this.value = false }
                    }
                )
                send(TdApi.LoadChats().apply { chatList = TdApi.ChatListMain(); limit = 100 })
            }
            is TdApi.AuthorizationStateLoggingOut -> setState(State.LOGGING_OUT)
            is TdApi.AuthorizationStateClosing -> Unit
            is TdApi.AuthorizationStateClosed -> onClosed()
            else -> {
                hint = text(R.string.tg_hint_unsupported, authState.javaClass.simpleName)
                setState(State.UNSUPPORTED)
            }
        }
    }

    @Synchronized
    private fun onClosed() {
        client = null
        unwatchNetwork()
        chats.clear()
        users.clear()
        pendingAuto.clear()
        Presence.clear()
        TelegramPrefs.setLoggedIn(appContext, false)
        hint = null
        setState(State.STOPPED)
        // Çıkıştan sonra yeniden giriş için yeni istemci gerekir.
        if (TelegramPrefs.enabled(appContext)) start(appContext) else ConnectionService.refresh(appContext)
    }

    private fun tdlibParameters() = TdApi.SetTdlibParameters().apply {
        useTestDc = false
        databaseDirectory = File(appContext.filesDir, "tdlib").absolutePath
        filesDirectory = File(appContext.noBackupFilesDir, "tdlib_files").absolutePath
        databaseEncryptionKey = ByteArray(0)
        useFileDatabase = true
        useChatInfoDatabase = true
        useMessageDatabase = true
        useSecretChats = false
        apiId = TelegramConfig.apiId
        apiHash = TelegramConfig.apiHash
        systemLanguageCode = "tr"
        deviceModel = "${Build.MANUFACTURER} ${Build.MODEL}"
        systemVersion = "Android ${Build.VERSION.RELEASE}"
        applicationVersion = "Mesa"
    }

    private fun describeCodeType(type: TdApi.AuthenticationCodeType): String = when (type) {
        is TdApi.AuthenticationCodeTypeTelegramMessage -> text(R.string.tg_code_app)
        is TdApi.AuthenticationCodeTypeSms -> text(R.string.tg_code_sms)
        is TdApi.AuthenticationCodeTypeCall -> text(R.string.tg_code_call)
        else -> text(R.string.tg_code_other)
    }

    // ---- Kayıt ----

    /** [replaces]: bu mesajla değişen geçici satır (gönderim onaylandı/başarısız). */
    private fun ingest(chatId: Long, messages: List<TdApi.Message>, replaces: String? = null) {
        val chat = chats[chatId] ?: return
        if (!AppSettings.isCaptured(appContext, PACKAGE)) return
        val type = chat.type
        if (type is TdApi.ChatTypeSupergroup && type.isChannel && AppSettings.hideTelegramChannels(appContext)) return
        val isGroup = chat.type is TdApi.ChatTypeBasicGroup || chat.type is TdApi.ChatTypeSupergroup
        val captured = messages.mapNotNull { message ->
            val text = TelegramText.describe(message.content) ?: return@mapNotNull null
            val media = TelegramText.mediaFile(message.content)
            val full = TelegramText.fullFile(message.content)?.remote?.id?.takeIf { it.isNotEmpty() }
            val sending = message.sendingState
            val sendState = when (sending) {
                is TdApi.MessageSendingStatePending -> SendState.PENDING
                is TdApi.MessageSendingStateFailed -> SendState.FAILED
                else -> SendState.SENT
            }
            val autoId = autoKey(chatId, text)
            CapturedMessage(
                sender = if (message.isOutgoing) null else senderName(message.senderId),
                text = text,
                time = message.date * 1000L,
                outgoing = message.isOutgoing,
                fromFallback = false,
                id = TelegramIds.of(chatId, message.id),
                // Otomatik yanıt işareti kesin mesajda tüketilir.
                auto = message.isOutgoing &&
                    (if (sendState == SendState.SENT) pendingAuto.remove(autoId) else autoId in pendingAuto),
                sendState = sendState,
                sendError = (sending as? TdApi.MessageSendingStateFailed)?.error?.let(::describeError),
                mediaMime = media?.second,
                mediaUri = media?.let { "$MEDIA_SCHEME${it.first.id}" },
                mediaKind = TelegramText.mediaKind(message.content),
                mediaRef = full?.let { "$REMOTE_SCHEME$it" },
                mediaDuration = TelegramText.mediaDuration(message.content),
                mediaSize = TelegramText.mediaSize(message.content),
            )
        }
        if (captured.isEmpty()) return
        val conversation = CapturedConversation(
            key = keyOf(chatId),
            packageName = PACKAGE,
            title = Names.title(chat.title) ?: "Telegram",
            isGroup = isGroup,
            messages = captured,
            replyAction = null,
        )
        Hub.io.execute {
            val store = Hub.store(appContext)
            replaces?.takeIf { old -> captured.none { it.id == old } }?.let(store::deleteMessage)
            val result = store.ingest(conversation)
            if (replaces != null && result.added == 0) Hub.notifyChanged(conversation.key)
            for ((messageId, message) in result.pendingMedia) downloadMedia(messageId, conversation.key, message)
            var fired = emptySet<RuleAction>()
            if (result.newIncoming.isNotEmpty()) {
                fired = try {
                    RuleRunner.run(appContext, store, conversation, result.newIncoming)
                } catch (e: RuntimeException) {
                    Log.w(TAG, "Kurallar uygulanamadı (Telegram)", e)
                    emptySet()
                }
                // Telegram'da sessize alınmış sohbet burada da bildirim göstermez.
                // Geçmiş indirilirken gelen eski mesajlar bildirim çaldırmasın.
                val fresh = result.newIncoming.any { System.currentTimeMillis() - it.time < RuleEngine.MAX_MESSAGE_AGE_MS }
                if (AppSettings.unifiedNotifications(appContext) && fresh && !isMuted(chat) && RuleAction.MUTE !in fired) {
                    UnifiedNotifier.show(appContext, conversation.key, alert = true, important = RuleAction.IMPORTANT in fired)
                }
            }
            if (result.added > 0) Hub.notifyChanged(conversation.key)
        }
    }

    /** Görseli TDLib'in dosya klasörüne indirir ve mesaja bağlar; büyük dosyalar atlanır. */
    private fun downloadMedia(messageId: String, key: String, message: CapturedMessage) {
        val fileId = message.mediaUri?.removePrefix(MEDIA_SCHEME)?.toIntOrNull() ?: return
        val request = TdApi.DownloadFile().apply {
            this.fileId = fileId
            priority = 1
            offset = 0
            limit = 0
            synchronous = true
        }
        client?.send(request) { result ->
            val file = result as? TdApi.File ?: return@send
            if (!file.local.isDownloadingCompleted || file.size > MAX_MEDIA_BYTES) return@send
            Hub.io.execute {
                Hub.store(appContext).setMedia(messageId, file.local.path, message.mediaMime)
                Hub.notifyChanged(key)
            }
        }
    }

    /** Sohbet sessizde mi: kendi ayarı ya da (varsayılanı kullanıyorsa) türünün genel ayarı. */
    private fun isMuted(chat: TdApi.Chat): Boolean {
        val settings = chat.notificationSettings ?: return false
        if (!settings.useDefaultMuteFor) return settings.muteFor > 0
        val scope = when (val type = chat.type) {
            is TdApi.ChatTypePrivate, is TdApi.ChatTypeSecret -> "NotificationSettingsScopePrivateChats"
            is TdApi.ChatTypeSupergroup ->
                if (type.isChannel) "NotificationSettingsScopeChannelChats" else "NotificationSettingsScopeGroupChats"
            else -> "NotificationSettingsScopeGroupChats"
        }
        return (scopeMuteFor[scope] ?: 0) > 0
    }

    private fun downloadAvatar(chatId: Long, photo: TdApi.ChatPhotoInfo?) {
        val small = photo?.small ?: return
        val key = keyOf(chatId)
        if (small.local.isDownloadingCompleted) {
            Hub.io.execute { Hub.store(appContext).setAvatar(key, small.local.path) }
            return
        }
        client?.send(
            TdApi.DownloadFile().apply {
                fileId = small.id
                priority = 1
                offset = 0
                limit = 0
                synchronous = true
            }
        ) { result ->
            val file = result as? TdApi.File ?: return@send
            if (!file.local.isDownloadingCompleted) return@send
            Hub.io.execute {
                Hub.store(appContext).setAvatar(key, file.local.path)
                Hub.notifyChanged(key)
            }
        }
    }

    /**
     * Uzak kaynaktaki tam boy dosyayı indirir ve yerel yolunu döner. Engelleyici:
     * TDLib iş parçacığından çağrılmamalı.
     */
    fun downloadRemote(ref: String): String? {
        val remoteId = ref.removePrefix(REMOTE_SCHEME)
        val file = call(TdApi.GetRemoteFile().apply { remoteFileId = remoteId }) as? TdApi.File ?: return null
        if (file.local.isDownloadingCompleted) return file.local.path
        remoteFileIds[remoteId] = file.id
        downloads[file.id] = file.local.downloadedSize.toLong() to totalSize(file)
        try {
            val downloaded = call(
                TdApi.DownloadFile().apply {
                    fileId = file.id
                    priority = 32
                    offset = 0
                    limit = 0
                    synchronous = true
                },
                timeoutSeconds = 180,
            ) as? TdApi.File ?: return null
            return downloaded.local.path.takeIf { downloaded.local.isDownloadingCompleted }
        } finally {
            downloads.remove(file.id)
            remoteFileIds.remove(remoteId)
        }
    }

    // İndirilen dosyaların ilerlemesi (arayüzdeki yüzde için): dosya → (inen, toplam).
    private val downloads = ConcurrentHashMap<Int, Pair<Long, Long>>()
    private val remoteFileIds = ConcurrentHashMap<String, Int>()

    private fun totalSize(file: TdApi.File) =
        if (file.size.toLong() > 0) file.size.toLong() else file.expectedSize.toLong()

    private fun onFile(file: TdApi.File) {
        if (downloads.containsKey(file.id)) {
            downloads[file.id] = file.local.downloadedSize.toLong() to totalSize(file)
        }
        uploadRows[file.id]?.let { row -> uploads[row] = file.remote.uploadedSize.toLong() to totalSize(file) }
    }

    // Gönderilirken yüklenen dosyalar: dosya → mesaj satırı; satır → (yüklenen, toplam).
    private val uploadRows = ConcurrentHashMap<Int, String>()
    private val uploads = ConcurrentHashMap<String, Pair<Long, Long>>()

    private fun trackUpload(message: TdApi.Message) {
        if (!message.isOutgoing) return
        val file = TelegramText.uploadFile(message.content) ?: return
        val row = TelegramIds.of(message.chatId, message.id)
        uploadRows[file.id] = row
        uploads[row] = file.remote.uploadedSize.toLong() to totalSize(file)
        Log.i(TAG, "Telegram yüklemesi başladı: ${totalSize(file) / 1024} KB")
    }

    private fun untrackUpload(chatId: Long, oldMessageId: Long) {
        val row = TelegramIds.of(chatId, oldMessageId)
        val last = uploads.remove(row) ?: return
        uploadRows.values.removeAll { it == row }
        val percent = if (last.second > 0) last.first * 100 / last.second else 0
        Log.i(TAG, "Telegram yüklemesi bitti (son görülen %$percent)")
    }

    /** Gönderilen medya yükleniyorsa 0..1 arası ilerleme; yüklenmiyorsa null. */
    fun uploadProgress(rowId: String): Double? {
        val (done, total) = uploads[rowId] ?: return null
        return if (total > 0) (done.toDouble() / total).coerceIn(0.0, 1.0) else null
    }

    /** Dosya indiriliyorsa 0..1 arası ilerleme; indirilmiyorsa ya da bilinmiyorsa null. */
    fun downloadProgress(ref: String): Double? {
        val id = remoteFileIds[ref.removePrefix(REMOTE_SCHEME)] ?: return null
        val (done, total) = downloads[id] ?: return null
        return if (total > 0) (done.toDouble() / total).coerceIn(0.0, 1.0) else null
    }

    private fun senderName(sender: TdApi.MessageSender): String? = when (sender) {
        is TdApi.MessageSenderUser -> users[sender.userId]?.let(TelegramText::displayName)
        is TdApi.MessageSenderChat -> chats[sender.chatId]?.title
        else -> null
    }

    private fun autoKey(chatId: Long, text: String) = "$chatId\u0000$text"

    // ---- Yardımcılar ----

    /**
     * TDLib'e istek gönderip sonucu bekler. TDLib'in kendi iş parçacığından
     * (güncelleme/sonuç işleyicileri) ÇAĞRILMAMALI: sonuç o iş parçacığında
     * teslim edildiği için kilitlenir.
     */
    fun call(function: TdApi.Function<*>, timeoutSeconds: Long = 30): TdApi.Object? {
        val current = client ?: return null
        val latch = java.util.concurrent.CountDownLatch(1)
        var value: TdApi.Object? = null
        current.send(function) { result ->
            value = result
            latch.countDown()
        }
        if (!latch.await(timeoutSeconds, java.util.concurrent.TimeUnit.SECONDS)) return null
        return value.also { if (it is TdApi.Error) Log.w(TAG, "TDLib isteği başarısız: ${it.message}") }
    }

    fun callAsync(function: TdApi.Function<*>, done: (TdApi.Object?) -> Unit) {
        val current = client ?: return done(null)
        current.send(function) { result -> done(result) }
    }

    private fun send(function: TdApi.Function<*>, done: ((String?) -> Unit)? = null) {
        val current = client
        if (current == null) {
            done?.invoke(text(R.string.tg_not_connected))
            return
        }
        current.send(function) { result ->
            val error = (result as? TdApi.Error)?.let(::describeError)
            if (error != null && done == null) Log.w(TAG, "TDLib isteği başarısız: $error")
            done?.invoke(error)
        }
    }

    private fun describeError(error: TdApi.Error): String = when {
        "PHONE_NUMBER_INVALID" in error.message -> text(R.string.tg_err_phone)
        "PHONE_CODE_INVALID" in error.message -> text(R.string.tg_err_code)
        "PHONE_CODE_EXPIRED" in error.message -> text(R.string.tg_err_code_expired)
        "PASSWORD_HASH_INVALID" in error.message -> text(R.string.tg_err_password)
        "EMAIL_CODE_INVALID" in error.message -> text(R.string.tg_err_email_code)
        error.code == 429 -> text(R.string.tg_err_flood)
        else -> error.message
    }

    private fun setState(newState: State) {
        // Yalnızca durum adı; telefon numarası, kod vb. asla yazılmaz.
        if (newState != state) Log.i(TAG, "Telegram durumu: ${state.name} → ${newState.name}")
        state = newState
        Hub.notifyTelegramState()
    }
}
