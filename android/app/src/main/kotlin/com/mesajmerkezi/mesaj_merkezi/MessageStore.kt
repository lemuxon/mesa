package com.mesajmerkezi.mesaj_merkezi

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import android.util.Log
import java.security.MessageDigest
import java.util.UUID

/** [MessageStore.ingest] sonucu: kaç mesaj eklendi, bunlardan hangileri gelen mesaj. */
data class IngestResult(
    val added: Int,
    val newIncoming: List<CapturedMessage>,
    /** Yeni eklenen ve kopyalanacak görseli olan mesajlar: kimlik → mesaj. */
    val pendingMedia: List<Pair<String, CapturedMessage>> = emptyList(),
)

/**
 * Yakalanan mesajların ve kuralların yerel deposu. Veri yalnızca bu cihazda tutulur.
 *
 * minSdk 24 olduğu için SQLite UPSERT ("ON CONFLICT DO UPDATE", API 30+)
 * kullanılmaz; yerine INSERT OR IGNORE + UPDATE yapılır.
 */
/** Veritabanı sürümü (yedekler bundan yeni olamaz). */
const val DB_VERSION = 13

class MessageStore(context: Context) : SQLiteOpenHelper(context, "mesajlar.db", null, DB_VERSION) {

    private val appContext: Context = context.applicationContext

    /** Uygulamanın kendi medya kopyaları (bildirimden kopyalananlar). */
    private val mediaDir = java.io.File(context.applicationContext.filesDir, "media")

    override fun onCreate(db: SQLiteDatabase) {
        createV1(db)
        upgradeToV2(db)
        upgradeToV3(db)
        upgradeToV4(db)
        upgradeToV5(db)
        upgradeToV6(db)
        upgradeToV8(db)
        upgradeToV9(db)
        upgradeToV10(db)
        upgradeToV12(db)
        upgradeToV13(db)
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        if (oldVersion < 2) upgradeToV2(db)
        if (oldVersion < 3) upgradeToV3(db)
        if (oldVersion < 4) upgradeToV4(db)
        if (oldVersion < 5) upgradeToV5(db)
        if (oldVersion < 6) upgradeToV6(db)
        if (oldVersion < 7) upgradeToV7(db)
        if (oldVersion < 8) upgradeToV8(db)
        if (oldVersion < 9) upgradeToV9(db)
        if (oldVersion < 10) upgradeToV10(db)
        // Önceden silinmiş mesajlarda kalan medya kopyaları temizlenir.
        if (oldVersion < 11) dropDeletedMedia(db)
        if (oldVersion < 12) upgradeToV12(db)
        if (oldVersion < 13) upgradeToV13(db)
    }

    /** Gönderilmekte olan / gönderilemeyen mesaj (Telegram) ve sebebi. */
    private fun upgradeToV13(db: SQLiteDatabase) {
        db.execSQL("ALTER TABLE messages ADD COLUMN send_state INTEGER NOT NULL DEFAULT 0")
        db.execSQL("ALTER TABLE messages ADD COLUMN send_error TEXT")
    }

    /** Videonun/sesin süresi ve tam boy dosyanın boyutu (Telegram). */
    private fun upgradeToV12(db: SQLiteDatabase) {
        db.execSQL("ALTER TABLE messages ADD COLUMN media_duration INTEGER")
        db.execSQL("ALTER TABLE messages ADD COLUMN media_size INTEGER")
    }

    /**
     * Kişiler: farklı uygulamalardaki sohbetler tek kişide toplanır
     * (kullanıcı onaylar). Reddedilen öneri çiftleri yeniden sorulmaz.
     */
    private fun upgradeToV10(db: SQLiteDatabase) {
        db.execSQL("CREATE TABLE people (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, created INTEGER NOT NULL)")
        db.execSQL("ALTER TABLE conversations ADD COLUMN person_id INTEGER")
        db.execSQL("CREATE TABLE person_dismissed (a TEXT NOT NULL, b TEXT NOT NULL, PRIMARY KEY (a, b))")
    }

    /**
     * Silinen mesajlar (metni korunur), kaydedilenler, sonra hatırlat,
     * "yanıt gerekmez" ve planlı mesajlar.
     */
    private fun upgradeToV9(db: SQLiteDatabase) {
        db.execSQL("ALTER TABLE messages ADD COLUMN deleted INTEGER NOT NULL DEFAULT 0")
        db.execSQL("ALTER TABLE messages ADD COLUMN starred INTEGER NOT NULL DEFAULT 0")
        db.execSQL("ALTER TABLE conversations ADD COLUMN snoozed_until INTEGER NOT NULL DEFAULT 0")
        db.execSQL("ALTER TABLE conversations ADD COLUMN reminded INTEGER NOT NULL DEFAULT 0")
        db.execSQL("ALTER TABLE conversations ADD COLUMN waiting_dismissed INTEGER NOT NULL DEFAULT 0")
        db.execSQL(
            """
            CREATE TABLE scheduled (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              conv_key TEXT NOT NULL,
              text TEXT NOT NULL,
              at INTEGER NOT NULL,
              created INTEGER NOT NULL,
              remote_id INTEGER
            )
            """
        )
    }

    /**
     * Sohbet kısayolu (bildirim gidince de o sohbete gönderebilmek için) ve
     * Telegram'da karşı tarafın okuduğu son mesaj ("görüldü").
     */
    private fun upgradeToV8(db: SQLiteDatabase) {
        db.execSQL("ALTER TABLE conversations ADD COLUMN shortcut_id TEXT")
        db.execSQL("ALTER TABLE conversations ADD COLUMN read_outbox INTEGER NOT NULL DEFAULT 0")
    }

    private fun createV1(db: SQLiteDatabase) {
        db.execSQL(
            """
            CREATE TABLE conversations (
              key TEXT PRIMARY KEY,
              package TEXT NOT NULL,
              title TEXT NOT NULL,
              is_group INTEGER NOT NULL DEFAULT 0,
              last_text TEXT NOT NULL DEFAULT '',
              last_time INTEGER NOT NULL DEFAULT 0,
              unread INTEGER NOT NULL DEFAULT 0
            )
            """
        )
        db.execSQL(
            """
            CREATE TABLE messages (
              id TEXT PRIMARY KEY,
              conv_key TEXT NOT NULL,
              sender TEXT,
              text TEXT NOT NULL,
              time INTEGER NOT NULL,
              outgoing INTEGER NOT NULL DEFAULT 0
            )
            """
        )
        db.execSQL("CREATE INDEX messages_conv_time ON messages(conv_key, time)")
    }

    /** Otomatik kurallar. */
    private fun upgradeToV2(db: SQLiteDatabase) {
        db.execSQL("ALTER TABLE conversations ADD COLUMN important INTEGER NOT NULL DEFAULT 0")
        db.execSQL("ALTER TABLE messages ADD COLUMN auto INTEGER NOT NULL DEFAULT 0")
        db.execSQL(
            """
            CREATE TABLE rules (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              enabled INTEGER NOT NULL,
              packages TEXT NOT NULL,
              keywords TEXT NOT NULL,
              sender_contains TEXT NOT NULL,
              include_groups INTEGER NOT NULL,
              action TEXT NOT NULL,
              reply_text TEXT NOT NULL,
              cooldown_minutes INTEGER NOT NULL
            )
            """
        )
        db.execSQL(
            """
            CREATE TABLE rule_fires (
              rule_id INTEGER NOT NULL,
              conv_key TEXT NOT NULL,
              action TEXT NOT NULL,
              time INTEGER NOT NULL
            )
            """
        )
        db.execSQL("CREATE INDEX rule_fires_rule_conv ON rule_fires(rule_id, conv_key, time)")
    }

    /**
     * Görünmez yön işaretleri yüzünden bölünmüş sohbetleri birleştirir ve
     * iki kez kaydedilmiş mesajları teke indirir (bkz. [Names]).
     */
    private fun upgradeToV3(db: SQLiteDatabase) {
        val senders = db.rawQuery(
            "SELECT DISTINCT sender FROM messages WHERE sender IS NOT NULL",
            null,
        ).use { c -> buildList { while (c.moveToNext()) add(c.getString(0)) } }
        for (raw in senders) {
            val clean = Names.normalize(raw)
            if (clean != raw) {
                db.execSQL("UPDATE messages SET sender = ? WHERE sender = ?", arrayOf(clean, raw))
            }
        }

        val conversations = db.rawQuery("SELECT key, package, title FROM conversations", null)
            .use { c -> buildList { while (c.moveToNext()) add(Triple(c.getString(0), c.getString(1), c.getString(2))) } }
        for ((oldKey, packageName, rawTitle) in conversations) {
            val title = Names.title(rawTitle) ?: continue
            val key = "$packageName|$title"
            if (key == oldKey) continue
            db.execSQL("UPDATE messages SET conv_key = ? WHERE conv_key = ?", arrayOf(key, oldKey))
            db.execSQL("UPDATE rule_fires SET conv_key = ? WHERE conv_key = ?", arrayOf(key, oldKey))
            val targetExists = db.rawQuery("SELECT 1 FROM conversations WHERE key = ?", arrayOf(key))
                .use { it.moveToFirst() }
            if (targetExists) {
                // İki kopya aynı mesajları saydığı için okunmamışlar toplanmaz, büyüğü alınır.
                db.execSQL(
                    "UPDATE conversations SET " +
                        "unread = MAX(unread, (SELECT unread FROM conversations WHERE key = ?)), " +
                        "important = MAX(important, (SELECT important FROM conversations WHERE key = ?)) " +
                        "WHERE key = ?",
                    arrayOf(oldKey, oldKey, key),
                )
                db.execSQL("DELETE FROM conversations WHERE key = ?", arrayOf(oldKey))
            } else {
                db.execSQL("UPDATE conversations SET key = ?, title = ? WHERE key = ?", arrayOf(key, title, oldKey))
            }
        }

        db.execSQL(
            "DELETE FROM messages WHERE rowid IN (" +
                "SELECT m.rowid FROM messages m JOIN messages o ON o.conv_key = m.conv_key " +
                "AND o.time = m.time AND o.text = m.text AND o.rowid < m.rowid)"
        )
        db.execSQL(
            "UPDATE conversations SET " +
                "last_text = COALESCE((SELECT text FROM messages WHERE conv_key = conversations.key " +
                "ORDER BY time DESC LIMIT 1), last_text), " +
                "last_time = COALESCE((SELECT MAX(time) FROM messages WHERE conv_key = conversations.key), last_time)"
        )
    }

    /** Görseller (çıkartma, GIF, fotoğraf): uygulamanın kendi klasörüne kopyalanan dosya. */
    private fun upgradeToV4(db: SQLiteDatabase) {
        db.execSQL("ALTER TABLE messages ADD COLUMN media_path TEXT")
        db.execSQL("ALTER TABLE messages ADD COLUMN media_mime TEXT")
    }

    /**
     * Sabitleme, arşiv, arama ve kural saat aralığı. `search_text`, metnin
     * [RuleEngine.fold] hali: SQLite LIKE yalnızca ASCII harflerde büyük/küçük
     * duyarsız; "İSTANBUL" araması "istanbul"u bulsun diye önceden katlanır.
     */
    /**
     * Profil fotoğrafı ve tam boy medya. `media_kind`: photo, video, animation,
     * sticker. `media_ref`: tam boy dosyanın kaynağı (ör. "tdlib-remote:<id>");
     * bildirimden gelen medyada yok, yalnızca önizleme kopyalanabiliyor.
     */
    private fun upgradeToV6(db: SQLiteDatabase) {
        db.execSQL("ALTER TABLE conversations ADD COLUMN avatar_path TEXT")
        db.execSQL("ALTER TABLE messages ADD COLUMN media_kind TEXT")
        db.execSQL("ALTER TABLE messages ADD COLUMN media_ref TEXT")
    }

    /**
     * 2026-10-11: mesaj olmayan bildirimler (beğeni, takip, uygulamanın kendi
     * duyuruları) eskiden sohbet olarak kaydediliyordu; artık MessageFilter
     * ayıklıyor. Başlığı uygulamanın kendi adı olan ("Instagram", "X") kişi
     * sohbetleri bunlardır ve silinir. Telegram (TDLib) sohbetleri ve web
     * servisleri gerçek sohbet olduğu için dokunulmaz.
     */
    private fun upgradeToV7(db: SQLiteDatabase) {
        val junk = db.rawQuery("SELECT key, package, title FROM conversations WHERE is_group = 0", null).use { c ->
            buildList {
                while (c.moveToNext()) {
                    val key = c.getString(0)
                    val pkg = c.getString(1)
                    if (key.startsWith(TelegramClient.KEY_PREFIX) || WebServices.isWebPackage(pkg)) continue
                    if (pkg !in SupportedApps.packages) continue
                    if (c.getString(2).orEmpty().trim().equals(SupportedApps.name(pkg), ignoreCase = true)) add(key)
                }
            }
        }
        for (key in junk) {
            db.rawQuery("SELECT media_path FROM messages WHERE conv_key = ? AND media_path IS NOT NULL", arrayOf(key))
                .use { c -> while (c.moveToNext()) java.io.File(c.getString(0)).delete() }
            db.delete("messages", "conv_key = ?", arrayOf(key))
            db.delete("conversations", "key = ?", arrayOf(key))
            db.delete("rule_fires", "conv_key = ?", arrayOf(key))
        }
    }

    private fun upgradeToV5(db: SQLiteDatabase) {
        db.execSQL("ALTER TABLE conversations ADD COLUMN pinned INTEGER NOT NULL DEFAULT 0")
        db.execSQL("ALTER TABLE conversations ADD COLUMN archived INTEGER NOT NULL DEFAULT 0")
        db.execSQL("ALTER TABLE messages ADD COLUMN search_text TEXT")
        db.execSQL("ALTER TABLE rules ADD COLUMN active_from INTEGER")
        db.execSQL("ALTER TABLE rules ADD COLUMN active_to INTEGER")
        db.execSQL("ALTER TABLE rules ADD COLUMN active_days INTEGER NOT NULL DEFAULT ${Rule.ALL_DAYS}")
        // İmleç açıkken aynı tabloyu güncellememek için önce topla.
        val rows = db.rawQuery("SELECT id, text FROM messages", null)
            .use { c -> buildList { while (c.moveToNext()) add(c.getString(0) to c.getString(1)) } }
        for ((id, text) in rows) {
            db.execSQL("UPDATE messages SET search_text = ? WHERE id = ?", arrayOf(RuleEngine.fold(text), id))
        }
    }

    // ---- Mesajlar ----

    /**
     * Uygulamalar her yeni mesajda bildirimi geçmişiyle birlikte yeniden
     * yayınlar; daha önce görülen mesajlar atlanır.
     */
    fun ingest(conv: CapturedConversation): IngestResult {
        val db = writableDatabase
        var added = 0
        val newIncoming = mutableListOf<CapturedMessage>()
        val pendingMedia = mutableListOf<Pair<String, CapturedMessage>>()
        db.beginTransaction()
        try {
            for (m in conv.messages) {
                // Kalıcı kimliği olan mesajda içerik karşılaştırması yapılmaz:
                // aynı saniyede iki "tamam" gerçekten iki mesajdır.
                if (!m.outgoing && m.id == null && DeletedMessages.isDeletedLabel(m.text)) {
                    markDeletedLike(db, conv.key, m)
                    continue
                }
                if (m.id == null && isEcho(db, conv.key, m)) continue
                val id = m.id ?: messageId(conv.key, m)
                val row = ContentValues().apply {
                    put("id", id)
                    put("conv_key", conv.key)
                    put("sender", m.sender)
                    put("text", m.text)
                    put("time", m.time)
                    put("outgoing", if (m.outgoing) 1 else 0)
                    put("auto", if (m.auto) 1 else 0)
                    put("media_mime", m.mediaMime)
                    put("search_text", RuleEngine.fold(m.text))
                    put("media_kind", m.mediaKind)
                    put("media_ref", m.mediaRef)
                    put("media_duration", m.mediaDuration)
                    put("media_size", m.mediaSize)
                    put("send_state", m.sendState)
                    put("send_error", m.sendError)
                }
                val inserted = db.insertWithOnConflict("messages", null, row, SQLiteDatabase.CONFLICT_IGNORE) != -1L
                if (!inserted && m.id != null) {
                    // Aynı kimlikli mesajın gönderim durumu değişmiş olabilir (Telegram).
                    db.execSQL(
                        "UPDATE messages SET send_state = ?, send_error = ? WHERE id = ? AND send_state != ?",
                        arrayOf<Any?>(m.sendState, m.sendError, id, m.sendState),
                    )
                }
                if (!inserted && (m.mediaDuration != null || m.mediaSize != null)) {
                    // Süre/boyut bilgisinden önce kaydedilmiş mesaj: geçmiş yeniden gelince tamamlanır.
                    db.execSQL(
                        "UPDATE messages SET media_duration = COALESCE(media_duration, ?), " +
                            "media_size = COALESCE(media_size, ?) WHERE id = ? AND deleted = 0",
                        arrayOf<Any?>(m.mediaDuration, m.mediaSize, id),
                    )
                }
                if (inserted) {
                    added++
                    if (!m.outgoing) newIncoming += m
                    if (m.mediaUri != null) pendingMedia += id to m
                } else if (m.mediaUri != null && !hasMedia(db, id)) {
                    // Daha önce görselsiz kaydedilmiş (ör. görsel desteğinden önce);
                    // bildirim görseli hâlâ taşıyorsa şimdi bağlanır.
                    pendingMedia += id to m
                }
            }
            if (added > 0) {
                val conversation = ContentValues().apply {
                    put("key", conv.key)
                    put("package", conv.packageName)
                    put("title", conv.title)
                    put("is_group", if (conv.isGroup) 1 else 0)
                }
                db.insertWithOnConflict("conversations", null, conversation, SQLiteDatabase.CONFLICT_IGNORE)
                // Telegram sohbetlerinin anahtarı kimliktir; ad değişebilir.
                db.execSQL("UPDATE conversations SET title = ? WHERE key = ?", arrayOf(conv.title, conv.key))
                refreshConversation(db, conv.key, newIncoming.size)
            }
            if (conv.shortcutId != null) {
                db.execSQL(
                    "UPDATE conversations SET shortcut_id = ? WHERE key = ?",
                    arrayOf(conv.shortcutId, conv.key),
                )
            }
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
        return IngestResult(added, newIncoming, pendingMedia)
    }

    /**
     * Aynı metin başka bir sohbete yakın zamanda gelen mesaj olarak yazıldı mı.
     * Web servisi ile telefondaki uygulaması aynı mesajı iki kez getirmesin diye.
     */
    fun hasRecentIncoming(text: String, since: Long, exceptKey: String): Boolean =
        readableDatabase.rawQuery(
            "SELECT 1 FROM messages WHERE outgoing = 0 AND time >= ? AND conv_key != ? AND text = ? LIMIT 1",
            arrayOf(since.toString(), exceptKey, text),
        ).use { it.moveToFirst() }

    /** Mesajın görsel dosyasını bağlar (kopyalama/indirme kayıttan sonra yapılır). */
    fun setAvatar(key: String, path: String) {
        writableDatabase.execSQL("UPDATE conversations SET avatar_path = ? WHERE key = ?", arrayOf(path, key))
    }

    fun avatarPath(key: String): String? =
        readableDatabase.rawQuery("SELECT avatar_path FROM conversations WHERE key = ?", arrayOf(key))
            .use { c -> if (c.moveToFirst() && !c.isNull(0)) c.getString(0) else null }

    /** Tam boy medyanın kaynağı ve türü (indirme için). */
    fun mediaSource(messageId: String): Pair<String, String?>? =
        readableDatabase.rawQuery("SELECT media_ref, media_kind FROM messages WHERE id = ?", arrayOf(messageId))
            .use { c -> if (c.moveToFirst() && !c.isNull(0)) c.getString(0) to c.getString(1) else null }

    fun messageCount(): Int =
        readableDatabase.rawQuery("SELECT COUNT(*) FROM messages", null).use { c -> if (c.moveToFirst()) c.getInt(0) else 0 }

    /** Sohbetin bilgisi (bildirim oluşturmak için); yoksa null. */
    fun conversation(key: String): Map<String, Any?>? =
        readableDatabase.rawQuery(
            "SELECT package, title, is_group, unread, avatar_path, shortcut_id FROM conversations WHERE key = ?",
            arrayOf(key),
        ).use { c ->
            if (!c.moveToFirst()) return null
            mapOf(
                "package" to c.getString(0),
                "title" to c.getString(1),
                "isGroup" to (c.getInt(2) == 1),
                "unread" to c.getInt(3),
                "avatarPath" to c.getString(4),
                "shortcutId" to c.getString(5),
            )
        }

    /** Telegram: karşı taraf bu kimliğe kadarki mesajlarımızı okudu. */
    fun setReadOutbox(key: String, messageId: Long) {
        writableDatabase.execSQL(
            "UPDATE conversations SET read_outbox = MAX(read_outbox, ?) WHERE key = ?",
            arrayOf<Any>(messageId, key),
        )
    }

    /** Sohbetteki son gelen mesajın kimliği (Telegram'a "okundu" bildirmek için). */
    fun lastIncomingId(key: String): String? =
        readableDatabase.rawQuery(
            "SELECT id FROM messages WHERE conv_key = ? AND outgoing = 0 ORDER BY time DESC LIMIT 1",
            arrayOf(key),
        ).use { c -> if (c.moveToFirst()) c.getString(0) else null }

    fun setMedia(messageId: String, path: String, mime: String?) {
        val db = writableDatabase
        // Kopyalama sürerken gönderen sildiyse medya saklanmaz.
        val deleted = db.rawQuery("SELECT deleted FROM messages WHERE id = ?", arrayOf(messageId))
            .use { c -> c.moveToFirst() && c.getInt(0) == 1 }
        if (deleted) {
            val file = java.io.File(path)
            if (file.canonicalPath.startsWith(mediaDir.canonicalPath + java.io.File.separator)) file.delete()
            return
        }
        db.execSQL(
            "UPDATE messages SET media_path = ?, media_mime = COALESCE(?, media_mime) WHERE id = ?",
            arrayOf(path, mime, messageId),
        )
    }

    /** Sohbeti, mesajlarını ve görsel dosyalarını yalnızca bu uygulamadan siler. */
    fun deleteConversation(key: String) {
        val db = writableDatabase
        val files = db.rawQuery(
            "SELECT media_path FROM messages WHERE conv_key = ? AND media_path IS NOT NULL",
            arrayOf(key),
        ).use { c -> buildList { while (c.moveToNext()) add(c.getString(0)) } }
        db.beginTransaction()
        try {
            db.delete("messages", "conv_key = ?", arrayOf(key))
            db.delete("conversations", "key = ?", arrayOf(key))
            db.delete("rule_fires", "conv_key = ?", arrayOf(key))
            cleanupPeople(db)
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
        files.forEach { java.io.File(it).delete() }
    }

    fun renameConversation(key: String, title: String) {
        writableDatabase.execSQL("UPDATE conversations SET title = ? WHERE key = ?", arrayOf(title, key))
    }

    /**
     * Tek mesajı siler (Telegram: geçici kimlikli "gönderiliyor" satırı kesin
     * mesajla değişince, ya da gönderilemeyen mesaj silinince).
     */
    fun deleteMessage(id: String) {
        val db = writableDatabase
        db.beginTransaction()
        try {
            val (key, path) = db.rawQuery("SELECT conv_key, media_path FROM messages WHERE id = ?", arrayOf(id))
                .use { c -> if (c.moveToFirst()) c.getString(0) to c.getString(1) else return }
            db.delete("messages", "id = ?", arrayOf(id))
            refreshConversation(db, key, 0)
            db.setTransactionSuccessful()
            // Yalnızca uygulamanın kendi kopyası silinir (Telegram önbelleğine dokunulmaz).
            if (path != null) {
                val file = java.io.File(path)
                if (file.canonicalPath.startsWith(mediaDir.canonicalPath + java.io.File.separator)) file.delete()
            }
        } finally {
            db.endTransaction()
        }
    }

    /** Bu uygulamadan (elle ya da kuralla) gönderilen yanıtı kaydeder. */
    /** Gönderilen yanıtın yerel kaydı; kimliğini döner. */
    fun recordOutgoing(key: String, text: String, auto: Boolean = false): String {
        val id = "out-${UUID.randomUUID()}"
        val db = writableDatabase
        db.beginTransaction()
        try {
            val row = ContentValues().apply {
                put("id", id)
                put("conv_key", key)
                put("text", text)
                put("time", System.currentTimeMillis())
                put("outgoing", 1)
                put("auto", if (auto) 1 else 0)
                put("search_text", RuleEngine.fold(text))
            }
            db.insert("messages", null, row)
            refreshConversation(db, key, 0)
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
        return id
    }

    /** Kullanıcı sohbeti açtı: okunmamış sayısı ve "önemli" işareti silinir. */
    fun markRead(key: String) {
        writableDatabase.execSQL(
            "UPDATE conversations SET unread = 0, important = 0, reminded = 0 WHERE key = ?",
            arrayOf(key),
        )
    }

    // ---- Silinen ve kaydedilen mesajlar ----

    /** Etiketin yerini aldığı mesaj: aynı gönderen, aynı zaman damgası (±2 sn). */
    private fun markDeletedLike(db: SQLiteDatabase, key: String, label: CapturedMessage) {
        db.execSQL(
            "UPDATE messages SET deleted = 1 WHERE conv_key = ? AND outgoing = 0 AND deleted = 0 " +
                "AND COALESCE(sender, '') = ? AND ABS(time - ?) < 2000",
            arrayOf<Any>(key, label.sender.orEmpty(), label.time),
        )
        dropDeletedMedia(db)
    }

    /** Telegram: gönderen kalıcı olarak sildi. */
    fun markDeleted(ids: List<String>) {
        if (ids.isEmpty()) return
        val marks = ids.joinToString(",") { "?" }
        val db = writableDatabase
        db.execSQL("UPDATE messages SET deleted = 1 WHERE id IN ($marks)", ids.toTypedArray())
        dropDeletedMedia(db)
    }

    /**
     * Gönderen sildiyse "silindi" etiketi ve metin kalır ama fotoğraf/video
     * saklanmaz: uygulamanın kopyası silinir, kaydı temizlenir (Telegram'ın
     * kendi önbelleğindeki dosyaya dokunulmaz, yalnızca bağlantısı kalkar).
     */
    private fun dropDeletedMedia(db: SQLiteDatabase) {
        val files = db.rawQuery(
            "SELECT media_path FROM messages WHERE deleted = 1 AND media_path IS NOT NULL",
            null,
        ).use { c -> buildList { while (c.moveToNext()) add(c.getString(0)) } }
        db.execSQL(
            "UPDATE messages SET media_path = NULL, media_mime = NULL, media_kind = NULL, media_ref = NULL " +
                "WHERE deleted = 1 AND (media_path IS NOT NULL OR media_ref IS NOT NULL OR media_kind IS NOT NULL)"
        )
        val own = mediaDir.canonicalPath + java.io.File.separator
        var removed = 0
        for (path in files) {
            val file = java.io.File(path)
            if (file.canonicalPath.startsWith(own) && file.delete()) removed++
        }
        if (files.isNotEmpty()) Log.i(TAG, "Silinen mesajın medyası kaldırıldı: ${files.size} (${removed} dosya)")
    }

    /**
     * Sohbetlerde paylaşılan fotoğraf ve videolar (kişi galerisi), yeniden
     * eskiye. Silinmiş mesajlar ve çıkartmalar girmez.
     */
    fun media(keys: List<String>, limit: Int = MEDIA_LIMIT): List<Map<String, Any?>> {
        if (keys.isEmpty()) return emptyList()
        val marks = keys.joinToString(",") { "?" }
        return readableDatabase.rawQuery(
            "SELECT id, sender, text, time, outgoing, media_path, media_mime, media_kind, media_ref, starred, conv_key, " +
                "media_duration, media_size " +
                "FROM messages WHERE conv_key IN ($marks) AND deleted = 0 AND media_path IS NOT NULL " +
                "AND COALESCE(media_kind, '') != 'sticker' ORDER BY time DESC LIMIT $limit",
            keys.toTypedArray(),
        ).use { c ->
            buildList {
                while (c.moveToNext()) {
                    add(
                        mapOf(
                            "id" to c.getString(0),
                            "sender" to c.getString(1),
                            "text" to c.getString(2),
                            "time" to c.getLong(3),
                            "outgoing" to (c.getInt(4) == 1),
                            "mediaPath" to c.getString(5),
                            "mediaMime" to c.getString(6),
                            "mediaKind" to c.getString(7),
                            "downloadable" to !c.isNull(8),
                            "starred" to (c.getInt(9) == 1),
                            "key" to c.getString(10),
                            "mediaDuration" to (if (c.isNull(11)) null else c.getInt(11)),
                            "mediaSize" to (if (c.isNull(12)) null else c.getLong(12)),
                        )
                    )
                }
            }
        }
    }

    fun setStarred(id: String, starred: Boolean) {
        writableDatabase.execSQL(
            "UPDATE messages SET starred = ? WHERE id = ?",
            arrayOf<Any>(if (starred) 1 else 0, id),
        )
    }

    /** Tüm uygulamalardan kaydedilen mesajlar, yeniden eskiye. */
    fun starred(): List<Map<String, Any?>> =
        readableDatabase.rawQuery(
            "SELECT m.id, m.sender, m.text, m.time, m.outgoing, m.conv_key, c.title, c.package, m.media_path " +
                "FROM messages m JOIN conversations c ON c.key = m.conv_key " +
                "WHERE m.starred = 1 ORDER BY m.time DESC LIMIT 300",
            null,
        ).use { c ->
            buildList {
                while (c.moveToNext()) {
                    add(
                        mapOf(
                            "id" to c.getString(0),
                            "sender" to c.getString(1),
                            "text" to c.getString(2),
                            "time" to c.getLong(3),
                            "outgoing" to (c.getInt(4) == 1),
                            "key" to c.getString(5),
                            "title" to c.getString(6),
                            "package" to c.getString(7),
                            "mediaPath" to c.getString(8),
                        )
                    )
                }
            }
        }

    // ---- Yanıt bekleyenler ve sonra hatırlat ----

    /**
     * Size yazıp yanıt bekleyen kişiler: grup değil, son mesaj gelen mesaj,
     * son 2 gün içinde ve "yanıt gerekmez" denmemiş. En uzun bekleyen önce.
     */
    fun waiting(now: Long): List<Map<String, Any?>> =
        readableDatabase.rawQuery(
            "SELECT c.key, c.title, c.package, c.avatar_path, c.last_time, c.last_text FROM conversations c " +
                "WHERE c.is_group = 0 AND c.archived = 0 AND c.snoozed_until <= ? AND c.last_time > ? " +
                "AND c.last_time > c.waiting_dismissed " +
                "AND (SELECT outgoing FROM messages m WHERE m.conv_key = c.key ORDER BY time DESC LIMIT 1) = 0 " +
                "ORDER BY c.last_time ASC LIMIT 15",
            arrayOf(now.toString(), (now - WAITING_WINDOW_MS).toString()),
        ).use { c ->
            buildList {
                while (c.moveToNext()) {
                    add(
                        mapOf(
                            "key" to c.getString(0),
                            "title" to c.getString(1),
                            "package" to c.getString(2),
                            "avatarPath" to c.getString(3),
                            "lastTime" to c.getLong(4),
                            "lastText" to c.getString(5),
                        )
                    )
                }
            }
        }

    /** "Yanıt gerekmez": yeni mesaj gelene kadar listede görünmez. */
    fun dismissWaiting(key: String) {
        writableDatabase.execSQL(
            "UPDATE conversations SET waiting_dismissed = last_time WHERE key = ?",
            arrayOf(key),
        )
    }

    /** Sohbet [until] anına kadar gelen kutusundan kalkar; o an hatırlatılır. */
    fun snooze(key: String, until: Long) {
        writableDatabase.execSQL(
            "UPDATE conversations SET snoozed_until = ?, reminded = 0 WHERE key = ?",
            arrayOf<Any>(until, key),
        )
    }

    /** Hatırlatma zamanı geldi (ya da kullanıcı erken getirdi): en üste ⏰ ile döner. */
    fun unsnooze(key: String, remind: Boolean) {
        writableDatabase.execSQL(
            "UPDATE conversations SET snoozed_until = 0, reminded = ? WHERE key = ?",
            arrayOf<Any>(if (remind) 1 else 0, key),
        )
    }

    fun snoozed(): List<Map<String, Any?>> =
        readableDatabase.rawQuery(
            "SELECT key, title, package, snoozed_until FROM conversations WHERE snoozed_until > 0 " +
                "ORDER BY snoozed_until ASC",
            null,
        ).use { c ->
            buildList {
                while (c.moveToNext()) {
                    add(
                        mapOf(
                            "key" to c.getString(0),
                            "title" to c.getString(1),
                            "package" to c.getString(2),
                            "until" to c.getLong(3),
                        )
                    )
                }
            }
        }

    // ---- Planlı mesajlar ----

    fun addScheduled(key: String, text: String, at: Long): Long =
        writableDatabase.insert(
            "scheduled",
            null,
            ContentValues().apply {
                put("conv_key", key)
                put("text", text)
                put("at", at)
                put("created", System.currentTimeMillis())
            },
        )

    fun scheduled(key: String? = null): List<Map<String, Any?>> =
        readableDatabase.rawQuery(
            "SELECT s.id, s.conv_key, s.text, s.at, c.title, c.package, s.remote_id FROM scheduled s " +
                "LEFT JOIN conversations c ON c.key = s.conv_key " +
                (if (key != null) "WHERE s.conv_key = ? " else "") + "ORDER BY s.at ASC",
            if (key != null) arrayOf(key) else null,
        ).use { c ->
            buildList {
                while (c.moveToNext()) {
                    add(
                        mapOf(
                            "id" to c.getLong(0),
                            "key" to c.getString(1),
                            "text" to c.getString(2),
                            "at" to c.getLong(3),
                            "title" to c.getString(4),
                            "package" to c.getString(5),
                            "remoteId" to if (c.isNull(6)) null else c.getLong(6),
                        )
                    )
                }
            }
        }

    fun scheduledById(id: Long): Map<String, Any?>? = scheduled().firstOrNull { it["id"] == id }

    /** Telegram sunucusunda bekleyen planlı mesajın kimliği (iptal için). */
    fun setScheduledRemote(id: Long, remoteId: Long) {
        writableDatabase.execSQL("UPDATE scheduled SET remote_id = ? WHERE id = ?", arrayOf<Any>(remoteId, id))
    }

    fun deleteScheduled(id: Long) {
        writableDatabase.delete("scheduled", "id = ?", arrayOf(id.toString()))
    }

    // ---- Haftalık özet ----

    /** Son [days] günün özeti: günlere göre sayılar, uygulamalar, en çok yazışılanlar, yoğun saat. */
    fun stats(now: Long, days: Int): Map<String, Any?> {
        val since = now - days * 24 * 60 * 60 * 1000L
        val db = readableDatabase
        val args = arrayOf(since.toString())
        val perDay = db.rawQuery(
            "SELECT strftime('%Y-%m-%d', time / 1000, 'unixepoch', 'localtime') d, COUNT(*) FROM messages " +
                "WHERE time >= ? GROUP BY d ORDER BY d",
            args,
        ).use { c -> buildList { while (c.moveToNext()) add(mapOf("day" to c.getString(0), "count" to c.getInt(1))) } }
        val perApp = db.rawQuery(
            "SELECT c.package, COUNT(*) n FROM messages m JOIN conversations c ON c.key = m.conv_key " +
                "WHERE m.time >= ? GROUP BY c.package ORDER BY n DESC",
            args,
        ).use { c -> buildList { while (c.moveToNext()) add(mapOf("package" to c.getString(0), "count" to c.getInt(1))) } }
        val top = db.rawQuery(
            "SELECT c.key, c.title, c.package, c.avatar_path, c.is_group, COUNT(*) n FROM messages m " +
                "JOIN conversations c ON c.key = m.conv_key WHERE m.time >= ? " +
                "GROUP BY c.key ORDER BY n DESC LIMIT 5",
            args,
        ).use { c ->
            buildList {
                while (c.moveToNext()) {
                    add(
                        mapOf(
                            "key" to c.getString(0),
                            "title" to c.getString(1),
                            "package" to c.getString(2),
                            "avatarPath" to c.getString(3),
                            "isGroup" to (c.getInt(4) == 1),
                            "count" to c.getInt(5),
                        )
                    )
                }
            }
        }
        val busiestHour = db.rawQuery(
            "SELECT CAST(strftime('%H', time / 1000, 'unixepoch', 'localtime') AS INTEGER) h, COUNT(*) n " +
                "FROM messages WHERE time >= ? GROUP BY h ORDER BY n DESC LIMIT 1",
            args,
        ).use { c -> if (c.moveToFirst()) c.getInt(0) else null }
        val (incoming, outgoing) = db.rawQuery(
            "SELECT SUM(outgoing = 0), SUM(outgoing = 1) FROM messages WHERE time >= ?",
            args,
        ).use { c -> if (c.moveToFirst()) c.getInt(0) to c.getInt(1) else 0 to 0 }
        val people = db.rawQuery(
            "SELECT COUNT(DISTINCT m.conv_key) FROM messages m JOIN conversations c ON c.key = m.conv_key " +
                "WHERE m.time >= ? AND c.is_group = 0",
            args,
        ).use { c -> if (c.moveToFirst()) c.getInt(0) else 0 }
        val deleted = db.rawQuery(
            "SELECT COUNT(*) FROM messages WHERE time >= ? AND deleted = 1",
            args,
        ).use { c -> if (c.moveToFirst()) c.getInt(0) else 0 }
        return mapOf(
            "perDay" to perDay,
            "perApp" to perApp,
            "top" to top,
            "busiestHour" to busiestHour,
            "incoming" to incoming,
            "outgoing" to outgoing,
            "people" to people,
            "deleted" to deleted,
        )
    }

    /** Sessize alma kuralı: okunmamış sayılmaz, "önemli" işaretine dokunulmaz. */
    fun clearUnread(key: String) {
        writableDatabase.execSQL("UPDATE conversations SET unread = 0 WHERE key = ?", arrayOf(key))
    }

    fun setImportant(key: String) {
        writableDatabase.execSQL("UPDATE conversations SET important = 1 WHERE key = ?", arrayOf(key))
    }

    fun setPinned(key: String, pinned: Boolean) {
        writableDatabase.execSQL(
            "UPDATE conversations SET pinned = ? WHERE key = ?",
            arrayOf<Any?>(if (pinned) 1 else 0, key),
        )
    }

    /** Arşivlenen sohbet gelen kutusundan kalkar; yeni mesaj gelse de arşivde kalır. */
    fun setArchived(key: String, archived: Boolean) {
        writableDatabase.execSQL(
            "UPDATE conversations SET archived = ? WHERE key = ?",
            arrayOf<Any?>(if (archived) 1 else 0, key),
        )
    }

    /** Gelen kutusundaki (arşiv dışı) tüm sohbetlerin okunmamış sayısı ve önem işareti sıfırlanır. */
    fun markAllRead() {
        writableDatabase.execSQL("UPDATE conversations SET unread = 0, important = 0 WHERE archived = 0")
    }

    /** Uygulama başına okunmamış mesaj sayısı (Servisler'deki uygulama rozetleri). */
    fun unreadByPackage(): Map<String, Int> =
        readableDatabase.rawQuery(
            "SELECT package, SUM(unread) FROM conversations WHERE archived = 0 GROUP BY package",
            null,
        ).use { c -> buildMap { while (c.moveToNext()) put(c.getString(0), c.getInt(1)) } }

    fun archivedCount(): Int =
        readableDatabase.rawQuery("SELECT COUNT(*) FROM conversations WHERE archived = 1", null)
            .use { c -> if (c.moveToFirst()) c.getInt(0) else 0 }

    /**
     * Tüm mesajlarda arama (en yeniden eskiye, en fazla [SEARCH_LIMIT]).
     * Büyük/küçük harf ve I/ı/İ/i farkı gözetilmez.
     */
    fun search(query: String): List<Map<String, Any?>> {
        val folded = RuleEngine.fold(query.trim())
        if (folded.isEmpty()) return emptyList()
        // LIKE'ın joker karakterleri aranan metinde düz karakter sayılsın.
        val pattern = "%" + folded.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_") + "%"
        return readableDatabase.rawQuery(
            "SELECT m.conv_key, m.text, m.time, m.sender, m.outgoing, c.title, c.package " +
                "FROM messages m JOIN conversations c ON c.key = m.conv_key " +
                "WHERE m.search_text LIKE ? ESCAPE '\\' ORDER BY m.time DESC LIMIT $SEARCH_LIMIT",
            arrayOf(pattern),
        ).use { c ->
            buildList {
                while (c.moveToNext()) {
                    add(
                        mapOf(
                            "key" to c.getString(0),
                            "text" to c.getString(1),
                            "time" to c.getLong(2),
                            "sender" to c.getString(3),
                            "outgoing" to (c.getInt(4) == 1),
                            "title" to c.getString(5),
                            "package" to c.getString(6),
                        )
                    )
                }
            }
        }
    }

    /**
     * Saklama süresi: [cutoff]'tan eski mesajları ve görsellerini siler, boş
     * kalan sohbetleri kaldırır. Silinen mesaj sayısını döner.
     */
    /**
     * Önbellek temizliğinden ya da geri yüklemeden sonra: dosyası artık olmayan
     * medya ve fotoğraf bağlantıları kaldırılır (Telegram'dakiler gerekince
     * yeniden iner; balonda kırık resim görünmez). Düzeltilen satır sayısı.
     */
    fun clearMissingFiles(): Int {
        val db = writableDatabase
        fun missing(sql: String): List<Pair<String, String>> = db.rawQuery(sql, null).use { c ->
            buildList {
                while (c.moveToNext()) {
                    val path = c.getString(1)
                    if (!java.io.File(path).exists()) add(c.getString(0) to path)
                }
            }
        }
        val media = missing("SELECT id, media_path FROM messages WHERE media_path IS NOT NULL")
        val avatars = missing("SELECT key, avatar_path FROM conversations WHERE avatar_path IS NOT NULL")
        db.beginTransaction()
        try {
            for ((id, _) in media) db.execSQL("UPDATE messages SET media_path = NULL WHERE id = ?", arrayOf(id))
            for ((key, _) in avatars) db.execSQL("UPDATE conversations SET avatar_path = NULL WHERE key = ?", arrayOf(key))
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
        if (media.isNotEmpty() || avatars.isNotEmpty()) {
            Log.i(TAG, "Kayıp dosya bağlantısı temizlendi: ${media.size} medya, ${avatars.size} fotoğraf")
        }
        return media.size + avatars.size
    }

    fun purgeOlderThan(cutoff: Long): Int {
        val db = writableDatabase
        val files = db.rawQuery(
            "SELECT media_path FROM messages WHERE time < ? AND starred = 0 AND media_path IS NOT NULL",
            arrayOf(cutoff.toString()),
        ).use { c -> buildList { while (c.moveToNext()) add(c.getString(0)) } }
        var deleted = 0
        db.beginTransaction()
        try {
            // Kaydedilen mesajlar saklama süresinden etkilenmez.
            deleted = db.delete("messages", "time < ? AND starred = 0", arrayOf(cutoff.toString()))
            if (deleted > 0) {
                db.execSQL("DELETE FROM conversations WHERE key NOT IN (SELECT DISTINCT conv_key FROM messages)")
                cleanupPeople(db)
                db.execSQL(
                    "UPDATE conversations SET " +
                        "last_text = (SELECT text FROM messages WHERE conv_key = conversations.key " +
                        "ORDER BY time DESC LIMIT 1), " +
                        "last_time = (SELECT MAX(time) FROM messages WHERE conv_key = conversations.key)"
                )
            }
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
        files.forEach { java.io.File(it).delete() }
        return deleted
    }

    // ---- Kişiler ----

    /**
     * Sohbetleri tek kişide toplar. Biri zaten bir kişiye aitse diğerleri o
     * kişiye katılır; iki ayrı kişi birleşir. Kişinin kimliği.
     */
    fun mergePeople(keys: List<String>, name: String? = null): Long {
        require(keys.size >= 2) { "En az iki sohbet gerekir" }
        val db = writableDatabase
        db.beginTransaction()
        try {
            val existing = keys.mapNotNull { personIdOf(db, it) }.distinct().sorted()
            val target = existing.firstOrNull() ?: db.insertOrThrow(
                "people",
                null,
                ContentValues().apply {
                    put("name", name ?: titleOf(db, keys.first()) ?: Lang.str(appContext, R.string.person_default))
                    put("created", System.currentTimeMillis())
                },
            )
            for (other in existing.drop(1)) {
                db.execSQL("UPDATE conversations SET person_id = ? WHERE person_id = ?", arrayOf<Any>(target, other))
                db.delete("people", "id = ?", arrayOf(other.toString()))
            }
            for (key in keys) {
                db.execSQL("UPDATE conversations SET person_id = ? WHERE key = ?", arrayOf<Any>(target, key))
            }
            if (name != null) db.execSQL("UPDATE people SET name = ? WHERE id = ?", arrayOf<Any>(name, target))
            db.setTransactionSuccessful()
            Log.i(TAG, "Kişi birleştirildi: ${keys.size} sohbet (${keys.map { it.substringBefore('|') }.distinct().size} uygulama)")
            return target
        } finally {
            db.endTransaction()
        }
    }

    /** Sohbeti kişiden ayırır; aynı çift yeniden önerilmez. Tek üye kalırsa kişi kalkar. */
    fun unmergePerson(key: String) {
        val db = writableDatabase
        db.beginTransaction()
        try {
            val person = personIdOf(db, key) ?: return
            val others = db.rawQuery(
                "SELECT key FROM conversations WHERE person_id = ? AND key != ?",
                arrayOf(person.toString(), key),
            ).use { c -> buildList { while (c.moveToNext()) add(c.getString(0)) } }
            db.execSQL("UPDATE conversations SET person_id = NULL WHERE key = ?", arrayOf(key))
            for (other in others) insertDismissed(db, key, other)
            cleanupPeople(db)
            db.setTransactionSuccessful()
            Log.i(TAG, "Sohbet kişiden ayrıldı")
        } finally {
            db.endTransaction()
        }
    }

    fun renamePerson(id: Long, name: String) {
        writableDatabase.execSQL("UPDATE people SET name = ? WHERE id = ?", arrayOf<Any>(name, id))
    }

    /** "Farklı kişi": bu çift yeniden önerilmez. */
    fun dismissPersonSuggestion(a: String, b: String) {
        insertDismissed(writableDatabase, a, b)
    }

    /** Gelen kutusundaki sohbetlerden "aynı kişi mi?" önerileri. */
    fun personSuggestions(limit: Int = 10): List<Map<String, Any?>> {
        val db = readableDatabase
        val candidates = db.rawQuery(
            "SELECT key, package, title, is_group, shortcut_id, person_id, last_time FROM conversations " +
                "WHERE archived = 0",
            null,
        ).use { c ->
            buildList {
                while (c.moveToNext()) {
                    add(
                        PersonCandidate(
                            key = c.getString(0),
                            packageName = c.getString(1),
                            title = c.getString(2),
                            isGroup = c.getInt(3) == 1,
                            shortcutId = c.getString(4),
                            personId = if (c.isNull(5)) null else c.getLong(5),
                            lastTime = c.getLong(6),
                        )
                    )
                }
            }
        }
        val dismissed = db.rawQuery("SELECT a, b FROM person_dismissed", null).use { c ->
            buildSet { while (c.moveToNext()) add(c.getString(0) to c.getString(1)) }
        }
        val suggestions = PersonMatcher.suggestions(candidates, dismissed, limit)
        // İçeriksiz: yalnızca sayı, değiştiğinde.
        if (suggestions.size != lastSuggestionCount) {
            lastSuggestionCount = suggestions.size
            Log.i(
                TAG,
                "Kişi önerisi: ${suggestions.size} (ad ${suggestions.count { it.reason == "name" }}, " +
                    "numara ${suggestions.count { it.reason == "phone" }})",
            )
        }
        return suggestions.map { s ->
            mapOf(
                "a" to s.a.key,
                "b" to s.b.key,
                "reason" to s.reason,
            )
        }
    }

    private fun personIdOf(db: SQLiteDatabase, key: String): Long? =
        db.rawQuery("SELECT person_id FROM conversations WHERE key = ?", arrayOf(key)).use { c ->
            if (c.moveToFirst() && !c.isNull(0)) c.getLong(0) else null
        }

    private fun titleOf(db: SQLiteDatabase, key: String): String? =
        db.rawQuery("SELECT title FROM conversations WHERE key = ?", arrayOf(key)).use { c ->
            if (c.moveToFirst()) c.getString(0) else null
        }

    private fun insertDismissed(db: SQLiteDatabase, a: String, b: String) {
        val (first, second) = PersonMatcher.pairOf(a, b)
        db.execSQL("INSERT OR IGNORE INTO person_dismissed (a, b) VALUES (?, ?)", arrayOf(first, second))
    }

    /** Tek üyesi kalan kişi dağıtılır, üyesiz kişi silinir. */
    private fun cleanupPeople(db: SQLiteDatabase) {
        db.execSQL(
            "UPDATE conversations SET person_id = NULL WHERE person_id IN (" +
                "SELECT person_id FROM conversations WHERE person_id IS NOT NULL " +
                "GROUP BY person_id HAVING COUNT(*) < 2)"
        )
        db.execSQL(
            "DELETE FROM people WHERE id NOT IN " +
                "(SELECT DISTINCT person_id FROM conversations WHERE person_id IS NOT NULL)"
        )
    }

    /** Sabitlenenler en üstte, sonra önem işaretliler, sonra en yeniden eskiye. */
    fun conversations(archived: Boolean = false): List<Map<String, Any?>> =
        readableDatabase.rawQuery(
            "SELECT c.key, c.package, c.title, c.is_group, c.last_text, c.last_time, c.unread, c.important, " +
                "c.pinned, c.avatar_path, c.shortcut_id, c.reminded, c.person_id, p.name " +
                "FROM conversations c LEFT JOIN people p ON p.id = c.person_id " +
                "WHERE c.archived = ? AND c.snoozed_until = 0 " +
                "ORDER BY c.pinned DESC, c.reminded DESC, c.important DESC, c.last_time DESC",
            arrayOf(if (archived) "1" else "0"),
        ).use { c ->
            buildList {
                while (c.moveToNext()) {
                    add(
                        mapOf(
                            "key" to c.getString(0),
                            "package" to c.getString(1),
                            "title" to c.getString(2),
                            "isGroup" to (c.getInt(3) == 1),
                            "lastText" to c.getString(4),
                            "lastTime" to c.getLong(5),
                            "unread" to c.getInt(6),
                            "important" to (c.getInt(7) == 1),
                            "pinned" to (c.getInt(8) == 1),
                            "avatarPath" to c.getString(9),
                            "hasShortcut" to !c.isNull(10),
                            "reminded" to (c.getInt(11) == 1),
                            "personId" to (if (c.isNull(12)) null else c.getLong(12)),
                            "personName" to c.getString(13),
                            "archived" to archived,
                        )
                    )
                }
            }
        }

    /** Sohbetin son [MESSAGE_LIMIT] mesajı, eskiden yeniye. */
    fun messages(key: String): List<Map<String, Any?>> {
        // Telegram: kimliği okunan son mesajınkine eşit ya da küçük giden mesajlar görüldü.
        val readOutbox = readableDatabase.rawQuery(
            "SELECT read_outbox FROM conversations WHERE key = ?",
            arrayOf(key),
        ).use { c -> if (c.moveToFirst()) c.getLong(0) else 0L }
        return readableDatabase.rawQuery(
            "SELECT id, sender, text, time, outgoing, auto, media_path, media_mime, media_kind, media_ref, " +
                "deleted, starred, media_duration, media_size, send_state, send_error FROM (" +
                "SELECT * FROM messages WHERE conv_key = ? ORDER BY time DESC LIMIT $MESSAGE_LIMIT" +
                ") ORDER BY time ASC",
            arrayOf(key),
        ).use { c ->
            buildList {
                while (c.moveToNext()) {
                    add(
                        mapOf(
                            "id" to c.getString(0),
                            "sender" to c.getString(1),
                            "text" to c.getString(2),
                            "time" to c.getLong(3),
                            "outgoing" to (c.getInt(4) == 1),
                            "auto" to (c.getInt(5) == 1),
                            "mediaPath" to c.getString(6),
                            "mediaMime" to c.getString(7),
                            "mediaKind" to c.getString(8),
                            "downloadable" to !c.isNull(9),
                            "deleted" to (c.getInt(10) == 1),
                            "starred" to (c.getInt(11) == 1),
                            "mediaDuration" to (if (c.isNull(12)) null else c.getInt(12)),
                            "mediaSize" to (if (c.isNull(13)) null else c.getLong(13)),
                            "sendState" to when (c.getInt(14)) {
                                SendState.PENDING -> "pending"
                                SendState.FAILED -> "failed"
                                else -> null
                            },
                            "sendError" to c.getString(15),
                            "read" to (c.getInt(4) == 1 && readOutbox > 0 &&
                                TelegramIds.messageId(c.getString(0)).let { it != null && it <= readOutbox }),
                        )
                    )
                }
            }
        }
    }

    // ---- Kurallar ----

    fun rules(): List<Rule> =
        readableDatabase.rawQuery(
            "SELECT id, name, enabled, packages, keywords, sender_contains, include_groups, " +
                "action, reply_text, cooldown_minutes, active_from, active_to, active_days " +
                "FROM rules ORDER BY id",
            null,
        ).use { c ->
            buildList {
                while (c.moveToNext()) {
                    add(
                        Rule(
                            id = c.getLong(0),
                            name = c.getString(1),
                            enabled = c.getInt(2) == 1,
                            packages = splitList(c.getString(3)).toSet(),
                            keywords = splitList(c.getString(4)),
                            senderContains = c.getString(5),
                            includeGroups = c.getInt(6) == 1,
                            action = RuleAction.valueOf(c.getString(7)),
                            replyText = c.getString(8),
                            cooldownMinutes = c.getInt(9),
                            activeFrom = if (c.isNull(10)) null else c.getInt(10),
                            activeTo = if (c.isNull(11)) null else c.getInt(11),
                            activeDays = c.getInt(12),
                        )
                    )
                }
            }
        }

    /** Kurallar ve son [FIRE_RETENTION_MS] içinde kaç kez çalıştıkları. */
    fun ruleMaps(): List<Map<String, Any?>> {
        val since = System.currentTimeMillis() - FIRE_RETENTION_MS
        return rules().map { rule ->
            val fires = readableDatabase.rawQuery(
                "SELECT COUNT(*) FROM rule_fires WHERE rule_id = ? AND time >= ?",
                arrayOf(rule.id.toString(), since.toString()),
            ).use { c -> if (c.moveToFirst()) c.getInt(0) else 0 }
            rule.toMap() + ("recentFires" to fires)
        }
    }

    /** Yeni kuralı ekler ya da var olanı günceller; kuralın kimliğini döner. */
    fun saveRule(rule: Rule): Long {
        val row = ContentValues().apply {
            put("name", rule.name)
            put("enabled", if (rule.enabled) 1 else 0)
            put("packages", joinList(rule.packages))
            put("keywords", joinList(rule.keywords))
            put("sender_contains", rule.senderContains)
            put("include_groups", if (rule.includeGroups) 1 else 0)
            put("action", rule.action.name)
            put("reply_text", rule.replyText)
            put("cooldown_minutes", rule.cooldownMinutes)
            if (rule.activeFrom == null) putNull("active_from") else put("active_from", rule.activeFrom)
            if (rule.activeTo == null) putNull("active_to") else put("active_to", rule.activeTo)
            put("active_days", rule.activeDays)
        }
        if (rule.id == 0L) return writableDatabase.insertOrThrow("rules", null, row)
        writableDatabase.update("rules", row, "id = ?", arrayOf(rule.id.toString()))
        return rule.id
    }

    fun deleteRule(id: Long) {
        val db = writableDatabase
        db.beginTransaction()
        try {
            db.delete("rules", "id = ?", arrayOf(id.toString()))
            db.delete("rule_fires", "rule_id = ?", arrayOf(id.toString()))
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
    }

    fun recordFire(ruleId: Long, key: String, action: RuleAction, time: Long) {
        val db = writableDatabase
        db.insert(
            "rule_fires",
            null,
            ContentValues().apply {
                put("rule_id", ruleId)
                put("conv_key", key)
                put("action", action.name)
                put("time", time)
            },
        )
        db.delete("rule_fires", "time < ?", arrayOf((time - FIRE_RETENTION_MS).toString()))
    }

    fun lastAutoReply(ruleId: Long, key: String): Long? =
        readableDatabase.rawQuery(
            "SELECT MAX(time) FROM rule_fires WHERE rule_id = ? AND conv_key = ? AND action = ?",
            arrayOf(ruleId.toString(), key, RuleAction.AUTO_REPLY.name),
        ).use { c -> if (c.moveToFirst() && !c.isNull(0)) c.getLong(0) else null }

    fun autoRepliesSince(since: Long): Int =
        readableDatabase.rawQuery(
            "SELECT COUNT(*) FROM rule_fires WHERE action = ? AND time >= ?",
            arrayOf(RuleAction.AUTO_REPLY.name, since.toString()),
        ).use { c -> if (c.moveToFirst()) c.getInt(0) else 0 }

    // ---- Yardımcılar ----

    private fun refreshConversation(db: SQLiteDatabase, key: String, newIncoming: Int) {
        db.rawQuery(
            "SELECT text, time FROM messages WHERE conv_key = ? ORDER BY time DESC LIMIT 1",
            arrayOf(key),
        ).use { c ->
            if (!c.moveToFirst()) return
            db.execSQL(
                "UPDATE conversations SET last_text = ?, last_time = ?, unread = unread + ? WHERE key = ?",
                arrayOf<Any?>(c.getString(0), c.getLong(1), newIncoming, key),
            )
        }
    }

    /**
     * Aynı mesajın ikinci kez gelmiş hali mi?
     * - Bizim gönderdiğimiz yanıtı uygulama bildirime kendi zaman damgasıyla geri koyar.
     * - MessagingStyle'sız bildirimler güncellendikçe zaman damgası değişir.
     * - Aynı sohbette aynı milisaniyede aynı metin: kimlik formülü (ör. ad
     *   temizleme) değişse de aynı mesajdır.
     */
    private fun isEcho(db: SQLiteDatabase, key: String, m: CapturedMessage): Boolean {
        val (sql, args) = when {
            m.outgoing -> "SELECT 1 FROM messages WHERE conv_key = ? AND outgoing = 1 AND text = ? " +
                "AND ABS(time - ?) < ? LIMIT 1" to
                arrayOf(key, m.text, m.time.toString(), ECHO_WINDOW_MS.toString())
            m.fromFallback -> "SELECT 1 FROM messages WHERE conv_key = ? AND text = ? " +
                "AND ABS(time - ?) < ? AND COALESCE(sender, '') = ? LIMIT 1" to
                arrayOf(key, m.text, m.time.toString(), FALLBACK_WINDOW_MS.toString(), m.sender.orEmpty())
            else -> "SELECT 1 FROM messages WHERE conv_key = ? AND time = ? AND text = ? LIMIT 1" to
                arrayOf(key, m.time.toString(), m.text)
        }
        return db.rawQuery(sql, args).use { it.moveToFirst() }
    }

    private fun hasMedia(db: SQLiteDatabase, id: String): Boolean =
        db.rawQuery("SELECT 1 FROM messages WHERE id = ? AND media_path IS NOT NULL", arrayOf(id))
            .use { it.moveToFirst() }

    private fun messageId(key: String, m: CapturedMessage): String {
        val digest = MessageDigest.getInstance("SHA-1")
            .digest("$key\u0000${m.time}\u0000${m.sender}\u0000${m.text}".toByteArray())
        return digest.joinToString("") { "%02x".format(it) }
    }

    // Liste ayırıcısı satır sonu; öğelerin içindeki satır sonları boşluğa çevrilir.
    private fun joinList(items: Collection<String>) =
        items.joinToString("\n") { it.replace('\n', ' ') }

    private fun splitList(s: String) = s.split('\n').filter { it.isNotEmpty() }

    @Volatile
    private var lastSuggestionCount = -1

    private companion object {
        const val TAG = "MesajMerkezi"
        const val MESSAGE_LIMIT = 500
        const val MEDIA_LIMIT = 300
        const val SEARCH_LIMIT = 100
        const val ECHO_WINDOW_MS = 2 * 60 * 1000L
        const val FALLBACK_WINDOW_MS = 10 * 60 * 1000L
        const val FIRE_RETENTION_MS = 7 * 24 * 60 * 60 * 1000L
        const val WAITING_WINDOW_MS = 2 * 24 * 60 * 60 * 1000L
    }
}
