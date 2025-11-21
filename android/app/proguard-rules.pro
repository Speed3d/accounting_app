#: قواعد ProGuard للحفاظ على كود Firebase من التشويش

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

#حماية الـ Models من التشويش (مهم للـ JSON serialization)#
-keep class com.accountant.touch.data.models.** { *; }

#: احتفظ أيضاً بالـ Services المهمة
-keep class com.accountant.touch.services.FirebaseService { *; }
-keep class com.accountant.touch.services.BackupService { *; }
-keep class com.accountant.touch.services.TimeValidationService { *; }
-keep class com.accountant.touch.services.DeviceService { *; }


# SQLite
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# Decimal
-keep class org.decimal4j.** { *; }

#: منع إزالة الـ annotations المهمة
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature
-keepattributes Exceptions

# Keep Play Core classes
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Keep XML classes
-keep class javax.xml.** { *; }
-dontwarn javax.xml.**
-dontwarn org.apache.tika.**

# ============================================================================
# 🔥 حماية إضافية - تشويش الأكواد الحساسة
#: هذه القواعد تجعل فك تشفير APK أصعب بكثير
# ============================================================================

#: إعادة تسمية Packages لإخفاء بنية المشروع
-repackageclasses 'a'
-allowaccessmodification

#: الحفاظ على معلومات Debugging لـ Crashlytics
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

#: تشويش أسماء الكلاسات والميثودات (ما عدا الـ public APIs)
-keepclassmembers class com.accountant.touch.services.** {
    public <methods>;
}

#: حماية إضافية للـ Constants
-keepclassmembers class * {
    static final <fields>;
}

#: تفعيل Optimization القوي
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose

#: إزالة Logs من Production
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
}

#: تشويش الـ Native Methods (إن وجدت)
-keepclasseswithmembernames class * {
    native <methods>;
}