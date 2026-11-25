package com.mesajmerkezi.mesaj_merkezi

import android.accessibilityservice.AccessibilityService
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

/**
 * WhatsApp'ta yazılan yanıtları Mesa'ya ekleyen isteğe bağlı erişilebilirlik
 * servisi ([OwnReplies]). Sistem yalnızca WhatsApp ve WhatsApp Business
 * olaylarını iletir (res/xml/own_replies.xml); kullanıcı Android'in
 * Erişilebilirlik ayarından açar ve kapatır.
 */
class OwnReplyService : AccessibilityService() {

    private val tracker = ReplyTracker()
    private val main = Handler(Looper.getMainLooper())

    /** En son açık görülen sohbet; aynı sohbet için tekrar okundu yazılmasın. */
    private var openChat: String? = null
    private var windowCheck: Runnable? = null

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
            }
        } catch (e: RuntimeException) {
            // WhatsApp'ın ekranı habersiz değişebilir; servis düşmemeli.
            Log.w(TAG, "WhatsApp olayı işlenemedi: ${e.javaClass.simpleName}")
        }
    }

    private fun onText(event: AccessibilityEvent, ids: ChatIds) {
        if (event.source?.viewIdResourceName != ids.entry) return
        val candidate = tracker.onTextChanged(
            text = event.text.joinToString(""),
            before = event.beforeText?.toString(),
            removed = event.removedCount,
            added = event.addedCount,
        ) ?: return
        // Enter ile gönderim: metin sohbet listesinde belirince kaydedilir.
        main.postDelayed({ verify(ids, candidate) }, VERIFY_DELAY_MS)
    }

    private fun onClick(event: AccessibilityEvent, ids: ChatIds) {
        if (event.source?.viewIdResourceName != ids.send) return
        val text = tracker.onSendClicked() ?: return
        record(ids, text)
    }

    private fun verify(ids: ChatIds, text: String) {
        val root = rootInActiveWindow
        val shown = root?.findAccessibilityNodeInfosByViewId(ids.messageText)
            ?.any { it.text?.toString()?.trim() == text } == true
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
            if (title == openChat) return@Runnable
            openChat = title
            if (title != null) {
                val app = applicationContext
                Hub.io.execute { OwnReplies.opened(app, ids.packageName, title) }
            }
        }
        windowCheck = check
        main.postDelayed(check, WINDOW_DELAY_MS)
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
    }

    private companion object {
        const val TAG = "MesajMerkezi"
        const val VERIFY_DELAY_MS = 800L
        const val WINDOW_DELAY_MS = 400L
    }
}
