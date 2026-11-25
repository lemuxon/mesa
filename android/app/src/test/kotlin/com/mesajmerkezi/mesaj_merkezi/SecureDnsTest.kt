package com.mesajmerkezi.mesaj_merkezi

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.net.InetAddress

/** Şifreli DNS: DNS iletisi, tünel paketleri ve DoH istemcisi. */
@RunWith(RobolectricTestRunner::class)
class SecureDnsTest {

    /** [query]'ye A kayıtlı yanıt (ad, sorudaki ada işaretçi). */
    private fun answer(query: ByteArray, vararg records: Pair<String, Int>, rcode: Int = 0): ByteArray {
        val out = ByteArrayOutputStream()
        out.write(query)
        val bytes = out.toByteArray()
        bytes[2] = (0x80 or (bytes[2].toInt() and 0x01)).toByte()
        bytes[3] = (0x80 or rcode).toByte()
        DnsMessage.put16(bytes, 6, records.size)
        val full = ByteArrayOutputStream().apply { write(bytes) }
        for ((ip, ttl) in records) {
            val address = InetAddress.getByName(ip).address
            full.write(byteArrayOf(0xC0.toByte(), 0x0C))
            full.write(byteArrayOf(0, if (address.size == 4) 1 else 28, 0, 1))
            full.write(byteArrayOf((ttl ushr 24).toByte(), (ttl ushr 16).toByte(), (ttl ushr 8).toByte(), ttl.toByte()))
            full.write(byteArrayOf(0, address.size.toByte()))
            full.write(address)
        }
        return full.toByteArray()
    }

    @Test
    fun queryAndQuestionKeyIgnoreCase() {
        val query = DnsMessage.query(0x1234, "Example.COM", DnsMessage.TYPE_A)
        assertEquals(0x1234, DnsMessage.id(query))
        assertEquals("example.com./1/1", DnsMessage.questionKey(query))
        assertEquals(
            DnsMessage.questionKey(query),
            DnsMessage.questionKey(DnsMessage.query(7, "example.com.", DnsMessage.TYPE_A)),
        )
    }

    @Test
    fun answerTtlAndAddressesAreRead() {
        val query = DnsMessage.query(1, "mesa.example", DnsMessage.TYPE_A)
        val response = answer(query, "93.184.216.34" to 120, "93.184.216.35" to 60)
        assertEquals(60, DnsMessage.cacheSeconds(response))
        assertEquals(
            listOf("93.184.216.34", "93.184.216.35"),
            DnsMessage.addresses(response).map { it.hostAddress },
        )
    }

    @Test
    fun servfailKeepsIdAndQuestion() {
        val query = DnsMessage.query(0xBEEF, "blocked.example", DnsMessage.TYPE_AAAA)
        val fail = DnsMessage.servfail(query)
        assertEquals(0xBEEF, DnsMessage.id(fail))
        assertEquals(2, DnsMessage.rcode(fail))
        assertEquals(DnsMessage.questionKey(query), DnsMessage.questionKey(fail))
        assertEquals(query.size, fail.size)
    }

    /** Tünele gelen IPv4/UDP sorgu paketi. */
    private fun udpPacket(dns: ByteArray, port: Int = 53): ByteArray {
        val p = ByteArray(28 + dns.size)
        p[0] = 0x45
        DnsMessage.put16(p, 2, p.size)
        p[8] = 64
        p[9] = 17
        byteArrayOf(10, 111, 222.toByte(), 1).copyInto(p, 12)
        byteArrayOf(10, 111, 222.toByte(), 2).copyInto(p, 16)
        DnsMessage.put16(p, 20, 40_000)
        DnsMessage.put16(p, 22, port)
        DnsMessage.put16(p, 24, 8 + dns.size)
        dns.copyInto(p, 28)
        return p
    }

    @Test
    fun tunnelPacketRoundTripHasValidChecksums() {
        val dns = DnsMessage.query(9, "mesa.example", DnsMessage.TYPE_A)
        val parsed = DnsPacket.parse(udpPacket(dns), 28 + dns.size)
        assertNotNull(parsed)
        assertArrayEquals(dns, parsed!!.dns)
        assertEquals(40_000, parsed.sourcePort)

        val reply = answer(dns, "1.2.3.4" to 30)
        val packet = DnsPacket.response(parsed, reply)
        // IPv4 başlığının toplamı 0 çıkmalı (sağlama toplamı dahil).
        assertEquals(0, DnsPacket.checksum(packet, 0, 20, 0))
        // Kaynak/hedef ve portlar ters çevrilmiş.
        assertArrayEquals(byteArrayOf(10, 111, 222.toByte(), 2), packet.copyOfRange(12, 16))
        assertEquals(40_000, DnsMessage.u16(packet, 22))
        // UDP sağlama toplamı sözde başlıkla doğrulanır.
        var pseudo = 0L
        for (i in 12 until 20 step 2) pseudo += DnsMessage.u16(packet, i)
        pseudo += 17 + (packet.size - 20)
        assertEquals(0, DnsPacket.checksum(packet, 20, packet.size - 20, pseudo))
        assertArrayEquals(reply, packet.copyOfRange(28, packet.size))
    }

    @Test
    fun nonDnsTrafficIsIgnored() {
        val dns = DnsMessage.query(9, "mesa.example", DnsMessage.TYPE_A)
        assertNull(DnsPacket.parse(udpPacket(dns, port = 443), 28 + dns.size))
        val ipv6 = udpPacket(dns).also { it[0] = 0x60 }
        assertNull(DnsPacket.parse(ipv6, ipv6.size))
    }

    @Test
    fun responsesAreCachedForTheirTtlWithTheCallersId() {
        var calls = 0
        var clock = 0L
        val client = DohClient(transport = { _, body ->
            calls++
            answer(body, "1.2.3.4" to 30)
        }, now = { clock })
        val first = client.resolve(DnsMessage.query(11, "mesa.example", DnsMessage.TYPE_A))
        val second = client.resolve(DnsMessage.query(22, "MESA.example", DnsMessage.TYPE_A))
        assertEquals(1, calls)
        assertEquals(11, DnsMessage.id(first))
        assertEquals(22, DnsMessage.id(second))
        assertEquals(1, client.cacheHits.get())
        clock += 31_000
        client.resolve(DnsMessage.query(33, "mesa.example", DnsMessage.TYPE_A))
        assertEquals(2, calls)
    }

    @Test
    fun nextAddressIsTriedAndAllFailingGivesServfail() {
        val tried = mutableListOf<String>()
        val client = DohClient(transport = { url, body ->
            tried += url
            if (url.contains("1.1.1.1")) answer(body, "5.6.7.8" to 60) else throw IOException("engelli")
        }, now = { 0L })
        val ok = client.resolve(DnsMessage.query(1, "a.example", DnsMessage.TYPE_A))
        assertEquals(0, DnsMessage.rcode(ok))
        assertEquals(listOf("https://cloudflare-dns.com/dns-query", "https://1.1.1.1/dns-query"), tried)
        // Sonraki sorgu çalışan adresten başlar.
        tried.clear()
        client.resolve(DnsMessage.query(2, "b.example", DnsMessage.TYPE_A))
        assertEquals(listOf("https://1.1.1.1/dns-query"), tried)

        val down = DohClient(transport = { _, _ -> throw IOException("ağ yok") }, now = { 0L })
        val fail = down.resolve(DnsMessage.query(3, "c.example", DnsMessage.TYPE_A))
        assertEquals(2, DnsMessage.rcode(fail))
        assertEquals(1, down.failures.get())
    }

    @Test
    fun lookupUsesDohAndLiteralsSkipDns() {
        var calls = 0
        val client = DohClient(transport = { _, body ->
            calls++
            val type = DnsMessage.u16(body, body.size - 4)
            if (type == DnsMessage.TYPE_A) answer(body, "9.8.7.6" to 60) else answer(body)
        }, now = { 0L })
        assertEquals(listOf("9.8.7.6"), client.lookup("discord.com").map { it.hostAddress })
        assertEquals(2, calls)
        assertEquals(listOf("1.2.3.4"), client.lookup("1.2.3.4").map { it.hostAddress })
        assertEquals(2, calls)
    }

    @Test
    fun switchingProviderClearsCache() {
        var calls = 0
        val client = DohClient(transport = { _, body -> calls++; answer(body, "1.1.1.1" to 300) }, now = { 0L })
        client.resolve(DnsMessage.query(1, "x.example", DnsMessage.TYPE_A))
        client.provider = DohProviders.byId("adguard")
        client.resolve(DnsMessage.query(2, "x.example", DnsMessage.TYPE_A))
        assertEquals(2, calls)
        assertEquals("cloudflare", DohProviders.byId("bilinmeyen").id)
    }
}
