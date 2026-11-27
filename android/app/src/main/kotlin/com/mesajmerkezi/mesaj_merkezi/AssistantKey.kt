package com.mesajmerkezi.mesaj_merkezi

import android.content.Context

/**
 * Yapay zekâ asistanının (Claude) API anahtarı: kullanıcının kendi anahtarı.
 *
 * Telefonun güvenli donanım anahtarıyla ([SecretBox]) şifreli saklanır;
 * Mesa'nın yedeklerine ve Android'in bulut yedeğine girmez. Mesa'nın sunucusu
 * yok: anahtar yalnızca kullanıcı asistana bir iş verdiğinde, telefondan
 * api.anthropic.com'a giden istekte kullanılır.
 */
object AssistantKey {
    private const val PREFS = "assistant"
    private const val KEY = "api_key"

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun set(context: Context, key: String) {
        prefs(context).edit().putString(KEY, SecretBox.encrypt(key.trim())).apply()
    }

    /** Anahtar; yoksa ya da açılamıyorsa (güvenli donanım anahtarı silinmiş) null. */
    fun get(context: Context): String? = prefs(context).getString(KEY, null)?.let(SecretBox::decrypt)

    fun present(context: Context): Boolean = get(context) != null

    fun clear(context: Context) {
        prefs(context).edit().remove(KEY).apply()
    }
}
