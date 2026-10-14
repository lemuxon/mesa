package com.mesajmerkezi.mesaj_merkezi

import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import java.util.concurrent.ConcurrentHashMap

/**
 * "Yazıyor…" ve "çevrimiçi" bilgisi (yalnızca Telegram verir; WhatsApp ve
 * Instagram bildirimlerinde bu bilgi yok). Bellekte tutulur, değişince
 * arayüze olay gönderilir.
 */
object Presence {

    /** Telegram "yazıyor" bilgisini ~5 sn'de bir yeniler; gelmezse biter. */
    private const val TYPING_MS = 6_000L

    private class Typing(val text: String, val until: Long)
    private class Online(val online: Boolean, val lastSeen: Long?)

    private val typing = ConcurrentHashMap<String, Typing>()
    private val online = ConcurrentHashMap<String, Online>()
    private val main = Handler(Looper.getMainLooper())

    /** Arayüz dinler (ana iş parçacığında çağrılır). */
    @Volatile
    var onChanged: ((Map<String, Any?>) -> Unit)? = null

    fun setTyping(key: String, text: String?) {
        if (text == null) {
            if (typing.remove(key) != null) emit(key)
            return
        }
        typing[key] = Typing(text, SystemClock.elapsedRealtime() + TYPING_MS)
        emit(key)
        main.postDelayed({
            val current = typing[key] ?: return@postDelayed
            if (current.until <= SystemClock.elapsedRealtime()) {
                typing.remove(key)
                emit(key)
            }
        }, TYPING_MS + 100)
    }

    /** [lastSeen] çevrimdışıysa son görülme (ms), bilinmiyorsa null. */
    fun setOnline(key: String, isOnline: Boolean, lastSeen: Long?) {
        val previous = online[key]
        if (previous != null && previous.online == isOnline && previous.lastSeen == lastSeen) return
        online[key] = Online(isOnline, lastSeen)
        emit(key)
    }

    fun of(key: String): Map<String, Any?> {
        val t = typing[key]?.takeIf { it.until > SystemClock.elapsedRealtime() }
        val o = online[key]
        return mapOf("key" to key, "typing" to t?.text, "online" to o?.online, "lastSeen" to o?.lastSeen)
    }

    fun all(): List<Map<String, Any?>> = (typing.keys + online.keys).toSet().map(::of)

    fun clear() {
        typing.clear()
        online.clear()
    }

    private fun emit(key: String) {
        val state = of(key)
        main.post { onChanged?.invoke(state) }
    }
}
