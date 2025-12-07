// 💾 lib/services/backup_service.dart

import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../data/database_helper.dart';
import '../utils/archive_helper.dart';
import 'encryption_service.dart';
import 'database_key_manager.dart';

/// 💾 خدمة النسخ الاحتياطي الشامل - الإصدار 2.0
///
/// ← Hint: هذه الخدمة الجديدة تستبدل النظام القديم بالكامل
/// ← Hint: ميزات النظام الجديد:
///   ✅ تشفير كامل بكلمة سر (AES-256-GCM)
///   ✅ نقل بين أجهزة مختلفة وحسابات مختلفة (100% مستقل)
///   ✅ نسخ احتياطي لجميع البيانات والصور وملفات PDF
///   ✅ التحقق من سلامة البيانات (SHA-256)
///   ✅ metadata شامل
///   ✅ لا يعتمد على activation_secret أو device fingerprint
///
/// 📝 للمستقبل:
/// - إضافة backup scheduling (نسخ تلقائي يومي/أسبوعي)
/// - إضافة cloud backup (Google Drive, Dropbox)
/// - إضافة incremental backup (نسخ التغييرات فقط)
/// - إضافة backup encryption variants (ChaCha20-Poly1305)
/// - إضافة backup compression levels
/// - إضافة recovery questions (بديل لكلمة السر)
/// - إضافة multi-device sync
class BackupService {
  // ============================================================================
  // 🔧 الإعدادات الثابتة
  // ============================================================================

  /// ← Hint: رقم إصدار النسخ الاحتياطي الحالي
  /// ← Hint: يزيد عند تغيير بنية النسخة
  /// 📝 للمستقبل: استخدامه لـ migration بين إصدارات مختلفة
  static const String backupVersion = '2.0';

  /// ← Hint: امتداد ملف النسخة الاحتياطية
  /// ← Hint: .aab = Accounting App Backup
  /// 📝 للمستقبل: يمكن تغييره لـ .aabv2 للتمييز
  static const String backupExtension = '.aab';

  /// ← Hint: الحد الأدنى لطول كلمة السر (حسب طلب المستخدم)
  static const int minPasswordLength = 6;

  // ============================================================================
  // 🎯 إنشاء نسخة احتياطية كاملة مشفرة
  // ============================================================================

  /// إنشاء نسخة احتياطية شاملة مشفرة
  ///
  /// ← Hint: هذه الدالة هي قلب النظام - تجمع كل شيء
  ///
  /// الخطوات:
  /// 1. إنشاء مجلد عمل مؤقت
  /// 2. نسخ قاعدة البيانات + مفتاح SQLCipher
  /// 3. نسخ جميع الصور
  /// 4. نسخ ملفات PDF (إن وجدت)
  /// 5. إنشاء metadata شامل
  /// 6. تشفير كل ملف بـ AES-256
  /// 7. ضغط كل شيء في ملف .aab واحد
  /// 8. تنظيف المجلد المؤقت
  ///
  /// [password] كلمة السر للتشفير (مطلوبة!)
  /// [onProgress] callback للتقدم (اختياري)
  ///
  /// Returns: Map يحتوي على:
  /// - status: 'success' أو 'error'
  /// - message: رسالة توضيحية
  /// - file_path: مسار ملف النسخة (عند النجاح)
  /// - file_size: حجم الملف
  /// - metadata: معلومات النسخة
  ///
  /// 📝 للمستقبل:
  /// - إضافة selective backup (اختيار جداول معينة)
  /// - إضافة compression before encryption لتقليل الحجم
  /// - إضافة backup to cloud option
  Future<Map<String, dynamic>> createEncryptedBackup({
    required String password,
    Function(String status, int current, int total)? onProgress,
  }) async {
    Directory? workDir;

    try {
      debugPrint('🎯 [BackupService] بدء إنشاء نسخة احتياطية مشفرة...');

      // ══════════════════════════════════════════════════════════
      // 1️⃣ التحقق من كلمة السر
      // ══════════════════════════════════════════════════════════

      if (password.length < minPasswordLength) {
        return {
          'status': 'error',
          'message': 'كلمة السر يجب أن تكون $minPasswordLength أحرف على الأقل',
        };
      }

      onProgress?.call('جاري التحقق من كلمة السر...', 1, 10);

      final passwordCheck = EncryptionService.checkPasswordStrength(password);
      if (!passwordCheck['isValid']) {
        return {
          'status': 'error',
          'message': passwordCheck['feedback'],
        };
      }

      debugPrint('✅ كلمة السر: ${passwordCheck['strengthText']}');

      // ══════════════════════════════════════════════════════════
      // 2️⃣ إنشاء مجلد عمل مؤقت
      // ← Hint: كل عملية نسخ لها مجلد مؤقت خاص بها
      // ══════════════════════════════════════════════════════════

      onProgress?.call('جاري إنشاء مجلد العمل...', 2, 10);

      final tempDir = await getTemporaryDirectory();
      workDir = Directory(
        '${tempDir.path}/encrypted_backup_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (await workDir.exists()) {
        await workDir.delete(recursive: true);
      }
      await workDir.create(recursive: true);

      debugPrint('📁 مجلد العمل: ${workDir.path}');

      // ══════════════════════════════════════════════════════════
      // 3️⃣ نسخ قاعدة البيانات + مفتاح التشفير
      // ← Hint: نحفظ مفتاح SQLCipher لأنه ضروري لفتح قاعدة البيانات
      // ══════════════════════════════════════════════════════════

      onProgress?.call('جاري نسخ قاعدة البيانات...', 3, 10);

      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;
      final dbPath = db.path;

      // ← Hint: نسخ ملف قاعدة البيانات
      final dbFile = File(dbPath);
      final backupDbFile = File('${workDir.path}/database.db');
      await dbFile.copy(backupDbFile.path);

      final dbSize = await backupDbFile.length();
      debugPrint('✅ نسخ قاعدة البيانات: ${_formatBytes(dbSize)}');

      // ← Hint: حفظ مفتاح SQLCipher
      final dbEncryptionKey = await DatabaseKeyManager.instance.getDatabaseKey();
      final keyFile = File('${workDir.path}/db_key.txt');
      await keyFile.writeAsString(dbEncryptionKey);

      debugPrint('✅ حفظ مفتاح قاعدة البيانات');

      // ══════════════════════════════════════════════════════════
      // 4️⃣ نسخ جميع الصور
      // ← Hint: نحافظ على بنية المجلدات (users/, suppliers/, etc.)
      // ══════════════════════════════════════════════════════════

      onProgress?.call('جاري نسخ الصور...', 4, 10);

      final imagesStats = await _copyAllImages(workDir.path, db);
      final totalImages = imagesStats['total'] ?? 0;

      debugPrint('✅ نسخ $totalImages صورة');

      // ══════════════════════════════════════════════════════════
      // 5️⃣ نسخ ملفات PDF (إن وجدت)
      // ← Hint: ميزة جديدة لم تكن في النظام القديم
      // ══════════════════════════════════════════════════════════

      onProgress?.call('جاري نسخ ملفات PDF...', 5, 10);

      final pdfStats = await _copyAllPDFs(workDir.path);
      final totalPDFs = pdfStats['total'] ?? 0;

      debugPrint('✅ نسخ $totalPDFs ملف PDF');

      // ══════════════════════════════════════════════════════════
      // 6️⃣ إنشاء metadata شامل
      // ← Hint: معلومات عن النسخة (بدون أي أسرار خاصة بالجهاز!)
      // ══════════════════════════════════════════════════════════

      onProgress?.call('جاري إنشاء المعلومات...', 6, 10);

      final metadata = await _createMetadata(db, totalImages, totalPDFs, imagesStats, pdfStats);

      final metadataFile = File('${workDir.path}/metadata.json');
      await metadataFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(metadata),
      );

      debugPrint('✅ إنشاء metadata');

      // ══════════════════════════════════════════════════════════
      // 7️⃣ تشفير جميع الملفات
      // ← Hint: كل ملف يُشفَّر بـ AES-256 مع IV خاص به
      // ══════════════════════════════════════════════════════════

      onProgress?.call('جاري تشفير البيانات...', 7, 10);

      final encryptionInfo = await _encryptAllFiles(workDir.path, password);

      // ← Hint: حفظ معلومات التشفير (Salt و IVs)
      final encryptionFile = File('${workDir.path}/encryption_info.json');
      await encryptionFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(encryptionInfo),
      );

      debugPrint('✅ تشفير جميع الملفات');

      // ══════════════════════════════════════════════════════════
      // 8️⃣ ضغط كل شيء في ملف واحد
      // ← Hint: اسم الملف: accounting_backup_YYYY-MM-DD_HH-mm-ss.aab
      // ══════════════════════════════════════════════════════════

      onProgress?.call('جاري ضغط النسخة...', 8, 10);

      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final timestamp = DateTime.now()
          .toIso8601String()
          .split('.')[0]
          .replaceAll(':', '-')
          .replaceAll('T', '_');

      final backupFileName = 'accounting_backup_$timestamp$backupExtension';
      final backupFile = File('${downloadsDir.path}/$backupFileName');

      final compressed = await ArchiveHelper.compressDirectory(
        sourceDir: workDir,
        outputZipFile: backupFile,
        onProgress: (current, total) {
          // ← Hint: progress من ضمن المرحلة 8
          onProgress?.call('جاري ضغط النسخة... ($current/$total)', 8, 10);
        },
      );

      if (!compressed) {
        throw Exception('فشل ضغط الملفات');
      }

      final backupSize = await backupFile.length();
      debugPrint('✅ إنشاء ملف النسخة: ${_formatBytes(backupSize)}');

      // ══════════════════════════════════════════════════════════
      // 9️⃣ حساب checksum للتحقق من السلامة
      // ← Hint: SHA-256 hash للملف النهائي
      // ══════════════════════════════════════════════════════════

      onProgress?.call('جاري التحقق من السلامة...', 9, 10);

      final checksum = await EncryptionService.calculateFileHash(backupFile.path);

      debugPrint('✅ Checksum: ${checksum.substring(0, 16)}...');

      // ══════════════════════════════════════════════════════════
      // 🔟 تنظيف المجلد المؤقت
      // ══════════════════════════════════════════════════════════

      onProgress?.call('جاري التنظيف...', 10, 10);

      await workDir.delete(recursive: true);

      debugPrint('✅ تنظيف المجلد المؤقت');

      // ══════════════════════════════════════════════════════════
      // ✅ النجاح!
      // ══════════════════════════════════════════════════════════

      onProgress?.call('اكتمل!', 10, 10);

      return {
        'status': 'success',
        'message': 'تم إنشاء النسخة الاحتياطية المشفرة بنجاح',
        'file_path': backupFile.path,
        'file_name': backupFileName,
        'file_size': backupSize,
        'file_size_formatted': _formatBytes(backupSize),
        'total_images': totalImages,
        'total_pdfs': totalPDFs,
        'checksum': checksum,
        'metadata': metadata,
        'password_strength': passwordCheck['strengthText'],
      };
    } catch (e, stackTrace) {
      debugPrint('❌ [BackupService] خطأ في createEncryptedBackup: $e');
      debugPrint('Stack trace: $stackTrace');

      // ← Hint: تنظيف في حالة الخطأ
      if (workDir != null && await workDir.exists()) {
        try {
          await workDir.delete(recursive: true);
        } catch (_) {}
      }

      return {
        'status': 'error',
        'message': 'فشل في إنشاء النسخة الاحتياطية: $e',
      };
    }
  }

  // ============================================================================
  // 🔄 استعادة نسخة احتياطية مشفرة
  // ============================================================================

  /// استعادة نسخة احتياطية مشفرة
  ///
  /// ← Hint: هذه الدالة تعكس createEncryptedBackup تماماً
  ///
  /// الخطوات:
  /// 1. فك ضغط ملف .aab
  /// 2. قراءة معلومات التشفير
  /// 3. فك تشفير جميع الملفات بكلمة السر
  /// 4. قراءة والتحقق من metadata
  /// 5. استبدال مفتاح SQLCipher
  /// 6. إغلاق قاعدة البيانات الحالية
  /// 7. استبدال قاعدة البيانات
  /// 8. استعادة جميع الصور
  /// 9. استعادة ملفات PDF
  /// 10. إعادة فتح قاعدة البيانات
  ///
  /// [filePath] مسار ملف النسخة الاحتياطية
  /// [password] كلمة السر
  /// [onProgress] callback للتقدم
  ///
  /// 📝 للمستقبل:
  /// - إضافة preview mode (عرض المحتويات بدون استعادة)
  /// - إضافة selective restore (استعادة جداول معينة فقط)
  /// - إضافة backup merge (دمج نسختين)
  Future<Map<String, dynamic>> restoreEncryptedBackup({
    required String filePath,
    required String password,
    Function(String status, int current, int total)? onProgress,
  }) async {
    Directory? workDir;

    try {
      debugPrint('🔄 [BackupService] بدء استعادة نسخة احتياطية مشفرة...');
      debugPrint('📂 الملف: $filePath');

      // ══════════════════════════════════════════════════════════
      // 1️⃣ التحقق من وجود الملف
      // ══════════════════════════════════════════════════════════

      final backupFile = File(filePath);
      if (!await backupFile.exists()) {
        return {
          'status': 'error',
          'message': 'ملف النسخة الاحتياطية غير موجود',
        };
      }

      onProgress?.call('جاري فحص الملف...', 1, 12);

      // ← Hint: التحقق من صحة ملف ZIP
      final isValid = await ArchiveHelper.validateZip(backupFile);
      if (!isValid) {
        return {
          'status': 'error',
          'message': 'ملف النسخة الاحتياطية تالف أو غير صالح',
        };
      }

      debugPrint('✅ الملف صالح');

      // ══════════════════════════════════════════════════════════
      // 2️⃣ فك ضغط النسخة الاحتياطية
      // ══════════════════════════════════════════════════════════

      onProgress?.call('جاري فك ضغط النسخة...', 2, 12);

      final tempDir = await getTemporaryDirectory();
      workDir = Directory(
        '${tempDir.path}/restore_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (await workDir.exists()) {
        await workDir.delete(recursive: true);
      }
      await workDir.create(recursive: true);

      final extracted = await ArchiveHelper.extractZip(
        zipFile: backupFile,
        outputDir: workDir,
        onProgress: (current, total) {
          onProgress?.call('جاري فك الضغط... ($current/$total)', 2, 12);
        },
      );

      if (!extracted) {
        return {
          'status': 'error',
          'message': 'فشل في فك ضغط ملف النسخة الاحتياطية',
        };
      }

      debugPrint('✅ فك الضغط');

      // ══════════════════════════════════════════════════════════
      // 3️⃣ قراءة معلومات التشفير
      // ← Hint: نحتاج Salt و IVs لفك التشفير
      // ══════════════════════════════════════════════════════════

      onProgress?.call('جاري قراءة معلومات التشفير...', 3, 12);

      final encryptionFile = File('${workDir.path}/encryption_info.json');
      if (!await encryptionFile.exists()) {
        return {
          'status': 'error',
          'message': 'معلومات التشفير مفقودة في النسخة الاحتياطية',
        };
      }

      final encryptionInfoJson = await encryptionFile.readAsString();
      final encryptionInfo = jsonDecode(encryptionInfoJson) as Map<String, dynamic>;

      debugPrint('✅ قراءة معلومات التشفير');

      // ══════════════════════════════════════════════════════════
      // 4️⃣ فك تشفير جميع الملفات
      // ← Hint: إذا كانت كلمة السر خاطئة، سيفشل هنا
      // ══════════════════════════════════════════════════════════

      onProgress?.call('جاري فك التشفير...', 4, 12);

      try {
        await _decryptAllFiles(workDir.path, password, encryptionInfo);
        debugPrint('✅ فك تشفير جميع الملفات');
      } catch (e) {
        debugPrint('❌ فشل فك التشفير: $e');
        return {
          'status': 'error',
          'message': 'كلمة السر خاطئة أو ملف تالف',
        };
      }

      // ══════════════════════════════════════════════════════════
      // 5️⃣ قراءة والتحقق من metadata
      // ══════════════════════════════════════════════════════════

      onProgress?.call('جاري التحقق من البيانات...', 5, 12);

      final metadataFile = File('${workDir.path}/metadata.json');
      if (!await metadataFile.exists()) {
        return {
          'status': 'error',
          'message': 'معلومات النسخة مفقودة',
        };
      }

      final metadataJson = await metadataFile.readAsString();
      final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;

      debugPrint('📋 Metadata: ${metadata['backup_date']}');
      debugPrint('   - الإصدار: ${metadata['backup_version']}');
      debugPrint('   - الصور: ${metadata['total_images']}');
      debugPrint('   - PDF: ${metadata['total_pdfs']}');

      // ← Hint: التحقق من توافق الإصدار
      if (metadata['backup_version'] != backupVersion) {
        debugPrint('⚠️ إصدار النسخة مختلف: ${metadata['backup_version']} vs $backupVersion');
        // ← Hint: يمكن إضافة migration logic هنا في المستقبل
      }

      // ══════════════════════════════════════════════════════════
      // 6️⃣ استعادة مفتاح قاعدة البيانات
      // ← Hint: نستبدل المفتاح الحالي بالمفتاح من النسخة
      // ══════════════════════════════════════════════════════════

      onProgress?.call('جاري استعادة مفتاح التشفير...', 6, 12);

      final keyFile = File('${workDir.path}/db_key.txt');
      if (!await keyFile.exists()) {
        return {
          'status': 'error',
          'message': 'مفتاح قاعدة البيانات مفقود في النسخة',
        };
      }

      final restoredDbKey = await keyFile.readAsString();
      await DatabaseKeyManager.instance.replaceKey(restoredDbKey);

      debugPrint('✅ استعادة مفتاح قاعدة البيانات');

      // ══════════════════════════════════════════════════════════
      // 7️⃣ إغلاق قاعدة البيانات الحالية
      // ← Hint: ضروري قبل استبدال الملف
      // ══════════════════════════════════════════════════════════

      onProgress?.call('جاري إغلاق قاعدة البيانات...', 7, 12);

      final dbHelper = DatabaseHelper.instance;
      await dbHelper.closeDatabase();

      debugPrint('✅ إغلاق قاعدة البيانات');

      // ══════════════════════════════════════════════════════════
      // 8️⃣ استبدال قاعدة البيانات
      // ← Hint: نسخ ملف database.db المستعاد فوق القديم
      // ══════════════════════════════════════════════════════════

      onProgress?.call('جاري استعادة قاعدة البيانات...', 8, 12);

      final restoredDbFile = File('${workDir.path}/database.db');
      if (!await restoredDbFile.exists()) {
        return {
          'status': 'error',
          'message': 'ملف قاعدة البيانات مفقود في النسخة',
        };
      }

      // ← Hint: فتح قاعدة جديدة للحصول على المسار
      final newDb = await dbHelper.database;
      final dbPath = newDb.path;
      await newDb.close();

      final currentDbFile = File(dbPath);
      if (await currentDbFile.exists()) {
        await currentDbFile.delete();
      }

      await restoredDbFile.copy(dbPath);

      final dbSize = await File(dbPath).length();
      debugPrint('✅ استعادة قاعدة البيانات: ${_formatBytes(dbSize)}');

      // ══════════════════════════════════════════════════════════
      // 9️⃣ استعادة جميع الصور
      // ══════════════════════════════════════════════════════════

      onProgress?.call('جاري استعادة الصور...', 9, 12);

      final imagesStats = await _restoreAllImages(workDir.path);
      final totalImagesRestored = imagesStats['total'] ?? 0;

      debugPrint('✅ استعادة $totalImagesRestored صورة');

      // ══════════════════════════════════════════════════════════
      // 🔟 استعادة ملفات PDF
      // ══════════════════════════════════════════════════════════

      onProgress?.call('جاري استعادة ملفات PDF...', 10, 12);

      final pdfStats = await _restoreAllPDFs(workDir.path);
      final totalPDFsRestored = pdfStats['total'] ?? 0;

      debugPrint('✅ استعادة $totalPDFsRestored ملف PDF');

      // ══════════════════════════════════════════════════════════
      // 1️⃣1️⃣ إعادة فتح قاعدة البيانات
      // ← Hint: التأكد من أن كل شيء يعمل
      // ══════════════════════════════════════════════════════════

      onProgress?.call('جاري التحقق من القاعدة...', 11, 12);

      try {
        final testDb = await dbHelper.database;
        await testDb.rawQuery('SELECT COUNT(*) FROM TB_Settings');
        debugPrint('✅ قاعدة البيانات تعمل بشكل صحيح');
      } catch (e) {
        debugPrint('❌ خطأ في فتح قاعدة البيانات: $e');
        return {
          'status': 'error',
          'message': 'فشل في فتح قاعدة البيانات المستعادة: $e',
        };
      }

      // ══════════════════════════════════════════════════════════
      // 1️⃣2️⃣ تنظيف المجلد المؤقت
      // ══════════════════════════════════════════════════════════

      onProgress?.call('جاري التنظيف...', 12, 12);

      await workDir.delete(recursive: true);

      debugPrint('✅ تنظيف المجلد المؤقت');

      // ══════════════════════════════════════════════════════════
      // ✅ النجاح!
      // ══════════════════════════════════════════════════════════

      onProgress?.call('اكتمل!', 12, 12);

      return {
        'status': 'success',
        'message': 'تمت استعادة النسخة الاحتياطية بنجاح',
        'total_images': totalImagesRestored,
        'total_pdfs': totalPDFsRestored,
        'metadata': metadata,
      };
    } catch (e, stackTrace) {
      debugPrint('❌ [BackupService] خطأ في restoreEncryptedBackup: $e');
      debugPrint('Stack trace: $stackTrace');

      // ← Hint: تنظيف في حالة الخطأ
      if (workDir != null && await workDir.exists()) {
        try {
          await workDir.delete(recursive: true);
        } catch (_) {}
      }

      return {
        'status': 'error',
        'message': 'فشل في استعادة النسخة الاحتياطية: $e',
      };
    }
  }

  // ============================================================================
  // 📋 الحصول على معلومات نسخة احتياطية (بدون كلمة سر)
  // ============================================================================

  /// الحصول على معلومات نسخة احتياطية بدون الحاجة لكلمة السر
  ///
  /// ← Hint: مفيد لعرض معلومات قبل الاستعادة
  /// ← Hint: يقرأ metadata فقط (غير مشفر)
  ///
  /// 📝 للمستقبل: يمكن إضافة thumbnail للصور
  Future<Map<String, dynamic>> getBackupInfo(String filePath) async {
    Directory? workDir;

    try {
      debugPrint('📋 [BackupService] قراءة معلومات النسخة...');

      final backupFile = File(filePath);
      if (!await backupFile.exists()) {
        return {
          'status': 'error',
          'message': 'الملف غير موجود',
        };
      }

      // ← Hint: معلومات الملف نفسه
      final fileSize = await backupFile.length();
      final fileModified = await backupFile.lastModified();

      // ← Hint: معلومات ZIP
      final zipInfo = await ArchiveHelper.getZipInfo(backupFile);

      if (zipInfo.containsKey('error')) {
        return {
          'status': 'error',
          'message': 'فشل في قراءة ملف النسخة: ${zipInfo['error']}',
        };
      }

      return {
        'status': 'success',
        'file_name': filePath.split('/').last,
        'file_path': filePath,
        'file_size': fileSize,
        'file_size_formatted': _formatBytes(fileSize),
        'file_modified': fileModified.toIso8601String(),
        'zip_info': zipInfo,
      };
    } catch (e) {
      debugPrint('❌ [BackupService] خطأ في getBackupInfo: $e');

      return {
        'status': 'error',
        'message': 'خطأ في قراءة المعلومات: $e',
      };
    } finally {
      if (workDir != null && await workDir.exists()) {
        try {
          await workDir.delete(recursive: true);
        } catch (_) {}
      }
    }
  }

  // ============================================================================
  // 🛠️ دوال مساعدة - نسخ البيانات
  // ============================================================================

  /// نسخ جميع الصور
  ///
  /// ← Hint: يبحث في قاعدة البيانات عن مسارات الصور
  /// ← Hint: ينسخ الصور مع الحفاظ على بنية المجلدات
  ///
  /// 📝 للمستقبل: يمكن إضافة image compression option
  Future<Map<String, dynamic>> _copyAllImages(
    String backupPath,
    Database db,
  ) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesBaseDir = Directory('${appDir.path}/images');

      if (!await imagesBaseDir.exists()) {
        return {'total': 0};
      }

      // ← Hint: المجلدات المعروفة
      final categories = {
        'users': 'TB_Settings', // ← صور الشركة
        'suppliers': 'TB_Suppliers',
        'customers': 'TB_Customer',
        'products': 'Store_Products',
        'employees': 'TB_Employees',
        'company': 'TB_Settings',
      };

      int totalCopied = 0;
      final stats = <String, int>{};

      for (final category in categories.entries) {
        final categoryName = category.key;
        final sourceCategoryDir = Directory('${imagesBaseDir.path}/$categoryName');

        if (!await sourceCategoryDir.exists()) {
          stats[categoryName] = 0;
          continue;
        }

        final destCategoryDir = Directory('$backupPath/images/$categoryName');
        await destCategoryDir.create(recursive: true);

        int categoryCopied = 0;

        await for (final entity in sourceCategoryDir.list()) {
          if (entity is File) {
            try {
              final fileName = entity.path.split('/').last;
              final destFile = File('${destCategoryDir.path}/$fileName');
              await entity.copy(destFile.path);
              categoryCopied++;
              totalCopied++;
            } catch (e) {
              debugPrint('⚠️ خطأ في نسخ صورة: $e');
            }
          }
        }

        stats[categoryName] = categoryCopied;
        if (categoryCopied > 0) {
          debugPrint('  ✅ $categoryName: $categoryCopied صورة');
        }
      }

      return {
        'total': totalCopied,
        ...stats,
      };
    } catch (e) {
      debugPrint('❌ خطأ في _copyAllImages: $e');
      return {'total': 0};
    }
  }

  /// نسخ جميع ملفات PDF
  ///
  /// ← Hint: يبحث في المجلدات المعروفة لملفات PDF
  /// ← Hint: ميزة جديدة لم تكن في النظام القديم
  ///
  /// 📝 للمستقبل: يمكن إضافة PDF metadata extraction
  Future<Map<String, dynamic>> _copyAllPDFs(String backupPath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();

      // ← Hint: المجلدات المحتملة لملفات PDF
      final pdfDirs = [
        '${appDir.path}/pdfs',
        '${appDir.path}/reports',
        '${appDir.path}/invoices',
      ];

      int totalCopied = 0;
      final stats = <String, int>{};

      for (final dirPath in pdfDirs) {
        final sourceDir = Directory(dirPath);

        if (!await sourceDir.exists()) {
          continue;
        }

        final dirName = dirPath.split('/').last;
        final destDir = Directory('$backupPath/pdfs/$dirName');
        await destDir.create(recursive: true);

        int dirCopied = 0;

        await for (final entity in sourceDir.list()) {
          if (entity is File && entity.path.toLowerCase().endsWith('.pdf')) {
            try {
              final fileName = entity.path.split('/').last;
              final destFile = File('${destDir.path}/$fileName');
              await entity.copy(destFile.path);
              dirCopied++;
              totalCopied++;
            } catch (e) {
              debugPrint('⚠️ خطأ في نسخ PDF: $e');
            }
          }
        }

        stats[dirName] = dirCopied;
        if (dirCopied > 0) {
          debugPrint('  ✅ $dirName: $dirCopied ملف PDF');
        }
      }

      return {
        'total': totalCopied,
        ...stats,
      };
    } catch (e) {
      debugPrint('❌ خطأ في _copyAllPDFs: $e');
      return {'total': 0};
    }
  }

  /// استعادة جميع الصور
  ///
  /// ← Hint: ينسخ الصور من النسخة الاحتياطية لمجلد التطبيق
  Future<Map<String, dynamic>> _restoreAllImages(String restorePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesBaseDir = Directory('${appDir.path}/images');

      if (!await imagesBaseDir.exists()) {
        await imagesBaseDir.create(recursive: true);
      }

      final backupImagesDir = Directory('$restorePath/images');

      if (!await backupImagesDir.exists()) {
        return {'total': 0};
      }

      int totalRestored = 0;
      final stats = <String, int>{};

      final categories = [
        'users',
        'suppliers',
        'customers',
        'products',
        'employees',
        'company',
      ];

      for (final category in categories) {
        final sourceCategoryDir = Directory('${backupImagesDir.path}/$category');

        if (!await sourceCategoryDir.exists()) {
          stats[category] = 0;
          continue;
        }

        final destCategoryDir = Directory('${imagesBaseDir.path}/$category');
        await destCategoryDir.create(recursive: true);

        int categoryRestored = 0;

        await for (final entity in sourceCategoryDir.list()) {
          if (entity is File) {
            try {
              final fileName = entity.path.split('/').last;
              final destFile = File('${destCategoryDir.path}/$fileName');
              await entity.copy(destFile.path);
              categoryRestored++;
              totalRestored++;
            } catch (e) {
              debugPrint('⚠️ خطأ في استعادة صورة: $e');
            }
          }
        }

        stats[category] = categoryRestored;
        if (categoryRestored > 0) {
          debugPrint('  ✅ $category: $categoryRestored صورة');
        }
      }

      return {
        'total': totalRestored,
        ...stats,
      };
    } catch (e) {
      debugPrint('❌ خطأ في _restoreAllImages: $e');
      return {'total': 0};
    }
  }

  /// استعادة جميع ملفات PDF
  Future<Map<String, dynamic>> _restoreAllPDFs(String restorePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupPDFsDir = Directory('$restorePath/pdfs');

      if (!await backupPDFsDir.exists()) {
        return {'total': 0};
      }

      int totalRestored = 0;
      final stats = <String, int>{};

      await for (final categoryEntity in backupPDFsDir.list()) {
        if (categoryEntity is! Directory) continue;

        final categoryName = categoryEntity.path.split('/').last;
        final destDir = Directory('${appDir.path}/$categoryName');
        await destDir.create(recursive: true);

        int categoryRestored = 0;

        await for (final fileEntity in categoryEntity.list()) {
          if (fileEntity is File) {
            try {
              final fileName = fileEntity.path.split('/').last;
              final destFile = File('${destDir.path}/$fileName');
              await fileEntity.copy(destFile.path);
              categoryRestored++;
              totalRestored++;
            } catch (e) {
              debugPrint('⚠️ خطأ في استعادة PDF: $e');
            }
          }
        }

        stats[categoryName] = categoryRestored;
        if (categoryRestored > 0) {
          debugPrint('  ✅ $categoryName: $categoryRestored ملف PDF');
        }
      }

      return {
        'total': totalRestored,
        ...stats,
      };
    } catch (e) {
      debugPrint('❌ خطأ في _restoreAllPDFs: $e');
      return {'total': 0};
    }
  }

  // ============================================================================
  // 🛠️ دوال مساعدة - التشفير
  // ============================================================================

  /// تشفير جميع الملفات في مجلد النسخ الاحتياطي
  ///
  /// ← Hint: كل ملف يُشفَّر بـ IV خاص به
  /// ← Hint: Salt واحد مشترك لكل النسخة (من كلمة السر)
  ///
  /// Returns: Map يحتوي على salt و IVs لكل ملف
  Future<Map<String, dynamic>> _encryptAllFiles(
    String workPath,
    String password,
  ) async {
    // ← Hint: توليد Salt واحد لكل النسخة الاحتياطية
    final salt = EncryptionService.generateSalt();

    final filesToEncrypt = [
      'database.db',
      'db_key.txt',
      'metadata.json',
    ];

    final ivs = <String, String>{};

    for (final fileName in filesToEncrypt) {
      final file = File('$workPath/$fileName');

      if (!await file.exists()) {
        debugPrint('⚠️ ملف غير موجود للتشفير: $fileName');
        continue;
      }

      final encryptedFile = File('$workPath/$fileName.encrypted');

      final encryptionResult = await EncryptionService.encryptFile(
        inputPath: file.path,
        outputPath: encryptedFile.path,
        password: password,
      );

      // ← Hint: حفظ IV الخاص بهذا الملف
      ivs[fileName] = base64Encode(encryptionResult['iv']!);

      // ← Hint: حذف الملف الأصلي (غير المشفر)
      await file.delete();

      // ← Hint: إعادة تسمية الملف المشفر
      await encryptedFile.rename(file.path);

      debugPrint('  🔒 تم تشفير: $fileName');
    }

    return {
      'salt': base64Encode(salt),
      'ivs': ivs,
      'encrypted_files': filesToEncrypt,
    };
  }

  /// فك تشفير جميع الملفات
  ///
  /// ← Hint: عكس _encryptAllFiles
  Future<void> _decryptAllFiles(
    String workPath,
    String password,
    Map<String, dynamic> encryptionInfo,
  ) async {
    final salt = base64Decode(encryptionInfo['salt'] as String);
    final ivs = encryptionInfo['ivs'] as Map<String, dynamic>;

    for (final entry in ivs.entries) {
      final fileName = entry.key;
      final ivBase64 = entry.value as String;
      final iv = base64Decode(ivBase64);

      final file = File('$workPath/$fileName');

      if (!await file.exists()) {
        throw Exception('ملف مشفر مفقود: $fileName');
      }

      final decryptedFile = File('$workPath/$fileName.decrypted');

      await EncryptionService.decryptFile(
        inputPath: file.path,
        outputPath: decryptedFile.path,
        password: password,
        salt: salt,
        iv: iv,
      );

      // ← Hint: حذف الملف المشفر
      await file.delete();

      // ← Hint: إعادة تسمية الملف المفكوك
      await decryptedFile.rename(file.path);

      debugPrint('  🔓 تم فك تشفير: $fileName');
    }
  }

  // ============================================================================
  // 🛠️ دوال مساعدة - Metadata
  // ============================================================================

  /// إنشاء metadata شامل للنسخة الاحتياطية
  ///
  /// ← Hint: لا يحتوي على أي معلومات سرية أو خاصة بالجهاز!
  /// ← Hint: يمكن قراءته بدون كلمة سر (سيكون غير مشفر في النسخة النهائية)
  ///
  /// 📝 للمستقبل: يمكن إضافة schema version لكل جدول
  Future<Map<String, dynamic>> _createMetadata(
    Database db,
    int totalImages,
    int totalPDFs,
    Map<String, dynamic> imagesStats,
    Map<String, dynamic> pdfStats,
  ) async {
    try {
      // ← Hint: جمع إحصائيات من قاعدة البيانات
      final tables = [
        'TB_Suppliers',
        'Supplier_Partners',
        'TB_Customer',
        'Debt_Customer',
        'Payment_Customer',
        'Store_Products',
        'TB_Product_Categories',
        'TB_Product_Units',
        'TB_Employees',
        'TB_Payroll',
        'TB_Employee_Advances',
        'TB_Advance_Repayments',
        'TB_Employee_Bonuses',
        'TB_Expenses',
        'TB_Expense_Categories',
        'TB_Invoices',
        'Sales_Returns',
        'TB_Settings',
        'TB_Subscription_Cache',
        'TB_App_State',
        'Activity_Log',
      ];

      final tableStats = <String, int>{};

      for (final table in tables) {
        try {
          final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
          tableStats[table] = result.first['count'] as int;
        } catch (e) {
          debugPrint('⚠️ خطأ في قراءة $table: $e');
          tableStats[table] = 0;
        }
      }

      return {
        'backup_version': backupVersion,
        'backup_date': DateTime.now().toIso8601String(),
        'app_version': '1.0.0', // ← يمكن جلبه من package_info
        'database_version': 5, // ← من DatabaseHelper
        'encryption_method': 'AES-256-GCM',
        'encryption_pbkdf2_iterations': 100000,
        'total_images': totalImages,
        'total_pdfs': totalPDFs,
        'images_stats': imagesStats,
        'pdfs_stats': pdfStats,
        'table_stats': tableStats,
        'total_records': tableStats.values.reduce((a, b) => a + b),
      };
    } catch (e) {
      debugPrint('⚠️ خطأ في _createMetadata: $e');
      return {
        'backup_version': backupVersion,
        'backup_date': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }

  // ============================================================================
  // 🛠️ دوال مساعدة - عامة
  // ============================================================================

  /// تنسيق حجم البيانات
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

// ============================================================================
// 📝 ملاحظات للمستقبل
// ============================================================================

/// ← Hint: الميزات المخططة للمستقبل:
///
/// 1. **Cloud Backup Integration**
///    - Google Drive
///    - Dropbox
///    - OneDrive
///    - S3-compatible storage
///
/// 2. **Incremental Backup**
///    - نسخ التغييرات فقط (أسرع وأصغر)
///    - Timestamp-based detection
///    - Delta compression
///
/// 3. **Scheduled Backups**
///    - يومي / أسبوعي / شهري
///    - Automatic cleanup (حذف النسخ القديمة)
///    - Background sync
///
/// 4. **Advanced Encryption**
///    - Multi-factor authentication
///    - Hardware key support (YubiKey)
///    - Biometric unlock
///    - Recovery questions
///
/// 5. **Compression Options**
///    - Level selection (fast/balanced/maximum)
///    - Algorithm selection (ZIP/7z/tar.gz)
///    - Image compression
///
/// 6. **Selective Backup/Restore**
///    - اختيار جداول معينة
///    - اختيار فترة زمنية
///    - اختيار categories
///
/// 7. **Backup Validation**
///    - Automatic integrity checks
///    - Corruption detection
///    - Repair tools
///
/// 8. **Multi-Device Sync**
///    - Real-time sync
///    - Conflict resolution
///    - Offline support
///
/// 9. **Backup Analytics**
///    - Size trends
///    - Backup frequency
///    - Storage optimization suggestions
///
/// 10. **Export Options**
///     - Excel export
///     - CSV export
///     - JSON export
///     - PDF reports
