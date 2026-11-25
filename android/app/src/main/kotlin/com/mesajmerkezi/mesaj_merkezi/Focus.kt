package com.mesajmerkezi.mesaj_merkezi

import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.service.quicksettings.TileService
import android.util.Log
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import java.time.Instant
import java.time.ZoneId
import java.time.ZonedDateTime

/**
 * Odak modunun saf karar mantığı (testli). Etkin olduğunda yalnızca VIP
 * sohbetler, "Önemli işaretle" kuralına uyanlar ve acil durum geçişi
 * (aynı sohbet 5 dakikada 3. kez yazarsa) bildirim verir; diğer mesajlar
 * Mesa'ya sessizce düşer.
 */
internal class FocusPolicy(
    /** 0: elle kapalı; Long.MAX_VALUE: kapatılana kadar; diğer: bu ana kadar. */
    val manualUntil: Long,
    val schedule: Schedule?,
    /** Zamanlama bu ana kadar duraklatıldı (kutucuktan kapatıldı). */
    val schedulePausedUntil: Long,
    val vip: Set<String>,
    val breakthrough: Boolean,
    private val zone: ZoneId = ZoneId.systemDefault(),
) {
    /** Gece yarısından dakika; [from] > [to] ise aralık gece yarısını aşar. Gün biti 0 = pazartesi. */
    data class Schedule(val from: Int, val to: Int, val days: Int)

    enum class Decision { ALLOW, ALLOW_VIP, ALLOW_IMPORTANT, ALLOW_BREAKTHROUGH, SILENCE }

    fun manualActive(now: Long) = manualUntil > now

    /** Zamanlanmış aralığın içinde mi (aralığın başladığı günün seçili olması gerekir). */
    fun scheduleActive(now: Long): Boolean {
        val s = schedule ?: return false
        if (now < schedulePausedUntil || s.from == s.to) return false
        val time = ZonedDateTime.ofInstant(Instant.ofEpochMilli(now), zone)
        val minute = time.hour * 60 + time.minute
        val today = time.dayOfWeek.value - 1
        val startedDay = when {
            s.from < s.to -> if (minute in s.from until s.to) today else return false
            minute >= s.from -> today
            minute < s.to -> (today + 6) % 7 // dün başladı
            else -> return false
        }
        return s.days and (1 shl startedDay) != 0
    }

    fun isActive(now: Long) = manualActive(now) || scheduleActive(now)

    /** Etkin odağın biteceği an; süresizse ya da etkin değilse null. */
    fun end(now: Long): Long? {
        val manual = if (manualActive(now)) manualUntil else null
        if (manual == Long.MAX_VALUE) return null
        val scheduled = if (scheduleActive(now)) scheduleEnd(now) else null
        return listOfNotNull(manual, scheduled).maxOrNull()
    }

    /** İçinde bulunulan zamanlanmış aralığın bitişi. */
    fun scheduleEnd(now: Long): Long {
        val s = schedule ?: return now
        val time = ZonedDateTime.ofInstant(Instant.ofEpochMilli(now), zone)
        var end = time.withHour(s.to / 60).withMinute(s.to % 60).withSecond(0).withNano(0)
        if (!end.isAfter(time)) end = end.plusDays(1)
        return end.toInstant().toEpochMilli()
    }

    /** [recentSilenced]: bu sohbetin son 5 dakikada susturulan mesajlarının zamanları. */
    fun decide(key: String, important: Boolean, now: Long, recentSilenced: List<Long>): Decision = when {
        !isActive(now) -> Decision.ALLOW
        important -> Decision.ALLOW_IMPORTANT
        key in vip -> Decision.ALLOW_VIP
        breakthrough && recentSilenced.count { now - it < BREAKTHROUGH_WINDOW_MS } >= 2 -> Decision.ALLOW_BREAKTHROUGH
        else -> Decision.SILENCE
    }

    companion object {
        const val BREAKTHROUGH_WINDOW_MS = 5 * 60 * 1000L
    }
}

/**
 * Odak modu: ayarlar, susturma kaydı, bitişte özet bildirimi ve hızlı
 * ayarlar kutucuğu. Mesa'nın kendi bildirimlerini (birleşik bildirimler,
 * Telegram, web servisleri) susturur; birleşik bildirimler kapalıyken diğer
 * uygulamaların kendi bildirimleri yine çalabilir (ekran bunu söyler).
 */
object Focus {

    private const val TAG = "MesajMerkezi"
    private const val PREFS = "focus"
    const val ACTION_END = "com.mesajmerkezi.mesaj_merkezi.FOCUS_END"
    private const val CHANNEL = "focus"
    private const val NOTIFICATION_ID = 11
    private const val MAX_KEYS = 50

    private val recent = HashMap<String, ArrayDeque<Long>>()

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    internal fun policy(context: Context): FocusPolicy {
        val p = prefs(context)
        return FocusPolicy(
            manualUntil = p.getLong("manual_until", 0),
            schedule = if (p.getBoolean("schedule_on", false)) {
                FocusPolicy.Schedule(p.getInt("schedule_from", 22 * 60), p.getInt("schedule_to", 7 * 60), p.getInt("schedule_days", Rule.ALL_DAYS))
            } else {
                null
            },
            schedulePausedUntil = p.getLong("schedule_paused_until", 0),
            vip = p.getStringSet("vip", emptySet()).orEmpty(),
            breakthrough = p.getBoolean("breakthrough", true),
        )
    }

    fun isActive(context: Context) = policy(context).isActive(System.currentTimeMillis())

    /**
     * Yeni mesaj bildirimi gösterilmeden önce: true ise susturulur (mesaj
     * Mesa'da kalır, bildirim çıkmaz) ve susturulanlar sayılır.
     */
    fun shouldSilence(context: Context, key: String, important: Boolean): Boolean {
        val now = System.currentTimeMillis()
        val policy = policy(context)
        val recentForKey = synchronized(recent) {
            recent[key]?.filter { now - it < FocusPolicy.BREAKTHROUGH_WINDOW_MS }.orEmpty()
        }
        return when (policy.decide(key, important, now, recentForKey)) {
            FocusPolicy.Decision.SILENCE -> {
                record(context, key, now, policy)
                true
            }
            FocusPolicy.Decision.ALLOW_BREAKTHROUGH -> {
                synchronized(recent) { recent.remove(key) }
                Log.i(TAG, "Odak: acil durum geçişi (aynı sohbet 5 dk'da 3. kez yazdı)")
                false
            }
            else -> false
        }
    }

    private fun record(context: Context, key: String, now: Long, policy: FocusPolicy) {
        synchronized(recent) { recent.getOrPut(key) { ArrayDeque() }.addLast(now) }
        val p = prefs(context)
        val keys = p.getStringSet("silenced_keys", emptySet()).orEmpty()
        p.edit()
            .putInt("silenced", p.getInt("silenced", 0) + 1)
            .putStringSet("silenced_keys", if (keys.size < MAX_KEYS) keys + key else keys)
            .apply()
        Log.i(TAG, "Odak: bildirim susturuldu")
        // Özet bildirimi bitişte çıksın.
        policy.end(now)?.let { scheduleEnd(context, it) }
    }

    // ---- Ayarlar ----

    /** [until]: 0 kapat, Long.MAX_VALUE kapatılana kadar, diğer: bu ana kadar. */
    fun setManual(context: Context, until: Long) {
        val p = prefs(context)
        val now = System.currentTimeMillis()
        val edit = p.edit().putLong("manual_until", until)
        if (until == 0L && policy(context).scheduleActive(now)) {
            // Zamanlanmış aralıkta elle kapatıldı: bu aralık boyunca duraklat.
            edit.putLong("schedule_paused_until", policy(context).scheduleEnd(now))
        } else if (until != 0L) {
            edit.putLong("schedule_paused_until", 0)
        }
        edit.commit()
        Log.i(TAG, "Odak elle: ${if (until == 0L) "kapalı" else "açık"}")
        afterChange(context)
    }

    fun setSchedule(context: Context, enabled: Boolean, from: Int, to: Int, days: Int) {
        prefs(context).edit()
            .putBoolean("schedule_on", enabled)
            .putInt("schedule_from", from.coerceIn(0, 1439))
            .putInt("schedule_to", to.coerceIn(0, 1439))
            .putInt("schedule_days", days and Rule.ALL_DAYS)
            .putLong("schedule_paused_until", 0)
            .commit()
        afterChange(context)
    }

    fun setVip(context: Context, keys: Collection<String>) {
        prefs(context).edit().putStringSet("vip", keys.toSet()).apply()
    }

    fun setBreakthrough(context: Context, enabled: Boolean) {
        prefs(context).edit().putBoolean("breakthrough", enabled).apply()
    }

    private fun afterChange(context: Context) {
        val now = System.currentTimeMillis()
        val policy = policy(context)
        if (!policy.isActive(now)) finish(context) else policy.end(now)?.let { scheduleEnd(context, it) }
        refreshTile(context)
    }

    // ---- Bitiş ----

    private fun endIntent(context: Context) = PendingIntent.getBroadcast(
        context,
        "focus_end".hashCode(),
        Intent(context, ReminderReceiver::class.java).setAction(ACTION_END),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    private fun scheduleEnd(context: Context, at: Long) = Reminders.alarm(context, endIntent(context), at + 1_000)

    /** Bitiş alarmı (ReminderReceiver, Hub.io iş parçacığında). */
    internal fun onAlarm(context: Context) {
        val now = System.currentTimeMillis()
        val policy = policy(context)
        if (policy.isActive(now)) {
            policy.end(now)?.let { scheduleEnd(context, it) }
        } else {
            finish(context)
        }
        refreshTile(context)
    }

    /** Odak bitti: susturulan mesaj varsa özet bildirimi, sayaçlar sıfırlanır. */
    private fun finish(context: Context) {
        val p = prefs(context)
        val count = p.getInt("silenced", 0)
        val keys = p.getStringSet("silenced_keys", emptySet()).orEmpty()
        p.edit().putInt("silenced", 0).remove("silenced_keys").apply()
        synchronized(recent) { recent.clear() }
        if (count == 0) return
        Hub.io.execute {
            val names = keys.mapNotNull { Hub.store(context).conversation(it)?.get("title") as String? }.distinct()
            showSummary(context, count, names)
        }
    }

    internal fun summaryText(context: Context, names: List<String>): String = when {
        names.isEmpty() -> ""
        names.size <= 2 -> names.joinToString(", ")
        else -> Lang.str(context, R.string.focus_and_more, names.take(2).joinToString(", "), names.size - 2)
    }

    private fun showSummary(context: Context, count: Int, names: List<String>) {
        if (Build.VERSION.SDK_INT >= 33 &&
            context.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) != android.content.pm.PackageManager.PERMISSION_GRANTED
        ) return
        val manager = NotificationManagerCompat.from(context)
        manager.createNotificationChannel(
            NotificationChannelCompat.Builder(CHANNEL, NotificationManagerCompat.IMPORTANCE_LOW)
                .setName(Lang.str(context, R.string.focus_channel))
                .build()
        )
        val open = PendingIntent.getActivity(
            context,
            0,
            Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(context, CHANNEL)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(Lang.plural(context, R.plurals.focus_summary, count))
            .setContentText(summaryText(context, names))
            .setAutoCancel(true)
            .setContentIntent(open)
            .build()
        manager.notify(NOTIFICATION_ID, notification)
        Log.i(TAG, "Odak bitti: $count mesaj susturulmuştu")
    }

    private fun refreshTile(context: Context) {
        try {
            TileService.requestListeningState(context, ComponentName(context, FocusTileService::class.java))
        } catch (e: RuntimeException) {
            // Kutucuk eklenmemiş olabilir.
        }
    }

    fun status(context: Context): Map<String, Any?> {
        val now = System.currentTimeMillis()
        val p = prefs(context)
        val policy = policy(context)
        return mapOf(
            "active" to policy.isActive(now),
            "manualUntil" to policy.manualUntil.takeIf { policy.manualActive(now) },
            "scheduleOn" to p.getBoolean("schedule_on", false),
            "scheduleFrom" to p.getInt("schedule_from", 22 * 60),
            "scheduleTo" to p.getInt("schedule_to", 7 * 60),
            "scheduleDays" to p.getInt("schedule_days", Rule.ALL_DAYS),
            "scheduleActive" to policy.scheduleActive(now),
            "end" to policy.end(now),
            "vip" to policy.vip.toList(),
            "breakthrough" to policy.breakthrough,
            "silenced" to p.getInt("silenced", 0),
            "unified" to AppSettings.unifiedNotifications(context),
        )
    }
}
