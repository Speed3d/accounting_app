// lib/services/fiscal_year_financial_service.dart

import 'package:decimal/decimal.dart';
import '../data/database_helper.dart';

/// 💰 خدمة التقارير المالية للسنة المالية
///
/// ← Hint: هذه الخدمة تجمع البيانات المالية المرتبطة بسنة مالية محددة
/// ← Hint: تستخدم نفس منطق ComprehensiveCashFlowService لكن مع دعم FiscalYear
///
/// **المصادر:**
/// - TB_Invoices: المبيعات (نقدية + آجلة)
/// - Payment_Customer: دفعات الزبائن
/// - TB_Advance_Repayments: تسديدات السلف
/// - TB_Expenses: المصاريف العامة
/// - TB_Payroll: الرواتب
/// - TB_Employee_Advances: السلف
/// - TB_Employee_Bonuses: المكافآت
/// - TB_Profit_Withdrawals: سحوبات الأرباح
/// - Sales_Returns: مرتجعات المبيعات (خصم من المبيعات)
class FiscalYearFinancialService {
  // ============================================================================
  // Singleton Pattern
  // ============================================================================

  static final FiscalYearFinancialService _instance = FiscalYearFinancialService._internal();
  FiscalYearFinancialService._internal();
  factory FiscalYearFinancialService() => _instance;
  static FiscalYearFinancialService get instance => _instance;

  final _db = DatabaseHelper.instance;

  // ============================================================================
  // ← Hint: دالة رئيسية - جلب التقرير المالي للسنة
  // ← Hint: تجمع كل البيانات المالية لسنة مالية محددة
  // ============================================================================

  /// جلب التقرير المالي الشامل لسنة مالية
  ///
  /// **Parameters:**
  /// - fiscalYearId: معرف السنة المالية (مطلوب)
  /// - startDate: تاريخ البداية داخل السنة (اختياري)
  /// - endDate: تاريخ النهاية داخل السنة (اختياري)
  ///
  /// **Returns:**
  /// Map يحتوي على جميع البيانات المالية والإحصائيات
  Future<Map<String, dynamic>> getFinancialReport({
    required int fiscalYearId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // ═══════════════════════════════════════════════════════════
    // جمع بيانات الإيرادات (Revenue)
    // ═══════════════════════════════════════════════════════════

    final grossSales = await _getGrossSalesInPeriod(fiscalYearId, startDate, endDate);
    final salesReturns = await _getSalesReturnsInPeriod(fiscalYearId, startDate, endDate);
    final netSales = grossSales - salesReturns; // ← Hint: المبيعات الصافية

    final customerPayments = await _getCustomerPaymentsInPeriod(fiscalYearId, startDate, endDate);
    final advanceRepayments = await _getAdvanceRepaymentsInPeriod(fiscalYearId, startDate, endDate);

    final totalRevenue = netSales + customerPayments + advanceRepayments;

    // ═══════════════════════════════════════════════════════════
    // جمع بيانات المصروفات (Expenses)
    // ← Hint: المرتجعات لا تُحسب هنا (تم خصمها من المبيعات)
    // ═══════════════════════════════════════════════════════════

    final generalExpenses = await _getGeneralExpensesInPeriod(fiscalYearId, startDate, endDate);
    final salaries = await _getSalariesInPeriod(fiscalYearId, startDate, endDate);
    final advances = await _getAdvancesInPeriod(fiscalYearId, startDate, endDate);
    final bonuses = await _getBonusesInPeriod(fiscalYearId, startDate, endDate);
    final profitWithdrawals = await _getProfitWithdrawalsInPeriod(fiscalYearId, startDate, endDate);

    final totalExpenses = generalExpenses + salaries + advances + bonuses + profitWithdrawals;

    // ═══════════════════════════════════════════════════════════
    // حسابات صافي الربح
    // ═══════════════════════════════════════════════════════════

    final netProfit = totalRevenue - totalExpenses;

    // ═══════════════════════════════════════════════════════════
    // حساب الأعداد
    // ═══════════════════════════════════════════════════════════

    final incomeCount = await _getIncomeCount(fiscalYearId, startDate, endDate);
    final expenseCount = await _getExpenseCount(fiscalYearId, startDate, endDate);

    // ═══════════════════════════════════════════════════════════
    // إرجاع التقرير الشامل
    // ═══════════════════════════════════════════════════════════

    return {
      // --- الملخص العام ---
      'fiscalYearId': fiscalYearId,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'totalIncome': totalRevenue,
      'totalExpense': totalExpenses,
      'netProfit': netProfit,
      'incomeCount': incomeCount,
      'expenseCount': expenseCount,
      'totalCount': incomeCount + expenseCount,

      // --- التفصيل حسب النوع ---
      'breakdown': {
        // الإيرادات
        'sales': netSales,                    // ← Hint: المبيعات الصافية (بعد خصم المرتجعات)
        'grossSales': grossSales,             // ← Hint: إجمالي المبيعات (للعرض)
        'salesReturns': salesReturns,         // ← Hint: المرتجعات (للعرض فقط)
        'customerPayments': customerPayments,
        'advanceRepayments': advanceRepayments,

        // المصروفات (بدون المرتجعات)
        'salaries': salaries,
        'advances': advances,
        'bonuses': bonuses,
        'expenses': generalExpenses,
        'profitWithdrawals': profitWithdrawals,
        'returns': salesReturns, // ← Hint: للتوافق مع الكود القديم (لكن لا تُحسب في المصروفات)
      },
    };
  }

  // ============================================================================
  // دوال خاصة - حساب الإجماليات
  // ============================================================================

  /// إجمالي المبيعات من TB_Invoices (قبل خصم المرتجعات)
  Future<double> _getGrossSalesInPeriod(int fiscalYearId, DateTime? startDate, DateTime? endDate) async {
    final db = await _db.database;

    String sql = '''
      SELECT COALESCE(SUM(TotalAmount), 0) as total
      FROM TB_Invoices
      WHERE IsVoid = 0 AND FiscalYearID = ?
    ''';

    final List<dynamic> args = [fiscalYearId];

    if (startDate != null) {
      sql += ' AND InvoiceDate >= ?';
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      sql += ' AND InvoiceDate <= ?';
      args.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery(sql, args);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// مرتجعات المبيعات من Sales_Returns
  Future<double> _getSalesReturnsInPeriod(int fiscalYearId, DateTime? startDate, DateTime? endDate) async {
    final db = await _db.database;

    String sql = 'SELECT COALESCE(SUM(ReturnAmount), 0) as total FROM Sales_Returns WHERE FiscalYearID = ?';
    final List<dynamic> args = [fiscalYearId];

    if (startDate != null) {
      sql += ' AND ReturnDate >= ?';
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      sql += ' AND ReturnDate <= ?';
      args.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery(sql, args);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// دفعات الزبائن من Payment_Customer
  Future<double> _getCustomerPaymentsInPeriod(int fiscalYearId, DateTime? startDate, DateTime? endDate) async {
    final db = await _db.database;

    String sql = 'SELECT COALESCE(SUM(Payment), 0) as total FROM Payment_Customer WHERE FiscalYearID = ?';
    final List<dynamic> args = [fiscalYearId];

    if (startDate != null) {
      sql += ' AND DateT >= ?';
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      sql += ' AND DateT <= ?';
      args.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery(sql, args);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// تسديدات السلف من TB_Advance_Repayments
  Future<double> _getAdvanceRepaymentsInPeriod(int fiscalYearId, DateTime? startDate, DateTime? endDate) async {
    final db = await _db.database;

    String sql = 'SELECT COALESCE(SUM(RepaymentAmount), 0) as total FROM TB_Advance_Repayments WHERE FiscalYearID = ?';
    final List<dynamic> args = [fiscalYearId];

    if (startDate != null) {
      sql += ' AND RepaymentDate >= ?';
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      sql += ' AND RepaymentDate <= ?';
      args.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery(sql, args);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// المصاريف العامة من TB_Expenses
  Future<double> _getGeneralExpensesInPeriod(int fiscalYearId, DateTime? startDate, DateTime? endDate) async {
    final db = await _db.database;

    String sql = 'SELECT COALESCE(SUM(Amount), 0) as total FROM TB_Expenses WHERE FiscalYearID = ?';
    final List<dynamic> args = [fiscalYearId];

    if (startDate != null) {
      sql += ' AND ExpenseDate >= ?';
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      sql += ' AND ExpenseDate <= ?';
      args.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery(sql, args);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// الرواتب من TB_Payroll
  Future<double> _getSalariesInPeriod(int fiscalYearId, DateTime? startDate, DateTime? endDate) async {
    final db = await _db.database;

    String sql = 'SELECT COALESCE(SUM(NetSalary), 0) as total FROM TB_Payroll WHERE FiscalYearID = ?';
    final List<dynamic> args = [fiscalYearId];

    if (startDate != null) {
      sql += ' AND PaymentDate >= ?';
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      sql += ' AND PaymentDate <= ?';
      args.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery(sql, args);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// السلف من TB_Employee_Advances
  Future<double> _getAdvancesInPeriod(int fiscalYearId, DateTime? startDate, DateTime? endDate) async {
    final db = await _db.database;

    String sql = 'SELECT COALESCE(SUM(AdvanceAmount), 0) as total FROM TB_Employee_Advances WHERE FiscalYearID = ?';
    final List<dynamic> args = [fiscalYearId];

    if (startDate != null) {
      sql += ' AND AdvanceDate >= ?';
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      sql += ' AND AdvanceDate <= ?';
      args.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery(sql, args);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// المكافآت من TB_Employee_Bonuses
  Future<double> _getBonusesInPeriod(int fiscalYearId, DateTime? startDate, DateTime? endDate) async {
    final db = await _db.database;

    String sql = 'SELECT COALESCE(SUM(BonusAmount), 0) as total FROM TB_Employee_Bonuses WHERE FiscalYearID = ?';
    final List<dynamic> args = [fiscalYearId];

    if (startDate != null) {
      sql += ' AND BonusDate >= ?';
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      sql += ' AND BonusDate <= ?';
      args.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery(sql, args);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// سحوبات الأرباح من TB_Profit_Withdrawals
  Future<double> _getProfitWithdrawalsInPeriod(int fiscalYearId, DateTime? startDate, DateTime? endDate) async {
    final db = await _db.database;

    String sql = 'SELECT COALESCE(SUM(WithdrawalAmount), 0) as total FROM TB_Profit_Withdrawals WHERE FiscalYearID = ?';
    final List<dynamic> args = [fiscalYearId];

    if (startDate != null) {
      sql += ' AND WithdrawalDate >= ?';
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      sql += ' AND WithdrawalDate <= ?';
      args.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery(sql, args);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // ============================================================================
  // دوال حساب الأعداد
  // ============================================================================

  /// عدد عمليات الدخل
  Future<int> _getIncomeCount(int fiscalYearId, DateTime? startDate, DateTime? endDate) async {
    final db = await _db.database;

    // نحسب من الجداول الأصلية
    int count = 0;

    // المبيعات
    String sql1 = 'SELECT COUNT(*) as count FROM TB_Invoices WHERE IsVoid = 0 AND FiscalYearID = ?';
    List<dynamic> args1 = [fiscalYearId];
    if (startDate != null) {
      sql1 += ' AND InvoiceDate >= ?';
      args1.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      sql1 += ' AND InvoiceDate <= ?';
      args1.add(endDate.toIso8601String());
    }
    final result1 = await db.rawQuery(sql1, args1);
    count += (result1.first['count'] as int?) ?? 0;

    // دفعات الزبائن
    String sql2 = 'SELECT COUNT(*) as count FROM Payment_Customer WHERE FiscalYearID = ?';
    List<dynamic> args2 = [fiscalYearId];
    if (startDate != null) {
      sql2 += ' AND DateT >= ?';
      args2.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      sql2 += ' AND DateT <= ?';
      args2.add(endDate.toIso8601String());
    }
    final result2 = await db.rawQuery(sql2, args2);
    count += (result2.first['count'] as int?) ?? 0;

    // تسديدات السلف
    String sql3 = 'SELECT COUNT(*) as count FROM TB_Advance_Repayments WHERE FiscalYearID = ?';
    List<dynamic> args3 = [fiscalYearId];
    if (startDate != null) {
      sql3 += ' AND RepaymentDate >= ?';
      args3.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      sql3 += ' AND RepaymentDate <= ?';
      args3.add(endDate.toIso8601String());
    }
    final result3 = await db.rawQuery(sql3, args3);
    count += (result3.first['count'] as int?) ?? 0;

    return count;
  }

  /// عدد عمليات المصروفات
  Future<int> _getExpenseCount(int fiscalYearId, DateTime? startDate, DateTime? endDate) async {
    final db = await _db.database;

    int count = 0;

    // المصاريف العامة
    String sql1 = 'SELECT COUNT(*) as count FROM TB_Expenses WHERE FiscalYearID = ?';
    List<dynamic> args1 = [fiscalYearId];
    if (startDate != null) {
      sql1 += ' AND ExpenseDate >= ?';
      args1.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      sql1 += ' AND ExpenseDate <= ?';
      args1.add(endDate.toIso8601String());
    }
    final result1 = await db.rawQuery(sql1, args1);
    count += (result1.first['count'] as int?) ?? 0;

    // الرواتب
    String sql2 = 'SELECT COUNT(*) as count FROM TB_Payroll WHERE FiscalYearID = ?';
    List<dynamic> args2 = [fiscalYearId];
    if (startDate != null) {
      sql2 += ' AND PaymentDate >= ?';
      args2.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      sql2 += ' AND PaymentDate <= ?';
      args2.add(endDate.toIso8601String());
    }
    final result2 = await db.rawQuery(sql2, args2);
    count += (result2.first['count'] as int?) ?? 0;

    // السلف
    String sql3 = 'SELECT COUNT(*) as count FROM TB_Employee_Advances WHERE FiscalYearID = ?';
    List<dynamic> args3 = [fiscalYearId];
    if (startDate != null) {
      sql3 += ' AND AdvanceDate >= ?';
      args3.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      sql3 += ' AND AdvanceDate <= ?';
      args3.add(endDate.toIso8601String());
    }
    final result3 = await db.rawQuery(sql3, args3);
    count += (result3.first['count'] as int?) ?? 0;

    // المكافآت
    String sql4 = 'SELECT COUNT(*) as count FROM TB_Employee_Bonuses WHERE FiscalYearID = ?';
    List<dynamic> args4 = [fiscalYearId];
    if (startDate != null) {
      sql4 += ' AND BonusDate >= ?';
      args4.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      sql4 += ' AND BonusDate <= ?';
      args4.add(endDate.toIso8601String());
    }
    final result4 = await db.rawQuery(sql4, args4);
    count += (result4.first['count'] as int?) ?? 0;

    // سحوبات الأرباح
    String sql5 = 'SELECT COUNT(*) as count FROM TB_Profit_Withdrawals WHERE FiscalYearID = ?';
    List<dynamic> args5 = [fiscalYearId];
    if (startDate != null) {
      sql5 += ' AND WithdrawalDate >= ?';
      args5.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      sql5 += ' AND WithdrawalDate <= ?';
      args5.add(endDate.toIso8601String());
    }
    final result5 = await db.rawQuery(sql5, args5);
    count += (result5.first['count'] as int?) ?? 0;

    return count;
  }
}
