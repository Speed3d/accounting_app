// 📁 lib/services/backup_service.dart

import 'dart:io';
import 'dart:convert';
import 'package:accountant_touch/services/firebase_service.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../utils/archive_helper.dart';
import '../data/database_helper.dart';
import 'database_key_manager.dart';

/// 🎯 نظام النسخ الاحتياطي البسيط
///
/// ✅ بدون كلمة سر
/// ✅ بدون backup_magic_number
/// ✅ بدون تشفير AES إضافي
/// ✅ يستخدم فقط activation_secret و time_validation_secret
///
/// البنية:
/// - قاعدة البيانات SQLite (مع تشفير SQLCipher الداخلي)
/// - جميع الصور منظمة في مجلدات
/// - metadata.json للمعلومات الأساسية
class BackupService {
  // ============================================================================
  // 🚀 إنشاء نسخة احتياطية بسيطة
  // ============================================================================

  /// إنشاء نسخة احتياطية بسيطة - بدون تشفير إضافي
  Future<Map<String, dynamic>> createSimpleBackup({
    Function(String status, int current, int total)? onProgress,
  }) async {
    try {
      debugPrint('🎯 [BackupService] بدء إنشاء نسخة احتياطية بسيطة...');

      // 1️⃣ إنشاء مجلد مؤقت للعمل
      final tempDir = await getTemporaryDirectory();
      final backupWorkDir = Directory(
        '${tempDir.path}/simple_backup_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (await backupWorkDir.exists()) {
        await backupWorkDir.delete(recursive: true);
      }
      await backupWorkDir.create(recursive: true);

      onProgress?.call('جاري تحضير المجلدات...', 1, 6);

      // 2️⃣ نسخ قاعدة البيانات
      debugPrint('📦 [BackupService] نسخ قاعدة البيانات...');
      onProgress?.call('جاري نسخ قاعدة البيانات...', 2, 6);

      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;
      final dbPath = db.path;

      final dbFile = File(dbPath);
      final backupDbFile = File('${backupWorkDir.path}/database.db');
      await dbFile.copy(backupDbFile.path);

      debugPrint('✅ [BackupService] تم نسخ قاعدة البيانات');

      // 3️⃣ نسخ جميع الصور
      debugPrint('🖼️ [BackupService] جمع جميع الصور...');
      onProgress?.call('جاري نسخ الصور...', 3, 6);

      final imagesStats = await _collectAllImages(backupWorkDir.path, db);
      final totalImages = imagesStats['total'] ?? 0;

      debugPrint('✅ [BackupService] تم نسخ $totalImages صورة');

      // 4️⃣ إنشاء metadata.json
      debugPrint('📋 [BackupService] إنشاء metadata...');
      onProgress?.call('جاري إنشاء معلومات النسخة...', 4, 6);

      // ← Hint: الحصول على مفتاح التشفير لحفظه مع النسخة
      final dbKey = await DatabaseKeyManager.instance.getDatabaseKey();

      final metadata = await _createSimpleMetadata(db, totalImages, imagesStats, dbKey);
      final metadataFile = File('${backupWorkDir.path}/metadata.json');
      await metadataFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(metadata),
      );

      debugPrint('✅ [BackupService] تم إنشاء metadata');

      // 5️⃣ ضغط كل شيء في ZIP
      debugPrint('🗜️ [BackupService] ضغط النسخة الاحتياطية...');
      onProgress?.call('جاري ضغط الملفات...', 5, 6);

      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final timestamp = DateTime.now()
          .toIso8601String()
          .split('.')[0]
          .replaceAll(':', '-');
      final zipFileName = 'accounting_backup_$timestamp.zip';
      final zipFile = File('${downloadsDir.path}/$zipFileName');

      final compressed = await ArchiveHelper.compressDirectory(
        sourceDir: backupWorkDir,
        outputZipFile: zipFile,
      );

      if (!compressed) {
        throw Exception('فشل ضغط الملفات');
      }

      final zipSize = await zipFile.length();
      debugPrint('✅ [BackupService] تم إنشاء ملف ZIP: ${zipFile.path}');

      // 6️⃣ تنظيف المجلد المؤقت
      await backupWorkDir.delete(recursive: true);

      onProgress?.call('اكتمل!', 6, 6);

      return {
        'status': 'success',
        'message': 'تم إنشاء النسخة الاحتياطية بنجاح',
        'file_path': zipFile.path,
        'file_size': zipSize,
        'file_size_formatted': _formatBytes(zipSize),
        'total_images': totalImages,
        'metadata': metadata,
      };
    } catch (e, stackTrace) {
      debugPrint('❌ [BackupService] خطأ في createSimpleBackup: $e');
      debugPrint('Stack trace: $stackTrace');
      return {
        'status': 'error',
        'message': 'فشل في إنشاء النسخة الاحتياطية: $e',
      };
    }
  }

  // ============================================================================
  // 🔄 استعادة نسخة احتياطية بسيطة
  // ============================================================================

  /// استعادة نسخة احتياطية بسيطة مع خيار دمج المستخدمين
  Future<Map<String, dynamic>> restoreSimpleBackup({
    required String filePath,
    required bool mergeUsers,
    Function(String status, int current, int total)? onProgress,
  }) async {
    Directory? tempRestoreDir;

    try {
      debugPrint('🎯 [BackupService] بدء استعادة نسخة احتياطية بسيطة...');
      debugPrint('📂 [BackupService] ملف النسخة: $filePath');
      debugPrint('👥 [BackupService] دمج المستخدمين: $mergeUsers');

      final zipFile = File(filePath);
      if (!await zipFile.exists()) {
        return {
          'status': 'error',
          'message': 'ملف النسخة الاحتياطية غير موجود',
        };
      }

      onProgress?.call('جاري فك ضغط النسخة...', 1, 8);

      // 1️⃣ فك ضغط ZIP
      final tempDir = await getTemporaryDirectory();
      tempRestoreDir = Directory(
        '${tempDir.path}/simple_restore_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (await tempRestoreDir.exists()) {
        await tempRestoreDir.delete(recursive: true);
      }
      await tempRestoreDir.create(recursive: true);

      debugPrint('📦 [BackupService] فك ضغط الملف...');
      final extracted = await ArchiveHelper.extractZip(
        zipFile: zipFile,
        outputDir: tempRestoreDir,
      );

      if (!extracted) {
        return {
          'status': 'error',
          'message': 'فشل في فك ضغط ملف النسخة الاحتياطية',
        };
      }

      // 2️⃣ قراءة والتحقق من metadata
      onProgress?.call('جاري التحقق من البيانات...', 2, 8);

      final metadataFile = File('${tempRestoreDir.path}/metadata.json');
      if (!await metadataFile.exists()) {
        return {
          'status': 'error',
          'message': 'ملف metadata.json غير موجود في النسخة الاحتياطية',
        };
      }

      final metadataContent = await metadataFile.readAsString();
      final metadata = jsonDecode(metadataContent) as Map<String, dynamic>;

      debugPrint('📋 [BackupService] معلومات النسخة: $metadata');

      // ═══════════════════════════════════════════════════════════
      // 3️⃣ تم إلغاء التحقق من activation_secret و time_validation_secret
      // ═══════════════════════════════════════════════════════════
      // ← Hint: تم إزالة التحقق من الأسرار لإتاحة النسخ الاحتياطي بين الأجهزة
      // ← Hint: السبب: كل جهاز له activation_secret فريد
      // ← Hint: الحل: الاعتماد فقط على db_encryption_key المحفوظ في النسخة
      // ← Hint: هذا يسمح بـ:
      //         1. نقل النسخة بين أجهزة مختلفة ✅
      //         2. استعادة النسخة بعد حذف التطبيق وإعادة تثبيته ✅
      //         3. مشاركة النسخة مع مستخدمين آخرين ✅
      // ═══════════════════════════════════════════════════════════

      debugPrint('✅ [BackupService] تم تخطي التحقق من الأسرار (للتوافق بين الأجهزة)');

      // 4️⃣ استعادة مفتاح التشفير من النسخة الاحتياطية
      onProgress?.call('جاري استعادة مفتاح التشفير...', 3, 8);

      final restoredKey = metadata['db_encryption_key'] as String?;
      if (restoredKey == null || restoredKey.isEmpty) {
        return {
          'status': 'error',
          'message': 'مفتاح التشفير غير موجود في النسخة الاحتياطية',
        };
      }

      // ← Hint: استبدال المفتاح الحالي بالمفتاح من النسخة الاحتياطية
      await DatabaseKeyManager.instance.replaceKey(restoredKey);
      debugPrint('✅ [BackupService] تم استعادة مفتاح التشفير');

      // 5️⃣ نسخ احتياطي للمستخدمين الحاليين (إذا كان mergeUsers = true)
      List<Map<String, dynamic>>? currentUsers;
      if (mergeUsers) {
        onProgress?.call('جاري حفظ المستخدمين الحاليين...', 4, 8);

        final dbHelper = DatabaseHelper.instance;
        final db = await dbHelper.database;
        currentUsers = await db.query('TB_Users');
        debugPrint(
            '👥 [BackupService] تم حفظ ${currentUsers.length} مستخدمين حاليين');
      }

      // 6️⃣ إغلاق قاعدة البيانات الحالية
      onProgress?.call('جاري إغلاق قاعدة البيانات...', 5, 8);

      final dbHelper = DatabaseHelper.instance;
      await dbHelper.closeDatabase();
      debugPrint('✅ [BackupService] تم إغلاق قاعدة البيانات');

      // 7️⃣ استبدال قاعدة البيانات
      onProgress?.call('جاري استعادة قاعدة البيانات...', 6, 8);

      final restoredDbFile = File('${tempRestoreDir.path}/database.db');
      if (!await restoredDbFile.exists()) {
        return {
          'status': 'error',
          'message': 'ملف قاعدة البيانات غير موجود في النسخة الاحتياطية',
        };
      }

      final currentDb = await dbHelper.database;
      final currentDbPath = currentDb.path;
      await currentDb.close();

      final currentDbFile = File(currentDbPath);
      if (await currentDbFile.exists()) {
        await currentDbFile.delete();
      }

      await restoredDbFile.copy(currentDbPath);
      debugPrint('✅ [BackupService] تم استعادة قاعدة البيانات');

      // 8️⃣ دمج المستخدمين (إذا طُلب ذلك)
      if (mergeUsers && currentUsers != null && currentUsers.isNotEmpty) {
        onProgress?.call('جاري دمج المستخدمين...', 7, 8);

        final newDb = await dbHelper.database;
        int mergedCount = 0;

        for (final user in currentUsers) {
          try {
            // التحقق من عدم وجود المستخدم (بناءً على الإيميل)
            final email = user['email'] as String?;
            if (email != null && email.isNotEmpty) {
              final existing = await newDb.query(
                'TB_Users',
                where: 'email = ?',
                whereArgs: [email],
              );

              if (existing.isEmpty) {
                // المستخدم غير موجود، نضيفه
                await newDb.insert('TB_Users', user);
                mergedCount++;
                debugPrint('✅ [BackupService] تم دمج المستخدم: $email');
              } else {
                debugPrint('⏭️ [BackupService] المستخدم موجود مسبقاً: $email');
              }
            }
          } catch (e) {
            debugPrint('⚠️ [BackupService] خطأ في دمج مستخدم: $e');
          }
        }

        debugPrint('✅ [BackupService] تم دمج $mergedCount مستخدم جديد');
      }

      // 9️⃣ استعادة الصور
      onProgress?.call('جاري استعادة الصور...', 8, 8);

      final imagesStats = await _restoreAllImages(tempRestoreDir.path);
      final totalImagesRestored = imagesStats['total'] ?? 0;

      debugPrint('✅ [BackupService] تم استعادة $totalImagesRestored صورة');

      // 9️⃣ تنظيف
      await tempRestoreDir.delete(recursive: true);

      return {
        'status': 'success',
        'message': 'تم استعادة النسخة الاحتياطية بنجاح',
        'total_images': totalImagesRestored,
        'merged_users': mergeUsers,
        'metadata': metadata,
      };
    } catch (e, stackTrace) {
      debugPrint('❌ [BackupService] خطأ في restoreSimpleBackup: $e');
      debugPrint('Stack trace: $stackTrace');

      // تنظيف في حالة الخطأ
      if (tempRestoreDir != null && await tempRestoreDir.exists()) {
        await tempRestoreDir.delete(recursive: true);
      }

      return {
        'status': 'error',
        'message': 'فشل في استعادة النسخة الاحتياطية: $e',
      };
    }
  }

  // ============================================================================
  // 📋 دوال مساعدة
  // ============================================================================

  /// إنشاء metadata بسيط بدون backup_magic_number
  Future<Map<String, dynamic>> _createSimpleMetadata(
    Database db,
    int totalImages,
    Map<String, dynamic> imagesStats,
    String dbEncryptionKey,
  ) async {
    try {
      // جمع إحصائيات من قاعدة البيانات
      final users = await db.query('TB_Users');
      final suppliers = await db.query('TB_Suppliers');
      final customers = await db.query('Debt_Customer');
      final products = await db.query('Store_Products');
      final employees = await db.query('TB_Employees');
      final settings = await db.query('TB_Settings');

      return {
        'backup_format': 'simple_v1',
        'app_version': '1.0.0',
        'backup_date': DateTime.now().toIso8601String(),
        'activation_secret': FirebaseService.instance.getActivationSecret(),
        'time_validation_secret':
            FirebaseService.instance.getTimeValidationSecret(),
        'db_encryption_key': dbEncryptionKey, // ← Hint: المفتاح المهم!
        'total_images': totalImages,
        'database_version': 1,
        'categories': {
          'users': users.length,
          'suppliers': suppliers.length,
          'customers': customers.length,
          'products': products.length,
          'employees': employees.length,
          'company': settings.length,
        },
        'images_stats': imagesStats,
      };
    } catch (e) {
      debugPrint('⚠️ [BackupService] خطأ في _createSimpleMetadata: $e');
      return {
        'backup_format': 'simple_v1',
        'app_version': '1.0.0',
        'backup_date': DateTime.now().toIso8601String(),
        'activation_secret': FirebaseService.instance.getActivationSecret(),
        'time_validation_secret':
            FirebaseService.instance.getTimeValidationSecret(),
        'total_images': totalImages,
        'error': e.toString(),
      };
    }
  }

  /// جمع جميع الصور ونسخها إلى مجلد النسخ الاحتياطي
  Future<Map<String, dynamic>> _collectAllImages(
    String backupPath,
    Database db,
  ) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesBaseDir = Directory('${appDir.path}/images');

      if (!await imagesBaseDir.exists()) {
        return {'total': 0};
      }

      // المجلدات والجداول المرتبطة
      final categories = {
        'users': 'TB_Users',
        'suppliers': 'TB_Suppliers',
        'customers': 'Debt_Customer',
        'products': 'Store_Products',
        'employees': 'TB_Employees',
        'company': 'TB_Settings',
      };

      int totalImagesCopied = 0;
      final stats = <String, int>{};

      for (final category in categories.entries) {
        final categoryName = category.key;
        final tableName = category.value;

        try {
          // الحصول على جميع السجلات من الجدول
          final records = await db.query(tableName);

          int categoryImageCount = 0;

          for (final record in records) {
            // البحث عن حقل الصورة
            String? imagePath;

            if (record.containsKey('image_path')) {
              imagePath = record['image_path'] as String?;
            } else if (record.containsKey('logo_path')) {
              imagePath = record['logo_path'] as String?;
            } else if (record.containsKey('photo_path')) {
              imagePath = record['photo_path'] as String?;
            }

            if (imagePath != null && imagePath.isNotEmpty) {
              final imageFile = File(imagePath);

              if (await imageFile.exists()) {
                // إنشاء مجلد الفئة في النسخة الاحتياطية
                final categoryDir =
                    Directory('$backupPath/images/$categoryName');
                if (!await categoryDir.exists()) {
                  await categoryDir.create(recursive: true);
                }

                // نسخ الصورة
                final fileName = imageFile.path.split('/').last;
                final destFile = File('${categoryDir.path}/$fileName');
                await imageFile.copy(destFile.path);

                categoryImageCount++;
                totalImagesCopied++;
              }
            }
          }

          stats[categoryName] = categoryImageCount;
          debugPrint('  ✅ $categoryName: $categoryImageCount صورة');
        } catch (e) {
          debugPrint('  ⚠️ خطأ في معالجة $categoryName: $e');
          stats[categoryName] = 0;
        }
      }

      return {
        'total': totalImagesCopied,
        ...stats,
      };
    } catch (e) {
      debugPrint('❌ [BackupService] خطأ في _collectAllImages: $e');
      return {'total': 0};
    }
  }

  /// استعادة جميع الصور من مجلد النسخ الاحتياطي
  Future<Map<String, dynamic>> _restoreAllImages(String restorePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesBaseDir = Directory('${appDir.path}/images');

      // التأكد من وجود مجلد الصور الأساسي
      if (!await imagesBaseDir.exists()) {
        await imagesBaseDir.create(recursive: true);
      }

      final backupImagesDir = Directory('$restorePath/images');

      if (!await backupImagesDir.exists()) {
        return {'total': 0};
      }

      int totalImagesRestored = 0;
      final stats = <String, int>{};

      // المجلدات المتوقعة
      final categories = [
        'users',
        'suppliers',
        'customers',
        'products',
        'employees',
        'company',
      ];

      for (final category in categories) {
        final categoryBackupDir =
            Directory('${backupImagesDir.path}/$category');

        if (await categoryBackupDir.exists()) {
          final categoryRestoreDir =
              Directory('${imagesBaseDir.path}/$category');

          if (!await categoryRestoreDir.exists()) {
            await categoryRestoreDir.create(recursive: true);
          }

          int categoryCount = 0;

          final files = categoryBackupDir.listSync();
          for (final file in files) {
            if (file is File) {
              try {
                final fileName = file.path.split('/').last;
                final destFile = File('${categoryRestoreDir.path}/$fileName');
                await file.copy(destFile.path);

                categoryCount++;
                totalImagesRestored++;
              } catch (e) {
                debugPrint('  ⚠️ خطأ في نسخ صورة: $e');
              }
            }
          }

          stats[category] = categoryCount;
          debugPrint('  ✅ $category: $categoryCount صورة');
        } else {
          stats[category] = 0;
        }
      }

      return {
        'total': totalImagesRestored,
        ...stats,
      };
    } catch (e) {
      debugPrint('❌ [BackupService] خطأ في _restoreAllImages: $e');
      return {'total': 0};
    }
  }

  /// تنسيق حجم الملف
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
