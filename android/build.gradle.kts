
buildscript { // Add this buildscript block if it's not present already
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // IMPORTANT: Replace with the actual versions used in your project
        // These are common placeholders, check your project for exact versions
        classpath("com.android.tools.build:gradle:7.3.0") // Example Android Gradle Plugin version
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.8.0") // Example Kotlin version
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // --- ADD THIS BLOCK FOR JAVA COMPATIBILITY ---
    project.afterEvaluate { // Use afterEvaluate to ensure project properties are available
        if (project.plugins.hasPlugin("com.android.library") || project.plugins.hasPlugin("com.android.application")) {
            project.android { // Access the 'android' extension if it exists
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_11
                    targetCompatibility = JavaVersion.VERSION_11
                }
            }
        }
    }

    // Configure Kotlin compilation for all subprojects (including plugins)
    // to explicitly target JVM 11, matching your app module.
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        kotlinOptions {
            jvmTarget = "11" // Explicitly set to "11"
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

fun Project.android(configure: com.android.build.gradle.BaseExtension.() -> Unit) {
    (this as org.gradle.api.plugins.ExtensionAware).extensions.configure("android", configure)
}