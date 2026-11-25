package com.mesajmerkezi.mesaj_merkezi

import android.content.ActivityNotFoundException
import android.net.VpnService
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.result.contract.ActivityResultContracts

/**
 * Görünmez ara ekran: sistemin VPN izni penceresini ("Bağlantı isteği")
 * açar, kullanıcı onaylarsa şifreli DNS'i başlatır. Hem Mesa'nın ekranı hem
 * de hızlı ayarlar kutucuğu bunu kullanır (kutucuktan doğrudan izin
 * istenemez, servis de arka plandan başlatılamayabilir).
 */
class DnsPermissionActivity : ComponentActivity() {

    private val permission = registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
        if (result.resultCode == RESULT_OK) {
            startDns()
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
            Log.w("MesaDNS", "VPN izni istenemiyor", e)
            SecureDns.onStopped(this, "error")
            finish()
            return
        }
        if (request == null) {
            startDns()
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

    private fun startDns() {
        try {
            SecureDns.start(this)
        } catch (e: IllegalStateException) {
            Log.w("MesaDNS", "Şifreli DNS başlatılamadı", e)
            SecureDns.onStopped(this, "error")
        }
    }
}
