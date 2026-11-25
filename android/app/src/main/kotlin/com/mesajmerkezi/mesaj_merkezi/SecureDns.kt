package com.mesajmerkezi.mesaj_merkezi

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.VpnService
import android.provider.Settings
import android.service.quicksettings.TileService
import android.util.Log
import androidx.core.content.ContextCompat

/**
 * Şifreli DNS'in ayarları ve durumu. Bütün telefonun DNS sorguları yerel,
 * yalnızca DNS taşıyan bir VPN (DnsVpnService) üzerinden seçilen sağlayıcıya
 * DNS-over-HTTPS ile gider. Bu bir tünel VPN değildir: IP adresi değişmez,
 * yalnızca DNS engelleri aşılır ve sorgular operatörden gizlenir.
 */
object SecureDns {

    private const val TAG = "MesaDNS"
    private const val PREFS = "secure_dns"
    private const val KEY_ENABLED = "enabled"
    private const val KEY_PROVIDER = "provider"

    /** Hem telefonun DNS'i hem de erişim kalkanı bu istemciyi paylaşır. */
    internal val client = DohClient()

    @Volatile
    var running = false
        private set

    /** Son kapanma nedeni: "user", "revoked" (başka VPN), "permission", "error". */
    @Volatile
    var lastStop: String? = null
        private set

    @Volatile
    private var startedAt = 0L

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun enabled(context: Context) = prefs(context).getBoolean(KEY_ENABLED, false)

    internal fun provider(context: Context) = DohProviders.byId(prefs(context).getString(KEY_PROVIDER, null))

    fun setProvider(context: Context, id: String) {
        val provider = DohProviders.byId(id)
        prefs(context).edit().putString(KEY_PROVIDER, provider.id).apply()
        client.provider = provider
        Log.i(TAG, "Sağlayıcı: ${provider.id}")
        DnsVpnService.refreshNotification()
        changed(context)
    }

    /** Bildirimde ve kutucukta görünen, dile bağlı olmayan ad. */
    internal fun label(provider: DohProvider) = when (provider.id) {
        "cloudflare" -> "Cloudflare 1.1.1.1"
        "cloudflare_security" -> "Cloudflare 1.1.1.2"
        "cloudflare_family" -> "Cloudflare 1.1.1.3"
        "adguard" -> "AdGuard DNS"
        "quad9" -> "Quad9 9.9.9.9"
        "google" -> "Google 8.8.8.8"
        else -> provider.id
    }

    /** Kullanıcı VPN iznini (sistem penceresi) vermiş mi. */
    fun isPrepared(context: Context) = try {
        VpnService.prepare(context) == null
    } catch (e: RuntimeException) {
        false
    }

    /**
     * Şifreli DNS'i başlatır. İzin yoksa false döner (önce
     * DnsPermissionActivity açılmalı). Uygulama arka plandayken Android ön
     * plan servisi başlatmaya izin vermeyebilir; o zaman IllegalStateException.
     */
    fun start(context: Context): Boolean {
        if (!isPrepared(context)) return false
        // Aynı anda tek VPN: açık WireGuard tüneli kapanır (sistem de zaten geri alırdı).
        if (WireGuardVpn.activeId != null) WireGuardVpn.disconnect(context) { }
        prefs(context).edit().putBoolean(KEY_ENABLED, true).apply()
        lastStop = null
        client.provider = provider(context)
        ContextCompat.startForegroundService(context, Intent(context, DnsVpnService::class.java))
        return true
    }

    fun stop(context: Context) {
        prefs(context).edit().putBoolean(KEY_ENABLED, false).apply()
        DnsVpnService.stopRunning("user")
        changed(context)
    }

    /** Telefon açılınca: açık bırakıldıysa ve izin duruyorsa yeniden başlar. */
    fun restoreAfterBoot(context: Context) {
        if (!enabled(context) || running) return
        try {
            if (!start(context)) Log.w(TAG, "Açılışta başlatılamadı: VPN izni yok")
        } catch (e: IllegalStateException) {
            Log.w(TAG, "Açılışta başlatılamadı", e)
        }
    }

    internal fun onStarted(context: Context) {
        running = true
        startedAt = System.currentTimeMillis()
        client.resetStats()
        // Sistem "her zaman açık VPN" ile başlattıysa ayar da açık sayılsın.
        prefs(context).edit().putBoolean(KEY_ENABLED, true).apply()
        Log.i(TAG, "Şifreli DNS açıldı: ${client.provider.id}")
        changed(context)
    }

    internal fun onStopped(context: Context, reason: String) {
        val wasRunning = running
        running = false
        lastStop = reason
        if (reason == "revoked") prefs(context).edit().putBoolean(KEY_ENABLED, false).apply()
        if (wasRunning) Log.i(TAG, "Şifreli DNS kapandı: $reason")
        changed(context)
    }

    private fun changed(context: Context) {
        try {
            TileService.requestListeningState(context, ComponentName(context, DnsTileService::class.java))
        } catch (e: RuntimeException) {
            // Kutucuk eklenmemiş olabilir.
        }
    }

    /** Başka bir uygulamanın VPN'i açık mı (ikisi aynı anda çalışamaz). */
    @Suppress("DEPRECATION") // allNetworks: Mesa'yı kapsamayan VPN'ler de görünsün.
    private fun otherVpnActive(context: Context): Boolean {
        if (running) return false
        val manager = context.getSystemService(ConnectivityManager::class.java) ?: return false
        return try {
            manager.allNetworks.any { network ->
                manager.getNetworkCapabilities(network)?.hasTransport(NetworkCapabilities.TRANSPORT_VPN) == true
            }
        } catch (e: RuntimeException) {
            false
        }
    }

    /** Sistemin "Özel DNS" ayarı: off, opportunistic ya da hostname. */
    private fun privateDnsMode(context: Context): String? = try {
        Settings.Global.getString(context.contentResolver, "private_dns_mode")
    } catch (e: RuntimeException) {
        null
    }

    fun status(context: Context): Map<String, Any?> = mapOf(
        "running" to running,
        "enabled" to enabled(context),
        "prepared" to isPrepared(context),
        "provider" to provider(context).id,
        "providers" to DohProviders.all.map { it.id },
        "queries" to client.queries.get(),
        "cacheHits" to client.cacheHits.get(),
        "failures" to client.failures.get(),
        "latencyMs" to client.averageLatencyMs,
        "since" to if (running) startedAt else 0L,
        "lastStop" to lastStop,
        "otherVpn" to otherVpnActive(context),
        "privateDns" to privateDnsMode(context),
    )
}
