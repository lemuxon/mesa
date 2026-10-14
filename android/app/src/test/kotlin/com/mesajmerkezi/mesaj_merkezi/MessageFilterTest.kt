package com.mesajmerkezi.mesaj_merkezi

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class MessageFilterTest {

    @Test
    fun `sohbet bicimindeki bildirim mesajdir`() {
        assertTrue(MessageFilter.isMessage(null, hasMessagingStyle = true, channelId = "default"))
        assertTrue(MessageFilter.isMessage("msg", hasMessagingStyle = false, channelId = null))
        assertTrue(MessageFilter.isMessage("social", hasMessagingStyle = true, channelId = "ig_direct"))
    }

    @Test
    fun `arama ve yukleme bildirimi sohbet bicimli olsa da mesaj degildir`() {
        assertFalse(MessageFilter.isMessage("call", hasMessagingStyle = true, channelId = "calls"))
        assertFalse(MessageFilter.isMessage("missed_call", hasMessagingStyle = false, channelId = "missed_calls"))
        assertFalse(MessageFilter.isMessage("progress", hasMessagingStyle = false, channelId = "backup"))
    }

    @Test
    fun `instagram begeni ve takip bildirimleri disarida kalir, DM girer`() {
        // 2026-10-10 telefondaki Instagram kanalları (usagestats).
        assertTrue(MessageFilter.isMessage(null, hasMessagingStyle = false, channelId = "ig_direct"))
        assertTrue(MessageFilter.isMessage("social", hasMessagingStyle = false, channelId = "ig_direct_requests"))
        assertFalse(MessageFilter.isMessage("social", hasMessagingStyle = false, channelId = "ig_likes"))
        assertFalse(MessageFilter.isMessage(null, hasMessagingStyle = false, channelId = "ig_highlights"))
        assertFalse(MessageFilter.isMessage(null, hasMessagingStyle = false, channelId = "ig_new_followers"))
        assertFalse(MessageFilter.isMessage(null, hasMessagingStyle = false, channelId = "ig_posting_status"))
    }

    @Test
    fun `kanal adindaki mesaj sozcukleri taninir`() {
        assertTrue(MessageFilter.isMessageChannel("chat_messages"))
        assertTrue(MessageFilter.isMessageChannel("DM_NOTIFICATIONS"))
        assertTrue(MessageFilter.isMessageChannel("conversations"))
        assertTrue(MessageFilter.isMessageChannel("Messaging"))
        // "admin" içindeki "dm" sözcük değildir.
        assertFalse(MessageFilter.isMessageChannel("admin_alerts"))
        assertFalse(MessageFilter.isMessageChannel("recommendations"))
        assertFalse(MessageFilter.isMessageChannel(null))
    }

    @Test
    fun `web bildiriminde gonderen ve metin olmali`() {
        val names = listOf("Discord")
        assertTrue(MessageFilter.isWebMessage("Ahmet (#genel, Sunucu)", "Merhaba", names))
        assertFalse(MessageFilter.isWebMessage("Discord", "Ahmet arkadaşlık isteği gönderdi", names))
        assertFalse(MessageFilter.isWebMessage("Ahmet", "", names))
        assertFalse(MessageFilter.isWebMessage("", "Merhaba", names))
    }
}
