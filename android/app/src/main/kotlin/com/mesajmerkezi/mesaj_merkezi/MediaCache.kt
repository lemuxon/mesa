package com.mesajmerkezi.mesaj_merkezi

import android.content.Context
import android.net.Uri
import android.util.Log
import java.io.File
import java.io.IOException
import java.security.MessageDigest

/**
 * Mesajlardaki görselleri (çıkartma, GIF, fotoğraf) uygulamanın özel
 * klasörüne kopyalar. Bildirimdeki içerik URI'sine erişim bildirim
 * kalkınca biter; görsel kayıt anında kopyalanmazsa kaybolur.
 */
object MediaCache {

    private const val TAG = "MesajMerkezi"
    private const val MAX_BYTES = 8L * 1024 * 1024

    private fun dir(context: Context) = File(context.filesDir, "media").apply { mkdirs() }

    /** Kopyalanan dosyanın yolu; okunamazsa (izin yok, çok büyük) null. */
    fun copyFromNotification(
        context: Context,
        uri: String,
        mime: String?,
        messageId: String,
        source: String = "?",
    ): String? {
        val target = File(dir(context), fileName(messageId, mime))
        if (target.exists()) return target.absolutePath
        val partial = File(target.path + ".part")
        return try {
            val input = context.contentResolver.openInputStream(Uri.parse(uri)) ?: return null
            input.use { source ->
                partial.outputStream().use { sink ->
                    val buffer = ByteArray(64 * 1024)
                    var total = 0L
                    while (true) {
                        val read = source.read(buffer)
                        if (read < 0) break
                        total += read
                        if (total > MAX_BYTES) throw IOException("görsel çok büyük")
                        sink.write(buffer, 0, read)
                    }
                }
            }
            if (!partial.renameTo(target)) return null
            logSize(target, source)
            target.absolutePath
        } catch (e: Exception) {
            // SecurityException: kaynak uygulama URI'yi bildirim dinleyicilerine açmamış.
            Log.i(TAG, "Bildirim görseli kopyalanamadı (${e.javaClass.simpleName}): $mime")
            partial.delete()
            null
        }
    }

    /**
     * İçeriksiz: kaynak uygulamanın bildirime koyduğu görselin boyutu
     * (ör. Instagram gönderileri küçük önizleme olarak geliyor mu).
     */
    private fun logSize(file: File, source: String) {
        val bounds = android.graphics.BitmapFactory.Options().apply { inJustDecodeBounds = true }
        android.graphics.BitmapFactory.decodeFile(file.path, bounds)
        Log.i(TAG, "Bildirim görseli kopyalandı: $source ${bounds.outWidth}x${bounds.outHeight} (${file.length() / 1024} KB)")
    }

    private fun fileName(messageId: String, mime: String?): String {
        val hash = MessageDigest.getInstance("SHA-1").digest(messageId.toByteArray())
            .joinToString("") { "%02x".format(it) }
        val extension = when (mime) {
            "image/webp" -> "webp"
            "image/gif" -> "gif"
            "image/png" -> "png"
            else -> "jpg"
        }
        return "$hash.$extension"
    }
}
