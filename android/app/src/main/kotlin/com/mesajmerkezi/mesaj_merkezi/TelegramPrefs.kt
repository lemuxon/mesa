package com.mesajmerkezi.mesaj_merkezi

import android.content.Context

/**
 * Telegram (TDLib) bağlantısının kalıcı durumu. Bildirim servisi ve açılış
 * alıcısı da okur; bu yüzden bellekte değil diskte tutulur.
 */
object TelegramPrefs {

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences("telegram", Context.MODE_PRIVATE)

    /** Kullanıcı bağlantıyı açtı; servis telefon açılınca da başlatılır. */
    fun enabled(context: Context) = prefs(context).getBoolean("enabled", false)

    fun setEnabled(context: Context, value: Boolean) =
        prefs(context).edit().putBoolean("enabled", value).apply()

    /**
     * Oturum açık. Bu sürede Telegram bildirimleri yok sayılır; mesajlar
     * TDLib'den gelir, iki kaynak birden aynı mesajı çift kaydederdi.
     */
    fun loggedIn(context: Context) = prefs(context).getBoolean("logged_in", false)

    fun setLoggedIn(context: Context, value: Boolean) =
        prefs(context).edit().putBoolean("logged_in", value).apply()
}
