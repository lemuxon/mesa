package com.mesajmerkezi.mesaj_merkezi

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.Callable

@RunWith(RobolectricTestRunner::class)
class BackupTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val key = "com.whatsapp|Ayşe"
    private val t0 = 1_791_700_000_000L

    @Before
    fun reset() {
        Hub.io.submit(Callable { Hub.closeStore() }).get()
    }

    @After
    fun cleanUp() {
        Hub.io.submit(Callable { Hub.closeStore() }).get()
        context.deleteDatabase("mesajlar.db")
    }

    private fun ingest(text: String, time: Long, mediaUri: String? = null) =
        Hub.store(context).ingest(
            CapturedConversation(
                key, "com.whatsapp", "Ayşe", isGroup = false,
                messages = listOf(
                    CapturedMessage(
                        "Ayşe", text, time, outgoing = false, fromFallback = false,
                        mediaMime = mediaUri?.let { "image/jpeg" }, mediaUri = mediaUri,
                        mediaKind = mediaUri?.let { "photo" },
                    )
                ),
                replyAction = null,
            )
        )

    @Test
    fun `yedek alinip geri yuklenince mesajlar ve fotograflar doner`() {
        ingest("Selam", t0)
        val (id, _) = ingest("📷 Fotoğraf", t0 + 1000, mediaUri = "content://b/1").pendingMedia.single()
        val photo = File(context.filesDir, "media/$id.jpg").apply {
            parentFile!!.mkdirs()
            writeText("fotoğraf baytları")
        }
        Hub.store(context).setMedia(id, photo.path, "image/jpeg")

        val file = ByteArrayOutputStream()
        val summary = Backup.export(context, file, "parola123".toCharArray())
        assertEquals(2, summary.messages)
        assertEquals(1, summary.files)

        // Telefon sıfırlandı: sohbet ve fotoğraf gitti.
        Hub.store(context).deleteConversation(key)
        assertTrue(Hub.store(context).messages(key).isEmpty())
        assertTrue(!photo.exists())

        val restored = Backup.restore(context, ByteArrayInputStream(file.toByteArray()), "parola123".toCharArray())
        assertEquals(2, restored.messages)
        val rows = Hub.store(context).messages(key)
        assertEquals(listOf("Selam", "📷 Fotoğraf"), rows.map { it["text"] })
        assertEquals("fotoğraf baytları", File(rows.last()["mediaPath"] as String).readText())
    }

    @Test
    fun `yanlis sifre mevcut veriye dokunmaz`() {
        ingest("Eski", t0)
        val file = ByteArrayOutputStream()
        Backup.export(context, file, "parola123".toCharArray())
        ingest("Yeni", t0 + 5000)

        val error = runCatching {
            Backup.restore(context, ByteArrayInputStream(file.toByteArray()), "yanlış".toCharArray())
        }.exceptionOrNull()
        assertTrue(error is WrongPasswordException)
        assertEquals(listOf("Eski", "Yeni"), Hub.store(context).messages(key).map { it["text"] })
    }
}
