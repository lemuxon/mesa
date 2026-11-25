package com.mesajmerkezi.mesaj_merkezi

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import android.util.Log
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.TimeUnit

/**
 * Otomatik şifreli yedek: kullanıcının seçtiği klasöre (telefon, SD kart,
 * Drive gibi bir belge sağlayıcısı) düzenli olarak Backup.export ile yedek
 * yazılır; en yeni [KEEP] otomatik yedek kalır, elle alınanlara dokunulmaz.
 *
 * Otomatik çalışabilmesi için parola cihazda tutulur: SecretBox (Android
 * Keystore, dışa aktarılamaz anahtar) ile şifreli. Elle yedek parolayı hiç
 * saklamaz.
 */
object AutoBackup {

    private const val TAG = "MesajMerkezi"
    private const val PREFS = "auto_backup"
    private const val WORK = "auto_backup"
    private const val WORK_NOW = "auto_backup_now"
    private const val CHANNEL = "backup"
    private const val NOTIFICATION_ID = 12
    internal const val PREFIX = "mesa-otomatik-"
    internal const val SUFFIX = ".mmyedek"
    const val KEEP = 5

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun enabled(context: Context) = prefs(context).getBoolean("enabled", false)

    /** Klasör ve parola kaydedilir, düzenli iş kurulur ve ilk yedek hemen alınır. */
    fun enable(context: Context, tree: Uri, password: String, days: Int) {
        prefs(context).edit()
            .putBoolean("enabled", true)
            .putString("tree", tree.toString())
            .putString("folder", folderName(context, tree))
            .putInt("days", days.coerceIn(1, 30))
            .putString("password", SecretBox.encrypt(password))
            .remove("last_error")
            .commit()
        schedule(context)
        runNow(context)
        Log.i(TAG, "Otomatik yedek açıldı: $days günde bir")
    }

    fun disable(context: Context) {
        WorkManager.getInstance(context).cancelUniqueWork(WORK)
        prefs(context).edit().putBoolean("enabled", false).remove("password").apply()
        Log.i(TAG, "Otomatik yedek kapatıldı")
    }

    private fun schedule(context: Context) {
        val days = prefs(context).getInt("days", 7).toLong()
        val request = PeriodicWorkRequestBuilder<AutoBackupWorker>(days, TimeUnit.DAYS)
            .setConstraints(Constraints.Builder().setRequiresBatteryNotLow(true).build())
            .setInitialDelay(days, TimeUnit.DAYS)
            .build()
        WorkManager.getInstance(context).enqueueUniquePeriodicWork(WORK, ExistingPeriodicWorkPolicy.UPDATE, request)
    }

    fun runNow(context: Context) {
        WorkManager.getInstance(context)
            .enqueueUniqueWork(WORK_NOW, ExistingWorkPolicy.REPLACE, OneTimeWorkRequestBuilder<AutoBackupWorker>().build())
    }

    /** Yedeği alır (iş parçacığında). Başarılıysa null, değilse hata kodu. */
    internal fun run(context: Context): String? {
        val p = prefs(context)
        if (!p.getBoolean("enabled", false)) return null
        val tree = p.getString("tree", null)?.let(Uri::parse) ?: return fail(context, "NO_FOLDER")
        val password = p.getString("password", null)?.let(SecretBox::decrypt) ?: return fail(context, "PASSWORD")
        val resolver = context.contentResolver
        val parent = try {
            DocumentsContract.buildDocumentUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))
        } catch (e: IllegalArgumentException) {
            return fail(context, "NO_FOLDER")
        }
        val document = try {
            DocumentsContract.createDocument(resolver, parent, "application/octet-stream", fileName(System.currentTimeMillis()))
        } catch (e: Exception) {
            // Klasör silinmiş, izin geri alınmış ya da sağlayıcı yanıt vermiyor.
            Log.w(TAG, "Otomatik yedek dosyası oluşturulamadı: ${e.javaClass.simpleName}")
            null
        } ?: return fail(context, "FOLDER")
        val summary = try {
            val out = resolver.openOutputStream(document, "w") ?: throw java.io.IOException("akış yok")
            out.use { Backup.export(context, it, password.toCharArray()) }
        } catch (e: Exception) {
            Log.w(TAG, "Otomatik yedek yazılamadı: ${e.javaClass.simpleName}")
            try {
                DocumentsContract.deleteDocument(resolver, document)
            } catch (ignored: Exception) {
                // Yarım dosya kalabilir; bir sonraki budamada silinir.
            }
            return fail(context, "WRITE")
        }
        prune(context, tree, parent)
        p.edit()
            .putLong("last_time", System.currentTimeMillis())
            .putLong("last_bytes", summary.bytes)
            .putInt("last_messages", summary.messages)
            .remove("last_error")
            .apply()
        Log.i(TAG, "Otomatik yedek alındı: ${summary.messages} mesaj, ${summary.bytes / 1024} KB")
        return null
    }

    private fun fail(context: Context, code: String): String {
        prefs(context).edit().putString("last_error", code).putLong("last_error_time", System.currentTimeMillis()).apply()
        notifyFailure(context)
        return code
    }

    /** Otomatik yedeğin adı: tarih sırasıyla sıralanabilir. */
    internal fun fileName(time: Long, locale: Locale = Locale.ROOT): String =
        PREFIX + SimpleDateFormat("yyyy-MM-dd-HHmm", locale).format(Date(time)) + SUFFIX

    /** Silinecek eski otomatik yedekler (en yeni [keep] tanesi kalır; diğer dosyalara dokunulmaz). */
    internal fun toDelete(names: List<String>, keep: Int = KEEP): List<String> =
        names.filter { it.startsWith(PREFIX) && it.endsWith(SUFFIX) }.sortedDescending().drop(keep)

    private fun prune(context: Context, tree: Uri, parent: Uri) {
        val resolver = context.contentResolver
        val children = DocumentsContract.buildChildDocumentsUriUsingTree(tree, DocumentsContract.getDocumentId(parent))
        val documents = HashMap<String, String>()
        try {
            resolver.query(
                children,
                arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID, DocumentsContract.Document.COLUMN_DISPLAY_NAME),
                null,
                null,
                null,
            )?.use { c ->
                while (c.moveToNext()) documents[c.getString(1) ?: continue] = c.getString(0)
            }
            for (name in toDelete(documents.keys.toList())) {
                DocumentsContract.deleteDocument(resolver, DocumentsContract.buildDocumentUriUsingTree(tree, documents[name]))
            }
        } catch (e: Exception) {
            Log.w(TAG, "Eski otomatik yedekler silinemedi: ${e.javaClass.simpleName}")
        }
    }

    private fun folderName(context: Context, tree: Uri): String? = try {
        val root = DocumentsContract.buildDocumentUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))
        context.contentResolver.query(root, arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME), null, null, null)
            ?.use { c -> if (c.moveToFirst()) c.getString(0) else null }
    } catch (e: Exception) {
        null
    }

    private fun notifyFailure(context: Context) {
        if (Build.VERSION.SDK_INT >= 33 &&
            context.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) != android.content.pm.PackageManager.PERMISSION_GRANTED
        ) return
        val manager = NotificationManagerCompat.from(context)
        manager.createNotificationChannel(
            NotificationChannelCompat.Builder(CHANNEL, NotificationManagerCompat.IMPORTANCE_DEFAULT)
                .setName(Lang.str(context, R.string.backup_channel))
                .build()
        )
        val open = PendingIntent.getActivity(context, 0, Intent(context, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE)
        manager.notify(
            NOTIFICATION_ID,
            NotificationCompat.Builder(context, CHANNEL)
                .setSmallIcon(R.drawable.ic_notification)
                .setContentTitle(Lang.str(context, R.string.backup_auto_failed))
                .setContentText(Lang.str(context, R.string.backup_auto_failed_text))
                .setAutoCancel(true)
                .setContentIntent(open)
                .build(),
        )
    }

    fun status(context: Context): Map<String, Any?> {
        val p = prefs(context)
        return mapOf(
            "enabled" to p.getBoolean("enabled", false),
            "days" to p.getInt("days", 7),
            "folder" to p.getString("folder", null),
            "lastTime" to p.getLong("last_time", 0L),
            "lastBytes" to p.getLong("last_bytes", 0L),
            "lastMessages" to p.getInt("last_messages", 0),
            "lastError" to p.getString("last_error", null),
        )
    }
}

/** WorkManager işi: düzenli ve "şimdi yedekle" çalıştırmaları. */
class AutoBackupWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    override fun doWork(): Result {
        val error = AutoBackup.run(applicationContext) ?: return Result.success()
        // Geçici hata (sağlayıcı yanıt vermedi) birkaç kez yeniden denenir.
        return if (error == "WRITE" && runAttemptCount < 2) Result.retry() else Result.failure()
    }
}
