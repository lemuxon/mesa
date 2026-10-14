package com.mesajmerkezi.mesaj_merkezi

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class RuleEngineTest {

    private val now = 1_760_000_000_000L

    private fun rule(
        id: Long = 1,
        action: RuleAction = RuleAction.AUTO_REPLY,
        packages: Set<String> = emptySet(),
        keywords: List<String> = emptyList(),
        sender: String = "",
        includeGroups: Boolean = false,
        enabled: Boolean = true,
        cooldownMinutes: Int = 60,
    ) = Rule(
        id, "kural $id", enabled, packages, keywords, sender, includeGroups, action,
        replyText = "Şu an müsait değilim", cooldownMinutes = cooldownMinutes,
    )

    private fun input(
        text: String = "merhaba",
        sender: String? = "Ali",
        title: String = "Ali",
        packageName: String = "com.whatsapp",
        isGroup: Boolean = false,
        ageMs: Long = 0,
        outgoing: Boolean = false,
    ) = RuleInput(
        packageName, title, isGroup,
        listOf(CapturedMessage(sender, text, now - ageMs, outgoing, fromFallback = false)),
        now,
    )

    private fun decide(
        rules: List<Rule>,
        input: RuleInput,
        lastAutoReply: Long? = null,
        lastHour: Int = 0,
    ) = RuleEngine.decide(rules, input, { lastAutoReply }, lastHour)

    @Test
    fun `kosulsuz kural her yeni mesaja uyar`() {
        assertTrue(RuleEngine.matches(rule(), input()))
    }

    @Test
    fun `kapali kural calismaz`() {
        assertFalse(RuleEngine.matches(rule(enabled = false), input()))
    }

    @Test
    fun `uygulama filtresi`() {
        val r = rule(packages = setOf("org.telegram.messenger"))
        assertFalse(RuleEngine.matches(r, input(packageName = "com.whatsapp")))
        assertTrue(RuleEngine.matches(r, input(packageName = "org.telegram.messenger")))
    }

    @Test
    fun `anahtar kelime buyuk kucuk harf ve Turkce I farkini yok sayar`() {
        val r = rule(keywords = listOf("İSTANBUL", "acil"))
        assertTrue(RuleEngine.matches(r, input(text = "istanbul'a geldim")))
        assertTrue(RuleEngine.matches(r, input(text = "ACİL dönüş yap")))
        assertTrue(RuleEngine.matches(rule(keywords = listOf("Istanbul")), input(text = "istanbul")))
        assertFalse(RuleEngine.matches(r, input(text = "nasılsın")))
    }

    @Test
    fun `gonderen sohbet adinda ya da gonderen adinda aranir`() {
        val r = rule(sender = "anne", includeGroups = true)
        assertTrue(RuleEngine.matches(r, input(title = "Annem", sender = "Annem")))
        assertTrue(RuleEngine.matches(r, input(title = "Aile", sender = "Anne", isGroup = true)))
        assertFalse(RuleEngine.matches(r, input(title = "Ali", sender = "Ali")))
    }

    @Test
    fun `grup sohbetleri varsayilan olarak disarida`() {
        assertFalse(RuleEngine.matches(rule(), input(isGroup = true)))
        assertTrue(RuleEngine.matches(rule(includeGroups = true), input(isGroup = true)))
    }

    @Test
    fun `eski ve giden mesajlar tetiklemez`() {
        assertFalse(RuleEngine.matches(rule(), input(ageMs = RuleEngine.MAX_MESSAGE_AGE_MS + 1)))
        assertFalse(RuleEngine.matches(rule(), input(outgoing = true)))
    }

    @Test
    fun `bekleme suresi dolmadan ayni sohbete tekrar yanit gitmez`() {
        val r = rule(cooldownMinutes = 60)
        assertTrue(decide(listOf(r), input(), lastAutoReply = now - 59 * 60_000L).isEmpty())
        assertEquals(listOf(r), decide(listOf(r), input(), lastAutoReply = now - 61 * 60_000L))
    }

    @Test
    fun `bekleme suresi alt siniri uygulanir`() {
        val r = rule(cooldownMinutes = 0)
        assertTrue(decide(listOf(r), input(), lastAutoReply = now - 60_000L).isEmpty())
    }

    @Test
    fun `saatlik ust sinira ulasinca otomatik yanit durur ama diger eylemler calisir`() {
        val reply = rule(id = 1)
        val important = rule(id = 2, action = RuleAction.IMPORTANT)
        val fired = decide(listOf(reply, important), input(), lastHour = RuleEngine.MAX_AUTO_REPLIES_PER_HOUR)
        assertEquals(listOf(important), fired)
    }

    @Test
    fun `ayni mesaj partisine yalnizca bir otomatik yanit`() {
        val first = rule(id = 1)
        val second = rule(id = 2)
        val mute = rule(id = 3, action = RuleAction.MUTE)
        assertEquals(listOf(first, mute), decide(listOf(first, second, mute), input()))
    }

    @Test
    fun `harita donusumu gidip gelir`() {
        val r = rule(id = 7, packages = setOf("com.whatsapp"), keywords = listOf("a", "b"))
        assertEquals(r, Rule.fromMap(r.toMap()))
        assertEquals(0L, Rule.fromMap(r.toMap() - "id").id)
    }

    @Test
    fun `saat araligi gun icinde`() {
        val r = rule().copy(activeFrom = 9 * 60, activeTo = 18 * 60)
        assertTrue(r.isActiveAt(9 * 60, 0))
        assertTrue(r.isActiveAt(17 * 60 + 59, 0))
        assertFalse(r.isActiveAt(18 * 60, 0)) // bitiş dahil değil
        assertFalse(r.isActiveAt(8 * 60 + 59, 0))
    }

    @Test
    fun `gece yarisini asan saat araligi`() {
        val r = rule().copy(activeFrom = 23 * 60, activeTo = 8 * 60)
        assertTrue(r.isActiveAt(23 * 60 + 30, 2))
        assertTrue(r.isActiveAt(2 * 60, 2))
        assertFalse(r.isActiveAt(8 * 60, 2))
        assertFalse(r.isActiveAt(12 * 60, 2))
    }

    @Test
    fun `gun secimi`() {
        val weekend = rule().copy(activeDays = (1 shl 5) or (1 shl 6)) // cumartesi + pazar
        assertFalse(weekend.isActiveAt(12 * 60, 0)) // pazartesi
        assertTrue(weekend.isActiveAt(12 * 60, 5))
        assertTrue(weekend.isActiveAt(12 * 60, 6))
    }

    @Test
    fun `aralik disindaki mesaj kurali tetiklemez`() {
        val night = rule().copy(activeFrom = 23 * 60, activeTo = 8 * 60)
        val noon = input().copy(minuteOfDay = 12 * 60)
        val midnight = input().copy(minuteOfDay = 30)
        assertFalse(RuleEngine.matches(night, noon))
        assertTrue(RuleEngine.matches(night, midnight))
    }

    @Test
    fun `saat alanlari harita donusumunde korunur`() {
        val r = rule().copy(activeFrom = 60, activeTo = 120, activeDays = 0b0011111)
        assertEquals(r, Rule.fromMap(r.toMap()))
        // Eski sürümden gelen haritada saat alanları yok: her zaman etkin.
        val old = Rule.fromMap(r.toMap() - "activeFrom" - "activeTo" - "activeDays")
        assertEquals(null, old.activeFrom)
        assertEquals(Rule.ALL_DAYS, old.activeDays)
    }
}
