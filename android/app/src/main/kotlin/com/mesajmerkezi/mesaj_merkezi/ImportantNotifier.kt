package com.mesajmerkezi.mesaj_merkezi

import android.Manifest
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

/**
 * "Önemli işaretle" kuralı çalışınca gösterilen bildirim. Sessize alınmış
 * kaynaklardan (ör. Telegram'da sessiz bir grup) gelen önemli mesaj da
 * böylece fark edilir. Kendi paketimiz desteklenenler listesinde olmadığı için
 * bildirim dinleyicisi bunu mesaj sanıp kaydetmez.
 */
object ImportantNotifier {

    private const val CHANNEL_ID = "important_messages"

    fun notify(context: Context, conversation: CapturedConversation, text: String) {
        if (!AppSettings.importantNotifications(context)) return
        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) return

        val manager = NotificationManagerCompat.from(context)
        manager.createNotificationChannel(
            NotificationChannelCompat.Builder(CHANNEL_ID, NotificationManagerCompat.IMPORTANCE_HIGH)
                .setName(Lang.str(context, R.string.channel_important))
                .setDescription(Lang.str(context, R.string.channel_important_desc))
                .build()
        )
        val open = PendingIntent.getActivity(
            context,
            0,
            Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.btn_star_big_on)
            .setContentTitle("⭐ ${conversation.title}")
            .setContentText(StoredLabels.display(context, text))
            .setStyle(NotificationCompat.BigTextStyle().bigText(StoredLabels.display(context, text)))
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(open)
            .build()
        // Sohbet başına bir bildirim: aynı sohbetten yeni önemli mesaj öncekinin yerine geçer.
        manager.notify(conversation.key, 0, notification)
    }
}
