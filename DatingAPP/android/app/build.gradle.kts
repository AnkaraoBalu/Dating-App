import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.matchify.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications (notification banners).
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.matchify.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storePassword = keystoreProperties["storePassword"] as String
                val storeFileName = keystoreProperties["storeFile"] as String
                // key.properties lives in android/; keystore is beside it (not under app/).
                val resolved =
                    listOf(
                        rootProject.file(storeFileName),
                        rootProject.file("app/$storeFileName"),
                    ).firstOrNull { it.isFile }
                        ?: error(
                            "Keystore '$storeFileName' not found under android/ or android/app/.",
                        )
                storeFile = resolved
            }
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig =
                if (keystorePropertiesFile.exists()) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // FaceTec Device SDK local package supplied in the repository root.
    implementation(files("../../../FaceTecSDK-android-10.1.20/facetec-sdk-10.1.20.aar"))
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}
