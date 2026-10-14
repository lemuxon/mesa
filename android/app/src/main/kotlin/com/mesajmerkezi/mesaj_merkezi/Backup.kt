package com.mesajmerkezi.mesaj_merkezi

import android.content.Context
import android.database.DatabaseUtils
import android.database.sqlite.SQLiteDatabase
import android.util.Log
import org.json.JSONObject
import java.io.File
import java.io.FilterOutputStream
import java.io.InputStream
import java.io.OutputStream
import java.util.concurrent.Callable
import java.util.concurrent.ExecutionException
import java.util.zip.ZipEntry
import java.util.zip.ZipInputStream
import java.util.zip.ZipOutputStream

/**
 * Şifreli yedek: mesaj veritabanı (mesajlar, kişiler, kurallar, planlı
 * mesajlar, kaydedilenler) ve bildirimden gelen fotoğraflar / profil
 * resimleri. Telegram oturumu ve web servisi girişleri bilerek dışarıda
 * (güvenlik anahtarları; yeni telefonda yeniden giriş yapılır).
 *
 * Ana iş parçacığında ya da Hub.io'da DEĞİL, ayrı bir iş parçacığında
 * çağrılmalı: veritabanına dokunan kısım Hub.io'da sırayla yürütülür.
 */
object Backup {

    private const val TAG = "MesajMerkezi"
    private const val DB = "mesajlar.db"
    private const val MANIFEST = "manifest.json"
    private val FOLDERS = listOf("media", "avatars")

    data class Summary(val messages: Int, val files: Int, val bytes: Long)

    fun export(context: Context, out: OutputStream, password: CharArray): Summary {
        val app = context.applicationContext
        val snapshot = File(app.cacheDir, "yedek-$DB")
        try {
            // Tutarlı kopya: yazma kuyruğunda, başka iş veritabanına yazmazken.
            val messages = onIo {
                val store = Hub.store(app)
                store.writableDatabase.rawQuery("PRAGMA wal_checkpoint(FULL)", null).use { it.moveToFirst() }
                app.getDatabasePath(DB).copyTo(snapshot, overwrite = true)
                store.messageCount()
            }
            val counting = CountingStream(out)
            var files = 0
            ZipOutputStream(BackupCrypto.Writer(counting, password)).use { zip ->
                zip.putNextEntry(ZipEntry(MANIFEST))
                zip.write(
                    JSONObject()
                        .put("app", "Mesa")
                        .put("format", 1)
                        .put("dbVersion", DB_VERSION)
                        .put("created", System.currentTimeMillis())
                        .put("messages", messages)
                        .toString()
                        .toByteArray()
                )
                zip.closeEntry()
                zip.putNextEntry(ZipEntry(DB))
                snapshot.inputStream().use { it.copyTo(zip) }
                zip.closeEntry()
                for (folder in FOLDERS) {
                    File(app.filesDir, folder).listFiles()?.filter { it.isFile }?.forEach { file ->
                        zip.putNextEntry(ZipEntry("$folder/${file.name}"))
                        file.inputStream().use { it.copyTo(zip) }
                        zip.closeEntry()
                        files++
                    }
                }
            }
            Log.i(TAG, "Yedek alındı: $messages mesaj, $files dosya, ${counting.count / 1024} KB")
            return Summary(messages, files, counting.count)
        } finally {
            snapshot.delete()
            password.fill('\u0000')
        }
    }

    /**
     * Yedeği geri yükler: bu telefondaki mesajlar yedektekiyle DEĞİŞİR.
     * Şifre yanlışsa [WrongPasswordException], dosya bozuksa
     * [CorruptBackupException]; bu durumlarda mevcut veriye dokunulmaz.
     */
    fun restore(context: Context, input: InputStream, password: CharArray): Summary {
        val app = context.applicationContext
        val temp = File(app.cacheDir, "geri-yukleme").apply {
            deleteRecursively()
            mkdirs()
        }
        try {
            var files = 0
            var manifest = false
            ZipInputStream(BackupCrypto.Reader(input, password)).use { zip ->
                while (true) {
                    val entry = zip.nextEntry ?: break
                    val target = safeTarget(temp, entry.name) ?: continue
                    target.parentFile?.mkdirs()
                    target.outputStream().use { zip.copyTo(it) }
                    if (entry.name == MANIFEST) manifest = true
                    if ('/' in entry.name) files++
                }
            }
            val db = File(temp, DB)
            if (!manifest || !db.exists()) throw CorruptBackupException(R.string.backup_no_db)
            val (version, messages) = try {
                SQLiteDatabase.openDatabase(db.path, null, SQLiteDatabase.OPEN_READONLY).use { d ->
                    d.version to DatabaseUtils.queryNumEntries(d, "messages").toInt()
                }
            } catch (e: RuntimeException) {
                throw CorruptBackupException(R.string.backup_db_open)
            }
            if (version > DB_VERSION) {
                throw CorruptBackupException(R.string.backup_newer)
            }
            // Dosya değişimi yazma kuyruğunda: o sırada hiçbir iş veritabanına dokunmaz.
            onIo {
                Hub.closeStore()
                val live = app.getDatabasePath(DB)
                listOf("", "-wal", "-shm", "-journal").forEach { File(live.path + it).delete() }
                db.copyTo(live, overwrite = true)
                for (folder in FOLDERS) {
                    val destination = File(app.filesDir, folder).apply { mkdirs() }
                    File(temp, folder).listFiles()?.forEach { it.copyTo(File(destination, it.name), overwrite = true) }
                }
                // Eski sürüm yedeği açılırken veritabanı güncellenir.
                Hub.store(app).clearMissingFiles()
                Reminders.rescheduleAll(app)
            }
            Hub.notifyChanged("")
            Log.i(TAG, "Yedek geri yüklendi: $messages mesaj, $files dosya")
            return Summary(messages, files, 0)
        } finally {
            temp.deleteRecursively()
            password.fill('\u0000')
        }
    }

    /** Yalnızca bilinen yerler; "../" gibi kaçışlar ve alt klasörler yok sayılır. */
    private fun safeTarget(root: File, name: String): File? {
        val allowed = name == MANIFEST || name == DB ||
            FOLDERS.any { folder ->
                name.startsWith("$folder/") && name.substringAfter('/').let { it.isNotEmpty() && '/' !in it && '\\' !in it && it != ".." }
            }
        if (!allowed) return null
        val target = File(root, name)
        return target.takeIf { it.canonicalPath.startsWith(root.canonicalPath + File.separator) }
    }

    private fun <T> onIo(work: () -> T): T = try {
        Hub.io.submit(Callable { work() }).get()
    } catch (e: ExecutionException) {
        throw e.cause ?: e
    }

    private class CountingStream(out: OutputStream) : FilterOutputStream(out) {
        var count = 0L

        override fun write(b: Int) {
            out.write(b)
            count++
        }

        override fun write(b: ByteArray, off: Int, len: Int) {
            out.write(b, off, len)
            count += len
        }
    }
}
