// 📁 lib/services/backup_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:crypto/crypto.dart';

/// 🧠 كلاس مسؤول عن إنشاء النسخ الاحتياطي واستعادته بشكل آمن ومشفر
///
/// ← Hint: يستخدم هذا الكلاس تشفير AES-256 مع كلمة مرور من المستخدم
/// ← Hint: يتم اشتقاق مفتاح التشفير من كلمة المرور باستخدام PBKDF2 (10000 iteration)
/// ← Hint: هيكل الملف المشفر: [Magic Number] + [Salt 16 bytes] + [Encrypted Data]
class BackupService {
  // 1️⃣ اسم ملف قاعدة البيانات (كما هو في تطبيقك)
  static const String _dbFileName = "accounting.db";

  // 2️⃣ معرف خاص للتحقق من صحة ملف النسخة الاحتياطية
  /// ← Hint: Magic Number يضمن أن الملف من تطبيقنا وليس ملف عشوائي
  static const String _magicNumber = 'MY_ACCOUNTING_APP_BACKUP_V2';

  // 3️⃣ الامتداد الخاص بملف النسخ الاحتياطي
  static const String _backupFileExtension = 'accbak';

  // 4️⃣ عدد مرات التكرار لـ PBKDF2 (كلما زاد كان أكثر أماناً ولكن أبطأ)
  /// ← Hint: 10000 iteration تعطي توازن جيد بين الأمان والسرعة
  static const int _pbkdf2Iterations = 10000;

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

      // تحقق من وجود قاعدة البيانات
      if (!await dbFile.exists()) {
        print("⚠️ ملف قاعدة البيانات غير موجود في: ${dbFile.path}");
        return {
          'status': 'error',
          'message': 'ملف قاعدة البيانات غير موجود.',
        };
      }

      // قراءة محتوى قاعدة البيانات كـ Bytes
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

      // 🔸 بناء الملف النهائي: [Magic Number] + [Salt] + [Encrypted Data]
      /// ← Hint: نحتاج Salt عند فك التشفير لاشتقاق نفس المفتاح
      final finalFileBytes = Uint8List.fromList([
        ..._magicNumber.codeUnits,  // ← Hint: للتحقق من صحة الملف
        ...salt,                     // ← Hint: Salt للاشتقاق (16 بايت)
        ...encryptedData.bytes,      // ← Hint: البيانات المشفرة
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
      // طباعة الخطأ في الـ Console لتتبع المشكلة
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

      // قراءة محتوى الملف كاملاً
      final fileBytes = await backupFile.readAsBytes();

      // 🔸 التحقق من الحد الأدنى لحجم الملف
      /// ← Hint: الحد الأدنى = Magic Number + Salt (16 bytes) + بيانات مشفرة (16 bytes على الأقل)
      final minFileSize = _magicNumber.codeUnits.length + _saltLength + 16;
      if (fileBytes.length < minFileSize) {
        throw Exception('حجم الملف صغير جداً. الملف قد يكون تالفاً.');
      }

      // 🔸 استخراج Magic Number من بداية الملف
      final magicNumberSize = _magicNumber.codeUnits.length;
      final fileMagicNumber = String.fromCharCodes(
        fileBytes.sublist(0, magicNumberSize),
      );

      // ← Hint: التحقق من Magic Number للتأكد أن الملف من تطبيقنا
      if (fileMagicNumber != _magicNumber) {
        throw Exception('ملف النسخة الاحتياطية غير صالح أو لا يخص هذا التطبيق.');
      }

      // 🔸 استخراج Salt من الملف
      /// ← Hint: Salt موجود مباشرة بعد Magic Number
      final salt = fileBytes.sublist(
        magicNumberSize,
        magicNumberSize + _saltLength,
      );

      // 🔸 استخراج البيانات المشفرة
      /// ← Hint: باقي الملف هو البيانات المشفرة
      final encryptedBytes = fileBytes.sublist(magicNumberSize + _saltLength);
      final encryptedData = enc.Encrypted(Uint8List.fromList(encryptedBytes));

      // 🔸 اشتقاق مفتاح فك التشفير من كلمة المرور والـ Salt المستخرج
      print("🔹 اشتقاق مفتاح فك التشفير من كلمة المرور...");
      final decryptionKey = _deriveKeyFromPassword(password, salt);
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

      // كتابة البيانات المستعادة
      await dbFile.writeAsBytes(dbBytes);

      print("✅ تم استعادة النسخة الاحتياطية بنجاح!");
      return 'نجاح';
    } catch (e) {
      print('❌ خطأ أثناء استعادة النسخة الاحتياطية: $e');
      return e.toString().replaceFirst("Exception: ", "");
    }
  }
}