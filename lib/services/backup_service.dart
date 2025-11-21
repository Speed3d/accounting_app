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
import 'package:sqflite/sqflite.dart';

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

      // ← Hint: التحقق من كلمة المرور ليست فارغة
      if (password.trim().isEmpty) {
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

final decryptionKey = _deriveKeyFromPassword(password, salt);
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

      // ← Hint: التحقق من أن البيانات صحيحة (SQLite)
      if (dbBytes.length < 16 ||
          String.fromCharCodes(dbBytes.sublist(0, 6)) != 'SQLite') {
        throw Exception('كلمة المرور غير صحيحة أو الملف تالف');
      }

      // ← Hint: حفظ قاعدة البيانات في ملف مؤقت
      final tempDir = await getTemporaryDirectory();
      final tempDbPath = p.join(tempDir.path, 'temp_backup.db');
      final tempDbFile = File(tempDbPath);
      await tempDbFile.writeAsBytes(dbBytes);

      // ← Hint: فتح قاعدة البيانات المؤقتة وقراءة المستخدمين
      final tempDb = await openDatabase(tempDbPath);
      
      try {
        final users = await tempDb.query('TB_Users');
        print("✅ تم استخراج ${users.length} مستخدم");
        return users;
      } finally {
        await tempDb.close();
        // ← Hint: حذف الملف المؤقت
        if (await tempDbFile.exists()) {
          await tempDbFile.delete();
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

      // ← Hint: التحقق من كلمة المرور
      if (password.trim().isEmpty) {
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

final decryptionKey = _deriveKeyFromPassword(password, salt);
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

      // ← Hint: التحقق من صحة البيانات
      if (dbBytes.length < 16 ||
          String.fromCharCodes(dbBytes.sublist(0, 6)) != 'SQLite') {
        throw Exception(
          'كلمة المرور غير صحيحة أو الملف تالف.',
        );
      }

      // ← Hint: ✅ النقطة المهمة - حفظ المستخدمين الحاليين قبل الاستبدال
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dbFolder.path, _dbFileName));
      
      List<Map<String, dynamic>> currentUsers = [];
      
      // ← Hint: قراءة المستخدمين الحاليين إذا كان الخيار ليس 'replace'
      if (userMergeOption != 'replace') {
        if (await dbFile.exists()) {
          final currentDb = await openDatabase(dbFile.path);
          try {
            currentUsers = await currentDb.query('TB_Users');
            print("🔹 تم حفظ ${currentUsers.length} مستخدم حالي");
          } finally {
            await currentDb.close();
          }
        }
      }

      // ← Hint: نسخ احتياطية من القاعدة الحالية (للأمان)
      if (await dbFile.exists()) {
        final backupPath = '${dbFile.path}.old';
        await dbFile.copy(backupPath);
        print("🔸 تم إنشاء نسخة احتياطية من القاعدة الحالية: $backupPath");
      }

      // ← Hint: كتابة البيانات المستعادة
      await dbFile.writeAsBytes(dbBytes);
      print("✅ تم استعادة قاعدة البيانات");

      // ← Hint: ✅ الجزء الأهم - معالجة المستخدمين حسب الخيار
      if (userMergeOption == 'merge' && currentUsers.isNotEmpty) {
        // ← Hint: دمج المستخدمين - الحفاظ على الصلاحيات الحالية
        print("🔹 بدء دمج المستخدمين...");
        
        final restoredDb = await openDatabase(dbFile.path);
        
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
        
        final restoredDb = await openDatabase(dbFile.path);
        
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

      // ← Hint: التحقق من أن كلمة المرور ليست فارغة
      if (password.trim().isEmpty) {
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

      // 🔸 توليد Salt عشوائي لهذه النسخة الاحتياطية
      /// ← Hint: Salt عشوائي جديد لكل نسخة احتياطية يمنع هجمات Rainbow Table
      /// ← Hint: حتى لو استخدمنا نفس كلمة المرور، كل نسخة ستكون مختلفة
      final salt = enc.IV.fromSecureRandom(_saltLength).bytes;

      // 🔸 اشتقاق مفتاح التشفير من كلمة المرور والـ Salt
      print("🔹 اشتقاق مفتاح التشفير من كلمة المرور...");
      final encryptionKey = _deriveKeyFromPassword(password, salt);
      final iv = _deriveIVFromSalt(salt);

      // 🔸 إنشاء أداة التشفير باستخدام AES-256
      /// ← Hint: نستخدم CBC mode للتشفير القوي
      final encrypter = enc.Encrypter(enc.AES(encryptionKey, mode: enc.AESMode.cbc));

      // 🔸 تشفير بيانات قاعدة البيانات
      print("🔹 تشفير البيانات...");
      final encryptedData = encrypter.encryptBytes(dbBytes, iv: iv);
      
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

      // ← Hint: التحقق من أن كلمة المرور ليست فارغة
      if (password.trim().isEmpty) {
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
    final decryptionKey = _deriveKeyFromPassword(password, salt);
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

      // 🔸 التحقق من أن البيانات المفكوكة منطقية (SQLite database)
      /// ← Hint: قواعد بيانات SQLite تبدأ دائماً بـ "SQLite format 3"
      if (dbBytes.length < 16 ||
          String.fromCharCodes(dbBytes.sublist(0, 6)) != 'SQLite') {
        throw Exception(
          'كلمة المرور غير صحيحة أو الملف تالف.',
        );
      }

      // 🔸 تحديد مكان قاعدة البيانات الأصلية واستبدالها بالنسخة الجديدة
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dbFolder.path, _dbFileName));

      // ← Hint: نسخ احتياطية من قاعدة البيانات الحالية قبل الاستبدال (للأمان)
      if (await dbFile.exists()) {
        final backupPath = '${dbFile.path}.old';
        await dbFile.copy(backupPath);
        print("🔸 تم إنشاء نسخة احتياطية من القاعدة الحالية: $backupPath");
      }

      // ← Hint: كتابة البيانات المستعادة
      await dbFile.writeAsBytes(dbBytes);

      print("✅ تم استعادة النسخة الاحتياطية بنجاح!");
      return 'نجاح';
    } catch (e) {
      print('❌ خطأ أثناء استعادة النسخة الاحتياطية: $e');
      return e.toString().replaceFirst("Exception: ", "");
    }
  }
}