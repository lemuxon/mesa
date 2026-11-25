package com.mesajmerkezi.mesaj_merkezi

import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.util.Log

/**
 * "WhatsApp'ta yazdıklarım da görünsün": kullanıcı WhatsApp'ı açıp oradan
 * yanıt verince WhatsApp bildirimini yalnızca kaldırır, yazılan metin hiçbir
 * bildirimde yer almaz. Mesa'da sohbet tek taraflı kalıyordu (2026-11-26,
 * kullanıcı bildirdi). İsteğe bağlı erişilebilirlik servisi ([OwnReplyService])
 * WhatsApp'ta Gönder'e basılınca metni Mesa'daki aynı sohbete ekler ve
 * WhatsApp'ta açılan sohbeti okundu sayar.
 *
 * Yalnızca WhatsApp okunur (servis yapılandırması: res/xml/own_replies.xml):
 * mesaj kutusu, Gönder düğmesi, sohbet adı. Metinler günlüğe yazılmaz.
 */
object OwnReplies {
    private const val TAG = "MesajMerkezi"

    /** Ekran öğe kimlikleri WhatsApp ve WhatsApp Business'ta aynı adlarla. */
    val packages = setOf("com.whatsapp", "com.whatsapp.w4b")

    /** Kullanıcı servisi Android'in Erişilebilirlik ayarından açtı mı. */
    fun isEnabled(context: Context): Boolean {
        val enabled = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
        ) ?: return false
        val component = ComponentName(context, OwnReplyService::class.java)
        return enabled.split(':').any { ComponentName.unflattenFromString(it.trim()) == component }
    }

    /** Servisin ayar sayfası; açılamazsa Erişilebilirlik ayarlarının tamamı. */
    fun openSettings(context: Context) {
        val component = ComponentName(context, OwnReplyService::class.java)
        // Android 12+: servisin kendi sayfası. SDK'da gizli sabit; yalnızca
        // servisin sahibi uygulama açabilir, açılamazsa genel sayfaya düşülür.
        val details = if (Build.VERSION.SDK_INT >= 31) {
            Intent("android.settings.ACCESSIBILITY_DETAILS_SETTINGS")
                .putExtra(Intent.EXTRA_COMPONENT_NAME, component.flattenToString())
        } else {
            null
        }
        for (intent in listOfNotNull(details, Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))) {
            try {
                context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                return
            } catch (e: ActivityNotFoundException) {
                continue
            } catch (e: SecurityException) {
                continue
            }
        }
    }

    /**
     * Hub.io'da çağrılır. WhatsApp'ta gönderilen metni, sohbet Mesa'da
     * varsa giden mesaj olarak ekler; sohbet okunmuş sayılır.
     * @return sohbet bulundu ve mesaj eklendi
     */
    fun record(context: Context, packageName: String, chatTitle: String, text: String): Boolean {
        if (!AppSettings.isCaptured(context, packageName)) return false
        val store = Hub.store(context)
        val key = knownKey(store, packageName, chatTitle) ?: run {
            Log.i(TAG, "WhatsApp yanıtı: sohbet Mesa'da yok, eklenmedi")
            return false
        }
        store.recordOutgoing(key, text)
        store.markRead(key)
        UnifiedNotifier.cancel(context, key)
        Hub.notifyChanged(key)
        Log.i(TAG, "WhatsApp'ta yazılan yanıt Mesa'ya eklendi")
        return true
    }

    /**
     * Hub.io'da çağrılır. Sohbet WhatsApp'ta açıldı: Mesa'da da okunmuş sayılır.
     * @return okunmamış mesajı vardı ve okundu yapıldı
     */
    fun opened(context: Context, packageName: String, chatTitle: String): Boolean {
        if (!AppSettings.isCaptured(context, packageName)) return false
        val store = Hub.store(context)
        val key = knownKey(store, packageName, chatTitle) ?: return false
        val unread = (store.conversation(key)?.get("unread") as Int?) ?: 0
        if (unread == 0) return false
        store.markRead(key)
        UnifiedNotifier.cancel(context, key)
        Hub.notifyChanged(key)
        return true
    }

    /**
     * Sohbet başlığı bildirimdekiyle aynı biçimde sadeleştirilir (görünmez
     * yön işaretleri vb.). Mesa'da olmayan sohbet açılmaz: WhatsApp'ta
     * yazılan her sohbet gelen kutusuna dolmasın.
     */
    internal fun knownKey(store: MessageStore, packageName: String, chatTitle: String): String? {
        val title = Names.title(chatTitle) ?: return null
        return "$packageName|$title".takeIf { store.conversation(it) != null }
    }
}

/**
 * Mesaj kutusundaki metni izleyip gönderimi tanır. Android'e bağımlı değildir.
 *
 * İki yol var: Gönder düğmesine dokunma (kesin) ve klavyedeki Enter ile
 * gönderim. İkincisinde yalnızca kutunun bir anda boşaldığı görülür;
 * hepsini seçip silmekle karışmasın diye metnin sohbet listesinde
 * belirdiği ayrıca doğrulanır ([onVerified]).
 */
internal class ReplyTracker(private val now: () -> Long = System::currentTimeMillis) {
    private var draft: String? = null
    private var pending: Pair<String, Long>? = null
    private var lastSent: Pair<String, Long>? = null

    /**
     * Mesaj kutusunun metni değişti.
     * @return kutu bir anda boşaldı: doğrulanması gereken aday metin
     */
    fun onTextChanged(text: String, before: String?, removed: Int, added: Int): String? {
        if (text.isNotBlank()) {
            draft = text
            pending = null
            return null
        }
        val previousRaw = before?.takeIf { it.isNotBlank() } ?: draft
        draft = null
        val previous = previousRaw?.trim()?.takeIf { it.isNotEmpty() } ?: return null
        // Harf harf silmek gönderim değildir: gönderince kutu tek seferde boşalır.
        if (added != 0 || removed < previousRaw.length) return null
        // Gönder'e basıldı, ardından kutu boşaldı: zaten kaydedildi.
        val sent = lastSent
        if (sent != null && sent.first == previous && now() - sent.second < SAME_SEND_MS) return null
        pending = previous to now()
        return previous
    }

    /** Gönder düğmesine dokunuldu. @return kaydedilecek metin */
    fun onSendClicked(): String? {
        val text = draft?.trim()?.takeIf { it.isNotEmpty() }
            ?: pending?.takeIf { now() - it.second < SAME_SEND_MS }?.first
            ?: return null
        draft = null
        pending = null
        lastSent = text to now()
        return text
    }

    /**
     * Boşalan kutunun metni sohbet listesinde arandı.
     * @return kaydedilmeli (aday hâlâ bekliyor ve listede göründü)
     */
    fun onVerified(text: String, shownInList: Boolean): Boolean {
        val candidate = pending ?: return false
        if (candidate.first != text) return false
        pending = null
        if (!shownInList) return false
        lastSent = text to now()
        return true
    }

    /** Ekran değişti: yarım kalan taslak başka sohbete taşınmasın. */
    fun reset() {
        draft = null
        pending = null
    }

    companion object {
        /** Dokunma ile kutunun boşalması arasındaki en uzun süre. */
        const val SAME_SEND_MS = 2_000L
    }
}
