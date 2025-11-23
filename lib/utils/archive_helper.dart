// lib/utils/archive_helper.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

/// 📦 مساعد لضغط وفك ضغط الملفات - ZIP Archive Helper
///
/// ← Hint: يستخدم حزمة archive لضغط وفك ضغط الملفات بصيغة ZIP
/// ← Hint: مهم للنسخ الاحتياطي الشامل (قاعدة البيانات + الصور)
///
/// الاستخدامات:
/// • ضغط مجلد كامل إلى ملف ZIP
/// • فك ضغط ملف ZIP إلى مجلد
/// • إضافة ملفات متعددة إلى ZIP
/// • دعم كامل للمجلدات المتداخلة
class ArchiveHelper {
  // ============================================================================
  // ← Hint: ضغط مجلد كامل إلى ملف ZIP
  // ← Hint: يحتوي على جميع الملفات والمجلدات الفرعية
  // ============================================================================

  /// ضغط مجلد كامل إلى ملف ZIP
  ///
  /// [sourceDir] - المجلد المراد ضغطه
  /// [outputZipFile] - ملف ZIP الناتج
  /// [onProgress] - callback اختياري لتتبع التقدم (تمرير: current, total)
  ///
  /// Returns: true إذا نجحت العملية
  static Future<bool> compressDirectory({
    required Directory sourceDir,
    required File outputZipFile,
    Function(int current, int total)? onProgress,
  }) async {
    try {
      debugPrint('📦 [ArchiveHelper] بدء ضغط المجلد: ${sourceDir.path}');

      // ═══════════════════════════════════════════════════════════
      // الخطوة 1: التحقق من وجود المجلد المصدر
      // ═══════════════════════════════════════════════════════════

      if (!await sourceDir.exists()) {
        debugPrint('❌ [ArchiveHelper] المجلد المصدر غير موجود');
        return false;
      }

      // ═══════════════════════════════════════════════════════════
      // الخطوة 2: إنشاء Archive
      // ═══════════════════════════════════════════════════════════

      final archive = Archive();

      // ← Hint: الحصول على جميع الملفات في المجلد (بما فيها المجلدات الفرعية)
      final files = await _getAllFilesInDirectory(sourceDir);

      debugPrint('📂 [ArchiveHelper] عدد الملفات: ${files.length}');

      // ═══════════════════════════════════════════════════════════
      // الخطوة 3: إضافة كل ملف إلى Archive
      // ═══════════════════════════════════════════════════════════

      for (int i = 0; i < files.length; i++) {
        final file = files[i];

        try {
          // ← Hint: قراءة محتوى الملف
          final bytes = await file.readAsBytes();

          // ← Hint: حساب المسار النسبي للملف داخل ZIP
          // مثال: إذا المجلد المصدر /storage/temp/backup
          // والملف /storage/temp/backup/images/photo.jpg
          // المسار النسبي: images/photo.jpg
          final relativePath = p.relative(file.path, from: sourceDir.path);

          // ← Hint: إنشاء ArchiveFile وإضافته
          final archiveFile = ArchiveFile(
            relativePath,
            bytes.length,
            bytes,
          );

          archive.addFile(archiveFile);

          // ← Hint: تحديث التقدم
          if (onProgress != null) {
            onProgress(i + 1, files.length);
          }

          debugPrint('  ✅ تمت إضافة: $relativePath (${_formatBytes(bytes.length)})');

        } catch (e) {
          debugPrint('  ⚠️ خطأ في إضافة الملف ${file.path}: $e');
          // ← Hint: نستمر حتى لو فشل ملف واحد
          continue;
        }
      }

      // ═══════════════════════════════════════════════════════════
      // الخطوة 4: ترميز Archive إلى ZIP
      // ← Hint: هذه الخطوة قد تأخذ وقتاً حسب حجم الملفات
      // ═══════════════════════════════════════════════════════════

      debugPrint('🔄 [ArchiveHelper] ترميز ZIP...');

      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);

      if (zipData == null) {
        debugPrint('❌ [ArchiveHelper] فشل ترميز ZIP');
        return false;
      }

      // ═══════════════════════════════════════════════════════════
      // الخطوة 5: كتابة ZIP إلى ملف
      // ═══════════════════════════════════════════════════════════

      await outputZipFile.writeAsBytes(zipData);

      final fileSize = await outputZipFile.length();
      debugPrint('✅ [ArchiveHelper] تم إنشاء ZIP: ${outputZipFile.path}');
      debugPrint('   الحجم: ${_formatBytes(fileSize)}');

      return true;

    } catch (e, stackTrace) {
      debugPrint('❌ [ArchiveHelper] خطأ في compressDirectory: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  // ============================================================================
  // ← Hint: فك ضغط ملف ZIP إلى مجلد
  // ← Hint: يستخرج جميع الملفات والمجلدات
  // ============================================================================

  /// فك ضغط ملف ZIP إلى مجلد
  ///
  /// [zipFile] - ملف ZIP المراد فك ضغطه
  /// [outputDir] - المجلد الذي سيتم استخراج الملفات إليه
  /// [onProgress] - callback اختياري لتتبع التقدم
  ///
  /// Returns: true إذا نجحت العملية
  static Future<bool> extractZip({
    required File zipFile,
    required Directory outputDir,
    Function(int current, int total)? onProgress,
  }) async {
    try {
      debugPrint('📦 [ArchiveHelper] بدء فك ضغط: ${zipFile.path}');

      // ═══════════════════════════════════════════════════════════
      // الخطوة 1: التحقق من وجود ملف ZIP
      // ═══════════════════════════════════════════════════════════

      if (!await zipFile.exists()) {
        debugPrint('❌ [ArchiveHelper] ملف ZIP غير موجود');
        return false;
      }

      // ═══════════════════════════════════════════════════════════
      // الخطوة 2: قراءة وفك تشفير ZIP
      // ═══════════════════════════════════════════════════════════

      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      debugPrint('📂 [ArchiveHelper] عدد الملفات في ZIP: ${archive.length}');

      // ═══════════════════════════════════════════════════════════
      // الخطوة 3: إنشاء مجلد الإخراج إذا لم يكن موجوداً
      // ═══════════════════════════════════════════════════════════

      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }

      // ═══════════════════════════════════════════════════════════
      // الخطوة 4: استخراج كل ملف
      // ═══════════════════════════════════════════════════════════

      for (int i = 0; i < archive.length; i++) {
        final file = archive[i];

        try {
          // ← Hint: المسار الكامل للملف
          final filePath = p.join(outputDir.path, file.name);

          // ← Hint: التحقق إذا كان مجلد أو ملف
          if (file.isFile) {
            // ← Hint: إنشاء المجلدات الأب إذا لم تكن موجودة
            final outFile = File(filePath);
            await outFile.create(recursive: true);

            // ← Hint: كتابة محتوى الملف
            await outFile.writeAsBytes(file.content as List<int>);

            debugPrint('  ✅ استخرج: ${file.name} (${_formatBytes(file.size)})');

          } else {
            // ← Hint: إنشاء مجلد
            final outDir = Directory(filePath);
            await outDir.create(recursive: true);

            debugPrint('  📁 أنشأ مجلد: ${file.name}');
          }

          // ← Hint: تحديث التقدم
          if (onProgress != null) {
            onProgress(i + 1, archive.length);
          }

        } catch (e) {
          debugPrint('  ⚠️ خطأ في استخراج ${file.name}: $e');
          // ← Hint: نستمر حتى لو فشل ملف واحد
          continue;
        }
      }

      debugPrint('✅ [ArchiveHelper] تم فك ضغط ZIP إلى: ${outputDir.path}');

      return true;

    } catch (e, stackTrace) {
      debugPrint('❌ [ArchiveHelper] خطأ في extractZip: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  // ============================================================================
  // ← Hint: إضافة ملف واحد إلى ZIP موجود (أو إنشاء جديد)
  // ============================================================================

  /// إضافة ملف إلى ZIP
  ///
  /// [zipFile] - ملف ZIP (موجود أو سيتم إنشاؤه)
  /// [fileToAdd] - الملف المراد إضافته
  /// [nameInZip] - الاسم داخل ZIP (اختياري)
  ///
  /// Returns: true إذا نجحت العملية
  static Future<bool> addFileToZip({
    required File zipFile,
    required File fileToAdd,
    String? nameInZip,
  }) async {
    try {
      debugPrint('📦 [ArchiveHelper] إضافة ملف إلى ZIP...');

      // ← Hint: قراءة ZIP الموجود (إن وجد)
      Archive archive;

      if (await zipFile.exists()) {
        final bytes = await zipFile.readAsBytes();
        archive = ZipDecoder().decodeBytes(bytes);
      } else {
        archive = Archive();
      }

      // ← Hint: قراءة الملف الجديد
      final fileBytes = await fileToAdd.readAsBytes();
      final fileName = nameInZip ?? p.basename(fileToAdd.path);

      // ← Hint: إضافة الملف
      final archiveFile = ArchiveFile(
        fileName,
        fileBytes.length,
        fileBytes,
      );

      archive.addFile(archiveFile);

      // ← Hint: حفظ ZIP المحدث
      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);

      if (zipData == null) return false;

      await zipFile.writeAsBytes(zipData);

      debugPrint('✅ [ArchiveHelper] تمت الإضافة: $fileName');

      return true;

    } catch (e) {
      debugPrint('❌ [ArchiveHelper] خطأ في addFileToZip: $e');
      return false;
    }
  }

  // ============================================================================
  // ← Hint: الحصول على قائمة الملفات في ZIP (بدون استخراج)
  // ============================================================================

  /// الحصول على قائمة محتويات ZIP
  ///
  /// [zipFile] - ملف ZIP
  ///
  /// Returns: قائمة بأسماء الملفات وأحجامها
  static Future<List<Map<String, dynamic>>?> getZipContents(File zipFile) async {
    try {
      if (!await zipFile.exists()) {
        return null;
      }

      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final contents = <Map<String, dynamic>>[];

      for (final file in archive) {
        contents.add({
          'name': file.name,
          'size': file.size,
          'isFile': file.isFile,
          'isCompressed': file.isCompressed,
          'compressedSize': file.compressedSize,
        });
      }

      return contents;

    } catch (e) {
      debugPrint('❌ [ArchiveHelper] خطأ في getZipContents: $e');
      return null;
    }
  }

  // ============================================================================
  // ← Hint: دوال مساعدة داخلية (private)
  // ============================================================================

  /// الحصول على جميع الملفات في مجلد (بما فيها المجلدات الفرعية)
  static Future<List<File>> _getAllFilesInDirectory(Directory dir) async {
    final files = <File>[];

    try {
      // ← Hint: recursive: true للحصول على الملفات في المجلدات الفرعية
      final entities = dir.listSync(recursive: true);

      for (final entity in entities) {
        if (entity is File) {
          files.add(entity);
        }
      }

      return files;

    } catch (e) {
      debugPrint('⚠️ [ArchiveHelper] خطأ في _getAllFilesInDirectory: $e');
      return files;
    }
  }

  /// تنسيق حجم الملف بشكل قابل للقراءة
  ///
  /// ← Hint: يحول bytes إلى KB, MB, GB
  static String _formatBytes(int bytes) {
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

  // ============================================================================
  // ← Hint: دالة للتحقق من صحة ملف ZIP
  // ============================================================================

  /// التحقق من صحة ملف ZIP
  ///
  /// Returns: true إذا كان الملف ZIP صالح
  static Future<bool> isValidZip(File zipFile) async {
    try {
      if (!await zipFile.exists()) {
        return false;
      }

      final bytes = await zipFile.readAsBytes();

      // ← Hint: محاولة فك تشفير ZIP
      ZipDecoder().decodeBytes(bytes);

      return true;

    } catch (e) {
      debugPrint('⚠️ [ArchiveHelper] ملف ZIP غير صالح: $e');
      return false;
    }
  }
}
