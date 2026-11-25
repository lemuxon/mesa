package com.mesajmerkezi.mesaj_merkezi

import com.mesajmerkezi.mesaj_merkezi.DnsMessage.put16
import com.mesajmerkezi.mesaj_merkezi.DnsMessage.u16

/**
 * TLS ClientHello'yu bölme. Derin paket incelemesi (DPI) bağlantının ilk
 * paketindeki sunucu adını (SNI) okuyup engeller. ClientHello, adın
 * ortasından iki ayrı TLS kaydına bölünür ve ayrı TCP parçalarında gönderilir:
 * tek pakete bakan süzgeç adı göremez; sunucu ise iki kaydı birleştirir
 * (RFC 8446 §5.1: el sıkışma iletileri kayıtlara bölünebilir). Saf Kotlin; testli.
 */
internal object TlsSplit {

    private const val HANDSHAKE = 0x16
    private const val CLIENT_HELLO = 0x01

    /**
     * Gönderilecek parçalar. [data] bir ClientHello ile başlamıyorsa olduğu
     * gibi tek parça döner.
     */
    fun split(data: ByteArray): List<ByteArray> {
        if (!isClientHello(data)) return listOf(data)
        val recordLength = u16(data, 3)
        val payloadEnd = minOf(5 + recordLength, data.size)
        val payloadSize = payloadEnd - 5
        if (payloadSize < 2) return listOf(data)
        val sni = serverName(data, 5, payloadEnd)
        // Kesim, kayıt içeriğine göre: adın ortası; ad yoksa içeriğin ortası.
        val cut = (if (sni != null) sni.first + sni.second / 2 - 5 else payloadSize / 2).coerceIn(1, payloadSize - 1)
        if (5 + recordLength > data.size) {
            // Kayıt bu okumada tamamlanmamış: yalnızca TCP düzeyinde böl.
            return listOf(data.copyOfRange(0, 5 + cut), data.copyOfRange(5 + cut, data.size))
        }
        val first = ByteArray(5 + cut)
        data.copyInto(first, 0, 0, 3)
        put16(first, 3, cut)
        data.copyInto(first, 5, 5, 5 + cut)
        val rest = data.size - (5 + recordLength)
        val second = ByteArray(5 + (payloadSize - cut) + rest)
        data.copyInto(second, 0, 0, 3)
        put16(second, 3, payloadSize - cut)
        data.copyInto(second, 5, 5 + cut, data.size)
        return listOf(first, second)
    }

    fun isClientHello(data: ByteArray) =
        data.size >= 6 &&
            data[0].toInt() and 0xFF == HANDSHAKE &&
            data[1].toInt() == 0x03 &&
            data[5].toInt() and 0xFF == CLIENT_HELLO

    /** ClientHello'daki sunucu adı (yalnızca test ve günlük için). */
    fun hostName(data: ByteArray): String? {
        if (!isClientHello(data)) return null
        val (start, length) = serverName(data, 5, minOf(5 + u16(data, 3), data.size)) ?: return null
        return String(data, start, length, Charsets.US_ASCII)
    }

    /** server_name uzantısındaki ilk host_name: (mutlak konum, uzunluk). */
    internal fun serverName(data: ByteArray, start: Int, end: Int): Pair<Int, Int>? {
        var i = start
        if (i + 4 > end || data[i].toInt() and 0xFF != CLIENT_HELLO) return null
        i += 4 + 2 + 32 // tür + uzunluk, sürüm, rastgele
        if (i + 1 > end) return null
        i += 1 + (data[i].toInt() and 0xFF) // oturum kimliği
        if (i + 2 > end) return null
        i += 2 + u16(data, i) // şifre takımları
        if (i + 1 > end) return null
        i += 1 + (data[i].toInt() and 0xFF) // sıkıştırma yöntemleri
        if (i + 2 > end) return null
        val extensionsEnd = minOf(end, i + 2 + u16(data, i))
        i += 2
        while (i + 4 <= extensionsEnd) {
            val type = u16(data, i)
            val length = u16(data, i + 2)
            i += 4
            if (type == 0) {
                // liste uzunluğu (2), ad türü (1), ad uzunluğu (2), ad
                if (i + 5 > extensionsEnd || data[i + 2].toInt() != 0) return null
                val nameLength = u16(data, i + 3)
                val nameStart = i + 5
                return if (nameStart + nameLength <= extensionsEnd) nameStart to nameLength else null
            }
            i += length
        }
        return null
    }
}

/** Yerel proxy'ye gelen istek satırı ve başlıkları (CONNECT ya da düz HTTP). */
internal class ProxyRequest(
    val method: String,
    val host: String,
    val port: Int,
    /** Düz HTTP'de yolu (ör. "/a?b=1"); CONNECT'te boş. */
    val path: String,
    val version: String,
    val proxyAuthorization: String?,
    private val headers: List<String>,
) {
    val isConnect get() = method == "CONNECT"

    /**
     * Düz HTTP isteğinin sunucuya gidecek hali: mutlak adres yerine yol,
     * proxy başlıkları çıkarılmış, bağlantı tek istekten sonra kapanır.
     */
    fun originRequest(): ByteArray {
        val out = StringBuilder("$method $path $version\r\n")
        for (header in headers) {
            val name = header.substringBefore(':').trim().lowercase()
            if (name == "proxy-authorization" || name == "proxy-connection" || name == "connection" || name == "keep-alive") continue
            out.append(header).append("\r\n")
        }
        out.append("Connection: close\r\n\r\n")
        return out.toString().toByteArray(Charsets.ISO_8859_1)
    }

    companion object {
        fun parse(head: String): ProxyRequest? {
            val lines = head.split("\r\n").filter { it.isNotEmpty() }
            val parts = lines.firstOrNull()?.split(' ') ?: return null
            if (parts.size != 3 || !parts[2].startsWith("HTTP/1.")) return null
            val method = parts[0].uppercase()
            val headers = lines.drop(1)
            val auth = headers.firstOrNull { it.substringBefore(':').trim().equals("proxy-authorization", true) }
                ?.substringAfter(':')?.trim()
            return if (method == "CONNECT") {
                val (host, port) = hostPort(parts[1], defaultPort = 443) ?: return null
                ProxyRequest(method, host, port, "", parts[2], auth, headers)
            } else {
                val target = parts[1]
                if (!target.startsWith("http://", ignoreCase = true)) return null
                val rest = target.substring(7)
                val authority = rest.substringBefore('/').substringBefore('?')
                val path = rest.substring(authority.length).ifEmpty { "/" }.let { if (it.startsWith("?")) "/$it" else it }
                val (host, port) = hostPort(authority, defaultPort = 80) ?: return null
                ProxyRequest(method, host, port, path, parts[2], auth, headers)
            }
        }

        /** "ad:port", "[v6]:port" ya da yalnızca ad. */
        private fun hostPort(authority: String, defaultPort: Int): Pair<String, Int>? {
            if (authority.isEmpty() || '@' in authority) return null
            val host: String
            val portText: String?
            if (authority.startsWith("[")) {
                val close = authority.indexOf(']')
                if (close < 0) return null
                host = authority.substring(1, close)
                portText = authority.substring(close + 1).removePrefix(":").ifEmpty { null }
            } else {
                host = authority.substringBefore(':')
                portText = if (':' in authority) authority.substringAfter(':') else null
            }
            val port = portText?.toIntOrNull() ?: if (portText == null) defaultPort else return null
            if (host.isEmpty() || port !in 1..65535) return null
            return host to port
        }
    }
}
