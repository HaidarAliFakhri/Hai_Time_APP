import java.util.Properties

val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) load(f.inputStream())
}

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // Flutter Gradle plugin harus di bawah plugin Android & Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ppkd.haitime"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.ppkd.haitime"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    //  Kompatibilitas Java 11 + desugaring aktif
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    //  Konfigurasi tanda tangan (release)
    signingConfigs {
        if (keystoreProperties.isNotEmpty()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    //  Build types: release dan debug
    buildTypes {
        getByName("release") {
            if (signingConfigs.names.contains("release")) {
                signingConfig = signingConfigs.getByName("release")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }

        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    //  Packaging options
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    //  Desugaring library
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    //  Kotlin stdlib
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8")

    //  AndroidX Core
    implementation("androidx.core:core-ktx:1.12.0")

    //  Jika pakai notifikasi / alarm / background task
    implementation("androidx.work:work-runtime-ktx:2.9.0")
    
}
