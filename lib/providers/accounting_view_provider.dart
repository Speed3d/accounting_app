// lib/providers/accounting_view_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ============================================================================
/// 📊 Provider لإدارة إعدادات العرض المحاسبي
/// ============================================================================
/// الغرض:
/// - حفظ واسترجاع خيار العرض (بسيط أو محاسبي)
/// - إشعار الواجهات عند تغيير الإعداد
/// ============================================================================
class AccountingViewProvider with ChangeNotifier {
  static const String _keyShowAccountingView = 'show_accounting_view';

  bool _showAccountingView = false;  // ← Hint: افتراضياً: عرض بسيط

  /// ← Hint: الحصول على حالة العرض الحالية
  bool get showAccountingView => _showAccountingView;

  /// ============================================================================
  /// تحميل الإعدادات من SharedPreferences
  /// ============================================================================
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _showAccountingView = prefs.getBool(_keyShowAccountingView) ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ خطأ في تحميل إعدادات العرض المحاسبي: $e');
    }
  }

  /// ============================================================================
  /// تبديل حالة العرض المحاسبي
  /// ============================================================================
  Future<void> toggleAccountingView(bool value) async {
    try {
      _showAccountingView = value;
      notifyListeners();

      // ← Hint: حفظ الإعداد
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyShowAccountingView, value);

      debugPrint('✅ تم تبديل العرض المحاسبي: ${value ? "محاسبي" : "بسيط"}');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ إعدادات العرض المحاسبي: $e');
    }
  }
}
