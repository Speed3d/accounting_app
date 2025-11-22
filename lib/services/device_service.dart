// lib/services/device_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

/// 🔐 خدمة متخصصة لجلب معلومات الجهاز - محسّنة (Week 1)
/// 
/// ← Hint: التحديثات الرئيسية:
/// - ✅ Multi-layer Fingerprinting (4 طبقات)
/// - ✅ Root Detection (كشف الـ Root)
/// - ✅ Device Info Helper (معلومات تفصيلية)
class DeviceService {
  // ========================================================================
  // Singleton Pattern
  // ========================================================================
  
  DeviceService._privateConstructor();
  static final DeviceService instance = DeviceService._privateConstructor();

  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  // ========================================================================
  // الحصول على Device Fingerprint متعدد الطبقات
  // ========================================================================
  
  /// دالة غير متزامنة لجلب "بصمة الجهاز" الفريدة والقوية
  /// 
  /// ← Hint: تستخدم 4 طبقات من البيانات:
  ///   1. Android ID (الأساسي - 64-bit unique)
  ///   2. Hardware Info (Brand + Model + Hardware)
  ///   3. Build Fingerprint (صعب التزوير)
  ///   4. Security Patch Level (مؤشر على الأمان)
  /// 
  /// Returns: بصمة فريدة بصيغة: AND-[32 chars HEX]
  Future<String> getDeviceFingerprint() async {
    try {
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
        
        // ═════════════════════════════════════════════════════════
        // Layer 1: Android ID (الأساسي - 64-bit)
        // ← Hint: يتم إنشاؤه عند أول تشغيل للجهاز
        // ← Hint: يبقى ثابتاً حتى Factory Reset
        // ═════════════════════════════════════════════════════════
        final String androidId = androidInfo.id ?? 'UNKNOWN_ID';
        
        // ═════════════════════════════════════════════════════════
        // Layer 2: Hardware Information
        // ← Hint: Brand + Model + Hardware = بصمة فريدة للجهاز
        // مثال: samsung/SM-G973F/exynos9820
        // ═════════════════════════════════════════════════════════
        final String brand = androidInfo.brand ?? 'UNKNOWN_BRAND';
        final String model = androidInfo.model ?? 'UNKNOWN_MODEL';
        final String hardware = androidInfo.hardware ?? 'UNKNOWN_HW';
        
        // ═════════════════════════════════════════════════════════
        // Layer 3: Build Fingerprint (الأصعب للتزوير)
        // ← Hint: يحتوي على: brand/product/device:version/id/build
        // مثال: google/redfin/redfin:13/TP1A.220624.021/8877034:user/release-keys
        // ═════════════════════════════════════════════════════════
        final String buildFingerprint = androidInfo.fingerprint ?? 'UNKNOWN_BUILD';
        
        // ═════════════════════════════════════════════════════════
        // Layer 4: Security Patch Level (مؤشر على الأمان)
        // ← Hint: تاريخ آخر تحديث أمني
        // مثال: 2024-01-01
        // ═════════════════════════════════════════════════════════
        final String securityPatch = androidInfo.version.securityPatch ?? 'UNKNOWN_PATCH';
        
        // ═════════════════════════════════════════════════════════
        // دمج كل الطبقات مع فاصل |
        // ═════════════════════════════════════════════════════════
        final combined = '$androidId|$brand|$model|$hardware|$buildFingerprint|$securityPatch';
        
        debugPrint('📱 Device Fingerprint Layers:');
        debugPrint('   └─ Android ID: ${androidId.substring(0, 8)}...');
        debugPrint('   └─ Hardware: $brand $model ($hardware)');
        debugPrint('   └─ Build: ${buildFingerprint.substring(0, min(30, buildFingerprint.length))}...');
        debugPrint('   └─ Security Patch: $securityPatch');
        
        // ═════════════════════════════════════════════════════════
        // Hash النهائي (SHA-256)
        // ← Hint: 64 حرف hex = 256 bit
        // ═════════════════════════════════════════════════════════
        final bytes = utf8.encode(combined);
        final digest = sha256.convert(bytes);
        final hash = digest.toString();
        
        // ← Hint: نأخذ أول 32 حرف للقراءة + بادئة AND-
        final fingerprint = 'AND-${hash.substring(0, 32).toUpperCase()}';
        
        debugPrint('✅ Device Fingerprint: $fingerprint');
        return fingerprint;
      } 
      // ← Hint: يمكن إضافة دعم iOS هنا
      else {
        return 'UNSUPPORTED_PLATFORM';
      }
    } catch (e) {
      debugPrint('❌ Error getting device fingerprint: $e');
      return 'ERROR_GETTING_ID';
    }
  }

  // ========================================================================
  // Root Detection (كشف الـ Root)
  // ========================================================================
  
  /// التحقق من وجود Root في الجهاز
  /// 
  /// ← Hint: يفحص:
  ///   1. ملفات Root الشائعة (12 موقع)
  ///   2. تطبيقات Root Management (7 تطبيقات)
  ///   3. خصائص النظام (test-keys, userdebug)
  /// 
  /// Returns: true إذا كان الجهاز مُخترق (Rooted)
  Future<bool> isDeviceRooted() async {
    try {
      if (!Platform.isAndroid) return false;

      debugPrint('🔍 فحص Root...');

      // ═════════════════════════════════════════════════════════
      // 1. فحص ملفات Root الشائعة
      // ═════════════════════════════════════════════════════════
      final rootFiles = [
        '/system/app/Superuser.apk',          // SuperSU
        '/system/xbin/su',                    // su binary
        '/system/bin/su',                     // su binary (alternative)
        '/system/xbin/daemonsu',              // SuperSU daemon
        '/sbin/su',                           // su in sbin
        '/system/xbin/busybox',               // BusyBox
        '/data/local/xbin/su',                // Custom location
        '/data/local/bin/su',                 // Custom location
        '/system/sd/xbin/su',                 // SD card
        '/system/bin/failsafe/su',            // Failsafe
        '/data/local/su',                     // Local su
        '/su/bin/su',                         // Magisk
      ];

      int foundFiles = 0;
      for (final path in rootFiles) {
        try {
          if (await File(path).exists()) {
            debugPrint('   ⚠️ وُجد ملف root: $path');
            foundFiles++;
          }
        } catch (e) {
          // ← Hint: قد يفشل بسبب الأذونات (Permission denied - طبيعي)
        }
      }

      if (foundFiles > 0) {
        debugPrint('🚨 Root مكتشف: وُجدت $foundFiles ملفات root');
        return true;
      }

      // ═════════════════════════════════════════════════════════
      // 2. فحص تطبيقات Root Management
      // ← Hint: فحص وجود APK files في /data/app
      // ═════════════════════════════════════════════════════════
      final rootApps = [
        'com.noshufou.android.su',           // Superuser
        'com.noshufou.android.su.elite',     // Superuser Elite
        'eu.chainfire.supersu',              // SuperSU
        'com.koushikdutta.superuser',        // Koush Superuser
        'com.thirdparty.superuser',          // Third-party Superuser
        'com.yellowes.su',                   // Yellow Superuser
        'com.topjohnwu.magisk',              // Magisk
      ];

      for (final packageName in rootApps) {
        final apkPath = '/data/app/$packageName';
        try {
          if (await Directory(apkPath).exists()) {
            debugPrint('   ⚠️ وُجد تطبيق root: $packageName');
            return true;
          }
        } catch (e) {
          // Permission denied - normal
        }
      }

      // ═════════════════════════════════════════════════════════
      // 3. فحص خصائص النظام
      // ← Hint: الأجهزة المعدلة غالباً تحمل كلمات مفتاحية
      // ═════════════════════════════════════════════════════════
      final androidInfo = await _deviceInfoPlugin.androidInfo;
      
      final tags = androidInfo.tags ?? '';
      final fingerprint = androidInfo.fingerprint ?? '';
      
      if (tags.contains('test-keys') || 
          fingerprint.contains('test-keys') ||
          fingerprint.contains('userdebug')) {
        debugPrint('🚨 Root مكتشف: build tags مشبوهة ($tags)');
        return true;
      }

      debugPrint('✅ الجهاز غير مُخترق (Root غير موجود)');
      return false;

    } catch (e) {
      debugPrint('❌ خطأ في فحص Root: $e');
      // ← Hint: في حالة الخطأ، نفترض أنه آمن (fail-safe)
      return false;
    }
  }

  // ========================================================================
  // معلومات الجهاز التفصيلية (للتصحيح والدعم الفني)
  // ========================================================================
  
  /// الحصول على معلومات مفصلة عن الجهاز
  /// 
  /// ← Hint: مفيد للدعم الفني والتصحيح
  /// 
  /// Returns: Map يحتوي على كل معلومات الجهاز
  Future<Map<String, String>> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;

        return {
          'platform': 'Android',
          'version': androidInfo.version.release ?? 'Unknown',
          'sdk': androidInfo.version.sdkInt.toString(),
          'brand': androidInfo.brand ?? 'Unknown',
          'manufacturer': androidInfo.manufacturer ?? 'Unknown',
          'model': androidInfo.model ?? 'Unknown',
          'device': androidInfo.device ?? 'Unknown',
          'hardware': androidInfo.hardware ?? 'Unknown',
          'display': androidInfo.display ?? 'Unknown',
          'fingerprint': androidInfo.fingerprint ?? 'Unknown',
          'security_patch': androidInfo.version.securityPatch ?? 'Unknown',
          'is_physical_device': androidInfo.isPhysicalDevice.toString(),
          'supported_abis': androidInfo.supportedAbis.join(', '),
          'android_id': androidInfo.id ?? 'Unknown',
        };
      } else {
        return {'platform': 'Unsupported'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ========================================================================
  // دالة مساعدة: min (للتوافقية)
  // ========================================================================
  
  int min(int a, int b) => a < b ? a : b;
}