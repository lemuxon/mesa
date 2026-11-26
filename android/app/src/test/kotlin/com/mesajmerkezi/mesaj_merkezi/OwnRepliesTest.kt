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

/** WhatsApp sohbet listesinde yeni beliren satırların bulunması (Android'siz). */
class ChatRowsTest {

    private fun first(known: List<String>, current: List<String>, baseline: Boolean = false) =
        OwnReplies.firstNewRow(known, current, baseline)

    @Test
    fun newRowsAtTheBottomAreFound() {
        assertEquals(2, first(listOf("a", "b"), listOf("a", "b", "c")))
        // Liste kaydı: üstteki satır ekrandan çıktı, altta iki yeni satır var.
        assertEquals(2, first(listOf("a", "b", "c"), listOf("b", "c", "d", "e")))
    }

    @Test
    fun nothingNewWhenUnchanged() {
        assertEquals(2, first(listOf("a", "b"), listOf("a", "b")))
    }

    @Test
    fun sameTextTwiceInARowIsStillNew() {
        // "tamam" art arda gönderildi: ikincisi kaçmamalı.
        assertEquals(2, first(listOf("x", "tamam"), listOf("x", "tamam", "tamam")))
    }

    @Test
    fun unknownListIsNotTreatedAsNew() {
        // Önceki bakışın hiçbir satırı görünmüyor (başka yere kaydı): yeni sayılmaz.
        assertEquals(2, first(listOf("a", "b"), listOf("y", "z")))
        // Açılışta liste henüz çizilmemişti: görünenler geçmiştir.
        assertEquals(2, first(emptyList(), listOf("y", "z")))
    }

    @Test
    fun brandNewChatCountsEveryRow() {
        // Gerçekten boş (yeni) sohbet: ilk mesaj da yenidir.
        assertEquals(0, first(emptyList(), listOf("merhaba"), baseline = true))
        assertEquals(0, first(emptyList(), emptyList(), baseline = true))
    }
}

/** WhatsApp sohbetlerinin Mesa ile eşlenmesi, otomatik gönderim ve balonun korunması. */
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

    private fun incoming(text: String, chat: String = key, title: String = "Ayşe", isGroup: Boolean = false) {
        Hub.store(context).ingest(
            CapturedConversation(
                chat, wa, title, isGroup = isGroup,
                messages = listOf(CapturedMessage("Ayşe", text, t0, outgoing = false, fromFallback = false)),
                replyAction = null,
            ),
        )
    }

    private fun unread(chat: String = key) = Hub.store(context).conversation(chat)?.get("unread") as Int?

    private fun mine(text: String) = OwnReplies.ChatRow(text, outgoing = true, sender = null)

    private fun theirs(text: String, sender: String? = null) = OwnReplies.ChatRow(text, outgoing = false, sender = sender)

    @Test
    fun replyWrittenInWhatsAppJoinsTheSameChat() {
        incoming("Akşam geliyor musun?")
        assertEquals(1, unread())
        // WhatsApp başlığı görünmez yön işaretiyle başlayabilir.
        assertEquals(1, OwnReplies.recordRows(context, wa, "‎Ayşe", isGroup = false, listOf(mine("Geliyorum"))))
        val messages = Hub.store(context).messages(key)
        assertEquals(listOf("Akşam geliyor musun?", "Geliyorum"), messages.map { it["text"] })
        assertEquals(true, messages.last()["outgoing"])
        assertEquals(0, unread())
    }

    @Test
    fun chatStartedInWhatsAppAppearsInMesa() {
        // Kullanıcı WhatsApp'ta size hiç yazmamış birine yazdı.
        assertNull(Hub.store(context).conversation("$wa|Mehmet"))
        assertEquals(1, OwnReplies.recordRows(context, wa, "Mehmet", isGroup = false, listOf(mine("Selam, nasılsın?"))))
        val chat = Hub.store(context).conversation("$wa|Mehmet")!!
        assertEquals("Mehmet", chat["title"])
        assertEquals(false, chat["isGroup"])
        assertEquals(listOf("Selam, nasılsın?"), Hub.store(context).messages("$wa|Mehmet").map { it["text"] })
    }

    @Test
    fun repliesArrivingWhileTheChatIsOpenAreAdded() {
        incoming("Neredesin?")
        // Sohbet WhatsApp'ta açıkken WhatsApp bildirim göstermez; satırlar listeden okunur.
        OwnReplies.recordRows(context, wa, "Ayşe", isGroup = false, listOf(mine("Yoldayım"), theirs("Tamam, bekliyorum")))
        val messages = Hub.store(context).messages(key)
        assertEquals(listOf("Neredesin?", "Yoldayım", "Tamam, bekliyorum"), messages.map { it["text"] })
        assertEquals("Ayşe", messages.last()["sender"])
        assertEquals(false, messages.last()["outgoing"])
        // Kullanıcı sohbeti WhatsApp'ta görüyor: okunmamış sayılmaz.
        assertEquals(0, unread())
    }

    @Test
    fun groupSenderNamesAreKept() {
        OwnReplies.recordRows(context, wa, "Aile", isGroup = true, listOf(theirs("Yemek hazır", sender = "Annem")))
        val chat = Hub.store(context).conversation("$wa|Aile")!!
        assertEquals(true, chat["isGroup"])
        assertEquals("Annem", Hub.store(context).messages("$wa|Aile").single()["sender"])
    }

    @Test
    fun aGroupStartedFromWhatsAppBecomesAGroupWithItsFirstNotification() {
        // Yalnızca kendi mesajlarımız görülünce grup olduğu anlaşılamaz.
        OwnReplies.recordRows(context, wa, "Okul", isGroup = false, listOf(mine("Yarın toplantı var mı?")))
        assertEquals(false, Hub.store(context).conversation("$wa|Okul")!!["isGroup"])
        incoming("Var, 10'da", chat = "$wa|Okul", title = "Okul", isGroup = true)
        assertEquals(true, Hub.store(context).conversation("$wa|Okul")!!["isGroup"])
    }

    @Test
    fun theSameIncomingMessageIsNotAddedTwice() {
        OwnReplies.recordRows(context, wa, "Ayşe", isGroup = false, listOf(theirs("Geldim")))
        OwnReplies.recordRows(context, wa, "Ayşe", isGroup = false, listOf(theirs("Geldim")))
        assertEquals(1, Hub.store(context).messages(key).count { it["text"] == "Geldim" })
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
        assertEquals(OwnReplies.Step.PRESS, step(wa, "‎Ayşe", " Geliyorum "))
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
    fun messagesMatchDespiteInvisiblePadding() {
        // WhatsApp balondaki metne saat için görünmez boşluklar ekleyebiliyor.
        assertTrue(OwnReplies.sameMessage("Geliyorum   ​", "Geliyorum"))
        assertTrue(OwnReplies.sameMessage("Akşam  görüşürüz", "Akşam görüşürüz "))
        // Emoji birleştiricisi korunur; farklı metin eşleşmez, boş metin hiç eşleşmez.
        assertTrue(OwnReplies.sameMessage("👨‍👩", "👨‍👩"))
        assertFalse(OwnReplies.sameMessage("Geliyorum", "Geliyorum ama"))
        assertFalse(OwnReplies.sameMessage("", ""))
        assertFalse(OwnReplies.sameMessage(null, "x"))
    }

    @Test
    fun failedAutoSendDoesNotHideTheUsersOwnSend() {
        incoming("Neredesin?")
        OwnReplies.markSending(key, "Yoldayım")
        // Otomatik gönderim olmadı, Mesa kaydını sildi; kullanıcı WhatsApp'tan gönderdi.
        OwnReplies.clearSending(key)
        assertEquals(1, OwnReplies.recordRows(context, wa, "Ayşe", isGroup = false, listOf(mine("Yoldayım"))))
        assertEquals(1, Hub.store(context).messages(key).count { it["text"] == "Yoldayım" })
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
        // Mesa mesajı WhatsApp'a vermeden önce kendisi kaydeder; sonra listede görünür.
        Hub.store(context).recordOutgoing(key, "Yoldayım")
        OwnReplies.markSending(key, "Yoldayım")
        assertEquals(0, OwnReplies.recordRows(context, wa, "Ayşe", isGroup = false, listOf(mine("Yoldayım"))))
        assertEquals(1, Hub.store(context).messages(key).count { it["text"] == "Yoldayım" })
        // Dönüşte sonuç bir kez sorulur.
        assertNull(OwnReplies.takeResult(key))
        OwnReplies.markResult(key, sent = true)
        assertEquals("sent", OwnReplies.takeResult(key))
        assertNull(OwnReplies.takeResult(key))
        OwnReplies.markResult(key, sent = false)
        assertEquals("failed", OwnReplies.takeResult(key))
    }

    @Test
    fun mesaSentReplyIsNotDuplicatedWithoutTheSendingMark() {
        incoming("Neredesin?")
        // Bildirimin yanıt yolundan gönderilip Mesa'ya yazılan mesaj, sonra WhatsApp listesinde görünür.
        Hub.store(context).recordOutgoing(key, "Geliyorum")
        assertEquals(0, OwnReplies.recordRows(context, wa, "Ayşe", isGroup = false, listOf(mine("Geliyorum"))))
        assertEquals(1, Hub.store(context).messages(key).count { it["text"] == "Geliyorum" })
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
    fun openingTheChatInItsBubbleKeepsTheBubble() {
        post(key, bubble = true)
        // Balon penceresi sohbeti açtı: bildirim kaldırılmaz, çubuktan gizlenir.
        UnifiedNotifier.cancel(context, key, keepBubble = true)
        val kept = active(key)
        assertTrue("balon kapanmamalı", kept != null)
        assertTrue(kept!!.notification.bubbleMetadata!!.isNotificationSuppressed)
    }

    @Test
    fun markAsReadRemovesEvenABubblingNotification() {
        post(key, bubble = true)
        // "Okundu", WhatsApp'ta okuma, Mesa'da açma: bildirim tamamen kalkar (Xiaomi gizlemeyi yok sayıyor).
        UnifiedNotifier.cancel(context, key)
        assertNull(active(key))
    }

    @Test
    fun plainNotificationIsCancelled() {
        post(key, bubble = false)
        UnifiedNotifier.cancel(context, key)
        assertNull(active(key))
    }
}
