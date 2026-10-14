package com.mesajmerkezi.mesaj_merkezi

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class PersonMatcherTest {

    private fun c(
        key: String,
        pkg: String,
        title: String,
        group: Boolean = false,
        shortcut: String? = null,
        person: Long? = null,
        time: Long = 0,
    ) = PersonCandidate(key, pkg, title, group, shortcut, person, time)

    @Test
    fun `ad turkce harf, buyuk kucuk ve isaretlerden bagimsiz`() {
        assertEquals("yagizarda", PersonMatcher.nameKey("Yağız Arda"))
        assertEquals("yagizarda", PersonMatcher.nameKey("yagiz.arda"))
        assertEquals("yagizarda", PersonMatcher.nameKey("YAĞIZ_ARDA 🎮"))
        assertEquals("iremcelik", PersonMatcher.nameKey("İrem Çelik"))
    }

    @Test
    fun `cok kisa ad ve yalnizca numara ad sayilmaz`() {
        assertNull(PersonMatcher.nameKey("Ali"))
        assertNull(PersonMatcher.nameKey("+90 555 123 45 67"))
    }

    @Test
    fun `numara whatsapp kimliginden ve numara olan basliktan`() {
        assertEquals("5551234567", PersonMatcher.phoneKey("Ali Veli", "905551234567@s.whatsapp.net"))
        assertEquals("5551234567", PersonMatcher.phoneKey("+90 555 123 45 67", null))
        assertNull(PersonMatcher.phoneKey("Ali Veli", null))
        assertNull(PersonMatcher.phoneKey("Ali", "123@g.us"))
    }

    @Test
    fun `farkli uygulamadaki ayni ad onerilir`() {
        val list = PersonMatcher.suggestions(
            listOf(
                c("wa|Yağız Arda", "com.whatsapp", "Yağız Arda", time = 5),
                c("ig|yagiz.arda", "com.instagram.android", "yagiz.arda", time = 9),
                c("wa|Mehmet", "com.whatsapp", "Mehmet Kaya"),
            ),
            emptySet(),
        )
        assertEquals(1, list.size)
        assertEquals("name", list[0].reason)
        assertEquals(setOf("wa|Yağız Arda", "ig|yagiz.arda"), setOf(list[0].a.key, list[0].b.key))
    }

    @Test
    fun `numara eslesmesi whatsapp ile sms arasinda`() {
        val list = PersonMatcher.suggestions(
            listOf(
                c("wa|Annem", "com.whatsapp", "Annem", shortcut = "905551234567@s.whatsapp.net"),
                c("sms|05551234567", "com.google.android.apps.messaging", "0555 123 45 67"),
            ),
            emptySet(),
        )
        assertEquals("phone", list.single().reason)
    }

    @Test
    fun `grup, ayni uygulama, ayni kisi ve reddedilen cift onerilmez`() {
        val candidates = listOf(
            c("wa|Aile Grubu", "com.whatsapp", "Aile Grubu", group = true),
            c("tg|Aile Grubu", "org.telegram.messenger", "Aile Grubu", group = true),
            c("wa|Zeynep Ak", "com.whatsapp", "Zeynep Ak"),
            c("wa4b|Zeynep Ak", "com.whatsapp", "Zeynep Ak"),
            c("wa|Can Demir", "com.whatsapp", "Can Demir", person = 1),
            c("ig|can.demir", "com.instagram.android", "can.demir", person = 1),
            c("wa|Elif Su", "com.whatsapp", "Elif Su"),
            c("ig|elif.su", "com.instagram.android", "elif.su"),
        )
        val list = PersonMatcher.suggestions(candidates, setOf(PersonMatcher.pairOf("wa|Elif Su", "ig|elif.su")))
        assertTrue(list.isEmpty())
    }

    @Test
    fun `en son yazisilan once`() {
        val list = PersonMatcher.suggestions(
            listOf(
                c("wa|Eski Kisi", "com.whatsapp", "Eski Kisi", time = 1),
                c("ig|eski.kisi", "com.instagram.android", "eski.kisi", time = 2),
                c("wa|Yeni Kisi", "com.whatsapp", "Yeni Kisi", time = 50),
                c("tg|Yeni Kisi", "org.telegram.messenger", "Yeni Kisi", time = 40),
            ),
            emptySet(),
        )
        assertEquals(listOf("yenikisi", "eskikisi"), list.map { PersonMatcher.nameKey(it.a.title) })
    }
}
