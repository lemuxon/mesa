package com.mesajmerkezi.mesaj_merkezi

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

@RunWith(RobolectricTestRunner::class)
class SafeExecutorTest {

    @Test
    fun `hatali is sureci dusurmez, sonraki isler surer`() {
        val uncaught = mutableListOf<Throwable>()
        val previous = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { _, e -> uncaught += e }
        try {
            val executor = SafeExecutor("Test")
            val done = CountDownLatch(1)
            val order = mutableListOf<Int>()
            executor.execute { order += 1 }
            executor.execute { throw IllegalStateException("disk dolu") }
            executor.execute {
                order += 3
                done.countDown()
            }
            assertTrue(done.await(5, TimeUnit.SECONDS))
            assertEquals(listOf(1, 3), order)
            assertTrue(uncaught.isEmpty())
            executor.shutdown()
        } finally {
            Thread.setDefaultUncaughtExceptionHandler(previous)
        }
    }
}
