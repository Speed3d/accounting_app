import 'package:accountant_touch/services/app_lock_service.dart';
import 'package:accountant_touch/services/currency_service.dart';
import 'package:accountant_touch/services/firebase_service.dart'; // ← Hint: إضافة Firebase Service
import 'package:accountant_touch/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:accountant_touch/l10n/app_localizations.dart';
import 'package:accountant_touch/providers/theme_provider.dart';
import 'package:accountant_touch/providers/locale_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/auth/splash_screen.dart';
import 'services/biometric_service.dart';
// import 'services/database_migration_service.dart';
import 'services/pdf_service.dart';

Future<void> main() async {
  // ← Hint: ضروري لتهيئة الخدمات قبل runApp
  WidgetsFlutterBinding.ensureInitialized();

  // // ============================================================================
  // // 🔄 ترحيل قاعدة البيانات إلى مشفرة (مرة واحدة فقط)
  // // ← Hint: يحدث تلقائياً عند أول تشغيل بعد التحديث
  // // ============================================================================

  // debugPrint('🔄 فحص الحاجة لترحيل قاعدة البيانات...');
  // final migrated = await DatabaseMigrationService.migrateIfNeeded();

  // if (migrated) {
  //   debugPrint('✅ تم ترحيل قاعدة البيانات بنجاح!');
  //   debugPrint('🔐 قاعدة البيانات الآن مشفرة بـ AES-256');
  // } else {
  //   debugPrint('ℹ️ لا حاجة للترحيل');
  // }

  // ============================================================================
  // 🔥 الخطوة 1: تهيئة Firebase (الأولوية القصوى!)
  // ← Hint: يجب أن تكون أول خطوة قبل أي شيء آخر
  // ============================================================================
  
  debugPrint('🚀 بدء تهيئة التطبيق...');
  
  final firebaseInitialized = await FirebaseService.instance.initialize(
    onError: (error) {
      // ← Hint: في حالة فشل Firebase، نطبع الخطأ ونكمل
      // التطبيق سيعمل بالقيم الافتراضية
      debugPrint('⚠️ Firebase initialization failed: $error');
      debugPrint('ℹ️ التطبيق سيعمل بالوضع Offline مع القيم الافتراضية');
    },
  );

  if (firebaseInitialized) {
    debugPrint('✅ Firebase جاهز للاستخدام');
  } else {
    debugPrint('⚠️ Firebase غير متاح - الوضع Offline');
  }

  // ============================================================================
  // الخطوة 2: تهيئة الـ Providers
  // ============================================================================
  
  final themeProvider = ThemeProvider();
  final localeProvider = LocaleProvider();

  // ============================================================================
  // الخطوة 3: تحميل الإعدادات المحلية
  // ============================================================================
  
  // ← Hint: تحميل خطوط PDF
  await PdfService.instance.loadFonts();

  // ← Hint: تحميل اللغة المحفوظة
  await localeProvider.loadSavedLocale();

  // ← Hint: تحميل العملة المحفوظة
  await CurrencyService.instance.loadSavedCurrency();

  // ← Hint: تحميل حالة البصمة المحفوظة
  await BiometricService.instance.loadBiometricState();

  // ← Hint: تحميل إعدادات القفل
  await AppLockService.instance.loadSettings();

  debugPrint('✅ اكتملت تهيئة جميع الخدمات');

  // ============================================================================
  // الخطوة 4: تشغيل التطبيق
  // ============================================================================
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: localeProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, child) {
        return MaterialApp(
          title: 'نظام المحاسبة',
          debugShowCheckedModeBanner: false,

          // ============= الثيمات =============
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,

          // ============= اللغة =============
          locale: localeProvider.locale ?? const Locale('ar'),
          supportedLocales: const [
            Locale('ar'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // ============= الصفحة الأولى =============
          home: const SplashScreen(),
        );
      },
    );
  }
}