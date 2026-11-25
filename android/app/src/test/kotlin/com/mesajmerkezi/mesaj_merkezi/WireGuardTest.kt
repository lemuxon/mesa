package com.mesajmerkezi.mesaj_merkezi

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import javax.crypto.KeyGenerator

/** Şifreli kutu ve WireGuard yapılandırmalarının içe aktarılması. */
@RunWith(RobolectricTestRunner::class)
class WireGuardTest {

    private val context: Context = ApplicationProvider.getApplicationContext()

    private val privateKey = "yAnz5TF+lXXJte14tji3zlMNq+hd2rYUIgJBgB3fBmk="
    private val config = """
        [Interface]
        PrivateKey = $privateKey
        Address = 10.64.0.2/32, fd00::2/128
        DNS = 1.1.1.1

        [Peer]
        PublicKey = xTIBA5rboUvnH4htodjb6e697QjLERt1NAB4mZqp8Dg=
        AllowedIPs = 0.0.0.0/0, ::/0
        Endpoint = vpn.example.com:51820
    """.trimIndent()

    @Before
    fun softwareKey() {
        // Robolectric'te Android Keystore yok: aynı biçimde yazılımsal AES anahtarı.
        SecretBox.keyForTests = KeyGenerator.getInstance("AES").apply { init(256) }.generateKey()
        context.getSharedPreferences("wireguard", Context.MODE_PRIVATE).edit().clear().commit()
    }

    @After
    fun reset() {
        SecretBox.keyForTests = null
    }

    @Test
    fun secretBoxRoundTripAndTamperDetection() {
        val box = SecretBox.encrypt("gizli parola")
        assertNotEquals("gizli parola", box)
        assertEquals("gizli parola", SecretBox.decrypt(box))
        // Aynı metin her seferinde farklı şifrelenir (rastgele IV).
        assertNotEquals(box, SecretBox.encrypt("gizli parola"))
        val bytes = android.util.Base64.decode(box, android.util.Base64.NO_WRAP)
        bytes[bytes.size - 1] = (bytes.last().toInt() xor 1).toByte()
        assertNull(SecretBox.decrypt(android.util.Base64.encodeToString(bytes, android.util.Base64.NO_WRAP)))
        assertNull(SecretBox.decrypt("bozuk"))
    }

    @Test
    fun importedConfigIsListedWithoutSecrets() {
        val (id, error) = WireGuardVpn.import(context, "Ev sunucusu.conf", config)
        assertNull(error)
        assertNotNull(id)
        val stored = context.getSharedPreferences("wireguard", Context.MODE_PRIVATE).all.values.joinToString()
        assertFalse("özel anahtar düz metin saklanmamalı", stored.contains(privateKey))

        val tunnel = WireGuardVpn.list(context).single()
        assertEquals("Ev sunucusu", tunnel["name"])
        assertEquals(listOf("vpn.example.com:51820"), tunnel["endpoints"])
        assertEquals(listOf("1.1.1.1"), tunnel["dns"])
        assertEquals(true, tunnel["fullTunnel"])
        assertFalse(tunnel.values.joinToString().contains(privateKey))
    }

    @Test
    fun invalidConfigsAreRejectedWithAReason() {
        val (id, error) = WireGuardVpn.import(context, "x", "[Interface]\nPrivateKey = kısa\n")
        assertNull(id)
        assertTrue(error!!.startsWith("BAD_CONFIG"))
        val noPeer = WireGuardVpn.import(context, "x", config.substringBefore("[Peer]"))
        assertEquals("NO_PEER", noPeer.second)
        assertTrue(WireGuardVpn.list(context).isEmpty())
    }

    @Test
    fun configThatCannotBeDecryptedIsMarkedBroken() {
        val (id, _) = WireGuardVpn.import(context, "Eski", config)
        // Telefon sıfırlanıp Keystore anahtarı değişmiş gibi.
        SecretBox.keyForTests = KeyGenerator.getInstance("AES").apply { init(256) }.generateKey()
        val tunnel = WireGuardVpn.list(context).single()
        assertEquals(id, tunnel["id"])
        assertEquals(true, tunnel["broken"])
        var removed = false
        WireGuardVpn.remove(context, id!!) { removed = true }
        assertTrue(removed)
        assertTrue(WireGuardVpn.list(context).isEmpty())
    }
}
