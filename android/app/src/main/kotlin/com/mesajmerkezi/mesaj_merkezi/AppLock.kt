package com.mesajmerkezi.mesaj_merkezi

import android.app.Activity
import android.app.Application
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.os.SystemClock

/**
 * Uygulama kilidinin zamanlaması: uygulamanın hiçbir ekranı görünmüyorken
 * [relockAfterMs]'den uzun kalınca yeniden kilitlenir. Ekranlar arası geçiş
 * (gelen kutusu → web servisi) arka plan sayılmaz. Android'den bağımsız.
 */
class AppLockState(private val relockAfterMs: Long = 30_000L) {

    /** Süreç yeni başladıysa kilitli: önce kimlik doğrulanmalı. */
    @Volatile
    var locked = true
        private set

    /** Doğrulama penceresi uygulamayı arkaya itebilir; o sırada kilitlenmesin. */
    @Volatile
    var authenticating = false

    private var started = 0
    private var backgroundSince = -1L

    fun onStarted(now: Long) {
        if (started == 0 && backgroundSince >= 0 && !authenticating && now - backgroundSince >= relockAfterMs) {
            locked = true
        }
        started++
        backgroundSince = -1L
    }

    fun onStopped(now: Long) {
        if (started > 0) started--
        if (started == 0) backgroundSince = now
    }

    fun unlock() {
        locked = false
    }

    fun lock() {
        locked = true
    }
}

/**
 * Uygulama kilidi yerel tarafta da geçerli: web servisi sayfası (yerel ekran)
 * bildirimden açılınca Flutter'daki kilit ekranı devreye girmiyordu
 * (2026-10-11 güvenlik denetimi). Kilit açık mı bilgisi Flutter'ın ayarından
 * ve buradaki kopyasından okunur; biri açıksa kilit var sayılır.
 */
object AppLock {

    private const val PREFS = "app_lock"
    private const val KEY_ENABLED = "enabled"

    val state = AppLockState()

    @Volatile
    private var installed = false

    fun enabled(context: Context): Boolean {
        val own = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getBoolean(KEY_ENABLED, false)
        val flutter = try {
            context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                .getBoolean("flutter.lock_enabled", false)
        } catch (e: ClassCastException) {
            false
        }
        return own || flutter
    }

    /** Flutter tarafı kilidi açıp kapatınca (ve açılışta) çağırır. */
    fun setEnabled(context: Context, value: Boolean) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putBoolean(KEY_ENABLED, value).apply()
    }

    fun isLocked(context: Context) = enabled(context) && state.locked

    /** Uygulamanın ekranlarını sayar (ön plan / arka plan). Birden çok kez çağrılabilir. */
    fun install(app: Application) {
        if (installed) return
        installed = true
        app.registerActivityLifecycleCallbacks(object : Application.ActivityLifecycleCallbacks {
            override fun onActivityStarted(activity: Activity) = state.onStarted(SystemClock.elapsedRealtime())
            override fun onActivityStopped(activity: Activity) = state.onStopped(SystemClock.elapsedRealtime())
            override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}
            override fun onActivityResumed(activity: Activity) {}
            override fun onActivityPaused(activity: Activity) {}
            override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}
            override fun onActivityDestroyed(activity: Activity) {}
        })
    }

    /**
     * Kilit açıksa "Son uygulamalar"daki küçük resimde içerik görünmesin
     * (Android 13+; ekran görüntüsü almak yine serbest).
     */
    fun applyRecentsPrivacy(activity: Activity) {
        if (Build.VERSION.SDK_INT >= 33) activity.setRecentsScreenshotEnabled(!enabled(activity))
    }
}
