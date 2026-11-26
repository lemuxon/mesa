package com.mesajmerkezi.mesaj_merkezi

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import androidx.test.core.app.ApplicationProvider
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.util.concurrent.Callable

/** Mesaj çevirisi: dil kodları, dil adları, satır satır çeviri, saklama ve veritabanı yükseltmesi. */
@RunWith(RobolectricTestRunner::class)
class MessageTranslatorTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val t0 = 1_795_000_000_000L

    @Before
    fun reset() {
        Hub.io.submit(Callable { Hub.closeStore() }).get()
        context.deleteDatabase("mesajlar.db")
    }

    @After
    fun cleanUp() {
        Hub.io.submit(Callable { Hub.closeStore() }).get()
        context.deleteDatabase("mesajlar.db")
    }

    @Test
    fun languageTagsBecomeTranslationCodes() {
        assertEquals("en", MessageTranslator.translateCode("en"))
        assertEquals("en", MessageTranslator.translateCode("en-US"))
        assertEquals("tr", MessageTranslator.translateCode("tr"))
        // Eski Java kodları.
        assertEquals("he", MessageTranslator.translateCode("iw"))
        assertEquals("id", MessageTranslator.translateCode("in"))
        assertEquals("zh", MessageTranslator.translateCode("zh"))
        // Belirsiz, Latin harfle yazılmış Hintçe (modeli yok) ve bilinmeyen dil.
        assertNull(MessageTranslator.translateCode("und"))
        assertNull(MessageTranslator.translateCode("hi-Latn"))
        assertNull(MessageTranslator.translateCode("xx"))
        assertNull(MessageTranslator.translateCode(null))
    }

    @Test
    fun languageNamesAreInTheTargetLanguage() {
        assertEquals("İngilizce", MessageTranslator.displayName("en", "tr"))
        assertEquals("Almanca", MessageTranslator.displayName("de", "tr"))
        // Cümle içinde kullanıldığı için büyük harfe çevrilmez.
        assertEquals("anglais", MessageTranslator.displayName("en", "fr"))
    }

    @Test
    fun linesAreTranslatedOneByOne() {
        val seen = mutableListOf<String>()
        val out = MessageTranslator.byLines("Hello\n\n  See you  ") { line ->
            seen += line
            line.uppercase()
        }
        assertEquals("HELLO\n\nSEE YOU", out)
        assertEquals(listOf("Hello", "See you"), seen)
    }

    @Test
    fun mediaLabelsAreNotTranslated() {
        assertEquals("Look at this", StoredLabels.caption("📷 Fotoğraf: Look at this"))
        assertEquals("", StoredLabels.caption("📷 Fotoğraf"))
        assertEquals("", StoredLabels.caption("😀 Çıkartma"))
        assertEquals("See you", StoredLabels.caption("See you"))
    }

    @Test
    fun translationIsStoredWithTheMessage() {
        val key = "com.whatsapp|Deniz"
        val store = Hub.store(context)
        store.ingest(
            CapturedConversation(
                key, "com.whatsapp", "Deniz", isGroup = false,
                messages = listOf(CapturedMessage("Deniz", "Are you coming tonight?", t0, outgoing = false, fromFallback = false)),
                replyAction = null,
            ),
        )
        val id = store.messages(key).single()["id"] as String
        val source = store.translationSource(id)!!
        assertEquals(key, source.key)
        assertEquals("Are you coming tonight?", source.text)
        assertNull(source.translation)

        store.setTranslation(id, "Bu akşam geliyor musun?", "en", "tr")
        val row = store.messages(key).single()
        assertEquals("Bu akşam geliyor musun?", row["translation"])
        assertEquals("en", row["translationFrom"])
        assertEquals("tr", row["translationTo"])
        assertEquals("İngilizce", row["translationFromName"])
        assertEquals("tr", store.translationSource(id)!!.to)

        // Gizlenince dili de silinir.
        store.setTranslation(id, null, "en", "tr")
        val cleared = store.messages(key).single()
        assertNull(cleared["translation"])
        assertNull(cleared["translationFrom"])
        assertNull(cleared["translationFromName"])
    }

    @Test
    fun upgradingFromVersion14AddsTranslationColumns() {
        // 1.2.1'deki veritabanı (yalnızca yükseltmenin dokunduğu tablo).
        val file = context.getDatabasePath("mesajlar.db")
        file.parentFile?.mkdirs()
        SQLiteDatabase.openOrCreateDatabase(file, null).use { db ->
            db.execSQL("CREATE TABLE messages (id TEXT PRIMARY KEY, conv_key TEXT, text TEXT, transcript TEXT)")
            db.execSQL("INSERT INTO messages (id, conv_key, text) VALUES ('m1', 'k', 'Hello')")
            db.version = 14
        }
        val db = Hub.store(context).readableDatabase
        val columns = db.rawQuery("PRAGMA table_info(messages)", null).use { c ->
            buildList { while (c.moveToNext()) add(c.getString(1)) }
        }
        assertTrue(columns.containsAll(listOf("translation", "translation_from", "translation_to")))
        assertEquals(DB_VERSION, db.version)
        // Eski mesaj yerinde, çevirisi yok.
        db.rawQuery("SELECT text, translation FROM messages WHERE id = 'm1'", null).use { c ->
            assertTrue(c.moveToFirst())
            assertEquals("Hello", c.getString(0))
            assertTrue(c.isNull(1))
        }
    }
}
