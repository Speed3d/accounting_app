# ← Hint: قواعد ProGuard للحفاظ على كود Firebase من التشويش

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

# ← Hint: حماية الـ Models من التشويش (مهم للـ JSON serialization)
-keep class com.accountant_touch.data.models.** { *; }
#-keep class com.accountant.touch.data.models.** { *; }

# SQLite
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# Decimal
-keep class org.decimal4j.** { *; }

# ← Hint: منع إزالة الـ annotations المهمة
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