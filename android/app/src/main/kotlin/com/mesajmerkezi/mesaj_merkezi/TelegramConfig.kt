package com.mesajmerkezi.mesaj_merkezi

/**
 * my.telegram.org'dan alınan uygulama kimliği. Depoya girmez:
 * android/local.properties içindeki telegram.apiId / telegram.apiHash
 * derleme sırasında BuildConfig'e yazılır (app/build.gradle.kts).
 */
object TelegramConfig {
    val apiId: Int get() = BuildConfig.TELEGRAM_API_ID
    val apiHash: String get() = BuildConfig.TELEGRAM_API_HASH
    val isConfigured: Boolean get() = apiId > 0 && apiHash.isNotBlank()
}
