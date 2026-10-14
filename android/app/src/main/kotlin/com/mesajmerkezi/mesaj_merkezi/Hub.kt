package com.mesajmerkezi.mesaj_merkezi

import android.app.ActivityOptions
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.RemoteInput
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.ExecutorService

/**
 * Bildirimden yanıt verilemiyor: eylem bu süreçte hiç görülmedi ya da
 * ([canceled]) kaynak uygulama onu sonradan iptal etti.
 */
class NoReplyActionException(val canceled: Boolean = false) : Exception()

/** Bildirim servisi ile Flutter köprüsünün paylaştığı süreç içi durum. */
object Hub {

    /**
     * Tüm veritabanı işleri sırayla bu iş parçacığında yürür. Bir işteki hata
     * süreci düşürmez, kaydedilir (bkz. [SafeExecutor]).
     */
    val io: ExecutorService = SafeExecutor("Veritabanı")

    private val main = Handler(Looper.getMainLooper())

    // PendingIntent kalıcı saklanamaz; süreç ölünce yanıt yolları da kaybolur
    // ve o sohbete yeni bildirim gelene kadar yanıt verilemez.
    private val replyActions = ConcurrentHashMap<String, NotificationCompat.Action>()

    @Volatile
    var onChanged: ((String) -> Unit)? = null

    /**
     * Sistem bildirim servisini bağladı mı. İzin verilmiş olsa bile üretici
     * kısıtlamaları (ör. MIUI otomatik başlatma) bağlamayı engelleyebiliyor;
     * o sırada hiçbir mesaj yakalanmaz. Servis bu süreçte çalışır.
     */
    @Volatile
    var listenerConnected = false
        private set

    @Volatile
    var onListenerStatus: ((Boolean) -> Unit)? = null

    fun setListenerConnected(connected: Boolean) {
        listenerConnected = connected
        main.post { onListenerStatus?.invoke(connected) }
    }

    @Volatile
    private var store: MessageStore? = null

    fun store(context: Context): MessageStore {
        appContext = context.applicationContext
        return store ?: synchronized(this) {
            store ?: MessageStore(context.applicationContext).also { store = it }
        }
    }

    /**
     * Geri yüklemede veritabanı dosyası değişirken: açık bağlantı kapanır,
     * sonraki [store] yeniden açar. Hub.io'da çağrılmalı.
     */
    fun closeStore() {
        synchronized(this) {
            store?.close()
            store = null
        }
    }

    /** Ana ekran bileşenini değişiklikte yenilemek için. */
    @Volatile
    private var appContext: Context? = null

    fun rememberReply(key: String, action: NotificationCompat.Action) {
        replyActions[key] = action
    }

    /** Bu süreçte doğrudan yanıt verilebilen sohbet sayısı (tanılama). */
    fun replyPathCount() = replyActions.size

    // Bildirime dokununca açılacak yer (genelde kaynak uygulamadaki sohbetin kendisi).
    private val openIntents = ConcurrentHashMap<String, PendingIntent>()

    fun rememberOpen(key: String, intent: PendingIntent) {
        openIntents[key] = intent
    }

    /**
     * Sohbeti kaynak uygulamada açar: bildirimin kendi bağlantısı varsa
     * doğrudan sohbete, yoksa uygulamanın ana ekranına. Açılamazsa false.
     */
    fun openInSourceApp(context: Context, key: String, packageName: String): Boolean {
        if (WebServices.isWebPackage(packageName)) {
            val id = WebServices.idOfPackage(packageName)
            if (context is android.app.Activity) {
                WebServiceActivity.open(context, id, WebHost.clickIdFor(key))
            } else {
                context.startActivity(
                    WebServiceActivity.intent(context, id, WebHost.clickIdFor(key)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                )
            }
            return true
        }
        openIntents[key]?.let { intent ->
            try {
                // Android 14+: başka uygulamanın PendingIntent'i ile etkinlik
                // başlatmak için gönderenin açıkça izin vermesi gerekir.
                val options = if (Build.VERSION.SDK_INT >= 34) {
                    ActivityOptions.makeBasic()
                        .setPendingIntentBackgroundActivityStartMode(
                            ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED
                        )
                        .toBundle()
                } else {
                    null
                }
                intent.send(context, 0, null, null, null, null, options)
                return true
            } catch (e: PendingIntent.CanceledException) {
                openIntents.remove(key)
            }
        }
        // Bildirimin bağlantısı yoksa (süreç yeniden başladı): sohbetin bağlantısıyla.
        val shortcut = store(context).conversation(key)?.get("shortcutId") as String?
        chatLink(packageName, shortcut)?.let { (link, what) ->
            val chat = Intent(Intent.ACTION_VIEW, android.net.Uri.parse(link))
                .setPackage(packageName)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            try {
                context.startActivity(chat)
                Log.i("MesajMerkezi", "Uygulamada açıldı: $packageName $what")
                return true
            } catch (e: android.content.ActivityNotFoundException) {
                // Uygulamanın ana ekranıyla devam.
            }
        }
        val launch = context.packageManager.getLaunchIntentForPackage(packageName) ?: return false
        context.startActivity(launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        return true
    }

    private val instagramThread = Regex("^thread_shortcut_\\d+_(\\d+)$")

    /**
     * Bildirim bağlantısı olmadan sohbeti açan adres ve ne olduğu (kayıt için):
     * WhatsApp kişisi numarasıyla; Instagram sohbeti kısayol kimliğindeki
     * sohbet numarasıyla ("thread_shortcut_<hesap>_<sohbet>"), o da yoksa
     * mesajlar kutusu (ana akış değil).
     */
    fun chatLink(packageName: String, shortcut: String?): Pair<String, String>? {
        if (packageName.startsWith("com.whatsapp")) {
            val number = shortcut?.removeSuffix("@s.whatsapp.net")?.takeIf { it.isNotEmpty() && it.all(Char::isDigit) }
            return number?.let { "https://wa.me/$it" to "kişi bağlantısı" }
        }
        if (packageName == "com.instagram.android") {
            val thread = shortcut?.let { instagramThread.find(it)?.groupValues?.get(1) }
            return if (thread != null) {
                "https://www.instagram.com/direct/t/$thread/" to "sohbet bağlantısı"
            } else {
                "https://www.instagram.com/direct/inbox/" to "mesajlar kutusu"
            }
        }
        return null
    }

    /**
     * Bu sohbete nasıl gönderilir:
     * - "direct": doğrudan (Telegram/TDLib ya da bildirimin yanıt yolu),
     * - "app": kaynak uygulamada sohbet hazır açılır, kullanıcı orada gönderir
     *   (yanıt yolu yokken: karşı taraf yazmadıysa ya da uygulama yeniden başladıysa),
     * - "web": servisin sayfasından, "none": gönderilemez.
     */
    fun replyMode(context: Context, key: String, packageName: String): String = when {
        TelegramClient.isTelegramKey(key) -> if (TelegramClient.isReady) "direct" else "none"
        WebServices.isWebPackage(packageName) -> "web"
        replyActions.containsKey(key) -> "direct"
        context.packageManager.getLaunchIntentForPackage(packageName) != null -> "app"
        else -> "none"
    }

    fun canReply(key: String) =
        if (TelegramClient.isTelegramKey(key)) TelegramClient.isReady else replyActions.containsKey(key)

    fun notifyChanged(key: String) {
        main.post { onChanged?.invoke(key) }
        appContext?.let(MessagesWidget::refresh)
    }

    @Volatile
    var onTelegramState: (() -> Unit)? = null

    fun notifyTelegramState() {
        main.post { onTelegramState?.invoke() }
    }

    /**
     * Gönderilen yanıtın yerel kaydını çağıran yapmalı mı? Telegram (TDLib)
     * mesajları sunucudan kalıcı kimlikleriyle döner ve öyle kaydedilir.
     */
    fun recordsOwnReplies(key: String) = !TelegramClient.isTelegramKey(key)

    /**
     * Metni gönderir: Telegram sohbetlerinde TDLib ile, diğerlerinde kaynak
     * uygulamanın bildirimindeki "Yanıtla" eylemi üzerinden.
     */
    fun sendReply(context: Context, key: String, text: String, auto: Boolean = false) {
        if (TelegramClient.isTelegramKey(key)) {
            TelegramClient.sendText(key, text, auto)
            return
        }
        val action = replyActions[key] ?: throw NoReplyActionException()
        val inputs = action.remoteInputs?.filter { it.allowFreeFormInput }.orEmpty()
        val pendingIntent = action.actionIntent
        if (inputs.isEmpty() || pendingIntent == null) throw NoReplyActionException()

        val results = Bundle().apply { inputs.forEach { putCharSequence(it.resultKey, text) } }
        val fillIn = Intent().addFlags(Intent.FLAG_RECEIVER_FOREGROUND)
        RemoteInput.addResultsToIntent(inputs.toTypedArray(), fillIn, results)
        try {
            pendingIntent.send(context, 0, fillIn)
        } catch (e: PendingIntent.CanceledException) {
            replyActions.remove(key)
            throw NoReplyActionException(canceled = true)
        }
    }
}
