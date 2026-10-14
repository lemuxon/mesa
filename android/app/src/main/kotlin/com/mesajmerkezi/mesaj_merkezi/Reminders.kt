package com.mesajmerkezi.mesaj_merkezi

import android.Manifest
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

/**
 * "Sonra hatırlat" ve planlı mesajlar. Zamanı gelince AlarmManager
 * ReminderReceiver'ı uyandırır; telefon yeniden başlayınca BootReceiver
 * hepsini yeniden kurar.
 *
 * Planlı mesaj Telegram'da Telegram sunucusunda bekler (telefon kapalı olsa
 * da gider). Diğer uygulamalarda zamanı gelince bildirimin yanıt yolu varsa
 * doğrudan gönderilir, yoksa "dokun, gönder" bildirimi çıkar.
 */
object Reminders {

    private const val TAG = "MesajMerkezi"
    private const val CHANNEL = "reminders"
    private const val NOTIFICATION_ID = 9
    const val ACTION_SNOOZE = "com.mesajmerkezi.mesaj_merkezi.SNOOZE_DUE"
    const val ACTION_SCHEDULED = "com.mesajmerkezi.mesaj_merkezi.SCHEDULED_DUE"
    const val EXTRA_KEY = "conversation_key"
    const val EXTRA_ID = "scheduled_id"

    // ---- Sonra hatırlat ----

    /** Hub.io iş parçacığında çağrılmalı. */
    fun snooze(context: Context, key: String, until: Long) {
        Hub.store(context).snooze(key, until)
        UnifiedNotifier.cancel(context, key)
        alarm(context, snoozeIntent(context, key), until)
        Log.i(TAG, "Sohbet ertelendi: ${(until - System.currentTimeMillis()) / 60_000} dk")
    }

    fun unsnooze(context: Context, key: String) {
        Hub.store(context).unsnooze(key, remind = false)
        alarmManager(context).cancel(snoozeIntent(context, key))
    }

    private fun snoozeIntent(context: Context, key: String) = PendingIntent.getBroadcast(
        context,
        "snooze|$key".hashCode(),
        Intent(context, ReminderReceiver::class.java).setAction(ACTION_SNOOZE).putExtra(EXTRA_KEY, key),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    // ---- Planlı mesajlar ----

    /** Hub.io iş parçacığında çağrılmalı. Planlı mesajın kimliği. */
    fun schedule(context: Context, key: String, text: String, at: Long): Long {
        val store = Hub.store(context)
        val id = store.addScheduled(key, text, at)
        if (TelegramClient.isTelegramKey(key) && TelegramClient.isReady) {
            // Telegram sunucusunda bekler; buradaki kayıt yalnızca listede görünsün diye.
            TelegramClient.sendScheduled(key, text, at) { remoteId ->
                Log.i(TAG, "Telegram sunucusu planlı mesajı ${if (remoteId != null) "kabul etti" else "kabul etmedi"}")
                if (remoteId != null) Hub.io.execute { store.setScheduledRemote(id, remoteId) }
            }
        }
        alarm(context, scheduledIntent(context, id), at)
        val app = if (TelegramClient.isTelegramKey(key)) "telegram" else store.conversation(key)?.get("package")
        val path = if (Hub.canReply(key)) "yanıt yolu var" else "yanıt yolu yok"
        Log.i(TAG, "Mesaj planlandı: ${(at - System.currentTimeMillis()) / 60_000} dk sonra ($app, $path)")
        return id
    }

    fun cancelScheduled(context: Context, id: Long) {
        val store = Hub.store(context)
        val row = store.scheduledById(id) ?: return
        val key = row["key"] as String
        (row["remoteId"] as Long?)?.let { TelegramClient.deleteMessages(key, longArrayOf(it)) }
        store.deleteScheduled(id)
        alarmManager(context).cancel(scheduledIntent(context, id))
    }

    private fun scheduledIntent(context: Context, id: Long) = PendingIntent.getBroadcast(
        context,
        "scheduled|$id".hashCode(),
        Intent(context, ReminderReceiver::class.java).setAction(ACTION_SCHEDULED).putExtra(EXTRA_ID, id),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    /** Telefon açılınca ya da güncellemeden sonra (Hub.io iş parçacığında). */
    fun rescheduleAll(context: Context) {
        val store = Hub.store(context)
        val now = System.currentTimeMillis()
        for (row in store.snoozed()) {
            val key = row["key"] as String
            val until = row["until"] as Long
            if (until <= now) remindNow(context, key) else alarm(context, snoozeIntent(context, key), until)
        }
        for (row in store.scheduled()) {
            val id = row["id"] as Long
            val at = row["at"] as Long
            if (at <= now) deliverScheduled(context, id) else alarm(context, scheduledIntent(context, id), at)
        }
    }

    // ---- Zamanı gelince ----

    internal fun remindNow(context: Context, key: String) {
        val store = Hub.store(context)
        store.unsnooze(key, remind = true)
        Hub.notifyChanged(key)
        val info = store.conversation(key) ?: return
        val title = info["title"] as String
        val packageName = info["package"] as String
        val open = PendingIntent.getActivity(
            context,
            "remind|$key".hashCode(),
            Intent(context, MainActivity::class.java)
                .putExtra(UnifiedNotifier.EXTRA_KEY, key)
                .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val avatar = (info["avatarPath"] as String?)?.let { BitmapFactory.decodeFile(it) }
        notify(
            context,
            "remind|$key",
            NotificationCompat.Builder(context, CHANNEL)
                .setSmallIcon(R.drawable.ic_notification)
                .setColor(SupportedApps.color(packageName))
                .setContentTitle("⏰ $title")
                .setContentText(Lang.str(context, R.string.reminder_text))
                .setSubText(SupportedApps.name(packageName))
                .setLargeIcon(avatar ?: AvatarCache.appIconBitmap(context, packageName))
                .setCategory(NotificationCompat.CATEGORY_REMINDER)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .setContentIntent(open)
                .build(),
        )
        Log.i(TAG, "Hatırlatma gösterildi")
    }

    internal fun deliverScheduled(context: Context, id: Long) {
        val store = Hub.store(context)
        val row = store.scheduledById(id) ?: return
        store.deleteScheduled(id)
        val key = row["key"] as String
        val text = row["text"] as String
        // Telegram'da sunucu kendisi gönderdi.
        if (TelegramClient.isTelegramKey(key) && row["remoteId"] != null) {
            Log.i(TAG, "Planlı mesajın zamanı geldi: Telegram sunucusu gönderdi")
            return
        }
        if (TelegramClient.isTelegramKey(key) && TelegramClient.isReady) {
            TelegramClient.sendText(key, text, auto = false)
            Log.i(TAG, "Planlı mesaj Telegram'a gönderildi")
            return
        }
        val info = store.conversation(key) ?: return
        val title = info["title"] as String
        val packageName = info["package"] as String
        try {
            Hub.sendReply(context, key, text)
            store.recordOutgoing(key, text)
            Hub.notifyChanged(key)
            Log.i(TAG, "Planlı mesaj gönderildi: $packageName")
            notify(
                context,
                "scheduled|$id",
                NotificationCompat.Builder(context, CHANNEL)
                    .setSmallIcon(R.drawable.ic_notification)
                    .setColor(SupportedApps.color(packageName))
                    .setContentTitle(Lang.str(context, R.string.scheduled_sent))
                    .setContentText("$title: $text")
                    .setSubText(SupportedApps.name(packageName))
                    .setSilent(true)
                    .setAutoCancel(true)
                    .build(),
            )
        } catch (e: NoReplyActionException) {
            // Yanıt yolu yok: dokununca uygulama sohbeti metin hazır açar.
            val shortcut = info["shortcutId"] as String?
            val share = MediaTools.shareIntent(context, packageName, shortcut, text, emptyList())
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            val tap = PendingIntent.getActivity(
                context,
                "scheduled|$id".hashCode(),
                share,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            notify(
                context,
                "scheduled|$id",
                NotificationCompat.Builder(context, CHANNEL)
                    .setSmallIcon(R.drawable.ic_notification)
                    .setColor(SupportedApps.color(packageName))
                    .setContentTitle(Lang.str(context, R.string.scheduled_due_title, title))
                    .setContentText(Lang.str(context, R.string.scheduled_due_text, SupportedApps.name(packageName), text))
                    .setStyle(NotificationCompat.BigTextStyle().bigText(text))
                    .setCategory(NotificationCompat.CATEGORY_REMINDER)
                    .setPriority(NotificationCompat.PRIORITY_HIGH)
                    .setAutoCancel(true)
                    .setContentIntent(tap)
                    .addAction(android.R.drawable.ic_menu_send, Lang.str(context, R.string.send), tap)
                    .build(),
            )
            val reason = if (e.canceled) "uygulama yanıt yolunu iptal etmiş" else "yanıt yolu yok"
            Log.i(TAG, "Planlı mesaj için dokun-gönder bildirimi: $packageName ($reason)")
        }
    }

    // ---- Yardımcılar ----

    private fun alarmManager(context: Context) = context.getSystemService(AlarmManager::class.java)

    private fun alarm(context: Context, intent: PendingIntent, at: Long) {
        val manager = alarmManager(context)
        try {
            if (Build.VERSION.SDK_INT >= 31 && !manager.canScheduleExactAlarms()) {
                manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, intent)
            } else {
                manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, intent)
            }
        } catch (e: SecurityException) {
            manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, intent)
        }
    }

    private fun notify(context: Context, tag: String, notification: android.app.Notification) {
        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) return
        val manager = NotificationManagerCompat.from(context)
        manager.createNotificationChannel(
            NotificationChannelCompat.Builder(CHANNEL, NotificationManagerCompat.IMPORTANCE_HIGH)
                .setName(Lang.str(context, R.string.channel_reminders))
                .setDescription(Lang.str(context, R.string.channel_reminders_desc))
                .build()
        )
        manager.notify(tag, NOTIFICATION_ID, notification)
    }
}

/** Hatırlatma ve planlı mesaj alarmları. */
class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val pending = goAsync()
        Hub.io.execute {
            try {
                when (intent.action) {
                    Reminders.ACTION_SNOOZE ->
                        intent.getStringExtra(Reminders.EXTRA_KEY)?.let { Reminders.remindNow(context, it) }
                    Reminders.ACTION_SCHEDULED ->
                        intent.getLongExtra(Reminders.EXTRA_ID, -1).takeIf { it >= 0 }
                            ?.let { Reminders.deliverScheduled(context, it) }
                }
            } finally {
                pending.finish()
            }
        }
    }
}
