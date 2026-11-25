package com.mesajmerkezi.mesaj_merkezi

import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.util.Log

/** Bildirim panelindeki "Şifreli DNS" kutucuğu: tek dokunuşla aç/kapat. */
class DnsTileService : TileService() {

    override fun onStartListening() {
        super.onStartListening()
        update()
    }

    override fun onClick() {
        super.onClick()
        if (SecureDns.running) {
            SecureDns.stop(this)
            update()
            return
        }
        if (SecureDns.isPrepared(this)) {
            try {
                SecureDns.start(this)
                update()
                return
            } catch (e: IllegalStateException) {
                // Android arka plandan ön plan servisi başlatmaya izin vermedi;
                // görünmez ara ekran başlatır.
                Log.i("MesaDNS", "Kutucuktan doğrudan başlatılamadı, ara ekran açılıyor")
            }
        }
        openPermissionScreen()
    }

    private fun openPermissionScreen() {
        val intent = VpnPermissionActivity.intent(this).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        if (Build.VERSION.SDK_INT >= 34) {
            startActivityAndCollapse(PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_IMMUTABLE))
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }

    private fun update() {
        val tile = qsTile ?: return
        tile.state = if (SecureDns.running) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        tile.label = Lang.str(this, R.string.dns_channel)
        if (Build.VERSION.SDK_INT >= 29) {
            tile.subtitle = if (SecureDns.running) SecureDns.label(SecureDns.provider(this)) else null
        }
        tile.updateTile()
    }
}
