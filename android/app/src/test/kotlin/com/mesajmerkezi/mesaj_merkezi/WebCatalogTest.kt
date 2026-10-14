package com.mesajmerkezi.mesaj_merkezi

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class WebCatalogTest {

    @Test
    fun `basliktaki okunmamis sayisi okunur`() {
        assertEquals(3, WebTitles.unread("(3) Discord | #genel"))
        assertEquals(12, WebTitles.unread("(12) Messenger"))
        assertEquals(99, WebTitles.unread("(99+) X"))
        assertEquals(WebTitles.DOT, WebTitles.unread("• Discord"))
        assertEquals(WebTitles.DOT, WebTitles.unread("* genel - Ekip - Slack"))
        assertEquals(0, WebTitles.unread("Discord"))
        assertEquals(0, WebTitles.unread(null))
        // Sohbet adındaki parantez sayaç değildir.
        assertEquals(0, WebTitles.unread("Ahmet (iş) - Teams"))
    }

    @Test
    fun `ayni okunmamislar icin yeniden uyari verilmez`() {
        assertTrue(WebTitles.shouldAlert(alerted = 0, now = 1))
        assertTrue(WebTitles.shouldAlert(alerted = 1, now = 2))
        assertFalse(WebTitles.shouldAlert(alerted = 2, now = 2))
        assertFalse(WebTitles.shouldAlert(alerted = 3, now = 1))
        assertFalse(WebTitles.shouldAlert(alerted = 3, now = 0))
        assertTrue(WebTitles.shouldAlert(alerted = 0, now = WebTitles.DOT))
        assertFalse(WebTitles.shouldAlert(alerted = WebTitles.DOT, now = WebTitles.DOT))
        assertFalse(WebTitles.shouldAlert(alerted = WebTitles.DOT, now = 1))
        assertTrue(WebTitles.shouldAlert(alerted = WebTitles.DOT, now = 2))
    }

    @Test
    fun `servisin alan adlari sayfada kalir, digerleri tarayicida acilir`() {
        val discord = WebCatalog.entry("discord")!!.hosts
        assertTrue(WebCatalog.isAllowedHost("discord.com", discord))
        assertTrue(WebCatalog.isAllowedHost("canary.discord.com", discord))
        assertFalse(WebCatalog.isAllowedHost("youtube.com", discord))
        // Benzer görünen alan adı kandırmasın.
        assertFalse(WebCatalog.isAllowedHost("evil-discord.com", discord))
        assertFalse(WebCatalog.isAllowedHost("discord.com.evil.net", discord))
        assertFalse(WebCatalog.isAllowedHost(null, discord))
    }

    @Test
    fun `kopru yalnizca servisin kokenlerinde calisir`() {
        assertEquals(
            setOf("https://slack.com", "https://*.slack.com"),
            WebCatalog.originRules(WebCatalog.entry("slack")!!.hosts),
        )
    }

    @Test
    fun `kullanici sitesi adresi duzeltilir ve dogrulanir`() {
        assertEquals("https://chat.example.com", WebCatalog.normalizeUrl(" chat.example.com "))
        assertEquals("https://vk.com/im", WebCatalog.normalizeUrl("https://vk.com/im"))
        assertNull(WebCatalog.normalizeUrl("http://example.com"))
        assertNull(WebCatalog.normalizeUrl("localhost"))
        assertNull(WebCatalog.normalizeUrl("bir şey"))
        assertNull(WebCatalog.normalizeUrl(""))
        assertEquals(listOf("vk.com"), WebCatalog.hostsForUrl("https://www.vk.com/im"))
    }

    @Test
    fun `katalog kimlikleri benzersiz ve adresleri https`() {
        val ids = WebCatalog.entries.map { it.id }
        assertEquals(ids.size, ids.toSet().size)
        for (entry in WebCatalog.entries) {
            assertTrue(entry.url, entry.url.startsWith("https://"))
            assertTrue(entry.url, WebCatalog.isAllowedHost(WebCatalog.hostOf(entry.url), entry.hosts))
        }
    }

    @Test
    fun `tarayici kimligi gomulu tarayici izlerini tasimaz`() {
        val default = "Mozilla/5.0 (Linux; Android 13; Pixel 8 Build/TP1A.220624.014; wv) " +
            "AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/141.0.7390.122 Mobile Safari/537.36"
        val mobile = WebAgents.mobile(default)
        assertFalse(mobile.contains("; wv"))
        assertFalse(mobile.contains("Version/4.0"))
        assertTrue(mobile.contains("Chrome/141.0.7390.122 Mobile Safari"))
        val desktop = WebAgents.desktop(default)
        assertTrue(desktop.contains("Windows NT 10.0"))
        assertTrue(desktop.contains("Chrome/141.0.0.0"))
        assertFalse(desktop.contains("Android"))
        assertFalse(desktop.contains("Mobile"))
    }

    @Test
    fun `web sohbet anahtari servis kimligini tasir`() {
        val key = WebServices.keyFor("discord-2", "Ahmet | Sunucu")
        assertTrue(WebServices.isWebKey(key))
        assertEquals("discord-2", WebServices.idOfKey(key))
        assertTrue(WebServices.isWebPackage("web:discord"))
        assertEquals("discord", WebServices.idOfPackage("web:discord"))
        assertFalse(WebServices.isWebKey("tg|123"))
    }
}
