package com.mesajmerkezi.mesaj_merkezi

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import javax.crypto.KeyGenerator

/** Asistanın API anahtarı şifreli saklanır, okunur ve silinir. */
@RunWith(RobolectricTestRunner::class)
class AssistantKeyTest {

    private val context: Context = ApplicationProvider.getApplicationContext()

    @Before
    fun setUp() {
        SecretBox.keyForTests = KeyGenerator.getInstance("AES").apply { init(256) }.generateKey()
        AssistantKey.clear(context)
    }

    @After
    fun tearDown() {
        AssistantKey.clear(context)
        SecretBox.keyForTests = null
    }

    @Test
    fun keyIsStoredEncryptedAndCleared() {
        assertFalse(AssistantKey.present(context))
        AssistantKey.set(context, "  sk-ant-deneme  ")
        assertEquals("sk-ant-deneme", AssistantKey.get(context))
        assertTrue(AssistantKey.present(context))
        // Diskte düz metin olarak durmaz.
        val stored = context.getSharedPreferences("assistant", Context.MODE_PRIVATE).getString("api_key", null)
        assertNotEquals("sk-ant-deneme", stored)
        assertFalse(stored!!.contains("sk-ant"))

        AssistantKey.clear(context)
        assertNull(AssistantKey.get(context))
        assertFalse(AssistantKey.present(context))
    }

    @Test
    fun keyFromAnotherDeviceIsIgnored() {
        AssistantKey.set(context, "sk-ant-deneme")
        // Güvenli donanım anahtarı değişti (başka cihaz ya da silinmiş).
        SecretBox.keyForTests = KeyGenerator.getInstance("AES").apply { init(256) }.generateKey()
        assertNull(AssistantKey.get(context))
        assertFalse(AssistantKey.present(context))
    }
}
