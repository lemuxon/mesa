package com.mesajmerkezi.mesaj_merkezi

import android.content.Context
import android.util.Base64
import android.util.Log
import androidx.annotation.MainThread
import androidx.core.content.ContextCompat
import androidx.webkit.ProxyConfig
import androidx.webkit.ProxyController
import androidx.webkit.WebViewFeature
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.net.Inet4Address
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.ServerSocket
import java.net.Socket
import java.security.SecureRandom
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.RejectedExecutionException
import java.util.concurrent.atomic.AtomicLong

/**
 * Erişim kalkanı: Mesa'nın web servisleri (Discord, Slack…) için yerel
 * proxy. WebView bütün bağlantılarını 127.0.0.1'deki bu proxy'den açar;
 * proxy hedef adı şifreli DNS ile çözer (DNS engeli aşılır) ve TLS
 * ClientHello'yu bölerek gönderir (SNI'ye bakan engel aşılır). VPN gerekmez,
 * kullanıcının kendi VPN'iyle de çakışmaz.
 *
 * Proxy yalnızca Mesa'nın web görünümlerine açıktır: kuruluma özgü rastgele
 * bir parolayla kimlik ister (telefondaki başka uygulamalar kullanamaz).
 * Proxy düşerse WebView doğrudan bağlantıya geri döner (sayfalar yine açılır).
 */
object AccessShield {

    private const val TAG = "MesaShield"
    private const val PREFS = "secure_dns"
    private const val KEY_ENABLED = "shield"
    internal const val USER = "mesa"
    internal const val REALM = "mesa-kalkan"
    private val PORTS = setOf(80, 443, 8080, 8443)
    private const val CONNECT_TIMEOUT_MS = 10_000
    private const val HEAD_TIMEOUT_MS = 15_000
    private const val MAX_HEAD = 16 * 1024

    /** Kuruluma ve sürece özgü proxy parolası; yalnızca WebView'e verilir. */
    internal val token: String by lazy {
        Base64.encodeToString(ByteArray(18).also(SecureRandom()::nextBytes), Base64.NO_WRAP or Base64.URL_SAFE or Base64.NO_PADDING)
    }
    private val expectedAuthorization by lazy {
        "Basic " + Base64.encodeToString("$USER:$token".toByteArray(Charsets.ISO_8859_1), Base64.NO_WRAP)
    }

    @Volatile
    private var server: ServerSocket? = null

    val connections = AtomicLong()
    val splits = AtomicLong()
    val failures = AtomicLong()

    private val pool: ExecutorService = Executors.newCachedThreadPool { r ->
        Thread(r, "MesaShield").apply { isDaemon = true }
    }

    fun supported() = try {
        WebViewFeature.isFeatureSupported(WebViewFeature.PROXY_OVERRIDE)
    } catch (e: RuntimeException) {
        false
    }

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun enabled(context: Context) = prefs(context).getBoolean(KEY_ENABLED, false)

    @MainThread
    fun setEnabled(context: Context, on: Boolean) {
        prefs(context).edit().putBoolean(KEY_ENABLED, on).apply()
        apply(context)
    }

    /** WebView'in kalkanın sorduğu kimliği mi istediği (bkz. WebHost.Client). */
    fun isOwnChallenge(host: String?, realm: String?) =
        realm == REALM && (host == null || host.startsWith("127.0.0.1"))

    /** Ayara göre WebView proxy'sini kurar ya da kaldırır. Ana iş parçacığında. */
    @MainThread
    fun apply(context: Context) {
        if (!supported()) return
        val executor = ContextCompat.getMainExecutor(context)
        try {
            if (enabled(context)) {
                val port = ensureServer() ?: return
                SecureDns.client.provider = SecureDns.provider(context)
                val config = ProxyConfig.Builder()
                    .addProxyRule("127.0.0.1:$port")
                    .addDirect()
                    .build()
                ProxyController.getInstance().setProxyOverride(config, executor) { Log.i(TAG, "Erişim kalkanı açık") }
            } else if (server != null) {
                ProxyController.getInstance().clearProxyOverride(executor) { Log.i(TAG, "Erişim kalkanı kapalı") }
                stopServer()
            }
        } catch (e: RuntimeException) {
            Log.w(TAG, "Erişim kalkanı uygulanamadı", e)
        }
    }

    fun status(context: Context): Map<String, Any?> = mapOf(
        "supported" to supported(),
        "enabled" to enabled(context),
        "active" to (server?.isClosed == false),
        "connections" to connections.get(),
        "splits" to splits.get(),
        "failures" to failures.get(),
    )

    // ---- Proxy ----

    @Synchronized
    private fun ensureServer(): Int? {
        server?.let { if (!it.isClosed) return it.localPort }
        return try {
            val socket = ServerSocket(0, 64, InetAddress.getByName("127.0.0.1"))
            server = socket
            Thread({ acceptLoop(socket) }, "MesaShield-kabul").apply {
                isDaemon = true
                start()
            }
            socket.localPort
        } catch (e: IOException) {
            Log.w(TAG, "Yerel proxy açılamadı", e)
            null
        }
    }

    @Synchronized
    private fun stopServer() {
        try {
            server?.close()
        } catch (e: IOException) {
            // Zaten kapalı.
        }
        server = null
    }

    private fun acceptLoop(socket: ServerSocket) {
        while (!socket.isClosed) {
            val client = try {
                socket.accept()
            } catch (e: IOException) {
                break
            }
            try {
                pool.execute { handle(client) }
            } catch (e: RejectedExecutionException) {
                close(client)
            }
        }
    }

    private class Head(val text: String, val extra: ByteArray)

    /** Boş satıra kadar başlık; ardından gelen baytlar da döner. */
    private fun readHead(input: InputStream): Head? {
        val buffer = ByteArrayOutputStream(1024)
        val chunk = ByteArray(4096)
        while (buffer.size() < MAX_HEAD) {
            val n = input.read(chunk)
            if (n < 0) return null
            buffer.write(chunk, 0, n)
            val bytes = buffer.toByteArray()
            val end = indexOfHeadEnd(bytes)
            if (end >= 0) {
                return Head(String(bytes, 0, end, Charsets.ISO_8859_1), bytes.copyOfRange(end + 4, bytes.size))
            }
        }
        return null
    }

    private fun indexOfHeadEnd(b: ByteArray): Int {
        for (i in 0..b.size - 4) {
            if (b[i] == '\r'.code.toByte() && b[i + 1] == '\n'.code.toByte() &&
                b[i + 2] == '\r'.code.toByte() && b[i + 3] == '\n'.code.toByte()
            ) return i
        }
        return -1
    }

    private fun respond(output: OutputStream, status: String, extra: String = "") {
        try {
            output.write("HTTP/1.1 $status\r\n${extra}Content-Length: 0\r\nConnection: close\r\n\r\n".toByteArray(Charsets.ISO_8859_1))
            output.flush()
        } catch (e: IOException) {
            // İstemci gitti.
        }
    }

    private fun handle(client: Socket) {
        var upstream: Socket? = null
        try {
            client.soTimeout = HEAD_TIMEOUT_MS
            client.tcpNoDelay = true
            val input = client.getInputStream()
            val output = client.getOutputStream()
            val head = readHead(input) ?: return
            val request = ProxyRequest.parse(head.text)
            if (request == null) {
                respond(output, "400 Bad Request")
                return
            }
            if (request.proxyAuthorization != expectedAuthorization) {
                respond(output, "407 Proxy Authentication Required", "Proxy-Authenticate: Basic realm=\"$REALM\"\r\n")
                return
            }
            if (request.port !in PORTS) {
                respond(output, "403 Forbidden")
                return
            }
            upstream = connect(SecureDns.client.lookup(request.host), request.port)
            if (upstream == null) {
                failures.incrementAndGet()
                respond(output, "502 Bad Gateway")
                return
            }
            connections.incrementAndGet()
            val toServer = upstream.getOutputStream()
            if (request.isConnect) {
                output.write("HTTP/1.1 200 Connection established\r\n\r\n".toByteArray(Charsets.ISO_8859_1))
                output.flush()
                var first = head.extra
                if (first.isEmpty()) {
                    val buffer = ByteArray(16 * 1024)
                    val n = input.read(buffer)
                    if (n <= 0) return
                    first = buffer.copyOf(n)
                }
                val parts = TlsSplit.split(first)
                if (parts.size > 1) splits.incrementAndGet()
                for (part in parts) {
                    toServer.write(part)
                    toServer.flush()
                }
            } else {
                toServer.write(request.originRequest())
                toServer.write(head.extra)
                toServer.flush()
            }
            client.soTimeout = 0
            pipe(client, upstream)
        } catch (e: IOException) {
            // Bağlantı koptu; WebView yeniden dener.
        } finally {
            close(client)
            upstream?.let(::close)
        }
    }

    /** Adreslerden ilk bağlananı (IPv4 önce; IPv6'sız ağlarda takılmasın). */
    private fun connect(addresses: List<InetAddress>, port: Int): Socket? {
        for (address in addresses.sortedBy { if (it is Inet4Address) 0 else 1 }.take(4)) {
            val socket = Socket()
            try {
                socket.tcpNoDelay = true
                socket.connect(InetSocketAddress(address, port), CONNECT_TIMEOUT_MS)
                return socket
            } catch (e: IOException) {
                close(socket)
            }
        }
        return null
    }

    /** İki yönlü aktarım; bir yön bitince karşı tarafın yazma yönü kapatılır. */
    private fun pipe(client: Socket, upstream: Socket) {
        val back = try {
            pool.submit {
                copy(upstream.getInputStream(), client.getOutputStream())
                try {
                    client.shutdownOutput()
                } catch (e: IOException) {
                    // Kapalı.
                }
            }
        } catch (e: RejectedExecutionException) {
            return
        }
        copy(client.getInputStream(), upstream.getOutputStream())
        try {
            upstream.shutdownOutput()
        } catch (e: IOException) {
            // Kapalı.
        }
        try {
            back.get()
        } catch (e: Exception) {
            // Karşı yön hata ile bitti.
        }
    }

    private fun copy(input: InputStream, output: OutputStream) {
        val buffer = ByteArray(32 * 1024)
        try {
            while (true) {
                val n = input.read(buffer)
                if (n < 0) break
                output.write(buffer, 0, n)
                output.flush()
            }
        } catch (e: IOException) {
            // Bağlantı kapandı.
        }
    }

    private fun close(socket: Socket) {
        try {
            socket.close()
        } catch (e: IOException) {
            // Zaten kapalı.
        }
    }
}
