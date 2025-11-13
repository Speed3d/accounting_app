// lib/services/secure_time_storage.dart

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 🔐 التخزين الآمن لبيانات الوقت
/// ← Hint: يستخدم SecureStorage مع Checksum للحماية من التلاعب
class SecureTimeStorage {
  // ← Hint: Singleton Pattern
  static final SecureTimeStorage _instance = SecureTimeStorage._internal();
  SecureTimeStorage._internal();
  factory SecureTimeStorage() => _instance;
  static SecureTimeStorage get instance => _instance;

  // ← Hint: التخزين الآمن
  final _secureStorage = const FlutterSecureStorage();

  // ← Hint: مفاتيح التخزين
  static const String _lastRealTimeKey = 'last_real_time';
  static const String _lastDeviceTimeKey = 'last_device_time';
  static const String _timeDriftKey = 'time_drift_seconds';
  static const String _lastOnlineCheckKey = 'last_online_check';
  static const String _daysOfflineKey = 'days_offline';
  static const String _suspiciousAttemptsKey = 'suspicious_attempts';
  static const String _checksumKey = 'data_checksum';

  // ← Hint: مفتاح سري للـ Checksum
  static const String _secretKey = 'TIME_VALIDATION_SECRET_2025_SHAHAD';

  // ==========================================================================
  // ← Hint: حفظ بيانات الوقت مع Checksum
  // ==========================================================================
  Future<void> saveTimeData({
    required DateTime realTime,
    required DateTime deviceTime,
    required Duration timeDrift,
    required DateTime lastOnlineCheck,
    required int daysOffline,
    required int suspiciousAttempts,
  }) async {
    try {
      // ← Hint: تحويل البيانات لـ Map
      final data = {
        'last_real_time': realTime.toIso8601String(),
        'last_device_time': deviceTime.toIso8601String(),
        'time_drift_seconds': timeDrift.inSeconds,
        'last_online_check': lastOnlineCheck.toIso8601String(),
        'days_offline': daysOffline,
        'suspicious_attempts': suspiciousAttempts,
      };

      // ← Hint: حساب Checksum
      final checksum = _calculateChecksum(data);

      // ← Hint: حفظ كل قيمة على حدة
      await _secureStorage.write(key: _lastRealTimeKey, value: data['last_real_time'].toString());
      await _secureStorage.write(key: _lastDeviceTimeKey, value: data['last_device_time'].toString());
      await _secureStorage.write(key: _timeDriftKey, value: data['time_drift_seconds'].toString());
      await _secureStorage.write(key: _lastOnlineCheckKey, value: data['last_online_check'].toString());
      await _secureStorage.write(key: _daysOfflineKey, value: data['days_offline'].toString());
      await _secureStorage.write(key: _suspiciousAttemptsKey, value: data['suspicious_attempts'].toString());
      await _secureStorage.write(key: _checksumKey, value: checksum);

      debugPrint('✅ تم حفظ بيانات الوقت بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ بيانات الوقت: $e');
    }
  }

  // ==========================================================================
  // ← Hint: قراءة بيانات الوقت مع التحقق من Checksum
  // ==========================================================================
  Future<Map<String, dynamic>?> loadTimeData() async {
    try {
      // ← Hint: قراءة البيانات
      final lastRealTime = await _secureStorage.read(key: _lastRealTimeKey);
      final lastDeviceTime = await _secureStorage.read(key: _lastDeviceTimeKey);
      final timeDriftSeconds = await _secureStorage.read(key: _timeDriftKey);
      final lastOnlineCheck = await _secureStorage.read(key: _lastOnlineCheckKey);
      final daysOffline = await _secureStorage.read(key: _daysOfflineKey);
      final suspiciousAttempts = await _secureStorage.read(key: _suspiciousAttemptsKey);
      final savedChecksum = await _secureStorage.read(key: _checksumKey);

      // ← Hint: التحقق من وجود البيانات
      if (lastRealTime == null || lastDeviceTime == null) {
        debugPrint('ℹ️ لا توجد بيانات وقت محفوظة');
        return null;
      }

      // ← Hint: بناء Map البيانات
      final data = {
        'last_real_time': lastRealTime,
        'last_device_time': lastDeviceTime,
        'time_drift_seconds': int.tryParse(timeDriftSeconds ?? '0') ?? 0,
        'last_online_check': lastOnlineCheck ?? DateTime.now().toIso8601String(),
        'days_offline': int.tryParse(daysOffline ?? '0') ?? 0,
        'suspicious_attempts': int.tryParse(suspiciousAttempts ?? '0') ?? 0,
      };

      // ← Hint: التحقق من Checksum
      final calculatedChecksum = _calculateChecksum(data);
      if (calculatedChecksum != savedChecksum) {
        debugPrint('⚠️ Checksum غير متطابق - محاولة تلاعب محتملة!');
        
        // ← Hint: زيادة عداد المحاولات المشبوهة
        await incrementSuspiciousAttempts();
        
        return null;
      }

      debugPrint('✅ تم تحميل بيانات الوقت بنجاح');
      return data;
    } catch (e) {
      debugPrint('❌ خطأ في تحميل بيانات الوقت: $e');
      return null;
    }
  }

  // ==========================================================================
  // ← Hint: حساب Checksum
  // ==========================================================================
  String _calculateChecksum(Map<String, dynamic> data) {
    // ← Hint: ترتيب المفاتيح للحصول على نتيجة ثابتة
    final sortedData = Map.fromEntries(
      data.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    // ← Hint: تحويل لـ JSON + إضافة المفتاح السري
    final jsonString = jsonEncode(sortedData);
    final stringToHash = '$jsonString-$_secretKey';

    // ← Hint: حساب SHA256
    final bytes = utf8.encode(stringToHash);
    final digest = sha256.convert(bytes);

    return digest.toString();
  }

  // ==========================================================================
  // ← Hint: زيادة عداد المحاولات المشبوهة
  // ==========================================================================
  Future<void> incrementSuspiciousAttempts() async {
    try {
      final current = await _secureStorage.read(key: _suspiciousAttemptsKey);
      final attempts = int.tryParse(current ?? '0') ?? 0;
      await _secureStorage.write(
        key: _suspiciousAttemptsKey,
        value: (attempts + 1).toString(),
      );
      
      debugPrint('⚠️ عداد المحاولات المشبوهة: ${attempts + 1}');
    } catch (e) {
      debugPrint('❌ خطأ في زيادة عداد المحاولات: $e');
    }
  }

  // ==========================================================================
  // ← Hint: الحصول على عداد المحاولات المشبوهة
  // ==========================================================================
  Future<int> getSuspiciousAttempts() async {
    try {
      final value = await _secureStorage.read(key: _suspiciousAttemptsKey);
      return int.tryParse(value ?? '0') ?? 0;
    } catch (e) {
      debugPrint('❌ خطأ في قراءة عداد المحاولات: $e');
      return 0;
    }
  }

  // ==========================================================================
  // ← Hint: إعادة تعيين عداد المحاولات المشبوهة
  // ==========================================================================
  Future<void> resetSuspiciousAttempts() async {
    try {
      await _secureStorage.write(key: _suspiciousAttemptsKey, value: '0');
      debugPrint('✅ تم إعادة تعيين عداد المحاولات');
    } catch (e) {
      debugPrint('❌ خطأ في إعادة تعيين عداد المحاولات: $e');
    }
  }

  // ==========================================================================
  // ← Hint: حذف جميع البيانات (عند التفعيل الجديد)
  // ==========================================================================
  Future<void> clearAll() async {
    try {
      await _secureStorage.delete(key: _lastRealTimeKey);
      await _secureStorage.delete(key: _lastDeviceTimeKey);
      await _secureStorage.delete(key: _timeDriftKey);
      await _secureStorage.delete(key: _lastOnlineCheckKey);
      await _secureStorage.delete(key: _daysOfflineKey);
      await _secureStorage.delete(key: _suspiciousAttemptsKey);
      await _secureStorage.delete(key: _checksumKey);
      
      debugPrint('✅ تم حذف جميع بيانات الوقت');
    } catch (e) {
      debugPrint('❌ خطأ في حذف البيانات: $e');
    }
  }

  // ==========================================================================
  // ← Hint: تحديث عدد الأيام بدون إنترنت
  // ==========================================================================
  Future<void> updateDaysOffline(int days) async {
    try {
      await _secureStorage.write(key: _daysOfflineKey, value: days.toString());
      debugPrint('ℹ️ عدد الأيام بدون إنترنت: $days');
    } catch (e) {
      debugPrint('❌ خطأ في تحديث الأيام: $e');
    }
  }
}