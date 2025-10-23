import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider {
  LocaleProvider._();
  static final LocaleProvider instance = LocaleProvider._();

  static const String _languageCodeKey = 'languageCode';

  final ValueNotifier<Locale?> _locale = ValueNotifier(null);

  ValueNotifier<Locale?> get locale => _locale;

  // --- ✅ الدالة النهائية والمصححة بالكامل ---
  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString(_languageCodeKey);

    if (savedLanguageCode != null && savedLanguageCode.isNotEmpty) {
      // --- الحالة 1: هناك لغة محفوظة من اختيار المستخدم ---
      // Hint: هذا هو السيناريو الأهم. إذا اختار المستخدم لغة، نحترم اختياره دائماً.
      _locale.value = Locale(savedLanguageCode);
      return; // <-- نخرج من الدالة هنا
    }

    // --- الحالة 2: لا توجد لغة محفوظة (التشغيل الأول) ---
    // Hint: هذا الكود يتم تنفيذه فقط إذا كان savedLanguageCode هو null أو فارغ.
    
    // 1. احصل على لغات الجهاز.
    final deviceLocales = PlatformDispatcher.instance.locales;
    
    // 2. ابحث عن أول لغة مدعومة في قائمة لغات الجهاز.
    for (final deviceLocale in deviceLocales) {
      if (deviceLocale.languageCode == 'ar') {
        _locale.value = const Locale('ar');
        // Hint: بمجرد أن نجد لغة مدعومة، نخرج من الحلقة.
        return; 
      }
      if (deviceLocale.languageCode == 'en') {
        _locale.value = const Locale('en');
        return;
      }
    }

    // --- الحالة 3: لم نجد أي لغة مدعومة في لغات الجهاز ---
    // Hint: هذا يحدث إذا كانت لغة الجهاز مثلاً إسبانية أو فرنسية.
    // في هذه الحالة، نختار لغة افتراضية ثابتة (لتكن الإنجليزية).
    if (_locale.value == null) {
      _locale.value = const Locale('en');
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    if (_locale.value == newLocale) return;
    _locale.value = newLocale;
    final prefs = await SharedPreferences.getInstance();
    // Hint: عند تغيير اللغة، نقوم بحفظها فوراً لتُستخدم في المرة القادمة.
    await prefs.setString(_languageCodeKey, newLocale.languageCode);
  }
}
