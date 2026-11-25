package com.mesajmerkezi.mesaj_merkezi

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.result.contract.ActivityResultContracts

/**
 * Görünmez ara ekran: sistemin VPN izni penceresini ("Bağlantı isteği")
 * açar, kullanıcı onaylarsa istenen VPN'i başlatır: şifreli DNS ya da bir
 * WireGuard tüneli. Mesa'nın ekranı da hızlı ayarlar kutucuğu da bunu
 * kullanır (kutucuktan doğrudan izin istenemez, servis de arka plandan
 * başlatılamayabilir).
 */
class VpnPermissionActivity : ComponentActivity() {

    private val permission = registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
        if (result.resultCode == RESULT_OK) {
            startTarget()
        } else {
            SecureDns.onStopped(this, "permission")
        }
        finish()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (savedInstanceState != null) return // izin penceresi zaten açık
        val request = try {
            VpnService.prepare(this)
        } catch (e: RuntimeException) {
            Log.w(TAG, "VPN izni istenemiyor", e)
            SecureDns.onStopped(this, "error")
            finish()
            return
        }
        if (request == null) {
            startTarget()
            finish()
            return
        }
        try {
            permission.launch(request)
        } catch (e: ActivityNotFoundException) {
            SecureDns.onStopped(this, "error")
            finish()
        }
    }

    private fun startTarget() {
        val tunnel = intent.getStringExtra(EXTRA_TUNNEL)
        if (tunnel != null) {
            WireGuardVpn.connect(this, tunnel) { error -> if (error != null) Log.w(TAG, "Tünel açılamadı: $error") }
            return
        }
        try {
            SecureDns.start(this)
        } catch (e: IllegalStateException) {
            Log.w(TAG, "Şifreli DNS başlatılamadı", e)
            SecureDns.onStopped(this, "error")
        }
    }

    companion object {
        private const val TAG = "MesaDNS"
        private const val EXTRA_TUNNEL = "wireguard_tunnel"

        /** Şifreli DNS için (tunnel null) ya da bir WireGuard tüneli için. */
        fun intent(context: Context, tunnel: String? = null): Intent =
            Intent(context, VpnPermissionActivity::class.java).apply {
                if (tunnel != null) putExtra(EXTRA_TUNNEL, tunnel)
            }
    }
}
