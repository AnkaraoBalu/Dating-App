allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

fun Project.forceCompileSdk36() {
    val android = extensions.findByName("android") ?: return
    try {
        android.javaClass
            .getMethod("setCompileSdk", Int::class.javaPrimitiveType)
            .invoke(android, 36)
    } catch (_: Throwable) {
        try {
            android.javaClass
                .getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                .invoke(android, 36)
        } catch (_: Throwable) {
            // Non-Android / API mismatch.
        }
    }
}

// Plugins like flutter_ringtone_player still declare compileSdk 33; force 36
// so AAR metadata checks pass against current AndroidX.
subprojects {
    if (state.executed) {
        forceCompileSdk36()
    } else {
        afterEvaluate { forceCompileSdk36() }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
