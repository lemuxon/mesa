package com.mesajmerkezi.mesaj_merkezi

import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat

/**
 * Telegram bağlantısını ve web servislerini uygulama kapalıyken de açık tutan
 * ön plan servisi. Bildirim çubuğunda kalıcı, sessiz tek bir bildirim gösterir.
 * İkisi de gerekmiyorsa kendini kapatır.
 */
class ConnectionService : Service() {

    override fun onCreate() {
        super.onCreate()
        instance = this
        startInForeground()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        apply()
        return START_STICKY
    }

    override fun onDestroy() {
        instance = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?) = null

    /** Gerekenleri başlatır ve bildirim metnini günceller. Ana iş parçacığında. */
    private fun apply() {
        val telegram = telegramWanted(this)
        val web = WebServices.all(this).filter { it.background }
        if (!telegram && web.isEmpty()) {
            stopSelf()
            return
        }
        if (telegram) TelegramClient.start(this)
        WebHost.sync(this)
        startInForeground(telegram, web.map { it.name })
    }

    private fun startInForeground(telegram: Boolean = false, web: List<String> = emptyList()) {
        val manager = NotificationManagerCompat.from(this)
        manager.deleteNotificationChannel(OLD_CHANNEL_ID)
        manager.createNotificationChannel(
            NotificationChannelCompat.Builder(CHANNEL_ID, NotificationManagerCompat.IMPORTANCE_LOW)
                .setName(Lang.str(this, R.string.channel_connections))
                .setDescription(Lang.str(this, R.string.channel_connections_desc))
                .setShowBadge(false)
                .build()
        )
        val openApp = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE,
        )
        val names = (if (telegram) listOf("Telegram") else emptyList()) + web
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(
                when (names.size) {
                    0 -> "Mesa"
                    1 -> Lang.str(this, R.string.connected_one, names[0])
                    else -> Lang.plural(this, R.plurals.connected_services, names.size)
                }
            )
            .setContentText(
                if (names.size > 1) names.joinToString(", ") else Lang.str(this, R.string.connected_text)
            )
            .setOngoing(true)
            .setSilent(true)
            .setContentIntent(openApp)
            .build()
        // Tür sabiti API 34'te geldi; eski sürümlerde tür verilmez.
        val type = if (Build.VERSION.SDK_INT >= 34) ServiceInfo.FOREGROUND_SERVICE_TYPE_REMOTE_MESSAGING else 0
        ServiceCompat.startForeground(this, NOTIFICATION_ID, notification, type)
    }

    companion object {
        private const val TAG = "MesajMerkezi"
        private const val CHANNEL_ID = "connections"
        private const val OLD_CHANNEL_ID = "telegram_connection"
        private const val NOTIFICATION_ID = 1001

        @Volatile
        private var instance: ConnectionService? = null

        private fun telegramWanted(context: Context) =
            TelegramPrefs.enabled(context) && TelegramConfig.isConfigured

        fun needed(context: Context) = telegramWanted(context) || WebServices.anyBackground(context)

        /**
         * Telegram ya da arka plan web servisi ayarı değişti: servis gerekiyorsa
         * başlatılır ya da güncellenir, gerekmiyorsa kapatılır.
         */
        fun refresh(context: Context) {
            val running = instance
            if (!needed(context)) {
                context.stopService(Intent(context, ConnectionService::class.java))
                // Ekranda açık olmayan web görünümleri de kapansın.
                ContextCompat.getMainExecutor(context).execute { WebHost.sync(context) }
                return
            }
            if (running != null) {
                ContextCompat.getMainExecutor(context).execute { running.apply() }
                return
            }
            try {
                ContextCompat.startForegroundService(context, Intent(context, ConnectionService::class.java))
            } catch (e: IllegalStateException) {
                // Android 12+: uygulama arka plandayken ön plan servisi başlatılamaz;
                // uygulama bir sonraki açılışta başlatır.
                Log.w(TAG, "Bağlantı servisi başlatılamadı", e)
            }
        }
    }
}

/** Telefon açılınca ya da uygulama güncellenince bağlantıları geri getirir. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED &&
            intent.action != Intent.ACTION_MY_PACKAGE_REPLACED
        ) return
        if (ConnectionService.needed(context)) ConnectionService.refresh(context)
        // Alarmlar telefon kapanınca silinir: hatırlatmalar ve planlı mesajlar yeniden kurulur.
        val pending = goAsync()
        Hub.io.execute {
            try {
                Reminders.rescheduleAll(context)
            } finally {
                pending.finish()
            }
        }
    }
}
