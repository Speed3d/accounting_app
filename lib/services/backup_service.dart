// 📁 lib/services/backup_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:accountant_touch/services/firebase_service.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:crypto/crypto.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:sqflite_sqlcipher/sqflite.dart';

// ← Hint: استيراد مساعدات جديدة للنسخ الاحتياطي الشامل
import '../utils/archive_helper.dart';
import '../data/database_helper.dart';
import 'database_key_manager.dart';

/// 🧠 كلاس مسؤول عن إنشاء النسخ الاحتياطي واستعادته بشكل آمن ومشفر
///
/// ← Hint: يستخدم هذا الكلاس تشفير AES-256 مع كلمة مرور من المستخدم
/// ← Hint: يتم اشتقاق مفتاح التشفير من كلمة المرور باستخدام PBKDF2 (10000 iteration)
/// ← Hint: هيكل الملف المشفر: [Magic Number] + [Salt 16 bytes] + [Encrypted Data]
class BackupService {
  // 1️⃣ اسم ملف قاعدة البيانات (كما هو في تطبيقك)
  /// ← Hint: هذا هو اسم ملف قاعدة البيانات الذي نريد نسخه واستعادته
  static const String _dbFileName = "accounting.db";

  // 2️⃣ معرف خاص للتحقق من صحة ملف النسخة الاحتياطية
  /// ← Hint: يتم جلبه من Firebase عند الحاجة بدلاً من القيمة الثابتة
  String get _magicNumber => FirebaseService.instance.getBackupMagicNumber();

  // 3️⃣ الامتداد الخاص بملف النسخ الاحتياطي
  /// ← Hint: امتداد مخصص لملفاتنا لسهولة التعرف عليها
  static const String _backupFileExtension = 'accbak';

  // 4️⃣ عدد مرات التكرار لـ PBKDF2 (كلما زاد كان أكثر أماناً ولكن أبطأ)
  /// ← Hint: 10000 iteration تعطي توازن جيد بين الأمان والسرعة
  static const int _pbkdf2Iterations = 100000;

  // 5️⃣ طول Salt بالبايتات (16 بايت = 128 بت)
  /// ← Hint: Salt عشوائي يمنع هجمات Rainbow Table
  static const int _saltLength = 16;

  // ==========================================================
  // ← Hint: دالة مساعدة لاشتقاق مفتاح تشفير قوي من كلمة المرور
  // ==========================================================
  /// تحول كلمة المرور إلى مفتاح AES-256 (32 بايت) باستخدام PBKDF2
  ///
  /// ← Hint: PBKDF2 = Password-Based Key Derivation Function 2
  /// ← Hint: يطبق دالة Hash متكررة لجعل التخمين صعب جداً
  ///
  /// [password] كلمة المرور من المستخدم
  /// [salt] قيمة عشوائية لجعل كل مفتاح فريد حتى لو تكررت كلمة المرور
  enc.Key _deriveKeyFromPassword(String password, List<int> salt) {
    // ← Hint: نستخدم HMAC-SHA256 كدالة Hash أساسية
    final hmac = Hmac(sha256, utf8.encode(password));

    // ← Hint: تطبيق PBKDF2 يدوياً (مبسط لكن فعال)
    var result = hmac.convert(salt + [0, 0, 0, 1]).bytes;
    var previousBlock = result;

    for (var i = 1; i < _pbkdf2Iterations; i++) {
      previousBlock = hmac.convert(previousBlock).bytes;
      // ← Hint: XOR كل النتائج معاً
      for (var j = 0; j < result.length; j++) {
        result[j] ^= previousBlock[j];
      }
    }

    // ← Hint: نأخذ أول 32 بايت للحصول على مفتاح AES-256
    return enc.Key(Uint8List.fromList(result.sublist(0, 32)));
  }

  // ==========================================================
  // ← Hint: دالة لإنشاء IV من الـ Salt (مشتق ثانوي)
  // ==========================================================
  /// ← Hint: بدلاً من تخزين IV منفصل، نشتقه من Salt
  /// ← Hint: هذا يقلل حجم الملف ويحافظ على الأمان
  enc.IV _deriveIVFromSalt(List<int> salt) {
    // ← Hint: نأخذ Hash من Salt ونستخدم أول 16 بايت كـ IV
    final hash = sha256.convert(salt).bytes;
    return enc.IV(Uint8List.fromList(hash.sublist(0, 16)));
  }

  // ============================================================================
  // ← Hint: 🔥 دالة ذكية للكشف عن صيغة النسخة الاحتياطية (قديمة أم جديدة)
  // ============================================================================
  /// كشف ذكي لصيغة النسخة الاحتياطية
  ///
  /// ← Hint: النسخ الجديدة (بعد التحديث الأخير):
  ///    البنية: [4 bytes length] + [dbEncryptionKey] + [database bytes]
  ///
  /// ← Hint: النسخ القديمة (قبل التحديث):
  ///    البنية: [database bytes فقط] - بدون مفتاح مضمن
  ///
  /// ← Hint: الكشف يعتمد على:
  ///    1. قراءة أول 4 bytes كطول مفترض للمفتاح
  ///    2. التحقق من أن الطول منطقي (16-256 bytes)
  ///    3. التحقق من أن حجم البيانات كافٍ
  ///
  /// Returns: Map يحتوي على {'isNewFormat': bool, 'keyLength': int?, 'diagnostic': String}
  Map<String, dynamic> _detectBackupFormat(Uint8List dbBytes) {
    try {
      print("🔍 [BackupService] فحص صيغة النسخة الاحتياطية...");

      // ═══════════════════════════════════════════════════════════
      // التحقق من الحد الأدنى للحجم
      // ═══════════════════════════════════════════════════════════

      if (dbBytes.length < 1024 + 4) {
        return {
          'isNewFormat': false,
          'reason': 'حجم البيانات صغير جداً (أقل من 1KB)',
          'diagnostic': 'الملف أصغر من الحد الأدنى المطلوب',
        };
      }

      // ═══════════════════════════════════════════════════════════
      // استخراج أول 4 bytes (الطول المفترض)
      // ═══════════════════════════════════════════════════════════

      final possibleKeyLength = (dbBytes[0] << 24) |
          (dbBytes[1] << 16) |
          (dbBytes[2] << 8) |
          dbBytes[3];

      print("   • أول 4 bytes: [${dbBytes[0]}, ${dbBytes[1]}, ${dbBytes[2]}, ${dbBytes[3]}]");
      print("   • الطول المحسوب: $possibleKeyLength bytes");
      print("   • حجم البيانات الكلي: ${_formatBytes(dbBytes.length)}");

      // ═══════════════════════════════════════════════════════════
      // فحص صحة الطول
      // ← Hint: مفتاح صالح يجب أن يكون بين 16-256 bytes
      // ═══════════════════════════════════════════════════════════

      if (possibleKeyLength < 16 || possibleKeyLength > 256) {
        print("   ⚠️ الطول خارج النطاق المقبول (16-256)");
        return {
          'isNewFormat': false,
          'reason': 'الطول المحسوب خارج النطاق المقبول',
          'possibleKeyLength': possibleKeyLength,
          'diagnostic': 'النسخة لا تحتوي على مفتاح مضمن (صيغة قديمة)',
        };
      }

      // ═══════════════════════════════════════════════════════════
      // فحص أن البيانات كافية لاحتواء: طول + مفتاح + قاعدة بيانات
      // ═══════════════════════════════════════════════════════════

      final requiredSize = 4 + possibleKeyLength + 1024; // على الأقل 1KB للقاعدة

      if (dbBytes.length < requiredSize) {
        print("   ⚠️ البيانات غير كافية: يحتاج $requiredSize، متوفر ${dbBytes.length}");
        return {
          'isNewFormat': false,
          'reason': 'حجم البيانات أقل من المتوقع',
          'possibleKeyLength': possibleKeyLength,
          'requiredSize': requiredSize,
          'actualSize': dbBytes.length,
          'diagnostic': 'البيانات لا تتطابق مع الصيغة الجديدة',
        };
      }

      // ═══════════════════════════════════════════════════════════
      // فحص إضافي: محاولة قراءة المفتاح المفترض كـ UTF-8
      // ← Hint: مفتاح صالح يجب أن يكون hex string (فقط 0-9, a-f, A-F)
      // ═══════════════════════════════════════════════════════════

      try {
        final keyBytes = dbBytes.sublist(4, 4 + possibleKeyLength);
        final possibleKey = utf8.decode(keyBytes);

        // ← Hint: التحقق من أنه hex string صالح
        final hexRegex = RegExp(r'^[0-9a-fA-F]+$');

        if (!hexRegex.hasMatch(possibleKey)) {
          print("   ⚠️ المفتاح المستخرج ليس hex string صالح");
          return {
            'isNewFormat': false,
            'reason': 'المفتاح المستخرج ليس بالصيغة الصحيحة',
            'possibleKeyLength': possibleKeyLength,
            'diagnostic': 'البيانات المستخرجة لا تطابق مفتاح تشفير صالح',
          };
        }

        // ✅ كل الفحوصات نجحت - هذه نسخة جديدة!
        print("   ✅ الصيغة: جديدة (تحتوي على مفتاح مضمن)");
        print("   • طول المفتاح: $possibleKeyLength bytes");
        print("   • حجم القاعدة: ${_formatBytes(dbBytes.length - 4 - possibleKeyLength)}");

        return {
          'isNewFormat': true,
          'keyLength': possibleKeyLength,
          'databaseSize': dbBytes.length - 4 - possibleKeyLength,
          'diagnostic': 'نسخة احتياطية حديثة - تحتوي على مفتاح التشفير',
        };

      } catch (e) {
        print("   ⚠️ فشل فك تشفير المفتاح كـ UTF-8: $e");
        return {
          'isNewFormat': false,
          'reason': 'فشل قراءة المفتاح المفترض',
          'possibleKeyLength': possibleKeyLength,
          'diagnostic': 'البيانات لا يمكن تفسيرها كمفتاح صالح',
        };
      }

    } catch (e) {
      debugPrint("❌ [BackupService] خطأ في _detectBackupFormat: $e");
      return {
        'isNewFormat': false,
        'reason': 'خطأ في الكشف',
        'error': e.toString(),
        'diagnostic': 'حدث خطأ أثناء تحليل صيغة النسخة',
      };
    }
  }

  // ==========================================================
  // ← Hint: استخراج قائمة المستخدمين من ملف نسخة احتياطية
  // ← Hint: بدون استعادة كاملة - فقط للمعاينة
  // ← Hint: هذه الدالة مفيدة لعرض المستخدمين قبل اتخاذ قرار الاستعادة
  // ==========================================================
  /// [backupFile] ملف النسخة الاحتياطية
  /// [password] كلمة المرور
  /// قائمة المستخدمين أو null في حالة الفشل
  Future<List<Map<String, dynamic>>?> extractUsersFromBackup(
    File backupFile,
    String password,
  ) async {
    try {
      print("🔹 استخراج المستخدمين من النسخة الاحتياطية...");

      // ← Hint: تنظيف كلمة المرور من المسافات
      final cleanPassword = password.trim();

      // ← Hint: التحقق من كلمة المرور ليست فارغة
      if (cleanPassword.isEmpty) {
        return null;
      }

      // ← Hint: قراءة محتوى الملف
      final fileBytes = await backupFile.readAsBytes();

      // ← Hint: الحصول على Magic Number من Firebase
      final magicNumber = _magicNumber;
      final magicNumberSize = magicNumber.codeUnits.length;

      // ← Hint: التحقق من الحد الأدنى لحجم الملف
      final minFileSize = magicNumberSize + _saltLength + 16;
      if (fileBytes.length < minFileSize) {
        throw Exception('حجم الملف صغير جداً');
      }

      // ← Hint: استخراج Magic Number من الملف
      final fileMagicNumber = String.fromCharCodes(
        fileBytes.sublist(0, magicNumberSize),
      );

      if (fileMagicNumber != magicNumber) {
        throw Exception('ملف النسخة الاحتياطية غير صالح');
      }

      // ← Hint: استخراج Salt
      final salt = fileBytes.sublist(
        magicNumberSize,
        magicNumberSize + _saltLength,
      );

      // ============================================================================
// 🔥 التحقق من HMAC
// ============================================================================

const int hmacLength = 32;

final minFileSizeWithHMAC = magicNumberSize + _saltLength + hmacLength + 16;
if (fileBytes.length < minFileSizeWithHMAC) {
  throw Exception('حجم الملف صغير جداً أو الملف تالف.');
}

final storedHMAC = fileBytes.sublist(
  magicNumberSize + _saltLength,
  magicNumberSize + _saltLength + hmacLength,
);

final encryptedBytes = fileBytes.sublist(
  magicNumberSize + _saltLength + hmacLength,
);
final encryptedData = enc.Encrypted(Uint8List.fromList(encryptedBytes));

print("🔹 التحقق من سلامة الملف...");

final decryptionKey = _deriveKeyFromPassword(cleanPassword, salt);
final hmacKey = Hmac(sha256, decryptionKey.bytes);
final calculatedHMAC = hmacKey.convert([
  ...magicNumber.codeUnits,
  ...salt,
  ...encryptedBytes,
]);

bool hmacMatches = true;
if (storedHMAC.length != calculatedHMAC.bytes.length) {
  hmacMatches = false;
} else {
  for (int i = 0; i < storedHMAC.length; i++) {
    if (storedHMAC[i] != calculatedHMAC.bytes[i]) {
      hmacMatches = false;
      break;
    }
  }
}

if (!hmacMatches) {
  throw Exception('الملف تم التلاعب به أو تالف. HMAC غير متطابق.');
}

print("✅ تم التحقق من سلامة الملف بنجاح");


      // ← Hint: اشتقاق مفتاح فك التشفير
      // final decryptionKey = _deriveKeyFromPassword(password, salt);

      final iv = _deriveIVFromSalt(salt);

      // ← Hint: فك التشفير
      final encrypter = enc.Encrypter(enc.AES(decryptionKey, mode: enc.AESMode.cbc));

      Uint8List dbBytes;
      try {
        final decryptedData = encrypter.decryptBytes(encryptedData, iv: iv);
        dbBytes = Uint8List.fromList(decryptedData);
      } catch (e) {
        throw Exception('كلمة المرور غير صحيحة');
      }

      // ============================================================================
      // ← Hint: 🔥 ملاحظة مهمة جداً - لماذا لا نتحقق من "SQLite"؟
      // ============================================================================
      // ← Hint: قاعدة البيانات في التطبيق مشفرة بـ SQLCipher (تشفير مزدوج):
      // ← Hint: الطبقة 1: SQLCipher encryption (تشفير القاعدة نفسها)
      // ← Hint: الطبقة 2: AES-256 encryption (تشفير النسخة الاحتياطية)
      // ← Hint:
      // ← Hint: عند فك تشفير AES، نحصل على قاعدة بيانات مشفرة بـ SQLCipher
      // ← Hint: القاعدة المشفرة بـ SQLCipher لا تبدأ بـ "SQLite" بل ببيانات عشوائية
      // ← Hint: لذلك التحقق من "SQLite" سيفشل دائماً حتى لو كانت كلمة المرور صحيحة!
      // ← Hint:
      // ← Hint: ✅ بدلاً من ذلك نعتمد على:
      // ← Hint: 1. HMAC (تم التحقق منه مسبقاً) - يضمن سلامة البيانات
      // ← Hint: 2. نجاح فك التشفير AES - يضمن صحة كلمة المرور
      // ← Hint: 3. محاولة فتح القاعدة لاحقاً - يضمن صحة البيانات
      // ============================================================================

      // ============================================================================
      // ← Hint: 🔥 كشف صيغة النسخة الاحتياطية (قديمة أم جديدة)
      // ============================================================================

      print("🔍 استخدام الكشف الذكي لصيغة النسخة...");
      final formatInfo = _detectBackupFormat(dbBytes);
      final isNewFormat = formatInfo['isNewFormat'] == true;

      print("   📊 نتيجة الكشف: ${formatInfo['diagnostic']}");

      // ============================================================================
      // ← Hint: معالجة النسخ القديمة - رسالة خطأ واضحة
      // ============================================================================

      if (!isNewFormat) {
        print("❌ نسخة احتياطية قديمة - لا يمكن استعادتها بعد حذف التطبيق");
        throw Exception(
          '⚠️ نسخة احتياطية قديمة\n\n'
          'هذه النسخة تم إنشاؤها بنسخة قديمة من التطبيق.\n'
          'لا يمكن استعادتها بعد حذف التطبيق وإعادة تثبيته.\n\n'
          '💡 الحل:\n'
          '• إذا كان التطبيق ما زال مثبتاً ويعمل، استعد النسخة من داخل التطبيق أولاً\n'
          '• ثم أنشئ نسخة احتياطية جديدة\n'
          '• النسخ الجديدة تعمل بشكل صحيح بعد حذف التطبيق وإعادة تثبيته ✅\n\n'
          'السبب التقني: ${formatInfo['diagnostic']}'
        );
      }

      // ============================================================================
      // ← Hint: 🔥 استخراج dbEncryptionKey من النسخة الجديدة
      // ============================================================================

      final dbKeyLength = formatInfo['keyLength'] as int;
      print("🔹 استخراج المفتاح من النسخة الجديدة - الطول: $dbKeyLength bytes");

      // ← Hint: استخراج المفتاح
      final dbKeyBytes = dbBytes.sublist(4, 4 + dbKeyLength);
      final restoredDbEncryptionKey = utf8.decode(dbKeyBytes);

      // ← Hint: استخراج بيانات قاعدة البيانات
      final actualDbBytes = dbBytes.sublist(4 + dbKeyLength);

      print("✅ تم استخراج المفتاح بنجاح");
      print("   • حجم القاعدة المستعادة: ${_formatBytes(actualDbBytes.length)}");

      // ============================================================================
      // ← Hint: 🎯 استبدال المفتاح الحالي بالمفتاح المستعاد
      // ← Hint: هذا هو السر! نحفظ المفتاح القديم لفتح القاعدة القديمة
      // ============================================================================

      print("🔹 حفظ المفتاح المستعاد في DatabaseKeyManager...");
      await DatabaseKeyManager.instance.replaceKey(restoredDbEncryptionKey);
      print("✅ تم استبدال المفتاح بنجاح!");

      // ← Hint: حفظ قاعدة البيانات في ملف مؤقت
      final tempDir = await getTemporaryDirectory();
      final tempDbPath = p.join(tempDir.path, 'temp_backup_${DateTime.now().millisecondsSinceEpoch}.db');
      final tempDbFile = File(tempDbPath);
      await tempDbFile.writeAsBytes(actualDbBytes);

      // ← Hint: الآن نستخدم المفتاح المستعاد لفتح القاعدة
      final dbEncryptionKey = restoredDbEncryptionKey;

      // ============================================================================
      // ← Hint: 🎯 التحقق النهائي من صحة كلمة المرور والبيانات
      // ← Hint: نحاول فتح قاعدة البيانات بـ SQLCipher - هذا يضمن:
      // ← Hint: 1. كلمة المرور صحيحة (HMAC + AES نجحا)
      // ← Hint: 2. البيانات سليمة (القاعدة تفتح بنجاح)
      // ← Hint: 3. مفتاح SQLCipher صحيح (القاعدة مشفرة بنفس المفتاح)
      // ============================================================================

      Database? tempDb;

      try {
        // ← Hint: محاولة فتح قاعدة البيانات المؤقتة
        tempDb = await openDatabase(
          tempDbPath,
          password: dbEncryptionKey,
          readOnly: true, // ← Hint: القراءة فقط للأمان
        );

        // ← Hint: قراءة المستخدمين
        final users = await tempDb.query('TB_Users');
        print("✅ تم استخراج ${users.length} مستخدم بنجاح");
        return users;

      } on DatabaseException catch (e) {
        // ← Hint: إذا فشل فتح القاعدة، المشكلة في البيانات أو المفتاح
        print("❌ فشل فتح قاعدة البيانات: $e");
        throw Exception('فشل قراءة البيانات - تأكد من صحة كلمة المرور');

      } finally {
        // ← Hint: إغلاق القاعدة وحذف الملف المؤقت
        if (tempDb != null && tempDb.isOpen) {
          await tempDb.close();
        }

        try {
          if (await tempDbFile.exists()) {
            await tempDbFile.delete();
          }
        } catch (e) {
          print("⚠️ تحذير: فشل حذف الملف المؤقت: $e");
        }
      }

    } catch (e) {
      print('❌ خطأ في استخراج المستخدمين: $e');
      return null;
    }
  }

  // ==========================================================
  // ← Hint: استعادة ذكية مع خيارات دمج المستخدمين
  // ← Hint: هذه الدالة الرئيسية للاستعادة مع الحفاظ على الصلاحيات
  // ==========================================================
  /// [password] كلمة المرور
  /// [backupFile] ملف النسخة الاحتياطية
  /// [userMergeOption] خيار دمج المستخدمين:
  ///   - 'merge': دمج المستخدمين (الأفضل - يحافظ على الصلاحيات)
  ///   - 'replace': استبدال كامل
  ///   - 'keep': الاحتفاظ بالمستخدمين الحاليين فقط
  Future<Map<String, dynamic>> restoreBackupSmart(
    String password,
    File backupFile,
    String userMergeOption,
  ) async {
    try {
      print("🔹 بدء عملية الاستعادة الذكية...");
      print("🔹 خيار الدمج: $userMergeOption");

      // ← Hint: تنظيف كلمة المرور من المسافات
      final cleanPassword = password.trim();

      // ← Hint: التحقق من كلمة المرور
      if (cleanPassword.isEmpty) {
        return {
          'status': 'error',
          'message': 'كلمة المرور لا يمكن أن تكون فارغة',
        };
      }

      // ← Hint: قراءة محتوى الملف
      final fileBytes = await backupFile.readAsBytes();

      // ← Hint: الحصول على Magic Number من Firebase
      final magicNumber = _magicNumber;
      final magicNumberSize = magicNumber.codeUnits.length;

      // ← Hint: التحقق من الحد الأدنى للحجم
      final minFileSize = magicNumberSize + _saltLength + 16;
      if (fileBytes.length < minFileSize) {
        throw Exception('حجم الملف صغير جداً. الملف قد يكون تالفاً.');
      }

      // ← Hint: استخراج Magic Number
      final fileMagicNumber = String.fromCharCodes(
        fileBytes.sublist(0, magicNumberSize),
      );

      if (fileMagicNumber != magicNumber) {
        throw Exception('ملف النسخة الاحتياطية غير صالح أو لا يخص هذا التطبيق.');
      }

      // ← Hint: استخراج Salt والبيانات المشفرة
      final salt = fileBytes.sublist(
        magicNumberSize,
        magicNumberSize + _saltLength,
      );

      // ============================================================================
// 🔥 التحقق من HMAC
// ============================================================================

const int hmacLength = 32;

final minFileSizeWithHMAC = magicNumberSize + _saltLength + hmacLength + 16;
if (fileBytes.length < minFileSizeWithHMAC) {
  throw Exception('حجم الملف صغير جداً أو الملف تالف.');
}

final storedHMAC = fileBytes.sublist(
  magicNumberSize + _saltLength,
  magicNumberSize + _saltLength + hmacLength,
);

final encryptedBytes = fileBytes.sublist(
  magicNumberSize + _saltLength + hmacLength,
);
final encryptedData = enc.Encrypted(Uint8List.fromList(encryptedBytes));

print("🔹 التحقق من سلامة الملف...");

final decryptionKey = _deriveKeyFromPassword(cleanPassword, salt);
final hmacKey = Hmac(sha256, decryptionKey.bytes);
final calculatedHMAC = hmacKey.convert([
  ...magicNumber.codeUnits,
  ...salt,
  ...encryptedBytes,
]);

bool hmacMatches = true;
if (storedHMAC.length != calculatedHMAC.bytes.length) {
  hmacMatches = false;
} else {
  for (int i = 0; i < storedHMAC.length; i++) {
    if (storedHMAC[i] != calculatedHMAC.bytes[i]) {
      hmacMatches = false;
      break;
    }
  }
}

if (!hmacMatches) {
  throw Exception('الملف تم التلاعب به أو تالف. HMAC غير متطابق.');
}

print("✅ تم التحقق من سلامة الملف بنجاح");


      // ← Hint: فك التشفير
      print("🔹 فك تشفير البيانات...");

      // final decryptionKey = _deriveKeyFromPassword(password, salt);

      final iv = _deriveIVFromSalt(salt);

      final encrypter = enc.Encrypter(enc.AES(decryptionKey, mode: enc.AESMode.cbc));

      Uint8List dbBytes;
      try {
        final decryptedData = encrypter.decryptBytes(encryptedData, iv: iv);
        dbBytes = Uint8List.fromList(decryptedData);
      } catch (e) {
        throw Exception(
          'فشل فك التشفير. تأكد من صحة كلمة المرور أو أن الملف غير تالف.',
        );
      }

      // ============================================================================
      // ← Hint: 🔥 ملاحظة مهمة - التحقق من صحة البيانات
      // ============================================================================
      // ← Hint: لا نتحقق من "SQLite" لأن القاعدة مشفرة بـ SQLCipher (شرح مفصل في السطور 206-220)
      // ← Hint: نعتمد على:
      // ← Hint: ✅ HMAC - تم التحقق منه مسبقاً (السطر 342)
      // ← Hint: ✅ نجاح فك التشفير AES - يضمن صحة كلمة المرور
      // ← Hint: ✅ محاولة فتح القاعدة بعد الاستعادة - التحقق النهائي
      // ============================================================================

      // ← Hint: التحقق الأساسي من حجم البيانات
      if (dbBytes.length < 1024) {
        throw Exception(
          'الملف تالف - حجم البيانات صغير جداً (أقل من 1KB).',
        );
      }

      print("✅ تم فك التشفير بنجاح - حجم البيانات: ${_formatBytes(dbBytes.length)}");

      // ============================================================================
      // ← Hint: 🔥 كشف صيغة النسخة الاحتياطية (قديمة أم جديدة)
      // ============================================================================

      print("🔍 استخدام الكشف الذكي لصيغة النسخة...");
      final formatInfo = _detectBackupFormat(dbBytes);
      final isNewFormat = formatInfo['isNewFormat'] == true;

      print("   📊 نتيجة الكشف: ${formatInfo['diagnostic']}");

      // ============================================================================
      // ← Hint: معالجة النسخ القديمة - رسالة خطأ واضحة
      // ============================================================================

      if (!isNewFormat) {
        print("❌ نسخة احتياطية قديمة - لا يمكن استعادتها بعد حذف التطبيق");
        throw Exception(
          '⚠️ نسخة احتياطية قديمة\n\n'
          'هذه النسخة تم إنشاؤها بنسخة قديمة من التطبيق.\n'
          'لا يمكن استعادتها بعد حذف التطبيق وإعادة تثبيته.\n\n'
          '💡 الحل:\n'
          '• إذا كان التطبيق ما زال مثبتاً ويعمل، استعد النسخة من داخل التطبيق أولاً\n'
          '• ثم أنشئ نسخة احتياطية جديدة\n'
          '• النسخ الجديدة تعمل بشكل صحيح بعد حذف التطبيق وإعادة تثبيته ✅\n\n'
          'السبب التقني: ${formatInfo['diagnostic']}'
        );
      }

      // ============================================================================
      // ← Hint: 🔥 استخراج dbEncryptionKey من النسخة الجديدة
      // ============================================================================

      final dbKeyLength = formatInfo['keyLength'] as int;
      print("🔹 استخراج المفتاح من النسخة الجديدة - الطول: $dbKeyLength bytes");

      // ← Hint: استخراج المفتاح
      final dbKeyBytes = dbBytes.sublist(4, 4 + dbKeyLength);
      final restoredDbEncryptionKey = utf8.decode(dbKeyBytes);

      // ← Hint: استخراج بيانات قاعدة البيانات الفعلية
      final actualDbBytes = dbBytes.sublist(4 + dbKeyLength);

      print("✅ تم استخراج المفتاح - حجم القاعدة: ${_formatBytes(actualDbBytes.length)}");

      // ← Hint: ✅ النقطة المهمة - حفظ المستخدمين الحاليين قبل الاستبدال
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dbFolder.path, _dbFileName));

      List<Map<String, dynamic>> currentUsers = [];

      // ← Hint: الحصول على مفتاح التشفير الحالي (قبل الاستبدال)
      final currentDbEncryptionKey = await DatabaseKeyManager.instance.getDatabaseKey();

      // ← Hint: قراءة المستخدمين الحاليين إذا كان الخيار ليس 'replace'
      if (userMergeOption != 'replace') {
        if (await dbFile.exists()) {
          Database? currentDb;
          try {
            currentDb = await openDatabase(
              dbFile.path,
              password: currentDbEncryptionKey, // ← استخدام المفتاح الحالي
              readOnly: true, // ← Hint: القراءة فقط للأمان
            );
            currentUsers = await currentDb.query('TB_Users');
            print("🔹 تم حفظ ${currentUsers.length} مستخدم حالي");
          } catch (e) {
            print("⚠️ تحذير: فشل قراءة المستخدمين الحاليين: $e");
          } finally {
            if (currentDb != null && currentDb.isOpen) {
              await currentDb.close();
            }
          }
        }
      }

      // ← Hint: نسخ احتياطية من القاعدة الحالية (للأمان)
      if (await dbFile.exists()) {
        final backupPath = '${dbFile.path}.old';
        await dbFile.copy(backupPath);
        print("🔸 تم إنشاء نسخة احتياطية من القاعدة الحالية: $backupPath");
      }

      // ============================================================================
      // ← Hint: 🎯 استبدال المفتاح قبل كتابة القاعدة!
      // ← Hint: نستبدل المفتاح الجديد بالمفتاح المستعاد من النسخة
      // ============================================================================

      print("🔹 استبدال المفتاح الحالي بالمفتاح المستعاد...");
      await DatabaseKeyManager.instance.replaceKey(restoredDbEncryptionKey);
      print("✅ تم استبدال المفتاح بنجاح!");

      final dbEncryptionKey = restoredDbEncryptionKey;

      // ← Hint: كتابة البيانات المستعادة (الآن بدون المفتاح، فقط القاعدة)
      await dbFile.writeAsBytes(actualDbBytes);
      print("✅ تم استعادة قاعدة البيانات");

      // ============================================================================
      // ← Hint: 🎯 التحقق النهائي - محاولة فتح القاعدة المستعادة
      // ← Hint: هذا يضمن أن البيانات المستعادة صحيحة وقابلة للاستخدام
      // ============================================================================

      try {
        final testDb = await openDatabase(
          dbFile.path,
          password: dbEncryptionKey,
          readOnly: true,
        );
        await testDb.close();
        print("✅ تم التحقق من صحة قاعدة البيانات المستعادة");
      } catch (e) {
        // ← Hint: إذا فشل فتح القاعدة، نستعيد النسخة الاحتياطية القديمة
        print("❌ فشل فتح قاعدة البيانات المستعادة: $e");

        final backupPath = '${dbFile.path}.old';
        final backupFile = File(backupPath);

        if (await backupFile.exists()) {
          await backupFile.copy(dbFile.path);
          // ← Hint: استعادة المفتاح القديم أيضاً
          await DatabaseKeyManager.instance.replaceKey(currentDbEncryptionKey);
          print("🔄 تم استعادة النسخة الاحتياطية القديمة والمفتاح");
        }

        throw Exception('فشل استعادة البيانات - الملف تالف أو غير متوافق');
      }

      // ← Hint: ✅ الجزء الأهم - معالجة المستخدمين حسب الخيار
      if (userMergeOption == 'merge' && currentUsers.isNotEmpty) {
        // ← Hint: دمج المستخدمين - الحفاظ على الصلاحيات الحالية
        print("🔹 بدء دمج المستخدمين...");

        final restoredDb = await openDatabase(
          dbFile.path,
          password: dbEncryptionKey,
        );
        
        try {
          int mergedCount = 0;
          int skippedCount = 0;
          
          for (var user in currentUsers) {
            try {
              // ← Hint: محاولة إدراج المستخدم
              // ← Hint: إذا كان UserName موجود، سيفشل (UNIQUE constraint)
              await restoredDb.insert('TB_Users', user);
              mergedCount++;
              print("  ✅ تم دمج: ${user['UserName']}");
            } catch (e) {
              // ← Hint: اسم المستخدم موجود - نتخطاه
              // ← Hint: هذا يحافظ على الصلاحيات الحالية
              skippedCount++;
              print("  ⚠️ تم تخطي (موجود): ${user['UserName']}");
            }
          }
          
          print("✅ اكتمل الدمج - تم دمج: $mergedCount، تم تخطي: $skippedCount");
          
          return {
            'status': 'success',
            'message': 'تم دمج المستخدمين بنجاح',
            'merged': mergedCount,
            'skipped': skippedCount,
          };
        } finally {
          await restoredDb.close();
        }
        
      } else if (userMergeOption == 'keep' && currentUsers.isNotEmpty) {
        // ← Hint: الاحتفاظ بالمستخدمين الحاليين - حذف المستخدمين من النسخة المستعادة
        print("🔹 الاحتفاظ بالمستخدمين الحاليين فقط...");

        final restoredDb = await openDatabase(
          dbFile.path,
          password: dbEncryptionKey,
        );
        
        try {
          // ← Hint: حذف جميع المستخدمين من النسخة المستعادة
          await restoredDb.delete('TB_Users');
          
          // ← Hint: إعادة إدراج المستخدمين الحاليين
          for (var user in currentUsers) {
            await restoredDb.insert('TB_Users', user);
          }
          
          print("✅ تم الاحتفاظ بـ ${currentUsers.length} مستخدم حالي");
          
          return {
            'status': 'success',
            'message': 'تم الاحتفاظ بالمستخدمين الحاليين',
            'kept': currentUsers.length,
          };
        } finally {
          await restoredDb.close();
        }
      }

      // ← Hint: الخيار 'replace' - لا نفعل شيء (الاستبدال الكامل)
      print("✅ تم استبدال قاعدة البيانات بالكامل");

      return {
        'status': 'success',
        'message': 'نجاح',
      };

    } catch (e) {
      print('❌ خطأ أثناء استعادة النسخة الاحتياطية: $e');
      return {
        'status': 'error',
        'message': e.toString().replaceFirst("Exception: ", ""),
      };
    }
  }

  // ==========================================================
  // ← Hint: دالة للحصول على مجلد Downloads مع طلب الأذونات
  // ==========================================================
  Future<Directory?> _getDownloadsDirectory() async {
    // ← Hint: على Android 10+ لا نحتاج أذونات للكتابة في Downloads
    if (Platform.isAndroid) {
      // ← Hint: محاولة الحصول على مجلد Downloads
      final directory = Directory('/storage/emulated/0/Download');
      if (await directory.exists()) {
        return directory;
      }
      
      // ← Hint: إذا فشل، نستخدم External Storage Directory
      return await getExternalStorageDirectory();
    } else if (Platform.isIOS) {
      // ← Hint: على iOS نستخدم Documents Directory
      return await getApplicationDocumentsDirectory();
    }
    return null;
  }

  // ==========================================================
  // 🗂️ إنشاء ومشاركة نسخة احتياطية مشفرة بكلمة مرور
  // ← Hint: المنطق المحدث - استخدام كلمة مرور من المستخدم للتشفير
  // ← Hint: هيكل الملف: [Magic Number] + [Salt] + [Encrypted Database]
  // ==========================================================
  /// [password] كلمة المرور التي سيستخدمها المستخدم لحماية النسخة
  Future<Map<String, dynamic>> createAndShareBackup(String password) async {

    try {
      print("🔹 بدء إنشاء النسخة الاحتياطية...");

      // ← Hint: تنظيف كلمة المرور من المسافات
      final cleanPassword = password.trim();

      if (cleanPassword.isEmpty) {
        return {
          'status': 'error',
          'message': 'كلمة المرور لا يمكن أن تكون فارغة',
        };
      }

      // 🔸 الحصول على مجلد قاعدة البيانات
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dbFolder.path, _dbFileName));

      // ← Hint: تحقق من وجود قاعدة البيانات
      if (!await dbFile.exists()) {
        print("⚠️ ملف قاعدة البيانات غير موجود في: ${dbFile.path}");
        return {
          'status': 'error',
          'message': 'ملف قاعدة البيانات غير موجود.',
        };
      }

      // ← Hint: قراءة محتوى قاعدة البيانات كـ Bytes
      final dbBytes = await dbFile.readAsBytes();

      // ============================================================================
      // ← Hint: 🔥 الحل العبقري - حفظ dbEncryptionKey داخل النسخة الاحتياطية!
      // ============================================================================
      // ← Hint: المشكلة: عند حذف التطبيق، يتم توليد dbEncryptionKey جديد
      // ← Hint: الحل: نحفظ المفتاح القديم داخل النسخة، ونستعيده عند الاستعادة
      // ← Hint: البنية الجديدة: [dbEncryptionKey Length] + [dbEncryptionKey] + [dbBytes]
      // ============================================================================

      // ← Hint: الحصول على مفتاح تشفير قاعدة البيانات (SQLCipher)
      print("🔹 الحصول على مفتاح تشفير قاعدة البيانات...");
      final dbEncryptionKey = await DatabaseKeyManager.instance.getDatabaseKey();

      // ← Hint: تحويل المفتاح إلى bytes
      final dbKeyBytes = utf8.encode(dbEncryptionKey);
      final dbKeyLength = dbKeyBytes.length;

      // ← Hint: دمج المفتاح مع بيانات القاعدة
      // ← Hint: البنية: [4 bytes length] + [key bytes] + [db bytes]
      final combinedData = BytesBuilder();
      combinedData.add([
        (dbKeyLength >> 24) & 0xFF,
        (dbKeyLength >> 16) & 0xFF,
        (dbKeyLength >> 8) & 0xFF,
        dbKeyLength & 0xFF,
      ]); // ← 4 bytes للطول
      combinedData.add(dbKeyBytes); // ← المفتاح
      combinedData.add(dbBytes); // ← قاعدة البيانات

      final dataToEncrypt = combinedData.toBytes();

      print("✅ تم تجهيز البيانات - الحجم الكلي: ${_formatBytes(dataToEncrypt.length)}");
      print("   • حجم المفتاح: ${dbKeyBytes.length} bytes");
      print("   • حجم القاعدة: ${_formatBytes(dbBytes.length)}");

      // 🔸 توليد Salt عشوائي لهذه النسخة الاحتياطية
      /// ← Hint: Salt عشوائي جديد لكل نسخة احتياطية يمنع هجمات Rainbow Table
      /// ← Hint: حتى لو استخدمنا نفس كلمة المرور، كل نسخة ستكون مختلفة
      final salt = enc.IV.fromSecureRandom(_saltLength).bytes;

      // 🔸 اشتقاق مفتاح التشفير من كلمة المرور والـ Salt
      print("🔹 اشتقاق مفتاح التشفير من كلمة المرور...");
      final encryptionKey = _deriveKeyFromPassword(cleanPassword, salt);
      final iv = _deriveIVFromSalt(salt);

      // 🔸 إنشاء أداة التشفير باستخدام AES-256
      /// ← Hint: نستخدم CBC mode للتشفير القوي
      final encrypter = enc.Encrypter(enc.AES(encryptionKey, mode: enc.AESMode.cbc));

      // 🔸 تشفير البيانات (المفتاح + القاعدة معاً)
      print("🔹 تشفير البيانات (المفتاح + القاعدة)...");
      final encryptedData = encrypter.encryptBytes(dataToEncrypt, iv: iv);
      
      // ============================================================================
     // 🔥 إضافة HMAC للتحقق من سلامة البيانات (جديد!)
     // ← Hint: HMAC يكشف أي تعديل على الملف المشفر
     // ← Hint: يمنع Tampering Attacks
     // ============================================================================
     print("🔹 حساب HMAC للتحقق من السلامة...");

      // ← Hint: الحصول على Magic Number من Firebase
      final magicNumber = _magicNumber;

           // ← Hint: إنشاء مفتاح HMAC من كلمة المرور والـ Salt
      final hmacKey = Hmac(sha256, encryptionKey.bytes);
      final hmacData = hmacKey.convert([
       ...magicNumber.codeUnits,
       ...salt,
       ...encryptedData.bytes,
     ]);

     // ← Hint: HMAC = 32 bytes
     final hmacBytes = hmacData.bytes;

     debugPrint('✅ تم حساب HMAC: ${hmacBytes.length} bytes');

     // [Magic Number] + [Salt 16] + [HMAC 32] + [Encrypted Data]
     final finalFileBytes = Uint8List.fromList([
      ...magicNumber.codeUnits,    // ← Magic Number (متغير الطول)
      ...salt,                      // ← Salt (16 bytes)
      ...hmacBytes,                 // ← HMAC (32 bytes) - جديد!
      ...encryptedData.bytes,       // ← البيانات المشفرة
    ]);

      // ← Hint: إنشاء اسم ملف مع التاريخ والوقت
      final timestamp = DateTime.now();
      final backupFileName = 'backup-${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}-${timestamp.hour.toString().padLeft(2, '0')}-${timestamp.minute.toString().padLeft(2, '0')}.$_backupFileExtension';

      // ← Hint: الخطوة 1 - حفظ الملف في Downloads أولاً
      final downloadsDir = await _getDownloadsDirectory();

      if (downloadsDir == null) {
        return {
          'status': 'error',
          'message': 'لا يمكن الوصول إلى مجلد التنزيلات',
        };
      }

      final backupFile = File(p.join(downloadsDir.path, backupFileName));

      // ← Hint: كتابة البيانات المشفرة في ملف Downloads
      await backupFile.writeAsBytes(finalFileBytes);

      print("✅ تم حفظ الملف في: ${backupFile.path}");

      // ← Hint: الخطوة 2 - إرجاع معلومات الملف المحفوظ
      return {
        'status': 'success',
        'message': 'تم حفظ النسخة الاحتياطية بنجاح',
        'filePath': backupFile.path,
        'fileName': backupFileName,
      };

    } catch (e) {
      // ← Hint: طباعة الخطأ في الـ Console لتتبع المشكلة
      print('❌ خطأ أثناء إنشاء النسخة الاحتياطية: $e');
      return {
        'status': 'error',
        'message': 'حدث خطأ: ${e.toString()}',
      };
    }
  }

  // ==========================================================
  // ← Hint: دالة جديدة لمشاركة ملف موجود
  // ==========================================================
  Future<bool> shareBackupFile(String filePath) async {
    try {
      print("🔹 مشاركة ملف النسخة الاحتياطية...");
      
      final file = File(filePath);
      if (!await file.exists()) {
        print("⚠️ الملف غير موجود: $filePath");
        return false;
      }

      // ← Hint: مشاركة الملف باستخدام share_plus
      final result = await Share.shareXFiles(
        [XFile(filePath)],
        text: '📦 ملف النسخة الاحتياطية لتطبيق المحاسبة',
      );

      if (result.status == ShareResultStatus.success) {
        print("✅ تم مشاركة الملف بنجاح!");
        return true;
      } else {
        print("ℹ️ تم إلغاء المشاركة من قبل المستخدم.");
        return false;
      }
    } catch (e) {
      print('❌ خطأ أثناء مشاركة الملف: $e');
      return false;
    }
  }

  // ==========================================================
  // ♻️ استعادة البيانات من نسخة احتياطية مشفرة بكلمة مرور
  // ← Hint: المنطق المحدث - استخدام كلمة مرور من المستخدم لفك التشفير
  // ← Hint: نستخرج Salt من الملف ونستخدمه مع كلمة المرور لاشتقاق المفتاح
  // ==========================================================
  /// [password] كلمة المرور التي استخدمها المستخدم عند إنشاء النسخة
  Future<String> restoreBackup(String password) async {
    try {
      print("🔹 بدء عملية استعادة النسخة الاحتياطية...");

      // ← Hint: تنظيف كلمة المرور من المسافات
      final cleanPassword = password.trim();

      // ← Hint: التحقق من أن كلمة المرور ليست فارغة
      if (cleanPassword.isEmpty) {
        return 'كلمة المرور لا يمكن أن تكون فارغة';
      }

      // 🔸 اختيار ملف النسخة الاحتياطية من الجهاز
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [_backupFileExtension],
      );

      if (result == null || result.files.single.path == null) {
        print("ℹ️ تم إلغاء عملية الاستعادة.");
        return 'تم إلغاء عملية الاستعادة.';
      }

      final backupFile = File(result.files.single.path!);

      // ← Hint: قراءة محتوى الملف كاملاً
      final fileBytes = await backupFile.readAsBytes();

      // ← Hint: الحصول على Magic Number من Firebase
      final magicNumber = _magicNumber;
      final magicNumberSize = magicNumber.codeUnits.length;

      // 🔸 التحقق من الحد الأدنى لحجم الملف
      /// ← Hint: الحد الأدنى = Magic Number + Salt (16 bytes) + بيانات مشفرة (16 bytes على الأقل)
      final minFileSize = magicNumberSize + _saltLength + 16;
      if (fileBytes.length < minFileSize) {
        throw Exception('حجم الملف صغير جداً. الملف قد يكون تالفاً.');
      }

      // 🔸 استخراج Magic Number من بداية الملف
      final fileMagicNumber = String.fromCharCodes(
        fileBytes.sublist(0, magicNumberSize),
      );

      // ← Hint: التحقق من Magic Number للتأكد أن الملف من تطبيقنا
      if (fileMagicNumber != magicNumber) {
        throw Exception('ملف النسخة الاحتياطية غير صالح أو لا يخص هذا التطبيق.');
      }

      // 🔸 استخراج Salt من الملف
      /// ← Hint: Salt موجود مباشرة بعد Magic Number
      final salt = fileBytes.sublist(
        magicNumberSize,
        magicNumberSize + _saltLength,
      );

    // ============================================================================
    // 🔥 التحقق من HMAC (جديد!)
    // ← Hint: نتأكد أن الملف لم يُعدّل
    // ============================================================================

    const int hmacLength = 32; // SHA256 HMAC = 32 bytes

    // ← Hint: التحقق من حجم الملف (يجب أن يتضمن HMAC)
    final minFileSizeWithHMAC = magicNumberSize + _saltLength + hmacLength + 16;
    if (fileBytes.length < minFileSizeWithHMAC) {
     throw Exception('حجم الملف صغير جداً أو الملف تالف.');
    }

    // ← Hint: استخراج HMAC المحفوظ
    final storedHMAC = fileBytes.sublist(
      magicNumberSize + _saltLength,
      magicNumberSize + _saltLength + hmacLength,
    );

   // ← Hint: استخراج البيانات المشفرة (بعد HMAC)
    final encryptedBytes = fileBytes.sublist(
      magicNumberSize + _saltLength + hmacLength,
   );
    final encryptedData = enc.Encrypted(Uint8List.fromList(encryptedBytes));

    print("🔹 التحقق من سلامة الملف...");

    // ← Hint: حساب HMAC المتوقع
    final decryptionKey = _deriveKeyFromPassword(cleanPassword, salt);
    final hmacKey = Hmac(sha256, decryptionKey.bytes);
    final calculatedHMAC = hmacKey.convert([
      ...magicNumber.codeUnits,
      ...salt,
      ...encryptedBytes,
    ]);

// ← Hint: مقارنة HMAC      
    bool hmacMatches = true;
     if (storedHMAC.length != calculatedHMAC.bytes.length) {
     hmacMatches = false;
     } else {
      for (int i = 0; i < storedHMAC.length; i++) {
       if (storedHMAC[i] != calculatedHMAC.bytes[i]) {
            hmacMatches = false;
          break;
        }
      }
    }

      if (!hmacMatches) {
          throw Exception(
           'الملف تم التلاعب به أو تالف. HMAC غير متطابق.',
         );
       }

      print("✅ تم التحقق من سلامة الملف بنجاح");

      // 🔸 اشتقاق مفتاح فك التشفير من كلمة المرور والـ Salt المستخرج
      print("🔹 اشتقاق مفتاح فك التشفير من كلمة المرور...");

      // final decryptionKey = _deriveKeyFromPassword(password, salt);
      final iv = _deriveIVFromSalt(salt);

      // 🔸 إنشاء أداة فك التشفير
      final encrypter = enc.Encrypter(enc.AES(decryptionKey, mode: enc.AESMode.cbc));

      // 🔸 فك تشفير البيانات
      print("🔹 فك تشفير البيانات...");

      Uint8List dbBytes;
      try {
        final decryptedData = encrypter.decryptBytes(encryptedData, iv: iv);
        dbBytes = Uint8List.fromList(decryptedData);
      } catch (e) {
        // ← Hint: إذا فشل فك التشفير، غالباً السبب هو كلمة مرور خاطئة
        throw Exception(
          'فشل فك التشفير. تأكد من صحة كلمة المرور أو أن الملف غير تالف.',
        );
      }

      // ============================================================================
      // ← Hint: 🔥 التحقق من صحة البيانات المستعادة
      // ============================================================================
      // ← Hint: لا نتحقق من "SQLite" لأن القاعدة مشفرة بـ SQLCipher
      // ← Hint: للشرح المفصل، راجع السطور 206-220 في نفس الملف
      // ← Hint:
      // ← Hint: نعتمد على:
      // ← Hint: ✅ HMAC (تم التحقق منه في السطر 784)
      // ← Hint: ✅ نجاح فك التشفير AES
      // ← Hint: ✅ محاولة فتح القاعدة لاحقاً
      // ============================================================================

      // ← Hint: التحقق الأساسي من حجم البيانات
      if (dbBytes.length < 1024) {
        throw Exception(
          'الملف تالف - حجم البيانات صغير جداً (أقل من 1KB).',
        );
      }

      print("✅ تم فك التشفير بنجاح - حجم البيانات: ${_formatBytes(dbBytes.length)}");

      // ============================================================================
      // ← Hint: 🔥 كشف صيغة النسخة الاحتياطية (قديمة أم جديدة)
      // ============================================================================

      print("🔍 استخدام الكشف الذكي لصيغة النسخة...");
      final formatInfo = _detectBackupFormat(dbBytes);
      final isNewFormat = formatInfo['isNewFormat'] == true;

      print("   📊 نتيجة الكشف: ${formatInfo['diagnostic']}");

      // ============================================================================
      // ← Hint: معالجة النسخ القديمة - رسالة خطأ واضحة
      // ============================================================================

      if (!isNewFormat) {
        print("❌ نسخة احتياطية قديمة - لا يمكن استعادتها بعد حذف التطبيق");
        throw Exception(
          '⚠️ نسخة احتياطية قديمة\n\n'
          'هذه النسخة تم إنشاؤها بنسخة قديمة من التطبيق.\n'
          'لا يمكن استعادتها بعد حذف التطبيق وإعادة تثبيته.\n\n'
          '💡 الحل:\n'
          '• إذا كان التطبيق ما زال مثبتاً ويعمل، استعد النسخة من داخل التطبيق أولاً\n'
          '• ثم أنشئ نسخة احتياطية جديدة\n'
          '• النسخ الجديدة تعمل بشكل صحيح بعد حذف التطبيق وإعادة تثبيته ✅\n\n'
          'السبب التقني: ${formatInfo['diagnostic']}'
        );
      }

      // ============================================================================
      // ← Hint: 🔥 استخراج dbEncryptionKey من النسخة الجديدة
      // ============================================================================

      final dbKeyLength = formatInfo['keyLength'] as int;
      print("🔹 استخراج المفتاح من النسخة الجديدة - الطول: $dbKeyLength bytes");

      // ← Hint: استخراج المفتاح
      final dbKeyBytes = dbBytes.sublist(4, 4 + dbKeyLength);
      final restoredDbEncryptionKey = utf8.decode(dbKeyBytes);

      // ← Hint: استخراج بيانات قاعدة البيانات الفعلية
      final actualDbBytes = dbBytes.sublist(4 + dbKeyLength);

      print("✅ تم استخراج المفتاح - حجم القاعدة: ${_formatBytes(actualDbBytes.length)}");

      // 🔸 تحديد مكان قاعدة البيانات الأصلية واستبدالها بالنسخة الجديدة
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dbFolder.path, _dbFileName));

      // ← Hint: حفظ المفتاح الحالي قبل الاستبدال (للتراجع إذا فشلت العملية)
      final currentDbEncryptionKey = await DatabaseKeyManager.instance.getDatabaseKey();

      // ← Hint: نسخ احتياطية من قاعدة البيانات الحالية قبل الاستبدال (للأمان)
      if (await dbFile.exists()) {
        final backupPath = '${dbFile.path}.old';
        await dbFile.copy(backupPath);
        print("🔸 تم إنشاء نسخة احتياطية من القاعدة الحالية: $backupPath");
      }

      // ============================================================================
      // ← Hint: 🎯 استبدال المفتاح قبل كتابة القاعدة!
      // ============================================================================

      print("🔹 استبدال المفتاح بالمفتاح المستعاد...");
      await DatabaseKeyManager.instance.replaceKey(restoredDbEncryptionKey);
      print("✅ تم استبدال المفتاح بنجاح!");

      // ← Hint: كتابة البيانات المستعادة (بدون المفتاح، فقط القاعدة)
      await dbFile.writeAsBytes(actualDbBytes);

      // ============================================================================
      // ← Hint: 🎯 التحقق النهائي العبقري - محاولة فتح القاعدة
      // ← Hint: هذا يضمن أن كل شيء صحيح 100% قبل إبلاغ المستخدم بالنجاح
      // ============================================================================

      try {
        // ← Hint: محاولة فتح القاعدة المستعادة بالمفتاح المستعاد
        final testDb = await openDatabase(
          dbFile.path,
          password: restoredDbEncryptionKey,
          readOnly: true,
        );

        // ← Hint: محاولة قراءة جدول بسيط للتأكد
        await testDb.rawQuery('SELECT COUNT(*) FROM TB_Users');

        await testDb.close();

        print("✅ تم التحقق من صحة قاعدة البيانات المستعادة");

      } catch (e) {
        print("❌ فشل التحقق من القاعدة المستعادة: $e");

        // ← Hint: استعادة النسخة الاحتياطية القديمة والمفتاح
        final backupPath = '${dbFile.path}.old';
        final backupFile = File(backupPath);

        if (await backupFile.exists()) {
          await backupFile.copy(dbFile.path);
          await DatabaseKeyManager.instance.replaceKey(currentDbEncryptionKey);
          print("🔄 تم استعادة النسخة الاحتياطية القديمة والمفتاح للأمان");
        }

        throw Exception(
          'فشل التحقق من البيانات المستعادة. تم استعادة النسخة السابقة للأمان.',
        );
      }

      print("✅ تم استعادة النسخة الاحتياطية بنجاح!");
      return 'نجاح';
    } catch (e) {
      print('❌ خطأ أثناء استعادة النسخة الاحتياطية: $e');
      return e.toString().replaceFirst("Exception: ", "");
    }
  }

  // ============================================================================
  // ← Hint: النسخ الاحتياطي الشامل الجديد (v2.0) - يتضمن الصور!
  // ← Hint: هيكل النسخة: ZIP مشفر يحتوي على:
  //    - database.db (قاعدة البيانات)
  //    - metadata.json (معلومات النسخة)
  //    - encryption_key.enc (مفتاح التشفير مشفر)
  //    - images/ (جميع الصور)
  // ============================================================================

  /// إنشاء نسخة احتياطية شاملة (قاعدة البيانات + الصور + المفاتيح)
  ///
  /// [password] - كلمة المرور لتشفير النسخة
  /// [onProgress] - callback لتتبع التقدم (اختياري)
  ///
  /// Returns: Map يحتوي على حالة العملية ومعلومات الملف
  Future<Map<String, dynamic>> createComprehensiveBackup({
    required String password,
    Function(String status, int current, int total)? onProgress,
  }) async {
    try {
      debugPrint('🚀 [BackupService] بدء النسخ الاحتياطي الشامل...');

      // ═══════════════════════════════════════════════════════════
      // التحقق من كلمة المرور
      // ═══════════════════════════════════════════════════════════

      // ← Hint: تنظيف كلمة المرور من المسافات
      final cleanPassword = password.trim();

      if (cleanPassword.isEmpty) {
        return {
          'status': 'error',
          'message': 'كلمة المرور لا يمكن أن تكون فارغة',
        };
      }

      // ═══════════════════════════════════════════════════════════
      // إنشاء مجلد مؤقت للتحضير
      // ═══════════════════════════════════════════════════════════

      final tempDir = await getTemporaryDirectory();
      final backupWorkDir = Directory(p.join(tempDir.path, 'backup_${DateTime.now().millisecondsSinceEpoch}'));
      await backupWorkDir.create(recursive: true);

      debugPrint('📂 [BackupService] مجلد العمل: ${backupWorkDir.path}');

      try {
        // ═══════════════════════════════════════════════════════════
        // الخطوة 1: نسخ قاعدة البيانات
        // ═══════════════════════════════════════════════════════════

        onProgress?.call('نسخ قاعدة البيانات...', 1, 5);

        final dbFolder = await getApplicationDocumentsDirectory();
        final dbFile = File(p.join(dbFolder.path, _dbFileName));

        if (!await dbFile.exists()) {
          throw Exception('قاعدة البيانات غير موجودة');
        }

        final dbBackupFile = File(p.join(backupWorkDir.path, 'database.db'));
        await dbFile.copy(dbBackupFile.path);

        debugPrint('✅ [BackupService] نسخ قاعدة البيانات: ${await dbBackupFile.length()} bytes');

        // ═══════════════════════════════════════════════════════════
        // الخطوة 2: جمع جميع الصور
        // ═══════════════════════════════════════════════════════════

        onProgress?.call('جمع الصور...', 2, 5);

        final imagesStats = await _collectAllImages(backupWorkDir);

        debugPrint('✅ [BackupService] تم جمع ${imagesStats['total']} صورة');

        // ═══════════════════════════════════════════════════════════
        // الخطوة 3: حفظ مفتاح التشفير (مشفر بكلمة المرور)
        // ═══════════════════════════════════════════════════════════

        onProgress?.call('حفظ مفتاح التشفير...', 3, 5);

        final encryptionKey = await DatabaseKeyManager.instance.getDatabaseKey();
        await _saveEncryptionKey(backupWorkDir, encryptionKey, cleanPassword);

        debugPrint('✅ [BackupService] تم حفظ مفتاح التشفير');

        // ═══════════════════════════════════════════════════════════
        // الخطوة 4: إنشاء metadata.json
        // ═══════════════════════════════════════════════════════════

        onProgress?.call('إنشاء Metadata...', 4, 5);

        await _createMetadata(backupWorkDir, imagesStats);

        debugPrint('✅ [BackupService] تم إنشاء Metadata');

        // ═══════════════════════════════════════════════════════════
        // الخطوة 5: ضغط كل شيء في ZIP
        // ═══════════════════════════════════════════════════════════

        onProgress?.call('ضغط الملفات...', 5, 5);

        final timestamp = DateTime.now();
        final backupFileName = 'backup-comprehensive-${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}-${timestamp.hour.toString().padLeft(2, '0')}-${timestamp.minute.toString().padLeft(2, '0')}.$_backupFileExtension';

        final downloadsDir = await _getDownloadsDirectory();
        if (downloadsDir == null) {
          throw Exception('لا يمكن الوصول إلى مجلد التنزيلات');
        }

        final tempZipFile = File(p.join(tempDir.path, 'temp_backup.zip'));

        // ← Hint: ضغط المجلد بالكامل
        final compressed = await ArchiveHelper.compressDirectory(
          sourceDir: backupWorkDir,
          outputZipFile: tempZipFile,
        );

        if (!compressed) {
          throw Exception('فشل ضغط النسخة الاحتياطية');
        }

        debugPrint('✅ [BackupService] تم ضغط ZIP: ${await tempZipFile.length()} bytes');

        // ═══════════════════════════════════════════════════════════
        // الخطوة 6: تشفير ملف ZIP
        // ═══════════════════════════════════════════════════════════

        final zipBytes = await tempZipFile.readAsBytes();

        final salt = enc.IV.fromSecureRandom(_saltLength).bytes;
        final encryptionKeyDerived = _deriveKeyFromPassword(cleanPassword, salt);
        final iv = _deriveIVFromSalt(salt);

        final encrypter = enc.Encrypter(enc.AES(encryptionKeyDerived, mode: enc.AESMode.cbc));
        final encryptedData = encrypter.encryptBytes(zipBytes, iv: iv);

        // ← Hint: HMAC للتحقق
        final magicNumber = _magicNumber;
        final hmacKey = Hmac(sha256, encryptionKeyDerived.bytes);
        final hmacData = hmacKey.convert([
          ...magicNumber.codeUnits,
          ...salt,
          ...encryptedData.bytes,
        ]);

        // ← Hint: الملف النهائي
        final finalFileBytes = Uint8List.fromList([
          ...magicNumber.codeUnits,
          ...salt,
          ...hmacData.bytes,
          ...encryptedData.bytes,
        ]);

        // ═══════════════════════════════════════════════════════════
        // الخطوة 7: حفظ الملف النهائي
        // ═══════════════════════════════════════════════════════════

        final backupFile = File(p.join(downloadsDir.path, backupFileName));
        await backupFile.writeAsBytes(finalFileBytes);

        final fileSize = await backupFile.length();

        debugPrint('✅ [BackupService] النسخة الاحتياطية الشاملة جاهزة!');
        debugPrint('   الملف: ${backupFile.path}');
        debugPrint('   الحجم: ${_formatBytes(fileSize)}');

        return {
          'status': 'success',
          'message': 'تم إنشاء النسخة الاحتياطية الشاملة بنجاح',
          'filePath': backupFile.path,
          'fileName': backupFileName,
          'fileSize': fileSize,
          'imagesCount': imagesStats['total'],
          'metadata': imagesStats,
        };

      } finally {
        // ← Hint: تنظيف المجلد المؤقت
        try {
          if (await backupWorkDir.exists()) {
            await backupWorkDir.delete(recursive: true);
          }
        } catch (e) {
          debugPrint('⚠️ [BackupService] خطأ في التنظيف: $e');
        }
      }

    } catch (e, stackTrace) {
      debugPrint('❌ [BackupService] خطأ في createComprehensiveBackup: $e');
      debugPrint('Stack trace: $stackTrace');
      return {
        'status': 'error',
        'message': 'حدث خطأ: ${e.toString()}',
      };
    }
  }

  // ============================================================================
  // ← Hint: جمع جميع الصور من قاعدة البيانات
  // ============================================================================

  Future<Map<String, dynamic>> _collectAllImages(Directory backupDir) async {
    try {
      final imagesDir = Directory(p.join(backupDir.path, 'images'));
      await imagesDir.create(recursive: true);

      int totalImages = 0;
      final stats = <String, int>{};

      // ← Hint: الحصول على قاعدة البيانات
      final db = await DatabaseHelper.instance.database;

      // ═══════════════════════════════════════════════════════════
      // الفئات التي تحتوي على صور
      // ═══════════════════════════════════════════════════════════

      final categories = {
        'users': 'TB_Users',
        'suppliers': 'TB_Suppliers',
        'customers': 'TB_Customers',
        'products': 'TB_Products',
        'employees': 'TB_Employees',
        'company': 'TB_App_Settings',
      };

      for (final entry in categories.entries) {
        final categoryName = entry.key;
        final tableName = entry.value;

        try {
          // ← Hint: إنشاء مجلد للفئة
          final categoryDir = Directory(p.join(imagesDir.path, categoryName));
          await categoryDir.create();

          int categoryCount = 0;

          // ← Hint: قراءة جميع السجلات
          final rows = await db.query(tableName);

          for (final row in rows) {
            // ← Hint: البحث عن عمود ImagePath
            final imagePath = row['ImagePath'] as String?;

            if (imagePath != null && imagePath.isNotEmpty) {
              final imageFile = File(imagePath);

              if (await imageFile.exists()) {
                // ← Hint: نسخ الصورة
                final fileName = p.basename(imagePath);
                final destFile = File(p.join(categoryDir.path, fileName));

                await imageFile.copy(destFile.path);

                categoryCount++;
                totalImages++;
              }
            }
          }

          stats[categoryName] = categoryCount;
          debugPrint('  📁 $categoryName: $categoryCount صورة');

        } catch (e) {
          debugPrint('  ⚠️ خطأ في $categoryName: $e');
          stats[categoryName] = 0;
        }
      }

      return {
        'total': totalImages,
        ...stats,
      };

    } catch (e) {
      debugPrint('❌ خطأ في _collectAllImages: $e');
      return {'total': 0};
    }
  }

  // ============================================================================
  // ← Hint: حفظ مفتاح التشفير (مشفر بكلمة المرور)
  // ============================================================================

  Future<void> _saveEncryptionKey(
    Directory backupDir,
    String encryptionKey,
    String password,
  ) async {
    try {
      // ← Hint: تشفير المفتاح بكلمة مرور المستخدم
      final salt = enc.IV.fromSecureRandom(_saltLength).bytes;
      final derivedKey = _deriveKeyFromPassword(password, salt);
      final iv = _deriveIVFromSalt(salt);

      final encrypter = enc.Encrypter(enc.AES(derivedKey, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encrypt(encryptionKey, iv: iv);

      // ← Hint: حفظ: salt + encrypted key
      final keyData = {
        'salt': base64Encode(salt),
        'key': encrypted.base64,
        'version': '2.0',
      };

      final keyFile = File(p.join(backupDir.path, 'encryption_key.enc'));
      await keyFile.writeAsString(jsonEncode(keyData));

    } catch (e) {
      debugPrint('⚠️ خطأ في _saveEncryptionKey: $e');
      // ← Hint: غير حرج - يمكن للمستخدم استعادة المفتاح يدوياً
    }
  }

  // ============================================================================
  // ← Hint: إنشاء ملف metadata.json
  // ============================================================================

  Future<void> _createMetadata(
    Directory backupDir,
    Map<String, dynamic> imagesStats,
  ) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // ← Hint: إحصائيات قاعدة البيانات
      final usersCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM TB_Users')) ?? 0;
      final suppliersCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM TB_Suppliers')) ?? 0;
      final customersCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM TB_Customers')) ?? 0;
      final productsCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM TB_Products')) ?? 0;
      final employeesCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM TB_Employees')) ?? 0;

      final metadata = {
        'version': '2.0',
        'type': 'comprehensive',
        'created_at': DateTime.now().toIso8601String(),
        'app_version': '1.0.0', // ← يمكن جلبه من package_info_plus
        'statistics': {
          'users': usersCount,
          'suppliers': suppliersCount,
          'customers': customersCount,
          'products': productsCount,
          'employees': employeesCount,
          'images_total': imagesStats['total'],
          'images_by_category': {
            'users': imagesStats['users'] ?? 0,
            'suppliers': imagesStats['suppliers'] ?? 0,
            'customers': imagesStats['customers'] ?? 0,
            'products': imagesStats['products'] ?? 0,
            'employees': imagesStats['employees'] ?? 0,
            'company': imagesStats['company'] ?? 0,
          },
        },
        'encryption': {
          'database_key_included': true,
          'algorithm': 'AES-256-CBC',
          'key_derivation': 'PBKDF2-HMAC-SHA256',
        },
      };

      final metadataFile = File(p.join(backupDir.path, 'metadata.json'));
      await metadataFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(metadata),
      );

    } catch (e) {
      debugPrint('⚠️ خطأ في _createMetadata: $e');
    }
  }

  // ============================================================================
  // ← Hint: دالة مساعدة لتنسيق حجم الملف
  // ============================================================================

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}