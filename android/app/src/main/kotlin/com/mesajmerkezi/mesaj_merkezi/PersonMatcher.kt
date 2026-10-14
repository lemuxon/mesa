package com.mesajmerkezi.mesaj_merkezi

import java.text.Normalizer
import java.util.Locale

/** Kişi önerisi için bir sohbetin özeti. */
data class PersonCandidate(
    val key: String,
    val packageName: String,
    val title: String,
    val isGroup: Boolean,
    val shortcutId: String? = null,
    val personId: Long? = null,
    val lastTime: Long = 0,
)

/** "Aynı kişi mi?" önerisi: iki sohbet ve neden eşleştikleri ("name" ya da "phone"). */
data class PersonSuggestion(val a: PersonCandidate, val b: PersonCandidate, val reason: String)

/**
 * Farklı uygulamalardaki sohbetlerden aynı kişiye ait olabilecekleri bulur.
 * Yalnızca öneri üretir; birleştirmeyi kullanıcı onaylar.
 *
 * Eşleşme: (1) sadeleştirilmiş ad aynı ("Yağız Arda" = "yagiz.arda" =
 * "YAGIZ_ARDA"), (2) telefon numarasının son 10 hanesi aynı (WhatsApp sohbet
 * kimliği "905…@s.whatsapp.net" ya da numara olan başlık, ör. SMS).
 * Gruplar, aynı uygulamanın iki sohbeti, zaten aynı kişide olanlar ve
 * kullanıcının "farklı kişi" dediği çiftler önerilmez.
 */
object PersonMatcher {

    private const val MIN_NAME = 4
    private val TR = Locale("tr")
    private val MARKS = Regex("\\p{M}+")

    /** Ad karşılaştırma biçimi; çok kısa ya da yalnızca rakamsa null. */
    fun nameKey(title: String): String? {
        val folded = buildString {
            for (c in title.lowercase(TR)) {
                append(
                    when (c) {
                        'ı' -> 'i'
                        'ğ' -> 'g'
                        'ş' -> 's'
                        'ç' -> 'c'
                        'ö' -> 'o'
                        'ü' -> 'u'
                        else -> c
                    }
                )
            }
        }
        val compact = Normalizer.normalize(folded, Normalizer.Form.NFD)
            .replace(MARKS, "")
            .filter { it.isLetterOrDigit() }
        if (compact.length < MIN_NAME || compact.all { it.isDigit() }) return null
        return compact
    }

    /** Telefon numarasının son 10 hanesi; numara yoksa null. */
    fun phoneKey(title: String, shortcutId: String?): String? {
        val jid = shortcutId?.takeIf { it.endsWith("@s.whatsapp.net") }?.substringBefore('@')
        val source = jid ?: title.takeIf { t -> t.all { it.isDigit() || it in " +-()" } }
        val digits = source?.filter { it.isDigit() } ?: return null
        return if (digits.length >= 10) digits.takeLast(10) else null
    }

    fun suggestions(
        candidates: List<PersonCandidate>,
        dismissed: Set<Pair<String, String>>,
        limit: Int = 10,
    ): List<PersonSuggestion> {
        val buckets = HashMap<String, MutableList<PersonCandidate>>()
        for (c in candidates) {
            if (c.isGroup) continue
            nameKey(c.title)?.let { buckets.getOrPut("name:$it") { mutableListOf() }.add(c) }
            phoneKey(c.title, c.shortcutId)?.let { buckets.getOrPut("phone:$it") { mutableListOf() }.add(c) }
        }
        val seen = HashSet<Pair<String, String>>()
        val result = ArrayList<PersonSuggestion>()
        for ((bucket, members) in buckets) {
            if (members.size < 2) continue
            val reason = bucket.substringBefore(':')
            for (i in members.indices) {
                for (j in i + 1 until members.size) {
                    val a = members[i]
                    val b = members[j]
                    if (a.packageName == b.packageName) continue
                    if (a.personId != null && a.personId == b.personId) continue
                    val pair = pairOf(a.key, b.key)
                    if (pair in dismissed || !seen.add(pair)) continue
                    result += PersonSuggestion(a, b, reason)
                }
            }
        }
        // En son yazışılanlar önce; numara eşleşmesi addan güçlü.
        return result
            .sortedWith(
                compareByDescending<PersonSuggestion> { maxOf(it.a.lastTime, it.b.lastTime) }
                    .thenBy { if (it.reason == "phone") 0 else 1 }
            )
            .take(limit)
    }

    /** Sıradan bağımsız çift (veritabanında da böyle saklanır). */
    fun pairOf(a: String, b: String): Pair<String, String> = if (a <= b) a to b else b to a
}
