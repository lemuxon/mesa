package com.mesajmerkezi.mesaj_merkezi

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Icon
import android.provider.Settings
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
import java.util.concurrent.Callable

/** Mesaj kutusunu izleyip gönderimi tanıma (Android'siz). */
class ReplyTrackerTest {

    private var clock = 1_000_000L
    private val tracker = ReplyTracker { clock }

    private fun type(text: String) {
        tracker.onTextChanged(text, before = text.dropLast(1), removed = 0, added = 1)
    }

    /** Gönderim sonrası kutunun bir anda boşalması. */
    private fun clear(before: String) =
        tracker.onTextChanged("", before = before, removed = before.length, added = 0)

    @Test
    fun sendButtonRecordsDraftOnce() {
        type("Geliyorum ")
        assertEquals("Geliyorum", tracker.onSendClicked())
        clock += 50
        // Dokunmanın ardından kutu boşalır: ikinci kez aday olmaz.
        assertNull(clear("Geliyorum "))
        assertNull(tracker.onSendClicked())
    }

    @Test
    fun enterKeySendIsVerifiedInList() {
        type("Tamam")
        assertEquals("Tamam", clear("Tamam"))
        assertTrue(tracker.onVerified("Tamam", shownInList = true))
        // Aynı aday ikinci kez kaydedilmez.
        assertFalse(tracker.onVerified("Tamam", shownInList = true))
    }

    @Test
    fun clearingWithoutSendingIsNotRecorded() {
        type("Yanlış")
        assertEquals("Yanlış", clear("Yanlış"))
        assertFalse(tracker.onVerified("Yanlış", shownInList = false))
    }

    @Test
    fun deletingLetterByLetterIsNotASend() {
        type("ab")
        assertNull(tracker.onTextChanged("a", before = "ab", removed = 1, added = 0))
        // Son harfin silinmesi gönderimle aynı görünür; listede görünmediği için kaydedilmez.
        assertEquals("a", tracker.onTextChanged("", before = "a", removed = 1, added = 0))
        assertFalse(tracker.onVerified("a", shownInList = false))
        // Kısmi silme (yeni metin eklenerek) aday olmaz.
        type("Merhaba")
        assertNull(tracker.onTextChanged("", before = "Merhaba", removed = 3, added = 0))
    }

    @Test
    fun clearThenClickRecordsOnce() {
        type("Selam")
        assertEquals("Selam", clear("Selam"))
        clock += 30
        assertEquals("Selam", tracker.onSendClicked())
        // Gecikmeli doğrulama artık bir şey kaydetmez.
        assertFalse(tracker.onVerified("Selam", shownInList = true))
    }

    @Test
    fun sameTextSentTwiceIsRecordedTwice() {
        type("ok")
        assertEquals("ok", tracker.onSendClicked())
        assertNull(clear("ok"))
        clock += 5_000
        type("ok")
        assertEquals("ok", tracker.onSendClicked())
    }

    @Test
    fun autoSendIsNotCapturedAgain() {
        type("Yoldayım")
        tracker.onAutoSend("Yoldayım")
        clock += 300
        assertNull(clear("Yoldayım"))
    }

    @Test
    fun screenChangeDropsDraft() {
        type("Taslak")
        tracker.reset()
        assertNull(tracker.onSendClicked())
    }
}

/** WhatsApp'ta yazılan yanıtların Mesa'ya eklenmesi ve balonun korunması. */
@RunWith(RobolectricTestRunner::class)
class OwnRepliesTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val wa = "com.whatsapp"
    private val key = "$wa|Ayşe"
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

    private fun incoming(text: String) {
        Hub.store(context).ingest(
            CapturedConversation(
                key, wa, "Ayşe", isGroup = false,
                messages = listOf(CapturedMessage("Ayşe", text, t0, outgoing = false, fromFallback = false)),
                replyAction = null,
            ),
        )
    }

    private fun unread() = Hub.store(context).conversation(key)?.get("unread") as Int?

    @Test
    fun replyWrittenInWhatsAppJoinsTheSameChat() {
        incoming("Akşam geliyor musun?")
        assertEquals(1, unread())
        // WhatsApp başlığı görünmez yön işaretiyle başlayabilir.
        assertTrue(OwnReplies.record(context, wa, "\u200EAyşe", "Geliyorum"))
        val messages = Hub.store(context).messages(key)
        assertEquals(listOf("Akşam geliyor musun?", "Geliyorum"), messages.map { it["text"] })
        assertEquals(true, messages.last()["outgoing"])
        assertEquals(0, unread())
    }

    @Test
    fun unknownChatIsNotCreated() {
        assertFalse(OwnReplies.record(context, wa, "Yabancı", "Merhaba"))
        assertNull(Hub.store(context).conversation("$wa|Yabancı"))
    }

    @Test
    fun openingChatInWhatsAppMarksItRead() {
        incoming("Bakar mısın?")
        assertTrue(OwnReplies.opened(context, wa, "Ayşe"))
        assertEquals(0, unread())
        assertFalse(OwnReplies.opened(context, wa, "Ayşe"))
    }

    @Test
    fun enabledStateComesFromAccessibilitySettings() {
        val resolver = context.contentResolver
        val own = ComponentName(context, OwnReplyService::class.java).flattenToString()
        Settings.Secure.putString(resolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, "")
        assertFalse(OwnReplies.isEnabled(context))
        Settings.Secure.putString(
            resolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
            "com.example/.Reader:$own",
        )
        assertTrue(OwnReplies.isEnabled(context))
    }

    private fun enableService(on: Boolean) {
        val own = ComponentName(context, OwnReplyService::class.java).flattenToString()
        Settings.Secure.putString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
            if (on) own else "",
        )
    }

    @Test
    fun autoSendOnlyInTheChatMesaOpened() {
        val now = 1_000L
        val pending = OwnReplies.PendingSend(wa, key, "Ayşe", "Geliyorum", until = now + 10_000, returnToMesa = true)
        fun step(pkg: String, title: String?, entry: String?, at: Long = now) =
            OwnReplies.autoSendStep(pending, pkg, title, entry, at)
        assertEquals(OwnReplies.Step.PRESS, step(wa, "\u200EAyşe", " Geliyorum "))
        // Doğru sohbette kutu boş ya da eski taslak var: kutu Mesa'nın metniyle doldurulur.
        assertEquals(OwnReplies.Step.FILL, step(wa, "Ayşe", ""))
        assertEquals(OwnReplies.Step.FILL, step(wa, "Ayşe", "eski taslak Geliyorum"))
        // Başka sohbet, başka uygulama ya da sohbet adı okunamıyor: dokunulmaz.
        assertEquals(OwnReplies.Step.WAIT, step(wa, "Mehmet", "Geliyorum"))
        assertEquals(OwnReplies.Step.WAIT, step(wa, null, "Geliyorum"))
        assertEquals(OwnReplies.Step.WAIT, step("com.whatsapp.w4b", "Ayşe", "Geliyorum"))
        assertEquals(OwnReplies.Step.WAIT, step(wa, "Ayşe", null))
        assertEquals(OwnReplies.Step.EXPIRED, step(wa, "Ayşe", "Geliyorum", at = now + 10_001))
    }

    @Test
    fun autoSendNeedsTheServiceAndWhatsApp() {
        enableService(false)
        assertFalse(OwnReplies.expectSend(context, wa, key, "Selam", returnToMesa = true))
        enableService(true)
        assertFalse(OwnReplies.expectSend(context, "org.telegram.messenger", "tg|1", "Selam", returnToMesa = true))
        assertFalse(OwnReplies.expectSend(context, wa, key, "   ", returnToMesa = true))
        assertTrue(OwnReplies.expectSend(context, wa, key, " Selam ", returnToMesa = false))
        val pending = OwnReplies.pendingSend!!
        assertEquals("Ayşe", pending.title)
        assertEquals("Selam", pending.text)
        assertFalse(pending.returnToMesa)
        OwnReplies.pendingSend = null
    }

    @Test
    fun autoSentMessageIsNotRecordedTwice() {
        incoming("Neredesin?")
        // Mesa mesajı WhatsApp'a vermeden önce kendisi kaydeder.
        Hub.store(context).recordOutgoing(key, "Yoldayım")
        OwnReplies.markSending(key, "Yoldayım")
        assertFalse(OwnReplies.record(context, wa, "Ayşe", "Yoldayım"))
        assertEquals(1, Hub.store(context).messages(key).count { it["text"] == "Yoldayım" })
        // Dönüşte sonuç bir kez sorulur.
        assertNull(OwnReplies.takeResult(key))
        OwnReplies.markResult(key, sent = true)
        assertEquals("sent", OwnReplies.takeResult(key))
        assertNull(OwnReplies.takeResult(key))
        OwnReplies.markResult(key, sent = false)
        assertEquals("failed", OwnReplies.takeResult(key))
    }

    private fun post(tag: String, bubble: Boolean) {
        val manager = context.getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(NotificationChannel("test", "test", NotificationManager.IMPORTANCE_HIGH))
        val icon = Icon.createWithResource(context, R.mipmap.ic_launcher)
        val pending = PendingIntent.getActivity(
            context, 0, Intent(context, BubbleActivity::class.java), PendingIntent.FLAG_MUTABLE,
        )
        val notification = Notification.Builder(context, "test")
            .setSmallIcon(icon)
            .setContentTitle("Ayşe")
            .apply { if (bubble) setBubbleMetadata(Notification.BubbleMetadata.Builder(pending, icon).build()) }
            .build()
        // Sistem balon olarak gösterdiğinde bu bayrağı koyar.
        if (bubble) notification.flags = notification.flags or Notification.FLAG_BUBBLE
        manager.notify(tag, UnifiedNotifier.NOTIFICATION_ID, notification)
    }

    private fun active(tag: String) = context.getSystemService(NotificationManager::class.java)
        .activeNotifications.firstOrNull { it.tag == tag }

    @Test
    fun readingABubbleChatKeepsTheBubble() {
        post(key, bubble = true)
        UnifiedNotifier.cancel(context, key)
        val kept = active(key)
        assertTrue("balon kapanmamalı", kept != null)
        assertTrue(kept!!.notification.bubbleMetadata!!.isNotificationSuppressed)
        // Sohbet silinince balon da kalkar.
        UnifiedNotifier.cancel(context, key, keepBubble = false)
        assertNull(active(key))
    }

    @Test
    fun plainNotificationIsCancelled() {
        post(key, bubble = false)
        UnifiedNotifier.cancel(context, key)
        assertNull(active(key))
    }
}
