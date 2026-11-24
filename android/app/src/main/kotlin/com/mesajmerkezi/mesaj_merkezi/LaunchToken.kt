package com.mesajmerkezi.mesaj_merkezi

import android.content.Context
import android.content.Intent
import android.net.Uri
import java.security.MessageDigest
import java.security.SecureRandom

/**
 * MainActivity dışa açık (başlatıcı ekranı). Önceden "conversation_key"
 * ekstrasını her niyetten okuyordu: telefondaki başka bir uygulama Mesa'yı
 * istediği sohbet ekranıyla açtırabiliyordu (2026-10-14 genel tarama, düşük
 * önem). Artık sohbet açan niyetler yalnızca Mesa'nın kendi oluşturduğu
 * niyetlerdir: kuruluma özgü, rastgele bir belirteç taşırlar ve MainActivity
 * belirteci sabit zamanlı karşılaştırır.
 *
 * Belirteç uygulamanın özel tercihlerinde durur (yedeğe ve cihaz aktarımına
 * girmez). Sistem kısayollarında saklanan niyetler de aynı belirteci taşır.
 */
object LaunchToken {

    const val EXTRA_TOKEN = "mesa_launch_token"
    private const val PREFS = "launch_token"
    private const val KEY = "token"

    @Volatile
    private var cached: String? = null

    fun get(context: Context): String {
        cached?.let { return it }
        synchronized(this) {
            cached?.let { return it }
            val prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val token = prefs.getString(KEY, null) ?: ByteArray(24)
                .also(SecureRandom()::nextBytes)
                .joinToString("") { "%02x".format(it) }
                .also { prefs.edit().putString(KEY, it).apply() }
            cached = token
            return token
        }
    }

    /**
     * Mesa'da [key] sohbetini açan niyet. Veri adresi sohbete özgüdür: iki
     * farklı sohbetin PendingIntent'i, istek kodları çakışsa bile birbirinin
     * yerine geçmez (PendingIntent eşitliği ekstralara bakmaz).
     */
    fun conversationIntent(context: Context, key: String, scope: String): Intent =
        Intent(context, MainActivity::class.java)
            .setData(uniqueData(scope, key))
            .putExtra(UnifiedNotifier.EXTRA_KEY, key)
            .putExtra(EXTRA_TOKEN, get(context))

    /** Niyet Mesa'nın kendisinden geldiyse açılacak sohbet; değilse null. */
    fun conversationKey(context: Context, intent: Intent?): String? {
        val key = intent?.getStringExtra(UnifiedNotifier.EXTRA_KEY) ?: return null
        val token = intent.getStringExtra(EXTRA_TOKEN) ?: return null
        val expected = get(context)
        return key.takeIf {
            MessageDigest.isEqual(token.toByteArray(Charsets.UTF_8), expected.toByteArray(Charsets.UTF_8))
        }
    }

    /**
     * PendingIntent'leri birbirinden ayıran veri adresi ("mesa://<kapsam>/<değer>").
     * Yalnızca eşitlik için; hiçbir bileşen bu adresi işlemez.
     */
    fun uniqueData(scope: String, value: String): Uri =
        Uri.Builder().scheme("mesa").authority(scope).appendPath(value).build()
}
