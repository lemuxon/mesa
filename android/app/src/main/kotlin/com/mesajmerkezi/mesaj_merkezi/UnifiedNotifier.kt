package com.mesajmerkezi.mesaj_merkezi

import android.Manifest
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
import androidx.core.app.Person
import androidx.core.app.RemoteInput
import androidx.core.content.ContextCompat
import androidx.core.content.LocusIdCompat
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat

/**
 * Birleşik bildirimler: kaynak uygulamaların bildirimleri kaldırılır, yerine
 * sohbet başına tek bir Mesa bildirimi gösterilir (son mesajlar,
 * profil fotoğrafı, uygulama adı ve rengi, doğrudan yanıt, okundu).
 *
 * Kendi paketimiz desteklenenler listesinde olmadığı için bildirim
 * dinleyicisi bu bildirimleri mesaj sanıp tekrar kaydetmez.
 */
object UnifiedNotifier {

    private const val TAG = "MesajMerkezi"
    const val CHANNEL_ID = "unified_messages"
    private const val CHANNEL_IMPORTANT = "unified_important"
    private const val GROUP = "mesaj_merkezi"
    private const val SUMMARY_TAG = "ozet"
    private const val SHOWN_MESSAGES = 6

    const val ACTION_REPLY = "com.mesajmerkezi.mesaj_merkezi.REPLY"
    const val ACTION_MARK_READ = "com.mesajmerkezi.mesaj_merkezi.MARK_READ"
    const val EXTRA_KEY = "conversation_key"
    const val REPLY_INPUT = "reply_text"

    /** "Yanıtla" alanı; hazır yanıtlar bildirimin altında tek dokunuşla gönderilir. */
    fun replyInput(context: Context): RemoteInput =
        RemoteInput.Builder(REPLY_INPUT)
            .setLabel(Lang.str(context, R.string.notif_reply_label))
            .setChoices(
                AppSettings.quickReplies(context)
                    .take(AppSettings.NOTIFICATION_CHOICES)
                    .toTypedArray<CharSequence>()
            )
            .build()

    /**
     * Kullanıcının şu an Mesa'da açık tuttuğu sohbetler (bildirim
     * gösterilmez). Kişi ekranında kişinin tüm sohbetleri.
     */
    @Volatile
    var activeConversations: Set<String> = emptySet()

    fun canPost(context: Context) =
        Build.VERSION.SDK_INT < 33 ||
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED

    /**
     * Sohbetin bildirimini (yeniden) gösterir. [alert] false ise sessiz
     * güncellenir (ör. yanıt sonrası). Hub.io iş parçacığında çağrılmalı.
     */
    fun show(context: Context, key: String, alert: Boolean, important: Boolean = false) {
        if (!canPost(context)) {
            Log.w(TAG, "Birleşik bildirim gösterilemedi: bildirim izni yok")
            return
        }
        if (key in activeConversations) return
        val store = Hub.store(context)
        val info = store.conversation(key) ?: return
        val packageName = info["package"] as String
        // Web servisinin adı ve rengi listeden okunur (süreç yeni başladıysa liste henüz yüklenmemiş olabilir).
        if (WebServices.isWebPackage(packageName)) WebServices.all(context)
        val title = info["title"] as String
        val isGroup = info["isGroup"] as Boolean
        val unread = info["unread"] as Int
        val messages = store.messages(key).takeLast(SHOWN_MESSAGES)
        if (messages.isEmpty()) return

        val me = Person.Builder().setName(Lang.str(context, R.string.notif_you)).build()
        val style = NotificationCompat.MessagingStyle(me)
            .setGroupConversation(isGroup)
            .setConversationTitle(if (isGroup) title else null)
        val avatar = (info["avatarPath"] as String?)?.let { BitmapFactory.decodeFile(it) }
        for (m in messages) {
            val outgoing = m["outgoing"] as Boolean
            val sender = if (outgoing) null else Person.Builder()
                .setName((m["sender"] as String?) ?: title)
                .apply { if (!isGroup && avatar != null) setIcon(IconCompat.createWithBitmap(avatar)) }
                .build()
            style.addMessage(StoredLabels.display(context, m["text"] as String), m["time"] as Long, sender)
        }

        val manager = NotificationManagerCompat.from(context)
        ensureChannels(context, manager)
        val requestCode = key.hashCode()
        val reply = NotificationCompat.Action.Builder(
            android.R.drawable.ic_menu_send,
            Lang.str(context, R.string.notif_reply),
            PendingIntent.getBroadcast(
                context,
                requestCode,
                actionIntent(context, ACTION_REPLY, key),
                PendingIntent.FLAG_UPDATE_CURRENT or mutableFlag(),
            ),
        )
            .addRemoteInput(replyInput(context))
            .setSemanticAction(NotificationCompat.Action.SEMANTIC_ACTION_REPLY)
            .setShowsUserInterface(false)
            .build()
        val markRead = NotificationCompat.Action.Builder(
            android.R.drawable.ic_menu_view,
            Lang.str(context, R.string.notif_mark_read),
            PendingIntent.getBroadcast(
                context,
                requestCode,
                actionIntent(context, ACTION_MARK_READ, key),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            ),
        )
            .setSemanticAction(NotificationCompat.Action.SEMANTIC_ACTION_MARK_AS_READ)
            .setShowsUserInterface(false)
            .build()
        val web = WebServices.isWebKey(key)
        // Web servislerine yanıt sitenin kendisinden yazılır; bildirime dokununca o sohbet açılır.
        val open = if (web) {
            WebServiceActivity.pendingIntent(context, WebServices.idOfKey(key), WebHost.clickIdFor(key))
        } else {
            PendingIntent.getActivity(
                context,
                requestCode,
                Intent(context, MainActivity::class.java)
                    .putExtra(EXTRA_KEY, key)
                    .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        val shortcut = conversationShortcut(context, key, title, isGroup, avatar)
        val notification = NotificationCompat.Builder(context, if (important) CHANNEL_IMPORTANT else CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setColor(SupportedApps.color(packageName))
            .setSubText(
                SupportedApps.name(packageName) +
                    if (unread > 1) " · " + Lang.plural(context, R.plurals.notif_new, unread) else "",
            )
            .setLargeIcon(avatar ?: AvatarCache.appIconBitmap(context, packageName))
            .setStyle(style)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setGroup(GROUP)
            .setOnlyAlertOnce(!alert)
            .setSilent(!alert)
            .setAutoCancel(true)
            .setContentIntent(open)
            .apply { if (!web) addAction(reply) }
            .addAction(markRead)
            .setWhen(messages.last()["time"] as Long)
            .apply { if (shortcut != null) setShortcutInfo(shortcut) }
            .build()
        manager.notify(key, NOTIFICATION_ID, notification)
        showSummary(context, manager)
        Log.i(TAG, "Birleşik bildirim gösterildi: $packageName (uyarı=$alert, önemli=$important)")
    }

    /**
     * Android 11+ "Görüşmeler" bölümü: bildirim uzun ömürlü bir konuşma
     * kısayoluna bağlanınca kişi fotoğrafı büyük, yanıt alanı öne çıkmış
     * gösterilir (WhatsApp/Telegram bildirimleri gibi). Kısayol açılınca
     * Mesa'da o sohbet açılır. Yayınlanamazsa bildirim yine çıkar.
     */
    private fun conversationShortcut(
        context: Context,
        key: String,
        title: String,
        isGroup: Boolean,
        avatar: android.graphics.Bitmap?,
    ): ShortcutInfoCompat? = try {
        val icon = avatar?.let { IconCompat.createWithBitmap(it) }
            ?: IconCompat.createWithResource(context, R.mipmap.ic_launcher)
        ShortcutInfoCompat.Builder(context, shortcutId(key))
            .setShortLabel(title)
            .setLongLived(true)
            .setIcon(icon)
            .setLocusId(LocusIdCompat(key))
            .setIntent(
                Intent(context, MainActivity::class.java)
                    .setAction(Intent.ACTION_VIEW)
                    .putExtra(EXTRA_KEY, key)
            )
            .apply { if (!isGroup) setPerson(Person.Builder().setName(title).setKey(key).setIcon(icon).build()) }
            .build()
            .also { ShortcutManagerCompat.pushDynamicShortcut(context, it) }
    } catch (e: RuntimeException) {
        // Kısayol sınırı ya da başlatıcı desteği yok: düz bildirim yeterli.
        Log.i(TAG, "Konuşma kısayolu yayınlanamadı: ${e.javaClass.simpleName}")
        null
    }

    private fun shortcutId(key: String) = "sohbet_" + Integer.toHexString(key.hashCode())

    /** Sohbet silinince kısayolu da kalkar. */
    fun removeShortcut(context: Context, key: String) {
        ShortcutManagerCompat.removeLongLivedShortcuts(context, listOf(shortcutId(key)))
    }

    fun cancel(context: Context, key: String) {
        NotificationManagerCompat.from(context).cancel(key, NOTIFICATION_ID)
    }

    private fun showSummary(context: Context, manager: NotificationManagerCompat) {
        val summary = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("Mesa")
            .setGroup(GROUP)
            .setGroupSummary(true)
            .setSilent(true)
            .setAutoCancel(true)
            .build()
        manager.notify(SUMMARY_TAG, NOTIFICATION_ID, summary)
    }

    fun ensureChannels(context: Context, manager: NotificationManagerCompat) {
        manager.createNotificationChannel(
            NotificationChannelCompat.Builder(CHANNEL_ID, NotificationManagerCompat.IMPORTANCE_HIGH)
                .setName(Lang.str(context, R.string.channel_messages))
                .setDescription(Lang.str(context, R.string.channel_messages_desc))
                .build()
        )
        manager.createNotificationChannel(
            NotificationChannelCompat.Builder(CHANNEL_IMPORTANT, NotificationManagerCompat.IMPORTANCE_HIGH)
                .setName(Lang.str(context, R.string.channel_important))
                .setDescription(Lang.str(context, R.string.channel_important_desc))
                .build()
        )
    }

    private fun actionIntent(context: Context, action: String, key: String) =
        Intent(context, NotificationActionReceiver::class.java).setAction(action).putExtra(EXTRA_KEY, key)

    // RemoteInput yanıtı PendingIntent'e eklenebilsin diye değiştirilebilir olmalı (API 31+ zorunlu bayrak).
    private fun mutableFlag() = if (Build.VERSION.SDK_INT >= 31) PendingIntent.FLAG_MUTABLE else 0

    private const val NOTIFICATION_ID = 7

    /** Bildirimdeki "Yanıtla" ve "Okundu" düğmeleri. */
    class NotificationActionReceiver : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val key = intent.getStringExtra(EXTRA_KEY) ?: return
            val pending = goAsync()
            when (intent.action) {
                ACTION_REPLY -> {
                    val text = RemoteInput.getResultsFromIntent(intent)
                        ?.getCharSequence(REPLY_INPUT)?.toString()?.trim()
                    if (text.isNullOrEmpty()) return pending.finish()
                    Hub.io.execute {
                        try {
                            Hub.sendReply(context, key, text)
                            Log.i(TAG, "Bildirimden yanıt gönderildi")
                            val store = Hub.store(context)
                            if (Hub.recordsOwnReplies(key)) store.recordOutgoing(key, text)
                            store.markRead(key)
                            Hub.notifyChanged(key)
                            show(context, key, alert = false)
                        } catch (e: NoReplyActionException) {
                            Log.i(TAG, "Bildirimden yanıt gönderilemedi: yanıt yolu yok")
                            failed(context, key)
                        } finally {
                            pending.finish()
                        }
                    }
                }
                ACTION_MARK_READ -> Hub.io.execute {
                    Hub.store(context).markRead(key)
                    Hub.notifyChanged(key)
                    cancel(context, key)
                    pending.finish()
                }
                else -> pending.finish()
            }
        }

        private fun failed(context: Context, key: String) {
            if (!canPost(context)) return
            NotificationManagerCompat.from(context).notify(
                key,
                NOTIFICATION_ID,
                NotificationCompat.Builder(context, CHANNEL_ID)
                    .setSmallIcon(R.drawable.ic_notification)
                    .setContentTitle(Lang.str(context, R.string.reply_failed_title))
                    .setContentText(Lang.str(context, R.string.reply_failed_text))
                    .setSilent(true)
                    .setAutoCancel(true)
                    .build(),
            )
        }
    }
}
