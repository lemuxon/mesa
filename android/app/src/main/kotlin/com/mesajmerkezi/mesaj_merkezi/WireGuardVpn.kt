package com.mesajmerkezi.mesaj_merkezi

import android.content.Context
import android.util.Log
import com.wireguard.android.backend.BackendException
import com.wireguard.android.backend.GoBackend
import com.wireguard.android.backend.Tunnel
import com.wireguard.config.BadConfigException
import com.wireguard.config.Config
import java.io.BufferedReader
import java.io.IOException
import java.io.StringReader
import java.util.concurrent.Executors

/**
 * Tam VPN: kullanıcının içe aktardığı WireGuard yapılandırmasıyla gerçek
 * tünel (resmî WireGuard kitaplığı, GoBackend). Bütün trafik tünelden geçer,
 * IP adresi değişir. Mesa sunucu sağlamaz; yapılandırma kullanıcının kendi
 * sunucusundan ya da bir VPN sağlayıcısından gelir.
 *
 * Yapılandırma metni özel anahtar içerdiği için SecretBox ile şifreli
 * saklanır; arayüze yalnızca özet (uç nokta, adres, DNS) gider.
 * Android aynı anda tek VPN çalıştırır: tünel açılırken şifreli DNS kapatılır.
 */
object WireGuardVpn {

    private const val TAG = "MesaVPN"
    private const val PREFS = "wireguard"
    private const val KEY_IDS = "ids"
    private const val KEY_NEXT = "next_id"
    private const val KEY_LAST = "last_id"

    private val io = Executors.newSingleThreadExecutor { r -> Thread(r, "MesaVPN").apply { isDaemon = true } }

    @Volatile
    private var backend: GoBackend? = null
    private val tunnels = HashMap<String, MesaTunnel>()

    /** Açık tünelin kimliği; kapalıysa null. */
    @Volatile
    var activeId: String? = null
        private set

    @Volatile
    var lastError: String? = null
        private set

    private class MesaTunnel(val id: String) : Tunnel {
        override fun getName() = "mesa$id"

        override fun onStateChange(newState: Tunnel.State) {
            Log.i(TAG, "Tünel durumu: $newState")
            if (newState == Tunnel.State.DOWN && activeId == id) activeId = null
        }
    }

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    @Synchronized
    private fun backend(context: Context): GoBackend =
        backend ?: GoBackend(context.applicationContext).also {
            backend = it
            // Sistem "her zaman açık VPN" ile başlatırsa son tünel geri gelsin.
            GoBackend.setAlwaysOnCallback { connectLast(context.applicationContext) }
        }

    @Synchronized
    private fun tunnel(id: String) = tunnels.getOrPut(id) { MesaTunnel(id) }

    private fun ids(context: Context): List<String> =
        prefs(context).getString(KEY_IDS, "").orEmpty().split(',').filter { it.isNotEmpty() }

    /** Yapılandırmayı doğrular; geçersizse BadConfigException ya da IOException. */
    internal fun parse(text: String): Config = Config.parse(BufferedReader(StringReader(text)))

    /** Arayüze giden özet; özel ve paylaşılan anahtarlar asla içermez. */
    internal fun summary(id: String, name: String, config: Config): Map<String, Any?> = mapOf(
        "id" to id,
        "name" to name,
        "endpoints" to config.peers.mapNotNull { it.endpoint.orElse(null)?.toString() },
        "addresses" to config.`interface`.addresses.map { it.toString() },
        "dns" to config.`interface`.dnsServers.map { it.hostAddress },
        "fullTunnel" to config.peers.any { peer ->
            peer.allowedIps.any { it.toString() == "0.0.0.0/0" || it.toString() == "::/0" }
        },
        "active" to (activeId == id),
    )

    private fun load(context: Context, id: String): Pair<String, Config>? {
        val p = prefs(context)
        val name = p.getString("name_$id", null) ?: return null
        val text = p.getString("config_$id", null)?.let(SecretBox::decrypt) ?: return null
        return try {
            name to parse(text)
        } catch (e: Exception) {
            null
        }
    }

    fun list(context: Context): List<Map<String, Any?>> = ids(context).mapNotNull { id ->
        val loaded = load(context, id)
        if (loaded != null) {
            summary(id, loaded.first, loaded.second)
        } else {
            // Açılamayan kayıt (ör. telefon sıfırlanıp anahtar değişti): silinebilsin diye listelenir.
            mapOf("id" to id, "name" to prefs(context).getString("name_$id", "?"), "broken" to true, "active" to false)
        }
    }

    /**
     * Yapılandırmayı içe aktarır. Başarılıysa (kimlik, null); değilse
     * (null, hata kodu): "BAD_CONFIG:<bölüm>/<alan>/<neden>", "NO_PEER".
     */
    fun import(context: Context, name: String, text: String): Pair<String?, String?> {
        val config = try {
            parse(text)
        } catch (e: BadConfigException) {
            return null to "BAD_CONFIG:${e.section}/${e.location}/${e.reason}"
        } catch (e: IOException) {
            return null to "BAD_CONFIG"
        }
        if (config.peers.isEmpty()) return null to "NO_PEER"
        val p = prefs(context)
        val id = p.getInt(KEY_NEXT, 1).toString()
        val cleanName = name.trim().removeSuffix(".conf").ifEmpty { "WireGuard $id" }.take(40)
        p.edit()
            .putInt(KEY_NEXT, id.toInt() + 1)
            .putString("name_$id", cleanName)
            .putString("config_$id", SecretBox.encrypt(text))
            .putString(KEY_IDS, (ids(context) + id).joinToString(","))
            .apply()
        Log.i(TAG, "WireGuard yapılandırması içe aktarıldı (${config.peers.size} eş)")
        return id to null
    }

    fun remove(context: Context, id: String, done: () -> Unit) {
        val finish = {
            prefs(context).edit()
                .remove("name_$id")
                .remove("config_$id")
                .putString(KEY_IDS, ids(context).filter { it != id }.joinToString(","))
                .apply()
            done()
        }
        if (activeId == id) disconnect(context) { finish() } else finish()
    }

    /**
     * Tüneli açar (VPN izni önceden verilmiş olmalı). Hata yoksa null, varsa
     * kod: VPN_NOT_AUTHORIZED, DNS_RESOLUTION_FAILURE, MISSING, … .
     */
    fun connect(context: Context, id: String, done: (String?) -> Unit) {
        val app = context.applicationContext
        // Aynı anda tek VPN: şifreli DNS açıksa önce kapanır.
        if (SecureDns.running) SecureDns.stop(app)
        io.execute {
            val error = try {
                val loaded = load(app, id) ?: throw IllegalStateException("MISSING")
                if (SecureDns.running) Thread.sleep(400) // DNS tüneli kapansın
                val previous = activeId
                if (previous != null && previous != id) backend(app).setState(tunnel(previous), Tunnel.State.DOWN, null)
                backend(app).setState(tunnel(id), Tunnel.State.UP, loaded.second)
                activeId = id
                prefs(app).edit().putString(KEY_LAST, id).apply()
                Log.i(TAG, "WireGuard tüneli açıldı")
                null
            } catch (e: BackendException) {
                e.reason.name
            } catch (e: IllegalStateException) {
                e.message ?: "ERROR"
            } catch (e: Exception) {
                Log.w(TAG, "WireGuard tüneli açılamadı", e)
                e.javaClass.simpleName
            }
            lastError = error
            done(error)
        }
    }

    fun disconnect(context: Context, done: (String?) -> Unit) {
        val id = activeId ?: return done(null)
        val app = context.applicationContext
        io.execute {
            val error = try {
                backend(app).setState(tunnel(id), Tunnel.State.DOWN, null)
                activeId = null
                Log.i(TAG, "WireGuard tüneli kapatıldı")
                null
            } catch (e: Exception) {
                Log.w(TAG, "WireGuard tüneli kapatılamadı", e)
                e.javaClass.simpleName
            }
            done(error)
        }
    }

    /** Sistem her zaman açık VPN'i başlattığında son kullanılan tünel. */
    private fun connectLast(context: Context) {
        val id = prefs(context).getString(KEY_LAST, null) ?: return
        if (activeId == null) connect(context, id) { error -> if (error != null) Log.w(TAG, "Her zaman açık: $error") }
    }

    /** Açık tünelin durumu; GoBackend yalnızca tünel açıkken sorulur. */
    fun status(context: Context): Map<String, Any?> {
        val id = activeId
        var rx = 0L
        var tx = 0L
        var handshake = 0L
        if (id != null) {
            try {
                val stats = backend(context).getStatistics(tunnel(id))
                rx = stats.totalRx()
                tx = stats.totalTx()
                handshake = stats.peers().maxOfOrNull { stats.peer(it)?.latestHandshakeEpochMillis() ?: 0L } ?: 0L
            } catch (e: Exception) {
                // İstatistik okunamadı; bağlantı durumu yine gösterilir.
            }
        }
        return mapOf(
            "activeId" to id,
            "rx" to rx,
            "tx" to tx,
            "handshake" to handshake,
            "lastError" to lastError,
        )
    }
}
