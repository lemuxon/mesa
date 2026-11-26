package com.mesajmerkezi.mesaj_merkezi

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import android.util.Log
import androidx.core.content.ContextCompat
import java.io.File
import java.text.SimpleDateFormat
import java.util.Locale
import kotlin.math.abs

/**
 * Sesli mesajların yazıya çevrilmesi ([Transcriber]) için sesin bulunması.
 *
 * WhatsApp bildirimi sesi taşımaz, yalnızca "🎤 Sesli mesaj (0:12)" yazar.
 * WhatsApp sesli mesajları kendisi indirip telefonda saklar
 * (Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Voice Notes/<hafta>/PTT-yyyyMMdd-WAnnnn.opus);
 * klasörde .nomedia olduğu için başka uygulamalar göremez. Kullanıcı bu
 * klasörü bir kez seçerek Mesa'ya okuma izni verir; mesaj, dosyanın zamanı
 * ve (varsa) süresiyle eşleştirilir. Tek bir dosyaya kesin eşleşmezse hiçbiri
 * kullanılmaz (yanlış mesajın yazısı gösterilmesin). Telegram sesleri TDLib'den
 * indirilir.
 */
object VoiceNotes {
    private const val TAG = "MesajMerkezi"
    private const val PREFS = "voice_notes"

    /** Uygulamaların ses klasörü (Android/media altında, klasör seçiciyle izin verilebilir). */
    private val folders = mapOf(
        "com.whatsapp" to "Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Voice Notes",
        "com.whatsapp.w4b" to "Android/media/com.whatsapp.w4b/WhatsApp Business/Media/WhatsApp Business Voice Notes",
    )

    fun supportsFolder(packageName: String) = packageName in folders

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    /** Klasör seçicinin açılacağı yer: doğrudan uygulamanın ses klasörü. */
    fun initialUri(packageName: String): Uri? = folders[packageName]?.let {
        DocumentsContract.buildDocumentUri("com.android.externalstorage.documents", "primary:$it")
    }

    /** İzni hâlâ duran ses klasörü; yoksa null. */
    fun folder(context: Context, packageName: String): Uri? {
        val uri = prefs(context).getString("tree_$packageName", null)?.let(Uri::parse) ?: return null
        val granted = context.contentResolver.persistedUriPermissions.any { it.uri == uri && it.isReadPermission }
        return uri.takeIf { granted }
    }

    /**
     * Kullanıcının seçtiği klasör: yalnızca uygulamanın ses klasörüyse saklanır.
     * @return doğru klasör seçildi
     */
    fun saveFolder(context: Context, packageName: String, tree: Uri): Boolean {
        val docId = try {
            DocumentsContract.getTreeDocumentId(tree)
        } catch (e: IllegalArgumentException) {
            return false
        }
        if (!docId.endsWith("Voice Notes")) return false
        context.contentResolver.takePersistableUriPermission(tree, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        prefs(context).edit().putString("tree_$packageName", tree.toString()).apply()
        return true
    }

    /** Ses klasöründeki bir dosya. */
    internal data class Candidate(val uri: Uri, val name: String, val modified: Long, val durationMs: Long?)

    /** "🎤 Sesli mesaj (0:12)" → 12 sn; süre yazmıyorsa null. */
    internal fun parseDuration(text: String): Int? {
        val m = Regex("""\((\d{1,2}):(\d{2})\)""").find(text) ?: return null
        return m.groupValues[1].toInt() * 60 + m.groupValues[2].toInt()
    }

    /**
     * Mesaja düşen dosya: zamanı mesajdan en çok 2 dk önce, 30 dk sonra; süre
     * biliniyorsa en çok 1,5 sn farklı. Birden çok dosya aynı ölçüde uyuyorsa
     * (5 sn'den yakın) hiçbiri seçilmez.
     */
    internal fun choose(candidates: List<Candidate>, messageTime: Long, durationSec: Int?): Candidate? {
        val inWindow = candidates.filter { it.modified in (messageTime - 120_000)..(messageTime + 1_800_000) }
        val matching = if (durationSec == null) {
            inWindow
        } else {
            inWindow.filter { it.durationMs != null && abs(it.durationMs / 1000.0 - durationSec) <= 1.5 }
        }
        val sorted = matching.sortedBy { abs(it.modified - messageTime) }
        val best = sorted.firstOrNull() ?: return null
        val next = sorted.getOrNull(1)
        if (next != null && abs(next.modified - messageTime) - abs(best.modified - messageTime) < 5_000) return null
        return best
    }

    /** Hub.io'da. Mesajın ses dosyası (yerel kopya, Telegram ya da WhatsApp klasörü). */
    private fun locate(context: Context, info: MessageStore.VoiceInfo): Pair<Uri?, String?> {
        info.mediaPath?.let { path -> if (File(path).exists()) return Uri.fromFile(File(path)) to null }
        if (info.mediaRef?.startsWith(TelegramClient.REMOTE_SCHEME) == true) {
            val path = TelegramClient.downloadRemote(info.mediaRef) ?: return null to "NOT_FOUND"
            return Uri.fromFile(File(path)) to null
        }
        if (!supportsFolder(info.packageName)) return null to "NOT_FOUND"
        val tree = folder(context, info.packageName) ?: return null to "NEED_FOLDER"
        val file = choose(listCandidates(context, tree, info.time), info.time, parseDuration(info.text))
        return (file?.uri) to (if (file == null) "NOT_FOUND" else null)
    }

    /** Son üç haftalık klasör (ve kök) içindeki opus dosyaları; süre yalnızca zamanı uyanlarda okunur. */
    private fun listCandidates(context: Context, tree: Uri, messageTime: Long): List<Candidate> {
        val rootId = DocumentsContract.getTreeDocumentId(tree)
        val root = children(context, tree, rootId)
        val weekDirs = root.filter { it.isDir && it.name.matches(Regex("""\d{6}""")) }
        // Mesajın haftası (ve komşuları) ile en yeni üç hafta: eski sesli mesajlar da bulunur.
        val codes = weekCodes(messageTime)
        val weeks = (weekDirs.filter { it.name in codes } + weekDirs.sortedByDescending { it.name }.take(3))
            .distinctBy { it.id }
        val day = SimpleDateFormat("yyyyMMdd", Locale.US)
        val days = setOf(-1, 0, 1).map { day.format(messageTime + it * 86_400_000L) }
        val files = (root + weeks.flatMap { children(context, tree, it.id) })
            .filter { !it.isDir && it.name.endsWith(".opus") }
            .filter { file -> days.any { file.name.contains(it) } }
            .filter { it.modified in (messageTime - 120_000)..(messageTime + 1_800_000) }
        return files.map { doc ->
            val uri = DocumentsContract.buildDocumentUriUsingTree(tree, doc.id)
            Candidate(uri, doc.name, doc.modified, duration(context, uri))
        }
    }

    /**
     * WhatsApp'ın haftalık klasör adları ("202647" = yıl + hafta) mesajın
     * gününe göre; hafta numarası yerel ayara göre değişebildiği için ABD ve
     * ISO numaralandırmasıyla, bir hafta önce ve sonrası da.
     */
    internal fun weekCodes(time: Long): Set<String> = buildSet {
        for (locale in listOf(Locale.US, Locale.forLanguageTag("tr-TR"))) {
            for (days in listOf(-7, 0, 7)) {
                val calendar = java.util.GregorianCalendar(locale).apply { timeInMillis = time + days * 86_400_000L }
                add(String.format(Locale.US, "%04d%02d", calendar.weekYear, calendar.get(java.util.Calendar.WEEK_OF_YEAR)))
            }
        }
    }

    private class Doc(val id: String, val name: String, val isDir: Boolean, val modified: Long)

    private fun children(context: Context, tree: Uri, parentId: String): List<Doc> {
        val uri = DocumentsContract.buildChildDocumentsUriUsingTree(tree, parentId)
        val columns = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
            DocumentsContract.Document.COLUMN_LAST_MODIFIED,
        )
        return try {
            context.contentResolver.query(uri, columns, null, null, null)?.use { c ->
                buildList {
                    while (c.moveToNext()) {
                        add(
                            Doc(
                                id = c.getString(0),
                                name = c.getString(1) ?: "",
                                isDir = c.getString(2) == DocumentsContract.Document.MIME_TYPE_DIR,
                                modified = c.getLong(3),
                            ),
                        )
                    }
                }
            }.orEmpty()
        } catch (e: RuntimeException) {
            Log.w(TAG, "Ses klasörü okunamadı: ${e.javaClass.simpleName}")
            emptyList()
        }
    }

    private fun duration(context: Context, uri: Uri): Long? {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(context, uri)
            retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull()
        } catch (e: RuntimeException) {
            null
        } finally {
            runCatching { retriever.release() }
        }
    }

    /**
     * Mesajı yazıya çevirir ve saklar; sonuç ana iş parçacığında döner:
     * "text" ya da "error" (MIC, NEED_FOLDER, NOT_FOUND, NO_SPEECH, LANGUAGE,
     * UNSUPPORTED, BUSY, DECODE, OFFLINE…).
     */
    fun transcribe(context: Context, messageId: String, done: (Map<String, Any?>) -> Unit) {
        val app = context.applicationContext
        val main = Handler(Looper.getMainLooper())
        fun reply(result: Map<String, Any?>) {
            main.post { done(result) }
        }
        fun fail(code: String) = reply(mapOf("error" to code))
        if (!Transcriber.isSupported) return done(mapOf("error" to "UNSUPPORTED"))
        // Android konuşma tanıma için mikrofon iznini istiyor (mikrofon kullanılmaz; ses dosyadan verilir).
        if (ContextCompat.checkSelfPermission(app, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            return done(mapOf("error" to "MIC"))
        }
        Hub.io.execute {
            val store = Hub.store(app)
            val info = store.voiceInfo(messageId) ?: return@execute fail("NOT_FOUND")
            info.transcript?.let { text -> return@execute reply(mapOf("text" to text)) }
            val (uri, error) = try {
                locate(app, info)
            } catch (e: RuntimeException) {
                Log.w(TAG, "Ses bulunamadı: ${e.javaClass.simpleName}")
                null to "NOT_FOUND"
            }
            if (uri == null) return@execute fail(error ?: "NOT_FOUND")
            main.post {
                Transcriber.transcribe(app, uri, Lang.speechLanguage(app)) { result ->
                    val text = result.text
                    if (text == null) {
                        done(mapOf("error" to (result.error ?: "ERROR")))
                    } else {
                        Hub.io.execute {
                            store.setTranscript(messageId, text)
                            Hub.notifyChanged(info.key)
                        }
                        Log.i(TAG, "Sesli mesaj yazıya çevrildi (internetsiz=${result.onDevice})")
                        done(mapOf("text" to text))
                    }
                }
            }
        }
    }
}
