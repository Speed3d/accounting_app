// lib/screens/fiscal_years/financial_report_screen.dart

import 'package:accountant_touch/data/models.dart';
import 'package:accountant_touch/services/fiscal_year_service.dart';
import 'package:accountant_touch/services/transaction_service.dart';
import 'package:accountant_touch/services/currency_service.dart';
import 'package:accountant_touch/theme/app_colors.dart';
import 'package:accountant_touch/theme/app_constants.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 📊 شاشة تقرير الحركة المالية الشامل
///
/// ← Hint: تعرض تقرير مفصل بجميع الحركات المالية للسنة
/// ← Hint: - ملخص مالي شامل
/// ← Hint: - تقسيم حسب الأنواع
/// ← Hint: - نسب ومؤشرات أداء
class FinancialReportScreen extends StatefulWidget {
  const FinancialReportScreen({super.key});

  @override
  State<FinancialReportScreen> createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends State<FinancialReportScreen> {
  final _transactionService = TransactionService.instance;
  final _fiscalYearService = FiscalYearService.instance;

  FiscalYear? _selectedFiscalYear;
  List<FiscalYear> _allFiscalYears = [];
  Map<String, dynamic>? _summary;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// تحميل البيانات
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ← Hint: تحميل السنوات المالية
      final allYears = await _fiscalYearService.getAllFiscalYears();
      final activeYear = await _fiscalYearService.getActiveFiscalYear();

      setState(() {
        _allFiscalYears = allYears;
        _selectedFiscalYear = activeYear ?? (allYears.isNotEmpty ? allYears.first : null);
      });

      // ← Hint: تحميل الملخص المالي
      if (_selectedFiscalYear != null) {
        await _loadSummary();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'لا توجد سنة مالية للعرض';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ في تحميل البيانات: $e';
        _isLoading = false;
      });
    }
  }

  /// تحميل الملخص المالي
  Future<void> _loadSummary() async {
    if (_selectedFiscalYear == null) return;

    try {
      final summary = await _transactionService.getFinancialSummary(
        fiscalYearId: _selectedFiscalYear!.fiscalYearID,
      );

      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ في تحميل الملخص: $e';
        _isLoading = false;
      });
    }
  }

  /// اختيار سنة مالية مختلفة
  void _selectFiscalYear() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر السنة المالية'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _allFiscalYears.length,
            itemBuilder: (context, index) {
              final year = _allFiscalYears[index];
              final isSelected = year.fiscalYearID == _selectedFiscalYear?.fiscalYearID;

              return ListTile(
                leading: Icon(
                  year.isActive ? Icons.check_circle : Icons.calendar_today,
                  color: year.isActive ? AppColors.primaryLight : Colors.grey,
                ),
                title: Text(year.name),
                subtitle: Text(
                  '${DateFormat('yyyy/MM/dd').format(year.startDate)} - ${DateFormat('yyyy/MM/dd').format(year.endDate)}',
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: AppColors.primaryLight)
                    : null,
                selected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedFiscalYear = year;
                  });
                  Navigator.pop(context);
                  _loadSummary();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقرير المالي الشامل'),
        actions: [
          if (_selectedFiscalYear != null)
            TextButton.icon(
              onPressed: _selectFiscalYear,
              icon: const Icon(Icons.calendar_today, color: Colors.white),
              label: Text(
                _selectedFiscalYear!.name,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (_summary == null) {
      return const Center(
        child: Text('لا توجد بيانات للعرض'),
      );
    }

    return SingleChildScrollView(
      padding: AppConstants.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ← Hint: الملخص الرئيسي
          _buildMainSummaryCard(isDark),
          const SizedBox(height: AppConstants.spacingLg),

          // ← Hint: التفصيل حسب النوع
          _buildBreakdownCard(isDark),
          const SizedBox(height: AppConstants.spacingLg),

          // ← Hint: مؤشرات الأداء
          _buildPerformanceIndicators(isDark),
          const SizedBox(height: AppConstants.spacingLg),
        ],
      ),
    );
  }

  Widget _buildMainSummaryCard(bool isDark) {
    final totalIncome = Decimal.parse(_summary!['totalIncome'].toString());
    final totalExpense = Decimal.parse(_summary!['totalExpense'].toString());
    final netProfit = Decimal.parse(_summary!['netProfit'].toString());

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance,
                  color: AppColors.primaryLight,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'الملخص المالي',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ← Hint: الرصيد الافتتاحي
            _buildSummaryRow(
              'الرصيد الافتتاحي',
              _selectedFiscalYear!.openingBalance,
              Icons.trending_up,
              Colors.blue,
            ),
            const Divider(height: 24),

            // ← Hint: إجمالي الدخل
            _buildSummaryRow(
              'إجمالي الدخل',
              totalIncome,
              Icons.arrow_downward,
              Colors.green,
            ),
            const Divider(height: 24),

            // ← Hint: إجمالي المصروفات
            _buildSummaryRow(
              'إجمالي المصروفات',
              totalExpense,
              Icons.arrow_upward,
              Colors.red,
            ),
            const Divider(height: 24),

            // ← Hint: صافي الربح
            _buildSummaryRow(
              'صافي الربح',
              netProfit,
              Icons.account_balance_wallet,
              netProfit >= Decimal.zero ? Colors.green : Colors.red,
              isHighlighted: true,
            ),
            const Divider(height: 24),

            // ← Hint: الرصيد الختامي
            _buildSummaryRow(
              'الرصيد الختامي',
              _selectedFiscalYear!.closingBalance,
              Icons.account_balance,
              Colors.purple,
              isHighlighted: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    Decimal amount,
    IconData icon,
    Color color, {
    bool isHighlighted = false,
  }) {
    return Container(
      padding: isHighlighted ? const EdgeInsets.all(12) : EdgeInsets.zero,
      decoration: isHighlighted
          ? BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: Row(
        children: [
          Icon(icon, size: isHighlighted ? 24 : 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isHighlighted ? 16 : 14,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            CurrencyService.instance.formatAmount(amount),
            style: TextStyle(
              fontSize: isHighlighted ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(bool isDark) {
    final breakdown = _summary!['breakdown'] as Map<String, dynamic>;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart,
                  color: AppColors.primaryLight,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'التفصيل حسب النوع',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ← Hint: الدخل
            _buildSubtitle('الدخل', Colors.green),
            const SizedBox(height: 12),
            _buildBreakdownItem(
              'المبيعات',
              Decimal.parse(breakdown['sales'].toString()),
              Icons.shopping_cart,
              Colors.green,
            ),
            const SizedBox(height: 8),
            _buildBreakdownItem(
              'دفعات العملاء',
              Decimal.parse(breakdown['customerPayments'].toString()),
              Icons.payment,
              Colors.green,
            ),
            const SizedBox(height: 8),
            _buildBreakdownItem(
              'تسديدات السلف من الموظفين',
              Decimal.parse(breakdown['advanceRepayments'].toString()),
              Icons.account_balance_wallet,
              Colors.green,
            ),

            const Divider(height: 32),

            // ← Hint: المصروفات
            _buildSubtitle('المصروفات', Colors.red),
            const SizedBox(height: 12),
            _buildBreakdownItem(
              'الرواتب',
              Decimal.parse(breakdown['salaries'].toString()),
              Icons.people,
              Colors.red,
            ),
            const SizedBox(height: 8),
            _buildBreakdownItem(
              'السلف',
              Decimal.parse(breakdown['advances'].toString()),
              Icons.monetization_on,
              Colors.red,
            ),
            const SizedBox(height: 8),
            _buildBreakdownItem(
              'المكافآت',
              Decimal.parse(breakdown['bonuses'].toString()),
              Icons.card_giftcard,
              Colors.red,
            ),
            const SizedBox(height: 8),
            _buildBreakdownItem(
              'المرتجعات',
              Decimal.parse(breakdown['returns'].toString()),
              Icons.undo,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitle(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownItem(
    String label,
    Decimal amount,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        const SizedBox(width: 12),
        Icon(icon, size: 18, color: color.withOpacity(0.7)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Text(
          CurrencyService.instance.formatAmount(amount),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceIndicators(bool isDark) {
    final totalIncome = Decimal.parse(_summary!['totalIncome'].toString());
    final totalExpense = Decimal.parse(_summary!['totalExpense'].toString());
    final netProfit = Decimal.parse(_summary!['netProfit'].toString());

    // ← Hint: حساب المؤشرات - نحول إلى double مباشرة لتجنب مشاكل Rational
    final profitMarginValue = totalIncome > Decimal.zero
        ? (netProfit.toDouble() / totalIncome.toDouble() * 100)
        : 0.0;
    
    final expenseRatioValue = totalIncome > Decimal.zero
        ? (totalExpense.toDouble() / totalIncome.toDouble() * 100)
        : 0.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: AppColors.primaryLight,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'مؤشرات الأداء',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ← Hint: هامش الربح
            _buildIndicatorRow(
              'هامش الربح',
              '${profitMarginValue.toStringAsFixed(1)}%',
              profitMarginValue >= 20
                  ? Colors.green
                  : profitMarginValue >= 10
                      ? Colors.orange
                      : Colors.red,
              profitMarginValue / 100,
            ),
            const SizedBox(height: 16),

            // ← Hint: نسبة المصروفات
            _buildIndicatorRow(
              'نسبة المصروفات للدخل',
              '${expenseRatioValue.toStringAsFixed(1)}%',
              expenseRatioValue <= 70
                  ? Colors.green
                  : expenseRatioValue <= 85
                      ? Colors.orange
                      : Colors.red,
              expenseRatioValue / 100,
            ),
            const SizedBox(height: 16),

            // ← Hint: عدد القيود
            _buildInfoChip(
              'إجمالي عدد القيود',
              '${_summary!['incomeCount'] + _summary!['expenseCount']}',
              Icons.receipt_long,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    'قيود الدخل',
                    '${_summary!['incomeCount']}',
                    Icons.arrow_downward,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoChip(
                    'قيود المصروف',
                    '${_summary!['expenseCount']}',
                    Icons.arrow_upward,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorRow(
    String label,
    String value,
    Color color,
    double progress,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (color ?? Colors.blue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color ?? Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}