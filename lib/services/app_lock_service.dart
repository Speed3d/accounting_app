// lib/services/app_lock_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🔐 خدمة إدارة قفل التطبيق التلقائي - Singleton Pattern
class AppLockService {
  // ← Hint: Singleton Pattern
  static final AppLockService _instance = AppLockService._internal();
  AppLockService._internal();
  factory AppLockService() => _instance;
  static AppLockService get instance => _instance;

  // ← Hint: مفاتيح التخزين
  static const String _lastActiveKey = 'last_active_time';
  static const String _lockEnabledKey = 'app_lock_enabled';
  static const String _lockDurationKey = 'lock_duration_minutes';

  // ← Hint: القيم الافتراضية
  static const int defaultLockDurationMinutes = 1;

  // ← Hint: التخزين الآمن
  final _secureStorage = const FlutterSecureStorage();

  // ← Hint: متغيرات الحالة
  bool _isLockEnabled = false;
  int _lockDurationMinutes = defaultLockDurationMinutes;
  bool _isLocked = false;

  // ← Hint: Getters
  bool get isLockEnabled => _isLockEnabled;
  int get lockDurationMinutes => _lockDurationMinutes;
  bool get isLocked => _isLocked;

  // ==========================================================================
  // ← Hint: تحميل الإعدادات عند بدء التطبيق
  // ==========================================================================
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLockEnabled = prefs.getBool(_lockEnabledKey) ?? false;
      _lockDurationMinutes = prefs.getInt(_lockDurationKey) ?? defaultLockDurationMinutes;
      
      debugPrint('✅ تم تحميل إعدادات القفل: مُفعّل=$_isLockEnabled, المدة=$_lockDurationMinutes دقيقة');
    } catch (e) {
      debugPrint('❌ خطأ في تحميل إعدادات القفل: $e');
      _isLockEnabled = false;
      _lockDurationMinutes = defaultLockDurationMinutes;
    }
  }

  // ==========================================================================
  // ← Hint: تفعيل القفل التلقائي
  // ==========================================================================
  Future<void> enableLock() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_lockEnabledKey, true);
      _isLockEnabled = true;
      
      debugPrint('✅ تم تفعيل القفل التلقائي');
    } catch (e) {
      debugPrint('❌ خطأ في تفعيل القفل: $e');
    }
  }

  // ==========================================================================
  // ← Hint: إيقاف القفل التلقائي
  // ==========================================================================
  Future<void> disableLock() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_lockEnabledKey, false);
      _isLockEnabled = false;
      
      // ← Hint: حذف آخر وقت نشاط
      await _secureStorage.delete(key: _lastActiveKey);
      
      debugPrint('✅ تم إيقاف القفل التلقائي');
    } catch (e) {
      debugPrint('❌ خطأ في إيقاف القفل: $e');
    }
  }

  // ==========================================================================
  // ← Hint: تغيير مدة القفل
  // ==========================================================================
  Future<void> setLockDuration(int minutes) async {
    if (minutes <= 0) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lockDurationKey, minutes);
      _lockDurationMinutes = minutes;
      
      debugPrint('✅ تم تغيير مدة القفل إلى: $minutes دقيقة');
    } catch (e) {
      debugPrint('❌ خطأ في تغيير مدة القفل: $e');
    }
  }

  // ==========================================================================
  // ← Hint: حفظ وقت آخر نشاط (عند الخروج من التطبيق)
  // ==========================================================================
  Future<void> saveLastActiveTime() async {
    if (!_isLockEnabled) return;
    
    try {
      final now = DateTime.now().toIso8601String();
      await _secureStorage.write(key: _lastActiveKey, value: now);
      
      debugPrint('✅ تم حفظ وقت آخر نشاط: $now');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ وقت آخر نشاط: $e');
    }
  }

  // ==========================================================================
  // ← Hint: التحقق من ضرورة قفل التطبيق (عند العودة)
  // ==========================================================================
  Future<bool> shouldLockApp() async {
    // ← Hint: إذا كان القفل غير مُفعّل
    if (!_isLockEnabled) {
      debugPrint('ℹ️ القفل غير مُفعّل');
      return false;
    }

    try {
      // ← Hint: قراءة آخر وقت نشاط
      final lastActiveString = await _secureStorage.read(key: _lastActiveKey);
      
      if (lastActiveString == null) {
        debugPrint('ℹ️ لا يوجد وقت نشاط محفوظ - القفل غير مطلوب');
        return false;
      }

      final lastActive = DateTime.parse(lastActiveString);
      final now = DateTime.now();
      final difference = now.difference(lastActive);

      debugPrint('ℹ️ الفرق الزمني: ${difference.inMinutes} دقيقة');

      // ← Hint: التحقق من المدة
      if (difference.inMinutes >= _lockDurationMinutes) {
        _isLocked = true;
        debugPrint('🔒 يجب قفل التطبيق - مر ${difference.inMinutes} دقيقة');
        return true;
      } else {
        debugPrint('✅ لا حاجة للقفل - مر فقط ${difference.inMinutes} دقيقة');
        return false;
      }
    } catch (e) {
      debugPrint('❌ خطأ في التحقق من القفل: $e');
      return false;
    }
  }

  // ==========================================================================
  // ← Hint: فتح القفل بعد التحقق الناجح
  // ==========================================================================
  Future<void> unlockApp() async {
    try {
      _isLocked = false;
      // ← Hint: حفظ وقت جديد لبدء العد من جديد
      await saveLastActiveTime();
      
      debugPrint('🔓 تم فتح القفل بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في فتح القفل: $e');
    }
  }

  // ==========================================================================
  // ← Hint: قفل التطبيق فوراً (للاستخدام اليدوي)
  // ==========================================================================
  void lockAppImmediately() {
    _isLocked = true;
    debugPrint('🔒 تم قفل التطبيق فوراً');
  }

  // ==========================================================================
  // ← Hint: إعادة تعيين (للتنظيف عند تسجيل الخروج)
  // ==========================================================================
  Future<void> reset() async {
    try {
      await _secureStorage.delete(key: _lastActiveKey);
      _isLocked = false;

      debugPrint('✅ تم إعادة تعيين حالة القفل');
    } catch (e) {
      debugPrint('❌ خطأ في إعادة التعيين: $e');
    }
  }

  // ==========================================================================
  // ← Hint: تعطيل القفل مؤقتاً (للعمليات الحساسة مثل البيع وطباعة الفواتير)
  // ← Hint: يُستخدم في direct_sale_screen.dart لمنع القفل المزعج أثناء البيع
  // ==========================================================================
  /// 🔓 تعطيل القفل التلقائي مؤقتاً
  ///
  /// استخدام:
  /// - قبل عملية البيع وطباعة الفاتورة
  /// - قبل أي عملية قد تأخذ وقتاً وتتطلب الخروج من التطبيق
  ///
  /// [duration] المدة التي سيبقى فيها القفل معطلاً (افتراضي: 10 دقائق)
  ///
  /// مثال:
  /// ```dart
  /// await AppLockService.instance.temporarilyDisableLock(
  ///   duration: Duration(minutes: 10)
  /// );
  /// ```
  Future<void> temporarilyDisableLock({Duration duration = const Duration(minutes: 10)}) async {
    if (!_isLockEnabled) {
      debugPrint('ℹ️ القفل غير مُفعّل أصلاً - لا حاجة للتعطيل المؤقت');
      return;
    }

    try {
      // ← Hint: حفظ وقت مستقبلي = الآن + المدة
      // ← Hint: عند التحقق لاحقاً، سيجد أن الفرق الزمني = 0 (لأننا في المستقبل)
      final futureTime = DateTime.now().add(duration);
      await _secureStorage.write(
        key: _lastActiveKey,
        value: futureTime.toIso8601String(),
      );

      debugPrint('🔓 تم تعطيل القفل مؤقتاً لمدة ${duration.inMinutes} دقيقة');
      debugPrint('⏰ سيُعاد تفعيل القفل في: ${futureTime.toString()}');
    } catch (e) {
      debugPrint('❌ خطأ في تعطيل القفل مؤقتاً: $e');
    }
  }

  // ==========================================================================
  // ← Hint: إلغاء التعطيل المؤقت (إعادة تفعيل القفل فوراً)
  // ==========================================================================
  /// 🔒 إلغاء التعطيل المؤقت وإعادة تفعيل القفل
  ///
  /// استخدام:
  /// - إذا انتهت العملية الحساسة مبكراً
  /// - أو إذا أراد المستخدم قفل التطبيق يدوياً
  Future<void> cancelTemporaryDisable() async {
    try {
      // ← Hint: حفظ الوقت الحالي = يُعيد التفعيل الفوري للقفل
      await saveLastActiveTime();
      debugPrint('🔒 تم إلغاء التعطيل المؤقت وإعادة تفعيل القفل');
    } catch (e) {
      debugPrint('❌ خطأ في إلغاء التعطيل المؤقت: $e');
    }
  }
}