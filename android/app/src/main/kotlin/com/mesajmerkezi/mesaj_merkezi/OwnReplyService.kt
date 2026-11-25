package com.mesajmerkezi.mesaj_merkezi

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.content.Intent
import android.graphics.Path
import android.graphics.Rect
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

/**
 * WhatsApp'ta yazılan yanıtları Mesa'ya ekleyen, Mesa'dan yazılanları da
 * WhatsApp'ta gönderen isteğe bağlı erişilebilirlik servisi ([OwnReplies]).
 * Sistem yalnızca WhatsApp ve WhatsApp Business olaylarını iletir
 * (res/xml/own_replies.xml); kullanıcı Android'in Erişilebilirlik ayarından
 * açar ve kapatır.
 *
 * WhatsApp 2.26'da ayrı bir Gönder düğmesi yok: mikrofon düğmesi
 * (voice_note_btn) metin yazılınca gönder olur ve dokunmayı kendisi işler,
 * "tıklandı" olayı gelmez. Gönderim, kutunun bir anda boşalmasından ve
 * metnin sohbet listesinde belirmesinden anlaşılır (2026-11-26, cihazda).
 */
class OwnReplyService : AccessibilityService() {

    private val tracker = ReplyTracker()
    private val main = Handler(Looper.getMainLooper())

    /** En son açık görülen sohbet; aynı sohbet için tekrar okundu yazılmasın. */
    private var openChat: String? = null
    private var windowCheck: Runnable? = null
    private var lastSendCheck = 0L

    override fun onServiceConnected() {
        Log.i(TAG, "WhatsApp yanıt servisi bağlandı")
    }

    override fun onInterrupt() = Unit

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        event ?: return
        val packageName = event.packageName?.toString() ?: return
        if (packageName !in OwnReplies.packages) return
        val ids = ChatIds(packageName)
        try {
            when (event.eventType) {
                AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED -> onText(event, ids)
                AccessibilityEvent.TYPE_VIEW_CLICKED -> onClick(event, ids)
                AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> onWindow(ids)
                AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> maybeAutoSend(ids)
            }
        } catch (e: RuntimeException) {
            // WhatsApp'ın ekranı habersiz değişebilir; servis düşmemeli.
            Log.w(TAG, "WhatsApp olayı işlenemedi: ${e.javaClass.simpleName}")
        }
    }

    private fun onText(event: AccessibilityEvent, ids: ChatIds) {
        val node = event.source ?: return
        if (node.viewIdResourceName != ids.entry) return
        val before = event.beforeText?.toString()
        // Boş kutu metin yerine ipucunu ("Mesaj") bildirir; boşalma olaydan anlaşılır.
        val cleared = event.addedCount == 0 && !before.isNullOrEmpty() && event.removedCount >= before.length
        val text = if (cleared) "" else entryText(node) ?: event.text.joinToString("")
        val candidate = tracker.onTextChanged(text, before, event.removedCount, event.addedCount)
        if (candidate != null) {
            // Gönderildiyse metin sohbet listesinde belirir.
            main.postDelayed({ verify(ids, candidate, attempt = 1) }, VERIFY_DELAY_MS)
        } else if (text.isNotBlank()) {
            maybeAutoSend(ids)
        }
    }

    private fun onClick(event: AccessibilityEvent, ids: ChatIds) {
        if (event.source?.viewIdResourceName != ids.send) return
        val text = tracker.onSendClicked() ?: return
        record(ids, text)
    }

    private fun verify(ids: ChatIds, text: String, attempt: Int) {
        val root = rootInActiveWindow
        val shown = root?.findAccessibilityNodeInfosByViewId(ids.messageText)
            ?.any { it.text?.toString()?.trim() == text } == true
        if (!shown && attempt == 1) {
            main.postDelayed({ verify(ids, text, attempt = 2) }, VERIFY_DELAY_MS)
            return
        }
        if (tracker.onVerified(text, shown)) record(ids, text, root)
    }

    private fun record(ids: ChatIds, text: String, root: AccessibilityNodeInfo? = rootInActiveWindow) {
        val title = chatTitle(root, ids) ?: run {
            Log.i(TAG, "WhatsApp yanıtı: sohbet adı okunamadı")
            return
        }
        val app = applicationContext
        Hub.io.execute { OwnReplies.record(app, ids.packageName, title, text) }
    }

    /** Yeni ekran: sohbet açıldıysa (başlık görünüyorsa) Mesa'da okundu sayılır. */
    private fun onWindow(ids: ChatIds) {
        tracker.reset()
        windowCheck?.let(main::removeCallbacks)
        // Ekran çizilmeden başlık henüz yok; kısa bir süre sonra bakılır.
        val check = Runnable {
            val title = chatTitle(rootInActiveWindow, ids)
            if (title != openChat) {
                openChat = title
                if (title != null) {
                    val app = applicationContext
                    Hub.io.execute { OwnReplies.opened(app, ids.packageName, title) }
                }
            }
            maybeAutoSend(ids)
        }
        windowCheck = check
        main.postDelayed(check, WINDOW_DELAY_MS)
    }

    // ---- Mesa'dan yazılan mesajı WhatsApp'ta gönderme ----

    private fun maybeAutoSend(ids: ChatIds) {
        val pending = OwnReplies.pendingSend ?: return
        val now = System.currentTimeMillis()
        if (now > pending.until) {
            OwnReplies.pendingSend = null
            Log.i(TAG, "Otomatik gönderim: süre doldu, WhatsApp'ta bırakıldı")
            return
        }
        // İçerik olayları sık gelir; ekran en fazla 150 ms'de bir okunur.
        val tick = SystemClock.uptimeMillis()
        if (tick - lastSendCheck < 150) return
        lastSendCheck = tick
        val root = rootInActiveWindow ?: return
        val entry = root.findAccessibilityNodeInfosByViewId(ids.entry).firstOrNull() ?: return
        if (!OwnReplies.shouldAutoSend(pending, ids.packageName, chatTitle(root, ids), entryText(entry), now)) return
        OwnReplies.pendingSend = null
        // Basmadan önce: kutu boşalınca yakalanan metin ikinci kez kaydedilmesin.
        OwnReplies.markSending(pending.key, pending.text)
        tracker.onAutoSend(pending.text)
        if (!pressSend(root, ids)) {
            Log.w(TAG, "Otomatik gönderim: Gönder düğmesi bulunamadı")
            return
        }
        main.postDelayed({ confirmAutoSend(ids, pending, attempt = 1) }, VERIFY_DELAY_MS)
    }

    /** Önce erişilebilir "Gönder" düğmesi; yoksa düğmenin yerine dokunulur. */
    private fun pressSend(root: AccessibilityNodeInfo, ids: ChatIds): Boolean {
        root.findAccessibilityNodeInfosByViewId(ids.send)
            .firstOrNull { it.isVisibleToUser && it.isClickable }
            ?.let { if (it.performAction(AccessibilityNodeInfo.ACTION_CLICK)) return true }
        val button = ids.sendTargets.firstNotNullOfOrNull { id ->
            root.findAccessibilityNodeInfosByViewId(id).firstOrNull { it.isVisibleToUser }
        } ?: return false
        val bounds = Rect().also(button::getBoundsInScreen)
        if (bounds.isEmpty) return false
        val tap = Path().apply { moveTo(bounds.exactCenterX(), bounds.exactCenterY()) }
        val gesture = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(tap, 0, TAP_MS))
            .build()
        return dispatchGesture(gesture, null, null)
    }

    private fun confirmAutoSend(ids: ChatIds, pending: OwnReplies.PendingSend, attempt: Int) {
        val root = rootInActiveWindow
        val entry = root?.findAccessibilityNodeInfosByViewId(ids.entry)?.firstOrNull()
        val sent = entry != null && entryText(entry).isNullOrBlank()
        if (!sent) {
            if (attempt == 1) {
                main.postDelayed({ confirmAutoSend(ids, pending, attempt = 2) }, VERIFY_DELAY_MS)
            } else {
                Log.w(TAG, "Otomatik gönderim doğrulanamadı; WhatsApp'ta bırakıldı")
            }
            return
        }
        OwnReplies.markAutoSent(pending.key)
        Log.i(TAG, "Mesa'dan yazılan mesaj WhatsApp'ta gönderildi")
        if (pending.returnToMesa) {
            // Başlatıcıdaki simgeye dokunmak gibi: Mesa kaldığı yerden öne gelir.
            packageManager.getLaunchIntentForPackage(this.packageName)
                ?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED)
                ?.let(::startActivity)
        }
    }

    // ---- Ekran okuma ----

    /** Kutunun metni; boşken Android ipucunu ("Mesaj") döndürdüğü için ayıklanır. */
    private fun entryText(node: AccessibilityNodeInfo): String? {
        if (Build.VERSION.SDK_INT >= 26 && node.isShowingHintText) return ""
        return node.text?.toString()
    }

    private fun chatTitle(root: AccessibilityNodeInfo?, ids: ChatIds): String? =
        root?.findAccessibilityNodeInfosByViewId(ids.title)
            ?.firstNotNullOfOrNull { it.text?.toString()?.takeIf(String::isNotBlank) }

    override fun onDestroy() {
        main.removeCallbacksAndMessages(null)
        super.onDestroy()
    }

    /** WhatsApp sohbet ekranının öğe kimlikleri (iki uygulamada da aynı adlar). */
    private class ChatIds(val packageName: String) {
        val entry = "$packageName:id/entry"
        val send = "$packageName:id/send"
        val title = "$packageName:id/conversation_contact_name"
        val messageText = "$packageName:id/message_text"

        /** Metin yazılınca gönder olan düğme ve kapları (2.26: voice_note_btn). */
        val sendTargets = listOf(
            "$packageName:id/send",
            "$packageName:id/voice_note_btn",
            "$packageName:id/send_container",
            "$packageName:id/conversation_entry_action_button",
        )
    }

    private companion object {
        const val TAG = "MesajMerkezi"
        const val VERIFY_DELAY_MS = 800L
        const val WINDOW_DELAY_MS = 400L
        const val TAP_MS = 60L
    }
}
