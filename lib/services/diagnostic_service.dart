// lib/services/diagnostic_service.dart

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;

import '../data/database_helper.dart';
import 'database_key_manager.dart';
import 'device_service.dart';

/// 🔧 خدمة التشخيص - Diagnostic Service
///
/// ← Hint: تساعد في تشخيص مشاكل التطبيق وجمع معلومات للدعم الفني
/// ← Hint: لا تحتوي على معلومات حساسة (كلمات مرور، مفاتيح، إلخ)
///
/// الاستخدامات:
/// • فحص صحة قاعدة البيانات
/// • جمع معلومات النظام
/// • تصدير تقرير تشخيصي
/// • فحص المفاتيح والإعدادات
class DiagnosticService {
  // ============================================================================
  // Singleton Pattern
  // ============================================================================

  static final DiagnosticService _instance = DiagnosticService._internal();
  DiagnosticService._internal();
  factory DiagnosticService() => _instance;
  static DiagnosticService get instance => _instance;

  // ============================================================================
  // ← Hint: فحص صحة قاعدة البيانات
  // ============================================================================

  /// فحص صحة قاعدة البيانات
  ///
  /// Returns: Map يحتوي على معلومات الصحة
  Future<Map<String, dynamic>> checkDatabaseHealth() async {
    try {
      debugPrint('🔍 [Diagnostic] فحص صحة قاعدة البيانات...');

      final result = <String, dynamic>{};

      // ═══════════════════════════════════════════════════════════
      // فحص وجود ملف قاعدة البيانات
      // ═══════════════════════════════════════════════════════════

      final dbFolder = await getApplicationDocumentsDirectory();
      final dbPath = p.join(dbFolder.path, 'accounting.db');
      final dbFile = File(dbPath);

      result['database_exists'] = await dbFile.exists();

      if (await dbFile.exists()) {
        result['database_size'] = await dbFile.length();
        result['database_path'] = dbPath;
      }

      // ═══════════════════════════════════════════════════════════
      // محاولة فتح قاعدة البيانات
      // ═══════════════════════════════════════════════════════════

      try {
        final db = await DatabaseHelper.instance.database;

        result['database_accessible'] = true;

        // ← Hint: إحصائيات بسيطة
        final userCount = await db.rawQuery('SELECT COUNT(*) as count FROM TB_Users');
        result['users_count'] = userCount.first['count'];

        final supplierCount = await db.rawQuery('SELECT COUNT(*) as count FROM TB_Suppliers');
        result['suppliers_count'] = supplierCount.first['count'];

        final customerCount = await db.rawQuery('SELECT COUNT(*) as count FROM TB_Customers');
        result['customers_count'] = customerCount.first['count'];

        final productCount = await db.rawQuery('SELECT COUNT(*) as count FROM TB_Products');
        result['products_count'] = productCount.first['count'];

        debugPrint('✅ [Diagnostic] قاعدة البيانات سليمة');

      } catch (e) {
        result['database_accessible'] = false;
        result['database_error'] = e.toString();

        debugPrint('❌ [Diagnostic] خطأ في فتح قاعدة البيانات: $e');
      }

      return result;

    } catch (e) {
      debugPrint('❌ [Diagnostic] خطأ في checkDatabaseHealth: $e');
      return {'error': e.toString()};
    }
  }

  // ============================================================================
  // ← Hint: فحص المفاتيح
  // ============================================================================

  /// فحص حالة المفاتيح
  ///
  /// Returns: Map يحتوي على معلومات المفاتيح (بدون المفاتيح نفسها!)
  Future<Map<String, dynamic>> checkEncryptionKeys() async {
    try {
      debugPrint('🔍 [Diagnostic] فحص المفاتيح...');

      final keyInfo = await DatabaseKeyManager.instance.getKeyInfo();

      debugPrint('✅ [Diagnostic] معلومات المفاتيح: $keyInfo');

      return {
        'status': 'success',
        'key_info': keyInfo,
      };

    } catch (e) {
      debugPrint('❌ [Diagnostic] خطأ في checkEncryptionKeys: $e');
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  // ============================================================================
  // ← Hint: جمع معلومات النظام
  // ============================================================================

  /// جمع معلومات النظام والجهاز
  ///
  /// Returns: Map شامل بمعلومات النظام
  Future<Map<String, dynamic>> getSystemInfo() async {
    try {
      debugPrint('🔍 [Diagnostic] جمع معلومات النظام...');

      final deviceInfo = await DeviceService.instance.getDeviceInfo();
      final packageInfo = await PackageInfo.fromPlatform();

      final result = {
        'app': {
          'name': packageInfo.appName,
          'version': packageInfo.version,
          'build_number': packageInfo.buildNumber,
          'package_name': packageInfo.packageName,
        },
        'device': deviceInfo,
        'paths': {
          'documents': (await getApplicationDocumentsDirectory()).path,
          'temp': (await getTemporaryDirectory()).path,
          'support': (await getApplicationSupportDirectory()).path,
        },
        'platform': Platform.operatingSystem,
        'timestamp': DateTime.now().toIso8601String(),
      };

      debugPrint('✅ [Diagnostic] تم جمع معلومات النظام');

      return result;

    } catch (e) {
      debugPrint('❌ [Diagnostic] خطأ في getSystemInfo: $e');
      return {'error': e.toString()};
    }
  }

  // ============================================================================
  // ← Hint: تقرير تشخيصي شامل
  // ============================================================================

  /// إنشاء تقرير تشخيصي شامل
  ///
  /// ← Hint: يجمع جميع المعلومات في تقرير واحد
  /// ← Hint: آمن - لا يحتوي على معلومات حساسة
  ///
  /// Returns: Map يحتوي على التقرير الكامل
  Future<Map<String, dynamic>> generateDiagnosticReport() async {
    try {
      debugPrint('📋 [Diagnostic] إنشاء تقرير تشخيصي...');

      final report = <String, dynamic>{};

      // ═══════════════════════════════════════════════════════════
      // معلومات عامة
      // ═══════════════════════════════════════════════════════════

      report['report_date'] = DateTime.now().toIso8601String();
      report['report_version'] = '2.0';

      // ═══════════════════════════════════════════════════════════
      // معلومات النظام
      // ═══════════════════════════════════════════════════════════

      report['system'] = await getSystemInfo();

      // ═══════════════════════════════════════════════════════════
      // صحة قاعدة البيانات
      // ═══════════════════════════════════════════════════════════

      report['database_health'] = await checkDatabaseHealth();

      // ═══════════════════════════════════════════════════════════
      // معلومات المفاتيح
      // ═══════════════════════════════════════════════════════════

      report['encryption_keys'] = await checkEncryptionKeys();

      // ═══════════════════════════════════════════════════════════
      // فحص الملفات المهمة
      // ═══════════════════════════════════════════════════════════

      report['important_files'] = await _checkImportantFiles();

      debugPrint('✅ [Diagnostic] تم إنشاء التقرير التشخيصي');

      return report;

    } catch (e, stackTrace) {
      debugPrint('❌ [Diagnostic] خطأ في generateDiagnosticReport: $e');
      debugPrint('Stack trace: $stackTrace');

      return {
        'status': 'error',
        'error': e.toString(),
        'stack_trace': stackTrace.toString(),
      };
    }
  }

  // ============================================================================
  // ← Hint: فحص الملفات المهمة
  // ============================================================================

  Future<Map<String, dynamic>> _checkImportantFiles() async {
    try {
      final result = <String, dynamic>{};

      final dbFolder = await getApplicationDocumentsDirectory();

      // ← Hint: قائمة الملفات المهمة
      final importantFiles = [
        'accounting.db',
        'accounting.db.old',
        'accounting.db.backup',
      ];

      for (final fileName in importantFiles) {
        final file = File(p.join(dbFolder.path, fileName));
        final exists = await file.exists();

        result[fileName] = {
          'exists': exists,
          'size': exists ? await file.length() : 0,
        };
      }

      return result;

    } catch (e) {
      debugPrint('⚠️ [Diagnostic] خطأ في _checkImportantFiles: $e');
      return {};
    }
  }

  // ============================================================================
  // ← Hint: تصدير التقرير التشخيصي كملف JSON
  // ============================================================================

  /// تصدير التقرير التشخيصي إلى ملف
  ///
  /// Returns: مسار الملف أو null في حالة الفشل
  Future<String?> exportDiagnosticReport() async {
    try {
      debugPrint('📤 [Diagnostic] تصدير التقرير...');

      final report = await generateDiagnosticReport();

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now();
      final fileName = 'diagnostic-${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}-${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}.json';

      final file = File(p.join(tempDir.path, fileName));

      // ← Hint: كتابة JSON بتنسيق جميل
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(report),
      );

      debugPrint('✅ [Diagnostic] تم تصدير التقرير: ${file.path}');

      return file.path;

    } catch (e) {
      debugPrint('❌ [Diagnostic] خطأ في exportDiagnosticReport: $e');
      return null;
    }
  }

  // ============================================================================
  // ← Hint: تنظيف الملفات المؤقتة والاحتياطية القديمة
  // ============================================================================

  /// تنظيف الملفات القديمة
  ///
  /// [daysOld] - عمر الملفات بالأيام (افتراضي: 7)
  ///
  /// Returns: عدد الملفات المحذوفة
  Future<int> cleanupOldFiles({int daysOld = 7}) async {
    try {
      debugPrint('🧹 [Diagnostic] تنظيف الملفات القديمة...');

      int deletedCount = 0;

      final tempDir = await getTemporaryDirectory();
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      // ← Hint: البحث عن ملفات backup_* القديمة
      final entities = tempDir.listSync(recursive: true);

      for (final entity in entities) {
        if (entity is File) {
          final stat = await entity.stat();

          if (stat.modified.isBefore(cutoffDate)) {
            try {
              await entity.delete();
              deletedCount++;
              debugPrint('  🗑️ حذف: ${p.basename(entity.path)}');
            } catch (e) {
              debugPrint('  ⚠️ فشل حذف: ${p.basename(entity.path)}');
            }
          }
        }
      }

      debugPrint('✅ [Diagnostic] تم حذف $deletedCount ملف');

      return deletedCount;

    } catch (e) {
      debugPrint('❌ [Diagnostic] خطأ في cleanupOldFiles: $e');
      return 0;
    }
  }
}
