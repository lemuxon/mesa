package com.mesajmerkezi.mesaj_merkezi

import android.content.Context
import android.content.Intent
import android.media.AudioFormat
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import java.io.ByteArrayOutputStream
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.Locale
import kotlin.concurrent.thread

/**
 * Sesli mesajı yazıya çevirir: ses dosyası (WhatsApp/Telegram opus, wav…)
 * çözülüp 16 kHz tek kanal PCM'e indirilir ve Android'in konuşma tanıma
 * servisine dosyadan verilir (Android 13+, EXTRA_AUDIO_SOURCE). Mikrofon
 * kullanılmaz. Telefonda internetsiz tanıma varsa o kullanılır.
 */
object Transcriber {
    private const val TAG = "MesajMerkezi"
    private const val RATE = 16_000

    /** Sonuç: metin ya da hata kodu (NO_SPEECH, UNSUPPORTED, DECODE, BUSY, ERROR_n). */
    data class Result(val text: String?, val error: String?, val onDevice: Boolean)

    val isSupported get() = Build.VERSION.SDK_INT >= 33

    @Volatile
    private var busy = false

    /**
     * [source] çözülür ve tanınır; [done] ana iş parçacığında çağrılır.
     * Aynı anda tek tanıma yürür.
     */
    fun transcribe(context: Context, source: Uri, language: String = Locale.getDefault().toLanguageTag(), done: (Result) -> Unit) {
        val main = Handler(Looper.getMainLooper())
        if (!isSupported) return done(Result(null, "UNSUPPORTED", false))
        if (busy) return done(Result(null, "BUSY", false))
        busy = true
        val app = context.applicationContext
        thread(name = "ses-cozucu") {
            val pcm = try {
                decodeToPcm16k(app, source)
            } catch (e: Exception) {
                Log.w(TAG, "Ses çözülemedi: ${e.javaClass.simpleName}")
                null
            }
            main.post {
                if (pcm == null || pcm.isEmpty()) {
                    busy = false
                    done(Result(null, "DECODE", false))
                } else {
                    recognize(app, pcm, language) { result ->
                        busy = false
                        done(result)
                    }
                }
            }
        }
    }

    /** Ana iş parçacığında: PCM bir boru üzerinden tanıyıcıya akıtılır. */
    private fun recognize(context: Context, pcm: ByteArray, language: String, done: (Result) -> Unit) {
        val onDevice = SpeechRecognizer.isOnDeviceRecognitionAvailable(context)
        val recognizer = try {
            if (onDevice) {
                SpeechRecognizer.createOnDeviceSpeechRecognizer(context)
            } else {
                SpeechRecognizer.createSpeechRecognizer(context)
            }
        } catch (e: RuntimeException) {
            return done(Result(null, "UNSUPPORTED", onDevice))
        }
        val pipe = ParcelFileDescriptor.createPipe()
        val segments = StringBuilder()
        var finished = false
        fun finish(result: Result) {
            if (finished) return
            finished = true
            try {
                recognizer.destroy()
            } catch (e: RuntimeException) {
                // Zaten kapandı.
            }
            runCatching { pipe[0].close() }
            done(result)
        }
        fun addText(bundle: Bundle?) {
            val best = bundle?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()?.trim()
            if (!best.isNullOrEmpty()) {
                if (segments.isNotEmpty()) segments.append(' ')
                segments.append(best)
            }
        }
        fun textOrNoSpeech() = segments.toString().trim().takeIf { it.isNotEmpty() }
            ?.let { Result(it, null, onDevice) }
            ?: Result(null, "NO_SPEECH", onDevice)
        recognizer.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) = Unit
            override fun onBeginningOfSpeech() = Unit
            override fun onRmsChanged(rmsdB: Float) = Unit
            override fun onBufferReceived(buffer: ByteArray?) = Unit
            override fun onEndOfSpeech() = Unit
            override fun onPartialResults(partialResults: Bundle?) = Unit
            override fun onEvent(eventType: Int, params: Bundle?) = Unit

            override fun onSegmentResults(segmentResults: Bundle) {
                addText(segmentResults)
            }

            override fun onEndOfSegmentedSession() {
                finish(textOrNoSpeech())
            }

            override fun onResults(results: Bundle?) {
                addText(results)
                finish(textOrNoSpeech())
            }

            override fun onError(error: Int) {
                // Konuşma bitti ama hiç bölüm gelmediyse "konuşma yok"; bölüm geldiyse onlar yeterli.
                if (segments.isNotEmpty()) {
                    finish(textOrNoSpeech())
                } else {
                    val code = when (error) {
                        SpeechRecognizer.ERROR_NO_MATCH, SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "NO_SPEECH"
                        SpeechRecognizer.ERROR_LANGUAGE_NOT_SUPPORTED, SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE -> {
                            requestLanguagePack(context, language)
                            "LANGUAGE"
                        }
                        SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "PERMISSION"
                        SpeechRecognizer.ERROR_NETWORK, SpeechRecognizer.ERROR_NETWORK_TIMEOUT,
                        SpeechRecognizer.ERROR_SERVER, SpeechRecognizer.ERROR_SERVER_DISCONNECTED -> "OFFLINE"
                        else -> "ERROR_$error"
                    }
                    finish(Result(null, code, onDevice))
                }
            }
        })
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, language)
            putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
            putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE, pipe[0])
            putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE_CHANNEL_COUNT, 1)
            putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE_ENCODING, AudioFormat.ENCODING_PCM_16BIT)
            putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE_SAMPLING_RATE, RATE)
            // Uzun mesaj ilk duraklamada kesilmesin: oturum ses bitince biter.
            putExtra(RecognizerIntent.EXTRA_SEGMENTED_SESSION, RecognizerIntent.EXTRA_AUDIO_SOURCE)
        }
        try {
            recognizer.startListening(intent)
        } catch (e: RuntimeException) {
            return finish(Result(null, "UNSUPPORTED", onDevice))
        }
        // Ses, gerçek zamandan hızlı ama tanıyıcıyı boğmadan boruya yazılır.
        thread(name = "ses-akisi") {
            try {
                FileOutputStream(pipe[1].fileDescriptor).use { out ->
                    var offset = 0
                    val chunk = RATE * 2 / 10 // 100 ms
                    while (offset < pcm.size) {
                        val n = minOf(chunk, pcm.size - offset)
                        out.write(pcm, offset, n)
                        offset += n
                        Thread.sleep(20)
                    }
                }
            } catch (e: Exception) {
                Log.w(TAG, "Ses tanıyıcıya aktarılamadı: ${e.javaClass.simpleName}")
            } finally {
                runCatching { pipe[1].close() }
            }
        }
        // Tanıyıcı hiç yanıt vermezse takılı kalınmasın.
        val seconds = pcm.size / (RATE * 2)
        Handler(Looper.getMainLooper()).postDelayed({ finish(textOrNoSpeech()) }, (seconds * 3_000L) + 20_000L)
    }

    /** İnternetsiz tanıma paketi yoksa telefonun indirmesi istenir (Android 13+). */
    private fun requestLanguagePack(context: Context, language: String) {
        if (!SpeechRecognizer.isOnDeviceRecognitionAvailable(context)) return
        try {
            val recognizer = SpeechRecognizer.createOnDeviceSpeechRecognizer(context)
            recognizer.triggerModelDownload(
                Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).putExtra(RecognizerIntent.EXTRA_LANGUAGE, language),
            )
            recognizer.destroy()
        } catch (e: RuntimeException) {
            Log.w(TAG, "Dil paketi indirilemedi: ${e.javaClass.simpleName}")
        }
    }

    /** Herhangi bir ses dosyası → 16 kHz, tek kanal, 16 bit PCM (küçük uçlu). */
    internal fun decodeToPcm16k(context: Context, source: Uri): ByteArray {
        val extractor = MediaExtractor()
        // Dosya, çözme bitene kadar açık kalmalı.
        val fd = context.contentResolver.openFileDescriptor(source, "r")!!
        try {
            extractor.setDataSource(fd.fileDescriptor)
            val track = (0 until extractor.trackCount).first {
                extractor.getTrackFormat(it).getString(MediaFormat.KEY_MIME)?.startsWith("audio/") == true
            }
            extractor.selectTrack(track)
            val format = extractor.getTrackFormat(track)
            val codec = MediaCodec.createDecoderByType(format.getString(MediaFormat.KEY_MIME)!!)
            codec.configure(format, null, null, 0)
            codec.start()
            var rate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
            var channels = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
            val out = ByteArrayOutputStream()
            val info = MediaCodec.BufferInfo()
            var inputDone = false
            var outputDone = false
            while (!outputDone) {
                if (!inputDone) {
                    val inIndex = codec.dequeueInputBuffer(10_000)
                    if (inIndex >= 0) {
                        val buffer = codec.getInputBuffer(inIndex)!!
                        val size = extractor.readSampleData(buffer, 0)
                        if (size < 0) {
                            codec.queueInputBuffer(inIndex, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                            inputDone = true
                        } else {
                            codec.queueInputBuffer(inIndex, 0, size, extractor.sampleTime, 0)
                            extractor.advance()
                        }
                    }
                }
                val outIndex = codec.dequeueOutputBuffer(info, 10_000)
                when {
                    outIndex >= 0 -> {
                        val buffer = codec.getOutputBuffer(outIndex)!!
                        if (info.size > 0) {
                            val bytes = ByteArray(info.size)
                            buffer.position(info.offset)
                            buffer.get(bytes, 0, info.size)
                            out.write(bytes)
                        }
                        codec.releaseOutputBuffer(outIndex, false)
                        if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) outputDone = true
                    }
                    outIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                        rate = codec.outputFormat.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                        channels = codec.outputFormat.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                    }
                }
            }
            codec.stop()
            codec.release()
            return resampleTo16kMono(out.toByteArray(), rate, channels)
        } finally {
            extractor.release()
            fd.close()
        }
    }

    /** 16 bit PCM: kanallar birleştirilir, örnekleme 16 kHz'e indirilir (doğrusal ara değer). */
    internal fun resampleTo16kMono(pcm: ByteArray, rate: Int, channels: Int): ByteArray {
        val samples = ByteBuffer.wrap(pcm).order(ByteOrder.LITTLE_ENDIAN).asShortBuffer()
        val frames = samples.remaining() / channels
        val mono = FloatArray(frames) { i ->
            var sum = 0f
            for (c in 0 until channels) sum += samples.get(i * channels + c)
            sum / channels
        }
        if (rate == RATE) return toBytes(mono)
        val ratio = rate.toDouble() / RATE
        val outFrames = (frames / ratio).toInt()
        val result = FloatArray(outFrames)
        for (i in 0 until outFrames) {
            val pos = i * ratio
            val left = pos.toInt().coerceAtMost(frames - 1)
            val right = (left + 1).coerceAtMost(frames - 1)
            val frac = (pos - left).toFloat()
            // Örnek seyreltilmeden önce yan yana örneklerin ortalaması: kaba alçak geçiren süzgeç.
            val span = ratio.toInt().coerceAtLeast(1)
            var avg = 0f
            var count = 0
            for (k in 0 until span) {
                val idx = left + k
                if (idx < frames) {
                    avg += mono[idx]
                    count++
                }
            }
            avg /= count.coerceAtLeast(1)
            result[i] = if (span > 1) avg else mono[left] * (1 - frac) + mono[right] * frac
        }
        return toBytes(result)
    }

    private fun toBytes(samples: FloatArray): ByteArray {
        val buffer = ByteBuffer.allocate(samples.size * 2).order(ByteOrder.LITTLE_ENDIAN)
        for (s in samples) buffer.putShort(s.toInt().coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt()).toShort())
        return buffer.array()
    }
}
