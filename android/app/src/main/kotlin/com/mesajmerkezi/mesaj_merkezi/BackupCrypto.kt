package com.mesajmerkezi.mesaj_merkezi

import java.io.ByteArrayOutputStream
import java.io.DataInputStream
import java.io.DataOutputStream
import java.io.EOFException
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.nio.ByteBuffer
import java.security.SecureRandom
import javax.crypto.AEADBadTagException
import javax.crypto.Cipher
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.PBEKeySpec
import javax.crypto.spec.SecretKeySpec

/** Şifre yanlış (ya da dosya bu şifreyle oluşturulmamış). */
class WrongPasswordException : IOException("Şifre yanlış")

/** Dosya Mesa yedeği değil, eksik ya da değiştirilmiş. */
/** [reason]: kullanıcıya gösterilecek metin (seçili dilde, bkz. Lang). */
class CorruptBackupException(@androidx.annotation.StringRes val reason: Int) : IOException("corrupt backup: $reason")

/**
 * Yedek dosyasının şifrelemesi (Android'den bağımsız; birim testli).
 *
 * Biçim: "MMYEDEK1" + sürüm (1 bayt) + PBKDF2 tur sayısı (4) + tuz (16) +
 * nonce öneki (8); ardından parçalar: [uzunluk (4)][AES-256-GCM şifreli
 * parça + 16 bayt etiket]. Parça i'nin nonce'u = önek ‖ i; ek doğrulanan
 * veri = başlık ‖ i ‖ son-parça-işareti. Böylece parçaların yeri
 * değiştirilemez, dosyanın sonu kesilirse fark edilir; büyük yedekler
 * belleğe sığdırılmadan parça parça çözülür.
 */
object BackupCrypto {

    private val MAGIC = "MMYEDEK1".toByteArray(Charsets.US_ASCII)
    private const val VERSION: Byte = 1
    const val ITERATIONS = 310_000
    private const val SALT_BYTES = 16
    private const val PREFIX_BYTES = 8
    private const val TAG_BITS = 128
    const val CHUNK = 1 shl 20
    private val HEADER_BYTES = MAGIC.size + 1 + 4 + SALT_BYTES + PREFIX_BYTES

    fun deriveKey(password: CharArray, salt: ByteArray, iterations: Int): SecretKeySpec {
        val spec = PBEKeySpec(password, salt, iterations, 256)
        try {
            val bytes = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256").generateSecret(spec).encoded
            return SecretKeySpec(bytes, "AES")
        } finally {
            spec.clearPassword()
        }
    }

    private fun nonce(prefix: ByteArray, index: Int) =
        ByteBuffer.allocate(12).put(prefix).putInt(index).array()

    private fun aad(header: ByteArray, index: Int, last: Boolean) =
        ByteBuffer.allocate(header.size + 5).put(header).putInt(index).put(if (last) 1 else 0).array()

    /** Yazılan her şeyi şifreler; [close] son parçayı yazar (unutulursa dosya eksik sayılır). */
    class Writer(
        out: OutputStream,
        password: CharArray,
        iterations: Int = ITERATIONS,
        random: SecureRandom = SecureRandom(),
    ) : OutputStream() {
        private val sink = DataOutputStream(out)
        private val header: ByteArray
        private val key: SecretKeySpec
        private val prefix = ByteArray(PREFIX_BYTES).also(random::nextBytes)
        private val buffer = ByteArrayOutputStream(CHUNK)
        private var index = 0
        private var closed = false

        init {
            val salt = ByteArray(SALT_BYTES).also(random::nextBytes)
            header = ByteBuffer.allocate(HEADER_BYTES)
                .put(MAGIC).put(VERSION).putInt(iterations).put(salt).put(prefix).array()
            key = deriveKey(password, salt, iterations)
            sink.write(header)
        }

        override fun write(b: Int) {
            buffer.write(b)
            if (buffer.size() >= CHUNK) flushChunk(last = false)
        }

        override fun write(b: ByteArray, off: Int, len: Int) {
            var offset = off
            var remaining = len
            while (remaining > 0) {
                val n = minOf(remaining, CHUNK - buffer.size())
                buffer.write(b, offset, n)
                offset += n
                remaining -= n
                if (buffer.size() >= CHUNK) flushChunk(last = false)
            }
        }

        private fun flushChunk(last: Boolean) {
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.ENCRYPT_MODE, key, GCMParameterSpec(TAG_BITS, nonce(prefix, index)))
            cipher.updateAAD(aad(header, index, last))
            val sealed = cipher.doFinal(buffer.toByteArray())
            sink.writeInt(sealed.size)
            sink.write(sealed)
            buffer.reset()
            index++
        }

        override fun flush() = sink.flush()

        override fun close() {
            if (closed) return
            closed = true
            flushChunk(last = true)
            sink.close()
        }
    }

    /** Çözülmüş içeriği verir; şifre yanlışsa ilk okumada [WrongPasswordException]. */
    class Reader(input: InputStream, password: CharArray) : InputStream() {
        private val source = DataInputStream(input)
        private val header = ByteArray(HEADER_BYTES)
        private val key: SecretKeySpec
        private val prefix: ByteArray
        private var plain = ByteArray(0)
        private var position = 0
        private var index = 0
        private var finished = false

        init {
            try {
                source.readFully(header)
            } catch (e: EOFException) {
                throw CorruptBackupException(R.string.backup_not_backup)
            }
            val buf = ByteBuffer.wrap(header)
            val magic = ByteArray(MAGIC.size).also { buf.get(it) }
            if (!magic.contentEquals(MAGIC)) throw CorruptBackupException(R.string.backup_not_backup)
            if (buf.get() != VERSION) throw CorruptBackupException(R.string.backup_version)
            val iterations = buf.int
            if (iterations !in 1_000..10_000_000) throw CorruptBackupException(R.string.backup_corrupted)
            val salt = ByteArray(SALT_BYTES).also { buf.get(it) }
            prefix = ByteArray(PREFIX_BYTES).also { buf.get(it) }
            key = deriveKey(password, salt, iterations)
            nextChunk()
        }

        private fun nextChunk() {
            val size = try {
                source.readInt()
            } catch (e: EOFException) {
                throw CorruptBackupException(R.string.backup_truncated)
            }
            if (size < TAG_BITS / 8 || size > CHUNK + TAG_BITS / 8) throw CorruptBackupException(R.string.backup_corrupted)
            val sealed = ByteArray(size)
            try {
                source.readFully(sealed)
            } catch (e: EOFException) {
                throw CorruptBackupException(R.string.backup_truncated)
            }
            // Son parça mı bilinmez: önce "değil" diye dener, olmazsa "son" diye.
            plain = open(sealed, last = false) ?: open(sealed, last = true)?.also { finished = true }
                ?: throw if (index == 0) WrongPasswordException() else CorruptBackupException(R.string.backup_tampered)
            position = 0
            index++
        }

        private fun open(sealed: ByteArray, last: Boolean): ByteArray? = try {
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(TAG_BITS, nonce(prefix, index)))
            cipher.updateAAD(aad(header, index, last))
            cipher.doFinal(sealed)
        } catch (e: AEADBadTagException) {
            null
        }

        override fun read(): Int {
            val one = ByteArray(1)
            return if (read(one, 0, 1) < 0) -1 else one[0].toInt() and 0xFF
        }

        override fun read(b: ByteArray, off: Int, len: Int): Int {
            if (len == 0) return 0
            while (position >= plain.size) {
                if (finished) return -1
                nextChunk()
            }
            val n = minOf(len, plain.size - position)
            System.arraycopy(plain, position, b, off, n)
            position += n
            return n
        }

        override fun close() = source.close()
    }
}
