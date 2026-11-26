package com.mesajmerkezi.mesaj_merkezi

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.RemoteInput
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Bildirimlerin "Yanıtla" ve "Aç" yolları (PendingIntent) diske yazılamaz;
 * yalnızca bellekte duruyorlardı. Mesa'nın süreci kapanınca (Xiaomi'nin arka
 * planda kapatması) hepsi kayboluyor, yanıtlar WhatsApp ekranı açılarak
 * gidiyordu (2026-11-26: "anında gönderim").
 *
 * Çözüm: yollar Mesa'nın kendi PendingIntent'inin ek verisinde sisteme
 * bırakılır. Sistem o PendingIntent'i uzak bir tarihe kurulu bir alarm uğruna
 * tuttukça içindeki yollar da yaşar. Süreç yeniden başlayınca Mesa bu
 * PendingIntent'i kendine gönderir, ek veri [ReplyStashReceiver]'a geri döner.
 *
 * Telefon yeniden açılınca ya da Mesa güncellenince (sistem uygulamayı zorla
 * durdurur) alarm ve yollar silinir; o sohbetlere yeni mesaj gelince yeniden
 * dolar. Hiçbir şey diske ya da telefon dışına yazılmaz.
 */
internal object ReplyStash {
    private const val TAG = "MesajMerkezi"
    private const val ACTION = "com.mesajmerkezi.mesaj_merkezi.REPLY_STASH"

    /** Saklanan en fazla sohbet (en son yolu gelenler). */
    const val MAX_CHATS = 80

    /** Tutucu alarmın tarihi: hiç çalmasın diye uzak gelecek. */
    private const val HOLD_MS = 10L * 365 * 24 * 60 * 60 * 1000

    /** Saklanan bir sohbetin yolları. */
    class Entry(val reply: NotificationCompat.Action?, val open: PendingIntent?)

    private val restored = AtomicBoolean(false)

    private fun intent(context: Context) = Intent(context, ReplyStashReceiver::class.java).setAction(ACTION)

    /** Yolların listesi PendingIntent ek verisine çevrilir (yalnızca çerçeve türleri). */
    internal fun pack(entries: List<Pair<String, Entry>>): Bundle = Bundle().apply {
        val kept = entries.takeLast(MAX_CHATS)
        putInt("n", kept.size)
        kept.forEachIndexed { i, (key, entry) ->
            putString("k$i", key)
            entry.open?.let { putParcelable("o$i", it) }
            val reply = entry.reply ?: return@forEachIndexed
            val intent = reply.actionIntent ?: return@forEachIndexed
            val inputs = reply.remoteInputs?.filter { it.allowFreeFormInput }.orEmpty()
            if (inputs.isEmpty()) return@forEachIndexed
            putParcelable("a$i", intent)
            putStringArrayList("r$i", ArrayList(inputs.map { it.resultKey }))
            putCharSequence("t$i", reply.title)
        }
    }

    /** [pack]'in tersi: anahtar → yollar. */
    internal fun unpack(extras: Bundle?): List<Pair<String, Entry>> {
        extras ?: return emptyList()
        val count = extras.getInt("n", 0)
        return (0 until count).mapNotNull { i ->
            val key = extras.getString("k$i") ?: return@mapNotNull null
            @Suppress("DEPRECATION")
            val open = extras.getParcelable<PendingIntent>("o$i")
            @Suppress("DEPRECATION")
            val actionIntent = extras.getParcelable<PendingIntent>("a$i")
            val resultKeys = extras.getStringArrayList("r$i")
            val reply = if (actionIntent != null && !resultKeys.isNullOrEmpty()) {
                NotificationCompat.Action.Builder(0, extras.getCharSequence("t$i") ?: "Reply", actionIntent)
                    .apply {
                        resultKeys.forEach { addRemoteInput(RemoteInput.Builder(it).setAllowFreeFormInput(true).build()) }
                    }
                    .setSemanticAction(NotificationCompat.Action.SEMANTIC_ACTION_REPLY)
                    .build()
            } else {
                null
            }
            if (reply == null && open == null) null else key to Entry(reply, open)
        }
    }

    /**
     * Hub.io'da. Bellekteki yolların güncel kopyası sisteme bırakılır: aynı
     * PendingIntent'in ek verisi yenilenir, alarm onu tutmaya devam eder.
     */
    fun save(context: Context, entries: List<Pair<String, Entry>>) {
        try {
            val holder = PendingIntent.getBroadcast(
                context,
                0,
                intent(context).putExtras(pack(entries)),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            context.getSystemService(AlarmManager::class.java)
                ?.set(AlarmManager.RTC, System.currentTimeMillis() + HOLD_MS, holder)
        } catch (e: RuntimeException) {
            Log.w(TAG, "Yanıt yolları saklanamadı: ${e.javaClass.simpleName}")
        }
    }

    /**
     * Süreç başında bir kez: saklanan yollar varsa Mesa'ya geri gönderilir
     * ([ReplyStashReceiver] doldurur). Bu süreçte gelen taze yollar ezilmez.
     */
    fun restore(context: Context) {
        if (!restored.compareAndSet(false, true)) return
        val holder = PendingIntent.getBroadcast(
            context,
            0,
            intent(context),
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        ) ?: return
        try {
            holder.send()
        } catch (e: PendingIntent.CanceledException) {
            Log.i(TAG, "Saklanan yanıt yolları artık geçersiz")
        }
    }

    /** Testler için: süreç yeniden başlamış gibi. */
    internal fun resetForTest() {
        restored.set(false)
    }
}

/** Saklanan yanıt yollarını sistemden geri alır (yalnızca Mesa'nın kendi PendingIntent'i tetikler). */
class ReplyStashReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val entries = ReplyStash.unpack(intent.extras)
        val restored = Hub.restorePaths(entries)
        Log.i("MesajMerkezi", "Saklanan yanıt yolları geri alındı: $restored sohbet")
    }
}
