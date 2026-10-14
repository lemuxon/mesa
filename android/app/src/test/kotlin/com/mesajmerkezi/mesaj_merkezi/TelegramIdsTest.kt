package com.mesajmerkezi.mesaj_merkezi

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class TelegramIdsTest {

    @Test
    fun `mesaj kimligi sohbet kimligi eksi olsa da cozulur`() {
        // Grupların sohbet kimliği eksidir: "tg--100123-456".
        assertEquals(456L, TelegramIds.messageId(TelegramIds.of(-100123L, 456L)))
        assertEquals(9L, TelegramIds.messageId(TelegramIds.of(42L, 9L)))
    }

    @Test
    fun `telegram disi kimlik gorulmedi sayilmaz`() {
        assertNull(TelegramIds.messageId("a1b2c3"))
        assertNull(TelegramIds.messageId(null))
        assertNull(TelegramIds.messageId("tg-1-abc"))
    }

    @Test
    fun `sohbet kimligi eksi olsa da cozulur`() {
        assertEquals(-100123L, TelegramIds.chatId(TelegramIds.of(-100123L, 456L)))
        assertEquals(42L, TelegramIds.chatId(TelegramIds.of(42L, 9L)))
        assertNull(TelegramIds.chatId("a1b2c3"))
        assertNull(TelegramIds.chatId("tg-"))
    }
}
