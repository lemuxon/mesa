package com.mesajmerkezi.mesaj_merkezi

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Base64
import android.util.Log
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.IOException
import java.io.OutputStream
import java.net.Inet4Address
import java.net.NetworkInterface
import java.security.MessageDigest
import java.security.SecureRandom
import java.util.concurrent.Callable
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit

/**
 * Bilgisayardan Mesa: aynı Wi-Fi'deki bilgisayarın tarayıcısından mesajları
 * okuma ve yanıtlama.
 *
 * Telefon küçük bir HTTPS sunucusu açar ([DesktopServer], kendinden imzalı
 * sertifika [DesktopCert]); internete çıkılmaz, aracı sunucu yoktur. Bir
 * tarayıcı ancak telefonda çıkan bildirimde, bilgisayarda görünen kod
 * onaylanırsa bağlanır; sonra kendi oturum anahtarıyla istek yapar (çerez
 * kullanılmaz). Oturumlar 30 gün kullanılmazsa düşer, Mesa'dan da kaldırılabilir.
 * Sunucu [ConnectionService] açıkken çalışır.
 */
object Desktop {
    private const val TAG = "MesajMerkezi"
    private const val PREFS = "desktop"
    private const val CHANNEL_ID = "desktop"
    private val PORTS = 8743..8763
    private const val SESSION_MAX_IDLE_MS = 30L * 86_400_000L
    private const val PAIRING_TTL_MS = 120_000L

    private val random = SecureRandom()

    @Volatile
    private var server: DesktopServer? = null

    @Volatile
    var port: Int = 0
        private set

    @Volatile
    private var appContext: Context? = null

    // ---- Açık / kapalı ----

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun enabled(context: Context) = prefs(context).getBoolean("enabled", false)

    fun setEnabled(context: Context, value: Boolean) {
        prefs(context).edit().putBoolean("enabled", value).apply()
        if (!value) stop()
    }

    val running: Boolean get() = server?.running == true

    /** Ayara göre sunucuyu açar ya da kapatır ([ConnectionService]'ten çağrılır). */
    fun sync(context: Context) {
        if (enabled(context)) start(context) else stop()
    }

    @Volatile
    private var starting = false

    @Synchronized
    private fun start(context: Context) {
        if (server?.running == true || starting) return
        starting = true
        val app = context.applicationContext
        appContext = app
        Thread({
            try {
                val identity = DesktopCert.load(app)
                val created = DesktopServer(DesktopCert.sslContext(identity)) { handle(app, it) }
                val bound = created.start(PORTS)
                synchronized(this) {
                    server = created
                    port = bound
                }
                if (listener !in Hub.changeListeners) Hub.changeListeners.add(listener)
                Log.i(TAG, "Bilgisayardan Mesa açıldı (port $bound)")
            } catch (e: Exception) {
                Log.w(TAG, "Bilgisayardan Mesa açılamadı: ${e.javaClass.simpleName}")
            } finally {
                starting = false
            }
        }, "mesa-masaustu-baslat").start()
    }

    @Synchronized
    fun stop() {
        server?.stop()
        server = null
        port = 0
        Hub.changeListeners.remove(listener)
        streams.forEach { it.offer(CLOSE) }
        pairings.clear()
    }

    /** Telefonun yerel ağ adresleri (önce Wi-Fi). */
    fun addresses(): List<String> = try {
        NetworkInterface.getNetworkInterfaces().toList()
            .filter { it.isUp && !it.isLoopback }
            .sortedByDescending { it.name.startsWith("wlan") }
            .flatMap { iface -> iface.inetAddresses.toList() }
            .filterIsInstance<Inet4Address>()
            .filter { it.isSiteLocalAddress }
            .mapNotNull { it.hostAddress }
            .distinct()
    } catch (e: Exception) {
        emptyList()
    }

    /** Mesa ekranı için durum. */
    fun status(context: Context): Map<String, Any?> = mapOf(
        "enabled" to enabled(context),
        "running" to running,
        "urls" to (if (running) addresses().map { "https://$it:$port" } else emptyList()),
        "sessions" to sessions(context).map { mapOf("id" to it.id, "name" to it.name, "lastSeen" to it.lastSeen) },
    )

    // ---- Oturumlar ----

    internal class Session(val id: String, val hash: String, val name: String, val created: Long, val lastSeen: Long)

    @Synchronized
    internal fun sessions(context: Context): List<Session> {
        val now = System.currentTimeMillis()
        val raw = prefs(context).getString("sessions", null) ?: return emptyList()
        return try {
            val array = JSONArray(raw)
            (0 until array.length()).map { array.getJSONObject(it) }.map {
                Session(it.getString("id"), it.getString("hash"), it.getString("name"), it.getLong("created"), it.getLong("lastSeen"))
            }.filter { now - it.lastSeen < SESSION_MAX_IDLE_MS }
        } catch (e: Exception) {
            emptyList()
        }
    }

    @Synchronized
    private fun saveSessions(context: Context, sessions: List<Session>) {
        val array = JSONArray()
        sessions.forEach {
            array.put(
                JSONObject().put("id", it.id).put("hash", it.hash).put("name", it.name)
                    .put("created", it.created).put("lastSeen", it.lastSeen),
            )
        }
        prefs(context).edit().putString("sessions", array.toString()).apply()
    }

    private fun hash(token: String) =
        Base64.encodeToString(MessageDigest.getInstance("SHA-256").digest(token.toByteArray()), Base64.NO_WRAP)

    private fun newSecret(bytes: Int): String {
        val raw = ByteArray(bytes).also(random::nextBytes)
        return Base64.encodeToString(raw, Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING)
    }

    @Synchronized
    internal fun createSession(context: Context, name: String): String {
        val token = newSecret(32)
        val now = System.currentTimeMillis()
        saveSessions(context, sessions(context) + Session(newSecret(9), hash(token), name, now, now))
        return token
    }

    /** İsteğin oturumu (Authorization: Bearer …); geçersizse null. */
    @Synchronized
    internal fun sessionFor(context: Context, request: HttpRequest): Session? {
        val token = request.header("authorization")?.removePrefix("Bearer ")?.trim()?.takeIf { it.isNotEmpty() }
            ?: return null
        val wanted = hash(token)
        val all = sessions(context)
        val session = all.firstOrNull { MessageDigest.isEqual(it.hash.toByteArray(), wanted.toByteArray()) } ?: return null
        val now = System.currentTimeMillis()
        // Son görülme dakikada bir yazılır.
        if (now - session.lastSeen > 60_000L) {
            saveSessions(context, all.map { if (it.id == session.id) Session(it.id, it.hash, it.name, it.created, now) else it })
        }
        return session
    }

    @Synchronized
    fun revoke(context: Context, id: String) {
        saveSessions(context, sessions(context).filter { it.id != id })
        streams.filter { it.sessionId == id }.forEach { it.offer(CLOSE) }
    }

    // ---- Eşleştirme ----

    internal enum class PairState { PENDING, APPROVED, DENIED }

    internal class Pairing(val id: String, val code: String, val device: String, val created: Long, val remote: String) {
        @Volatile
        var state = PairState.PENDING

        @Volatile
        var token: String? = null
    }

    internal val pairings = ConcurrentHashMap<String, Pairing>()
    internal val lastPairing = ConcurrentHashMap<String, Long>()

    /** Yeni eşleştirme isteği; çok sık ya da çok fazlaysa null. */
    internal fun requestPairing(context: Context, device: String, remote: String): Pairing? {
        val now = System.currentTimeMillis()
        pairings.values.removeIf { now - it.created > PAIRING_TTL_MS }
        if ((lastPairing[remote] ?: 0L) > now - 3_000L) return null
        if (pairings.values.count { it.state == PairState.PENDING } >= 3) return null
        lastPairing[remote] = now
        val code = "%04d".format(random.nextInt(10_000))
        val pairing = Pairing(newSecret(18), code, device, now, remote)
        pairings[pairing.id] = pairing
        notifyPairing(context, pairing)
        return pairing
    }

    internal fun approve(context: Context, id: String): Boolean {
        val pairing = pairings[id] ?: return false
        if (pairing.state != PairState.PENDING) return false
        if (System.currentTimeMillis() - pairing.created > PAIRING_TTL_MS) return false
        pairing.token = createSession(context, pairing.device)
        pairing.state = PairState.APPROVED
        Log.i(TAG, "Bilgisayar bağlandı")
        return true
    }

    internal fun deny(id: String) {
        pairings[id]?.state = PairState.DENIED
    }

    private fun notificationId(pairing: Pairing) = 3100 + (pairing.id.hashCode() and 0xFF)

    private fun notifyPairing(context: Context, pairing: Pairing) {
        val manager = NotificationManagerCompat.from(context)
        manager.createNotificationChannel(
            NotificationChannelCompat.Builder(CHANNEL_ID, NotificationManagerCompat.IMPORTANCE_HIGH)
                .setName(Lang.str(context, R.string.desktop_name))
                .setDescription(Lang.str(context, R.string.desktop_channel_desc))
                .build(),
        )
        fun action(kind: String, label: Int, requestCode: Int, unlock: Boolean): NotificationCompat.Action {
            val intent = Intent(context, DesktopReceiver::class.java)
                .setAction(kind)
                .putExtra(EXTRA_PAIRING, pairing.id)
                .putExtra(EXTRA_NOTIFICATION, notificationId(pairing))
            val pending = PendingIntent.getBroadcast(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            // İzin vermek için telefonun kilidi açılmalı.
            return NotificationCompat.Action.Builder(0, Lang.str(context, label), pending)
                .setAuthenticationRequired(unlock)
                .build()
        }
        val code = notificationId(pairing)
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(Lang.str(context, R.string.desktop_pair_title))
            .setContentText(Lang.str(context, R.string.desktop_pair_text, pairing.device, pairing.code))
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText(Lang.str(context, R.string.desktop_pair_text, pairing.device, pairing.code)),
            )
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setTimeoutAfter(PAIRING_TTL_MS)
            .setAutoCancel(true)
            .addAction(action(ACTION_ALLOW, R.string.desktop_allow, code * 2, unlock = true))
            .addAction(action(ACTION_DENY, R.string.desktop_deny, code * 2 + 1, unlock = false))
            .build()
        try {
            manager.notify(code, notification)
        } catch (e: SecurityException) {
            Log.w(TAG, "Bildirim izni yok: eşleştirme sorulamadı")
        }
    }

    internal const val ACTION_ALLOW = "com.mesajmerkezi.mesaj_merkezi.DESKTOP_ALLOW"
    internal const val ACTION_DENY = "com.mesajmerkezi.mesaj_merkezi.DESKTOP_DENY"
    internal const val EXTRA_PAIRING = "pairing"
    internal const val EXTRA_NOTIFICATION = "notification"

    /** Tarayıcının kimliği ("Chrome · Windows"): bildirimde ve bağlı cihazlar listesinde. */
    internal fun deviceName(userAgent: String?): String {
        val ua = userAgent.orEmpty()
        val browser = when {
            "Edg/" in ua -> "Edge"
            "OPR/" in ua || "Opera" in ua -> "Opera"
            "Firefox/" in ua -> "Firefox"
            "Chrome/" in ua -> "Chrome"
            "Safari/" in ua -> "Safari"
            else -> "Tarayıcı"
        }
        val system = when {
            "Windows" in ua -> "Windows"
            "Mac OS X" in ua || "Macintosh" in ua -> "macOS"
            "CrOS" in ua -> "ChromeOS"
            "Android" in ua -> "Android"
            "iPhone" in ua || "iPad" in ua -> "iOS"
            "Linux" in ua -> "Linux"
            else -> null
        }
        return if (system == null) browser else "$browser · $system"
    }

    // ---- Canlı güncellemeler ----

    private class EventQueue(val sessionId: String) : LinkedBlockingQueue<String>()

    private const val CLOSE = "\u0000close"
    private val streams = CopyOnWriteArrayList<EventQueue>()
    private val listener: (String) -> Unit = { key ->
        val event = JSONObject().put("key", key).toString()
        streams.forEach { it.offer(event) }
    }

    private fun events(session: Session): HttpResponse = HttpResponse(
        200,
        "text/event-stream; charset=utf-8",
        headers = mapOf("Cache-Control" to "no-store", "X-Accel-Buffering" to "no"),
        stream = { output -> pump(session, output) },
    )

    private fun pump(session: Session, output: OutputStream) {
        val queue = EventQueue(session.id)
        streams.add(queue)
        try {
            output.write(": merhaba\n\n".toByteArray())
            output.flush()
            while (running) {
                val event = queue.poll(25, TimeUnit.SECONDS)
                when {
                    event == null -> output.write(": ping\n\n".toByteArray())
                    event == CLOSE -> break
                    else -> output.write("event: changed\ndata: $event\n\n".toByteArray(Charsets.UTF_8))
                }
                output.flush()
            }
        } catch (_: IOException) {
        } catch (_: InterruptedException) {
        } finally {
            streams.remove(queue)
        }
    }

    // ---- İstekler ----

    private val STATIC = mapOf(
        "/" to ("index.html" to "text/html; charset=utf-8"),
        "/index.html" to ("index.html" to "text/html; charset=utf-8"),
        "/app.js" to ("app.js" to "text/javascript; charset=utf-8"),
        "/app.css" to ("app.css" to "text/css; charset=utf-8"),
        "/icon.png" to ("icon.png" to "image/png"),
    )

    private const val CSP =
        "default-src 'none'; script-src 'self'; style-src 'self'; img-src 'self' blob: data:; " +
            "connect-src 'self'; manifest-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'"

    /** [value]: JSONObject ya da JSONArray. */
    private fun json(status: Int, value: Any) =
        HttpResponse(status, "application/json; charset=utf-8", value.toString().toByteArray(Charsets.UTF_8))

    private fun error(status: Int, code: String) = json(status, JSONObject().put("error", code))

    private fun <T> io(block: () -> T): T = Hub.io.submit(Callable { block() }).get(20, TimeUnit.SECONDS)

    /**
     * Adres çubuğunda IP adresi mi (ör. 192.168.1.23:8743): bir alan adının
     * telefonun adresine yönlendirildiği saldırılarda (DNS rebinding) istek
     * başka bir sitenin adını taşır ve reddedilir.
     */
    internal fun isIpHost(host: String?): Boolean {
        if (host == null) return false
        if (host.startsWith("[")) return host.substringBefore(']').drop(1).all { it.isLetterOrDigit() || it == ':' || it == '.' }
        return Regex("""\d{1,3}(\.\d{1,3}){3}(:\d{1,5})?""").matches(host)
    }

    internal fun handle(context: Context, request: HttpRequest): HttpResponse {
        if (!isIpHost(request.header("host"))) return error(421, "host")
        STATIC[request.path]?.let { (file, type) ->
            if (request.method != "GET") return error(405, "method")
            val bytes = context.assets.open("desktop/$file").use { it.readBytes() }
            val headers = if (file == "index.html") mapOf("Content-Security-Policy" to CSP) else emptyMap()
            return HttpResponse(200, type, bytes, headers)
        }
        if (!request.path.startsWith("/api/")) return error(404, "not_found")
        // Başka bir sitenin sayfası bu adrese istek gönderemesin.
        val origin = request.header("origin")
        val host = request.header("host")
        if (request.method == "POST" && origin != null && origin != "https://$host") return error(403, "origin")
        when (request.path) {
            "/api/hello" -> return json(200, JSONObject().put("language", language(context)))
            "/api/pair" -> {
                if (request.method != "POST") return error(405, "method")
                val pairing = requestPairing(context, deviceName(request.header("user-agent")), request.remote.hostAddress.orEmpty())
                    ?: return error(429, "busy")
                return json(200, JSONObject().put("id", pairing.id).put("code", pairing.code))
            }
            "/api/pair/status" -> {
                val pairing = pairings[request.query["id"].orEmpty()] ?: return error(404, "expired")
                return when (pairing.state) {
                    PairState.PENDING -> json(200, JSONObject().put("state", "pending"))
                    PairState.DENIED -> {
                        pairings.remove(pairing.id)
                        json(200, JSONObject().put("state", "denied"))
                    }
                    PairState.APPROVED -> {
                        // Anahtar bir kez verilir.
                        pairings.remove(pairing.id)
                        json(200, JSONObject().put("state", "approved").put("token", pairing.token))
                    }
                }
            }
        }
        val session = sessionFor(context, request) ?: return error(401, "unauthorized")
        return when (request.path) {
            "/api/session" -> json(
                200,
                JSONObject().put("language", language(context)).put("device", session.name),
            )
            "/api/conversations" -> json(200, conversations(context))
            "/api/messages" -> {
                val key = request.query["key"] ?: return error(400, "key")
                json(200, messages(context, key))
            }
            "/api/send" -> {
                if (request.method != "POST") return error(405, "method")
                val body = JSONObject(String(request.body, Charsets.UTF_8))
                send(context, body.getString("key"), body.getString("text"))
            }
            "/api/read" -> {
                if (request.method != "POST") return error(405, "method")
                val key = JSONObject(String(request.body, Charsets.UTF_8)).getString("key")
                TelegramClient.markViewed(key)
                io { Hub.store(context).markRead(key) }
                UnifiedNotifier.cancel(context, key)
                Hub.notifyChanged(key)
                json(200, JSONObject().put("ok", true))
            }
            "/api/events" -> events(session)
            "/api/avatar" -> {
                val key = request.query["key"] ?: return error(400, "key")
                val path = io { Hub.store(context).conversation(key)?.get("avatarPath") as String? }
                file(path, "image/png")
            }
            "/api/media" -> {
                val key = request.query["key"] ?: return error(400, "key")
                val id = request.query["id"] ?: return error(400, "id")
                val row = io { Hub.store(context).messages(key).firstOrNull { it["id"] == id } }
                file(row?.get("mediaPath") as String?, row?.get("mediaMime") as String? ?: "application/octet-stream")
            }
            "/api/logout" -> {
                revoke(context, session.id)
                json(200, JSONObject().put("ok", true))
            }
            else -> error(404, "not_found")
        }
    }

    private fun language(context: Context) = Lang.code(context) ?: java.util.Locale.getDefault().language

    private fun file(path: String?, type: String): HttpResponse {
        val file = path?.let(::File)?.takeIf { it.isFile } ?: return error(404, "not_found")
        return HttpResponse(200, type, file.readBytes(), mapOf("Cache-Control" to "private, max-age=3600"))
    }

    private fun conversations(context: Context): JSONArray {
        val rows = io { Hub.store(context).conversations() }
        val out = JSONArray()
        for (row in rows) {
            val key = row["key"] as String
            val pkg = row["package"] as String
            out.put(
                JSONObject()
                    .put("key", key)
                    .put("title", row["personName"] as String? ?: row["title"])
                    .put("app", SupportedApps.name(pkg))
                    .put("color", "#%06X".format(SupportedApps.color(pkg) and 0xFFFFFF))
                    .put("isGroup", row["isGroup"])
                    .put("lastText", StoredLabels.display(context, row["lastText"] as String? ?: ""))
                    .put("lastTime", row["lastTime"])
                    .put("unread", row["unread"])
                    .put("pinned", row["pinned"])
                    .put("hasAvatar", row["avatarPath"] != null)
                    .put("canReply", Hub.canReply(key)),
            )
        }
        return out
    }

    private fun messages(context: Context, key: String): JSONObject {
        val rows = io { Hub.store(context).messages(key) }
        val array = JSONArray()
        for (row in rows) {
            val mime = row["mediaMime"] as String?
            array.put(
                JSONObject()
                    .put("id", row["id"])
                    .put("sender", row["sender"])
                    .put("text", StoredLabels.display(context, row["text"] as String? ?: ""))
                    .put("time", row["time"])
                    .put("outgoing", row["outgoing"])
                    .put("deleted", row["deleted"])
                    .put("image", row["mediaPath"] != null && mime?.startsWith("image/") == true)
                    .put("transcript", row["transcript"])
                    .put("failed", row["sendState"] == "failed"),
            )
        }
        return JSONObject().put("key", key).put("canReply", Hub.canReply(key)).put("messages", array)
    }

    private fun send(context: Context, key: String, text: String): HttpResponse {
        val message = text.trim()
        if (message.isEmpty() || message.length > 4096) return error(400, "text")
        try {
            Hub.sendReply(context, key, message)
        } catch (e: NoReplyActionException) {
            return error(409, "no_reply")
        }
        io {
            if (Hub.recordsOwnReplies(key)) Hub.store(context).recordOutgoing(key, message)
        }
        Hub.notifyChanged(key)
        return json(200, JSONObject().put("ok", true))
    }
}

/** Eşleştirme bildirimindeki "İzin ver" / "Reddet". */
class DesktopReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getStringExtra(Desktop.EXTRA_PAIRING) ?: return
        when (intent.action) {
            Desktop.ACTION_ALLOW -> Desktop.approve(context, id)
            Desktop.ACTION_DENY -> Desktop.deny(id)
        }
        NotificationManagerCompat.from(context).cancel(intent.getIntExtra(Desktop.EXTRA_NOTIFICATION, 0))
    }
}
