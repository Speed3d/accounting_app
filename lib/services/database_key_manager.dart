// lib/services/database_key_manager.dart

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'device_service.dart';

/// 🔑 مدير مفاتيح قاعدة البيانات المشفرة
class DatabaseKeyManager {
  static final DatabaseKeyManager _instance = DatabaseKeyManager._internal();
  DatabaseKeyManager._internal();
  factory DatabaseKeyManager() => _instance;
  static DatabaseKeyManager get instance => _instance;

  final _secureStorage = const FlutterSecureStorage();
  static const String _keyStorageKey = 'db_encryption_key_v1';
  
  String? _cachedKey;

  /// الحصول على مفتاح التشفير (أو توليده)
  Future<String> getDatabaseKey() async {
    try {
      // 1. Cache
      if (_cachedKey != null) return _cachedKey!;

      // 2. محاولة قراءة المفتاح المحفوظ
      final storedKey = await _secureStorage.read(key: _keyStorageKey);
      
      if (storedKey != null && storedKey.isNotEmpty) {
        debugPrint('✅ مفتاح التشفير: محمّل من Secure Storage');
        _cachedKey = storedKey;
        return storedKey;
      }

      // 3. توليد مفتاح جديد
      debugPrint('🔑 توليد مفتاح تشفير جديد...');
      final newKey = await _generateNewKey();
      
      await _secureStorage.write(key: _keyStorageKey, value: newKey);
      _cachedKey = newKey;
      
      debugPrint('✅ تم توليد وحفظ مفتاح التشفير');
      return newKey;

    } catch (e) {
      debugPrint('❌ خطأ في DatabaseKeyManager: $e');
      rethrow;
    }
  }

  /// توليد مفتاح قوي
  Future<String> _generateNewKey() async {
    // ← Hint: نستخدم Device ID + Random Salt + PBKDF2
    final deviceId = await DeviceService.instance.getDeviceFingerprint();
    final salt = _generateRandomBytes(32);
    
    return _deriveKey(deviceId, salt);
  }

  /// توليد bytes عشوائية
  String _generateRandomBytes(int length) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  /// اشتقاق مفتاح من Device ID
  String _deriveKey(String deviceId, String salt) {
    const iterations = 10000; // ← أقل من BackupService (للسرعة)
    
    final saltBytes = utf8.encode(salt);
    final passwordBytes = utf8.encode(deviceId);
    
    var result = Hmac(sha256, passwordBytes).convert(saltBytes).bytes;
    var previousBlock = result;

    for (var i = 1; i < iterations; i++) {
      previousBlock = Hmac(sha256, passwordBytes).convert(previousBlock).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= previousBlock[j];
      }
    }

    // ← Hint: 64 حرف hex
    return result.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}