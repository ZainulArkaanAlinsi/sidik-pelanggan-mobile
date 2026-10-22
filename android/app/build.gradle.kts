import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Google Services dipasang HANYA kalau berkasnya ada — pola yang sama dengan
// aplikasi lab (`sidik-calibration-mobile/android/app/build.gradle.kts`).
//
// `google-services.json` masuk `.gitignore` (repo ini publik), jadi checkout
// bersih tidak punya berkas itu. Plugin yang dipasang tanpa syarat membuat
// `assembleDebug` GAGAL TOTAL ("File google-services.json is missing"), padahal
// sisi Dart sudah aman tanpanya: `PushPelanggan.nyalakan()` menelan kegagalan
// `Firebase.initializeApp()` dan aplikasi jalan penuh tanpa push.
//
// Taruh `android/app/google-services.json` (Firebase Console, proyek yang SAMA
// dengan aplikasi lab, aplikasi Android `com.ptsidik.pelanggan`) dan push
// langsung hidup tanpa mengubah apa pun di sini.
val berkasGoogleServices = file("google-services.json")

if (berkasGoogleServices.exists()) {
    apply(plugin = "com.google.gms.google-services")
    // Crashlytics ikut syarat yang sama: tanpa google-services.json Firebase
    // memang mati (dan pelapor Crashlytics di sisi Dart tidak dipasang).
    apply(plugin = "com.google.firebase.crashlytics")
} else {
    logger.warn(
        "[sidik-pelanggan] PERINGATAN: android/app/google-services.json tidak ada — " +
            "build jalan terus, tapi NOTIFIKASI PUSH MATI di APK ini.",
    )
}

// Kunci penanda tangan rilis — dibaca dari `android/key.properties`
// (storeFile, storePassword, keyAlias, keyPassword). Berkas itu dan keystore-nya
// TIDAK PERNAH di-commit (lihat .gitignore): repo ini publik.
//
// Play Store mengikat aplikasi ke sertifikat penanda tangan unggahan pertama
// (atau ke upload key kalau memakai Play App Signing). APK/AAB bertanda tangan
// kunci debug ditolak Play, dan pembaruan yang ditandatangani kunci berbeda
// tidak bisa dipasang di atas versi yang sudah ada di HP pelanggan.
//
// Absennya kunci TIDAK menggagalkan build: `flutter run --release` di laptop
// dan build uji coba tetap butuh jalan. Gantinya, peringatan keras di bawah
// muncul di tiap build release yang jatuh ke kunci debug.
val berkasKunciRilis = rootProject.file("key.properties")

val kunciRilis =
    Properties().apply {
        if (berkasKunciRilis.exists()) {
            berkasKunciRilis.inputStream().use { load(it) }
        }
    }

// Semua-atau-tidak-sama-sekali: `key.properties` yang terisi separuh membuat
// Gradle gagal jauh di `:app:packageRelease` dengan pesan yang tidak menyebut
// kunci mana yang bolong.
val adaKunciRilis =
    berkasKunciRilis.exists() &&
        listOf("storeFile", "storePassword", "keyAlias", "keyPassword").all {
            !kunciRilis.getProperty(it).isNullOrBlank()
        }

if (!adaKunciRilis) {
    logger.warn(
        "\n[sidik-pelanggan] ================================================================\n" +
            "[sidik-pelanggan] PERINGATAN: android/key.properties tidak ada / tidak lengkap.\n" +
            "[sidik-pelanggan] Build RELEASE ditandatangani KUNCI DEBUG.\n" +
            "[sidik-pelanggan] JANGAN diunggah ke Play Store dan JANGAN dibagikan ke pelanggan.\n" +
            "[sidik-pelanggan] ================================================================\n",
    )
}

android {
    namespace = "id.ptsidik.sidik_pelanggan"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // ID Play Store (05-Task M2-01). PERMANEN begitu unggahan pertama
        // diterima Play — mengganti ID sesudahnya = aplikasi baru, pelanggan
        // harus memasang ulang. `namespace` di atas sengaja tetap (itu cuma
        // paket kelas Kotlin/R, bukan identitas di Play).
        applicationId = "com.ptsidik.pelanggan"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Dibuat hanya kalau kuncinya ada: signing config kosong membuat
        // Gradle gagal walau jalur yang dipakai tidak pernah menyentuhnya.
        if (adaKunciRilis) {
            create("rilis") {
                // Relatif ke `android/`, tempat `key.properties` duduk.
                storeFile = rootProject.file(kunciRilis.getProperty("storeFile"))
                storePassword = kunciRilis.getProperty("storePassword")
                keyAlias = kunciRilis.getProperty("keyAlias")
                keyPassword = kunciRilis.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                if (adaKunciRilis) {
                    signingConfigs.getByName("rilis")
                } else {
                    signingConfigs.getByName("debug")
                }
        }
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
