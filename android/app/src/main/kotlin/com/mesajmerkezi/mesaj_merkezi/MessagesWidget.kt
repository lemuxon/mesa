package com.mesajmerkezi.mesaj_merkezi

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.BitmapShader
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Shader
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/** Bileşende bir satır: bir sohbet ya da (birleştirilmişse) bir kişi. */
data class WidgetRow(
    val key: String,
    val packageName: String,
    val title: String,
    val text: String,
    val time: Long,
    val unread: Int,
    val avatarPath: String?,
)

/** Bileşende hangi satırların gösterileceği (Android'den bağımsız; birim testli). */
object WidgetRows {

    /**
     * Kişiye birleştirilmiş sohbetler tek satır (okunmamışlar toplanır, en son
     * yazışılan üyenin mesajı); okunmamışı olanlar önce, sonra en yeniler.
     */
    fun select(conversations: List<Map<String, Any?>>, limit: Int): List<WidgetRow> {
        val merged = LinkedHashMap<String, WidgetRow>()
        for (c in conversations) {
            val personId = c["personId"] as Long?
            val id = personId?.let { "person:$it" } ?: c["key"] as String
            val row = WidgetRow(
                key = c["key"] as String,
                packageName = c["package"] as String,
                title = (c["personName"] as String?) ?: c["title"] as String,
                text = c["lastText"] as String? ?: "",
                time = c["lastTime"] as Long? ?: 0L,
                unread = c["unread"] as Int? ?: 0,
                avatarPath = c["avatarPath"] as String?,
            )
            val existing = merged[id]
            merged[id] = if (existing == null) {
                row
            } else {
                val latest = if (row.time > existing.time) row else existing
                latest.copy(
                    unread = existing.unread + row.unread,
                    avatarPath = latest.avatarPath ?: existing.avatarPath ?: row.avatarPath,
                )
            }
        }
        return merged.values
            .sortedWith(compareByDescending<WidgetRow> { it.unread > 0 }.thenByDescending { it.time })
            .take(limit)
    }

    /** Bugün "14:05", dün "Dün", daha eski "03.10". */
    fun formatTime(time: Long, now: Long, yesterday: String = "Dün"): String {
        if (time <= 0) return ""
        val day = Calendar.getInstance().apply { timeInMillis = now }
        val then = Calendar.getInstance().apply { timeInMillis = time }
        fun sameDay(a: Calendar, b: Calendar) =
            a.get(Calendar.YEAR) == b.get(Calendar.YEAR) && a.get(Calendar.DAY_OF_YEAR) == b.get(Calendar.DAY_OF_YEAR)
        if (sameDay(day, then)) return SimpleDateFormat("HH:mm", Locale.ROOT).format(Date(time))
        day.add(Calendar.DAY_OF_YEAR, -1)
        if (sameDay(day, then)) return yesterday
        return SimpleDateFormat("dd.MM", Locale.ROOT).format(Date(time))
    }
}

/**
 * Ana ekran bileşeni: okunmamış sayısı, yanıt bekleyenler ve son sohbetler.
 * Satıra dokununca o sohbet (kişiyse kişi ekranı) açılır. Uygulama kilidi
 * açıksa ana ekranda mesaj içeriği gösterilmez. Güncelleme uygulamadan
 * itilir: yeni mesaj, okundu, uygulamadan çıkış.
 */
class MessagesWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, appWidgetIds: IntArray) {
        val pending = goAsync()
        Hub.io.execute {
            try {
                render(context.applicationContext)
            } finally {
                pending.finish()
            }
        }
    }

    companion object {
        private const val TAG = "MesajMerkezi"
        private const val MAX_ROWS = 4
        private const val AVATAR_PX = 96

        private val main = Handler(Looper.getMainLooper())

        @Volatile
        private var scheduled = false

        /** Arka arkaya gelen değişiklikleri birleştirerek (≤ 1 sn) yeniler. */
        fun refresh(context: Context) {
            val app = context.applicationContext
            if (scheduled) return
            scheduled = true
            main.postDelayed({
                scheduled = false
                if (widgetIds(app).isNotEmpty()) Hub.io.execute { render(app) }
            }, 800)
        }

        private fun widgetIds(context: Context): IntArray =
            AppWidgetManager.getInstance(context)
                .getAppWidgetIds(ComponentName(context, MessagesWidget::class.java))

        /** Telefonun başlatıcısı izin veriyorsa bileşeni ana ekrana ekleme penceresi. */
        fun requestPin(context: Context): Boolean {
            if (Build.VERSION.SDK_INT < 26) return false
            val manager = AppWidgetManager.getInstance(context)
            if (!manager.isRequestPinAppWidgetSupported) return false
            return manager.requestPinAppWidget(ComponentName(context, MessagesWidget::class.java), null, null)
        }

        /** Hub.io iş parçacığında çağrılmalı (veritabanı okunur). */
        internal fun render(context: Context) {
            val ids = widgetIds(context)
            if (ids.isEmpty()) return
            val store = Hub.store(context)
            val conversations = store.conversations()
            val unread = conversations.sumOf { it["unread"] as Int? ?: 0 }
            val waiting = store.waiting(System.currentTimeMillis()).size
            val locked = AppLock.enabled(context)
            val now = System.currentTimeMillis()

            val views = RemoteViews(context.packageName, R.layout.widget_messages)
            views.setTextViewText(R.id.widget_count, if (unread > 0) Lang.plural(context, R.plurals.web_unread, unread) else "")
            views.setTextViewText(
                R.id.widget_subtitle,
                when {
                    locked -> Lang.str(context, R.string.widget_locked)
                    waiting > 0 -> Lang.plural(context, R.plurals.widget_waiting, waiting)
                    unread == 0 -> Lang.str(context, R.string.widget_all_read)
                    else -> Lang.str(context, R.string.widget_tagline)
                },
            )
            views.setOnClickPendingIntent(R.id.widget_header, openApp(context))
            views.removeAllViews(R.id.widget_rows)

            val rows = if (locked) emptyList() else WidgetRows.select(conversations, MAX_ROWS)
            views.setViewVisibility(R.id.widget_empty, if (rows.isEmpty()) View.VISIBLE else View.GONE)
            views.setTextViewText(
                R.id.widget_empty,
                Lang.str(context, if (locked) R.string.widget_open_to_see else R.string.widget_empty),
            )
            views.setOnClickPendingIntent(R.id.widget_empty, openApp(context))
            for (row in rows) {
                val item = RemoteViews(context.packageName, R.layout.widget_row)
                item.setTextViewText(R.id.row_title, row.title)
                item.setTextViewText(R.id.row_text, StoredLabels.display(context, row.text))
                item.setTextViewText(
                    R.id.row_time,
                    WidgetRows.formatTime(row.time, now, Lang.str(context, R.string.widget_yesterday)),
                )
                item.setViewVisibility(R.id.row_badge, if (row.unread > 0) View.VISIBLE else View.GONE)
                item.setTextViewText(R.id.row_badge, if (row.unread > 99) "99+" else row.unread.toString())
                avatar(context, row)?.let { item.setImageViewBitmap(R.id.row_avatar, it) }
                item.setOnClickPendingIntent(R.id.row_root, openConversation(context, row.key))
                views.addView(R.id.widget_rows, item)
            }
            try {
                AppWidgetManager.getInstance(context).updateAppWidget(ids, views)
                Log.i(TAG, "Ana ekran bileşeni güncellendi: ${rows.size} satır${if (locked) " (kilitli)" else ""}")
            } catch (e: RuntimeException) {
                Log.w(TAG, "Bileşen güncellenemedi", e)
            }
        }

        private fun openApp(context: Context): PendingIntent = PendingIntent.getActivity(
            context,
            "widget|app".hashCode(),
            Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        /** Bildirime dokunulmuş gibi: uygulama o sohbeti (kişiyse kişi ekranını) açar. */
        private fun openConversation(context: Context, key: String): PendingIntent = PendingIntent.getActivity(
            context,
            "widget|$key".hashCode(),
            Intent(context, MainActivity::class.java)
                .putExtra(UnifiedNotifier.EXTRA_KEY, key)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        /** Kişi fotoğrafı (yoksa uygulama simgesi), yuvarlak ve küçük. */
        private fun avatar(context: Context, row: WidgetRow): Bitmap? {
            val source = row.avatarPath?.let(::decodeSmall) ?: AvatarCache.appIconBitmap(context, row.packageName)
            return source?.let(::circle)
        }

        private fun decodeSmall(path: String): Bitmap? {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(path, bounds)
            if (bounds.outWidth <= 0) return null
            var sample = 1
            while (bounds.outWidth / (sample * 2) >= AVATAR_PX) sample *= 2
            return BitmapFactory.decodeFile(path, BitmapFactory.Options().apply { inSampleSize = sample })
        }

        private fun circle(source: Bitmap): Bitmap {
            val size = AVATAR_PX
            val scaled = Bitmap.createScaledBitmap(source, size, size, true)
            val out = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                shader = BitmapShader(scaled, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP)
            }
            Canvas(out).drawCircle(size / 2f, size / 2f, size / 2f, paint)
            return out
        }
    }
}
