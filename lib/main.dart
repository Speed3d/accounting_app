import 'package:accounting_app/screens/HomeScreen/home_screen.dart';
import 'package:accounting_app/screens/dashboard/dashboard_screen.dart';
import 'package:accounting_app/screens/test_layout_screen.dart';
import 'package:accounting_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:accounting_app/l10n/app_localizations.dart';
import 'package:accounting_app/providers/theme_provider.dart';
import 'package:accounting_app/providers/locale_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/auth/splash_screen.dart';
import 'widgets/test_widgets_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ============= تهيئة الـ Providers =============
  final themeProvider = ThemeProvider();
  final localeProvider = LocaleProvider();
  
  // تحميل اللغة المحفوظة
  await localeProvider.loadSavedLocale();
  
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
          locale: localeProvider.locale ?? const Locale('ar'), // اللغة الحالية من LocaleProvider
          supportedLocales: const [
            Locale('ar'), // العربية
            Locale('en'), // الإنجليزية
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