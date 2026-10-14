package com.mesajmerkezi.mesaj_merkezi

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import kotlin.random.Random

class BackupCryptoTest {

    private val password = "doğru-şifre-123".toCharArray()

    // Testte hızlı olsun diye az tur.
    private fun encrypt(data: ByteArray, pass: CharArray = password): ByteArray {
        val out = ByteArrayOutputStream()
        BackupCrypto.Writer(out, pass.copyOf(), iterations = 1_000).use { it.write(data) }
        return out.toByteArray()
    }

    private fun decrypt(file: ByteArray, pass: CharArray = password): ByteArray =
        BackupCrypto.Reader(ByteArrayInputStream(file), pass.copyOf()).use { it.readBytes() }

    @Test
    fun `kucuk ve cok parcali veri geri acilir`() {
        for (size in listOf(0, 1, 1000, BackupCrypto.CHUNK, BackupCrypto.CHUNK * 2 + 123)) {
            val data = Random(size).nextBytes(size)
            assertArrayEquals("boyut $size", data, decrypt(encrypt(data)))
        }
    }

    @Test
    fun `sifreli dosyada icerik acikca gorunmez`() {
        val secret = "Toplantı kodu 4821".repeat(50).toByteArray()
        val file = encrypt(secret)
        assertFalse(String(file, Charsets.ISO_8859_1).contains("Toplant"))
    }

    @Test(expected = WrongPasswordException::class)
    fun `yanlis sifre reddedilir`() {
        decrypt(encrypt("merhaba".toByteArray()), "yanlış".toCharArray())
    }

    @Test
    fun `sonu kesilmis dosya fark edilir`() {
        val file = encrypt(Random(1).nextBytes(BackupCrypto.CHUNK + 500))
        val cut = file.copyOf(file.size - 600)
        assertTrue(runCatching { decrypt(cut) }.exceptionOrNull() is CorruptBackupException)
    }

    @Test
    fun `degistirilmis bayt fark edilir`() {
        val file = encrypt(Random(2).nextBytes(BackupCrypto.CHUNK + 500))
        file[file.size - 100] = (file[file.size - 100].toInt() xor 1).toByte()
        assertTrue(runCatching { decrypt(file) }.exceptionOrNull() is CorruptBackupException)
    }

    @Test
    fun `yedek olmayan dosya reddedilir`() {
        val error = runCatching { decrypt("PK\u0003\u0004 bir zip".toByteArray()) }.exceptionOrNull()
        assertTrue(error is CorruptBackupException)
    }
}
