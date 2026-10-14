package com.mesajmerkezi.mesaj_merkezi

import android.content.Context
import android.content.res.Configuration
import androidx.annotation.PluralsRes
import androidx.annotation.StringRes
import java.util.Locale

/**
 * Yerel taraftaki metinlerin (bildirimler, ana ekran bileşeni, web servisi
 * ekranı) dili: Flutter'da seçilen dil ("en", …); seçilmediyse telefonun dili.
 * Desteklenmeyen telefon dilinde res/values (İngilizce) kullanılır.
 * Seçim uygulama yeniden başlasa da (ör. açılışta gelen bildirim) bilinsin
 * diye kaydedilir.
 */
object Lang {

    private const val PREFS = "app_language"
    private const val KEY = "code"

    @Volatile
    private var code: String? = null

    @Volatile
    private var loaded = false

    @Volatile
    private var cached: Pair<String, Context>? = null

    fun set(context: Context, value: String?) {
        code = value
        loaded = true
        cached = null
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().apply {
            if (value == null) remove(KEY) else putString(KEY, value)
        }.apply()
    }

    fun code(context: Context): String? {
        if (!loaded) {
            code = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, null)
            loaded = true
        }
        return code
    }

    /** Seçilen dilde kaynaklara erişen bağlam (seçim yoksa kendisi). */
    fun context(context: Context): Context {
        val chosen = code(context) ?: return context
        cached?.let { (c, ctx) -> if (c == chosen) return ctx }
        val config = Configuration(context.resources.configuration).apply { setLocale(Locale(chosen)) }
        val localized = context.applicationContext.createConfigurationContext(config)
        cached = chosen to localized
        return localized
    }

    fun str(context: Context, @StringRes id: Int, vararg args: Any): String =
        if (args.isEmpty()) context(context).getString(id) else context(context).getString(id, *args)

    fun plural(context: Context, @PluralsRes id: Int, count: Int): String =
        context(context).resources.getQuantityString(id, count, count)
}

/**
 * Yakalarken veritabanına Türkçe yazılan medya etiketleri ("📷 Fotoğraf",
 * "🎤 Sesli mesaj: altyazı", "😀 Çıkartma"); bildirimde ve bileşende seçili
 * dilde gösterilir. Dart'taki karşılığı lib/l10n/stored_labels.dart.
 */
object StoredLabels {

    private val labels = listOf(
        "📷 Fotoğraf" to R.string.label_photo,
        "🎥 Video" to R.string.label_video,
        "🎵 Ses dosyası" to R.string.label_audio_file,
        "🎤 Sesli mesaj" to R.string.label_voice,
        "🎤 Ses" to R.string.label_audio,
        "⏺ Görüntülü mesaj" to R.string.label_video_note,
        "📍 Konum" to R.string.label_location,
        "📄 Dosya" to R.string.label_file,
        "👤 Kişi" to R.string.label_contact,
        "📊 Anket" to R.string.label_poll,
    )
    private const val STICKER = "Çıkartma"

    fun display(context: Context, text: String): String {
        if (text.isEmpty()) return text
        for ((label, id) in labels) {
            if (text == label) return Lang.str(context, id)
            if (text.startsWith("$label: ")) return Lang.str(context, id) + text.substring(label.length)
        }
        if (text == STICKER || text.endsWith(" $STICKER")) {
            return text.removeSuffix(STICKER) + Lang.str(context, R.string.label_sticker)
        }
        return text
    }
}
