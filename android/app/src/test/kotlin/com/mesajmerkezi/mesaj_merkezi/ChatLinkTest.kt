package com.mesajmerkezi.mesaj_merkezi

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class ChatLinkTest {

    @Test
    fun `instagram sohbeti kisayoldaki sohbet numarasiyla acilir`() {
        val thread = "340282366841710300949128137443944319"
        assertEquals(
            "https://www.instagram.com/direct/t/$thread/" to "sohbet bağlantısı",
            Hub.chatLink("com.instagram.android", "thread_shortcut_12345678901_$thread"),
        )
    }

    @Test
    fun `instagram kisayolu tanınmazsa ana akis degil mesajlar kutusu`() {
        val inbox = "https://www.instagram.com/direct/inbox/" to "mesajlar kutusu"
        assertEquals(inbox, Hub.chatLink("com.instagram.android", null))
        assertEquals(inbox, Hub.chatLink("com.instagram.android", "post"))
    }

    @Test
    fun `whatsapp kisisi numarasiyla, grup ve diger uygulamalar baglantisiz`() {
        assertEquals(
            "https://wa.me/905551112233" to "kişi bağlantısı",
            Hub.chatLink("com.whatsapp", "905551112233@s.whatsapp.net"),
        )
        assertNull(Hub.chatLink("com.whatsapp", "120363000000000000@g.us"))
        assertNull(Hub.chatLink("com.whatsapp", null))
        assertNull(Hub.chatLink("com.discord", "abc"))
    }
}
