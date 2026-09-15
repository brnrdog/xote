plugins {
  id("com.android.application")
  id("org.jetbrains.kotlin.android")
}

android {
  namespace = "dev.xote.host"
  compileSdk = 34

  defaultConfig {
    applicationId = "dev.xote.native.example"
    minSdk = 23
    targetSdk = 34
    versionCode = 1
    versionName = "0.1"
    testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
  }

  sourceSets {
    getByName("main") {
      // The bundle is built once for both platforms by `npm run native:bundle`
      // and consumed from where it lands. Copying it would be a second copy to
      // forget to update.
      assets.srcDirs("../../../bundle/dist")
    }
    getByName("androidTest") {
      // Likewise the conformance suite, which is shared with the JavaScript
      // hosts and with iOS. One file, three hosts, no drift.
      assets.srcDirs("../../../conformance")
    }
  }

  compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
  }

  kotlinOptions { jvmTarget = "17" }

  buildTypes {
    release {
      isMinifyEnabled = false
    }
  }
}

dependencies {
  androidTestImplementation("androidx.test.ext:junit:1.1.5")
  androidTestImplementation("androidx.test:runner:1.5.2")
}
