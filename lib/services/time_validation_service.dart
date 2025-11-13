// lib/services/time_validation_service.dart

import 'package:flutter/material.dart';
import 'package:ntp/ntp.dart';
import 'secure_time_storage.dart';

/// ⏰ خدمة التحقق من صحة الوقت والحماية من التلاعب - محسّنة
/// ← Hint: تستخدم NTP + Drift calculation + Checksum مع تحسينات الأداء
class TimeValidationService {
  // ← Hint: Singleton Pattern
  static final TimeValidationService _instance = TimeValidationService._internal();
  TimeValidationService._internal();
  factory TimeValidationService() => _instance;
  static TimeValidationService get instance => _instance;

  // ← Hint: التخزين
  final _storage = SecureTimeStorage.instance;

  // ← Hint: البيانات المحملة في الذاكرة
  DateTime? _lastKnownRealTime;
  DateTime? _lastDeviceTime;
  Duration _timeDrift = Duration.zero;
  DateTime? _lastOnlineCheck;
  int _daysOffline = 0;
  int _suspiciousAttempts = 0;

  // ← Hint: الثوابت
  static const int maxDaysOffline = 7;
  static const int maxSuspiciousAttempts = 3;
  static const int driftToleranceDays = 1;
  
  // ← Hint: Timeout محسّن - قصير جداً (كان 5 ثواني، الآن 2)
  static const Duration ntpTimeout = Duration(seconds: 2);

  // ← Hint: قائمة خوادم NTP محسّنة (3 خوادم فقط - الأسرع)
  // Google وCloudflare هم الأسرع عادةً
  static const List<String> ntpServers = [
    'time.google.com',      // ← الأسرع
    'time.cloudflare.com',  // ← سريع جداً
    'pool.ntp.org',         // ← احتياطي
  ];

  // ==========================================================================
  // ← Hint: التهيئة الأولية
  // ==========================================================================
  Future<void> initialize() async {
    debugPrint('🔄 بدء تهيئة TimeValidationService...');
    
    try {
      final data = await _storage.loadTimeData();

      if (data != null) {
        _lastKnownRealTime = DateTime.parse(data['last_real_time']);
        _lastDeviceTime = DateTime.parse(data['last_device_time']);
        _timeDrift = Duration(seconds: data['time_drift_seconds']);
        _lastOnlineCheck = DateTime.parse(data['last_online_check']);
        _daysOffline = data['days_offline'];
        _suspiciousAttempts = data['suspicious_attempts'];

        debugPrint('✅ تم تحميل البيانات المحفوظة');
        debugPrint('   - آخر وقت حقيقي: $_lastKnownRealTime');
        debugPrint('   - Drift: ${_timeDrift.inSeconds} ثانية');
        debugPrint('   - أيام بدون إنترنت: $_daysOffline');
        debugPrint('   - محاولات مشبوهة: $_suspiciousAttempts');
      } else {
        debugPrint('ℹ️ لا توجد بيانات محفوظة - أول تشغيل');
      }
    } catch (e) {
      debugPrint('❌ خطأ في التهيئة: $e');
    }
  }

  // ==========================================================================
  // ← Hint: الحصول على الوقت الحقيقي (محسّن)
  // ==========================================================================
  Future<DateTime> getRealTime() async {
    try {
      // ← Hint: محاولة الحصول على الوقت من NTP (مع تحسينات)
      final ntpTime = await _tryGetNtpTime();

      if (ntpTime != null) {
        // ← Hint: نجحت المزامنة - تحديث البيانات
        await _updateAfterSync(ntpTime);
        return ntpTime;
      }

      // ← Hint: بدون إنترنت - استخدام Drift
      final deviceTime = DateTime.now();
      final estimatedRealTime = deviceTime.add(_timeDrift);

      debugPrint('ℹ️ العمل بدون إنترنت - الوقت المقدر: $estimatedRealTime');
      
      // ← Hint: تحديث عداد الأيام بدون إنترنت
      await _updateDaysOffline();

      return estimatedRealTime;
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على الوقت: $e');
      return DateTime.now();
    }
  }

  // ==========================================================================
  // ← Hint: محاولة الحصول على الوقت من NTP (محسّن جداً!)
  // ==========================================================================
  Future<DateTime?> _tryGetNtpTime() async {
    // ← Hint: استراتيجية ذكية - إذا لدينا drift صالح، نحاول مرة واحدة فقط!
    if (_timeDrift != Duration.zero && _lastOnlineCheck != null) {
      // ← Hint: لدينا drift محفوظ - محاولة سريعة مع خادم واحد فقط
      try {
        debugPrint('⚡ محاولة سريعة مع ${ntpServers[0]}...');
        
        final ntpTime = await NTP.now(
          lookUpAddress: ntpServers[0],
          timeout: ntpTimeout, // ← 2 ثانية فقط!
        );

        debugPrint('✅ مزامنة سريعة ناجحة في ${ntpTimeout.inSeconds}s');
        return ntpTime;
      } catch (e) {
        debugPrint('⚠️ فشلت المزامنة السريعة - سنستخدم drift المحفوظ');
        // ← Hint: لا مشكلة - drift صالح ودقيق
        return null;
      }
    }

    // ← Hint: لا يوجد drift صالح - نحتاج مزامنة كاملة
    debugPrint('🌐 مزامنة كاملة مطلوبة (أول مرة أو drift غير صالح)...');
    
    for (final server in ntpServers) {
      try {
        debugPrint('   محاولة: $server');
        
        final ntpTime = await NTP.now(
          lookUpAddress: server,
          timeout: ntpTimeout, // ← Timeout قصير لكل خادم
        );

        debugPrint('✅ نجح الاتصال بـ $server');
        return ntpTime;
      } catch (e) {
        debugPrint('   ⚠️ فشل $server - التالي...');
        continue; // ← تجربة الخادم التالي
      }
    }

    debugPrint('❌ فشلت جميع محاولات NTP (سنستخدم drift إن وُجد)');
    return null;
  }

  // ==========================================================================
  // ← Hint: تحديث البيانات بعد المزامنة الناجحة
  // ==========================================================================
  Future<void> _updateAfterSync(DateTime ntpTime) async {
    final deviceTime = DateTime.now();
    final newDrift = ntpTime.difference(deviceTime);

    debugPrint('✅ مزامنة ناجحة:');
    debugPrint('   - وقت NTP: $ntpTime');
    debugPrint('   - وقت الجهاز: $deviceTime');
    debugPrint('   - Drift الجديد: ${newDrift.inSeconds} ثانية');

    _lastKnownRealTime = ntpTime;
    _lastDeviceTime = deviceTime;
    _timeDrift = newDrift;
    _lastOnlineCheck = ntpTime;
    _daysOffline = 0; // ← إعادة تعيين العداد

    await _storage.saveTimeData(
      realTime: ntpTime,
      deviceTime: deviceTime,
      timeDrift: newDrift,
      lastOnlineCheck: ntpTime,
      daysOffline: 0,
      suspiciousAttempts: _suspiciousAttempts,
    );
  }

  // ==========================================================================
  // ← Hint: تحديث عدد الأيام بدون إنترنت
  // ==========================================================================
  Future<void> _updateDaysOffline() async {
    if (_lastOnlineCheck == null) return;

    final now = DateTime.now();
    final daysSinceLastCheck = now.difference(_lastOnlineCheck!).inDays;

    if (daysSinceLastCheck != _daysOffline) {
      _daysOffline = daysSinceLastCheck;
      await _storage.updateDaysOffline(_daysOffline);
      
      debugPrint('ℹ️ عدد الأيام بدون إنترنت: $_daysOffline/$maxDaysOffline');
    }
  }

  // ==========================================================================
  // ← Hint: كشف التلاعب بالوقت (سريع - بدون NTP)
  // ==========================================================================
  Future<Map<String, dynamic>> detectManipulation() async {
    debugPrint('🔍 بدء فحص التلاعب...');

    try {
      // ← Hint: 1. التحقق من عداد المحاولات المشبوهة
      final attempts = await _storage.getSuspiciousAttempts();
      if (attempts >= maxSuspiciousAttempts) {
        debugPrint('🚫 تم تجاوز الحد الأقصى للمحاولات المشبوهة ($attempts)');
        return {
          'isManipulated': true,
          'reason': 'suspicious_attempts',
          'message': 'تم رصد محاولات تلاعب متكررة ($attempts محاولة)',
        };
      }

      // ← Hint: 2. التحقق من الوقت للخلف
      if (_lastDeviceTime != null) {
        final currentDeviceTime = DateTime.now();
        
        if (currentDeviceTime.isBefore(_lastDeviceTime!)) {
          debugPrint('⚠️ الوقت للخلف! التلاعب المكتشف:');
          debugPrint('   - آخر وقت: $_lastDeviceTime');
          debugPrint('   - الوقت الحالي: $currentDeviceTime');
          
          await _storage.incrementSuspiciousAttempts();
          _suspiciousAttempts++;

          return {
            'isManipulated': true,
            'reason': 'time_backward',
            'message': 'تم تغيير تاريخ الجهاز للخلف',
            'attempts': _suspiciousAttempts,
          };
        }

        // ← Hint: 3. التحقق من قفزة كبيرة بدون إنترنت
        if (_daysOffline > 0) {
          final diff = currentDeviceTime.difference(_lastDeviceTime!);
          
          if (diff.inDays > driftToleranceDays) {
            debugPrint('⚠️ قفزة كبيرة في الوقت بدون إنترنت!');
            debugPrint('   - الفرق: ${diff.inDays} يوم');
            
            await _storage.incrementSuspiciousAttempts();
            _suspiciousAttempts++;

            return {
              'isManipulated': true,
              'reason': 'large_jump',
              'message': 'قفزة غير طبيعية في التاريخ',
              'attempts': _suspiciousAttempts,
            };
          }
        }
      }

      debugPrint('✅ لم يتم رصد أي تلاعب');
      return {
        'isManipulated': false,
        'message': 'الوقت صحيح',
      };
    } catch (e) {
      debugPrint('❌ خطأ في كشف التلاعب: $e');
      return {
        'isManipulated': false,
        'message': 'خطأ في الفحص',
      };
    }
  }

  // ==========================================================================
  // ← Hint: مزامنة في الخلفية (جديد - لا تُوقف التطبيق!)
  // ==========================================================================
  Future<void> backgroundSync() async {
    // ← Hint: هذه الدالة تعمل في الخلفية بدون انتظار
    // يمكن استدعاؤها بعد فتح التطبيق بدون تأخير
    debugPrint('🔄 بدء مزامنة خلفية...');
    
    try {
      final ntpTime = await _tryGetNtpTime();
      if (ntpTime != null) {
        await _updateAfterSync(ntpTime);
        debugPrint('✅ مزامنة خلفية ناجحة');
      } else {
        debugPrint('ℹ️ لم تنجح المزامنة الخلفية (لا مشكلة - drift صالح)');
      }
    } catch (e) {
      debugPrint('⚠️ فشلت المزامنة الخلفية: $e');
    }
  }

  // ==========================================================================
  // ← Hint: التحقق من ضرورة الاتصال بالإنترنت
  // ==========================================================================
  bool shouldRequireInternet() {
    return _daysOffline >= maxDaysOffline;
  }

  // ==========================================================================
  // ← Hint: الحصول على عدد الأيام المتبقية
  // ==========================================================================
  int getDaysRemaining() {
    return maxDaysOffline - _daysOffline;
  }

  // ==========================================================================
  // ← Hint: الحصول على عداد المحاولات المشبوهة
  // ==========================================================================
  int getSuspiciousAttempts() {
    return _suspiciousAttempts;
  }

  // ==========================================================================
  // ← Hint: الحصول على عدد المحاولات المتبقية قبل الحظر
  // ==========================================================================
  int getAttemptsRemaining() {
    return maxSuspiciousAttempts - _suspiciousAttempts;
  }

  // ==========================================================================
  // ← Hint: إعادة تعيين بعد التفعيل الجديد
  // ==========================================================================
  Future<void> resetOnNewActivation() async {
    debugPrint('🔄 إعادة تعيين بيانات الوقت بعد التفعيل الجديد...');
    
    try {
      await _storage.clearAll();

      _lastKnownRealTime = null;
      _lastDeviceTime = null;
      _timeDrift = Duration.zero;
      _lastOnlineCheck = null;
      _daysOffline = 0;
      _suspiciousAttempts = 0;

      // ← Hint: محاولة مزامنة جديدة (في الخلفية)
      backgroundSync();

      debugPrint('✅ تم إعادة التعيين بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إعادة التعيين: $e');
    }
  }

  // ==========================================================================
  // ← Hint: إعادة تعيين عداد المحاولات المشبوهة
  // ==========================================================================
  Future<void> resetSuspiciousAttempts() async {
    debugPrint('🔄 إعادة تعيين عداد المحاولات المشبوهة...');
    
    _suspiciousAttempts = 0;
    await _storage.resetSuspiciousAttempts();

    debugPrint('✅ تم إعادة تعيين العداد');
  }

  // ==========================================================================
  // ← Hint: فرض مزامنة فورية (للمستخدم عند الحاجة)
  // ==========================================================================
  Future<bool> forceSync() async {
    debugPrint('🔄 بدء المزامنة الإجبارية...');
    
    try {
      final ntpTime = await _tryGetNtpTime();
      
      if (ntpTime != null) {
        await _updateAfterSync(ntpTime);
        await resetSuspiciousAttempts();
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ فشلت المزامنة الإجبارية: $e');
      return false;
    }
  }

  // ==========================================================================
  // ← Hint: معلومات الحالة (للتصحيح والمطورين)
  // ==========================================================================
  Map<String, dynamic> getStatus() {
    return {
      'last_real_time': _lastKnownRealTime?.toIso8601String(),
      'last_device_time': _lastDeviceTime?.toIso8601String(),
      'time_drift_seconds': _timeDrift.inSeconds,
      'last_online_check': _lastOnlineCheck?.toIso8601String(),
      'days_offline': _daysOffline,
      'days_remaining': getDaysRemaining(),
      'suspicious_attempts': _suspiciousAttempts,
      'attempts_remaining': getAttemptsRemaining(),
      'should_require_internet': shouldRequireInternet(),
    };
  }
}