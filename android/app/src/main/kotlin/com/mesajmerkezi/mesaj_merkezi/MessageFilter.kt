package com.mesajmerkezi.mesaj_merkezi

/**
 * Sohbetler'e yalnızca mesajlar girer. Desteklenen uygulamaların beğeni,
 * takip, yorum, arama, yükleme ve öneri bildirimleri dışarıda kalır
 * (2026-10-11: Instagram'ın beğeni bildirimleri sohbet gibi görünüyordu).
 */
object MessageFilter {

    /** Bu türler mesaj olamaz (Notification.CATEGORY_* değerleri). */
    private val NEVER = setOf(
        "call", "missed_call", "progress", "promo", "recommendation", "sys", "service",
        "status", "err", "alarm", "transport", "navigation", "location_sharing",
        "stopwatch", "workout",
    )

    // Kanal kimliğindeki sözcükler: "ig_direct", "dm_notifications", "chat_messages"…
    private val MESSAGE_WORDS = setOf("direct", "dm", "dms", "msg", "msgs", "inbox", "mesaj", "sohbet")
    private val MESSAGE_PREFIXES = listOf("message", "messaging", "conversation", "chat")

    /**
     * [category] bildirimin türü, [hasMessagingStyle] sohbet biçimi var mı,
     * [channelId] Android 8+ bildirim kanalı.
     */
    fun isMessage(category: String?, hasMessagingStyle: Boolean, channelId: String?): Boolean {
        if (category in NEVER) return false
        if (category == "msg" || hasMessagingStyle) return true
        return isMessageChannel(channelId)
    }

    fun isMessageChannel(channelId: String?): Boolean {
        val words = channelId?.lowercase()?.split(Regex("[^a-z0-9]+"))?.filter { it.isNotEmpty() }
            ?: return false
        return words.any { w -> w in MESSAGE_WORDS || MESSAGE_PREFIXES.any { w.startsWith(it) } }
    }

    /**
     * Web sitesinin bildirimi bir mesaj mı: başlıkta gönderen, gövdede metin
     * olmalı. Başlığı yalnızca servisin adı olanlar ("Discord", "Instagram")
     * sistem bildirimidir (arkadaşlık isteği, beğeni…).
     */
    fun isWebMessage(title: String?, body: String?, serviceNames: Collection<String>): Boolean {
        val t = title?.trim().orEmpty()
        if (t.isEmpty() || body.isNullOrBlank()) return false
        return serviceNames.none { it.equals(t, ignoreCase = true) }
    }
}
