// lib/screens/reports/comprehensive_cash_flow_report_screen.dart

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../services/comprehensive_cash_flow_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_state.dart';

/// 📊 تقرير التدفقات النقدية الشامل
///
/// ← Hint: هذا التقرير يجمع جميع التدفقات المالية من مصادر مختلفة
/// ← Hint: يعرض الإيرادات والمصروفات وصافي التدفق النقدي
///
/// **الميزات:**
/// - ✅ فلترة حسب الفترة الزمنية
/// - ✅ عرض ملخص شامل (Summary Cards)
/// - ✅ تفاصيل الإيرادات والمصروفات
/// - ✅ دعم اللغتين العربية والإنجليزية
/// - ✅ Pull to Refresh
/// - ✅ حسابات تلقائية (صافي التدفق، هامش الربح)
class ComprehensiveCashFlowReportScreen extends StatefulWidget {
  const ComprehensiveCashFlowReportScreen({super.key});

  @override
  State<ComprehensiveCashFlowReportScreen> createState() => _ComprehensiveCashFlowReportScreenState();
}

class _ComprehensiveCashFlowReportScreenState extends State<ComprehensiveCashFlowReportScreen> {
  // ============================================================================
  // المتغيرات
  // ============================================================================

  final _cashFlowService = ComprehensiveCashFlowService.instance;

  /// ← Hint: الفترة الزمنية الافتراضية (آخر 30 يوم)
  DateTime? _startDate;
  DateTime? _endDate = DateTime.now();

  /// ← Hint: البيانات المحملة من الخدمة
  Map<String, dynamic>? _reportData;

  /// ← Hint: حالة التحميل
  bool _isLoading = false;

  // ============================================================================
  // دورة الحياة
  // ============================================================================

  @override
  void initState() {
    super.initState();
    // ← Hint: تحميل البيانات عند فتح الشاشة
    _loadReport();
  }

  // ============================================================================
  // تحميل البيانات
  // ============================================================================

  /// تحميل التقرير من الخدمة
  Future<void> _loadReport() async {
    setState(() => _isLoading = true);

    try {
      final data = await _cashFlowService.getComprehensiveReport(
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _reportData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تحميل التقرير: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ============================================================================
  // البناء الرئيسي
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.comprehensiveCashFlowReport),
        centerTitle: false,
        actions: [
          // ← Hint: زر لتحديث البيانات
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadReport,
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingState()
          : RefreshIndicator(
              onRefresh: _loadReport,
              child: _buildContent(l10n),
            ),
    );
  }

  // ============================================================================
  // بناء المحتوى
  // ============================================================================

  Widget _buildContent(AppLocalizations l10n) {
    if (_reportData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.3),
            ),
            const SizedBox(height: AppConstants.spacingLg),
            Text(
              l10n.noDataAvailable,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: AppConstants.screenPadding,
      children: [
        // --- Date Range Picker ---
        _buildDateRangePicker(l10n),
        const SizedBox(height: AppConstants.spacingLg),

        // --- Summary Cards ---
        _buildSummaryCards(l10n),
        const SizedBox(height: AppConstants.spacingXl),

        // --- Revenue Section ---
        _buildRevenueSection(l10n),
        const SizedBox(height: AppConstants.spacingLg),

        // --- Expenses Section ---
        _buildExpensesSection(l10n),
      ],
    );
  }

  // ============================================================================
  // Date Range Picker
  // ============================================================================

  Widget _buildDateRangePicker(AppLocalizations l10n) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return CustomCard(
      child: Padding(
        padding: AppConstants.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.date_range, color: AppColors.primaryLight, size: 20),
                const SizedBox(width: AppConstants.spacingSm),
                Text(
                  l10n.timePeriod,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Row(
              children: [
                // --- From Date ---
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: Container(
                      padding: AppConstants.paddingMd,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: AppConstants.borderRadiusMd,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.from,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _startDate != null ? dateFormat.format(_startDate!) : l10n.allTime,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingMd),

                // --- To Date ---
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: Container(
                      padding: AppConstants.paddingMd,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: AppConstants.borderRadiusMd,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.to,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _endDate != null ? dateFormat.format(_endDate!) : l10n.now,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // --- Quick Date Ranges ---
            const SizedBox(height: AppConstants.spacingMd),
            Wrap(
              spacing: AppConstants.spacingSm,
              runSpacing: AppConstants.spacingSm,
              children: [
                _buildQuickDateButton(l10n.today, () => _setQuickDateRange(0)),
                _buildQuickDateButton(l10n.thisWeek, () => _setQuickDateRange(7)),
                _buildQuickDateButton(l10n.thisMonth, () => _setQuickDateRange(30)),
                _buildQuickDateButton(l10n.allTime, () => _setQuickDateRange(null)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDateButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: const Size(0, 32),
        textStyle: const TextStyle(fontSize: 13),
      ),
      child: Text(label),
    );
  }

  /// اختيار تاريخ من Date Picker
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? DateTime.now());

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
        } else {
          _endDate = pickedDate;
        }
      });
      _loadReport();
    }
  }

  /// تعيين فترة زمنية سريعة
  void _setQuickDateRange(int? days) {
    setState(() {
      if (days == null) {
        _startDate = null;
        _endDate = null;
      } else {
        _endDate = DateTime.now();
        _startDate = _endDate!.subtract(Duration(days: days));
      }
    });
    _loadReport();
  }

  // ============================================================================
  // Summary Cards
  // ============================================================================

  Widget _buildSummaryCards(AppLocalizations l10n) {
    final summary = _reportData!['summary'] as Map<String, dynamic>;

    final totalRevenue = summary['totalRevenue'] as double;
    final totalExpenses = summary['totalExpenses'] as double;
    final netCashFlow = summary['netCashFlow'] as double;

    return Column(
      children: [
        Row(
          children: [
            // --- Total Revenue ---
            Expanded(
              child: _buildSummaryCard(
                title: l10n.totalRevenue,
                amount: totalRevenue,
                icon: Icons.trending_up,
                color: AppColors.success,
                l10n: l10n,
              ),
            ),
            const SizedBox(width: AppConstants.spacingMd),

            // --- Total Expenses ---
            Expanded(
              child: _buildSummaryCard(
                title: l10n.totalExpenses,
                amount: totalExpenses,
                icon: Icons.trending_down,
                color: AppColors.error,
                l10n: l10n,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingMd),
        // --- Net Cash Flow ---
        _buildSummaryCard(
          title: l10n.netCashFlow,
          amount: netCashFlow,
          icon: Icons.account_balance_wallet,
          color: netCashFlow >= 0 ? AppColors.success : AppColors.error,
          l10n: l10n,
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required AppLocalizations l10n,
  }) {
    return CustomCard(
      child: Padding(
        padding: AppConstants.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: AppConstants.borderRadiusMd,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              formatCurrency(Decimal.parse(amount.toString())),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // Revenue Section
  // ============================================================================

  Widget _buildRevenueSection(AppLocalizations l10n) {
    final revenue = _reportData!['revenue'] as Map<String, dynamic>;

    final cashSales = revenue['cashSales'] as double;
    final customerPayments = revenue['customerPayments'] as double;
    final salesReturns = revenue['salesReturns'] as double;
    final total = revenue['total'] as double;

    return CustomCard(
      child: Padding(
        padding: AppConstants.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Row(
              children: [
                Icon(Icons.attach_money, color: AppColors.success, size: 24),
                const SizedBox(width: AppConstants.spacingSm),
                Text(
                  l10n.revenue,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: AppConstants.spacingLg),

            // --- Revenue Items ---
            _buildRevenueItem(l10n.cashSales, cashSales, Icons.point_of_sale, l10n),
            _buildRevenueItem(l10n.customerPayments, customerPayments, Icons.payments, l10n),
            _buildRevenueItem(l10n.salesReturns, -salesReturns, Icons.keyboard_return, l10n, isNegative: true),

            const Divider(height: AppConstants.spacingLg),

            // --- Total ---
            _buildRevenueItem(l10n.total, total, Icons.check_circle, l10n, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueItem(String title, double amount, IconData icon, AppLocalizations l10n, {bool isNegative = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isTotal
                  ? AppColors.success.withOpacity(0.1)
                  : isNegative
                      ? AppColors.error.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
              borderRadius: AppConstants.borderRadiusSm,
            ),
            child: Icon(
              icon,
              size: 16,
              color: isTotal
                  ? AppColors.success
                  : isNegative
                      ? AppColors.error
                      : Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: AppConstants.spacingMd),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: isTotal ? 15 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            formatCurrency(Decimal.parse(amount.abs().toString())),
            style: TextStyle(
              fontSize: isTotal ? 15 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal
                  ? AppColors.success
                  : isNegative
                      ? AppColors.error
                      : null,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Expenses Section
  // ============================================================================

  Widget _buildExpensesSection(AppLocalizations l10n) {
    final expenses = _reportData!['expenses'] as Map<String, dynamic>;

    final generalExpenses = expenses['generalExpenses'] as double;
    final salaries = expenses['salaries'] as double;
    final advances = expenses['advances'] as double;
    final profitWithdrawals = expenses['profitWithdrawals'] as double;
    final total = expenses['total'] as double;

    return CustomCard(
      child: Padding(
        padding: AppConstants.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Row(
              children: [
                Icon(Icons.money_off, color: AppColors.error, size: 24),
                const SizedBox(width: AppConstants.spacingSm),
                Text(
                  l10n.expenses,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: AppConstants.spacingLg),

            // --- Expense Items ---
            _buildExpenseItem(l10n.generalExpenses, generalExpenses, Icons.receipt_long, l10n),
            _buildExpenseItem(l10n.salaries, salaries, Icons.work, l10n),
            _buildExpenseItem(l10n.advances, advances, Icons.money, l10n),
            _buildExpenseItem(l10n.profitWithdrawals, profitWithdrawals, Icons.account_balance, l10n),

            const Divider(height: AppConstants.spacingLg),

            // --- Total ---
            _buildExpenseItem(l10n.total, total, Icons.check_circle, l10n, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseItem(String title, double amount, IconData icon, AppLocalizations l10n, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isTotal
                  ? AppColors.error.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: AppConstants.borderRadiusSm,
            ),
            child: Icon(
              icon,
              size: 16,
              color: isTotal ? AppColors.error : Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: AppConstants.spacingMd),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: isTotal ? 15 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            formatCurrency(Decimal.parse(amount.toString())),
            style: TextStyle(
              fontSize: isTotal ? 15 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? AppColors.error : null,
            ),
          ),
        ],
      ),
    );
  }
}
