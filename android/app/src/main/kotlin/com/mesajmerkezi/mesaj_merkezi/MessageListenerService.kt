package com.mesajmerkezi.mesaj_merkezi

import android.app.Notification
import android.content.ComponentName
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * Kullanıcı "Bildirim erişimi" verdiğinde sistem bu servisi bağlar; uygulama
 * arayüzü kapalıyken de mesajları yakalar.
 */
class MessageListenerService : NotificationListenerService() {

    override fun onListenerDisconnected() {
        Hub.setListenerConnected(false)
        instance = null
        // Sistem bağlantıyı kendiliğinden yeniden kurmayabiliyor.
        requestRebind(ComponentName(this, MessageListenerService::class.java))
    }

    override fun onListenerConnected() {
        Hub.setListenerConnected(true)
        instance = this
        // Servis bağlanmadan önce gelmiş ve hâlâ duran bildirimleri de topla.
        val active = try {
            activeNotifications
        } catch (e: SecurityException) {
            null
        }
        active?.forEach(::handle)
        Log.i(TAG, "Bildirim servisi bağlandı: ${Hub.replyPathCount()} sohbette yanıt yolu var")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) = handle(sbn)

    /**
     * Çubukta duran bildirimleri yeniden işler. Birleşik bildirimler açılınca
     * var olan kaynak bildirimleri hemen Mesa bildirimine dönüşsün diye.
     */
    private fun reprocessActive() {
        val active = try {
            activeNotifications
        } catch (e: SecurityException) {
            null
        }
        active?.forEach(::handle)
    }

    private fun handle(sbn: StatusBarNotification) {
        val supported = sbn.packageName in SupportedApps.packages
        if (!supported) {
            if (Diagnostics.enabled) diagnose(sbn, supported = false, parsed = null)
            return
        }
        // Beğeni, takip, arama vb. Sohbetler'e girmez; kaynak bildirimi de olduğu gibi kalır.
        val n = sbn.notification
        val hasStyle = NotificationCompat.MessagingStyle.extractMessagingStyleFromNotification(n) != null
        val isMessage = MessageFilter.isMessage(n.category, hasStyle, NotificationCompat.getChannelId(n))
        val unified = AppSettings.unifiedNotifications(this)
        // Birleşik bildirimlerde kaynak uygulamanın "3 sohbetten 5 mesaj" özeti de kalkar.
        if (unified && n.flags and Notification.FLAG_GROUP_SUMMARY != 0 &&
            AppSettings.isCaptured(this, sbn.packageName)
        ) {
            if (isMessage && !AppSettings.keepsSource(this, sbn.packageName)) cancelNotification(sbn.key)
            return
        }
        // Telegram hesabı TDLib ile bağlıyken mesajlar oradan gelir; bildirimi
        // de kaydetmek aynı mesajı farklı anahtarla ikinci kez yazardı.
        if (sbn.packageName in SupportedApps.telegramPackages && TelegramPrefs.loggedIn(this)) {
            // Mesajlar TDLib'den gelir ve bildirimi oradan gösterilir.
            if (unified && sbn.notification.category == Notification.CATEGORY_MESSAGE) cancelNotification(sbn.key)
            return
        }
        // Kullanıcı bu uygulamanın okunmasını ayarlardan kapattı.
        if (!AppSettings.isCaptured(this, sbn.packageName)) return
        if (!isMessage) {
            if (Diagnostics.enabled) Log.d(TAG, "Mesaj değil, atlandı: ${sbn.packageName} kanal=${NotificationCompat.getChannelId(n)}")
            return
        }
        val conversation = try {
            NotificationParser.parse(sbn)
        } catch (e: RuntimeException) {
            // Uygulamaların bildirim biçimi habersiz değişebilir; tek bir bozuk
            // bildirim servisi düşürmemeli.
            Log.w(TAG, "Bildirim ayrıştırılamadı: ${sbn.packageName}", e)
            null
        }
        if (Diagnostics.enabled) diagnose(sbn, supported = true, parsed = conversation)
        if (conversation == null) return

        conversation.replyAction?.let { Hub.rememberReply(conversation.key, it) }
        sbn.notification.contentIntent?.let { Hub.rememberOpen(conversation.key, it) }
        val style = NotificationCompat.MessagingStyle.extractMessagingStyleFromNotification(sbn.notification)
        Hub.io.execute {
            Maintenance.purgeIfDue(this)
            Maintenance.cleanCachesIfDue(this)
            val store = Hub.store(this)
            val result = store.ingest(conversation)
            for ((messageId, message) in result.pendingMedia) {
                val path = MediaCache.copyFromNotification(
                    this,
                    message.mediaUri!!,
                    message.mediaMime,
                    messageId,
                    source = sbn.packageName,
                )
                if (path != null) store.setMedia(messageId, path, message.mediaMime)
            }
            AvatarCache.saveFromNotification(this, conversation.key, sbn.notification, style)
                ?.let { store.setAvatar(conversation.key, it) }
            var fired = emptySet<RuleAction>()
            if (result.newIncoming.isNotEmpty()) {
                fired = try {
                    RuleRunner.run(this, store, conversation, result.newIncoming)
                } catch (e: RuntimeException) {
                    Log.w(TAG, "Kurallar uygulanamadı: ${conversation.packageName}", e)
                    emptySet()
                }
            }
            // Kaynak bildirim, içindeki görseller kopyalandıktan sonra kaldırılır
            // (bildirim kalkınca görsel URI'sine erişim de biter).
            if (unified) {
                // Kullanıcı istediyse kaynak bildirim kalır (yanıt yolu yeniden
                // başlayınca geri alınsın); sessize alınan sohbette yine kalkar.
                val keepSource = AppSettings.keepsSource(this, sbn.packageName) && RuleAction.MUTE !in fired
                if (keepSource) {
                    Log.i(TAG, "Birleşik: ${sbn.packageName} bildirimi korundu")
                } else {
                    cancelNotification(sbn.key)
                    Log.i(TAG, "Birleşik: ${sbn.packageName} bildirimi kaldırıldı")
                }
                // Sessize alınan ya da zaten okunmuş sohbet bildirim göstermez.
                val unread = (store.conversation(conversation.key)?.get("unread") as Int?) ?: 0
                if (RuleAction.MUTE !in fired && unread > 0) {
                    UnifiedNotifier.show(
                        this,
                        conversation.key,
                        // Kaynak bildirim zaten çaldı; ikinci kez çalmasın.
                        alert = result.newIncoming.isNotEmpty() && !keepSource,
                        important = RuleAction.IMPORTANT in fired,
                    )
                }
            }
            if (result.added > 0 || conversation.replyAction != null) {
                Hub.notifyChanged(conversation.key)
            }
        }
    }

    private fun diagnose(sbn: StatusBarNotification, supported: Boolean, parsed: CapturedConversation?) {
        try {
            Diagnostics.log(this, sbn, supported, parsed)
        } catch (e: RuntimeException) {
            Log.w(TAG, "Tanılama yazılamadı: ${sbn.packageName}", e)
        }
    }

    companion object {
        private const val TAG = "MesajMerkezi"

        @Volatile
        private var instance: MessageListenerService? = null

        /** Servis bağlıysa çubuktaki bildirimleri yeniden işler. */
        fun reprocessActiveNotifications() {
            instance?.reprocessActive()
        }
    }
}
