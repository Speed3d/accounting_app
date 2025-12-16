// lib/services/transaction_service.dart

import 'package:accountant_touch/data/database_helper.dart';
import 'package:accountant_touch/data/models.dart';
import 'package:accountant_touch/services/fiscal_year_service.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

/// ===========================================================================
/// 💰 خدمة إدارة القيود المالية
/// ===========================================================================
///
/// ← Hint: هذه الخدمة هي المسؤولة عن جميع عمليات القيود المالية
/// ← Hint: تدير إنشاء، استعلام، حذف القيود المالية
/// ← Hint: توفر API بسيط وآمن للتعامل مع القيود
/// ← Hint: كل عملية مالية في النظام تمر من هنا
///
/// ===========================================================================

class TransactionService {
  // ==========================================================================
  // Singleton Pattern
  // ← Hint: نستخدم نمط Singleton لضمان instance واحدة فقط
  // ==========================================================================

  static final TransactionService _instance = TransactionService._internal();
  TransactionService._internal();
  factory TransactionService() => _instance;
  static TransactionService get instance => _instance;

  // ==========================================================================
  // Dependencies
  // ← Hint: الاعتماد على FiscalYearService للحصول على السنة النشطة
  // ==========================================================================

  final _fiscalYearService = FiscalYearService.instance;

  // ==========================================================================
  // 1️⃣ إنشاء قيد مالي جديد
  // ← Hint: هذه الدالة الأساسية لتسجيل أي عملية مالية
  // ==========================================================================

  /// إنشاء قيد مالي جديد
  ///
  /// ← Hint: جميع المعاملات تُسجل عبر هذه الدالة
  /// ← Hint: الـ Triggers في قاعدة البيانات تحدّث الأرصدة تلقائياً
  Future<FinancialTransaction?> createTransaction({
    required TransactionType type,
    required TransactionCategory category,
    required Decimal amount,
    required String direction, // "in" أو "out"
    required String description,
    String? notes,
    String? referenceType,
    int? referenceId,
    int? customerId,
    int? supplierId,
    int? employeeId,
    int? productId,
    int? createdBy,
    DateTime? transactionDate,
    int? fiscalYearId, // ← Hint: اختياري - إذا لم يُحدد، يُستخدم السنة النشطة
  }) async {
    try {
      debugPrint('💰 [TransactionService] إنشاء قيد مالي جديد...');
      debugPrint('  ├─ النوع: ${type.name}');
      debugPrint('  ├─ المبلغ: ${amount.toString()}');
      debugPrint('  └─ الاتجاه: $direction');

      // ← Hint: الحصول على السنة المالية
      int targetFiscalYearId;
      if (fiscalYearId != null) {
        targetFiscalYearId = fiscalYearId;
      } else {
        // ← Hint: استخدام السنة النشطة
        final activeFiscalYear = await _fiscalYearService.getActiveFiscalYear();
        if (activeFiscalYear == null) {
          debugPrint('❌ [TransactionService] لا توجد سنة مالية نشطة!');
          return null;
        }

        // ← Hint: التحقق من أن السنة غير مقفلة
        if (activeFiscalYear.isClosed) {
          debugPrint('❌ [TransactionService] السنة المالية النشطة مقفلة!');
          return null;
        }

        targetFiscalYearId = activeFiscalYear.fiscalYearID!;
      }

      // ← Hint: التحقق من صحة البيانات
      if (amount <= Decimal.zero) {
        debugPrint('⚠️ [TransactionService] المبلغ يجب أن يكون أكبر من صفر!');
        return null;
      }

      if (direction != 'in' && direction != 'out') {
        debugPrint('⚠️ [TransactionService] الاتجاه يجب أن يكون "in" أو "out"!');
        return null;
      }

      final db = await DatabaseHelper.instance.database;

      // ← Hint: إنشاء القيد المالي
      final transaction = FinancialTransaction(
        fiscalYearID: targetFiscalYearId,
        date: transactionDate ?? DateTime.now(),
        type: type,
        category: category,
        amount: amount,
        direction: direction,
        description: description,
        notes: notes,
        referenceType: referenceType,
        referenceId: referenceId,
        customerId: customerId,
        supplierId: supplierId,
        employeeId: employeeId,
        productId: productId,
        createdBy: createdBy,
      );

      // ← Hint: حفظ القيد في قاعدة البيانات
      final transactionId = await db.insert(
        'TB_Transactions',
        transaction.toMap(),
      );

      debugPrint('✅ [TransactionService] تم إنشاء القيد (ID: $transactionId)');

      // ← Hint: إعادة القيد المحفوظ
      return await getTransactionById(transactionId);
    } catch (e) {
      debugPrint('❌ [TransactionService] خطأ في createTransaction: $e');
      return null;
    }
  }

  // ==========================================================================
  // 2️⃣ الحصول على قيد مالي بواسطة المعرف
  // ==========================================================================

  /// الحصول على قيد مالي بواسطة معرفه
  Future<FinancialTransaction?> getTransactionById(int transactionId) async {
    try {
      final db = await DatabaseHelper.instance.database;

      final List<Map<String, dynamic>> maps = await db.query(
        'TB_Transactions',
        where: 'TransactionID = ?',
        whereArgs: [transactionId],
        limit: 1,
      );

      if (maps.isEmpty) return null;

      return FinancialTransaction.fromMap(maps.first);
    } catch (e) {
      debugPrint('❌ [TransactionService] خطأ في getTransactionById: $e');
      return null;
    }
  }

  // ==========================================================================
  // 3️⃣ الحصول على القيود بفلاتر متعددة
  // ==========================================================================

  /// الحصول على قائمة القيود المالية مع إمكانية الفلترة
  ///
  /// ← Hint: دالة مرنة جداً تدعم فلاتر متعددة
  Future<List<FinancialTransaction>> getTransactions({
    int? fiscalYearId,        // ← Hint: فلتر حسب السنة المالية
    TransactionType? type,    // ← Hint: فلتر حسب النوع
    String? direction,        // ← Hint: فلتر حسب الاتجاه (in/out)
    int? customerId,          // ← Hint: فلتر حسب الزبون
    int? employeeId,          // ← Hint: فلتر حسب الموظف
    DateTime? startDate,      // ← Hint: فلتر حسب تاريخ البداية
    DateTime? endDate,        // ← Hint: فلتر حسب تاريخ النهاية
    int? limit,               // ← Hint: عدد السجلات المطلوبة
    String orderBy = 'Date DESC', // ← Hint: ترتيب النتائج
  }) async {
    try {
      debugPrint('📋 [TransactionService] جلب القيود المالية...');

      final db = await DatabaseHelper.instance.database;

      // ← Hint: بناء الـ WHERE clause ديناميكياً
      final whereClauses = <String>[];
      final whereArgs = <dynamic>[];

      if (fiscalYearId != null) {
        whereClauses.add('FiscalYearID = ?');
        whereArgs.add(fiscalYearId);
      }

      if (type != null) {
        whereClauses.add('Type = ?');
        whereArgs.add(type.name);
      }

      if (direction != null) {
        whereClauses.add('Direction = ?');
        whereArgs.add(direction);
      }

      if (customerId != null) {
        whereClauses.add('CustomerID = ?');
        whereArgs.add(customerId);
      }

      if (employeeId != null) {
        whereClauses.add('EmployeeID = ?');
        whereArgs.add(employeeId);
      }

      if (startDate != null) {
        whereClauses.add('Date >= ?');
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        whereClauses.add('Date <= ?');
        whereArgs.add(endDate.toIso8601String());
      }

      final String? whereClause =
          whereClauses.isEmpty ? null : whereClauses.join(' AND ');

      // ← Hint: تنفيذ الاستعلام
      final List<Map<String, dynamic>> maps = await db.query(
        'TB_Transactions',
        where: whereClause,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: orderBy,
        limit: limit,
      );

      final transactions =
          maps.map((map) => FinancialTransaction.fromMap(map)).toList();

      debugPrint('✅ [TransactionService] تم جلب ${transactions.length} قيد');

      return transactions;
    } catch (e) {
      debugPrint('❌ [TransactionService] خطأ في getTransactions: $e');
      return [];
    }
  }

  // ==========================================================================
  // 4️⃣ الحصول على قيود سنة مالية محددة
  // ==========================================================================

  /// الحصول على جميع قيود سنة مالية محددة
  Future<List<FinancialTransaction>> getTransactionsByFiscalYear(
    int fiscalYearId,
  ) async {
    return await getTransactions(fiscalYearId: fiscalYearId);
  }

  /// الحصول على قيود السنة المالية النشطة
  Future<List<FinancialTransaction>> getActiveYearTransactions() async {
    final activeFiscalYear = await _fiscalYearService.getActiveFiscalYear();
    if (activeFiscalYear == null) return [];

    return await getTransactions(
      fiscalYearId: activeFiscalYear.fiscalYearID,
    );
  }

  // ==========================================================================
  // 5️⃣ الحصول على قيود حسب النوع
  // ==========================================================================

  /// الحصول على قيود المبيعات
  Future<List<FinancialTransaction>> getSalesTransactions({
    int? fiscalYearId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await getTransactions(
      fiscalYearId: fiscalYearId,
      type: TransactionType.sale,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// الحصول على قيود الرواتب
  Future<List<FinancialTransaction>> getSalaryTransactions({
    int? fiscalYearId,
    int? employeeId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await getTransactions(
      fiscalYearId: fiscalYearId,
      type: TransactionType.salary,
      employeeId: employeeId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// الحصول على قيود السلف
  Future<List<FinancialTransaction>> getAdvanceTransactions({
    int? fiscalYearId,
    int? employeeId,
  }) async {
    return await getTransactions(
      fiscalYearId: fiscalYearId,
      type: TransactionType.employeeAdvance,
      employeeId: employeeId,
    );
  }

  // ==========================================================================
  // 6️⃣ الحصول على قيود حسب الاتجاه
  // ==========================================================================

  /// الحصول على قيود الدخل فقط
  Future<List<FinancialTransaction>> getIncomeTransactions({
    int? fiscalYearId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await getTransactions(
      fiscalYearId: fiscalYearId,
      direction: 'in',
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// الحصول على قيود المصروفات فقط
  Future<List<FinancialTransaction>> getExpenseTransactions({
    int? fiscalYearId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await getTransactions(
      fiscalYearId: fiscalYearId,
      direction: 'out',
      startDate: startDate,
      endDate: endDate,
    );
  }

  // ==========================================================================
  // 7️⃣ حذف قيد مالي
  // ==========================================================================

  /// حذف قيد مالي
  ///
  /// ← Hint: عملية حساسة - تؤثر على أرصدة السنة المالية
  /// ← Hint: الـ Trigger يحدّث الأرصدة تلقائياً
  Future<bool> deleteTransaction(int transactionId) async {
    try {
      debugPrint('🗑️ [TransactionService] حذف القيد (ID: $transactionId)...');

      // ← Hint: الحصول على القيد أولاً
      final transaction = await getTransactionById(transactionId);
      if (transaction == null) {
        debugPrint('⚠️ [TransactionService] القيد غير موجود!');
        return false;
      }

      // ← Hint: التحقق من أن السنة المالية غير مقفلة
      final fiscalYear = await _fiscalYearService.getFiscalYearById(
        transaction.fiscalYearID,
      );

      if (fiscalYear != null && fiscalYear.isClosed) {
        debugPrint('⚠️ [TransactionService] لا يمكن حذف قيد من سنة مقفلة!');
        return false;
      }

      final db = await DatabaseHelper.instance.database;

      // ← Hint: حذف القيد
      await db.delete(
        'TB_Transactions',
        where: 'TransactionID = ?',
        whereArgs: [transactionId],
      );

      debugPrint('✅ [TransactionService] تم حذف القيد بنجاح');

      return true;
    } catch (e) {
      debugPrint('❌ [TransactionService] خطأ في deleteTransaction: $e');
      return false;
    }
  }

  // ==========================================================================
  // 8️⃣ إحصائيات وتقارير
  // ==========================================================================

  /// حساب إجمالي الدخل لفترة معينة
  Future<Decimal> getTotalIncome({
    int? fiscalYearId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // ← Hint: بناء الـ WHERE clause
      final whereClauses = <String>['Direction = ?'];
      final whereArgs = <dynamic>['in'];

      if (fiscalYearId != null) {
        whereClauses.add('FiscalYearID = ?');
        whereArgs.add(fiscalYearId);
      }

      if (startDate != null) {
        whereClauses.add('Date >= ?');
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        whereClauses.add('Date <= ?');
        whereArgs.add(endDate.toIso8601String());
      }

      final result = await db.rawQuery('''
        SELECT COALESCE(SUM(Amount), 0) as total
        FROM TB_Transactions
        WHERE ${whereClauses.join(' AND ')}
      ''', whereArgs);

      final total = (result.first['total'] as num).toDouble();
      return Decimal.parse(total.toString());
    } catch (e) {
      debugPrint('❌ [TransactionService] خطأ في getTotalIncome: $e');
      return Decimal.zero;
    }
  }

  /// حساب إجمالي المصروفات لفترة معينة
  Future<Decimal> getTotalExpense({
    int? fiscalYearId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // ← Hint: بناء الـ WHERE clause
      final whereClauses = <String>['Direction = ?'];
      final whereArgs = <dynamic>['out'];

      if (fiscalYearId != null) {
        whereClauses.add('FiscalYearID = ?');
        whereArgs.add(fiscalYearId);
      }

      if (startDate != null) {
        whereClauses.add('Date >= ?');
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        whereClauses.add('Date <= ?');
        whereArgs.add(endDate.toIso8601String());
      }

      final result = await db.rawQuery('''
        SELECT COALESCE(SUM(Amount), 0) as total
        FROM TB_Transactions
        WHERE ${whereClauses.join(' AND ')}
      ''', whereArgs);

      final total = (result.first['total'] as num).toDouble();
      return Decimal.parse(total.toString());
    } catch (e) {
      debugPrint('❌ [TransactionService] خطأ في getTotalExpense: $e');
      return Decimal.zero;
    }
  }

  /// حساب صافي الربح لفترة معينة
  Future<Decimal> getNetProfit({
    int? fiscalYearId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final income = await getTotalIncome(
      fiscalYearId: fiscalYearId,
      startDate: startDate,
      endDate: endDate,
    );

    final expense = await getTotalExpense(
      fiscalYearId: fiscalYearId,
      startDate: startDate,
      endDate: endDate,
    );

    return income - expense;
  }

  /// عدد القيود لفترة معينة
  Future<int> getTransactionCount({
    int? fiscalYearId,
    TransactionType? type,
    String? direction,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // ← Hint: بناء الـ WHERE clause
      final whereClauses = <String>[];
      final whereArgs = <dynamic>[];

      if (fiscalYearId != null) {
        whereClauses.add('FiscalYearID = ?');
        whereArgs.add(fiscalYearId);
      }

      if (type != null) {
        whereClauses.add('Type = ?');
        whereArgs.add(type.name);
      }

      if (direction != null) {
        whereClauses.add('Direction = ?');
        whereArgs.add(direction);
      }

      if (startDate != null) {
        whereClauses.add('Date >= ?');
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        whereClauses.add('Date <= ?');
        whereArgs.add(endDate.toIso8601String());
      }

      final whereClause =
          whereClauses.isEmpty ? null : whereClauses.join(' AND ');

      final result = await db.rawQuery('''
        SELECT COUNT(*) as count
        FROM TB_Transactions
        ${whereClause != null ? 'WHERE $whereClause' : ''}
      ''', whereArgs.isEmpty ? null : whereArgs);

      return (result.first['count'] as int?) ?? 0;
    } catch (e) {
      debugPrint('❌ [TransactionService] خطأ في getTransactionCount: $e');
      return 0;
    }
  }

  // ==========================================================================
  // 9️⃣ تقرير شامل للحركة المالية
  // ==========================================================================

  /// الحصول على تقرير شامل للحركة المالية
  ///
  /// ← Hint: يعيد Map يحتوي على جميع الإحصائيات
  Future<Map<String, dynamic>> getFinancialSummary({
    int? fiscalYearId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint('📊 [TransactionService] إعداد التقرير المالي الشامل...');

      // ← Hint: إذا لم يُحدد fiscalYearId، نستخدم السنة النشطة
      int? targetFiscalYearId = fiscalYearId;
      if (targetFiscalYearId == null) {
        final activeFiscalYear = await _fiscalYearService.getActiveFiscalYear();
        targetFiscalYearId = activeFiscalYear?.fiscalYearID;
      }

      // ← Hint: جمع الإحصائيات
      final totalIncome = await getTotalIncome(
        fiscalYearId: targetFiscalYearId,
        startDate: startDate,
        endDate: endDate,
      );

      final totalExpense = await getTotalExpense(
        fiscalYearId: targetFiscalYearId,
        startDate: startDate,
        endDate: endDate,
      );

      final netProfit = totalIncome - totalExpense;

      final incomeCount = await getTransactionCount(
        fiscalYearId: targetFiscalYearId,
        direction: 'in',
        startDate: startDate,
        endDate: endDate,
      );

      final expenseCount = await getTransactionCount(
        fiscalYearId: targetFiscalYearId,
        direction: 'out',
        startDate: startDate,
        endDate: endDate,
      );

      final totalCount = incomeCount + expenseCount;

      // ← Hint: تفصيل حسب النوع
      final salesTotal = await _getTotalByType(
        TransactionType.sale,
        fiscalYearId: targetFiscalYearId,
        startDate: startDate,
        endDate: endDate,
      );

      final customerPaymentsTotal = await _getTotalByType(
        TransactionType.customerPayment,
        fiscalYearId: targetFiscalYearId,
        startDate: startDate,
        endDate: endDate,
      );

      final salariesTotal = await _getTotalByType(
        TransactionType.salary,
        fiscalYearId: targetFiscalYearId,
        startDate: startDate,
        endDate: endDate,
      );

      final advancesTotal = await _getTotalByType(
        TransactionType.employeeAdvance,
        fiscalYearId: targetFiscalYearId,
        startDate: startDate,
        endDate: endDate,
      );

      final bonusesTotal = await _getTotalByType(
        TransactionType.employeeBonus,
        fiscalYearId: targetFiscalYearId,
        startDate: startDate,
        endDate: endDate,
      );

      final returnsTotal = await _getTotalByType(
        TransactionType.saleReturn,
        fiscalYearId: targetFiscalYearId,
        startDate: startDate,
        endDate: endDate,
      );

      final advanceRepaymentsTotal = await _getTotalByType(
        TransactionType.advanceRepayment,
        fiscalYearId: targetFiscalYearId,
        startDate: startDate,
        endDate: endDate,
      );

      // ← Hint: المصروفات العامة من TB_Transactions (النوع: expense)
      final expensesTotal = await _getTotalByType(
        TransactionType.expense,
        fiscalYearId: targetFiscalYearId,
        startDate: startDate,
        endDate: endDate,
      );

      // ← Hint: سحوبات الأرباح/الشركاء (النوع: other مع category خاصة أو من جدول منفصل)
      // سيتم جلبها من جدول TB_Profit_Withdrawals إذا لزم الأمر
      final profitWithdrawalsTotal = await _getProfitWithdrawalsFromDB(
        fiscalYearId: targetFiscalYearId,
        startDate: startDate,
        endDate: endDate,
      );

      final summary = {
        'fiscalYearId': targetFiscalYearId,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'totalIncome': totalIncome.toDouble(),
        'totalExpense': totalExpense.toDouble(),
        'netProfit': netProfit.toDouble(),
        'incomeCount': incomeCount,
        'expenseCount': expenseCount,
        'totalCount': totalCount,
        'breakdown': {
          'sales': salesTotal.toDouble(),
          'customerPayments': customerPaymentsTotal.toDouble(),
          'advanceRepayments': advanceRepaymentsTotal.toDouble(),
          'salaries': salariesTotal.toDouble(),
          'advances': advancesTotal.toDouble(),
          'bonuses': bonusesTotal.toDouble(),
          'returns': returnsTotal.toDouble(),
          'expenses': expensesTotal.toDouble(),
          'profitWithdrawals': profitWithdrawalsTotal.toDouble(),
        },
      };

      debugPrint('✅ [TransactionService] تم إعداد التقرير المالي');

      return summary;
    } catch (e) {
      debugPrint('❌ [TransactionService] خطأ في getFinancialSummary: $e');
      return {};
    }
  }

  // ← Hint: دالة مساعدة لحساب الإجمالي حسب النوع
  Future<Decimal> _getTotalByType(
    TransactionType type, {
    int? fiscalYearId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;

      final whereClauses = <String>['Type = ?'];
      final whereArgs = <dynamic>[type.name];

      if (fiscalYearId != null) {
        whereClauses.add('FiscalYearID = ?');
        whereArgs.add(fiscalYearId);
      }

      if (startDate != null) {
        whereClauses.add('Date >= ?');
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        whereClauses.add('Date <= ?');
        whereArgs.add(endDate.toIso8601String());
      }

      final result = await db.rawQuery('''
        SELECT COALESCE(SUM(Amount), 0) as total
        FROM TB_Transactions
        WHERE ${whereClauses.join(' AND ')}
      ''', whereArgs);

      final total = (result.first['total'] as num).toDouble();
      return Decimal.parse(total.toString());
    } catch (e) {
      return Decimal.zero;
    }
  }

  // ==========================================================================
  // 🔟 دوال مساعدة للربط التلقائي
  // ==========================================================================

  /// إنشاء قيد مبيعات تلقائياً
  ///
  /// ← Hint: يُستدعى عند إضافة مبيعة جديدة
  Future<FinancialTransaction?> createSaleTransaction({
    required int saleId,
    required Decimal amount,
    required int customerId,
    int? productId,
    String? notes,
    DateTime? saleDate,
  }) async {
    return await createTransaction(
      type: TransactionType.sale,
      category: TransactionCategory.revenue,
      amount: amount,
      direction: 'in',
      description: 'مبيعات - عملية رقم #$saleId',
      notes: notes,
      referenceType: 'sale',
      referenceId: saleId,
      customerId: customerId,
      productId: productId,
      transactionDate: saleDate,
    );
  }

  /// إنشاء قيد راتب تلقائياً
  ///
  /// ← Hint: يُستدعى عند دفع راتب موظف
  Future<FinancialTransaction?> createSalaryTransaction({
    required int payrollId,
    required int employeeId,
    required Decimal amount,
    String? notes,
    DateTime? paymentDate,
  }) async {
    return await createTransaction(
      type: TransactionType.salary,
      category: TransactionCategory.salaryExpense,
      amount: amount,
      direction: 'out',
      description: 'راتب موظف - سجل رقم #$payrollId',
      notes: notes,
      referenceType: 'payroll',
      referenceId: payrollId,
      employeeId: employeeId,
      transactionDate: paymentDate,
    );
  }

  /// إنشاء قيد سلفة تلقائياً
  ///
  /// ← Hint: يُستدعى عند إعطاء سلفة لموظف
  Future<FinancialTransaction?> createAdvanceTransaction({
    required int advanceId,
    required int employeeId,
    required Decimal amount,
    String? notes,
    DateTime? advanceDate,
  }) async {
    return await createTransaction(
      type: TransactionType.employeeAdvance,
      category: TransactionCategory.advanceExpense,
      amount: amount,
      direction: 'out',
      description: 'سلفة موظف - سلفة رقم #$advanceId',
      notes: notes,
      referenceType: 'advance',
      referenceId: advanceId,
      employeeId: employeeId,
      transactionDate: advanceDate,
    );
  }

  /// إنشاء قيد تسديد سلفة تلقائياً
  ///
  /// ← Hint: يُستدعى عند تسديد سلفة
  Future<FinancialTransaction?> createAdvanceRepaymentTransaction({
    required int repaymentId,
    required int advanceId,
    required int employeeId,
    required Decimal amount,
    String? notes,
    DateTime? repaymentDate,
  }) async {
    return await createTransaction(
      type: TransactionType.advanceRepayment,
      category: TransactionCategory.revenue,
      amount: amount,
      direction: 'in',
      description: 'تسديد سلفة - تسديد رقم #$repaymentId',
      notes: notes,
      referenceType: 'advance_repayment',
      referenceId: repaymentId,
      employeeId: employeeId,
      transactionDate: repaymentDate,
    );
  }

  /// إنشاء قيد دفعة زبون تلقائياً
  ///
  /// ← Hint: يُستدعى عند استلام دفعة من زبون
  Future<FinancialTransaction?> createCustomerPaymentTransaction({
    required int paymentId,
    required int customerId,
    required Decimal amount,
    String? notes,
    DateTime? paymentDate,
  }) async {
    return await createTransaction(
      type: TransactionType.customerPayment,
      category: TransactionCategory.revenue,
      amount: amount,
      direction: 'in',
      description: 'دفعة زبون - دفعة رقم #$paymentId',
      notes: notes,
      referenceType: 'customer_payment',
      referenceId: paymentId,
      customerId: customerId,
      transactionDate: paymentDate,
    );
  }

  /// إنشاء قيد مرتجع مبيعات تلقائياً
  ///
  /// ← Hint: يُستدعى عند إرجاع منتج
  Future<FinancialTransaction?> createSaleReturnTransaction({
    required int returnId,
    required int saleId,
    required int customerId,
    required Decimal amount,
    String? notes,
    DateTime? returnDate,
  }) async {
    return await createTransaction(
      type: TransactionType.saleReturn,
      category: TransactionCategory.returnExpense,
      amount: amount,
      direction: 'out',
      description: 'مرتجع مبيعات - مرتجع رقم #$returnId',
      notes: notes,
      referenceType: 'sale_return',
      referenceId: returnId,
      customerId: customerId,
      transactionDate: returnDate,
    );
  }

  // ==========================================================================
  // 🔟1 جلب سحوبات الأرباح من جدول TB_Profit_Withdrawals
  // ==========================================================================

  /// جلب إجمالي سحوبات الأرباح من جدول TB_Profit_Withdrawals
  ///
  /// ← Hint: هذا جدول منفصل عن TB_Transactions
  /// ← Hint: نجمع البيانات مباشرة من قاعدة البيانات
  Future<Decimal> _getProfitWithdrawalsFromDB({
    int? fiscalYearId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // ← Hint: بناء الـ WHERE clause
      final whereClauses = <String>[];
      final whereArgs = <dynamic>[];

      if (startDate != null) {
        whereClauses.add('WithdrawalDate >= ?');
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        whereClauses.add('WithdrawalDate <= ?');
        whereArgs.add(endDate.toIso8601String());
      }

      final whereClause =
          whereClauses.isEmpty ? '1=1' : whereClauses.join(' AND ');

      final result = await db.rawQuery('''
        SELECT COALESCE(SUM(WithdrawalAmount), 0) as total
        FROM TB_Profit_Withdrawals
        WHERE $whereClause
      ''', whereArgs.isEmpty ? null : whereArgs);

      final total = (result.first['total'] as num).toDouble();
      return Decimal.parse(total.toString());
    } catch (e) {
      debugPrint('❌ [TransactionService] خطأ في _getProfitWithdrawalsFromDB: $e');
      return Decimal.zero;
    }
  }
}
