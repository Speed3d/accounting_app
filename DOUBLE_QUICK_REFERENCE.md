# المرجع السريع: استخدام double في تطبيق المحاسبة

## 🔍 البحث السريع عن استخدامات double

### البحث في Models:
```bash
grep -n "final dynamic\|toDouble()" lib/data/models.dart
```

### البحث في Database:
```bash
grep -n "toDouble()\|REAL" lib/data/database_helper.dart
```

### البحث في جميع الملفات:
```bash
grep -r "toDouble()" lib --include="*.dart" | wc -l  # العدد: 28
```

---

## 📊 جدول ملخص البيانات المالية

| النموذج | الحقل | النوع | الجدول | الوصف |
|-------|------|------|--------|-------|
| Employee | baseSalary | dynamic→double | TB_Employees | الراتب الأساسي |
| Employee | balance | dynamic→double | TB_Employees | الرصيد المستحق |
| PayrollEntry | baseSalary | dynamic→double | TB_Payroll | الراتب الأساسي |
| PayrollEntry | bonuses | dynamic→double | TB_Payroll | المكافآت |
| PayrollEntry | deductions | dynamic→double | TB_Payroll | الخصومات |
| PayrollEntry | advanceDeduction | dynamic→double | TB_Payroll | خصم السلفة |
| PayrollEntry | netSalary | dynamic→double | TB_Payroll | الراتب الصافي |
| EmployeeAdvance | advanceAmount | dynamic→double | TB_Employee_Advances | مبلغ السلفة |
| Product | costPrice | dynamic→double | Store_Products | سعر التكلفة |
| Product | sellingPrice | dynamic→double | Store_Products | سعر البيع |
| Customer | debt | dynamic→double | TB_Customer | الدين |
| Customer | payment | dynamic→double | TB_Customer | الدفعة |
| Customer | remaining | dynamic→double | TB_Customer | المتبقي |
| CustomerDebt | debt | dynamic→double | Debt_Customer | الدين |
| CustomerDebt | costPriceAtTimeOfSale | dynamic→double | Debt_Customer | سعر التكلفة وقت البيع |
| CustomerDebt | profitAmount | dynamic→double | Debt_Customer | مبلغ الربح |
| CustomerPayment | payment | dynamic→double | Payment_Customer | مبلغ الدفعة |
| Partner | sharePercentage | dynamic | Supplier_Partners | نسبة الحصة |

---

## 🗂️ قائمة الملفات الرئيسية

### الملفات الحاسمة (يجب مراجعتها):
```
1. lib/data/models.dart ........................... 540 سطر - 8 فئات مالية
2. lib/data/database_helper.dart ................. 1912 سطر - 11+ دالة مالية
3. lib/services/currency_service.dart ........... 149 سطر - تنسيق 6 عملات
4. lib/services/pdf_service.dart ................ 500+ سطر - إنشاء تقارير
```

### الشاشات المهمة:
```
1. lib/screens/employees/add_payroll_screen.dart .... حساب الراتب
2. lib/screens/dashboard/dashboard_screen.dart ..... عرض الإحصائيات
3. lib/screens/reports/profit_report_screen.dart .. تقرير الأرباح
4. lib/screens/reports/customer_sales_report_screen.dart ... تقرير المبيعات
```

---

## 🧮 الحسابات الشائعة

### 1. حساب الراتب الصافي:
```dart
double netSalary = (baseSalary + bonuses) - (deductions + advanceRepayment);
```
**الملف:** `lib/screens/employees/add_payroll_screen.dart:95`

### 2. حساب الربح الصافي:
```dart
double netProfit = grossProfit - totalExpenses - totalWithdrawals;
```
**الملف:** `lib/screens/reports/profit_report_screen.dart:143-145`

### 3. نسبة التحصيل:
```dart
double collectionRate = (totalPayments / totalSales) * 100;
```
**الملف:** `lib/data/database_helper.dart:1588-1593`

### 4. ربح المنتج:
```dart
double profit = sellingPrice - costPrice;
```
**الملف:** يُحسب في `getTotalProfit()` و `getProfitBySupplier()`

---

## 🔀 تحويل البيانات

### الطريقة الآمنة (Safe):
```dart
// من قاعدة البيانات
double value = (map['FieldName'] as num).toDouble();

// من input المستخدم
double value = double.tryParse(userInput) ?? 0.0;

// مع safe navigation
double value = (result.first['Total'] as num?)?.toDouble() ?? 0.0;
```

### الطريقة غير الآمنة (Unsafe):
```dart
// تجنب هذا:
double value = map['FieldName'] as double;  // قد يحدث خطأ
```

---

## 📱 عرض البيانات المالية

### تنسيق في واجهة المستخدم:
```dart
// في utils/helpers.dart
String formatted = formatCurrency(amount);  // مثال: "1,000.50 IQD"
```

### تنسيق في PDF:
```dart
// في services/pdf_service.dart
String formatted = _formatCurrency(amount);  // مثال: "1,000.50 د.ع"
```

### تنسيق مخصص:
```dart
NumberFormat formatter = NumberFormat.currency(
  locale: 'en_US',
  symbol: '\$',
  decimalDigits: 2,
);
String result = formatter.format(amount);
```

---

## 🌍 العملات المدعومة

| الرمز | الاسم | الكسور العشرية | الرمز | المحلية |
|------|------|--------------|------|---------|
| IQD | دينار عراقي | 0 | د.ع | en_US |
| USD | دولار أمريكي | 2 | $ | en_US |
| EUR | يورو | 2 | € | en_US |
| GBP | جنيه إسترليني | 2 | £ | en_GB |
| SAR | ريال سعودي | 2 | SAR | ar_SA |
| AED | درهم إماراتي | 2 | AED | ar_AE |

---

## ✅ نقاط التحقق (Checklist)

### عند إضافة حقل مالي جديد:
- [ ] إضافة الحقل في النموذج (models.dart) كـ `dynamic`
- [ ] إضافة عمود REAL في جدول قاعدة البيانات
- [ ] إضافة التحويل `(map['FieldName'] as num).toDouble()` في fromMap
- [ ] إضافة الحقل في toMap method
- [ ] اختبار الحفظ والاسترجاع من قاعدة البيانات
- [ ] إضافة دالة لحساب الإجمالي (إن كانت مطلوبة)
- [ ] اختبار التنسيق في الواجهة

### عند إنشاء حساب جديد:
- [ ] التحقق من صحة input باستخدام `double.tryParse()`
- [ ] التعامل مع الحالات الفارغة أو الخاطئة
- [ ] عدم السماح بقيم سالبة (إذا لزم الأمر)
- [ ] حفظ في قاعدة البيانات كـ REAL
- [ ] عرض مع التنسيق الصحيح

---

## 🐛 استكشاف الأخطاء

### مشكلة: الأرقام العشرية غير صحيحة
```dart
// ❌ خطأ شائع:
double price = 100.1 + 200.2;  // قد تعطي 300.2999999...

// ✅ الحل:
// استخدم Decimal أو قرّب النتيجة
double price = (100.1 + 200.2).toStringAsFixed(2);
```

### مشكلة: القيمة null من قاعدة البيانات
```dart
// ❌ خطأ:
double value = (result['Total'] as num).toDouble();  // null exception

// ✅ الحل:
double value = (result['Total'] as num?)?.toDouble() ?? 0.0;
```

### مشكلة: عدم تحويل input المستخدم
```dart
// ❌ خطأ:
double amount = double.parse(userInput);  // قد يحدث crash

// ✅ الحل:
double? amount = double.tryParse(userInput);
if (amount == null) {
  // عرض رسالة خطأ
}
```

---

## 📚 مراجع سريعة للدوال

### الدوال الترجع double (في database_helper.dart):
```dart
Future<double> getTotalProfit()
Future<double> getTotalNetSalariesPaid()
Future<double> getTotalActiveAdvancesBalance()
Future<double> getTotalExpenses()
Future<double> getTotalAllProfitWithdrawals()
Future<double> getTotalSales()
Future<double> getTotalDebts()
Future<double> getTotalPaymentsCollected()
Future<double> getTotalWithdrawnForSupplier(int supplierId)
Future<double> getCollectionRate()
```

### الدوال المتقدمة:
```dart
Future<Map<String, dynamic>> getCustomerSalesStatistics(...)
  // ترجع: totalSales, totalProfit, averageTransaction, minTransaction, maxTransaction

Future<List<Map<String, dynamic>>> getProfitBySupplier()
  // ترجع: TotalProfit لكل مورد
```

---

## 🎯 أمثلة عملية

### مثال 1: عرض الأرباح في الواجهة
```dart
final profit = await dbHelper.getTotalProfit();
final formatted = formatCurrency(profit);
Text(formatted);  // مثال: "50,000.00 د.ع"
```

### مثال 2: حساب صافي الراتب
```dart
final netSalary = (baseSalary + bonuses) - (deductions + advances);
await dbHelper.recordNewPayroll(payroll, advanceRepayment);
```

### مثال 3: إنشاء فاتورة
```dart
double totalAmount = cartItems.fold(0.0, (sum, item) {
  return sum + (item.product.sellingPrice * item.quantity);
});
```

### مثال 4: حساب الدين المتبقي
```dart
double remaining = customer.debt - customer.payment;
await dbHelper.updateCustomer(customer);
```

---

## 🔗 الروابط السريعة

- **models.dart:** `/home/user/accounting_app/lib/data/models.dart`
- **database_helper.dart:** `/home/user/accounting_app/lib/data/database_helper.dart`
- **currency_service.dart:** `/home/user/accounting_app/lib/services/currency_service.dart`
- **pdf_service.dart:** `/home/user/accounting_app/lib/services/pdf_service.dart`
- **add_payroll_screen.dart:** `/home/user/accounting_app/lib/screens/employees/add_payroll_screen.dart`

---

## 📋 ملفات التقارير

- **التقرير الشامل:** `DOUBLE_ANALYSIS_COMPREHENSIVE.md`
- **الملخص التنفيذي:** `DOUBLE_ANALYSIS_SUMMARY.txt`
- **هذا الملف:** `DOUBLE_QUICK_REFERENCE.md`

