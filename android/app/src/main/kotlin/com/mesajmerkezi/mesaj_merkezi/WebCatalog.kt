package com.mesajmerkezi.mesaj_merkezi

import java.net.URI

/**
 * Ferdium gibi resmi web sürümüyle eklenebilen servisler. Arayüzdeki
 * karşılığı lib/core/web_services.dart'ta; ikisi birlikte güncellenmeli.
 */
data class WebCatalogEntry(
    val id: String,
    val name: String,
    val url: String,
    val color: Int,
    /**
     * Telefon tarayıcısını "uygulamayı indirin" sayfasına yönlendiren siteler
     * masaüstü tarayıcısı kimliğiyle açılır.
     */
    val desktop: Boolean,
    /** Sayfanın içinde açılan alan adları (giriş sayfaları dahil); diğer bağlantılar tarayıcıda açılır. */
    val hosts: List<String>,
    /** Aynı servisin telefondaki uygulaması. */
    val appPackage: String?,
    /**
     * Videolar kendiliğinden oynar mı. Instagram ve TikTok akışında kendiliğinden
     * oynayan videolar telefonu yoruyordu (2026-10-11: Instagram sayfası
     * gezinirken ~1,7 çekirdek); bu sitelerde videolar dokununca oynar.
     */
    val autoplay: Boolean = true,
)

object WebCatalog {

    val entries = listOf(
        WebCatalogEntry(
            "discord", "Discord", "https://discord.com/app", 0xFF5865F2.toInt(), desktop = true,
            hosts = listOf("discord.com", "discordapp.com", "discord.gg"), appPackage = "com.discord",
        ),
        WebCatalogEntry(
            "instagram", "Instagram", "https://www.instagram.com/direct/inbox/", 0xFFE1306C.toInt(),
            desktop = false, hosts = listOf("instagram.com", "facebook.com"), appPackage = "com.instagram.android",
            autoplay = false,
        ),
        WebCatalogEntry(
            "messenger", "Messenger", "https://www.messenger.com/", 0xFF0084FF.toInt(), desktop = true,
            hosts = listOf("messenger.com", "facebook.com"), appPackage = "com.facebook.orca",
        ),
        WebCatalogEntry(
            "slack", "Slack", "https://app.slack.com/client", 0xFF611F69.toInt(), desktop = true,
            hosts = listOf("slack.com"), appPackage = "com.Slack",
        ),
        WebCatalogEntry(
            "x", "X", "https://x.com/messages", 0xFF536471.toInt(), desktop = false,
            hosts = listOf("x.com", "twitter.com"), appPackage = "com.twitter.android",
        ),
        WebCatalogEntry(
            "linkedin", "LinkedIn", "https://www.linkedin.com/messaging/", 0xFF0A66C2.toInt(), desktop = false,
            hosts = listOf("linkedin.com"), appPackage = "com.linkedin.android",
        ),
        WebCatalogEntry(
            "reddit", "Reddit", "https://chat.reddit.com/", 0xFFFF4500.toInt(), desktop = true,
            hosts = listOf("reddit.com"), appPackage = "com.reddit.frontpage",
        ),
        WebCatalogEntry(
            "snapchat", "Snapchat", "https://web.snapchat.com/", 0xFFE6C800.toInt(), desktop = true,
            hosts = listOf("snapchat.com"), appPackage = "com.snapchat.android",
        ),
        WebCatalogEntry(
            "tiktok", "TikTok", "https://www.tiktok.com/messages", 0xFF010101.toInt(), desktop = true,
            hosts = listOf("tiktok.com"), appPackage = "com.zhiliaoapp.musically",
            autoplay = false,
        ),
        WebCatalogEntry(
            "teams", "Teams", "https://teams.microsoft.com/", 0xFF6264A7.toInt(), desktop = true,
            // Kişisel hesaplar teams.live.com'a, girişler Microsoft hesap sayfalarına gider.
            hosts = listOf(
                "teams.microsoft.com", "teams.live.com", "teams.cloud.microsoft", "microsoftonline.com",
                "login.live.com", "login.microsoft.com", "account.live.com", "skype.com",
            ),
            appPackage = "com.microsoft.teams",
        ),
    )

    fun entry(id: String?) = entries.firstOrNull { it.id == id }

    /** Kullanıcının eklediği site için sayfada kalınacak alan adı. */
    fun hostsForUrl(url: String): List<String> {
        val host = hostOf(url) ?: return emptyList()
        return listOf(host.removePrefix("www."))
    }

    fun hostOf(url: String): String? = try {
        URI(url.trim()).host?.lowercase()?.takeIf { it.isNotEmpty() }
    } catch (e: Exception) {
        null
    }

    /** [host] listedeki alan adlarından biri ya da onun alt alan adı mı. */
    fun isAllowedHost(host: String?, hosts: List<String>): Boolean {
        val h = host?.lowercase()?.trimEnd('.') ?: return false
        return hosts.any { h == it || h.endsWith(".$it") }
    }

    /**
     * Köprü ve enjekte betiğin çalışacağı kökenler. Yalnızca servisin kendi
     * sayfaları bildirim gönderebilsin; reklam ya da gömülü üçüncü taraf
     * çerçeveler köprüye ulaşamaz.
     */
    fun originRules(hosts: List<String>): Set<String> =
        hosts.flatMap { listOf("https://$it", "https://*.$it") }.toSet()

    /** Kullanıcının girdiği adresi https adresine çevirir; geçersizse null. */
    fun normalizeUrl(input: String): String? {
        val trimmed = input.trim()
        if (trimmed.isEmpty() || trimmed.any { it.isWhitespace() }) return null
        val withScheme = if (trimmed.contains("://")) trimmed else "https://$trimmed"
        val uri = try {
            URI(withScheme)
        } catch (e: Exception) {
            return null
        }
        if (uri.scheme?.lowercase() != "https") return null
        val host = uri.host ?: return null
        if (!host.contains('.')) return null
        return withScheme
    }
}

/** Sekme başlığındaki okunmamış sayısı: "(3) Discord", "• Slack", "* genel - Slack". */
object WebTitles {
    /** Sayı yok ama okunmamış var. */
    const val DOT = -1

    private val counter = Regex("""^\s*[(\[]\s*(\d{1,5})\+?\s*[)\]]""")

    fun unread(title: String?): Int {
        val t = title?.trimStart() ?: return 0
        counter.find(t)?.let { return it.groupValues[1].toInt() }
        if (t.startsWith("(•)") || t.startsWith("•") || t.startsWith("* ") || t.startsWith("! ")) return DOT
        return 0
    }

    /**
     * Kullanıcıya en son [alerted] okunmamış için haber verildi; [now] için
     * yeniden haber verilmeli mi. Sayı azalınca ya da aynı kalınca hayır.
     */
    fun shouldAlert(alerted: Int, now: Int): Boolean = when {
        now == 0 -> false
        now == DOT -> alerted == 0
        alerted == 0 -> true
        alerted == DOT -> now > 1
        else -> now > alerted
    }
}

/** Sitelerin gördüğü tarayıcı kimliği. */
object WebAgents {
    /**
     * Gömülü tarayıcı kimliğindeki "wv" ve "Version/4.0" işaretleri kaldırılır;
     * bazı siteler bunları görünce girişi engelliyor ya da uygulamaya yönlendiriyor.
     */
    fun mobile(default: String): String =
        default.replace("; wv", "").replace(Regex("""Version/[\d.]+ """), "")

    /** Telefondaki Chrome sürümüyle Windows masaüstü Chrome kimliği. */
    fun desktop(default: String): String {
        val major = Regex("""Chrome/(\d+)""").find(default)?.groupValues?.get(1) ?: "130"
        return "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " +
            "(KHTML, like Gecko) Chrome/$major.0.0.0 Safari/537.36"
    }
}
