package com.mesajmerkezi.mesaj_merkezi

import java.net.InetAddress

/**
 * DNS iletisi (RFC 1035) üzerinde şifreli DNS'in gerektirdiği kadar işlem:
 * kimlik, soru bölümü (önbellek anahtarı), en kısa TTL, SERVFAIL yanıtı,
 * A/AAAA sorgusu kurma ve yanıttaki adresleri okuma. Saf Kotlin; testli.
 */
internal object DnsMessage {

    const val TYPE_A = 1
    const val TYPE_AAAA = 28
    private const val TYPE_SOA = 6
    private const val HEADER = 12

    fun id(message: ByteArray): Int = u16(message, 0)

    /** Aynı ileti, kimliği [id] yapılmış kopya. */
    fun withId(message: ByteArray, id: Int): ByteArray =
        message.copyOf().also { put16(it, 0, id) }

    fun rcode(message: ByteArray): Int = message[3].toInt() and 0x0F

    private fun qdCount(message: ByteArray) = u16(message, 4)
    private fun anCount(message: ByteArray) = u16(message, 6)
    private fun nsCount(message: ByteArray) = u16(message, 8)

    /**
     * Önbellek anahtarı: soru bölümü (ad küçük harfe çevrilmiş, tür, sınıf).
     * Tek soruluk değilse ya da bozuksa null (önbelleğe alınmaz).
     */
    fun questionKey(message: ByteArray): String? {
        if (message.size < HEADER || qdCount(message) != 1) return null
        val name = StringBuilder()
        var i = HEADER
        while (true) {
            if (i >= message.size) return null
            val len = message[i].toInt() and 0xFF
            if (len == 0) break
            if (len and 0xC0 != 0 || i + 1 + len > message.size) return null
            for (j in i + 1..i + len) name.append((message[j].toInt() and 0xFF).toChar().lowercaseChar())
            name.append('.')
            i += 1 + len
        }
        if (i + 5 > message.size) return null
        return "$name/${u16(message, i + 1)}/${u16(message, i + 3)}"
    }

    /** Soru bölümünün bittiği konum; bozuksa -1. */
    private fun questionEnd(message: ByteArray): Int {
        var i = HEADER
        repeat(qdCount(message)) {
            i = skipName(message, i)
            if (i < 0 || i + 4 > message.size) return -1
            i += 4
        }
        return i
    }

    /** Adı (sıkıştırılmış olabilir) atlar; sonraki konum ya da -1. */
    private fun skipName(message: ByteArray, start: Int): Int {
        var i = start
        while (true) {
            if (i >= message.size) return -1
            val len = message[i].toInt() and 0xFF
            when {
                len == 0 -> return i + 1
                len and 0xC0 == 0xC0 -> return if (i + 2 <= message.size) i + 2 else -1
                len and 0xC0 != 0 -> return -1
                else -> i += 1 + len
            }
        }
    }

    /**
     * Önbellek süresi (saniye): yanıtlardaki en kısa TTL. Yanıt yoksa
     * (ör. alan adı yok) yetki bölümündeki SOA'nın süresi; o da yoksa null.
     */
    fun cacheSeconds(message: ByteArray): Int? {
        if (message.size < HEADER) return null
        var i = questionEnd(message)
        if (i < 0) return null
        var min: Int? = null
        val answers = anCount(message)
        val records = answers + nsCount(message)
        for (n in 0 until records) {
            i = skipName(message, i)
            if (i < 0 || i + 10 > message.size) return min
            val type = u16(message, i)
            val ttl = ((u16(message, i + 4).toLong() shl 16) or u16(message, i + 6).toLong()).coerceAtMost(Int.MAX_VALUE.toLong()).toInt()
            val rdLength = u16(message, i + 8)
            i += 10 + rdLength
            if (i > message.size) return min
            val counts = n < answers || (answers == 0 && type == TYPE_SOA)
            if (counts) min = if (min == null) ttl else minOf(min, ttl)
        }
        return min
    }

    /** Sorguya SERVFAIL yanıtı: aynı kimlik ve soru, kayıt yok. */
    fun servfail(query: ByteArray): ByteArray {
        if (query.size < HEADER) return ByteArray(0)
        val end = questionEnd(query)
        val out = if (end > 0) query.copyOf(end) else query.copyOf(HEADER).also { put16(it, 4, 0) }
        val rd = out[2].toInt() and 0x01
        out[2] = (0x80 or rd).toByte() // QR=1, opcode=0, RD korunur
        out[3] = (0x80 or 2).toByte() // RA=1, RCODE=2 (SERVFAIL)
        put16(out, 6, 0)
        put16(out, 8, 0)
        put16(out, 10, 0)
        return out
    }

    /** [name] için A ya da AAAA sorgusu (özyinelemeli). */
    fun query(id: Int, name: String, type: Int): ByteArray {
        val labels = name.trimEnd('.').split('.').filter { it.isNotEmpty() }
        val size = HEADER + labels.sumOf { 1 + it.toByteArray(Charsets.US_ASCII).size } + 1 + 4
        val out = ByteArray(size)
        put16(out, 0, id)
        out[2] = 0x01 // RD
        put16(out, 4, 1)
        var i = HEADER
        for (label in labels) {
            val bytes = label.toByteArray(Charsets.US_ASCII)
            require(bytes.size in 1..63) { "geçersiz alan adı" }
            out[i++] = bytes.size.toByte()
            bytes.copyInto(out, i)
            i += bytes.size
        }
        out[i++] = 0
        put16(out, i, type)
        put16(out, i + 2, 1) // IN
        return out
    }

    /** Yanıttaki A ve AAAA adresleri (CNAME zincirleri atlanır). */
    fun addresses(message: ByteArray): List<InetAddress> {
        if (message.size < HEADER) return emptyList()
        var i = questionEnd(message)
        if (i < 0) return emptyList()
        val out = ArrayList<InetAddress>()
        repeat(anCount(message)) {
            i = skipName(message, i)
            if (i < 0 || i + 10 > message.size) return out
            val type = u16(message, i)
            val rdLength = u16(message, i + 8)
            val data = i + 10
            if (data + rdLength > message.size) return out
            if ((type == TYPE_A && rdLength == 4) || (type == TYPE_AAAA && rdLength == 16)) {
                out += InetAddress.getByAddress(message.copyOfRange(data, data + rdLength))
            }
            i = data + rdLength
        }
        return out
    }

    internal fun u16(b: ByteArray, i: Int) = ((b[i].toInt() and 0xFF) shl 8) or (b[i + 1].toInt() and 0xFF)

    internal fun put16(b: ByteArray, i: Int, v: Int) {
        b[i] = (v ushr 8).toByte()
        b[i + 1] = v.toByte()
    }
}
