package com.mesajmerkezi.mesaj_merkezi

import android.content.Context
import android.util.Log

/** Saklama süresi temizliği. Hub.io iş parçacığında çağrılır. */
object Maintenance {

    private const val TAG = "MesajMerkezi"
    private const val DAY_MS = 24 * 60 * 60 * 1000L

    /** En son ne zaman çalıştı (süreç içinde); sık bildirimlerde her seferinde silme yapılmasın. */
    @Volatile
    private var lastRun = 0L

    private const val CACHE_EVERY_MS = 7 * DAY_MS
    private const val CACHE_KEY = "cache_cleaned_at"

    /**
     * Haftada bir: Telegram'da 30 gündür açılmamış medya silinir (gerekirse
     * yeniden iner) ki önbellek aylar içinde gigabaytlara çıkmasın. Telegram
     * bağlı değilse sonraya kalır.
     */
    fun cleanCachesIfDue(context: Context) {
        val prefs = context.getSharedPreferences("maintenance", Context.MODE_PRIVATE)
        val now = System.currentTimeMillis()
        if (now - prefs.getLong(CACHE_KEY, 0L) < CACHE_EVERY_MS) return
        if (!TelegramClient.isReady) return
        prefs.edit().putLong(CACHE_KEY, now).apply()
        // TDLib temizliği uzun sürebilir: mesaj işleyen kuyruğu bekletmesin.
        Thread {
            if (TelegramClient.optimizeStorage(30 * 24 * 60 * 60)) {
                Hub.io.execute { Hub.store(context).clearMissingFiles() }
            } else {
                prefs.edit().putLong(CACHE_KEY, 0L).apply()
            }
        }.apply {
            name = "Önbellek temizliği"
            isDaemon = true
        }.start()
    }

    /** Saklama süresi açıksa eski mesajları siler; [force] değilse saatte en fazla bir kez. */
    fun purgeIfDue(context: Context, force: Boolean = false) {
        val days = AppSettings.retentionDays(context)
        if (days <= 0) return
        val now = System.currentTimeMillis()
        if (!force && now - lastRun < 60 * 60 * 1000L) return
        lastRun = now
        val deleted = Hub.store(context).purgeOlderThan(now - days * DAY_MS)
        if (deleted > 0) {
            Log.i(TAG, "Saklama süresi: $deleted eski mesaj silindi ($days gün)")
            Hub.notifyChanged("")
        }
    }
}
