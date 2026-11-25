package com.mesajmerkezi.mesaj_merkezi

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import android.util.Log
import java.security.GeneralSecurityException
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Cihazda saklanması gereken sırlar (WireGuard yapılandırmasındaki özel
 * anahtar, otomatik yedek parolası) için şifreli kutu. Anahtar Android
 * Keystore'da durur ve dışa aktarılamaz: dosyalar kopyalansa da başka bir
 * cihazda açılamaz. Biçim: Base64(12 bayt IV + AES-256-GCM şifreli metin).
 */
object SecretBox {

    private const val TAG = "MesajMerkezi"
    private const val ALIAS = "mesa_secrets"
    private const val PROVIDER = "AndroidKeyStore"
    private const val TRANSFORMATION = "AES/GCM/NoPadding"
    private const val IV_BYTES = 12

    /** Testler için: Robolectric'te Android Keystore yok. */
    @Volatile
    internal var keyForTests: SecretKey? = null

    @Synchronized
    private fun key(): SecretKey {
        keyForTests?.let { return it }
        val store = KeyStore.getInstance(PROVIDER).apply { load(null) }
        (store.getEntry(ALIAS, null) as? KeyStore.SecretKeyEntry)?.let { return it.secretKey }
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, PROVIDER)
        generator.init(
            KeyGenParameterSpec.Builder(ALIAS, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build()
        )
        return generator.generateKey()
    }

    fun encrypt(plain: String): String {
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, key())
        val iv = cipher.iv
        check(iv.size == IV_BYTES) { "beklenmeyen IV uzunluğu" }
        val sealed = cipher.doFinal(plain.toByteArray(Charsets.UTF_8))
        return Base64.encodeToString(iv + sealed, Base64.NO_WRAP)
    }

    /** Açılamazsa (bozuk, başka cihazdan, anahtar silinmiş) null. */
    fun decrypt(box: String): String? = try {
        val bytes = Base64.decode(box, Base64.NO_WRAP)
        if (bytes.size <= IV_BYTES) {
            null
        } else {
            val cipher = Cipher.getInstance(TRANSFORMATION)
            cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, bytes, 0, IV_BYTES))
            String(cipher.doFinal(bytes, IV_BYTES, bytes.size - IV_BYTES), Charsets.UTF_8)
        }
    } catch (e: GeneralSecurityException) {
        Log.w(TAG, "Şifreli kutu açılamadı: ${e.javaClass.simpleName}")
        null
    } catch (e: IllegalArgumentException) {
        null
    }
}
