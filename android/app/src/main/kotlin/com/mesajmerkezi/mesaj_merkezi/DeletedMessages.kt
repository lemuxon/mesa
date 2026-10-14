package com.mesajmerkezi.mesaj_merkezi

/**
 * Gönderen mesajı silince uygulamalar bildirimdeki metni bir etiketle
 * değiştirir (WhatsApp: "Bu mesaj silindi"). Mesa asıl metni
 * zaten kaydetmiştir: etiket yeni mesaj sayılmaz, eskisi "silindi" işaretlenir.
 */
object DeletedMessages {

    private val labels = setOf(
        "bu mesaj silindi",
        "bu mesaj silinmiştir",
        "mesaj silindi",
        "this message was deleted",
        "message deleted",
        "bu mesajı sildiniz",
        "you deleted this message",
    )

    fun isDeletedLabel(text: String): Boolean {
        val t = text.trim().removePrefix("🚫").trim().trimEnd('.').lowercase()
        return t in labels
    }
}
