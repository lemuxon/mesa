package com.mesajmerkezi.mesaj_merkezi

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class DeletedMessagesTest {

    @Test
    fun `whatsapp silme etiketleri taninir`() {
        assertTrue(DeletedMessages.isDeletedLabel("Bu mesaj silindi"))
        assertTrue(DeletedMessages.isDeletedLabel("🚫 Bu mesaj silindi"))
        assertTrue(DeletedMessages.isDeletedLabel("This message was deleted."))
        assertTrue(DeletedMessages.isDeletedLabel("  bu mesaj silindi  "))
    }

    @Test
    fun `icinde silindi gecen siradan mesaj etiket sayilmaz`() {
        assertFalse(DeletedMessages.isDeletedLabel("Bu mesaj silindi mi?"))
        assertFalse(DeletedMessages.isDeletedLabel("Dosya silindi"))
        assertFalse(DeletedMessages.isDeletedLabel(""))
    }
}
