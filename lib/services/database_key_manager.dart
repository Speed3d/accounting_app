// lib/services/database_key_manager.dart

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🔑 مدير مفاتيح قاعدة البيانات المشفرة - النسخة المحسّنة
///
/// ← Hint: التحديثات الرئيسية (v2.0):
/// 1. ✅ مفتاح مستقل تماماً (غير مرتبط بـ Device Fingerprint)
/// 2. ✅ نظام نسخ احتياطي متعدد الطبقات
/// 3. ✅ آلية استرداد ذكية
/// 4. ✅ دعم تدوير المفاتيح (Key Rotation)
/// 5. ✅ logging محسّن للتشخيص
class DatabaseKeyManager {
  // ============================================================================
  // Singleton Pattern
  // ============================================================================

  static final DatabaseKeyManager _instance = DatabaseKeyManager._internal();
  DatabaseKeyManager._internal();
  factory DatabaseKeyManager() => _instance;
  static DatabaseKeyManager get instance => _instance;

  // ============================================================================
  // ← Hint: FlutterSecureStorage مع خيارات أمان محسّنة
  // ← Hint: resetOnError: false - لا نحذف البيانات عند حدوث خطأ
  // ← Hint: encryptedSharedPreferences: true - استخدام التشفير على Android
  // ============================================================================

  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: false, // ← Hint: مهم جداً! لا نفقد البيانات عند الخطأ
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // ← Hint: FlutterSecureStorage بدون encryption للمحاكيات (Fallback)
  // ← Hint: في بعض المحاكيات، encryptedSharedPreferences قد يسبب مشاكل
  final _secureStorageNoEncryption = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: false, // ← بدون encryption للتوافق
      resetOnError: false,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // ← Hint: مفاتيح التخزين
  static const String _primaryKeyStorageKey = 'db_encryption_key_v2';
  static const String _backupKeyStorageKey = 'db_encryption_key_v2_backup';
  static const String _noEncKeyStorageKey = 'db_encryption_key_v2_no_enc'; // ← جديد
  static const String _keyVersionKey = 'db_key_version';
  static const String _keyCreatedAtKey = 'db_key_created_at';

  // ← Hint: Cache في الذاكرة لتحسين الأداء
  String? _cachedKey;

  // ← Hint: قائمة بالمفاتيح القديمة للتوافقية
  static const String _legacyKeyStorageKey = 'db_encryption_key_v1';

  // ============================================================================
  // ← Hint: الدالة الرئيسية - الحصول على مفتاح التشفير
  // ← Hint: تحاول بالترتيب: Cache → Primary → Backup → Legacy → Generate New
  // ============================================================================

  /// الحصول على مفتاح التشفير (أو توليده)
  ///
  /// ← Hint: هذه الدالة هي نقطة الدخول الوحيدة للحصول على المفتاح
  /// ← Hint: تستخدم آلية fallback متعددة الطبقات لضمان عدم فقدان البيانات
  Future<String> getDatabaseKey() async {
    try {
      // ═══════════════════════════════════════════════════════════
      // المستوى 1: Cache (الأسرع)
      // ← Hint: إذا كان المفتاح موجود في الذاكرة، نرجعه مباشرة
      // ═══════════════════════════════════════════════════════════

      if (_cachedKey != null) {
        debugPrint('✅ [KeyManager] مفتاح التشفير: محمّل من Cache');
        return _cachedKey!;
      }

      // ═══════════════════════════════════════════════════════════
      // المستوى 2: Primary Storage (FlutterSecureStorage)
      // ← Hint: المصدر الأساسي للمفتاح
      // ═══════════════════════════════════════════════════════════

      final primaryKey = await _loadKeyWithFallback();

      if (primaryKey != null) {
        _cachedKey = primaryKey;
        return primaryKey;
      }

      // ═══════════════════════════════════════════════════════════
      // المستوى 3: توليد مفتاح جديد
      // ← Hint: إذا لم نجد أي مفتاح، نولد واحد جديد ونحفظه بأمان
      // ═══════════════════════════════════════════════════════════

      debugPrint('🔑 [KeyManager] توليد مفتاح تشفير جديد...');
      final newKey = await _generateNewKey();

      // ← Hint: حفظ المفتاح في مواقع متعددة للأمان
      await _saveKeyWithBackup(newKey);

      _cachedKey = newKey;

      debugPrint('✅ [KeyManager] تم توليد وحفظ مفتاح التشفير بنجاح');
      return newKey;

    } catch (e, stackTrace) {
      debugPrint('❌ [KeyManager] خطأ حرج في getDatabaseKey: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ============================================================================
  // ← Hint: تحميل المفتاح مع Fallback متعدد الطبقات
  // ← Hint: يحاول: Primary → Backup → Legacy → SharedPreferences
  // ============================================================================

  Future<String?> _loadKeyWithFallback() async {
    try {
      debugPrint('🔍 [KeyManager] بدء البحث عن مفتاح محفوظ...');

      // ═══════════════════════════════════════════════════════════
      // الطبقة 1: Primary Storage (مع encryption)
      // ═══════════════════════════════════════════════════════════

      try {
        final primaryKey = await _secureStorage.read(key: _primaryKeyStorageKey);
        debugPrint('🔍 [KeyManager] Primary Storage: ${primaryKey != null ? "موجود (${primaryKey.length} chars)" : "فارغ"}');

        if (primaryKey != null && primaryKey.isNotEmpty) {
          // ← Hint: التحقق من صحة المفتاح
          if (_isValidKey(primaryKey)) {
            debugPrint('✅ [KeyManager] مفتاح التشفير: محمّل من Primary Storage');
            return primaryKey;
          } else {
            debugPrint('⚠️ [KeyManager] المفتاح الأساسي غير صالح، محاولة Backup...');
          }
        }
      } catch (e) {
        debugPrint('⚠️ [KeyManager] خطأ في قراءة Primary Storage: $e');
      }

      // ═══════════════════════════════════════════════════════════
      // الطبقة 2: Backup Storage (مع encryption)
      // ═══════════════════════════════════════════════════════════

      try {
        final backupKey = await _secureStorage.read(key: _backupKeyStorageKey);
        debugPrint('🔍 [KeyManager] Backup Storage: ${backupKey != null ? "موجود (${backupKey.length} chars)" : "فارغ"}');

        if (backupKey != null && backupKey.isNotEmpty && _isValidKey(backupKey)) {
          debugPrint('✅ [KeyManager] مفتاح التشفير: محمّل من Backup Storage');

          // ← Hint: استعادة المفتاح الأساسي من Backup
          await _secureStorage.write(key: _primaryKeyStorageKey, value: backupKey);

          return backupKey;
        }
      } catch (e) {
        debugPrint('⚠️ [KeyManager] خطأ في قراءة Backup Storage: $e');
      }

      // ═══════════════════════════════════════════════════════════
      // الطبقة 3: No-Encryption Storage (للمحاكيات) 🆕
      // ← Hint: بعض المحاكيات تفقد بيانات EncryptedSharedPreferences
      // ═══════════════════════════════════════════════════════════

      try {
        final noEncKey = await _secureStorageNoEncryption.read(key: _noEncKeyStorageKey);
        debugPrint('🔍 [KeyManager] No-Encryption Storage: ${noEncKey != null ? "موجود (${noEncKey.length} chars)" : "فارغ"}');

        if (noEncKey != null && noEncKey.isNotEmpty && _isValidKey(noEncKey)) {
          debugPrint('✅ [KeyManager] مفتاح التشفير: محمّل من No-Encryption Storage (Emulator Fix)');

          // ← Hint: استعادة المفتاح إلى المخازن الأخرى
          await _saveKeyWithBackup(noEncKey);

          return noEncKey;
        }
      } catch (e) {
        debugPrint('⚠️ [KeyManager] خطأ في قراءة No-Encryption Storage: $e');
      }

      // ═══════════════════════════════════════════════════════════
      // الطبقة 4: Legacy Storage (التوافقية مع النسخة القديمة)
      // ═══════════════════════════════════════════════════════════

      try {
        final legacyKey = await _secureStorage.read(key: _legacyKeyStorageKey);
        debugPrint('🔍 [KeyManager] Legacy Storage: ${legacyKey != null ? "موجود (${legacyKey.length} chars)" : "فارغ"}');

        if (legacyKey != null && legacyKey.isNotEmpty && _isValidKey(legacyKey)) {
          debugPrint('✅ [KeyManager] مفتاح التشفير: محمّل من Legacy Storage (v1)');
          debugPrint('🔄 [KeyManager] ترحيل المفتاح إلى النظام الجديد...');

          // ← Hint: ترحيل المفتاح القديم إلى النظام الجديد
          await _migrateFromLegacyKey(legacyKey);

          return legacyKey;
        }
      } catch (e) {
        debugPrint('⚠️ [KeyManager] خطأ في قراءة Legacy Storage: $e');
      }

      // ═══════════════════════════════════════════════════════════
      // الطبقة 5: SharedPreferences (احتياطي إضافي)
      // ← Hint: نسخة مشفرة في SharedPreferences
      // ═══════════════════════════════════════════════════════════

      try {
        final spKey = await _loadFromSharedPreferences();
        debugPrint('🔍 [KeyManager] SharedPreferences: ${spKey != null ? "موجود (${spKey.length} chars)" : "فارغ"}');

        if (spKey != null && spKey.isNotEmpty && _isValidKey(spKey)) {
          debugPrint('✅ [KeyManager] مفتاح التشفير: محمّل من SharedPreferences');

          // ← Hint: استعادة المفتاح إلى SecureStorage
          await _saveKeyWithBackup(spKey);

          return spKey;
        }
      } catch (e) {
        debugPrint('⚠️ [KeyManager] خطأ في قراءة SharedPreferences: $e');
      }

      // ═══════════════════════════════════════════════════════════
      // لم نجد أي مفتاح
      // ═══════════════════════════════════════════════════════════

      debugPrint('⚠️ [KeyManager] لم يتم العثور على مفتاح محفوظ في أي من المخازن الـ 5');
      return null;

    } catch (e) {
      debugPrint('❌ [KeyManager] خطأ حرج في _loadKeyWithFallback: $e');
      return null;
    }
  }

  // ============================================================================
  // ← Hint: حفظ المفتاح مع نسخ احتياطية متعددة
  // ← Hint: يحفظ في: Primary + Backup + SharedPreferences
  // ============================================================================

  Future<void> _saveKeyWithBackup(String key) async {
    try {
      // ← Hint: الطابع الزمني للمفتاح
      final timestamp = DateTime.now().toIso8601String();

      debugPrint('💾 [KeyManager] بدء حفظ المفتاح في مخازن متعددة...');

      // ═══════════════════════════════════════════════════════════
      // حفظ في Primary Storage (مع encryption)
      // ═══════════════════════════════════════════════════════════

      try {
        await _secureStorage.write(
          key: _primaryKeyStorageKey,
          value: key,
        );
        debugPrint('✅ [KeyManager] تم حفظ المفتاح في Primary Storage');
      } catch (e) {
        debugPrint('❌ [KeyManager] فشل حفظ Primary Storage: $e');
      }

      // ═══════════════════════════════════════════════════════════
      // حفظ في Backup Storage (مع encryption)
      // ═══════════════════════════════════════════════════════════

      try {
        await _secureStorage.write(
          key: _backupKeyStorageKey,
          value: key,
        );
        debugPrint('✅ [KeyManager] تم حفظ المفتاح في Backup Storage');
      } catch (e) {
        debugPrint('❌ [KeyManager] فشل حفظ Backup Storage: $e');
      }

      // ═══════════════════════════════════════════════════════════
      // حفظ في No-Encryption Storage (للمحاكيات) 🆕
      // ← Hint: إصلاح مشكلة المحاكيات مع EncryptedSharedPreferences
      // ═══════════════════════════════════════════════════════════

      try {
        await _secureStorageNoEncryption.write(
          key: _noEncKeyStorageKey,
          value: key,
        );
        debugPrint('✅ [KeyManager] تم حفظ المفتاح في No-Encryption Storage (Emulator Fix)');
      } catch (e) {
        debugPrint('❌ [KeyManager] فشل حفظ No-Encryption Storage: $e');
      }

      // ═══════════════════════════════════════════════════════════
      // حفظ Metadata
      // ═══════════════════════════════════════════════════════════

      try {
        await _secureStorage.write(
          key: _keyVersionKey,
          value: '2.0',
        );

        await _secureStorage.write(
          key: _keyCreatedAtKey,
          value: timestamp,
        );
        debugPrint('✅ [KeyManager] تم حفظ Metadata');
      } catch (e) {
        debugPrint('⚠️ [KeyManager] فشل حفظ Metadata: $e');
      }

      // ═══════════════════════════════════════════════════════════
      // حفظ في SharedPreferences (احتياطي إضافي)
      // ← Hint: نسخة مشفرة بسيطة
      // ═══════════════════════════════════════════════════════════

      try {
        await _saveToSharedPreferences(key);
        debugPrint('✅ [KeyManager] تم حفظ المفتاح في SharedPreferences');
      } catch (e) {
        debugPrint('❌ [KeyManager] فشل حفظ SharedPreferences: $e');
      }

      debugPrint('✅ [KeyManager] اكتمل حفظ المفتاح في جميع المخازن المتاحة');

    } catch (e) {
      debugPrint('❌ [KeyManager] خطأ حرج في _saveKeyWithBackup: $e');
      // ← Hint: لا نرمي Exception هنا لأننا حاولنا الحفظ في مخازن متعددة
    }
  }

  // ============================================================================
  // ← Hint: توليد مفتاح قوي جديد (مستقل تماماً)
  // ← Hint: لا يعتمد على Device Fingerprint (هذه هي النقطة الأهم!)
  // ============================================================================

  Future<String> _generateNewKey() async {
    // ← Hint: نستخدم Random.secure() لتوليد bytes عشوائية حقيقية
    // ← Hint: 64 bytes = 512 bits من العشوائية القوية
    final random = Random.secure();
    final bytes = List<int>.generate(64, (_) => random.nextInt(256));

    // ← Hint: تحويل إلى hex string (128 حرف)
    final key = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    debugPrint('🔑 [KeyManager] تم توليد مفتاح عشوائي قوي (512-bit)');

    return key;
  }

  // ============================================================================
  // ← Hint: ترحيل من المفتاح القديم (v1) إلى الجديد (v2)
  // ============================================================================

  Future<void> _migrateFromLegacyKey(String legacyKey) async {
    try {
      debugPrint('🔄 [KeyManager] بدء ترحيل المفتاح من v1 إلى v2...');

      // ← Hint: حفظ المفتاح القديم في النظام الجديد
      await _saveKeyWithBackup(legacyKey);

      debugPrint('✅ [KeyManager] اكتمل الترحيل بنجاح');

    } catch (e) {
      debugPrint('⚠️ [KeyManager] خطأ في الترحيل: $e');
    }
  }

  // ============================================================================
  // ← Hint: حفظ/تحميل من SharedPreferences (احتياطي)
  // ← Hint: نستخدم تشفير بسيط (XOR + Base64)
  // ============================================================================

  Future<void> _saveToSharedPreferences(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ← Hint: تشفير بسيط للمفتاح (XOR مع salt ثابت)
      final obfuscatedKey = _obfuscateKey(key);

      await prefs.setString('db_key_backup_v2', obfuscatedKey);

    } catch (e) {
      debugPrint('⚠️ [KeyManager] خطأ في _saveToSharedPreferences: $e');
    }
  }

  Future<String?> _loadFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final obfuscatedKey = prefs.getString('db_key_backup_v2');

      if (obfuscatedKey != null) {
        return _deobfuscateKey(obfuscatedKey);
      }

      return null;

    } catch (e) {
      debugPrint('⚠️ [KeyManager] خطأ في _loadFromSharedPreferences: $e');
      return null;
    }
  }

  // ============================================================================
  // ← Hint: تشفير/فك تشفير بسيط للمفتاح (XOR + Base64)
  // ← Hint: ليس تشفيراً قوياً، لكنه يمنع القراءة المباشرة
  // ============================================================================

  String _obfuscateKey(String key) {
    // ← Hint: salt ثابت للـ XOR
    const salt = 'AccountingAppSecretSalt2024';

    final keyBytes = utf8.encode(key);
    final saltBytes = utf8.encode(salt);

    // ← Hint: XOR كل byte مع salt
    final obfuscated = <int>[];
    for (int i = 0; i < keyBytes.length; i++) {
      obfuscated.add(keyBytes[i] ^ saltBytes[i % saltBytes.length]);
    }

    // ← Hint: تحويل إلى Base64
    return base64Encode(obfuscated);
  }

  String _deobfuscateKey(String obfuscatedKey) {
    // ← Hint: نفس العملية للفك (XOR عكسي)
    const salt = 'AccountingAppSecretSalt2024';

    final obfuscatedBytes = base64Decode(obfuscatedKey);
    final saltBytes = utf8.encode(salt);

    final deobfuscated = <int>[];
    for (int i = 0; i < obfuscatedBytes.length; i++) {
      deobfuscated.add(obfuscatedBytes[i] ^ saltBytes[i % saltBytes.length]);
    }

    return utf8.decode(deobfuscated);
  }

  // ============================================================================
  // ← Hint: التحقق من صحة المفتاح
  // ============================================================================

  bool _isValidKey(String key) {
    // ← Hint: المفتاح يجب أن يكون hex string بطول 128 حرف (64 bytes)
    if (key.length != 128) return false;

    // ← Hint: التحقق من أنه hex صحيح
    final hexRegex = RegExp(r'^[0-9a-fA-F]+$');
    return hexRegex.hasMatch(key);
  }

  // ============================================================================
  // ← Hint: الحصول على معلومات المفتاح (للتشخيص)
  // ============================================================================

  Future<Map<String, String?>> getKeyInfo() async {
    try {
      final version = await _secureStorage.read(key: _keyVersionKey);
      final createdAt = await _secureStorage.read(key: _keyCreatedAtKey);

      return {
        'version': version ?? 'unknown',
        'created_at': createdAt ?? 'unknown',
        'has_primary': (await _secureStorage.read(key: _primaryKeyStorageKey))?.isNotEmpty.toString() ?? 'false',
        'has_backup': (await _secureStorage.read(key: _backupKeyStorageKey))?.isNotEmpty.toString() ?? 'false',
        'has_legacy': (await _secureStorage.read(key: _legacyKeyStorageKey))?.isNotEmpty.toString() ?? 'false',
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ============================================================================
  // ← Hint: مسح المفتاح من Cache (للتطوير/التشخيص فقط)
  // ============================================================================

  void clearCache() {
    _cachedKey = null;
    debugPrint('🗑️ [KeyManager] تم مسح Cache');
  }

  // ============================================================================
  // ← Hint: 🔥 استبدال المفتاح بمفتاح مستعاد (للنسخ الاحتياطية!)
  // ← Hint: هذه الدالة الحل السحري لمشكلة dbEncryptionKey المختلف
  // ============================================================================

  /// استبدال المفتاح الحالي بمفتاح مستعاد من نسخة احتياطية
  ///
  /// ← Hint: تُستخدم عند استعادة نسخة احتياطية من جهاز آخر
  /// ← Hint: تستبدل المفتاح الجديد بالمفتاح القديم من النسخة
  /// ← Hint: هذا يضمن أن قاعدة البيانات المستعادة تفتح بنجاح!
  Future<void> replaceKey(String newKey) async {
    try {
      debugPrint('🔄 [KeyManager] استبدال المفتاح بمفتاح مستعاد...');

      // ← Hint: التحقق من صحة المفتاح الجديد
      if (!_isValidKey(newKey)) {
        throw Exception('المفتاح المستعاد غير صالح');
      }

      // ← Hint: حفظ المفتاح في جميع المخازن
      await _saveKeyWithBackup(newKey);

      // ← Hint: تحديث الـ Cache
      _cachedKey = newKey;

      debugPrint('✅ [KeyManager] تم استبدال المفتاح بنجاح');

    } catch (e) {
      debugPrint('❌ [KeyManager] خطأ في استبدال المفتاح: $e');
      rethrow;
    }
  }

  // ============================================================================
  // ← Hint: إعادة توليد المفتاح (للطوارئ فقط!)
  // ← Hint: تحذير: سيؤدي لفقدان الوصول لقاعدة البيانات الحالية!
  // ============================================================================

  Future<String> regenerateKey() async {
    debugPrint('⚠️ [KeyManager] تحذير: إعادة توليد المفتاح...');

    final newKey = await _generateNewKey();
    await _saveKeyWithBackup(newKey);

    _cachedKey = newKey;

    debugPrint('✅ [KeyManager] تم إعادة توليد المفتاح');

    return newKey;
  }
}
