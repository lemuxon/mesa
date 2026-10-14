package com.mesajmerkezi.mesaj_merkezi

import android.app.Notification
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Process
import android.service.notification.StatusBarNotification
import androidx.core.app.NotificationCompat
import androidx.core.app.Person
import androidx.core.app.RemoteInput
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/** Mesajlaşma uygulamalarının bildirim biçimleri (Robolectric, gerçek Notification). */
@RunWith(RobolectricTestRunner::class)
class NotificationParserTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val t0 = 1_791_700_000_000L

    private fun builder() = NotificationCompat.Builder(context, "mesajlar").setSmallIcon(android.R.drawable.sym_def_app_icon)

    @Suppress("DEPRECATION")
    private fun sbn(n: Notification, pkg: String = "com.whatsapp") =
        StatusBarNotification(pkg, pkg, 1, "etiket", 0, 0, 0, n, Process.myUserHandle(), t0)

    private fun replyAction(): NotificationCompat.Action {
        val intent = PendingIntent.getBroadcast(context, 0, Intent("yanit"), PendingIntent.FLAG_MUTABLE)
        return NotificationCompat.Action.Builder(0, "Yanıtla", intent)
            .addRemoteInput(RemoteInput.Builder("text").setLabel("Yanıtla").build())
            .setSemanticAction(NotificationCompat.Action.SEMANTIC_ACTION_REPLY)
            .build()
    }

    private val me = Person.Builder().setName("Siz").build()
    private val ayse = Person.Builder().setName("Ayşe").build()

    @Test
    fun `whatsapp birebir sohbet, gelen ve giden ayrilir`() {
        val n = builder()
            .setContentTitle("Ayşe")
            .setStyle(
                NotificationCompat.MessagingStyle(me)
                    .addMessage("Selam", t0, ayse)
                    .addMessage("Merhaba", t0 + 1000, null as Person?)
            )
            .addAction(replyAction())
            .build()
        val c = NotificationParser.parse(sbn(n))!!
        assertEquals("com.whatsapp|Ayşe", c.key)
        assertEquals("Ayşe", c.title)
        assertFalse(c.isGroup)
        assertEquals(listOf(false, true), c.messages.map { it.outgoing })
        assertEquals("Ayşe", c.messages[0].sender)
        assertNotNull(c.replyAction)
    }

    @Test
    fun `grup sohbeti grup adiyla kaydedilir`() {
        val n = builder()
            .setStyle(
                NotificationCompat.MessagingStyle(me)
                    .setConversationTitle("Aile")
                    .setGroupConversation(true)
                    .addMessage("Akşam yemeği 8'de", t0, ayse)
            )
            .build()
        val c = NotificationParser.parse(sbn(n))!!
        assertEquals("Aile", c.title)
        assertTrue(c.isGroup)
        assertEquals("Ayşe", c.messages.single().sender)
    }

    @Test
    fun `metinsiz fotograf etiketlenir ve gorseli alinir`() {
        val message = NotificationCompat.MessagingStyle.Message("", t0, ayse)
            .setData("image/jpeg", Uri.parse("content://com.whatsapp/resim/1"))
        val n = builder()
            .setContentTitle("Ayşe")
            .setStyle(NotificationCompat.MessagingStyle(me).addMessage(message))
            .build()
        val m = NotificationParser.parse(sbn(n))!!.messages.single()
        assertEquals("📷 Fotoğraf", m.text)
        assertEquals("photo", m.mediaKind)
        assertEquals("content://com.whatsapp/resim/1", m.mediaUri)
    }

    @Test
    fun `ozet bildirimi sohbet sayilmaz`() {
        val n = builder()
            .setContentTitle("WhatsApp")
            .setContentText("3 sohbetten 5 mesaj")
            .setGroup("mesajlar")
            .setGroupSummary(true)
            .build()
        assertNull(NotificationParser.parse(sbn(n)))
    }

    @Test
    fun `mesaj bicimi olmayan ama mesaj olan bildirim yedek yoldan alinir`() {
        val n = builder()
            .setContentTitle("Mehmet")
            .setContentText("Yarın görüşürüz")
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .build()
        val c = NotificationParser.parse(sbn(n, "com.viber.voip"))!!
        assertEquals("com.viber.voip|Mehmet", c.key)
        assertTrue(c.messages.single().fromFallback)
        assertEquals("Yarın görüşürüz", c.messages.single().text)
    }

    @Test
    fun `begeni gibi mesaj olmayan bildirim alinmaz`() {
        val n = builder()
            .setContentTitle("Instagram")
            .setContentText("ayse.k gönderini beğendi")
            .build()
        assertNull(NotificationParser.parse(sbn(n, "com.instagram.android")))
    }

    @Test
    fun `adlardaki gorunmez yon isareti anahtari bolmez`() {
        val n = builder()
            .setContentTitle("‎Ayşe")
            .setStyle(
                NotificationCompat.MessagingStyle(me)
                    .addMessage("Selam", t0, Person.Builder().setName("‎Ayşe").build())
            )
            .build()
        assertEquals("com.whatsapp|Ayşe", NotificationParser.parse(sbn(n))!!.key)
    }
}
