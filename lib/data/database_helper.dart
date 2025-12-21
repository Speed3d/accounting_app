import 'dart:io';
import 'package:accountant_touch/services/database_key_manager.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:accountant_touch/data/models.dart';
// import 'package:sqflite/sqflite.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../services/database_key_manager.dart';
import 'database_migrations.dart';  // 🆕 استيراد نظام الـ Migrations
import '../helpers/financial_integration_helper.dart';  // 🆕 استيراد مساعد الربط المالي

import 'models.dart' as models;

// ============================================================================
// ← Hint: استثناء مخصص لأخطاء استرداد قاعدة البيانات
// ============================================================================

class DatabaseRecoveryException implements Exception {
  final String message;
  DatabaseRecoveryException(this.message);

  @override
  String toString() => 'DatabaseRecoveryException: $message';
}

// ============================================================================
// Hint: هذا الكلاس هو المسؤول الوحيد عن كل عمليات قاعدة البيانات في التطبيق.
// ============================================================================
class DatabaseHelper {
  static const _databaseName = "accounting.db";

  // --- ✅ الخطوة 1: تحديد الإصدار النهائي ---
  // Version 1: الهيكل الأساسي
  // Version 2: إضافة جدول TB_Employee_Bonuses
  // Version 3: 🆕 النظام الجديد - Email Auth + Subscriptions
  // Version 4: ✅ نظام الوحدات والتصنيفات للمنتجات
  // Version 5: ✅ نظام تسديدات السلف (TB_Advance_Repayments)
  // Version 7: 🔧 إصلاحات DELETE/UPDATE triggers + منطق البيع النقدي/الآجل
  // Version 8: 🔧 UPDATE triggers للسنوات المالية والموظفين + إصلاح المرتجعات
  // Version 9: 🔧 إصلاح ReferenceType للسلف في triggers (employee_advance → advance)
  // Version 10: ✨ قيد واحد لكل فاتورة (بدلاً من قيد لكل منتج) + triggers المرتجعات
  // Version 11: 🏦 نظام الحسابات المحاسبي الكامل (Chart of Accounts) + محاسبة مزدوجة القيد
  // ← Hint: v5 يضيف جدول تسديدات السلف لتسجيل عمليات التسديد الكاملة أو الجزئية
  // ← Hint: v6 يحول التطبيق إلى نظام محاسبي احترافي مع قيود مالية موحدة وإقفال سنوات
  // ← Hint: v7 يضيف triggers للحذف والتعديل التلقائي + إصلاح منطق البيع (نقدي vs آجل)
  // ← Hint: v8 يضيف UPDATE trigger للسنوات المالية + 4 triggers للموظفين + إصلاح منطق المرتجعات
  // ← Hint: v9 يصلح عدم التطابق في ReferenceType للسلف ليعمل التعديل والحذف بشكل صحيح
  // ← Hint: v10 يحوّل النظام من قيد لكل منتج إلى قيد واحد لكل فاتورة (تقارير أنظف)
  // ← Hint: v11 يضيف جدول TB_Accounts + 12 حساب افتراضي + Triggers لتحديث الأرصدة تلقائياً
  static const _databaseVersion = 11;

    // --- ✅ تعريف الاسم الرمزي الثابت للزبون النقدي ---
  static const String cashCustomerInternalName = '_CASH_CUSTOMER_';


  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();


  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();

    // ✅ إصلاح: تنظيف البيانات القديمة (مرة واحدة فقط)
    await cleanupCategoriesAndUnits();

    return _database!;
  }

  // ============================================================================
  // ← Hint: إغلاق قاعدة البيانات ومسح الـ Cache
  // ← Hint: مفيد عند استعادة نسخة احتياطية لإجبار إعادة فتح القاعدة
  // ============================================================================
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      debugPrint('🔒 [DatabaseHelper] تم إغلاق قاعدة البيانات ومسح الـ Cache');
    }
  }


  // ============================================================================
  // ← Hint: تهيئة قاعدة البيانات - النسخة المحسّنة مع معالجة أخطاء
  // ============================================================================

  _initDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, _databaseName);

      // ═══════════════════════════════════════════════════════════
      // 🔐 الحصول على مفتاح التشفير
      // ← Hint: نظام المفاتيح المحسّن (v2.0)
      // ═══════════════════════════════════════════════════════════

      debugPrint('📂 [DatabaseHelper] مسار قاعدة البيانات: $path');

      final encryptionKey = await DatabaseKeyManager.instance.getDatabaseKey();
      debugPrint('🔐 [DatabaseHelper] تم الحصول على مفتاح التشفير');

      // ═══════════════════════════════════════════════════════════
      // محاولة فتح قاعدة البيانات
      // ← Hint: مع معالجة شاملة للأخطاء
      // ═══════════════════════════════════════════════════════════

      try {
        debugPrint('🔓 [DatabaseHelper] محاولة فتح قاعدة البيانات...');

        final db = await openDatabase(
          path,
          version: _databaseVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
          password: encryptionKey,
        );

        debugPrint('✅ [DatabaseHelper] تم فتح قاعدة البيانات بنجاح');
        return db;

      } on DatabaseException catch (e) {
        // ═══════════════════════════════════════════════════════════
        // معالجة أخطاء قاعدة البيانات
        // ← Hint: قد يكون السبب: مفتاح خاطئ، قاعدة تالفة، إلخ
        // ═══════════════════════════════════════════════════════════

        debugPrint('❌ [DatabaseHelper] خطأ في فتح قاعدة البيانات: $e');

        // ← Hint: التحقق من نوع الخطأ - رسائل خطأ SQLCipher الشائعة
        final errorString = e.toString().toLowerCase();

        if (errorString.contains('file is not a database') ||
            errorString.contains('file is encrypted') ||
            errorString.contains('notadb') ||
            errorString.contains('unsupported file format') ||
            errorString.contains('cipher') ||
            errorString.contains('decrypt') ||
            errorString.contains('invalid key') ||
            errorString.contains('wrong password') ||
            errorString.contains('database disk image is malformed') ||
            errorString.contains('sqlite_notadb')) {

          debugPrint('⚠️ [DatabaseHelper] قاعدة البيانات مشفرة بمفتاح مختلف أو تالفة');
          debugPrint('   الخطأ: $errorString');

          // ============================================================================
          // 🔥 الحل الجذري: حذف القاعدة الفاسدة وإنشاء واحدة جديدة
          // ============================================================================
          // ← Hint: هذا يحدث عادة عند:
          //    1. حذف التطبيق وإعادة تثبيته (مفتاح جديد ≠ مفتاح قديم)
          //    2. قاعدة البيانات تالفة فعلياً
          // ← Hint: الحل: نحذف القاعدة القديمة ونبدأ من جديد
          // ============================================================================

          debugPrint('🗑️ [DatabaseHelper] حذف قاعدة البيانات الفاسدة...');

          final dbFile = File(path);
          if (await dbFile.exists()) {
            await dbFile.delete();
            debugPrint('✅ [DatabaseHelper] تم حذف القاعدة الفاسدة');
          }

          // ← Hint: إنشاء قاعدة بيانات جديدة ونظيفة
          debugPrint('🆕 [DatabaseHelper] إنشاء قاعدة بيانات جديدة...');

          final newDb = await openDatabase(
            path,
            version: _databaseVersion,
            onCreate: _onCreate,
            onUpgrade: _onUpgrade,
            password: encryptionKey,
          );

          debugPrint('✅ [DatabaseHelper] تم إنشاء قاعدة بيانات جديدة بنجاح');
          debugPrint('💡 [DatabaseHelper] يمكنك الآن إنشاء حساب مدير جديد');

          return newDb;
        }

        // ← Hint: خطأ آخر غير متوقع
        rethrow;
      }

    } catch (e, stackTrace) {
      debugPrint('❌ [DatabaseHelper] خطأ حرج في _initDatabase: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ============================================================================
  // ← Hint: محاولة استرداد قاعدة البيانات من نسخة احتياطية
  // ← Hint: يبحث عن .db.old أو .db.backup
  // ============================================================================

  Future<Database?> _attemptDatabaseRecovery(String dbPath, String encryptionKey) async {
    try {
      debugPrint('🔄 [DatabaseHelper] محاولة استرداد قاعدة البيانات...');

      // ← Hint: قائمة بملفات النسخ الاحتياطية المحتملة
      final backupPaths = [
        '$dbPath.old',
        '$dbPath.backup',
        '$dbPath-backup',
      ];

      for (final backupPath in backupPaths) {
        final backupFile = File(backupPath);

        if (await backupFile.exists()) {
          debugPrint('📂 [DatabaseHelper] وُجدت نسخة احتياطية: $backupPath');

          try {
            // ← Hint: محاولة فتح النسخة الاحتياطية
            final db = await openDatabase(
              backupPath,
              version: _databaseVersion,
              onCreate: _onCreate,
              onUpgrade: _onUpgrade,
              password: encryptionKey,
            );

            // ← Hint: إذا نجحت، ننسخها مكان القاعدة الأصلية
            await db.close();

            final originalFile = File(dbPath);
            if (await originalFile.exists()) {
              await originalFile.delete();
            }

            await backupFile.copy(dbPath);

            // ← Hint: فتح القاعدة المستردة
            final restoredDb = await openDatabase(
              dbPath,
              version: _databaseVersion,
              onCreate: _onCreate,
              onUpgrade: _onUpgrade,
              password: encryptionKey,
            );

            debugPrint('✅ [DatabaseHelper] تم الاسترداد من: $backupPath');
            return restoredDb;

          } catch (e) {
            debugPrint('⚠️ [DatabaseHelper] فشل الاسترداد من: $backupPath - $e');
            continue;
          }
        }
      }

      debugPrint('❌ [DatabaseHelper] لم يتم العثور على نسخة احتياطية صالحة');
      return null;

    } catch (e) {
      debugPrint('❌ [DatabaseHelper] خطأ في _attemptDatabaseRecovery: $e');
      return null;
    }
  }

///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////

  // --- ✅ الخطوة 2: دالة `_onCreate` المثالية ---
  // Hint: هذه الدالة تحتوي على الشكل النهائي لقاعدة البيانات.
  // سيتم استدعاؤها عند تثبيت التطبيق لأول مرة.

  Future _onCreate(Database db, int version) async {
    var batch = db.batch();

    // ← Hint: تم حذف جدول TB_Users - النظام الجديد يستخدم Firebase Auth فقط
    // ← Hint: لا حاجة لتخزين بيانات المستخدمين محلياً، كل شيء يدار عبر Firebase Authentication & Firestore

    // 🆕 v3: جدول Subscription Cache
    // ← Hint: Schema موحّد يطابق migration للتوافق الكامل
    batch.execute('''
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


      // --- جداول الموظفين ---
    batch.execute('''
      CREATE TABLE TB_Employees (
        EmployeeID INTEGER PRIMARY KEY AUTOINCREMENT, 
        FullName TEXT NOT NULL, 
        jobTitle TEXT NOT NULL, 
        Address TEXT, Phone TEXT, 
        ImagePath TEXT, HireDate TEXT NOT NULL, 
        BaseSalary REAL NOT NULL DEFAULT 0.0, 
        Balance REAL NOT NULL DEFAULT 0.0, 
        IsActive INTEGER NOT NULL DEFAULT 1
      )
    ''');
    batch.execute('''
      CREATE TABLE TB_Payroll (
        PayrollID INTEGER PRIMARY KEY AUTOINCREMENT, 
        EmployeeID INTEGER NOT NULL, 
        PaymentDate TEXT NOT NULL, 
        PayrollMonth INTEGER NOT NULL,
        PayrollYear INTEGER NOT NULL, 
        BaseSalary REAL NOT NULL, 
        Bonuses REAL NOT NULL DEFAULT 0.0, 
        Deductions REAL NOT NULL DEFAULT 0.0, 
        AdvanceDeduction REAL NOT NULL DEFAULT 0.0, 
        NetSalary REAL NOT NULL, Notes TEXT
      )
    ''');
    // --- إصلاح اسم الجدول ---
    batch.execute('''
      CREATE TABLE TB_Employee_Advances (
        AdvanceID INTEGER PRIMARY KEY AUTOINCREMENT,
        EmployeeID INTEGER NOT NULL,
        AdvanceDate TEXT NOT NULL,
        AdvanceAmount REAL NOT NULL,
        RepaymentStatus TEXT NOT NULL, Notes TEXT
      )
    ''');

    // ← Hint: جدول تسديدات السلف (Advance Repayments) - مُضاف في v5
    // ← Hint: يسجل كل عملية تسديد للسلف (كامل أو جزئي)
    // ← Hint: يتيح للموظفين تسديد السلف على دفعات
    // ← Hint: يظهر التسديد في تقرير التدفقات النقدية كإيراد
    batch.execute('''
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

    // ← Hint: جدول المكافآت للموظفين (Employee Bonuses)
    // ← Hint: يحتوي على جميع المكافآت والحوافز الممنوحة للموظفين
    batch.execute('''
      CREATE TABLE TB_Employee_Bonuses (
        BonusID INTEGER PRIMARY KEY AUTOINCREMENT,
        EmployeeID INTEGER NOT NULL,
        BonusDate TEXT NOT NULL,
        BonusAmount REAL NOT NULL,
        BonusReason TEXT,
        Notes TEXT,
        FOREIGN KEY (EmployeeID) REFERENCES TB_Employees (EmployeeID)
      )
    ''');


    batch.execute('''
      CREATE TABLE TB_Suppliers (
      SupplierID INTEGER PRIMARY KEY AUTOINCREMENT, 
      SupplierName TEXT NOT NULL, 
      SupplierType TEXT NOT NULL, 
      Address TEXT, Phone TEXT, 
      Notes TEXT, 
      DateAdded TEXT NOT NULL, 
      ImagePath TEXT, 
      IsActive INTEGER NOT NULL DEFAULT 1)
    ''');

    batch.execute('''
      CREATE TABLE Supplier_Partners (
        PartnerID INTEGER PRIMARY KEY AUTOINCREMENT, 
        SupplierID INTEGER NOT NULL, 
        PartnerName TEXT NOT NULL, 
        SharePercentage REAL NOT NULL, 
        PartnerAddress TEXT, 
        PartnerPhone TEXT, 
        ImagePath TEXT,
        DateAdded TEXT NOT NULL, 
        Notes TEXT
      )
    ''');

    batch.execute('''
       CREATE TABLE TB_Profit_Withdrawals (
          WithdrawalID INTEGER PRIMARY KEY AUTOINCREMENT,
          SupplierID INTEGER NOT NULL,
          PartnerName TEXT,
          WithdrawalAmount REAL NOT NULL,
          WithdrawalDate TEXT NOT NULL,
          Notes TEXT
        )
      ''');

   // ============================================================================
   // 🎨 جدول التصنيفات (النسخة المبسطة)
   // ============================================================================
   // ← Hint: فقط اسمين (عربي + إنجليزي) + IsActive + CreatedAt
   // ← Hint: تم حذف: Icon, ColorCode, DisplayOrder, Description
  batch.execute('''
    CREATE TABLE IF NOT EXISTS TB_ProductCategory (
      CategoryID INTEGER PRIMARY KEY AUTOINCREMENT,
      CategoryNameAr TEXT NOT NULL,
      CategoryNameEn TEXT NOT NULL,
      IsActive INTEGER DEFAULT 1,
      CreatedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  ''');
  debugPrint('✅ تم إنشاء جدول TB_ProductCategory (النسخة المبسطة)');

   // ============================================================================
  // 📏 جدول الوحدات (النسخة المبسطة)
  // ============================================================================
  // ← Hint: فقط اسمين (عربي + إنجليزي) + IsActive + CreatedAt
  // ← Hint: تم حذف: UnitSymbol, DisplayOrder
  batch.execute('''
    CREATE TABLE IF NOT EXISTS TB_ProductUnit (
      UnitID INTEGER PRIMARY KEY AUTOINCREMENT,
      UnitNameAr TEXT NOT NULL,
      UnitNameEn TEXT NOT NULL,
      IsActive INTEGER DEFAULT 1,
      CreatedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  ''');
  debugPrint('✅ تم إنشاء جدول TB_ProductUnit (النسخة المبسطة)');


  // ← Hint: جدول المنتجات - محدث بإضافة UnitID و CategoryID
  batch.execute('''
    CREATE TABLE Store_Products (
    ProductID INTEGER PRIMARY KEY AUTOINCREMENT,
    ProductName TEXT NOT NULL,
    ProductDetails TEXT,
    Barcode TEXT UNIQUE,
    Quantity INTEGER NOT NULL,
    CostPrice REAL NOT NULL,
    SellingPrice REAL NOT NULL,
    SupplierID INTEGER NOT NULL,
    ImagePath TEXT,
    IsActive INTEGER NOT NULL DEFAULT 1,
    UnitID INTEGER,
    CategoryID INTEGER,
    FOREIGN KEY (UnitID) REFERENCES TB_ProductUnit (UnitID),
    FOREIGN KEY (CategoryID) REFERENCES TB_ProductCategory (CategoryID)
    )
  ''');

    batch.execute('''
      CREATE TABLE TB_Customer (
      CustomerID INTEGER PRIMARY KEY AUTOINCREMENT, 
      CustomerName TEXT NOT NULL, 
      Address TEXT, 
      Phone TEXT, 
      Debt REAL DEFAULT 0.0, 
      Payment REAL DEFAULT 0.0, 
      Remaining REAL DEFAULT 0.0, 
      DateT TEXT NOT NULL, 
      ImagePath TEXT, 
      IsActive INTEGER NOT NULL DEFAULT 1)
    ''');

    batch.execute('''
       CREATE TABLE Debt_Customer (
          ID INTEGER PRIMARY KEY AUTOINCREMENT, 
          InvoiceID INTEGER,
          CustomerID INTEGER NOT NULL, 
          ProductID INTEGER NOT NULL, 
          CustomerName TEXT, 
          Details TEXT, 
          Debt REAL NOT NULL, 
          DateT TEXT NOT NULL, 
          Qty_Customer INTEGER NOT NULL, 
          CostPriceAtTimeOfSale REAL NOT NULL, 
          ProfitAmount REAL NOT NULL, 
          IsReturned INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (InvoiceID) REFERENCES TB_Invoices (InvoiceID)
        )
      ''');

    batch.execute('''
      CREATE TABLE Payment_Customer (
      ID INTEGER PRIMARY KEY AUTOINCREMENT, 
      CustomerID INTEGER NOT NULL, 
      CustomerName TEXT, 
      Payment REAL NOT NULL, 
      DateT TEXT NOT NULL, 
      Comments TEXT)
    ''');

    // تجييك
    batch.execute('CREATE TABLE TB_Settings (Key TEXT PRIMARY KEY, Value TEXT NOT NULL)');

    batch.execute('''
      CREATE TABLE Sales_Returns (
      ReturnID INTEGER PRIMARY KEY AUTOINCREMENT, 
      OriginalSaleID INTEGER NOT NULL, 
      CustomerID INTEGER NOT NULL, 
      ProductID INTEGER NOT NULL, 
      ReturnedQuantity INTEGER NOT NULL, 
      ReturnAmount REAL NOT NULL, 
      ReturnDate TEXT NOT NULL, 
      Reason TEXT)
    ''');

    batch.execute('''
      CREATE TABLE Activity_Log (
      LogID INTEGER PRIMARY KEY AUTOINCREMENT, 
      UserID INTEGER, UserName TEXT, 
      Action TEXT NOT NULL, 
      Timestamp TEXT NOT NULL)
    ''');

   // إنشاء جدول حالة التطبيق بالهيكل النهائي الصحيح
    batch.execute('''
      CREATE TABLE TB_App_State (
        ID INTEGER PRIMARY KEY, 
        first_run_date TEXT, 
        activation_expiry_date TEXT,
        last_time_check TEXT,
        time_manipulation_detected INTEGER DEFAULT 0,
        days_offline INTEGER DEFAULT 0
      )
    ''');

     batch.execute('''
      CREATE TABLE TB_Invoices (
        InvoiceID INTEGER PRIMARY KEY AUTOINCREMENT,
          CustomerID INTEGER NOT NULL,
          InvoiceDate TEXT NOT NULL,
          TotalAmount REAL NOT NULL,
          IsVoid INTEGER NOT NULL DEFAULT 0,
          Status TEXT,
          FiscalYearID INTEGER,
          FOREIGN KEY (CustomerID) REFERENCES TB_Customer (CustomerID),
          FOREIGN KEY (FiscalYearID) REFERENCES TB_FiscalYears (FiscalYearID)
      )
    ''');

    batch.execute('''
      CREATE TABLE TB_Expenses (
        ExpenseID INTEGER PRIMARY KEY AUTOINCREMENT,
        Description TEXT NOT NULL,
        Amount REAL NOT NULL,
        ExpenseDate TEXT NOT NULL,
        Category TEXT,
        Notes TEXT,
        FiscalYearID INTEGER,
        FOREIGN KEY (FiscalYearID) REFERENCES TB_FiscalYears (FiscalYearID)
      )
      ''');


       batch.execute('''
      CREATE TABLE TB_Expense_Categories (
        CategoryID INTEGER PRIMARY KEY AUTOINCREMENT,
        CategoryName TEXT NOT NULL UNIQUE
      )
    ''');


    batch.execute('''
    CREATE TABLE SubscriptionCache (
    ID INTEGER PRIMARY KEY,
    Email TEXT,
    Plan TEXT,
    StartDate TEXT,
    EndDate TEXT,
    IsActive INTEGER,
    MaxDevices INTEGER,
    CurrentDeviceId TEXT,
    CurrentDeviceName TEXT,
    LastSyncAt TEXT,
    OfflineDaysRemaining INTEGER,
    LastOnlineCheck TEXT,
    FeaturesJson TEXT,
    Status TEXT,
    UpdatedAt TEXT
    )
    ''');

    // ============================================================================
    // 🆕 إنشاء جداول السنوات المالية (مُضاف في v6)
    // ============================================================================
    // ← Hint: هذه الجداول ضرورية لنظام السنوات المالية والقيود المحاسبية
    debugPrint('📊 [DatabaseHelper] إنشاء جداول السنوات المالية...');

    // 1️⃣ جدول السنوات المالية
    batch.execute('''
      CREATE TABLE TB_FiscalYears (
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

    // 2️⃣ جدول القيود المالية الموحدة
    batch.execute('''
      CREATE TABLE TB_Transactions (
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
        FOREIGN KEY (CustomerID) REFERENCES TB_Customer(CustomerID) ON DELETE SET NULL,
        FOREIGN KEY (SupplierID) REFERENCES TB_Suppliers(SupplierID) ON DELETE SET NULL,
        FOREIGN KEY (EmployeeID) REFERENCES TB_Employees(EmployeeID) ON DELETE SET NULL,
        FOREIGN KEY (ProductID) REFERENCES Store_Products(ProductID) ON DELETE SET NULL
      )
    ''');

    debugPrint('✅ [DatabaseHelper] تم إنشاء جداول السنوات المالية بنجاح');

    await batch.commit();

    // // ============================================================================
    // // ✅ إضافة البيانات الأولية للوحدات والتصنيفات
    // // ============================================================================
    // debugPrint('📦 [DatabaseHelper] إضافة البيانات الأولية للوحدات والتصنيفات...');
    // await _insertDefaultUnitsAndCategories(db);
    // debugPrint('✅ [DatabaseHelper] تم إضافة البيانات الأولية بنجاح');

    // تم ايقافه يخص التصنيفات القديمة

    // ============================================================================
    // ✅ إضافة البيانات الافتراضية البسيطة (2 تصنيف + 2 وحدة فقط)
    // ============================================================================
    // ← Hint: يتم تنفيذها مرة واحدة فقط عند أول تشغيل للتطبيق
    // ← Hint: بعد ذلك المستخدم يضيف ما يحتاجه
    debugPrint('📦 إضافة التصنيفات والوحدات الافتراضية...');
    await _insertDefaultCategoriesAndUnits(db);
    debugPrint('✅ تم إضافة البيانات الافتراضية بنجاح');

    // ============================================================================
    // 💰 إضافة المورد الافتراضي "الصندوق"
    // ============================================================================
    // ← Hint: يتم إضافته مرة واحدة عند أول تثبيت للتطبيق
    // ← Hint: يمثل الشراء النقدي المباشر من الصندوق
    debugPrint('💰 [DatabaseHelper] إضافة المورد الافتراضي "الصندوق"...');
    await db.insert('TB_Suppliers', {
      'SupplierName': 'الصندوق',
      'SupplierType': 'individual',  // مورد فردي
      'Address': '',
      'Phone': '',
      'Notes': 'المورد الافتراضي للنظام - يمثل الشراء النقدي المباشر من الصندوق',
      'DateAdded': DateTime.now().toIso8601String(),
      'ImagePath': null,
      'IsActive': 1,
    });
    debugPrint('✅ [DatabaseHelper] تم إضافة المورد الافتراضي "الصندوق" بنجاح');

    // ============================================================================
    // 🔥 إضافة Database Indexes لتحسين الأداء
    // ============================================================================
    debugPrint('📊 [DatabaseHelper] إنشاء Database Indexes...');

    // ← Hint: تم حذف Users Indexes - لا حاجة لها بعد إزالة TB_Users

    await db.execute('CREATE INDEX IF NOT EXISTS idx_employees_isactive ON TB_Employees(IsActive)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_employees_hiredate ON TB_Employees(HireDate)');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_payroll_employee ON TB_Payroll(EmployeeID)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_payroll_date ON TB_Payroll(PaymentDate)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_payroll_period ON TB_Payroll(PayrollYear, PayrollMonth)');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_advances_employee ON TB_Employee_Advances(EmployeeID)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_advances_date ON TB_Employee_Advances(AdvanceDate)');

    // ← Hint: Indexes لجدول تسديدات السلف (مُضاف في v5)
    await db.execute('CREATE INDEX IF NOT EXISTS idx_repayments_advance ON TB_Advance_Repayments(AdvanceID)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_repayments_employee ON TB_Advance_Repayments(EmployeeID)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_repayments_date ON TB_Advance_Repayments(RepaymentDate)');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_bonuses_employee ON TB_Employee_Bonuses(EmployeeID)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_bonuses_date ON TB_Employee_Bonuses(BonusDate)');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_suppliers_isactive ON TB_Suppliers(IsActive)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_suppliers_type ON TB_Suppliers(SupplierType)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_suppliers_date ON TB_Suppliers(DateAdded)');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_partners_supplier ON Supplier_Partners(SupplierID)');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_withdrawals_supplier ON TB_Profit_Withdrawals(SupplierID)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_withdrawals_date ON TB_Profit_Withdrawals(WithdrawalDate)');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_supplier ON Store_Products(SupplierID)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_barcode ON Store_Products(Barcode)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_isactive ON Store_Products(IsActive)');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_customers_isactive ON TB_Customer(IsActive)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_customers_date ON TB_Customer(DateT)');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_debt_customer ON Debt_Customer(CustomerID)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_debt_product ON Debt_Customer(ProductID)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_debt_invoice ON Debt_Customer(InvoiceID)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_debt_date ON Debt_Customer(DateT)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_debt_returned ON Debt_Customer(IsReturned)');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_payment_customer ON Payment_Customer(CustomerID)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_payment_date ON Payment_Customer(DateT)');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_returns_sale ON Sales_Returns(OriginalSaleID)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_returns_customer ON Sales_Returns(CustomerID)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_returns_product ON Sales_Returns(ProductID)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_returns_date ON Sales_Returns(ReturnDate)');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_log_user ON Activity_Log(UserID)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_log_timestamp ON Activity_Log(Timestamp)');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_invoices_customer ON TB_Invoices(CustomerID)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_invoices_date ON TB_Invoices(InvoiceDate)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_invoices_void ON TB_Invoices(IsVoid)');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_expenses_date ON TB_Expenses(ExpenseDate)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_expenses_category ON TB_Expenses(Category)');

    // ← Hint: Indexes للسنوات المالية (مُضاف في v6)
    await db.execute('CREATE INDEX IF NOT EXISTS idx_invoices_fiscal_year ON TB_Invoices(FiscalYearID)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_expenses_fiscal_year ON TB_Expenses(FiscalYearID)');

    // ← Hint: Indexes لجداول السنوات المالية والقيود
    await db.execute('CREATE INDEX IF NOT EXISTS idx_fiscal_years_active ON TB_FiscalYears(IsActive)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_fiscal_years_year ON TB_FiscalYears(Year)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_fiscal_year ON TB_Transactions(FiscalYearID)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_date ON TB_Transactions(Date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_type ON TB_Transactions(Type)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_direction ON TB_Transactions(Direction)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_fiscal_date ON TB_Transactions(FiscalYearID, Date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_fiscal_type ON TB_Transactions(FiscalYearID, Type)');

      // ← Hint: Indexes للتصنيفات والوحدات (بسيطة)
  await db.execute('CREATE INDEX IF NOT EXISTS idx_category_active ON TB_ProductCategory(IsActive)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_category_namear ON TB_ProductCategory(CategoryNameAr)');
  
  await db.execute('CREATE INDEX IF NOT EXISTS idx_unit_active ON TB_ProductUnit(IsActive)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_unit_namear ON TB_ProductUnit(UnitNameAr)');

  // ← Hint: Indexes للمنتجات (ربط مع التصنيفات والوحدات)
  await db.execute('CREATE INDEX IF NOT EXISTS idx_products_category ON Store_Products(CategoryID)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_products_unit ON Store_Products(UnitID)');

    debugPrint('✅ [DatabaseHelper] تم إنشاء Database Indexes بنجاح');

    // ============================================================================
    // 🔄 إنشاء Triggers للتحديث التلقائي للأرصدة
    // ============================================================================
    debugPrint('🔄 [DatabaseHelper] إنشاء Triggers التحديث التلقائي...');

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

    // ← Hint: Trigger عند تعديل مبلغ قيد - تحديث السنة المالية تلقائياً
    // ← Hint: هذا يضمن تحديث أرصدة السنة المالية عند تعديل أي قيد
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_update_fiscal_on_update
      AFTER UPDATE OF Amount ON TB_Transactions
      WHEN OLD.Amount != NEW.Amount
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

    // ← Hint: Trigger عند حذف فاتورة - حذف القيد المالي المرتبط
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_delete_invoice_transaction
      BEFORE DELETE ON TB_Invoices
      BEGIN
        DELETE FROM TB_Transactions
        WHERE ReferenceType = 'invoice' AND ReferenceID = OLD.InvoiceID;
      END;
    ''');

    // ← Hint: Trigger عند حذف دفعة زبون - حذف القيد المالي المرتبط
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_delete_payment_transaction
      BEFORE DELETE ON Payment_Customer
      BEGIN
        DELETE FROM TB_Transactions
        WHERE ReferenceType = 'customer_payment' AND ReferenceID = OLD.ID;
      END;
    ''');

    // ← Hint: Trigger عند حذف مصروف - حذف القيد المالي المرتبط
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_delete_expense_transaction
      BEFORE DELETE ON TB_Expenses
      BEGIN
        DELETE FROM TB_Transactions
        WHERE ReferenceType = 'expense' AND ReferenceID = OLD.ExpenseID;
      END;
    ''');

    // ← Hint: Trigger عند حذف سلفة موظف - حذف القيد المالي المرتبط
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_delete_advance_transaction
      BEFORE DELETE ON TB_Employee_Advances
      BEGIN
        DELETE FROM TB_Transactions
        WHERE ReferenceType = 'advance' AND ReferenceID = OLD.AdvanceID;
      END;
    ''');

    // ← Hint: Trigger عند حذف تسديد سلفة - حذف القيد المالي المرتبط
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_delete_repayment_transaction
      BEFORE DELETE ON TB_Advance_Repayments
      BEGIN
        DELETE FROM TB_Transactions
        WHERE ReferenceType = 'advance_repayment' AND ReferenceID = OLD.RepaymentID;
      END;
    ''');

    // ← Hint: Trigger عند حذف راتب - حذف القيد المالي المرتبط
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_delete_payroll_transaction
      BEFORE DELETE ON TB_Payroll
      BEGIN
        DELETE FROM TB_Transactions
        WHERE ReferenceType = 'payroll' AND ReferenceID = OLD.PayrollID;
      END;
    ''');

    // ← Hint: Trigger عند حذف مكافأة - حذف القيد المالي المرتبط
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_delete_bonus_transaction
      BEFORE DELETE ON TB_Employee_Bonuses
      BEGIN
        DELETE FROM TB_Transactions
        WHERE ReferenceType = 'bonus' AND ReferenceID = OLD.BonusID;
      END;
    ''');

    // ← Hint: Trigger عند حذف سحب أرباح مورد/شريك - حذف القيد المالي المرتبط
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_delete_withdrawal_transaction
      BEFORE DELETE ON TB_Profit_Withdrawals
      BEGIN
        DELETE FROM TB_Transactions
        WHERE ReferenceType = 'supplier_withdrawal' AND ReferenceID = OLD.WithdrawalID;
      END;
    ''');

    // ← Hint: Trigger عند حذف فاتورة - حذف القيد المالي المرتبط
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_delete_invoice_transaction
      BEFORE DELETE ON TB_Invoices
      BEGIN
        DELETE FROM TB_Transactions
        WHERE ReferenceType = 'invoice' AND ReferenceID = OLD.InvoiceID;
      END;
    ''');

    // ← Hint: Trigger عند تعديل مبلغ فاتورة - تحديث القيد المالي
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_update_invoice_transaction
      AFTER UPDATE OF TotalAmount ON TB_Invoices
      WHEN OLD.TotalAmount != NEW.TotalAmount
      BEGIN
        UPDATE TB_Transactions
        SET Amount = NEW.TotalAmount
        WHERE ReferenceType = 'invoice' AND ReferenceID = NEW.InvoiceID;
      END;
    ''');

    // ← Hint: Trigger عند تعديل دفعة زبون - تحديث القيد المالي
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_update_payment_transaction
      AFTER UPDATE OF Payment ON Payment_Customer
      WHEN OLD.Payment != NEW.Payment
      BEGIN
        UPDATE TB_Transactions
        SET Amount = NEW.Payment
        WHERE ReferenceType = 'customer_payment' AND ReferenceID = NEW.ID;
      END;
    ''');

    // ← Hint: Trigger عند تعديل مصروف - تحديث القيد المالي
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_update_expense_transaction
      AFTER UPDATE OF Amount ON TB_Expenses
      WHEN OLD.Amount != NEW.Amount
      BEGIN
        UPDATE TB_Transactions
        SET Amount = NEW.Amount
        WHERE ReferenceType = 'expense' AND ReferenceID = NEW.ExpenseID;
      END;
    ''');

    // ← Hint: Trigger عند تعديل مبلغ سلفة موظف - تحديث القيد المالي تلقائياً
    // ← Hint: يضمن تحديث القيود والتقارير المالية عند تعديل السلفة
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_update_advance_transaction
      AFTER UPDATE OF AdvanceAmount ON TB_Employee_Advances
      WHEN OLD.AdvanceAmount != NEW.AdvanceAmount
      BEGIN
        UPDATE TB_Transactions
        SET Amount = NEW.AdvanceAmount
        WHERE ReferenceType = 'advance' AND ReferenceID = NEW.AdvanceID;
      END;
    ''');

    // ← Hint: Trigger عند تعديل مبلغ تسديد سلفة - تحديث القيد المالي تلقائياً
    // ← Hint: يضمن تحديث القيود والتقارير المالية عند تعديل التسديد
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_update_repayment_transaction
      AFTER UPDATE OF RepaymentAmount ON TB_Advance_Repayments
      WHEN OLD.RepaymentAmount != NEW.RepaymentAmount
      BEGIN
        UPDATE TB_Transactions
        SET Amount = NEW.RepaymentAmount
        WHERE ReferenceType = 'advance_repayment' AND ReferenceID = NEW.RepaymentID;
      END;
    ''');

    // ← Hint: Trigger عند تعديل مبلغ مكافأة - تحديث القيد المالي تلقائياً
    // ← Hint: يضمن تحديث القيود والتقارير المالية عند تعديل المكافأة
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_update_bonus_transaction
      AFTER UPDATE OF BonusAmount ON TB_Employee_Bonuses
      WHEN OLD.BonusAmount != NEW.BonusAmount
      BEGIN
        UPDATE TB_Transactions
        SET Amount = NEW.BonusAmount
        WHERE ReferenceType = 'bonus' AND ReferenceID = NEW.BonusID;
      END;
    ''');

    // ← Hint: Trigger عند تعديل مبلغ راتب - تحديث القيد المالي تلقائياً
    // ← Hint: يضمن تحديث القيود والتقارير المالية عند تعديل الراتب
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_update_payroll_transaction
      AFTER UPDATE OF NetSalary ON TB_Payroll
      WHEN OLD.NetSalary != NEW.NetSalary
      BEGIN
        UPDATE TB_Transactions
        SET Amount = NEW.NetSalary
        WHERE ReferenceType = 'payroll' AND ReferenceID = NEW.PayrollID;
      END;
    ''');

    // ← Hint: Trigger عند تعديل مبلغ سحب أرباح مورد/شريك - تحديث القيد المالي تلقائياً
    // ← Hint: يضمن تحديث القيود والتقارير المالية عند تعديل مبلغ السحب
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_update_withdrawal_transaction
      AFTER UPDATE OF WithdrawalAmount ON TB_Profit_Withdrawals
      WHEN OLD.WithdrawalAmount != NEW.WithdrawalAmount
      BEGIN
        UPDATE TB_Transactions
        SET Amount = NEW.WithdrawalAmount
        WHERE ReferenceType = 'supplier_withdrawal' AND ReferenceID = NEW.WithdrawalID;
      END;
    ''');

    // ← Hint: Trigger عند إرجاع بند في فاتورة - تحديث TotalAmount للفاتورة تلقائياً
    // ← Hint: عند تحديث IsReturned من 0 إلى 1، يتم إنقاص TotalAmount بمبلغ البند
    // ← Hint: هذا سيُطلق trg_update_invoice_transaction لتحديث القيد المالي
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_update_invoice_on_return
      AFTER UPDATE OF IsReturned ON Debt_Customer
      WHEN NEW.IsReturned = 1 AND OLD.IsReturned = 0
      BEGIN
        UPDATE TB_Invoices
        SET TotalAmount = TotalAmount - OLD.Debt
        WHERE InvoiceID = OLD.InvoiceID;
      END;
    ''');

    debugPrint('✅ [DatabaseHelper] تم إنشاء Triggers التحديث التلقائي بنجاح');

    // ============================================================================
    // 📅 إنشاء سنة مالية افتراضية
    // ============================================================================
    debugPrint('📅 [DatabaseHelper] إنشاء سنة مالية افتراضية...');

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

    debugPrint('✅ [DatabaseHelper] تم إنشاء السنة المالية الافتراضية ($defaultYear) بنجاح');

    // ============================================================================
    // 🆕 إنشاء جدول الحسابات المحاسبية (TB_Accounts)
    // ============================================================================
    debugPrint('💰 [DatabaseHelper] إنشاء جدول الحسابات المحاسبية...');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS TB_Accounts (
        AccountID INTEGER PRIMARY KEY AUTOINCREMENT,
        AccountCode TEXT NOT NULL UNIQUE,
        AccountNameAr TEXT NOT NULL,
        AccountNameEn TEXT NOT NULL,
        AccountType TEXT NOT NULL,
        AccountCategory TEXT NOT NULL,
        ParentAccountID INTEGER,
        Balance REAL NOT NULL DEFAULT 0.0,
        DebitBalance REAL NOT NULL DEFAULT 0.0,
        CreditBalance REAL NOT NULL DEFAULT 0.0,
        IsDefault INTEGER NOT NULL DEFAULT 0,
        IsActive INTEGER NOT NULL DEFAULT 1,
        Description TEXT,
        CreatedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UpdatedAt TEXT,
        FOREIGN KEY (ParentAccountID) REFERENCES TB_Accounts(AccountID) ON DELETE SET NULL
      )
    ''');

    debugPrint('✅ [DatabaseHelper] تم إنشاء جدول TB_Accounts بنجاح');

    // ← Hint: إضافة DebitAccountID و CreditAccountID إلى TB_Transactions
    await db.execute(
      'ALTER TABLE TB_Transactions ADD COLUMN DebitAccountID INTEGER REFERENCES TB_Accounts(AccountID)'
    );
    await db.execute(
      'ALTER TABLE TB_Transactions ADD COLUMN CreditAccountID INTEGER REFERENCES TB_Accounts(AccountID)'
    );
    debugPrint('✅ [DatabaseHelper] تم تعديل جدول TB_Transactions لدعم القيد المزدوج');

    // ============================================================================
    // 💰 إضافة الحسابات الافتراضية (12 حساب)
    // ============================================================================
    debugPrint('📊 [DatabaseHelper] إضافة الحسابات الافتراضية...');

    final defaultAccounts = [
      // ═══════════════════════════════════════════════════════════
      // 🏦 الأصول (Assets) - AccountType: asset
      // ═══════════════════════════════════════════════════════════
      {
        'AccountCode': '1001',
        'AccountNameAr': 'الصندوق',
        'AccountNameEn': 'Cash',
        'AccountType': 'asset',
        'AccountCategory': 'current_asset',
        'IsDefault': 1,
        'Description': 'النقدية في الصندوق - الحساب الافتراضي للعمليات النقدية',
      },
      {
        'AccountCode': '1002',
        'AccountNameAr': 'البنك',
        'AccountNameEn': 'Bank',
        'AccountType': 'asset',
        'AccountCategory': 'current_asset',
        'IsDefault': 1,
        'Description': 'الأرصدة البنكية',
      },
      {
        'AccountCode': '1100',
        'AccountNameAr': 'المخزون',
        'AccountNameEn': 'Inventory',
        'AccountType': 'asset',
        'AccountCategory': 'current_asset',
        'IsDefault': 1,
        'Description': 'قيمة المنتجات المخزنة (يتحدث تلقائياً عند الشراء/البيع)',
      },
      {
        'AccountCode': '1200',
        'AccountNameAr': 'العملاء (المدينون)',
        'AccountNameEn': 'Accounts Receivable',
        'AccountType': 'asset',
        'AccountCategory': 'current_asset',
        'IsDefault': 1,
        'Description': 'ديون العملاء (مبيعات آجلة)',
      },

      // ═══════════════════════════════════════════════════════════
      // 📊 الخصوم (Liabilities) - AccountType: liability
      // ═══════════════════════════════════════════════════════════
      {
        'AccountCode': '2001',
        'AccountNameAr': 'الموردون (الدائنون)',
        'AccountNameEn': 'Accounts Payable',
        'AccountType': 'liability',
        'AccountCategory': 'current_liability',
        'IsDefault': 1,
        'Description': 'ديون للموردين (مشتريات آجلة)',
      },

      // ═══════════════════════════════════════════════════════════
      // 💰 حقوق الملكية (Equity) - AccountType: equity
      // ═══════════════════════════════════════════════════════════
      {
        'AccountCode': '3001',
        'AccountNameAr': 'رأس المال',
        'AccountNameEn': 'Capital',
        'AccountType': 'equity',
        'AccountCategory': 'capital',
        'IsDefault': 1,
        'Description': 'رأس المال الأولي للشركة',
      },
      {
        'AccountCode': '3002',
        'AccountNameAr': 'الأرباح المحتجزة',
        'AccountNameEn': 'Retained Earnings',
        'AccountType': 'equity',
        'AccountCategory': 'retained_earnings',
        'IsDefault': 1,
        'Description': 'الأرباح المتراكمة من السنوات السابقة',
      },

      // ═══════════════════════════════════════════════════════════
      // 📈 الإيرادات (Revenue) - AccountType: revenue
      // ═══════════════════════════════════════════════════════════
      {
        'AccountCode': '4001',
        'AccountNameAr': 'إيرادات المبيعات',
        'AccountNameEn': 'Sales Revenue',
        'AccountType': 'revenue',
        'AccountCategory': 'sales_revenue',
        'IsDefault': 1,
        'Description': 'دخل من بيع المنتجات',
      },

      // ═══════════════════════════════════════════════════════════
      // 📉 المصروفات (Expenses) - AccountType: expense
      // ═══════════════════════════════════════════════════════════
      {
        'AccountCode': '5001',
        'AccountNameAr': 'تكلفة المبيعات',
        'AccountNameEn': 'Cost of Goods Sold',
        'AccountType': 'expense',
        'AccountCategory': 'cost_of_sales',
        'IsDefault': 1,
        'Description': 'تكلفة شراء المنتجات المباعة',
      },
      {
        'AccountCode': '5002',
        'AccountNameAr': 'الرواتب والأجور',
        'AccountNameEn': 'Salaries & Wages',
        'AccountType': 'expense',
        'AccountCategory': 'salary_expense',
        'IsDefault': 1,
        'Description': 'رواتب الموظفين ومكافآتهم',
      },
      {
        'AccountCode': '5003',
        'AccountNameAr': 'المصروفات العامة',
        'AccountNameEn': 'General Expenses',
        'AccountType': 'expense',
        'AccountCategory': 'general_expense',
        'IsDefault': 1,
        'Description': 'مصروفات متنوعة (كهرباء، ماء، إيجار، إلخ)',
      },
      {
        'AccountCode': '5010',
        'AccountNameAr': 'خسائر المخزون',
        'AccountNameEn': 'Inventory Losses',
        'AccountType': 'expense',
        'AccountCategory': 'general_expense',
        'IsDefault': 1,
        'Description': 'خسائر ناتجة عن تلف أو سرقة المخزون',
      },
    ];

    // إدراج جميع الحسابات الافتراضية
    for (var account in defaultAccounts) {
      await db.insert('TB_Accounts', account);
    }

    debugPrint('✅ [DatabaseHelper] تم إضافة ${defaultAccounts.length} حساب افتراضي');

    // ============================================================================
    // 🔄 إنشاء Triggers لتحديث أرصدة الحسابات تلقائياً
    // ============================================================================
    debugPrint('🔄 [DatabaseHelper] إنشاء Triggers لتحديث أرصدة الحسابات...');

    // Trigger: عند إضافة قيد جديد → تحديث رصيد الحساب المدين والدائن
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_update_account_on_insert
      AFTER INSERT ON TB_Transactions
      WHEN NEW.DebitAccountID IS NOT NULL AND NEW.CreditAccountID IS NOT NULL
      BEGIN
        -- تحديث الحساب المدين (إضافة للرصيد)
        UPDATE TB_Accounts
        SET
          DebitBalance = DebitBalance + NEW.Amount,
          Balance = CASE
            WHEN AccountType IN ('asset', 'expense') THEN Balance + NEW.Amount
            ELSE Balance - NEW.Amount
          END
        WHERE AccountID = NEW.DebitAccountID;

        -- تحديث الحساب الدائن (خصم من الرصيد)
        UPDATE TB_Accounts
        SET
          CreditBalance = CreditBalance + NEW.Amount,
          Balance = CASE
            WHEN AccountType IN ('liability', 'equity', 'revenue') THEN Balance + NEW.Amount
            ELSE Balance - NEW.Amount
          END
        WHERE AccountID = NEW.CreditAccountID;
      END;
    ''');

    // Trigger: عند حذف قيد → عكس التأثير على الأرصدة
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_update_account_on_delete
      AFTER DELETE ON TB_Transactions
      WHEN OLD.DebitAccountID IS NOT NULL AND OLD.CreditAccountID IS NOT NULL
      BEGIN
        -- عكس التأثير على الحساب المدين
        UPDATE TB_Accounts
        SET
          DebitBalance = DebitBalance - OLD.Amount,
          Balance = CASE
            WHEN AccountType IN ('asset', 'expense') THEN Balance - OLD.Amount
            ELSE Balance + OLD.Amount
          END
        WHERE AccountID = OLD.DebitAccountID;

        -- عكس التأثير على الحساب الدائن
        UPDATE TB_Accounts
        SET
          CreditBalance = CreditBalance - OLD.Amount,
          Balance = CASE
            WHEN AccountType IN ('liability', 'equity', 'revenue') THEN Balance - OLD.Amount
            ELSE Balance + OLD.Amount
          END
        WHERE AccountID = OLD.CreditAccountID;
      END;
    ''');

    // Trigger: عند تعديل مبلغ قيد → تحديث الأرصدة
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_update_account_on_update
      AFTER UPDATE OF Amount ON TB_Transactions
      WHEN OLD.Amount != NEW.Amount
        AND NEW.DebitAccountID IS NOT NULL
        AND NEW.CreditAccountID IS NOT NULL
      BEGIN
        -- عكس التأثير القديم
        UPDATE TB_Accounts
        SET
          DebitBalance = DebitBalance - OLD.Amount,
          Balance = CASE
            WHEN AccountType IN ('asset', 'expense') THEN Balance - OLD.Amount
            ELSE Balance + OLD.Amount
          END
        WHERE AccountID = OLD.DebitAccountID;

        UPDATE TB_Accounts
        SET
          CreditBalance = CreditBalance - OLD.Amount,
          Balance = CASE
            WHEN AccountType IN ('liability', 'equity', 'revenue') THEN Balance - OLD.Amount
            ELSE Balance + OLD.Amount
          END
        WHERE AccountID = OLD.CreditAccountID;

        -- تطبيق التأثير الجديد
        UPDATE TB_Accounts
        SET
          DebitBalance = DebitBalance + NEW.Amount,
          Balance = CASE
            WHEN AccountType IN ('asset', 'expense') THEN Balance + NEW.Amount
            ELSE Balance - NEW.Amount
          END
        WHERE AccountID = NEW.DebitAccountID;

        UPDATE TB_Accounts
        SET
          CreditBalance = CreditBalance + NEW.Amount,
          Balance = CASE
            WHEN AccountType IN ('liability', 'equity', 'revenue') THEN Balance + NEW.Amount
            ELSE Balance - NEW.Amount
          END
        WHERE AccountID = NEW.CreditAccountID;
      END;
    ''');

    debugPrint('✅ [DatabaseHelper] تم إنشاء 3 Triggers للحسابات');

    // ============================================================================
    // 📊 إنشاء Indexes لتحسين الأداء
    // ============================================================================
    debugPrint('📊 [DatabaseHelper] إنشاء Indexes للحسابات...');

    // مؤشر على كود الحساب (فريد - بحث سريع)
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_accounts_code
      ON TB_Accounts(AccountCode)
    ''');

    // مؤشر على نوع الحساب (للفلترة)
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_accounts_type
      ON TB_Accounts(AccountType)
    ''');

    // مؤشر على الحسابات النشطة
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_accounts_active
      ON TB_Accounts(IsActive)
    ''');

    // مؤشر على الحسابات الافتراضية
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_accounts_default
      ON TB_Accounts(IsDefault)
    ''');

    // مؤشر على الحساب المدين في Transactions
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_transactions_debit
      ON TB_Transactions(DebitAccountID)
    ''');

    // مؤشر على الحساب الدائن في Transactions
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_transactions_credit
      ON TB_Transactions(CreditAccountID)
    ''');

    debugPrint('✅ [DatabaseHelper] تم إنشاء 6 Indexes للحسابات');

    debugPrint('🎉 [DatabaseHelper] نظام الحسابات المحاسبي جاهز في _onCreate!');

    // ✅✅✅ التعديل الثالث: إضافة الفئات الافتراضية بعد إنشاء الجداول ✅✅✅
    await _insertDefaultCategories(db);

  }

  ///////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////

  // =================================================================================================
  // ✅ الخطوة 3: تحديث دالة onUpgrade لتكون قوية وتدريجية
  // Hint: هذا هو التصحيح الأهم. سيقوم بمعالجة كل حالة ترقية بشكل منفصل.
  // =================================================================================================
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('🔄 ترقية قاعدة البيانات من $oldVersion إلى $newVersion');

    // ترقية من الإصدار 1 إلى 2: إضافة جدول TB_Employee_Bonuses
    if (oldVersion < 2) {
      debugPrint('📦 إضافة جدول TB_Employee_Bonuses...');
      await db.execute('''
        CREATE TABLE TB_Employee_Bonuses (
          BonusID INTEGER PRIMARY KEY AUTOINCREMENT,
          EmployeeID INTEGER NOT NULL,
          BonusDate TEXT NOT NULL,
          BonusAmount REAL NOT NULL,
          BonusReason TEXT,
          Notes TEXT,
          FOREIGN KEY (EmployeeID) REFERENCES TB_Employees (EmployeeID)
        )
      ''');
      debugPrint('✅ تم إضافة جدول TB_Employee_Bonuses بنجاح');
    }

   ///////////////////////////////////////////////////////////////
   ///////////////////////////////////////////////////////////////

    // 🆕 ترقية من الإصدار 2 إلى 3: النظام الجديد - Email Auth + Subscriptions
    if (oldVersion < 3) {
      debugPrint('📦 تطبيق Migration إلى v3 (النظام الجديد)...');
      await DatabaseMigrations.migrateToV2(db);  // migrateToV2 يحتوي على التحديثات لـ v3
      debugPrint('✅ تم تطبيق Migration إلى v3 بنجاح');
    }

    ///////////////////////////////////////////////////////////////
   ///////////////////////////////////////////////////////////////

      // ✅ ترقية من الإصدار 3 إلى 4: نظام التصنيفات والوحدات المبسط
  if (oldVersion < 4) {
    debugPrint('📦 تطبيق Migration إلى v4 (نظام التصنيفات والوحدات المبسط)...');

    // ============================================================================
    // ← Hint: إنشاء جدول التصنيفات (النسخة المبسطة)
    // ============================================================================
    await db.execute('''
      CREATE TABLE IF NOT EXISTS TB_ProductCategory (
        CategoryID INTEGER PRIMARY KEY AUTOINCREMENT,
        CategoryNameAr TEXT NOT NULL,
        CategoryNameEn TEXT NOT NULL,
        IsActive INTEGER DEFAULT 1,
        CreatedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    debugPrint('✅ تم إنشاء جدول TB_ProductCategory');

    // ============================================================================
    // ← Hint: إنشاء جدول الوحدات (النسخة المبسطة)
    // ============================================================================
    await db.execute('''
      CREATE TABLE IF NOT EXISTS TB_ProductUnit (
        UnitID INTEGER PRIMARY KEY AUTOINCREMENT,
        UnitNameAr TEXT NOT NULL,
        UnitNameEn TEXT NOT NULL,
        IsActive INTEGER DEFAULT 1,
        CreatedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    debugPrint('✅ تم إنشاء جدول TB_ProductUnit');

    // ← Hint: إضافة البيانات الافتراضية البسيطة
    await _insertDefaultCategoriesAndUnits(db);
    debugPrint('✅ تم إضافة البيانات الافتراضية');

    // ← Hint: إضافة أعمدة UnitID و CategoryID لجدول المنتجات
    await db.execute('ALTER TABLE Store_Products ADD COLUMN UnitID INTEGER');
    await db.execute('ALTER TABLE Store_Products ADD COLUMN CategoryID INTEGER');
    debugPrint('✅ تم إضافة أعمدة UnitID و CategoryID');

    // ← Hint: تحديث المنتجات الموجودة لتأخذ الوحدة والتصنيف الافتراضي
    // ← Hint: الوحدة الافتراضية = "قطعة" (UnitID = 1)
    // ← Hint: التصنيف الافتراضي = "عام" (CategoryID = 1)
    await db.execute('UPDATE Store_Products SET UnitID = 1, CategoryID = 1 WHERE UnitID IS NULL');
    debugPrint('✅ تم تحديث المنتجات الموجودة');

    debugPrint('✅ تم تطبيق Migration إلى v4 بنجاح');
  }

    ///////////////////////////////////////////////////////////////
   ///////////////////////////////////////////////////////////////

    // ✅ ترقية من الإصدار 4 إلى 5: نظام تسديدات السلف
    // ← Hint: إضافة جدول TB_Advance_Repayments لتسجيل عمليات التسديد
    if (oldVersion < 5) {
      debugPrint('📦 تطبيق Migration إلى v5 (نظام تسديدات السلف)...');
      await DatabaseMigrations.migrateToV5(db);
      debugPrint('✅ تم تطبيق Migration إلى v5 بنجاح');
    }

    ///////////////////////////////////////////////////////////////
   ///////////////////////////////////////////////////////////////

    // ✅ ترقية من الإصدار 5 إلى 6: نظام السنوات المالية والقيود المحاسبية
    // ← Hint: إضافة جدول TB_FiscalYears و TB_Transactions
    // ← Hint: هذا يحول التطبيق إلى نظام محاسبي احترافي كامل
    if (oldVersion < 6) {
      debugPrint('📦 تطبيق Migration إلى v6 (نظام السنوات المالية)...');
      await DatabaseMigrations.migrateToV6(db);
      debugPrint('✅ تم تطبيق Migration إلى v6 بنجاح - النظام المحاسبي جاهز! 🎉');
    }

    // ✅ ترقية من الإصدار 6 إلى 7: إصلاحات الحذف والتعديل التلقائي
    if (oldVersion < 7) {
      debugPrint('📦 تطبيق Migration إلى v7 (DELETE/UPDATE triggers)...');
      await DatabaseMigrations.migrateToV7(db);
      debugPrint('✅ تم تطبيق Migration إلى v7 بنجاح - الحذف والتعديل يعملان تلقائياً! 🎉');
    }

    // ✅ ترقية من الإصدار 7 إلى 8: إصلاحات UPDATE للسنوات المالية والموظفين
    if (oldVersion < 8) {
      debugPrint('📦 تطبيق Migration إلى v8 (UPDATE triggers للسنوات والموظفين)...');
      await DatabaseMigrations.migrateToV8(db);
      debugPrint('✅ تم تطبيق Migration إلى v8 بنجاح - التعديل يحدّث القيود والسنوات تلقائياً! 🎉');
    }

    // ✅ ترقية من الإصدار 8 إلى 9: إصلاح ReferenceType للسلف
    if (oldVersion < 9) {
      debugPrint('📦 تطبيق Migration إلى v9 (إصلاح ReferenceType للسلف)...');
      await DatabaseMigrations.migrateToV9(db);
      debugPrint('✅ تم تطبيق Migration إلى v9 بنجاح - تعديل وحذف السلف يعمل الآن! 🎉');
    }

    // ✅ ترقية من الإصدار 9 إلى 10: قيد واحد لكل فاتورة
    if (oldVersion < 10) {
      debugPrint('📦 تطبيق Migration إلى v10 (قيد واحد لكل فاتورة)...');
      await DatabaseMigrations.migrateToV10(db);
      debugPrint('✅ تم تطبيق Migration إلى v10 بنجاح - قيد واحد لكل فاتورة! 🎉');
    }

    // ═════════════════════════════════════════════════════════════
    // Migration v11: نظام الحسابات المحاسبي الكامل
    // ═════════════════════════════════════════════════════════════
    // ← Hint: هذا هو التحديث الأهم! يحول التطبيق لنظام محاسبي مزدوج القيد
    // ← Hint: يضيف جدول TB_Accounts + 12 حساب افتراضي
    // ← Hint: يضيف DebitAccountID و CreditAccountID لـ TB_Transactions
    // ← Hint: يضيف Triggers لتحديث أرصدة الحسابات تلقائياً
    if (oldVersion < 11) {
      debugPrint('📦 تطبيق Migration إلى v11 (نظام الحسابات المحاسبي)...');
      await DatabaseMigrations.migrateToV11(db);
      debugPrint('✅ تم تطبيق Migration إلى v11 بنجاح - نظام محاسبي مزدوج القيد كامل! 🎉');
    }

  }

   ///////////////////////////////////////////////////////////////
   ///////////////////////////////////////////////////////////////

    


  /// ✅✅✅ دالة مساعدة لإضافة الفئات الافتراضية ✅✅✅
  /// الشرح: هذه الدالة تقوم بإضافة مجموعة من الفئات الأساسية إلى الجدول الجديد.
  Future<void> _insertDefaultCategories(Database db) async {
    // final defaultCategories = ['فواتير', 'إيجار', 'صيانة', 'نثرية', 'أخرى'];
    final defaultCategories = ['rent-إيجار',];
    for (var category in defaultCategories) {
      await db.insert(
        'TB_Expense_Categories',
        {'CategoryName': category},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  // // ============================================================================
  // // ← Hint: دالة مساعدة لإضافة البيانات الأولية للوحدات والتصنيفات
  // // ← Hint: يتم استدعاؤها عند إنشاء قاعدة البيانات لأول مرة
  // // ============================================================================
  // Future<void> _insertDefaultUnitsAndCategories(Database db) async {
  //   // ← Hint: الوحدات الافتراضية (7 وحدات)
  //   final defaultUnits = [
  //     {'UnitName': 'Piece', 'UnitNameAr': 'قطعة', 'IsActive': 1},
  //     {'UnitName': 'Set', 'UnitNameAr': 'سيت', 'IsActive': 1},
  //     {'UnitName': 'Dozen', 'UnitNameAr': 'درزن', 'IsActive': 1},
  //     {'UnitName': 'Kilo', 'UnitNameAr': 'كيلو', 'IsActive': 1},
  //     {'UnitName': 'Carton', 'UnitNameAr': 'كارتون', 'IsActive': 1},
  //     {'UnitName': 'Meter', 'UnitNameAr': 'متر', 'IsActive': 1},
  //     {'UnitName': 'Liter', 'UnitNameAr': 'لتر', 'IsActive': 1},
  //   ];

  //   // ← Hint: التصنيفات الافتراضية (8 تصنيفات)
  //   final defaultCategories = [
  //     {'CategoryName': 'Electricals', 'CategoryNameAr': 'كهربائيات', 'IconName': 'bolt', 'ColorCode': '#FFA726', 'IsActive': 1},
  //     {'CategoryName': 'Furniture', 'CategoryNameAr': 'أثاث', 'IconName': 'chair', 'ColorCode': '#8D6E63', 'IsActive': 1},
  //     {'CategoryName': 'Clothes', 'CategoryNameAr': 'ملابس', 'IconName': 'checkroom', 'ColorCode': '#EC407A', 'IsActive': 1},
  //     {'CategoryName': 'Home Supplies', 'CategoryNameAr': 'مستلزمات منزلية', 'IconName': 'home', 'ColorCode': '#66BB6A', 'IsActive': 1},
  //     {'CategoryName': 'Accessories', 'CategoryNameAr': 'إكسسوارات', 'IconName': 'watch', 'ColorCode': '#AB47BC', 'IsActive': 1},
  //     {'CategoryName': 'Electronics', 'CategoryNameAr': 'إلكترونيات', 'IconName': 'devices', 'ColorCode': '#42A5F5', 'IsActive': 1},
  //     {'CategoryName': 'Office Supplies', 'CategoryNameAr': 'أدوات مكتبية', 'IconName': 'business_center', 'ColorCode': '#78909C', 'IsActive': 1},
  //     {'CategoryName': 'General', 'CategoryNameAr': 'عام', 'IconName': 'category', 'ColorCode': '#BDBDBD', 'IsActive': 1},
  //   ];

  //   // ← Hint: إضافة الوحدات
  //   for (var unit in defaultUnits) {
  //     await db.insert(
  //       'TB_ProductUnit',
  //       unit,
  //       conflictAlgorithm: ConflictAlgorithm.ignore,
  //     );
  //   }

  //   // ← Hint: إضافة التصنيفات
  //   for (var category in defaultCategories) {
  //     await db.insert(
  //       'TB_ProductCategory',
  //       category,
  //       conflictAlgorithm: ConflictAlgorithm.ignore,
  //     );
  //   }
  // }

   ///////////////////////////////////////////////////////////////
   ///////////////////////////////////////////////////////////////


  // --- ✅ إضافة دوال جديدة للتعامل مع حالة التطبيق ---
// دوال للتفعيل الدائمي سوف اقوم بايقافها
  // Future<Map<String, dynamic>?> getAppState() async {
  //   final db = await instance.database;
  //   final result = await db.query('TB_App_State', limit: 1);
  //   if (result.isNotEmpty) {
  //     return {
  //       'first_run_date': result.first['first_run_date'],
  //       'is_activated': (result.first['is_activated'] as int) == 1,
  //     };
  //   }
  //   return null; // لا يوجد سجل = التشغيل الأول
  // }


  // /// دالة لتهيئة حالة التطبيق (تسجيل تاريخ أول تشغيل).
  // /// يتم استدعاؤها مرة واحدة فقط عند أول فتح للتطبيق.
  // Future<void> initializeAppState() async {
  //   final db = await instance.database;
  //   await db.insert('TB_App_State', {
  //     'ID': 1, // دائماً نستخدم نفس السجل
  //     'first_run_date': DateTime.now().toIso8601String(),
  //     'is_activated': 0,
  //   }, conflictAlgorithm: ConflictAlgorithm.ignore); // تجاهل إذا كان السجل موجوداً بالفعل
  // }


  /// دالة لتفعيل التطبيق بشكل دائم.
  // Future<void> activateApp() async {
  //   final db = await instance.database;
  //   await db.update(
  //     'TB_App_State',
  //     {'is_activated': 1},
  //     where: 'ID = ?',
  //     whereArgs: [1],
  //   );
  // }

// دوال للتفعيل حسب المدة
 Future<Map<String, dynamic>?> getAppState() async {
    final db = await instance.database;
    final result = await db.query('TB_App_State', limit: 1);
    if (result.isNotEmpty) {
      return {
        'first_run_date': result.first['first_run_date'],
        // نقرأ العمود الجديد
        'activation_expiry_date': result.first['activation_expiry_date'], 
      };
    }
    return null;
  }

  Future<void> initializeAppState() async {
    final db = await instance.database;
    await db.insert('TB_App_State', {
      'ID': 1,
      'first_run_date': DateTime.now().toIso8601String(),
      // لا نضع تاريخ انتهاء عند التهيئة
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// دالة لتفعيل التطبيق لمدة محددة. مدة التفعيل بالأيام (مثلاً 365 لسنة)
  Future<void> activateApp({required int durationInDays}) async {
    final db = await instance.database;
    final expiryDate = DateTime.now().add(Duration(days: durationInDays));
    await db.update(
      'TB_App_State',
      {'activation_expiry_date': expiryDate.toIso8601String()},
      where: 'ID = ?',
      whereArgs: [1],
    );
  }


///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////

///  دوال الإعدادات المحسّنة (تستخدم جدول TB_Settings الموجود) ---
// دالة لحفظ أو تحديث إعداد معين. قمنا بتغيير نوع الإرجاع إلى void للتبسيط.  
 Future<void> saveSetting(String key, String value) async {
    final db = await instance.database;
    await db.insert('TB_Settings', {'Key': key, 'Value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

    ///////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////  


// دالة لجلب كل الإعدادات المحفوظة كـ Map لسهولة الوصول إليها.
  Future<Map<String, String>> getAppSettings() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('TB_Settings');
  
    // تحويل قائمة الـ maps إلى map واحد باستخدام أسماء الأعمدة الصحيحة.
    return {for (var map in maps) map['Key']: map['Value']};
  }


//////////////////////////////////////////////////////////

  // --- باقي الدوال ---
  Future<void> logActivity(String action, {int? userId, String? userName}) async {
    final db = await instance.database;
    await db.insert('Activity_Log', {'UserID': userId, 'UserName': userName, 'Action': action, 'Timestamp': DateTime.now().toIso8601String()});
  }

  // ============================================================================
  // ← Hint: تم حذف جميع دوال TB_Users - النظام الجديد يستخدم Firebase Auth
  // ============================================================================
  // ← تم حذف الدوال التالية:
  // ← - getFirstUser() → Firebase Auth يدير المستخدم الحالي
  // ← - insertUser() → Firebase Auth يدير التسجيل
  // ← - updateUser() → Firestore يدير بيانات المستخدم
  // ← - deleteUser() → Firebase Auth يدير حذف الحسابات
  // ← - getAllUsers() → Firestore يدير قائمة المستخدمين
  // ← - getUserByUsername() → Firebase Auth يستخدم Email بدلاً من Username
  // ← - getUserCount() → غير مطلوب، Firebase يدير العد
  // ← - getUserByEmail() → Firebase Auth يوفر هذه الوظيفة
  // ← - getSubUsersByOwnerEmail() → Firestore Queries تدير هذا
  // ← - hasOwner() → Firestore/RemoteConfig يوفران هذه المعلومة
  // ← - getAllOwners() → Firestore Queries
  // ← - updateUserLastLogin() → Firebase Analytics/Firestore
  // ← - deactivateSubUser() → Firestore
  // ← - activateSubUser() → Firestore
  // ============================================================================

  // ============================================================================
  // 🆕 دوال Subscription Cache
  // ============================================================================

  /// حفظ/تحديث بيانات الاشتراك محلياً
  Future<void> saveSubscriptionCache(Map<String, dynamic> subscription) async {
    final db = await instance.database;
    await db.insert(
      'TB_Subscription_Cache',
      subscription,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// الحصول على بيانات الاشتراك المحلية
  Future<Map<String, dynamic>?> getSubscriptionCache() async {
    final db = await instance.database;
    final result = await db.query('TB_Subscription_Cache');
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  /// مسح بيانات الاشتراك المحلية
  Future<void> clearSubscriptionCache() async {
    final db = await instance.database;
    await db.delete('TB_Subscription_Cache');
  }  


  /// =============================================================================
  /// قسم: دوال إدارة الموردين والشركاء
  /// =============================================================================
  
  /// =============================================================================
/// ملاحظات مهمة للمطورين:
/// =============================================================================
/// 
/// 1. **المصطلحات:**
///    - "فردي": مورد واحد بدون شركاء
///    - "شراكة": مورد متعدد الشركاء (يجب أن يكون لديه شريك واحد على الأقل)
///    - "شريك": شخص داخل شراكة (ليس نوع مورد!)
/// 
/// 2. **قواعد النسب المئوية:**
///    - مجموع نسب الشركاء يجب ألا يتجاوز 100%
///    - يجب التحقق من هذا في الواجهة قبل الحفظ
/// 
/// 3. **الأرشفة vs الحذف:**
///    - نستخدم الأرشفة (IsActive = 0) بدلاً من الحذف النهائي
///    - هذا يحافظ على السجلات التاريخية ويمنع فقد البيانات
/// 
/// 4. **Transactions:**
///    - نستخدم Transactions عند إجراء عمليات متعددة مرتبطة
///    - إما تنجح كلها أو تفشل كلها (All or Nothing)
///    - مثال: إضافة مورد + إضافة شركائه
/// 
/// 5. **Foreign Keys:**
///    - العلاقة بين TB_Suppliers و Supplier_Partners هي One-to-Many
///    - كل شريك يرتبط بمورد واحد فقط (SupplierID)
///    - لكن المورد يمكن أن يكون له عدة شركاء
/// 
/// =============================================================================


  /// دالة لإدراج مورد جديد مع شركائه (إن وجدوا) في قاعدة البيانات.
  /// 
  /// **المعاملات:**
  /// - `supplier`: كائن المورد الجديد الذي سيتم إضافته
  /// - `partners`: قائمة بالشركاء (قد تكون فارغة إذا كان المورد فرديًا)
  /// 
  /// **آلية العمل:**
  /// 1. تستخدم Transaction لضمان تكامل البيانات (إما تنجح العملية كلها أو تفشل كلها)
  /// 2. تدرج المورد أولاً في جدول `TB_Suppliers` وتحصل على `supplierID`
  /// 3. إذا كان نوع المورد "شراكة"، تدرج كل الشركاء في جدول `Supplier_Partners`
  /// 4. تربط كل شريك بـ `supplierID` الصحيح
  /// 
  /// **مثال الاستخدام:**
  /// ```dart
  /// final newSupplier = Supplier(
  ///   supplierName: 'شركة النور',
  ///   supplierType: 'شراكة',
  ///   ...
  /// );
  /// 
  /// final partners = [
  ///   Partner(partnerName: 'أحمد', sharePercentage: 50),
  ///   Partner(partnerName: 'محمد', sharePercentage: 50),
  /// ];
  /// 
  /// await dbHelper.insertSupplierWithPartners(newSupplier, partners);
  /// ```
  Future<void> insertSupplierWithPartners(Supplier supplier, List<Partner> partners) async {
    final db = await instance.database;
    
    // استخدام Transaction لضمان تنفيذ العمليات كوحدة واحدة
    await db.transaction((txn) async {
      // الخطوة 1: إدراج المورد والحصول على ID الخاص به
      final supplierId = await txn.insert('TB_Suppliers', supplier.toMap());
      
      // الخطوة 2: إذا كان النوع "شراكة"، ندرج الشركاء
      if (supplier.supplierType == 'شراكة') {
        for (final partner in partners) {
          // نربط كل شريك بالمورد باستخدام supplierID
          // ونضيف تاريخ الإضافة الحالي
          await txn.insert(
            'Supplier_Partners', 
            partner.copyWith(
              supplierID: supplierId, 
              dateAdded: DateTime.now().toIso8601String()
            ).toMap()
          );
        }
      }
    });
  }

  /// دالة لتحديث بيانات مورد موجود مع إدارة شركائه.
  /// 
  /// **المعاملات:**
  /// - `supplier`: كائن المورد المحدّث (يجب أن يحتوي على `supplierID`)
  /// - `partners`: قائمة الشركاء الجديدة (ستحل محل القائمة القديمة)
  /// 
  /// **آلية العمل:**
  /// 1. تتحقق من وجود `supplierID` (لا يمكن التحديث بدونه)
  /// 2. تحدّث بيانات المورد الأساسية في جدول `TB_Suppliers`
  /// 3. تحذف **جميع** الشركاء القدامى المرتبطين بهذا المورد
  /// 4. إذا كان النوع "شراكة"، تضيف الشركاء الجدد
  /// 
  /// **ملاحظة مهمة:**
  /// - هذه الدالة تستبدل الشركاء القدامى بالكامل، لا تضيف عليهم
  /// - إذا تم تغيير النوع من "شراكة" إلى "فردي"، سيتم حذف كل الشركاء
  /// 
  /// **مثال الاستخدام:**
  /// ```dart
  /// // تحديث بيانات المورد
  /// supplier.supplierName = 'شركة النور المحدثة';
  /// 
  /// // قائمة شركاء جديدة (ستحذف القديمة)
  /// final newPartners = [
  ///   Partner(partnerName: 'أحمد', sharePercentage: 60),
  ///   Partner(partnerName: 'خالد', sharePercentage: 40),
  /// ];
  /// 
  /// await dbHelper.updateSupplierWithPartners(supplier, newPartners);
  /// ```
  Future<void> updateSupplierWithPartners(Supplier supplier, List<Partner> partners) async {
    final db = await instance.database;
    final supplierId = supplier.supplierID;
    
    // التحقق من وجود ID المورد
    if (supplierId == null) {
      return; // لا يمكن تحديث مورد بدون معرّف
    }

    // استخدام Transaction لضمان تكامل البيانات
    await db.transaction((txn) async {
      // الخطوة 1: تحديث بيانات المورد الأساسية
      await txn.update(
        'TB_Suppliers',
        supplier.toMap(),
        where: 'SupplierID = ?',
        whereArgs: [supplierId],
      );

      // الخطوة 2: حذف **جميع** الشركاء القدامى المرتبطين بهذا المورد
      // هذا يضمن عدم وجود بيانات متضاربة
      await txn.delete(
        'Supplier_Partners',
        where: 'SupplierID = ?',
        whereArgs: [supplierId],
      );

      // الخطوة 3: إضافة الشركاء الجدد إذا كان النوع "شراكة"
      if (supplier.supplierType == 'شراكة') {
        for (final partner in partners) {
          // نستخدم copyWith لضمان أن كل شريك يحمل supplierID الصحيح
          await txn.insert(
            'Supplier_Partners', 
            partner.copyWith(supplierID: supplierId).toMap()
          );
        }
      }
      // ملاحظة: إذا كان النوع "فردي"، لن يتم إضافة أي شركاء (وقد تم حذف القدامى)
    });
  }


  /// دالة لجلب كل الموردين النشطين من قاعدة البيانات.
  /// 
  /// **الوظيفة:**
  /// - تجلب جميع الموردين الذين `IsActive = 1` (نشطين فقط)
  /// - ترتبهم أبجديًا حسب `SupplierName`
  /// - إذا كان المورد من نوع "شراكة"، تجلب أيضًا قائمة شركائه
  /// 
  /// **العائد:**
  /// قائمة `List<Supplier>` تحتوي على كل الموردين النشطين مع شركائهم (إن وجدوا).
  /// 
  /// **مثال الاستخدام:**
  /// ```dart
  /// final suppliers = await dbHelper.getAllSuppliers();
  /// 
  /// for (var supplier in suppliers) {
  ///   print('${supplier.supplierName} - ${supplier.supplierType}');
  ///   
  ///   if (supplier.supplierType == 'شراكة') {
  ///     print('  الشركاء:');
  ///     for (var partner in supplier.partners) {
  ///       print('    - ${partner.partnerName}: ${partner.sharePercentage}%');
  ///     }
  ///   }
  /// }
  /// ```
  Future<List<Supplier>> getAllSuppliers() async {
    final db = await instance.database;
    
    // جلب كل الموردين النشطين مرتبين أبجديًا
    final supplierMaps = await db.query(
      'TB_Suppliers', 
      where: 'IsActive = ?', 
      whereArgs: [1], 
      orderBy: 'SupplierName ASC'
    );
    
    // تحويل النتائج من Map إلى كائنات Supplier
    List<Supplier> suppliers = supplierMaps.map((map) => Supplier.fromMap(map)).toList();
    
    // لكل مورد، إذا كان نوعه "شراكة"، نجلب قائمة شركائه
    for (var supplier in suppliers) {
      // ✅ التصحيح المطبق: تغيير 'شريك' إلى 'شراكة'
      if (supplier.supplierType == 'شراكة') {
        supplier.partners = await getPartnersForSupplier(supplier.supplierID!);
      }
    }
    
    return suppliers;
  }

  /// ✅ Hint: جلب مورد محدد بواسطة المعرف
  Future<Supplier?> getSupplierById(int supplierID) async {
    try {
      final db = await instance.database;
      final supplierMaps = await db.query(
        'TB_Suppliers',
        where: 'SupplierID = ? AND IsActive = ?',
        whereArgs: [supplierID, 1],
      );

      if (supplierMaps.isEmpty) {
        return null;
      }

      final supplier = Supplier.fromMap(supplierMaps.first);

      // جلب الشركاء إذا كان النوع "شراكة"
      if (supplier.supplierType == 'شراكة') {
        supplier.partners = await getPartnersForSupplier(supplier.supplierID!);
      }

      return supplier;
    } catch (e) {
      debugPrint('❌ خطأ في جلب المورد: $e');
      rethrow;
    }
  }

  /// دالة لأرشفة مورد (جعله غير نشط).
  /// 
  /// **المعامل:**
  /// - `id`: معرّف المورد (SupplierID) المراد أرشفته
  /// 
  /// **آلية العمل:**
  /// - لا تحذف المورد من قاعدة البيانات
  /// - فقط تغير `IsActive` من `1` إلى `0`
  /// - بهذا يبقى في السجلات لكن لا يظهر في القوائم العادية
  /// 
  /// **العائد:**
  /// عدد الصفوف المتأثرة (يجب أن يكون 1 في حالة النجاح)
  /// 
  /// **ملاحظة:**
  /// يجب التحقق من عدم وجود منتجات نشطة مرتبطة بهذا المورد قبل الأرشفة.
  /// استخدم `hasActiveProducts(supplierId)` للتحقق.
  Future<int> archiveSupplier(int id) async => 
    await (await instance.database).update(
      'TB_Suppliers', 
      {'IsActive': 0}, 
      where: 'SupplierID = ?', 
      whereArgs: [id]
    );


  /// دالة للتحقق من وجود منتجات نشطة مرتبطة بمورد معين.
  /// 
  /// **المعامل:**
  /// - `supplierId`: معرّف المورد (SupplierID)
  /// 
  /// **العائد:**
  /// - `true`: إذا كان هناك منتج واحد على الأقل نشط (`IsActive = 1`) لهذا المورد
  /// - `false`: إذا لم يكن هناك منتجات نشطة
  /// 
  /// **الاستخدام:**
  /// هذه الدالة مهمة جداً قبل أرشفة المورد. يجب التأكد من عدم وجود منتجات
  /// نشطة مرتبطة به، وإلا سيحدث تضارب في البيانات.
  /// 
  /// **مثال الاستخدام:**
  /// ```dart
  /// if (await dbHelper.hasActiveProducts(supplierId)) {
  ///   showError('لا يمكن أرشفة المورد لوجود منتجات نشطة مرتبطة به');
  ///   return;
  /// }
  /// 
  /// await dbHelper.archiveSupplier(supplierId);
  /// ```
  Future<bool> hasActiveProducts(int supplierId) async {
    final result = await (await instance.database).rawQuery(
      'SELECT COUNT(*) as count FROM Store_Products WHERE SupplierID = ? AND IsActive = 1', 
      [supplierId]
    );
    
    return (result.first['count'] as int) > 0;
  }

  /// دالة لجلب قائمة شركاء مورد معين.
  /// 
  /// **المعامل:**
  /// - `supplierId`: معرّف المورد (ID) الذي نريد جلب شركائه
  /// 
  /// **العائد:**
  /// قائمة `List<Partner>` تحتوي على جميع الشركاء المرتبطين بهذا المورد.
  /// 
  /// **مثال الاستخدام:**
  /// ```dart
  /// final partners = await dbHelper.getPartnersForSupplier(5);
  /// 
  /// print('عدد الشركاء: ${partners.length}');
  /// double totalPercentage = partners.fold(0, (sum, p) => sum + p.sharePercentage);
  /// print('إجمالي النسب: $totalPercentage%');
  /// ```
  Future<List<Partner>> getPartnersForSupplier(int supplierId) async {
    final maps = await (await instance.database).query(
      'Supplier_Partners', 
      where: 'SupplierID = ?', 
      whereArgs: [supplierId]
    );
    
    // تحويل النتائج من Map إلى كائنات Partner
    return maps.map((map) => Partner.fromMap(map)).toList();
  }

  Future<int> insertProduct(Product product) async => await (await instance.database).insert('Store_Products', product.toMap());
  Future<int> updateProduct(Product product) async => await (await instance.database).update('Store_Products', product.toMap(), where: 'ProductID = ?', whereArgs: [product.productID]);
  Future<int> archiveProduct(int id) async => await (await instance.database).update('Store_Products', {'IsActive': 0}, where: 'ProductID = ?', whereArgs: [id]);
  Future<bool> isProductSold(int id) async {
    final result = await (await instance.database).rawQuery('SELECT COUNT(*) as count FROM Debt_Customer WHERE ProductID = ? AND IsReturned = 0', [id]);
    return (result.first['count'] as int) > 0;
  }

  /// ← Hint: جلب جميع المنتجات مع أسماء الموردين والوحدات والتصنيفات
  Future<List<Product>> getAllProductsWithSupplierName() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT
        P.*,
        S.SupplierName,
        U.UnitNameAr as UnitName,
        C.CategoryNameAr as CategoryName
      FROM Store_Products P
      LEFT JOIN TB_Suppliers S ON P.SupplierID = S.SupplierID
      LEFT JOIN TB_ProductUnit U ON P.UnitID = U.UnitID
      LEFT JOIN TB_ProductCategory C ON P.CategoryID = C.CategoryID
      WHERE P.IsActive = 1
      ORDER BY P.ProductName
    ''');
    return result.map((map) => Product.fromMap(map)).toList();
  }

  /// ✅ Hint: جلب المنتجات المعطلة (كمية = 0)
  Future<List<Product>> getInactiveProducts() async {
    try {
      final db = await instance.database;
      final result = await db.rawQuery('''
        SELECT
          P.*,
          S.SupplierName,
          U.UnitNameAr as UnitName,
          C.CategoryNameAr as CategoryName
        FROM Store_Products P
        LEFT JOIN TB_Suppliers S ON P.SupplierID = S.SupplierID
        LEFT JOIN TB_ProductUnit U ON P.UnitID = U.UnitID
        LEFT JOIN TB_ProductCategory C ON P.CategoryID = C.CategoryID
        WHERE P.IsActive = 1 AND P.Quantity = 0
        ORDER BY P.ProductName
      ''');
      return result.map((map) => Product.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ خطأ في جلب المنتجات المعطلة: $e');
      rethrow;
    }
  }

  /// ✅ Hint: استعادة منتج (تحديث الكمية من 0 إلى قيمة جديدة)
  Future<int> reactivateProduct(int productID, int newQuantity) async {
    try {
      if (newQuantity <= 0) {
        throw Exception('الكمية يجب أن تكون أكبر من صفر');
      }

      final db = await instance.database;
      final result = await db.update(
        'Store_Products',
        {'Quantity': newQuantity},
        where: 'ProductID = ? AND IsActive = 1',
        whereArgs: [productID],
      );

      debugPrint('✅ تم استعادة المنتج $productID بكمية $newQuantity');
      return result;
    } catch (e) {
      debugPrint('❌ خطأ في استعادة المنتج: $e');
      rethrow;
    }
  }

  Future<int> insertCustomer(Customer customer) async => await (await instance.database).insert('TB_Customer', customer.toMap());
  Future<int> updateCustomer(Customer customer) async => await (await instance.database).update('TB_Customer', customer.toMap(), where: 'CustomerID = ?', whereArgs: [customer.customerID]);
  Future<int> archiveCustomer(int id) async => await (await instance.database).update('TB_Customer', {'IsActive': 0}, where: 'CustomerID = ?', whereArgs: [id]);
  Future<List<Customer>> getAllCustomers() async {
    final maps = await (await instance.database).query('TB_Customer', where: 'IsActive = ?', whereArgs: [1], orderBy: 'CustomerName ASC');
    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  Future<Customer?> getCustomerById(int id) async {
    final maps = await (await instance.database).query('TB_Customer', where: 'CustomerID = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Customer.fromMap(maps.first);
    return null;
  }

  Future<List<CustomerDebt>> getDebtsForCustomer(int customerId) async {
    final maps = await (await instance.database).query('Debt_Customer', where: 'CustomerID = ?', whereArgs: [customerId], orderBy: 'DateT DESC');
    return maps.map((map) => CustomerDebt.fromMap(map)).toList();
  }

  Future<List<CustomerPayment>> getPaymentsForCustomer(int customerId) async {
    final maps = await (await instance.database).query('Payment_Customer', where: 'CustomerID = ?', whereArgs: [customerId], orderBy: 'DateT DESC');
    return maps.map((map) => CustomerPayment.fromMap(map)).toList();
  }

  // --- التغيير الوحيد هنا ---
  // Hint: دالة إرجاع المبيعات المحدثة.
  // لم نعد نتحقق مما إذا كانت قيمة الإرجاع أكبر من الدين المتبقي.
  // ببساطة نقوم بإنقاص المبلغ المتبقي، مما يسمح له بأن يصبح سالبًا (رصيد دائن للزبون).
  // ← Hint: تسجل قيد مالي تلقائي عبر FinancialIntegrationHelper
  Future<void> returnSaleItem(CustomerDebt saleToReturn) async {
    final db = await instance.database;
    int? returnId;

    await db.transaction((txn) async {
      // الخطوة 1: تحديث حالة عملية البيع الأصلية إلى "مرجع".
      await txn.update('Debt_Customer', {'IsReturned': 1}, where: 'ID = ?', whereArgs: [saleToReturn.id]);
      // الخطوة 2: زيادة كمية المنتج في المخزن.
      await txn.rawUpdate('UPDATE Store_Products SET Quantity = Quantity + ? WHERE ProductID = ?',
       [saleToReturn.qty_Customer, saleToReturn.productID]);

      // الخطوة 3 (المُعدلة): إنقاص المبلغ المتبقي على الزبون.
      // لا يوجد تغيير في الكود هنا، لكن المنطق تغير. الآن نسمح بأن تكون النتيجة سالبة.
      await txn.rawUpdate('UPDATE TB_Customer SET Remaining = Remaining - ? WHERE CustomerID = ?',
       [saleToReturn.debt.toDouble(), saleToReturn.customerID]);

      // الخطوة 4: تسجيل عملية الإرجاع في جدول المرتجعات.
      final saleReturn = SalesReturn(
        originalSaleID: saleToReturn.id!,
        customerID: saleToReturn.customerID,
        productID: saleToReturn.productID,
        returnedQuantity: saleToReturn.qty_Customer,
        returnAmount: saleToReturn.debt,
        returnDate: DateTime.now().toIso8601String(),
        reason: 'إرجاع من قبل المستخدم',
      );
      returnId = await txn.insert('Sales_Returns', saleReturn.toMap());
    });

    // ← Hint: تسجيل القيد المالي التلقائي (بعد transaction)
    if (returnId != null && saleToReturn.id != null) {
      await FinancialIntegrationHelper.recordSaleReturnTransaction(
        returnId: returnId!,
        originalSaleId: saleToReturn.id!,
        customerId: saleToReturn.customerID,
        amount: saleToReturn.debt,
        returnDate: DateTime.now().toIso8601String(),
        reason: 'إرجاع من قبل المستخدم',
      );
    }
  }



  // Hint: دالة لجلب كل عمليات البيع (الديون) التي لم يتم إرجاعها.
  Future<List<CustomerDebt>> getAllSales() async {
    final db = await instance.database;
    final maps = await db.query('Debt_Customer', where: 'IsReturned = 0', orderBy: 'DateT DESC');
    if (maps.isNotEmpty) {
      return maps.map((map) => CustomerDebt.fromMap(map)).toList();
    }
    return [];
  }

  //================================
  // Hint: دالة لحساب إجمالي الأرباح من جميع المبيعات التي لم يتم إرجاعها.
  Future<Decimal> getTotalProfit() async {
     final db = await instance.database;
     final result = await db.rawQuery(
      'SELECT SUM(ProfitAmount) as Total FROM Debt_Customer WHERE IsReturned = 0'
     );
  
     final data = result.first;
     if (data['Total'] != null) {
     return Decimal.parse(data['Total'].toString());
     }
     return Decimal.zero;
   }

  // Hint: دالة لجلب إجمالي الأرباح مجمعة حسب كل مورد (فقط من المبيعات غير المرجعة).
  Future<List<Map<String, dynamic>>> getProfitBySupplier() async {

    final db = await instance.database;
  final String sql = """
    SELECT 
      S.SupplierID, S.SupplierName, S.SupplierType, SUM(D.ProfitAmount) as TotalProfit
    FROM Debt_Customer D
    JOIN Store_Products P ON D.ProductID = P.ProductID
    JOIN TB_Suppliers S ON P.SupplierID = S.SupplierID
    WHERE D.IsReturned = 0
    GROUP BY S.SupplierID, S.SupplierName, S.SupplierType
    ORDER BY TotalProfit DESC
  """;
  
  final results = await db.rawQuery(sql);
  
  // ✅ تحويل TotalProfit إلى Decimal
  return results.map((row) {
    final map = Map<String, dynamic>.from(row);
    if (map['TotalProfit'] != null) {
      map['TotalProfit'] = Decimal.parse(map['TotalProfit'].toString());
    }
    return map;
  }).toList();

    }


  // Hint: دالة لجلب تفاصيل المبيعات (غير المرجعة) لمورد معين.
  Future<List<CustomerDebt>> getSalesForSupplier(int supplierId) async {
    final db = await instance.database;
    final String sql = """
      SELECT D.* 
      FROM Debt_Customer D
      JOIN Store_Products P ON D.ProductID = P.ProductID
      WHERE P.SupplierID = ? AND D.IsReturned = 0
      ORDER BY D.DateT DESC
    """;
    final result = await db.rawQuery(sql, [supplierId]);
    return result.map((map) => CustomerDebt.fromMap(map)).toList();
  }


  // --- دوال مركز الأرشفة ---

  // Hint: دالة لجلب كل الزبائن المؤرشفين فقط.
  // وضعنا شرط ايضا ان يقوم باخفاء اسم الزبون المباشر لكي لا يظهر في الارشفة 
  Future<List<Customer>> getArchivedCustomers() async {
    final db = await instance.database;
    final maps = await db.query(
     'TB_Customer', 
     where: 'IsActive = 0 AND CustomerName != ?',
     whereArgs: [cashCustomerInternalName],
     orderBy: 'CustomerName ASC',
     );
    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  // Hint: دالة لجلب كل الموردين المؤرشفين فقط.
  Future<List<Supplier>> getArchivedSuppliers() async {
    final db = await instance.database;
    final maps = await db.query('TB_Suppliers', where: 'IsActive = 0', orderBy: 'SupplierName ASC');
    return List.generate(maps.length, (i) => Supplier.fromMap(maps[i]));
  }

  // Hint: دالة لجلب كل المنتجات المؤرشفة فقط مع أسماء مورديها.
  Future<List<Product>> getArchivedProductsWithSupplierName() async {
    final db = await instance.database;
    final result = await db.rawQuery("""
      SELECT P.*, S.SupplierName 
      FROM Store_Products P 
      LEFT JOIN TB_Suppliers S ON P.SupplierID = S.SupplierID 
      WHERE P.IsActive = 0 
      ORDER BY P.ProductName
    """);
    return result.map((map) => Product.fromMap(map)).toList();
  }

  // --- دوال الاستعادة ---

  // Hint: دالة لاستعادة (إعادة تنشيط) عنصر مؤرشف.
  // نمرر لها اسم الجدول، اسم عمود الـ ID، والـ ID الخاص بالعنصر.
  Future<int> restoreItem(String tableName, String idColumn, int id) async {
    final db = await instance.database;
    return await db.update(
      tableName,
      {'IsActive': 1}, // Hint: ببساطة نعيد قيمة IsActive إلى 1.
      where: '$idColumn = ?',
      whereArgs: [id],
    );
  }


///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////
  // --- دوال إدارة الموظفين ---

// Hint: دالة لجلب كل الموظفين النشطين.
Future<List<Employee>> getAllActiveEmployees() async {
  final db = await instance.database;
  final maps = await db.query('TB_Employees', where: 'IsActive = 1', orderBy: 'FullName ASC');
  return List.generate(maps.length, (i) => Employee.fromMap(maps[i]));
}

// Hint: دالة لإضافة موظف جديد.
Future<int> insertEmployee(Employee employee) async {
  final db = await instance.database;
  return await db.insert('TB_Employees', employee.toMap());
}

// Hint: دالة لتحديث بيانات موظف.
Future<int> updateEmployee(Employee employee) async {
  final db = await instance.database;
  return await db.update('TB_Employees', employee.toMap(), where: 'EmployeeID = ?', whereArgs: [employee.employeeID]);
}

// Hint: دالة لأرشفة موظف (جعله غير نشط).
Future<int> archiveEmployee(int id) async {
  final db = await instance.database;
  return await db.update('TB_Employees', {'IsActive': 0}, where: 'EmployeeID = ?', whereArgs: [id]);
}

// Hint: دالة لاستعادة موظف مؤرشف (جعله نشط مرة أخرى).
Future<int> restoreEmployee(int id) async {
  final db = await instance.database;
  return await db.update('TB_Employees', {'IsActive': 1}, where: 'EmployeeID = ?', whereArgs: [id]);
}

// Hint: دالة للتحقق من وجود التزامات مالية للموظف (رواتب، سلف، مكافآت).
Future<bool> employeeHasFinancialObligations(int employeeId) async {
  final db = await instance.database;

  // التحقق من وجود سجلات رواتب
  final payrollCount = Sqflite.firstIntValue(
    await db.rawQuery('SELECT COUNT(*) FROM TB_Payroll WHERE EmployeeID = ?', [employeeId]),
  ) ?? 0;

  if (payrollCount > 0) return true;

  // التحقق من وجود سلف
  final advancesCount = Sqflite.firstIntValue(
    await db.rawQuery('SELECT COUNT(*) FROM TB_Employee_Advances WHERE EmployeeID = ?', [employeeId]),
  ) ?? 0;

  if (advancesCount > 0) return true;

  // التحقق من وجود مكافآت
  final bonusesCount = Sqflite.firstIntValue(
    await db.rawQuery('SELECT COUNT(*) FROM TB_Employee_Bonuses WHERE EmployeeID = ?', [employeeId]),
  ) ?? 0;

  return bonusesCount > 0;
}

// Hint: دالة لجلب الموظفين المؤرشفين (غير النشطين).
Future<List<models.Employee>> getArchivedEmployees() async {
  final db = await instance.database;
  final maps = await db.query('TB_Employees', where: 'IsActive = 0', orderBy: 'FullName ASC');
  return List.generate(maps.length, (i) => models.Employee.fromMap(maps[i]));
}

// Hint: دالة لجلب كل سجلات الرواتب لموظف معين.
Future<List<PayrollEntry>> getPayrollForEmployee(int employeeId) async {
  final db = await instance.database;
  final maps = await db.query('TB_Payroll', where: 'EmployeeID = ?', whereArgs: [employeeId], orderBy: 'PaymentDate DESC');
  return List.generate(maps.length, (i) => PayrollEntry.fromMap(maps[i]));
}






// Hint: دالة لجلب كل سجلات السلف لموظف معين.
Future<List<EmployeeAdvance>> getAdvancesForEmployee(int employeeId) async {
  final db = await instance.database;
  final maps = await db.query('TB_Employee_Advances', where: 'EmployeeID = ?', whereArgs: [employeeId], orderBy: 'AdvanceDate DESC');
  return List.generate(maps.length, (i) => EmployeeAdvance.fromMap(maps[i]));
}

// Hint: دالة لجلب بيانات موظف معين بالـ ID الخاص به.
// سنحتاجها لتحديث بيانات الموظف في الشاشة بعد كل عملية.
Future<Employee?> getEmployeeById(int id) async {
  final db = await instance.database;
  final maps = await db.query('TB_Employees', where: 'EmployeeID = ?', whereArgs: [id]);
  if (maps.isNotEmpty) {
    return Employee.fromMap(maps.first);
  }
  return null;
}

// Hint: دالة لتسجيل سلفة جديدة لموظف.
// تستخدم transaction لضمان تنفيذ العمليتين معًا.
// ← Hint: تسجل قيد مالي تلقائي عبر FinancialIntegrationHelper
Future<void> recordNewAdvance(EmployeeAdvance advance) async {
  final db = await instance.database;
  int? advanceId;

  await db.transaction((txn) async {
    // ← Hint: إدراج السلفة في الجدول
    advanceId = await txn.insert('TB_Employee_Advances', advance.toMap());

    // ✅ تحديث رصيد الموظف
    await txn.rawUpdate(
      'UPDATE TB_Employees SET Balance = Balance + ? WHERE EmployeeID = ?',
      [advance.advanceAmount.toDouble(), advance.employeeID],
    );
  });

  // ← Hint: تسجيل القيد المالي التلقائي (بعد transaction)
  if (advanceId != null) {
    await FinancialIntegrationHelper.recordAdvanceTransaction(
      advanceId: advanceId!,
      employeeId: advance.employeeID,
      amount: advance.advanceAmount,
      advanceDate: advance.advanceDate,
      notes: advance.notes,
    );
  }
}



// دالة لتسجيل عملية دفع راتب جديدة.
// هذه دالة حرجة تستخدم transaction لضمان تكامل البيانات.
// ← Hint: تسجل قيد مالي تلقائي عبر FinancialIntegrationHelper
Future<void> recordNewPayroll(PayrollEntry payroll, Decimal advanceAmountToRepay) async {
  final db = await instance.database;
  int? payrollId;

  await db.transaction((txn) async {
    // ← Hint: إدراج الراتب في الجدول
    payrollId = await txn.insert('TB_Payroll', payroll.toMap());

    await txn.rawUpdate(
      'UPDATE TB_Employees SET Balance = Balance - ? WHERE EmployeeID = ?',
      [advanceAmountToRepay.toDouble(), payroll.employeeID],
    );

    // ✅ تحديث حالة السلف
    final result = await txn.query(
      'TB_Employees',
      columns: ['Balance'],
      where: 'EmployeeID = ?',
      whereArgs: [payroll.employeeID],
    );

    final currentBalance = Decimal.parse(result.first['Balance'].toString());

    if (currentBalance <= Decimal.zero) {
      await txn.update(
        'TB_Employee_Advances',
        {'RepaymentStatus': 'مسددة بالكامل'},
        where: 'EmployeeID = ? AND RepaymentStatus != ?',
        whereArgs: [payroll.employeeID, 'مسددة بالكامل'],
      );
    }
  });

  // ← Hint: تسجيل القيد المالي التلقائي (بعد transaction)
  if (payrollId != null) {
    await FinancialIntegrationHelper.recordSalaryTransaction(
      payrollId: payrollId!,
      employeeId: payroll.employeeID,
      netSalary: payroll.netSalary,
      paymentDate: payroll.paymentDate,
      notes: 'راتب ${payroll.payrollMonth}/${payroll.payrollYear}',
    );
  }
}


//  دالة للتحقق مما إذا كان قد تم تسجيل راتب لنفس الموظف في نفس الشهر والسنة.
Future<bool> isPayrollDuplicate(int employeeId, int month, int year) async {
  final db = await instance.database;
  final result = await db.rawQuery(
    'SELECT COUNT(*) FROM TB_Payroll WHERE EmployeeID = ? AND PayrollMonth = ? AND PayrollYear = ?',
    [employeeId, month, year],
  );
  final count = Sqflite.firstIntValue(result);
  return count != null && count > 0;
}


// Hint: دالة لحساب إجمالي الرواتب الصافية المدفوعة.
Future<Decimal> getTotalNetSalariesPaid() async {
    final db = await instance.database;
  final result = await db.rawQuery(
    'SELECT SUM(NetSalary) as Total FROM TB_Payroll'
  );

  if (result.first['Total'] != null) {
    return Decimal.parse(result.first['Total'].toString());
  }
  return Decimal.zero;
}

// ============================================================================
// ← Hint: دوال تعديل وحذف الرواتب (Payroll Edit/Delete)
// ============================================================================

// ← Hint: تعديل راتب موجود
// ← Hint: يحسب الفرق ويحدث رصيد الموظف
Future<void> editPayroll({
  required int payrollID,
  required String newDate,
  required Decimal newBaseSalary,
  required Decimal newBonuses,
  required Decimal newDeductions,
  required Decimal newAdvanceDeduction,
  required Decimal newNetSalary,
  String? newNotes,
}) async {
  final db = await instance.database;

  await db.transaction((txn) async {
    // جلب الراتب القديم
    final oldPayrollMaps = await txn.query(
      'TB_Payroll',
      where: 'PayrollID = ?',
      whereArgs: [payrollID],
    );

    if (oldPayrollMaps.isEmpty) return;

    final oldAdvanceDeduction = Decimal.parse(oldPayrollMaps.first['AdvanceDeduction'].toString());
    final advanceDifference = newAdvanceDeduction - oldAdvanceDeduction;

    // تحديث الراتب
    await txn.update(
      'TB_Payroll',
      {
        'PaymentDate': newDate,
        'BaseSalary': newBaseSalary.toDouble(),
        'Bonuses': newBonuses.toDouble(),
        'Deductions': newDeductions.toDouble(),
        'AdvanceDeduction': newAdvanceDeduction.toDouble(),
        'NetSalary': newNetSalary.toDouble(),
        'Notes': newNotes,
      },
      where: 'PayrollID = ?',
      whereArgs: [payrollID],
    );

    // تحديث رصيد الموظف بفرق خصم السلفة
    await txn.rawUpdate(
      'UPDATE TB_Employees SET Balance = Balance + ?',
      [advanceDifference.toDouble()],
    );
  });
}

// ← Hint: حذف راتب
// ← Hint: يعيد رصيد السلفة للموظف
Future<void> deletePayroll(int payrollID) async {
  final db = await instance.database;

  await db.transaction((txn) async {
    // جلب الراتب
    final payrollMaps = await txn.query(
      'TB_Payroll',
      where: 'PayrollID = ?',
      whereArgs: [payrollID],
    );

    if (payrollMaps.isEmpty) return;

    final advanceDeduction = Decimal.parse(payrollMaps.first['AdvanceDeduction'].toString());

    // حذف الراتب
    await txn.delete(
      'TB_Payroll',
      where: 'PayrollID = ?',
      whereArgs: [payrollID],
    );

    // إرجاع خصم السلفة لرصيد الموظف
    await txn.rawUpdate(
      'UPDATE TB_Employees SET Balance = Balance + ?',
      [advanceDeduction.toDouble()],
    );
  });
}

// ============================================================================
// ← Hint: دوال تعديل وحذف السلف (Advances Edit/Delete)
// ============================================================================

// ← Hint: تعديل سلفة موجودة
// ← Hint: يحسب الفرق ويحدث رصيد الموظف
Future<void> editAdvance({
  required int advanceID,
  required String newDate,
  required Decimal newAmount,
  required String newStatus,
  String? newNotes,
}) async {
  final db = await instance.database;

  await db.transaction((txn) async {
    // جلب السلفة القديمة
    final oldAdvanceMaps = await txn.query(
      'TB_Employee_Advances',
      where: 'AdvanceID = ?',
      whereArgs: [advanceID],
    );

    if (oldAdvanceMaps.isEmpty) return;

    final oldAmount = Decimal.parse(oldAdvanceMaps.first['AdvanceAmount'].toString());
    final difference = newAmount - oldAmount;

    // تحديث السلفة
    await txn.update(
      'TB_Employee_Advances',
      {
        'AdvanceDate': newDate,
        'AdvanceAmount': newAmount.toDouble(),
        'RepaymentStatus': newStatus,
        'Notes': newNotes,
      },
      where: 'AdvanceID = ?',
      whereArgs: [advanceID],
    );

    // تحديث رصيد الموظف بالفرق
    await txn.rawUpdate(
      'UPDATE TB_Employees SET Balance = Balance + ?',
      [difference.toDouble()],
    );
  });
}

// ← Hint: حذف سلفة (مع معالجة التسديدات بشكل صحيح)
// ← Hint: تحذف السلفة وجميع تسديداتها من قاعدة البيانات
// ← Hint: تحدّث Balance بشكل صحيح عند الحذف
// ← Hint:
// ← Hint: السيناريوهات المدعومة:
// ← Hint: - حذف سلفة غير مسددة: Balance = Balance - AdvanceAmount
// ← Hint: - حذف سلفة مسددة جزئياً: Balance = Balance + TotalRepaid - AdvanceAmount
// ← Hint: - حذف سلفة مسددة بالكامل: Balance = Balance + TotalRepaid - AdvanceAmount = Balance + 0
// ← Hint:
// ← Hint: معادلة التحديث الموحدة:
// ← Hint: Balance = Balance + (TotalRepaid - AdvanceAmount)
// ← Hint:
// ← Hint: التفسير:
// ← Hint: 1. عند إعطاء السلفة: Balance += AdvanceAmount (زيادة الرصيد)
// ← Hint: 2. عند التسديد: Balance -= RepaymentAmount (تخفيض الرصيد)
// ← Hint: 3. عند الحذف: نعكس العمليتين:
// ← Hint:    - نزيل أثر السلفة: -AdvanceAmount
// ← Hint:    - نزيل أثر التسديدات: +TotalRepaid
// ← Hint:    - النتيجة: Balance += (TotalRepaid - AdvanceAmount)
Future<void> deleteAdvance(int advanceID) async {
  final db = await instance.database;

  await db.transaction((txn) async {
    // ← Hint: 1. جلب معلومات السلفة
    final advanceMaps = await txn.query(
      'TB_Employee_Advances',
      where: 'AdvanceID = ?',
      whereArgs: [advanceID],
    );

    if (advanceMaps.isEmpty) return;

    final employeeID = advanceMaps.first['EmployeeID'] as int;
    final advanceAmount = Decimal.parse(advanceMaps.first['AdvanceAmount'].toString());

    // ← Hint: 2. حساب إجمالي التسديدات الموجودة لهذه السلفة
    // ← Hint: نحتاج هذا لحساب تأثير الحذف على Balance بشكل صحيح
    final repaymentsMaps = await txn.query(
      'TB_Advance_Repayments',
      where: 'AdvanceID = ?',
      whereArgs: [advanceID],
    );

    Decimal totalRepaid = Decimal.zero;
    for (var repayment in repaymentsMaps) {
      totalRepaid += Decimal.parse(repayment['RepaymentAmount'].toString());
    }

    // ← Hint: 🛡️ شرط الأمان: التحقق من التسديد الكامل قبل الحذف
    // ← Hint: منع حذف السلفة إذا لم يتم تسديدها بالكامل (حماية البيانات المالية)
    if (totalRepaid < advanceAmount) {
      final remaining = advanceAmount - totalRepaid;
      throw Exception(
        'لا يمكن حذف السلفة - المبلغ المتبقي: ${remaining.toStringAsFixed(2)} دينار\n'
        'يجب تسديد السلفة بالكامل أولاً قبل الحذف.'
      );
    }

    // ← Hint: 3. حذف جميع التسديدات أولاً
    // ← Hint: على الرغم من وجود CASCADE DELETE في schema قاعدة البيانات،
    // ← Hint: نحذفها يدوياً لضمان عملها في جميع إصدارات SQLite
    await txn.delete(
      'TB_Advance_Repayments',
      where: 'AdvanceID = ?',
      whereArgs: [advanceID],
    );

    // ← Hint: 4. حذف السلفة نفسها
    await txn.delete(
      'TB_Employee_Advances',
      where: 'AdvanceID = ?',
      whereArgs: [advanceID],
    );

    // ← Hint: 5. تحديث رصيد الموظف بالصيغة الصحيحة
    // ← Hint: Balance = Balance + (TotalRepaid - AdvanceAmount)
    // ← Hint:
    // ← Hint: أمثلة:
    // ← Hint: - سلفة 50,000 غير مسددة (TotalRepaid=0):
    // ← Hint:   Adjustment = 0 - 50,000 = -50,000 ✅
    // ← Hint:   (عكس العملية الأصلية عند إعطاء السلفة)
    // ← Hint:
    // ← Hint: - سلفة 50,000 مسددة جزئياً بـ 20,000 (TotalRepaid=20,000):
    // ← Hint:   Adjustment = 20,000 - 50,000 = -30,000 ✅
    // ← Hint:   (نعكس السلفة الأصلية ونعكس التسديدات)
    // ← Hint:
    // ← Hint: - سلفة 50,000 مسددة بالكامل (TotalRepaid=50,000):
    // ← Hint:   Adjustment = 50,000 - 50,000 = 0 ✅
    // ← Hint:   (Balance لن يتغير لأن السلفة والتسديد كانا متساويين)
    final balanceAdjustment = totalRepaid - advanceAmount;

    await txn.rawUpdate(
      'UPDATE TB_Employees SET Balance = Balance + ? WHERE EmployeeID = ?',
      [balanceAdjustment.toDouble(), employeeID],
    );

    debugPrint('✅ تم حذف السلفة #$advanceID');
    debugPrint('   ├─ مبلغ السلفة: ${advanceAmount.toStringAsFixed(2)}');
    debugPrint('   ├─ إجمالي التسديدات: ${totalRepaid.toStringAsFixed(2)}');
    debugPrint('   └─ تعديل الرصيد: ${balanceAdjustment.toStringAsFixed(2)}');
  });
}

// ← Hint: تسديد سلفة
// ← Hint: يغير حالة السلفة من "غير مسددة" إلى "مسددة بالكامل"
// ← Hint: دالة تسديد السلفة (النظام الجديد مع دعم التسديد الجزئي والكامل)
// ← Hint: تسجل عملية التسديد في جدول TB_Advance_Repayments
// ← Hint: تحدّث Balance في TB_Employees
// ← Hint: تحدّث RepaymentStatus في TB_Employee_Advances
// ← Hint: تسجل قيد مالي تلقائي عبر FinancialIntegrationHelper
Future<void> repayAdvance({
  required int advanceID,
  required int employeeID,
  required Decimal repaymentAmount,
  String? notes,
}) async {
  final db = await instance.database;
  int? repaymentId;

  await db.transaction((txn) async {
    // ← Hint: 1. جلب معلومات السلفة للتحقق من المبلغ المتبقي
    final advanceResult = await txn.query(
      'TB_Employee_Advances',
      where: 'AdvanceID = ?',
      whereArgs: [advanceID],
    );

    if (advanceResult.isEmpty) {
      throw Exception('السلفة غير موجودة');
    }

    final advanceData = advanceResult.first;
    final advanceAmount = Decimal.parse(advanceData['AdvanceAmount'].toString());

    // ← Hint: 2. حساب المبلغ المسدد مسبقاً من جدول التسديدات
    final repaymentsResult = await txn.rawQuery(
      'SELECT COALESCE(SUM(RepaymentAmount), 0) as TotalRepaid FROM TB_Advance_Repayments WHERE AdvanceID = ?',
      [advanceID],
    );
    final totalRepaid = Decimal.parse(repaymentsResult.first['TotalRepaid'].toString());

    // ← Hint: 3. حساب المبلغ المتبقي
    final remainingAmount = advanceAmount - totalRepaid;

    // ← Hint: 4. التحقق من أن المبلغ المسدد لا يتجاوز المبلغ المتبقي
    if (repaymentAmount > remainingAmount) {
      throw Exception('المبلغ المسدد ($repaymentAmount) أكبر من المبلغ المتبقي ($remainingAmount)');
    }

    // ← Hint: 5. تسجيل التسديد في جدول TB_Advance_Repayments
    final repayment = AdvanceRepayment(
      advanceID: advanceID,
      employeeID: employeeID,
      repaymentDate: DateTime.now().toIso8601String(),
      repaymentAmount: repaymentAmount,
      notes: notes,
    );

    repaymentId = await txn.insert('TB_Advance_Repayments', repayment.toMap());

    // ← Hint: 6. تحديث Balance في TB_Employees (تنقيص المبلغ المسدد)
    await txn.rawUpdate(
      'UPDATE TB_Employees SET Balance = Balance - ? WHERE EmployeeID = ?',
      [repaymentAmount.toDouble(), employeeID],
    );

    // ← Hint: 7. تحديث حالة السلفة (RepaymentStatus)
    final newTotalRepaid = totalRepaid + repaymentAmount;
    final newStatus = newTotalRepaid >= advanceAmount
        ? 'مسددة بالكامل'
        : newTotalRepaid > Decimal.zero
            ? 'مسددة جزئيًا'
            : 'غير مسددة';

    await txn.update(
      'TB_Employee_Advances',
      {'RepaymentStatus': newStatus},
      where: 'AdvanceID = ?',
      whereArgs: [advanceID],
    );
  });

  // ← Hint: تسجيل القيد المالي التلقائي (بعد transaction)
  if (repaymentId != null) {
    await FinancialIntegrationHelper.recordAdvanceRepaymentTransaction(
      repaymentId: repaymentId!,
      advanceId: advanceID,
      employeeId: employeeID,
      amount: repaymentAmount,
      repaymentDate: DateTime.now().toIso8601String(),
      notes: notes,
    );
  }
}

// ============================================================================
// دوال مساعدة للتسديدات (جديد في v5)
// ============================================================================

// ← Hint: جلب تسديدات سلفة معينة
// ← Hint: يُستخدم لعرض سجل التسديدات في تفاصيل السلفة
Future<List<AdvanceRepayment>> getRepaymentsForAdvance(int advanceID) async {
  final db = await instance.database;
  final maps = await db.query(
    'TB_Advance_Repayments',
    where: 'AdvanceID = ?',
    whereArgs: [advanceID],
    orderBy: 'RepaymentDate DESC',
  );
  return maps.map((map) => AdvanceRepayment.fromMap(map)).toList();
}

// ← Hint: حساب المبلغ المتبقي من السلفة
// ← Hint: = مبلغ السلفة - مجموع التسديدات
Future<Decimal> getRemainingAdvanceAmount(int advanceID) async {
  final db = await instance.database;

  // ← Hint: جلب مبلغ السلفة الأصلي
  final advanceResult = await db.query(
    'TB_Employee_Advances',
    columns: ['AdvanceAmount'],
    where: 'AdvanceID = ?',
    whereArgs: [advanceID],
  );

  if (advanceResult.isEmpty) {
    return Decimal.zero;
  }

  final advanceAmount = Decimal.parse(advanceResult.first['AdvanceAmount'].toString());

  // ← Hint: حساب مجموع التسديدات
  final repaymentsResult = await db.rawQuery(
    'SELECT COALESCE(SUM(RepaymentAmount), 0) as TotalRepaid FROM TB_Advance_Repayments WHERE AdvanceID = ?',
    [advanceID],
  );

  final totalRepaid = Decimal.parse(repaymentsResult.first['TotalRepaid'].toString());

  // ← Hint: المبلغ المتبقي = المبلغ الأصلي - المبلغ المسدد
  return advanceAmount - totalRepaid;
}

// ← Hint: جلب إجمالي التسديدات في فترة زمنية معينة
// ← Hint: يُستخدم في تقرير التدفقات النقدية لعرض التسديدات كإيرادات
Future<double> getTotalRepaymentsInPeriod({
  DateTime? startDate,
  DateTime? endDate,
}) async {
  final db = await instance.database;

  String sql = 'SELECT SUM(RepaymentAmount) as total FROM TB_Advance_Repayments WHERE 1=1';
  final List<dynamic> args = [];

  if (startDate != null) {
    sql += ' AND RepaymentDate >= ?';
    args.add(startDate.toIso8601String());
  }

  if (endDate != null) {
    sql += ' AND RepaymentDate <= ?';
    args.add(endDate.toIso8601String());
  }

  final result = await db.rawQuery(sql, args);
  return result.first['total'] != null ? (result.first['total'] as num).toDouble() : 0.0;
}

// ← Hint: جلب تفاصيل التسديدات في فترة زمنية معينة
// ← Hint: يُستخدم لعرض قائمة مفصلة بالتسديدات في التقارير
Future<List<Map<String, dynamic>>> getRepaymentsDetailsInPeriod({
  DateTime? startDate,
  DateTime? endDate,
}) async {
  final db = await instance.database;

  String sql = '''
    SELECT
      r.*,
      e.FullName as EmployeeName,
      a.AdvanceAmount as OriginalAdvanceAmount
    FROM TB_Advance_Repayments r
    INNER JOIN TB_Employees e ON r.EmployeeID = e.EmployeeID
    INNER JOIN TB_Employee_Advances a ON r.AdvanceID = a.AdvanceID
    WHERE 1=1
  ''';

  final List<dynamic> args = [];

  if (startDate != null) {
    sql += ' AND r.RepaymentDate >= ?';
    args.add(startDate.toIso8601String());
  }

  if (endDate != null) {
    sql += ' AND r.RepaymentDate <= ?';
    args.add(endDate.toIso8601String());
  }

  sql += ' ORDER BY r.RepaymentDate DESC';

  return await db.rawQuery(sql, args);
}

// Hint: دالة لحساب إجمالي رصيد السلف المستحقة على جميع الموظفين.
Future<Decimal> getTotalActiveAdvancesBalance() async {
    final db = await instance.database;
  final result = await db.rawQuery(
    'SELECT SUM(Balance) as Total FROM TB_Employees WHERE IsActive = 1'
  );
  
  if (result.first['Total'] != null) {
    return Decimal.parse(result.first['Total'].toString());
  }
  return Decimal.zero;
}

// Hint: دالة لحساب عدد الموظفين النشطين.
Future<int> getActiveEmployeesCount() async {
  final db = await instance.database;
  final result = await db.rawQuery('SELECT COUNT(*) FROM TB_Employees WHERE IsActive = 1');
  return Sqflite.firstIntValue(result) ?? 0;
}

// Hint: دالة لحساب إجمالي المكافآت المدفوعة لجميع الموظفين.
// تجمع كل قيم Bonuses من جدول TB_Payroll.
Future<Decimal> getTotalBonuses() async {
  final db = await instance.database;
  final result = await db.rawQuery(
    'SELECT SUM(Bonuses) as Total FROM TB_Payroll'
  );
  
  if (result.first['Total'] != null) {
    return Decimal.parse(result.first['Total'].toString());
  }
  return Decimal.zero;
}

// Hint: دالة لحساب إجمالي الخصومات المطبقة على جميع الموظفين.
// تجمع كل قيم Deductions من جدول TB_Payroll.
Future<Decimal> getTotalDeductions() async {
  final db = await instance.database;
  final result = await db.rawQuery(
    'SELECT SUM(Deductions) as Total FROM TB_Payroll'
  );

  if (result.first['Total'] != null) {
    return Decimal.parse(result.first['Total'].toString());
  }
  return Decimal.zero;
}

// Hint: دالة لحساب إجمالي المكافآت من TB_Employee_Bonuses (النظام الجديد).
// ← ملاحظة: هذه الدالة تقرأ من TB_Employee_Bonuses فقط (المكافآت الجديدة المنفصلة).
// ← للحصول على المكافآت القديمة من TB_Payroll، استخدم getTotalBonuses().
Future<Decimal> getTotalEmployeeBonuses() async {
  final db = await instance.database;
  final result = await db.rawQuery(
    'SELECT SUM(BonusAmount) as Total FROM TB_Employee_Bonuses'
  );

  if (result.first['Total'] != null) {
    return Decimal.parse(result.first['Total'].toString());
  }
  return Decimal.zero;
}


// =================================================================================================
  // ✅✅✅ Hint: دالة جديدة للبحث عن منتج باستخدام الباركود الخاص به. ✅✅✅
  // =================================================================================================
  // هذه الدالة هي المحرك الرئيسي لميزة البيع السريع بالباركود.
  // وظيفتها: استقبال باركود (String)، والبحث في قاعدة البيانات عن منتج يمتلك هذا الباركود.
  Future<Product?> getProductByBarcode(String barcode) async {
    // Hint: نتأكد من الحصول على نسخة من قاعدة البيانات.
    final db = await instance.database;
    
    // Hint: نستخدم دالة `query` للبحث في جدول `Store_Products`.
    // `where`: هذا هو الشرط. نبحث عن صف يكون فيه عمود `Barcode` مطابقاً للقيمة المستلمة،
    // وأيضاً يكون المنتج نشطاً (`IsActive = 1`). هذا يمنع بيع المنتجات المؤرشفة.
    // `whereArgs`: نمرر قيمة الباركود هنا لمنع هجمات SQL Injection.
    final maps = await db.query(
      'Store_Products',
      where: 'Barcode = ? AND IsActive = 1',
      whereArgs: [barcode],
    );

    // Hint: `query` تعيد قائمة من النتائج. نحن نتأكد من أن القائمة ليست فارغة.
    if (maps.isNotEmpty) {
      // Hint: إذا وجدنا المنتج، نأخذ النتيجة الأولى (`maps.first`)،
      // ونستخدم دالة `Product.fromMap` لتحويلها من `Map` إلى كائن `Product` كامل.
      return Product.fromMap(maps.first);
    }
    
    // Hint: إذا لم نجد أي منتج مطابق للشروط، نرجع `null` للإشارة إلى عدم العثور عليه.
    return null;
  }



  // =================================================================================================
  // ✅✅✅ Hint: دالة محدثة للتحقق من وجود باركود مسبقاً ✅✅✅
  // =================================================================================================
  // الآن، هذه الدالة تتجاهل الباركودات التي تبدأ بـ "INTERNAL-" لأنها خاصة بالتطبيق
  // ولا يجب أن تتطابق مع أي باركود يدخله المستخدم.
  Future<bool> barcodeExists(String barcode, {int? currentProductId}) async {
    final db = await instance.database;
    
    // Hint: إذا كان الباركود يبدأ بـ "INTERNAL-"، نعتبره غير موجود دائماً
    // لأننا سنقوم بتوليده بشكل فريد في كل مرة.
    if (barcode.startsWith('INTERNAL-')) {
      return false;
    }

    String whereClause = 'Barcode = ?';
    List<dynamic> whereArgs = [barcode];

    if (currentProductId != null) {
      whereClause += ' AND ProductID != ?';
      whereArgs.add(currentProductId);
    }

    final result = await db.query(
      'Store_Products',
      where: whereClause,
      whereArgs: whereArgs,
    );
    return result.isNotEmpty;
  }


  

  // --- ✅ اضافة دالة جديدة لجلب أو إنشاء الزبون النقدي ---
  /// دالة لجلب الزبون النقدي الافتراضي. إذا لم يكن موجوداً، تقوم بإنشائه تلقائياً.
  /// كائن Customer الخاص بالبيع النقدي.
  Future<Customer> getOrCreateCashCustomer() async {
    final db = await instance.database;
    
    // 1. ابحث عن الزبون باستخدام الاسم الرمزي.
    final existing = await db.query(
      'TB_Customer',
      where: 'CustomerName = ?',
      whereArgs: [cashCustomerInternalName],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      // 2. إذا وجدناه، قم بإرجاعه.
      return Customer.fromMap(existing.first);
    } else {
      // 3. إذا لم نجده، قم بإنشائه الآن.
      final newCashCustomer = Customer(
        // Hint: نستخدم الاسم الرمزي كاسم، ونضيف اسماً للعرض في التقارير.
        customerName: cashCustomerInternalName, 
        address: 'بيع نقدي مباشر', // هذا سيظهر في تفاصيل التقارير
        phone: 'N/A',
        dateT: DateTime.now().toIso8601String(),
        // Hint: نجعله غير نشط (IsActive = 0) لمنعه من الظهور في قائمة الزبائن العادية.
        isActive: false, 
      );

      final id = await db.insert('TB_Customer', newCashCustomer.toMap());
      
      // 4. قم بإرجاع الكائن الجديد مع الـ ID الصحيح.
      return Customer.fromMap(newCashCustomer.toMap()..['CustomerID'] = id);
    }
  }




  /// ✅ دالة محدّثة لجلب كل الفواتير النقدية مع حساب المبلغ الصافي ومجموع المرتجعات
/// تحسب المبلغ الصافي بعد خصم المرتجعات ومجموع المرتجعات لكل فاتورة.    
  Future<List<Map<String, dynamic>>> getCashInvoices() async {
  final db = await instance.database;
  // 1. نحصل على الـ ID الخاص بالزبون النقدي أولاً.
  final cashCustomer = await getOrCreateCashCustomer();
  
  // 2. استعلام محسّن يحسب المبلغ الصافي ومجموع المرتجعات
  final result = await db.rawQuery('''
    SELECT 
      I.InvoiceID,
      I.CustomerID,
      I.InvoiceDate,
      I.TotalAmount,
      I.IsVoid,
      I.Status,
      COALESCE(SUM(CASE WHEN D.IsReturned = 0 THEN D.Debt ELSE 0 END), 0) as NetAmount,
      COALESCE(SUM(CASE WHEN D.IsReturned = 1 THEN D.Debt ELSE 0 END), 0) as ReturnedAmount,
      COALESCE(SUM(CASE WHEN D.IsReturned = 1 THEN 1 ELSE 0 END), 0) as ReturnedItemsCount
    FROM TB_Invoices I
    LEFT JOIN Debt_Customer D ON I.InvoiceID = D.InvoiceID
    WHERE I.CustomerID = ?
    GROUP BY I.InvoiceID
    ORDER BY I.InvoiceDate DESC
  ''', [cashCustomer.customerID]);
  
  return result;
  }




  /// دالة لجلب كل بنود المبيعات (المنتجات) لفاتورة معينة.
  Future<List<CustomerDebt>> getSalesForInvoice(int invoiceId) async {
    final db = await instance.database;
    final maps = await db.query(
      'Debt_Customer',
      where: 'InvoiceID = ?',
      whereArgs: [invoiceId],
    );
    if (maps.isNotEmpty) {
      return maps.map((map) => CustomerDebt.fromMap(map)).toList();
    }
    return [];
  }



  // ✅ إضافة دالة جديدة لإلغاء الفاتورة بالكامل
  /// دالة لإلغاء فاتورة نقدية بالكامل. تقوم بإرجاع كل المنتجات وإلغاء الفاتورة.
  Future<void> voidInvoice(int invoiceId) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      // 1. جلب كل بنود المبيعات في هذه الفاتورة التي لم يتم إرجاعها بعد
      final salesToReturn = await txn.query(
        'Debt_Customer',
        where: 'InvoiceID = ? AND IsReturned = 0',
        whereArgs: [invoiceId],
      );

      // 2. المرور على كل بند وإرجاعه
      for (var saleMap in salesToReturn) {
        final sale = CustomerDebt.fromMap(saleMap);
        // تحديث حالة البند إلى "مرجع"
        await txn.update('Debt_Customer', {'IsReturned': 1}, where: 'ID = ?', whereArgs: [sale.id]);
        // زيادة كمية المنتج في المخزن
        await txn.rawUpdate('UPDATE Store_Products SET Quantity = Quantity + ? WHERE ProductID = ?', [sale.qty_Customer, sale.productID]);
      }

      // 3. تحديث حالة الفاتورة الرئيسية إلى "ملغاة"
      await txn.update(
        'TB_Invoices',
        {'IsVoid': 1, 'Status': 'ملغاة'},
        where: 'InvoiceID = ?',
        whereArgs: [invoiceId],
      );
    });
  }




  // ✅  إضافة دالة لتحديث حالة الفاتورة (عند تعديلها)
  Future<void> updateInvoiceStatus(int invoiceId, String status) async {
    final db = await instance.database;
    await db.update(
      'TB_Invoices',
      {'Status': status},
      where: 'InvoiceID = ?',
      whereArgs: [invoiceId],
    );
  }


  // =================================================================================================
  // ✅ دالة جديدة لتقرير المقبوضات النقدية
  // =================================================================================================
  /// دالة لجلب كل المعاملات النقدية الواردة (مبيعات نقدية + تسديد ديون)
  /// ضمن فترة زمنية محددة.
  Future<List<Map<String, dynamic>>> getCashFlowTransactions({DateTime? startDate, DateTime? endDate}) async {

  final db = await instance.database;
  final cashCustomerId = (await getOrCreateCashCustomer()).customerID;

  // تحديد التواريخ الافتراضية إذا لم يتم توفيرها
  final now = DateTime.now();
  final finalStartDate = startDate ?? DateTime(now.year, now.month, 1); // بداية الشهر الحالي
  final finalEndDate = endDate ?? now.add(const Duration(days: 1)); // حتى نهاية اليوم الحالي

  // ✅ 1. جلب المبيعات النقدية مع المبلغ الصافي (بعد خصم المرتجعات)
  final cashSales = await db.rawQuery('''
    SELECT 
      'CASH_SALE' as type,
      I.InvoiceID as id,
      'بيع نقدي مباشر (فاتورة #' || I.InvoiceID || ')' as description,
      COALESCE(SUM(CASE WHEN D.IsReturned = 0 THEN D.Debt ELSE 0 END), 0) as amount,
      I.InvoiceDate as date
    FROM TB_Invoices I
    LEFT JOIN Debt_Customer D ON I.InvoiceID = D.InvoiceID
    WHERE I.CustomerID = ? 
      AND I.IsVoid = 0 
      AND I.InvoiceDate BETWEEN ? AND ?
    GROUP BY I.InvoiceID
  ''', [cashCustomerId, finalStartDate.toIso8601String(), finalEndDate.toIso8601String()]);

  // 2. جلب تسديدات الديون (بدون تغيير)
  final debtPayments = await db.rawQuery('''
    SELECT 
      'DEBT_PAYMENT' as type,
      ID as id,
      'تسديد من الزبون: ' || CustomerName as description,
      Payment as amount,
      DateT as date
    FROM Payment_Customer
    WHERE DateT BETWEEN ? AND ?
  ''', [finalStartDate.toIso8601String(), finalEndDate.toIso8601String()]);

  // 3. دمج القائمتين وترتيبها
  final allTransactions = [...cashSales, ...debtPayments];
  allTransactions.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String)); // ترتيب تنازلي

  return allTransactions;

  }




  // إضافة الدوال الجديدة للتعامل مع جدول سحب الأرباح

  /// دالة لحفظ سجل سحب أرباح جديد.
  /// ← Hint: تسجل السحب في جدول TB_Profit_Withdrawals وتنشئ قيد مالي تلقائياً
  Future<int> recordProfitWithdrawal(Map<String, dynamic> withdrawalData) async {
      final db = await instance.database;

    // ✅ تحويل Decimal إلى double للتخزين
      final dataToStore = Map<String, dynamic>.from(withdrawalData);
      final originalAmount = dataToStore['WithdrawalAmount']; // ← حفظ القيمة الأصلية للربط
      if (dataToStore['WithdrawalAmount'] is Decimal) {
       dataToStore['WithdrawalAmount'] =
      (dataToStore['WithdrawalAmount'] as Decimal).toDouble();
     }

    final withdrawalId = await db.insert('TB_Profit_Withdrawals', dataToStore);

    // ← Hint: الربط التلقائي مع النظام المالي
    await FinancialIntegrationHelper.recordSupplierWithdrawalTransaction(
      withdrawalId: withdrawalId,
      supplierId: withdrawalData['SupplierID'] as int,
      amount: originalAmount is Decimal ? originalAmount : Decimal.parse(originalAmount.toString()),
      withdrawalDate: withdrawalData['WithdrawalDate'] as String,
      partnerName: withdrawalData['PartnerName'] as String?,
      notes: withdrawalData['Notes'] as String?,
    );

    return withdrawalId;
  }


  /// دالة لجلب إجمالي المبالغ المسحوبة لمورد معين.
  Future<Decimal> getTotalWithdrawnForSupplier(int supplierId) async {
      final db = await instance.database;
  final result = await db.rawQuery(
    'SELECT SUM(WithdrawalAmount) as Total FROM TB_Profit_Withdrawals WHERE SupplierID = ?',
    [supplierId],
  );
  
  if (result.first['Total'] != null) {
    return Decimal.parse(result.first['Total'].toString());
  }
  return Decimal.zero;
  }


  /// دالة لجلب كل سجلات السحب لمورد معين.
  Future<List<Map<String, dynamic>>> getWithdrawalsForSupplier(int supplierId) async {
    final db = await instance.database;
    return await db.query(
      'TB_Profit_Withdrawals',
      where: 'SupplierID = ?',
      whereArgs: [supplierId],
      orderBy: 'WithdrawalDate DESC',
    );
  }


  // =================================================================================================
  // ✅✅✅ دوال جديدة لإدارة مسحوبات الشركاء بشكل دقيق ✅✅✅
  // =================================================================================================

  /// Hint: دالة لجلب إجمالي المبالغ المسحوبة لشريك معين في مورد معين.
  /// ← تستخدم لحساب كم سحب هذا الشريك من أرباحه حتى الآن.
  /// ← partnerName يمكن أن يكون null للموردين الفرديين (بدون شركاء).
  Future<Decimal> getTotalWithdrawnForPartner(int supplierId, String? partnerName) async {
    final db = await instance.database;

    // Hint: إذا كان partnerName هو null، نحسب المسحوب للمورد نفسه (بدون شركاء)
    // وإذا كان له قيمة، نحسب المسحوب للشريك المحدد
    final result = await db.rawQuery(
      partnerName == null
          ? 'SELECT SUM(WithdrawalAmount) as Total FROM TB_Profit_Withdrawals WHERE SupplierID = ? AND PartnerName IS NULL'
          : 'SELECT SUM(WithdrawalAmount) as Total FROM TB_Profit_Withdrawals WHERE SupplierID = ? AND PartnerName = ?',
      partnerName == null ? [supplierId] : [supplierId, partnerName],
    );

    if (result.first['Total'] != null) {
      return Decimal.parse(result.first['Total'].toString());
    }
    return Decimal.zero;
  }


  /// Hint: دالة لحساب الرصيد المتاح للسحب لشريك معين.
  /// ← netProfit: صافي الربح الإجمالي للمورد (بعد طرح كل المسحوبات)
  /// ← sharePercentage: نسبة الشريك من الأرباح (مثلاً 55.5)
  /// ← partnerName: اسم الشريك (أو null للمورد الفردي)
  ///
  /// الحساب: (netProfit × sharePercentage ÷ 100) - totalWithdrawnForThisPartner
  Future<Decimal> getPartnerAvailableBalance({
    required int supplierId,
    required Decimal totalProfit,
    required Decimal totalWithdrawnForSupplier,
    required Decimal sharePercentage,
    String? partnerName,
  }) async {
    // 1️⃣ حساب صافي الربح الإجمالي
    final netProfit = totalProfit - totalWithdrawnForSupplier;

    // 2️⃣ حساب نصيب هذا الشريك من صافي الربح
    final partnerTotalShare = Decimal.parse((netProfit * sharePercentage / Decimal.fromInt(100)).toString());

    // 3️⃣ حساب كم سحب هذا الشريك بالفعل
    final partnerWithdrawn = await getTotalWithdrawnForPartner(supplierId, partnerName);

    // 4️⃣ الرصيد المتاح = نصيبه - ما سحبه
    final availableBalance = Decimal.parse((partnerTotalShare - partnerWithdrawn).toString());

    return availableBalance;
  }


  /// Hint: دالة لتعديل سجل سحب أرباح موجود.
  /// ← withdrawalId: معرّف السحب المراد تعديله
  /// ← updatedData: البيانات الجديدة (يجب أن تحتوي على WithdrawalAmount و WithdrawalDate و Notes على الأقل)
  ///
  /// ⚠️ مهم: قبل استدعاء هذه الدالة، يجب التحقق من:
  ///   - أن المبلغ الجديد لا يتجاوز الرصيد المتاح للشريك
  ///   - إعادة حساب الرصيد بعد التعديل
  Future<int> updateProfitWithdrawal(int withdrawalId, Map<String, dynamic> updatedData) async {
    final db = await instance.database;

    // ✅ تحويل Decimal إلى double للتخزين
    final dataToStore = Map<String, dynamic>.from(updatedData);
    if (dataToStore['WithdrawalAmount'] is Decimal) {
      dataToStore['WithdrawalAmount'] = (dataToStore['WithdrawalAmount'] as Decimal).toDouble();
    }

    return await db.update(
      'TB_Profit_Withdrawals',
      dataToStore,
      where: 'WithdrawalID = ?',
      whereArgs: [withdrawalId],
    );
  }


  /// Hint: دالة لحذف سجل سحب أرباح.
  /// ← withdrawalId: معرّف السحب المراد حذفه
  ///
  /// ⚠️ مهم: بعد الحذف، يجب:
  ///   - إعادة حساب إجمالي المسحوب للمورد/الشريك
  ///   - تحديث الرصيد المتاح في الواجهة
  Future<int> deleteProfitWithdrawal(int withdrawalId) async {
    final db = await instance.database;

    return await db.delete(
      'TB_Profit_Withdrawals',
      where: 'WithdrawalID = ?',
      whereArgs: [withdrawalId],
    );
  }



  // =================================================================================================
  // ✅  إضافة الدوال الجديدة الخاصة بالمصاريف
  // =================================================================================================

  /// دالة لتسجيل مصروف جديد.
  Future<int> recordExpense(Map<String, dynamic> expenseData) async {
    final db = await instance.database;
    int? expenseId;

    expenseId = await db.insert('TB_Expenses', expenseData);

    // ← Hint: تسجيل القيد المالي التلقائي
    if (expenseId != null) {
      await FinancialIntegrationHelper.recordExpenseTransaction(
        expenseId: expenseId,
        amount: Decimal.parse(expenseData['Amount'].toString()),
        expenseDate: expenseData['ExpenseDate'],
        description: expenseData['Description'],
        category: expenseData['Category'],
      );
    }

    return expenseId;
  }

  /// دالة لجلب كل المصاريف، مرتبة من الأحدث للأقدم.
  Future<List<Map<String, dynamic>>> getExpenses() async {
    final db = await instance.database;
    return await db.query('TB_Expenses', orderBy: 'ExpenseDate DESC');
  }

  /// دالة لحساب إجمالي المصاريف.
  Future<Decimal> getTotalExpenses() async {
      final db = await instance.database;
  final result = await db.rawQuery(
    'SELECT SUM(Amount) as Total FROM TB_Expenses'
  );
  
  if (result.first['Total'] != null) {
    return Decimal.parse(result.first['Total'].toString());
  }
  return Decimal.zero;
  }



  // =================================================================================================
  // ✅  إضافة دالة جديدة لحساب إجمالي مسحوبات أرباح الموردين
  // =================================================================================================
  
  /// دالة لحساب إجمالي كل المبالغ المسحوبة من أرباح الموردين والشركاء.
  Future<Decimal> getTotalAllProfitWithdrawals() async {
      final db = await instance.database;
  final result = await db.rawQuery(
    'SELECT SUM(WithdrawalAmount) as Total FROM TB_Profit_Withdrawals'
  );
  
  if (result.first['Total'] != null) {
    return Decimal.parse(result.first['Total'].toString());
  }
  return Decimal.zero;
  }



  // =================================================================================================
  // ✅✅✅ التعديل السادس: إضافة دوال إدارة فئات المصاريف ✅✅✅
  // =================================================================================================
  
  ///  دالة لجلب كل فئات المصاريف من قاعدة البيانات، مرتبة أبجدياً.
  Future<List<Map<String, dynamic>>> getExpenseCategories() async {
    final db = await instance.database;
    return await db.query('TB_Expense_Categories', orderBy: 'CategoryName ASC');
  }

  ///  دالة لإضافة فئة مصروف جديدة.
  Future<int> addExpenseCategory(String name) async {
    final db = await instance.database;
    return await db.insert(
      'TB_Expense_Categories',
      {'CategoryName': name},
      conflictAlgorithm: ConflictAlgorithm.fail, // سيسبب خطأ إذا كان الاسم مكرراً
    );
  }


  /// دالة لتعديل اسم فئة موجودة.
  Future<int> updateExpenseCategory(int id, String newName) async {
    final db = await instance.database;
    return await db.update(
      'TB_Expense_Categories',
      {'CategoryName': newName},
      where: 'CategoryID = ?',
      whereArgs: [id],
    );
  }


  ///  دالة لحذف فئة.
  /// ملاحظة: حالياً لا نمنع حذف الفئة حتى لو كانت مستخدمة. يمكن إضافة هذا التحقق لاحقاً إذا لزم الأمر.
  Future<int> deleteExpenseCategory(int id) async {
    final db = await instance.database;
    return await db.delete(
      'TB_Expense_Categories',
      where: 'CategoryID = ?',
      whereArgs: [id],
    );
  }




  // =================================================================================================
  // ✅✅✅ دوال جديدة للوحة القيادة (Dashboard) ✅✅✅
  // =================================================================================================

  /// دالة لجلب المنتجات الأكثر مبيعاً بناءً على الكمية المباعة.
  /// تقبل `limit` لتحديد عدد المنتجات المراد جلبها.
  Future<List<Product>> getTopSellingProducts({int limit = 5}) async {
    final db = await instance.database;
    // الشرح:
    // 1. SUM(D.Qty_Customer) as total_quantity: نحسب مجموع الكميات المباعة لكل منتج ونسميه total_quantity.
    // 2. JOIN: نربط جدول المبيعات (Debt_Customer) بجدول المنتجات (Store_Products).
    // 3. WHERE D.IsReturned = 0: نستبعد المبيعات التي تم إرجاعها.
    // 4. GROUP BY P.ProductID: نجمع النتائج لكل منتج على حدة.
    // 5. ORDER BY total_quantity DESC: نرتب المنتجات تنازلياً حسب الكمية المباعة.
    // 6. LIMIT ?: نأخذ فقط العدد المحدد من النتائج.
    final result = await db.rawQuery('''
      SELECT P.*, SUM(D.Qty_Customer) as total_quantity
      FROM Debt_Customer D
      JOIN Store_Products P ON D.ProductID = P.ProductID
      WHERE D.IsReturned = 0
      GROUP BY P.ProductID
      ORDER BY total_quantity DESC
      LIMIT ?
    ''', [limit]);

    return result.map((map) => Product.fromMap(map)).toList();
  }


  /// دالة لجلب العملاء الأكثر شراءً بناءً على إجمالي قيمة المشتريات.
  /// تقبل `limit` لتحديد عدد العملاء المراد جلبهم.
  Future<List<Customer>> getTopCustomers({int limit = 5}) async {
    final db = await instance.database;
    // الشرح:
    // 1. TB_Customer C: نبدأ من جدول العملاء.
    // 2. LEFT JOIN Debt_Customer D: نربطه بجدول المبيعات. استخدام LEFT JOIN يضمن ظهور كل العملاء حتى لو لم يشتروا شيئاً.
    // 3. SUM(D.Debt) as total_purchases: نحسب مجموع قيمة المشتريات لكل عميل.
    // 4. WHERE C.IsActive = 1: نختار العملاء النشطين فقط.
    // 5. GROUP BY C.CustomerID: نجمع النتائج لكل عميل.
    // 6. ORDER BY total_purchases DESC: نرتبهم تنازلياً.
    // 7. LIMIT ?: نأخذ العدد المحدد.
    final result = await db.rawQuery('''
      SELECT C.*, SUM(D.Debt) as total_purchases
      FROM TB_Customer C
      LEFT JOIN Debt_Customer D ON C.CustomerID = D.CustomerID
      WHERE C.IsActive = 1 AND D.IsReturned = 0
      GROUP BY C.CustomerID
      ORDER BY total_purchases DESC
      LIMIT ?
    ''', [limit]);

    return result.map((map) => Customer.fromMap(map)).toList();
  }




  // =================================================================================================
  // ✅✅✅ دوال إضافية للوحة القيادة (Dashboard) ✅✅✅
  // =================================================================================================

  /// ✅ Hint: حساب إجمالي المبيعات (مجموع كل الديون من المبيعات غير المرجعة)
  Future<Decimal> getTotalSales() async {
      final db = await instance.database;
  final result = await db.rawQuery(
    'SELECT SUM(Debt) as Total FROM Debt_Customer WHERE IsReturned = 0'
  );
  
  if (result.first['Total'] != null) {
    return Decimal.parse(result.first['Total'].toString());
  }
  return Decimal.zero;
  }

  /// ✅ Hint: حساب عدد العملاء النشطين (الذين لديهم معاملات)
  Future<int> getActiveCustomersCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT COUNT(DISTINCT CustomerID) as count 
      FROM Debt_Customer 
      WHERE IsReturned = 0
    ''');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// ✅ Hint: حساب عدد المنتجات النشطة في المخزن
  Future<int> getActiveProductsCount() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM Store_Products WHERE IsActive = 1'
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// ✅ Hint: جلب المنتجات منخفضة المخزون
  /// threshold: الحد الأدنى للكمية (افتراضياً 5)
  Future<List<Product>> getLowStockProducts({int threshold = 5}) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT P.*, S.SupplierName 
      FROM Store_Products P 
      LEFT JOIN TB_Suppliers S ON P.SupplierID = S.SupplierID 
      WHERE P.IsActive = 1 AND P.Quantity <= ?
      ORDER BY P.Quantity ASC
    ''', [threshold]);
    
    return result.map((map) => Product.fromMap(map)).toList();
  }

  /// ✅ Hint: جلب العملاء المتأخرين عن السداد
  /// daysThreshold: عدد الأيام بين آخر شراء وآخر تسديد (افتراضياً 30 يوم)
  /// يقوم بمقارنة تاريخ آخر شراء مع تاريخ آخر تسديد
  Future<List<Map<String, dynamic>>> getOverdueCustomers({int daysThreshold = 30}) async {
    final db = await instance.database;

    final result = await db.rawQuery('''
      SELECT
        C.CustomerID,
        C.CustomerName,
        C.Remaining,
        C.Phone,
        MAX(D.DateT) as LastPurchaseDate,
        MAX(P.DateT) as LastPaymentDate,
        julianday('now') - julianday(MAX(D.DateT)) as DaysSinceLastPurchase,
        CASE
          WHEN MAX(P.DateT) IS NULL THEN julianday('now') - julianday(MAX(D.DateT))
          ELSE julianday(MAX(D.DateT)) - julianday(MAX(P.DateT))
        END as DaysSinceLastPayment
      FROM TB_Customer C
      LEFT JOIN Debt_Customer D ON C.CustomerID = D.CustomerID
      LEFT JOIN Payment_Customer P ON C.CustomerID = P.CustomerID
      WHERE C.Remaining > 0
        AND C.IsActive = 1
        AND C.CustomerName != ?
      GROUP BY C.CustomerID
      HAVING (
        -- إما لم يدفع أبداً ومضى على آخر شراء أكثر من الحد المسموح
        (MAX(P.DateT) IS NULL AND julianday('now') - julianday(MAX(D.DateT)) >= ?)
        OR
        -- أو آخر شراء أحدث من آخر دفعة بأكثر من الحد المسموح
        (MAX(P.DateT) IS NOT NULL AND julianday(MAX(D.DateT)) - julianday(MAX(P.DateT)) >= ?)
      )
      ORDER BY C.Remaining DESC
    ''', [cashCustomerInternalName, daysThreshold, daysThreshold]);

    return result;
  }

  /// ✅ Hint: حساب إجمالي الديون المستحقة على جميع العملاء
  Future<Decimal> getTotalDebts() async {
      final db = await instance.database;
  final result = await db.rawQuery('''
    SELECT SUM(Remaining) as Total 
    FROM TB_Customer 
    WHERE Remaining > 0 AND IsActive = 1 AND CustomerName != ?
  ''', [cashCustomerInternalName]);
  
  if (result.first['Total'] != null) {
    return Decimal.parse(result.first['Total'].toString());
  }
  return Decimal.zero;
  }

  /// ✅ Hint: حساب إجمالي المدفوعات المحصلة
  Future<Decimal> getTotalPaymentsCollected() async {
      final db = await instance.database;
  final result = await db.rawQuery(
    'SELECT SUM(Payment) as Total FROM Payment_Customer'
  );
  
  if (result.first['Total'] != null) {
    return Decimal.parse(result.first['Total'].toString());
  }
  return Decimal.zero;
  }

  /// ✅ Hint: حساب نسبة التحصيل (المدفوعات / المبيعات × 100)
  Future<Decimal> getCollectionRate() async {
      final totalSales = await getTotalSales();

      if (totalSales == Decimal.zero) return Decimal.fromInt(100);

      final totalPayments = await getTotalPaymentsCollected();

      final ratio = totalPayments / totalSales;
      final percentage = ratio.toDecimal(scaleOnInfinitePrecision: 10) * Decimal.fromInt(100);
  
       return percentage;

  }

  /// ✅ Hint: جلب المبيعات الشهرية لآخر 6 أشهر (للرسم البياني)
  Future<List<Map<String, dynamic>>> getMonthlySales({int months = 6}) async {
    final db = await instance.database;
    
    // ✅ Hint: حساب تاريخ البداية (قبل X شهر)
    final startDate = DateTime.now().subtract(Duration(days: months * 30)).toIso8601String();
    
    final result = await db.rawQuery('''
      SELECT 
        strftime('%Y-%m', DateT) as Month,
        SUM(Debt) as TotalSales,
        COUNT(*) as TransactionCount
      FROM Debt_Customer
      WHERE IsReturned = 0 AND DateT >= ?
      GROUP BY strftime('%Y-%m', DateT)
      ORDER BY Month ASC
    ''', [startDate]);
    
    return result;
  }

  /// ✅ Hint: جلب أكثر 5 موردين ربحاً (للرسم الدائري)
  Future<List<Map<String, dynamic>>> getTopSuppliersByProfit({int limit = 5}) async {
    final db = await instance.database;
    
    final result = await db.rawQuery('''
      SELECT 
        S.SupplierID,
        S.SupplierName,
        SUM(D.ProfitAmount) as TotalProfit,
        COUNT(D.ID) as SalesCount
      FROM Debt_Customer D
      JOIN Store_Products P ON D.ProductID = P.ProductID
      JOIN TB_Suppliers S ON P.SupplierID = S.SupplierID
      WHERE D.IsReturned = 0
      GROUP BY S.SupplierID
      ORDER BY TotalProfit DESC
      LIMIT ?
    ''', [limit]);
    
    // ✅ تحويل TotalProfit إلى Decimal
    return result.map((row) {
      final map = Map<String, dynamic>.from(row);
      if (map['TotalProfit'] != null) {
        map['TotalProfit'] = Decimal.parse(map['TotalProfit'].toString());
       }
      return map;
     }).toList();

  }


  // =================================================================================================
// ✅✅✅ دوال تقرير مبيعات الزبائن ✅✅✅
// =================================================================================================

/// دالة شاملة لجلب مبيعات الزبائن مع فلاتر متقدمة
/// 
/// المعاملات:
/// - [customerId]: معرف الزبون (null = كل الزبائن)
/// - [productId]: معرف المنتج (null = كل المنتجات)
/// - [supplierId]: معرف المورد (null = كل الموردين)
/// - [startDate]: تاريخ البداية (null = بلا حد)
/// - [endDate]: تاريخ النهاية (null = بلا حد)
/// - [excludeReturned]: استبعاد المرتجعات (افتراضي true)
Future<List<Map<String, dynamic>>> getCustomerSalesReport({
  int? customerId,
  int? productId,
  int? supplierId,
  DateTime? startDate,
  DateTime? endDate,
  bool excludeReturned = true,
}) async {
  final db = await instance.database;
  
  // بناء الاستعلام الأساسي
  String sql = '''
    SELECT 
      D.ID as saleId,
      D.DateT as saleDate,
      D.Qty_Customer as quantity,
      D.Debt as amount,
      D.ProfitAmount as profit,
      D.CostPriceAtTimeOfSale as costPrice,
      D.IsReturned as isReturned,
      C.CustomerID as customerId,
      C.CustomerName as customerName,
      C.Phone as customerPhone,
      P.ProductID as productId,
      P.ProductName as productName,
      P.Barcode as productBarcode,
      S.SupplierID as supplierId,
      S.SupplierName as supplierName
    FROM Debt_Customer D
    INNER JOIN TB_Customer C ON D.CustomerID = C.CustomerID
    INNER JOIN Store_Products P ON D.ProductID = P.ProductID
    INNER JOIN TB_Suppliers S ON P.SupplierID = S.SupplierID
    WHERE 1=1
  ''';
  
  // بناء الشروط
  final List<dynamic> args = [];
  
  // فلتر الزبون
  if (customerId != null) {
    sql += ' AND D.CustomerID = ?';
    args.add(customerId);
  }
  
  // فلتر المنتج
  if (productId != null) {
    sql += ' AND D.ProductID = ?';
    args.add(productId);
  }
  
  // فلتر المورد
  if (supplierId != null) {
    sql += ' AND P.SupplierID = ?';
    args.add(supplierId);
  }
  
  // فلتر التاريخ - من
  if (startDate != null) {
    sql += ' AND D.DateT >= ?';
    args.add(startDate.toIso8601String());
  }
  
  // فلتر التاريخ - إلى
  if (endDate != null) {
    sql += ' AND D.DateT <= ?';
    args.add(endDate.toIso8601String());
  }
  
  // استبعاد المرتجعات
  if (excludeReturned) {
    sql += ' AND D.IsReturned = 0';
  }
  
  // إخفاء الزبون النقدي الداخلي
  sql += ' AND C.CustomerName != ?';
  args.add(cashCustomerInternalName);
  
  // الترتيب
  sql += ' ORDER BY D.DateT DESC';
  
  return await db.rawQuery(sql, args);
}

/// حساب إحصائيات تقرير المبيعات
/// 
/// المعاملات: نفس معاملات getCustomerSalesReport
Future<Map<String, dynamic>> getCustomerSalesStatistics({
  int? customerId,
  int? productId,
  int? supplierId,
  DateTime? startDate,
  DateTime? endDate,
  bool excludeReturned = true,
}) async {
  final db = await instance.database;
  
  // بناء الاستعلام
  String sql = '''
    SELECT 
      COUNT(D.ID) as totalTransactions,
      SUM(D.Qty_Customer) as totalQuantity,
      SUM(D.Debt) as totalSales,
      SUM(D.ProfitAmount) as totalProfit,
      AVG(D.Debt) as averageTransaction,
      MIN(D.Debt) as minTransaction,
      MAX(D.Debt) as maxTransaction
    FROM Debt_Customer D
    INNER JOIN TB_Customer C ON D.CustomerID = C.CustomerID
    INNER JOIN Store_Products P ON D.ProductID = P.ProductID
    WHERE 1=1
  ''';
  
  final List<dynamic> args = [];
  
  // تطبيق نفس الفلاتر
  if (customerId != null) {
    sql += ' AND D.CustomerID = ?';
    args.add(customerId);
  }
  
  if (productId != null) {
    sql += ' AND D.ProductID = ?';
    args.add(productId);
  }
  
  if (supplierId != null) {
    sql += ' AND P.SupplierID = ?';
    args.add(supplierId);
  }
  
  if (startDate != null) {
    sql += ' AND D.DateT >= ?';
    args.add(startDate.toIso8601String());
  }
  
  if (endDate != null) {
    sql += ' AND D.DateT <= ?';
    args.add(endDate.toIso8601String());
  }
  
  if (excludeReturned) {
    sql += ' AND D.IsReturned = 0';
  }
  
  sql += ' AND C.CustomerName != ?';
  args.add(cashCustomerInternalName);
  
  final result = await db.rawQuery(sql, args);
  
  if (result.isEmpty) {
    return {
      'totalTransactions': 0,
      'totalQuantity': 0,
      'totalSales': Decimal.zero,
      'totalProfit': Decimal.zero,
      'averageTransaction': Decimal.zero,
      'minTransaction': Decimal.zero,
      'maxTransaction': Decimal.zero,
    };
  }
  
  return {
    'totalTransactions': result.first['totalTransactions'] ?? 0,
    'totalQuantity': result.first['totalQuantity'] ?? 0,
    // 'totalSales': (result.first['totalSales'] as num?)?.toDouble() ?? 0.0,
    'totalSales': Decimal.parse((result.first['totalSales'] as num?)?.toString() ?? '0'),
    // 'totalProfit': (result.first['totalProfit'] as num?)?.toDouble() ?? 0.0,
    'totalProfit': Decimal.parse((result.first['totalProfit'] as num?)?.toString() ?? '0'),
    'averageTransaction': (result.first['averageTransaction'] as num?)?.toDouble() ?? 0.0,
    'minTransaction': (result.first['minTransaction'] as num?)?.toDouble() ?? 0.0,
    'maxTransaction': (result.first['maxTransaction'] as num?)?.toDouble() ?? 0.0,
  };
}

/// جلب أكثر المنتجات مبيعاً في الفترة المحددة
Future<List<Map<String, dynamic>>> getTopSellingProductsInPeriod({
  DateTime? startDate,
  DateTime? endDate,
  int limit = 5,
}) async {
  final db = await instance.database;
  
  String sql = '''
    SELECT 
      P.ProductID,
      P.ProductName,
      SUM(D.Qty_Customer) as totalQuantity,
      SUM(D.Debt) as totalSales,
      SUM(D.ProfitAmount) as totalProfit
    FROM Debt_Customer D
    INNER JOIN Store_Products P ON D.ProductID = P.ProductID
    WHERE D.IsReturned = 0
  ''';
  
  final List<dynamic> args = [];
  
  if (startDate != null) {
    sql += ' AND D.DateT >= ?';
    args.add(startDate.toIso8601String());
  }
  
  if (endDate != null) {
    sql += ' AND D.DateT <= ?';
    args.add(endDate.toIso8601String());
  }
  
  sql += '''
    GROUP BY P.ProductID, P.ProductName
    ORDER BY totalQuantity DESC
    LIMIT ?
  ''';
  args.add(limit);
  
  return await db.rawQuery(sql, args);
}

/// جلب أكثر الزبائن شراءً في الفترة المحددة
Future<List<Map<String, dynamic>>> getTopCustomersInPeriod({
  DateTime? startDate,
  DateTime? endDate,
  int limit = 5,
}) async {
  final db = await instance.database;
  
  String sql = '''
    SELECT 
      C.CustomerID,
      C.CustomerName,
      COUNT(D.ID) as transactionCount,
      SUM(D.Debt) as totalPurchases
    FROM Debt_Customer D
    INNER JOIN TB_Customer C ON D.CustomerID = C.CustomerID
    WHERE D.IsReturned = 0
    AND C.CustomerName != ?
  ''';
  
  final List<dynamic> args = [cashCustomerInternalName];
  
  if (startDate != null) {
    sql += ' AND D.DateT >= ?';
    args.add(startDate.toIso8601String());
  }
  
  if (endDate != null) {
    sql += ' AND D.DateT <= ?';
    args.add(endDate.toIso8601String());
  }
  
  sql += '''
    GROUP BY C.CustomerID, C.CustomerName
    ORDER BY totalPurchases DESC
    LIMIT ?
  ''';
  args.add(limit);
  
  return await db.rawQuery(sql, args);
}

// ============================================================================
// ← Hint: دوال التعامل مع المكافآت (Employee Bonuses)
// ============================================================================

/// إضافة مكافأة جديدة لموظف
///
/// ← Hint: تستخدم لتسجيل مكافأة/حافز للموظف
/// ← Hint: يجب التأكد من وجود الموظف قبل الإضافة
Future<int> insertBonus(Map<String, dynamic> bonus) async {
  final db = await instance.database;
  return await db.insert('TB_Employee_Bonuses', bonus);
}

/// جلب جميع المكافآت في فترة زمنية محددة
///
/// ← Hint: تستخدم في التقارير المالية لحساب إجمالي المكافآت في فترة معينة
Future<List<Map<String, dynamic>>> getBonusesInPeriod({
  DateTime? startDate,
  DateTime? endDate,
}) async {
  final db = await instance.database;

  String sql = '''
    SELECT
      B.*,
      E.FullName as EmployeeName
    FROM TB_Employee_Bonuses B
    INNER JOIN TB_Employees E ON B.EmployeeID = E.EmployeeID
    WHERE 1=1
  ''';

  final List<dynamic> args = [];

  if (startDate != null) {
    sql += ' AND B.BonusDate >= ?';
    args.add(startDate.toIso8601String());
  }

  if (endDate != null) {
    sql += ' AND B.BonusDate <= ?';
    args.add(endDate.toIso8601String());
  }

  sql += ' ORDER BY B.BonusDate DESC';

  return await db.rawQuery(sql, args);
}

/// حساب إجمالي المكافآت في فترة زمنية
///
/// ← Hint: تستخدم في التقارير لعرض إجمالي المكافآت المصروفة
Future<double> getTotalBonusesInPeriod({
  DateTime? startDate,
  DateTime? endDate,
}) async {
  final db = await instance.database;

  String sql = 'SELECT SUM(BonusAmount) as total FROM TB_Employee_Bonuses WHERE 1=1';
  final List<dynamic> args = [];

  if (startDate != null) {
    sql += ' AND BonusDate >= ?';
    args.add(startDate.toIso8601String());
  }

  if (endDate != null) {
    sql += ' AND BonusDate <= ?';
    args.add(endDate.toIso8601String());
  }

  final result = await db.rawQuery(sql, args);
  return result.first['total'] != null ? (result.first['total'] as num).toDouble() : 0.0;
}

/// جلب جميع المكافآت لموظف محدد
///
/// ← Hint: تستخدم في صفحة تفاصيل الموظف لعرض سجل المكافآت
Future<List<models.EmployeeBonus>> getBonusesForEmployee(int employeeID) async {
  final db = await instance.database;
  final List<Map<String, dynamic>> maps = await db.query(
    'TB_Employee_Bonuses',
    where: 'EmployeeID = ?',
    whereArgs: [employeeID],
    orderBy: 'BonusDate DESC',
  );
  return maps.map((map) => models.EmployeeBonus.fromMap(map)).toList();
}

/// إضافة مكافأة جديدة (باستخدام EmployeeBonus object)
///
/// ← Hint: تستخدم لتسجيل مكافأة/حافز للموظف
/// ← Hint: تسجل قيد مالي تلقائي عبر FinancialIntegrationHelper
Future<void> recordNewBonus(models.EmployeeBonus bonus) async {
  final db = await instance.database;
  final bonusId = await db.insert('TB_Employee_Bonuses', bonus.toMap());

  // ← Hint: تسجيل القيد المالي التلقائي
  await FinancialIntegrationHelper.recordBonusTransaction(
    bonusId: bonusId,
    employeeId: bonus.employeeID,
    amount: bonus.bonusAmount,
    bonusDate: bonus.bonusDate,
    bonusReason: bonus.bonusReason,
  );
}

/// تعديل مكافأة موجودة
///
/// ← Hint: تستخدم لتعديل بيانات مكافأة محددة
Future<void> updateBonus(models.EmployeeBonus bonus) async {
  final db = await instance.database;
  await db.update(
    'TB_Employee_Bonuses',
    bonus.toMap(),
    where: 'BonusID = ?',
    whereArgs: [bonus.bonusID],
  );
}

/// حذف مكافأة
///
/// ← Hint: تستخدم لحذف مكافأة محددة من السجل
Future<void> deleteBonus(int bonusID) async {
  final db = await instance.database;
  await db.delete(
    'TB_Employee_Bonuses',
    where: 'BonusID = ?',
    whereArgs: [bonusID],
  );
}

// ============================================================================
// ✅ دوال الوحدات (Product Units) - النسخة المبسطة
// ============================================================================

/// جلب جميع الوحدات النشطة
/// ← Hint: تستخدم في Dropdown اختيار الوحدة عند إضافة/تعديل منتج
/// ← Hint: ترتيب أبجدي حسب الاسم العربي
Future<List<ProductUnit>> getProductUnits({bool activeOnly = true}) async {
  final db = await instance.database;
  final List<Map<String, dynamic>> maps = await db.query(
    'TB_ProductUnit',
    where: activeOnly ? 'IsActive = ?' : null,
    whereArgs: activeOnly ? [1] : null,
    orderBy: 'UnitNameAr ASC',  // ← Hint: ترتيب أبجدي عربي
  );
  return maps.map((map) => ProductUnit.fromMap(map)).toList();
}

/// إضافة وحدة جديدة
/// ← Hint: تستخدم في صفحة إدارة الوحدات لإضافة وحدات مخصصة
Future<int> addProductUnit(ProductUnit unit) async {
  final db = await instance.database;
  return await db.insert('TB_ProductUnit', unit.toMap());
}

/// تعديل وحدة موجودة
/// ← Hint: تستخدم لتعديل اسم الوحدة (عربي أو إنجليزي)
Future<int> editProductUnit(ProductUnit unit) async {
  final db = await instance.database;
  return await db.update(
    'TB_ProductUnit',
    unit.toMap(),
    where: 'UnitID = ?',
    whereArgs: [unit.unitID],
  );
}

/// حذف (تعطيل) وحدة
/// ← Hint: في الواقع نقوم بتعطيل الوحدة (IsActive = 0) بدلاً من حذفها نهائياً
Future<int> deleteProductUnit(int unitID) async {
  final db = await instance.database;
  return await db.update(
    'TB_ProductUnit',
    {'IsActive': 0},
    where: 'UnitID = ?',
    whereArgs: [unitID],
  );
}

/// التحقق من إمكانية حذف وحدة
/// ← Hint: نتحقق من عدم وجود منتجات نشطة تستخدم هذه الوحدة
Future<bool> canDeleteUnit(int unitID) async {
  final db = await instance.database;
  final result = await db.rawQuery(
    'SELECT COUNT(*) as count FROM Store_Products WHERE UnitID = ? AND IsActive = 1',
    [unitID],
  );
  return (result.first['count'] as int) == 0;
}

/// 🆕 حساب عدد المنتجات المرتبطة بوحدة معينة
/// ← Hint: تستخدم لعرض رسالة تحذير قبل التعطيل/الحذف
/// ← Hint: تعد المنتجات النشطة فقط (IsActive = 1)
///
/// العودة:
/// - عدد المنتجات المرتبطة
Future<int> countProductsByUnit(int unitID) async {
  final db = await instance.database;
  final result = await db.rawQuery(
    'SELECT COUNT(*) as count FROM Store_Products WHERE UnitID = ? AND IsActive = 1',
    [unitID],
  );
  return result.first['count'] as int;
}

/// 🆕 إعادة تفعيل وحدة معطلة
/// ← Hint: تستخدم لاستعادة الوحدات المعطلة (IsActive = 0 → 1)
///
/// المعاملات:
/// - [unitID] معرّف الوحدة المراد تفعيلها
///
/// العودة:
/// - عدد الصفوف المتأثرة (1 في حالة النجاح)
Future<int> reactivateUnit(int unitID) async {
  final db = await instance.database;
  return await db.update(
    'TB_ProductUnit',
    {'IsActive': 1},
    where: 'UnitID = ?',
    whereArgs: [unitID],
  );
}


// ============================================================================
// ✅ دوال التصنيفات (Product Categories) - النسخة المبسطة
// ============================================================================

/// جلب جميع التصنيفات النشطة
/// ← Hint: تستخدم في Dropdown اختيار التصنيف عند إضافة/تعديل منتج
/// ← Hint: ترتيب أبجدي حسب الاسم العربي
Future<List<ProductCategory>> getProductCategories({bool activeOnly = true}) async {
  final db = await instance.database;
  final List<Map<String, dynamic>> maps = await db.query(
    'TB_ProductCategory',
    where: activeOnly ? 'IsActive = ?' : null,
    whereArgs: activeOnly ? [1] : null,
    orderBy: 'CategoryNameAr ASC',  // ← Hint: ترتيب أبجدي عربي
  );
  return maps.map((map) => ProductCategory.fromMap(map)).toList();
}

/// إضافة تصنيف جديد
/// ← Hint: تستخدم في صفحة إدارة التصنيفات لإضافة تصنيفات مخصصة
Future<int> addProductCategory(ProductCategory category) async {
  final db = await instance.database;
  return await db.insert('TB_ProductCategory', category.toMap());
}

/// تعديل تصنيف موجود
/// ← Hint: تستخدم لتعديل اسم التصنيف (عربي أو إنجليزي)
Future<int> editProductCategory(ProductCategory category) async {
  final db = await instance.database;
  return await db.update(
    'TB_ProductCategory',
    category.toMap(),
    where: 'CategoryID = ?',
    whereArgs: [category.categoryID],
  );
}

/// حذف (تعطيل) تصنيف
/// ← Hint: في الواقع نقوم بتعطيل التصنيف (IsActive = 0) بدلاً من حذفه نهائياً
/// ← Hint: هذا يحافظ على سلامة البيانات المرتبطة
Future<int> deleteProductCategory(int categoryID) async {
  final db = await instance.database;
  return await db.update(
    'TB_ProductCategory',
    {'IsActive': 0},
    where: 'CategoryID = ?',
    whereArgs: [categoryID],
  );
}

/// التحقق من إمكانية حذف تصنيف
/// ← Hint: نتحقق من عدم وجود منتجات نشطة مرتبطة بهذا التصنيف
/// ← Hint: إذا كانت هناك منتجات، يجب تغيير تصنيفها أولاً
Future<bool> canDeleteCategory(int categoryID) async {
  final db = await instance.database;
  final result = await db.rawQuery(
    'SELECT COUNT(*) as count FROM Store_Products WHERE CategoryID = ? AND IsActive = 1',
    [categoryID],
  );
  return (result.first['count'] as int) == 0;
}

/// 🆕 حساب عدد المنتجات المرتبطة بتصنيف معين
/// ← Hint: تستخدم لعرض رسالة تحذير قبل التعطيل/الحذف
/// ← Hint: تعد المنتجات النشطة فقط (IsActive = 1)
///
/// العودة:
/// - عدد المنتجات المرتبطة
Future<int> countProductsByCategory(int categoryID) async {
  final db = await instance.database;
  final result = await db.rawQuery(
    'SELECT COUNT(*) as count FROM Store_Products WHERE CategoryID = ? AND IsActive = 1',
    [categoryID],
  );
  return result.first['count'] as int;
}

/// 🆕 إعادة تفعيل تصنيف معطل
/// ← Hint: تستخدم لاستعادة التصنيفات المعطلة (IsActive = 0 → 1)
///
/// المعاملات:
/// - [categoryID] معرّف التصنيف المراد تفعيله
///
/// العودة:
/// - عدد الصفوف المتأثرة (1 في حالة النجاح)
Future<int> reactivateCategory(int categoryID) async {
  final db = await instance.database;
  return await db.update(
    'TB_ProductCategory',
    {'IsActive': 1},
    where: 'CategoryID = ?',
    whereArgs: [categoryID],
  );
}

/// جلب منتجات حسب التصنيف
/// ← Hint: تستخدم في صفحة اختيار المنتجات للفلترة حسب التصنيف
Future<List<Product>> getProductsByCategory(int categoryID) async {
  final db = await instance.database;
  final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT
      p.*,
      s.SupplierName,
      u.UnitNameAr as UnitName,
      c.CategoryNameAr as CategoryName
    FROM Store_Products p
    LEFT JOIN TB_Suppliers s ON p.SupplierID = s.SupplierID
    LEFT JOIN TB_ProductUnit u ON p.UnitID = u.UnitID
    LEFT JOIN TB_ProductCategory c ON p.CategoryID = c.CategoryID
    WHERE p.CategoryID = ? AND p.IsActive = 1
    ORDER BY p.ProductName ASC
  ''', [categoryID]);

  return maps.map((map) => Product.fromMap(map)).toList();
}

// ============================================================================
// 🆕 دالة مساعدة جديدة: إضافة التصنيفات والوحدات الافتراضية
// ============================================================================
// ← Hint: يتم استدعاؤها مرة واحدة فقط عند إنشاء قاعدة البيانات لأول مرة
// ← Hint: تضيف 2 تصنيف و 2 وحدة كأمثلة بسيطة
Future<void> _insertDefaultCategoriesAndUnits(Database db) async {
  // ============================================================================
  // 📦 التصنيفات الافتراضية (2 فقط)
  // ============================================================================
  // ← Hint: تصنيفان أساسيان يمكن للمستخدم البدء بهما
  // ← Hint: المستخدم يستطيع إضافة المزيد من manage_categories_units_screen
  final defaultCategories = [
    {
      'CategoryNameAr': 'عام',
      'CategoryNameEn': 'General',
      'IsActive': 1,
    },
    {
      'CategoryNameAr': 'أخرى',
      'CategoryNameEn': 'Other',
      'IsActive': 1,
    },
  ];

  // ← Hint: إدراج التصنيفات مع تجاهل التكرار (إن وجد)
  for (var category in defaultCategories) {
    await db.insert(
      'TB_ProductCategory',
      category,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
  debugPrint('✅ تم إضافة ${defaultCategories.length} تصنيف افتراضي');

  // ============================================================================
  // 📏 الوحدات الافتراضية (2 فقط)
  // ============================================================================
  // ← Hint: وحدتان أساسيتان يمكن للمستخدم البدء بهما
  final defaultUnits = [
    {
      'UnitNameAr': 'قطعة',
      'UnitNameEn': 'Piece',
      'IsActive': 1,
    },
    {
      'UnitNameAr': 'كيلو',
      'UnitNameEn': 'Kilogram',
      'IsActive': 1,
    },
  ];

  // ← Hint: إدراج الوحدات مع تجاهل التكرار (إن وجد)
  for (var unit in defaultUnits) {
    await db.insert(
      'TB_ProductUnit',
      unit,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
  debugPrint('✅ تم إضافة ${defaultUnits.length} وحدة افتراضية');
}

/// ============================================================================
/// تنظيف وإصلاح بيانات التصنيفات والوحدات
/// ============================================================================
/// ← Hint: تُستدعى مرة واحدة لإصلاح البيانات القديمة
Future<void> cleanupCategoriesAndUnits() async {
  final db = await database;

  try {
    // ← Hint: حذف التصنيفات التي لديها أسماء null
    await db.delete(
      'TB_ProductCategory',
      where: 'CategoryNameAr IS NULL OR CategoryNameEn IS NULL',
    );

    // ← Hint: حذف الوحدات التي لديها أسماء null
    await db.delete(
      'TB_ProductUnit',
      where: 'UnitNameAr IS NULL OR UnitNameEn IS NULL',
    );

    // ← Hint: التحقق من وجود البيانات الافتراضية
    final categoriesCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM TB_ProductCategory WHERE IsActive = 1'),
    ) ?? 0;

    final unitsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM TB_ProductUnit WHERE IsActive = 1'),
    ) ?? 0;

    // ← Hint: إضافة البيانات الافتراضية إذا لم تكن موجودة
    if (categoriesCount == 0) {
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
    }

    if (unitsCount == 0) {
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
    }

    debugPrint('✅ تم تنظيف وإصلاح بيانات التصنيفات والوحدات');
  } catch (e) {
    debugPrint('❌ خطأ في تنظيف البيانات: $e');
  }
}

// ==============================================================================
// 🔗 دوال wrapper للعمليات المالية مع الربط التلقائي
// ==============================================================================
// ← Hint: هذه الدوال الجديدة توفر طريقة موحدة وآمنة للعمليات المالية
// ← Hint: تسجل القيود المالية تلقائياً عبر FinancialIntegrationHelper
// ← Hint: يُفضل استخدامها بدلاً من التعامل المباشر مع قاعدة البيانات

/// تسجيل مبيعة جديدة (بند في فاتورة)
///
/// ← Hint: تُستدعى من الشاشات لتسجيل بند مبيعة
/// ← Hint: ⚠️ لا تسجل القيد المالي هنا! القيد يُسجل على مستوى الفاتورة بأكملها
/// ← Returns: معرف المبيعة (Sale ID)
Future<int> recordSale({
  required int invoiceId,
  required int customerId,
  required int productId,
  required String customerName,
  required String details,
  required Decimal debt,
  required int quantity,
  required Decimal costPrice,
  required Decimal profitAmount,
  String? productName,
  bool isCashSale = true, // ✅ معامل جديد: افتراضياً true (نقدي)
}) async {
  final db = await instance.database;

  // ← Hint: إدراج المبيعة في جدول Debt_Customer
  final saleId = await db.insert('Debt_Customer', {
    'InvoiceID': invoiceId,
    'CustomerID': customerId,
    'ProductID': productId,
    'CustomerName': customerName,
    'Details': details,
    'Debt': debt.toDouble(),
    'DateT': DateTime.now().toIso8601String(),
    'Qty_Customer': quantity,
    'CostPriceAtTimeOfSale': costPrice.toDouble(),
    'ProfitAmount': profitAmount.toDouble(),
    'IsReturned': 0,
  });

  // ← Hint: ⚠️ تم إزالة recordSaleTransaction من هنا
  // ← Hint: القيد المالي الآن يُسجل مرة واحدة على مستوى الفاتورة (recordInvoiceTransaction)
  // ← Hint: هذا يمنع إنشاء قيود متعددة لنفس الفاتورة

  return saleId;
}

/// تسجيل دفعة من زبون مع قيد مالي تلقائي
///
/// ← Hint: تُستدعى عند استلام دفعة من زبون
/// ← Hint: تسجل القيد المالي تلقائياً
/// ← Returns: معرف الدفعة (Payment ID)
Future<int> recordCustomerPayment({
  required int customerId,
  required Decimal amount,
  required String paymentDate,
  String? comments,
}) async {
  final db = await instance.database;

  // ← Hint: إدراج الدفعة في جدول Payment_Customer
  final paymentId = await db.insert('Payment_Customer', {
    'CustomerID': customerId,
    'Payment': amount.toDouble(), // ✅ تم تصحيح اسم العمود من Amount إلى Payment
    'DateT': paymentDate,
    'Comments': comments ?? '',
  });

  // ← Hint: تسجيل القيد المالي التلقائي
  await FinancialIntegrationHelper.recordCustomerPaymentTransaction(
    paymentId: paymentId,
    customerId: customerId,
    amount: amount,
    paymentDate: paymentDate,
    comments: comments,
  );

  // ← Hint: تحديث رصيد العميل المتبقي
  await db.rawUpdate(
    'UPDATE TB_Customer SET Remaining = Remaining - ? WHERE CustomerID = ?',
    [amount.toDouble(), customerId],
  );

  return paymentId;
}


}
