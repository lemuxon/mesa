package com.mesajmerkezi.mesaj_merkezi

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.io.File

/** Mesaj deposunun asıl kuralları, gerçek SQLite ile (Robolectric). */
@RunWith(RobolectricTestRunner::class)
class MessageStoreTest {

    private lateinit var context: Context
    private lateinit var store: MessageStore

    private val wa = "com.whatsapp"
    private val ayseKey = "$wa|Ayşe"
    private val t0 = 1_791_700_000_000L

    @Before
    fun setUp() {
        context = ApplicationProvider.getApplicationContext()
        store = MessageStore(context)
    }

    @After
    fun tearDown() {
        store.close()
        context.deleteDatabase("mesajlar.db")
    }

    private fun msg(
        text: String,
        time: Long,
        sender: String? = "Ayşe",
        outgoing: Boolean = false,
        id: String? = null,
        mediaUri: String? = null,
    ) = CapturedMessage(
        sender = sender,
        text = text,
        time = time,
        outgoing = outgoing,
        fromFallback = false,
        id = id,
        mediaMime = mediaUri?.let { "image/jpeg" },
        mediaUri = mediaUri,
        mediaKind = mediaUri?.let { "photo" },
    )

    private fun conv(vararg messages: CapturedMessage, key: String = ayseKey, title: String = "Ayşe", pkg: String = wa) =
        CapturedConversation(key, pkg, title, isGroup = false, messages = messages.toList(), replyAction = null)

    private fun texts(key: String = ayseKey) = store.messages(key).map { it["text"] }

    private fun unread(key: String = ayseKey) =
        store.conversations().first { it["key"] == key }["unread"] as Int

    @Test
    fun `ayni bildirim yeniden gelince mesaj ikinci kez yazilmaz`() {
        val first = store.ingest(conv(msg("Selam", t0)))
        val again = store.ingest(conv(msg("Selam", t0)))
        assertEquals(1, first.newIncoming.size)
        assertEquals(0, again.added)
        assertEquals(listOf("Selam"), texts())
        assertEquals(1, unread())
    }

    @Test
    fun `bildirim gecmisi buyudukce yalnizca yenisi yeni sayilir`() {
        store.ingest(conv(msg("Selam", t0), msg("Naber", t0 + 1000)))
        val result = store.ingest(conv(msg("Selam", t0), msg("Naber", t0 + 1000), msg("Orada mısın", t0 + 2000)))
        assertEquals(listOf("Orada mısın"), result.newIncoming.map { it.text })
        assertEquals(listOf("Selam", "Naber", "Orada mısın"), texts())
        assertEquals(3, unread())
    }

    @Test
    fun `uygulamadan gonderilen yanit bildirimde geri gelince ikinci kez yazilmaz`() {
        store.ingest(conv(msg("Selam", t0)))
        store.recordOutgoing(ayseKey, "Geliyorum")
        val now = System.currentTimeMillis()
        val echo = store.ingest(conv(msg("Selam", t0), msg("Geliyorum", now + 3000, sender = null, outgoing = true)))
        assertEquals(0, echo.added)
        assertEquals(listOf("Selam", "Geliyorum"), texts())
    }

    @Test
    fun `kalici kimlikli ayni metin iki ayri mesajdir`() {
        val key = "tg-42"
        store.ingest(
            conv(
                msg("tamam", t0, id = "tg-42-1"),
                msg("tamam", t0, id = "tg-42-2"),
                key = key,
                title = "Can",
                pkg = "org.telegram.messenger",
            )
        )
        assertEquals(listOf("tamam", "tamam"), texts(key))
    }

    @Test
    fun `okununca okunmamis sifirlanir`() {
        store.ingest(conv(msg("Selam", t0), msg("Naber", t0 + 1)))
        store.markRead(ayseKey)
        assertEquals(0, unread())
    }

    @Test
    fun `silinen mesaj etiketi eskisini isaretler, medyasini birakir`() {
        val result = store.ingest(conv(msg("📷 Fotoğraf", t0, mediaUri = "content://bildirim/1")))
        val (id, _) = result.pendingMedia.single()
        val copy = File(context.filesDir, "media/$id.jpg").apply {
            parentFile!!.mkdirs()
            writeText("resim")
        }
        store.setMedia(id, copy.path, "image/jpeg")
        assertEquals(copy.path, store.messages(ayseKey).single()["mediaPath"])

        val label = store.ingest(conv(msg("Bu mesaj silindi", t0 + 500)))
        assertEquals(0, label.newIncoming.size)
        val row = store.messages(ayseKey).single()
        assertEquals(true, row["deleted"])
        assertEquals("📷 Fotoğraf", row["text"])
        assertNull(row["mediaPath"])
        assertFalse(copy.exists())
        assertTrue(store.media(listOf(ayseKey)).isEmpty())
    }

    @Test
    fun `kopyalama surerken silinen mesaja medya yazilmaz`() {
        val result = store.ingest(conv(msg("📷 Fotoğraf", t0, mediaUri = "content://bildirim/2")))
        val (id, _) = result.pendingMedia.single()
        store.ingest(conv(msg("Bu mesaj silindi", t0 + 300)))
        val late = File(context.filesDir, "media/$id.jpg").apply {
            parentFile!!.mkdirs()
            writeText("resim")
        }
        store.setMedia(id, late.path, "image/jpeg")
        assertNull(store.messages(ayseKey).single()["mediaPath"])
        assertFalse(late.exists())
    }

    @Test
    fun `galeri silinmemis fotograflari yeniden eskiye verir, cikartmayi almaz`() {
        val r = store.ingest(
            conv(
                msg("📷 Fotoğraf", t0, mediaUri = "content://b/1"),
                msg("📷 Fotoğraf 2", t0 + 1000, mediaUri = "content://b/2"),
            )
        )
        for ((id, _) in r.pendingMedia) store.setMedia(id, File(context.filesDir, "media/$id.jpg").path, "image/jpeg")
        val sticker = store.ingest(
            conv(
                CapturedMessage(
                    "Ayşe", "Çıkartma", t0 + 2000, outgoing = false, fromFallback = false,
                    mediaMime = "image/webp", mediaUri = "content://b/3", mediaKind = "sticker",
                )
            )
        ).pendingMedia.single()
        store.setMedia(sticker.first, File(context.filesDir, "media/s.webp").path, "image/webp")

        val media = store.media(listOf(ayseKey))
        assertEquals(listOf("📷 Fotoğraf 2", "📷 Fotoğraf"), media.map { it["text"] })
        assertEquals(ayseKey, media.first()["key"])
    }

    @Test
    fun `kisi birlestirme, ayirma ve reddedilen cift`() {
        val igKey = "com.instagram.android|ayse.k"
        store.ingest(conv(msg("Selam", t0)))
        store.ingest(conv(msg("Hey", t0 + 10), key = igKey, title = "ayse.k", pkg = "com.instagram.android"))

        val person = store.mergePeople(listOf(ayseKey, igKey), name = "Ayşe")
        val rows = store.conversations().associateBy { it["key"] }
        assertEquals(person, rows[ayseKey]!!["personId"])
        assertEquals(person, rows[igKey]!!["personId"])
        assertEquals("Ayşe", rows[igKey]!!["personName"])

        store.unmergePerson(igKey)
        val after = store.conversations()
        // İki üyeli kişi tek üyeyle kalınca dağılır.
        assertTrue(after.all { it["personId"] == null })
        // Ayrılan çift yeniden önerilmez.
        assertTrue(store.personSuggestions().none { setOf(it["a"], it["b"]) == setOf(ayseKey, igKey) })
    }

    @Test
    fun `ayni ad farkli uygulamada onerilir, silinen sohbet kisiyi dagitir`() {
        val tgKey = "tg-7"
        store.ingest(conv(msg("Selam", t0), key = "$wa|Yağız Arda", title = "Yağız Arda"))
        store.ingest(conv(msg("Hey", t0 + 5, id = "tg-7-1"), key = tgKey, title = "Yağız Arda", pkg = "org.telegram.messenger"))

        val suggestion = store.personSuggestions().single()
        assertEquals("name", suggestion["reason"])

        store.mergePeople(listOf("$wa|Yağız Arda", tgKey))
        assertTrue(store.personSuggestions().isEmpty())
        store.deleteConversation(tgKey)
        assertTrue(store.conversations().all { it["personId"] == null })
    }

    @Test
    fun `telegram mesaji once gonderiliyor, onaylaninca kesin kimlikle degisir`() {
        val key = "tg-42"
        fun sent(id: String, state: Int, error: String? = null) = conv(
            CapturedMessage(
                null, "Yoldayım", t0, outgoing = true, fromFallback = false, id = id,
                sendState = state, sendError = error,
            ),
            key = key, title = "Can", pkg = "org.telegram.messenger",
        )
        store.ingest(sent("tg-42-9001", SendState.PENDING))
        assertEquals("pending", store.messages(key).single()["sendState"])

        // Sunucu onayladı: geçici satır silinir, kesin mesaj yazılır.
        store.deleteMessage("tg-42-9001")
        store.ingest(sent("tg-42-77", SendState.SENT))
        val row = store.messages(key).single()
        assertEquals("tg-42-77", row["id"])
        assertNull(row["sendState"])
        assertEquals("Yoldayım", store.conversations().first { it["key"] == key }["lastText"])
    }

    @Test
    fun `gonderilemeyen mesaj sebebiyle kalir, durumu guncellenir`() {
        val key = "tg-42"
        val failed = CapturedMessage(
            null, "Yoldayım", t0, outgoing = true, fromFallback = false, id = "tg-42-9002",
            sendState = SendState.FAILED, sendError = "Bağlantı yok",
        )
        store.ingest(conv(failed, key = key, title = "Can", pkg = "org.telegram.messenger"))
        val row = store.messages(key).single()
        assertEquals("failed", row["sendState"])
        assertEquals("Bağlantı yok", row["sendError"])

        // Aynı kimlik yeniden "gönderiliyor" olarak gelirse durum güncellenir.
        store.ingest(
            conv(failed.copy(sendState = SendState.PENDING, sendError = null), key = key, title = "Can", pkg = "org.telegram.messenger")
        )
        assertEquals("pending", store.messages(key).single()["sendState"])

        store.deleteMessage("tg-42-9002")
        assertTrue(store.messages(key).isEmpty())
    }

    @Test
    fun `dosyasi silinen medya baglantisi temizlenir, depolama hesaplanir`() {
        val r = store.ingest(conv(msg("📷 Fotoğraf", t0, mediaUri = "content://b/9")))
        val (id, _) = r.pendingMedia.single()
        val file = File(context.filesDir, "media/$id.jpg").apply {
            parentFile!!.mkdirs()
            writeText("resim")
        }
        store.setMedia(id, file.path, "image/jpeg")
        assertEquals(0, store.clearMissingFiles())

        val usage = Storage.usage(context)
        assertTrue(usage.getValue("database") > 0)
        assertTrue(usage.getValue("media") >= 5)

        file.delete()
        assertEquals(1, store.clearMissingFiles())
        assertNull(store.messages(ayseKey).single()["mediaPath"])
    }
}
