package com.mesajmerkezi.mesaj_merkezi

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
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
                )
            )
            "dnsStart" -> result.success(startDns())
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
        activity.startActivity(Intent(activity, DnsPermissionActivity::class.java))
        return "permission"
    }

    /** TDLib yanıtları kendi iş parçacığında gelir; Flutter'a ana iş parçacığından. */
    private fun reply(result: MethodChannel.Result, value: Any?) {
        activity.runOnUiThread { result.success(value) }
    }
}
