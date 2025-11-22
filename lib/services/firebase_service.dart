// lib/services/firebase_service.dart

import 'dart:convert';

import 'package:accountant_touch/services/native_secrets_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 🔥 خدمة Firebase المركزية - Singleton Pattern (محدثة - Week 1)
/// 
/// ← Hint: التحديثات الرئيسية:
/// - ✅ تأمين المفاتيح السرية نهائياً
/// - ✅ Fail-Safe محسّن (إيقاف التطبيق عند فشل Firebase)
/// - ✅ Environment-based Caching
/// - ✅ Root Detection logging
class FirebaseService {
  // ========================================================================
  // Singleton Pattern
  // ========================================================================
  
  static final FirebaseService _instance = FirebaseService._internal();
  FirebaseService._internal();
  factory FirebaseService() => _instance;
  static FirebaseService get instance => _instance;

  // ========================================================================
  // المتغيرات الخاصة
  // ========================================================================
  
  FirebaseRemoteConfig? _remoteConfig;
  bool _isInitialized = false;
  
  bool get isInitialized => _isInitialized;
  FirebaseRemoteConfig? get remoteConfig => _remoteConfig;

  // ========================================================================
  // التهيئة الأساسية
  // ========================================================================
  
  /// تهيئة Firebase (يُستدعى مرة واحدة في main.dart)
  Future<bool> initialize({Function(String)? onError}) async {
    try {
      debugPrint('🔥 بدء تهيئة Firebase...');

      if (_isInitialized) {
        debugPrint('✅ Firebase مُهيّأ مسبقاً');
        return true;
      }

      // 1. تهيئة Firebase Core
      await Firebase.initializeApp();
      debugPrint('✅ تم تهيئة Firebase Core');

      // 2. تهيئة Remote Config
      await _initializeRemoteConfig();

      // 3. تهيئة Crashlytics
      await _initializeCrashlytics();

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
  Future<void> _initializeRemoteConfig() async {
    try {
      debugPrint('🔧 تهيئة Remote Config...');

      _remoteConfig = FirebaseRemoteConfig.instance;

      // ========================================================================
      // ✅ الإصلاح 1: Environment-based Caching
      // ========================================================================
      
      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          
          // ✅ للتطوير: تحديث فوري | للإنتاج: 5 دقائق
          minimumFetchInterval: kDebugMode || kProfileMode
            ? Duration.zero                   
            : const Duration(minutes: 5),
        ),
      );

      debugPrint('ℹ️ Cache Interval: ${kDebugMode ? "0s (Dev)" : "5min (Prod)"}');

      // ========================================================================
      // ✅ الإصلاح 2: القيم الافتراضية - قيم وهمية فقط
      // ← Hint: لن تُستخدم أبداً - إذا استُخدمت = فشل Firebase = إيقاف التطبيق
      // ========================================================================
      
      await _remoteConfig!.setDefaults({
        // ========== App Control ==========
        'app_is_active': true,
        'app_min_version': '1.0.0',
        'app_force_update': false,
        'app_block_message': 'التطبيق متوقف مؤقتاً للصيانة',

        // ========== 🔐 مفاتيح سرية - قيم وهمية (لن تعمل) ==========
        'activation_secret': 'INVALID_FIREBASE_REQUIRED_FOR_ACTIVATION',
        'backup_magic_number': 'INVALID_USE_FIREBASE',
        'time_validation_secret': 'INVALID_CONNECT_TO_INTERNET_FIRST',

        // ========== Kill Switch المتقدم ==========
        'app_maintenance_mode': false,
        'app_maintenance_message_ar': 'التطبيق متوقف مؤقتاً للصيانة. نعتذر عن الإزعاج.',
        'app_maintenance_message_en': 'App is under maintenance. Sorry for the inconvenience.',
        'app_critical_update_required': false,
        'app_allowed_versions': '["1.0.0"]',
        'app_blocked_devices': '[]',
        
        // ========== Security Settings ==========
        'pbkdf2_iterations': 100000,
        'max_suspicious_attempts': 3,
        'trial_period_days': 14,
        
        // ========== NTP Servers ==========
        'ntp_servers': '["time.google.com","time.cloudflare.com","pool.ntp.org"]',
        
        // ========== Features Flags ==========
        'feature_biometric': true,
        'feature_backup_v2': true,
        'feature_online_validation': false,
      });

      debugPrint('✅ تم تعيين القيم الافتراضية (الوهمية)');

      // ========================================================================
      // جلب وتفعيل القيم من Firebase
      // ========================================================================
      
      final updated = await _remoteConfig!.fetchAndActivate();
      
      if (updated) {
        debugPrint('✅ تم تحديث Remote Config بقيم جديدة من Firebase');
      } else {
        debugPrint('ℹ️ Remote Config يستخدم القيم المخزنة (Cache)');
      }

      // ← Hint: طباعة بعض القيم للتأكد (في Development فقط)
      if (kDebugMode) {
        debugPrint('📋 Remote Config Values:');
        debugPrint('  - app_is_active: ${_remoteConfig!.getBool('app_is_active')}');
        debugPrint('  - trial_period_days: ${_remoteConfig!.getInt('trial_period_days')}');
        
        // ✅ فحص المفاتيح السرية (بدون طباعتها!)
        final activationSecret = _remoteConfig!.getString('activation_secret');
        final backupMagic = _remoteConfig!.getString('backup_magic_number');
        final timeSecret = _remoteConfig!.getString('time_validation_secret');
        
        debugPrint('  - activation_secret: ${activationSecret.substring(0, 10)}... (${activationSecret.length} chars)');
        debugPrint('  - backup_magic_number: ${backupMagic.substring(0, 10)}... (${backupMagic.length} chars)');
        debugPrint('  - time_validation_secret: ${timeSecret.substring(0, 10)}... (${timeSecret.length} chars)');
      }

    } catch (e) {
      debugPrint('⚠️ خطأ في تهيئة Remote Config: $e');
      debugPrint('⚠️ سيتم استخدام القيم الافتراضية (الوهمية)');
      // ← Hint: لا نرمي Exception - نكمل بالقيم الافتراضية
    }
  }

  // ========================================================================
  // Crashlytics
  // ========================================================================
  
  /// تهيئة Crashlytics لتتبع الأخطاء
  Future<void> _initializeCrashlytics() async {
    try {
      debugPrint('📊 تهيئة Crashlytics...');

      if (kDebugMode) {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
        debugPrint('ℹ️ Crashlytics معطّل في Debug mode');
      } else {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
        debugPrint('✅ Crashlytics مُفعّل في Release mode');
      }

      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

    } catch (e) {
      debugPrint('⚠️ خطأ في تهيئة Crashlytics: $e');
    }
  }

  // ========================================================================
  // Kill Switch - التحكم في حالة التطبيق عن بُعد
  // ========================================================================
  
  /// التحقق من حالة التطبيق (Kill Switch المتقدم)
  Future<Map<String, dynamic>> checkAppStatus({
    required String currentVersion,
    String? deviceFingerprint,
    String? locale,
  }) async {
    try {
      debugPrint('🔍 فحص حالة التطبيق...');
      debugPrint('   - الإصدار: $currentVersion');
      debugPrint('   - Device ID: ${deviceFingerprint ?? "N/A"}');
      debugPrint('   - اللغة: ${locale ?? "ar"}');
      
      if (_remoteConfig == null) {
        debugPrint('⚠️ Remote Config غير مُهيّأ - السماح بالدخول (fail-safe)');
        return {
          'isActive': true,
          'isBlocked': false,
          'needsUpdate': false,
          'forceUpdate': false,
          'message': '',
          'messageAr': '',
          'messageEn': '',
          'reason': '',
        };
      }

      // 1️⃣ التحقق من الجهاز المحظور
      if (deviceFingerprint != null && deviceFingerprint.isNotEmpty) {
        final blockedDevicesJson = _remoteConfig!.getString('app_blocked_devices');
        
        try {
          final blockedDevices = (jsonDecode(blockedDevicesJson) as List<dynamic>)
            .cast<String>();
          
          if (blockedDevices.contains(deviceFingerprint)) {
            debugPrint('🚫 الجهاز محظور! Device: $deviceFingerprint');
            
            logSuspiciousActivity(
              reason: 'blocked_device',
              deviceId: deviceFingerprint,
              additionalInfo: {'action': 'blocked_device_tried_to_access'},
            );
            
            return {
              'isActive': false,
              'isBlocked': true,
              'needsUpdate': false,
              'forceUpdate': false,
              'message': 'تم حظر هذا الجهاز من استخدام التطبيق',
              'messageAr': 'تم حظر هذا الجهاز من استخدام التطبيق. للاستفسار تواصل مع الدعم الفني.',
              'messageEn': 'This device has been blocked. Contact support for inquiries.',
              'reason': 'blocked_device',
            };
          }
        } catch (e) {
          debugPrint('⚠️ خطأ في قراءة app_blocked_devices: $e');
        }
      }

      // 2️⃣ التحقق من Maintenance Mode
      final isMaintenanceMode = _remoteConfig!.getBool('app_maintenance_mode');
      
      if (isMaintenanceMode) {
        debugPrint('🔧 وضع الصيانة مُفعّل');
        
        final messageAr = _remoteConfig!.getString('app_maintenance_message_ar');
        final messageEn = _remoteConfig!.getString('app_maintenance_message_en');
        final message = (locale == 'en') ? messageEn : messageAr;
        
        return {
          'isActive': false,
          'isBlocked': false,
          'needsUpdate': false,
          'forceUpdate': false,
          'message': message,
          'messageAr': messageAr,
          'messageEn': messageEn,
          'reason': 'maintenance',
        };
      }

      // 3️⃣ التحقق من app_is_active
      final isActive = _remoteConfig!.getBool('app_is_active');
      
      if (!isActive) {
        debugPrint('🚫 التطبيق موقوف (app_is_active = false)');
        
        final blockMessage = _remoteConfig!.getString('app_block_message');
        
        return {
          'isActive': false,
          'isBlocked': false,
          'needsUpdate': false,
          'forceUpdate': false,
          'message': blockMessage,
          'messageAr': blockMessage,
          'messageEn': blockMessage,
          'reason': 'app_inactive',
        };
      }

      // 4️⃣ التحقق من الإصدارات المسموحة (Whitelist)
      try {
        final allowedVersionsJson = _remoteConfig!.getString('app_allowed_versions');
        final allowedVersions = (jsonDecode(allowedVersionsJson) as List<dynamic>)
          .cast<String>();
        
        if (allowedVersions.isNotEmpty && !allowedVersions.contains(currentVersion)) {
          debugPrint('⚠️ الإصدار الحالي ($currentVersion) غير مسموح');
          debugPrint('   الإصدارات المسموحة: $allowedVersions');
          
          return {
            'isActive': false,
            'isBlocked': false,
            'needsUpdate': true,
            'forceUpdate': true,
            'message': 'هذا الإصدار لم يعد مدعوماً. يرجى التحديث.',
            'messageAr': 'هذا الإصدار من التطبيق لم يعد مدعوماً. يرجى تحديث التطبيق للمتابعة.',
            'messageEn': 'This app version is no longer supported. Please update to continue.',
            'reason': 'version_not_allowed',
            'minVersion': allowedVersions.last,
          };
        }
      } catch (e) {
        debugPrint('⚠️ خطأ في قراءة app_allowed_versions: $e');
      }

      // 5️⃣ التحقق من الحد الأدنى للإصدار
      final minVersion = _remoteConfig!.getString('app_min_version');
      final criticalUpdate = _remoteConfig!.getBool('app_critical_update_required');
      final forceUpdate = _remoteConfig!.getBool('app_force_update');
      
      final needsUpdate = _compareVersions(currentVersion, minVersion) < 0;
      
      if (needsUpdate) {
        debugPrint('ℹ️ يوجد تحديث متاح');
        debugPrint('   الإصدار الحالي: $currentVersion');
        debugPrint('   الإصدار المطلوب: $minVersion');
        debugPrint('   إجباري: ${forceUpdate || criticalUpdate}');
        
        final isForceUpdate = forceUpdate || criticalUpdate;
        
        return {
          'isActive': !isForceUpdate,
          'isBlocked': false,
          'needsUpdate': true,
          'forceUpdate': isForceUpdate,
          'message': isForceUpdate 
            ? 'تحديث أمني مهم متاح. يجب التحديث للمتابعة.'
            : 'يتوفر تحديث جديد. يُنصح بالتحديث.',
          'messageAr': isForceUpdate
            ? 'تحديث أمني مهم متاح. يجب تحديث التطبيق للمتابعة.'
            : 'يتوفر تحديث جديد للتطبيق. يُنصح بالتحديث.',
          'messageEn': isForceUpdate
            ? 'Critical security update available. Please update to continue.'
            : 'A new update is available. Update recommended.',
          'reason': criticalUpdate ? 'critical_update' : 'update_available',
          'minVersion': minVersion,
        };
      }

      // ✅ كل شيء على ما يرام
      debugPrint('✅ التطبيق نشط وجاهز');
      
      return {
        'isActive': true,
        'isBlocked': false,
        'needsUpdate': false,
        'forceUpdate': false,
        'message': '',
        'messageAr': '',
        'messageEn': '',
        'reason': '',
      };

    } catch (e, stackTrace) {
      debugPrint('❌ خطأ في فحص حالة التطبيق: $e');
      
      logError(e, stackTrace, reason: 'checkAppStatus_error');
      
      return {
        'isActive': true,
        'isBlocked': false,
        'needsUpdate': false,
        'forceUpdate': false,
        'message': '',
        'messageAr': '',
        'messageEn': '',
        'reason': 'error',
      };
    }
  }

  // ========================================================================
  // مقارنة الإصدارات
  // ========================================================================
  
  int _compareVersions(String version1, String version2) {
    try {
      final v1Parts = version1.split('.').map(int.parse).toList();
      final v2Parts = version2.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        final v1Part = i < v1Parts.length ? v1Parts[i] : 0;
        final v2Part = i < v2Parts.length ? v2Parts[i] : 0;

        if (v1Part < v2Part) return -1;
        if (v1Part > v2Part) return 1;
      }

      return 0;
      
    } catch (e) {
      debugPrint('⚠️ خطأ في مقارنة الإصدارات: $e');
      return 0;
    }
  }

  // ========================================================================
  // ✅ الإصلاح 3: Getters للمفاتيح السرية مع التحقق الصارم
  // ========================================================================
  
  /// الحصول على Activation Secret مع التحقق الصارم من Native Layer 
  String getActivationSecret() {
        try {
      final secret = NativeSecretsService.instance.cachedActivationSecret;
      
      if (secret == null || secret.isEmpty) {
        debugPrint('⚠️ Activation secret غير محمّل - استدعِ NativeSecretsService.initialize() أولاً');
        throw Exception('Activation secret not loaded. Call NativeSecretsService.initialize() first.');
      }
      
      if (secret.length < 32) {
        debugPrint('⚠️ Activation secret قصير جداً (${secret.length} حرف)');
      }
      
      if (secret.contains('INVALID') || 
          secret.contains('FAILED') ||
          secret.contains('TEMP_')) {
        debugPrint('🚨 Activation secret يبدو وهمياً أو غير صالح');
        throw Exception('Invalid activation secret detected');
      }
      
      return secret;
    } catch (e) {
      debugPrint('❌ خطأ في قراءة activation_secret: $e');
      
      // ← Hint: Fail-Safe - إيقاف التطبيق
      throw Exception(
        '🚨 خطأ أمني حرج\n\n'
        'لا يمكن الوصول لمفاتيح التفعيل.\n'
        'رمز الخطأ: ACTIVATION_KEY_FAILED'
      );
    }
   }

  /// الحصول على Backup Magic Number مع التحقق الصارم من Native Layer 
  String getBackupMagicNumber() {
        try {
      final magic = NativeSecretsService.instance.cachedBackupMagic;
      
      if (magic == null || magic.isEmpty) {
        debugPrint('⚠️ Backup magic غير محمّل');
        throw Exception('Backup magic not loaded');
      }
      
      if (magic.length < 16) {
        debugPrint('⚠️ Backup magic قصير جداً (${magic.length} حرف)');
      }
      
      if (magic.contains('INVALID') || 
          magic.contains('FAILED') ||
          magic.contains('USE_FIREBASE')) {
        debugPrint('🚨 Backup magic يبدو وهمياً أو غير صالح');
        throw Exception('Invalid backup magic detected');
      }
      
      return magic;
    } catch (e) {
      debugPrint('❌ خطأ في قراءة backup_magic_number: $e');
      
      throw Exception(
        '🚨 خطأ أمني حرج\n\n'
        'لا يمكن الوصول لمفاتيح النسخ الاحتياطي.\n'
        'رمز الخطأ: BACKUP_KEY_FAILED'
      );
    }
  }

  /// الحصول على Time Validation Secret مع التحقق الصارم
  String getTimeValidationSecret() {
        try {
      final secret = NativeSecretsService.instance.cachedTimeSecret;
      
      if (secret == null || secret.isEmpty) {
        debugPrint('⚠️ Time secret غير محمّل');
        throw Exception('Time secret not loaded');
      }
      
      if (secret.length < 32) {
        debugPrint('⚠️ Time secret قصير جداً (${secret.length} حرف)');
      }
      
      if (secret.contains('INVALID') || 
          secret.contains('FAILED') ||
          secret.contains('CONNECT_TO_INTERNET')) {
        debugPrint('🚨 Time secret يبدو وهمياً أو غير صالح');
        throw Exception('Invalid time secret detected');
      }
      
      return secret;
    } catch (e) {
      debugPrint('❌ خطأ في قراءة time_validation_secret: $e');
      
      throw Exception(
        '🚨 خطأ أمني حرج\n\n'
        'لا يمكن الوصول لمفاتيح التحقق من الوقت.\n'
        'رمز الخطأ: TIME_KEY_FAILED'
      );
    }
  }

  // ========================================================================
  // ✅ الإصلاح 4: Fail-Safe محسّن (إيقاف التطبيق)
  // ========================================================================
  
  /// ⚠️ هذه الدالة لن تُستدعى أبداً في الحالة الطبيعية
  /// لكن إذا حدث شيء غير متوقع، نُوقف التطبيق بدل استخدام مفتاح ضعيف
  String _getFallbackKey(String type) {
    debugPrint('');
    debugPrint('═══════════════════════════════════════════');
    debugPrint('🚨 CRITICAL SECURITY ERROR');
    debugPrint('═══════════════════════════════════════════');
    debugPrint('Cannot retrieve $type key from:');
    debugPrint('  ✗ Firebase Remote Config (failed)');
    debugPrint('  ✗ Local defaults (intentionally invalid)');
    debugPrint('');
    debugPrint('This should NEVER happen if:');
    debugPrint('  1. Internet connection is available');
    debugPrint('  2. Firebase is configured correctly');
    debugPrint('  3. App has valid Remote Config values');
    debugPrint('═══════════════════════════════════════════');
    
    // تسجيل في Crashlytics
    logError(
      Exception('CRITICAL: Cannot retrieve $type key - both Firebase and defaults failed'),
      StackTrace.current,
      reason: 'Security key retrieval failure',
      fatal: true,
    );
    
    // إيقاف التطبيق نهائياً
    throw Exception(
      '🚨 خطأ أمني حرج\n\n'
      'لا يمكن بدء التطبيق بسبب فقدان مفاتيح الأمان.\n\n'
      'الرجاء التحقق من:\n'
      '• الاتصال بالإنترنت\n'
      '• إعدادات Firebase\n'
      '• سلامة التطبيق\n\n'
      'إذا استمرت المشكلة، تواصل مع الدعم الفني.\n\n'
      'رمز الخطأ: KEY_RETRIEVAL_FAILED_$type'
    );
  }

  // ========================================================================
  // باقي Getters
  // ========================================================================
  
  int getPbkdf2Iterations() {
    return _remoteConfig?.getInt('pbkdf2_iterations') ?? 100000;
  }

  int getMaxSuspiciousAttempts() {
    return _remoteConfig?.getInt('max_suspicious_attempts') ?? 3;
  }

  int getTrialPeriodDays() {
    return _remoteConfig?.getInt('trial_period_days') ?? 14;
  }

  List<String> getNtpServers() {
    try {
      final serversJson = _remoteConfig?.getString('ntp_servers') 
        ?? '["time.google.com"]';
      
      final decoded = jsonDecode(serversJson) as List<dynamic>;
      return decoded.cast<String>();
      
    } catch (e) {
      debugPrint('⚠️ خطأ في قراءة NTP servers: $e');
      return ['time.google.com', 'time.cloudflare.com', 'pool.ntp.org'];
    }
  }

  bool isBiometricEnabled() {
    return _remoteConfig?.getBool('feature_biometric') ?? true;
  }

  bool isBackupV2Enabled() {
    return _remoteConfig?.getBool('feature_backup_v2') ?? true;
  }

  bool isOnlineValidationEnabled() {
    return _remoteConfig?.getBool('feature_online_validation') ?? false;
  }

  // ========================================================================
  // Crashlytics Helpers
  // ========================================================================
  
  /// تسجيل محاولة قرصنة محتملة
  void logSuspiciousActivity({
    required String reason,
    required String deviceId,
    Map<String, dynamic>? additionalInfo,
  }) {
    try {
      if (kDebugMode) return;

      FirebaseCrashlytics.instance.log('🚨 Suspicious Activity: $reason');
      FirebaseCrashlytics.instance.setCustomKey('device_id', deviceId);
      FirebaseCrashlytics.instance.setCustomKey('reason', reason);
      
      if (additionalInfo != null) {
        additionalInfo.forEach((key, value) {
          FirebaseCrashlytics.instance.setCustomKey(key, value.toString());
        });
      }

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
  // ========================================================================
  
  /// إجبار تحديث Remote Config
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