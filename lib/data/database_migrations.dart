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
  // Migration من v2 إلى v3
  // ==========================================================================
  static Future<void> migrateToV3(Database db) async {
    debugPrint('🔄 بدء Migration من v2 إلى v3...');

    try {
      // لا توجد تحديثات في v3 - تم تخطيها

      debugPrint('✅ Migration إلى v3 اكتمل بنجاح');

    } catch (e, stackTrace) {
      debugPrint('❌ خطأ في Migration إلى v3: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ==========================================================================
  // Migration من v3 إلى v4 - نظام التصنيفات والوحدات للمنتجات
  // ==========================================================================
  /// ← Hint: التحديثات في v4:
  /// 1. إنشاء جدول TB_Product_Categories (تصنيفات المنتجات)
  /// 2. إنشاء جدول TB_Product_Units (وحدات القياس)
  /// 3. إضافة عمود CategoryID إلى جدول Store_Products
  /// 4. إضافة عمود Unit إلى جدول Store_Products
  /// 5. إضافة البيانات الافتراضية
  static Future<void> migrateToV4(Database db) async {
    debugPrint('🔄 بدء Migration من v3 إلى v4...');

    try {
      // ========================================================================
      // 1️⃣ إنشاء جدول التصنيفات
      // ========================================================================
      debugPrint('  ├─ إنشاء جدول TB_Product_Categories...');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS TB_Product_Categories (
          CategoryID INTEGER PRIMARY KEY AUTOINCREMENT,
          CategoryName TEXT NOT NULL UNIQUE,
          CategoryNameEn TEXT,
          Description TEXT,
          Icon TEXT,
          ColorCode TEXT,
          IsActive INTEGER NOT NULL DEFAULT 1,
          DisplayOrder INTEGER DEFAULT 0,
          CreatedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      debugPrint('  ├─ ✅ تم إنشاء جدول TB_Product_Categories بنجاح');

      // ========================================================================
      // 2️⃣ إنشاء جدول الوحدات
      // ========================================================================
      debugPrint('  ├─ إنشاء جدول TB_Product_Units...');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS TB_Product_Units (
          UnitID INTEGER PRIMARY KEY AUTOINCREMENT,
          UnitName TEXT NOT NULL UNIQUE,
          UnitNameEn TEXT,
          UnitSymbol TEXT,
          IsActive INTEGER NOT NULL DEFAULT 1,
          DisplayOrder INTEGER DEFAULT 0,
          CreatedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      debugPrint('  ├─ ✅ تم إنشاء جدول TB_Product_Units بنجاح');

      // ========================================================================
      // 3️⃣ إضافة أعمدة جديدة لجدول Store_Products
      // ========================================================================
      debugPrint('  ├─ إضافة أعمدة جديدة لجدول Store_Products...');

      // التحقق من وجود العمود قبل الإضافة
      if (!await columnExists(db, 'Store_Products', 'CategoryID')) {
        await db.execute(
          'ALTER TABLE Store_Products ADD COLUMN CategoryID INTEGER REFERENCES TB_Product_Categories(CategoryID)'
        );
        debugPrint('    ├─ ✅ تم إضافة عمود CategoryID');
      }

      if (!await columnExists(db, 'Store_Products', 'Unit')) {
        await db.execute(
          'ALTER TABLE Store_Products ADD COLUMN Unit TEXT'
        );
        debugPrint('    ├─ ✅ تم إضافة عمود Unit');
      }

      // ========================================================================
      // 4️⃣ إضافة البيانات الافتراضية - التصنيفات
      // ========================================================================
      debugPrint('  ├─ إضافة التصنيفات الافتراضية...');

      final defaultCategories = [
        {'name': 'إلكترونيات', 'nameEn': 'Electronics', 'icon': 'devices', 'color': '#2196F3', 'order': 1},
        {'name': 'أثاث', 'nameEn': 'Furniture', 'icon': 'chair', 'color': '#795548', 'order': 2},
        {'name': 'ملابس', 'nameEn': 'Clothing', 'icon': 'checkroom', 'color': '#E91E63', 'order': 3},
        {'name': 'أغذية', 'nameEn': 'Food', 'icon': 'restaurant', 'color': '#4CAF50', 'order': 4},
        {'name': 'أدوات منزلية', 'nameEn': 'Home Appliances', 'icon': 'home', 'color': '#FF9800', 'order': 5},
        {'name': 'مستلزمات مكتبية', 'nameEn': 'Office Supplies', 'icon': 'work', 'color': '#9C27B0', 'order': 6},
        {'name': 'مستحضرات تجميل', 'nameEn': 'Cosmetics', 'icon': 'face', 'color': '#F06292', 'order': 7},
        {'name': 'أدوية', 'nameEn': 'Pharmaceuticals', 'icon': 'medication', 'color': '#00BCD4', 'order': 8},
        {'name': 'أخرى', 'nameEn': 'Others', 'icon': 'category', 'color': '#607D8B', 'order': 99},
      ];

      for (var category in defaultCategories) {
        await db.insert(
          'TB_Product_Categories',
          {
            'CategoryName': category['name'],
            'CategoryNameEn': category['nameEn'],
            'Icon': category['icon'],
            'ColorCode': category['color'],
            'DisplayOrder': category['order'],
            'IsActive': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      debugPrint('  ├─ ✅ تم إضافة ${defaultCategories.length} تصنيف افتراضي');

      // ========================================================================
      // 5️⃣ إضافة البيانات الافتراضية - الوحدات
      // ========================================================================
      debugPrint('  ├─ إضافة الوحدات الافتراضية...');

      final defaultUnits = [
        {'name': 'حبة', 'nameEn': 'Piece', 'symbol': 'قطعة', 'order': 1},
        {'name': 'كرتون', 'nameEn': 'Carton', 'symbol': 'كرتون', 'order': 2},
        {'name': 'كيلو', 'nameEn': 'Kilogram', 'symbol': 'كغ', 'order': 3},
        {'name': 'جرام', 'nameEn': 'Gram', 'symbol': 'غ', 'order': 4},
        {'name': 'لتر', 'nameEn': 'Liter', 'symbol': 'ل', 'order': 5},
        {'name': 'متر', 'nameEn': 'Meter', 'symbol': 'م', 'order': 6},
        {'name': 'علبة', 'nameEn': 'Box', 'symbol': 'علبة', 'order': 7},
        {'name': 'صندوق', 'nameEn': 'Crate', 'symbol': 'صندوق', 'order': 8},
        {'name': 'دزينة', 'nameEn': 'Dozen', 'symbol': 'دزينة', 'order': 9},
        {'name': 'عبوة', 'nameEn': 'Package', 'symbol': 'عبوة', 'order': 10},
      ];

      for (var unit in defaultUnits) {
        await db.insert(
          'TB_Product_Units',
          {
            'UnitName': unit['name'],
            'UnitNameEn': unit['nameEn'],
            'UnitSymbol': unit['symbol'],
            'DisplayOrder': unit['order'],
            'IsActive': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      debugPrint('  ├─ ✅ تم إضافة ${defaultUnits.length} وحدة افتراضية');

      debugPrint('✅ Migration إلى v4 اكتمل بنجاح');

    } catch (e, stackTrace) {
      debugPrint('❌ خطأ في Migration إلى v4: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ==========================================================================
  // Migration من v4 إلى v5 - نظام تسديدات السلف
  // ==========================================================================
  /// ← Hint: التحديثات في v5:
  /// 1. إنشاء جدول TB_Advance_Repayments (تسديدات السلف)
  /// ← Hint: هذا الجدول يسجل كل عملية تسديد للسلف (كامل أو جزئي)
  /// ← Hint: يتيح للموظفين تسديد السلف على دفعات
  /// ← Hint: يظهر التسديد في تقرير التدفقات النقدية كإيراد
  static Future<void> migrateToV5(Database db) async {
    debugPrint('🔄 بدء Migration من v4 إلى v5...');

    try {
      // ========================================================================
      // 1️⃣ إنشاء جدول تسديدات السلف
      // ========================================================================
      debugPrint('  ├─ إنشاء جدول TB_Advance_Repayments...');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS TB_Advance_Repayments (
          RepaymentID INTEGER PRIMARY KEY AUTOINCREMENT,
          AdvanceID INTEGER NOT NULL,
          EmployeeID INTEGER NOT NULL,
          RepaymentDate TEXT NOT NULL,
          RepaymentAmount REAL NOT NULL,
          Notes TEXT,
          CreatedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (AdvanceID) REFERENCES TB_Employee_Advances(AdvanceID) ON DELETE CASCADE,
          FOREIGN KEY (EmployeeID) REFERENCES TB_Employees(EmployeeID) ON DELETE CASCADE
        )
      ''');

      debugPrint('  ├─ ✅ تم إنشاء جدول TB_Advance_Repayments بنجاح');

      // ========================================================================
      // 2️⃣ إنشاء مؤشرات لتحسين الأداء
      // ========================================================================
      debugPrint('  ├─ إنشاء المؤشرات...');

      // ← Hint: مؤشر على AdvanceID لتسريع البحث عن تسديدات سلفة معينة
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_repayments_advance
        ON TB_Advance_Repayments(AdvanceID)
      ''');

      // ← Hint: مؤشر على EmployeeID لتسريع البحث عن تسديدات موظف معين
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_repayments_employee
        ON TB_Advance_Repayments(EmployeeID)
      ''');

      // ← Hint: مؤشر على RepaymentDate لتسريع الاستعلامات حسب الفترة الزمنية
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_repayments_date
        ON TB_Advance_Repayments(RepaymentDate)
      ''');

      debugPrint('  ├─ ✅ تم إنشاء المؤشرات بنجاح');

      debugPrint('✅ Migration إلى v5 اكتمل بنجاح');

    } catch (e, stackTrace) {
      debugPrint('❌ خطأ في Migration إلى v5: $e');
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
