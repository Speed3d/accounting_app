plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // نُعلن البلجن مع النسخة ولكن لا نطبّقه فوراً (apply false) - هذا مطابق لوجوده في classpath
    id("com.google.firebase.crashlytics") apply false
}

// ملاحظة: نحتفظ بطريقة التطبيق لاحقاً باستخدام apply(plugin = "...") كما في الأسفل

// استيراد قيمة kotlin_version من خصائص المشروع (إذا معرفة في gradle.properties)
val kotlin_version: String by project

android {
    namespace = "com.accountant.touch"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.accountant.touch"

        // نفترض أن flutter.minSdkVersion موجود كخاصية في المشروع (كما في مشاريع Flutter عادة)
        // نحاول قراءتها من خصائص المشروع وتحويلها إلى Int

       //val minSdkFromProps = (project.findProperty("flutter.minSdkVersion") as? String)?.toIntOrNull()
        val flutterVersionName = project.findProperty("flutter.versionName") as String? 
        ?: "1.0.0"

        val flutterVersionCode = (project.findProperty("flutter.versionCode") as String?)?.toIntOrNull() 
        ?: 1

         versionName = flutterVersionName
         versionCode = flutterVersionCode

        // ← Hint: قراءة minSdk
        val minSdkFromProps = (project.findProperty("flutter.minSdkVersion") as? String)?.toIntOrNull()
        if (minSdkFromProps != null) {
        minSdk = minSdkFromProps
        } else {
          minSdk = flutter.minSdkVersion
        }

        targetSdk = 36

        // ✅ : تفعيل MultiDex لتجنب مشاكل 64K methods
        multiDexEnabled = true
    }

    // ✅ : إعدادات ProGuard للحماية (سنفعّلها لاحقاً)
       buildTypes {
         getByName("release") {
           isMinifyEnabled = true
           isShrinkResources = true

           proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            file("proguard-rules.pro")
           )

           signingConfig = signingConfigs.getByName("debug")
       }
    }
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version")

    // ✅ Hint: Firebase BoM - يدير إصدارات كل مكتبات Firebase تلقائياً (محدثة لتتوافق مع pubspec.yaml)
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))

    // ✅ Hint: Firebase Core (إجباري)
    implementation("com.google.firebase:firebase-analytics-ktx")

    // ✅ Hint: Firebase Auth (للمصادقة بالإيميل)
    implementation("com.google.firebase:firebase-auth-ktx")

    // ✅ Hint: Cloud Firestore (لإدارة الاشتراكات)
    implementation("com.google.firebase:firebase-firestore-ktx")

    // ✅ Hint: Remote Config (للمفاتيح السرية)
    implementation("com.google.firebase:firebase-config-ktx")

    // ✅ Hint: Crashlytics (للتتبع والأمان)
    implementation("com.google.firebase:firebase-crashlytics-ktx")

    // ✅ Hint: MultiDex support
    implementation("androidx.multidex:multidex:2.0.1")

    // ✅ Hint: Google Play In-App Updates (بدلاً من play:core القديمة)
    implementation("com.google.android.play:app-update:2.1.0")
    implementation("com.google.android.play:app-update-ktx:2.1.0")

    // ✅ Hint: Google Play In-App Review
    implementation("com.google.android.play:review:2.0.1")
    implementation("com.google.android.play:review-ktx:2.0.1")

    // ✅ Hint: تفعيل مكتبة الاشعارات
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// ✅ Hint: نطبّق البلجن في نهاية الملف كما كنت تفعل في Groovy (صيغة Kotlin)
apply(plugin = "com.google.gms.google-services")
apply(plugin = "com.google.firebase.crashlytics")

// Flutter block كما في الأصل
flutter {
    source = "../.."
}
