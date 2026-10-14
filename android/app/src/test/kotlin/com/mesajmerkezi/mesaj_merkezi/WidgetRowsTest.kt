package com.mesajmerkezi.mesaj_merkezi

import org.junit.Assert.assertEquals
import org.junit.Test
import java.util.Calendar

class WidgetRowsTest {

    private fun conv(
        key: String,
        title: String,
        time: Long,
        unread: Int = 0,
        person: Long? = null,
        personName: String? = null,
        avatar: String? = null,
    ) = mapOf(
        "key" to key,
        "package" to key.substringBefore('|'),
        "title" to title,
        "lastText" to "son $key",
        "lastTime" to time,
        "unread" to unread,
        "personId" to person,
        "personName" to personName,
        "avatarPath" to avatar,
    )

    @Test
    fun `okunmamislar once, sonra en yeniler, sinirli sayida`() {
        val rows = WidgetRows.select(
            listOf(
                conv("com.whatsapp|Ali", "Ali", time = 50),
                conv("com.whatsapp|Ayşe", "Ayşe", time = 10, unread = 2),
                conv("com.whatsapp|Can", "Can", time = 40),
                conv("com.whatsapp|Ece", "Ece", time = 30, unread = 1),
                conv("com.whatsapp|Mert", "Mert", time = 20),
            ),
            limit = 4,
        )
        assertEquals(listOf("Ece", "Ayşe", "Ali", "Can"), rows.map { it.title })
    }

    @Test
    fun `birlestirilmis kisi tek satir, okunmamislar toplanir`() {
        val rows = WidgetRows.select(
            listOf(
                conv("com.whatsapp|Yağız", "Yağız", time = 10, unread = 1, person = 7, personName = "Yağız Arda", avatar = "/a.jpg"),
                conv("com.instagram.android|yagiz", "yagiz", time = 30, unread = 2, person = 7, personName = "Yağız Arda"),
            ),
            limit = 4,
        )
        val row = rows.single()
        assertEquals("Yağız Arda", row.title)
        assertEquals(3, row.unread)
        // En son yazışılan üyenin mesajı ve anahtarı; fotoğraf olan üyeden.
        assertEquals("com.instagram.android|yagiz", row.key)
        assertEquals("/a.jpg", row.avatarPath)
    }

    @Test
    fun `saat bugun saat, dun Dun, daha eski gun ay`() {
        val now = Calendar.getInstance().apply { set(2026, Calendar.OCTOBER, 11, 21, 0, 0) }.timeInMillis
        val today = Calendar.getInstance().apply { set(2026, Calendar.OCTOBER, 11, 9, 5, 0) }.timeInMillis
        val yesterday = Calendar.getInstance().apply { set(2026, Calendar.OCTOBER, 10, 23, 0, 0) }.timeInMillis
        val older = Calendar.getInstance().apply { set(2026, Calendar.OCTOBER, 3, 12, 0, 0) }.timeInMillis
        assertEquals("09:05", WidgetRows.formatTime(today, now))
        assertEquals("Dün", WidgetRows.formatTime(yesterday, now))
        assertEquals("03.10", WidgetRows.formatTime(older, now))
        assertEquals("", WidgetRows.formatTime(0, now))
    }
}
