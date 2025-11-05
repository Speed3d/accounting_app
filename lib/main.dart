import 'package:accounting_app/services/currency_service.dart'; // ✅ Hint: إضافة
import 'package:accounting_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:accounting_app/l10n/app_localizations.dart';
import 'package:accounting_app/providers/theme_provider.dart';
import 'package:accounting_app/providers/locale_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/auth/splash_screen.dart';
import 'services/biometric_service.dart';
import 'services/pdf_service.dart';

Future<void> main() async {
WidgetsFlutterBinding.ensureInitialized();
// ============= تهيئة الـ Providers =============
final themeProvider = ThemeProvider();
final localeProvider = LocaleProvider();

 // ✅ Hint: تحميل خطوط PDF
await PdfService.instance.loadFonts();

// تحميل اللغة المحفوظة
await localeProvider.loadSavedLocale();
// ✅ Hint: تحميل العملة المحفوظة
await CurrencyService.instance.loadSavedCurrency();
// ✅ Hint: تحميل حالة البصمة المحفوظة
await BiometricService.instance.loadBiometricState();

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
// ============= مراقبة ThemeProvider و LocaleProvider معاً =============
return Consumer2<ThemeProvider, LocaleProvider>(
builder: (context, themeProvider, localeProvider, child) {
return MaterialApp(
title: 'نظام المحاسبة',
debugShowCheckedModeBanner: false,
      // ============= الثيمات =============
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      
      // ============= اللغة (مع دعم التبديل الديناميكي) =============
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