package com.mesajmerkezi.mesaj_merkezi

import android.app.Activity
import android.graphics.Bitmap
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.PixelCopy
import android.view.SurfaceView
import android.view.TextureView
import android.view.View
import android.view.ViewGroup

/**
 * Mesa'nın o anki görüntüsü. WhatsApp üzerinden gönderirken servis bu
 * görüntüyü örtü olarak gösterir: kullanıcı Mesa'dan hiç çıkmamış gibi
 * görür (2026-11-26: "uygulama içerisinde kalmak istiyorum").
 *
 * Flutter çizimi ayrı bir yüzeyde (SurfaceView) yapar; pencerenin kopyası
 * onu içermez, bu yüzden doğrudan Flutter yüzeyi kopyalanır.
 */
internal object ScreenShot {

    class Shot(val bitmap: Bitmap, val x: Int, val y: Int)

    fun of(activity: Activity, done: (Shot?) -> Unit) {
        val view = findRenderView(activity.window.decorView)
        if (view == null || view.width == 0 || view.height == 0) return done(null)
        val location = IntArray(2).also(view::getLocationOnScreen)
        if (view is TextureView) {
            val bitmap = try {
                view.bitmap
            } catch (e: RuntimeException) {
                null
            }
            return done(bitmap?.let { Shot(it, location[0], location[1]) })
        }
        val surface = view as SurfaceView
        if (Build.VERSION.SDK_INT < 24 || !surface.holder.surface.isValid) return done(null)
        val bitmap = try {
            Bitmap.createBitmap(surface.width, surface.height, Bitmap.Config.ARGB_8888)
        } catch (e: OutOfMemoryError) {
            return done(null)
        }
        val handler = Handler(Looper.getMainLooper())
        var finished = false
        fun finish(shot: Shot?) {
            if (finished) return
            finished = true
            done(shot)
        }
        // Kopya gecikirse gönderim bekletilmez.
        handler.postDelayed({ finish(null) }, 300)
        try {
            PixelCopy.request(surface, bitmap, { result ->
                finish(if (result == PixelCopy.SUCCESS) Shot(bitmap, location[0], location[1]) else null)
            }, handler)
        } catch (e: IllegalArgumentException) {
            finish(null)
        }
    }

    private fun findRenderView(view: View): View? = when (view) {
        is SurfaceView, is TextureView -> view.takeIf { it.isShown }
        is ViewGroup -> (0 until view.childCount).firstNotNullOfOrNull { findRenderView(view.getChildAt(it)) }
        else -> null
    }
}
