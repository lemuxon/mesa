package com.mesajmerkezi.mesaj_merkezi

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * Uygulamanın kapladığı yer ve önbellek temizliği. Mesajlar, kişiler, kurallar
 * ve oturumlar hiç silinmez; yalnızca yeniden elde edilebilen dosyalar
 * (Telegram'ın yeniden indirebildiği medya, web önbelleği, gönderim kopyaları).
 * Arka plan iş parçacığında çağrılmalı (ana iş parçacığında değil).
 */
object Storage {

    private const val TAG = "MesajMerkezi"
    private const val DAY_S = 24 * 60 * 60

    /** Kategoriye göre bayt. */
    fun usage(context: Context): Map<String, Long> {
        val db = context.getDatabasePath("mesajlar.db")
        val database = listOf("", "-wal", "-shm", "-journal").sumOf { File(db.path + it).length() }
        val files = context.filesDir
        val cache = context.cacheDir
        val webCache = File(cache, "WebView")
        return mapOf(
            "database" to database,
            "media" to listOf("media", "avatars", "web_icons").sumOf { dirSize(File(files, it)) },
            "telegram" to dirSize(File(files, "tdlib")) + dirSize(File(context.noBackupFilesDir, "tdlib_files")),
            "web" to dirSize(File(context.dataDir, "app_webview")) + dirSize(webCache),
            "temporary" to (dirSize(cache) - dirSize(webCache)).coerceAtLeast(0),
        )
    }

    /**
     * Elle "Önbelleği temizle": Telegram'da [telegramDays] gündür açılmamış
     * medya, web servislerinin önbelleği (oturumlar kalır) ve gönderim
     * kopyaları. Boşalan bayt.
     */
    fun clean(context: Context, telegramDays: Int = 7): Long {
        val before = usage(context).values.sum()
        MediaTools.outbox(context).listFiles()
            ?.filter { System.currentTimeMillis() - it.lastModified() > 60 * 60 * 1000L }
            ?.forEach { it.delete() }
        TelegramClient.optimizeStorage(telegramDays * DAY_S)
        clearWebCaches()
        Hub.store(context).clearMissingFiles()
        val freed = (before - usage(context).values.sum()).coerceAtLeast(0)
        Log.i(TAG, "Önbellek temizlendi: ${freed / 1024 / 1024} MB")
        return freed
    }

    /** Web görünümlerinin önbelleği ana iş parçacığında temizlenir; en fazla 5 sn beklenir. */
    private fun clearWebCaches() {
        val done = CountDownLatch(1)
        Handler(Looper.getMainLooper()).post {
            try {
                WebHost.clearCaches()
            } finally {
                done.countDown()
            }
        }
        done.await(5, TimeUnit.SECONDS)
    }

    private fun dirSize(dir: File): Long {
        if (!dir.exists()) return 0
        return dir.walkTopDown().filter { it.isFile }.sumOf { it.length() }
    }
}
