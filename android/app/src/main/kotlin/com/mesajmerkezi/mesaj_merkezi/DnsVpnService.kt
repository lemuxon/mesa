package com.mesajmerkezi.mesaj_merkezi

import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.RejectedExecutionException

/**
 * Yalnızca DNS taşıyan yerel VPN. Tünele sadece sanal DNS sunucusunun
 * adresi yönlendirilir; telefonun diğer trafiği tünele hiç girmez (hız ve
 * pil etkilenmez). Gelen her UDP 53 sorgusu DohClient ile şifreli olarak
 * sağlayıcıya sorulur, yanıt paketi uygulamaya geri yazılır.
 *
 * Mesa'nın kendisi tünelin dışında tutulur: DoH isteği tünele geri girip
 * döngü oluşturmasın. Mesa'nın web servisleri erişim kalkanından geçer.
 */
class DnsVpnService : VpnService() {

    private var tun: ParcelFileDescriptor? = null
    private var reader: Thread? = null
    private var workers: ExecutorService? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            shutdown("user")
            return START_NOT_STICKY
        }
        startInForeground()
        establish()
        return START_STICKY
    }

    override fun onRevoke() {
        // Kullanıcı başka bir VPN açtı ya da sistem ayarından kapattı.
        shutdown("revoked")
        super.onRevoke()
    }

    override fun onDestroy() {
        shutdown(SecureDns.lastStop ?: "user")
        instance = null
        super.onDestroy()
    }

    private fun establish() {
        SecureDns.client.provider = SecureDns.provider(this)
        if (tun != null) return
        val builder = Builder()
            .setSession("Mesa DNS")
            .addAddress(TUN_ADDRESS, 24)
            .addDnsServer(DNS_ADDRESS)
            .addRoute(DNS_ADDRESS, 32)
            .setMtu(MTU)
            .setBlocking(true)
            .setConfigureIntent(openAppIntent())
        try {
            builder.addDisallowedApplication(packageName)
        } catch (e: PackageManager.NameNotFoundException) {
            Log.w(TAG, "Mesa tünel dışına alınamadı", e)
        }
        if (Build.VERSION.SDK_INT >= 29) builder.setMetered(false)
        val fd = try {
            builder.establish()
        } catch (e: RuntimeException) {
            Log.w(TAG, "Tünel kurulamadı", e)
            null
        }
        if (fd == null) {
            // İzin geri alınmış (prepare gerekli) ya da sistem reddetti.
            shutdown("permission")
            return
        }
        setUnderlyingNetworks(null)
        tun = fd
        val pool = Executors.newFixedThreadPool(WORKERS) { r -> Thread(r, "MesaDNS-sorgu").apply { isDaemon = true } }
        workers = pool
        reader = Thread({ loop(fd, pool) }, "MesaDNS").apply {
            isDaemon = true
            start()
        }
        SecureDns.onStarted(this)
    }

    private fun loop(fd: ParcelFileDescriptor, pool: ExecutorService) {
        val input = FileInputStream(fd.fileDescriptor)
        val output = FileOutputStream(fd.fileDescriptor)
        val buffer = ByteArray(MTU)
        while (!Thread.currentThread().isInterrupted) {
            val length = try {
                input.read(buffer)
            } catch (e: IOException) {
                break // tünel kapandı
            }
            if (length < 0) break
            if (length == 0) continue
            val query = DnsPacket.parse(buffer, length) ?: continue
            try {
                pool.execute {
                    val answer = SecureDns.client.resolve(query.dns)
                    val packet = DnsPacket.response(query, answer)
                    synchronized(output) {
                        try {
                            output.write(packet)
                        } catch (e: IOException) {
                            // Tünel bu arada kapandı.
                        }
                    }
                }
            } catch (e: RejectedExecutionException) {
                break
            }
        }
    }

    private fun shutdown(reason: String) {
        val wasOpen = tun != null
        reader?.interrupt()
        reader = null
        workers?.shutdownNow()
        workers = null
        try {
            tun?.close()
        } catch (e: IOException) {
            // Zaten kapalı.
        }
        tun = null
        if (wasOpen || reason != "user") SecureDns.onStopped(this, reason)
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun openAppIntent(): PendingIntent = PendingIntent.getActivity(
        this,
        0,
        Intent(this, MainActivity::class.java),
        PendingIntent.FLAG_IMMUTABLE,
    )

    private fun startInForeground() {
        val manager = NotificationManagerCompat.from(this)
        manager.createNotificationChannel(
            NotificationChannelCompat.Builder(CHANNEL_ID, NotificationManagerCompat.IMPORTANCE_LOW)
                .setName(Lang.str(this, R.string.dns_channel))
                .setDescription(Lang.str(this, R.string.dns_channel_desc))
                .setShowBadge(false)
                .build()
        )
        val stop = PendingIntent.getService(
            this,
            0,
            Intent(this, DnsVpnService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_secure_dns)
            .setContentTitle(Lang.str(this, R.string.dns_on_title))
            .setContentText(Lang.str(this, R.string.dns_on_text, SecureDns.label(SecureDns.provider(this))))
            .setOngoing(true)
            .setSilent(true)
            .setContentIntent(openAppIntent())
            .addAction(R.drawable.ic_secure_dns, Lang.str(this, R.string.dns_stop), stop)
            .build()
        // Tür sabiti API 34'te geldi; VPN uygulamalarına "systemExempted" izinli.
        val type = if (Build.VERSION.SDK_INT >= 34) ServiceInfo.FOREGROUND_SERVICE_TYPE_SYSTEM_EXEMPTED else 0
        ServiceCompat.startForeground(this, NOTIFICATION_ID, notification, type)
    }

    companion object {
        private const val TAG = "MesaDNS"
        private const val CHANNEL_ID = "secure_dns"
        private const val NOTIFICATION_ID = 1002
        private const val ACTION_STOP = "com.mesajmerkezi.mesaj_merkezi.DNS_STOP"
        private const val TUN_ADDRESS = "10.111.222.1"
        private const val DNS_ADDRESS = "10.111.222.2"
        private const val MTU = 1500
        private const val WORKERS = 6

        @Volatile
        private var instance: DnsVpnService? = null

        /** Çalışıyorsa kapatır (ana iş parçacığında). */
        fun stopRunning(reason: String) {
            val service = instance ?: return
            ContextCompat.getMainExecutor(service).execute { service.shutdown(reason) }
        }

        /** Sağlayıcı değişince bildirimdeki ad güncellensin. */
        fun refreshNotification() {
            val service = instance ?: return
            ContextCompat.getMainExecutor(service).execute { if (service.tun != null) service.startInForeground() }
        }
    }
}
