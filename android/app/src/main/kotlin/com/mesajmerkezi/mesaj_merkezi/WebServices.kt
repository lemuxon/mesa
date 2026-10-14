package com.mesajmerkezi.mesaj_merkezi

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/** Kullanıcının eklediği bir web servisi (aynı servisten ikinci hesap da olabilir). */
data class WebService(
    /** "discord", ikinci hesap "discord-2", kullanıcı sitesi "site-<zaman>". */
    val id: String,
    /** WebCatalog kimliği; kullanıcının kendi eklediği sitede null. */
    val catalogId: String?,
    val name: String,
    val url: String,
    val desktop: Boolean,
    /** Masaüstü sayfası telefona sığdırılır (1024 piksel genişlikte çizilip küçültülür). */
    val wide: Boolean = false,
    /** Uygulama kapalıyken de açık tutulur ve bildirim gelir. */
    val background: Boolean = true,
    /** Sitenin bildirimleri Mesa'ya alınır. */
    val notify: Boolean = true,
    /** Yazı boyutu yüzdesi. */
    val zoom: Int = 100,
    /** Videolar kendiliğinden oynar; kapalıysa dokununca oynar. */
    val autoplay: Boolean = true,
) {
    val catalog get() = WebCatalog.entry(catalogId)

    val hosts: List<String> get() = catalog?.hosts ?: WebCatalog.hostsForUrl(url)

    val color: Int get() = catalog?.color ?: 0xFF546E7A.toInt()

    val packageName get() = WebServices.PACKAGE_PREFIX + id

    fun toJson(): JSONObject = JSONObject()
        .put("id", id)
        .put("catalogId", catalogId)
        .put("name", name)
        .put("url", url)
        .put("desktop", desktop)
        .put("wide", wide)
        .put("background", background)
        .put("notify", notify)
        .put("zoom", zoom)
        .put("autoplay", autoplay)

    companion object {
        fun fromJson(o: JSONObject) = WebService(
            id = o.getString("id"),
            catalogId = o.optString("catalogId").takeIf { it.isNotEmpty() && it != "null" },
            name = o.getString("name"),
            url = o.getString("url"),
            desktop = o.optBoolean("desktop"),
            wide = o.optBoolean("wide"),
            background = o.optBoolean("background", true),
            notify = o.optBoolean("notify", true),
            zoom = o.optInt("zoom", 100),
            autoplay = o.optBoolean("autoplay", WebCatalog.entry(o.optString("catalogId"))?.autoplay ?: true),
        )
    }
}

/**
 * Eklenen web servislerinin listesi (cihazda, "web_services" tercih dosyasında).
 * Sohbet anahtarı "web|<servis>|<başlık>", paket adı "web:<servis>".
 */
object WebServices {
    const val PACKAGE_PREFIX = "web:"
    const val KEY_PREFIX = "web|"
    private const val PREFS = "web_services"
    private const val LIST = "list"

    @Volatile
    private var cache: List<WebService>? = null

    fun all(context: Context): List<WebService> = cache ?: synchronized(this) {
        cache ?: load(context).also { cache = it }
    }

    fun get(context: Context, id: String) = all(context).firstOrNull { it.id == id }

    fun anyBackground(context: Context) = all(context).any { it.background }

    private fun load(context: Context): List<WebService> {
        val raw = prefs(context).getString(LIST, null) ?: return emptyList()
        return try {
            val array = JSONArray(raw)
            (0 until array.length()).map { WebService.fromJson(array.getJSONObject(it)) }
        } catch (e: org.json.JSONException) {
            emptyList()
        }
    }

    @Synchronized
    private fun save(context: Context, services: List<WebService>) {
        val array = JSONArray().apply { services.forEach { put(it.toJson()) } }
        prefs(context).edit().putString(LIST, array.toString()).apply()
        cache = services
    }

    /** Katalogdaki servisi ekler; aynısı varsa ikinci hesap olarak. */
    @Synchronized
    fun addFromCatalog(context: Context, catalogId: String): WebService? {
        val entry = WebCatalog.entry(catalogId) ?: return null
        val existing = all(context)
        val count = existing.count { it.catalogId == catalogId }
        val id = if (count == 0) entry.id else uniqueId(existing, "${entry.id}-${count + 1}")
        val name = if (count == 0) entry.name else "${entry.name} ${count + 1}"
        val service = WebService(id, entry.id, name, entry.url, entry.desktop, autoplay = entry.autoplay)
        save(context, existing + service)
        return service
    }

    @Synchronized
    fun addCustom(context: Context, name: String, url: String): WebService? {
        val normalized = WebCatalog.normalizeUrl(url) ?: return null
        val existing = all(context)
        val service = WebService(
            id = uniqueId(existing, "site-${System.currentTimeMillis().toString(36)}"),
            catalogId = null,
            name = name.trim().ifEmpty { WebCatalog.hostOf(normalized) ?: "Site" },
            url = normalized,
            desktop = false,
        )
        save(context, existing + service)
        return service
    }

    @Synchronized
    fun update(context: Context, id: String, change: (WebService) -> WebService): WebService? {
        var updated: WebService? = null
        save(context, all(context).map { if (it.id == id) change(it).also { s -> updated = s } else it })
        return updated
    }

    @Synchronized
    fun remove(context: Context, id: String) {
        save(context, all(context).filterNot { it.id == id })
        WebIcons.delete(context, id)
    }

    private fun uniqueId(existing: List<WebService>, wanted: String): String {
        var id = wanted
        var n = 2
        while (existing.any { it.id == id }) id = "$wanted-${n++}"
        return id
    }

    fun isWebKey(key: String) = key.startsWith(KEY_PREFIX)

    fun isWebPackage(packageName: String) = packageName.startsWith(PACKAGE_PREFIX)

    fun idOfPackage(packageName: String) = packageName.removePrefix(PACKAGE_PREFIX)

    /** "web|discord|Ahmet" → "discord". */
    fun idOfKey(key: String) = key.removePrefix(KEY_PREFIX).substringBefore('|')

    fun keyFor(id: String, title: String) = "$KEY_PREFIX$id|$title"

    /** Önbellekteki listeden ad (bağlamsız çağrılar için; liste henüz okunmadıysa paket adı). */
    fun nameOf(packageName: String): String {
        val id = idOfPackage(packageName)
        return cache?.firstOrNull { it.id == id }?.name ?: WebCatalog.entry(id)?.name ?: "Web"
    }

    fun colorOf(packageName: String): Int {
        val id = idOfPackage(packageName)
        return cache?.firstOrNull { it.id == id }?.color ?: WebCatalog.entry(id)?.color ?: 0xFF546E7A.toInt()
    }

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
