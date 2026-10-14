package com.mesajmerkezi.mesaj_merkezi

import android.app.Activity
import android.content.pm.PackageManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Web servisleri ekranının (lib/core/web_services.dart) yerel tarafı. */
class WebChannel(private val activity: Activity) {

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "mesaj_merkezi/web").setMethodCallHandler(::onCall)
        EventChannel(messenger, "mesaj_merkezi/web_events").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    WebHost.onChanged = { events.success(null) }
                }

                override fun onCancel(arguments: Any?) {
                    WebHost.onChanged = null
                }
            }
        )
    }

    private fun onCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "catalog" -> result.success(
                WebCatalog.entries.map { entry ->
                    mapOf(
                        "id" to entry.id,
                        "name" to entry.name,
                        "color" to entry.color,
                        "appInstalled" to (entry.appPackage?.let(::isInstalled) ?: false),
                        // Kuruluysa arayüz uygulamanın gerçek simgesini gösterir.
                        "appPackage" to entry.appPackage?.takeIf(::isInstalled),
                    )
                }
            )
            "services" -> result.success(WebHost.describe(activity))
            "apps" -> {
                // Okunmamış sayıları veritabanından; işi ana iş parçacığı dışında yap.
                Hub.io.execute {
                    val unread = Hub.store(activity).unreadByPackage()
                    val apps = installedApps().map { (name, packages) ->
                        mapOf(
                            "package" to packages.first(),
                            "name" to name,
                            "color" to SupportedApps.color(packages.first()),
                            "unread" to packages.sumOf { unread[it] ?: 0 },
                        )
                    }
                    activity.runOnUiThread { result.success(apps) }
                }
            }
            "openApp" -> {
                val launch = activity.packageManager.getLaunchIntentForPackage(call.argument<String>("package")!!)
                if (launch == null) {
                    result.success(false)
                } else {
                    activity.startActivity(launch)
                    result.success(true)
                }
            }
            "profilesSupported" -> result.success(WebHost.profilesSupported())
            "add" -> {
                val catalogId = call.argument<String>("catalogId")
                val service = if (catalogId != null) {
                    WebServices.addFromCatalog(activity, catalogId)
                } else {
                    WebServices.addCustom(activity, call.argument<String>("name").orEmpty(), call.argument<String>("url").orEmpty())
                }
                if (service == null) {
                    result.error("INVALID_URL", null, null)
                    return
                }
                ConnectionService.refresh(activity)
                WebHost.onChanged?.invoke()
                result.success(service.id)
            }
            "update" -> {
                val id = call.argument<String>("id")!!
                WebServices.update(activity, id) { s ->
                    s.copy(
                        name = call.argument<String>("name")?.trim()?.takeIf { it.isNotEmpty() } ?: s.name,
                        background = call.argument<Boolean>("background") ?: s.background,
                        notify = call.argument<Boolean>("notify") ?: s.notify,
                        autoplay = call.argument<Boolean>("autoplay") ?: s.autoplay,
                    )
                }
                if (call.argument<Boolean>("autoplay") != null) WebHost.reload(activity, id)
                ConnectionService.refresh(activity)
                WebHost.sync(activity)
                WebHost.onChanged?.invoke()
                result.success(null)
            }
            "remove" -> {
                WebHost.remove(activity, call.argument<String>("id")!!)
                result.success(null)
            }
            "logout" -> result.success(WebHost.logout(activity, call.argument<String>("id")!!))
            "open" -> {
                val id = call.argument<String>("id")!!
                WebServiceActivity.open(activity, id, null)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    /** Telefonda kurulu desteklenen mesajlaşma uygulamaları, adına göre tek kez (ör. iki Telegram). */
    private fun installedApps(): List<Pair<String, List<String>>> =
        SupportedApps.packages.filter(::isInstalled)
            .groupBy { SupportedApps.name(it) }
            .map { (name, packages) -> name to packages }
            .sortedBy { it.first.lowercase() }

    private fun isInstalled(packageName: String) = try {
        activity.packageManager.getPackageInfo(packageName, 0)
        true
    } catch (e: PackageManager.NameNotFoundException) {
        false
    }
}
