package com.mesajmerkezi.mesaj_merkezi

import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

/** Bildirim panelindeki "Odak modu" kutucuğu: kapatılana kadar aç / kapat. */
class FocusTileService : TileService() {

    override fun onStartListening() {
        super.onStartListening()
        update()
    }

    override fun onClick() {
        super.onClick()
        Focus.setManual(this, if (Focus.isActive(this)) 0L else Long.MAX_VALUE)
        update()
    }

    private fun update() {
        val tile = qsTile ?: return
        val active = Focus.isActive(this)
        tile.state = if (active) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        tile.label = Lang.str(this, R.string.focus_channel)
        if (Build.VERSION.SDK_INT >= 29) {
            tile.subtitle = if (active) Lang.str(this, R.string.focus_tile_on) else null
        }
        tile.updateTile()
    }
}
