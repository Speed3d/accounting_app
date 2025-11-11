// 📁 lib/services/backup_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';

/// 🧠 كلاس مسؤول عن إنشاء النسخ الاحتياطي واستعادته بشكل آمن ومشفر
class BackupService {
  // 1️⃣ تخزين المفاتيح بشكل آمن داخل النظام (Keychain في iOS و Keystore في Android)
  final _secureStorage = const FlutterSecureStorage();

  // أسماء المفاتيح التي نخزن بها القيم في التخزين الآمن
  static const _encryptionKeyStorageKey = 'backup_encryption_key';
  static const _encryptionIvStorageKey = 'backup_encryption_iv';

  // 2️⃣ اسم ملف قاعدة البيانات (كما هو في تطبيقك)
  static const String _dbFileName = "accounting.db";

  // 3️⃣ معرف خاص للتحقق من صحة ملف النسخة الاحتياطية
  static const String _magicNumber = 'MY_ACCOUNTING_APP_BACKUP_V1';

  // 4️⃣ الامتداد الخاص بملف النسخ الاحتياطي
  static const String _backupFileExtension = 'accbak';

  // ==========================================================
  // دالة مساعدة: الحصول على Encrypter مشفر باستخدام AES-256
  // ==========================================================
  Future<enc.Encrypter> _getEncrypter() async {
    // نحاول قراءة المفتاح و IV من التخزين الآمن
    String? keyString = await _secureStorage.read(key: _encryptionKeyStorageKey);
    String? ivString = await _secureStorage.read(key: _encryptionIvStorageKey);

    // إذا لم تكن المفاتيح موجودة (أول مرة يتم فيها تشغيل التطبيق)
    if (keyString == null || ivString == null) {
      // إنشاء مفتاح جديد (32 بايت = AES-256)
      final newKey = enc.Key.fromSecureRandom(32);
      // إنشاء IV جديد (16 بايت)
      final newIv = enc.IV.fromSecureRandom(16);

      // حفظ القيم في التخزين الآمن
      await _secureStorage.write(key: _encryptionKeyStorageKey, value: newKey.base64);
      await _secureStorage.write(key: _encryptionIvStorageKey, value: newIv.base64);

      keyString = newKey.base64;
      ivString = newIv.base64;
    }

    // إنشاء أداة التشفير باستخدام القيم المخزنة
    final key = enc.Key.fromBase64(keyString);
    final iv = enc.IV.fromBase64(ivString);

    // نستخدم AES بنمط CBC للتشفير القوي
    return enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
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
  // 🗂️ إنشاء ومشاركة نسخة احتياطية مشفرة
  // ← Hint: المنطق الجديد - حفظ في Downloads أولاً ثم المشاركة
  // ==========================================================
  Future<Map<String, dynamic>> createAndShareBackup() async {
    try {
      print("🔹 بدء إنشاء النسخة الاحتياطية...");

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

      // نضيف معرف مميز للملف لتمييزه كنسخة احتياطية لتطبيقنا
      final dataToEncrypt = Uint8List.fromList(
        _magicNumber.codeUnits + dbBytes,
      );

      // 🔸 إنشاء أداة التشفير
      final encrypter = await _getEncrypter();

      // التأكد من وجود IV أو إنشاؤه إذا مفقود
      String? ivBase64 = await _secureStorage.read(key: _encryptionIvStorageKey);
      if (ivBase64 == null || ivBase64.isEmpty) {
        final newIv = enc.IV.fromSecureRandom(16);
        ivBase64 = newIv.base64;
        await _secureStorage.write(key: _encryptionIvStorageKey, value: ivBase64);
      }

      final iv = enc.IV.fromBase64(ivBase64);

      // 🔸 تشفير البيانات
      print("🔹 تشفير البيانات...");
      final encryptedData = encrypter.encryptBytes(dataToEncrypt, iv: iv);

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
      await backupFile.writeAsBytes(encryptedData.bytes);

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
  // ♻️ استعادة البيانات من نسخة احتياطية مشفرة
  // ==========================================================
  Future<String> restoreBackup() async {
    try {
      print("🔹 بدء عملية استعادة النسخة الاحتياطية...");

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

      // قراءة محتوى الملف المشفر
      final encryptedBytes = await backupFile.readAsBytes();
      final encryptedData = enc.Encrypted(encryptedBytes);

      // 🔸 إنشاء أداة التشفير
      final encrypter = await _getEncrypter();

      // قراءة IV من التخزين الآمن (أو إنشاؤه إذا مفقود)
      String? ivBase64 = await _secureStorage.read(key: _encryptionIvStorageKey);
      if (ivBase64 == null || ivBase64.isEmpty) {
        throw Exception('مفتاح فك التشفير مفقود. لا يمكن استعادة النسخة.');
      }

      final iv = enc.IV.fromBase64(ivBase64);

      // 🔸 فك تشفير البيانات
      print("🔹 فك تشفير البيانات...");
      Uint8List decryptedBytes;
      try {
        final decryptedData = encrypter.decryptBytes(encryptedData, iv: iv);
        decryptedBytes = Uint8List.fromList(decryptedData);
      } catch (e) {
        throw Exception(
            'فشل فك التشفير. الملف قد يكون تالفًا أو لا يخص هذا التطبيق.');
      }

      // 🔸 التحقق من العلامة المميزة في بداية الملف
      if (decryptedBytes.length < _magicNumber.codeUnits.length ||
          String.fromCharCodes(
                  decryptedBytes.sublist(0, _magicNumber.codeUnits.length)) !=
              _magicNumber) {
        throw Exception('ملف النسخة الاحتياطية غير صالح أو لا يخص هذا التطبيق.');
      }

      // 🔸 استخراج بيانات قاعدة البيانات الفعلية بعد إزالة المعرف
      final dbData = decryptedBytes.sublist(_magicNumber.codeUnits.length);

      // 🔸 تحديد مكان قاعدة البيانات الأصلية واستبدالها بالنسخة الجديدة
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dbFolder.path, _dbFileName));
      await dbFile.writeAsBytes(dbData);

      print("✅ تم استعادة النسخة الاحتياطية بنجاح!");
      return 'نجاح';
    } catch (e) {
      print('❌ خطأ أثناء استعادة النسخة الاحتياطية: $e');
      return e.toString().replaceFirst("Exception: ", "");
    }
  }
}