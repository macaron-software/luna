plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
}

android {
    namespace = "app.luna"
    compileSdk = 35

    defaultConfig {
        applicationId = "app.luna"
        minSdk = 26      // Android 8.0 — requis pour BiometricPrompt + HealthConnect
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"

        // i18n : inclure toutes les locales configurées
        resourceConfigurations += listOf(
            "fr", "en", "es", "pt-rBR", "de", "it", "nl", "pl",
            "ru", "uk", "tr", "ja", "ko", "zh-rCN", "zh-rTW",
            "ar", "he", "fa"
        )

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"

        // RTL support obligatoire
        manifestPlaceholders["supportsRtl"] = "true"

        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
        }
    }

    buildFeatures {
        viewBinding = true
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            isMinifyEnabled = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    // Répertoires JNI — cargo-ndk génère les .so ici
    sourceSets["main"].jniLibs.srcDirs("src/main/jniLibs")
    // Kotlin généré par UniFFI
    sourceSets["main"].kotlin.srcDirs("src/main/kotlin", "src/main/generated")

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

// ── Task cargo-ndk — compile le noyau Rust ─────────────────────────────────
tasks.register<Exec>("cargoBuildRust") {
    workingDir = rootDir.resolve("../luna-core")
    commandLine(
        "cargo", "ndk",
        "--target", "arm64-v8a",
        "--target", "armeabi-v7a",
        "--target", "x86_64",
        "--output-dir", "${projectDir}/src/main/jniLibs",
        "--", "build", "--release"
    )
    description = "Build luna-core Rust library via cargo-ndk"
}

// Liez la tâche Rust au preBuild pour que Gradle l'exécute automatiquement
tasks.named("preBuild") {
    dependsOn("cargoBuildRust")
}

// ── Dépendances ────────────────────────────────────────────────────────────
dependencies {
    // Désugar pour java.time sur API < 26
    coreLibraryDesugaring(libs.desugar.jdk.libs)

    // AndroidX
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.appcompat)
    implementation(libs.androidx.fragment.ktx)
    implementation(libs.androidx.navigation.fragment.ktx)
    implementation(libs.androidx.navigation.ui.ktx)
    implementation(libs.androidx.lifecycle.viewmodel.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)

    // Material Design
    implementation(libs.material)

    // Biométrie
    implementation(libs.androidx.biometric)

    // Health Connect (optionnel phase 2)
    // implementation(libs.androidx.health.connect.client)

    // Tests
    testImplementation(libs.junit)
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)
    // a11y tests
    androidTestImplementation(libs.accessibility.test.framework)
}
