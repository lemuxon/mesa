package com.mesajmerkezi.mesaj_merkezi

import android.Manifest
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaMetadataRetriever
import android.media.MediaRecorder
import android.net.Uri
import android.os.Build
import android.os.SystemClock
import android.provider.OpenableColumns
import android.util.Log
import android.webkit.MimeTypeMap
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import androidx.fragment.app.FragmentActivity
import java.io.File
import java.io.IOException
import java.util.UUID

/**
 * Gönderilecek medya: galeri, kamera, dosya ve ses kaydı. Seçilenler
 * uygulamanın önbelleğindeki "outbox" klasörüne kopyalanır; Telegram (TDLib)
 * oradan yükler, diğer uygulamalara FileProvider ile paylaşılır.
 * Etkinlik oluşturulurken kurulmalı (sonuç dinleyicileri onCreate'ten önce kaydedilir).
 */
class MediaTools(private val activity: FragmentActivity) {

    private val io = SafeExecutor("Medya")
    private var pending: ((List<Map<String, Any?>>?) -> Unit)? = null
    private var pendingPermission: ((Boolean) -> Unit)? = null
    private var cameraFile: File? = null

    private val pickVisual = activity.registerForActivityResult(
        ActivityResultContracts.PickMultipleVisualMedia(10)
    ) { uris -> deliver(uris) }

    private val pickDocument = activity.registerForActivityResult(
        ActivityResultContracts.GetMultipleContents()
    ) { uris -> deliver(uris) }

    private val takePicture = activity.registerForActivityResult(
        ActivityResultContracts.TakePicture()
    ) { ok ->
        val file = cameraFile
        cameraFile = null
        val done = pending ?: return@registerForActivityResult
        pending = null
        done(if (ok && file != null && file.length() > 0) listOf(describe(file, "image/jpeg", file.name)) else null)
    }

    private val micPermission = activity.registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        pendingPermission?.invoke(granted)
        pendingPermission = null
    }

    fun pick(source: String, done: (List<Map<String, Any?>>?) -> Unit) {
        pending?.invoke(null)
        pending = done
        try {
            when (source) {
                "camera" -> {
                    val file = File(outbox(activity), "foto_${System.currentTimeMillis()}.jpg")
                    cameraFile = file
                    takePicture.launch(uriFor(activity, file))
                }
                "file" -> pickDocument.launch("*/*")
                else -> pickVisual.launch(
                    PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageAndVideo)
                )
            }
        } catch (e: ActivityNotFoundException) {
            pending = null
            done(null)
        }
    }

    private fun deliver(uris: List<Uri>) {
        val done = pending ?: return
        pending = null
        if (uris.isEmpty()) return done(null)
        io.execute {
            val items = uris.mapNotNull(::copyToOutbox)
            activity.runOnUiThread { done(items.ifEmpty { null }) }
        }
    }

    private fun copyToOutbox(uri: Uri): Map<String, Any?>? {
        val resolver = activity.contentResolver
        val mime = resolver.getType(uri) ?: "application/octet-stream"
        val name = resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { c ->
            if (c.moveToFirst()) c.getString(0) else null
        }
        val ext = MimeTypeMap.getSingleton().getExtensionFromMimeType(mime)
            ?: name?.substringAfterLast('.', "")?.takeIf { it.isNotEmpty() }
            ?: "bin"
        val file = File(outbox(activity), "${UUID.randomUUID()}.$ext")
        return try {
            resolver.openInputStream(uri)?.use { input -> file.outputStream().use { input.copyTo(it) } } ?: return null
            describe(file, mime, name ?: file.name)
        } catch (e: IOException) {
            Log.w(TAG, "Seçilen dosya kopyalanamadı", e)
            file.delete()
            null
        } catch (e: SecurityException) {
            null
        }
    }

    // ---- Ses kaydı ----

    private var recorder: MediaRecorder? = null
    private var recordFile: File? = null
    private var recordStarted = 0L

    /** Mikrofon izni; yoksa sorulur. */
    fun requestMic(done: (Boolean) -> Unit) {
        if (hasMic()) return done(true)
        pendingPermission?.invoke(false)
        pendingPermission = done
        micPermission.launch(Manifest.permission.RECORD_AUDIO)
    }

    private fun hasMic() =
        ContextCompat.checkSelfPermission(activity, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED

    /** Telegram sesli mesajı Ogg/Opus ister (Android 10+); eskilerde AAC. */
    fun startRecording(): Boolean {
        if (!hasMic()) return false
        stopRecording(cancel = true)
        val opus = Build.VERSION.SDK_INT >= 29
        val file = File(outbox(activity), "ses_${System.currentTimeMillis()}.${if (opus) "ogg" else "m4a"}")
        @Suppress("DEPRECATION")
        val r = if (Build.VERSION.SDK_INT >= 31) MediaRecorder(activity) else MediaRecorder()
        return try {
            r.setAudioSource(MediaRecorder.AudioSource.MIC)
            if (opus) {
                r.setOutputFormat(MediaRecorder.OutputFormat.OGG)
                r.setAudioEncoder(MediaRecorder.AudioEncoder.OPUS)
            } else {
                r.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                r.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            }
            r.setAudioChannels(1)
            r.setAudioSamplingRate(48_000)
            r.setAudioEncodingBitRate(32_000)
            r.setOutputFile(file.absolutePath)
            r.prepare()
            r.start()
            recorder = r
            recordFile = file
            recordStarted = SystemClock.elapsedRealtime()
            Log.i(TAG, "Ses kaydı başladı")
            true
        } catch (e: Exception) {
            Log.w(TAG, "Ses kaydı başlatılamadı", e)
            r.release()
            file.delete()
            false
        }
    }

    /** Kaydı bitirir; [cancel] ya da çok kısa kayıtta dosya silinir ve null döner. */
    fun stopRecording(cancel: Boolean): Map<String, Any?>? {
        val r = recorder ?: return null
        val file = recordFile
        recorder = null
        recordFile = null
        val durationMs = SystemClock.elapsedRealtime() - recordStarted
        val ok = try {
            r.stop()
            true
        } catch (e: RuntimeException) {
            // Hiç ses yazılmadan durduruldu (çok kısa).
            false
        } finally {
            r.release()
        }
        Log.i(TAG, "Ses kaydı bitti: ${durationMs / 1000} sn, iptal=$cancel, yazıldı=$ok")
        if (cancel || !ok || durationMs < 700 || file == null) {
            file?.delete()
            return null
        }
        val mime = if (file.extension == "ogg") "audio/ogg" else "audio/mp4"
        return describe(file, mime, file.name) + mapOf("kind" to "voice", "duration" to (durationMs / 1000).toInt().coerceAtLeast(1))
    }

    private fun describe(file: File, mime: String, name: String): Map<String, Any?> {
        val kind = when {
            mime.startsWith("image/") && mime != "image/gif" -> "photo"
            mime.startsWith("video/") -> "video"
            else -> "file"
        }
        var duration = 0
        if (kind == "video") {
            // use {} değil: MediaMetadataRetriever Android 10 öncesinde AutoCloseable değil (minSdk 24).
            val r = MediaMetadataRetriever()
            try {
                r.setDataSource(file.absolutePath)
                duration = ((r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull() ?: 0L) / 1000).toInt()
            } catch (e: Exception) {
                // Süre bilinmiyorsa 0 gönderilir; Telegram kendisi hesaplar.
            } finally {
                r.release()
            }
        }
        return mapOf(
            "path" to file.absolutePath,
            "mime" to mime,
            "kind" to kind,
            "name" to name,
            "size" to file.length(),
            "duration" to duration,
        )
    }

    companion object {
        private const val TAG = "MesajMerkezi"
        private const val AUTHORITY_SUFFIX = ".files"

        fun outbox(context: Context) = File(context.cacheDir, "outbox").apply { mkdirs() }

        fun uriFor(context: Context, file: File): Uri =
            FileProvider.getUriForFile(context, context.packageName + AUTHORITY_SUFFIX, file)

        /** Bir günden eski gönderim kopyalarını siler. */
        fun cleanOutbox(context: Context) {
            val cutoff = System.currentTimeMillis() - 24 * 60 * 60 * 1000L
            outbox(context).listFiles()?.filter { it.lastModified() < cutoff }?.forEach { it.delete() }
        }

        /**
         * Kaynak uygulamada sohbeti metin ya da dosyalarla hazır açar; kullanıcı
         * orada gönder'e dokunur. [shortcutId] varsa doğrudan o sohbet açılır
         * (Android doğrudan paylaşım), yoksa uygulama kişi seçtirir.
         */
        fun shareToConversation(
            activity: android.app.Activity,
            packageName: String,
            shortcutId: String?,
            text: String?,
            files: List<File>,
        ): Boolean {
            val intent = shareIntent(activity, packageName, shortcutId, text, files)
            val count = files.size
            return try {
                activity.startActivity(intent)
                Log.i(TAG, "Uygulamada hazır açıldı: $packageName ${intent.type} ($count dosya, kısayol=${shortcutId != null})")
                true
            } catch (e: ActivityNotFoundException) {
                Log.w(TAG, "Uygulama açılamadı: $packageName")
                false
            }
        }

        /**
         * Uygulamanın paylaşımla kabul ettiği türler ("photo", "video", "voice",
         * "file"). Ör. Instagram ses ve belge kabul etmez: sesli mesaj düğmesi
         * hiç gösterilmez.
         */
        fun shareKinds(context: Context, packageName: String): List<String> =
            SHARE_PROBES.filter { (_, mimes) -> mimes.any { accepts(context, packageName, it) } }.map { it.first }

        private val SHARE_PROBES = listOf(
            "photo" to listOf("image/jpeg"),
            "video" to listOf("video/mp4"),
            "voice" to listOf("audio/ogg", "audio/mp4"),
            "file" to listOf("application/pdf"),
        )

        private fun accepts(context: Context, packageName: String, mime: String) =
            Intent(Intent.ACTION_SEND).setType(mime).setPackage(packageName)
                .resolveActivity(context.packageManager) != null

        /** Bu dosyalar uygulamaya paylaşılabilir mi (türünü kabul eden ekranı var mı). */
        fun canShare(context: Context, packageName: String, files: List<File>): Boolean {
            val intent = shareIntent(context, packageName, null, null, files)
            val ok = intent.resolveActivity(context.packageManager) != null
            if (!ok) Log.w(TAG, "Uygulama bu türü kabul etmiyor: $packageName ${intent.type}")
            return ok
        }

        /** Kaynak uygulamanın paylaşım ekranına giden niyet (bildirimden de açılabilir). */
        fun shareIntent(
            context: Context,
            packageName: String,
            shortcutId: String?,
            text: String?,
            files: List<File>,
        ): Intent {
            val activity = context
            val uris = files.map { uriFor(activity, it) }
            val intent = when {
                uris.size > 1 -> Intent(Intent.ACTION_SEND_MULTIPLE)
                    .putParcelableArrayListExtra(Intent.EXTRA_STREAM, ArrayList(uris))
                uris.size == 1 -> Intent(Intent.ACTION_SEND).putExtra(Intent.EXTRA_STREAM, uris[0])
                else -> Intent(Intent.ACTION_SEND)
            }
            intent.type = when {
                uris.isEmpty() -> "text/plain"
                else -> commonMime(files.map { activity.contentResolver.getType(uriFor(activity, it)) ?: "*/*" })
            }
            if (!text.isNullOrBlank()) intent.putExtra(Intent.EXTRA_TEXT, text)
            intent.setPackage(packageName)
            if (shortcutId != null) {
                intent.putExtra("android.intent.extra.shortcut.ID", shortcutId)
                // WhatsApp paylaşımda sohbeti "jid" ile de tanır.
                if (packageName.startsWith("com.whatsapp") && '@' in shortcutId) intent.putExtra("jid", shortcutId)
            }
            if (uris.isNotEmpty()) {
                intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                intent.clipData = ClipData.newRawUri("medya", uris[0]).apply {
                    uris.drop(1).forEach { addItem(ClipData.Item(it)) }
                }
            }
            return intent
        }

        private fun commonMime(mimes: List<String>): String {
            val distinct = mimes.distinct()
            if (distinct.size == 1) return distinct[0]
            val majors = distinct.map { it.substringBefore('/') }.distinct()
            return if (majors.size == 1) "${majors[0]}/*" else "*/*"
        }
    }
}
