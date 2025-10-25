import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// مدير الثيم - للتبديل بين الوضع النهاري والليلي
class ThemeProvider extends ChangeNotifier {
  // المفتاح لحفظ الثيم في SharedPreferences
  static const String _themeKey = 'theme_mode';
  
  // الوضع الحالي (افتراضياً النهاري)
  ThemeMode _themeMode = ThemeMode.light;
  
  // Getter للوضع الحالي
  ThemeMode get themeMode => _themeMode;
  
  // هل الوضع الحالي داكن؟
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  /// Constructor - تحميل الثيم المحفوظ
  ThemeProvider() {
    _loadThemeFromPrefs();
  }
  
  /// تحميل الثيم المحفوظ من SharedPreferences
  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      
      if (savedTheme != null) {
        _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }
  
  /// حفظ الثيم في SharedPreferences
  Future<void> _saveThemeToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, _themeMode == ThemeMode.dark ? 'dark' : 'light');
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }
  
  /// تبديل الثيم بين النهاري والليلي
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await _saveThemeToPrefs();
    notifyListeners();
  }
    // جديد
    final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.light);
  
  /// تعيين ثيم محدد
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    themeModeNotifier.value = mode; // ← أضف هذا السطر
    await _saveThemeToPrefs();
    notifyListeners();
  }
  
  /// تعيين الوضع النهاري
  Future<void> setLightMode() async {
    await setThemeMode(ThemeMode.light);
  }
  
  /// تعيين الوضع الليلي
  Future<void> setDarkMode() async {
    await setThemeMode(ThemeMode.dark);
  }
  
  /// تعيين حسب نظام الجهاز
  Future<void> setSystemMode() async {
    await setThemeMode(ThemeMode.system);
  }
}

/// Extension للوصول السريع للثيم من BuildContext
extension ThemeExtension on BuildContext {
  /// الحصول على ThemeProvider
  ThemeProvider get themeProvider => Provider.of<ThemeProvider>(this, listen: false);
  
  /// مراقبة التغييرات في الثيم
  ThemeProvider get watchTheme => Provider.of<ThemeProvider>(this);
  
  /// هل الوضع الحالي داكن؟
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  
  /// تبديل الثيم
  Future<void> toggleTheme() async {
    await themeProvider.toggleTheme();
  }
}