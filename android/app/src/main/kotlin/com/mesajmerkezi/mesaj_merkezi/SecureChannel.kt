package com.mesajmerkezi.mesaj_merkezi

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import android.provider.Settings
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** "Güvenli bağlantı" ekranının (lib/core/secure.dart) yerel tarafı. */
class SecureChannel(private val activity: Activity) {

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "mesaj_merkezi/secure").setMethodCallHandler(::onCall)
    }

    private fun onCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "status" -> result.success(
                mapOf(
                    "dns" to SecureDns.status(activity),
                    "shield" to AccessShield.status(activity),
                    "vpn" to WireGuardVpn.status(activity),
                )
            )
            "dnsStart" -> {
                // Aynı anda tek VPN: WireGuard açıksa önce kapanır.
                if (WireGuardVpn.activeId != null) {
                    WireGuardVpn.disconnect(activity) { activity.runOnUiThread { result.success(startDns()) } }
                } else {
                    result.success(startDns())
                }
            }
            "wgTunnels" -> result.success(WireGuardVpn.list(activity))
            "wgImport" -> {
                val (id, error) = WireGuardVpn.import(
                    activity,
                    call.argument<String>("name").orEmpty(),
                    call.argument<String>("text").orEmpty(),
                )
                result.success(mapOf("id" to id, "error" to error))
            }
            "wgImportUri" -> importFromUri(call.argument<String>("uri")!!, result)
            "wgConnect" -> {
                val id = call.argument<String>("id")!!
                if (SecureDns.isPrepared(activity)) {
                    WireGuardVpn.connect(activity, id) { error -> reply(result, error) }
                } else {
                    activity.startActivity(VpnPermissionActivity.intent(activity, id))
                    result.success("PERMISSION")
                }
            }
            "wgDisconnect" -> WireGuardVpn.disconnect(activity) { error -> reply(result, error) }
            "wgRemove" -> WireGuardVpn.remove(activity, call.argument<String>("id")!!) { reply(result, null) }
            "dnsStop" -> {
                SecureDns.stop(activity)
                result.success(null)
            }
            "dnsProvider" -> {
                SecureDns.setProvider(activity, call.argument<String>("id")!!)
                result.success(null)
            }
            "openVpnSettings" -> {
                try {
                    activity.startActivity(Intent(Settings.ACTION_VPN_SETTINGS))
                } catch (e: ActivityNotFoundException) {
                    activity.startActivity(Intent(Settings.ACTION_WIRELESS_SETTINGS))
                }
                result.success(null)
            }
            "shieldSet" -> {
                AccessShield.setEnabled(activity, call.argument<Boolean>("enabled") ?: false)
                result.success(null)
            }
            "tgProxies" -> TelegramClient.proxies(activity) { list -> reply(result, list) }
            "tgProxyAdd" -> TelegramClient.addProxy(
                activity,
                server = call.argument<String>("server").orEmpty(),
                port = call.argument<Int>("port") ?: 0,
                type = call.argument<String>("type").orEmpty(),
                secret = call.argument<String>("secret").orEmpty(),
                username = call.argument<String>("username").orEmpty(),
                password = call.argument<String>("password").orEmpty(),
            ) { error -> reply(result, error) }
            "tgProxyEnable" -> TelegramClient.setProxyEnabled(
                call.argument<Int>("id")!!,
                call.argument<Boolean>("enabled") ?: true,
            ) { error -> reply(result, error) }
            "tgProxyRemove" -> TelegramClient.removeProxy(call.argument<Int>("id")!!) { error -> reply(result, error) }
            "tgProxyPing" -> TelegramClient.pingProxy(activity, call.argument<Int>("id")) { ms -> reply(result, ms) }
            else -> result.notImplemented()
        }
    }

    /**
     * İzin varsa doğrudan başlatır; yoksa (ya da Android izin vermezse)
     * görünmez ara ekran sistemin VPN izni penceresini açar.
     */
    private fun startDns(): String {
        if (SecureDns.isPrepared(activity)) {
            try {
                SecureDns.start(activity)
                return "started"
            } catch (e: IllegalStateException) {
                Log.w("MesaDNS", "Doğrudan başlatılamadı", e)
            }
        }
        activity.startActivity(VpnPermissionActivity.intent(activity))
        return "permission"
    }

    /** Seçilen .conf dosyasını okuyup içe aktarır (en çok 64 KB). */
    private fun importFromUri(uri: String, result: MethodChannel.Result) {
        Thread {
            val parsed = Uri.parse(uri)
            val outcome = try {
                val name = activity.contentResolver.query(parsed, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
                    ?.use { c -> if (c.moveToFirst()) c.getString(0) else null }
                    .orEmpty()
                val text = activity.contentResolver.openInputStream(parsed)?.use { input ->
                    val bytes = input.readNBytesCompat(64 * 1024 + 1)
                    if (bytes.size > 64 * 1024) null else String(bytes, Charsets.UTF_8)
                }
                if (text == null) {
                    mapOf("id" to null, "error" to "TOO_LARGE")
                } else {
                    val (id, error) = WireGuardVpn.import(activity, name, text)
                    mapOf("id" to id, "error" to error)
                }
            } catch (e: Exception) {
                Log.w("MesaVPN", "Yapılandırma dosyası okunamadı: ${e.javaClass.simpleName}")
                mapOf("id" to null, "error" to "READ")
            }
            reply(result, outcome)
        }.start()
    }

    /** InputStream.readNBytes API 33'te geldi; en çok [limit] bayt okur. */
    private fun java.io.InputStream.readNBytesCompat(limit: Int): ByteArray {
        val out = java.io.ByteArrayOutputStream()
        val buffer = ByteArray(8192)
        while (out.size() < limit) {
            val n = read(buffer, 0, minOf(buffer.size, limit - out.size()))
            if (n < 0) break
            out.write(buffer, 0, n)
        }
        return out.toByteArray()
    }

    /** TDLib yanıtları kendi iş parçacığında gelir; Flutter'a ana iş parçacığından. */
    private fun reply(result: MethodChannel.Result, value: Any?) {
        activity.runOnUiThread { result.success(value) }
    }
}
