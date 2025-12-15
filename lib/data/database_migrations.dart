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
// Migration من v3 إلى v4 - نظام التصنيفات والوحدات المبسط
// ==========================================================================
/// ← Hint: التحديثات في v4 (النسخة المبسطة):
/// 1. إنشاء جدول TB_ProductCategory (بسيط: اسم عربي + اسم إنجليزي)
/// 2. إنشاء جدول TB_ProductUnit (بسيط: اسم عربي + اسم إنجليزي)
/// 3. إضافة عمود CategoryID و UnitID إلى جدول Store_Products
/// 4. إضافة البيانات الافتراضية (2 تصنيف + 2 وحدة)
static Future<void> migrateToV4(Database db) async {
  debugPrint('🔄 بدء Migration من v3 إلى v4...');

  try {
    // ========================================================================
    // 1️⃣ إنشاء جدول التصنيفات (النسخة المبسطة)
    // ========================================================================
    // ← Hint: فقط: CategoryNameAr, CategoryNameEn, IsActive, CreatedAt
    // ← Hint: تم حذف: Icon, ColorCode, DisplayOrder, Description
    debugPrint('  ├─ إنشاء جدول TB_ProductCategory...');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS TB_ProductCategory (
        CategoryID INTEGER PRIMARY KEY AUTOINCREMENT,
        CategoryNameAr TEXT NOT NULL,
        CategoryNameEn TEXT NOT NULL,
        IsActive INTEGER DEFAULT 1,
        CreatedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    debugPrint('  ├─ ✅ تم إنشاء جدول TB_ProductCategory بنجاح');

    // ========================================================================
    // 2️⃣ إنشاء جدول الوحدات (النسخة المبسطة)
    // ========================================================================
    // ← Hint: فقط: UnitNameAr, UnitNameEn, IsActive, CreatedAt
    // ← Hint: تم حذف: UnitSymbol, DisplayOrder
    debugPrint('  ├─ إنشاء جدول TB_ProductUnit...');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS TB_ProductUnit (
        UnitID INTEGER PRIMARY KEY AUTOINCREMENT,
        UnitNameAr TEXT NOT NULL,
        UnitNameEn TEXT NOT NULL,
        IsActive INTEGER DEFAULT 1,
        CreatedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    debugPrint('  ├─ ✅ تم إنشاء جدول TB_ProductUnit بنجاح');

    // ========================================================================
    // 3️⃣ إضافة البيانات الافتراضية البسيطة (2 + 2)
    // ========================================================================
    debugPrint('  ├─ إضافة التصنيفات والوحدات الافتراضية...');

    // ← Hint: التصنيفات الافتراضية
    await db.insert('TB_ProductCategory', {
      'CategoryNameAr': 'عام',
      'CategoryNameEn': 'General',
      'IsActive': 1,
    });

    await db.insert('TB_ProductCategory', {
      'CategoryNameAr': 'أخرى',
      'CategoryNameEn': 'Other',
      'IsActive': 1,
    });

    // ← Hint: الوحدات الافتراضية
    await db.insert('TB_ProductUnit', {
      'UnitNameAr': 'قطعة',
      'UnitNameEn': 'Piece',
      'IsActive': 1,
    });

    await db.insert('TB_ProductUnit', {
      'UnitNameAr': 'كيلو',
      'UnitNameEn': 'Kilogram',
      'IsActive': 1,
    });

    debugPrint('  ├─ ✅ تم إضافة البيانات الافتراضية');

    // ========================================================================
    // 4️⃣ إضافة أعمدة جديدة لجدول Store_Products
    // ========================================================================
    debugPrint('  ├─ إضافة أعمدة جديدة لجدول Store_Products...');

    // ← Hint: التحقق من وجود العمود قبل الإضافة
    if (!await columnExists(db, 'Store_Products', 'CategoryID')) {
      await db.execute(
        'ALTER TABLE Store_Products ADD COLUMN CategoryID INTEGER'
      );
      debugPrint('    ├─ ✅ تم إضافة عمود CategoryID');
    }

    if (!await columnExists(db, 'Store_Products', 'UnitID')) {
      await db.execute(
        'ALTER TABLE Store_Products ADD COLUMN UnitID INTEGER'
      );
      debugPrint('    ├─ ✅ تم إضافة عمود UnitID');
    }

    // ========================================================================
    // 5️⃣ تحديث المنتجات الموجودة لتأخذ الوحدة والتصنيف الافتراضي
    // ========================================================================
    // ← Hint: الوحدة الافتراضية = "قطعة" (UnitID = 1)
    // ← Hint: التصنيف الافتراضي = "عام" (CategoryID = 1)
    await db.execute(
      'UPDATE Store_Products SET UnitID = 1, CategoryID = 1 WHERE UnitID IS NULL'
    );
    debugPrint('  ├─ ✅ تم تحديث المنتجات الموجودة');

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
  // Migration من v5 إلى v6 - نظام السنوات المالية والقيود المحاسبية
  // ==========================================================================
  /// ← Hint: التحديثات في v6 (النظام المحاسبي الاحترافي):
  /// 1. إنشاء جدول TB_FiscalYears (السنوات المالية)
  /// 2. إنشاء جدول TB_Transactions (القيود المالية الموحدة)
  /// 3. إضافة عمود FiscalYearID لكل الجداول المالية
  /// 4. إنشاء سنة مالية افتراضية (سنة 2025)
  /// 5. إنشاء indexes لتحسين الأداء
  /// ← Hint: هذا النظام يحول التطبيق إلى نظام محاسبي احترافي كامل
  static Future<void> migrateToV6(Database db) async {
    debugPrint('🔄 بدء Migration من v5 إلى v6 (نظام السنوات المالية)...');

    try {
      // ========================================================================
      // 1️⃣ إنشاء جدول السنوات المالية
      // ========================================================================
      debugPrint('  ├─ إنشاء جدول TB_FiscalYears...');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS TB_FiscalYears (
          FiscalYearID INTEGER PRIMARY KEY AUTOINCREMENT,
          Name TEXT NOT NULL,
          Year INTEGER NOT NULL,
          StartDate TEXT NOT NULL,
          EndDate TEXT NOT NULL,
          IsClosed INTEGER NOT NULL DEFAULT 0,
          IsActive INTEGER NOT NULL DEFAULT 0,
          OpeningBalance REAL NOT NULL DEFAULT 0.0,
          TotalIncome REAL NOT NULL DEFAULT 0.0,
          TotalExpense REAL NOT NULL DEFAULT 0.0,
          NetProfit REAL NOT NULL DEFAULT 0.0,
          ClosingBalance REAL NOT NULL DEFAULT 0.0,
          Notes TEXT,
          CreatedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          ClosedAt TEXT,
          UNIQUE(Year)
        )
      ''');

      debugPrint('  ├─ ✅ تم إنشاء جدول TB_FiscalYears بنجاح');

      // ========================================================================
      // 2️⃣ إنشاء جدول القيود المالية الموحدة
      // ========================================================================
      // ← Hint: هذا الجدول هو قلب النظام المحاسبي
      // ← Hint: كل عملية (مبيعات، رواتب، إلخ) تسجل هنا تلقائياً
      debugPrint('  ├─ إنشاء جدول TB_Transactions...');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS TB_Transactions (
          TransactionID INTEGER PRIMARY KEY AUTOINCREMENT,
          FiscalYearID INTEGER NOT NULL,
          Date TEXT NOT NULL,
          Type TEXT NOT NULL,
          Category TEXT NOT NULL,
          Amount REAL NOT NULL,
          Direction TEXT NOT NULL,
          Description TEXT NOT NULL,
          Notes TEXT,
          ReferenceType TEXT,
          ReferenceID INTEGER,
          CustomerID INTEGER,
          SupplierID INTEGER,
          EmployeeID INTEGER,
          ProductID INTEGER,
          CreatedBy INTEGER,
          CreatedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (FiscalYearID) REFERENCES TB_FiscalYears(FiscalYearID) ON DELETE RESTRICT,
          FOREIGN KEY (CustomerID) REFERENCES TB_Customers(CustomerID) ON DELETE SET NULL,
          FOREIGN KEY (SupplierID) REFERENCES TB_Suppliers(SupplierID) ON DELETE SET NULL,
          FOREIGN KEY (EmployeeID) REFERENCES TB_Employees(EmployeeID) ON DELETE SET NULL,
          FOREIGN KEY (ProductID) REFERENCES Store_Products(ProductID) ON DELETE SET NULL
        )
      ''');

      debugPrint('  ├─ ✅ تم إنشاء جدول TB_Transactions بنجاح');

      // ========================================================================
      // 3️⃣ إضافة عمود FiscalYearID للجداول المالية
      // ========================================================================
      // ← Hint: إضافة السنة المالية لكل الجداول التي تحتوي عمليات مالية
      debugPrint('  ├─ إضافة عمود FiscalYearID للجداول المالية...');

      // ← Hint: قائمة الجداول التي نحتاج لإضافة FiscalYearID لها
      final tables = [
        'TB_Customer_Debts',      // ديون العملاء (مبيعات)
        'TB_Customer_Payments',   // دفعات العملاء
        'TB_Payroll',             // رواتب الموظفين
        'TB_Employee_Advances',   // سلف الموظفين
        'TB_Employee_Bonuses',    // مكافآت الموظفين
        'TB_Advance_Repayments',  // تسديدات السلف
        'TB_Sales_Returns',       // مرتجعات المبيعات
      ];

      for (final tableName in tables) {
        // ← Hint: التحقق من وجود الجدول أولاً
        final exists = await tableExists(db, tableName);
        if (exists) {
          // ← Hint: التحقق من عدم وجود العمود قبل الإضافة
          if (!await columnExists(db, tableName, 'FiscalYearID')) {
            await db.execute(
              'ALTER TABLE $tableName ADD COLUMN FiscalYearID INTEGER'
            );
            debugPrint('    ├─ ✅ تم إضافة FiscalYearID إلى $tableName');
          }
        }
      }

      // ========================================================================
      // 4️⃣ إنشاء سنة مالية افتراضية (2025)
      // ========================================================================
      // ← Hint: إنشاء سنة مالية نشطة لسنة 2025
      // ← Hint: هذه السنة ستكون النشطة افتراضياً
      debugPrint('  ├─ إنشاء سنة مالية افتراضية (2025)...');

      final currentYear = DateTime.now().year;
      final defaultYear = currentYear >= 2025 ? currentYear : 2025;

      await db.insert('TB_FiscalYears', {
        'Name': 'سنة $defaultYear',
        'Year': defaultYear,
        'StartDate': '$defaultYear-01-01T00:00:00.000',
        'EndDate': '$defaultYear-12-31T23:59:59.999',
        'IsClosed': 0,
        'IsActive': 1,
        'OpeningBalance': 0.0,
        'TotalIncome': 0.0,
        'TotalExpense': 0.0,
        'NetProfit': 0.0,
        'ClosingBalance': 0.0,
        'Notes': 'السنة المالية الافتراضية - تم إنشاؤها تلقائياً',
      });

      debugPrint('  ├─ ✅ تم إنشاء السنة المالية الافتراضية ($defaultYear)');

      // ========================================================================
      // 5️⃣ تحديث السجلات الموجودة لتنتمي للسنة المالية الافتراضية
      // ========================================================================
      // ← Hint: ربط كل السجلات الموجودة بالسنة المالية الافتراضية (ID = 1)
      debugPrint('  ├─ ربط السجلات الموجودة بالسنة المالية الافتراضية...');

      for (final tableName in tables) {
        final exists = await tableExists(db, tableName);
        if (exists) {
          await db.execute(
            'UPDATE $tableName SET FiscalYearID = 1 WHERE FiscalYearID IS NULL'
          );
        }
      }

      debugPrint('  ├─ ✅ تم ربط السجلات الموجودة بالسنة المالية الافتراضية');

      // ========================================================================
      // 6️⃣ إنشاء Indexes لتحسين الأداء
      // ========================================================================
      debugPrint('  ├─ إنشاء المؤشرات لتحسين الأداء...');

      // ← Hint: مؤشر على السنة المالية النشطة (استعلام متكرر)
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_fiscal_years_active
        ON TB_FiscalYears(IsActive)
      ''');

      // ← Hint: مؤشر على رقم السنة (للبحث السريع)
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_fiscal_years_year
        ON TB_FiscalYears(Year)
      ''');

      // ← Hint: مؤشر على FiscalYearID في Transactions (استعلام متكرر جداً)
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_transactions_fiscal_year
        ON TB_Transactions(FiscalYearID)
      ''');

      // ← Hint: مؤشر على التاريخ (للفلترة حسب الفترة)
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_transactions_date
        ON TB_Transactions(Date)
      ''');

      // ← Hint: مؤشر على نوع القيد (للفلترة حسب النوع)
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_transactions_type
        ON TB_Transactions(Type)
      ''');

      // ← Hint: مؤشر على اتجاه القيد (دخل/صرف - للتقارير)
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_transactions_direction
        ON TB_Transactions(Direction)
      ''');

      // ← Hint: مؤشر مركب: السنة المالية + التاريخ (أكثر الاستعلامات شيوعاً)
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_transactions_fiscal_date
        ON TB_Transactions(FiscalYearID, Date)
      ''');

      // ← Hint: مؤشر مركب: السنة المالية + النوع (للتقارير التفصيلية)
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_transactions_fiscal_type
        ON TB_Transactions(FiscalYearID, Type)
      ''');

      debugPrint('  ├─ ✅ تم إنشاء جميع المؤشرات بنجاح');

      // ========================================================================
      // 7️⃣ إنشاء Trigger لتحديث الأرصدة تلقائياً
      // ========================================================================
      // ← Hint: عند إضافة قيد جديد، نحدث أرصدة السنة المالية تلقائياً
      debugPrint('  ├─ إنشاء Triggers للتحديث التلقائي...');

      // ← Hint: Trigger عند إضافة قيد جديد
      await db.execute('''
        CREATE TRIGGER IF NOT EXISTS trg_update_fiscal_on_insert
        AFTER INSERT ON TB_Transactions
        BEGIN
          UPDATE TB_FiscalYears
          SET
            TotalIncome = (
              SELECT COALESCE(SUM(Amount), 0)
              FROM TB_Transactions
              WHERE FiscalYearID = NEW.FiscalYearID AND Direction = 'in'
            ),
            TotalExpense = (
              SELECT COALESCE(SUM(Amount), 0)
              FROM TB_Transactions
              WHERE FiscalYearID = NEW.FiscalYearID AND Direction = 'out'
            )
          WHERE FiscalYearID = NEW.FiscalYearID;

          UPDATE TB_FiscalYears
          SET
            NetProfit = TotalIncome - TotalExpense,
            ClosingBalance = OpeningBalance + (TotalIncome - TotalExpense)
          WHERE FiscalYearID = NEW.FiscalYearID;
        END;
      ''');

      // ← Hint: Trigger عند حذف قيد
      await db.execute('''
        CREATE TRIGGER IF NOT EXISTS trg_update_fiscal_on_delete
        AFTER DELETE ON TB_Transactions
        BEGIN
          UPDATE TB_FiscalYears
          SET
            TotalIncome = (
              SELECT COALESCE(SUM(Amount), 0)
              FROM TB_Transactions
              WHERE FiscalYearID = OLD.FiscalYearID AND Direction = 'in'
            ),
            TotalExpense = (
              SELECT COALESCE(SUM(Amount), 0)
              FROM TB_Transactions
              WHERE FiscalYearID = OLD.FiscalYearID AND Direction = 'out'
            )
          WHERE FiscalYearID = OLD.FiscalYearID;

          UPDATE TB_FiscalYears
          SET
            NetProfit = TotalIncome - TotalExpense,
            ClosingBalance = OpeningBalance + (TotalIncome - TotalExpense)
          WHERE FiscalYearID = OLD.FiscalYearID;
        END;
      ''');

      debugPrint('  ├─ ✅ تم إنشاء Triggers التحديث التلقائي');

      debugPrint('✅ Migration إلى v6 اكتمل بنجاح - تم تفعيل نظام السنوات المالية! 🎉');

    } catch (e, stackTrace) {
      debugPrint('❌ خطأ في Migration إلى v6: $e');
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
