package com.mesajmerkezi.mesaj_merkezi

import android.util.Log
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.ThreadPoolExecutor
import java.util.concurrent.TimeUnit

/**
 * Sıralı, tek iş parçacıklı yürütücü; bir işteki beklenmedik hata yalnızca
 * kaydedilir. Android'de yakalanmamış hata tüm süreci (bildirim dinleyicisi,
 * Telegram, web servisleri dahil) düşürür: dolu disk ya da bozuk bir kayıt
 * yüzünden bir mesajın işlenememesi uygulamayı kapatmamalı.
 */
class SafeExecutor(private val name: String) :
    ThreadPoolExecutor(1, 1, 0L, TimeUnit.MILLISECONDS, LinkedBlockingQueue()) {

    override fun execute(command: Runnable) {
        super.execute {
            try {
                command.run()
            } catch (e: Exception) {
                Log.e(TAG, "$name işi başarısız: ${e.javaClass.simpleName}", e)
            }
        }
    }

    private companion object {
        const val TAG = "MesajMerkezi"
    }
}
