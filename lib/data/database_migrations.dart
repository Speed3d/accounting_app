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
  /// التحديثات في v2:
  /// 1. إضافة حقول جديدة لجدول TB_Users (Email, Phone, UserType, etc.)
  /// 2. إنشاء جدول TB_Subscription_Cache
  /// 3. إضافة Indexes للأداء
  static Future<void> migrateToV2(Database db) async {
    debugPrint('🔄 بدء Migration من v1 إلى v2...');

    try {
      // ========================================================================
      // 1️⃣ تعديل جدول TB_Users - إضافة الأعمدة الجديدة
      // ========================================================================

      debugPrint('  ├─ إضافة أعمدة جديدة لجدول TB_Users...');

      // Email - للـ Owner فقط
      await db.execute(
        'ALTER TABLE TB_Users ADD COLUMN Email TEXT',
      );

      // Phone - اختياري
      await db.execute(
        'ALTER TABLE TB_Users ADD COLUMN Phone TEXT',
      );

      // UserType - 'owner' أو 'sub_user'
      await db.execute(
        'ALTER TABLE TB_Users ADD COLUMN UserType TEXT NOT NULL DEFAULT "sub_user"',
      );

      // OwnerEmail - للـ Sub Users (FK to owner)
      await db.execute(
        'ALTER TABLE TB_Users ADD COLUMN OwnerEmail TEXT',
      );

      // CreatedBy - Email of creator
      await db.execute(
        'ALTER TABLE TB_Users ADD COLUMN CreatedBy TEXT',
      );

      // LastLoginAt - آخر تسجيل دخول
      await db.execute(
        'ALTER TABLE TB_Users ADD COLUMN LastLoginAt TEXT',
      );

      debugPrint('  ├─ ✅ تم إضافة الأعمدة الجديدة بنجاح');

      // ========================================================================
      // 2️⃣ إنشاء Indexes للأداء
      // ========================================================================

      debugPrint('  ├─ إنشاء Indexes...');

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_users_email ON TB_Users(Email)',
      );

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_users_owner_email ON TB_Users(OwnerEmail)',
      );

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_users_type ON TB_Users(UserType)',
      );

      debugPrint('  ├─ ✅ تم إنشاء Indexes بنجاح');

      // ========================================================================
      // 3️⃣ إنشاء جدول TB_Subscription_Cache
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
      // 4️⃣ تحديث المستخدمين الموجودين (إذا وُجدوا)
      // ========================================================================

      debugPrint('  ├─ تحديث المستخدمين الموجودين...');

      // جعل جميع المستخدمين الموجودين admin owners (للتوافقية)
      final existingUsers = await db.query('TB_Users');

      if (existingUsers.isNotEmpty) {
        debugPrint('  ├─ وُجد ${existingUsers.length} مستخدمين موجودين');
        debugPrint('  ├─ تحويلهم إلى owners...');

        for (var user in existingUsers) {
          // إذا كان المستخدم admin، نجعله owner
          if ((user['IsAdmin'] as int?) == 1) {
            await db.update(
              'TB_Users',
              {'UserType': 'owner'},
              where: 'ID = ?',
              whereArgs: [user['ID']],
            );
          }
        }

        debugPrint('  ├─ ✅ تم تحديث المستخدمين الموجودين');
      } else {
        debugPrint('  ├─ لا يوجد مستخدمين موجودين');
      }

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
