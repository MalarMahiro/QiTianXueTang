plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "cc.septnet.qitianxuetang"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "cc.septnet.qitianxuetang"
        minSdk = 24
        targetSdk = 35
        versionCode = 40601
        versionName = "4.6.1"
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
    // MTDataFilesProvider：为 MT 管理器注入文件提供器（仅 debug 版）
    debugImplementation("com.github.L-JINBIN:MTDataFilesProvider:v1.0.0")
}