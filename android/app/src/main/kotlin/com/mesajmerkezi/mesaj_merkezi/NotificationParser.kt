package com.mesajmerkezi.mesaj_merkezi

import android.app.Notification
import android.service.notification.StatusBarNotification
import androidx.core.app.NotificationCompat

data class CapturedMessage(
    val sender: String?,
    val text: String,
    val time: Long,
    val outgoing: Boolean,
    /** MessagingStyle yoksa düz başlık/metinden üretildi; zaman damgası güvenilmez. */
    val fromFallback: Boolean,
    /**
     * Kaynağın verdiği kalıcı kimlik (TDLib: "tg-<sohbet>-<mesaj>"). Varsa
     * tekrar ayıklaması yalnızca buna dayanır; yoksa içerikten özet üretilir.
     */
    val id: String? = null,
    /** Bir otomatik yanıt kuralı tarafından gönderildi. */
    val auto: Boolean = false,
    /** Görsel içeriğin türü (image/webp çıkartma, image/gif, image/jpeg…). */
    val mediaMime: String? = null,
    /** Bildirimin taşıdığı içerik URI'si; kayıttan sonra uygulamaya kopyalanır. */
    val mediaUri: String? = null,
    /** photo, video, animation, sticker; bilinmiyorsa null. */
    val mediaKind: String? = null,
    /** Tam boy dosyanın kaynağı (Telegram: "tdlib-remote:<id>"); bildirimlerde yok. */
    val mediaRef: String? = null,
    /** Videonun, GIF'in ya da sesin süresi (saniye); bilinmiyorsa null. */
    val mediaDuration: Int? = null,
    /** Tam boy dosyanın boyutu (bayt); bilinmiyorsa null. */
    val mediaSize: Long? = null,
    /** Bizim gönderdiğimiz mesajın durumu (Telegram): [SendState]. */
    val sendState: Int = SendState.SENT,
    /** Gönderilemediyse sebebi. */
    val sendError: String? = null,
)

/** Uygulamadan gönderilen mesajın durumu (yalnızca Telegram bildirir). */
object SendState {
    const val SENT = 0
    const val PENDING = 1
    const val FAILED = 2
}

data class CapturedConversation(
    val key: String,
    val packageName: String,
    val title: String,
    val isGroup: Boolean,
    val messages: List<CapturedMessage>,
    val replyAction: NotificationCompat.Action?,
    /**
     * Uygulamanın bu sohbet için yayınladığı kısayol (WhatsApp: "905…@s.whatsapp.net").
     * Kalıcıdır: bildirim gidince ya da süreç yeniden başlayınca da o sohbete
     * paylaşım (metin, fotoğraf, video, ses) yapılabilir.
     */
    val shortcutId: String? = null,
)

/** Mesajlaşma uygulamalarının bildirimlerini sohbet + mesaj listesine çevirir. */
object NotificationParser {

    fun parse(sbn: StatusBarNotification): CapturedConversation? {
        val n = sbn.notification
        if (n.flags and Notification.FLAG_GROUP_SUMMARY != 0) return null
        if (n.flags and Notification.FLAG_ONGOING_EVENT != 0) return null

        val extras = n.extras
        val replyAction = findReplyAction(n)
        val style = NotificationCompat.MessagingStyle.extractMessagingStyleFromNotification(n)

        if (style != null) {
            val userName = Names.normalize(style.user.name)
            val messages = style.messages.mapNotNull { m ->
                val mime = m.dataMimeType?.takeIf { m.dataUri != null }
                // Çıkartma ve fotoğraflarda metin boş gelebilir; içerik türünden etiket üretilir.
                val text = m.text?.toString()?.takeIf { it.isNotBlank() }
                    ?: mime?.let(::mediaLabel)
                    ?: return@mapNotNull null
                val senderName = Names.normalize(m.person?.name)
                CapturedMessage(
                    sender = senderName,
                    text = text,
                    time = m.timestamp,
                    // Kullanıcının kendi mesajlarında gönderen boş ya da kullanıcının kendisidir.
                    outgoing = senderName == null || senderName == userName,
                    fromFallback = false,
                    mediaMime = mime,
                    mediaUri = mime?.let { m.dataUri?.toString() },
                    mediaKind = mime?.let(::mediaKind),
                )
            }
            if (messages.isEmpty()) return null
            val title = Names.conversationTitle(
                conversationTitle = style.conversationTitle,
                notificationTitle = extras.getCharSequence(Notification.EXTRA_TITLE),
                isGroup = style.isGroupConversation,
                lastIncomingSender = messages.lastOrNull { !it.outgoing }?.sender,
                userName = userName,
            ) ?: return null
            return CapturedConversation(
                key = conversationKey(sbn.packageName, title),
                packageName = sbn.packageName,
                title = title,
                isGroup = style.isGroupConversation,
                messages = messages,
                replyAction = replyAction,
                shortcutId = NotificationCompat.getShortcutId(n),
            )
        }

        // MessagingStyle yoksa yalnızca mesaj olduğu belli olan bildirimleri al;
        // "gönderini beğendi", "WhatsApp Web etkin" gibi bildirimler sohbet değildir.
        if (replyAction == null && n.category != Notification.CATEGORY_MESSAGE) return null
        val title = Names.title(extras.getCharSequence(Notification.EXTRA_TITLE)) ?: return null
        val text = (extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
            ?: extras.getCharSequence(Notification.EXTRA_TEXT))
            ?.toString()?.takeIf { it.isNotBlank() } ?: return null
        val time = if (n.`when` > 0) n.`when` else sbn.postTime
        return CapturedConversation(
            key = conversationKey(sbn.packageName, title),
            packageName = sbn.packageName,
            title = title,
            isGroup = false,
            messages = listOf(CapturedMessage(title, text, time, outgoing = false, fromFallback = true)),
            replyAction = replyAction,
            shortcutId = NotificationCompat.getShortcutId(n),
        )
    }

    private fun conversationKey(packageName: String, title: String) = "$packageName|$title"

    fun mediaKind(mime: String): String? = when {
        mime == "image/webp" -> "sticker"
        mime.startsWith("image/") -> "photo"
        mime.startsWith("video/") -> "video"
        else -> null
    }

    /** Metni olmayan görsel mesajın etiketi. WhatsApp çıkartmaları webp'dir. */
    fun mediaLabel(mime: String): String? = when {
        mime == "image/webp" -> "Çıkartma"
        mime == "image/gif" -> "GIF"
        mime.startsWith("image/") -> "📷 Fotoğraf"
        mime.startsWith("video/") -> "🎥 Video"
        mime.startsWith("audio/") -> "🎤 Ses"
        else -> null
    }

    /** Serbest metin kabul eden ilk yanıt eylemi; "Yanıtla" anlamlı olan tercih edilir. */
    private fun findReplyAction(n: Notification): NotificationCompat.Action? {
        val actions = (0 until NotificationCompat.getActionCount(n))
            .mapNotNull { NotificationCompat.getAction(n, it) } +
            NotificationCompat.WearableExtender(n).actions
        val replyable = actions.filter { a ->
            a.actionIntent != null && a.remoteInputs?.any { it.allowFreeFormInput } == true
        }
        return replyable.firstOrNull { it.semanticAction == NotificationCompat.Action.SEMANTIC_ACTION_REPLY }
            ?: replyable.firstOrNull()
    }
}
