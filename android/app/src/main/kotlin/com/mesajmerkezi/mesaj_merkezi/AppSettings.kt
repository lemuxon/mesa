package com.mesajmerkezi.mesaj_merkezi

import android.content.Context
import android.util.Log

/**
 * Bildirim servisi ve Telegram istemcisinin de okuduğu kullanıcı ayarları.
 * Uygulama kilidi ve hazır yanıtlar gibi yalnızca arayüzü ilgilendirenler
 * Dart tarafında tutulur.
 */
object AppSettings {

    private const val DISABLED_PACKAGES = "disabled_packages"
    private const val HIDE_TELEGRAM_CHANNELS = "hide_telegram_channels"
    private const val RETENTION_DAYS = "retention_days"
    private const val IMPORTANT_NOTIFICATIONS = "important_notifications"
    private const val UNIFIED_NOTIFICATIONS = "unified_notifications"
    private const val TELEGRAM_GHOST_READ = "telegram_ghost_read"
    private const val KEEP_SOURCE_PACKAGES = "keep_source_packages"
    private const val QUICK_REPLIES = "quick_replies"

    /** Bildirimdeki "Yanıtla" alanında tek dokunuşluk seçenek sayısı. */
    const val NOTIFICATION_CHOICES = 3

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences("settings", Context.MODE_PRIVATE)

    /** Mesajları okunmayacak uygulamalar (paket adı). */
    fun disabledPackages(context: Context): Set<String> =
        prefs(context).getStringSet(DISABLED_PACKAGES, emptySet()).orEmpty()

    fun isCaptured(context: Context, packageName: String) = packageName !in disabledPackages(context)

    /** Telegram yayın kanallarının mesajları alınmaz (gruplar ve kişiler alınır). */
    fun hideTelegramChannels(context: Context) = prefs(context).getBoolean(HIDE_TELEGRAM_CHANNELS, false)

    /** Bundan eski mesajlar silinir; 0 = süresiz. */
    fun retentionDays(context: Context) = prefs(context).getInt(RETENTION_DAYS, 0)

    /** "Önemli işaretle" kuralı çalışınca Mesa bildirim gösterir. */
    fun importantNotifications(context: Context) = prefs(context).getBoolean(IMPORTANT_NOTIFICATIONS, true)

    /**
     * Birleşik bildirimler: kaynak uygulamaların mesaj bildirimleri kaldırılır,
     * yerine Mesa'nınki gösterilir. Kullanıcı açıkça açar.
     */
    fun unifiedNotifications(context: Context) = prefs(context).getBoolean(UNIFIED_NOTIFICATIONS, false)

    /**
     * Telegram'da gizli okuma: sohbet açılınca "görüldü", yazarken "yazıyor"
     * gönderilmez. WhatsApp ve Instagram'da Mesa zaten göndermez.
     */
    fun telegramGhostRead(context: Context) = prefs(context).getBoolean(TELEGRAM_GHOST_READ, false)

    /**
     * Birleşik bildirimlerde kendi bildirimi de çubukta kalan uygulamalar.
     * Bildirim durdukça yanıt yolu (RemoteInput) uygulama yeniden başlayınca
     * geri alınır; Mesa'nın bildirimi bunlarda sessiz gelir.
     */
    fun keepSourcePackages(context: Context): Set<String> =
        prefs(context).getStringSet(KEEP_SOURCE_PACKAGES, emptySet()).orEmpty()

    fun keepsSource(context: Context, packageName: String) = packageName in keepSourcePackages(context)

    /**
     * Hazır yanıtlar (Flutter'daki listenin kopyası): bildirimde tek
     * dokunuşla gönderilebilsin. Sıra korunur.
     */
    fun quickReplies(context: Context): List<String> =
        prefs(context).getString(QUICK_REPLIES, null)
            ?.split('\n')
            ?.filter { it.isNotBlank() }
            .orEmpty()

    fun setQuickReplies(context: Context, replies: List<String>) {
        prefs(context).edit()
            .putString(QUICK_REPLIES, replies.map { it.replace('\n', ' ').trim() }.filter { it.isNotEmpty() }.joinToString("\n"))
            .apply()
    }

    fun toMap(context: Context): Map<String, Any?> = mapOf(
        "disabledPackages" to disabledPackages(context).toList(),
        "hideTelegramChannels" to hideTelegramChannels(context),
        "retentionDays" to retentionDays(context),
        "importantNotifications" to importantNotifications(context),
        "unifiedNotifications" to unifiedNotifications(context),
        "telegramGhostRead" to telegramGhostRead(context),
        "keepSourcePackages" to keepSourcePackages(context).toList(),
    )

    /** Haritadaki anahtarları yazar; olmayanlara dokunmaz. */
    fun update(context: Context, values: Map<*, *>) {
        val editor = prefs(context).edit()
        (values["disabledPackages"] as List<*>?)?.let { list ->
            editor.putStringSet(DISABLED_PACKAGES, list.map { it as String }.toSet())
        }
        (values["hideTelegramChannels"] as Boolean?)?.let { editor.putBoolean(HIDE_TELEGRAM_CHANNELS, it) }
        (values["retentionDays"] as Number?)?.let { editor.putInt(RETENTION_DAYS, it.toInt()) }
        (values["importantNotifications"] as Boolean?)?.let { editor.putBoolean(IMPORTANT_NOTIFICATIONS, it) }
        (values["unifiedNotifications"] as Boolean?)?.let {
            if (it != unifiedNotifications(context)) Log.i("MesajMerkezi", "Birleşik bildirimler: ${if (it) "açık" else "kapalı"}")
            editor.putBoolean(UNIFIED_NOTIFICATIONS, it)
        }
        (values["telegramGhostRead"] as Boolean?)?.let { editor.putBoolean(TELEGRAM_GHOST_READ, it) }
        (values["keepSourcePackages"] as List<*>?)?.let { list ->
            val packages = list.map { it as String }.toSet()
            if (packages != keepSourcePackages(context)) Log.i("MesajMerkezi", "Kendi bildirimi kalan: ${packages.sorted()}")
            editor.putStringSet(KEEP_SOURCE_PACKAGES, packages)
        }
        editor.apply()
    }
}
