pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
    // Membaca `android/app/google-services.json`. Dipasang di `app/` HANYA
    // kalau berkas itu ada — lihat komentar `berkasGoogleServices` di sana.
    id("com.google.gms.google-services") version "4.4.4" apply false
    // Crashlytics: menyuntikkan build ID (WAJIB — tanpa itu SDK Crashlytics
    // menolak jalan) dan mengunggah mapping R8. Diterapkan bersyarat di
    // app/build.gradle.kts, sama seperti google-services. Versi sama dengan
    // aplikasi lab.
    id("com.google.firebase.crashlytics") version "3.0.8" apply false
}

include(":app")
