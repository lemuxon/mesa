package com.mesajmerkezi.mesaj_merkezi

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/** Sohbet açan niyetlerin belirteci ve bildirim görseli adres denetimi (2026-11 denetimi). */
@RunWith(RobolectricTestRunner::class)
class LaunchSecurityTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val key = "com.whatsapp|Ayşe"

    @Test
    fun ownIntentOpensConversation() {
        val intent = LaunchToken.conversationIntent(context, key, "notification")
        assertEquals(key, LaunchToken.conversationKey(context, intent))
    }

    @Test
    fun foreignIntentWithoutTokenIsIgnored() {
        val intent = Intent(context, MainActivity::class.java).putExtra(UnifiedNotifier.EXTRA_KEY, key)
        assertNull(LaunchToken.conversationKey(context, intent))
    }

    @Test
    fun foreignIntentWithWrongTokenIsIgnored() {
        val intent = Intent(context, MainActivity::class.java)
            .putExtra(UnifiedNotifier.EXTRA_KEY, key)
            .putExtra(LaunchToken.EXTRA_TOKEN, "0".repeat(48))
        assertNull(LaunchToken.conversationKey(context, intent))
    }

    @Test
    fun tokenIsStableAndRandomLooking() {
        val first = LaunchToken.get(context)
        assertEquals(first, LaunchToken.get(context))
        assertEquals(48, first.length)
        assertTrue(first.all { it in '0'..'9' || it in 'a'..'f' })
    }

    @Test
    fun pendingIntentsOfDifferentConversationsNeverCompareEqual() {
        // Aynı hashCode'a sahip iki anahtar ("Aa" ve "BB" Java'da çakışır).
        assertEquals("Aa".hashCode(), "BB".hashCode())
        val a = LaunchToken.conversationIntent(context, "Aa", "notification")
        val b = LaunchToken.conversationIntent(context, "BB", "notification")
        assertFalse(a.filterEquals(b))
        assertNotEquals(LaunchToken.uniqueData("snooze", "Aa"), LaunchToken.uniqueData("snooze", "BB"))
    }

    @Test
    fun notificationMediaMustBeAnotherAppsContent() {
        assertTrue(MediaCache.isForeignContent(context, Uri.parse("content://com.whatsapp.provider.media/item/1")))
        assertFalse(MediaCache.isForeignContent(context, Uri.parse("file:///data/data/${context.packageName}/databases/mesajlar.db")))
        assertFalse(MediaCache.isForeignContent(context, Uri.parse("content://${context.packageName}.files/outbox/x.jpg")))
        assertFalse(MediaCache.isForeignContent(context, Uri.parse("https://example.com/a.jpg")))
        assertFalse(MediaCache.isForeignContent(context, Uri.parse("content:///no-authority")))
    }
}
