package com.mesajmerkezi.mesaj_merkezi

import android.os.SystemClock
import android.util.Log
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.net.HttpURLConnection
import java.net.InetAddress
import java.net.URL
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong

/**
 * Şifreli DNS sağlayıcısı: birincil adres alan adıyla, yedekleri IP ile
 * (operatör sağlayıcının alan adını engellerse ya da çözemezse). [plain]:
 * aynı sağlayıcının düz DNS adresleri (DNS satırı olmayan WireGuard
 * yapılandırmasına eklenir).
 */
internal class DohProvider(val id: String, val urls: List<String>, val plain: List<String>)

internal object DohProviders {
    val all = listOf(
        DohProvider("cloudflare", listOf("https://cloudflare-dns.com/dns-query", "https://1.1.1.1/dns-query", "https://1.0.0.1/dns-query"), listOf("1.1.1.1", "1.0.0.1")),
        DohProvider("cloudflare_security", listOf("https://security.cloudflare-dns.com/dns-query", "https://1.1.1.2/dns-query", "https://1.0.0.2/dns-query"), listOf("1.1.1.2", "1.0.0.2")),
        DohProvider("cloudflare_family", listOf("https://family.cloudflare-dns.com/dns-query", "https://1.1.1.3/dns-query", "https://1.0.0.3/dns-query"), listOf("1.1.1.3", "1.0.0.3")),
        DohProvider("adguard", listOf("https://dns.adguard-dns.com/dns-query", "https://94.140.14.14/dns-query", "https://94.140.15.15/dns-query"), listOf("94.140.14.14", "94.140.15.15")),
        DohProvider("quad9", listOf("https://dns.quad9.net/dns-query", "https://9.9.9.9/dns-query", "https://149.112.112.112/dns-query"), listOf("9.9.9.9", "149.112.112.112")),
        DohProvider("google", listOf("https://dns.google/dns-query", "https://8.8.8.8/dns-query", "https://8.8.4.4/dns-query"), listOf("8.8.8.8", "8.8.4.4")),
    )

    val default = all.first()

    fun byId(id: String?) = all.firstOrNull { it.id == id } ?: default
}

/**
 * DNS-over-HTTPS (RFC 8484) istemcisi. Hem bütün telefonun şifreli DNS'i
 * (DnsVpnService) hem de web servislerinin erişim kalkanı (AccessShield)
 * bunu kullanır. Yanıtlar TTL'leri kadar (en çok 5 dk) önbellekte kalır;
 * bir adres yanıt vermezse sağlayıcının sıradaki adresi denenir.
 */
internal class DohClient(
    private val transport: (url: String, body: ByteArray) -> ByteArray = ::post,
    private val now: () -> Long = SystemClock::elapsedRealtime,
) {
    @Volatile
    var provider: DohProvider = DohProviders.default
        set(value) {
            if (field.id != value.id) {
                synchronized(cache) { cache.clear() }
                preferred.set(0)
            }
            field = value
        }

    private class Entry(val response: ByteArray, val expiresAt: Long)

    private val cache = object : LinkedHashMap<String, Entry>(64, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, Entry>) = size > MAX_ENTRIES
    }

    /** Son başarılı adresin sırası: bir sonraki sorgu ondan başlar. */
    private val preferred = AtomicInteger(0)
    private val ids = AtomicInteger(1)

    val queries = AtomicLong()
    val cacheHits = AtomicLong()
    val failures = AtomicLong()
    private val answered = AtomicLong()
    private val latencyTotal = AtomicLong()

    /** Ağdan gelen yanıtların ortalama süresi (ms); henüz yoksa 0. */
    val averageLatencyMs: Long
        get() = answered.get().let { if (it == 0L) 0 else latencyTotal.get() / it }

    fun resetStats() {
        queries.set(0)
        cacheHits.set(0)
        failures.set(0)
        answered.set(0)
        latencyTotal.set(0)
    }

    /** [query] DNS iletisinin yanıtı; hiçbir adres yanıt vermezse SERVFAIL. */
    fun resolve(query: ByteArray): ByteArray {
        queries.incrementAndGet()
        val id = DnsMessage.id(query)
        val key = DnsMessage.questionKey(query)
        if (key != null) {
            synchronized(cache) {
                val hit = cache[key]
                if (hit != null && hit.expiresAt > now()) {
                    cacheHits.incrementAndGet()
                    return DnsMessage.withId(hit.response, id)
                }
            }
        }
        // RFC 8484: kimlik 0 gönderilir (ara önbellekler aynı soruyu tanısın).
        val wire = DnsMessage.withId(query, 0)
        val urls = provider.urls
        val start = preferred.get().coerceIn(0, urls.size - 1)
        for (n in urls.indices) {
            val index = (start + n) % urls.size
            val began = now()
            val response = try {
                transport(urls[index], wire)
            } catch (e: IOException) {
                Log.i(TAG, "DoH adresi yanıt vermedi (${index + 1}/${urls.size}): ${e.javaClass.simpleName}")
                continue
            }
            if (response.size < 12) continue
            latencyTotal.addAndGet(now() - began)
            answered.incrementAndGet()
            preferred.set(index)
            if (key != null) {
                val seconds = DnsMessage.cacheSeconds(response)?.coerceIn(0, MAX_CACHE_SECONDS)
                if (seconds != null && seconds > 0) {
                    synchronized(cache) { cache[key] = Entry(response, now() + seconds * 1000L) }
                }
            }
            return DnsMessage.withId(response, id)
        }
        failures.incrementAndGet()
        return DnsMessage.servfail(query)
    }

    /**
     * [host]'un adresleri, şifreli DNS ile (IPv4 önce). Sağlayıcıya
     * ulaşılamazsa telefonun normal DNS'ine düşülür: sayfa hiç açılmamaktansa
     * engelsiz yollardan açılsın.
     */
    fun lookup(host: String): List<InetAddress> {
        literal(host)?.let { return listOf(it) }
        val out = ArrayList<InetAddress>()
        for (type in intArrayOf(DnsMessage.TYPE_A, DnsMessage.TYPE_AAAA)) {
            val query = try {
                DnsMessage.query(ids.getAndIncrement() and 0xFFFF, host, type)
            } catch (e: IllegalArgumentException) {
                return emptyList()
            }
            val response = resolve(query)
            if (DnsMessage.rcode(response) == 3) return emptyList() // alan adı yok
            out += DnsMessage.addresses(response)
        }
        if (out.isNotEmpty()) return out
        return try {
            InetAddress.getAllByName(host).toList()
        } catch (e: IOException) {
            emptyList()
        }
    }

    companion object {
        private const val TAG = "MesaDNS"
        private const val MAX_ENTRIES = 500
        private const val MAX_CACHE_SECONDS = 300
        private const val TIMEOUT_MS = 5_000

        /** IP adresi yazılmışsa onu döner (ad çözülmez). */
        internal fun literal(host: String): InetAddress? {
            val h = host.removePrefix("[").removeSuffix("]")
            val ipv4 = Regex("""\d{1,3}(\.\d{1,3}){3}""")
            return if (h.matches(ipv4) || (':' in h && h.all { it.isLetterOrDigit() || it == ':' || it == '.' })) {
                try {
                    InetAddress.getByName(h)
                } catch (e: IOException) {
                    null
                }
            } else {
                null
            }
        }

        /** Bağlantı kapatılmaz: akış sonuna kadar okununca keep-alive havuzuna döner. */
        private fun post(url: String, body: ByteArray): ByteArray {
            val connection = URL(url).openConnection() as HttpURLConnection
            connection.requestMethod = "POST"
            connection.connectTimeout = TIMEOUT_MS
            connection.readTimeout = TIMEOUT_MS
            connection.doOutput = true
            connection.useCaches = false
            connection.setRequestProperty("Content-Type", "application/dns-message")
            connection.setRequestProperty("Accept", "application/dns-message")
            connection.setFixedLengthStreamingMode(body.size)
            connection.outputStream.use { it.write(body) }
            if (connection.responseCode != 200) {
                connection.disconnect()
                throw IOException("HTTP ${connection.responseCode}")
            }
            return connection.inputStream.use { input ->
                val out = ByteArrayOutputStream(512)
                val buffer = ByteArray(4096)
                while (true) {
                    val n = input.read(buffer)
                    if (n < 0) break
                    out.write(buffer, 0, n)
                    if (out.size() > 65_535) throw IOException("yanıt çok büyük")
                }
                out.toByteArray()
            }
        }
    }
}
