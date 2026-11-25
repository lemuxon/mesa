package com.mesajmerkezi.mesaj_merkezi

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone

/** Otomatik yedek: dosya adı ve budama (elle alınan yedeklere dokunulmaz). */
class AutoBackupTest {

    @Test
    fun fileNamesSortByTime() {
        val calendar = Calendar.getInstance(TimeZone.getDefault()).apply {
            clear()
            set(2026, Calendar.NOVEMBER, 25, 3, 7)
        }
        val name = AutoBackup.fileName(calendar.timeInMillis)
        assertEquals("mesa-otomatik-2026-11-25-0307.mmyedek", name)
        calendar.add(Calendar.DAY_OF_MONTH, 1)
        assertTrue(AutoBackup.fileName(calendar.timeInMillis) > name)
    }

    @Test
    fun onlyOldestAutomaticBackupsAreDeleted() {
        val names = listOf(
            "mesa-otomatik-2026-11-01-0300.mmyedek",
            "mesa-otomatik-2026-11-08-0300.mmyedek",
            "mesa-otomatik-2026-11-15-0300.mmyedek",
            "mesa-2026-11-10.mmyedek", // elle alınan
            "mesa-otomatik-2026-11-22-0300.mmyedek",
            "notlar.txt",
            "mesa-otomatik-2026-11-29-0300.mmyedek",
            "mesa-otomatik-2026-12-06-0300.mmyedek",
        )
        assertEquals(listOf("mesa-otomatik-2026-11-01-0300.mmyedek"), AutoBackup.toDelete(names))
        assertEquals(
            listOf("mesa-otomatik-2026-11-08-0300.mmyedek", "mesa-otomatik-2026-11-01-0300.mmyedek"),
            AutoBackup.toDelete(names, keep = 4),
        )
        assertTrue(AutoBackup.toDelete(names.take(3)).isEmpty())
    }
}
