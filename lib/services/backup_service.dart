// 📁 lib/services/backup_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  // 🗂️ إنشاء ومشاركة نسخة احتياطية مشفرة
  // ==========================================================
  Future<String> createAndShareBackup() async {
    try {
      print("🔹 بدء إنشاء النسخة الاحتياطية...");

      // 🔸 الحصول على مجلد قاعدة البيانات
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dbFolder.path, _dbFileName));

      // تحقق من وجود قاعدة البيانات
      if (!await dbFile.exists()) {
        print("⚠️ ملف قاعدة البيانات غير موجود في: ${dbFile.path}");
        return 'ملف قاعدة البيانات غير موجود.';
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

      // 🔸 تحديد مكان مؤقت لحفظ الملف قبل المشاركة
      final tempDir = await getTemporaryDirectory();
      final backupFileName =
          'backup-${DateTime.now().toIso8601String().replaceAll(":", "-")}.$_backupFileExtension';

      final backupFile = File(p.join(tempDir.path, backupFileName));

      // كتابة البيانات المشفرة داخل الملف
      await backupFile.writeAsBytes(encryptedData.bytes);

      print("✅ تم إنشاء الملف بنجاح في: ${backupFile.path}");

      // 🔸 مشاركة النسخة الاحتياطية مع المستخدم (WhatsApp, Email, Drive...)
      final result = await Share.shareXFiles(
        [XFile(backupFile.path)],
        text: '📦 ملف النسخة الاحتياطية لتطبيق المحاسبة',
      );

      // 🔸 النتيجة النهائية
      if (result.status == ShareResultStatus.success) {
        print("✅ تم إنشاء ومشاركة النسخة الاحتياطية بنجاح!");
        return 'نجاح';
      } else {
        print("ℹ️ تم إلغاء المشاركة من قبل المستخدم.");
        return 'تم إلغاء المشاركة.';
      }
    } catch (e) {
      // طباعة الخطأ في الـ Console لتتبع المشكلة
      print('❌ خطأ أثناء إنشاء النسخة الاحتياطية: $e');
      return 'حدث خطأ غير متوقع أثناء إنشاء النسخة الاحتياطية.\nتفاصيل: $e';
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
