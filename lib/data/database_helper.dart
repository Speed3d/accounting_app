import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:accounting_app/data/models.dart';
import 'package:sqflite/sqflite.dart';

import 'models.dart' as models;


// Hint: هذا الكلاس هو المسؤول الوحيد عن كل عمليات قاعدة البيانات في التطبيق.
class DatabaseHelper {
  static const _databaseName = "accounting.db";

  // --- ✅ الخطوة 1: تحديد الإصدار النهائي ---
  // بما أننا سنبدأ من جديد، يمكننا اعتباره الإصدار 1 من الهيكل الجديد.
  static const _databaseVersion = 2;

    // --- ✅ تعريف الاسم الرمزي الثابت للزبون النقدي ---
  static const String cashCustomerInternalName = '_CASH_CUSTOMER_';


  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();


  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }


  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path, version: _databaseVersion, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////

  // --- ✅ الخطوة 2: دالة `_onCreate` المثالية ---
  // Hint: هذه الدالة تحتوي على الشكل النهائي لقاعدة البيانات.
  // سيتم استدعاؤها عند تثبيت التطبيق لأول مرة.

  Future _onCreate(Database db, int version) async {
    var batch = db.batch();

    // --- جدول المستخدمين بالهيكل الجديد ---
    batch.execute('''
      CREATE TABLE TB_Users (
        ID INTEGER PRIMARY KEY AUTOINCREMENT, 
        FullName TEXT NOT NULL, 
        UserName TEXT NOT NULL UNIQUE, 
        Password TEXT NOT NULL, 
        DateT TEXT NOT NULL, 
        ImagePath TEXT, 
        IsAdmin INTEGER NOT NULL DEFAULT 0,

        CanViewSuppliers INTEGER NOT NULL DEFAULT 0,
        CanEditSuppliers INTEGER NOT NULL DEFAULT 0,
        CanViewProducts INTEGER NOT NULL DEFAULT 0,
        CanEditProducts INTEGER NOT NULL DEFAULT 0,
        CanViewCustomers INTEGER NOT NULL DEFAULT 0,
        CanEditCustomers INTEGER NOT NULL DEFAULT 0,
        CanViewReports INTEGER NOT NULL DEFAULT 0,
        CanManageEmployees INTEGER NOT NULL DEFAULT 0,
        CanViewSettings INTEGER NOT NULL DEFAULT 0,
        CanViewEmployeesReport INTEGER NOT NULL DEFAULT 0,
        canManageExpenses INTEGER NOT NULL DEFAULT 0,
        canViewCashSales INTEGER NOT NULL DEFAULT 0
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
    IsActive INTEGER NOT NULL DEFAULT 1
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
          Qty_Coustomer INTEGER NOT NULL, 
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
        activation_expiry_date TEXT 
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
          FOREIGN KEY (CustomerID) REFERENCES TB_Customer (CustomerID)
      )
    ''');

    batch.execute('''
      CREATE TABLE TB_Expenses (
        ExpenseID INTEGER PRIMARY KEY AUTOINCREMENT,
        Description TEXT NOT NULL,
        Amount REAL NOT NULL,
        ExpenseDate TEXT NOT NULL,
        Category TEXT,
        Notes TEXT
      )
      ''');


       batch.execute('''
      CREATE TABLE TB_Expense_Categories (
        CategoryID INTEGER PRIMARY KEY AUTOINCREMENT,
        CategoryName TEXT NOT NULL UNIQUE
      )
    ''');

    await batch.commit();

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

    // if (oldVersion < 1) {
    //   final oldData = await db.query('TB_App_State', limit: 1);
    //   String? firstRunDate;
    //   if (oldData.isNotEmpty) {
    //     firstRunDate = oldData.first['first_run_date'] as String?;
    //   }
    //   await db.execute("DROP TABLE IF EXISTS TB_App_State");
    //   await db.execute('''
    //     CREATE TABLE TB_App_State (
    //       ID INTEGER PRIMARY KEY,
    //       first_run_date TEXT,
    //       activation_expiry_date TEXT 
    //     )
    //   ''');
    //   if (firstRunDate != null) {
    //     await db.insert('TB_App_State', {'ID': 1, 'first_run_date': firstRunDate});
    //   }
    // }

    // // --- ✅ الترقية من الإصدار 1 إلى 2 ---
    // if (oldVersion < 2) {
    //   // 1. إنشاء جدول الفواتير الجديد
    //   await db.execute('''
    //     CREATE TABLE TB_Invoices (
    //       InvoiceID INTEGER PRIMARY KEY AUTOINCREMENT,
    //       CustomerID INTEGER NOT NULL,
    //       InvoiceDate TEXT NOT NULL,
    //       TotalAmount REAL NOT NULL,
    //       FOREIGN KEY (CustomerID) REFERENCES TB_Customer (CustomerID)
    //     )
    //   ''');

    //   // 2. إعادة إنشاء جدول الديون (المبيعات) بالهيكل الجديد
    //   // للأسف، إضافة Foreign Key لجدول موجود معقدة في SQLite،
    //   // لذا إعادة الإنشاء هي الطريقة الأكثر أماناً هنا.
    //   // بما أننا في مرحلة التطوير، هذا الإجراء مقبول.
    //   await db.execute("DROP TABLE IF EXISTS Debt_Customer");
    //   await db.execute('''
    //     CREATE TABLE Debt_Customer (
    //       ID INTEGER PRIMARY KEY AUTOINCREMENT, 
    //       InvoiceID INTEGER,
    //       CustomerID INTEGER NOT NULL, 
    //       ProductID INTEGER NOT NULL, 
    //       CustomerName TEXT, 
    //       Details TEXT, 
    //       Debt REAL NOT NULL, 
    //       DateT TEXT NOT NULL, 
    //       Qty_Coustomer INTEGER NOT NULL, 
    //       CostPriceAtTimeOfSale REAL NOT NULL, 
    //       ProfitAmount REAL NOT NULL, 
    //       IsReturned INTEGER NOT NULL DEFAULT 0,
    //       FOREIGN KEY (InvoiceID) REFERENCES TB_Invoices (InvoiceID)
    //     )
    //   ''');
    // }

    //  if (oldVersion < 3) {
    //   // إضافة الحقل الجديد `IsVoid` إلى جدول الفواتير
    //   await db.execute('ALTER TABLE TB_Invoices ADD COLUMN IsVoid INTEGER NOT NULL DEFAULT 0');
    //   // إضافة الحقل الجديد `Status` (اختياري لكن مفيد)
    //   await db.execute('ALTER TABLE TB_Invoices ADD COLUMN Status TEXT');
    // }

    // if (oldVersion < 4) {
    //   await db.execute('''
    //     CREATE TABLE TB_Profit_Withdrawals (
    //       WithdrawalID INTEGER PRIMARY KEY AUTOINCREMENT,
    //       SupplierID INTEGER NOT NULL,
    //       PartnerName TEXT,
    //       WithdrawalAmount REAL NOT NULL,
    //       WithdrawalDate TEXT NOT NULL,
    //       Notes TEXT
    //     )
    //   ''');
    // }

    // if (oldVersion < 5) {
    //   await db.execute('''
    //     CREATE TABLE TB_Expenses (
    //       ExpenseID INTEGER PRIMARY KEY AUTOINCREMENT,
    //       Description TEXT NOT NULL,
    //       Amount REAL NOT NULL,
    //       ExpenseDate TEXT NOT NULL,
    //       Category TEXT,
    //       Notes TEXT
    //     )
    //   ''');
    // }

    //  if (oldVersion < 6) {
    //   // 1. إنشاء جدول فئات المصاريف
    //   await db.execute('''
    //     CREATE TABLE TB_Expense_Categories (
    //       CategoryID INTEGER PRIMARY KEY AUTOINCREMENT,
    //       CategoryName TEXT NOT NULL UNIQUE
    //     )
    //   ''');
    //   // 2. إضافة الفئات الافتراضية
    //   await _insertDefaultCategories(db);
    // }

    //  if (oldVersion < 7) {
    //   await db.execute('ALTER TABLE TB_Users ADD COLUMN canManageExpenses INTEGER NOT NULL DEFAULT 0');
    //   await db.execute('ALTER TABLE TB_Users ADD COLUMN canViewCashSales INTEGER NOT NULL DEFAULT 0');
    // }

    
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE Supplier_Partners ADD COLUMN ImagePath TEXT');
    // }

  }



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

  Future<User?> getFirstUser() async {
    final db = await instance.database;
    final maps = await db.query('TB_Users', limit: 1);
    if (maps.isNotEmpty) return User.fromMap(maps.first);
    return null;
  }

  Future<int> insertUser(User user) async => await (await instance.database).insert('TB_Users', user.toMap());
  Future<int> updateUser(User user) async => await (await instance.database).update('TB_Users', user.toMap(), where: 'ID = ?', whereArgs: [user.id]);
  Future<int> deleteUser(int id) async => await (await instance.database).delete('TB_Users', where: 'ID = ?', whereArgs: [id]);

  Future<List<User>> getAllUsers() async {
    final maps = await (await instance.database).query('TB_Users');
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

     /// --- Hint: دالة لجلب مستخدم معين عن طريق اسم المستخدم الخاص به ---
     Future<models.User?> getUserByUsername(String username) async {
      final db = await instance.database;
      final maps = await db.query(
      'TB_Users',
       where: 'UserName = ?',
       whereArgs: [username],
      );
      if (maps.isNotEmpty) {
       return models.User.fromMap(maps.first);
      }
       return null;
      }

    /// --- Hint: دالة لحساب عدد المستخدمين في قاعدة البيانات ---
    /// هذه الدالة هي أساس منطق بدء التشغيل الذكي.
    Future<int> getUserCount() async {
     final db = await instance.database;
     final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM TB_Users'));
     return count ?? 0;
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

  Future<List<Product>> getAllProductsWithSupplierName() async {
    final db = await instance.database;
    final result = await db.rawQuery("SELECT P.*, S.SupplierName FROM Store_Products P LEFT JOIN TB_Suppliers S ON P.SupplierID = S.SupplierID WHERE P.IsActive = 1 ORDER BY P.ProductName");
    return result.map((map) => Product.fromMap(map)).toList();
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
  Future<void> returnSaleItem(CustomerDebt saleToReturn) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      // الخطوة 1: تحديث حالة عملية البيع الأصلية إلى "مرجع".
      await txn.update('Debt_Customer', {'IsReturned': 1}, where: 'ID = ?', whereArgs: [saleToReturn.id]);
      // الخطوة 2: زيادة كمية المنتج في المخزن.
      await txn.rawUpdate('UPDATE Store_Products SET Quantity = Quantity + ? WHERE ProductID = ?', [saleToReturn.qty_Coustomer, saleToReturn.productID]);
      
      // الخطوة 3 (المُعدلة): إنقاص المبلغ المتبقي على الزبون.
      // لا يوجد تغيير في الكود هنا، لكن المنطق تغير. الآن نسمح بأن تكون النتيجة سالبة.
      await txn.rawUpdate('UPDATE TB_Customer SET Remaining = Remaining - ? WHERE CustomerID = ?', [saleToReturn.debt, saleToReturn.customerID]);
      
      // الخطوة 4: تسجيل عملية الإرجاع في جدول المرتجعات.
      final saleReturn = SalesReturn(
        originalSaleID: saleToReturn.id!,
        customerID: saleToReturn.customerID,
        productID: saleToReturn.productID,
        returnedQuantity: saleToReturn.qty_Coustomer,
        returnAmount: saleToReturn.debt,
        returnDate: DateTime.now().toIso8601String(),
        reason: 'إرجاع من قبل المستخدم',
      );
      await txn.insert('Sales_Returns', saleReturn.toMap());
    });
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

  // Hint: دالة لحساب إجمالي الأرباح من جميع المبيعات التي لم يتم إرجاعها.
  Future<double> getTotalProfit() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT SUM(ProfitAmount) as Total FROM Debt_Customer WHERE IsReturned = 0');
    final data = result.first;
    if (data['Total'] != null) {
      return (data['Total'] as num).toDouble();
    } else {
      return 0.0;
    }
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
    return await db.rawQuery(sql);
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
Future<void> recordNewAdvance(EmployeeAdvance advance) async {
  final db = await instance.database;
  await db.transaction((txn) async {
    // الخطوة 1: إدراج سجل السلفة الجديد.
    await txn.insert('TB_Employee_Advances', advance.toMap());
    
    // الخطوة 2: تحديث رصيد الموظف (زيادة الدين عليه).
    await txn.rawUpdate(
      'UPDATE TB_Employees SET Balance = Balance + ? WHERE EmployeeID = ?',
      [advance.advanceAmount, advance.employeeID],
    );
  });
}



// Hint: دالة لتسجيل عملية دفع راتب جديدة.
// هذه دالة حرجة تستخدم transaction لضمان تكامل البيانات.
Future<void> recordNewPayroll(PayrollEntry payroll, double advanceAmountToRepay) async {
  final db = await instance.database;
  await db.transaction((txn) async {
    // الخطوة 1: إدراج سجل الراتب الجديد في جدول الرواتب.
    await txn.insert('TB_Payroll', payroll.toMap());

    // الخطوة 2: تحديث رصيد الموظف.
    // ننقص رصيد السلفة عليه بمقدار المبلغ الذي تم تسديده من السلفة.
    await txn.rawUpdate(
      'UPDATE TB_Employees SET Balance = Balance - ? WHERE EmployeeID = ?',
      [advanceAmountToRepay, payroll.employeeID],
    );

    // الخطوة 3 (اختياري لكن مهم): تحديث حالة السلف القديمة.
    // هذا منطق معقد قليلاً، يقوم بتحديث حالة السلف من "غير مسددة" إلى "مسددة بالكامل"
    // إذا أصبح رصيد الموظف صفرًا أو أقل.
    final result = await txn.query('TB_Employees', columns: ['Balance'], where: 'EmployeeID = ?', whereArgs: [payroll.employeeID]);
    final currentBalance = (result.first['Balance'] as num).toDouble();
    if (currentBalance <= 0) {
      await txn.update(
        'TB_Employee_Advances',
        {'RepaymentStatus': 'مسددة بالكامل'},
        where: 'EmployeeID = ? AND RepaymentStatus != ?',
        whereArgs: [payroll.employeeID, 'مسددة بالكامل'],
      );
    }
  });
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
Future<double> getTotalNetSalariesPaid() async {
  final db = await instance.database;
  final result = await db.rawQuery('SELECT SUM(NetSalary) as Total FROM TB_Payroll');
  return (result.first['Total'] as num?)?.toDouble() ?? 0.0;
}

// Hint: دالة لحساب إجمالي رصيد السلف المستحقة على جميع الموظفين.
Future<double> getTotalActiveAdvancesBalance() async {
  final db = await instance.database;
  final result = await db.rawQuery('SELECT SUM(Balance) as Total FROM TB_Employees WHERE IsActive = 1');
  return (result.first['Total'] as num?)?.toDouble() ?? 0.0;
}

// Hint: دالة لحساب عدد الموظفين النشطين.
Future<int> getActiveEmployeesCount() async {
  final db = await instance.database;
  final result = await db.rawQuery('SELECT COUNT(*) FROM TB_Employees WHERE IsActive = 1');
  return Sqflite.firstIntValue(result) ?? 0;
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




  /// دالة لجلب كل الفواتير النقدية، مرتبة من الأحدث إلى الأقدم.
  Future<List<Map<String, dynamic>>> getCashInvoices() async {
    final db = await instance.database;
    // 1. نحصل على الـ ID الخاص بالزبون النقدي أولاً.
    final cashCustomer = await getOrCreateCashCustomer();
    
    // 2. نبحث عن كل الفواتير المرتبطة بهذا الـ ID.
    final result = await db.query(
      'TB_Invoices',
      where: 'CustomerID = ?',
      whereArgs: [cashCustomer.customerID],
      orderBy: 'InvoiceDate DESC', // ترتيب تنازلي حسب التاريخ
    );
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
        await txn.rawUpdate('UPDATE Store_Products SET Quantity = Quantity + ? WHERE ProductID = ?', [sale.qty_Coustomer, sale.productID]);
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

    // 1. جلب المبيعات النقدية (فقط الفواتير غير الملغاة)
    final cashSales = await db.rawQuery('''
      SELECT 
        'CASH_SALE' as type,
        InvoiceID as id,
        'بيع نقدي مباشر (فاتورة #' || InvoiceID || ')' as description,
        TotalAmount as amount,
        InvoiceDate as date
      FROM TB_Invoices
      WHERE CustomerID = ? AND IsVoid = 0 AND InvoiceDate BETWEEN ? AND ?
    ''', [cashCustomerId, finalStartDate.toIso8601String(), finalEndDate.toIso8601String()]);

    // 2. جلب تسديدات الديون
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
  Future<int> recordProfitWithdrawal(Map<String, dynamic> withdrawalData) async {
    final db = await instance.database;
    return await db.insert('TB_Profit_Withdrawals', withdrawalData);
  }


  /// دالة لجلب إجمالي المبالغ المسحوبة لمورد معين.
  Future<double> getTotalWithdrawnForSupplier(int supplierId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(WithdrawalAmount) as Total FROM TB_Profit_Withdrawals WHERE SupplierID = ?',
      [supplierId],
    );
    return (result.first['Total'] as num?)?.toDouble() ?? 0.0;
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
  // ✅  إضافة الدوال الجديدة الخاصة بالمصاريف
  // =================================================================================================

  /// دالة لتسجيل مصروف جديد.
  Future<int> recordExpense(Map<String, dynamic> expenseData) async {
    final db = await instance.database;
    return await db.insert('TB_Expenses', expenseData);
  }

  /// دالة لجلب كل المصاريف، مرتبة من الأحدث للأقدم.
  Future<List<Map<String, dynamic>>> getExpenses() async {
    final db = await instance.database;
    return await db.query('TB_Expenses', orderBy: 'ExpenseDate DESC');
  }

  /// دالة لحساب إجمالي المصاريف.
  Future<double> getTotalExpenses() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT SUM(Amount) as Total FROM TB_Expenses');
    return (result.first['Total'] as num?)?.toDouble() ?? 0.0;
  }



  // =================================================================================================
  // ✅  إضافة دالة جديدة لحساب إجمالي مسحوبات أرباح الموردين
  // =================================================================================================
  
  /// دالة لحساب إجمالي كل المبالغ المسحوبة من أرباح الموردين والشركاء.
  Future<double> getTotalAllProfitWithdrawals() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT SUM(WithdrawalAmount) as Total FROM TB_Profit_Withdrawals');
    return (result.first['Total'] as num?)?.toDouble() ?? 0.0;
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
    // 1. SUM(D.Qty_Coustomer) as total_quantity: نحسب مجموع الكميات المباعة لكل منتج ونسميه total_quantity.
    // 2. JOIN: نربط جدول المبيعات (Debt_Customer) بجدول المنتجات (Store_Products).
    // 3. WHERE D.IsReturned = 0: نستبعد المبيعات التي تم إرجاعها.
    // 4. GROUP BY P.ProductID: نجمع النتائج لكل منتج على حدة.
    // 5. ORDER BY total_quantity DESC: نرتب المنتجات تنازلياً حسب الكمية المباعة.
    // 6. LIMIT ?: نأخذ فقط العدد المحدد من النتائج.
    final result = await db.rawQuery('''
      SELECT P.*, SUM(D.Qty_Coustomer) as total_quantity
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




}
