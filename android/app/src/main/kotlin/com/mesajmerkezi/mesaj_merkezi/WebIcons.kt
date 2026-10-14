package com.mesajmerkezi.mesaj_merkezi

import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.SystemClock
import android.util.Log
import android.util.LruCache
import androidx.core.graphics.drawable.toBitmap
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.ConcurrentHashMap

/**
 * Web servislerinin simgesi. Sıra: telefonda kurulu uygulamanın gerçek
 * simgesi → uygulamayla gelen katalog simgesi (assets/web_icons) → sitenin
 * büyük simgesi (manifest / apple-touch-icon, sayfadaki betik bulur) →
 * tarayıcının indirdiği küçük site simgesi → (arayüzde) baş harf.
 *
 * Sayfadan gelen resimler güvenilmez veridir: boyutu ve piksel sayısı
 * çözülmeden önce sınırlanır (dev bir resim belleği tüketmesin).
 */
object WebIcons {

    private const val TAG = "MesajMerkezi"
    private const val SIZE = 192
    private const val MAX_BYTES = 1_000_000
    private const val MAX_SIDE = 4096
    private const val HD_REFRESH_MS = 7 * 24 * 60 * 60 * 1000L
    private const val FAVICON_REFRESH_MS = 10 * 60_000L

    private val cache = LruCache<String, Bitmap>(32)
    private val faviconSavedAt = ConcurrentHashMap<String, Long>()
    private val downloading = ConcurrentHashMap.newKeySet<String>()
    private val net = SafeExecutor("Simge")

    private fun dir(context: Context) = File(context.filesDir, "web_icons").apply { mkdirs() }

    private fun faviconFile(context: Context, id: String) = File(dir(context), "$id.png")

    private fun hdFile(context: Context, id: String) = File(dir(context), "${id}_hd.png")

    /** Servisin telefonda kurulu uygulaması (simgesi kullanılır). */
    fun installedApp(context: Context, service: WebService?): String? {
        val pkg = service?.catalog?.appPackage ?: return null
        return try {
            context.packageManager.getPackageInfo(pkg, 0)
            pkg
        } catch (e: PackageManager.NameNotFoundException) {
            null
        }
    }

    fun bitmap(context: Context, id: String): Bitmap? {
        cache.get(id)?.let { return it }
        val service = WebServices.get(context, id)
        val bitmap = installedApp(context, service)?.let { pkg ->
            try {
                context.packageManager.getApplicationIcon(pkg).toBitmap(SIZE, SIZE, Bitmap.Config.ARGB_8888)
            } catch (e: Exception) {
                null
            }
        } ?: bundled(context, service) ?: decode(hdFile(context, id)) ?: decode(faviconFile(context, id)) ?: return null
        cache.put(id, bitmap)
        return bitmap
    }

    private fun bundledPath(service: WebService?): String? =
        service?.catalogId?.let { "flutter_assets/assets/web_icons/$it.png" }

    /** Uygulamayla gelen katalog simgesi; katalog dışı sitede ya da yoksa null. */
    private fun bundled(context: Context, service: WebService?): Bitmap? {
        val path = bundledPath(service) ?: return null
        return try {
            context.assets.open(path).use { BitmapFactory.decodeStream(it) }
        } catch (e: IOException) {
            null
        }
    }

    private fun hasBundled(context: Context, service: WebService?): Boolean {
        val path = bundledPath(service) ?: return false
        return try {
            context.assets.open(path).close()
            true
        } catch (e: IOException) {
            false
        }
    }

    fun png(context: Context, id: String): ByteArray? {
        val bitmap = bitmap(context, id) ?: return null
        return ByteArrayOutputStream().use { out ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
            out.toByteArray()
        }
    }

    /** Kurulu uygulama, katalog ya da büyük site simgesi var mı (yoksa sayfadan aranır). */
    fun hasGoodIcon(context: Context, id: String): Boolean {
        val service = WebServices.get(context, id)
        return installedApp(context, service) != null || hasBundled(context, service) || hdFile(context, id).exists()
    }

    /** Arayüz simgeyi ne zaman yeniden istemeli. */
    fun version(context: Context, id: String): String {
        val service = WebServices.get(context, id)
        if (installedApp(context, service) != null) return "app"
        if (hasBundled(context, service)) return "bundled"
        return "${hdFile(context, id).lastModified()}-${faviconFile(context, id).lastModified()}"
    }

    fun delete(context: Context, id: String) {
        faviconFile(context, id).delete()
        hdFile(context, id).delete()
        cache.remove(id)
    }

    /** Tarayıcının indirdiği küçük site simgesi; büyük simge yoksa kullanılır. */
    fun saveFavicon(context: Context, id: String, icon: Bitmap, onSaved: () -> Unit) {
        if (icon.width < 16) return
        // Daha iyi simge varsa küçüğü artık gerekmez.
        if (hasGoodIcon(context, id)) return
        val file = faviconFile(context, id)
        val now = SystemClock.elapsedRealtime()
        if (file.exists() && now - (faviconSavedAt[id] ?: 0L) < FAVICON_REFRESH_MS) return
        faviconSavedAt[id] = now
        val copy = Bitmap.createScaledBitmap(icon, icon.width.coerceAtMost(SIZE), icon.height.coerceAtMost(SIZE), true)
        net.execute {
            if (write(copy, file)) {
                cache.remove(id)
                onSaved()
            }
        }
    }

    /**
     * Sayfanın bulduğu büyük simgeyi indirir. Uygulaması kurulu servislerde
     * ve son bir haftada indirildiyse atlanır. Çerez gönderilmez.
     */
    fun downloadHd(context: Context, id: String, url: String, onSaved: () -> Unit) {
        if (!url.startsWith("https://")) return
        if (installedApp(context, WebServices.get(context, id)) != null) return
        if (hasBundled(context, WebServices.get(context, id))) return
        val file = hdFile(context, id)
        if (file.exists() && System.currentTimeMillis() - file.lastModified() < HD_REFRESH_MS) return
        if (!downloading.add(id)) return
        net.execute {
            try {
                val bitmap = fetch(url) ?: return@execute
                Log.i(TAG, "Servis simgesi indirildi: ${bitmap.width} px")
                if (bitmap.width < 48) return@execute
                val scaled = Bitmap.createScaledBitmap(bitmap, SIZE, SIZE * bitmap.height / bitmap.width, true)
                if (write(scaled, file)) {
                    cache.remove(id)
                    onSaved()
                }
            } finally {
                downloading.remove(id)
            }
        }
    }

    /** Sayfanın kendisinin indirip gönderdiği simge ("data:image/...;base64,..."). */
    fun saveHdData(context: Context, id: String, dataUrl: String, onSaved: () -> Unit) {
        if (installedApp(context, WebServices.get(context, id)) != null) return
        if (hasBundled(context, WebServices.get(context, id))) return
        // Base64 metni ~4/3 büyür; sınırın üstündekiler hiç çözülmez.
        if (dataUrl.length > MAX_BYTES * 4 / 3 + 100) return
        val file = hdFile(context, id)
        if (file.exists() && System.currentTimeMillis() - file.lastModified() < HD_REFRESH_MS) return
        net.execute {
            val bytes = try {
                android.util.Base64.decode(dataUrl.substringAfter("base64,", ""), android.util.Base64.DEFAULT)
            } catch (e: IllegalArgumentException) {
                return@execute
            }
            val bitmap = decodeBounded(bytes)
            if (bitmap == null) {
                Log.i(TAG, "Servis simgesi çözülemedi (${bytes.size} bayt)")
                return@execute
            }
            Log.i(TAG, "Servis simgesi sayfadan alındı: ${bitmap.width} px")
            if (bitmap.width < 48) return@execute
            val scaled = Bitmap.createScaledBitmap(bitmap, SIZE, SIZE * bitmap.height / bitmap.width, true)
            if (write(scaled, file)) {
                cache.remove(id)
                onSaved()
            }
        }
    }

    private fun fetch(url: String): Bitmap? {
        val connection = try {
            URL(url).openConnection() as HttpURLConnection
        } catch (e: IOException) {
            return null
        }
        return try {
            connection.connectTimeout = 10_000
            connection.readTimeout = 10_000
            connection.instanceFollowRedirects = true
            if (connection.responseCode != 200) return null
            val bytes = connection.inputStream.use { input ->
                val out = ByteArrayOutputStream()
                val buffer = ByteArray(16 * 1024)
                while (true) {
                    val n = input.read(buffer)
                    if (n < 0) break
                    out.write(buffer, 0, n)
                    if (out.size() > MAX_BYTES) return null
                }
                out.toByteArray()
            }
            decodeBounded(bytes)
        } catch (e: IOException) {
            Log.i(TAG, "Servis simgesi indirilemedi: ${e.javaClass.simpleName} ${e.message?.take(120)}")
            null
        } finally {
            connection.disconnect()
        }
    }

    /**
     * Önce yalnızca boyutları okunur: kenarı [MAX_SIDE]'dan büyük (ya da
     * bozuk) resim reddedilir, büyükçe olan [SIZE]'a yakın küçültülerek çözülür.
     */
    private fun decodeBounded(bytes: ByteArray): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
        val w = bounds.outWidth
        val h = bounds.outHeight
        if (w <= 0 || h <= 0 || w > MAX_SIDE || h > MAX_SIDE) return null
        var sample = 1
        while (w / (sample * 2) >= SIZE && h / (sample * 2) >= SIZE) sample *= 2
        return BitmapFactory.decodeByteArray(bytes, 0, bytes.size, BitmapFactory.Options().apply { inSampleSize = sample })
    }

    private fun write(bitmap: Bitmap, file: File): Boolean = try {
        FileOutputStream(file).use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
        true
    } catch (e: IOException) {
        Log.w(TAG, "Servis simgesi kaydedilemedi", e)
        false
    }

    private fun decode(file: File): Bitmap? =
        if (file.exists()) BitmapFactory.decodeFile(file.absolutePath) else null
}
