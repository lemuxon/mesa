package com.mesajmerkezi.mesaj_merkezi

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.json.JSONArray
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.io.ByteArrayOutputStream
import java.net.InetAddress
import java.security.KeyStore
import java.util.concurrent.Callable
import javax.crypto.KeyGenerator
import javax.net.ssl.SSLContext
import javax.net.ssl.SSLSocket
import javax.net.ssl.TrustManagerFactory

/** Bilgisayardan Mesa: sertifika, şifreli bağlantı, eşleştirme ve yetki. */
@RunWith(RobolectricTestRunner::class)
class DesktopTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private lateinit var identity: DesktopCert.Identity
    private var server: DesktopServer? = null
    private var port = 0

    @Before
    fun setUp() {
        SecretBox.keyForTests = KeyGenerator.getInstance("AES").apply { init(256) }.generateKey()
        context.getSharedPreferences("desktop", Context.MODE_PRIVATE).edit().clear().commit()
        Hub.io.submit(Callable { Hub.closeStore() }).get()
        context.deleteDatabase("mesajlar.db")
        Desktop.pairings.clear()
        Desktop.lastPairing.clear()
        identity = DesktopCert.create()
    }

    @After
    fun tearDown() {
        server?.stop()
        Hub.io.submit(Callable { Hub.closeStore() }).get()
        context.deleteDatabase("mesajlar.db")
        SecretBox.keyForTests = null
    }

    @Test
    fun certificateIsSelfSignedForTls() {
        val cert = identity.certificate
        cert.checkValidity()
        cert.verify(cert.publicKey)
        assertEquals("SHA256withECDSA", cert.sigAlgName)
        assertTrue(cert.subjectX500Principal.name.contains("CN=Mesa"))
        assertEquals(-1, cert.basicConstraints)
        assertTrue(cert.extendedKeyUsage.contains("1.3.6.1.5.5.7.3.1"))
        val days = (cert.notAfter.time - System.currentTimeMillis()) / 86_400_000L
        assertTrue(days in 395..397)
        assertEquals(95, identity.fingerprint.length)
    }

    @Test
    fun savedCertificateIsReused() {
        val first = DesktopCert.load(context)
        val second = DesktopCert.load(context)
        assertEquals(first.fingerprint, second.fingerprint)
    }

    @Test
    fun onlyLocalAddressesAndIpHostsAreAccepted() {
        assertTrue(DesktopServer.isLocal(InetAddress.getByName("192.168.1.20")))
        assertTrue(DesktopServer.isLocal(InetAddress.getByName("10.0.0.5")))
        assertTrue(DesktopServer.isLocal(InetAddress.getByName("172.20.1.1")))
        assertTrue(DesktopServer.isLocal(InetAddress.getByName("fd12::1")))
        assertFalse(DesktopServer.isLocal(InetAddress.getByName("8.8.8.8")))
        assertFalse(DesktopServer.isLocal(InetAddress.getByName("100.64.1.1")))

        assertTrue(Desktop.isIpHost("192.168.1.20:8743"))
        assertTrue(Desktop.isIpHost("[fd12::1]:8743"))
        assertFalse(Desktop.isIpHost("evil.example:8743"))
        assertFalse(Desktop.isIpHost(null))
    }

    @Test
    fun browserNamesAreShort() {
        assertEquals(
            "Chrome · Windows",
            Desktop.deviceName("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0 Safari/537.36"),
        )
        assertEquals(
            "Edge · Windows",
            Desktop.deviceName("Mozilla/5.0 (Windows NT 10.0) AppleWebKit/537.36 Chrome/131.0 Safari/537.36 Edg/131.0"),
        )
        assertEquals("Firefox · macOS", Desktop.deviceName("Mozilla/5.0 (Macintosh; Intel Mac OS X 14.1; rv:132.0) Gecko/20100101 Firefox/132.0"))
    }

    private class Reply(val status: Int, val body: String, val headers: Map<String, String>) {
        fun json() = JSONObject(body)
    }

    private fun start() {
        val created = DesktopServer(DesktopCert.sslContext(identity)) { Desktop.handle(context, it) }
        port = created.start(18743..18799)
        server = created
    }

    /** Sertifikaya güvenen bir istemciyle tek istek. */
    private fun call(
        method: String,
        path: String,
        token: String? = null,
        body: String? = null,
        host: String = "127.0.0.1:$port",
        origin: String? = "https://127.0.0.1:$port",
    ): Reply {
        val trust = KeyStore.getInstance(KeyStore.getDefaultType()).apply {
            load(null, null)
            setCertificateEntry("mesa", identity.certificate)
        }
        val tmf = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm()).apply { init(trust) }
        val ssl = SSLContext.getInstance("TLS").apply { init(null, tmf.trustManagers, null) }
        (ssl.socketFactory.createSocket("127.0.0.1", port) as SSLSocket).use { socket ->
            socket.soTimeout = 10_000
            val bytes = body?.toByteArray(Charsets.UTF_8) ?: ByteArray(0)
            val head = buildString {
                append("$method $path HTTP/1.1\r\n")
                append("Host: $host\r\n")
                append("User-Agent: Mozilla/5.0 (Windows NT 10.0) Chrome/131.0\r\n")
                append("Connection: close\r\n")
                if (origin != null && method == "POST") append("Origin: $origin\r\n")
                if (token != null) append("Authorization: Bearer $token\r\n")
                if (body != null) append("Content-Type: application/json\r\n")
                append("Content-Length: ${bytes.size}\r\n\r\n")
            }
            socket.outputStream.write(head.toByteArray(Charsets.UTF_8) + bytes)
            socket.outputStream.flush()
            val raw = ByteArrayOutputStream().also { socket.inputStream.copyTo(it) }.toString("UTF-8")
            val (headText, content) = raw.split("\r\n\r\n", limit = 2).let { it[0] to it.getOrElse(1) { "" } }
            val lines = headText.split("\r\n")
            val headers = lines.drop(1).associate { it.substringBefore(':').lowercase() to it.substringAfter(':').trim() }
            return Reply(lines[0].split(' ')[1].toInt(), content, headers)
        }
    }

    private fun pairAndApprove(): String {
        val pairing = call("POST", "/api/pair", body = "{}").json()
        assertTrue(Desktop.approve(context, pairing.getString("id")))
        val status = call("GET", "/api/pair/status?id=${pairing.getString("id")}").json()
        assertEquals("approved", status.getString("state"))
        return status.getString("token")
    }

    @Test
    fun pageIsServedOverTlsWithStrictPolicy() {
        start()
        val page = call("GET", "/")
        assertEquals(200, page.status)
        assertTrue(page.headers["content-type"]!!.startsWith("text/html"))
        assertTrue(page.headers["content-security-policy"]!!.contains("script-src 'self'"))
        assertTrue(page.body.contains("app.js"))
        assertEquals(200, call("GET", "/app.js").status)
        assertEquals(404, call("GET", "/../secrets").status)
    }

    @Test
    fun nothingIsReadableWithoutPairing() {
        start()
        assertEquals(401, call("GET", "/api/conversations").status)
        assertEquals(401, call("GET", "/api/conversations", token = "uydurma").status)
        assertEquals(401, call("POST", "/api/send", body = """{"key":"x","text":"y"}""").status)
        // Alan adıyla gelen istek (DNS rebinding) ve başka sitenin sayfası.
        assertEquals(421, call("GET", "/api/hello", host = "evil.example:$port").status)
        assertEquals(403, call("POST", "/api/pair", body = "{}", origin = "https://evil.example").status)
    }

    @Test
    fun pairingNeedsApprovalOnThePhone() {
        start()
        val pairing = call("POST", "/api/pair", body = "{}").json()
        assertEquals(4, pairing.getString("code").length)
        val id = pairing.getString("id")
        assertEquals("pending", call("GET", "/api/pair/status?id=$id").json().getString("state"))
        // Aynı adresten hemen yeni istek: bildirim yağmuru olmasın.
        assertEquals(429, call("POST", "/api/pair", body = "{}").status)

        Desktop.deny(id)
        assertEquals("denied", call("GET", "/api/pair/status?id=$id").json().getString("state"))
        assertEquals(404, call("GET", "/api/pair/status?id=$id").status)
    }

    @Test
    fun pairedBrowserReadsChatsAndSignsOut() {
        Hub.store(context).ingest(
            CapturedConversation(
                "com.whatsapp|Deniz", "com.whatsapp", "Deniz", isGroup = false,
                messages = listOf(CapturedMessage("Deniz", "Bu akşam geliyor musun?", 1_795_000_000_000L, outgoing = false, fromFallback = false)),
                replyAction = null,
            ),
        )
        start()
        val token = pairAndApprove()
        // Anahtar bir kez verilir.
        assertEquals(404, call("GET", "/api/pair/status?id=yok").status)

        val session = call("GET", "/api/session", token = token).json()
        assertEquals("Chrome · Windows", session.getString("device"))
        assertEquals(1, Desktop.sessions(context).size)

        val list = JSONArray(call("GET", "/api/conversations", token = token).body)
        val chat = list.getJSONObject(0)
        assertEquals("Deniz", chat.getString("title"))
        assertEquals("WhatsApp", chat.getString("app"))
        assertEquals(1, chat.getInt("unread"))
        assertFalse(chat.getBoolean("canReply"))

        val messages = call("GET", "/api/messages?key=com.whatsapp%7CDeniz", token = token).json()
        assertEquals("Bu akşam geliyor musun?", messages.getJSONArray("messages").getJSONObject(0).getString("text"))

        // Yanıt yolu yoksa gönderilmez.
        val sent = call("POST", "/api/send", token = token, body = """{"key":"com.whatsapp|Deniz","text":"Evet"}""")
        assertEquals(409, sent.status)
        assertEquals("no_reply", sent.json().getString("error"))

        assertEquals(200, call("POST", "/api/read", token = token, body = """{"key":"com.whatsapp|Deniz"}""").status)
        assertEquals(0, JSONArray(call("GET", "/api/conversations", token = token).body).getJSONObject(0).getInt("unread"))

        assertEquals(200, call("POST", "/api/logout", token = token, body = "{}").status)
        assertEquals(401, call("GET", "/api/session", token = token).status)
        assertTrue(Desktop.sessions(context).isEmpty())
    }

    @Test
    fun sessionsAreStoredHashedAndCanBeRevoked() {
        val token = Desktop.createSession(context, "Firefox · Linux")
        val stored = context.getSharedPreferences("desktop", Context.MODE_PRIVATE).getString("sessions", null)
        assertNotNull(stored)
        assertFalse(stored!!.contains(token))
        val session = Desktop.sessions(context).single()
        assertEquals("Firefox · Linux", session.name)
        Desktop.revoke(context, session.id)
        assertNull(Desktop.sessions(context).firstOrNull())
    }
}
