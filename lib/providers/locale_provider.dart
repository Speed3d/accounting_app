import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// مدير اللغة - للتبديل بين العربية والإنجليزية
class LocaleProvider extends ChangeNotifier {
  static const String _languageCodeKey = 'languageCode';

  Locale? _locale;

  /// الحصول على اللغة الحالية
  Locale? get locale => _locale;

  /// تحميل اللغة المحفوظة من SharedPreferences
  Future<void> loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguageCode = prefs.getString(_languageCodeKey);

      if (savedLanguageCode != null && savedLanguageCode.isNotEmpty) {
        // --- الحالة 1: هناك لغة محفوظة من اختيار المستخدم ---
        _locale = Locale(savedLanguageCode);
        notifyListeners();
        return;
      }

      // --- الحالة 2: لا توجد لغة محفوظة (التشغيل الأول) ---
      // احصل على لغات الجهاز
      final deviceLocales = PlatformDispatcher.instance.locales;
      
      // ابحث عن أول لغة مدعومة في قائمة لغات الجهاز
      for (final deviceLocale in deviceLocales) {
        if (deviceLocale.languageCode == 'ar') {
          _locale = const Locale('ar');
          notifyListeners();
          return;
        }
        if (deviceLocale.languageCode == 'en') {
          _locale = const Locale('en');
          notifyListeners();
          return;
        }
      }

      // --- الحالة 3: لم نجد أي لغة مدعومة في لغات الجهاز ---
      // نختار الإنجليزية كلغة افتراضية
      _locale = const Locale('en');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading locale: $e');
      _locale = const Locale('en');
      notifyListeners();
    }
  }

  /// تغيير اللغة وحفظها
  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;

    try {
      _locale = newLocale;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageCodeKey, newLocale.languageCode);
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting locale: $e');
    }
  }

  /// تبديل اللغة بين العربية والإنجليزية
  Future<void> toggleLocale() async {
    final newLocale = _locale?.languageCode == 'ar' 
        ? const Locale('en') 
        : const Locale('ar');
    await setLocale(newLocale);
  }
}

/// Extension للوصول السريع للغة من BuildContext
extension LocaleExtension on BuildContext {
  /// الحصول على LocaleProvider
  LocaleProvider get localeProvider => Provider.of<LocaleProvider>(this, listen: false);
  
  /// مراقبة التغييرات في اللغة
  LocaleProvider get watchLocale => Provider.of<LocaleProvider>(this);
  
  /// هل اللغة الحالية عربية؟
  bool get isArabic => Localizations.localeOf(this).languageCode == 'ar';
  
  /// تبديل اللغة
  Future<void> toggleLocale() async {
    await localeProvider.toggleLocale();
  }
}