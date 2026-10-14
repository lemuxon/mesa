package com.mesajmerkezi.mesaj_merkezi

/**
 * Sohbet başlıklarını ve gönderen adlarını karşılaştırılabilir hale getirir.
 * Android'e bağımlı değildir.
 *
 * WhatsApp aynı grubun adını bazı bildirimlerde U+200E (soldan sağa işareti)
 * ile başlatıyor, bazılarında başlatmıyor. Bu görünmez fark sohbet
 * anahtarını bölüyor ve aynı mesajlar iki ayrı sohbete düşüyordu
 * (2026-10-09, gerçek cihazda bir WhatsApp grubunda).
 */
object Names {

    // "Ali (3 mesaj)", "Aile (2 new messages)" gibi sayaç ekleri.
    private val counterSuffix = Regex("""\s*\(\d+[^)]*\)\s*$""")
    private val whitespace = Regex("""\s+""")

    /**
     * Görünmez biçim karakterlerini (Unicode Cf: yön işaretleri, yön
     * yalıtıcıları, sıfır genişlikli boşluk, BOM) atar, boşlukları sadeleştirir.
     * U+200D (birleştirici) korunur; aile/meslek emojileri ona dayanır.
     */
    fun normalize(raw: CharSequence?): String? {
        if (raw == null) return null
        val visible = buildString(raw.length) {
            for (c in raw) {
                if (c != ZERO_WIDTH_JOINER && Character.getType(c) == Character.FORMAT.toInt()) continue
                append(c)
            }
        }
        return visible.replace(whitespace, " ").trim().takeIf { it.isNotEmpty() }
    }

    /** Sohbet başlığı: [normalize] + sayaç eki atılır. */
    fun title(raw: CharSequence?): String? =
        normalize(raw)?.replace(counterSuffix, "")?.trim()?.takeIf { it.isNotEmpty() }

    /**
     * MessagingStyle bildiriminin sohbet adı. Birebir sohbette WhatsApp
     * konuşma başlığı vermez ve bildirim başlığını SON MESAJI GÖNDERENİN adı
     * yapar; kullanıcı yanıt verince başlık "Siz" olur ve ayrı bir "Siz"
     * sohbeti açılıyordu (2026-10-09, cihazda). Bu yüzden birebir sohbette
     * karşı taraftan gelen son mesajın göndereni esas alınır.
     *
     * @return null: sohbetin kime ait olduğu anlaşılamadı (yalnızca kendi mesajlarımız var)
     */
    fun conversationTitle(
        conversationTitle: CharSequence?,
        notificationTitle: CharSequence?,
        isGroup: Boolean,
        lastIncomingSender: String?,
        userName: String?,
    ): String? {
        title(conversationTitle)?.let { return it }
        if (!isGroup) lastIncomingSender?.let { return title(it) }
        return title(notificationTitle)?.takeUnless { it == userName }
    }

    private const val ZERO_WIDTH_JOINER = '‍'
}
