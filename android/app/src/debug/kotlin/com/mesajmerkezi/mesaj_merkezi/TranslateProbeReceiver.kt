package com.mesajmerkezi.mesaj_merkezi

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Yalnızca geliştirme sürümünde: sabit bir İngilizce cümle [MessageTranslator]
 * ile çevrilir (gerekirse dil paketi indirilir). Kullanıcının mesajlarına
 * dokunmadan çeviri motorunu cihazda denemek için. Mesa Dev önce açılmalı
 * (MIUI kapalı uygulamayı yayınla başlatmıyor; indirme uzun sürebilir).
 *
 * adb shell am broadcast -a com.mesajmerkezi.mesaj_merkezi.debug.TRANSLATE_PROBE -p com.mesajmerkezi.mesaj_merkezi.debug
 */
class TranslateProbeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val text = intent.getStringExtra("text") ?: "Are you coming to dinner tonight?\nI will be there at eight."
        val target = intent.getStringExtra("target") ?: "tr"
        val download = intent.getBooleanExtra("download", true)
        val started = System.currentTimeMillis()
        Log.i(TAG, "Deneme çeviri başladı (indirme=$download)")
        MessageTranslator.translateText(context, text, target, download, null) { result ->
            Log.i(TAG, "Deneme çeviri sonucu: süre=${System.currentTimeMillis() - started} ms $result")
        }
    }

    private companion object {
        const val TAG = "MesajMerkezi"
    }
}
