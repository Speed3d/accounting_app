// lib/data/database_migrations.dart

import 'package:flutter/foundation.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// ============================================================================
/// نظام Database Migrations الاحترافي
/// ============================================================================
/// الغرض:
/// - إدارة تحديثات قاعدة البيانات بطريقة منظمة
/// - دعم الترقية من إصدار لآخر بدون فقدان البيانات
/// - Migration تلقائي وآمن
/// ============================================================================
class DatabaseMigrations {

  // ==========================================================================
  // Migration من v1 إلى v2
  // ==========================================================================
  /// ← Hint: التحديثات في v2 (تم تبسيطها بعد حذف TB_Users):
  /// 1. إنشاء جدول TB_Subscription_Cache فقط
  /// ← Hint: تم حذف جميع الـ migrations المتعلقة بـ TB_Users - النظام الجديد يستخدم Firebase فقط
  static Future<void> migrateToV2(Database db) async {
    debugPrint('🔄 بدء Migration من v1 إلى v2...');

    try {
      // ========================================================================
      // ← Hint: تم حذف تعديلات TB_Users - Firebase Auth يدير المستخدمين
      // ========================================================================

      // ========================================================================
      // 1️⃣ إنشاء جدول TB_Subscription_Cache
      // ========================================================================

      debugPrint('  ├─ إنشاء جدول TB_Subscription_Cache...');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS TB_Subscription_Cache (
          ID INTEGER PRIMARY KEY CHECK (ID = 1),
          Email TEXT NOT NULL,
          Plan TEXT NOT NULL,
          StartDate TEXT NOT NULL,
          EndDate TEXT,
          IsActive INTEGER NOT NULL DEFAULT 1,
          MaxDevices INTEGER,
          CurrentDeviceCount INTEGER DEFAULT 0,
          CurrentDeviceId TEXT NOT NULL,
          CurrentDeviceName TEXT,
          LastSyncAt TEXT NOT NULL,
          OfflineDaysRemaining INTEGER DEFAULT 7,
          LastOnlineCheck TEXT NOT NULL,
          FeaturesJson TEXT,
          Status TEXT NOT NULL DEFAULT 'active',
          UpdatedAt TEXT NOT NULL
        )
      ''');

      debugPrint('  ├─ ✅ تم إنشاء جدول TB_Subscription_Cache بنجاح');

      // ========================================================================
      // ← Hint: تم حذف قسم تحديث المستخدمين - لا حاجة له بعد إزالة TB_Users
      // ========================================================================

      debugPrint('✅ Migration إلى v2 اكتمل بنجاح');

    } catch (e, stackTrace) {
      debugPrint('❌ خطأ في Migration إلى v2: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ==========================================================================
  // Migration من v2 إلى v3 (للمستقبل)
  // ==========================================================================
  static Future<void> migrateToV3(Database db) async {
    debugPrint('🔄 بدء Migration من v2 إلى v3...');

    try {
      // سيتم إضافة التحديثات المستقبلية هنا
      // مثال:
      // - إضافة جدول للـ Cloud Backup
      // - تحسينات أخرى

      debugPrint('✅ Migration إلى v3 اكتمل بنجاح');

    } catch (e, stackTrace) {
      debugPrint('❌ خطأ في Migration إلى v3: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ==========================================================================
  // دالة مساعدة: التحقق من وجود عمود في جدول
  // ==========================================================================
  static Future<bool> columnExists(
    Database db,
    String tableName,
    String columnName,
  ) async {
    try {
      final result = await db.rawQuery(
        'PRAGMA table_info($tableName)',
      );

      return result.any((col) => col['name'] == columnName);

    } catch (e) {
      debugPrint('⚠️ خطأ في فحص وجود العمود $columnName: $e');
      return false;
    }
  }

  // ==========================================================================
  // دالة مساعدة: التحقق من وجود جدول
  // ==========================================================================
  static Future<bool> tableExists(
    Database db,
    String tableName,
  ) async {
    try {
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName],
      );

      return result.isNotEmpty;

    } catch (e) {
      debugPrint('⚠️ خطأ في فحص وجود الجدول $tableName: $e');
      return false;
    }
  }
}
