package com.mesajmerkezi.mesaj_merkezi

import android.util.Log
import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.net.Inet6Address
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.ServerSocket
import java.net.Socket
import java.net.SocketException
import java.net.URLDecoder
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.Semaphore
import javax.net.ssl.SSLContext
import javax.net.ssl.SSLServerSocket

/** Tarayıcıdan gelen istek. */
internal class HttpRequest(
    val method: String,
    val path: String,
    val query: Map<String, String>,
    private val headers: Map<String, String>,
    val body: ByteArray,
    val remote: InetAddress,
) {
    fun header(name: String): String? = headers[name.lowercase()]
}

/** Yanıt; [stream] verilirse başlıktan sonra bağlantı ona bırakılır (sunucu olayları). */
internal class HttpResponse(
    val status: Int,
    val contentType: String,
    val body: ByteArray = ByteArray(0),
    val headers: Map<String, String> = emptyMap(),
    val stream: ((OutputStream) -> Unit)? = null,
)

/**
 * Bilgisayardan Mesa için küçük bir HTTPS sunucusu (HTTP/1.1, bağlantı yeniden
 * kullanımı, sunucu olayları). Yalnızca yerel ağdan (özel IP adresleri)
 * bağlantı kabul eder; başlıklar ve gövde boyutu sınırlıdır.
 */
internal class DesktopServer(
    private val ssl: SSLContext,
    private val handler: (HttpRequest) -> HttpResponse,
) {
    private var socket: ServerSocket? = null
    private var pool: ExecutorService? = null
    private val slots = Semaphore(MAX_CONNECTIONS)

    @Volatile
    var running = false
        private set

    /** [ports] içinden boş olan ilk portu açar; açılan portu döner. */
    fun start(ports: IntRange): Int {
        var lastError: IOException? = null
        for (port in ports) {
            val server = try {
                (ssl.serverSocketFactory.createServerSocket() as SSLServerSocket).apply {
                    reuseAddress = true
                    bind(InetSocketAddress(port), 32)
                }
            } catch (e: IOException) {
                lastError = e
                continue
            }
            socket = server
            running = true
            val workers = Executors.newCachedThreadPool { r -> Thread(r, "mesa-masaustu").apply { isDaemon = true } }
            pool = workers
            Thread({ acceptLoop(server, workers) }, "mesa-masaustu-kabul").apply { isDaemon = true }.start()
            return port
        }
        throw lastError ?: IOException("Boş port yok")
    }

    fun stop() {
        running = false
        try {
            socket?.close()
        } catch (_: IOException) {
        }
        socket = null
        pool?.shutdownNow()
        pool = null
    }

    private fun acceptLoop(server: ServerSocket, workers: ExecutorService) {
        while (running) {
            val client = try {
                server.accept()
            } catch (e: IOException) {
                if (running) Log.w(TAG, "Bilgisayar bağlantısı kabul edilemedi: ${e.javaClass.simpleName}")
                break
            }
            if (!isLocal(client.inetAddress) || !slots.tryAcquire()) {
                runCatching { client.close() }
                continue
            }
            try {
                workers.execute {
                    try {
                        serve(client)
                    } finally {
                        slots.release()
                    }
                }
            } catch (e: Exception) {
                slots.release()
                runCatching { client.close() }
            }
        }
    }

    private fun serve(client: Socket) {
        try {
            client.soTimeout = IDLE_TIMEOUT_MS
            val input = BufferedInputStream(client.getInputStream())
            val output = BufferedOutputStream(client.getOutputStream())
            while (running) {
                val request = try {
                    read(input, client.inetAddress) ?: break
                } catch (e: HttpError) {
                    write(output, HttpResponse(e.status, "text/plain; charset=utf-8", e.message.orEmpty().toByteArray()), false)
                    break
                }
                val keepAlive = !request.header("connection").equals("close", ignoreCase = true)
                val response = try {
                    handler(request)
                } catch (e: Exception) {
                    Log.w(TAG, "Bilgisayar isteği işlenemedi: ${e.javaClass.simpleName}")
                    HttpResponse(500, "application/json; charset=utf-8", """{"error":"server"}""".toByteArray())
                }
                val stream = response.stream
                if (stream != null) {
                    writeHead(output, response, contentLength = null, keepAlive = false)
                    output.flush()
                    client.soTimeout = 0
                    stream(output)
                    break
                }
                write(output, response, keepAlive)
                if (!keepAlive) break
            }
        } catch (_: SocketException) {
            // Tarayıcı bağlantıyı kapattı ya da sertifika uyarısında vazgeçti.
        } catch (e: IOException) {
            Log.d(TAG, "Bilgisayar bağlantısı kapandı: ${e.javaClass.simpleName} ${e.message}")
        } catch (e: Throwable) {
            Log.w(TAG, "Bilgisayar bağlantısı beklenmedik biçimde kapandı", e)
        } finally {
            runCatching { client.close() }
        }
    }

    private class HttpError(val status: Int, message: String) : IOException(message)

    /** Sıradaki istek; bağlantı kapandıysa null. */
    private fun read(input: InputStream, remote: InetAddress): HttpRequest? {
        val head = readHead(input) ?: return null
        val lines = head.split("\r\n")
        val parts = lines.first().split(' ')
        if (parts.size != 3 || !parts[2].startsWith("HTTP/1.")) throw HttpError(400, "Bad request")
        val headers = HashMap<String, String>()
        for (line in lines.drop(1)) {
            if (line.isEmpty()) continue
            val colon = line.indexOf(':')
            if (colon <= 0) throw HttpError(400, "Bad header")
            headers[line.substring(0, colon).trim().lowercase()] = line.substring(colon + 1).trim()
        }
        if (headers["transfer-encoding"] != null) throw HttpError(411, "Length required")
        val length = headers["content-length"]?.toIntOrNull() ?: 0
        if (length < 0 || length > MAX_BODY) throw HttpError(413, "Too large")
        val body = ByteArray(length)
        var read = 0
        while (read < length) {
            val n = input.read(body, read, length - read)
            if (n < 0) throw IOException("Gövde yarım kaldı")
            read += n
        }
        val target = parts[1]
        val path = decode(target.substringBefore('?'))
        val query = target.substringAfter('?', "").split('&').filter { it.isNotEmpty() }.associate {
            decode(it.substringBefore('=')) to decode(it.substringAfter('=', ""))
        }
        return HttpRequest(parts[0].uppercase(), path, query, headers, body, remote)
    }

    /** Boş satıra kadar başlık; ilk bayttan önce bağlantı kapandıysa null. */
    private fun readHead(input: InputStream): String? {
        val out = ByteArrayOutputStream()
        var matched = 0
        while (true) {
            val b = input.read()
            if (b < 0) {
                if (out.size() == 0) return null
                throw IOException("Başlık yarım kaldı")
            }
            out.write(b)
            if (out.size() > MAX_HEAD) throw HttpError(431, "Headers too large")
            matched = when {
                b == '\r'.code && (matched == 0 || matched == 2) -> matched + 1
                b == '\n'.code && (matched == 1 || matched == 3) -> matched + 1
                else -> 0
            }
            if (matched == 4) return out.toString(Charsets.ISO_8859_1.name()).removeSuffix("\r\n\r\n")
        }
    }

    private fun decode(text: String) = try {
        URLDecoder.decode(text, "UTF-8")
    } catch (e: IllegalArgumentException) {
        throw HttpError(400, "Bad encoding")
    }

    private fun write(output: OutputStream, response: HttpResponse, keepAlive: Boolean) {
        writeHead(output, response, response.body.size, keepAlive)
        output.write(response.body)
        output.flush()
    }

    private fun writeHead(output: OutputStream, response: HttpResponse, contentLength: Int?, keepAlive: Boolean) {
        val head = StringBuilder()
        head.append("HTTP/1.1 ").append(response.status).append(' ').append(reason(response.status)).append("\r\n")
        head.append("Content-Type: ").append(response.contentType).append("\r\n")
        if (contentLength != null) head.append("Content-Length: ").append(contentLength).append("\r\n")
        head.append("Connection: ").append(if (keepAlive) "keep-alive" else "close").append("\r\n")
        head.append("X-Content-Type-Options: nosniff\r\n")
        head.append("Referrer-Policy: no-referrer\r\n")
        head.append("X-Frame-Options: DENY\r\n")
        if ("Cache-Control" !in response.headers) head.append("Cache-Control: no-store\r\n")
        for ((name, value) in response.headers) head.append(name).append(": ").append(value).append("\r\n")
        head.append("\r\n")
        output.write(head.toString().toByteArray(Charsets.UTF_8))
    }

    companion object {
        private const val TAG = "MesajMerkezi"
        private const val MAX_CONNECTIONS = 24
        private const val MAX_HEAD = 16 * 1024
        private const val MAX_BODY = 256 * 1024
        private const val IDLE_TIMEOUT_MS = 30_000

        private fun reason(status: Int) = when (status) {
            200 -> "OK"
            204 -> "No Content"
            400 -> "Bad Request"
            401 -> "Unauthorized"
            403 -> "Forbidden"
            404 -> "Not Found"
            405 -> "Method Not Allowed"
            409 -> "Conflict"
            411 -> "Length Required"
            413 -> "Payload Too Large"
            421 -> "Misdirected Request"
            429 -> "Too Many Requests"
            431 -> "Request Header Fields Too Large"
            else -> if (status >= 500) "Server Error" else "Status"
        }

        /**
         * Yerel ağ adresi mi: özel IPv4 (10/8, 172.16/12, 192.168/16), yerel
         * bağlantı, kendi cihazı ya da IPv6 benzersiz yerel adres (fc00::/7).
         */
        fun isLocal(address: InetAddress): Boolean {
            if (address.isLoopbackAddress || address.isSiteLocalAddress || address.isLinkLocalAddress) return true
            return address is Inet6Address && (address.address[0].toInt() and 0xFE) == 0xFC
        }
    }
}
