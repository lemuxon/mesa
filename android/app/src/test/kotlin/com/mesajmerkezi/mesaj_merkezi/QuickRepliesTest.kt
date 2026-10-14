package com.mesajmerkezi.mesaj_merkezi

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class QuickRepliesTest {

    private val context: Context = ApplicationProvider.getApplicationContext()

    @Test
    fun `hazir yanitlar sirasiyla saklanir, satir sonlari temizlenir`() {
        AppSettings.setQuickReplies(context, listOf("Tamam 👍", "Sonra\nyazarım", "  ", "Yoldayım"))
        assertEquals(listOf("Tamam 👍", "Sonra yazarım", "Yoldayım"), AppSettings.quickReplies(context))
    }

    @Test
    fun `bildirimde ilk uc hazir yanit secenek olur`() {
        AppSettings.setQuickReplies(context, listOf("Tamam 👍", "Sonra yazarım", "Yoldayım", "Teşekkürler"))
        val input = UnifiedNotifier.replyInput(context)
        assertEquals(listOf("Tamam 👍", "Sonra yazarım", "Yoldayım"), input.choices!!.map { it.toString() })
        // Serbest yazı da açık kalır.
        assertTrue(input.allowFreeFormInput)
    }

    @Test
    fun `hazir yanit yoksa yalnizca serbest yazi`() {
        AppSettings.setQuickReplies(context, emptyList())
        val input = UnifiedNotifier.replyInput(context)
        assertTrue(input.choices.isNullOrEmpty())
        assertTrue(input.allowFreeFormInput)
    }
}
