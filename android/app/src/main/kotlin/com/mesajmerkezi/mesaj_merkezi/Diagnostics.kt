package com.mesajmerkezi.mesaj_merkezi

import android.app.Notification
import android.content.Context
import android.graphics.BitmapFactory
import android.net.Uri
import android.service.notification.StatusBarNotification
import android.util.Log
import androidx.core.app.NotificationCompat
import java.security.MessageDigest

/**
 * Bildirimlerin ham yapısını ve ayrıştırıcının kararını logcat'e yazar.
 * Yeni bir uygulamanın bildirim biçimini anlamak için kullanılır.
 *
 * Varsayılan KAPALI; yalnızca adb ile açılır:
 *   adb shell setprop log.tag.MesajMerkezi DEBUG
 *   adb logcat -s MesajMerkezi
 * Kapatmak: adb shell setprop log.tag.MesajMerkezi INFO
 *
 * Mesaj metni, kişi/sohbet adları ve telefon numaraları yazılmaz; yalnızca
 * uzunluğu ve kısa bir özeti (aynı ad/metin mi diye karşılaştırmak için).
 * Adlardaki görünmez biçim karakterleri (<U+200E>) ayrıca yazılır: anahtar
 * bölünmelerini görmek için. Logcat'i telefona bağlı bilgisayar okuyabilir.
 */
object Diagnostics {

    private const val TAG = "MesajMerkezi"

    val enabled: Boolean get() = Log.isLoggable(TAG, Log.DEBUG)

    fun log(context: Context, sbn: StatusBarNotification, supported: Boolean, parsed: CapturedConversation?) {
        val n = sbn.notification
        val extras = n.extras
        val style = NotificationCompat.MessagingStyle.extractMessagingStyleFromNotification(n)
        val actions = (0 until NotificationCompat.getActionCount(n))
            .mapNotNull { NotificationCompat.getAction(n, it) }
        val hasInput = actions.any { a -> a.remoteInputs?.isNotEmpty() == true }

        // Listede olmayan paketlerden yalnızca mesaja benzeyenler: yanlış paket adını yakalamak için.
        if (!supported && style == null && !hasInput && n.category != Notification.CATEGORY_MESSAGE) return

        val report = buildString {
            append("── ${sbn.packageName} supported=$supported id=${sbn.id} tag=${fingerprint(sbn.tag)}\n")
            append("   flags=0x${Integer.toHexString(n.flags)}")
            append(" summary=${n.flags and Notification.FLAG_GROUP_SUMMARY != 0}")
            append(" group=${n.group} category=${n.category}")
            append(" channel=${NotificationCompat.getChannelId(n)}")
            append(" when=${n.`when`} post=${sbn.postTime}\n")
            append("   template=${extras.getString(Notification.EXTRA_TEMPLATE)}")
            append(" title=${name(extras.getCharSequence(Notification.EXTRA_TITLE))}")
            append(" text=${fingerprint(extras.getCharSequence(Notification.EXTRA_TEXT))}")
            append(" bigText=${fingerprint(extras.getCharSequence(Notification.EXTRA_BIG_TEXT))}\n")
            if (style != null) {
                append("   style: convTitle=${name(style.conversationTitle)} group=${style.isGroupConversation}")
                append(" user=${name(style.user.name)} messages=${style.messages.size}\n")
                for (m in style.messages) {
                    append("     · sender=${name(m.person?.name)} time=${m.timestamp} text=${fingerprint(m.text)}")
                    append(" data=${m.dataMimeType}${if (m.dataUri != null) "+uri" + imageSize(context, m.dataUri) else ""}\n")
                }
            } else {
                append("   style: YOK\n")
            }
            append("   actions=")
            append(actions.joinToString { a ->
                val inputs = a.remoteInputs.orEmpty()
                "${a.title}(semantic=${a.semanticAction}, inputs=${inputs.size}, " +
                    "freeForm=${inputs.any { it.allowFreeFormInput }})"
            })
            append("\n   → ")
            append(
                when {
                    !supported -> "ATLANDI (paket listede yok)"
                    parsed == null -> "REDDEDİLDİ"
                    else -> "KABUL key=${parsed.packageName}|${name(parsed.key.substringAfter('|'))} " +
                        "messages=${parsed.messages.size} " +
                        "fallback=${parsed.messages.any { it.fromFallback }} reply=${parsed.replyAction != null}"
                }
            )
        }
        Log.d(TAG, report)
    }

    /**
     * Ad yerine özeti; içindeki görünmez biçim karakterleri <U+200E> gibi
     * öne yazılır (başlık bölünmelerini görmek için).
     */
    private fun name(text: CharSequence?): String {
        if (text == null) return "null"
        val marks = text.filter { Character.getType(it) == Character.FORMAT.toInt() }
            .map { "<U+%04X>".format(it.code) }
            .joinToString("")
        return marks + fingerprint(text)
    }

    /** Görselin piksel boyutu (yalnızca başlığı okunur); okunamazsa sebebi. */
    private fun imageSize(context: Context, uri: Uri?): String {
        if (uri == null) return ""
        return try {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            context.contentResolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, bounds) }
            " ${bounds.outWidth}x${bounds.outHeight}"
        } catch (e: Exception) {
            " (okunamadı: ${e.javaClass.simpleName})"
        }
    }

    private fun fingerprint(text: CharSequence?): String {
        if (text == null) return "null"
        val digest = MessageDigest.getInstance("SHA-1").digest(text.toString().toByteArray())
        val short = digest.take(3).joinToString("") { "%02x".format(it) }
        return "[${text.length} kr #$short]"
    }
}
