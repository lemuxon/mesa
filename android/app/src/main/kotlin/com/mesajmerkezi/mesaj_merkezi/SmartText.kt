package com.mesajmerkezi.mesaj_merkezi

/**
 * Bildirim için mesajdaki doğrulama kodu ("Kodu kopyala" düğmesi). Kurallar
 * Dart tarafındaki lib/core/smart_actions.dart ile aynıdır: kod yalnızca
 * "kod", "şifre" gibi bir sözcük varsa aranır, yıllar ("2026 yılında") ve
 * ondalık sayılar kod sayılmaz. Android'e bağımlı değildir.
 */
object SmartText {

    private val codeWord = Regex(
        "(?<![\\p{L}\\p{N}])(kod|kodu|kodunuz|code|doğrulama|onay|şifre|şifreniz|parola|otp|pin|verification|tek kullanımlık)",
    )
    private val code = Regex("(?<![\\d,.])((?:G-)?\\d{3}[ -]?\\d{3}|\\d{4,8})(?![\\d,.]\\d)")
    private val year = Regex("^(19|20)\\d\\d$")
    private val yearWord = Regex("^\\s*['’]?\\s*(yıl|sene|de|da|te|ta)")

    /** Mesajdaki doğrulama kodu; yoksa null. */
    fun verificationCode(text: String?): String? {
        if (text.isNullOrBlank()) return null
        val lower = text.replace('İ', 'i').replace('I', 'ı').lowercase()
        if (!codeWord.containsMatchIn(lower)) return null
        for (m in code.findAll(text)) {
            val digits = m.groupValues[1]
            if (year.matches(digits) && yearWord.containsMatchIn(lower.substring(m.range.last + 1))) continue
            return digits.removePrefix("G-").replace(" ", "").replace("-", "")
        }
        return null
    }
}
