package com.mesajmerkezi.mesaj_merkezi

import android.app.PendingIntent
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.webkit.ValueCallback
import android.webkit.WebChromeClient
import android.widget.FrameLayout
import android.widget.HorizontalScrollView
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import androidx.activity.OnBackPressedCallback
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.widget.Toolbar
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.core.graphics.ColorUtils
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import org.json.JSONObject
import kotlin.math.max

/**
 * Bir web servisinin sayfası (Ferdium'daki sekme). Altta, birden çok servis
 * eklendiyse aralarında geçiş şeridi. Görünümün kendisi WebHost'ta yaşar;
 * ekran kapanınca site arka planda bağlı kalır.
 */
class WebServiceActivity : AppCompatActivity(), WebHostUi {

    private lateinit var root: LinearLayout
    private lateinit var toolbar: Toolbar
    private lateinit var progress: ProgressBar
    private lateinit var container: FrameLayout
    private lateinit var stripScroll: HorizontalScrollView
    private lateinit var strip: LinearLayout
    private lateinit var lockCover: View
    private lateinit var lockMessage: TextView
    private var currentId: String? = null
    private var fileCallback: ValueCallback<Array<Uri>>? = null

    private val night
        get() = resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK == Configuration.UI_MODE_NIGHT_YES
    private val surface get() = if (night) 0xFF1B1B1F.toInt() else Color.WHITE
    private val onSurface get() = if (night) 0xFFE4E2E6.toInt() else 0xFF1B1B1F.toInt()

    private val pickFiles = registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
        fileCallback?.onReceiveValue(WebChromeClient.FileChooserParams.parseResult(result.resultCode, result.data))
        fileCallback = null
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        AppLock.install(application)
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        buildLayout()
        onBackPressedDispatcher.addCallback(
            this,
            object : OnBackPressedCallback(true) {
                override fun handleOnBackPressed() {
                    val view = currentId?.let(WebHost::view)
                    if (view != null && view.canGoBack()) view.goBack() else finish()
                }
            },
        )
        val id = intent.getStringExtra(EXTRA_ID)
        if (id == null) {
            finish()
            return
        }
        show(id, intent.getStringExtra(EXTRA_CLICK))
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val id = intent.getStringExtra(EXTRA_ID) ?: return
        show(id, intent.getStringExtra(EXTRA_CLICK))
    }

    override fun onResume() {
        super.onResume()
        AppLock.applyRecentsPrivacy(this)
        // Uygulama kilitliyse sayfa görünmez; kimlik doğrulanınca açılır.
        if (AppLock.isLocked(this)) {
            showLockCover(true)
            promptUnlock()
        } else {
            showLockCover(false)
            currentId?.let(WebHost::setVisible)
        }
    }

    private fun showLockCover(locked: Boolean) {
        lockCover.visibility = if (locked) View.VISIBLE else View.GONE
        root.importantForAccessibility =
            if (locked) View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS else View.IMPORTANT_FOR_ACCESSIBILITY_AUTO
    }

    private fun promptUnlock() {
        if (AppLock.state.authenticating) return
        val authenticators = BiometricManager.Authenticators.BIOMETRIC_WEAK or
            BiometricManager.Authenticators.DEVICE_CREDENTIAL
        if (BiometricManager.from(this).canAuthenticate(authenticators) != BiometricManager.BIOMETRIC_SUCCESS) {
            lockMessage.text = Lang.str(this, R.string.lock_needs_screen_lock)
            return
        }
        AppLock.state.authenticating = true
        val callback = object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                AppLock.state.authenticating = false
                AppLock.state.unlock()
                showLockCover(false)
                currentId?.let(WebHost::setVisible)
            }

            override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                AppLock.state.authenticating = false
            }
        }
        BiometricPrompt(this, ContextCompat.getMainExecutor(this), callback).authenticate(
            BiometricPrompt.PromptInfo.Builder()
                .setTitle(Lang.str(this, R.string.locked_title))
                .setSubtitle(Lang.str(this, R.string.verify_to_continue))
                .setAllowedAuthenticators(authenticators)
                .build()
        )
    }

    override fun onPause() {
        // Ekran arkadayken sitenin bildirimleri gösterilsin.
        WebHost.setVisible(null)
        super.onPause()
    }

    @Suppress("DEPRECATION")
    override fun finish() {
        super.finish()
        overridePendingTransition(0, R.anim.web_exit)
    }

    override fun onDestroy() {
        currentId?.let(WebHost::detach)
        WebHost.release(this)
        fileCallback?.onReceiveValue(null)
        fileCallback = null
        super.onDestroy()
    }

    private fun show(id: String, clickId: String?) {
        val service = WebServices.get(this, id)
        if (service == null) {
            finish()
            return
        }
        currentId?.takeIf { it != id }?.let(WebHost::detach)
        currentId = id
        applyChrome(service)
        val view = WebHost.attach(this, this, container, id) ?: return
        for (i in container.childCount - 1 downTo 0) {
            if (container.getChildAt(i) !== view) container.removeViewAt(i)
        }
        // Bildirime dokunuldu: sitenin kendi tıklama işleyicisi ilgili sohbeti açar.
        if (clickId != null) {
            view.evaluateJavascript("window.__mmClick && window.__mmClick(${JSONObject.quote(clickId)})", null)
        }
        renderStrip()
    }

    // ---- Görünüm ----

    private fun buildLayout() {
        root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(surface)
        }
        toolbar = Toolbar(this).apply {
            minimumHeight = dp(56)
            setNavigationIcon(androidx.appcompat.R.drawable.abc_ic_ab_back_material)
            navigationContentDescription = Lang.str(this@WebServiceActivity, R.string.back)
            setNavigationOnClickListener { finish() }
        }
        buildMenu()
        progress = ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal).apply {
            max = 100
            visibility = View.GONE
        }
        container = FrameLayout(this)
        strip = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(dp(8), dp(6), dp(8), dp(6))
        }
        stripScroll = HorizontalScrollView(this).apply {
            isHorizontalScrollBarEnabled = false
            setBackgroundColor(surface)
            addView(strip)
        }
        root.addView(toolbar, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        root.addView(progress, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(3)))
        root.addView(container, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f))
        root.addView(stripScroll, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        lockCover = buildLockCover()
        setContentView(
            FrameLayout(this).apply {
                addView(root, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
                addView(lockCover, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
            }
        )

        // Kenardan kenara: üst çubuk durum çubuğunun altına uzanır, klavye açılınca sayfa küçülür.
        ViewCompat.setOnApplyWindowInsetsListener(root) { _, insets ->
            val bars = insets.getInsets(WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout())
            val ime = insets.getInsets(WindowInsetsCompat.Type.ime())
            toolbar.setPadding(bars.left, bars.top, bars.right, 0)
            root.setPadding(0, 0, 0, max(bars.bottom, ime.bottom))
            stripScroll.setPadding(bars.left, 0, bars.right, 0)
            WindowInsetsCompat.CONSUMED
        }
        WindowCompat.getInsetsController(window, window.decorView).isAppearanceLightNavigationBars = !night
    }

    /** Kilitliyken sayfanın üstünü tamamen örten ekran (dokunuşları da yutar). */
    private fun buildLockCover(): View {
        lockMessage = TextView(this).apply {
            text = "Mesa kilitli"
            setTextColor(onSurface)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
            gravity = Gravity.CENTER
        }
        val icon = TextView(this).apply {
            text = "🔒"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 48f)
            gravity = Gravity.CENTER
        }
        val button = android.widget.Button(this).apply {
            text = Lang.str(this@WebServiceActivity, R.string.unlock)
            setOnClickListener { promptUnlock() }
        }
        val column = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            addView(icon)
            addView(lockMessage, LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply { topMargin = dp(12) })
            addView(button, LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply { topMargin = dp(24) })
        }
        return FrameLayout(this).apply {
            setBackgroundColor(surface)
            isClickable = true
            isFocusable = true
            visibility = View.GONE
            addView(column, FrameLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT, Gravity.CENTER))
        }
    }

    private fun buildMenu() {
        val menu = toolbar.menu
        fun label(id: Int) = Lang.str(this, id)
        menu.add(0, MENU_RELOAD, 0, label(R.string.menu_reload))
        menu.add(0, MENU_HOME, 1, label(R.string.menu_home))
        menu.add(0, MENU_BROWSER, 2, label(R.string.menu_browser))
        menu.add(0, MENU_DESKTOP, 3, label(R.string.menu_desktop)).isCheckable = true
        menu.add(0, MENU_WIDE, 4, label(R.string.menu_fit)).isCheckable = true
        menu.add(0, MENU_AUTOPLAY, 5, label(R.string.menu_autoplay)).isCheckable = true
        menu.add(0, MENU_ZOOM, 6, label(R.string.menu_zoom))
        menu.add(0, MENU_LOGOUT, 7, label(R.string.menu_logout))
        toolbar.setOnMenuItemClickListener { item ->
            val id = currentId ?: return@setOnMenuItemClickListener false
            val service = WebServices.get(this, id) ?: return@setOnMenuItemClickListener false
            when (item.itemId) {
                MENU_RELOAD -> WebHost.view(id)?.reload()
                MENU_HOME -> WebHost.view(id)?.loadUrl(service.url)
                MENU_BROWSER -> openInBrowser(WebHost.view(id)?.url ?: service.url)
                MENU_DESKTOP -> changeAndReload(id) { it.copy(desktop = !it.desktop) }
                MENU_WIDE -> changeAndReload(id) { it.copy(wide = !it.wide) }
                MENU_AUTOPLAY -> changeAndReload(id) { it.copy(autoplay = !it.autoplay) }
                MENU_ZOOM -> chooseZoom(service)
                MENU_LOGOUT -> confirmLogout(service)
                else -> return@setOnMenuItemClickListener false
            }
            true
        }
    }

    private fun applyChrome(service: WebService) {
        val color = service.color
        val light = ColorUtils.calculateLuminance(color) > 0.6
        val onColor = if (light) 0xFF1B1B1F.toInt() else Color.WHITE
        toolbar.setBackgroundColor(color)
        toolbar.title = service.name
        toolbar.setTitleTextColor(onColor)
        toolbar.navigationIcon?.setTint(onColor)
        toolbar.overflowIcon?.setTint(onColor)
        progress.setBackgroundColor(color)
        progress.progressTintList = ColorStateList.valueOf(onColor)
        WindowCompat.getInsetsController(window, window.decorView).isAppearanceLightStatusBars = light
        toolbar.menu.findItem(MENU_DESKTOP)?.isChecked = service.desktop
        toolbar.menu.findItem(MENU_WIDE)?.isChecked = service.wide
        toolbar.menu.findItem(MENU_AUTOPLAY)?.isChecked = service.autoplay
        toolbar.menu.findItem(MENU_LOGOUT)?.isVisible = WebHost.profilesSupported()
    }

    /** Birden çok servis varsa altta Ferdium'daki gibi geçiş şeridi. */
    private fun renderStrip() {
        val services = WebServices.all(this)
        stripScroll.visibility = if (services.size > 1) View.VISIBLE else View.GONE
        strip.removeAllViews()
        if (services.size <= 1) return
        for (service in services) strip.addView(stripItem(service))
    }

    private fun stripItem(service: WebService): View {
        val selected = service.id == currentId
        val size = dp(48)
        val item = FrameLayout(this).apply {
            contentDescription = service.name
            background = GradientDrawable().apply {
                cornerRadius = dp(14).toFloat()
                setColor(if (selected) ColorUtils.setAlphaComponent(service.color, 56) else Color.TRANSPARENT)
            }
            setOnClickListener { if (service.id != currentId) show(service.id, null) }
        }
        val icon = ImageView(this).apply {
            setImageBitmap(WebIcons.bitmap(this@WebServiceActivity, service.id) ?: letterIcon(service, dp(28)))
        }
        item.addView(icon, FrameLayout.LayoutParams(dp(28), dp(28), Gravity.CENTER))
        val unread = WebHost.unreadOf(service.id)
        if (unread != 0) {
            val badge = TextView(this).apply {
                text = when {
                    unread == WebTitles.DOT -> ""
                    unread > 99 -> "99+"
                    else -> unread.toString()
                }
                setTextColor(Color.WHITE)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 10f)
                typeface = Typeface.DEFAULT_BOLD
                gravity = Gravity.CENTER
                minWidth = dp(if (unread == WebTitles.DOT) 10 else 18)
                setPadding(dp(4), 0, dp(4), 0)
                background = GradientDrawable().apply {
                    cornerRadius = dp(9).toFloat()
                    setColor(0xFFE53935.toInt())
                    setStroke(dp(2), surface)
                }
            }
            val badgeHeight = dp(if (unread == WebTitles.DOT) 10 else 18)
            item.addView(
                badge,
                FrameLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, badgeHeight, Gravity.TOP or Gravity.END),
            )
        }
        return item.apply {
            layoutParams = LinearLayout.LayoutParams(size, size).apply { marginEnd = dp(6) }
        }
    }

    private fun letterIcon(service: WebService, size: Int): Bitmap {
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = service.color }
        canvas.drawCircle(size / 2f, size / 2f, size / 2f, paint)
        paint.color = if (ColorUtils.calculateLuminance(service.color) > 0.6) Color.BLACK else Color.WHITE
        paint.textSize = size * 0.5f
        paint.typeface = Typeface.DEFAULT_BOLD
        paint.textAlign = Paint.Align.CENTER
        val letter = service.name.take(1).uppercase()
        canvas.drawText(letter, size / 2f, size / 2f - (paint.descent() + paint.ascent()) / 2, paint)
        return bitmap
    }

    // ---- Menü eylemleri ----

    private fun changeAndReload(id: String, change: (WebService) -> WebService) {
        val updated = WebServices.update(this, id, change) ?: return
        applyChrome(updated)
        WebHost.reload(this, id)
        WebHost.onChanged?.invoke()
    }

    private fun chooseZoom(service: WebService) {
        val options = intArrayOf(80, 90, 100, 115, 130, 150)
        val labels = options.map { "%$it" }.toTypedArray()
        AlertDialog.Builder(this)
            .setTitle(Lang.str(this, R.string.menu_zoom))
            .setSingleChoiceItems(labels, options.indexOf(service.zoom).coerceAtLeast(0)) { dialog, which ->
                val zoom = options[which]
                WebServices.update(this, service.id) { it.copy(zoom = zoom) }
                WebHost.view(service.id)?.settings?.textZoom = zoom
                dialog.dismiss()
            }
            .setNegativeButton(Lang.str(this, R.string.cancel), null)
            .show()
    }

    private fun confirmLogout(service: WebService) {
        AlertDialog.Builder(this)
            .setTitle(Lang.str(this, R.string.logout_title, service.name))
            .setMessage(Lang.str(this, R.string.logout_message))
            .setPositiveButton(Lang.str(this, R.string.menu_logout)) { _, _ -> WebHost.logout(this, service.id) }
            .setNegativeButton(Lang.str(this, R.string.cancel), null)
            .show()
    }

    private fun openInBrowser(url: String) {
        try {
            startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)).addCategory(Intent.CATEGORY_BROWSABLE))
        } catch (e: ActivityNotFoundException) {
            // Tarayıcı yok.
        }
    }

    // ---- WebHostUi ----

    override fun onProgress(id: String, progress: Int) {
        if (id != currentId) return
        this.progress.visibility = if (progress in 1..99) View.VISIBLE else View.GONE
        this.progress.progress = progress
    }

    override fun onServicesChanged() {
        if (isFinishing || isDestroyed) return
        val id = currentId ?: return
        val service = WebServices.get(this, id)
        if (service == null) {
            finish()
            return
        }
        // Oturum kapatıldı ya da tarayıcı süreci yeniden başladı: görünüm yeniden bağlanır.
        val view = WebHost.view(id)
        if (view == null || view.parent !== container) WebHost.attach(this, this, container, id)
        applyChrome(service)
        renderStrip()
    }

    override fun showFileChooser(
        callback: ValueCallback<Array<Uri>>,
        params: WebChromeClient.FileChooserParams,
    ): Boolean {
        fileCallback?.onReceiveValue(null)
        fileCallback = callback
        return try {
            pickFiles.launch(params.createIntent())
            true
        } catch (e: ActivityNotFoundException) {
            fileCallback = null
            false
        }
    }

    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()

    companion object {
        private const val EXTRA_ID = "web_service_id"
        private const val EXTRA_CLICK = "web_click_id"
        private const val MENU_RELOAD = 1
        private const val MENU_HOME = 2
        private const val MENU_BROWSER = 3
        private const val MENU_DESKTOP = 4
        private const val MENU_WIDE = 5
        private const val MENU_ZOOM = 6
        private const val MENU_LOGOUT = 7
        private const val MENU_AUTOPLAY = 8

        /** Servis sayfasını kısa bir geçişle açar (varsayılan kayma ~300 ms). */
        @Suppress("DEPRECATION")
        fun open(activity: android.app.Activity, id: String, clickId: String?) {
            activity.startActivity(intent(activity, id, clickId))
            activity.overridePendingTransition(R.anim.web_enter, R.anim.web_hold)
        }

        fun intent(context: Context, id: String, clickId: String?): Intent =
            Intent(context, WebServiceActivity::class.java)
                .putExtra(EXTRA_ID, id)
                .apply { if (clickId != null) putExtra(EXTRA_CLICK, clickId) }

        fun pendingIntent(context: Context, id: String, clickId: String?): PendingIntent =
            PendingIntent.getActivity(
                context,
                "web|$id|$clickId".hashCode(),
                intent(context, id, clickId).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
    }
}
