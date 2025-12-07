// 📦 lib/utils/archive_helper.dart

import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

/// 📦 مساعد الأرشيف المحسّن - ضغط وفك ضغط ZIP
///
/// ← Hint: هذا المساعد يتعامل مع ملفات ZIP
/// ← Hint: يدعم الضغط والفك بكفاءة عالية
/// ← Hint: يمكن استخدامه مع EncryptionService للنسخ الاحتياطي المشفر
///
/// 📝 للمستقبل:
/// - يمكن إضافة دعم لـ 7z (ضغط أفضل)
/// - يمكن إضافة دعم لـ tar.gz (للتوافق مع Linux)
/// - يمكن إضافة progress streaming للملفات الكبيرة جداً
/// - يمكن إضافة split archives (تقسيم إلى أجزاء صغيرة)
class ArchiveHelper {
  // ============================================================================
  // 📦 ضغط مجلد كامل إلى ZIP
  // ============================================================================

  /// ضغط مجلد كامل إلى ملف ZIP
  ///
  /// ← Hint: يأخذ مجلد ويحوله لملف .zip واحد
  /// ← Hint: يحافظ على بنية المجلدات الداخلية
  /// ← Hint: يدعم callback للتقدم
  ///
  /// [sourceDir] المجلد المراد ضغطه
  /// [outputZipFile] ملف ZIP الناتج
  /// [onProgress] دالة callback للتقدم (اختياري)
  ///
  /// Returns: true إذا نجح الضغط
  ///
  /// 📝 للمستقبل:
  /// - يمكن إضافة compression level (0-9)
  /// - يمكن إضافة exclude patterns (تجاهل ملفات معينة)
  /// - يمكن إضافة password protection للـ ZIP نفسه
  static Future<bool> compressDirectory({
    required Directory sourceDir,
    required File outputZipFile,
    Function(int current, int total)? onProgress,
  }) async {
    try {
      debugPrint('📦 [Archive] بدء ضغط المجلد...');
      debugPrint('   - المصدر: ${sourceDir.path}');
      debugPrint('   - الوجهة: ${outputZipFile.path}');

      // ← Hint: التأكد من وجود المجلد المصدر
      if (!await sourceDir.exists()) {
        debugPrint('❌ [Archive] المجلد المصدر غير موجود');
        return false;
      }

      // ← Hint: إنشاء أرشيف جديد
      final archive = Archive();

      // ← Hint: جمع جميع الملفات من المجلد
      final files = await _getAllFiles(sourceDir);
      debugPrint('📂 [Archive] عدد الملفات: ${files.length}');

      int processed = 0;

      // ← Hint: إضافة كل ملف للأرشيف
      for (final file in files) {
        try {
          // ← Hint: قراءة محتوى الملف
          final bytes = await file.readAsBytes();

          // ← Hint: حساب المسار النسبي (لحفظ البنية)
          final relativePath = path.relative(
            file.path,
            from: sourceDir.path,
          );

          // ← Hint: إضافة الملف للأرشيف
          final archiveFile = ArchiveFile(
            relativePath,
            bytes.length,
            bytes,
          );

          archive.addFile(archiveFile);

          processed++;
          onProgress?.call(processed, files.length);

          if (processed % 10 == 0) {
            debugPrint('   📄 تم معالجة $processed/${files.length} ملف');
          }
        } catch (e) {
          debugPrint('⚠️ [Archive] خطأ في إضافة ملف ${file.path}: $e');
        }
      }

      // ← Hint: ضغط الأرشيف وحفظه
      debugPrint('🗜️ [Archive] ضغط وحفظ الملف...');

      final encoder = ZipEncoder();
      final zipData = encoder.encode(archive);

      if (zipData == null) {
        debugPrint('❌ [Archive] فشل الضغط');
        return false;
      }

      // ← Hint: حفظ ملف ZIP
      await outputZipFile.writeAsBytes(zipData);

      final zipSize = await outputZipFile.length();
      debugPrint('✅ [Archive] تم الضغط بنجاح');
      debugPrint('   - عدد الملفات: ${files.length}');
      debugPrint('   - حجم الملف: ${_formatBytes(zipSize)}');

      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ [Archive] خطأ في ضغط المجلد: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  // ============================================================================
  // 📂 فك ضغط ZIP إلى مجلد
  // ============================================================================

  /// فك ضغط ملف ZIP إلى مجلد
  ///
  /// ← Hint: يستخرج محتويات ملف ZIP
  /// ← Hint: يحافظ على بنية المجلدات
  /// ← Hint: يدعم callback للتقدم
  ///
  /// [zipFile] ملف ZIP المراد فك ضغطه
  /// [outputDir] المجلد الذي سيتم الاستخراج فيه
  /// [onProgress] دالة callback للتقدم (اختياري)
  ///
  /// Returns: true إذا نجح فك الضغط
  ///
  /// 📝 للمستقبل:
  /// - يمكن إضافة validation للـ ZIP قبل فك الضغط
  /// - يمكن إضافة extract specific files only
  /// - يمكن إضافة overwrite policy (skip/replace/rename)
  static Future<bool> extractZip({
    required File zipFile,
    required Directory outputDir,
    Function(int current, int total)? onProgress,
  }) async {
    try {
      debugPrint('📂 [Archive] بدء فك ضغط ZIP...');
      debugPrint('   - المصدر: ${zipFile.path}');
      debugPrint('   - الوجهة: ${outputDir.path}');

      // ← Hint: التأكد من وجود ملف ZIP
      if (!await zipFile.exists()) {
        debugPrint('❌ [Archive] ملف ZIP غير موجود');
        return false;
      }

      // ← Hint: قراءة ملف ZIP
      final bytes = await zipFile.readAsBytes();

      // ← Hint: فك تشفير ZIP
      final archive = ZipDecoder().decodeBytes(bytes);

      debugPrint('📦 [Archive] عدد الملفات في الأرشيف: ${archive.length}');

      // ← Hint: التأكد من وجود مجلد الوجهة
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }

      int processed = 0;

      // ← Hint: استخراج كل ملف
      for (final file in archive) {
        try {
          final filename = file.name;

          // ← Hint: إنشاء المسار الكامل
          final filePath = path.join(outputDir.path, filename);

          if (file.isFile) {
            // ← Hint: ملف - نستخرجه
            final outFile = File(filePath);

            // ← Hint: إنشاء المجلدات الأب إذا لزم الأمر
            await outFile.parent.create(recursive: true);

            // ← Hint: كتابة محتوى الملف
            await outFile.writeAsBytes(file.content as List<int>);
          } else {
            // ← Hint: مجلد - ننشئه فقط
            final outDir = Directory(filePath);
            await outDir.create(recursive: true);
          }

          processed++;
          onProgress?.call(processed, archive.length);

          if (processed % 10 == 0) {
            debugPrint('   📄 تم استخراج $processed/${archive.length} ملف');
          }
        } catch (e) {
          debugPrint('⚠️ [Archive] خطأ في استخراج ${file.name}: $e');
        }
      }

      debugPrint('✅ [Archive] تم فك الضغط بنجاح');
      debugPrint('   - عدد الملفات: ${archive.length}');

      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ [Archive] خطأ في فك ضغط ZIP: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  // ============================================================================
  // 📋 الحصول على معلومات ZIP بدون فك الضغط
  // ============================================================================

  /// الحصول على معلومات عن محتويات ملف ZIP
  ///
  /// ← Hint: يقرأ metadata فقط بدون استخراج الملفات
  /// ← Hint: مفيد لعرض معلومات النسخة الاحتياطية قبل الاستعادة
  ///
  /// Returns: Map يحتوي على:
  /// - totalFiles: عدد الملفات
  /// - totalSize: الحجم الكلي (غير مضغوط)
  /// - compressedSize: الحجم المضغوط
  /// - files: قائمة بأسماء الملفات
  ///
  /// 📝 للمستقبل:
  /// - يمكن إضافة file tree structure
  /// - يمكن إضافة compression ratio لكل ملف
  /// - يمكن إضافة file types breakdown
  static Future<Map<String, dynamic>> getZipInfo(File zipFile) async {
    try {
      debugPrint('📋 [Archive] قراءة معلومات ZIP...');

      if (!await zipFile.exists()) {
        return {
          'error': 'ملف ZIP غير موجود',
        };
      }

      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      int totalSize = 0;
      final fileNames = <String>[];

      for (final file in archive) {
        if (file.isFile) {
          totalSize += file.size;
          fileNames.add(file.name);
        }
      }

      final compressedSize = bytes.length;
      final compressionRatio = totalSize > 0
          ? ((1 - (compressedSize / totalSize)) * 100).toStringAsFixed(1)
          : '0.0';

      debugPrint('✅ [Archive] معلومات ZIP:');
      debugPrint('   - عدد الملفات: ${fileNames.length}');
      debugPrint('   - الحجم الأصلي: ${_formatBytes(totalSize)}');
      debugPrint('   - الحجم المضغوط: ${_formatBytes(compressedSize)}');
      debugPrint('   - نسبة الضغط: $compressionRatio%');

      return {
        'totalFiles': fileNames.length,
        'totalSize': totalSize,
        'totalSizeFormatted': _formatBytes(totalSize),
        'compressedSize': compressedSize,
        'compressedSizeFormatted': _formatBytes(compressedSize),
        'compressionRatio': compressionRatio,
        'files': fileNames,
      };
    } catch (e, stackTrace) {
      debugPrint('❌ [Archive] خطأ في قراءة معلومات ZIP: $e');
      debugPrint('Stack trace: $stackTrace');

      return {
        'error': e.toString(),
      };
    }
  }

  // ============================================================================
  // 🔍 فحص صحة ملف ZIP
  // ============================================================================

  /// التحقق من صحة ملف ZIP
  ///
  /// ← Hint: يتأكد أن ملف ZIP صالح وغير تالف
  /// ← Hint: لا يستخرج الملفات، فقط يتحقق من البنية
  ///
  /// Returns: true إذا كان الملف صالح
  ///
  /// 📝 للمستقبل:
  /// - يمكن إضافة CRC check لكل ملف
  /// - يمكن إضافة deep validation
  static Future<bool> validateZip(File zipFile) async {
    try {
      debugPrint('🔍 [Archive] فحص صحة ZIP...');

      if (!await zipFile.exists()) {
        debugPrint('❌ [Archive] الملف غير موجود');
        return false;
      }

      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      if (archive.isEmpty) {
        debugPrint('❌ [Archive] الأرشيف فارغ');
        return false;
      }

      debugPrint('✅ [Archive] ملف ZIP صالح');
      return true;
    } catch (e) {
      debugPrint('❌ [Archive] ملف ZIP تالف: $e');
      return false;
    }
  }

  // ============================================================================
  // 📁 ضغط ملف واحد
  // ============================================================================

  /// ضغط ملف واحد إلى ZIP
  ///
  /// ← Hint: لضغط ملف واحد بدل مجلد كامل
  /// ← Hint: مفيد لضغط قاعدة البيانات مثلاً
  ///
  /// 📝 للمستقبل: يمكن إضافة password protection
  static Future<bool> compressFile({
    required File sourceFile,
    required File outputZipFile,
  }) async {
    try {
      debugPrint('📁 [Archive] ضغط ملف واحد...');

      if (!await sourceFile.exists()) {
        debugPrint('❌ [Archive] الملف المصدر غير موجود');
        return false;
      }

      final bytes = await sourceFile.readAsBytes();
      final archive = Archive();

      final archiveFile = ArchiveFile(
        path.basename(sourceFile.path),
        bytes.length,
        bytes,
      );

      archive.addFile(archiveFile);

      final encoder = ZipEncoder();
      final zipData = encoder.encode(archive);

      if (zipData == null) {
        debugPrint('❌ [Archive] فشل الضغط');
        return false;
      }

      await outputZipFile.writeAsBytes(zipData);

      debugPrint('✅ [Archive] تم ضغط الملف بنجاح');
      return true;
    } catch (e) {
      debugPrint('❌ [Archive] خطأ في ضغط الملف: $e');
      return false;
    }
  }

  // ============================================================================
  // 🛠️ دوال مساعدة
  // ============================================================================

  /// جمع جميع الملفات من مجلد (بما في ذلك المجلدات الفرعية)
  ///
  /// ← Hint: دالة recursive تجمع كل الملفات
  /// ← Hint: تتجاهل المجلدات الفارغة
  static Future<List<File>> _getAllFiles(Directory dir) async {
    final files = <File>[];

    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        files.add(entity);
      }
    }

    return files;
  }

  /// تنسيق حجم البيانات
  ///
  /// ← Hint: تحويل bytes إلى وحدات قابلة للقراءة
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  // ============================================================================
  // 📝 معلومات إضافية للمستقبل
  // ============================================================================

  /// ← Hint: الامتدادات المدعومة حالياً: .zip فقط
  ///
  /// 📝 للمستقبل - امتدادات إضافية يمكن إضافتها:
  /// - .7z (ضغط أفضل من ZIP)
  /// - .tar.gz (معيار Linux/Unix)
  /// - .rar (يحتاج مكتبة خارجية)
  /// - .bz2 (ضغط جيد للنصوص)
  ///
  /// 📝 للمستقبل - ميزات إضافية:
  /// - Split archives (تقسيم لأجزاء صغيرة للمشاركة)
  /// - Resume support (استكمال فك الضغط بعد انقطاع)
  /// - Streaming extraction (للملفات الكبيرة جداً)
  /// - Parallel compression (استخدام multi-threading)
  /// - Cloud integration (رفع مباشر لـ Google Drive / Dropbox)
}
