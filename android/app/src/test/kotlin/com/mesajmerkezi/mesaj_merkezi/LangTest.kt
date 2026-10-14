package com.mesajmerkezi.mesaj_merkezi

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.io.File
import javax.xml.parsers.DocumentBuilderFactory

@RunWith(RobolectricTestRunner::class)
class LangTest {

    private val context: Context = ApplicationProvider.getApplicationContext()

    @After
    fun reset() = Lang.set(context, null)

    @Test
    fun `secilen dil bildirim metinlerine yansir`() {
        Lang.set(context, "tr")
        assertEquals("Yanıtla", Lang.str(context, R.string.notif_reply))
        assertEquals("3 yeni", Lang.plural(context, R.plurals.notif_new, 3))
        Lang.set(context, "en")
        assertEquals("Reply", Lang.str(context, R.string.notif_reply))
        assertEquals("Time to send the scheduled message: Ayşe", Lang.str(context, R.string.scheduled_due_title, "Ayşe"))
        Lang.set(context, "ru")
        assertEquals("Подключено 3 сервиса", Lang.plural(context, R.plurals.connected_services, 3))
    }

    @Test
    fun `kayittaki turkce medya etiketi secili dilde gosterilir`() {
        Lang.set(context, "en")
        assertEquals("📷 Photo", StoredLabels.display(context, "📷 Fotoğraf"))
        assertEquals("🎤 Voice message: selam", StoredLabels.display(context, "🎤 Sesli mesaj: selam"))
        assertEquals("😀 Sticker", StoredLabels.display(context, "😀 Çıkartma"))
        assertEquals("Merhaba", StoredLabels.display(context, "Merhaba"))
        Lang.set(context, "tr")
        assertEquals("📷 Fotoğraf", StoredLabels.display(context, "📷 Fotoğraf"))
    }

    @Test
    fun `her dil dosyasinda ayni metinler var`() {
        fun names(folder: String): Set<String> {
            val doc = DocumentBuilderFactory.newInstance().newDocumentBuilder()
                .parse(File("src/main/res/$folder/strings.xml"))
            val out = mutableSetOf<String>()
            for (tag in listOf("string", "plurals")) {
                val nodes = doc.getElementsByTagName(tag)
                for (i in 0 until nodes.length) out += tag + ":" + nodes.item(i).attributes.getNamedItem("name").nodeValue
            }
            return out
        }
        val base = names("values")
        for (lang in listOf("tr", "es", "pt", "de", "fr", "ar", "ru")) {
            assertEquals("values-$lang", base, names("values-$lang"))
        }
    }
}
