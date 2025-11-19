// lib/services/firebase_service.dart

import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 🔥 خدمة Firebase المركزية - Singleton Pattern
/// 
/// ← Hint: هذه الخدمة مسؤولة عن:
/// - تهيئة Firebase
/// - جلب Remote Config
/// - إدارة Crashlytics
/// - Kill Switch
class FirebaseService {
  // ========================================================================
  // Singleton Pattern
  // ← Hint: نضمن وجود نسخة واحدة فقط من الخدمة في التطبيق
  // ========================================================================
  
  static final FirebaseService _instance = FirebaseService._internal();
  FirebaseService._internal();
  factory FirebaseService() => _instance;
  static FirebaseService get instance => _instance;

  // ========================================================================
  // المتغيرات الخاصة
  // ========================================================================
  
  /// ← Hint: Remote Config instance - للوصول للإعدادات عن بُعد
  FirebaseRemoteConfig? _remoteConfig;
  
  /// ← Hint: هل تم التهيئة؟
  bool _isInitialized = false;
  
  /// ← Hint: Getters للوصول الآمن
  bool get isInitialized => _isInitialized;
  FirebaseRemoteConfig? get remoteConfig => _remoteConfig;

  // ========================================================================
  // التهيئة الأساسية
  // ========================================================================
  
  /// تهيئة Firebase (يُستدعى مرة واحدة في main.dart)
  /// 
  /// ← Hint: هذه الدالة يجب استدعاؤها قبل runApp()
  /// 
  /// [onError] - دالة callback في حالة الفشل
  Future<bool> initialize({Function(String)? onError}) async {
    try {
      debugPrint('🔥 بدء تهيئة Firebase...');

      // ← Hint: التحقق من عدم التهيئة المسبقة (تجنب الأخطاء)
      if (_isInitialized) {
        debugPrint('✅ Firebase مُهيّأ مسبقاً');
        return true;
      }

      // ========================================================================
      // 1. تهيئة Firebase Core
      // ← Hint: هذا يقرأ google-services.json ويربط التطبيق بـ Firebase
      // ========================================================================
      
      await Firebase.initializeApp();
      debugPrint('✅ تم تهيئة Firebase Core');

      // ========================================================================
      // 2. تهيئة Remote Config
      // ========================================================================
      
      await _initializeRemoteConfig();

      // ========================================================================
      // 3. تهيئة Crashlytics
      // ========================================================================
      
      await _initializeCrashlytics();

      // ← Hint: تعيين حالة التهيئة
      _isInitialized = true;
      debugPrint('✅ اكتملت تهيئة Firebase بنجاح');
      
      return true;

    } catch (e, stackTrace) {
      debugPrint('❌ خطأ في تهيئة Firebase: $e');
      debugPrint('Stack trace: $stackTrace');
      
      onError?.call('فشل الاتصال بخدمات Firebase: ${e.toString()}');
      
      return false;
    }
  }

  // ========================================================================
  // Remote Config
  // ========================================================================
  
  /// تهيئة Remote Config وجلب القيم
  /// 
  /// ← Hint: Remote Config يتيح لك تغيير الإعدادات بدون تحديث التطبيق
  Future<void> _initializeRemoteConfig() async {
    try {
      debugPrint('🔧 تهيئة Remote Config...');

      // ← Hint: الحصول على instance من Remote Config
      _remoteConfig = FirebaseRemoteConfig.instance;

      // ========================================================================
      // إعدادات Remote Config
      // ========================================================================
      
      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          // ← Hint: Fetch timeout - المدة القصوى للانتظار عند جلب الإعدادات
          fetchTimeout: const Duration(seconds: 10),
          
          // ← Hint: Minimum fetch interval - الحد الأدنى بين كل fetch
          // في Development: 0 للتجربة السريعة
          // في Production: 3600 (ساعة) لتقليل الاستهلاك
          minimumFetchInterval: kDebugMode 
            ? const Duration(seconds: 0)      // Development
            : const Duration(hours: 1),       // Production
        ),
      );

      // ========================================================================
      // القيم الافتراضية (Fallback)
      // ← Hint: تُستخدم إذا فشل الاتصال بـ Firebase
      // ========================================================================
      
      await _remoteConfig!.setDefaults({
        // ========== App Control ==========
        'app_is_active': true,                    // ← هل التطبيق نشط؟
        'app_min_version': '1.0.0',               // ← الحد الأدنى للإصدار المطلوب
        'app_force_update': false,                // ← هل التحديث إجباري؟
        'app_block_message': 'التطبيق متوقف مؤقتاً للصيانة',
        
        // ========== Security Keys (مؤقت - سننقلها لاحقاً) ==========
        // ← Hint: هذه مؤقتة فقط للتطوير - سنستبدلها بمفاتيح حقيقية من Firebase Console
        'activation_secret': 'TEMP_ACTIVATION_KEY_CHANGE_ME',
        'backup_magic_number': 'TEMP_BACKUP_MAGIC_V2',
        'time_validation_secret': 'TEMP_TIME_VALIDATION_KEY',
        
        // ========== Security Settings ==========
        'pbkdf2_iterations': 100000,              // ← عدد التكرارات (سنستبدل بـ Argon2 لاحقاً)
        'max_suspicious_attempts': 3,             // ← المحاولات المشبوهة المسموحة
        'trial_period_days': 14,                  // ← مدة الفترة التجريبية
        
        // ========== NTP Servers ==========
        // ← Hint: قائمة خوادم NTP (JSON string)
        'ntp_servers': '["time.google.com","time.cloudflare.com","pool.ntp.org"]',
        
        // ========== Features Flags ==========
        'feature_biometric': true,                // ← هل البصمة مفعّلة؟
        'feature_backup_v2': true,                // ← هل نسخ احتياطي V2 مفعّل؟
        'feature_online_validation': false,       // ← هل التحقق عبر الإنترنت مفعّل؟
      });

      // ========================================================================
      // جلب وتفعيل القيم من Firebase
      // ← Hint: fetchAndActivate تجلب القيم الجديدة وتفعّلها فوراً
      // ========================================================================
      
      final updated = await _remoteConfig!.fetchAndActivate();
      
      if (updated) {
        debugPrint('✅ تم تحديث Remote Config بقيم جديدة');
      } else {
        debugPrint('ℹ️ Remote Config يستخدم القيم المخزنة (لم تتغير)');
      }

      // ← Hint: طباعة بعض القيم للتأكد (في Development فقط)
      if (kDebugMode) {
        debugPrint('📋 Remote Config Values:');
        debugPrint('  - app_is_active: ${_remoteConfig!.getBool('app_is_active')}');
        debugPrint('  - trial_period_days: ${_remoteConfig!.getInt('trial_period_days')}');
        debugPrint('  - pbkdf2_iterations: ${_remoteConfig!.getInt('pbkdf2_iterations')}');
      }

    } catch (e) {
      debugPrint('⚠️ خطأ في تهيئة Remote Config (سيتم استخدام القيم الافتراضية): $e');
      // ← Hint: لا نرمي Exception - نكمل بالقيم الافتراضية
    }
  }

  // ========================================================================
  // Crashlytics
  // ========================================================================
  
  /// تهيئة Crashlytics لتتبع الأخطاء
  /// 
  /// ← Hint: Crashlytics يساعدك في رصد محاولات القرصنة والأخطاء
  Future<void> _initializeCrashlytics() async {
    try {
      debugPrint('📊 تهيئة Crashlytics...');

      // ← Hint: في Debug mode، نعطّل Crashlytics لعدم إرسال بيانات التطوير
      if (kDebugMode) {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
        debugPrint('ℹ️ Crashlytics معطّل في Debug mode');
      } else {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
        debugPrint('✅ Crashlytics مُفعّل في Release mode');
      }

      // ← Hint: تسجيل أخطاء Flutter غير المعالجة
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

      // ← Hint: تسجيل أخطاء Dart غير المعالجة
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

    } catch (e) {
      debugPrint('⚠️ خطأ في تهيئة Crashlytics: $e');
      // ← Hint: نكمل حتى لو فشل Crashlytics
    }
  }

  // ========================================================================
  // Kill Switch - التحكم في حالة التطبيق عن بُعد
  // ========================================================================
  
  /// التحقق من حالة التطبيق (هل نشط؟ هل يحتاج تحديث؟)
  /// 
  /// ← Hint: يُستدعى في SplashScreen قبل عرض أي شيء
  /// 
  /// Returns: Map يحتوي على:
  ///   - isActive: bool
  ///   - needsUpdate: bool
  ///   - forceUpdate: bool
  ///   - message: String
  ///   - minVersion: String
  Future<Map<String, dynamic>> checkAppStatus({
    required String currentVersion,
  }) async {
    try {
      // ← Hint: التأكد من تهيئة Remote Config
      if (_remoteConfig == null) {
        debugPrint('⚠️ Remote Config غير مُهيّأ - سيتم السماح بالدخول');
        return {
          'isActive': true,
          'needsUpdate': false,
          'forceUpdate': false,
          'message': '',
        };
      }

      // ========================================================================
      // 1. التحقق من حالة التطبيق
      // ========================================================================
      
      final isActive = _remoteConfig!.getBool('app_is_active');
      
      if (!isActive) {
        final message = _remoteConfig!.getString('app_block_message');
        
        debugPrint('🚫 التطبيق موقوف من قبل المطور');
        debugPrint('   السبب: $message');
        
        return {
          'isActive': false,
          'needsUpdate': false,
          'forceUpdate': false,
          'message': message,
        };
      }

      // ========================================================================
      // 2. التحقق من الإصدار
      // ========================================================================
      
      final minVersion = _remoteConfig!.getString('app_min_version');
      final forceUpdate = _remoteConfig!.getBool('app_force_update');
      
      // ← Hint: مقارنة الإصدارات
      final needsUpdate = _compareVersions(currentVersion, minVersion) < 0;
      
      if (needsUpdate) {
        debugPrint('ℹ️ يوجد تحديث متاح');
        debugPrint('   الإصدار الحالي: $currentVersion');
        debugPrint('   الإصدار المطلوب: $minVersion');
        debugPrint('   إجباري: $forceUpdate');
      }

      return {
        'isActive': true,
        'needsUpdate': needsUpdate,
        'forceUpdate': forceUpdate,
        'message': needsUpdate 
          ? 'يتوفر تحديث جديد. يرجى التحديث للمتابعة.' 
          : '',
        'minVersion': minVersion,
      };

    } catch (e) {
      debugPrint('❌ خطأ في فحص حالة التطبيق: $e');
      
      // ← Hint: في حالة الخطأ، نسمح بالدخول (fail-safe)
      return {
        'isActive': true,
        'needsUpdate': false,
        'forceUpdate': false,
        'message': '',
      };
    }
  }

  // ========================================================================
  // مقارنة الإصدارات
  // ← Hint: يقارن إصدارين بصيغة semver (مثل: 1.2.3)
  // ========================================================================
  
  /// مقارنة رقمي إصدار
  /// 
  /// Returns:
  ///   -1: version1 أقدم من version2
  ///    0: متساويان
  ///    1: version1 أحدث من version2
  int _compareVersions(String version1, String version2) {
    try {
      // ← Hint: تقسيم النسخة إلى أجزاء (major.minor.patch)
      final v1Parts = version1.split('.').map(int.parse).toList();
      final v2Parts = version2.split('.').map(int.parse).toList();

      // ← Hint: المقارنة جزء بجزء
      for (int i = 0; i < 3; i++) {
        final v1Part = i < v1Parts.length ? v1Parts[i] : 0;
        final v2Part = i < v2Parts.length ? v2Parts[i] : 0;

        if (v1Part < v2Part) return -1;
        if (v1Part > v2Part) return 1;
      }

      return 0; // متساويان
      
    } catch (e) {
      debugPrint('⚠️ خطأ في مقارنة الإصدارات: $e');
      return 0; // في حالة الخطأ، نعتبرهما متساويين
    }
  }

  // ========================================================================
  // Getters للمفاتيح السرية
  // ← Hint: هذه الدوال ستُستخدم بدلاً من المفاتيح الثابتة في الكود
  // ========================================================================
  
  /// الحصول على Activation Secret
  /// 
  /// ← Hint: بدلاً من: static const String _secretKey = "..."
  /// نستخدم: final secret = FirebaseService.instance.getActivationSecret()
  String getActivationSecret() {
    return _remoteConfig?.getString('activation_secret') 
      ?? 'FALLBACK_SECRET_KEY';
  }

  /// الحصول على Backup Magic Number
  String getBackupMagicNumber() {
    return _remoteConfig?.getString('backup_magic_number') 
      ?? 'FALLBACK_BACKUP_MAGIC';
  }

  /// الحصول على Time Validation Secret
  String getTimeValidationSecret() {
    return _remoteConfig?.getString('time_validation_secret') 
      ?? 'FALLBACK_TIME_SECRET';
  }

  /// الحصول على عدد PBKDF2 iterations
  int getPbkdf2Iterations() {
    return _remoteConfig?.getInt('pbkdf2_iterations') ?? 100000;
  }

  /// الحصول على عدد المحاولات المشبوهة المسموحة
  int getMaxSuspiciousAttempts() {
    return _remoteConfig?.getInt('max_suspicious_attempts') ?? 3;
  }

  /// الحصول على مدة الفترة التجريبية
  int getTrialPeriodDays() {
    return _remoteConfig?.getInt('trial_period_days') ?? 14;
  }

  /// الحصول على قائمة خوادم NTP
  /// 
  /// ← Hint: القيمة مخزنة كـ JSON string في Remote Config
  List<String> getNtpServers() {
    try {
      final serversJson = _remoteConfig?.getString('ntp_servers') 
        ?? '["time.google.com"]';
      
      // ← Hint: تحويل JSON string إلى List
      final decoded = jsonDecode(serversJson) as List<dynamic>;
      return decoded.cast<String>();
      
    } catch (e) {
      debugPrint('⚠️ خطأ في قراءة NTP servers: $e');
      return ['time.google.com', 'time.cloudflare.com', 'pool.ntp.org'];
    }
  }

  /// هل ميزة البصمة مفعّلة؟
  bool isBiometricEnabled() {
    return _remoteConfig?.getBool('feature_biometric') ?? true;
  }

  /// هل نسخ احتياطي V2 مفعّل؟
  bool isBackupV2Enabled() {
    return _remoteConfig?.getBool('feature_backup_v2') ?? true;
  }

  /// هل التحقق عبر الإنترنت مفعّل؟
  bool isOnlineValidationEnabled() {
    return _remoteConfig?.getBool('feature_online_validation') ?? false;
  }

  // ========================================================================
  // Crashlytics Helpers
  // ========================================================================
  
  /// تسجيل محاولة قرصنة محتملة
  /// 
  /// ← Hint: استخدم هذه الدالة عند رصد أي سلوك مشبوه
  void logSuspiciousActivity({
    required String reason,
    required String deviceId,
    Map<String, dynamic>? additionalInfo,
  }) {
    try {
      if (kDebugMode) return; // لا نسجل في Development

      FirebaseCrashlytics.instance.log('🚨 Suspicious Activity: $reason');
      FirebaseCrashlytics.instance.setCustomKey('device_id', deviceId);
      FirebaseCrashlytics.instance.setCustomKey('reason', reason);
      
      if (additionalInfo != null) {
        additionalInfo.forEach((key, value) {
          FirebaseCrashlytics.instance.setCustomKey(key, value.toString());
        });
      }

      // ← Hint: تسجيل كـ non-fatal error
      FirebaseCrashlytics.instance.recordError(
        Exception('Suspicious activity detected: $reason'),
        StackTrace.current,
        reason: 'Security Alert',
      );

      debugPrint('🚨 تم تسجيل نشاط مشبوه: $reason');
      
    } catch (e) {
      debugPrint('⚠️ خطأ في تسجيل النشاط المشبوه: $e');
    }
  }

  /// تسجيل خطأ عام
  void logError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) {
    try {
      if (kDebugMode) return;

      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace ?? StackTrace.current,
        reason: reason,
        fatal: fatal,
      );
      
    } catch (e) {
      debugPrint('⚠️ خطأ في تسجيل الخطأ: $e');
    }
  }

  // ========================================================================
  // Force Refresh Remote Config
  // ← Hint: للتطوير - إجبار تحديث Remote Config
  // ========================================================================
  
  /// إجبار تحديث Remote Config
  /// 
  /// ← Hint: مفيد للتجربة أثناء التطوير
  Future<bool> forceRefreshConfig() async {
    try {
      if (_remoteConfig == null) return false;

      debugPrint('🔄 إجبار تحديث Remote Config...');
      
      final updated = await _remoteConfig!.fetchAndActivate();
      
      if (updated) {
        debugPrint('✅ تم تحديث Remote Config بنجاح');
      } else {
        debugPrint('ℹ️ لا توجد تحديثات جديدة');
      }
      
      return updated;
      
    } catch (e) {
      debugPrint('❌ خطأ في تحديث Remote Config: $e');
      return false;
    }
  }
}