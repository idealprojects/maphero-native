extra["mapLibreArtifactGroupId"] = "io.maphero"
extra["mapLibreArtifactId"] = "android-sdk"
extra["mapLibreArtifactTitle"] = "MapHero Maps SDK for Android"
extra["mapLibreArtifactDescription"] = "MapHero Maps SDK for Android"
extra["mapLibreDeveloperName"] = "MapHero"
extra["mapLibreDeveloperId"] = "developer.ipc"
extra["mapLibreArtifactUrl"] = "https://github.com/idealprojects/maphero-native"
extra["mapLibreArtifactScmUrl"] = "scm:git@github.com:idealprojects/maphero-native.git"
extra["mapLibreArtifactLicenseName"] = "BSD"
extra["mapLibreArtifactLicenseUrl"] = "https://opensource.org/licenses/BSD-2-Clause"

val versionFilePath = rootDir.resolve("VERSION")
val versionName = if (versionFilePath.exists()) {
    versionFilePath.readText().trim()
} else {
    throw GradleException("VERSION file not found at ${versionFilePath.absolutePath}")
}

extra["versionName"] = versionName
