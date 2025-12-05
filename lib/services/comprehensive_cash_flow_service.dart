// lib/services/comprehensive_cash_flow_service.dart

import 'package:decimal/decimal.dart';
import '../data/database_helper.dart';

/// 💰 خدمة التدفقات النقدية الشاملة
///
/// ← Hint: هذه الخدمة تجمع جميع البيانات المالية من مصادر مختلفة
/// ← Hint: تستخدم لحساب الإيرادات والمصروفات وصافي التدفق النقدي
///
/// **المصادر:**
/// - TB_Invoices: المبيعات النقدية
/// - Payment_Customer: دفعات الزبائن
/// - Sales_Returns: مرتجعات المبيعات
/// - TB_Expenses: المصاريف العامة
/// - TB_Payroll: الرواتب
/// - TB_Employee_Advances: السلف
/// - TB_Employee_Bonuses: المكافآت
/// - TB_Profit_Withdrawals: سحوبات الأرباح
class ComprehensiveCashFlowService {
  // ============================================================================
  // Singleton Pattern
  // ============================================================================

  static final ComprehensiveCashFlowService _instance = ComprehensiveCashFlowService._internal();
  ComprehensiveCashFlowService._internal();
  factory ComprehensiveCashFlowService() => _instance;
  static ComprehensiveCashFlowService get instance => _instance;

  final _db = DatabaseHelper.instance;

  // ============================================================================
  // ← Hint: دالة رئيسية - جلب التقرير الشامل
  // ← Hint: تجمع كل البيانات المالية في فترة زمنية محددة
  // ============================================================================

  /// جلب التقرير المالي الشامل
  ///
  /// **Parameters:**
  /// - startDate: تاريخ البداية (اختياري)
  /// - endDate: تاريخ النهاية (اختياري)
  ///
  /// **Returns:**
  /// Map يحتوي على جميع البيانات المالية والإحصائيات
  Future<Map<String, dynamic>> getComprehensiveReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // ═══════════════════════════════════════════════════════════
    // جمع بيانات الإيرادات (Revenue)
    // ═══════════════════════════════════════════════════════════

    final cashSales = await _getCashSalesInPeriod(startDate, endDate);
    final customerPayments = await _getCustomerPaymentsInPeriod(startDate, endDate);

    final totalRevenue = cashSales + customerPayments;

    // ═══════════════════════════════════════════════════════════
    // جمع بيانات المصروفات (Expenses)
    // ═══════════════════════════════════════════════════════════

    final generalExpenses = await _getGeneralExpensesInPeriod(startDate, endDate);
    final salaries = await _getSalariesInPeriod(startDate, endDate);
    final advances = await _getAdvancesInPeriod(startDate, endDate);
    final bonuses = await _getBonusesInPeriod(startDate, endDate); // ← إضافة المكافآت من TB_Employee_Bonuses
    final profitWithdrawals = await _getProfitWithdrawalsInPeriod(startDate, endDate);

    final totalExpenses = generalExpenses + salaries + advances + bonuses + profitWithdrawals;

    // ═══════════════════════════════════════════════════════════
    // حسابات صافي التدفق النقدي
    // ═══════════════════════════════════════════════════════════

    final netCashFlow = totalRevenue - totalExpenses;
    final profitMargin = totalRevenue > 0 ? (netCashFlow / totalRevenue) * 100 : 0.0;

    // ═══════════════════════════════════════════════════════════
    // جمع التفاصيل
    // ═══════════════════════════════════════════════════════════

    final cashSalesDetails = await _getCashSalesDetails(startDate, endDate);
    final customerPaymentsDetails = await _getCustomerPaymentsDetails(startDate, endDate);
    final expensesDetails = await _getExpensesDetails(startDate, endDate);
    final salariesDetails = await _getSalariesDetails(startDate, endDate);
    final advancesDetails = await _getAdvancesDetails(startDate, endDate);
    final bonusesDetails = await _getBonusesDetails(startDate, endDate); // ← إضافة تفاصيل المكافآت
    final withdrawalsDetails = await _getWithdrawalsDetails(startDate, endDate);

    // ═══════════════════════════════════════════════════════════
    // إرجاع التقرير الشامل
    // ═══════════════════════════════════════════════════════════

    return {
      // --- الملخص العام ---
      'summary': {
        'totalRevenue': totalRevenue,
        'totalExpenses': totalExpenses,
        'netCashFlow': netCashFlow,
        'profitMargin': profitMargin,
      },

      // --- تفاصيل الإيرادات ---
      'revenue': {
        'cashSales': cashSales,
        'customerPayments': customerPayments,
        'total': totalRevenue,
        'details': {
          'cashSales': cashSalesDetails,
          'customerPayments': customerPaymentsDetails,
        },
      },

      // --- تفاصيل المصروفات ---
      'expenses': {
        'generalExpenses': generalExpenses,
        'salaries': salaries,
        'advances': advances,
        'bonuses': bonuses, // ← إضافة المكافآت
        'profitWithdrawals': profitWithdrawals,
        'total': totalExpenses,
        'details': {
          'generalExpenses': expensesDetails,
          'salaries': salariesDetails,
          'advances': advancesDetails,
          'bonuses': bonusesDetails, // ← إضافة تفاصيل المكافآت
          'profitWithdrawals': withdrawalsDetails,
        },
      },

      // --- الفترة الزمنية ---
      'period': {
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
      },
    };
  }

  // ============================================================================
  // دوال خاصة - حساب الإجماليات
  // ============================================================================

  /// المبيعات النقدية من TB_Invoices
  Future<double> _getCashSalesInPeriod(DateTime? startDate, DateTime? endDate) async {
    final db = await _db.database;

    String sql = '''
      SELECT SUM(TotalAmount) as total
      FROM TB_Invoices
      WHERE IsVoid = 0
    ''';

    final List<dynamic> args = [];

    if (startDate != null) {
      sql += ' AND InvoiceDate >= ?';
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      sql += ' AND InvoiceDate <= ?';
      args.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery(sql, args);
    return result.first['total'] != null ? (result.first['total'] as num).toDouble() : 0.0;
  }

  /// دفعات الزبائن من Payment_Customer
  Future<double> _getCustomerPaymentsInPeriod(DateTime? startDate, DateTime? endDate) async {
    final db = await _db.database;

    String sql = 'SELECT SUM(Payment) as total FROM Payment_Customer WHERE 1=1';
    final List<dynamic> args = [];

    if (startDate != null) {
      sql += ' AND DateT >= ?';
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      sql += ' AND DateT <= ?';
      args.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery(sql, args);
    return result.first['total'] != null ? (result.first['total'] as num).toDouble() : 0.0;
  }

  /// مرتجعات المبيعات من Sales_Returns
  Future<double> _getSalesReturnsInPeriod(DateTime? startDate, DateTime? endDate) async {
    final db = await _db.database;

    String sql = 'SELECT SUM(ReturnAmount) as total FROM Sales_Returns WHERE 1=1';
    final List<dynamic> args = [];

    if (startDate != null) {
      sql += ' AND ReturnDate >= ?';
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      sql += ' AND ReturnDate <= ?';
      args.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery(sql, args);
    return result.first['total'] != null ? (result.first['total'] as num).toDouble() : 0.0;
  }

  /// المصاريف العامة من TB_Expenses
  Future<double> _getGeneralExpensesInPeriod(DateTime? startDate, DateTime? endDate) async {
    final db = await _db.database;

    String sql = 'SELECT SUM(Amount) as total FROM TB_Expenses WHERE 1=1';
    final List<dynamic> args = [];

    if (startDate != null) {
      sql += ' AND ExpenseDate >= ?';
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      sql += ' AND ExpenseDate <= ?';
      args.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery(sql, args);
    return result.first['total'] != null ? (result.first['total'] as num).toDouble() : 0.0;
  }

  /// الرواتب من TB_Payroll
  Future<double> _getSalariesInPeriod(DateTime? startDate, DateTime? endDate) async {
    final db = await _db.database;

    String sql = 'SELECT SUM(NetSalary) as total FROM TB_Payroll WHERE 1=1';
    final List<dynamic> args = [];

    if (startDate != null) {
      sql += ' AND PaymentDate >= ?';
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      sql += ' AND PaymentDate <= ?';
      args.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery(sql, args);
    return result.first['total'] != null ? (result.first['total'] as num).toDouble() : 0.0;
  }

  /// السلف من TB_Employee_Advances
  Future<double> _getAdvancesInPeriod(DateTime? startDate, DateTime? endDate) async {
    final db = await _db.database;

    String sql = 'SELECT SUM(AdvanceAmount) as total FROM TB_Employee_Advances WHERE 1=1';
    final List<dynamic> args = [];

    if (startDate != null) {
      sql += ' AND AdvanceDate >= ?';
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      sql += ' AND AdvanceDate <= ?';
      args.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery(sql, args);
    return result.first['total'] != null ? (result.first['total'] as num).toDouble() : 0.0;
  }

  /// المكافآت من TB_Employee_Bonuses
  Future<double> _getBonusesInPeriod(DateTime? startDate, DateTime? endDate) async {
    return await _db.getTotalBonusesInPeriod(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// سحوبات الأرباح من TB_Profit_Withdrawals
  Future<double> _getProfitWithdrawalsInPeriod(DateTime? startDate, DateTime? endDate) async {
    final db = await _db.database;

    String sql = 'SELECT SUM(WithdrawalAmount) as total FROM TB_Profit_Withdrawals WHERE 1=1';
    final List<dynamic> args = [];

    if (startDate != null) {
      sql += ' AND WithdrawalDate >= ?';
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      sql += ' AND WithdrawalDate <= ?';
      args.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery(sql, args);
    return result.first['total'] != null ? (result.first['total'] as num).toDouble() : 0.0;
  }

  // ============================================================================
  // دوال خاصة - جلب التفاصيل
  // ============================================================================

  /// تفاصيل المبيعات النقدية
  Future<List<Map<String, dynamic>>> _getCashSalesDetails(DateTime? startDate, DateTime? endDate) async {
    final db = await _db.database;

    String sql = '''
      SELECT
        I.*,
        C.CustomerName
      FROM TB_Invoices I
      INNER JOIN TB_Customer C ON I.CustomerID = C.CustomerID
      WHERE I.IsVoid = 0
    ''';

    final List<dynamic> args = [];

    if (startDate != null) {
      sql += ' AND I.InvoiceDate >= ?';
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      sql += ' AND I.InvoiceDate <= ?';
      args.add(endDate.toIso8601String());
    }

    sql += ' ORDER BY I.InvoiceDate DESC';

    return await db.rawQuery(sql, args);
  }

  /// تفاصيل دفعات الزبائن
  Future<List<Map<String, dynamic>>> _getCustomerPaymentsDetails(DateTime? startDate, DateTime? endDate) async {
    final db = await _db.database;

    String sql = 'SELECT * FROM Payment_Customer WHERE 1=1';
    final List<dynamic> args = [];

    if (startDate != null) {
      sql += ' AND DateT >= ?';
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      sql += ' AND DateT <= ?';
      args.add(endDate.toIso8601String());
    }

    sql += ' ORDER BY DateT DESC';

    return await db.rawQuery(sql, args);
  }

  /// تفاصيل مرتجعات المبيعات
  Future<List<Map<String, dynamic>>> _getSalesReturnsDetails(DateTime? startDate, DateTime? endDate) async {
    final db = await _db.database;

    String sql = '''
      SELECT
        SR.*,
        C.CustomerName,
        P.ProductName
      FROM Sales_Returns SR
      INNER JOIN TB_Customer C ON SR.CustomerID = C.CustomerID
      INNER JOIN Store_Products P ON SR.ProductID = P.ProductID
      WHERE 1=1
    ''';

    final List<dynamic> args = [];

    if (startDate != null) {
      sql += ' AND SR.ReturnDate >= ?';
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      sql += ' AND SR.ReturnDate <= ?';
      args.add(endDate.toIso8601String());
    }

    sql += ' ORDER BY SR.ReturnDate DESC';

    return await db.rawQuery(sql, args);
  }

  /// تفاصيل المصاريف العامة
  Future<List<Map<String, dynamic>>> _getExpensesDetails(DateTime? startDate, DateTime? endDate) async {
    final db = await _db.database;

    String sql = 'SELECT * FROM TB_Expenses WHERE 1=1';
    final List<dynamic> args = [];

    if (startDate != null) {
      sql += ' AND ExpenseDate >= ?';
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      sql += ' AND ExpenseDate <= ?';
      args.add(endDate.toIso8601String());
    }

    sql += ' ORDER BY ExpenseDate DESC';

    return await db.rawQuery(sql, args);
  }

  /// تفاصيل الرواتب
  Future<List<Map<String, dynamic>>> _getSalariesDetails(DateTime? startDate, DateTime? endDate) async {
    final db = await _db.database;

    String sql = '''
      SELECT
        P.*,
        E.FullName as EmployeeName
      FROM TB_Payroll P
      INNER JOIN TB_Employees E ON P.EmployeeID = E.EmployeeID
      WHERE 1=1
    ''';

    final List<dynamic> args = [];

    if (startDate != null) {
      sql += ' AND P.PaymentDate >= ?';
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      sql += ' AND P.PaymentDate <= ?';
      args.add(endDate.toIso8601String());
    }

    sql += ' ORDER BY P.PaymentDate DESC';

    return await db.rawQuery(sql, args);
  }

  /// تفاصيل السلف
  Future<List<Map<String, dynamic>>> _getAdvancesDetails(DateTime? startDate, DateTime? endDate) async {
    final db = await _db.database;

    String sql = '''
      SELECT
        A.*,
        E.FullName as EmployeeName
      FROM TB_Employee_Advances A
      INNER JOIN TB_Employees E ON A.EmployeeID = E.EmployeeID
      WHERE 1=1
    ''';

    final List<dynamic> args = [];

    if (startDate != null) {
      sql += ' AND A.AdvanceDate >= ?';
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      sql += ' AND A.AdvanceDate <= ?';
      args.add(endDate.toIso8601String());
    }

    sql += ' ORDER BY A.AdvanceDate DESC';

    return await db.rawQuery(sql, args);
  }

  /// تفاصيل سحوبات الأرباح
  Future<List<Map<String, dynamic>>> _getWithdrawalsDetails(DateTime? startDate, DateTime? endDate) async {
    final db = await _db.database;

    String sql = 'SELECT * FROM TB_Profit_Withdrawals WHERE 1=1';
    final List<dynamic> args = [];

    if (startDate != null) {
      sql += ' AND WithdrawalDate >= ?';
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      sql += ' AND WithdrawalDate <= ?';
      args.add(endDate.toIso8601String());
    }

    sql += ' ORDER BY WithdrawalDate DESC';

    return await db.rawQuery(sql, args);
  }

  /// تفاصيل المكافآت من TB_Employee_Bonuses
  Future<List<Map<String, dynamic>>> _getBonusesDetails(
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    final db = await _db.database;

    String sql = '''
      SELECT
        b.BonusID,
        b.BonusDate,
        b.BonusAmount,
        b.BonusReason,
        b.Notes,
        e.FullName as EmployeeName
      FROM TB_Employee_Bonuses b
      INNER JOIN TB_Employees e ON b.EmployeeID = e.EmployeeID
      WHERE 1=1
    ''';
    final List<dynamic> args = [];

    if (startDate != null) {
      sql += ' AND b.BonusDate >= ?';
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      sql += ' AND b.BonusDate <= ?';
      args.add(endDate.toIso8601String());
    }

    sql += ' ORDER BY b.BonusDate DESC';

    return await db.rawQuery(sql, args);
  }

  // ============================================================================
  // دوال مساعدة - للرسوم البيانية
  // ============================================================================

  /// نسبة الإيرادات مقابل المصروفات (للـ Pie Chart)
  Future<Map<String, double>> getRevenueVsExpensesRatio({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final report = await getComprehensiveReport(
      startDate: startDate,
      endDate: endDate,
    );

    final totalRevenue = report['summary']['totalRevenue'] as double;
    final totalExpenses = report['summary']['totalExpenses'] as double;

    return {
      'revenue': totalRevenue,
      'expenses': totalExpenses,
    };
  }

  /// توزيع المصروفات حسب الأنواع (للـ Pie Chart)
  Future<Map<String, double>> getExpensesBreakdown({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final report = await getComprehensiveReport(
      startDate: startDate,
      endDate: endDate,
    );

    final expenses = report['expenses'];

    return {
      'generalExpenses': expenses['generalExpenses'] as double,
      'salaries': expenses['salaries'] as double,
      'advances': expenses['advances'] as double,
      'bonuses': expenses['bonuses'] as double, // ← إضافة المكافآت
      'profitWithdrawals': expenses['profitWithdrawals'] as double,
    };
  }
}
