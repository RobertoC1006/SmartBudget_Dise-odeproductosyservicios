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
subprojects {
    project.evaluationDependsOn(":app")
}

// NO BORRAR: workaround para camera_android_camerax. Su javac falla con
// "CallbackToFutureAdapter not found" porque concurrent-futures no queda
// en el compile classpath del plugin; se inyecta explícitamente aquí.
// Sin este bloque, `flutter build apk` rompe (verificado 2026-06-12).
subprojects {
    if (name == "camera_android_camerax") {
        val addFuturesDep: Project.() -> Unit = {
            dependencies.add(
                "implementation",
                "androidx.concurrent:concurrent-futures:1.1.0",
            )
        }
        if (state.executed) addFuturesDep() else afterEvaluate { addFuturesDep() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
