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
    
        // ✅ الإصلاح: 5 دقائق للجميع (Development + Production)
        //: يتفعل عند اصدار للهواتف الحقيقية لـ Kill Switch 

        // minimumFetchInterval: const Duration(minutes: 5),

        // ✅ مثالي للتطوير - تحديث فوري
        minimumFetchInterval: Duration.zero,

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


        // 🔐 إضافة المفاتيح السرية
        'activation_secret': 'X4NL27OcZRHz6SaDoClQdeB0Psk5UgIw3tVMqvKnA1JmjbuiGE8FyfhpYTxrW9',
        'backup_magic_number': 'LxwJtAU9bgXI3oH15B8zFfKWNamYuO7R',
        'time_validation_secret': 'w0LAC8y57giFxtYvUZDzuTJdPalBX2W6roqhHsecIkEVR3Om19Knj4GQNMpfSb',


        // ========== Kill Switch المتقدم (جديد) ==========
         'app_maintenance_mode': false,
         'app_maintenance_message_ar': 'التطبيق متوقف مؤقتاً للصيانة. نعتذر عن الإزعاج.',
         'app_maintenance_message_en': 'App is under maintenance. Sorry for the inconvenience.',
         'app_critical_update_required': false,
         'app_allowed_versions': '["1.0.0"]',
         'app_blocked_devices': '[]',   
        
         
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
  /// التحقق من حالة التطبيق (Kill Switch المتقدم)
/// 
/// ← Hint: يُستدعى في SplashScreen قبل عرض أي شيء
/// 
/// Returns: Map يحتوي على:
///   - isActive: bool
///   - isBlocked: bool (جديد - للأجهزة المحظورة)
///   - needsUpdate: bool
///   - forceUpdate: bool
///   - message: String
///   - messageAr: String (جديد)
///   - messageEn: String (جديد)
///   - minVersion: String
///   - reason: String (جديد - سبب الحظر)
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
    
    // ========================================================================
    // التأكد من تهيئة Remote Config
    // ========================================================================
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

    // ========================================================================
    // 1️⃣ التحقق من الجهاز المحظور (أعلى أولوية!)
    // ========================================================================
    if (deviceFingerprint != null && deviceFingerprint.isNotEmpty) {
      final blockedDevicesJson = _remoteConfig!.getString('app_blocked_devices');
      
      try {
        final blockedDevices = (jsonDecode(blockedDevicesJson) as List<dynamic>)
          .cast<String>();
        
        if (blockedDevices.contains(deviceFingerprint)) {
          debugPrint('🚫 الجهاز محظور! Device: $deviceFingerprint');
          
          // ← Hint: تسجيل في Crashlytics
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

    // ========================================================================
    // 2️⃣ التحقق من Maintenance Mode
    // ========================================================================
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

    // ========================================================================
    // 3️⃣ التحقق من app_is_active (الطريقة القديمة - للتوافقية)
    // ========================================================================
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

    // ========================================================================
    // 4️⃣ التحقق من الإصدارات المسموحة (Whitelist)
    // ========================================================================
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

    // ========================================================================
    // 5️⃣ التحقق من الحد الأدنى للإصدار (الطريقة القديمة)
    // ========================================================================
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
        'isActive': !isForceUpdate, // ← إذا كان التحديث إجباري، نوقف التطبيق
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

    // ========================================================================
    // ✅ كل شيء على ما يرام - السماح بالدخول
    // ========================================================================
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
    
    // ← Hint: تسجيل الخطأ
    logError(e, stackTrace, reason: 'checkAppStatus_error');
    
    // ← Hint: في حالة الخطأ، نسمح بالدخول (fail-safe)
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
  
  //=================================================================
  //=================================================================
  /// الحصول على Activation Secret مع التحقق من الصحة 
  /// ← Hint: يجب أن يكون على الأقل 32 حرف للأمان
String getActivationSecret() {
  try {
    final secret = _remoteConfig?.getString('activation_secret');
    
    // ← Hint: التحقق من الطول والمحتوى
    if (secret == null || secret.isEmpty) {
      debugPrint('⚠️ Activation secret غير موجود في Remote Config!');
      return _getFallbackKey('activation');
    }
    
    if (secret.length < 32) {
      debugPrint('⚠️ Activation secret قصير جداً (${secret.length} حرف)');
      return _getFallbackKey('activation');
    }
    
    // ← Hint: منع استخدام القيم المؤقتة
    if (secret.contains('TEMP_') || secret.contains('CHANGE_ME')) {
      debugPrint('🚨 Activation secret لا يزال مؤقتاً!');
      return _getFallbackKey('activation');
    }
    
    return secret;
  } catch (e) {
    debugPrint('❌ خطأ في قراءة activation_secret: $e');
    return _getFallbackKey('activation');
  }
}

/// الحصول على Backup Magic Number مع التحقق
/// 
/// ← Hint: يجب أن يكون على الأقل 16 حرف
String getBackupMagicNumber() {
  try {
    final magic = _remoteConfig?.getString('backup_magic_number');
    
    if (magic == null || magic.isEmpty) {
      debugPrint('⚠️ Backup magic number غير موجود في Remote Config!');
      return _getFallbackKey('backup');
    }
    
    if (magic.length < 16) {
      debugPrint('⚠️ Backup magic number قصير جداً (${magic.length} حرف)');
      return _getFallbackKey('backup');
    }
    
    if (magic.contains('TEMP_') || magic.contains('FALLBACK')) {
      debugPrint('🚨 Backup magic number لا يزال مؤقتاً!');
      return _getFallbackKey('backup');
    }
    
    return magic;
  } catch (e) {
    debugPrint('❌ خطأ في قراءة backup_magic_number: $e');
    return _getFallbackKey('backup');
  }
}

/// الحصول على Time Validation Secret مع التحقق
/// 
/// ← Hint: يجب أن يكون على الأقل 32 حرف
String getTimeValidationSecret() {
  try {
    final secret = _remoteConfig?.getString('time_validation_secret');
    
    if (secret == null || secret.isEmpty) {
      debugPrint('⚠️ Time validation secret غير موجود في Remote Config!');
      return _getFallbackKey('time');
    }
    
    if (secret.length < 32) {
      debugPrint('⚠️ Time validation secret قصير جداً (${secret.length} حرف)');
      return _getFallbackKey('time');
    }
    
    if (secret.contains('TEMP_') || secret.contains('FALLBACK')) {
      debugPrint('🚨 Time validation secret لا يزال مؤقتاً!');
      return _getFallbackKey('time');
    }
    
    return secret;
  } catch (e) {
    debugPrint('❌ خطأ في قراءة time_validation_secret: $e');
    return _getFallbackKey('time');
  }
}

// بحاجة الى  ترجمة النصوص   
  //=================================================================
  //=================================================================

    // ⚠️ هذه الدالة لن تُستدعى أبداً الآن (لأن defaults موجودة)
  // لكن إذا حدث شيء غير متوقع، نُوقف التطبيق بدل استخدام مفتاح ضعيف  
 String _getFallbackKey(String type) {

  debugPrint('🚨 CRITICAL: Fallback key requested for: $type');
  debugPrint('   This should NEVER happen - both Firebase and defaults failed!');
  
  // تسجيل في Crashlytics
  logError(
    Exception('Critical security failure: Cannot retrieve $type key'),
    StackTrace.current,
    reason: 'Both Firebase Remote Config and local defaults failed',
    fatal: true,
  );
  
  // إيقاف التطبيق
  throw Exception(
    '🚨 Security Error\n\n'
    'Cannot start the app due to missing security keys.\n'
    'Please check:\n'
    '1. Internet connection\n'
    '2. Firebase configuration\n'
    '3. App integrity\n\n'
    'Contact support if this persists.'
  );

}

//=================================================================
//=================================================================


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