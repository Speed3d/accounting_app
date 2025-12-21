# 🚨 خطة الإصلاح الطارئة الشاملة

## 📊 تحليل المشاكل المكتشفة

### ❌ المشكلة 1: العرض المحاسبي لا يظهر
**الوصف**: عند تفعيل "العرض المحاسبي" من الإعدادات، لا يحدث أي تغيير في التقارير.

**السبب**:
- النظام المحاسبي موجود في قاعدة البيانات ✅
- لكن شاشات التقارير لم يتم ربطها بـ `AccountingViewProvider` ❌
- التقارير لا تعرض البيانات المحاسبية الإضافية ❌

**التأثير**: ⭐⭐⭐ متوسط

---

### ❌ المشكلة 2: استعادة المنتج من الأرشيف بدون قيد محاسبي
**الوصف**:
1. عند حذف منتج → يسجل قيد محاسبي عكسي ✅
2. المنتج يذهب للأرشفة ✅
3. عند استعادة المنتج → يرجع بدون قيد محاسبي ❌

**السبب**:
- عملية الاستعادة فقط تغير `IsArchived = 0`
- لا يوجد كود لتسجيل قيد محاسبي عند الاستعادة

**المطلوب**:
- منع أرشفة منتج له كمية > 0
- السماح بأرشفة منتج كميته = 0 فقط
- عند استعادة منتج (كميته = 0) → لا نسجل قيد
- عند تعديل منتج مستعاد وإضافة كمية → نسجل قيد شراء جديد

**التأثير**: ⭐⭐⭐⭐⭐ خطير جداً (ثغرة محاسبية)

---

### ❌ المشكلة 3: عدم وجود مورد افتراضي عند التثبيت
**الوصف**:
- عند التثبيت الأول → قاعدة البيانات فارغة من الموردين
- عند محاولة إضافة منتج → "لا يوجد مورد"
- المستخدم مضطر لإنشاء مورد يدوياً قبل البدء

**المطلوب**:
- إنشاء مورد افتراضي باسم "الصندوق" أو "حساب المحل" عند `_onCreate`
- يكون هذا المورد:
  - نوعه: مفرد (Individual)
  - افتراضي (IsDefault = 1)
  - لا يمكن حذفه
  - يظهر دائماً في قائمة الموردين

**التأثير**: ⭐⭐⭐⭐ عالي (UX سيئة)

---

### ❌ المشكلة 4: تعديل المنتج لا يعمل
**الوصف**:
- عند تغيير كمية أو سعر المنتج → لا يحدث تحديث
- القيد المحاسبي للتعديل لا يُسجل

**السبب المحتمل**:
- خطأ في منطق `recordProductAdjustment()`
- أو خطأ في حساب الفرق

**التأثير**: ⭐⭐⭐⭐⭐ خطير جداً

---

### ❌ المشكلة 5: خيارات نوع الشراء مربكة
**الوصف**:
- عند إضافة منتج → dialog بـ 3 خيارات (نقدي، آجل، رصيد افتتاحي)
- المستخدم لا يفهم الفرق
- لا يوجد نظام لتتبع المدفوعات الآجلة
- الرصيد الافتتاحي غير واضح الاستخدام

**المطلوب**:
- **إلغاء Dialog تماماً**
- جعل جميع المشتريات "نقدية" فقط
- تبسيط النظام للمستخدم العادي

**التأثير**: ⭐⭐⭐ متوسط (لكن يسبب ارتباك)

---

## 🎯 خطة الإصلاح (6 خطوات)

### الخطوة 1: إنشاء مورد افتراضي "الصندوق" ⭐⭐⭐⭐⭐

**الملفات المتأثرة**:
- `lib/data/database_helper.dart` (تعديل `_onCreate`)
- `lib/data/database_migrations.dart` (إضافة migration للمستخدمين الحاليين)

**التغييرات**:
```dart
// في _onCreate بعد إنشاء جدول TB_Suppliers

// إنشاء مورد افتراضي
await db.insert('TB_Suppliers', {
  'SupplierName': 'الصندوق',
  'Phone': '',
  'Address': '',
  'Notes': 'المورد الافتراضي للنظام - يمثل الشراء النقدي المباشر',
  'IsSupplier': 1,  // مورد عادي
  'IsDefault': 1,   // افتراضي
  'IsActive': 1,
  'CreatedAt': DateTime.now().toIso8601String(),
});
```

**الفائدة**:
- المستخدم يمكنه البدء فوراً بإضافة منتجات
- لا حاجة لإنشاء مورد يدوياً

---

### الخطوة 2: تبسيط نظام الشراء (إلغاء Dialog) ⭐⭐⭐⭐

**الملفات المتأثرة**:
- `lib/screens/products/add_edit_product_screen.dart`
- `lib/helpers/accounting_integration_helper.dart`

**التغييرات**:

1. **حذف Dialog نوع الشراء**:
   - حذف دالة `_showPurchaseTypeDialog()`
   - حذف دالة `_buildPurchaseTypeOption()`

2. **تبسيط `_saveProduct()`**:
```dart
Future<void> _saveProduct() async {
  if (widget.product == null) {
    // منتج جديد

    // 1. حفظ المنتج
    final productId = await _dbHelper.insertProduct(product);

    // 2. تسجيل قيد محاسبي نقدي مباشرة (بدون dialog)
    await AccountingIntegrationHelper.recordProductPurchase(
      productId: productId,
      quantity: quantity,
      costPrice: costPrice,
      purchaseType: 'cash',  // ← دائماً نقدي
      supplierId: _selectedSupplier!.supplierID!,
    );

  } else {
    // تعديل منتج موجود
    // ... (سنصلحه في الخطوة 5)
  }
}
```

3. **تبسيط `recordProductPurchase()`**:
```dart
static Future<bool> recordProductPurchase({
  required int productId,
  required int quantity,
  required Decimal costPrice,
  int? supplierId,
}) async {
  // دائماً نقدي - بدون purchaseType parameter

  final totalCost = costPrice * Decimal.fromInt(quantity);
  final inventoryAccount = await accountService.getInventoryAccount();
  final cashAccount = await accountService.getCashAccount();

  // القيد: من ح/ المخزون - إلى ح/ الصندوق
  // Debit: Inventory (+), Credit: Cash (-)

  await transactionService.createTransaction(
    fiscalYearId: activeFiscalYear!.fiscalYearID!,
    transactionType: 'expense',
    amount: totalCost,
    debitAccountId: inventoryAccount!.accountID!,
    creditAccountId: cashAccount!.accountID!,
    description: 'شراء منتج #$productId - كمية: $quantity',
    transactionDate: DateTime.now(),
  );

  return true;
}
```

**الفائدة**:
- واجهة أبسط للمستخدم
- لا ارتباك في الخيارات
- نظام واضح ومباشر

---

### الخطوة 3: منع أرشفة منتج له كمية ⭐⭐⭐⭐⭐

**الملفات المتأثرة**:
- `lib/screens/products/products_list_screen.dart`

**التغييرات**:

```dart
Future<void> _handleArchiveProduct(Product product) async {
  // ✅ تحقق أولاً: هل الكمية = 0؟
  if (product.quantity > 0) {
    // ❌ منع الأرشفة
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'لا يمكن أرشفة منتج له كمية موجودة (${product.quantity})\n'
                'يجب تصفير الكمية أولاً عن طريق تعديل المنتج أو بيعه',
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.warning,
        duration: Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;  // إيقاف العملية
  }

  // ✅ الكمية = 0، يمكن المتابعة

  // تأكيد الأرشفة
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.archive, color: AppColors.warning),
          SizedBox(width: 8),
          Text('تأكيد الأرشفة'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('هل تريد أرشفة المنتج "${product.productName}"؟'),
          SizedBox(height: 8),
          Text(
            'المنتج لا يحتوي على كمية، سيتم نقله للأرشيف',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warning,
          ),
          child: Text('نعم، أرشفة'),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  // أرشفة المنتج (بدون حذف قيد محاسبي - لأن الكمية = 0)
  await dbHelper.archiveProduct(product.productID!);

  setState(() {
    _products.removeWhere((p) => p.productID == product.productID);
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('✅ تم أرشفة المنتج بنجاح'),
      backgroundColor: AppColors.success,
    ),
  );
}
```

**الفائدة**:
- حماية من ثغرة محاسبية خطيرة
- ضمان توازن الحسابات
- UX أفضل (رسالة واضحة)

---

### الخطوة 4: تسجيل قيد عند استعادة منتج وإضافة كمية ⭐⭐⭐⭐⭐

**الملفات المتأثرة**:
- `lib/screens/products/add_edit_product_screen.dart`

**السيناريو**:
1. منتج في الأرشيف (كميته = 0)
2. المستخدم يستعيد المنتج
3. المستخدم يعدل المنتج ويضيف كمية (مثلاً من 0 إلى 100)
4. **يجب تسجيل قيد شراء جديد**

**التغييرات**:

```dart
Future<void> _saveProduct() async {
  if (widget.product == null) {
    // منتج جديد - تم معالجته في الخطوة 2

  } else {
    // ✅ تعديل منتج موجود

    final oldProduct = widget.product!;
    final oldQuantity = oldProduct.quantity;
    final newQuantity = int.parse(_quantityController.text);

    final oldCostPrice = oldProduct.costPrice;
    final newCostPrice = Decimal.parse(_costPriceController.text);

    // حساب الفروقات
    final quantityDifference = newQuantity - oldQuantity;
    final costDifference = newCostPrice - oldCostPrice;

    // 1. حفظ التعديل
    await _dbHelper.updateProduct(updatedProduct);

    // 2. تسجيل قيد محاسبي

    if (quantityDifference != 0 || costDifference != Decimal.zero) {
      // ✅ حالة خاصة: استعادة من الأرشيف
      if (oldQuantity == 0 && newQuantity > 0) {
        // المنتج كان في الأرشيف (كمية = 0)
        // الآن نضيف كمية → نعتبره شراء جديد

        await AccountingIntegrationHelper.recordProductPurchase(
          productId: updatedProduct.productID!,
          quantity: newQuantity,
          costPrice: newCostPrice,
          supplierId: _selectedSupplier!.supplierID!,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم تسجيل قيد شراء جديد للمنتج المستعاد'),
            backgroundColor: AppColors.success,
          ),
        );

      } else {
        // حالة عادية: تعديل منتج موجود

        await AccountingIntegrationHelper.recordProductAdjustment(
          productId: updatedProduct.productID!,
          costDifference: costDifference,
          quantityDifference: quantityDifference,
          adjustmentReason: 'تعديل المنتج: ${updatedProduct.productName}',
        );
      }
    }
  }
}
```

**الفائدة**:
- إغلاق الثغرة المحاسبية
- تتبع دقيق لحركة المخزون
- نظام متسق

---

### الخطوة 5: إصلاح تعديل المنتج ⭐⭐⭐⭐⭐

**المشكلة المحتملة**:
- `recordProductAdjustment()` قد لا يعمل بشكل صحيح
- أو الفروقات تُحسب خطأ

**الحل**:

```dart
// في accounting_integration_helper.dart

static Future<bool> recordProductAdjustment({
  required int productId,
  required Decimal costDifference,
  required int quantityDifference,
  required String adjustmentReason,
}) async {
  // التحقق: هل هناك تغيير فعلي؟
  if (quantityDifference == 0 && costDifference == Decimal.zero) {
    debugPrint('⚠️ لا يوجد تغيير في الكمية أو السعر - تخطي القيد');
    return true;
  }

  final activeFiscalYear = await fiscalYearService.getActiveFiscalYear();
  if (activeFiscalYear == null) {
    debugPrint('❌ لا توجد سنة مالية نشطة');
    return false;
  }

  final inventoryAccount = await accountService.getInventoryAccount();
  final adjustmentAccount = await accountService.getCapitalAccount();

  if (inventoryAccount == null || adjustmentAccount == null) {
    debugPrint('❌ فشل جلب الحسابات');
    return false;
  }

  // حساب التأثير المالي الإجمالي
  // مثال: كمية زادت 10، سعر زاد 5
  // التأثير = (10 * سعر_جديد) + (كمية_قديمة * 5)
  // لكن الأبسط: نسجل القيمة الإجمالية للتغيير

  Decimal totalAdjustment = Decimal.zero;

  if (quantityDifference > 0) {
    // زيادة في الكمية → شراء إضافي
    // نحتاج سعر الوحدة الحالي
    final product = await DatabaseHelper.instance.getProductById(productId);
    if (product != null) {
      totalAdjustment = product.costPrice * Decimal.fromInt(quantityDifference);
    }
  } else if (quantityDifference < 0) {
    // نقص في الكمية → بيع أو تلف
    final product = await DatabaseHelper.instance.getProductById(productId);
    if (product != null) {
      totalAdjustment = product.costPrice * Decimal.fromInt(quantityDifference.abs());
      totalAdjustment = -totalAdjustment;  // قيمة سالبة
    }
  }

  // تسجيل القيد
  if (totalAdjustment > Decimal.zero) {
    // زيادة في قيمة المخزون
    await transactionService.createTransaction(
      fiscalYearId: activeFiscalYear.fiscalYearID!,
      transactionType: 'expense',
      amount: totalAdjustment,
      debitAccountId: inventoryAccount.accountID!,
      creditAccountId: adjustmentAccount.accountID!,
      description: adjustmentReason,
      transactionDate: DateTime.now(),
    );
  } else if (totalAdjustment < Decimal.zero) {
    // نقص في قيمة المخزون
    await transactionService.createTransaction(
      fiscalYearId: activeFiscalYear.fiscalYearID!,
      transactionType: 'income',
      amount: totalAdjustment.abs(),
      debitAccountId: adjustmentAccount.accountID!,
      creditAccountId: inventoryAccount.accountID!,
      description: adjustmentReason,
      transactionDate: DateTime.now(),
    );
  }

  debugPrint('✅ تم تسجيل قيد التسوية بمبلغ: $totalAdjustment');
  return true;
}
```

**الفائدة**:
- تعديل المنتج يعمل بشكل صحيح
- القيود المحاسبية دقيقة

---

### الخطوة 6: ربط العرض المحاسبي بالتقارير ⭐⭐⭐

**الملفات المتأثرة**:
- `lib/screens/reports/profit_report_screen.dart`
- `lib/screens/fiscal_years/financial_report_screen.dart`
- تقارير أخرى حسب الحاجة

**مثال**: إضافة قسم محاسبي لتقرير الأرباح

```dart
import 'package:provider/provider.dart';
import 'package:accountant_touch/providers/accounting_view_provider.dart';
import 'package:accountant_touch/services/account_service.dart';

class _ProfitReportScreenState extends State<ProfitReportScreen> {
  // ... existing code ...

  Account? _cashAccount;
  Account? _inventoryAccount;
  Decimal _totalAssets = Decimal.zero;

  @override
  void initState() {
    super.initState();
    _loadFinancialSummary();
    _loadAccountingData();  // ← جديد
  }

  Future<void> _loadAccountingData() async {
    _cashAccount = await AccountService.instance.getCashAccount();
    _inventoryAccount = await AccountService.instance.getInventoryAccount();
    _totalAssets = await AccountService.instance.getTotalAssets();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountingViewProvider>(
      builder: (context, accountingProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('تقرير الأرباح'),
          ),
          body: FutureBuilder<FinancialSummary>(
            future: _summaryFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return LoadingState();

              final summary = snapshot.data!;

              return SingleChildScrollView(
                child: Column(
                  children: [
                    // العرض العادي
                    _buildFinancialSummarySection(summary, netProfit),

                    // ✅ العرض المحاسبي (جديد)
                    if (accountingProvider.showAccountingView) ...[
                      Divider(height: 40, thickness: 2),
                      _buildAccountingSection(),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAccountingSection() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance, color: AppColors.primaryLight, size: 28),
                SizedBox(width: 12),
                Text(
                  'التفاصيل المحاسبية',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            SizedBox(height: 20),

            // أرصدة الحسابات
            _buildAccountRow('رصيد الصندوق', _cashAccount?.balance ?? Decimal.zero, Icons.money),
            Divider(),
            _buildAccountRow('رصيد المخزون', _inventoryAccount?.balance ?? Decimal.zero, Icons.inventory),
            Divider(),
            _buildAccountRow(
              'إجمالي الأصول',
              _totalAssets,
              Icons.trending_up,
              isBold: true,
              color: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountRow(String label, Decimal amount, IconData icon, {bool isBold = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: isBold ? 16 : 14,
              ),
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

**الفائدة**:
- المستخدم يرى تأثير تفعيل "العرض المحاسبي"
- معلومات إضافية مفيدة
- تكامل كامل بين النظامين

---

## 📋 ملخص التغييرات

| الخطوة | الملف | نوع التغيير | الأهمية |
|-------|------|-------------|---------|
| 1 | database_helper.dart | إضافة مورد افتراضي | ⭐⭐⭐⭐⭐ |
| 1 | database_migrations.dart | Migration للمستخدمين الحاليين | ⭐⭐⭐⭐ |
| 2 | add_edit_product_screen.dart | حذف dialog + تبسيط | ⭐⭐⭐⭐ |
| 2 | accounting_integration_helper.dart | تبسيط recordProductPurchase | ⭐⭐⭐⭐ |
| 3 | products_list_screen.dart | منع أرشفة منتج له كمية | ⭐⭐⭐⭐⭐ |
| 4 | add_edit_product_screen.dart | قيد عند استعادة + كمية | ⭐⭐⭐⭐⭐ |
| 5 | accounting_integration_helper.dart | إصلاح recordProductAdjustment | ⭐⭐⭐⭐⭐ |
| 6 | profit_report_screen.dart | ربط العرض المحاسبي | ⭐⭐⭐ |
| 6 | financial_report_screen.dart | ربط العرض المحاسبي | ⭐⭐⭐ |

---

## 🧪 خطة الاختبار

بعد تطبيق جميع الإصلاحات، يجب اختبار:

### ✅ Test 1: المورد الافتراضي
1. حذف التطبيق وإعادة تثبيته
2. فتح التطبيق
3. الذهاب لإضافة منتج
4. **المتوقع**: يظهر مورد "الصندوق" في القائمة

### ✅ Test 2: إضافة منتج (نقدي فقط)
1. إضافة منتج جديد
2. **المتوقع**: لا يظهر dialog نوع الشراء
3. **المتوقع**: يُسجل قيد محاسبي نقدي تلقائياً

### ✅ Test 3: منع أرشفة منتج له كمية
1. إضافة منتج بكمية 100
2. محاولة أرشفته
3. **المتوقع**: رسالة خطأ "لا يمكن أرشفة منتج له كمية"

### ✅ Test 4: أرشفة منتج بكمية 0
1. تعديل المنتج وجعل كميته = 0
2. محاولة أرشفته
3. **المتوقع**: نجاح الأرشفة

### ✅ Test 5: استعادة وإضافة كمية
1. استعادة منتج من الأرشيف
2. تعديل المنتج وإضافة كمية (مثلاً 50)
3. **المتوقع**: تسجيل قيد شراء جديد

### ✅ Test 6: تعديل كمية وسعر
1. تعديل منتج موجود
2. تغيير الكمية من 100 إلى 150
3. تغيير السعر من 10 إلى 12
4. **المتوقع**: تسجيل قيد تسوية

### ✅ Test 7: العرض المحاسبي
1. الذهاب للإعدادات
2. تفعيل "العرض المحاسبي"
3. فتح تقرير الأرباح
4. **المتوقع**: ظهور قسم "التفاصيل المحاسبية" مع أرصدة الحسابات

---

## ⏱️ الوقت المتوقع للتنفيذ

- الخطوة 1: 15 دقيقة
- الخطوة 2: 20 دقيقة
- الخطوة 3: 10 دقائق
- الخطوة 4: 15 دقيقة
- الخطوة 5: 20 دقيقة
- الخطوة 6: 30 دقيقة
- الاختبار: 20 دقيقة

**المجموع**: ~2 ساعة

---

## 🚀 ترتيب الأولويات

إذا أردنا التنفيذ بالتدريج:

**المرحلة الحرجة** (يجب إصلاحها فوراً):
1. ✅ الخطوة 1: مورد افتراضي
2. ✅ الخطوة 3: منع أرشفة منتج له كمية
3. ✅ الخطوة 4: قيد عند الاستعادة
4. ✅ الخطوة 5: إصلاح تعديل المنتج

**المرحلة التحسينية** (يمكن تأجيلها):
5. الخطوة 2: تبسيط نظام الشراء
6. الخطوة 6: ربط العرض المحاسبي

---

## ✅ الموافقة على الخطة

هل توافق على هذه الخطة الشاملة؟

بعد موافقتك سأبدأ فوراً بالتنفيذ خطوة بخطوة.
