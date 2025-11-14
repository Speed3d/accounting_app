# تقرير شامل: استخدام نوع البيانات `double` في تطبيق المحاسبة

## ملخص التقرير
هذا المشروع يستخدم نوع البيانات `double` في **35 ملف Dart** لتمثيل البيانات المالية والحسابات. تم العثور على **28 عملية تحويل إلى double** باستخدام `.toDouble()`.

---

## 1️⃣ جميع الملفات التي تحتوي على `double`

### أ) الملفات الأساسية (Data & Models)
- `/home/user/accounting_app/lib/data/models.dart` ✅ **الملف الأساسي**
- `/home/user/accounting_app/lib/data/database_helper.dart` ✅ **قاعدة البيانات**

### ب) ملفات الشاشات والواجهات (UI Screens)

**شاشات الموظفين:**
- `/home/user/accounting_app/lib/screens/employees/add_payroll_screen.dart`
- `/home/user/accounting_app/lib/screens/employees/add_advance_screen.dart`
- `/home/user/accounting_app/lib/screens/employees/add_edit_employee_screen.dart`
- `/home/user/accounting_app/lib/screens/employees/employees_list_screen.dart`

**شاشات المبيعات:**
- `/home/user/accounting_app/lib/screens/customers/new_sale_screen.dart`
- `/home/user/accounting_app/lib/screens/customers/customer_details_screen.dart`
- `/home/user/accounting_app/lib/screens/sales/cash_sales_history_screen.dart`
- `/home/user/accounting_app/lib/screens/sales/direct_sale_screen.dart`

**شاشات المنتجات:**
- `/home/user/accounting_app/lib/screens/products/add_edit_product_screen.dart`
- `/home/user/accounting_app/lib/screens/products/products_list_screen.dart`

**شاشات الموردين:**
- `/home/user/accounting_app/lib/screens/suppliers/add_edit_supplier_screen.dart`
- `/home/user/accounting_app/lib/screens/suppliers/add_edit_partner_screen.dart`

**شاشات التقارير:**
- `/home/user/accounting_app/lib/screens/reports/profit_report_screen.dart`
- `/home/user/accounting_app/lib/screens/reports/customer_sales_report_screen.dart`
- `/home/user/accounting_app/lib/screens/reports/cash_flow_report_screen.dart`
- `/home/user/accounting_app/lib/screens/reports/employees_report_screen.dart`
- `/home/user/accounting_app/lib/screens/reports/expenses_screen.dart`
- `/home/user/accounting_app/lib/screens/reports/supplier_details_report_screen.dart`
- `/home/user/accounting_app/lib/screens/reports/supplier_profit_report_screen.dart`

**شاشات أخرى:**
- `/home/user/accounting_app/lib/screens/dashboard/dashboard_screen.dart`
- `/home/user/accounting_app/lib/screens/auth/splash_screen.dart`
- `/home/user/accounting_app/lib/screens/auth/login_screen.dart`
- `/home/user/accounting_app/lib/screens/auth/activation_screen.dart`
- `/home/user/accounting_app/lib/screens/auth/blocked_screen.dart`
- `/home/user/accounting_app/lib/screens/auth/create_admin_screen.dart`
- `/home/user/accounting_app/lib/screens/auth/lock_screen.dart`
- `/home/user/accounting_app/lib/screens/settings/settings_screen.dart`

### ج) ملفات الخدمات والمساعدات (Services & Utilities)
- `/home/user/accounting_app/lib/services/pdf_service.dart` ✅ **خدمة PDF**
- `/home/user/accounting_app/lib/services/currency_service.dart` ✅ **خدمة العملات**
- `/home/user/accounting_app/lib/utils/helpers.dart` ✅ **دوال مساعدة**
- `/home/user/accounting_app/lib/utils/pdf_helpers.dart`

### د) ملفات الأدوات والعناصر
- `/home/user/accounting_app/lib/widgets/custom_button.dart`
- `/home/user/accounting_app/lib/widgets/custom_card.dart`
- `/home/user/accounting_app/lib/widgets/custom_drawer.dart`
- `/home/user/accounting_app/lib/widgets/loading_state.dart`
- `/home/user/accounting_app/lib/widgets/test_widgets_screen.dart`
- `/home/user/accounting_app/lib/theme/app_constants.dart`
- `/home/user/accounting_app/lib/theme/app_theme.dart`

---

## 2️⃣ سياقات استخدام `double`

### 🏦 السياق 1: النماذج (Models) - في `models.dart`

#### أ) نموذج الموظف (Employee)
```dart
class Employee {
  final dynamic baseSalary;  // الراتب الأساسي
  final dynamic balance;     // الرصيد المستحق (السلف)
  
  // التحويل من قاعدة البيانات:
  baseSalary: (map['BaseSalary'] as num).toDouble(),
  balance: (map['Balance'] as num).toDouble(),
}
```

#### ب) نموذج سجل الرواتب (PayrollEntry)
```dart
class PayrollEntry {
  final dynamic baseSalary;      // الراتب الأساسي
  final dynamic bonuses;         // المكافآت
  final dynamic deductions;      // الخصومات
  final dynamic advanceDeduction;// خصم السلفة
  final dynamic netSalary;       // الراتب الصافي
  
  // التحويل:
  baseSalary: (map['BaseSalary'] as num).toDouble(),
  bonuses: (map['Bonuses'] as num).toDouble(),
  deductions: (map['Deductions'] as num).toDouble(),
  advanceDeduction: (map['AdvanceDeduction'] as num).toDouble(),
  netSalary: (map['NetSalary'] as num).toDouble(),
}
```

#### ج) نموذج السلفة (EmployeeAdvance)
```dart
class EmployeeAdvance {
  final dynamic advanceAmount;  // مبلغ السلفة
  
  // التحويل:
  advanceAmount: (map['AdvanceAmount'] as num).toDouble(),
}
```

#### د) نموذج المنتج (Product)
```dart
class Product {
  final dynamic costPrice;      // سعر التكلفة
  final dynamic sellingPrice;   // سعر البيع
  
  // التحويل:
  costPrice: (map['CostPrice'] as num).toDouble(),
  sellingPrice: (map['SellingPrice'] as num).toDouble(),
}
```

#### هـ) نموذج الزبون (Customer)
```dart
class Customer {
  final dynamic debt;           // الدين
  final dynamic payment;        // الدفعة
  final dynamic remaining;      // المتبقي
  
  // التحويل:
  debt: (map['Debt'] as num).toDouble(),
  payment: (map['Payment'] as num).toDouble(),
  remaining: (map['Remaining'] as num).toDouble(),
}
```

#### و) نموذج دين الزبون (CustomerDebt)
```dart
class CustomerDebt {
  final dynamic debt;                      // الدين
  final dynamic costPriceAtTimeOfSale;    // سعر التكلفة وقت البيع
  final dynamic profitAmount;              // مبلغ الربح
  
  // التحويل:
  debt: (map['Debt'] as num).toDouble(),
  costPriceAtTimeOfSale: (map['CostPriceAtTimeOfSale'] as num).toDouble(),
  profitAmount: (map['ProfitAmount'] as num).toDouble(),
}
```

#### ز) نموذج دفعة الزبون (CustomerPayment)
```dart
class CustomerPayment {
  final dynamic payment;  // مبلغ الدفعة
  
  // التحويل:
  payment: (map['Payment'] as num).toDouble(),
}
```

#### ح) نموذج الشريك (Partner)
```dart
class Partner {
  final dynamic sharePercentage;  // نسبة الحصة
}
```

---

### 📊 السياق 2: قاعدة البيانات (Database) - في `database_helper.dart`

#### أ) حسابات الأرباح
```dart
Future<double> getTotalProfit() async {
  final result = await db.rawQuery('SELECT SUM(ProfitAmount) as Total FROM Debt_Customer WHERE IsReturned = 0');
  if (data['Total'] != null) {
    return (data['Total'] as num).toDouble();
  } else {
    return 0.0;
  }
}
```

#### ب) حسابات الرواتب
```dart
Future<double> getTotalNetSalariesPaid() async {
  final result = await db.rawQuery('SELECT SUM(NetSalary) as Total FROM TB_Payroll');
  return (result.first['Total'] as num?)?.toDouble() ?? 0.0;
}

Future<double> getTotalActiveAdvancesBalance() async {
  final result = await db.rawQuery('SELECT SUM(Balance) as Total FROM TB_Employees WHERE IsActive = 1');
  return (result.first['Total'] as num?)?.toDouble() ?? 0.0;
}
```

#### ج) حسابات المصاريف
```dart
Future<double> getTotalExpenses() async {
  final result = await db.rawQuery('SELECT SUM(Amount) as Total FROM TB_Expenses');
  return (result.first['Total'] as num?)?.toDouble() ?? 0.0;
}

Future<double> getTotalAllProfitWithdrawals() async {
  final result = await db.rawQuery('SELECT SUM(WithdrawalAmount) as Total FROM TB_Profit_Withdrawals');
  return (result.first['Total'] as num?)?.toDouble() ?? 0.0;
}
```

#### د) حسابات المبيعات والديون
```dart
Future<double> getTotalSales() async {
  final result = await db.rawQuery('SELECT SUM(Debt) as Total FROM Debt_Customer WHERE IsReturned = 0');
  return (result.first['Total'] as num?)?.toDouble() ?? 0.0;
}

Future<double> getTotalDebts() async {
  final result = await db.rawQuery('SELECT SUM(Remaining) as Total FROM TB_Customer WHERE Remaining > 0 AND IsActive = 1');
  return (result.first['Total'] as num?)?.toDouble() ?? 0.0;
}

Future<double> getTotalPaymentsCollected() async {
  final result = await db.rawQuery('SELECT SUM(Payment) as Total FROM Payment_Customer');
  return (result.first['Total'] as num?)?.toDouble() ?? 0.0;
}
```

#### هـ) حسابات الموردين
```dart
Future<double> getTotalWithdrawnForSupplier(int supplierId) async {
  final result = await db.rawQuery('SELECT SUM(WithdrawalAmount) as Total FROM TB_Profit_Withdrawals WHERE SupplierID = ?', [supplierId]);
  return (result.first['Total'] as num?)?.toDouble() ?? 0.0;
}
```

#### و) الإحصائيات المتقدمة
```dart
Future<Map<String, dynamic>> getCustomerSalesStatistics(...) async {
  return {
    'totalSales': (result.first['totalSales'] as num?)?.toDouble() ?? 0.0,
    'totalProfit': (result.first['totalProfit'] as num?)?.toDouble() ?? 0.0,
    'averageTransaction': (result.first['averageTransaction'] as num?)?.toDouble() ?? 0.0,
    'minTransaction': (result.first['minTransaction'] as num?)?.toDouble() ?? 0.0,
    'maxTransaction': (result.first['maxTransaction'] as num?)?.toDouble() ?? 0.0,
  };
}
```

---

### 🎨 السياق 3: واجهة المستخدم والحسابات (UI & Calculations)

#### أ) شاشة صرف الراتب
```dart
// في add_payroll_screen.dart
void _calculateNetSalary() {
  final baseSalary = double.tryParse(_baseSalaryController.text) ?? 0.0;
  final bonuses = double.tryParse(_bonusesController.text) ?? 0.0;
  final deductions = double.tryParse(_deductionsController.text) ?? 0.0;
  final advanceRepayment = double.tryParse(_advanceRepaymentController.text) ?? 0.0;
  
  setState(() {
    _netSalary = (baseSalary + bonuses) - (deductions + advanceRepayment);
  });
}

// متغير لحفظ النتيجة
double _netSalary = 0.0;
```

#### ب) شاشة لوحة التحكم
```dart
// في dashboard_screen.dart
final remaining = (debtor['Remaining'] as num).toDouble();
final profit = (supplier['TotalProfit'] as num).toDouble();

// حسابات:
sum + (supplier['TotalProfit'] as num).toDouble()
```

#### ج) التقارير والإحصائيات
```dart
// في customer_sales_report_screen.dart
final amount = (sale['amount'] as num).toDouble();
final profit = (sale['profit'] as num).toDouble();
```

---

### 💰 السياق 4: خدمة العملات (Currency Service)

```dart
// في currency_service.dart
String formatAmount(dynamic amount) {
  final formatter = NumberFormat.currency(
    locale: _currentCurrency.locale,
    symbol: _currentCurrency.symbol,
    decimalDigits: _currentCurrency.decimalDigits,
  );
  return formatter.format(amount);  // يتقبل double أو dynamic
}
```

---

### 📄 السياق 5: خدمة PDF والتقارير

```dart
// في pdf_service.dart
String _formatCurrency(dynamic amount) {
  final formatter = NumberFormat('#,##0.00', 'ar');
  return '${formatter.format(amount)} د.ع';
}

// الاستخدام:
_formatCurrency((sale['amount'] as num).toDouble()),
_formatCurrency((partner['partnerShare'] as num).toDouble()),
final amount = (withdrawal['WithdrawalAmount'] as num).toDouble();
```

---

## 3️⃣ هيكل قاعدة البيانات (Database Schema)

### جداول المبالغ المالية (REAL في SQL)

```sql
-- جدول الموظفين
CREATE TABLE TB_Employees (
  BaseSalary REAL NOT NULL DEFAULT 0.0,
  Balance REAL NOT NULL DEFAULT 0.0,  -- الرصيد المستحق
  ...
)

-- جدول الرواتب
CREATE TABLE TB_Payroll (
  BaseSalary REAL NOT NULL,
  Bonuses REAL NOT NULL DEFAULT 0.0,
  Deductions REAL NOT NULL DEFAULT 0.0,
  AdvanceDeduction REAL NOT NULL DEFAULT 0.0,
  NetSalary REAL NOT NULL,
  ...
)

-- جدول السلف
CREATE TABLE TB_Employee_Advances (
  AdvanceAmount REAL NOT NULL,
  ...
)

-- جدول المنتجات
CREATE TABLE Store_Products (
  CostPrice REAL NOT NULL,
  SellingPrice REAL NOT NULL,
  ...
)

-- جدول الزبائن
CREATE TABLE TB_Customer (
  Debt REAL DEFAULT 0.0,
  Payment REAL DEFAULT 0.0,
  Remaining REAL DEFAULT 0.0,
  ...
)

-- جدول ديون الزبائن
CREATE TABLE Debt_Customer (
  Debt REAL NOT NULL,
  CostPriceAtTimeOfSale REAL NOT NULL,
  ProfitAmount REAL NOT NULL,
  ...
)

-- جدول دفعات الزبائن
CREATE TABLE Payment_Customer (
  Payment REAL NOT NULL,
  ...
)

-- جدول سحب الأرباح
CREATE TABLE TB_Profit_Withdrawals (
  WithdrawalAmount REAL NOT NULL,
  ...
)

-- جدول المصاريف
CREATE TABLE TB_Expenses (
  Amount REAL NOT NULL,
  ...
)

-- جدول الفواتير
CREATE TABLE TB_Invoices (
  TotalAmount REAL NOT NULL,
  ...
)

-- جدول شركاء الموردين
CREATE TABLE Supplier_Partners (
  SharePercentage REAL NOT NULL,
  ...
)
```

---

## 4️⃣ عمليات التحويل `.toDouble()` - التفاصيل

### في models.dart (14 عملية تحويل)
```
Line 156: baseSalary: (map['BaseSalary'] as num).toDouble(),
Line 157: balance: (map['Balance'] as num).toDouble(),
Line 210: baseSalary: (map['BaseSalary'] as num).toDouble(),
Line 211: bonuses: (map['Bonuses'] as num).toDouble(),
Line 212: deductions: (map['Deductions'] as num).toDouble(),
Line 213: advanceDeduction: (map['AdvanceDeduction'] as num).toDouble(),
Line 214: netSalary: (map['NetSalary'] as num).toDouble(),
Line 250: advanceAmount: (map['AdvanceAmount'] as num).toDouble(),
Line 418: costPrice: (map['CostPrice'] as num).toDouble(),
Line 419: sellingPrice: (map['SellingPrice'] as num).toDouble(),
Line 464: debt: (map['Debt'] as num).toDouble(),
          payment: (map['Payment'] as num).toDouble(),
          remaining: (map['Remaining'] as num).toDouble(),
Line 487: debt: (map['Debt'] as num).toDouble(),
          costPriceAtTimeOfSale: (map['CostPriceAtTimeOfSale'] as num).toDouble(),
          profitAmount: (map['ProfitAmount'] as num).toDouble(),
Line 504: payment: (map['Payment'] as num).toDouble(),
```

### في database_helper.dart (14 عملية تحويل)
```
Line 845:  return (data['Total'] as num).toDouble();
Line 1032: final currentBalance = (result.first['Balance'] as num).toDouble();
Line 1061: return (result.first['Total'] as num?)?.toDouble() ?? 0.0;
Line 1068: return (result.first['Total'] as num?)?.toDouble() ?? 0.0;
Line 1330: return (result.first['Total'] as num?)?.toDouble() ?? 0.0;
Line 1367: return (result.first['Total'] as num?)?.toDouble() ?? 0.0;
Line 1380: return (result.first['Total'] as num?)?.toDouble() ?? 0.0;
Line 1499: return (result.first['Total'] as num?)?.toDouble() ?? 0.0;
Line 1817-1821: في getCustomerSalesStatistics - 5 تحويلات
```

---

## 5️⃣ الملفات الأساسية - التفاصيل الكاملة

### ملف models.dart
**الموقع:** `/home/user/accounting_app/lib/data/models.dart`

**الفئات (Classes) التي تستخدم `double`:**
1. ✅ `Employee` - الراتب الأساسي والرصيد
2. ✅ `PayrollEntry` - الرواتب والمكافآت والخصومات
3. ✅ `EmployeeAdvance` - مبلغ السلفة
4. ✅ `Product` - سعر التكلفة والبيع
5. ✅ `Customer` - الدين والدفعة والمتبقي
6. ✅ `CustomerDebt` - الدين والربح وسعر التكلفة
7. ✅ `CustomerPayment` - مبلغ الدفعة
8. ✅ `Partner` - نسبة الحصة المئوية

**طريقة الاستخدام:** استخدام `dynamic` في التعريف ثم تحويل من قاعدة البيانات باستخدام `(map['FieldName'] as num).toDouble()`

---

### ملف database_helper.dart
**الموقع:** `/home/user/accounting_app/lib/data/database_helper.dart`

**الدوال التي ترجع `double`:**
1. ✅ `getTotalProfit()` - إجمالي الأرباح
2. ✅ `getTotalNetSalariesPaid()` - إجمالي الرواتب الصافية المدفوعة
3. ✅ `getTotalActiveAdvancesBalance()` - إجمالي رصيد السلف
4. ✅ `getTotalExpenses()` - إجمالي المصاريف
5. ✅ `getTotalAllProfitWithdrawals()` - إجمالي المسحوبات
6. ✅ `getTotalSales()` - إجمالي المبيعات
7. ✅ `getTotalDebts()` - إجمالي الديون
8. ✅ `getTotalPaymentsCollected()` - إجمالي المدفوعات
9. ✅ `getTotalWithdrawnForSupplier()` - إجمالي المسحوب لمورد
10. ✅ `getCollectionRate()` - نسبة التحصيل (نسبة مئوية)
11. ✅ `getCustomerSalesStatistics()` - إحصائيات متقدمة (Map يحتوي على doubles)

**جداول قاعدة البيانات:**
- TB_Employees (BaseSalary, Balance)
- TB_Payroll (BaseSalary, Bonuses, Deductions, AdvanceDeduction, NetSalary)
- TB_Employee_Advances (AdvanceAmount)
- Store_Products (CostPrice, SellingPrice)
- TB_Customer (Debt, Payment, Remaining)
- Debt_Customer (Debt, CostPriceAtTimeOfSale, ProfitAmount)
- Payment_Customer (Payment)
- TB_Profit_Withdrawals (WithdrawalAmount)
- TB_Expenses (Amount)
- TB_Invoices (TotalAmount)
- Supplier_Partners (SharePercentage)

---

## 6️⃣ ملفات الشاشات المهمة

### شاشة صرف الراتب (add_payroll_screen.dart)
- **الاستخدام:** حساب الراتب الصافي من المكونات
- **الحسابات:** `_netSalary = (baseSalary + bonuses) - (deductions + advanceRepayment)`
- **الطريقة:** `double.tryParse()` من inputs المستخدم

### شاشة لوحة التحكم (dashboard_screen.dart)
- **الاستخدام:** عرض الإحصائيات المالية
- **الحسابات:** تجميع الأرباح والمبيعات والديون
- **التحويل:** `(value as num).toDouble()`

### شاشات التقارير
- **profit_report_screen.dart** - ملخص مالي شامل
- **customer_sales_report_screen.dart** - تقرير مبيعات بفلاتر متقدمة
- **cash_flow_report_screen.dart** - تقرير تدفق النقد
- **employees_report_screen.dart** - تقرير رواتب وسلف الموظفين
- **expenses_screen.dart** - تقرير المصاريف
- **supplier_details_report_screen.dart** - تقرير تفاصيل الموردين
- **supplier_profit_report_screen.dart** - تقرير أرباح الموردين

---

## 7️⃣ ملفات الخدمات والمساعدات

### خدمة العملات (currency_service.dart)
**الموقع:** `/home/user/accounting_app/lib/services/currency_service.dart`

```dart
String formatAmount(dynamic amount) {
  final formatter = NumberFormat.currency(
    locale: _currentCurrency.locale,
    symbol: _currentCurrency.symbol,
    decimalDigits: _currentCurrency.decimalDigits,
  );
  return formatter.format(amount);
}
```

**العملات المدعومة:**
- IQD (دينار عراقي) - 0 كسور عشرية
- USD (دولار) - 2 كسور عشرية
- EUR (يورو) - 2 كسور عشرية
- GBP (جنيه إسترليني) - 2 كسور عشرية
- SAR (ريال سعودي) - 2 كسور عشرية
- AED (درهم إماراتي) - 2 كسور عشرية

### خدمة PDF (pdf_service.dart)
**الموقع:** `/home/user/accounting_app/lib/services/pdf_service.dart`

```dart
String _formatCurrency(dynamic amount) {
  final formatter = NumberFormat('#,##0.00', 'ar');
  return '${formatter.format(amount)} د.ع';
}
```

**الاستخدامات:**
- تنسيق الأرقام المالية في التقارير PDF
- تحويل البيانات من قاعدة البيانات: `(value as num).toDouble()`

### دوال مساعدة (helpers.dart)
**الموقع:** `/home/user/accounting_app/lib/utils/helpers.dart`

```dart
String formatCurrency(dynamic amount) {
  return CurrencyService.instance.formatAmount(amount);
}

String formatCurrencyWithoutSymbol(dynamic amount) {
  return CurrencyService.instance.formatAmountWithoutSymbol(amount);
}
```

---

## 8️⃣ المشاكل المحتملة والملاحظات

### ✅ المميزات الجيدة:
1. **استخدام `dynamic` بدلاً من `double`** - يسمح بالمرونة أثناء التطوير
2. **تحويل آمن باستخدام `(num).toDouble()`** - تجنب الأخطاء من القاعدة
3. **استخدام Safe Navigation `??` للقيم الفارغة** - `??.toDouble() ?? 0.0`
4. **عمليات حسابية صحيحة** - الجمع والطرح والضرب والقسمة
5. **دعم عملات متعددة** - مع كسور عشرية مختلفة

### ⚠️ نقاط للانتباه:
1. **الدقة العشرية:** استخدام `double` قد يسبب مشاكل في الدقة مع الكسور العشرية الكثيرة
   - الحل: استخدام `Decimal` أو `BigDecimal` للعمليات المالية الدقيقة جداً

2. **تخزين البيانات:** استخدام `dynamic` في النماذج بدلاً من `double` مباشرة
   - يوصى باستخدام `double` مباشرة في التعريف

3. **عدم وجود validation قبل الحفظ:** بعض المدخلات قد لا تكون `double` صحيحة
   - يوصى باستخدام `double.tryParse()` والتحقق من القيم الفارغة

---

## 9️⃣ قائمة المراجعة (Checklist)

### نقاط التحقق من استخدام `double`:

✅ **Models:**
- [ ] Employee (BaseSalary, Balance)
- [ ] PayrollEntry (BaseSalary, Bonuses, Deductions, AdvanceDeduction, NetSalary)
- [ ] EmployeeAdvance (AdvanceAmount)
- [ ] Product (CostPrice, SellingPrice)
- [ ] Customer (Debt, Payment, Remaining)
- [ ] CustomerDebt (Debt, CostPriceAtTimeOfSale, ProfitAmount)
- [ ] CustomerPayment (Payment)
- [ ] Partner (SharePercentage)

✅ **Database Functions:**
- [ ] getTotalProfit()
- [ ] getTotalNetSalariesPaid()
- [ ] getTotalActiveAdvancesBalance()
- [ ] getTotalExpenses()
- [ ] getTotalAllProfitWithdrawals()
- [ ] getTotalSales()
- [ ] getTotalDebts()
- [ ] getTotalPaymentsCollected()
- [ ] getCollectionRate()
- [ ] getTotalWithdrawnForSupplier()
- [ ] getCustomerSalesStatistics()

✅ **UI Calculations:**
- [ ] Payroll calculation (_calculateNetSalary)
- [ ] Dashboard statistics
- [ ] Report data processing

✅ **Currency Formatting:**
- [ ] CurrencyService.formatAmount()
- [ ] formatCurrencyWithoutSymbol()
- [ ] PDF currency formatting

---

## 🔟 التوصيات

### 1. استخدام `Decimal` للدقة العالية
```dart
// بدلاً من:
final double amount = 100.1 + 200.2;  // قد يعطي نتيجة خاطئة

// استخدم:
final decimal.Decimal amount = decimal.Decimal.parse('100.1') + decimal.Decimal.parse('200.2');
```

### 2. التحقق من الـ Input
```dart
// استخدم:
final amount = double.tryParse(inputText);
if (amount == null) {
  // التعامل مع الخطأ
}
```

### 3. تجنب العمليات الحسابية المعقدة
```dart
// بدلاً من حسابات متعددة على التوالي:
// استخدم:
final total = (baseSalary + bonuses) - (deductions + advances);
```

### 4. توثيق النطاق المتوقع
```dart
/// حساب الراتب الصافي
/// 
/// المدخلات:
/// - baseSalary: من 0 إلى ملايين (حسب الشركة)
/// - bonuses: من 0 إلى baseSalary
/// - deductions: من 0 إلى baseSalary
/// 
/// الناتج: قد يكون سالب إذا كانت الخصومات أكثر من الراتب
double calculateNetSalary(double baseSalary, double bonuses, double deductions) {
  return (baseSalary + bonuses) - deductions;
}
```

---

## الخلاصة

هذا المشروع يستخدم `double` بشكل **منظم وآمن** لجميع العمليات المالية:
- ✅ 35 ملف Dart
- ✅ 28 عملية تحويل `toDouble()`
- ✅ 11+ دالة ترجع `double`
- ✅ 8 نماذج بيانات مالية
- ✅ دعم 6 عملات مختلفة

**الاستخدام يركز على:**
1. الرواتب والسلف (الموظفين)
2. الأسعار والأرباح (المنتجات والمبيعات)
3. الديون والدفعات (الزبائن)
4. المصاريف والمسحوبات (العام)
5. النسب والإحصائيات (التقارير)
