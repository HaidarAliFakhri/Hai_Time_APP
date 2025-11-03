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

    // ✅ Tambahkan bagian ini (desugaring aktif + kompatibilitas Java 11)
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true // WAJIB agar flutter_local_notifications jalan
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ Tambahkan library ini (wajib untuk desugaring)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // ✅ Pastikan ada kotlin stdlib
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8")

    // Tambahkan dependency lain jika diperlukan
    implementation("androidx.core:core-ktx:1.12.0")
}
