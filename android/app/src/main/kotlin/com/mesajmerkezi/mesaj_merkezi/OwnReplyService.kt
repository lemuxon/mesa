package com.mesajmerkezi.mesaj_merkezi

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Path
import android.graphics.PixelFormat
import android.graphics.Rect
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView

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

    /** Gönder'e basılan, sonucu beklenen mesaj. */
    private var sending: OwnReplies.PendingSend? = null

    /** WhatsApp'ı gizleyen "Gönderiliyor…" örtüsü. */
    private var overlay: View? = null
    private val giveUp = Runnable { onTimeout() }

    override fun onServiceConnected() {
        instance = this
        Log.i(TAG, "WhatsApp yanıt servisi bağlandı")
    }

    override fun onUnbind(intent: Intent?): Boolean {
        instance = null
        removeOverlay()
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        instance = null
        main.removeCallbacksAndMessages(null)
        removeOverlay()
        super.onDestroy()
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

    // ---- WhatsApp'ta yazılan yanıtları yakalama ----

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

    /**
     * Mesa mesajı WhatsApp'a vermek üzere (ana iş parçacığı, WhatsApp
     * açılmadan önce): ekran Mesa'nın "Gönderiliyor…" örtüsüyle kapanır.
     */
    fun beginAutoSend() {
        main.post {
            showOverlay()
            main.removeCallbacks(giveUp)
            main.postDelayed(giveUp, OwnReplies.AUTO_SEND_WINDOW_MS)
        }
    }

    private fun maybeAutoSend(ids: ChatIds) {
        if (sending != null) return
        val pending = OwnReplies.pendingSend ?: return
        // İçerik olayları sık gelir; ekran en fazla 150 ms'de bir okunur.
        val tick = SystemClock.uptimeMillis()
        if (tick - lastSendCheck < 150) return
        lastSendCheck = tick
        val root = rootInActiveWindow ?: return
        val entry = root.findAccessibilityNodeInfosByViewId(ids.entry).firstOrNull()
        val step = OwnReplies.autoSendStep(
            pending, ids.packageName, chatTitle(root, ids), entry?.let(::entryText), System.currentTimeMillis(),
        )
        when (step) {
            OwnReplies.Step.WAIT -> Unit
            OwnReplies.Step.EXPIRED -> onTimeout()
            OwnReplies.Step.FILL -> {
                // Eski bir taslak ya da paylaşımın eklemediği metin: kutu tam olarak Mesa'nın metni olur.
                val args = Bundle().apply {
                    putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, pending.text)
                }
                entry?.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args)
                main.postDelayed({ maybeAutoSend(ids) }, 200)
            }
            OwnReplies.Step.PRESS -> {
                OwnReplies.pendingSend = null
                sending = pending
                // Basmadan önce: kutu boşalınca yakalanan metin ikinci kez kaydedilmesin.
                OwnReplies.markSending(pending.key, pending.text)
                tracker.onAutoSend(pending.text)
                // Düğmenin mikrofondan gönder'e dönmesi ve klavyenin yerleşmesi beklenir.
                main.postDelayed({ press(ids, pending, attempt = 1) }, SETTLE_MS)
            }
        }
    }

    /**
     * Üç deneme: erişilebilir tıklama, düğmenin yerine dokunma, örtüyü
     * kaldırıp yeniden dokunma (WhatsApp örtülü dokunmaları yok sayıyor olabilir).
     */
    private fun press(ids: ChatIds, pending: OwnReplies.PendingSend, attempt: Int) {
        // Süre dolup bittiyse geciken denemeler durur.
        if (sending !== pending) return
        val root = rootInActiveWindow
        if (root == null || chatTitle(root, ids)?.let(Names::title) != pending.title) {
            finish(pending, sent = false, how = "sohbet ekrandan çıktı")
            return
        }
        val pressed = when (attempt) {
            1 -> clickSend(root, ids) || tapSend(root, ids)
            2 -> tapSend(root, ids)
            else -> {
                removeOverlay()
                main.postDelayed({ rootInActiveWindow?.let { tapSend(it, ids) } }, 250)
                true
            }
        }
        if (!pressed) Log.w(TAG, "Otomatik gönderim: Gönder düğmesi bulunamadı (deneme $attempt)")
        val wait = if (attempt == 3) VERIFY_DELAY_MS + 250 else VERIFY_DELAY_MS
        main.postDelayed({ confirm(ids, pending, attempt) }, wait)
    }

    private fun confirm(ids: ChatIds, pending: OwnReplies.PendingSend, attempt: Int) {
        if (sending !== pending) return
        val entry = rootInActiveWindow?.findAccessibilityNodeInfosByViewId(ids.entry)?.firstOrNull()
        if (entry != null && entryText(entry).isNullOrBlank()) {
            finish(pending, sent = true, how = "deneme $attempt")
        } else if (attempt < 3) {
            press(ids, pending, attempt + 1)
        } else {
            rootInActiveWindow?.let { Log.w(TAG, "Otomatik gönderim başarısız; ekran: ${describeInputBar(it, ids)}") }
            // Taslak WhatsApp'ta kalmasın; mesaj Mesa'nın yazma alanına geri konur.
            val args = Bundle().apply {
                putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, "")
            }
            entry?.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args)
            finish(pending, sent = false, how = "üç deneme")
        }
    }

    private fun onTimeout() {
        val pending = sending ?: OwnReplies.pendingSend
        OwnReplies.pendingSend = null
        if (pending == null) {
            removeOverlay()
            return
        }
        finish(pending, sent = false, how = "süre doldu")
    }

    /** Sonuç kaydedilir, Mesa öne gelir, örtü Mesa çizildikten sonra kalkar. */
    private fun finish(pending: OwnReplies.PendingSend, sent: Boolean, how: String) {
        sending = null
        main.removeCallbacks(giveUp)
        OwnReplies.markResult(pending.key, sent)
        if (sent) {
            Log.i(TAG, "Mesa'dan yazılan mesaj WhatsApp'ta gönderildi ($how)")
        } else {
            Log.w(TAG, "Mesa'dan yazılan mesaj gönderilemedi ($how)")
        }
        if (pending.returnToMesa) {
            // Başlatıcıdaki simgeye dokunmak gibi: Mesa kaldığı yerden öne gelir.
            packageManager.getLaunchIntentForPackage(this.packageName)
                ?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED)
                ?.let(::startActivity)
        }
        main.postDelayed({ removeOverlay() }, OVERLAY_LINGER_MS)
    }

    /** Erişilebilir "Gönder" düğmesine (ya da tıklanabilir kabına) tıklar. */
    private fun clickSend(root: AccessibilityNodeInfo, ids: ChatIds): Boolean {
        val candidates = ids.sendTargets.flatMap { root.findAccessibilityNodeInfosByViewId(it) } +
            SEND_LABELS.flatMap { root.findAccessibilityNodeInfosByText(it) }.filter { node ->
                val label = node.contentDescription?.toString() ?: return@filter false
                node.viewIdResourceName?.startsWith(ids.packageName) == true &&
                    SEND_LABELS.any { label.equals(it, ignoreCase = true) }
            }
        for (node in candidates) {
            if (!node.isVisibleToUser) continue
            var target: AccessibilityNodeInfo = node
            // Düğme tıklanamıyorsa en fazla iki üst kabına bakılır.
            repeat(2) { if (!target.isClickable) target.parent?.let { target = it } }
            if (target.isClickable && target.performAction(AccessibilityNodeInfo.ACTION_CLICK)) return true
        }
        return false
    }

    /** Düğmenin ekrandaki yerine dokunur (dokunmayı kendisi işleyen düğme için). */
    private fun tapSend(root: AccessibilityNodeInfo, ids: ChatIds): Boolean {
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

    /** Tanı için yazma çubuğunun yapısı: kimlik, tıklanabilirlik, yer. Metin YAZILMAZ. */
    private fun describeInputBar(root: AccessibilityNodeInfo, ids: ChatIds): String {
        var bar = root.findAccessibilityNodeInfosByViewId(ids.entry).firstOrNull() ?: return "kutu yok"
        repeat(4) { bar.parent?.let { bar = it } }
        val out = mutableListOf<String>()
        fun walk(node: AccessibilityNodeInfo, depth: Int) {
            if (depth > 6 || out.size > 40) return
            val r = Rect().also(node::getBoundsInScreen)
            val name = node.viewIdResourceName?.substringAfter(":id/")
                ?: node.className?.toString()?.substringAfterLast('.')
            val label = node.contentDescription?.takeIf { node.className?.contains("Button") == true }
            out += "$name t=${node.isClickable} g=${node.isVisibleToUser} ${r.toShortString()}" +
                (label?.let { " d=${it.toString().take(20)}" } ?: "")
            for (i in 0 until node.childCount) node.getChild(i)?.let { walk(it, depth + 1) }
        }
        walk(bar, 0)
        return out.joinToString(" | ")
    }

    // ---- Örtü ----

    private fun showOverlay() {
        if (overlay != null) return
        val night = resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK ==
            Configuration.UI_MODE_NIGHT_YES
        val background = if (night) 0xFF121316.toInt() else 0xFFF6F7FA.toInt()
        val foreground = if (night) 0xFFE6E7EA.toInt() else 0xFF1B1C1F.toInt()
        val density = resources.displayMetrics.density
        val view = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(background)
            addView(ProgressBar(context).apply { isIndeterminate = true })
            addView(
                TextView(context).apply {
                    text = getString(R.string.auto_send_progress)
                    setTextColor(foreground)
                    textSize = 16f
                    gravity = Gravity.CENTER
                    setPadding(0, (16 * density).toInt(), 0, 0)
                },
            )
        }
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            // Dokunmalar alttaki WhatsApp'a geçer (servisin dokunuşu da).
            WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.OPAQUE,
        )
        try {
            getSystemService(WindowManager::class.java).addView(view, params)
            overlay = view
        } catch (e: RuntimeException) {
            Log.w(TAG, "Gönderim örtüsü gösterilemedi: ${e.javaClass.simpleName}")
        }
    }

    private fun removeOverlay() {
        val view = overlay ?: return
        overlay = null
        try {
            getSystemService(WindowManager::class.java).removeView(view)
        } catch (e: RuntimeException) {
            Log.w(TAG, "Gönderim örtüsü kaldırılamadı: ${e.javaClass.simpleName}")
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

    companion object {
        private const val TAG = "MesajMerkezi"
        private const val VERIFY_DELAY_MS = 800L
        private const val WINDOW_DELAY_MS = 400L
        private const val SETTLE_MS = 450L
        private const val TAP_MS = 100L
        private const val OVERLAY_LINGER_MS = 700L

        /** WhatsApp'ın Gönder düğmesinin dillerdeki adı. */
        private val SEND_LABELS = listOf("Gönder", "Send", "Enviar", "Senden", "Envoyer", "إرسال", "Отправить")

        /** Bağlı servis; Mesa göndermeden önce örtüyü açtırır. */
        @Volatile
        var instance: OwnReplyService? = null
            private set
    }
}
