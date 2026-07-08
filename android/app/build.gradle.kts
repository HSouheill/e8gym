import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.e8gym.e8gym"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // Configure signing
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
                ?: error("keyAlias not found in key.properties")
            keyPassword = keystoreProperties["keyPassword"] as String
                ?: error("keyPassword not found in key.properties")
            storeFile = file("e8gym-release-key.keystore")
            storePassword = keystoreProperties["storePassword"] as String
                ?: error("storePassword not found in key.properties")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.e8gym.e8gym"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Add security configurations
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        
        debug {
            // Debug configuration
            isDebuggable = true
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
    
    // Add security configurations
    packagingOptions {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
    
    // Enable R8 for better code optimization
    buildFeatures {
        buildConfig = true
    }
}

flutter {
    source = "../.."
}
