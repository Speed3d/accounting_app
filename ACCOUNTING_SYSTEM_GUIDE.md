# 📊 دليل شامل لنظام المحاسبة في التطبيق

## 📋 جدول المحتويات

1. [نظرة عامة](#نظرة-عامة)
2. [البنية التحتية](#البنية-التحتية)
3. [الملفات المعدلة والمنشأة](#الملفات-المعدلة-والمنشأة)
4. [الدليل المحاسبي (Chart of Accounts)](#الدليل-المحاسبي)
5. [كيفية عمل النظام](#كيفية-عمل-النظام)
6. [التقارير المحاسبية المتوفرة](#التقارير-المحاسبية-المتوفرة)
7. [كيفية تفعيل العرض المحاسبي في التقارير](#كيفية-تفعيل-العرض-المحاسبي-في-التقارير)
8. [الأخطاء التي تم إصلاحها](#الأخطاء-التي-تم-إصلاحها)

---

## نظرة عامة

تم تحويل تطبيق المحاسبة من نظام بسيط إلى نظام محاسبي متكامل يدعم:

### ✅ الميزات المحاسبية الجديدة

1. **القيد المزدوج (Double-Entry Bookkeeping)**
   - كل عملية تسجل كـ مدين ودائن
   - ضمان توازن الحسابات دائماً

2. **دليل حسابات شامل (Chart of Accounts)**
   - 12 حساب افتراضي جاهز
   - تصنيف حسب الأنواع (أصول، خصوم، إيرادات، مصروفات، حقوق ملكية)
   - تصنيف فرعي حسب الفئات

3. **تكامل تلقائي مع عمليات المخزون**
   - إضافة منتج → قيد محاسبي تلقائي
   - تعديل منتج → قيد تسوية تلقائي
   - حذف منتج → قيد عكسي حسب السبب (إرجاع/تلف/خطأ)

4. **ربط مع السنوات المالية**
   - جميع القيود مرتبطة بسنة مالية
   - إمكانية إقفال السنوات
   - تقارير حسب السنة المالية

5. **تحديث أرصدة تلقائي**
   - Triggers في قاعدة البيانات تحدث الأرصدة تلقائياً
   - عند إدخال/تعديل/حذف قيد → تحديث رصيد الحسابات فوراً

6. **خيار عرض بسيط أو محاسبي**
   - المستخدم يختار من الإعدادات
   - عرض بسيط: للمحلات الصغيرة
   - عرض محاسبي: للشركات الكبيرة

---

## البنية التحتية

### 🗄️ قاعدة البيانات

#### جدول `TB_Accounts` (الحسابات)

```sql
CREATE TABLE TB_Accounts (
  AccountID INTEGER PRIMARY KEY AUTOINCREMENT,
  AccountCode TEXT NOT NULL UNIQUE,          -- رمز الحساب (1001, 1100, ...)
  AccountNameAr TEXT NOT NULL,               -- الاسم بالعربية
  AccountNameEn TEXT NOT NULL,               -- الاسم بالإنجليزية
  AccountType TEXT NOT NULL,                 -- النوع (asset, liability, ...)
  AccountCategory TEXT NOT NULL,             -- الفئة (current_asset, ...)
  ParentAccountID INTEGER,                   -- الحساب الأب (للحسابات الفرعية)
  Balance REAL NOT NULL DEFAULT 0.0,         -- الرصيد الحالي
  DebitBalance REAL NOT NULL DEFAULT 0.0,    -- إجمالي المدين
  CreditBalance REAL NOT NULL DEFAULT 0.0,   -- إجمالي الدائن
  IsDefault INTEGER NOT NULL DEFAULT 0,      -- حساب افتراضي؟
  IsActive INTEGER NOT NULL DEFAULT 1,       -- نشط؟
  Description TEXT,                          -- وصف
  CreatedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UpdatedAt TEXT
)
```

#### إضافات على جدول `TB_Transactions` (القيود المالية)

```sql
-- تم إضافة عمودين:
DebitAccountID INTEGER,   -- رقم الحساب المدين
CreditAccountID INTEGER,  -- رقم الحساب الدائن

-- مع Foreign Keys:
FOREIGN KEY (DebitAccountID) REFERENCES TB_Accounts(AccountID)
FOREIGN KEY (CreditAccountID) REFERENCES TB_Accounts(AccountID)
```

#### Triggers (المحفزات التلقائية)

##### 1. عند إدخال قيد جديد
```sql
CREATE TRIGGER TR_UpdateAccountBalances_AfterInsert
AFTER INSERT ON TB_Transactions
BEGIN
  -- تحديث حساب المدين
  UPDATE TB_Accounts
  SET
    DebitBalance = DebitBalance + NEW.Amount,
    Balance = Balance + NEW.Amount,
    UpdatedAt = CURRENT_TIMESTAMP
  WHERE AccountID = NEW.DebitAccountID;

  -- تحديث حساب الدائن
  UPDATE TB_Accounts
  SET
    CreditBalance = CreditBalance + NEW.Amount,
    Balance = Balance - NEW.Amount,
    UpdatedAt = CURRENT_TIMESTAMP
  WHERE AccountID = NEW.CreditAccountID;
END;
```

##### 2. عند تعديل قيد موجود
```sql
CREATE TRIGGER TR_UpdateAccountBalances_AfterUpdate
AFTER UPDATE ON TB_Transactions
BEGIN
  -- عكس القيد القديم
  UPDATE TB_Accounts SET ... WHERE AccountID = OLD.DebitAccountID;
  UPDATE TB_Accounts SET ... WHERE AccountID = OLD.CreditAccountID;

  -- تطبيق القيد الجديد
  UPDATE TB_Accounts SET ... WHERE AccountID = NEW.DebitAccountID;
  UPDATE TB_Accounts SET ... WHERE AccountID = NEW.CreditAccountID;
END;
```

##### 3. عند حذف قيد
```sql
CREATE TRIGGER TR_UpdateAccountBalances_AfterDelete
AFTER DELETE ON TB_Transactions
BEGIN
  -- عكس القيد المحذوف
  UPDATE TB_Accounts SET ... WHERE AccountID = OLD.DebitAccountID;
  UPDATE TB_Accounts SET ... WHERE AccountID = OLD.CreditAccountID;
END;
```

---

## الملفات المعدلة والمنشأة

### ✅ ملفات جديدة تماماً

#### 1. `lib/data/models.dart` (+210 سطر)

**الغرض**: نماذج البيانات المحاسبية

```dart
// 🔹 أنواع الحسابات الرئيسية
enum AccountType {
  asset,        // أصول
  liability,    // خصوم
  equity,       // حقوق ملكية
  revenue,      // إيرادات
  expense,      // مصروفات
}

// 🔹 الفئات الفرعية
enum AccountCategory {
  current_asset,        // أصول متداولة
  current_liability,    // خصوم متداولة
  capital,              // رأس المال
  retained_earnings,    // أرباح محتجزة
  sales_revenue,        // إيرادات المبيعات
  cost_of_sales,        // تكلفة المبيعات
  salary_expense,       // مصروف رواتب
  general_expense,      // مصروف عام
}

// 🔹 نموذج الحساب
class Account {
  final int? accountID;
  final String accountCode;      // "1001"
  final String accountNameAr;    // "الصندوق"
  final String accountNameEn;    // "Cash"
  final AccountType accountType;
  final AccountCategory accountCategory;
  final int? parentAccountID;
  final Decimal balance;
  final Decimal debitBalance;
  final Decimal creditBalance;
  final bool isDefault;
  final bool isActive;
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // ... toMap(), fromMap(), copyWith()
}
```

#### 2. `lib/services/account_service.dart` (450+ سطر)

**الغرض**: خدمة عالية المستوى للتعامل مع الحسابات

```dart
class AccountService {
  static final AccountService instance = AccountService._internal();

  // 🔸 جلب جميع الحسابات
  Future<List<Account>> getAllAccounts({
    AccountType? accountType,
    bool onlyActive = true,
  });

  // 🔸 جلب حساب معين
  Future<Account?> getAccountById(int accountId);
  Future<Account?> getAccountByCode(String accountCode);

  // 🔸 اختصارات للحسابات الشائعة
  Future<Account?> getCashAccount();              // 1001 - الصندوق
  Future<Account?> getBankAccount();              // 1002 - البنك
  Future<Account?> getInventoryAccount();         // 1100 - المخزون
  Future<Account?> getSuppliersAccount();         // 2001 - الموردون
  Future<Account?> getCapitalAccount();           // 3001 - رأس المال
  Future<Account?> getSalesRevenueAccount();      // 4001 - إيرادات المبيعات
  Future<Account?> getCostOfSalesAccount();       // 5001 - تكلفة المبيعات
  Future<Account?> getInventoryLossAccount();     // 5010 - خسائر المخزون

  // 🔸 إحصائيات
  Future<Decimal> getTotalAssets();           // مجموع الأصول
  Future<Decimal> getTotalLiabilities();      // مجموع الخصوم
  Future<Decimal> getTotalEquity();           // مجموع حقوق الملكية
  Future<Decimal> getTotalRevenue();          // مجموع الإيرادات
  Future<Decimal> getTotalExpenses();         // مجموع المصروفات

  // 🔸 القوائم المالية
  Future<Map<String, dynamic>> getBalanceSheet();      // الميزانية العمومية
  Future<Map<String, dynamic>> getIncomeStatement();   // قائمة الدخل
  Future<Map<String, dynamic>> getTrialBalance();      // ميزان المراجعة
}
```

**مثال استخدام**:
```dart
// الحصول على رصيد الصندوق
final cashAccount = await AccountService.instance.getCashAccount();
print('رصيد الصندوق: ${cashAccount?.balance}');

// الحصول على إجمالي الأصول
final totalAssets = await AccountService.instance.getTotalAssets();
print('إجمالي الأصول: $totalAssets');

// الحصول على الميزانية العمومية
final balanceSheet = await AccountService.instance.getBalanceSheet();
print('الأصول: ${balanceSheet['assets']}');
print('الخصوم: ${balanceSheet['liabilities']}');
print('حقوق الملكية: ${balanceSheet['equity']}');
```

#### 3. `lib/helpers/accounting_integration_helper.dart` (550+ سطر)

**الغرض**: ربط عمليات المخزون بالقيود المحاسبية

```dart
class AccountingIntegrationHelper {

  // 🔸 تسجيل شراء منتج
  static Future<bool> recordProductPurchase({
    required int productId,
    required int quantity,
    required Decimal costPrice,
    required String purchaseType,  // 'cash', 'credit', 'opening_stock'
    int? supplierId,
  }) async {
    final totalCost = costPrice * Decimal.fromInt(quantity);

    // الحصول على الحسابات
    final inventoryAccount = await accountService.getInventoryAccount();

    if (purchaseType == 'cash') {
      // شراء نقدي
      final cashAccount = await accountService.getCashAccount();
      // القيد: من ح/ المخزون - إلى ح/ الصندوق
      // Debit: Inventory (+), Credit: Cash (-)

    } else if (purchaseType == 'credit') {
      // شراء آجل
      final suppliersAccount = await accountService.getSuppliersAccount();
      // القيد: من ح/ المخزون - إلى ح/ الموردون
      // Debit: Inventory (+), Credit: Suppliers (+)

    } else if (purchaseType == 'opening_stock') {
      // رصيد افتتاحي
      final capitalAccount = await accountService.getCapitalAccount();
      // القيد: من ح/ المخزون - إلى ح/ رأس المال
      // Debit: Inventory (+), Credit: Capital (+)
    }

    return true;
  }

  // 🔸 تسجيل تعديل منتج
  static Future<bool> recordProductAdjustment({
    required int productId,
    required Decimal costDifference,
    required int quantityDifference,
    required String adjustmentReason,
  });

  // 🔸 تسجيل حذف منتج
  static Future<bool> recordProductDeletion({
    required int productId,
    required int quantity,
    required Decimal costPrice,
    required String deleteReason,  // 'loss', 'return_to_supplier', 'entry_error'
  }) async {
    final totalCost = costPrice * Decimal.fromInt(quantity);

    final inventoryAccount = await accountService.getInventoryAccount();

    if (deleteReason == 'loss') {
      // خسارة أو تلف
      final lossAccount = await accountService.getInventoryLossAccount();
      // القيد: من ح/ خسائر المخزون - إلى ح/ المخزون
      // Debit: Inventory Loss (+), Credit: Inventory (-)

    } else if (deleteReason == 'return_to_supplier') {
      // إرجاع للمورد
      final suppliersAccount = await accountService.getSuppliersAccount();
      // القيد: من ح/ الموردون - إلى ح/ المخزون
      // Debit: Suppliers (-), Credit: Inventory (-)

    } else if (deleteReason == 'entry_error') {
      // خطأ في الإدخال
      final capitalAccount = await accountService.getCapitalAccount();
      // القيد: من ح/ رأس المال - إلى ح/ المخزون
      // Debit: Capital (-), Credit: Inventory (-)
    }

    return true;
  }
}
```

#### 4. `lib/providers/accounting_view_provider.dart` (50 سطر)

**الغرض**: إدارة خيار العرض البسيط/المحاسبي

```dart
class AccountingViewProvider with ChangeNotifier {
  static const String _keyShowAccountingView = 'show_accounting_view';

  bool _showAccountingView = false;  // القيمة الافتراضية: عرض بسيط

  bool get showAccountingView => _showAccountingView;

  // تحميل الإعدادات من SharedPreferences
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _showAccountingView = prefs.getBool(_keyShowAccountingView) ?? false;
    notifyListeners();
  }

  // تبديل الإعداد
  Future<void> toggleAccountingView(bool value) async {
    _showAccountingView = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowAccountingView, value);
  }
}
```

### ✅ ملفات معدلة

#### 1. `lib/data/database_helper.dart`

**التعديلات الرئيسية**:

1. **تحديث رقم الإصدار**:
   ```dart
   static const _databaseVersion = 11;  // كان 10
   ```

2. **إضافة TB_Accounts إلى `_onCreate`** (السطر ~1090):
   ```dart
   // ✅ إنشاء جدول الحسابات
   await db.execute('''CREATE TABLE IF NOT EXISTS TB_Accounts (...)''');

   // ✅ إدراج 12 حساب افتراضي
   for (var account in defaultAccounts) {
     await db.insert('TB_Accounts', account);
   }

   // ✅ إنشاء 3 Triggers
   await db.execute('''CREATE TRIGGER TR_UpdateAccountBalances_AfterInsert ...''');
   await db.execute('''CREATE TRIGGER TR_UpdateAccountBalances_AfterUpdate ...''');
   await db.execute('''CREATE TRIGGER TR_UpdateAccountBalances_AfterDelete ...''');

   // ✅ إنشاء 6 Indexes للأداء
   ```

3. **إضافة DebitAccountID و CreditAccountID إلى TB_Transactions**

4. **إصلاح خطأ حرج**: استبدال `batch.execute()` بـ `await db.execute()` بعد `batch.commit()`

#### 2. `lib/data/database_migrations.dart`

**الغرض**: ترقية قاعدة البيانات للمستخدمين الحاليين

- إضافة دالة `migrateToV11()` (380+ سطر)
- نفس محتوى `_onCreate` لكن للترقية

#### 3. `lib/screens/products/add_edit_product_screen.dart`

**التعديلات**:

1. **إضافة Import**:
   ```dart
   import 'package:accountant_touch/helpers/accounting_integration_helper.dart';
   ```

2. **إنشاء Dialog لنوع الشراء**:
   ```dart
   Future<String?> _showPurchaseTypeDialog() async {
     return showDialog<String>(
       context: context,
       builder: (context) => AlertDialog(
         title: Text('نوع الشراء'),
         content: Column(
           children: [
             // ✅ شراء نقدي (من الصندوق)
             _buildPurchaseTypeOption(
               icon: Icons.money,
               title: 'شراء نقدي',
               description: 'تم الدفع من الصندوق فوراً',
               value: 'cash',
             ),
             // ✅ شراء آجل (على المورد)
             _buildPurchaseTypeOption(
               icon: Icons.credit_card,
               title: 'شراء آجل',
               description: 'سيتم الدفع للمورد لاحقاً',
               value: 'credit',
             ),
             // ✅ رصيد افتتاحي (مخزون موجود)
             _buildPurchaseTypeOption(
               icon: Icons.inventory_2,
               title: 'رصيد افتتاحي',
               description: 'مخزون موجود من قبل',
               value: 'opening_stock',
             ),
           ],
         ),
       ),
     );
   }
   ```

3. **تعديل `_saveProduct()`**:
   ```dart
   Future<void> _saveProduct() async {
     if (widget.product == null) {
       // إضافة منتج جديد

       // 1️⃣ إظهار dialog لنوع الشراء
       final purchaseType = await _showPurchaseTypeDialog();
       if (purchaseType == null) return;

       // 2️⃣ حفظ المنتج
       final productId = await _dbHelper.insertProduct(product);

       // 3️⃣ تسجيل القيد المحاسبي
       await AccountingIntegrationHelper.recordProductPurchase(
         productId: productId,
         quantity: quantity,
         costPrice: costPrice,
         purchaseType: purchaseType,
         supplierId: _selectedSupplier!.supplierID!,
       );

     } else {
       // تعديل منتج موجود

       // تسجيل قيد تسوية
       await AccountingIntegrationHelper.recordProductAdjustment(
         productId: product.productID!,
         costDifference: costPrice - oldProduct.costPrice,
         quantityDifference: quantity - oldProduct.quantity,
         adjustmentReason: 'تعديل المنتج: ${product.productName}',
       );
     }
   }
   ```

#### 4. `lib/screens/products/products_list_screen.dart`

**التعديلات**:

1. **إضافة Dialog لسبب الحذف**:
   ```dart
   final deleteReason = await showDialog<String>(
     context: context,
     builder: (ctx) => AlertDialog(
       title: Text('سبب حذف/أرشفة المنتج'),
       content: Column(
         children: [
           // ✅ إرجاع للمورد
           _buildDeleteReasonOption(
             icon: Icons.undo,
             title: 'إرجاع للمورد',
             value: 'return_to_supplier',
           ),
           // ✅ خسارة أو تلف
           _buildDeleteReasonOption(
             icon: Icons.broken_image,
             title: 'خسارة أو تلف',
             value: 'loss',
           ),
           // ✅ خطأ في الإدخال
           _buildDeleteReasonOption(
             icon: Icons.edit_off,
             title: 'خطأ في الإدخال',
             value: 'entry_error',
           ),
         ],
       ),
     ),
   );
   ```

2. **تعديل `_handleArchiveProduct()`**:
   ```dart
   // تسجيل القيد المحاسبي قبل الحذف
   await AccountingIntegrationHelper.recordProductDeletion(
     productId: product.productID!,
     quantity: product.quantity,  // ✅ تم إصلاحه
     costPrice: product.costPrice,
     deleteReason: deleteReason,
   );

   // ثم حذف المنتج
   await dbHelper.archiveProduct(product.productID!);
   ```

#### 5. `lib/screens/settings/settings_screen.dart`

**التعديلات**:

1. **إضافة قسم الإعدادات المحاسبية**:
   ```dart
   _buildSectionHeader(
     context,
     title: 'الإعدادات المحاسبية',
     icon: Icons.account_balance_outlined,
   ),

   _SettingsCard(
     child: Consumer<AccountingViewProvider>(
       builder: (context, accountingProvider, child) {
         return SwitchListTile(
           title: const Text('العرض المحاسبي'),
           subtitle: Text(
             accountingProvider.showAccountingView
                 ? 'عرض التفاصيل المحاسبية والقيود'
                 : 'عرض بسيط بدون تفاصيل محاسبية',
           ),
           value: accountingProvider.showAccountingView,
           onChanged: (value) {
             accountingProvider.toggleAccountingView(value);
           },
         );
       },
     ),
   ),
   ```

#### 6. `lib/main.dart`

**التعديلات**:

1. **إضافة AccountingViewProvider**:
   ```dart
   Future<void> main() async {
     final accountingViewProvider = AccountingViewProvider();
     await accountingViewProvider.loadSettings();

     runApp(
       MultiProvider(
         providers: [
           ChangeNotifierProvider.value(value: themeProvider),
           ChangeNotifierProvider.value(value: localeProvider),
           ChangeNotifierProvider.value(value: accountingViewProvider),  // ✅ جديد
         ],
         child: const MyApp(),
       ),
     );
   }
   ```

---

## الدليل المحاسبي

### 📊 الحسابات الافتراضية (12 حساب)

| الرمز | الاسم بالعربية | النوع | الفئة | الوصف |
|------|----------------|-------|-------|-------|
| **1001** | الصندوق | أصول | أصول متداولة | النقدية في الصندوق |
| **1002** | البنك | أصول | أصول متداولة | الأرصدة البنكية |
| **1100** | المخزون | أصول | أصول متداولة | قيمة البضاعة المخزنة |
| **1200** | العملاء | أصول | أصول متداولة | الذمم المدينة من العملاء |
| **2001** | الموردون | خصوم | خصوم متداولة | الذمم الدائنة للموردين |
| **2100** | الرواتب المستحقة | خصوم | خصوم متداولة | رواتب لم تُدفع بعد |
| **3001** | رأس المال | حقوق ملكية | رأس المال | رأس المال المستثمر |
| **3100** | الأرباح المحتجزة | حقوق ملكية | أرباح محتجزة | أرباح لم توزع |
| **4001** | إيرادات المبيعات | إيرادات | إيرادات المبيعات | دخل من بيع البضاعة |
| **5001** | تكلفة المبيعات | مصروفات | تكلفة المبيعات | تكلفة البضاعة المباعة |
| **5005** | مصروف الرواتب | مصروفات | مصروف رواتب | رواتب الموظفين |
| **5010** | خسائر المخزون | مصروفات | مصروف عام | خسائر من تلف/ضياع |

### 🔄 أمثلة على القيود المحاسبية

#### مثال 1: شراء منتج نقدياً

**السيناريو**: شراء 10 قطع من منتج بسعر 50 دينار للقطعة نقداً
- **المبلغ الإجمالي**: 500 دينار

**القيد المحاسبي**:
```
500  من ح/ المخزون (1100)          ← مدين (Debit)
     إلى ح/ الصندوق (1001)          ← دائن (Credit)  500
```

**التأثير**:
- رصيد المخزون: +500 (زيادة أصل)
- رصيد الصندوق: -500 (نقص أصل)

#### مثال 2: شراء منتج آجلاً (على المورد)

**السيناريو**: شراء 20 قطعة بسعر 100 دينار آجلاً
- **المبلغ الإجمالي**: 2000 دينار

**القيد المحاسبي**:
```
2000  من ح/ المخزون (1100)         ← مدين
      إلى ح/ الموردون (2001)       ← دائن  2000
```

**التأثير**:
- رصيد المخزون: +2000 (زيادة أصل)
- رصيد الموردون: +2000 (زيادة التزام)

#### مثال 3: رصيد افتتاحي

**السيناريو**: إدخال مخزون موجود قيمته 10000 دينار

**القيد المحاسبي**:
```
10000  من ح/ المخزون (1100)        ← مدين
       إلى ح/ رأس المال (3001)     ← دائن  10000
```

**التأثير**:
- رصيد المخزون: +10000
- رصيد رأس المال: +10000

#### مثال 4: حذف منتج (خسارة/تلف)

**السيناريو**: حذف منتج بسبب تلف، قيمته 200 دينار

**القيد المحاسبي**:
```
200  من ح/ خسائر المخزون (5010)    ← مدين (مصروف)
     إلى ح/ المخزون (1100)         ← دائن  200
```

**التأثير**:
- رصيد المخزون: -200 (نقص أصل)
- مصروف الخسائر: +200 (زيادة مصروف)

#### مثال 5: حذف منتج (إرجاع للمورد)

**السيناريو**: إرجاع منتج للمورد، قيمته 300 دينار

**القيد المحاسبي**:
```
300  من ح/ الموردون (2001)         ← مدين
     إلى ح/ المخزون (1100)         ← دائن  300
```

**التأثير**:
- رصيد المخزون: -300
- رصيد الموردون: -300 (تقليل الالتزام)

---

## كيفية عمل النظام

### 🔄 تدفق العمل عند إضافة منتج

```
┌─────────────────────────────────┐
│  المستخدم يضيف منتج جديد       │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│  1️⃣ Dialog: اختر نوع الشراء    │
│     □ نقدي                      │
│     □ آجل                       │
│     □ رصيد افتتاحي              │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│  2️⃣ حفظ المنتج في قاعدة البيانات │
│     (جدول TB_Products)          │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│  3️⃣ AccountingIntegrationHelper │
│     .recordProductPurchase()    │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│  4️⃣ إنشاء قيد محاسبي في         │
│     TB_Transactions:             │
│     - DebitAccountID            │
│     - CreditAccountID           │
│     - Amount                    │
│     - Description               │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│  5️⃣ Trigger تلقائي يُحدّث:      │
│     - رصيد حساب المخزون         │
│     - رصيد الحساب الآخر         │
│     (الصندوق/الموردون/رأس المال)│
└─────────────────────────────────┘
```

### 🔄 تدفق العمل عند حذف منتج

```
┌─────────────────────────────────┐
│  المستخدم يحذف منتج             │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│  1️⃣ Dialog: اختر سبب الحذف      │
│     □ إرجاع للمورد              │
│     □ خسارة/تلف                 │
│     □ خطأ في الإدخال            │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│  2️⃣ تأكيد الحذف               │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│  3️⃣ AccountingIntegrationHelper │
│     .recordProductDeletion()    │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│  4️⃣ إنشاء قيد عكسي حسب السبب   │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│  5️⃣ Trigger يُحدّث الأرصدة      │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│  6️⃣ أرشفة المنتج               │
└─────────────────────────────────┘
```

---

## التقارير المحاسبية المتوفرة

### 📊 التقارير الموجودة حالياً

يمكن الوصول إليها من **مركز التقارير** (`ReportsHubScreen`):

#### 1. ✅ التقرير المالي الشامل
**الملف**: `lib/screens/fiscal_years/financial_report_screen.dart`

**المحتوى**:
- الملخص المالي (رصيد افتتاحي، دخل، مصروف، ربح صافي، رصيد ختامي)
- التفصيل حسب النوع (مبيعات، دفعات عملاء، رواتب، سلف، مكافآت، سحوبات، مرتجعات)
- مؤشرات الأداء (هامش الربح، نسبة المصروفات، عدد القيود)

**كيفية الوصول**:
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => FinancialReportScreen()),
);
```

#### 2. ✅ شاشة القيود المالية
**الملف**: `lib/screens/fiscal_years/transactions_screen.dart`

**المحتوى**:
- قائمة بجميع القيود المحاسبية
- تفاصيل كل قيد (مدين، دائن، المبلغ، التاريخ، الوصف)

#### 3. ✅ إدارة السنوات المالية
**الملف**: `lib/screens/fiscal_years/fiscal_years_screen.dart`

**المحتوى**:
- قائمة السنوات المالية
- تفعيل سنة مالية
- إقفال سنة مالية
- إنشاء سنة جديدة

#### 4. تقرير الأرباح العام
**الملف**: `lib/screens/reports/profit_report_screen.dart`

**المحتوى**:
- إجمالي الأرباح من المبيعات
- إجمالي المصاريف
- إجمالي المسحوبات
- صافي الربح
- تفاصيل المبيعات

#### 5. تقرير التدفقات النقدية الشامل
**الملف**: `lib/screens/reports/comprehensive_cash_flow_report_screen.dart`

#### 6. تقرير مبيعات الزبائن
**الملف**: `lib/screens/reports/customer_sales_report_screen.dart`

#### 7. تقرير الموظفين والرواتب
**الملف**: `lib/screens/reports/employees_report_screen.dart`

---

## كيفية تفعيل العرض المحاسبي في التقارير

### 📌 الخطوة 1: إضافة AccountingViewProvider إلى الشاشة

في أي شاشة تقرير، استخدم `Consumer` لقراءة حالة العرض:

```dart
import 'package:provider/provider.dart';
import 'package:accountant_touch/providers/accounting_view_provider.dart';

Widget build(BuildContext context) {
  return Consumer<AccountingViewProvider>(
    builder: (context, accountingProvider, child) {
      final showAccounting = accountingProvider.showAccountingView;

      // بناء UI حسب الإعداد
      return Column(
        children: [
          // عرض عادي (دائماً)
          _buildBasicSummary(),

          // عرض محاسبي (فقط إذا كان مفعّلاً)
          if (showAccounting) ...[
            _buildAccountingDetails(),
            _buildAccountBalances(),
          ],
        ],
      );
    },
  );
}
```

### 📌 الخطوة 2: استخدام AccountService لجلب البيانات المحاسبية

#### مثال: إضافة أرصدة الحسابات إلى تقرير الأرباح

**قبل** (`profit_report_screen.dart`):
```dart
// يعرض فقط: إجمالي الأرباح، المصاريف، المسحوبات، صافي الربح
```

**بعد** (مع التكامل المحاسبي):
```dart
import 'package:accountant_touch/services/account_service.dart';
import 'package:accountant_touch/providers/accounting_view_provider.dart';

class _ProfitReportScreenState extends State<ProfitReportScreen> {
  final accountService = AccountService.instance;

  // متغيرات للبيانات المحاسبية
  Account? cashAccount;
  Account? inventoryAccount;
  Decimal totalAssets = Decimal.zero;

  @override
  void initState() {
    super.initState();
    _loadAccountingData();
  }

  Future<void> _loadAccountingData() async {
    // جلب الحسابات
    cashAccount = await accountService.getCashAccount();
    inventoryAccount = await accountService.getInventoryAccount();

    // جلب الإحصائيات
    totalAssets = await accountService.getTotalAssets();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountingViewProvider>(
      builder: (context, accountingProvider, child) {
        return SingleChildScrollView(
          child: Column(
            children: [
              // ✅ العرض العادي (دائماً)
              _buildFinancialSummarySection(),

              // ✅ العرض المحاسبي (اختياري)
              if (accountingProvider.showAccountingView) ...[
                const Divider(height: 40),

                // قسم الحسابات
                _buildAccountingSection(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccountingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عنوان
            Row(
              children: [
                Icon(Icons.account_balance, color: AppColors.primaryLight),
                const SizedBox(width: 8),
                Text(
                  'التفاصيل المحاسبية',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // أرصدة الحسابات
            _buildAccountRow('الصندوق', cashAccount?.balance ?? Decimal.zero),
            _buildAccountRow('المخزون', inventoryAccount?.balance ?? Decimal.zero),

            const Divider(),

            // إجماليات
            _buildAccountRow(
              'إجمالي الأصول',
              totalAssets,
              isBold: true,
              color: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountRow(
    String label,
    Decimal amount, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            CurrencyService.instance.formatAmount(amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: isBold ? 18 : 16,
            ),
          ),
        ],
      ),
    );
  }
}
```

### 📌 الخطوة 3: إضافة قائمة القيود المحاسبية لعملية معينة

#### مثال: عرض القيود المحاسبية المرتبطة بمنتج معين

```dart
import 'package:accountant_touch/data/database_helper.dart';
import 'package:accountant_touch/data/models.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  List<Transaction> productTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadProductTransactions();
  }

  Future<void> _loadProductTransactions() async {
    // جلب جميع القيود المرتبطة بهذا المنتج
    final db = await DatabaseHelper.instance.database;
    final results = await db.query(
      'TB_Transactions',
      where: 'Description LIKE ?',
      whereArgs: ['%منتج #${widget.product.productID}%'],
      orderBy: 'TransactionDate DESC',
    );

    setState(() {
      productTransactions = results.map((row) => Transaction.fromMap(row)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountingViewProvider>(
      builder: (context, accountingProvider, child) {
        return Scaffold(
          appBar: AppBar(title: Text(widget.product.productName)),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // معلومات المنتج الأساسية
                _buildProductInfo(),

                // القيود المحاسبية (اختياري)
                if (accountingProvider.showAccountingView) ...[
                  const Divider(height: 40),
                  _buildAccountingEntriesSection(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountingEntriesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'القيود المحاسبية المرتبطة',
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 16),

            if (productTransactions.isEmpty)
              const Text('لا توجد قيود محاسبية'),

            ...productTransactions.map((transaction) => _buildTransactionCard(transaction)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          transaction.transactionType == 'income'
              ? Icons.arrow_downward
              : Icons.arrow_upward,
          color: transaction.transactionType == 'income'
              ? Colors.green
              : Colors.red,
        ),
        title: Text(transaction.description ?? ''),
        subtitle: Text(
          'مدين: ${transaction.debitAccountID} | دائن: ${transaction.creditAccountID}',
        ),
        trailing: Text(
          CurrencyService.instance.formatAmount(transaction.amount),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
```

### 📌 الخطوة 4: إضافة أزرار تصدير القوائم المالية

```dart
import 'package:accountant_touch/services/account_service.dart';

// في AppBar
actions: [
  Consumer<AccountingViewProvider>(
    builder: (context, accountingProvider, child) {
      if (!accountingProvider.showAccountingView) {
        return const SizedBox.shrink();
      }

      return PopupMenuButton<String>(
        icon: const Icon(Icons.analytics),
        tooltip: 'القوائم المالية',
        onSelected: (value) async {
          if (value == 'balance_sheet') {
            await _showBalanceSheet();
          } else if (value == 'income_statement') {
            await _showIncomeStatement();
          } else if (value == 'trial_balance') {
            await _showTrialBalance();
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'balance_sheet',
            child: Row(
              children: [
                Icon(Icons.account_balance),
                SizedBox(width: 8),
                Text('الميزانية العمومية'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'income_statement',
            child: Row(
              children: [
                Icon(Icons.attach_money),
                SizedBox(width: 8),
                Text('قائمة الدخل'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'trial_balance',
            child: Row(
              children: [
                Icon(Icons.balance),
                SizedBox(width: 8),
                Text('ميزان المراجعة'),
              ],
            ),
          ),
        ],
      );
    },
  ),
],

// الدوال
Future<void> _showBalanceSheet() async {
  final balanceSheet = await AccountService.instance.getBalanceSheet();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('الميزانية العمومية'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الأصول: ${balanceSheet['assets']}'),
            Text('الخصوم: ${balanceSheet['liabilities']}'),
            Text('حقوق الملكية: ${balanceSheet['equity']}'),
            const Divider(),
            Text(
              'التوازن: ${balanceSheet['balanced'] ? "✅ متوازن" : "❌ غير متوازن"}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: balanceSheet['balanced'] ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
      ],
    ),
  );
}
```

### 📌 ملخص الخطوات لأي تقرير

1. **Import المكتبات**:
   ```dart
   import 'package:provider/provider.dart';
   import 'package:accountant_touch/providers/accounting_view_provider.dart';
   import 'package:accountant_touch/services/account_service.dart';
   ```

2. **استخدام Consumer**:
   ```dart
   Consumer<AccountingViewProvider>(
     builder: (context, accountingProvider, child) {
       if (accountingProvider.showAccountingView) {
         // عرض التفاصيل المحاسبية
       }
     },
   )
   ```

3. **جلب البيانات من AccountService**:
   ```dart
   final cashBalance = await AccountService.instance.getCashAccount();
   final totalAssets = await AccountService.instance.getTotalAssets();
   ```

4. **عرض البيانات في UI**:
   ```dart
   if (accountingProvider.showAccountingView) {
     Column(
       children: [
         Text('رصيد الصندوق: ${cashBalance?.balance}'),
         Text('إجمالي الأصول: $totalAssets'),
       ],
     )
   }
   ```

---

## الأخطاء التي تم إصلاحها

### ❌ الخطأ 1: Missing 'quantity' Parameter

**الموقع**: `lib/screens/products/products_list_screen.dart:263-267`

**الخطأ**:
```dart
final accountingSuccess = await AccountingIntegrationHelper.recordProductDeletion(
  productId: product.productID!,
  costPrice: product.costPrice,
  deleteReason: deleteReason,
  // ❌ نسينا quantity
);
```

**الإصلاح**:
```dart
final accountingSuccess = await AccountingIntegrationHelper.recordProductDeletion(
  productId: product.productID!,
  quantity: product.quantity,  // ✅ تمت الإضافة
  costPrice: product.costPrice,
  deleteReason: deleteReason,
);
```

**Commit**: `fix: إضافة معامل quantity المفقود في recordProductDeletion`

---

### ❌ الخطأ 2: Database Creation Crash (CRITICAL)

**الموقع**: `lib/data/database_helper.dart:_onCreate`

**المشكلة**:
- في السطر 653: `await batch.commit();` → تم إغلاق الـ batch
- في السطر 1090: `batch.execute(...)` → محاولة استخدام batch مغلق ❌
- في السطر 1122: `await batch.commit();` → محاولة commit مرة ثانية ❌

**الخطأ الأصلي**:
```dart
await batch.commit();  // السطر 653

// ... 400 سطر ...

batch.execute('''  // السطر 1090 - ❌ خطأ
  CREATE TABLE IF NOT EXISTS TB_Accounts (...)
''');

await batch.commit();  // السطر 1122 - ❌ خطأ
```

**الإصلاح**:
```dart
await batch.commit();  // السطر 653

// ... 400 سطر ...

await db.execute('''  // السطر 1090 - ✅ صحيح
  CREATE TABLE IF NOT EXISTS TB_Accounts (...)
''');

// تم حذف batch.commit() الثاني
```

**Commit**: `fix: إصلاح خطأ batch.execute بعد batch.commit في _onCreate`

**التأثير**:
- قبل الإصلاح: التطبيق يتعطل عند التثبيت الأول
- بعد الإصلاح: التطبيق يعمل بنجاح من أول تثبيت

---

## 🎯 الخلاصة

تم بنجاح تحويل التطبيق من نظام محاسبي بسيط إلى نظام محاسبي متكامل يدعم:

✅ القيد المزدوج (Double-Entry)
✅ دليل حسابات شامل (12 حساب افتراضي)
✅ تكامل تلقائي مع عمليات المخزون
✅ Triggers تلقائية لتحديث الأرصدة
✅ ربط مع السنوات المالية
✅ تقارير محاسبية متقدمة
✅ خيار عرض بسيط/محاسبي
✅ واجهة مستخدم سهلة وجميلة

**الملفات المعدلة**: 6 ملفات
**الملفات الجديدة**: 4 ملفات
**الأسطر المضافة**: ~2000 سطر
**الأخطاء المصلحة**: 2 أخطاء حرجة
**Commits**: 4 commits

---

## 📞 للمساعدة

إذا كان لديك أي استفسار أو تحتاج لمساعدة في:
- إضافة حسابات جديدة
- تخصيص القيود المحاسبية
- إنشاء تقارير جديدة
- تفعيل العرض المحاسبي في تقارير أخرى

فقط أخبرني! 🚀
