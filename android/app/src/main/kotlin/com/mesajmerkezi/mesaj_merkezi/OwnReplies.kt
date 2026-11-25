package com.mesajmerkezi.mesaj_merkezi

import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Context
import android.content.Intent
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
 * Otomatik gönderim: yanıt yolu olmayan sohbette (ör. telefon yeniden
 * başladıktan sonra) Mesa mesajı WhatsApp'ta hazır açar ve kullanıcı orada
 * ➤'e basmak zorunda kalıyordu ("Mesa'yı kullanmanın anlamı kalmıyor",
 * 2026-11-26). Servis açıksa Gönder'e kendisi basar ve Mesa'ya döner; yalnızca
 * Mesa'nın az önce açtığı sohbette, başlık ve kutudaki metin birebir
 * tutuyorsa ([shouldAutoSend]).
 *
 * Yalnızca WhatsApp okunur (servis yapılandırması: res/xml/own_replies.xml):
 * mesaj kutusu, Gönder düğmesi, sohbet adı. Metinler günlüğe yazılmaz.
 */
object OwnReplies {
    private const val TAG = "MesajMerkezi"

    /** Ekran öğe kimlikleri WhatsApp ve WhatsApp Business'ta aynı adlarla. */
    val packages = setOf("com.whatsapp", "com.whatsapp.w4b")

    /** Mesa'nın WhatsApp'ta hazır açtığı, servisin göndereceği mesaj. */
    internal data class PendingSend(
        val packageName: String,
        val key: String,
        val title: String,
        val text: String,
        val until: Long,
        /** Gönderince Mesa öne gelsin (balondan gönderilince gelmez). */
        val returnToMesa: Boolean,
    )

    @Volatile
    internal var pendingSend: PendingSend? = null

    /** Gönder'e basılan son mesaj: sohbet → (metin, zaman); ikinci kez kaydedilmez. */
    private val sending = java.util.concurrent.ConcurrentHashMap<String, Pair<String, Long>>()

    /** Gönderildiği doğrulanan son mesaj: sohbet → zaman (Mesa'ya dönüşte sorulur). */
    private val autoSent = java.util.concurrent.ConcurrentHashMap<String, Long>()

    /** Mesa'nın açtığı sohbette bu kadar süre içinde gönderilir. */
    const val AUTO_SEND_WINDOW_MS = 15_000L

    /**
     * Mesa mesajı WhatsApp'ta hazır açmak üzere: servis açıksa göndermeyi üstlenir.
     * @return otomatik gönderilecek
     */
    fun expectSend(context: Context, packageName: String, key: String, text: String, returnToMesa: Boolean): Boolean {
        if (packageName !in packages || !isEnabled(context)) return false
        val clean = text.trim().takeIf { it.isNotEmpty() } ?: return false
        val title = key.substringAfter('|', "").takeIf { it.isNotEmpty() } ?: return false
        pendingSend = PendingSend(
            packageName, key, title, clean,
            until = System.currentTimeMillis() + AUTO_SEND_WINDOW_MS,
            returnToMesa = returnToMesa,
        )
        return true
    }

    /**
     * Ekrandaki WhatsApp sohbeti beklenen mi: aynı uygulama, aynı sohbet adı,
     * kutuda tam olarak Mesa'nın verdiği metin ve süre dolmamış.
     */
    internal fun shouldAutoSend(
        pending: PendingSend,
        packageName: String,
        headerTitle: String?,
        entryText: String?,
        now: Long,
    ): Boolean = now <= pending.until &&
        pending.packageName == packageName &&
        Names.title(headerTitle) == pending.title &&
        entryText?.trim() == pending.text

    /** Servis Gönder'e bastı: Mesa mesajı zaten kaydetti, yakalanınca ikinci kez yazılmasın. */
    internal fun markSending(key: String, text: String) {
        sending[key] = text to System.currentTimeMillis()
    }

    /** Kutu boşaldı, mesaj gitti: Mesa'ya dönünce "gönderildi" denir. */
    internal fun markAutoSent(key: String) {
        autoSent[key] = System.currentTimeMillis()
    }

    /** Dönüşte bir kez sorulur. @return son dakika içinde otomatik gönderildi */
    fun takeAutoSent(key: String): Boolean =
        autoSent.remove(key)?.let { System.currentTimeMillis() - it < 60_000 } == true

    private fun wasAutoSent(key: String, text: String): Boolean =
        sending[key]?.let { it.first == text && System.currentTimeMillis() - it.second < 30_000 } == true

    /** Kullanıcı servisi Android'in Erişilebilirlik ayarından açtı mı. */
    fun isEnabled(context: Context): Boolean {
        val enabled = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
        ) ?: return false
        val component = ComponentName(context, OwnReplyService::class.java)
        return enabled.split(':').any { ComponentName.unflattenFromString(it.trim()) == component }
    }

    /**
     * Erişilebilirlik ayarları. Servisin kendi sayfası (ACCESSIBILITY_DETAILS_SETTINGS)
     * yalnızca sistem ve yükleyici uygulamalara açık; Mesa'dan açılamıyor
     * (2026-11-26, cihazda). Mesa'nın satırı "İndirilen uygulamalar" altında.
     */
    fun openSettings(context: Context) {
        try {
            context.startActivity(
                Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
        } catch (e: ActivityNotFoundException) {
            Log.w(TAG, "Erişilebilirlik ayarları açılamadı")
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
        // Mesa'dan gönderilen mesaj zaten kaydedildi.
        if (wasAutoSent(key, text)) return false
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

    /** Servis, Mesa'nın verdiği metni gönderiyor: boşalan kutu aday olmasın. */
    fun onAutoSend(text: String) {
        draft = null
        pending = null
        lastSent = text to now()
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
