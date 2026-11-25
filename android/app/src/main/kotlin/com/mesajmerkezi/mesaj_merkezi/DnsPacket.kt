package com.mesajmerkezi.mesaj_merkezi

import com.mesajmerkezi.mesaj_merkezi.DnsMessage.put16
import com.mesajmerkezi.mesaj_merkezi.DnsMessage.u16

/**
 * Şifreli DNS tünelinden geçen IPv4/UDP paketleri. Tünele yalnızca sanal
 * DNS sunucusuna giden trafik yönlendirilir; buradan yalnızca UDP 53
 * sorguları alınır ve yanıt paketi sağlama toplamlarıyla kurulur.
 */
internal object DnsPacket {

    class Query(
        val source: ByteArray,
        val destination: ByteArray,
        val sourcePort: Int,
        val destinationPort: Int,
        val dns: ByteArray,
    )

    /** IPv4, parçalanmamış, UDP ve hedef portu 53 olan paketin sorgusu; değilse null. */
    fun parse(packet: ByteArray, length: Int): Query? {
        if (length < 28 || length > packet.size) return null
        if ((packet[0].toInt() ushr 4) and 0x0F != 4) return null
        val ihl = (packet[0].toInt() and 0x0F) * 4
        if (ihl < 20 || length < ihl + 8) return null
        val total = u16(packet, 2)
        if (total > length || total < ihl + 8) return null
        // Daha fazla parça biti ya da parça konumu: DNS sorguları parçalanmaz.
        if (u16(packet, 6) and 0x3FFF != 0) return null
        if (packet[9].toInt() and 0xFF != PROTOCOL_UDP) return null
        val destinationPort = u16(packet, ihl + 2)
        if (destinationPort != 53) return null
        val udpLength = u16(packet, ihl + 4)
        if (udpLength < 8 + 12 || ihl + udpLength > total) return null
        return Query(
            source = packet.copyOfRange(12, 16),
            destination = packet.copyOfRange(16, 20),
            sourcePort = u16(packet, ihl),
            destinationPort = destinationPort,
            dns = packet.copyOfRange(ihl + 8, ihl + udpLength),
        )
    }

    /** [query]'yi soran uygulamaya [dns] yanıtını taşıyan IPv4/UDP paketi. */
    fun response(query: Query, dns: ByteArray): ByteArray {
        val udpLength = 8 + dns.size
        val total = 20 + udpLength
        val p = ByteArray(total)
        p[0] = 0x45
        put16(p, 2, total)
        put16(p, 6, 0x4000) // parçalama yok
        p[8] = 64
        p[9] = PROTOCOL_UDP.toByte()
        query.destination.copyInto(p, 12)
        query.source.copyInto(p, 16)
        put16(p, 10, checksum(p, 0, 20, 0))
        put16(p, 20, query.destinationPort)
        put16(p, 22, query.sourcePort)
        put16(p, 24, udpLength)
        dns.copyInto(p, 28)
        put16(p, 26, udpChecksum(p, udpLength))
        return p
    }

    private fun udpChecksum(p: ByteArray, udpLength: Int): Int {
        // Sözde başlık: kaynak, hedef, protokol, UDP uzunluğu.
        var sum = 0L
        for (i in 12 until 20 step 2) sum += u16(p, i)
        sum += PROTOCOL_UDP
        sum += udpLength
        val value = checksum(p, 20, udpLength, sum)
        return if (value == 0) 0xFFFF else value
    }

    /** Birler tümleyeni sağlama toplamı ([initial] sözde başlık toplamı). */
    internal fun checksum(b: ByteArray, offset: Int, length: Int, initial: Long): Int {
        var sum = initial
        var i = offset
        val end = offset + length
        while (i + 1 < end) {
            sum += u16(b, i)
            i += 2
        }
        if (i < end) sum += (b[i].toInt() and 0xFF) shl 8
        while (sum ushr 16 != 0L) sum = (sum and 0xFFFF) + (sum ushr 16)
        return sum.inv().toInt() and 0xFFFF
    }

    private const val PROTOCOL_UDP = 17
}
