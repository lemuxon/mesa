package com.mesajmerkezi.mesaj_merkezi

import java.util.Locale

enum class RuleAction { AUTO_REPLY, MUTE, IMPORTANT }

data class Rule(
    val id: Long,
    val name: String,
    val enabled: Boolean,
    /** Boşsa tüm desteklenen uygulamalar. */
    val packages: Set<String>,
    /** Herhangi biri mesajda geçerse eşleşir; boşsa her mesaj. */
    val keywords: List<String>,
    /** Sohbet adında ya da gönderen adında geçmeli; boşsa herkes. */
    val senderContains: String,
    val includeGroups: Boolean,
    val action: RuleAction,
    val replyText: String,
    val cooldownMinutes: Int,
    /**
     * Etkin saat aralığı, gece yarısından itibaren dakika. İkisi de null ise
     * gün boyu. Başlangıç bitişten büyükse aralık gece yarısını aşar (23:00–08:00).
     */
    val activeFrom: Int? = null,
    val activeTo: Int? = null,
    /** Etkin günler: bit 0 pazartesi … bit 6 pazar. */
    val activeDays: Int = ALL_DAYS,
) {
    /** Verilen yerel dakika ve gün (0 = pazartesi) kuralın etkin zamanında mı. */
    fun isActiveAt(minuteOfDay: Int, dayIndex: Int): Boolean {
        if (activeDays and (1 shl dayIndex) == 0) return false
        val from = activeFrom ?: return true
        val to = activeTo ?: return true
        return when {
            from == to -> true
            from < to -> minuteOfDay in from until to
            else -> minuteOfDay >= from || minuteOfDay < to
        }
    }

    fun toMap(): Map<String, Any?> = mapOf(
        "id" to id,
        "name" to name,
        "enabled" to enabled,
        "packages" to packages.toList(),
        "keywords" to keywords,
        "senderContains" to senderContains,
        "includeGroups" to includeGroups,
        "action" to action.name,
        "replyText" to replyText,
        "cooldownMinutes" to cooldownMinutes,
        "activeFrom" to activeFrom,
        "activeTo" to activeTo,
        "activeDays" to activeDays,
    )

    companion object {
        const val ALL_DAYS = 0b1111111

        /** Flutter'dan gelen harita; yeni kuralda id yok ya da 0. */
        fun fromMap(m: Map<*, *>) = Rule(
            id = (m["id"] as Number?)?.toLong() ?: 0L,
            name = m["name"] as String,
            enabled = m["enabled"] as Boolean,
            packages = (m["packages"] as List<*>).map { it as String }.toSet(),
            keywords = (m["keywords"] as List<*>).map { it as String },
            senderContains = m["senderContains"] as String,
            includeGroups = m["includeGroups"] as Boolean,
            action = RuleAction.valueOf(m["action"] as String),
            replyText = m["replyText"] as String,
            cooldownMinutes = (m["cooldownMinutes"] as Number).toInt(),
            activeFrom = (m["activeFrom"] as Number?)?.toInt(),
            activeTo = (m["activeTo"] as Number?)?.toInt(),
            activeDays = (m["activeDays"] as Number?)?.toInt() ?: ALL_DAYS,
        )
    }
}

/** Tek bir bildirimle yeni gelen mesajlar ve geldikleri sohbet. */
data class RuleInput(
    val packageName: String,
    val title: String,
    val isGroup: Boolean,
    val newIncoming: List<CapturedMessage>,
    val now: Long,
    /** [now]'ın yerel saatteki dakikası (0–1439). */
    val minuteOfDay: Int = 12 * 60,
    /** [now]'ın yerel günü: 0 = pazartesi … 6 = pazar. */
    val dayIndex: Int = 0,
)

/** Hangi kuralların çalışacağına karar verir. Android'e bağımlı değildir. */
object RuleEngine {

    /** Servis bağlanınca eski bildirimler de gelir; bunlar kural tetiklememeli. */
    const val MAX_MESSAGE_AGE_MS = 10 * 60 * 1000L

    /** Tüm sohbetlerde saatte en fazla bu kadar otomatik yanıt. */
    const val MAX_AUTO_REPLIES_PER_HOUR = 20

    /** Kural ne derse desin aynı sohbete bundan sık otomatik yanıt gitmez. */
    const val MIN_COOLDOWN_MINUTES = 5

    private val turkish = Locale.forLanguageTag("tr-TR")

    /** Büyük/küçük harfi ve I/ı/İ/i farkını yok sayan karşılaştırma biçimi. */
    fun fold(s: String) = s.lowercase(turkish).replace('ı', 'i')

    fun matches(rule: Rule, input: RuleInput): Boolean {
        if (!rule.enabled) return false
        if (!rule.isActiveAt(input.minuteOfDay, input.dayIndex)) return false
        if (rule.packages.isNotEmpty() && input.packageName !in rule.packages) return false
        if (input.isGroup && !rule.includeGroups) return false

        val recent = input.newIncoming.filter {
            !it.outgoing && input.now - it.time <= MAX_MESSAGE_AGE_MS
        }
        if (recent.isEmpty()) return false

        val sender = fold(rule.senderContains.trim())
        if (sender.isNotEmpty() &&
            sender !in fold(input.title) &&
            recent.none { sender in fold(it.sender.orEmpty()) }
        ) return false

        val keywords = rule.keywords.map { fold(it.trim()) }.filter { it.isNotEmpty() }
        if (keywords.isEmpty()) return true
        return recent.any { m ->
            val text = fold(m.text)
            keywords.any { it in text }
        }
    }

    /**
     * Bu mesajlar için çalışacak kurallar, sırasıyla. Otomatik yanıt döngüye
     * girmesin diye: aynı partiye en fazla bir yanıt, kural+sohbet başına
     * bekleme süresi ve saatlik genel üst sınır.
     *
     * @param lastAutoReply kuralın bu sohbete en son ne zaman yanıt verdiği
     */
    fun decide(
        rules: List<Rule>,
        input: RuleInput,
        lastAutoReply: (ruleId: Long) -> Long?,
        autoRepliesLastHour: Int,
    ): List<Rule> {
        var replied = false
        return rules.filter { rule ->
            if (!matches(rule, input)) return@filter false
            if (rule.action != RuleAction.AUTO_REPLY) return@filter true
            if (replied || rule.replyText.isBlank()) return@filter false
            if (autoRepliesLastHour >= MAX_AUTO_REPLIES_PER_HOUR) return@filter false
            val cooldownMs = maxOf(rule.cooldownMinutes, MIN_COOLDOWN_MINUTES) * 60_000L
            val last = lastAutoReply(rule.id)
            if (last != null && input.now - last < cooldownMs) return@filter false
            replied = true
            true
        }
    }
}
