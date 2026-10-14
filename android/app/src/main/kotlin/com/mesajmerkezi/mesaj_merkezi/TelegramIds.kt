package com.mesajmerkezi.mesaj_merkezi

/** Telegram mesaj kimlikleri: depoda "tg-<sohbet>-<mesaj>". */
object TelegramIds {

    fun of(chatId: Long, messageId: Long) = "tg-$chatId-$messageId"

    /** "tg--100123-456" → 456; Telegram kimliği değilse null. Sohbet kimliği eksi olabilir. */
    fun messageId(id: String?): Long? {
        if (id == null || !id.startsWith("tg-")) return null
        return id.substringAfterLast('-').toLongOrNull()
    }

    /** "tg--100123-456" → -100123; Telegram kimliği değilse null. */
    fun chatId(id: String?): Long? {
        if (id == null || !id.startsWith("tg-")) return null
        return id.removePrefix("tg-").substringBeforeLast('-', "").toLongOrNull()
    }
}
