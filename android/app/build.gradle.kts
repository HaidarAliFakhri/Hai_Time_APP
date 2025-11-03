plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.hai_time_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.hai_time_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ✅ Kompatibilitas Java 11 + desugaring aktif
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
    release {
        signingConfig = signingConfigs.getByName("debug")

        // ✅ Tambahkan dua baris ini:
        isMinifyEnabled = false
        isShrinkResources = false
    }
    debug {
        isMinifyEnabled = false
        isShrinkResources = false
    }
}


    // ✅ Optional: biar build stabil di semua versi Gradle
    packagingOptions {
        resources {
            excludes.add("/META-INF/{AL2.0,LGPL2.1}")

        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ Desugaring library wajib (biar support API modern di versi Android lama)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // ✅ Kotlin stdlib
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8")

    // ✅ AndroidX Core
    implementation("androidx.core:core-ktx:1.12.0")

    // 🔔 Tambahkan ini kalau pakai notifikasi & alarm
    implementation("androidx.work:work-runtime-ktx:2.9.0")
}
