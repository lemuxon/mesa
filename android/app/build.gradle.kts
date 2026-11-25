import java.util.Properties

// my.telegram.org'dan alinan Telegram uygulama kimligi. Depoya girmez:
// android/local.properties icine telegram.apiId=... ve telegram.apiHash=... yazilir.
// Yoksa Telegram baglantisi devre disi kalir, uygulamanin geri kalani calisir.
val localProperties = Properties().apply {
    val file = rootProject.file("local.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val telegramApiId = localProperties.getProperty("telegram.apiId", "0").trim().toIntOrNull() ?: 0
val telegramApiHash = localProperties.getProperty("telegram.apiHash", "").trim()
require(telegramApiHash.all { it.isLetterOrDigit() }) { "telegram.apiHash yalnizca harf ve rakam icermeli" }

// GitHub'da yayinlanan APK'lar kalici yayin anahtariyla imzalanir: MESA_RELEASE_SIGNING=1
// ve android/key.properties (depoya girmez) gerekir. Diger derlemeler debug anahtariyla
// imzalanir; gelistirme telefonundaki kurulum da oyle kalir (imza degisirse uzerine
// kurulamaz, veri silinmesi gerekirdi).
val publicSigning = System.getenv("MESA_RELEASE_SIGNING") == "1"
val keyProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (publicSigning) {
        require(file.exists()) { "MESA_RELEASE_SIGNING=1 ama android/key.properties yok" }
        file.inputStream().use { load(it) }
    }
}

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.mesajmerkezi.mesaj_merkezi"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.mesajmerkezi.mesaj_merkezi"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Baslaticida ve bildirim erisimi listesinde gorunen ad (debug: "Mesa Dev").
        manifestPlaceholders["appLabel"] = "Mesa"
        buildConfigField("int", "TELEGRAM_API_ID", telegramApiId.toString())
        buildConfigField("String", "TELEGRAM_API_HASH", "\"$telegramApiHash\"")
    }

    signingConfigs {
        if (publicSigning) {
            create("public") {
                storeFile = file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        debug {
            // Gelistirme derlemesi telefondaki yayin surumunun yanina ayri bir
            // uygulama ("Mesa Dev") olarak kurulur. Imzalar farkli oldugu icin
            // ayni paket adiyla kurmak, yayin surumunu kaldirip mesajlari
            // silmeyi gerektirirdi.
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
            manifestPlaceholders["appLabel"] = "Mesa Dev"
        }
        release {
            signingConfig = signingConfigs.getByName(if (publicSigning) "public" else "debug")
            // TDLib'in yerel kodu Java siniflarini adiyla arar (bkz. proguard-rules.pro).
            proguardFiles("proguard-rules.pro")
        }
    }

    // Robolectric: veritabani ve bildirim ayristirma testleri gercek Android
    // siniflariyla bilgisayarda calisir (yalnizca test; uygulamaya girmez).
    testOptions {
        unitTests.isIncludeAndroidResources = true
        // Turkce yerel ayarda Robolectric'in Conscrypt'i "windows"u "wındows" yapip
        // yerel kitapligini bulamiyor (I/ı tuzagi). Turkce'ye ozgu testler
        // yerel ayari kendileri secer.
        unitTests.all { it.jvmArgs("-Duser.language=en", "-Duser.country=US") }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// Robolectric test kaynaklari paketlenmeden once Flutter varliklari kopyalanmis olmali.
tasks.matching { it.name.matches(Regex("package(\\w+)UnitTestForUnitTest")) }.configureEach {
    val variant = name.removePrefix("package").removeSuffix("UnitTestForUnitTest")
    dependsOn("copyFlutterAssets$variant")
}

// Robolectric'in Android kitapliklari Gradle ile indirilir (onbellek, yeniden
// deneme) ve testler cevrimdisi calisir. Robolectric'in kendi indiricisi testin
// ortasinda Maven'a cikiyor ve CI'da basarisiz oluyordu. Testler sdk=34 ile
// calisir (robolectric.properties); Robolectric 4.14 en yeni desteklenen SDK'nin
// (35) kitapligini da ister. Robolectric ya da sdk degisirse surumler, testin
// "Path is not a file: ...android-all-instrumented-<surum>.jar" hatasindaki
// surumlerle guncellenmeli. Ayni modulun iki surumu tek yapilandirmada cakisir
// (Gradle yalnizca yenisini tutar), bu yuzden her surume ayri yapilandirma.
val robolectricAndroidAll = listOf(
    "14-robolectric-10818077-i7",
    "15-robolectric-12650502-i7",
).mapIndexed { index, version ->
    configurations.create("robolectricAndroidAll$index") { isTransitive = false }.also {
        dependencies.add(it.name, "org.robolectric:android-all-instrumented:$version")
    }
}
val robolectricJars = tasks.register<Sync>("robolectricJars") {
    from(robolectricAndroidAll)
    into(layout.buildDirectory.dir("robolectric-jars"))
}
tasks.withType<Test>().configureEach {
    dependsOn(robolectricJars)
    val jars = robolectricJars.map { it.destinationDir.absolutePath }
    jvmArgumentProviders.add(CommandLineArgumentProvider {
        listOf("-Drobolectric.offline=true", "-Drobolectric.dependency.dir=${jars.get()}")
    })
}

dependencies {
    // MessagingStyle ayristirma, RemoteInput ile yanit, bildirim erisimi kontrolu.
    implementation("androidx.core:core-ktx:1.13.1")
    // Uygulama kilidi (local_auth): eski Android surumlerinde biyometrik pencere AppCompat temasi ister.
    implementation("androidx.appcompat:appcompat:1.7.0")
    // Web servisleri: servis basina ayri cerez profili, sayfa basi betik ve guvenli kopru.
    implementation("androidx.webkit:webkit:1.14.0")
    // Web servisi ekrani da uygulama kilidine uysun (local_auth ile ayni surum).
    implementation("androidx.biometric:biometric:1.1.0")
    // Tam VPN: kullanicinin WireGuard yapilandirmasi (resmi kitaplik, Apache 2.0).
    implementation("com.wireguard.android:tunnel:1.0.20260102")
    // Otomatik sifreli yedek: duzenli arka plan isi.
    implementation("androidx.work:work-runtime-ktx:2.12.0")
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.robolectric:robolectric:4.14.1")
    testImplementation("androidx.test:core:1.6.1")
}
