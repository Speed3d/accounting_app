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
/// - 🆕 تحديث status و isActive تلقائياً عند الانتهاء
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
  // التحقق من الاشتراك (من Firestore) - محدث
  // ==========================================================================

  /// التحقق من اشتراك المستخدم في Firestore
  /// 
  /// ← Hint: التحديثات الجديدة:
  /// - 🆕 تحديث status و isActive تلقائياً إذا كان الاشتراك منتهي
  /// - 🆕 إضافة expiredAt timestamp للتوثيق
  /// - 🆕 تحديث updatedAt عند كل فحص
  Future<SubscriptionStatus> checkSubscription(String email) async {
    try {
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('🔍 [SubscriptionService] التحقق من اشتراك: $email');
      debugPrint('═══════════════════════════════════════════════════════════');

      final doc = await _firestore
          .collection('subscriptions')
          .doc(email)
          .get();

      if (!doc.exists) {
        debugPrint('❌ لا يوجد اشتراك لهذا الإيميل');
        debugPrint('═══════════════════════════════════════════════════════════');
        return SubscriptionStatus.notFound();
      }

      final data = doc.data()!;

      // ═══════════════════════════════════════════════════════════════════
      // 1️⃣ قراءة البيانات من Firestore
      // ═══════════════════════════════════════════════════════════════════

      final isActive = data['isActive'] as bool? ?? false;
      final status = data['status'] as String? ?? 'inactive';
      final endDate = (data['endDate'] as Timestamp?)?.toDate();
      final plan = data['plan'] as String? ?? 'unknown';

      debugPrint('📊 البيانات الحالية في Firestore:');
      debugPrint('   - plan: $plan');
      debugPrint('   - status: $status');
      debugPrint('   - isActive: $isActive');
      debugPrint('   - endDate: ${endDate?.toIso8601String() ?? "N/A"}');

      // ═══════════════════════════════════════════════════════════════════
      // 2️⃣ التحقق من حالة الاشتراك الفعلية
      // ═══════════════════════════════════════════════════════════════════

      final now = DateTime.now();
      final isExpired = endDate != null && endDate.isBefore(now);

      debugPrint('');
      debugPrint('🔍 الفحص الفعلي:');
      debugPrint('   - الوقت الحالي: ${now.toIso8601String()}');
      debugPrint('   - هل انتهى؟ $isExpired');

      // ═══════════════════════════════════════════════════════════════════
      // 3️⃣ 🆕 تحديث Firestore إذا كان هناك تعارض
      // ═══════════════════════════════════════════════════════════════════

      // ← Hint: إذا كان الاشتراك منتهي فعلياً لكن Firestore يقول "active"
      if (isExpired && (status == 'active' || isActive)) {
        debugPrint('');
        debugPrint('🔄 تحديث Firestore - الاشتراك منتهي فعلياً');
        debugPrint('   ← status: "$status" → "expired"');
        debugPrint('   ← isActive: $isActive → false');

        await _updateExpiredSubscriptionInFirestore(
          email: email,
          endDate: endDate!,
        );

        debugPrint('✅ تم تحديث Firestore بنجاح');
      }

      // ═══════════════════════════════════════════════════════════════════
      // 4️⃣ معالجة الحالات المختلفة
      // ═══════════════════════════════════════════════════════════════════

      // ────────────────────────────────────────────────────────────────────
      // الحالة 1: الاشتراك موقوف (suspended)
      // ────────────────────────────────────────────────────────────────────
      if (status == 'suspended') {
        debugPrint('');
        debugPrint('🚫 الاشتراك موقوف');
        debugPrint('═══════════════════════════════════════════════════════════');
        
        return SubscriptionStatus.suspended(
          reason: data['suspensionReason'] as String? ?? 'تم إيقاف الاشتراك',
        );
      }

      // ────────────────────────────────────────────────────────────────────
      // الحالة 2: الاشتراك منتهي
      // ────────────────────────────────────────────────────────────────────
      if (isExpired || !isActive) {
        debugPrint('');
        debugPrint('❌ الاشتراك منتهي');
        
        if (endDate != null) {
          final daysSinceExpiry = now.difference(endDate).inDays;
          debugPrint('   - انتهى منذ: $daysSinceExpiry يوم');
        }
        
        debugPrint('═══════════════════════════════════════════════════════════');
        
        return SubscriptionStatus.expired();
      }

      // ────────────────────────────────────────────────────────────────────
      // الحالة 3: التحقق من عدد الأجهزة
      // ────────────────────────────────────────────────────────────────────
      final maxDevices = data['maxDevices'] as int?;
      final currentDevices = (data['currentDevices'] as List?) ?? [];

      if (maxDevices != null && maxDevices > 0) {
        debugPrint('');
        debugPrint('📱 فحص الأجهزة:');
        debugPrint('   - الحد الأقصى: $maxDevices');
        debugPrint('   - الأجهزة الحالية: ${currentDevices.length}');

        if (currentDevices.length >= maxDevices) {
          // ← Hint: التحقق إذا كان الجهاز الحالي موجود في القائمة
          final currentDeviceId = await DeviceService.instance.getDeviceFingerprint();
          final deviceExists = currentDevices.any(
            (d) => d['deviceId'] == currentDeviceId,
          );

          if (!deviceExists) {
            debugPrint('🚫 تم الوصول للحد الأقصى من الأجهزة');
            debugPrint('═══════════════════════════════════════════════════════════');
            
            return SubscriptionStatus.maxDevicesReached(
              maxDevices: maxDevices,
              currentCount: currentDevices.length,
            );
          }
        }
      }

      // ────────────────────────────────────────────────────────────────────
      // ✅ الحالة 4: الاشتراك نشط وصالح
      // ────────────────────────────────────────────────────────────────────
      debugPrint('');
      debugPrint('✅ الاشتراك نشط وصالح');
      debugPrint('   - Plan: $plan');
      
      if (endDate != null) {
        final daysRemaining = endDate.difference(now).inDays;
        debugPrint('   - الأيام المتبقية: $daysRemaining يوم');
      }
      
      debugPrint('═══════════════════════════════════════════════════════════');

      return SubscriptionStatus.active(
        plan: plan,
        endDate: endDate,
        features: Map<String, dynamic>.from(data['features'] ?? {}),
      );

    } catch (e, stackTrace) {
      debugPrint('');
      debugPrint('❌ خطأ في التحقق من الاشتراك: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('═══════════════════════════════════════════════════════════');

      // ← Hint: Fallback - التحقق من الـ Cache المحلي
      return await _checkSubscriptionFromCache(email);
    }
  }

  // ==========================================================================
  // 🆕 تحديث الاشتراك المنتهي في Firestore (جديد - الخطوة 4)
  // ==========================================================================

  /// تحديث حالة الاشتراك في Firestore عندما يكون منتهي
  /// 
  /// ← Hint: يُستدعى تلقائياً من checkSubscription()
  /// ← Hint: يحدّث:
  ///   - status: "expired"
  ///   - isActive: false
  ///   - expiredAt: timestamp (للتوثيق)
  ///   - updatedAt: timestamp
  Future<void> _updateExpiredSubscriptionInFirestore({
    required String email,
    required DateTime endDate,
  }) async {
    try {
      debugPrint('🔄 [_updateExpiredSubscriptionInFirestore] بدء التحديث...');

      // ← Hint: تحديث الحقول في Firestore
      await _firestore.collection('subscriptions').doc(email).update({
        // ← Hint: تحديث الحالة
        'status': 'expired',
        'isActive': false,

        // ← Hint: إضافة timestamp لتوثيق وقت الانتهاء الفعلي
        'expiredAt': FieldValue.serverTimestamp(),

        // ← Hint: تحديث timestamp التعديل
        'updatedAt': FieldValue.serverTimestamp(),

        // ← Hint: إضافة ملاحظة (اختياري)
        'notes': 'الاشتراك انتهى تلقائياً في ${DateTime.now().toIso8601String()}',
      });

      debugPrint('✅ [_updateExpiredSubscriptionInFirestore] تم التحديث بنجاح');
      debugPrint('   ✓ status → "expired"');
      debugPrint('   ✓ isActive → false');
      debugPrint('   ✓ expiredAt → ${DateTime.now().toIso8601String()}');

    } catch (e, stackTrace) {
      // ← Hint: في حالة الفشل - نسجل الخطأ لكن لا نوقف التطبيق
      debugPrint('⚠️ [_updateExpiredSubscriptionInFirestore] فشل التحديث: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // ← Hint: ليس خطأ حرج - التطبيق يعمل محلياً
      // ← Hint: سيتم التحديث في المرة القادمة عند الاتصال
    }
  }

  // ==========================================================================
  // 🆕 تحديث الاشتراك المنتهي - دالة عامة (للاستخدام الخارجي)
  // ==========================================================================

  /// تحديث اشتراك منتهي في Firestore (للاستخدام من splash_screen)
  /// 
  /// ← Hint: نسخة عامة من _updateExpiredSubscriptionInFirestore
  /// ← Hint: يمكن استدعاؤها من أي مكان في التطبيق
  Future<bool> updateExpiredSubscription(String email) async {
    try {
      debugPrint('🔄 [updateExpiredSubscription] تحديث اشتراك منتهي: $email');

      // ← Hint: جلب البيانات الحالية
      final doc = await _firestore
          .collection('subscriptions')
          .doc(email)
          .get();

      if (!doc.exists) {
        debugPrint('⚠️ لا يوجد اشتراك لتحديثه');
        return false;
      }

      final data = doc.data()!;
      final endDate = (data['endDate'] as Timestamp?)?.toDate();

      if (endDate == null) {
        debugPrint('⚠️ لا يوجد endDate - لا يمكن التحديث');
        return false;
      }

      // ← Hint: التحقق من أن الاشتراك فعلاً منتهي
      final isExpired = endDate.isBefore(DateTime.now());

      if (!isExpired) {
        debugPrint('ℹ️ الاشتراك لم ينتهِ بعد - لا حاجة للتحديث');
        return false;
      }

      // ← Hint: تنفيذ التحديث
      await _updateExpiredSubscriptionInFirestore(
        email: email,
        endDate: endDate,
      );

      return true;

    } catch (e) {
      debugPrint('❌ [updateExpiredSubscription] خطأ: $e');
      return false;
    }
  }

  // ==========================================================================
  // تسجيل الجهاز الحالي في Firestore
  // ==========================================================================

  /// تسجيل الجهاز الحالي في قائمة الأجهزة
  /// 
  /// ← Hint: يُستدعى بعد تسجيل الدخول الناجح
  Future<bool> registerCurrentDevice(String email) async {
    try {
      debugPrint('📱 تسجيل الجهاز الحالي للمستخدم: $email');

      final deviceId = await DeviceService.instance.getDeviceFingerprint();
      final deviceInfo = await DeviceService.instance.getDeviceInfo();

      // ═══════════════════════════════════════════════════════════════════
      // ← Hint: استخدام Timestamp.now() بدلاً من serverTimestamp داخل Array
      // ═══════════════════════════════════════════════════════════════════
      final now = Timestamp.now();

      await _firestore.collection('subscriptions').doc(email).update({
        'currentDevices': FieldValue.arrayUnion([
          {
            'deviceId': deviceId,
            'deviceName': deviceInfo['device'] ?? 'Unknown',
            'deviceModel': deviceInfo['model'] ?? 'Unknown',
            'deviceBrand': deviceInfo['brand'] ?? 'Unknown',
            'firstLoginAt': now,  // ✅ استخدام Timestamp.now()
            'lastLoginAt': now,   // ✅ استخدام Timestamp.now()
            'isActive': true,
          }
        ]),
        'updatedAt': FieldValue.serverTimestamp(), // ✅ خارج Array - صحيح
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
  /// 
  /// ← Hint: يُستدعى عند كل تسجيل دخول
  Future<void> updateDeviceLastLogin(String email) async {
    try {
      final deviceId = await DeviceService.instance.getDeviceFingerprint();

      final doc = await _firestore.collection('subscriptions').doc(email).get();

      if (!doc.exists) return;

      final devices = List<Map<String, dynamic>>.from(
        doc.data()?['currentDevices'] ?? [],
      );

      // ← Hint: تحديث lastLoginAt للجهاز الحالي
      bool deviceFound = false;
      for (var i = 0; i < devices.length; i++) {
        if (devices[i]['deviceId'] == deviceId) {
          devices[i]['lastLoginAt'] = Timestamp.now();
          deviceFound = true;
          break;
        }
      }

      if (deviceFound) {
        await _firestore.collection('subscriptions').doc(email).update({
          'currentDevices': devices,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ تم تحديث آخر تسجيل دخول للجهاز');
      }

    } catch (e) {
      debugPrint('⚠️ خطأ في تحديث آخر تسجيل دخول: $e');
    }
  }

  // ==========================================================================
  // حفظ بيانات الاشتراك محلياً (للـ offline)
  // ==========================================================================

  /// حفظ الاشتراك في قاعدة البيانات المحلية للعمل offline
  /// 
  /// ← Hint: يُستدعى بعد التحقق الناجح من Firestore
  /// ← Hint: يسمح بالعمل بدون إنترنت لمدة 7 أيام (Grace Period)
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
      debugPrint('💾 حفظ الاشتراك في Cache المحلي...');

      final deviceId = await DeviceService.instance.getDeviceFingerprint();
      final deviceInfo = await DeviceService.instance.getDeviceInfo();

      await DatabaseHelper.instance.saveSubscriptionCache({
        'ID': 1, // ← Hint: صف واحد فقط
        'Email': email,
        'Plan': plan,
        'StartDate': startDate.toIso8601String(),
        'EndDate': endDate?.toIso8601String(),
        'IsActive': isActive ? 1 : 0,
        'MaxDevices': maxDevices,
        'CurrentDeviceId': deviceId,
        'CurrentDeviceName': deviceInfo['device'] ?? 'Unknown',
        'LastSyncAt': DateTime.now().toIso8601String(),
        'OfflineDaysRemaining': 7,
        'LastOnlineCheck': DateTime.now().toIso8601String(),
        'FeaturesJson': jsonEncode(features),
        'Status': isActive ? 'active' : 'inactive',
        'UpdatedAt': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ تم حفظ الاشتراك في Cache بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ الاشتراك محلياً: $e');
    }
  }

  // ==========================================================================
  // التحقق من الـ Cache المحلي (للـ offline)
  // ==========================================================================

  /// التحقق من الاشتراك من الـ Cache المحلي (عند عدم توفر الإنترنت)
  /// 
  /// ← Hint: Fallback عند فشل الاتصال بـ Firestore
  /// ← Hint: يدعم Grace Period لمدة 7 أيام
  Future<SubscriptionStatus> _checkSubscriptionFromCache(String email) async {
    try {
      debugPrint('');
      debugPrint('📦 التحقق من الاشتراك من الـ Cache المحلي...');

      final cache = await DatabaseHelper.instance.getSubscriptionCache();

      if (cache == null) {
        debugPrint('❌ لا يوجد cache محلي');
        return SubscriptionStatus.notFound();
      }

      // ← Hint: التحقق من الإيميل
      if (cache['Email'] != email) {
        debugPrint('❌ الإيميل في الـ cache لا يطابق');
        return SubscriptionStatus.notFound();
      }

      // ← Hint: التحقق من الـ Grace Period
      final lastOnlineCheck = DateTime.parse(cache['LastOnlineCheck'] as String);
      final daysSinceLastCheck = DateTime.now().difference(lastOnlineCheck).inDays;

      debugPrint('📊 معلومات Cache:');
      debugPrint('   - آخر تحقق: ${lastOnlineCheck.toIso8601String()}');
      debugPrint('   - مر عليه: $daysSinceLastCheck يوم');

      if (daysSinceLastCheck > 7) {
        debugPrint('❌ انتهى الـ Grace Period (7 أيام)');
        return SubscriptionStatus.requiresOnlineCheck();
      }

      // ← Hint: التحقق من الصلاحية
      final endDate = cache['EndDate'] != null
          ? DateTime.parse(cache['EndDate'] as String)
          : null;

      if (endDate != null && endDate.isBefore(DateTime.now())) {
        debugPrint('❌ الاشتراك منتهي (من الـ cache)');
        return SubscriptionStatus.expired();
      }

      // ✅ صالح من الـ Cache
      debugPrint('✅ الاشتراك صالح من الـ Cache (offline mode)');

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
  /// 
  /// ← Hint: يُستدعى من custom_drawer عند Logout
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
/// 
/// ← Hint: يُستخدم لإرجاع حالة الاشتراك من checkSubscription()
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

  // ==========================================================================
  // Factories لإنشاء حالات مختلفة
  // ==========================================================================

  /// اشتراك نشط وصالح
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

  /// اشتراك منتهي
  factory SubscriptionStatus.expired() {
    return SubscriptionStatus(
      isValid: false,
      statusType: 'expired',
      message: 'انتهى الاشتراك. يرجى التجديد.',
    );
  }

  /// لا يوجد اشتراك
  factory SubscriptionStatus.notFound() {
    return SubscriptionStatus(
      isValid: false,
      statusType: 'not_found',
      message: 'لا يوجد اشتراك لهذا الإيميل.',
    );
  }

  /// اشتراك موقوف
  factory SubscriptionStatus.suspended({required String reason}) {
    return SubscriptionStatus(
      isValid: false,
      statusType: 'suspended',
      message: reason,
    );
  }

  /// وصل للحد الأقصى من الأجهزة
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

  /// يحتاج التحقق عبر الإنترنت
  factory SubscriptionStatus.requiresOnlineCheck() {
    return SubscriptionStatus(
      isValid: false,
      statusType: 'requires_online',
      message: 'يرجى الاتصال بالإنترنت للتحقق من الاشتراك.',
    );
  }

  /// خطأ في التحقق
  factory SubscriptionStatus.error({required String message}) {
    return SubscriptionStatus(
      isValid: false,
      statusType: 'error',
      message: message,
    );
  }

  // ==========================================================================
  // Helper getters
  // ==========================================================================

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