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
 * bildirimde yer almaz; açık sohbete gelen mesajlar için de WhatsApp bildirim
 * göstermez. Mesa'da sohbetler tek taraflı kalıyordu (2026-11-26, kullanıcı
 * bildirdi). İsteğe bağlı erişilebilirlik servisi ([OwnReplyService]) WhatsApp'ta
 * açık sohbetin listesinin en altında beliren yeni mesajları (gönderilen ve
 * gelen) Mesa'daki aynı sohbete ekler; sohbet Mesa'da yoksa açar. WhatsApp'ta
 * açılan sohbet Mesa'da da okunmuş sayılır.
 *
 * Otomatik gönderim: yanıt yolu olmayan sohbette (ör. telefon yeniden
 * başladıktan sonra) Mesa mesajı WhatsApp'ta hazır açar ve kullanıcı orada
 * ➤'e basmak zorunda kalıyordu ("Mesa'yı kullanmanın anlamı kalmıyor",
 * 2026-11-26). Kullanıcı Mesa'dan hiç çıkmamalı: servis açıksa ekran
 * "Gönderiliyor…" örtüsüyle kapanır, WhatsApp altta açılır, servis kutuyu
 * doldurup Gönder'e basar ve Mesa'ya döner. Yalnızca Mesa'nın az önce
 * açtığı sohbette, başlık birebir tutuyorsa ([autoSendStep]).
 *
 * Yalnızca WhatsApp okunur (servis yapılandırması: res/xml/own_replies.xml):
 * mesaj kutusu, Gönder düğmesi, sohbet adı. Metinler günlüğe yazılmaz.
 */
object OwnReplies {
    private const val TAG = "MesajMerkezi"

    /** Ekran öğe kimlikleri WhatsApp ve WhatsApp Business'ta aynı adlarla. */
    val packages = setOf("com.whatsapp", "com.whatsapp.w4b")

    /** WhatsApp sohbet listesinde görülen bir mesaj satırı (yalnızca metinli satırlar). */
    data class ChatRow(val text: String, val outgoing: Boolean, val sender: String?)

    /**
     * Listenin en altında yeni beliren satırların başladığı yer. [known] bir
     * önceki bakıştaki satırların imzaları, [current] şimdiki (ikisi de
     * yukarıdan aşağı). Önceki bakışın sonu şimdikinde en uzun eşleşmeyle
     * aranır; aynı metin art arda gönderilse de yeni satır kaçmaz.
     * [knownIsBaseline]: önceki bakış boştu ve sohbet gerçekten boş (yeni
     * sohbet): şimdiki satırların hepsi yeni.
     * @return yeni satırların ilk sırası; yeni satır yoksa [current] boyu
     */
    internal fun firstNewRow(known: List<String>, current: List<String>, knownIsBaseline: Boolean): Int {
        if (current.isEmpty()) return 0
        if (known.isEmpty()) return if (knownIsBaseline) 0 else current.size
        var best = -1
        var bestLength = 0
        for (p in current.indices.reversed()) {
            var length = 0
            while (length < known.size && p - length >= 0 &&
                current[p - length] == known[known.size - 1 - length]
            ) {
                length++
            }
            if (length > bestLength) {
                bestLength = length
                best = p
            }
        }
        // Önceki bakışın hiçbir satırı görünmüyor: liste değişti; yeni sayılmaz.
        return if (best >= 0) best + 1 else current.size
    }

    /**
     * Hub.io'da çağrılır. WhatsApp'ta açık sohbette yeni beliren satırları
     * Mesa'daki aynı sohbete ekler; sohbet yoksa açılır. Kullanıcı sohbeti
     * WhatsApp'ta görmekte: okunmuş sayılır, bildirim gösterilmez, kurallar
     * çalışmaz. Aynı mesajın ikinci kopyası (Mesa'dan gönderilen ya da
     * bildirimden gelen) deponun yineleme denetimine takılır.
     * @return eklenen mesaj sayısı
     */
    fun recordRows(
        context: Context,
        packageName: String,
        chatTitle: String,
        isGroup: Boolean,
        rows: List<ChatRow>,
    ): Int {
        if (rows.isEmpty() || !AppSettings.isCaptured(context, packageName)) return 0
        val title = Names.title(chatTitle) ?: return 0
        val key = "$packageName|$title"
        val now = System.currentTimeMillis()
        val messages = rows
            // Mesa'nın az önce WhatsApp'ta gönderdiği mesaj zaten kayıtlı.
            .filterNot { it.outgoing && wasAutoSent(key, it.text) }
            .mapIndexed { i, row ->
                CapturedMessage(
                    sender = if (row.outgoing) null else row.sender ?: title.takeUnless { isGroup },
                    text = row.text,
                    // Aynı anda görülen satırların sırası korunur.
                    time = now + i,
                    outgoing = row.outgoing,
                    // Gelen satırın zamanı tahmini: bildirimden gelmiş kopyasıyla metin ve göndericiden eşleşir.
                    fromFallback = !row.outgoing,
                )
            }
        if (messages.isEmpty()) return 0
        val store = Hub.store(context)
        val created = store.conversation(key) == null
        val result = store.ingest(
            CapturedConversation(key, packageName, title, isGroup, messages, replyAction = null),
        )
        if (result.added == 0) return 0
        store.markRead(key)
        UnifiedNotifier.cancel(context, key)
        Hub.notifyChanged(key)
        Log.i(
            TAG,
            "WhatsApp'ta açık sohbetten ${result.added} mesaj Mesa'ya eklendi" +
                if (created) " (sohbet Mesa'da yeni açıldı)" else "",
        )
        return result.added
    }

    /** Mesa'nın WhatsApp'ta hazır açtığı, servisin göndereceği mesaj. */
    internal data class PendingSend(
        val packageName: String,
        val key: String,
        val title: String,
        val text: String,
        val until: Long,
        /** Gönderince Mesa öne gelsin. */
        val returnToMesa: Boolean,
    )

    /** Ekrandaki WhatsApp için sıradaki adım. */
    internal enum class Step {
        /** Doğru sohbet henüz ekranda değil. */
        WAIT,

        /** Süre doldu; gönderilmedi. */
        EXPIRED,

        /** Doğru sohbet ama kutuda başka metin: kutu Mesa'nın metniyle doldurulur. */
        FILL,

        /** Kutuda tam olarak Mesa'nın metni: Gönder'e basılır. */
        PRESS,
    }

    @Volatile
    internal var pendingSend: PendingSend? = null

    /** Gönder'e basılan son mesaj: sohbet → (metin, zaman); ikinci kez kaydedilmez. */
    private val sending = java.util.concurrent.ConcurrentHashMap<String, Pair<String, Long>>()

    /** Otomatik gönderimin sonucu: sohbet → (gitti mi, zaman); Mesa'ya dönüşte sorulur. */
    private val results = java.util.concurrent.ConcurrentHashMap<String, Pair<Boolean, Long>>()

    /** Mesa'nın açtığı sohbette bu kadar süre içinde gönderilir; örtü de en fazla bu kadar kalır. */
    const val AUTO_SEND_WINDOW_MS = 10_000L

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
     * Ekrandaki WhatsApp için sıradaki adım. Güvenlik şartı sohbet adıdır:
     * yalnızca Mesa'nın açtığı sohbette (aynı uygulama, aynı ad) kutuya
     * yazılır ya da Gönder'e basılır.
     */
    internal fun autoSendStep(
        pending: PendingSend,
        packageName: String,
        headerTitle: String?,
        entryText: String?,
        now: Long,
    ): Step = when {
        now > pending.until -> Step.EXPIRED
        pending.packageName != packageName || Names.title(headerTitle) != pending.title -> Step.WAIT
        entryText == null -> Step.WAIT
        entryText.trim() == pending.text -> Step.PRESS
        else -> Step.FILL
    }

    /** Servis Gönder'e bastı: Mesa mesajı zaten kaydetti, yakalanınca ikinci kez yazılmasın. */
    internal fun markSending(key: String, text: String) {
        sending[key] = text to System.currentTimeMillis()
    }

    /** Gönderilemedi: Mesa kaydını sildi; kullanıcı WhatsApp'tan gönderirse kaydedilsin. */
    internal fun clearSending(key: String) {
        sending.remove(key)
    }

    /**
     * Mesaj metinleri karşılaştırılabilir hale gelir: WhatsApp balondaki
     * metnin sonuna saat için görünmez boşluklar ekleyebiliyor; biçim
     * karakterleri (U+200B…, U+2060…, U+FEFF) atılır, boşluklar sadeleşir.
     * Emoji birleştiricisi (U+200D) korunur.
     */
    internal fun normalize(text: CharSequence?): String {
        if (text == null) return ""
        val visible = buildString(text.length) {
            for (c in text) {
                when {
                    c == '\u200D' -> append(c)
                    Character.getType(c) == Character.FORMAT.toInt() -> Unit
                    Character.isSpaceChar(c) || c.isWhitespace() -> append(' ')
                    else -> append(c)
                }
            }
        }
        return visible.replace(Regex(" +"), " ").trim()
    }

    /** İki metin aynı mesaj mı ([normalize] ile). */
    internal fun sameMessage(a: CharSequence?, b: CharSequence?): Boolean {
        val x = normalize(a)
        return x.isNotEmpty() && x == normalize(b)
    }

    /** Otomatik gönderim bitti: Mesa'ya dönünce "gönderildi" ya da "gönderilemedi" denir. */
    internal fun markResult(key: String, sent: Boolean) {
        results[key] = sent to System.currentTimeMillis()
    }

    /** Dönüşte bir kez sorulur. @return "sent", "failed" ya da (son dakikada yoksa) null */
    fun takeResult(key: String): String? =
        results.remove(key)
            ?.takeIf { System.currentTimeMillis() - it.second < 60_000 }
            ?.let { if (it.first) "sent" else "failed" }

    private fun wasAutoSent(key: String, text: String): Boolean =
        sending[key]?.let { sameMessage(it.first, text) && System.currentTimeMillis() - it.second < 30_000 } == true

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

    /** Sohbet başlığı bildirimdekiyle aynı biçimde sadeleştirilir (görünmez yön işaretleri vb.). */
    internal fun knownKey(store: MessageStore, packageName: String, chatTitle: String): String? {
        val title = Names.title(chatTitle) ?: return null
        return "$packageName|$title".takeIf { store.conversation(it) != null }
    }
}
