package com.mesajmerkezi.mesaj_merkezi

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionSupport
import android.speech.RecognitionSupportCallback
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.util.Log
import java.io.File
import java.util.Locale

/**
 * Yalnızca geliştirme sürümünde: telefonun kendi sesiyle Türkçe bir cümle
 * sentezlenir ve [Transcriber] ile yeniden yazıya çevrilir. Kullanıcının
 * sesli mesajlarına dokunmadan tanıma motorunu cihazda denemek için.
 *
 * adb shell am broadcast -a com.mesajmerkezi.mesaj_merkezi.debug.TRANSCRIBE_PROBE -p com.mesajmerkezi.mesaj_merkezi.debug
 */
class TranscribeProbeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val text = intent.getStringExtra("text") ?: "Merhaba, bu bir deneme mesajıdır. Yarın saat üçte buluşalım."
        val lang = intent.getStringExtra("lang") ?: "tr-TR"
        val pending = goAsync()
        val app = context.applicationContext
        val main = Handler(Looper.getMainLooper())
        Log.i(TAG, "Deneme: internetsiz tanıma var mı=${SpeechRecognizer.isOnDeviceRecognitionAvailable(app)}, tanıma var mı=${SpeechRecognizer.isRecognitionAvailable(app)}")
        if (Build.VERSION.SDK_INT >= 33) logSupport(app, lang)
        val file = File(app.cacheDir, "deneme.wav")
        lateinit var tts: TextToSpeech
        tts = TextToSpeech(app) { status ->
            if (status != TextToSpeech.SUCCESS) {
                Log.w(TAG, "Deneme: ses sentezi açılamadı")
                pending.finish()
                return@TextToSpeech
            }
            tts.language = Locale.forLanguageTag(lang)
            tts.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                override fun onStart(utteranceId: String?) = Unit

                override fun onDone(utteranceId: String?) {
                    main.post {
                        Log.i(TAG, "Deneme: ses dosyası hazır (${file.length()} bayt), tanınıyor")
                        val started = System.currentTimeMillis()
                        Transcriber.transcribe(app, Uri.fromFile(file), lang) { result ->
                            Log.i(
                                TAG,
                                "Deneme sonucu: internetsiz=${result.onDevice} hata=${result.error} " +
                                    "süre=${System.currentTimeMillis() - started} ms metin=${result.text}",
                            )
                            tts.shutdown()
                            pending.finish()
                        }
                    }
                }

                @Deprecated("Deprecated in Java")
                override fun onError(utteranceId: String?) {
                    Log.w(TAG, "Deneme: ses sentezi başarısız")
                    tts.shutdown()
                    pending.finish()
                }
            })
            tts.synthesizeToFile(text, Bundle(), file, "deneme")
        }
    }

    private fun logSupport(context: Context, lang: String) {
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
            .putExtra(RecognizerIntent.EXTRA_LANGUAGE, lang)
        for (onDevice in listOf(true, false)) {
            if (onDevice && !SpeechRecognizer.isOnDeviceRecognitionAvailable(context)) continue
            val recognizer = if (onDevice) {
                SpeechRecognizer.createOnDeviceSpeechRecognizer(context)
            } else {
                SpeechRecognizer.createSpeechRecognizer(context)
            }
            recognizer.checkRecognitionSupport(intent, context.mainExecutor, object : RecognitionSupportCallback {
                override fun onSupportResult(support: RecognitionSupport) {
                    Log.i(
                        TAG,
                        "Deneme destek (internetsiz=$onDevice): yüklü=${support.installedOnDeviceLanguages} " +
                            "indiriliyor=${support.pendingOnDeviceLanguages} indirilebilir=${support.supportedOnDeviceLanguages.take(8)} " +
                            "çevrimiçi=${support.onlineLanguages.take(8)}",
                    )
                    recognizer.destroy()
                }

                override fun onError(error: Int) {
                    Log.i(TAG, "Deneme destek (internetsiz=$onDevice): hata $error")
                    recognizer.destroy()
                }
            })
        }
    }

    private companion object {
        const val TAG = "MesajMerkezi"
    }
}
