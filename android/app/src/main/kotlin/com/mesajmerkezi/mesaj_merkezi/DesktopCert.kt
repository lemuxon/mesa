package com.mesajmerkezi.mesaj_merkezi

import android.content.Context
import android.util.Base64
import android.util.Log
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.math.BigInteger
import java.security.KeyFactory
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.MessageDigest
import java.security.PrivateKey
import java.security.SecureRandom
import java.security.Signature
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import java.security.spec.ECGenParameterSpec
import java.security.spec.PKCS8EncodedKeySpec
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import javax.net.ssl.KeyManagerFactory
import javax.net.ssl.SSLContext

/**
 * Bilgisayardan Mesa'nın TLS kimliği: telefonda üretilen, kendinden imzalı
 * sertifika (EC P-256, ECDSA-SHA256).
 *
 * Bağlantı şifrelidir; sertifikayı bir yetkili imzalamadığı için tarayıcı ilk
 * açılışta bir kez uyarır. Anahtar [SecretBox] ile şifreli saklanır ki her
 * açılışta yeni sertifika (ve yeni uyarı) çıkmasın; süresi dolmadan yenilenir.
 * Android'de sertifika üretmek için hazır bir arayüz olmadığından sertifika
 * burada DER olarak elle kodlanır.
 */
object DesktopCert {
    private const val TAG = "MesajMerkezi"
    private const val PREFS = "desktop"
    private const val VALID_DAYS = 397
    private val password = "mesa".toCharArray()

    class Identity(val key: PrivateKey, val certificate: X509Certificate) {
        /** SHA-256 parmak izi (tarayıcının sertifika ayrıntılarında görünen). */
        val fingerprint: String
            get() = MessageDigest.getInstance("SHA-256").digest(certificate.encoded)
                .joinToString(":") { "%02X".format(it) }
    }

    /** Kayıtlı kimlik; yoksa, açılamıyorsa ya da süresi bitmek üzereyse yenisi. */
    fun load(context: Context): Identity {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val saved = try {
            val key = prefs.getString("tls_key", null)?.let(SecretBox::decrypt)
            val cert = prefs.getString("tls_cert", null)
            if (key != null && cert != null) {
                Identity(
                    KeyFactory.getInstance("EC").generatePrivate(PKCS8EncodedKeySpec(Base64.decode(key, Base64.NO_WRAP))),
                    parse(Base64.decode(cert, Base64.NO_WRAP)),
                )
            } else {
                null
            }
        } catch (e: Exception) {
            Log.w(TAG, "Bilgisayar sertifikası açılamadı: ${e.javaClass.simpleName}")
            null
        }
        val renewBy = System.currentTimeMillis() + 30L * 86_400_000L
        if (saved != null && saved.certificate.notAfter.time > renewBy) return saved
        val fresh = create()
        prefs.edit()
            .putString("tls_key", SecretBox.encrypt(Base64.encodeToString(fresh.key.encoded, Base64.NO_WRAP)))
            .putString("tls_cert", Base64.encodeToString(fresh.certificate.encoded, Base64.NO_WRAP))
            .apply()
        return fresh
    }

    /** Sunucu soketleri için TLS bağlamı. */
    fun sslContext(identity: Identity): SSLContext {
        val store = KeyStore.getInstance(KeyStore.getDefaultType()).apply {
            load(null, null)
            setKeyEntry("mesa", identity.key, password, arrayOf(identity.certificate))
        }
        val keys = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm()).apply { init(store, password) }
        return SSLContext.getInstance("TLS").apply { init(keys.keyManagers, null, SecureRandom()) }
    }

    /** Yeni anahtar çifti ve onunla imzalanmış sertifika. */
    internal fun create(now: Long = System.currentTimeMillis()): Identity {
        val generator = KeyPairGenerator.getInstance("EC")
        generator.initialize(ECGenParameterSpec("secp256r1"), SecureRandom())
        val pair = generator.generateKeyPair()
        val der = selfSigned(pair.public.encoded, pair.private, now)
        return Identity(pair.private, parse(der))
    }

    private fun parse(der: ByteArray) =
        CertificateFactory.getInstance("X.509").generateCertificate(ByteArrayInputStream(der)) as X509Certificate

    // ---- DER ----

    private val ECDSA_SHA256 = oid(1, 2, 840, 10045, 4, 3, 2)

    private fun selfSigned(publicKey: ByteArray, privateKey: PrivateKey, now: Long): ByteArray {
        val serial = ByteArray(16).also { SecureRandom().nextBytes(it) }
        serial[0] = (serial[0].toInt() and 0x7F or 0x01).toByte()
        val name = seq(set(seq(oid(2, 5, 4, 3), utf8("Mesa"))), set(seq(oid(2, 5, 4, 10), utf8("Mesa"))))
        val algorithm = seq(ECDSA_SHA256)
        val tbs = seq(
            explicit(0, integer(BigInteger.valueOf(2))),
            integer(BigInteger(1, serial)),
            algorithm,
            name,
            seq(time(now - 86_400_000L), time(now + VALID_DAYS * 86_400_000L)),
            name,
            publicKey,
            explicit(
                3,
                seq(
                    // Sertifika yetkilisi değil.
                    extension(oid(2, 5, 29, 19), critical = true, value = seq()),
                    // Yalnızca imza (TLS el sıkışması).
                    extension(oid(2, 5, 29, 15), critical = true, value = tlv(0x03, byteArrayOf(0x07, 0x80.toByte()))),
                    // Sunucu kimliği.
                    extension(oid(2, 5, 29, 37), critical = false, value = seq(oid(1, 3, 6, 1, 5, 5, 7, 3, 1))),
                ),
            ),
        )
        val signature = Signature.getInstance("SHA256withECDSA").run {
            initSign(privateKey)
            update(tbs)
            sign()
        }
        return seq(tbs, algorithm, tlv(0x03, byteArrayOf(0) + signature))
    }

    private fun extension(id: ByteArray, critical: Boolean, value: ByteArray) =
        if (critical) seq(id, tlv(0x01, byteArrayOf(0xFF.toByte())), tlv(0x04, value)) else seq(id, tlv(0x04, value))

    private fun tlv(tag: Int, content: ByteArray): ByteArray {
        val out = ByteArrayOutputStream()
        out.write(tag)
        val n = content.size
        when {
            n < 0x80 -> out.write(n)
            n < 0x100 -> {
                out.write(0x81)
                out.write(n)
            }
            else -> {
                out.write(0x82)
                out.write(n shr 8)
                out.write(n and 0xFF)
            }
        }
        out.write(content)
        return out.toByteArray()
    }

    private fun concat(parts: Array<out ByteArray>): ByteArray {
        val out = ByteArrayOutputStream()
        parts.forEach(out::write)
        return out.toByteArray()
    }

    private fun seq(vararg parts: ByteArray) = tlv(0x30, concat(parts))

    private fun set(vararg parts: ByteArray) = tlv(0x31, concat(parts))

    private fun explicit(number: Int, content: ByteArray) = tlv(0xA0 + number, content)

    private fun integer(value: BigInteger) = tlv(0x02, value.toByteArray())

    private fun utf8(text: String) = tlv(0x0C, text.toByteArray(Charsets.UTF_8))

    private fun oid(vararg arcs: Long): ByteArray {
        val out = ByteArrayOutputStream()
        out.write((arcs[0] * 40 + arcs[1]).toInt())
        for (arc in arcs.drop(2)) {
            val bytes = mutableListOf((arc and 0x7F).toInt())
            var rest = arc shr 7
            while (rest > 0) {
                bytes.add(0, ((rest and 0x7F) or 0x80).toInt())
                rest = rest shr 7
            }
            bytes.forEach(out::write)
        }
        return tlv(0x06, out.toByteArray())
    }

    private fun oid(vararg arcs: Int) = oid(*arcs.map { it.toLong() }.toLongArray())

    /** 2050'den önce UTCTime, sonra GeneralizedTime (X.509 kuralı). */
    private fun time(millis: Long): ByteArray {
        val year = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply { timeInMillis = millis }.get(Calendar.YEAR)
        val utc = year < 2050
        val format = SimpleDateFormat(if (utc) "yyMMddHHmmss'Z'" else "yyyyMMddHHmmss'Z'", Locale.US)
        format.timeZone = TimeZone.getTimeZone("UTC")
        return tlv(if (utc) 0x17 else 0x18, format.format(Date(millis)).toByteArray(Charsets.US_ASCII))
    }
}
