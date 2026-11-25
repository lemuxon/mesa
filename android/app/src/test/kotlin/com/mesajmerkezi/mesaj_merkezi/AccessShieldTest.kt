package com.mesajmerkezi.mesaj_merkezi

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.io.ByteArrayOutputStream

/** Erişim kalkanı: ClientHello bölme ve proxy isteği ayrıştırma. */
@RunWith(RobolectricTestRunner::class)
class AccessShieldTest {

    private fun ByteArrayOutputStream.u16(v: Int) = apply { write(v ushr 8); write(v and 0xFF) }

    /** server_name ve supported_versions uzantılı küçük bir TLS 1.3 ClientHello kaydı. */
    private fun clientHello(host: String, trailing: ByteArray = ByteArray(0)): ByteArray {
        val name = host.toByteArray(Charsets.US_ASCII)
        val extensions = ByteArrayOutputStream().apply {
            u16(0) // server_name
            u16(2 + 1 + 2 + name.size)
            u16(1 + 2 + name.size)
            write(0)
            u16(name.size)
            write(name)
            u16(43) // supported_versions
            u16(3)
            write(byteArrayOf(2, 3, 4))
        }.toByteArray()
        val body = ByteArrayOutputStream().apply {
            u16(0x0303)
            write(ByteArray(32) { it.toByte() })
            write(0) // oturum kimliği yok
            u16(2)
            u16(0x1301)
            write(1)
            write(0)
            u16(extensions.size)
            write(extensions)
        }.toByteArray()
        val handshake = ByteArrayOutputStream().apply {
            write(1)
            write(0)
            u16(body.size)
            write(body)
        }.toByteArray()
        return ByteArrayOutputStream().apply {
            write(byteArrayOf(0x16, 0x03, 0x01))
            u16(handshake.size)
            write(handshake)
            write(trailing)
        }.toByteArray()
    }

    private fun contains(haystack: ByteArray, needle: ByteArray) =
        (0..haystack.size - needle.size).any { i -> needle.indices.all { haystack[i + it] == needle[it] } }

    @Test
    fun serverNameIsFound() {
        assertEquals("discord.com", TlsSplit.hostName(clientHello("discord.com")))
        assertNull(TlsSplit.hostName("GET / HTTP/1.1\r\n\r\n".toByteArray()))
    }

    @Test
    fun clientHelloIsSplitIntoTwoValidRecordsInsideTheName() {
        val hello = clientHello("discord.com")
        val parts = TlsSplit.split(hello)
        assertEquals(2, parts.size)
        val payload = ByteArrayOutputStream()
        for (part in parts) {
            assertEquals(0x16, part[0].toInt())
            assertEquals(0x03, part[1].toInt())
            assertEquals(part.size - 5, DnsMessage.u16(part, 3))
            payload.write(part, 5, part.size - 5)
        }
        assertArrayEquals(hello.copyOfRange(5, hello.size), payload.toByteArray())
        // Ad hiçbir parçada bütün olarak görünmez.
        val name = "discord.com".toByteArray()
        assertTrue(contains(hello, name))
        assertFalse(parts.any { contains(it, name) })
    }

    @Test
    fun bytesAfterTheRecordStayInTheSecondPart() {
        val extra = byteArrayOf(0x14, 0x03, 0x03, 0x00, 0x01, 0x01)
        val parts = TlsSplit.split(clientHello("slack.com", extra))
        assertArrayEquals(extra, parts[1].copyOfRange(parts[1].size - extra.size, parts[1].size))
    }

    @Test
    fun incompleteRecordIsOnlySplitAtTcpLevel() {
        val hello = clientHello("teams.microsoft.com")
        val partial = hello.copyOf(hello.size - 3)
        val parts = TlsSplit.split(partial)
        assertEquals(2, parts.size)
        assertArrayEquals(partial, parts[0] + parts[1])
    }

    @Test
    fun otherTrafficIsNotTouched() {
        val http = "GET / HTTP/1.1\r\nHost: a\r\n\r\n".toByteArray()
        val parts = TlsSplit.split(http)
        assertEquals(1, parts.size)
        assertArrayEquals(http, parts[0])
    }

    @Test
    fun connectRequestIsParsed() {
        val request = ProxyRequest.parse(
            "CONNECT discord.com:443 HTTP/1.1\r\nHost: discord.com:443\r\nProxy-Authorization: Basic abc\r\n"
        )!!
        assertTrue(request.isConnect)
        assertEquals("discord.com", request.host)
        assertEquals(443, request.port)
        assertEquals("Basic abc", request.proxyAuthorization)

        val v6 = ProxyRequest.parse("CONNECT [2606:4700::1111]:8443 HTTP/1.1\r\n")!!
        assertEquals("2606:4700::1111", v6.host)
        assertEquals(8443, v6.port)
    }

    @Test
    fun plainHttpIsRewrittenToOriginFormWithoutProxyHeaders() {
        val request = ProxyRequest.parse(
            "GET http://example.com/a?b=1 HTTP/1.1\r\nHost: example.com\r\nProxy-Connection: keep-alive\r\n" +
                "Proxy-Authorization: Basic abc\r\nAccept: */*\r\n"
        )!!
        assertEquals(80, request.port)
        assertEquals(
            "GET /a?b=1 HTTP/1.1\r\nHost: example.com\r\nAccept: */*\r\nConnection: close\r\n\r\n",
            String(request.originRequest(), Charsets.ISO_8859_1),
        )
        assertEquals("/", ProxyRequest.parse("GET http://example.com HTTP/1.1\r\n")!!.path)
    }

    @Test
    fun invalidRequestsAreRejected() {
        assertNull(ProxyRequest.parse("GET /relative HTTP/1.1\r\n"))
        assertNull(ProxyRequest.parse("CONNECT host:99999 HTTP/1.1\r\n"))
        assertNull(ProxyRequest.parse("CONNECT user@host:443 HTTP/1.1\r\n"))
        assertNull(ProxyRequest.parse("garbage"))
    }

    @Test
    fun onlyTheShieldsOwnChallengeIsAnswered() {
        assertTrue(AccessShield.isOwnChallenge("127.0.0.1:41234", AccessShield.REALM))
        assertFalse(AccessShield.isOwnChallenge("intranet.example", AccessShield.REALM))
        assertFalse(AccessShield.isOwnChallenge("127.0.0.1", "başka"))
    }
}
