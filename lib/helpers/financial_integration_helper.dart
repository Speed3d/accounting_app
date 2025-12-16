// lib/helpers/financial_integration_helper.dart

import 'package:accountant_touch/data/models.dart';
import 'package:accountant_touch/services/fiscal_year_service.dart';
import 'package:accountant_touch/services/transaction_service.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

/// ===========================================================================
/// 🔗 مساعد الربط المالي التلقائي
/// ===========================================================================
///
/// ← Hint: هذا الملف يوفر دوال مساعدة للربط التلقائي بين العمليات والقيود المالية
/// ← Hint: يُستخدم في DatabaseHelper لإنشاء قيود تلقائياً عند كل عملية مالية
/// ← Hint: يضمن أن كل عملية (مبيعات، رواتب، إلخ) تُسجل في نظام القيود
///
/// ===========================================================================

class FinancialIntegrationHelper {
  // ==========================================================================
  // Dependencies
  // ==========================================================================

  static final _transactionService = TransactionService.instance;
  static final _fiscalYearService = FiscalYearService.instance;

  // ==========================================================================
  // 🎯 الربط التلقائي للمبيعات
  // ==========================================================================

  /// إنشاء قيد مالي تلقائي عند إضافة فاتورة (البيع المباشر أو الآجل)
  ///
  /// ← Hint: يُستدعى بعد إنشاء الفاتورة الكاملة (TB_Invoices)
  /// ← Hint: يسجل قيد واحد فقط بمجموع الفاتورة (وليس قيد لكل منتج)
  /// ← Hint: يميز بين البيع النقدي (Cash) والآجل (Credit)
  static Future<bool> recordInvoiceTransaction({
    required int invoiceId,
    required int customerId,
    required Decimal totalAmount,
    required bool isCashSale, // ← جديد: هل الدفع نقدي أم آجل؟
    required DateTime invoiceDate,
    String? notes,
  }) async {
    try {
      debugPrint('🔗 [FinancialIntegration] تسجيل قيد فاتورة تلقائياً...');
      debugPrint('  ├─ رقم الفاتورة: #$invoiceId');
      debugPrint('  ├─ المبلغ الإجمالي: ${totalAmount.toString()}');
      debugPrint('  └─ نوع البيع: ${isCashSale ? "نقدي" : "آجل"}');

      // ← Hint: التحقق من وجود سنة مالية نشطة
      final isOpen = await _fiscalYearService.isActiveFiscalYearOpen();
      if (!isOpen) {
        debugPrint('⚠️ [FinancialIntegration] السنة المالية النشطة مقفلة - تخطي التسجيل');
        return false;
      }

      // ═══════════════════════════════════════════════════════════
      // المنطق المحاسبي الصحيح:
      // ═══════════════════════════════════════════════════════════
      // ✅ البيع النقدي (Cash Sale): يُسجل فوراً كقيد دخل (direction='in')
      //    لأن المبلغ تم تحصيله فعلياً
      //
      // ❌ البيع الآجل (Credit Sale): لا يُسجل كقيد دخل الآن
      //    لأن المبلغ لم يُحصّل بعد (مجرد دين على الزبون)
      //    سيُسجل القيد فقط عند التسديد الفعلي
      // ═══════════════════════════════════════════════════════════

      if (isCashSale) {
        // ← Hint: البيع النقدي - تسجيل قيد الدخل فوراً
        final transaction = await _transactionService.createTransaction(
          type: TransactionType.sale,
          category: TransactionCategory.revenue,
          amount: totalAmount,
          direction: 'in', // ← دخل (تم التحصيل)
          description: 'مبيعات نقدية - فاتورة رقم #$invoiceId',
          notes: notes,
          referenceType: 'invoice',
          referenceId: invoiceId,
          customerId: customerId,
          transactionDate: invoiceDate,
        );

        if (transaction != null) {
          debugPrint('✅ [FinancialIntegration] تم تسجيل قيد الفاتورة النقدية (ID: ${transaction.transactionID})');
          return true;
        }
      } else {
        // ← Hint: البيع الآجل - لا نسجل قيد الآن
        // ← Hint: سيتم التسجيل فقط عند استلام الدفعة من الزبون
        debugPrint('ℹ️ [FinancialIntegration] بيع آجل - لن يتم تسجيل قيد دخل الآن');
        debugPrint('   سيتم تسجيل القيد عند التسديد الفعلي من الزبون');
        return true; // ← نجاح العملية (لكن بدون تسجيل قيد)
      }

      return false;
    } catch (e) {
      debugPrint('❌ [FinancialIntegration] خطأ في recordInvoiceTransaction: $e');
      return false;
    }
  }

  /// إنشاء قيد مالي تلقائي عند إضافة مبيعة منفردة (DEPRECATED)
  ///
  /// ⚠️ DEPRECATED: استخدم recordInvoiceTransaction بدلاً من هذه الدالة
  /// ← Hint: هذه الدالة القديمة تُسجل قيد لكل منتج (خطأ محاسبياً)
  /// ← Hint: الدالة الجديدة recordInvoiceTransaction تسجل قيد واحد للفاتورة كاملة
  @Deprecated('Use recordInvoiceTransaction instead')
  static Future<bool> recordSaleTransaction({
    required int saleId,
    required int customerId,
    required Decimal amount,
    required String saleDate,
    int? productId,
    String? productName,
  }) async {
    try {
      debugPrint('⚠️ [FinancialIntegration] استخدام recordSaleTransaction القديمة (DEPRECATED)');
      debugPrint('⚠️ يُفضل استخدام recordInvoiceTransaction للفواتير الكاملة');

      // ← Hint: التحقق من وجود سنة مالية نشطة
      final isOpen = await _fiscalYearService.isActiveFiscalYearOpen();
      if (!isOpen) {
        debugPrint('⚠️ [FinancialIntegration] السنة المالية النشطة مقفلة - تخطي التسجيل');
        return false;
      }

      // ← Hint: إنشاء القيد المالي
      final transaction = await _transactionService.createSaleTransaction(
        saleId: saleId,
        amount: amount,
        customerId: customerId,
        productId: productId,
        notes: productName != null ? 'مبيعات - $productName' : null,
        saleDate: DateTime.parse(saleDate),
      );

      if (transaction != null) {
        debugPrint('✅ [FinancialIntegration] تم تسجيل قيد المبيعة (ID: ${transaction.transactionID})');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ [FinancialIntegration] خطأ في recordSaleTransaction: $e');
      return false;
    }
  }

  // ==========================================================================
  // 💰 الربط التلقائي لدفعات العملاء
  // ==========================================================================

  /// إنشاء قيد مالي تلقائي عند استلام دفعة من زبون
  ///
  /// ← Hint: يُستدعى من DatabaseHelper.insertCustomerPayment()
  static Future<bool> recordCustomerPaymentTransaction({
    required int paymentId,
    required int customerId,
    required Decimal amount,
    required String paymentDate,
    String? comments,
  }) async {
    try {
      debugPrint('🔗 [FinancialIntegration] تسجيل قيد دفعة زبون تلقائياً...');

      final isOpen = await _fiscalYearService.isActiveFiscalYearOpen();
      if (!isOpen) {
        debugPrint('⚠️ [FinancialIntegration] السنة المالية مقفلة - تخطي');
        return false;
      }

      final transaction = await _transactionService.createCustomerPaymentTransaction(
        paymentId: paymentId,
        customerId: customerId,
        amount: amount,
        notes: comments,
        paymentDate: DateTime.parse(paymentDate),
      );

      if (transaction != null) {
        debugPrint('✅ [FinancialIntegration] تم تسجيل قيد الدفعة (ID: ${transaction.transactionID})');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ [FinancialIntegration] خطأ في recordCustomerPaymentTransaction: $e');
      return false;
    }
  }

  // ==========================================================================
  // 💼 الربط التلقائي للرواتب
  // ==========================================================================

  /// إنشاء قيد مالي تلقائي عند دفع راتب موظف
  ///
  /// ← Hint: يُستدعى من DatabaseHelper.insertPayrollEntry()
  static Future<bool> recordSalaryTransaction({
    required int payrollId,
    required int employeeId,
    required Decimal netSalary,
    required String paymentDate,
    String? notes,
  }) async {
    try {
      debugPrint('🔗 [FinancialIntegration] تسجيل قيد راتب تلقائياً...');

      final isOpen = await _fiscalYearService.isActiveFiscalYearOpen();
      if (!isOpen) {
        debugPrint('⚠️ [FinancialIntegration] السنة المالية مقفلة - تخطي');
        return false;
      }

      final transaction = await _transactionService.createSalaryTransaction(
        payrollId: payrollId,
        employeeId: employeeId,
        amount: netSalary,
        notes: notes,
        paymentDate: DateTime.parse(paymentDate),
      );

      if (transaction != null) {
        debugPrint('✅ [FinancialIntegration] تم تسجيل قيد الراتب (ID: ${transaction.transactionID})');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ [FinancialIntegration] خطأ في recordSalaryTransaction: $e');
      return false;
    }
  }

  // ==========================================================================
  // 💸 الربط التلقائي للسلف
  // ==========================================================================

  /// إنشاء قيد مالي تلقائي عند إعطاء سلفة لموظف
  ///
  /// ← Hint: يُستدعى من DatabaseHelper.insertEmployeeAdvance()
  static Future<bool> recordAdvanceTransaction({
    required int advanceId,
    required int employeeId,
    required Decimal amount,
    required String advanceDate,
    String? notes,
  }) async {
    try {
      debugPrint('🔗 [FinancialIntegration] تسجيل قيد سلفة تلقائياً...');

      final isOpen = await _fiscalYearService.isActiveFiscalYearOpen();
      if (!isOpen) {
        debugPrint('⚠️ [FinancialIntegration] السنة المالية مقفلة - تخطي');
        return false;
      }

      final transaction = await _transactionService.createAdvanceTransaction(
        advanceId: advanceId,
        employeeId: employeeId,
        amount: amount,
        notes: notes,
        advanceDate: DateTime.parse(advanceDate),
      );

      if (transaction != null) {
        debugPrint('✅ [FinancialIntegration] تم تسجيل قيد السلفة (ID: ${transaction.transactionID})');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ [FinancialIntegration] خطأ في recordAdvanceTransaction: $e');
      return false;
    }
  }

  // ==========================================================================
  // 💵 الربط التلقائي لتسديدات السلف
  // ==========================================================================

  /// إنشاء قيد مالي تلقائي عند تسديد سلفة
  ///
  /// ← Hint: يُستدعى من DatabaseHelper.insertAdvanceRepayment()
  static Future<bool> recordAdvanceRepaymentTransaction({
    required int repaymentId,
    required int advanceId,
    required int employeeId,
    required Decimal amount,
    required String repaymentDate,
    String? notes,
  }) async {
    try {
      debugPrint('🔗 [FinancialIntegration] تسجيل قيد تسديد سلفة تلقائياً...');

      final isOpen = await _fiscalYearService.isActiveFiscalYearOpen();
      if (!isOpen) {
        debugPrint('⚠️ [FinancialIntegration] السنة المالية مقفلة - تخطي');
        return false;
      }

      final transaction = await _transactionService.createAdvanceRepaymentTransaction(
        repaymentId: repaymentId,
        advanceId: advanceId,
        employeeId: employeeId,
        amount: amount,
        notes: notes,
        repaymentDate: DateTime.parse(repaymentDate),
      );

      if (transaction != null) {
        debugPrint('✅ [FinancialIntegration] تم تسجيل قيد التسديد (ID: ${transaction.transactionID})');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ [FinancialIntegration] خطأ في recordAdvanceRepaymentTransaction: $e');
      return false;
    }
  }

  // ==========================================================================
  // 🎁 الربط التلقائي للمكافآت
  // ==========================================================================

  /// إنشاء قيد مالي تلقائي عند إعطاء مكافأة لموظف
  ///
  /// ← Hint: يُستدعى من DatabaseHelper.insertEmployeeBonus()
  static Future<bool> recordBonusTransaction({
    required int bonusId,
    required int employeeId,
    required Decimal amount,
    required String bonusDate,
    String? bonusReason,
  }) async {
    try {
      debugPrint('🔗 [FinancialIntegration] تسجيل قيد مكافأة تلقائياً...');

      final isOpen = await _fiscalYearService.isActiveFiscalYearOpen();
      if (!isOpen) {
        debugPrint('⚠️ [FinancialIntegration] السنة المالية مقفلة - تخطي');
        return false;
      }

      final transaction = await _transactionService.createTransaction(
        type: TransactionType.employeeBonus,
        category: TransactionCategory.operatingExpense,
        amount: amount,
        direction: 'out',
        description: 'مكافأة موظف - مكافأة رقم #$bonusId',
        notes: bonusReason,
        referenceType: 'bonus',
        referenceId: bonusId,
        employeeId: employeeId,
        transactionDate: DateTime.parse(bonusDate),
      );

      if (transaction != null) {
        debugPrint('✅ [FinancialIntegration] تم تسجيل قيد المكافأة (ID: ${transaction.transactionID})');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ [FinancialIntegration] خطأ في recordBonusTransaction: $e');
      return false;
    }
  }

  // ==========================================================================
  // ↩️ الربط التلقائي لمرتجعات المبيعات
  // ==========================================================================

  /// إنشاء قيد مالي تلقائي عند إرجاع منتج
  ///
  /// ← Hint: يُستدعى من DatabaseHelper.insertSalesReturn()
  static Future<bool> recordSaleReturnTransaction({
    required int returnId,
    required int originalSaleId,
    required int customerId,
    required Decimal amount,
    required String returnDate,
    String? reason,
  }) async {
    try {
      debugPrint('🔗 [FinancialIntegration] تسجيل قيد مرتجع مبيعات تلقائياً...');

      final isOpen = await _fiscalYearService.isActiveFiscalYearOpen();
      if (!isOpen) {
        debugPrint('⚠️ [FinancialIntegration] السنة المالية مقفلة - تخطي');
        return false;
      }

      final transaction = await _transactionService.createSaleReturnTransaction(
        returnId: returnId,
        saleId: originalSaleId,
        customerId: customerId,
        amount: amount,
        notes: reason,
        returnDate: DateTime.parse(returnDate),
      );

      if (transaction != null) {
        debugPrint('✅ [FinancialIntegration] تم تسجيل قيد المرتجع (ID: ${transaction.transactionID})');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ [FinancialIntegration] خطأ في recordSaleReturnTransaction: $e');
      return false;
    }
  }

  // ==========================================================================
  // 🗑️ حذف القيود المرتبطة عند حذف عملية
  // ==========================================================================

  /// حذف القيد المالي المرتبط بعملية معينة
  ///
  /// ← Hint: يُستدعى عند حذف مبيعة أو راتب أو سلفة إلخ
  /// ← Hint: referenceType: نوع العملية ("sale", "payroll", "advance", إلخ)
  /// ← Hint: referenceId: معرف العملية
  static Future<bool> deleteRelatedTransaction({
    required String referenceType,
    required int referenceId,
  }) async {
    try {
      debugPrint('🗑️ [FinancialIntegration] حذف القيد المرتبط بـ $referenceType #$referenceId...');

      // ← Hint: البحث عن القيد المرتبط
      final transactions = await _transactionService.getTransactions(
        limit: 1,
      );

      // ← Hint: البحث اليدوي (لأن getTransactions لا يدعم فلتر referenceType حالياً)
      final relatedTransaction = transactions.firstWhere(
        (t) => t.referenceType == referenceType && t.referenceId == referenceId,
        orElse: () => FinancialTransaction(
          fiscalYearID: 0,
          date: DateTime.now(),
          type: TransactionType.other,
          category: TransactionCategory.miscellaneous,
          amount: Decimal.zero,
          direction: 'in',
          description: '',
        ),
      );

      if (relatedTransaction.transactionID != null) {
        final deleted = await _transactionService.deleteTransaction(
          relatedTransaction.transactionID!,
        );

        if (deleted) {
          debugPrint('✅ [FinancialIntegration] تم حذف القيد المرتبط');
          return true;
        }
      } else {
        debugPrint('⚠️ [FinancialIntegration] لم يُعثر على قيد مرتبط');
      }

      return false;
    } catch (e) {
      debugPrint('❌ [FinancialIntegration] خطأ في deleteRelatedTransaction: $e');
      return false;
    }
  }

  // ==========================================================================
  // 📊 دوال مساعدة للتحقق
  // ==========================================================================

  /// التحقق من إمكانية إنشاء قيد مالي
  ///
  /// ← Hint: يتحقق من وجود سنة مالية نشطة ومفتوحة
  static Future<bool> canRecordTransaction() async {
    try {
      final activeFiscalYear = await _fiscalYearService.getActiveFiscalYear();

      if (activeFiscalYear == null) {
        debugPrint('⚠️ [FinancialIntegration] لا توجد سنة مالية نشطة');
        return false;
      }

      if (activeFiscalYear.isClosed) {
        debugPrint('⚠️ [FinancialIntegration] السنة المالية النشطة مقفلة');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('❌ [FinancialIntegration] خطأ في canRecordTransaction: $e');
      return false;
    }
  }

  /// الحصول على معرف السنة المالية النشطة
  ///
  /// ← Hint: دالة مساعدة سريعة
  static Future<int?> getActiveFiscalYearId() async {
    return await _fiscalYearService.getActiveFiscalYearId();
  }

  // ==========================================================================
  // 📝 تسجيل ملاحظة في سجل النظام
  // ==========================================================================

  /// تسجيل ملاحظة عن عملية ربط مالي
  ///
  /// ← Hint: للتوثيق والتتبع
  static void logIntegration({
    required String operation,
    required String status,
    String? details,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('📋 [FinancialIntegration] [$timestamp] $operation - $status');
    if (details != null) {
      debugPrint('   └─ التفاصيل: $details');
    }
  }
}
