// lib/services/subscription_service.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../data/database_helper.dart';
import 'device_service.dart';

/// ============================================================================
/// خدمة إدارة الاشتراكات - Singleton Pattern
/// ============================================================================
/// الغرض:
/// - إدارة اشتراكات المستخدمين عبر Firebase Firestore
/// - التحقق من صلاحية الاشتراك
/// - دعم Multi-device (3 أجهزة أو unlimited)
/// - دعم Offline mode (Grace period 7 أيام)
/// - حفظ الاشتراك محلياً للعمل بدون إنترنت
/// ============================================================================
class SubscriptionService {

  // ==========================================================================
  // Singleton Pattern
  // ==========================================================================

  static final SubscriptionService _instance = SubscriptionService._internal();
  SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  static SubscriptionService get instance => _instance;

  // ==========================================================================
  // المتغيرات الخاصة
  // ==========================================================================

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // ==========================================================================
  // التحقق من الاشتراك (من Firestore)
  // ==========================================================================

  /// التحقق من اشتراك المستخدم في Firestore
  Future<SubscriptionStatus> checkSubscription(String email) async {
    try {
      debugPrint('🔍 التحقق من اشتراك: $email');

      final doc = await _firestore
          .collection('subscriptions')
          .doc(email)
          .get();

      if (!doc.exists) {
        debugPrint('❌ لا يوجد اشتراك لهذا الإيميل');
        return SubscriptionStatus.notFound();
      }

      final data = doc.data()!;

      // التحقق من الحالة
      final isActive = data['isActive'] as bool? ?? false;
      final status = data['status'] as String? ?? 'inactive';

      if (status == 'suspended') {
        debugPrint('🚫 الاشتراك موقوف');
        return SubscriptionStatus.suspended(
          reason: data['suspensionReason'] ?? 'تم إيقاف الاشتراك',
        );
      }

      // التحقق من تاريخ الانتهاء
      final endDate = (data['endDate'] as Timestamp?)?.toDate();

      if (!isActive || (endDate != null && endDate.isBefore(DateTime.now()))) {
        debugPrint('❌ الاشتراك منتهي');
        return SubscriptionStatus.expired();
      }

      // التحقق من عدد الأجهزة
      final maxDevices = data['maxDevices'] as int?;
      final currentDevices = (data['currentDevices'] as List?) ?? [];

      if (maxDevices != null && currentDevices.length >= maxDevices) {
        // التحقق إذا كان الجهاز الحالي موجود
        final currentDeviceId = await DeviceService.instance.getDeviceFingerprint();
        final deviceExists = currentDevices.any(
          (d) => d['deviceId'] == currentDeviceId,
        );

        if (!deviceExists) {
          debugPrint('🚫 تم الوصول للحد الأقصى من الأجهزة');
          return SubscriptionStatus.maxDevicesReached(
            maxDevices: maxDevices,
            currentCount: currentDevices.length,
          );
        }
      }

      // ✅ كل شيء تمام
      debugPrint('✅ الاشتراك نشط وصالح');

      return SubscriptionStatus.active(
        plan: data['plan'] as String? ?? 'unknown',
        endDate: endDate,
        features: Map<String, dynamic>.from(data['features'] ?? {}),
      );

    } catch (e, stackTrace) {
      debugPrint('❌ خطأ في التحقق من الاشتراك: $e');
      debugPrint('Stack trace: $stackTrace');

      // Fallback: التحقق من الـ Cache المحلي
      return await _checkSubscriptionFromCache(email);
    }
  }

  // ==========================================================================
  // تسجيل الجهاز الحالي في Firestore
  // ==========================================================================

  /// تسجيل الجهاز الحالي في قائمة الأجهزة
  Future<bool> registerCurrentDevice(String email) async {
    try {
      debugPrint('📱 تسجيل الجهاز الحالي للمستخدم: $email');

      final deviceId = await DeviceService.instance.getDeviceFingerprint();
      final deviceInfo = await DeviceService.instance.getDeviceInfo();

      await _firestore.collection('subscriptions').doc(email).update({
        'currentDevices': FieldValue.arrayUnion([
          {
            'deviceId': deviceId,
            'deviceName': deviceInfo['deviceName'] ?? 'Unknown',
            'deviceModel': deviceInfo['model'] ?? 'Unknown',
            'firstLoginAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
            'isActive': true,
          }
        ]),
      });

      debugPrint('✅ تم تسجيل الجهاز بنجاح');
      return true;

    } catch (e) {
      debugPrint('❌ خطأ في تسجيل الجهاز: $e');
      return false;
    }
  }

  // ==========================================================================
  // تحديث آخر تسجيل دخول للجهاز
  // ==========================================================================

  /// تحديث lastLoginAt للجهاز الحالي
  Future<void> updateDeviceLastLogin(String email) async {
    try {
      final deviceId = await DeviceService.instance.getDeviceFingerprint();

      final doc = await _firestore.collection('subscriptions').doc(email).get();

      if (!doc.exists) return;

      final devices = List<Map<String, dynamic>>.from(
        doc.data()?['currentDevices'] ?? [],
      );

      // تحديث lastLoginAt للجهاز الحالي
      for (var i = 0; i < devices.length; i++) {
        if (devices[i]['deviceId'] == deviceId) {
          devices[i]['lastLoginAt'] = Timestamp.now();
          break;
        }
      }

      await _firestore.collection('subscriptions').doc(email).update({
        'currentDevices': devices,
      });

      debugPrint('✅ تم تحديث آخر تسجيل دخول للجهاز');

    } catch (e) {
      debugPrint('⚠️ خطأ في تحديث آخر تسجيل دخول: $e');
    }
  }

  // ==========================================================================
  // حفظ بيانات الاشتراك محلياً (للـ offline)
  // ==========================================================================

  /// حفظ الاشتراك في قاعدة البيانات المحلية للعمل offline
  Future<void> cacheSubscriptionLocally({
    required String email,
    required String plan,
    required DateTime startDate,
    DateTime? endDate,
    required bool isActive,
    int? maxDevices,
    required Map<String, dynamic> features,
  }) async {
    try {
      debugPrint('💾 حفظ الاشتراك محلياً...');

      final deviceId = await DeviceService.instance.getDeviceFingerprint();
      final deviceInfo = await DeviceService.instance.getDeviceInfo();

      await DatabaseHelper.instance.saveSubscriptionCache({
        'ID': 1, // صف واحد فقط
        'Email': email,
        'Plan': plan,
        'StartDate': startDate.toIso8601String(),
        'EndDate': endDate?.toIso8601String(),
        'IsActive': isActive ? 1 : 0,
        'MaxDevices': maxDevices,
        'CurrentDeviceId': deviceId,
        'CurrentDeviceName': deviceInfo['deviceName'] ?? 'Unknown',
        'LastSyncAt': DateTime.now().toIso8601String(),
        'OfflineDaysRemaining': 7,
        'LastOnlineCheck': DateTime.now().toIso8601String(),
        'FeaturesJson': jsonEncode(features),
        'Status': 'active',
        'UpdatedAt': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ تم حفظ الاشتراك محلياً بنجاح');

    } catch (e) {
      debugPrint('❌ خطأ في حفظ الاشتراك محلياً: $e');
    }
  }

  // ==========================================================================
  // التحقق من الـ Cache المحلي (للـ offline)
  // ==========================================================================

  /// التحقق من الاشتراك من الـ Cache المحلي (عند عدم توفر الإنترنت)
  Future<SubscriptionStatus> _checkSubscriptionFromCache(String email) async {
    try {
      debugPrint('📦 التحقق من الاشتراك من الـ Cache المحلي...');

      final cache = await DatabaseHelper.instance.getSubscriptionCache();

      if (cache == null) {
        debugPrint('❌ لا يوجد cache محلي');
        return SubscriptionStatus.notFound();
      }

      // التحقق من الإيميل
      if (cache['Email'] != email) {
        debugPrint('❌ الإيميل في الـ cache لا يطابق');
        return SubscriptionStatus.notFound();
      }

      // التحقق من الـ Grace Period
      final lastOnlineCheck = DateTime.parse(cache['LastOnlineCheck'] as String);
      final daysSinceLastCheck = DateTime.now().difference(lastOnlineCheck).inDays;

      if (daysSinceLastCheck > 7) {
        debugPrint('❌ انتهى الـ Grace Period (7 أيام)');
        return SubscriptionStatus.requiresOnlineCheck();
      }

      // التحقق من الصلاحية
      final endDate = cache['EndDate'] != null
          ? DateTime.parse(cache['EndDate'] as String)
          : null;

      if (endDate != null && endDate.isBefore(DateTime.now())) {
        debugPrint('❌ الاشتراك منتهي (من الـ cache)');
        return SubscriptionStatus.expired();
      }

      // ✅ صالح من الـ Cache
      debugPrint('✅ الاشتراك صالح من الـ Cache');

      return SubscriptionStatus.active(
        plan: cache['Plan'] as String,
        endDate: endDate,
        features: jsonDecode(cache['FeaturesJson'] as String),
        isFromCache: true,
      );

    } catch (e, stackTrace) {
      debugPrint('❌ خطأ في قراءة الـ Cache: $e');
      debugPrint('Stack trace: $stackTrace');
      return SubscriptionStatus.error(message: e.toString());
    }
  }

  // ==========================================================================
  // مسح الـ Cache المحلي
  // ==========================================================================

  /// مسح بيانات الاشتراك المحلية (عند تسجيل الخروج مثلاً)
  Future<void> clearLocalCache() async {
    try {
      await DatabaseHelper.instance.clearSubscriptionCache();
      debugPrint('✅ تم مسح الـ Cache المحلي');
    } catch (e) {
      debugPrint('❌ خطأ في مسح الـ Cache: $e');
    }
  }
}

// ============================================================================
// Model: SubscriptionStatus
// ============================================================================

/// نموذج حالة الاشتراك
class SubscriptionStatus {
  final bool isValid;
  final String statusType;
  final String? message;
  final String? plan;
  final DateTime? endDate;
  final Map<String, dynamic>? features;
  final bool isFromCache;

  SubscriptionStatus({
    required this.isValid,
    required this.statusType,
    this.message,
    this.plan,
    this.endDate,
    this.features,
    this.isFromCache = false,
  });

  // Factories لإنشاء حالات مختلفة

  factory SubscriptionStatus.active({
    required String plan,
    DateTime? endDate,
    required Map<String, dynamic> features,
    bool isFromCache = false,
  }) {
    return SubscriptionStatus(
      isValid: true,
      statusType: 'active',
      plan: plan,
      endDate: endDate,
      features: features,
      isFromCache: isFromCache,
    );
  }

  factory SubscriptionStatus.expired() {
    return SubscriptionStatus(
      isValid: false,
      statusType: 'expired',
      message: 'انتهى الاشتراك. يرجى التجديد.',
    );
  }

  factory SubscriptionStatus.notFound() {
    return SubscriptionStatus(
      isValid: false,
      statusType: 'not_found',
      message: 'لا يوجد اشتراك لهذا الإيميل.',
    );
  }

  factory SubscriptionStatus.suspended({required String reason}) {
    return SubscriptionStatus(
      isValid: false,
      statusType: 'suspended',
      message: reason,
    );
  }

  factory SubscriptionStatus.maxDevicesReached({
    required int maxDevices,
    required int currentCount,
  }) {
    return SubscriptionStatus(
      isValid: false,
      statusType: 'max_devices',
      message: 'تم الوصول للحد الأقصى من الأجهزة ($maxDevices).',
    );
  }

  factory SubscriptionStatus.requiresOnlineCheck() {
    return SubscriptionStatus(
      isValid: false,
      statusType: 'requires_online',
      message: 'يرجى الاتصال بالإنترنت للتحقق من الاشتراك.',
    );
  }

  factory SubscriptionStatus.error({required String message}) {
    return SubscriptionStatus(
      isValid: false,
      statusType: 'error',
      message: message,
    );
  }

  // Helper getters

  bool get isActive => isValid && statusType == 'active';
  bool get isExpired => statusType == 'expired';
  bool get isSuspended => statusType == 'suspended';
  bool get requiresOnline => statusType == 'requires_online';

  @override
  String toString() {
    return 'SubscriptionStatus(isValid: $isValid, statusType: $statusType, '
        'plan: $plan, message: $message, isFromCache: $isFromCache)';
  }
}
