// lib/services/native_secrets_service.dart

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// 🔐 خدمة الوصول للمفاتيح السرية من Native Layer
/// 
/// ← Hint: هذه الطبقة تُخفي تفاصيل الاتصال بـ Kotlin
class NativeSecretsService {
  // ========================================================================
  // Singleton Pattern
  // ========================================================================
  
  static final NativeSecretsService _instance = NativeSecretsService._internal();
  NativeSecretsService._internal();
  factory NativeSecretsService() => _instance;
  static NativeSecretsService get instance => _instance;

  // ========================================================================
  // Platform Channel
  // ========================================================================
  
  static const MethodChannel _channel = MethodChannel('com.accountant.touch/secrets');

  // ========================================================================
  // Cache المفاتيح (في الذاكرة فقط - لتقليل Native calls)
  // ========================================================================
  
  String? _cachedActivationSecret;
  String? _cachedBackupMagic;
  String? _cachedTimeSecret;
  bool? _cachedValidation;

  // ========================================================================
  // Public Methods
  // ========================================================================

  /// الحصول على مفتاح التفعيل
  Future<String> getActivationSecret() async {
    if (_cachedActivationSecret != null) {
      return _cachedActivationSecret!;
    }

    try {
      final String secret = await _channel.invokeMethod('getActivationSecret');
      
      // ← Hint: التحقق من صحة المفتاح
      if (secret.isEmpty || secret.length < 32 || secret.contains('FAILED')) {
        throw Exception('Invalid activation secret from native layer');
      }

      _cachedActivationSecret = secret;
      debugPrint('✅ تم تحميل activation secret من Native layer (${secret.length} chars)');
      
      return secret;
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على activation secret: $e');
      rethrow;
    }
  }

  /// الحصول على Backup Magic Number
  Future<String> getBackupMagic() async {
    if (_cachedBackupMagic != null) {
      return _cachedBackupMagic!;
    }

    try {
      final String magic = await _channel.invokeMethod('getBackupMagic');
      
      if (magic.isEmpty || magic.length < 16 || magic.contains('FAILED')) {
        throw Exception('Invalid backup magic from native layer');
      }

      _cachedBackupMagic = magic;
      debugPrint('✅ تم تحميل backup magic من Native layer (${magic.length} chars)');
      
      return magic;
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على backup magic: $e');
      rethrow;
    }
  }

  /// الحصول على Time Validation Secret
  Future<String> getTimeSecret() async {
    if (_cachedTimeSecret != null) {
      return _cachedTimeSecret!;
    }

    try {
      final String secret = await _channel.invokeMethod('getTimeSecret');
      
      if (secret.isEmpty || secret.length < 32 || secret.contains('FAILED')) {
        throw Exception('Invalid time secret from native layer');
      }

      _cachedTimeSecret = secret;
      debugPrint('✅ تم تحميل time secret من Native layer (${secret.length} chars)');
      
      return secret;
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على time secret: $e');
      rethrow;
    }
  }

  /// التحقق من سلامة جميع المفاتيح
  Future<bool> validateKeys() async {
    if (_cachedValidation != null) {
      return _cachedValidation!;
    }

    try {
      final bool isValid = await _channel.invokeMethod('validateKeys');
      
      _cachedValidation = isValid;
      
      if (isValid) {
        debugPrint('✅ جميع المفاتيح السرية صالحة');
      } else {
        debugPrint('❌ تحذير: بعض المفاتيح السرية غير صالحة!');
      }
      
      return isValid;
    } catch (e) {
      debugPrint('❌ خطأ في التحقق من المفاتيح: $e');
      return false;
    }
  }

  /// إعادة تعيين Cache (عند الحاجة لإعادة التحميل)
  void clearCache() {
    _cachedActivationSecret = null;
    _cachedBackupMagic = null;
    _cachedTimeSecret = null;
    _cachedValidation = null;
    
    debugPrint('🔄 تم مسح cache المفاتيح السرية');
  }

  // ========================================================================
  // 🆕 Getters للوصول السريع للقيم المُحملة (synchronous)
  // ← Hint: هذه الدوال تُستخدم بعد تحميل المفاتيح في main.dart
  // ========================================================================

  /// الحصول على القيمة المُخزنة في Cache (بدون استدعاء Native)
  String? get cachedActivationSecret => _cachedActivationSecret;

  /// الحصول على القيمة المُخزنة في Cache (بدون استدعاء Native)
  String? get cachedBackupMagic => _cachedBackupMagic;

  /// الحصول على القيمة المُخزنة في Cache (بدون استدعاء Native)
  String? get cachedTimeSecret => _cachedTimeSecret;

  /// التحقق من أن جميع المفاتيح محملة
  bool get areKeysLoaded => 
    _cachedActivationSecret != null && 
    _cachedBackupMagic != null && 
    _cachedTimeSecret != null;
}