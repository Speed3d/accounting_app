// lib/services/activation_status_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import '../data/database_helper.dart';

// ============================================================================
// 🎯 خدمة حالة التفعيل - Singleton Pattern
// ============================================================================
//
// ← Hint: هذه الخدمة تُستخدم لجلب حالة تفعيل التطبيق من قاعدة البيانات
// ← Hint: تُعرض في القائمة الجانبية بتنسيق جميل (الخيار D - كومبو)
//
// الأنواع المدعومة:
// 1. trial       → تجريبي (يعرض الأيام المتبقية)
// 2. active      → مُفعّل (يعرض الأيام المتبقية)
// 3. lifetime    → تفعيل دائمي (لا تاريخ انتهاء)
// 4. expired     → منتهي (يطلب التجديد)
//
// ============================================================================

/// 📊 معلومات حالة التفعيل
class ActivationInfo {
  final ActivationStatus status;
  final String displayText;       // ← النص المعروض للمستخدم
  final String? expiryDate;       // ← تاريخ الانتهاء (إن وجد)
  final int? daysRemaining;       // ← الأيام المتبقية
  final IconData icon;            // ← الأيقونة المناسبة
  final Color color;              // ← اللون المناسب
  final String plan;              // ← نوع الخطة (trial, professional, lifetime)

  ActivationInfo({
    required this.status,
    required this.displayText,
    this.expiryDate,
    this.daysRemaining,
    required this.icon,
    required this.color,
    required this.plan,
  });
}

/// 🔖 أنواع حالات التفعيل
enum ActivationStatus {
  trial,      // ← تجريبي
  active,     // ← مُفعّل
  lifetime,   // ← تفعيل دائمي
  expired,    // ← منتهي
}

// ============================================================================
// 🎯 خدمة حالة التفعيل - Singleton
// ============================================================================
class ActivationStatusService {
  // ← Hint: Singleton Pattern
  static final ActivationStatusService _instance = ActivationStatusService._internal();
  ActivationStatusService._internal();
  factory ActivationStatusService() => _instance;
  static ActivationStatusService get instance => _instance;

  // ← Hint: Cache للحد من استعلامات قاعدة البيانات
  ActivationInfo? _cachedInfo;
  DateTime? _lastFetchTime;
  static const _cacheDuration = Duration(minutes: 5);

  // ==========================================================================
  // ← Hint: الدالة الرئيسية - جلب حالة التفعيل
  // ==========================================================================
  /// 📊 جلب معلومات حالة التفعيل
  ///
  /// ← Hint: تُستخدم Cache لمدة 5 دقائق للأداء
  /// ← Hint: تحسب الأيام المتبقية تلقائياً
  /// ← Hint: تُحدد اللون والأيقونة المناسبة
  /// ← Hint: 🆕 الآن تقرأ من subscription_cache أولاً (بيانات Firebase)
  Future<ActivationInfo> getActivationStatus() async {
    try {
      // ← Hint: التحقق من الـ Cache
      if (_cachedInfo != null && _lastFetchTime != null) {
        final cacheAge = DateTime.now().difference(_lastFetchTime!);
        if (cacheAge < _cacheDuration) {
          debugPrint('✅ [ActivationStatus] استخدام Cache');
          return _cachedInfo!;
        }
      }

      debugPrint('🔍 [ActivationStatus] جلب حالة التفعيل من قاعدة البيانات...');

      // ← Hint: جلب البيانات من قاعدة البيانات
      final dbHelper = DatabaseHelper.instance;

      // ← Hint: 🆕 أولاً: محاولة القراءة من subscription_cache (بيانات Firebase)
      final subscriptionCache = await dbHelper.getSubscriptionCache();

      String? expiryDateString;
      String? startDateString;
      String? plan;

      if (subscriptionCache != null) {
        // ← Hint: استخدام بيانات الاشتراك من Firebase
        debugPrint('📦 [ActivationStatus] وجدنا بيانات الاشتراك من Firebase');
        expiryDateString = subscriptionCache['EndDate'] as String?;
        startDateString = subscriptionCache['StartDate'] as String?;
        plan = subscriptionCache['Plan'] as String?;
      } else {
        // ← Hint: Fallback: القراءة من app_settings (الطريقة القديمة)
        debugPrint('⚠️ [ActivationStatus] لا توجد بيانات في subscription_cache، استخدام app_settings');
        final appState = await dbHelper.getAppSettings();
        expiryDateString = appState['activation_expiry_date'] as String?;
        startDateString = appState['first_run_date'] as String?;
      }

      // ← Hint: حساب حالة التفعيل
      final info = _calculateActivationInfo(
        expiryDateString: expiryDateString,
        startDateString: startDateString,
        plan: plan,
      );

      // ← Hint: حفظ في الـ Cache
      _cachedInfo = info;
      _lastFetchTime = DateTime.now();

      debugPrint('✅ [ActivationStatus] الحالة: ${info.status.name}');
      debugPrint('📊 [ActivationStatus] النص: ${info.displayText}');
      if (info.daysRemaining != null) {
        debugPrint('⏰ [ActivationStatus] الأيام المتبقية: ${info.daysRemaining}');
      }

      return info;
    } catch (e) {
      debugPrint('❌ [ActivationStatus] خطأ في جلب حالة التفعيل: $e');

      // ← Hint: في حالة الخطأ، نُرجع حالة تجريبية افتراضية
      return ActivationInfo(
        status: ActivationStatus.trial,
        displayText: 'فترة تجريبية',
        icon: Icons.timer,
        color: Colors.orange,
        plan: 'trial',
      );
    }
  }

  // ==========================================================================
  // ← Hint: حساب معلومات التفعيل من البيانات
  // ==========================================================================
  ActivationInfo _calculateActivationInfo({
    required String? expiryDateString,
    required String? startDateString,
    String? plan,
  }) {
    final now = DateTime.now();

    // ═══════════════════════════════════════════════════════════════
    // ← Hint: حالة 1 - لا يوجد تاريخ انتهاء → تفعيل دائمي
    // ═══════════════════════════════════════════════════════════════
    if (expiryDateString == null || expiryDateString.isEmpty) {
      return ActivationInfo(
        status: ActivationStatus.lifetime,
        displayText: 'تفعيل دائمي',
        icon: Icons.verified,
        color: Colors.blue,
        plan: plan ?? 'lifetime',
      );
    }

    // ═══════════════════════════════════════════════════════════════
    // ← Hint: حالة 2 - يوجد تاريخ انتهاء → فحص الحالة
    // ═══════════════════════════════════════════════════════════════
    try {
      final expiryDate = DateTime.parse(expiryDateString);
      final difference = expiryDate.difference(now);
      final daysRemaining = difference.inDays;

      // ← Hint: التحقق من نوع الخطة (تجريبي أم مدفوع)
      // ← Hint: 🆕 نستخدم plan مباشرة إذا كان متاحاً (من Firebase)
      final isTrial = plan == 'trial' || _isTrial(
        startDateString: startDateString,
        expiryDate: expiryDate,
      );

      // ───────────────────────────────────────────────────────────
      // ← Hint: حالة 2.1 - منتهي (الأيام المتبقية <= 0)
      // ───────────────────────────────────────────────────────────
      if (daysRemaining <= 0) {
        return ActivationInfo(
          status: ActivationStatus.expired,
          displayText: 'منتهي',
          expiryDate: _formatDate(expiryDate),
          daysRemaining: 0,
          icon: Icons.error_outline,
          color: Colors.red,
          plan: plan ?? (isTrial ? 'trial' : 'professional'),
        );
      }

      // ───────────────────────────────────────────────────────────
      // ← Hint: حالة 2.2 - تجريبي (أقل من 30 يوم من أول تشغيل)
      // ───────────────────────────────────────────────────────────
      if (isTrial) {
        return ActivationInfo(
          status: ActivationStatus.trial,
          displayText: 'فترة تجريبية',
          expiryDate: _formatDate(expiryDate),
          daysRemaining: daysRemaining,
          icon: Icons.timer,
          color: Colors.orange,
          plan: plan ?? 'trial',
        );
      }

      // ───────────────────────────────────────────────────────────
      // ← Hint: حالة 2.3 - مُفعّل (مدفوع ولم ينته بعد)
      // ───────────────────────────────────────────────────────────
      return ActivationInfo(
        status: ActivationStatus.active,
        displayText: 'مُفعّل',
        expiryDate: _formatDate(expiryDate),
        daysRemaining: daysRemaining,
        icon: Icons.check_circle,
        color: Colors.green,
        plan: plan ?? 'professional',
      );

    } catch (e) {
      debugPrint('❌ [ActivationStatus] خطأ في تحليل التاريخ: $e');

      // ← Hint: في حالة الخطأ
      return ActivationInfo(
        status: ActivationStatus.expired,
        displayText: 'خطأ',
        icon: Icons.error,
        color: Colors.grey,
        plan: plan ?? 'unknown',
      );
    }
  }

  // ==========================================================================
  // ← Hint: التحقق إذا كان تجريبي أم لا
  // ==========================================================================
  /// ← Hint: التجريبي = مدته <= 30 يوم من تاريخ أول تشغيل
  bool _isTrial({
    required String? startDateString,
    required DateTime expiryDate,
  }) {
    if (startDateString == null || startDateString.isEmpty) {
      return true; // ← افتراضي: تجريبي
    }

    try {
      final startDate = DateTime.parse(startDateString);
      final trialDuration = expiryDate.difference(startDate);

      // ← Hint: إذا كانت المدة <= 30 يوم → تجريبي
      return trialDuration.inDays <= 30;
    } catch (e) {
      debugPrint('❌ [ActivationStatus] خطأ في التحقق من التجريبي: $e');
      return true;
    }
  }

  // ==========================================================================
  // ← Hint: تنسيق التاريخ بصيغة عربية واضحة
  // ==========================================================================
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // ==========================================================================
  // ← Hint: مسح الـ Cache (استخدام عند تغيير التفعيل)
  // ==========================================================================
  /// 🔄 مسح الـ Cache
  ///
  /// ← Hint: استخدمها بعد تفعيل التطبيق أو تحديث التفعيل
  void clearCache() {
    _cachedInfo = null;
    _lastFetchTime = null;
    debugPrint('🗑️ [ActivationStatus] تم مسح الـ Cache');
  }

  // ==========================================================================
  // ← Hint: تحديث الـ Cache يدوياً (اختياري)
  // ==========================================================================
  /// ♻️ إعادة تحميل حالة التفعيل (تجاهل الـ Cache)
  Future<ActivationInfo> refresh() async {
    clearCache();
    return await getActivationStatus();
  }
}
