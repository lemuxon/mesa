package com.mesajmerkezi.mesaj_merkezi

import android.content.Context
import android.net.Uri
import androidx.test.core.app.ApplicationProvider
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.Callable

/** Sesli mesajın WhatsApp dosyasıyla eşleşmesi, sesin 16 kHz'e indirilmesi, yazının saklanması. */
@RunWith(RobolectricTestRunner::class)
class VoiceNotesTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val t0 = 1_795_000_000_000L

    @Before
    fun reset() {
        Hub.io.submit(Callable { Hub.closeStore() }).get()
    }

    @After
    fun cleanUp() {
        Hub.io.submit(Callable { Hub.closeStore() }).get()
        context.deleteDatabase("mesajlar.db")
    }

    private fun file(name: String, modified: Long, seconds: Double?) = VoiceNotes.Candidate(
        Uri.parse("content://deneme/$name"), name, modified, seconds?.let { (it * 1000).toLong() },
    )

    @Test
    fun durationIsReadFromTheNotificationText() {
        assertEquals(12, VoiceNotes.parseDuration("🎤 Sesli mesaj (0:12)"))
        assertEquals(95, VoiceNotes.parseDuration("🎤 Voice message (1:35)"))
        assertNull(VoiceNotes.parseDuration("🎤 Sesli mesaj"))
    }

    @Test
    fun theFileWithTheMatchingTimeAndDurationIsChosen() {
        val files = listOf(
            file("PTT-1.opus", t0 + 3_000, 12.2),
            file("PTT-2.opus", t0 + 4_000, 30.0),
            file("PTT-3.opus", t0 - 3_600_000, 12.0),
        )
        assertEquals("PTT-1.opus", VoiceNotes.choose(files, t0, 12)?.name)
        // Süre yazmıyorsa en yakın zaman; ama ikinci dosya çok yakınsa hiçbiri.
        assertNull(VoiceNotes.choose(files, t0, null))
        assertEquals("PTT-2.opus", VoiceNotes.choose(files.drop(0).filter { it.name != "PTT-1.opus" }, t0, null)?.name)
    }

    @Test
    fun nothingIsChosenWhenUnsure() {
        // Saatler uyuşmuyor.
        assertNull(VoiceNotes.choose(listOf(file("PTT-1.opus", t0 + 3_600_000, 12.0)), t0, 12))
        // Süre uyuşmuyor.
        assertNull(VoiceNotes.choose(listOf(file("PTT-1.opus", t0 + 2_000, 40.0)), t0, 12))
        // Aynı süre, neredeyse aynı an: hangisi olduğu belli değil.
        assertNull(
            VoiceNotes.choose(listOf(file("PTT-1.opus", t0 + 2_000, 12.0), file("PTT-2.opus", t0 + 4_000, 12.0)), t0, 12),
        )
    }

    @Test
    fun audioIsMixedDownTo16kHzMono() {
        // 48 kHz, iki kanal, 1 saniye.
        val frames = 48_000
        val buffer = ByteBuffer.allocate(frames * 2 * 2).order(ByteOrder.LITTLE_ENDIAN)
        repeat(frames) {
            buffer.putShort(1000)
            buffer.putShort(3000)
        }
        val out = Transcriber.resampleTo16kMono(buffer.array(), 48_000, 2)
        assertEquals(16_000 * 2, out.size)
        assertEquals(2000, ByteBuffer.wrap(out).order(ByteOrder.LITTLE_ENDIAN).getShort(100).toInt())
    }

    @Test
    fun transcriptIsStoredWithTheMessage() {
        val key = "com.whatsapp|Ayşe"
        Hub.store(context).ingest(
            CapturedConversation(
                key, "com.whatsapp", "Ayşe", isGroup = false,
                messages = listOf(CapturedMessage("Ayşe", "🎤 Sesli mesaj (0:05)", t0, outgoing = false, fromFallback = false)),
                replyAction = null,
            ),
        )
        val id = Hub.store(context).messages(key).single()["id"] as String
        val info = Hub.store(context).voiceInfo(id)!!
        assertEquals("com.whatsapp", info.packageName)
        assertEquals(t0, info.time)
        assertNull(info.transcript)
        Hub.store(context).setTranscript(id, "Akşam yedide buluşalım")
        assertEquals("Akşam yedide buluşalım", Hub.store(context).messages(key).single()["transcript"])
        assertEquals("Akşam yedide buluşalım", Hub.store(context).voiceInfo(id)!!.transcript)
    }
}
