package com.mesajmerkezi.mesaj_merkezi

import android.content.Context
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.util.Log
import com.google.android.gms.tasks.Task
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.common.model.DownloadConditions
import com.google.mlkit.common.model.RemoteModelManager
import com.google.mlkit.common.sdkinternal.MlKitContext
import com.google.mlkit.nl.languageid.LanguageIdentification
import com.google.mlkit.nl.languageid.LanguageIdentificationOptions
import com.google.mlkit.nl.languageid.LanguageIdentifier
import com.google.mlkit.nl.translate.TranslateLanguage
import com.google.mlkit.nl.translate.TranslateRemoteModel
import com.google.mlkit.nl.translate.Translation
import com.google.mlkit.nl.translate.Translator
import com.google.mlkit.nl.translate.TranslatorOptions
import java.util.Locale
import java.util.concurrent.TimeUnit

/**
 * Mesaj çevirisi, telefonda (Google ML Kit).
 *
 * Mesajın metni hiçbir sunucuya gitmez: dil tanıma modeli uygulamanın
 * içindedir; her dilin çeviri paketi (~30 MB) kullanıcı onaylayınca bir kez
 * Google'dan indirilir, sonra çeviri internetsiz yapılır. ML Kit, kullanıcı
 * çeviri isteyene kadar başlatılmaz (manifestte kendi başlatıcısı
 * kaldırıldı): çeviriyi kullanmayan biri için hiçbir şey yapmaz.
 *
 * İşler kendi iş parçacığında sırayla yapılır (paket indirmesi dakikalar
 * sürebilir, veritabanı kuyruğu [Hub.io] beklemesin). Son kullanılan çevirmen
 * art arda mesajlar hızlı çevrilsin diye bir süre açık kalır, sonra kapatılır.
 */
object MessageTranslator {
    private const val TAG = "MesajMerkezi"
    private const val PREFS = "translation"

    /** Açık çevirmen ve dil tanıyıcı bu kadar boşta kalınca kapatılır (bellek). */
    private const val IDLE_CLOSE_MS = 90_000L

    /** Dil tanıma bu güvenin altındaysa dil "bilinmiyor" sayılır. */
    private const val MIN_CONFIDENCE = 0.3f

    private val worker: Handler by lazy { Handler(HandlerThread("mesa-ceviri").apply { start() }.looper) }
    private val main = Handler(Looper.getMainLooper())

    // Yalnızca worker iş parçacığında kullanılır.
    private var initialized = false
    private var identifier: LanguageIdentifier? = null
    private var translator: Pair<String, Translator>? = null
    private val closeIdle = Runnable { closeAll() }

    /**
     * ML Kit'in çevirebildiği dil kodu ("iw" → "he", "en-US" → "en"); dil
     * belirsizse ya da çevrilemiyorsa null. Latin harfle yazılmış Hintçe,
     * Japonca… ("hi-Latn") için çeviri modeli yok.
     */
    internal fun translateCode(tag: String?): String? {
        if (tag.isNullOrBlank() || tag == "und") return null
        if (tag.contains("-Latn", ignoreCase = true)) return null
        val base = when (val language = tag.substringBefore('-').substringBefore('_').lowercase(Locale.ROOT)) {
            "iw" -> "he"
            "in" -> "id"
            "ji" -> "yi"
            "fil" -> "tl"
            "nb", "nn" -> "no"
            else -> language
        }
        return base.takeIf { it in TranslateLanguage.getAllLanguages() }
    }

    /**
     * Dilin adı, [inLanguage] dilinde ("en", "tr" → "İngilizce"; "en", "fr" →
     * "anglais"). Cümle içinde kullanıldığı için büyük harfe çevrilmez.
     */
    fun displayName(code: String, inLanguage: String): String {
        val name = Locale.forLanguageTag(code).getDisplayLanguage(Locale.forLanguageTag(inLanguage))
        return name.ifEmpty { code }
    }

    /** Satır satır çevirir (çevirmen satır sonlarını korumuyor); boş satırlar aynen kalır. */
    internal fun byLines(text: String, translate: (String) -> String): String =
        text.split('\n').joinToString("\n") { line -> if (line.isBlank()) line else translate(line.trim()) }

    /** Çeviri en az bir kez kullanıldı (dil paketi listesi ML Kit'i boşuna başlatmasın). */
    private fun used(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getBoolean("used", false)

    private fun markUsed(context: Context) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putBoolean("used", true).apply()
    }

    /**
     * Mesajı [target] diline çevirir ve saklar; sonuç ana iş parçacığında döner:
     * "text", "from", "fromName" ya da "error": NEED_DOWNLOAD ("missing",
     * "missingNames": indirilecek paketler; [allowDownload] ile yeniden
     * çağrılır), SAME_LANGUAGE, UNKNOWN_LANGUAGE, UNSUPPORTED_LANGUAGE,
     * DOWNLOAD_FAILED, NOTHING (çevrilecek yazı yok), NOT_FOUND, ERROR.
     * [hint]: dil tanıma emin olamazsa kullanılacak tahmin (Dart'taki kaba tahmin).
     */
    fun translateMessage(
        context: Context,
        messageId: String,
        target: String,
        allowDownload: Boolean,
        hint: String?,
        done: (Map<String, Any?>) -> Unit,
    ) {
        val app = context.applicationContext
        fun reply(result: Map<String, Any?>) {
            main.post { done(result) }
        }
        Hub.io.execute {
            val store = Hub.store(app)
            val source = store.translationSource(messageId) ?: return@execute reply(mapOf("error" to "NOT_FOUND"))
            if (source.translation != null && source.to == target) {
                return@execute reply(
                    mapOf(
                        "text" to source.translation,
                        "from" to source.from,
                        "fromName" to source.from?.let { displayName(it, target) },
                    ),
                )
            }
            val text = StoredLabels.caption(source.text).trim()
            if (text.none { it.isLetter() }) return@execute reply(mapOf("error" to "NOTHING"))
            translateText(app, text, target, allowDownload, hint) { result ->
                val translated = result["text"] as String?
                if (translated != null) {
                    Hub.io.execute {
                        store.setTranslation(messageId, translated, result["from"] as String?, target)
                        Hub.notifyChanged(source.key)
                    }
                }
                done(result)
            }
        }
    }

    /**
     * Yazıyı çevirir (veritabanına dokunmadan); sonuç ana iş parçacığında,
     * [translateMessage] ile aynı biçimde döner.
     */
    internal fun translateText(
        context: Context,
        text: String,
        target: String,
        allowDownload: Boolean,
        hint: String?,
        done: (Map<String, Any?>) -> Unit,
    ) {
        val app = context.applicationContext
        worker.post {
            val result = try {
                translate(app, text, target, allowDownload, hint)
            } catch (e: Exception) {
                Log.w(TAG, "Çeviri başarısız: ${e.javaClass.simpleName}")
                mapOf("error" to "ERROR")
            }
            if (result["text"] != null) markUsed(app)
            worker.removeCallbacks(closeIdle)
            worker.postDelayed(closeIdle, IDLE_CLOSE_MS)
            main.post { done(result) }
        }
    }

    /** Worker'da: dili bulur, gerekirse paketleri indirir, çevirir. */
    private fun translate(
        context: Context,
        text: String,
        target: String,
        allowDownload: Boolean,
        hint: String?,
    ): Map<String, Any?> {
        val to = translateCode(target) ?: return mapOf("error" to "ERROR")
        ensureInitialized(context)
        val identified = identify(text)
        val from = when {
            identified != null -> translateCode(identified)
                ?: return mapOf("error" to "UNSUPPORTED_LANGUAGE", "fromName" to displayName(identified, target))
            else -> translateCode(hint) ?: return mapOf("error" to "UNKNOWN_LANGUAGE")
        }
        val fromName = displayName(from, target)
        if (from == to) return mapOf("error" to "SAME_LANGUAGE", "from" to from, "fromName" to fromName)
        val missing = missingModels(from, to)
        if (missing.isNotEmpty() && !allowDownload) {
            return mapOf(
                "error" to "NEED_DOWNLOAD",
                "from" to from,
                "fromName" to fromName,
                "missing" to missing,
                "missingNames" to missing.map { displayName(it, target) },
            )
        }
        val client = translatorFor(from, to)
        if (missing.isNotEmpty()) {
            try {
                val started = System.currentTimeMillis()
                await(client.downloadModelIfNeeded(DownloadConditions.Builder().build()), 10, TimeUnit.MINUTES)
                markUsed(context)
                Log.i(TAG, "Çeviri paketi indirildi: $missing (${System.currentTimeMillis() - started} ms)")
            } catch (e: Exception) {
                Log.w(TAG, "Çeviri paketi indirilemedi: ${e.javaClass.simpleName} ${e.cause?.javaClass?.simpleName}")
                return mapOf("error" to "DOWNLOAD_FAILED", "from" to from, "fromName" to fromName)
            }
        }
        val started = System.currentTimeMillis()
        val translated = byLines(text) { line -> await(client.translate(line), 60, TimeUnit.SECONDS) }
        Log.i(TAG, "Mesaj çevrildi: $from → $to (${System.currentTimeMillis() - started} ms)")
        return mapOf("text" to translated, "from" to from, "fromName" to fromName)
    }

    /** Metnin en olası dili; emin olunamazsa null. */
    private fun identify(text: String): String? {
        val client = identifier ?: LanguageIdentification.getClient(
            LanguageIdentificationOptions.Builder().setConfidenceThreshold(MIN_CONFIDENCE).build(),
        ).also { identifier = it }
        return await(client.identifyPossibleLanguages(text), 20, TimeUnit.SECONDS)
            .firstOrNull { it.languageTag != "und" }
            ?.languageTag
    }

    /** İndirilmesi gereken paketler. İngilizce paket hep telefonda (çeviriler onun üzerinden yapılır). */
    private fun missingModels(vararg languages: String): List<String> {
        val manager = RemoteModelManager.getInstance()
        return languages.distinct().filter { language ->
            language != TranslateLanguage.ENGLISH &&
                !await(manager.isModelDownloaded(TranslateRemoteModel.Builder(language).build()), 20, TimeUnit.SECONDS)
        }
    }

    private fun translatorFor(from: String, to: String): Translator {
        val pair = "$from>$to"
        translator?.let { (key, client) ->
            if (key == pair) return client
            client.close()
        }
        val client = Translation.getClient(
            TranslatorOptions.Builder().setSourceLanguage(from).setTargetLanguage(to).build(),
        )
        translator = pair to client
        return client
    }

    private fun ensureInitialized(context: Context) {
        if (initialized) return
        MlKitContext.initializeIfNeeded(context.applicationContext)
        initialized = true
    }

    private fun closeAll() {
        translator?.second?.close()
        translator = null
        identifier?.close()
        identifier = null
    }

    private fun <T> await(task: Task<T>, timeout: Long, unit: TimeUnit): T = Tasks.await(task, timeout, unit)

    /** İndirilmiş çeviri paketleri (İngilizce hep var, listelenmez): kod ve [inLanguage] dilinde adı. */
    fun downloadedPacks(context: Context, inLanguage: String, done: (List<Map<String, String>>) -> Unit) {
        val app = context.applicationContext
        if (!used(app)) return done(emptyList())
        worker.post {
            val packs = try {
                ensureInitialized(app)
                await(RemoteModelManager.getInstance().getDownloadedModels(TranslateRemoteModel::class.java), 20, TimeUnit.SECONDS)
                    .map { it.language }
                    .filter { it != TranslateLanguage.ENGLISH }
                    .map { mapOf("code" to it, "name" to displayName(it, inLanguage)) }
                    .sortedBy { it["name"] }
            } catch (e: Exception) {
                Log.w(TAG, "Çeviri paketleri okunamadı: ${e.javaClass.simpleName}")
                emptyList()
            }
            main.post { done(packs) }
        }
    }

    /** Çeviri paketini siler (yer açmak için); sonra o dil yeniden indirilmeden çevrilemez. */
    fun deletePack(context: Context, code: String, done: (Boolean) -> Unit) {
        val app = context.applicationContext
        worker.post {
            val ok = try {
                ensureInitialized(app)
                // Açık çevirmen bu paketi kullanıyor olabilir.
                closeAll()
                await(
                    RemoteModelManager.getInstance().deleteDownloadedModel(TranslateRemoteModel.Builder(code).build()),
                    30,
                    TimeUnit.SECONDS,
                )
                Log.i(TAG, "Çeviri paketi silindi: $code")
                true
            } catch (e: Exception) {
                Log.w(TAG, "Çeviri paketi silinemedi: ${e.javaClass.simpleName}")
                false
            }
            main.post { done(ok) }
        }
    }
}
