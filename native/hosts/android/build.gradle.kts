// Nothing about the host needs a particular Gradle version; this is here so the
// repository does not have to carry a wrapper it cannot run.
plugins {
  id("com.android.application") version "8.5.0" apply false
  id("org.jetbrains.kotlin.android") version "1.9.24" apply false
}
