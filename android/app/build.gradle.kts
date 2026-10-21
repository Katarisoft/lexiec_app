import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firma de Release: si existe android/key.properties (lo crea el workflow de Release desde
// secrets de GitHub; nunca se versiona) se usa ese keystore. Si no, se firma con la clave de
// depuración: el APK se instala igual en un emulador, pero no sirve para publicar en Play Store.
val propiedadesFirma = Properties().apply {
    val archivo = rootProject.file("key.properties")
    if (archivo.exists()) archivo.inputStream().use { load(it) }
}
val tieneFirmaPropia = propiedadesFirma.getProperty("storeFile") != null

android {
    namespace = "com.katarisoft.lexiec"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.katarisoft.lexiec"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["nombreApp"] = "LexiEC"
    }

    signingConfigs {
        if (tieneFirmaPropia) {
            create("release") {
                storeFile = file(propiedadesFirma.getProperty("storeFile"))
                storePassword = propiedadesFirma.getProperty("storePassword")
                keyAlias = propiedadesFirma.getProperty("keyAlias")
                keyPassword = propiedadesFirma.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        // Depuración: se instala como app aparte ("LexiEC (dev)") junto al APK de release,
        // que está firmado con otra clave y no se puede reemplazar por esta.
        debug {
            applicationIdSuffix = ".debug"
            manifestPlaceholders["nombreApp"] = "LexiEC (dev)"
        }
        release {
            signingConfig = signingConfigs.getByName(if (tieneFirmaPropia) "release" else "debug")
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
