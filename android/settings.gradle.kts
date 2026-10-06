@file:Suppress("UNCHECKED_CAST")

try {
    val processEnvClass = Class.forName("java.lang.ProcessEnvironment")
    val fields = listOf("theEnvironment", "theUnmodifiableEnvironment", "theCaseInsensitiveEnvironment")
    for (fieldName in fields) {
        try {
            val field = processEnvClass.getDeclaredField(fieldName)
            field.isAccessible = true
            val map = field.get(null) as? MutableMap<String, String>
            map?.remove("ANDROID_PREFS_ROOT")
        } catch (_: Throwable) {}
    }
} catch (_: Throwable) {}

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
}

include(":app")