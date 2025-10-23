import 'package:accounting_app/screens/HomeScreen/home_screen.dart';
import 'package:accounting_app/screens/dashboard/dashboard_screen.dart';
import 'package:accounting_app/screens/test_layout_screen.dart';
import 'package:accounting_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:accounting_app/l10n/app_localizations.dart';
import 'package:accounting_app/providers/theme_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/auth/splash_screen.dart';
import 'widgets/test_widgets_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // LocaleProvider معطل مؤقتاً
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // استخدم Consumer بدلاً من Consumer2
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'نظام المحاسبة',
          debugShowCheckedModeBanner: false,
          
          // الثيمات الجديدة
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          
          // Localization (مؤقتاً بدون LocaleProvider)
          locale: const Locale('ar'), // اللغة الافتراضية
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
          
          // الصفحة الأولى
          // home: const DashboardScreen(),
          // home: const HomeScreen(),
          home:  const SplashScreen(),
        );
      },
    );
  }
}