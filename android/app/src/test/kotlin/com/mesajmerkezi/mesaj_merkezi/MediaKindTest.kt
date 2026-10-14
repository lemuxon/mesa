package com.mesajmerkezi.mesaj_merkezi

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class MediaKindTest {

    @Test
    fun `bildirimdeki icerik turunden medya turu`() {
        assertEquals("sticker", NotificationParser.mediaKind("image/webp"))
        assertEquals("photo", NotificationParser.mediaKind("image/jpeg"))
        assertEquals("photo", NotificationParser.mediaKind("image/gif"))
        assertEquals("video", NotificationParser.mediaKind("video/mp4"))
        assertNull(NotificationParser.mediaKind("audio/ogg"))
    }

    @Test
    fun `metni olmayan medyanin etiketi`() {
        assertEquals("Çıkartma", NotificationParser.mediaLabel("image/webp"))
        assertEquals("GIF", NotificationParser.mediaLabel("image/gif"))
        assertEquals("🎥 Video", NotificationParser.mediaLabel("video/mp4"))
        assertNull(NotificationParser.mediaLabel("application/pdf"))
    }

    @Test
    fun `uygulama adi ve rengi`() {
        assertEquals("Discord", SupportedApps.name("com.discord"))
        assertEquals("com.ornek", SupportedApps.name("com.ornek"))
        assert("com.discord" in SupportedApps.packages)
    }
}
