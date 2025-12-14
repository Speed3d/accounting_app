// lib/services/notification_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'subscription_service.dart';
import 'session_service.dart';

/// ============================================================================
/// خدمة الإشعارات - Singleton Pattern
/// ============================================================================
/// 
/// ← Hint: الغرض:
/// - إرسال إشعارات قبل انتهاء الاشتراك (7, 3, 1 يوم)
/// - إشعار عند الانتهاء
/// - فحص يومي تلقائي
/// - تخزين آخر إشعار لتجنب التكرار
/// 
/// ============================================================================
class NotificationService {

  // ==========================================================================
  // Singleton Pattern
  // ==========================================================================

  static final NotificationService _instance = NotificationService._internal();
  NotificationService._internal();
  factory NotificationService() => _instance;
  static NotificationService get instance => _instance;

  // ==========================================================================
  // المتغيرات
  // ==========================================================================

  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;

  // ← Hint: مفاتيح SharedPreferences
  static const String _keyLastNotificationDate = 'last_notification_date';
  static const String _keyLastNotificationDays = 'last_notification_days';

  // ==========================================================================
  // التهيئة
  // ==========================================================================

  /// تهيئة خدمة الإشعارات
  /// 
  /// ← Hint: يُستدعى مرة واحدة في main.dart
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔔 [NotificationService] بدء التهيئة...');

      // ═══════════════════════════════════════════════════════════════════
      // Android Settings
      // ═══════════════════════════════════════════════════════════════════
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // ═══════════════════════════════════════════════════════════════════
      // iOS Settings (اختياري)
      // ═══════════════════════════════════════════════════════════════════
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // ═══════════════════════════════════════════════════════════════════
      // Initialization Settings
      // ═══════════════════════════════════════════════════════════════════
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // ═══════════════════════════════════════════════════════════════════
      // طلب الأذونات (Android 13+)
      // ═══════════════════════════════════════════════════════════════════
      await _requestPermissions();

      _isInitialized = true;
      debugPrint('✅ [NotificationService] تم التهيئة بنجاح');

    } catch (e) {
      debugPrint('❌ [NotificationService] فشل التهيئة: $e');
    }
  }

  /// طلب أذونات الإشعارات
  Future<void> _requestPermissions() async {
    try {
      // Android 13+
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
      }

      // iOS
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      
      if (iosPlugin != null) {
        await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      debugPrint('⚠️ [NotificationService] خطأ في طلب الأذونات: $e');
    }
  }

  /// معالجة الضغط على الإشعار
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 [NotificationService] تم الضغط على الإشعار');
    // ← Hint: يمكن فتح شاشة التفعيل هنا
  }

  // ==========================================================================
  // فحص الاشتراك وإرسال الإشعارات
  // ==========================================================================

  /// فحص الاشتراك وإرسال إشعار إذا لزم الأمر
  /// 
  /// ← Hint: يُستدعى عند بدء التطبيق (splash_screen)
  /// ← Hint: يُستدعى يومياً (background task اختياري)
  Future<void> checkAndNotifySubscription() async {
    try {
      if (!_isInitialized) {
        debugPrint('⚠️ [NotificationService] لم يتم التهيئة بعد');
        return;
      }

      debugPrint('🔍 [NotificationService] فحص الاشتراك للإشعارات...');

      // ═══════════════════════════════════════════════════════════════════
      // 1️⃣ الحصول على Email المستخدم
      // ═══════════════════════════════════════════════════════════════════
      final email = await SessionService.instance.getEmail();
      
      if (email == null || email.isEmpty) {
        debugPrint('⚠️ [NotificationService] لا يوجد مستخدم مسجل دخول');
        return;
      }

      // ═══════════════════════════════════════════════════════════════════
      // 2️⃣ التحقق من الاشتراك
      // ═══════════════════════════════════════════════════════════════════
      final subscription = await SubscriptionService.instance
          .checkSubscription(email)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => SubscriptionStatus.error(message: 'Timeout'),
          );

      // ← Hint: إذا لا يوجد اشتراك أو خطأ - لا نرسل إشعار
      if (!subscription.isValid || subscription.endDate == null) {
        debugPrint('ℹ️ [NotificationService] لا يوجد اشتراك صالح');
        return;
      }

      // ═══════════════════════════════════════════════════════════════════
      // 3️⃣ حساب الأيام المتبقية
      // ═══════════════════════════════════════════════════════════════════
      final daysRemaining = subscription.endDate!
          .difference(DateTime.now())
          .inDays;

      debugPrint('📊 [NotificationService] الأيام المتبقية: $daysRemaining');

      // ═══════════════════════════════════════════════════════════════════
      // 4️⃣ التحقق من آخر إشعار (لتجنب التكرار)
      // ═══════════════════════════════════════════════════════════════════
      final shouldNotify = await _shouldSendNotification(daysRemaining);

      if (!shouldNotify) {
        debugPrint('ℹ️ [NotificationService] تم إرسال إشعار اليوم بالفعل');
        return;
      }

      // ═══════════════════════════════════════════════════════════════════
      // 5️⃣ إرسال الإشعار حسب الأيام المتبقية
      // ═══════════════════════════════════════════════════════════════════
      if (daysRemaining <= 0) {
        await _sendExpiredNotification();
      } else if (daysRemaining == 1) {
        await _sendExpiringNotification(1);
      } else if (daysRemaining == 3) {
        await _sendExpiringNotification(3);
      } else if (daysRemaining == 7) {
        await _sendExpiringNotification(7);
      } else {
        debugPrint('ℹ️ [NotificationService] لا حاجة لإشعار اليوم');
        return;
      }

      // ═══════════════════════════════════════════════════════════════════
      // 6️⃣ حفظ آخر إشعار
      // ═══════════════════════════════════════════════════════════════════
      await _saveLastNotification(daysRemaining);

    } catch (e, stackTrace) {
      debugPrint('❌ [NotificationService] خطأ في فحص الاشتراك: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// التحقق من ضرورة إرسال إشعار
  /// 
  /// ← Hint: لتجنب إرسال نفس الإشعار مرتين في نفس اليوم
  Future<bool> _shouldSendNotification(int daysRemaining) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final lastDate = prefs.getString(_keyLastNotificationDate);
      final lastDays = prefs.getInt(_keyLastNotificationDays);

      // ← Hint: إذا لا يوجد إشعار سابق - يجب الإرسال
      if (lastDate == null || lastDays == null) {
        return true;
      }

      final today = DateTime.now();
      final lastNotificationDate = DateTime.parse(lastDate);

      // ← Hint: إذا آخر إشعار كان اليوم ونفس الأيام - لا نرسل
      if (lastNotificationDate.year == today.year &&
          lastNotificationDate.month == today.month &&
          lastNotificationDate.day == today.day &&
          lastDays == daysRemaining) {
        return false;
      }

      return true;

    } catch (e) {
      debugPrint('⚠️ [NotificationService] خطأ في فحص آخر إشعار: $e');
      return true; // ← Hint: في حالة الخطأ - نرسل الإشعار
    }
  }

  /// حفظ آخر إشعار تم إرساله
  Future<void> _saveLastNotification(int daysRemaining) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString(
        _keyLastNotificationDate,
        DateTime.now().toIso8601String(),
      );
      
      await prefs.setInt(_keyLastNotificationDays, daysRemaining);

      debugPrint('✅ [NotificationService] تم حفظ آخر إشعار');
    } catch (e) {
      debugPrint('⚠️ [NotificationService] خطأ في حفظ آخر إشعار: $e');
    }
  }

  // ==========================================================================
  // إرسال الإشعارات
  // ==========================================================================

  /// إشعار: اشتراكك ينتهي قريباً
  Future<void> _sendExpiringNotification(int daysRemaining) async {
    try {
      String title;
      String body;

      if (daysRemaining == 1) {
        title = '⚠️ اشتراكك ينتهي غداً!';
        body = 'اشتراكك في تطبيق المحاسب ينتهي خلال يوم واحد. يرجى التجديد.';
      } else if (daysRemaining == 3) {
        title = '⏰ اشتراكك ينتهي قريباً';
        body = 'اشتراكك في تطبيق المحاسب ينتهي خلال 3 أيام. فكر في التجديد.';
      } else {
        title = '🔔 تذكير: اشتراكك';
        body = 'اشتراكك في تطبيق المحاسب ينتهي خلال $daysRemaining أيام.';
      }

      await _sendNotification(
        id: 1,
        title: title,
        body: body,
        priority: daysRemaining <= 3 ? Priority.high : Priority.defaultPriority,
      );

      debugPrint('✅ [NotificationService] تم إرسال إشعار ($daysRemaining أيام)');

    } catch (e) {
      debugPrint('❌ [NotificationService] فشل إرسال إشعار: $e');
    }
  }

  /// إشعار: اشتراكك منتهي
  Future<void> _sendExpiredNotification() async {
    try {
      await _sendNotification(
        id: 2,
        title: '❌ انتهى اشتراكك',
        body: 'اشتراكك في تطبيق المحاسب قد انتهى. يرجى التجديد للمتابعة.',
        priority: Priority.high,
      );

      debugPrint('✅ [NotificationService] تم إرسال إشعار (منتهي)');

    } catch (e) {
      debugPrint('❌ [NotificationService] فشل إرسال إشعار: $e');
    }
  }

  /// إرسال إشعار عام
  Future<void> _sendNotification({
    required int id,
    required String title,
    required String body,
    Priority priority = Priority.defaultPriority,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'subscription_channel',
        'اشتراكات',
        channelDescription: 'إشعارات عن حالة الاشتراك',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        id,
        title,
        body,
        notificationDetails,
      );

    } catch (e) {
      debugPrint('❌ [NotificationService] فشل إرسال الإشعار: $e');
    }
  }

  // ==========================================================================
  // دوال مساعدة
  // ==========================================================================

  /// إلغاء جميع الإشعارات
  Future<void> cancelAll() async {
    try {
      await _notifications.cancelAll();
      debugPrint('✅ [NotificationService] تم إلغاء جميع الإشعارات');
    } catch (e) {
      debugPrint('❌ [NotificationService] فشل إلغاء الإشعارات: $e');
    }
  }

  /// إلغاء إشعار محدد
  Future<void> cancel(int id) async {
    try {
      await _notifications.cancel(id);
      debugPrint('✅ [NotificationService] تم إلغاء الإشعار #$id');
    } catch (e) {
      debugPrint('❌ [NotificationService] فشل إلغاء الإشعار: $e');
    }
  }
}