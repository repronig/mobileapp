import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android Gradle and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing: copy android/key.properties.example to android/key.properties and add your keystore.
// See https://docs.flutter.dev/deployment/android#signing-the-app
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

fun keystoreProp(props: Properties, name: String): String =
    props.getProperty(name)?.trim()?.takeIf { it.isNotEmpty() }
        ?: error("key.properties: missing or blank $name")

android {
    namespace = "org.repronig.app"
    compileSdk = flutter.compileSdkVersion
    // Plugins (file_picker, secure storage, image_picker, etc.) require NDK 27+.
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "org.repronig.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProp(keystoreProperties, "keyAlias")
                keyPassword = keystoreProp(keystoreProperties, "keyPassword")
                storePassword = keystoreProp(keystoreProperties, "storePassword")
                storeFile = rootProject.file(keystoreProp(keystoreProperties, "storeFile"))
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                // Local release builds without key.properties (e.g. CI); use debug signing — not for Play Store upload.
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
