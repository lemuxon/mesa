package com.mesajmerkezi.mesaj_merkezi

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Looper
import androidx.core.app.NotificationCompat
import androidx.core.app.RemoteInput
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import java.util.concurrent.Callable

/** Yanıt yollarının Mesa'nın süreci kapanınca da korunması. */
@RunWith(RobolectricTestRunner::class)
class ReplyStashTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val key = "com.whatsapp|Ayşe"

    @Before
    fun reset() {
        Hub.forgetPathsForTest()
        ReplyStash.resetForTest()
    }

    private fun replyAction(code: Int = 7): NotificationCompat.Action {
        val intent = PendingIntent.getBroadcast(
            context, code, Intent("whatsapp.REPLY").setPackage(context.packageName), PendingIntent.FLAG_MUTABLE,
        )
        return NotificationCompat.Action.Builder(0, "Yanıtla", intent)
            .addRemoteInput(RemoteInput.Builder("extra_text").setLabel("Yanıt yaz").build())
            .build()
    }

    @Test
    fun packingKeepsTheReplyRoute() {
        val action = replyAction()
        val back = ReplyStash.unpack(ReplyStash.pack(listOf(key to ReplyStash.Entry(action, null)))).single()
        assertEquals(key, back.first)
        assertEquals(action.actionIntent, back.second.reply!!.actionIntent)
        val input = back.second.reply!!.remoteInputs!!.single()
        assertEquals("extra_text", input.resultKey)
        assertTrue(input.allowFreeFormInput)
    }

    @Test
    fun onlyTheNewestChatsAreKept() {
        val entries = (1..100).map { "com.whatsapp|K$it" to ReplyStash.Entry(replyAction(it), null) }
        val back = ReplyStash.unpack(ReplyStash.pack(entries))
        assertEquals(ReplyStash.MAX_CHATS, back.size)
        assertEquals("com.whatsapp|K21", back.first().first)
        assertEquals("com.whatsapp|K100", back.last().first)
    }

    @Test
    fun routesSurviveAProcessRestart() {
        Hub.rememberReply(context, key, replyAction())
        // Saklama Hub.io'da yürür.
        Hub.io.submit(Callable { }).get()
        assertTrue(Hub.canReply(key))

        // Süreç kapandı: bellekteki yollar gitti.
        Hub.forgetPathsForTest()
        ReplyStash.resetForTest()
        assertFalse(Hub.canReply(key))

        ReplyStash.restore(context)
        shadowOf(Looper.getMainLooper()).idle()
        assertTrue("yanıt yolu geri gelmeli", Hub.canReply(key))
    }

    @Test
    fun freshRoutesAreNotOverwrittenByTheStash() {
        val fresh = replyAction(1)
        Hub.rememberReply(context, key, fresh)
        Hub.io.submit(Callable { }).get()
        val restored = Hub.restorePaths(listOf(key to ReplyStash.Entry(replyAction(2), null)))
        assertEquals(0, restored)
        // Gönderim taze yolu kullanır.
        val packed = ReplyStash.unpack(ReplyStash.pack(listOf(key to ReplyStash.Entry(fresh, null))))
        assertSame(fresh.actionIntent, packed.single().second.reply!!.actionIntent)
    }
}
