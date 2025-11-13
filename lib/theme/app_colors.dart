import 'package:flutter/material.dart';

/// نظام الألوان الموحد للتطبيق
class AppColors {
  AppColors._();

  // ============= Light Mode Colors =============
  
  // Primary Colors (أخضر محاسبي - يوحي بالنمو والمال)
  static const Color primaryLight = Color(0xFF10B981);
  static const Color primaryLightVariant = Color(0xFF059669);
  static const Color primaryContainer = Color(0xFFD1FAE5);
  
  // Secondary Colors (أزرق)
  static const Color secondaryLight = Color(0xFF3B82F6);
  static const Color secondaryLightVariant = Color(0xFF2563EB);
  static const Color secondaryContainer = Color(0xFFDBEAFE);
  
  // Background Colors - محسّن ✨
  static const Color backgroundLight = Color(0xFFF8F9FA); // بدلاً من الأبيض الساطع
  static const Color surfaceLight = Color(0xFFEFF1F3); // أغمق قليلاً
  static const Color cardLight = Color(0xFFFFFFFF); // الكروت تبقى بيضاء نقية
  
  // Text Colors - محسّن ✨
  static const Color textPrimaryLight = Color(0xFF1A1D1F); // أغمق قليلاً
  static const Color textSecondaryLight = Color(0xFF4B5563); // أغمق من الرمادي السابق
  static const Color textHintLight = Color(0xFF6B7280); // أغمق من السابق
  
  // Status Colors (موحدة للوضعين)
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Border & Divider
  static const Color borderLight = Color.fromARGB(255, 209, 219, 209); // أغمق قليلاً
  static const Color dividerLight = Color(0xFFD1D5DB);
  
  // ============= Dark Mode Colors =============
  
  // Primary Colors (أخضر أفتح قليلاً للظهور على الخلفية الداكنة)
  static const Color primaryDark = Color(0xFF34D399);
  static const Color primaryDarkVariant = Color(0xFF10B981);
  static const Color primaryContainerDark = Color(0xFF064E3B);
  
  // Secondary Colors
  static const Color secondaryDark = Color(0xFF60A5FA);
  static const Color secondaryDarkVariant = Color(0xFF3B82F6);
  static const Color secondaryContainerDark = Color(0xFF1E3A8A);
  
  // Background Colors (أزرق داكن - أفضل من الأسود الكامل للعين)
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color cardDark = Color(0xFF1E293B);
  
  // Text Colors
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFFCBD5E1);
  static const Color textHintDark = Color(0xFF94A3B8);
  
  // Border & Divider
  static const Color borderDark = Color(0xFF334155);
  static const Color dividerDark = Color(0xFF334155);
  
  // ============= Special Colors =============
  
  // AppBar Gradient Colors
  static const List<Color> gradientLight = [
    Color(0xFF10B981),
    Color(0xFF059669),
  ];
  
  static const List<Color> gradientDark = [
    Color(0xFF1E293B),
    Color(0xFF0F172A),
  ];
  
  // Shadow Colors
  static Color shadowLight = Colors.black.withOpacity(0.08);
  static Color shadowDark = Colors.black.withOpacity(0.25);
  
  // Shimmer Loading Colors
  static const Color shimmerBaseLight = Color(0xFFE5E7EB);
  static const Color shimmerHighlightLight = Color(0xFFF9FAFB);
  static const Color shimmerBaseDark = Color(0xFF1E293B);
  static const Color shimmerHighlightDark = Color(0xFF334155);
  
  // Income & Expense Colors (للتقارير المالية)
  static const Color income = Color(0xFF10B981);
  static const Color expense = Color(0xFFEF4444);
  static const Color profit = Color(0xFF3B82F6);
  
  // Chart Colors (للرسوم البيانية)
  static const List<Color> chartColors = [
    Color(0xFF10B981), // أخضر
    Color(0xFF3B82F6), // أزرق
    Color(0xFFF59E0B), // برتقالي
    Color(0xFF8B5CF6), // بنفسجي
    Color(0xFFEC4899), // وردي
    Color(0xFF06B6D4), // سماوي
  ];
  
  // ============= Helper Methods =============
  
  /// الحصول على اللون الأساسي حسب الثيم
  static Color getPrimary(bool isDark) => isDark ? primaryDark : primaryLight;
  
  /// الحصول على لون الخلفية حسب الثيم
  static Color getBackground(bool isDark) => isDark ? backgroundDark : backgroundLight;
  
  /// الحصول على لون النص الأساسي حسب الثيم
  static Color getTextPrimary(bool isDark) => isDark ? textPrimaryDark : textPrimaryLight;
  
  /// الحصول على لون الـ Surface حسب الثيم
  static Color getSurface(bool isDark) => isDark ? surfaceDark : surfaceLight;
  
  /// الحصول على Gradient حسب الثيم
  static List<Color> getGradient(bool isDark) => isDark ? gradientDark : gradientLight;
}

/// امتداد لتسهيل الوصول للألوان من BuildContext
extension AppColorsExtension on BuildContext {
  /// هل الثيم الحالي داكن؟
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  
  /// الحصول على اللون الأساسي
  Color get primaryColor => AppColors.getPrimary(isDarkMode);
  
  /// الحصول على لون الخلفية
  Color get backgroundColor => AppColors.getBackground(isDarkMode);
  
  /// الحصول على لون النص الأساسي
  Color get textColor => AppColors.getTextPrimary(isDarkMode);
  
  /// الحصول على لون الـ Surface
  Color get surfaceColor => AppColors.getSurface(isDarkMode);
}