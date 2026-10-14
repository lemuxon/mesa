package com.mesajmerkezi.mesaj_merkezi

import android.app.Notification
import android.content.Context
import android.graphics.Bitmap
import android.graphics.drawable.Drawable
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.graphics.drawable.toBitmap
import java.io.File
import java.security.MessageDigest

/**
 * Sohbetlerin profil fotoğrafları ve uygulama simgeleri. Fotoğraf, bildirimin
 * büyük simgesinden (WhatsApp'ta kişi/grup fotoğrafı) ya da gönderenin kişi
 * simgesinden alınır; günde en fazla bir kez yenilenir.
 */
object AvatarCache {

    private const val TAG = "MesajMerkezi"
    private const val SIZE = 192
    private const val REFRESH_MS = 24 * 60 * 60 * 1000L

    private fun dir(context: Context) = File(context.filesDir, "avatars").apply { mkdirs() }

    fun fileFor(context: Context, key: String): File {
        val hash = MessageDigest.getInstance("SHA-1").digest(key.toByteArray())
            .take(12).joinToString("") { "%02x".format(it) }
        return File(dir(context), "$hash.png")
    }

    /** Kaydedilen dosyanın yolu; bildirimde fotoğraf yoksa ya da yeniyse null. */
    fun saveFromNotification(
        context: Context,
        key: String,
        notification: Notification,
        style: NotificationCompat.MessagingStyle?,
    ): String? {
        val target = fileFor(context, key)
        if (target.exists() && System.currentTimeMillis() - target.lastModified() < REFRESH_MS) return null
        val drawable = try {
            notification.getLargeIcon()?.loadDrawable(context)
                ?: style?.messages?.lastOrNull { it.person?.icon != null }?.person?.icon?.loadDrawable(context)
        } catch (e: RuntimeException) {
            // Kaynak uygulamanın simge URI'si dinleyiciye açık olmayabilir.
            Log.i(TAG, "Bildirim fotoğrafı okunamadı: ${e.javaClass.simpleName}")
            null
        } ?: return null
        return write(drawable, target)
    }

    /** Hazır bir dosyadan (ör. TDLib'in indirdiği sohbet fotoğrafı) kopyalamadan yol döner. */
    fun write(drawable: Drawable, target: File): String? = try {
        val bitmap = drawable.toBitmap(SIZE, SIZE, Bitmap.Config.ARGB_8888)
        target.outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
        target.absolutePath
    } catch (e: RuntimeException) {
        Log.i(TAG, "Profil fotoğrafı yazılamadı: ${e.javaClass.simpleName}")
        null
    }

    /** Yüklü uygulamanın simgesi (PNG); uygulama kurulu değilse null. Web servisinde sitenin simgesi. */
    fun appIconPng(context: Context, packageName: String): ByteArray? = try {
        if (WebServices.isWebPackage(packageName)) return WebIcons.png(context, WebServices.idOfPackage(packageName))
        val icon = context.packageManager.getApplicationIcon(packageName)
        val bitmap = icon.toBitmap(128, 128, Bitmap.Config.ARGB_8888)
        java.io.ByteArrayOutputStream().use { out ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
            out.toByteArray()
        }
    } catch (e: Exception) {
        null
    }

    fun appIconBitmap(context: Context, packageName: String): Bitmap? = try {
        if (WebServices.isWebPackage(packageName)) return WebIcons.bitmap(context, WebServices.idOfPackage(packageName))
        context.packageManager.getApplicationIcon(packageName).toBitmap(128, 128, Bitmap.Config.ARGB_8888)
    } catch (e: Exception) {
        null
    }
}
