package com.mesajmerkezi.mesaj_merkezi

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class NamesTest {

    @Test
    fun `WhatsApp yon isareti ayni grubu bolmez`() {
        // 2026-10-09 cihazda: "\u200EÖrnek Grup" ile "Örnek Grup" iki ayrı sohbet oluyordu.
        assertEquals("Örnek Grup", Names.title("\u200EÖrnek Grup"))
        assertEquals(Names.title("Örnek Grup"), Names.title("\u200EÖrnek Grup"))
    }

    @Test
    fun `yon yalitici ve sifir genislikli karakterler atilir`() {
        assertEquals("Ali Veli", Names.normalize("⁨Ali⁩ ​Veli‬﻿"))
    }

    @Test
    fun `emoji birlestiricisi korunur`() {
        val family = "Aile 👨‍👩‍👧"
        assertEquals(family, Names.normalize(family))
    }

    @Test
    fun `bosluklar sadelesir`() {
        assertEquals("Ali Veli", Names.normalize("  Ali \n\t Veli "))
    }

    @Test
    fun `sayac eki baslktan atilir`() {
        assertEquals("Ali", Names.title("Ali (3 mesaj)"))
        assertEquals("Aile", Names.title("\u200EAile (2 new messages)"))
    }

    @Test
    fun `birebir sohbette kullanici yanit verince baslik Siz olmaz`() {
        // 2026-10-09 cihazda: yanıttan sonra WhatsApp bildirim başlığını "Siz" yaptı.
        assertEquals(
            "Burak",
            Names.conversationTitle(null, "Siz", isGroup = false, lastIncomingSender = "Burak", userName = "Siz"),
        )
    }

    @Test
    fun `yalnizca kendi mesajlarimiz varsa sohbet belirsizdir`() {
        assertNull(Names.conversationTitle(null, "Siz", isGroup = false, lastIncomingSender = null, userName = "Siz"))
    }

    @Test
    fun `konusma basligi varsa o kullanilir`() {
        assertEquals(
            "Aile",
            Names.conversationTitle("‎Aile", "Aile: Ali", isGroup = true, lastIncomingSender = "Ali", userName = "Siz"),
        )
    }

    @Test
    fun `grup basligi yoksa bildirim basligina dusulur`() {
        assertEquals("Aile", Names.conversationTitle(null, "Aile", isGroup = true, lastIncomingSender = "Ali", userName = "Siz"))
    }

    @Test
    fun `yalnizca gorunmez karakterden olusan ad bos sayilir`() {
        assertNull(Names.normalize("\u200E‏"))
        assertNull(Names.title(null))
    }
}
