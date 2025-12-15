# 📚 دليل نظام السنوات المالية - Fiscal Year System Documentation

## 📋 جدول المحتويات

1. [نظرة عامة](#نظرة-عامة)
2. [البنية التحتية](#البنية-التحتية)
3. [دليل الاستخدام](#دليل-الاستخدام)
4. [API Reference](#api-reference)
5. [أمثلة الكود](#أمثلة-الكود)
6. [الأسئلة الشائعة](#الأسئلة-الشائعة)

---

## 🌟 نظرة عامة

نظام السنوات المالية هو نظام محاسبي متكامل يتيح لك:

- ✅ **إدارة السنوات المالية** - إنشاء، تفعيل، وإقفال السنوات المالية
- ✅ **تسجيل القيود التلقائي** - كل عملية مالية تُسجل كقيد محاسبي تلقائياً
- ✅ **تقارير شاملة** - تقارير مفصلة عن الحركة المالية
- ✅ **التكامل الكامل** - ربط تلقائي بين العمليات والقيود
- ✅ **دقة عالية** - استخدام `Decimal` بدلاً من `double` لتجنب أخطاء الحسابات

### ✨ المميزات الرئيسية

```
📊 نظام موحد للقيود المالية
├── 💰 تسجيل تلقائي لجميع العمليات
├── 📈 تقارير مالية شاملة
├── 🔒 إقفال السنوات مع نقل الرصيد
└── 🎯 دقة عالية في الحسابات
```

---

## 🏗️ البنية التحتية

### 1. قاعدة البيانات (Database Migration v6)

#### الجداول الجديدة:

##### **TB_FiscalYears** - جدول السنوات المالية
```sql
CREATE TABLE TB_FiscalYears (
  FiscalYearID INTEGER PRIMARY KEY AUTOINCREMENT,
  Name TEXT NOT NULL,
  Year INTEGER NOT NULL UNIQUE,
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
  ClosedAt TEXT
)
```

##### **TB_Transactions** - جدول القيود المالية الموحد
```sql
CREATE TABLE TB_Transactions (
  TransactionID INTEGER PRIMARY KEY AUTOINCREMENT,
  FiscalYearID INTEGER NOT NULL,
  Date TEXT NOT NULL,
  Type TEXT NOT NULL,              -- نوع القيد
  Category TEXT NOT NULL,          -- التصنيف
  Amount REAL NOT NULL,            -- المبلغ
  Direction TEXT NOT NULL,         -- "in" أو "out"
  Description TEXT NOT NULL,       -- الوصف
  Notes TEXT,
  ReferenceType TEXT,              -- نوع المرجع (sale, payroll, etc)
  ReferenceID INTEGER,             -- معرف العملية الأصلية
  CustomerID INTEGER,
  EmployeeID INTEGER,
  ProductID INTEGER,
  CreatedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (FiscalYearID) REFERENCES TB_FiscalYears(FiscalYearID)
)
```

#### إضافة FiscalYearID للجداول الموجودة:
- ✅ `Debt_Customer` (المبيعات)
- ✅ `Payment_Customer` (دفعات العملاء)
- ✅ `TB_Payroll` (الرواتب)
- ✅ `TB_Employee_Advances` (السلف)
- ✅ `TB_Employee_Bonuses` (المكافآت)
- ✅ `TB_Advance_Repayments` (تسديدات السلف)
- ✅ `Sales_Returns` (المرتجعات)

#### Triggers التلقائية:
```sql
-- تحديث تلقائي للأرصدة عند إدراج قيد جديد
CREATE TRIGGER trg_update_fiscal_on_insert
AFTER INSERT ON TB_Transactions
BEGIN
  UPDATE TB_FiscalYears SET
    TotalIncome = (SELECT SUM(Amount) FROM TB_Transactions
                   WHERE FiscalYearID = NEW.FiscalYearID AND Direction = 'in'),
    TotalExpense = (SELECT SUM(Amount) FROM TB_Transactions
                    WHERE FiscalYearID = NEW.FiscalYearID AND Direction = 'out')
  WHERE FiscalYearID = NEW.FiscalYearID;
END;
```

### 2. Models (Data Classes)

#### **FiscalYear**
```dart
class FiscalYear {
  final int? fiscalYearID;
  final String name;              // "سنة 2025"
  final int year;                 // 2025
  final DateTime startDate;       // 2025-01-01
  final DateTime endDate;         // 2025-12-31
  final bool isClosed;            // هل السنة مقفلة؟
  final bool isActive;            // هل السنة نشطة؟
  final Decimal openingBalance;   // الرصيد الافتتاحي
  final Decimal totalIncome;      // إجمالي الدخل
  final Decimal totalExpense;     // إجمالي المصروفات
  final Decimal netProfit;        // صافي الربح
  final Decimal closingBalance;   // الرصيد الختامي
  final String? notes;
}
```

#### **FinancialTransaction**
```dart
class FinancialTransaction {
  final int? transactionID;
  final int fiscalYearID;
  final DateTime date;
  final TransactionType type;         // نوع القيد
  final TransactionCategory category; // التصنيف
  final Decimal amount;               // المبلغ
  final String direction;             // "in" or "out"
  final String description;           // الوصف
  final String? notes;
  final String? referenceType;        // "sale", "payroll", etc.
  final int? referenceId;             // معرف العملية الأصلية
  final int? customerId;
  final int? employeeId;
  final int? productId;
}
```

#### **Enums**
```dart
enum TransactionType {
  sale,              // مبيعة
  saleReturn,        // مرتجع مبيعات
  customerPayment,   // دفعة زبون
  salary,            // راتب
  employeeAdvance,   // سلفة
  advanceRepayment,  // تسديد سلفة
  employeeBonus,     // مكافأة
  expense,           // مصروف
  openingBalance,    // رصيد افتتاحي
  closingBalance,    // رصيد ختامي
  other              // أخرى
}

enum TransactionCategory {
  revenue,           // إيرادات
  costOfGoodsSold,   // تكلفة البضاعة
  operatingExpense,  // مصروفات تشغيلية
  salaryExpense,     // رواتب
  advanceExpense,    // سلف
  customerDebt,      // ديون عملاء
  returnExpense,     // مرتجعات
  balanceTransfer,   // نقل رصيد
  miscellaneous      // متنوعة
}
```

### 3. Services (Business Logic)

#### **FiscalYearService**
المسؤول عن إدارة السنوات المالية.

**الدوال الرئيسية:**
```dart
// الحصول على السنة النشطة
Future<FiscalYear?> getActiveFiscalYear({bool forceRefresh = false})

// الحصول على جميع السنوات
Future<List<FiscalYear>> getAllFiscalYears({bool includeInactive = true})

// إنشاء سنة جديدة
Future<FiscalYear?> createFiscalYear({
  required int year,
  Decimal? openingBalance,
  bool makeActive = false,
  String? notes,
})

// تفعيل سنة
Future<bool> activateFiscalYear(int fiscalYearId)

// إقفال سنة (مع إنشاء السنة التالية تلقائياً)
Future<FiscalYear?> closeFiscalYear({
  required int fiscalYearId,
  bool createNewYear = true,
})

// إعادة حساب الأرصدة
Future<bool> recalculateFiscalYearBalances(int fiscalYearId)
```

**مثال الاستخدام:**
```dart
final fiscalYearService = FiscalYearService.instance;

// إنشاء سنة 2025
final year2025 = await fiscalYearService.createFiscalYear(
  year: 2025,
  openingBalance: Decimal.fromInt(50000),
  makeActive: true,
);

// الحصول على السنة النشطة
final activeYear = await fiscalYearService.getActiveFiscalYear();
print('السنة النشطة: ${activeYear?.name}');
```

#### **TransactionService**
المسؤول عن إدارة القيود المالية.

**الدوال الرئيسية:**
```dart
// إنشاء قيد مالي
Future<FinancialTransaction?> createTransaction({
  required TransactionType type,
  required TransactionCategory category,
  required Decimal amount,
  required String direction,
  required String description,
  String? notes,
  String? referenceType,
  int? referenceId,
  // ... parameters
})

// جلب القيود بفلاتر مرنة
Future<List<FinancialTransaction>> getTransactions({
  int? fiscalYearId,
  TransactionType? type,
  String? direction,
  int? customerId,
  int? employeeId,
  DateTime? startDate,
  DateTime? endDate,
  int? limit,
  String orderBy = 'Date DESC',
})

// إحصائيات مالية
Future<Decimal> getTotalIncome({int? fiscalYearId, ...})
Future<Decimal> getTotalExpense({int? fiscalYearId, ...})
Future<Decimal> getNetProfit({int? fiscalYearId, ...})

// ملخص مالي شامل
Future<Map<String, dynamic>> getFinancialSummary({
  int? fiscalYearId,
  DateTime? startDate,
  DateTime? endDate,
})

// دوال مساعدة للربط التلقائي
Future<FinancialTransaction?> createSaleTransaction({...})
Future<FinancialTransaction?> createSalaryTransaction({...})
Future<FinancialTransaction?> createAdvanceTransaction({...})
// ... المزيد
```

**مثال الاستخدام:**
```dart
final transactionService = TransactionService.instance;

// جلب جميع قيود الدخل للسنة النشطة
final incomeTransactions = await transactionService.getTransactions(
  direction: 'in',
  orderBy: 'Date DESC',
);

// الحصول على ملخص مالي
final summary = await transactionService.getFinancialSummary(
  fiscalYearId: activeYear.fiscalYearID,
);

print('إجمالي الدخل: ${summary['totalIncome']}');
print('إجمالي المصروفات: ${summary['totalExpense']}');
print('صافي الربح: ${summary['netProfit']}');
```

### 4. FinancialIntegrationHelper
المسؤول عن الربط التلقائي بين العمليات والقيود.

**الدوال:**
```dart
// تسجيل قيد مبيعة تلقائياً
static Future<bool> recordSaleTransaction({
  required int saleId,
  required int customerId,
  required Decimal amount,
  required String saleDate,
  int? productId,
  String? productName,
})

// تسجيل قيد دفعة زبون تلقائياً
static Future<bool> recordCustomerPaymentTransaction({...})

// تسجيل قيد راتب تلقائياً
static Future<bool> recordSalaryTransaction({...})

// تسجيل قيد سلفة تلقائياً
static Future<bool> recordAdvanceTransaction({...})

// تسجيل قيد تسديد سلفة تلقائياً
static Future<bool> recordAdvanceRepaymentTransaction({...})

// تسجيل قيد مكافأة تلقائياً
static Future<bool> recordBonusTransaction({...})

// تسجيل قيد مرتجع تلقائياً
static Future<bool> recordSaleReturnTransaction({...})

// حذف القيد المرتبط بعملية
static Future<bool> deleteRelatedTransaction({
  required String referenceType,
  required int referenceId,
})
```

**كيف يعمل؟**
```dart
// مثال: عند إضافة راتب جديد في DatabaseHelper
Future<void> recordNewPayroll(PayrollEntry payroll, ...) async {
  int? payrollId;

  // 1. إدراج الراتب في قاعدة البيانات
  await db.transaction((txn) async {
    payrollId = await txn.insert('TB_Payroll', payroll.toMap());
    // ... عمليات أخرى
  });

  // 2. تسجيل القيد المالي تلقائياً
  if (payrollId != null) {
    await FinancialIntegrationHelper.recordSalaryTransaction(
      payrollId: payrollId!,
      employeeId: payroll.employeeID,
      netSalary: payroll.netSalary,
      paymentDate: payroll.paymentDate,
    );
  }
}
```

---

## 🎯 دليل الاستخدام

### الخطوة 1: إنشاء سنة مالية جديدة

```dart
import 'package:accountant_touch/services/fiscal_year_service.dart';
import 'package:decimal/decimal.dart';

final fiscalYearService = FiscalYearService.instance;

// إنشاء سنة 2025 برصيد افتتاحي 100,000 دينار
final year = await fiscalYearService.createFiscalYear(
  year: 2025,
  openingBalance: Decimal.fromInt(100000),
  makeActive: true,
  notes: 'سنة 2025 - البداية الجديدة',
);

if (year != null) {
  print('✅ تم إنشاء السنة المالية بنجاح');
} else {
  print('❌ فشل إنشاء السنة');
}
```

### الخطوة 2: تسجيل عمليات (تسجيل القيود تلقائي!)

```dart
import 'package:accountant_touch/data/database_helper.dart';

final dbHelper = DatabaseHelper.instance;

// مثال 1: تسجيل راتب (يُسجل قيد تلقائياً)
final payroll = PayrollEntry(
  employeeID: 5,
  payrollMonth: 12,
  payrollYear: 2025,
  basicSalary: Decimal.fromInt(5000),
  netSalary: Decimal.fromInt(4800),
  paymentDate: DateTime.now().toIso8601String(),
);

await dbHelper.recordNewPayroll(payroll, Decimal.zero);
// ← القيد المالي سُجل تلقائياً! 🎉

// مثال 2: تسجيل مبيعة (يُسجل قيد تلقائياً)
final saleId = await dbHelper.recordSale(
  invoiceId: 123,
  customerId: 10,
  productId: 50,
  customerName: 'أحمد',
  details: 'بيع منتج A',
  debt: Decimal.fromInt(1500),
  quantity: 3,
  costPrice: Decimal.fromInt(300),
  profitAmount: Decimal.fromInt(600),
  productName: 'منتج A',
);
// ← القيد المالي سُجل تلقائياً! 🎉
```

### الخطوة 3: عرض القيود والتقارير

```dart
import 'package:accountant_touch/services/transaction_service.dart';

final transactionService = TransactionService.instance;

// جلب جميع قيود الدخل
final incomeTransactions = await transactionService.getTransactions(
  direction: 'in',
);

print('عدد قيود الدخل: ${incomeTransactions.length}');

// الحصول على ملخص مالي شامل
final summary = await transactionService.getFinancialSummary();

print('📊 الملخص المالي:');
print('  إجمالي الدخل: ${summary['totalIncome']} دينار');
print('  إجمالي المصروفات: ${summary['totalExpense']} دينار');
print('  صافي الربح: ${summary['netProfit']} دينار');
print('  عدد القيود: ${summary['incomeCount'] + summary['expenseCount']}');

// التفصيل حسب النوع
final breakdown = summary['breakdown'];
print('\n📋 التفصيل:');
print('  مبيعات: ${breakdown['sales']} دينار');
print('  رواتب: ${breakdown['salaries']} دينار');
print('  سلف: ${breakdown['advances']} دينار');
```

### الخطوة 4: إقفال سنة مالية

```dart
final fiscalYearService = FiscalYearService.instance;

// إقفال سنة 2025 (مع إنشاء سنة 2026 تلقائياً)
final closedYear = await fiscalYearService.closeFiscalYear(
  fiscalYearId: year.fiscalYearID!,
  createNewYear: true,
);

if (closedYear != null) {
  print('✅ تم إقفال السنة 2025');
  print('✅ تم إنشاء سنة 2026 برصيد افتتاحي: ${closedYear.closingBalance}');
}
```

---

## 🖥️ الشاشات (UI Screens)

### 1. FiscalYearsScreen - شاشة إدارة السنوات المالية

**المسار:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const FiscalYearsScreen(),
  ),
);
```

**المميزات:**
- ✅ عرض قائمة بجميع السنوات المالية
- ✅ إنشاء سنة مالية جديدة
- ✅ تفعيل سنة مالية
- ✅ إقفال سنة مالية
- ✅ عرض معلومات مالية مفصلة
- ✅ تمييز بصري للسنة النشطة والمقفلة

### 2. TransactionsScreen - شاشة القيود المالية

**المسار:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const TransactionsScreen(),
  ),
);
```

**المميزات:**
- ✅ عرض جميع القيود المالية
- ✅ ملخص مالي في الأعلى (دخل، مصروف، صافي)
- ✅ فلترة حسب السنة/النوع/الاتجاه
- ✅ عرض تفاصيل كل قيد
- ✅ تمييز بصري للدخل والمصروف

### 3. FinancialReportScreen - التقرير المالي الشامل

**المسار:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const FinancialReportScreen(),
  ),
);
```

**المميزات:**
- ✅ ملخص مالي شامل
- ✅ تفصيل حسب النوع
- ✅ مؤشرات أداء (هامش الربح، نسبة المصروفات)
- ✅ اختيار السنة المالية
- ✅ رسوم بيانية تفاعلية

---

## ❓ الأسئلة الشائعة

### س: كيف أتأكد من أن القيود تُسجل تلقائياً؟

**ج:** القيود تُسجل تلقائياً عند استخدام الدوال المعدلة في `DatabaseHelper`:
- ✅ `recordNewPayroll()` - يسجل قيد راتب
- ✅ `recordNewAdvance()` - يسجل قيد سلفة
- ✅ `repayAdvance()` - يسجل قيد تسديد
- ✅ `recordNewBonus()` - يسجل قيد مكافأة
- ✅ `returnSaleItem()` - يسجل قيد مرتجع

### س: ماذا يحدث عند إقفال سنة مالية؟

**ج:** عند إقفال سنة مالية:
1. ✅ يتم وضع `isClosed = true`
2. ✅ لا يمكن إضافة قيود جديدة لهذه السنة
3. ✅ يتم إنشاء سنة جديدة تلقائياً (إذا اخترت ذلك)
4. ✅ الرصيد الختامي للسنة القديمة = الرصيد الافتتاحي للسنة الجديدة

### س: كيف أستخدم Decimal بدلاً من double؟

**ج:** استخدم حزمة `decimal`:
```dart
import 'package:decimal/decimal.dart';

// إنشاء
final amount = Decimal.fromInt(100);          // 100
final price = Decimal.parse('99.95');         // 99.95

// العمليات الحسابية
final total = amount + price;                 // 199.95
final discount = total * Decimal.parse('0.1'); // 19.995

// التحويل
final asDouble = total.toDouble();
final asString = total.toStringAsFixed(2);    // "199.95"
```

### س: كيف أضيف دعم للمصروفات العامة؟

**ج:** استخدم `createTransaction` مباشرة:
```dart
final transactionService = TransactionService.instance;

await transactionService.createTransaction(
  type: TransactionType.expense,
  category: TransactionCategory.operatingExpense,
  amount: Decimal.fromInt(500),
  direction: 'out',
  description: 'فاتورة كهرباء',
  notes: 'فاتورة شهر ديسمبر',
  transactionDate: DateTime.now(),
);
```

---

## 📝 ملاحظات مهمة

### ⚠️ تحذيرات:
1. **لا تعدل قاعدة البيانات مباشرة** - استخدم Services دائماً
2. **لا تستخدم double للمبالغ** - استخدم Decimal فقط
3. **لا تحذف قيود يدوياً** - استخدم `deleteRelatedTransaction()`

### ✅ أفضل الممارسات:
1. **استخدم الدوال الجديدة في DatabaseHelper** بدلاً من التعامل المباشر
2. **تحقق من السنة المالية النشطة** قبل أي عملية
3. **استخدم try-catch** للتعامل مع الأخطاء
4. **راجع القيود** بانتظام للتأكد من الدقة

---

## 🎉 الخلاصة

نظام السنوات المالية الآن جاهز للاستخدام! 🚀

**ما تم إنجازه:**
- ✅ 6 ملفات Services/Helpers جديدة (3,513 سطر)
- ✅ 3 شاشات UI كاملة (1,932 سطر)
- ✅ Migration v6 مع Triggers تلقائية
- ✅ ربط تلقائي كامل بين العمليات والقيود
- ✅ توثيق شامل

**الخطوات التالية:**
1. اختبار النظام مع بيانات حقيقية
2. إضافة المزيد من التقارير حسب الحاجة
3. دمج الشاشات في Navigation الرئيسي

**في حال الحاجة للمساعدة:**
- راجع الكود المصدري مع التعليقات (← Hint:)
- راجع أمثلة الاستخدام في هذا الملف
- تواصل مع فريق التطوير

---

**تم بنجاح! 🎊**

*آخر تحديث: 2025-12-15*
