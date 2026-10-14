package com.mesajmerkezi.mesaj_merkezi

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class AppLockStateTest {

    @Test
    fun `surec yeni basladiysa kilitli`() {
        assertTrue(AppLockState().locked)
    }

    @Test
    fun `ekranlar arasi gecis arka plan sayilmaz`() {
        val lock = AppLockState(relockAfterMs = 30_000)
        lock.onStarted(0)
        lock.unlock()
        // Gelen kutusunun üstüne web servisi açılır, sonra gelen kutusu durur.
        lock.onStarted(1_000)
        lock.onStopped(1_500)
        lock.onStopped(60_000)
        lock.onStarted(60_100)
        assertFalse(lock.locked)
    }

    @Test
    fun `arka planda uzun kalinca yeniden kilitlenir`() {
        val lock = AppLockState(relockAfterMs = 30_000)
        lock.onStarted(0)
        lock.unlock()
        lock.onStopped(10_000)
        lock.onStarted(39_999)
        assertFalse(lock.locked)
        lock.onStopped(40_000)
        lock.onStarted(70_000)
        assertTrue(lock.locked)
    }

    @Test
    fun `dogrulama sirasinda arkaya gecmek kilitlemez`() {
        val lock = AppLockState(relockAfterMs = 30_000)
        lock.onStarted(0)
        lock.unlock()
        lock.authenticating = true
        lock.onStopped(1_000)
        lock.onStarted(90_000)
        assertFalse(lock.locked)
    }
}
