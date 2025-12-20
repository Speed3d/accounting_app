import 'dart:io';
import 'package:accountant_touch/services/app_lock_service.dart';
import 'package:accountant_touch/services/currency_service.dart';
import 'package:accountant_touch/services/firebase_service.dart';
import 'package:accountant_touch/services/native_secrets_service.dart';
import 'package:accountant_touch/services/notification_service.dart';
import 'package:accountant_touch/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:accountant_touch/l10n/app_localizations.dart';
import 'package:accountant_touch/providers/theme_provider.dart';
import 'package:accountant_touch/providers/locale_provider.dart';
import 'package:accountant_touch/providers/accounting_view_provider.dart';  // 🆕 Provider العرض المحاسبي
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/auth/splash_screen.dart';
import 'services/biometric_service.dart';
import 'services/pdf_service.dart';

Future<void> main() async {
  // ← Hint: ضروري لتهيئة الخدمات قبل runApp
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================================
  // 🔐 الخطوة 0: تحميل المفاتيح السرية من Native Layer (محسّن!)
  // ← Hint: يجب أن يكون قبل أي شيء آخر
  // ============================================================================
  
  debugPrint('🔐 تحميل المفاتيح السرية من Native layer...');
  
  try {
    final nativeSecrets = NativeSecretsService.instance;
    
    // ═══════════════════════════════════════════════════════════
    // ← Hint: تحميل جميع المفاتيح بشكل متسلسل
    // ═══════════════════════════════════════════════════════════
    
    await nativeSecrets.getActivationSecret();
    await nativeSecrets.getBackupMagic();
    await nativeSecrets.getTimeSecret();
    
    // ═══════════════════════════════════════════════════════════
    // ← Hint: التحقق من الصلاحية (حرج جداً!)
    // ═══════════════════════════════════════════════════════════


    
    final isValid = await nativeSecrets.validateKeys();
    
    if (!isValid) {
      debugPrint('═════════════════════════════════════════════');
      debugPrint('🚨 CRITICAL: المفاتيح السرية غير صالحة!');
      debugPrint('═════════════════════════════════════════════');
      
      // ← Hint: 🔥 إيقاف التطبيق نهائياً
      throw Exception(
        'فشل التحقق من المفاتيح السرية.\n'
        'التطبيق لا يمكن أن يعمل بدون مفاتيح صالحة.\n\n'
        'الرجاء التواصل مع الدعم الفني.'
      );
    }
    
    // ═══════════════════════════════════════════════════════════
    // ← Hint: التحقق من أن المفاتيح ليست القيم الافتراضية القديمة
    // ═══════════════════════════════════════════════════════════
    
    final activation = nativeSecrets.cachedActivationSecret ?? '';
    
    if (activation.contains('X4NL27OcZRHz6')) {
      debugPrint('⚠️ تحذير: لا يزال يستخدم activation secret افتراضي!');
      debugPrint('⚠️ يُنصح بتغييره لمفتاح فريد للأمان');
    }
    
    debugPrint('✅ تم تحميل جميع المفاتيح السرية بنجاح');
    debugPrint('   - Activation: ${activation.substring(0, 10)}... (${activation.length} chars)');
    
  } catch (e, stackTrace) {
    // ═══════════════════════════════════════════════════════════
    // 🔥 معالجة الأخطاء الحرجة
    // ═══════════════════════════════════════════════════════════
    
    debugPrint('═════════════════════════════════════════════');
    debugPrint('❌ خطأ حرج: فشل تحميل المفاتيح السرية');
    debugPrint('❌ Error: $e');
    debugPrint('❌ StackTrace: $stackTrace');
    debugPrint('═════════════════════════════════════════════');
    
    // ← Hint: عرض رسالة للمستخدم قبل الإغلاق
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.red.shade50,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'خطأ في تهيئة التطبيق',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'فشل تحميل المفاتيح السرية الضرورية.\n\n'
                    'الرجاء التأكد من:\n'
                    '• تحديث التطبيق للإصدار الأحدث\n'
                    '• إعادة تثبيت التطبيق\n'
                    '• التواصل مع الدعم الفني\n\n'
                    'رمز الخطأ: NATIVE_KEYS_FAILED',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red.shade700,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => exit(0),
                    icon: const Icon(Icons.close),
                    label: const Text('إغلاق التطبيق'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    
    // ← Hint: إيقاف التنفيذ - لن نكمل التهيئة
    return;
  }

  // ============================================================================
  // 🔥 الخطوة 1: تهيئة Firebase (الأولوية القصوى!)
  // ← Hint: يجب أن تكون بعد Native Secrets مباشرة
  // ============================================================================
  
  debugPrint('🚀 بدء تهيئة Firebase...');
  
  final firebaseInitialized = await FirebaseService.instance.initialize(
    onError: (error) {
      // ← Hint: في حالة فشل Firebase، نطبع الخطأ ونكمل
      // التطبيق سيعمل بالقيم الافتراضية
      debugPrint('⚠️ Firebase initialization failed: $error');
      debugPrint('ℹ️ التطبيق سيعمل بالوضع Offline مع القيم الافتراضية');
    },
    ).timeout(
     const Duration(seconds: 10),
     onTimeout: () {
     debugPrint('⏱️ Firebase timeout - continuing offline');
    return false;
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
  final accountingViewProvider = AccountingViewProvider();  // 🆕 Provider العرض المحاسبي

  // ============================================================================
  // الخطوة 3: تحميل الإعدادات المحلية
  // ============================================================================
  
  debugPrint('⚙️ تحميل الإعدادات المحلية...');
  
  try {
    // ← Hint: تحميل خطوط PDF
    await PdfService.instance.loadFonts();

    // ← Hint: تحميل اللغة المحفوظة
    await localeProvider.loadSavedLocale();

    // 🆕 تحميل إعدادات العرض المحاسبي
    await accountingViewProvider.loadSettings();

    // ← Hint: تحميل العملة المحفوظة
    await CurrencyService.instance.loadSavedCurrency();

    // ← Hint: تحميل حالة البصمة المحفوظة
    await BiometricService.instance.loadBiometricState();

    // ← Hint: تحميل إعدادات القفل
    await AppLockService.instance.loadSettings();

    // 🆕 تهيئة الإشعارات
  try {
    await NotificationService.instance.initialize();
    debugPrint('✅ تم تهيئة الإشعارات');
  } catch (e) {
    debugPrint('⚠️ خطأ في تهيئة الإشعارات: $e');
  }
    
    debugPrint('✅ تم تحميل جميع الإعدادات المحلية');
  } catch (e) {
    debugPrint('⚠️ خطأ في تحميل بعض الإعدادات: $e');
    // ← Hint: نكمل - هذه الإعدادات غير حرجة
  }

  debugPrint('✅ اكتملت تهيئة جميع الخدمات');

  // ============================================================================
  // الخطوة 4: تشغيل التطبيق
  // ============================================================================
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: accountingViewProvider),  // 🆕 Provider العرض المحاسبي
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