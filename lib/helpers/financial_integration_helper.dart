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

  /// إنشاء قيد مالي تلقائي عند إضافة مبيعة
  ///
  /// ← Hint: يُستدعى من DatabaseHelper.insertCustomerDebt()
  /// ← Hint: للبيع النقدي فقط - البيع الآجل لا يُسجل (يُسجل عند الدفع)
  /// ← Parameter: isCashSale - true للبيع النقدي، false للبيع الآجل
  static Future<bool> recordSaleTransaction({
    required int saleId,
    required int customerId,
    required Decimal amount,
    required String saleDate,
    int? productId,
    String? productName,
    bool isCashSale = false, // ✅ معامل جديد: افتراضياً false (آجل)
  }) async {
    try {
      // ← Hint: البيع الآجل لا يُسجل كإيراد (سيُسجل عند التسديد)
      if (!isCashSale) {
        debugPrint('⏩ [FinancialIntegration] بيع آجل - لا يُسجل إيراد (سيُسجل عند التسديد)');
        return true; // نجاح لكن بدون تسجيل قيد
      }

      debugPrint('🔗 [FinancialIntegration] تسجيل قيد مبيعة نقدية تلقائياً...');

      // ← Hint: التحقق من وجود سنة مالية نشطة
      final isOpen = await _fiscalYearService.isActiveFiscalYearOpen();
      if (!isOpen) {
        debugPrint('⚠️ [FinancialIntegration] السنة المالية النشطة مقفلة - تخطي التسجيل');
        return false;
      }

      // ← Hint: إنشاء القيد المالي للبيع النقدي
      final transaction = await _transactionService.createSaleTransaction(
        saleId: saleId,
        amount: amount,
        customerId: customerId,
        productId: productId,
        notes: productName != null ? 'مبيعات نقدية - $productName' : 'مبيعات نقدية',
        saleDate: DateTime.parse(saleDate),
      );

      if (transaction != null) {
        debugPrint('✅ [FinancialIntegration] تم تسجيل قيد المبيعة النقدية (ID: ${transaction.transactionID})');
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

  /// معالجة إرجاع مبيعة (نقدية أو آجلة) بشكل ذكي
  ///
  /// ← Hint: يُستدعى من DatabaseHelper.insertSalesReturn()
  /// ← Hint: البيع النقدي → يحذف القيد الأصلي (بدلاً من تسجيل مرتجع)
  /// ← Hint: البيع الآجل → لا يفعل شيء (لأنه لم يكن هناك قيد أصلاً)
  static Future<bool> recordSaleReturnTransaction({
    required int returnId,
    required int originalSaleId,
    required int customerId,
    required Decimal amount,
    required String returnDate,
    String? reason,
  }) async {
    try {
      debugPrint('🔗 [FinancialIntegration] معالجة إرجاع مبيعة #$originalSaleId...');

      // ← Hint: التحقق من وجود قيد مالي للبيع الأصلي
      // ← Hint: إذا كان موجود = بيع نقدي، إذا لم يكن = بيع آجل
      final db = await _transactionService.database;
      final result = await db.query(
        'TB_Transactions',
        where: 'ReferenceType = ? AND ReferenceID = ?',
        whereArgs: ['sale', originalSaleId],
        limit: 1,
      );

      if (result.isEmpty) {
        // ← Hint: بيع آجل - لم يكن هناك قيد أصلاً
        debugPrint('⏩ [FinancialIntegration] بيع آجل - لا يوجد قيد للحذف');
        return true; // نجاح بدون فعل أي شيء
      }

      // ← Hint: بيع نقدي - يوجد قيد، يجب حذفه بدلاً من تسجيل مرتجع
      debugPrint('🗑️ [FinancialIntegration] بيع نقدي - حذف القيد الأصلي بدلاً من تسجيل مرتجع');
      final transactionId = result.first['TransactionID'] as int;

      await db.delete(
        'TB_Transactions',
        where: 'TransactionID = ?',
        whereArgs: [transactionId],
      );

      debugPrint('✅ [FinancialIntegration] تم حذف القيد المالي للبيع الأصلي');
      return true;

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
  // 💰 الربط التلقائي للمصروفات العامة
  // ==========================================================================

  /// إنشاء قيد مالي تلقائي عند إضافة مصروف عام
  ///
  /// ← Hint: يُستدعى من DatabaseHelper.recordExpense()
  static Future<bool> recordExpenseTransaction({
    required int expenseId,
    required Decimal amount,
    required String expenseDate,
    String? description,
    String? category,
  }) async {
    try {
      debugPrint('🔗 [FinancialIntegration] تسجيل قيد مصروف تلقائياً...');

      final isOpen = await _fiscalYearService.isActiveFiscalYearOpen();
      if (!isOpen) {
        debugPrint('⚠️ [FinancialIntegration] السنة المالية مقفلة - تخطي');
        return false;
      }

      final transaction = await _transactionService.createTransaction(
        type: TransactionType.expense,
        category: TransactionCategory.operatingExpense,
        amount: amount,
        direction: 'out',
        description: description ?? 'مصروف عام - مصروف رقم #$expenseId',
        notes: category,
        referenceType: 'expense',
        referenceId: expenseId,
        transactionDate: DateTime.parse(expenseDate),
      );

      if (transaction != null) {
        debugPrint('✅ [FinancialIntegration] تم تسجيل قيد المصروف (ID: ${transaction.transactionID})');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ [FinancialIntegration] خطأ في recordExpenseTransaction: $e');
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
