package com.mesajmerkezi.mesaj_merkezi

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.time.LocalDateTime
import java.time.ZoneId

/** Odak modu kararları: VIP, önemli, acil durum geçişi, zamanlama ve bitiş. */
@RunWith(RobolectricTestRunner::class)
class FocusTest {

    private val zone = ZoneId.of("Europe/Istanbul")

    /** 2026-11-23 bir pazartesi. */
    private fun at(day: Int, hour: Int, minute: Int = 0): Long =
        LocalDateTime.of(2026, 11, day, hour, minute).atZone(zone).toInstant().toEpochMilli()

    private fun policy(
        manualUntil: Long = 0,
        schedule: FocusPolicy.Schedule? = null,
        paused: Long = 0,
        vip: Set<String> = emptySet(),
        breakthrough: Boolean = true,
    ) = FocusPolicy(manualUntil, schedule, paused, vip, breakthrough, zone)

    @Test
    fun inactiveFocusAllowsEverything() {
        assertEquals(FocusPolicy.Decision.ALLOW, policy().decide("a", false, at(23, 12), emptyList()))
    }

    @Test
    fun vipAndImportantPassOthersAreSilenced() {
        val p = policy(manualUntil = Long.MAX_VALUE, vip = setOf("whatsapp|Anne"))
        val now = at(23, 12)
        assertEquals(FocusPolicy.Decision.ALLOW_VIP, p.decide("whatsapp|Anne", false, now, emptyList()))
        assertEquals(FocusPolicy.Decision.ALLOW_IMPORTANT, p.decide("slack|Patron", true, now, emptyList()))
        assertEquals(FocusPolicy.Decision.SILENCE, p.decide("instagram|Biri", false, now, emptyList()))
    }

    @Test
    fun thirdMessageWithinFiveMinutesBreaksThrough() {
        val p = policy(manualUntil = Long.MAX_VALUE)
        val now = at(23, 12, 10)
        val twoRecent = listOf(now - 60_000, now - 120_000)
        assertEquals(FocusPolicy.Decision.ALLOW_BREAKTHROUGH, p.decide("x", false, now, twoRecent))
        // Eski mesajlar sayılmaz.
        assertEquals(FocusPolicy.Decision.SILENCE, p.decide("x", false, now, listOf(now - 6 * 60_000, now - 60_000)))
        // Kapalıysa geçiş yok.
        assertEquals(FocusPolicy.Decision.SILENCE, policy(manualUntil = Long.MAX_VALUE, breakthrough = false).decide("x", false, now, twoRecent))
    }

    @Test
    fun overnightScheduleCountsTheDayItStarted() {
        // Yalnızca pazartesi gecesi 23:00–07:00.
        val p = policy(schedule = FocusPolicy.Schedule(23 * 60, 7 * 60, days = 0b0000001))
        assertTrue(p.isActive(at(23, 23, 30))) // pazartesi 23:30
        assertTrue(p.isActive(at(24, 2))) // salı 02:00, pazartesi başladı
        assertFalse(p.isActive(at(24, 7, 1))) // salı 07:01
        assertFalse(p.isActive(at(24, 23, 30))) // salı gecesi seçili değil
        assertEquals(at(24, 7), p.end(at(24, 2)))
    }

    @Test
    fun daytimeScheduleAndPause() {
        val weekdays = 0b0011111
        val p = policy(schedule = FocusPolicy.Schedule(9 * 60, 17 * 60, weekdays))
        assertTrue(p.isActive(at(25, 10))) // çarşamba
        assertFalse(p.isActive(at(28, 10))) // cumartesi
        val paused = policy(schedule = FocusPolicy.Schedule(9 * 60, 17 * 60, weekdays), paused = at(25, 17))
        assertFalse(paused.isActive(at(25, 10)))
        assertTrue(paused.isActive(at(26, 10)))
    }

    @Test
    fun endIsLaterOfManualAndScheduleAndNullWhenIndefinite() {
        val schedule = FocusPolicy.Schedule(22 * 60, 7 * 60, Rule.ALL_DAYS)
        val now = at(23, 23)
        assertEquals(at(24, 9), policy(manualUntil = at(24, 9), schedule = schedule).end(now))
        assertEquals(at(24, 7), policy(manualUntil = at(23, 23, 30), schedule = schedule).end(now))
        assertNull(policy(manualUntil = Long.MAX_VALUE).end(now))
        assertNull(policy().end(now))
    }

    @Test
    fun summaryNamesTwoPeopleThenCountsTheRest() {
        val context: Context = ApplicationProvider.getApplicationContext()
        assertEquals("Ayşe, Mehmet", Focus.summaryText(context, listOf("Ayşe", "Mehmet")))
        assertEquals("Ayşe, Mehmet and 3 more", Focus.summaryText(context, listOf("Ayşe", "Mehmet", "A", "B", "C")))
    }

    @Test
    fun manualFocusSilencesAndCounts() {
        val context: Context = ApplicationProvider.getApplicationContext()
        Focus.setVip(context, listOf("vip"))
        Focus.setManual(context, Long.MAX_VALUE)
        assertTrue(Focus.isActive(context))
        assertFalse(Focus.shouldSilence(context, "vip", important = false))
        assertTrue(Focus.shouldSilence(context, "other", important = false))
        assertEquals(1, Focus.status(context)["silenced"])
        Focus.setManual(context, 0)
        assertFalse(Focus.isActive(context))
        assertEquals(0, Focus.status(context)["silenced"])
    }
}
