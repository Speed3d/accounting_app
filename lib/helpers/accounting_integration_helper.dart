// lib/helpers/accounting_integration_helper.dart

import 'package:accountant_touch/data/database_helper.dart';
import 'package:accountant_touch/data/models.dart';
import 'package:accountant_touch/services/account_service.dart';
import 'package:accountant_touch/services/fiscal_year_service.dart';
import 'package:accountant_touch/services/transaction_service.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

/// ============================================================================
/// 🔗 مساعد الربط المحاسبي للمنتجات (Accounting Integration Helper)
/// ============================================================================
/// ← Hint: هذا الملف يوفر دوال مساعدة للربط التلقائي بين عمليات المنتجات والقيود المحاسبية
/// ← Hint: يُستخدم عند إضافة/تعديل/حذف المنتجات لتسجيل القيود المحاسبية تلقائياً
/// ← Hint: يضمن أن كل عملية مشتريات تُسجل كقيد مزدوج (مدين + دائن)
///
/// 📊 القيود المحاسبية للمنتجات:
/// ═══════════════════════════════════════════════════════════════════════════
/// عند شراء منتج نقداً من الصندوق:
///   من ح/ المخزون (1100)      [مدين]   +1000
///       إلى ح/ الصندوق (1001)  [دائن]   -1000
///
/// عند شراء منتج آجلاً من مورد:
///   من ح/ المخزون (1100)      [مدين]   +1000
///       إلى ح/ الموردون (2001) [دائن]   +1000
///
/// عند حذف منتج (خسارة):
///   من ح/ خسائر المخزون (5010) [مدين]  +1000
///       إلى ح/ المخزون (1100)   [دائن]  -1000
/// ═══════════════════════════════════════════════════════════════════════════
class AccountingIntegrationHelper {
  // ==========================================================================
  // Dependencies
  // ==========================================================================
  static final _transactionService = TransactionService.instance;
  static final _fiscalYearService = FiscalYearService.instance;
  static final _accountService = AccountService.instance;

  // ==========================================================================
  // 🛒 الربط التلقائي لشراء المنتجات (إضافة منتج جديد)
  // ==========================================================================

  /// إنشاء قيد محاسبي تلقائي عند شراء منتج جديد
  ///
  /// ← Hint: يُستدعى من AddEditProductScreen بعد إضافة المنتج
  /// ← Parameters:
  ///   - productId: معرف المنتج المضاف
  ///   - quantity: الكمية المشتراة
  ///   - costPrice: سعر التكلفة للوحدة الواحدة
  ///   - purchaseType: نوع الشراء (cash, credit, opening_stock)
  ///   - supplierId: معرف المورد (إذا كان الشراء آجلاً)
  ///   - purchaseDate: تاريخ الشراء (افتراضياً الآن)
  ///   - notes: ملاحظات إضافية
  static Future<bool> recordProductPurchase({
    required int productId,
    required int quantity,
    required Decimal costPrice,
    required String purchaseType, // 'cash', 'credit', 'opening_stock'
    int? supplierId,
    DateTime? purchaseDate,
    String? notes,
  }) async {
    try {
      // ← Hint: حساب إجمالي التكلفة
      final totalCost = costPrice * Decimal.fromInt(quantity);

      debugPrint('🔗 [AccountingIntegration] تسجيل قيد شراء منتج...');
      debugPrint('   📦 ProductID: $productId');
      debugPrint('   📊 الكمية: $quantity');
      debugPrint('   💰 التكلفة الإجمالية: $totalCost');
      debugPrint('   🏷️ نوع الشراء: $purchaseType');

      // ═══════════════════════════════════════════════════════════
      // 1️⃣ حالة خاصة: رصيد افتتاحي (لا يُسجل قيد)
      // ═══════════════════════════════════════════════════════════
      if (purchaseType == 'opening_stock') {
        debugPrint('⏩ [AccountingIntegration] رصيد افتتاحي - لا يُسجل قيد محاسبي');
        return true;
      }

      // ═══════════════════════════════════════════════════════════
      // 2️⃣ التحقق من وجود سنة مالية نشطة ومفتوحة
      // ═══════════════════════════════════════════════════════════
      final isOpen = await _fiscalYearService.isActiveFiscalYearOpen();
      if (!isOpen) {
        debugPrint('⚠️ [AccountingIntegration] السنة المالية النشطة مقفلة - تخطي التسجيل');
        return false;
      }

      // ═══════════════════════════════════════════════════════════
      // 3️⃣ الحصول على الحسابات المطلوبة
      // ═══════════════════════════════════════════════════════════
      final inventoryAccount = await _accountService.getInventoryAccount(); // 1100
      if (inventoryAccount == null) {
        debugPrint('❌ [AccountingIntegration] حساب المخزون غير موجود!');
        return false;
      }

      Account? creditAccount;
      if (purchaseType == 'cash') {
        // ← Hint: الشراء نقداً من الصندوق
        creditAccount = await _accountService.getCashAccount(); // 1001
      } else if (purchaseType == 'credit') {
        // ← Hint: الشراء آجلاً من مورد
        creditAccount = await _accountService.getSuppliersAccount(); // 2001
      }

      if (creditAccount == null) {
        debugPrint('❌ [AccountingIntegration] الحساب الدائن غير موجود!');
        return false;
      }

      // ═══════════════════════════════════════════════════════════
      // 4️⃣ إنشاء القيد المحاسبي المزدوج
      // ═══════════════════════════════════════════════════════════
      // ← Hint: القيد:
      //   من ح/ المخزون (مدين)
      //       إلى ح/ الصندوق أو الموردون (دائن)

      final fiscalYear = await _fiscalYearService.getActiveFiscalYear();
      if (fiscalYear == null) {
        debugPrint('❌ [AccountingIntegration] لا توجد سنة مالية نشطة!');
        return false;
      }

      final db = await DatabaseHelper.instance.database;

      // ← Hint: إنشاء القيد في TB_Transactions
      final transactionId = await db.insert('TB_Transactions', {
        'FiscalYearID': fiscalYear.fiscalYearID,
        'Date': (purchaseDate ?? DateTime.now()).toIso8601String(),
        'Type': 'purchase', // ← Hint: نوع جديد للمشتريات
        'Category': 'cost_of_sales',
        'Amount': totalCost.toDouble(),
        'Direction': 'out', // ← Hint: خروج نقدية
        'Description': purchaseType == 'cash'
            ? 'شراء منتج نقداً - رقم #$productId'
            : 'شراء منتج آجلاً - رقم #$productId',
        'Notes': notes,
        'ReferenceType': 'product_purchase',
        'ReferenceID': productId,
        'ProductID': productId,
        'SupplierID': supplierId,
        // ← Hint: أعمدة المحاسبة المزدوجة الجديدة
        'DebitAccountID': inventoryAccount.accountID,   // المدين: المخزون
        'CreditAccountID': creditAccount.accountID,     // الدائن: الصندوق أو الموردون
      });

      if (transactionId > 0) {
        debugPrint('✅ [AccountingIntegration] تم تسجيل قيد الشراء (ID: $transactionId)');
        debugPrint('   📈 مدين: ${inventoryAccount.accountNameAr} (+$totalCost)');
        debugPrint('   📉 دائن: ${creditAccount.accountNameAr} (-$totalCost)');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ [AccountingIntegration] خطأ في recordProductPurchase: $e');
      return false;
    }
  }

  // ==========================================================================
  // ✏️ الربط التلقائي لتعديل المنتجات
  // ==========================================================================

  /// إنشاء قيد محاسبي عند تعديل تكلفة أو كمية منتج
  ///
  /// ← Hint: يُستدعى من AddEditProductScreen عند تعديل منتج موجود
  /// ← Hint: يُسجل فقط الفرق في التكلفة أو الكمية
  /// تسجيل قيد محاسبي لتعديل منتج موجود (كمية أو سعر)
  /// ========================================================================
  /// ← Hint: تم تبسيط النظام - جميع المعاملات نقدية من/إلى الصندوق
  /// ← Hint: القيد يعتمد على فرق القيمة الإجمالية للمخزون
  /// ========================================================================
  static Future<bool> recordProductAdjustment({
    required int productId,
    required Decimal costDifference,    // الفرق في السعر (جديد - قديم)
    required int quantityDifference,    // الفرق في الكمية (جديد - قديم)
    required String adjustmentReason,
  }) async {
    try {
      // ═══════════════════════════════════════════════════════
      // التحقق: هل هناك تغيير فعلي؟
      // ═══════════════════════════════════════════════════════
      if (costDifference == Decimal.zero && quantityDifference == 0) {
        debugPrint('⏩ [AccountingIntegration] لا يوجد تغيير - تخطي القيد');
        return true;
      }

      debugPrint('🔗 [AccountingIntegration] تسجيل قيد تعديل منتج #$productId');
      debugPrint('   فرق السعر: $costDifference');
      debugPrint('   فرق الكمية: $quantityDifference');

      // ═══════════════════════════════════════════════════════
      // حساب القيمة المالية للتغيير
      // ═══════════════════════════════════════════════════════
      // المنطق: نحتاج لحساب قيمة التغيير الإجمالي في المخزون

      // جلب بيانات المنتج الحالية
      final db = await DatabaseHelper.instance.database;
      final productResult = await db.query(
        'Store_Products',
        where: 'ProductID = ?',
        whereArgs: [productId],
      );

      if (productResult.isEmpty) {
        debugPrint('❌ المنتج غير موجود!');
        return false;
      }

      final currentQuantity = productResult.first['Quantity'] as int;
      final currentCostPrice = Decimal.parse(productResult.first['CostPrice'].toString());

      // الكمية القديمة = الكمية الحالية - فرق الكمية
      final oldQuantity = currentQuantity - quantityDifference;

      // السعر القديم = السعر الحالي - فرق السعر
      final oldCostPrice = currentCostPrice - costDifference;

      // حساب القيمة الإجمالية للتغيير
      final oldTotalValue = oldCostPrice * Decimal.fromInt(oldQuantity);
      final newTotalValue = currentCostPrice * Decimal.fromInt(currentQuantity);
      final totalValueChange = newTotalValue - oldTotalValue;

      debugPrint('   القيمة القديمة للمخزون: $oldTotalValue');
      debugPrint('   القيمة الجديدة للمخزون: $newTotalValue');
      debugPrint('   التغيير الإجمالي: $totalValueChange');

      if (totalValueChange == Decimal.zero) {
        debugPrint('⏩ [AccountingIntegration] لا تغيير في القيمة الإجمالية - تخطي');
        return true;
      }

      // ═══════════════════════════════════════════════════════
      // التحقق من السنة المالية
      // ═══════════════════════════════════════════════════════
      final isOpen = await _fiscalYearService.isActiveFiscalYearOpen();
      if (!isOpen) {
        debugPrint('⚠️ [AccountingIntegration] السنة المالية مقفلة');
        return false;
      }

      final fiscalYear = await _fiscalYearService.getActiveFiscalYear();
      if (fiscalYear == null) {
        debugPrint('❌ لا توجد سنة مالية نشطة');
        return false;
      }

      // ═══════════════════════════════════════════════════════
      // الحصول على الحسابات المطلوبة
      // ═══════════════════════════════════════════════════════
      final inventoryAccount = await _accountService.getInventoryAccount();  // 1100
      final cashAccount = await _accountService.getCashAccount();            // 1001

      if (inventoryAccount == null || cashAccount == null) {
        debugPrint('❌ فشل جلب الحسابات المحاسبية');
        return false;
      }

      // ═══════════════════════════════════════════════════════
      // تسجيل القيد المحاسبي
      // ═══════════════════════════════════════════════════════
      int debitAccountId;
      int creditAccountId;
      String transactionType;

      if (totalValueChange > Decimal.zero) {
        // ✅ زيادة في قيمة المخزون (شراء/زيادة)
        // من ح/ المخزون - إلى ح/ الصندوق
        debitAccountId = inventoryAccount.accountID!;
        creditAccountId = cashAccount.accountID!;
        transactionType = 'correction'; // ← تغيير من expense إلى correction
      } else {
        // ❌ نقص في قيمة المخزون (بيع/تخفيض)
        // من ح/ الصندوق - إلى ح/ المخزون
        debitAccountId = cashAccount.accountID!;
        creditAccountId = inventoryAccount.accountID!;
        transactionType = 'correction'; // ← تغيير من income إلى correction
      }

      final transactionId = await db.insert('TB_Transactions', {
        'FiscalYearID': fiscalYear.fiscalYearID,
        'Date': DateTime.now().toIso8601String(),
        'Type': transactionType,
        'Category': 'inventory_adjustment',
        'Amount': totalValueChange.abs().toDouble(),
        'Direction': totalValueChange > Decimal.zero ? 'out' : 'in',
        'Description': adjustmentReason,
        'ReferenceType': 'product_adjustment',
        'ReferenceID': productId,
        'ProductID': productId,
        'DebitAccountID': debitAccountId,
        'CreditAccountID': creditAccountId,
      });

      if (transactionId > 0) {
        debugPrint('✅ [AccountingIntegration] قيد التعديل (ID: $transactionId) - مبلغ: ${totalValueChange.abs()}');
        return true;
      }

      return false;

    } catch (e, stackTrace) {
      debugPrint('❌ [AccountingIntegration] خطأ في recordProductAdjustment: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  // ==========================================================================
  // 🗑️ الربط التلقائي لحذف المنتجات
  // ==========================================================================

  /// إنشاء قيد محاسبي عند حذف منتج
  ///
  /// ← Hint: يُستدعى من AddEditProductScreen عند حذف منتج
  /// ← Parameters:
  ///   - deleteReason: سبب الحذف
  ///     * 'return_to_supplier': إرجاع للمورد (عكس قيد الشراء)
  ///     * 'loss': خسارة بسبب تلف/سرقة (قيد خسارة)
  ///     * 'entry_error': خطأ في الإدخال (حذف القيد القديم فقط)
  static Future<bool> recordProductDeletion({
    required int productId,
    required int quantity,
    required Decimal costPrice,
    required String deleteReason, // 'return_to_supplier', 'loss', 'entry_error'
    int? supplierId,
    String? notes,
  }) async {
    try {
      final totalCost = costPrice * Decimal.fromInt(quantity);

      debugPrint('🔗 [AccountingIntegration] تسجيل قيد حذف منتج...');
      debugPrint('   📦 ProductID: $productId');
      debugPrint('   💰 التكلفة الإجمالية: $totalCost');
      debugPrint('   🏷️ سبب الحذف: $deleteReason');

      // ═══════════════════════════════════════════════════════════
      // 1️⃣ حذف القيود القديمة المرتبطة بهذا المنتج
      // ═══════════════════════════════════════════════════════════
      // ← Hint: حذف قيود الشراء/التعديل السابقة
      final db = await DatabaseHelper.instance.database;
      await db.delete(
        'TB_Transactions',
        where: 'ReferenceType IN (?, ?) AND ReferenceID = ?',
        whereArgs: ['product_purchase', 'product_adjustment', productId],
      );

      debugPrint('✅ [AccountingIntegration] تم حذف القيود القديمة للمنتج');

      // ═══════════════════════════════════════════════════════════
      // 2️⃣ إذا كان خطأ إدخال، نكتفي بحذف القيود القديمة
      // ═══════════════════════════════════════════════════════════
      if (deleteReason == 'entry_error') {
        debugPrint('⏩ [AccountingIntegration] خطأ إدخال - تم حذف القيود فقط');
        return true;
      }

      // ═══════════════════════════════════════════════════════════
      // 3️⃣ التحقق من السنة المالية
      // ═══════════════════════════════════════════════════════════
      final isOpen = await _fiscalYearService.isActiveFiscalYearOpen();
      if (!isOpen) {
        debugPrint('⚠️ [AccountingIntegration] السنة المالية مقفلة - تخطي');
        return false;
      }

      // ═══════════════════════════════════════════════════════════
      // 4️⃣ الحصول على الحسابات
      // ═══════════════════════════════════════════════════════════
      final inventoryAccount = await _accountService.getInventoryAccount();
      if (inventoryAccount == null) {
        debugPrint('❌ [AccountingIntegration] حساب المخزون غير موجود!');
        return false;
      }

      Account? debitAccount;

      if (deleteReason == 'return_to_supplier') {
        // ← Hint: إرجاع للمورد (عكس قيد الشراء)
        debitAccount = await _accountService.getSuppliersAccount(); // 2001
      } else if (deleteReason == 'loss') {
        // ← Hint: خسارة (تلف/سرقة)
        debitAccount = await _accountService.getInventoryLossAccount(); // 5010
      }

      if (debitAccount == null) {
        debugPrint('❌ [AccountingIntegration] الحساب المدين غير موجود!');
        return false;
      }

      final fiscalYear = await _fiscalYearService.getActiveFiscalYear();
      if (fiscalYear == null) return false;

      // ═══════════════════════════════════════════════════════════
      // 5️⃣ إنشاء القيد المحاسبي
      // ═══════════════════════════════════════════════════════════
      // ← Hint: القيد حسب السبب:
      //   - إرجاع: من ح/ الموردون إلى ح/ المخزون
      //   - خسارة: من ح/ خسائر المخزون إلى ح/ المخزون

      final transactionId = await db.insert('TB_Transactions', {
        'FiscalYearID': fiscalYear.fiscalYearID,
        'Date': DateTime.now().toIso8601String(),
        'Type': 'product_deletion',
        'Category': deleteReason == 'loss' ? 'general_expense' : 'cost_of_sales',
        'Amount': totalCost.toDouble(),
        'Direction': deleteReason == 'loss' ? 'out' : 'in',
        'Description': deleteReason == 'return_to_supplier'
            ? 'إرجاع منتج للمورد - رقم #$productId'
            : 'خسارة منتج (تلف/سرقة) - رقم #$productId',
        'Notes': notes,
        'ReferenceType': 'product_deletion',
        'ReferenceID': productId,
        'ProductID': productId,
        'SupplierID': supplierId,
        'DebitAccountID': debitAccount.accountID,
        'CreditAccountID': inventoryAccount.accountID,
      });

      if (transactionId > 0) {
        debugPrint('✅ [AccountingIntegration] تم تسجيل قيد الحذف (ID: $transactionId)');
        debugPrint('   📈 مدين: ${debitAccount.accountNameAr} (+$totalCost)');
        debugPrint('   📉 دائن: ${inventoryAccount.accountNameAr} (-$totalCost)');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ [AccountingIntegration] خطأ في recordProductDeletion: $e');
      return false;
    }
  }

  // ==========================================================================
  // 🧹 دوال مساعدة - حذف القيود المرتبطة
  // ==========================================================================

  /// حذف جميع القيود المحاسبية المرتبطة بمنتج معين
  ///
  /// ← Hint: يُستخدم كـ cleanup عند حذف منتج نهائياً
  static Future<bool> deleteAllProductTransactions(int productId) async {
    try {
      debugPrint('🧹 [AccountingIntegration] حذف جميع قيود المنتج #$productId...');

      final db = await DatabaseHelper.instance.database;

      final count = await db.delete(
        'TB_Transactions',
        where: 'ProductID = ? OR (ReferenceType LIKE ? AND ReferenceID = ?)',
        whereArgs: [productId, 'product%', productId],
      );

      debugPrint('✅ [AccountingIntegration] تم حذف $count قيد مرتبط بالمنتج');
      return true;
    } catch (e) {
      debugPrint('❌ [AccountingIntegration] خطأ في deleteAllProductTransactions: $e');
      return false;
    }
  }
}
