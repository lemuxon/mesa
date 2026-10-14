package com.mesajmerkezi.mesaj_merkezi

/**
 * Yalnızca bu uygulamaların bildirimleri okunur; banka, SMS kodu vb. diğer
 * bildirimlere hiç dokunulmaz. Arayüzdeki adlar ve renkler lib/core/apps.dart'ta;
 * buradakiler birleşik bildirimler için ve onlarla aynı tutulmalı.
 */
object SupportedApps {
    /** TDLib bağlantısı açıkken bildirimleri yok sayılan Telegram istemcileri. */
    val telegramPackages = setOf(
        "org.telegram.messenger",
        "org.telegram.messenger.web",
        "org.thunderdog.challegram",
    )

    private class App(val name: String, val color: Int)

    private val apps = mapOf(
        "com.whatsapp" to App("WhatsApp", 0xFF25D366.toInt()),
        "com.whatsapp.w4b" to App("WhatsApp Business", 0xFF128C7E.toInt()),
        "org.telegram.messenger" to App("Telegram", 0xFF229ED9.toInt()),
        "org.telegram.messenger.web" to App("Telegram", 0xFF229ED9.toInt()),
        "org.thunderdog.challegram" to App("Telegram X", 0xFF229ED9.toInt()),
        "com.instagram.android" to App("Instagram", 0xFFE1306C.toInt()),
        "com.facebook.orca" to App("Messenger", 0xFF0084FF.toInt()),
        "com.facebook.mlite" to App("Messenger Lite", 0xFF0084FF.toInt()),
        "org.thoughtcrime.securesms" to App("Signal", 0xFF3A76F0.toInt()),
        "com.discord" to App("Discord", 0xFF5865F2.toInt()),
        "com.viber.voip" to App("Viber", 0xFF7360F2.toInt()),
        "jp.naver.line.android" to App("LINE", 0xFF06C755.toInt()),
        "com.snapchat.android" to App("Snapchat", 0xFFE6C800.toInt()),
        "com.twitter.android" to App("X", 0xFF536471.toInt()),
        "com.linkedin.android" to App("LinkedIn", 0xFF0A66C2.toInt()),
        "com.microsoft.teams" to App("Teams", 0xFF6264A7.toInt()),
        "com.Slack" to App("Slack", 0xFF611F69.toInt()),
        "com.reddit.frontpage" to App("Reddit", 0xFFFF4500.toInt()),
        "com.zhiliaoapp.musically" to App("TikTok", 0xFF010101.toInt()),
        "com.ss.android.ugc.trill" to App("TikTok", 0xFF010101.toInt()),
        "com.kakao.talk" to App("KakaoTalk", 0xFFFEE500.toInt()),
        "com.google.android.apps.messaging" to App("SMS", 0xFF1A73E8.toInt()),
        "com.samsung.android.messaging" to App("SMS", 0xFF1A73E8.toInt()),
    )

    val packages: Set<String> = apps.keys

    fun name(packageName: String) =
        if (WebServices.isWebPackage(packageName)) WebServices.nameOf(packageName)
        else apps[packageName]?.name ?: packageName

    fun color(packageName: String) =
        if (WebServices.isWebPackage(packageName)) WebServices.colorOf(packageName)
        else apps[packageName]?.color ?: 0xFF607D8B.toInt()
}
