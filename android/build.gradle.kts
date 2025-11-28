import org.gradle.api.file.Directory
import org.gradle.api.tasks.Delete

extra["kotlin_version"] = "2.1.0"

// ← Hint: هذا الملف الرئيسي لإعدادات Gradle على مستوى المشروع

buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        // ✅ تحديث Android Gradle Plugin لتوافق Gradle 8.12 + Flutter SDK
        classpath("com.android.tools.build:gradle:8.7.3")

        // ✅ Hint: إضافة Google Services plugin للاتصال بـ Firebase
        classpath("com.google.gms:google-services:4.4.4")

        // ✅ Hint: Crashlytics للتتبع (سنستخدمه لاحقاً)
        classpath("com.google.firebase:firebase-crashlytics-gradle:3.0.2")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
