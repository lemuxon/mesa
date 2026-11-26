package com.mesajmerkezi.mesaj_merkezi

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/** Bildirimdeki "Kodu kopyala" için doğrulama kodu (Dart'taki kurallarla aynı). */
class SmartTextTest {

    @Test
    fun codeNextToACodeWord() {
        assertEquals("482913", SmartText.verificationCode("Doğrulama kodunuz: 482913. Kimseyle paylaşmayın."))
        assertEquals("123456", SmartText.verificationCode("G-123456 is your Google verification code."))
        assertEquals("123456", SmartText.verificationCode("ŞİFRENİZ 123 456"))
    }

    @Test
    fun noCodeWithoutAWordOrForYears() {
        assertNull(SmartText.verificationCode("Saat 482913 gibi bir sayı"))
        assertNull(SmartText.verificationCode("Kod 2026 yılında değişti"))
        assertNull(SmartText.verificationCode("Şifre 12.50 TL"))
        assertNull(SmartText.verificationCode(null))
    }
}
