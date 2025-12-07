// 🔐 lib/services/encryption_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';

/// 🔐 خدمة التشفير المتقدمة - AES-256-GCM
///
/// ← Hint: هذه الخدمة مسؤولة عن تشفير وفك تشفير بيانات النسخ الاحتياطي
/// ← Hint: تستخدم AES-256-GCM (أقوى خوارزمية تشفير متاحة)
/// ← Hint: PBKDF2 لتوليد مفتاح قوي من كلمة المرور
/// ← Hint: Salt و IV عشوائيين لكل عملية تشفير (يمنع Rainbow Table Attack)
///
/// 📝 للمستقبل:
/// - يمكن إضافة دعم لخوارزميات تشفير إضافية (ChaCha20-Poly1305)
/// - يمكن إضافة compression قبل التشفير لتقليل الحجم
/// - يمكن إضافة digital signature للتحقق من الأصالة
class EncryptionService {
  // ============================================================================
  // 🔧 الإعدادات الثابتة
  // ============================================================================

  /// ← Hint: عدد تكرارات PBKDF2 (100,000 = توازن بين الأمان والسرعة)
  /// ← Hint: كلما زاد الرقم، زاد الأمان لكن بطء أكثر
  /// 📝 للمستقبل: يمكن جعل هذا قابل للتعديل من Firebase Remote Config
  static const int _pbkdf2Iterations = 100000;

  /// ← Hint: طول المفتاح المُولَّد = 32 byte = 256 bit (AES-256)
  static const int _keyLength = 32;

  /// ← Hint: طول Salt = 32 byte (موصى به للأمان القوي)
  /// ← Hint: Salt مختلف لكل نسخة احتياطية = حماية ضد Rainbow Tables
  static const int _saltLength = 32;

  /// ← Hint: طول IV (Initialization Vector) = 16 byte لـ AES
  /// ← Hint: IV مختلف لكل ملف مشفر = حماية إضافية
  static const int _ivLength = 16;

  // ============================================================================
  // 🔑 توليد مفتاح من كلمة المرور
  // ============================================================================

  /// توليد مفتاح تشفير قوي من كلمة المرور باستخدام PBKDF2
  ///
  /// ← Hint: PBKDF2 = Password-Based Key Derivation Function 2
  /// ← Hint: تأخذ كلمة مرور ضعيفة وتحولها لمفتاح قوي
  /// ← Hint: Salt مختلف لكل نسخة احتياطية = نفس كلمة المرور تنتج مفاتيح مختلفة!
  ///
  /// [password] كلمة المرور التي أدخلها المستخدم
  /// [salt] البيانات العشوائية المضافة (يجب حفظها مع النسخة!)
  ///
  /// 📝 للمستقبل:
  /// - يمكن استخدام Argon2 بدل PBKDF2 (أقوى لكن أبطأ)
  /// - يمكن جعل عدد التكرارات ديناميكي بناءً على سرعة الجهاز
  static Uint8List deriveKey(String password, Uint8List salt) {
    try {
      debugPrint('🔑 [Encryption] توليد مفتاح من كلمة المرور...');
      debugPrint('   - طول كلمة المرور: ${password.length} حرف');
      debugPrint('   - Salt: ${salt.length} bytes');
      debugPrint('   - التكرارات: $_pbkdf2Iterations');

      // ← Hint: تحويل كلمة المرور لـ bytes
      final passwordBytes = utf8.encode(password);

      // ← Hint: استخدام PBKDF2 مع SHA-256
      // ← Hint: كل تكرار يزيد من صعوبة كسر المفتاح
      final pbkdf2 = Pbkdf2(
        macAlgorithm: Hmac(sha256, passwordBytes), // ← تصحيح: استخدام Hmac بشكل صحيح
        iterations: _pbkdf2Iterations,
        bits: _keyLength * 8, // 256 bits
      );

      final derivedKey = pbkdf2.deriveKeyFromPassword(
        password: passwordBytes,
        nonce: salt,
      );

      debugPrint('✅ [Encryption] تم توليد المفتاح بنجاح (${derivedKey.length} bytes)');

      return Uint8List.fromList(derivedKey);
    } catch (e, stackTrace) {
      debugPrint('❌ [Encryption] خطأ في توليد المفتاح: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ============================================================================
  // 🎲 توليد بيانات عشوائية آمنة
  // ============================================================================

  /// توليد Salt عشوائي آمن
  ///
  /// ← Hint: Salt مختلف لكل نسخة احتياطية
  /// ← Hint: يُحفظ بدون تشفير مع النسخة (ليس سرياً!)
  /// ← Hint: دوره: يجعل نفس كلمة المرور تنتج مفاتيح مختلفة
  ///
  /// 📝 للمستقبل: يمكن دمج device ID في Salt لربط بالجهاز (اختياري)
  static Uint8List generateSalt() {
    final random = Random.secure();
    final salt = Uint8List(_saltLength);

    for (int i = 0; i < _saltLength; i++) {
      salt[i] = random.nextInt(256);
    }

    debugPrint('🎲 [Encryption] تم توليد Salt عشوائي (${salt.length} bytes)');
    return salt;
  }

  /// توليد IV (Initialization Vector) عشوائي
  ///
  /// ← Hint: IV مختلف لكل ملف مشفر
  /// ← Hint: يُحفظ مع الملف المشفر (ليس سرياً!)
  /// ← Hint: دوره: يجعل نفس البيانات تنتج نص مشفر مختلف
  ///
  /// 📝 للمستقبل: GCM mode يمكنه توليد IV تلقائياً
  static Uint8List generateIV() {
    final random = Random.secure();
    final iv = Uint8List(_ivLength);

    for (int i = 0; i < _ivLength; i++) {
      iv[i] = random.nextInt(256);
    }

    debugPrint('🎲 [Encryption] تم توليد IV عشوائي (${iv.length} bytes)');
    return iv;
  }

  // ============================================================================
  // 🔒 التشفير - AES-256-GCM
  // ============================================================================

  /// تشفير بيانات باستخدام AES-256-GCM
  ///
  /// ← Hint: GCM = Galois/Counter Mode (أفضل mode لـ AES)
  /// ← Hint: يوفر سرية (Confidentiality) + صحة (Integrity)
  /// ← Hint: يكتشف أي تعديل على البيانات المشفرة
  ///
  /// [data] البيانات المراد تشفيرها
  /// [password] كلمة المرور
  /// [salt] Salt (إذا لم يُعطى، يُولَّد تلقائياً)
  ///
  /// Returns: Map يحتوي على:
  /// - encrypted: البيانات المشفرة
  /// - salt: Salt المستخدم (يجب حفظه!)
  /// - iv: IV المستخدم (يجب حفظه!)
  ///
  /// 📝 للمستقبل:
  /// - يمكن إضافة AAD (Additional Authenticated Data) لحماية إضافية
  /// - يمكن إضافة compression قبل التشفير
  static Map<String, dynamic> encryptData({
    required Uint8List data,
    required String password,
    Uint8List? salt,
  }) {
    try {
      debugPrint('🔒 [Encryption] بدء تشفير البيانات...');
      debugPrint('   - حجم البيانات: ${_formatBytes(data.length)}');

      // 1️⃣ توليد أو استخدام Salt
      final usedSalt = salt ?? generateSalt();

      // 2️⃣ توليد المفتاح من كلمة المرور + Salt
      final key = deriveKey(password, usedSalt);

      // 3️⃣ توليد IV عشوائي
      final iv = generateIV();

      // 4️⃣ تشفير البيانات
      final encrypter = encrypt.Encrypter(
        encrypt.AES(
          encrypt.Key(key),
          mode: encrypt.AESMode.gcm, // ← Hint: GCM = أفضل mode
        ),
      );

      final encrypted = encrypter.encryptBytes(
        data,
        iv: encrypt.IV(iv),
      );

      debugPrint('✅ [Encryption] تم التشفير بنجاح');
      debugPrint('   - حجم بعد التشفير: ${_formatBytes(encrypted.bytes.length)}');

      return {
        'encrypted': Uint8List.fromList(encrypted.bytes),
        'salt': usedSalt,
        'iv': iv,
      };
    } catch (e, stackTrace) {
      debugPrint('❌ [Encryption] خطأ في التشفير: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// تشفير ملف
  ///
  /// ← Hint: يقرأ الملف، يشفره، ويحفظه في ملف جديد
  ///
  /// [inputPath] مسار الملف المراد تشفيره
  /// [outputPath] مسار الملف المشفر
  /// [password] كلمة المرور
  ///
  /// Returns: Map يحتوي على salt و iv (يجب حفظهما!)
  ///
  /// 📝 للمستقبل: يمكن إضافة streaming encryption للملفات الكبيرة جداً
  static Future<Map<String, Uint8List>> encryptFile({
    required String inputPath,
    required String outputPath,
    required String password,
  }) async {
    try {
      debugPrint('🔒 [Encryption] تشفير ملف...');
      debugPrint('   - Input: $inputPath');
      debugPrint('   - Output: $outputPath');

      // 1️⃣ قراءة الملف
      final file = await compute(_readFile, inputPath);

      // 2️⃣ تشفير البيانات
      final result = encryptData(data: file, password: password);

      // 3️⃣ حفظ الملف المشفر
      await compute(
        _writeFile,
        {'path': outputPath, 'data': result['encrypted'] as Uint8List},
      );

      debugPrint('✅ [Encryption] تم تشفير الملف بنجاح');

      return {
        'salt': result['salt'] as Uint8List,
        'iv': result['iv'] as Uint8List,
      };
    } catch (e, stackTrace) {
      debugPrint('❌ [Encryption] خطأ في تشفير الملف: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ============================================================================
  // 🔓 فك التشفير - AES-256-GCM
  // ============================================================================

  /// فك تشفير بيانات مشفرة بـ AES-256-GCM
  ///
  /// ← Hint: يتحقق تلقائياً من سلامة البيانات (GCM integrity check)
  /// ← Hint: إذا تم تعديل البيانات المشفرة، سيفشل فك التشفير!
  ///
  /// [encryptedData] البيانات المشفرة
  /// [password] كلمة المرور
  /// [salt] Salt المحفوظ (من عملية التشفير)
  /// [iv] IV المحفوظ (من عملية التشفير)
  ///
  /// 📝 للمستقبل: يمكن إضافة retry mechanism للكلمة خاطئة
  static Uint8List decryptData({
    required Uint8List encryptedData,
    required String password,
    required Uint8List salt,
    required Uint8List iv,
  }) {
    try {
      debugPrint('🔓 [Encryption] بدء فك التشفير...');
      debugPrint('   - حجم البيانات المشفرة: ${_formatBytes(encryptedData.length)}');

      // 1️⃣ توليد المفتاح من كلمة المرور + Salt
      final key = deriveKey(password, salt);

      // 2️⃣ فك التشفير
      final encrypter = encrypt.Encrypter(
        encrypt.AES(
          encrypt.Key(key),
          mode: encrypt.AESMode.gcm,
        ),
      );

      final decrypted = encrypter.decryptBytes(
        encrypt.Encrypted(encryptedData),
        iv: encrypt.IV(iv),
      );

      debugPrint('✅ [Encryption] تم فك التشفير بنجاح');
      debugPrint('   - حجم بعد فك التشفير: ${_formatBytes(decrypted.length)}');

      return Uint8List.fromList(decrypted);
    } catch (e, stackTrace) {
      debugPrint('❌ [Encryption] خطأ في فك التشفير: $e');
      debugPrint('   ⚠️ السبب المحتمل: كلمة سر خاطئة أو ملف تالف');
      debugPrint('Stack trace: $stackTrace');

      // ← Hint: رسالة واضحة للمستخدم
      throw Exception('فشل فك التشفير - كلمة السر خاطئة أو الملف تالف');
    }
  }

  /// فك تشفير ملف
  ///
  /// ← Hint: يقرأ الملف المشفر، يفك تشفيره، ويحفظه
  ///
  /// 📝 للمستقبل: يمكن إضافة progress callback للملفات الكبيرة
  static Future<void> decryptFile({
    required String inputPath,
    required String outputPath,
    required String password,
    required Uint8List salt,
    required Uint8List iv,
  }) async {
    try {
      debugPrint('🔓 [Encryption] فك تشفير ملف...');
      debugPrint('   - Input: $inputPath');
      debugPrint('   - Output: $outputPath');

      // 1️⃣ قراءة الملف المشفر
      final encryptedFile = await compute(_readFile, inputPath);

      // 2️⃣ فك التشفير
      final decrypted = decryptData(
        encryptedData: encryptedFile,
        password: password,
        salt: salt,
        iv: iv,
      );

      // 3️⃣ حفظ الملف
      await compute(
        _writeFile,
        {'path': outputPath, 'data': decrypted},
      );

      debugPrint('✅ [Encryption] تم فك تشفير الملف بنجاح');
    } catch (e, stackTrace) {
      debugPrint('❌ [Encryption] خطأ في فك تشفير الملف: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ============================================================================
  // 🔐 التحقق من قوة كلمة المرور
  // ============================================================================

  /// التحقق من قوة كلمة المرور
  ///
  /// ← Hint: يعطي تقييم من 0 إلى 4 (0 = ضعيف جداً، 4 = قوي جداً)
  ///
  /// Returns: Map يحتوي على:
  /// - strength: رقم من 0 إلى 4
  /// - feedback: نصيحة للمستخدم
  /// - isValid: هل كلمة المرور مقبولة (>= 6 أحرف)
  ///
  /// 📝 للمستقبل:
  /// - يمكن استخدام zxcvbn library لتقييم أدق
  /// - يمكن فحص ضد قاموس كلمات المرور الشائعة
  /// - يمكن فحص ضد Have I Been Pwned API
  static Map<String, dynamic> checkPasswordStrength(String password) {
    int strength = 0;
    final feedback = <String>[];

    // ← Hint: الحد الأدنى = 6 أحرف (حسب طلب المستخدم)
    if (password.length < 6) {
      return {
        'strength': 0,
        'strengthText': 'ضعيفة',
        'feedback': 'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
        'isValid': false,
      };
    }

    // ← Hint: الطول
    if (password.length >= 6) strength++;
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;

    // ← Hint: التنوع
    if (RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[A-Z]').hasMatch(password)) {
      strength++;
      feedback.add('تحتوي على أحرف كبيرة وصغيرة');
    }

    if (RegExp(r'[0-9]').hasMatch(password)) {
      strength++;
      feedback.add('تحتوي على أرقام');
    }

    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) {
      strength++;
      feedback.add('تحتوي على رموز خاصة');
    }

    // ← Hint: تحديد القوة النهائية (0-4)
    final finalStrength = (strength / 6 * 4).round().clamp(0, 4);

    String strengthText;
    switch (finalStrength) {
      case 0:
      case 1:
        strengthText = 'ضعيفة';
        break;
      case 2:
        strengthText = 'متوسطة';
        break;
      case 3:
        strengthText = 'جيدة';
        break;
      case 4:
        strengthText = 'قوية جداً';
        break;
      default:
        strengthText = 'ضعيفة';
    }

    return {
      'strength': finalStrength,
      'strengthText': strengthText,
      'feedback': feedback.isEmpty
          ? 'استخدم مزيج من الأحرف والأرقام والرموز'
          : feedback.join(' • '),
      'isValid': password.length >= 6,
    };
  }

  // ============================================================================
  // 🔐 حساب Hash (للتحقق من السلامة)
  // ============================================================================

  /// حساب SHA-256 hash لبيانات
  ///
  /// ← Hint: يُستخدم للتحقق من سلامة البيانات (integrity check)
  /// ← Hint: أي تغيير بسيط في البيانات = hash مختلف تماماً
  ///
  /// 📝 للمستقبل: يمكن استخدام BLAKE2 بدل SHA-256 (أسرع)
  static String calculateHash(Uint8List data) {
    final digest = sha256.convert(data);
    return digest.toString();
  }

  /// حساب hash لملف
  ///
  /// ← Hint: مفيد للتحقق من أن الملف لم يُعدَّل
  ///
  /// 📝 للمستقبل: يمكن إضافة streaming hash للملفات الكبيرة جداً
  static Future<String> calculateFileHash(String filePath) async {
    try {
      final file = await compute(_readFile, filePath);
      return calculateHash(file);
    } catch (e) {
      debugPrint('❌ [Encryption] خطأ في حساب hash: $e');
      rethrow;
    }
  }

  // ============================================================================
  // 🛠️ دوال مساعدة
  // ============================================================================

  /// تنسيق حجم البيانات بشكل قابل للقراءة
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// قراءة ملف (للاستخدام مع compute)
  static Future<Uint8List> _readFile(String path) async {
    final file = _getFile(path);
    return await file.readAsBytes();
  }

  /// كتابة ملف (للاستخدام مع compute)
  static Future<void> _writeFile(Map<String, dynamic> params) async {
    final path = params['path'] as String;
    final data = params['data'] as Uint8List;
    final file = _getFile(path);
    await file.writeAsBytes(data);
  }

  /// الحصول على File object (helper)
  static File _getFile(String path) {
    // ← Hint: دالة مساعدة لإنشاء File object
    return File(path);
  }
}

// ============================================================================
// 📝 PBKDF2 Implementation
// ← Hint: تطبيق بسيط لـ PBKDF2 (من مكتبة crypto)
// ============================================================================

/// ← Hint: PBKDF2 = Password-Based Key Derivation Function 2
/// ← Hint: معيار PKCS #5 v2.0
class Pbkdf2 {
  final Hmac macAlgorithm;
  final int iterations;
  final int bits;

  Pbkdf2({
    required this.macAlgorithm,
    required this.iterations,
    required this.bits,
  });

  List<int> deriveKeyFromPassword({
    required List<int> password,
    required List<int> nonce,
  }) {
    final keyLength = (bits / 8).ceil();
    final hmac = Hmac(sha256, password);

    final blocks = <int>[];
    final blockCount = (keyLength / macAlgorithm.convert([]).bytes.length).ceil();

    for (var i = 1; i <= blockCount; i++) {
      final block = _deriveBlock(hmac, nonce, i);
      blocks.addAll(block);
    }

    return blocks.sublist(0, keyLength);
  }

  List<int> _deriveBlock(Hmac hmac, List<int> nonce, int blockIndex) {
    final blockIndexBytes = [
      (blockIndex >> 24) & 0xff,
      (blockIndex >> 16) & 0xff,
      (blockIndex >> 8) & 0xff,
      blockIndex & 0xff,
    ];

    var u = hmac.convert([...nonce, ...blockIndexBytes]).bytes;
    final result = List<int>.from(u);

    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }

    return result;
  }
}
