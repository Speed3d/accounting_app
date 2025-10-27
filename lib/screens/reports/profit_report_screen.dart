// lib/screens/reports/profit_report_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../utils/helpers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_state.dart';

/// 📈 شاشة تقرير الأرباح العام
/// ---------------------------
/// صفحة فرعية تعرض:
/// 1. ملخص مالي شامل (الأرباح، المصاريف، المسحوبات، الربح الصافي)
/// 2. تفاصيل المبيعات (قابلة للإظهار/الإخفاء)
class ProfitReportScreen extends StatefulWidget {
  const ProfitReportScreen({super.key});

  @override
  State<ProfitReportScreen> createState() => _ProfitReportScreenState();
}

class _ProfitReportScreenState extends State<ProfitReportScreen> {
  // ============= المتغيرات =============
  final dbHelper = DatabaseHelper.instance;
  late Future<FinancialSummary> _summaryFuture;
  bool _isDetailsVisible = false; // للتحكم في إظهار/إخفاء التفاصيل

  // ============= التهيئة =============
  @override
  void initState() {
    super.initState();
    _loadFinancialSummary();
  }

  /// تحميل الملخص المالي من قاعدة البيانات
  void _loadFinancialSummary() {
    setState(() {
      _summaryFuture = _getFinancialSummary();
    });
  }

  /// جلب البيانات المالية من قاعدة البيانات
  Future<FinancialSummary> _getFinancialSummary() async {
    // تنفيذ جميع الاستعلامات بالتوازي لتحسين الأداء
    final results = await Future.wait([
      dbHelper.getTotalProfit(),
      dbHelper.getTotalExpenses(),
      dbHelper.getTotalAllProfitWithdrawals(),
      dbHelper.getAllSales(),
    ]);

    return FinancialSummary(
      grossProfit: results[0] as double,
      totalExpenses: results[1] as double,
      totalWithdrawals: results[2] as double,
      sales: results[3] as List<CustomerDebt>,
    );
  }

  // ============= البناء الرئيسي =============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- AppBar مع زر التحديث ---
      appBar: AppBar(
        title: const Text('تقرير الأرباح العام'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFinancialSummary,
            tooltip: 'تحديث',
          ),
        ],
      ),

      // --- الجسم: الملخص المالي والتفاصيل ---
      body: FutureBuilder<FinancialSummary>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          // --- حالة التحميل ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState(
              message: 'جاري حساب الأرباح...',
            );
          }

          // --- حالة الخطأ ---
          if (snapshot.hasError) {
            return ErrorState(
              message: 'حدث خطأ: ${snapshot.error}',
              onRetry: _loadFinancialSummary,
            );
          }

          // --- حالة عدم وجود بيانات ---
          if (!snapshot.hasData) {
            return const EmptyState(
              icon: Icons.trending_up,
              title: 'لا توجد بيانات',
              message: 'لم يتم تسجيل أي عمليات حتى الآن',
            );
          }

          // --- عرض البيانات ---
          final summary = snapshot.data!;
          final netProfit = summary.grossProfit -
              summary.totalExpenses -
              summary.totalWithdrawals;

          return SingleChildScrollView(
            padding: AppConstants.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 💰 قسم الملخص المالي
                _buildFinancialSummarySection(summary, netProfit),

                const SizedBox(height: AppConstants.spacingXl),

                // 🔍 زر إظهار/إخفاء التفاصيل
                _buildToggleDetailsButton(),

                // 📋 قائمة تفاصيل المبيعات
                if (_isDetailsVisible) ...[
                  const SizedBox(height: AppConstants.spacingMd),
                  _buildSalesList(summary.sales),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ============= قسم الملخص المالي =============
  /// يعرض 4 بطاقات إحصائية:
  /// 1. إجمالي الأرباح من المبيعات
  /// 2. إجمالي المصاريف العامة
  /// 3. إجمالي مسحوبات الأرباح
  /// 4. صافي الربح (النتيجة النهائية)
  Widget _buildFinancialSummarySection(
    FinancialSummary summary,
    double netProfit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- بطاقة إجمالي الأرباح ---
        StatCard(
          label: 'إجمالي الأرباح من المبيعات',
          value: formatCurrency(summary.grossProfit),
          icon: Icons.trending_up,
          color: AppColors.info,
          subtitle: 'قبل المصاريف',
          // iconSize: 22,
        ),

        const SizedBox(height: AppConstants.spacingMd),

        // --- بطاقة المصاريف ---
        StatCard(
          label: 'إجمالي المصاريف العامة',
          value: formatCurrency(summary.totalExpenses),
          icon: Icons.receipt_long,
          color: AppColors.error,
          subtitle: 'فواتير ونفقات',
          // iconSize: 22,
        ),

        const SizedBox(height: AppConstants.spacingMd),

        // --- بطاقة المسحوبات ---
        StatCard(
          label: 'إجمالي مسحوبات الأرباح',
          value: formatCurrency(summary.totalWithdrawals),
          icon: Icons.account_balance_wallet,
          color: AppColors.warning,
          subtitle: 'للموردين والشركاء',
          // iconSize: 22,
        ),

        const Divider(height: 32),

        // --- بطاقة صافي الربح (النتيجة النهائية) ---
        CustomCard(
          color: netProfit >= 0
              ? AppColors.success.withOpacity(0.1)
              : AppColors.error.withOpacity(0.1),
          child: Padding(
            padding: AppConstants.paddingLg,
            child: Row(
              children: [
                // أيقونة النتيجة
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: netProfit >= 0
                        ? AppColors.success.withOpacity(0.2)
                        : AppColors.error.withOpacity(0.2),
                    borderRadius: AppConstants.borderRadiusLg,
                  ),
                  child: Icon(
                    netProfit >= 0
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: netProfit >= 0
                        ? AppColors.success
                        : AppColors.error,
                    size: 28,
                  ),
                ),

                const SizedBox(width: AppConstants.spacingMd),

                // النص والمبلغ
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'صافي الربح',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppConstants.spacingXs),
                      Text(
                        formatCurrency(netProfit),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: netProfit >= 0
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============= زر إظهار/إخفاء التفاصيل =============
  /// زر لتبديل عرض قائمة تفاصيل المبيعات
  Widget _buildToggleDetailsButton() {
    return OutlinedButton.icon(
      onPressed: () {
        setState(() {
          _isDetailsVisible = !_isDetailsVisible;
        });
      },
      icon: Icon(
        _isDetailsVisible
            ? Icons.visibility_off_outlined
            : Icons.visibility_outlined,
      ),
      label: Text(
        _isDetailsVisible
            ? 'إخفاء تفاصيل المبيعات'
            : 'عرض تفاصيل المبيعات',
      ),
    );
  }

  // ============= قائمة تفاصيل المبيعات =============
  /// يعرض جدول بجميع عمليات البيع مع الربح لكل عملية
  Widget _buildSalesList(List<CustomerDebt> sales) {
    // --- حالة عدم وجود مبيعات ---
    if (sales.isEmpty) {
      return const EmptyState(
        icon: Icons.shopping_cart_outlined,
        title: 'لا توجد مبيعات',
        message: 'لم يتم تسجيل أي عمليات بيع حتى الآن',
      );
    }

    // --- عرض قائمة المبيعات ---
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان القائمة
        Text(
          'تفاصيل المبيعات (${sales.length})',
          style: Theme.of(context).textTheme.headlineSmall,
        ),

        const SizedBox(height: AppConstants.spacingMd),

        // القائمة
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sales.length,
          itemBuilder: (context, index) {
            final sale = sales[index];
            return _buildSaleCard(sale);
          },
        ),
      ],
    );
  }

  // ============= بطاقة المبيعة الواحدة =============
  /// يعرض تفاصيل عملية بيع واحدة
  Widget _buildSaleCard(CustomerDebt sale) {
    final saleDate = DateTime.parse(sale.dateT);

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: Padding(
        padding: AppConstants.paddingMd,
        child: Row(
          children: [
            // --- أيقونة الفاتورة ---
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.1),
                borderRadius: AppConstants.borderRadiusMd,
              ),
              child: Icon(
                Icons.receipt,
                color: AppColors.primaryLight,
                size: 24,
              ),
            ),

            const SizedBox(width: AppConstants.spacingMd),

            // --- تفاصيل المبيعة ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // اسم المنتج
                  Text(
                    sale.details,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: AppConstants.spacingXs),

                  // اسم الزبون والتاريخ
                  Text(
                    '${sale.customerName ?? "غير مسجل"} • '
                    '${DateFormat('yyyy-MM-dd').format(saleDate)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppConstants.spacingMd),

            // --- الربح والمبلغ ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // الربح
                Text(
                  formatCurrency(sale.profitAmount),
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: AppConstants.spacingXs),

                // مبلغ البيع
                Text(
                  'من ${formatCurrency(sale.debt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============= نموذج بيانات الملخص المالي =============
/// كلاس مساعد لتمثيل الملخص المالي الشامل
class FinancialSummary {
  final double grossProfit; // إجمالي الأرباح قبل المصاريف
  final double totalExpenses; // إجمالي المصاريف العامة
  final double totalWithdrawals; // إجمالي مسحوبات الأرباح
  final List<CustomerDebt> sales; // قائمة جميع المبيعات

  FinancialSummary({
    required this.grossProfit,
    required this.totalExpenses,
    required this.totalWithdrawals,
    required this.sales,
  });
}