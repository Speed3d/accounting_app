// lib/screens/dashboard/dashboard_screen.dart

import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_state.dart';

/// 📊 لوحة القيادة (Dashboard)
/// الغرض: عرض جميع الإحصائيات والتنبيهات الذكية
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with AutomaticKeepAliveClientMixin {
  final dbHelper = DatabaseHelper.instance;
  final authService = AuthService();

  // ✅ Hint: للحفاظ على حالة الصفحة عند التبديل بين التابات
  @override
  bool get wantKeepAlive => true;

  // ✅ Hint: متغيرات حالة التحميل
  bool _isLoading = true;

  // ✅ Hint: متغير جديد - عدد الأيام للعملاء المتأخرين
  int _overdueDaysThreshold = 30; // افتراضياً 30 يوم

  // ✅ Hint: متغيرات الإحصائيات السريعة
  Decimal _totalSales = Decimal.zero;
  Decimal _totalProfit = Decimal.zero;
  int _activeCustomersCount = 0;
  int _activeProductsCount = 0;
  Decimal _totalDebts = Decimal.zero;
  Decimal _totalPayments = Decimal.zero;
  Decimal _collectionRate = Decimal.zero;

  // ✅ Hint: متغيرات القوائم
  List<Customer> _topBuyers = [];
  List<Map<String, dynamic>> _topDebtors = [];
  List<Product> _topSellingProducts = [];
  List<Product> _lowStockProducts = [];
  List<Map<String, dynamic>> _overdueCustomers = [];

  // ✅ Hint: متغيرات الرسوم البيانية
  List<Map<String, dynamic>> _monthlySales = [];
  List<Map<String, dynamic>> _topSuppliers = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

// ✅ Hint: تحميل جميع البيانات (مع دعم فلتر الأيام)
Future<void> _loadDashboardData() async {
  setState(() => _isLoading = true);

  try {
    final results = await Future.wait([
      dbHelper.getTotalSales(),
      dbHelper.getTotalProfit(),
      dbHelper.getActiveCustomersCount(),
      dbHelper.getActiveProductsCount(),
      dbHelper.getTotalDebts(),
      dbHelper.getTotalPaymentsCollected(),
      dbHelper.getCollectionRate(),
      dbHelper.getTopCustomers(limit: 5),
      dbHelper.getOverdueCustomers(daysThreshold: _overdueDaysThreshold), // ✅ Hint: استخدام المتغير
      dbHelper.getTopSellingProducts(limit: 5),
      dbHelper.getLowStockProducts(threshold: 5),
      dbHelper.getMonthlySales(months: 6),
      dbHelper.getTopSuppliersByProfit(limit: 5),
    ]);

    if (mounted) {
      setState(() {
        _totalSales = results[0] as Decimal;
        _totalProfit = results[1] as Decimal;
        _activeCustomersCount = results[2] as int;
        _activeProductsCount = results[3] as int;
        _totalDebts = results[4] as Decimal;
        _totalPayments = results[5] as Decimal;
        _collectionRate = results[6] as Decimal;
        _topBuyers = results[7] as List<Customer>;
        _overdueCustomers = results[8] as List<Map<String, dynamic>>;
        _topSellingProducts = results[9] as List<Product>;
        _lowStockProducts = results[10] as List<Product>;
        _monthlySales = results[11] as List<Map<String, dynamic>>;
        _topSuppliers = results[12] as List<Map<String, dynamic>>;

        // ✅ Hint: حساب أكثر المدينين 
        _topDebtors = List.from(_overdueCustomers)..take(5);

        _isLoading = false;
      });
    }
  } catch (e) {
    debugPrint('❌ خطأ في تحميل بيانات Dashboard: $e');
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    super.build(context); // ✅ Hint: مهم لـ AutomaticKeepAliveClientMixin
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.statisticsinformation),
        actions: [
           IconButton(
            icon: Badge(
            label: Text('$_overdueDaysThreshold'),
            isLabelVisible: _overdueCustomers.isNotEmpty,
            child: const Icon(Icons.filter_list),
           ),
            onPressed: () => _showOverdueFilterSheet(l10n),
            tooltip: l10n.filterOverdueCustomers,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: _isLoading
          ? LoadingState(message: l10n.loadingData)
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: ListView(
                // ✅ Hint: استخدام ListView بدلاً من SingleChildScrollView لتحسين الأداء
                padding: AppConstants.screenPadding,
                // ✅  إضافة cacheExtent لتحسين الأداء
                cacheExtent: 1000,
                children: [
                  const SizedBox(height: AppConstants.spacingMd),

                  // ============= القسم 1: بطاقات الإحصائيات السريعة =============
                  _buildQuickStatsSection(l10n, isDark),

                  const SizedBox(height: AppConstants.spacingXl),

                  // ============= القسم 2: التنبيهات الذكية =============
                  _buildAlertsSection(l10n, isDark),

                  const SizedBox(height: AppConstants.spacingXl),
                
                  // ============= القسم 5: العملاء المدينون =============
                  _buildTopDebtorsSection(l10n, isDark),

                  const SizedBox(height: AppConstants.spacingXl),

                  // ============= القسم 3: الإحصائيات المالية =============
                  _buildFinancialStatsSection(l10n, isDark),

                  const SizedBox(height: AppConstants.spacingXl),

                  // ============= القسم 4: أكثر العملاء شراءً =============
                  _buildTopBuyersSection(l10n, isDark),

                  const SizedBox(height: AppConstants.spacingXl),

                  // ============= القسم 6: أكثر المنتجات مبيعاً =============
                  _buildTopSellingProductsSection(l10n, isDark),

                  const SizedBox(height: AppConstants.spacingXl),

                  // ============= القسم 7: رسم المبيعات الشهرية =============
                  // _buildMonthlySalesChart(l10n, isDark),

                  const SizedBox(height: AppConstants.spacingXl),

                  // ============= القسم 8: رسم الموردين =============
                  _buildSuppliersChart(l10n, isDark),

                  const SizedBox(height: AppConstants.spacingXl),
                ],
              ),
            ),
    );
  }

  // ==========================================================================
  // 📊 القسم 1: بطاقات الإحصائيات السريعة
  // ==========================================================================

Widget _buildQuickStatsSection(AppLocalizations l10n, bool isDark) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        l10n.quickStats,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      const SizedBox(height: AppConstants.spacingMd),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: context.isMobile ? 2 : 4,
        mainAxisSpacing: AppConstants.spacingMd,
        crossAxisSpacing: AppConstants.spacingMd,
        childAspectRatio: 1.4, // ✅ تم تغييره من 1.3 إلى 1.4 لمساحة أكبر
        children: [
          _buildStatCard(
            title: l10n.totalSales,
            value: formatCurrency(_totalSales),
            icon: Icons.trending_up,
            color: AppColors.success,
            isDark: isDark,
          ),
          _buildStatCard(
            title: l10n.totalProfit,
            value: formatCurrency(_totalProfit),
            icon: Icons.monetization_on,
            color: AppColors.profit,
            isDark: isDark,
          ),
          _buildStatCard(
            title: l10n.activeCustomers,
            value: '$_activeCustomersCount',
            icon: Icons.people,
            color: AppColors.info,
            isDark: isDark,
          ),
          _buildStatCard(
            title: l10n.availableProducts,
            value: '$_activeProductsCount',
            icon: Icons.inventory,
            color: AppColors.warning,
            isDark: isDark,
          ),
        ],
      ),
    ],
  );
}

// ✅ Hint: ويدجت بطاقة إحصائية واحدة (مُحسّن)
Widget _buildStatCard({
  required String title,
  required String value,
  required IconData icon,
  required Color color,
  required bool isDark,
}) {
  return CustomCard(
    padding: const EdgeInsets.all(AppConstants.spacingSm), // ✅ تقليل الـ padding
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min, // ✅ إضافة هذا
      children: [
        // الأيقونة
        Container(
          padding: const EdgeInsets.all(10), // ✅ تقليل من 12 إلى 10
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24), // ✅ تقليل من 28 إلى 24
        ),

        const SizedBox(height: 6), // ✅ تقليل من 8 إلى 6

        // العنوان
        Flexible( // ✅ استخدام Flexible بدلاً من Text العادي
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontSize: 11, // ✅ تقليل حجم الخط قليلاً
                ),
            textAlign: TextAlign.center,
            maxLines: 2, // ✅ تغيير من 1 إلى 2 للسماح بسطرين
            overflow: TextOverflow.ellipsis,
          ),
        ),

        const SizedBox(height: 4), // ✅ تقليل من 6 إلى 4

        // القيمة
        Flexible( // ✅ استخدام Flexible
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14, // ✅ تقليل حجم الخط قليلاً
                ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}


  //==========================================================================
  // ✅ Hint: دالة جديدة - فلتر اختيار عدد الأيام للعملاء المتأخرين
  //==========================================================================

Widget _buildOverdueDaysFilter(AppLocalizations l10n, bool isDark) {
  return CustomCard(
    color: AppColors.info.withOpacity(0.05),
    padding: const EdgeInsets.all(AppConstants.spacingMd),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.filter_list,
              color: AppColors.info,
              size: 20,
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Text(
              l10n.filterByDays, // ✅ Hint: سنضيفها في الترجمة
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.info,
                  ),
            ),
          ],
        ),
        
        const SizedBox(height: AppConstants.spacingMd),
        
        // ✅ Hint: أزرار اختيار سريع
        Wrap(
          spacing: AppConstants.spacingSm,
          runSpacing: AppConstants.spacingSm,
          children: [
            _buildDaysFilterChip(7, l10n, isDark),
            _buildDaysFilterChip(15, l10n, isDark),
            _buildDaysFilterChip(30, l10n, isDark),
            _buildDaysFilterChip(60, l10n, isDark),
            _buildDaysFilterChip(90, l10n, isDark),
          ],
        ),
        
        const SizedBox(height: AppConstants.spacingMd),
        
        // ✅ Hint: اختيار مخصص
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.customDays, // ✅ Hint: سنضيفها
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showCustomDaysDialog(l10n),
              icon: const Icon(Icons.edit, size: 16),
              label: Text(
                l10n.customize, // ✅ Hint: سنضيفها
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// ✅ Hint: بناء زر فلتر الأيام
Widget _buildDaysFilterChip(int days, AppLocalizations l10n, bool isDark) {
  final isSelected = _overdueDaysThreshold == days;
  
  return FilterChip(
    label: Text(
      l10n.daysCount(days.toString()), // ✅ Hint: سنضيفها
      style: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    ),
    selected: isSelected,
    onSelected: (selected) {
      if (selected) {
        setState(() {
          _overdueDaysThreshold = days;
        });
        _loadDashboardData(); // ✅ Hint: إعادة تحميل البيانات
      }
    },
    selectedColor: AppColors.info.withOpacity(0.3),
    checkmarkColor: AppColors.info,
    backgroundColor: isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight,
    side: BorderSide(
      color: isSelected ? AppColors.info : Colors.transparent,
      width: 2,
    ),
  );
}

// ✅ Hint: حوار اختيار عدد أيام مخصص
Future<void> _showCustomDaysDialog(AppLocalizations l10n) async {
  final controller = TextEditingController(text: _overdueDaysThreshold.toString());
  
  final result = await showDialog<int>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.selectCustomDays), // ✅ Hint: سنضيفها
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: l10n.numberOfDays, // ✅ Hint: سنضيفها
          hintText: '30',
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            final days = int.tryParse(controller.text);
            if (days != null && days > 0) {
              Navigator.pop(ctx, days);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.enterValidNumber),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          child: Text(l10n.apply), // ✅ Hint: سنضيفها
        ),
      ],
    ),
  );
  
  if (result != null && result != _overdueDaysThreshold) {
    setState(() {
      _overdueDaysThreshold = result;
    });
    _loadDashboardData(); // ✅ Hint: إعادة تحميل البيانات
  }
}

  // ==========================================================================
  // ⚠️ القسم 2: التنبيهات الذكية
  // ==========================================================================
  // ==========================================================================
// ⚠️ القسم 2: التنبيهات الذكية (مع فلتر الأيام)
// ==========================================================================
Widget _buildAlertsSection(AppLocalizations l10n, bool isDark) {
  final alertsCount = _lowStockProducts.length + _overdueCustomers.length;

  if (alertsCount == 0) {
    return const SizedBox.shrink();
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(Icons.notifications_active, color: AppColors.error),
          const SizedBox(width: AppConstants.spacingSm),
          Text(
            l10n.smartAlerts,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: AppConstants.borderRadiusFull,
            ),
            child: Text(
              '$alertsCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppConstants.spacingMd),

      // ✅ Hint: بطاقة المنتجات المنخفضة
      if (_lowStockProducts.isNotEmpty)
        _buildAlertCard(
          title: l10n.lowStockAlert,
          subtitle: l10n.lowStockAlertSubtitle(_lowStockProducts.length),
          icon: Icons.inventory_2,
          color: AppColors.error,
          isDark: isDark,
          onTap: () => _showLowStockDialog(l10n),
        ),

      if (_lowStockProducts.isNotEmpty && _overdueCustomers.isNotEmpty)
        const SizedBox(height: AppConstants.spacingSm),

     // تم تعطيله واشتخدام الفلتر اعلى الصفحة
      // // ✅ Hint: بطاقة العملاء المتأخرين (مع فلتر الأيام)
      // if (_overdueCustomers.isNotEmpty)
      //   Column(
      //     children: [
      //       _buildAlertCard(
      //         title: l10n.overdueCustomersAlert,
      //         subtitle: l10n.overdueCustomersAlertSubtitle(_overdueCustomers.length),
      //         icon: Icons.people_outline,
      //         color: AppColors.warning,
      //         isDark: isDark,
      //         onTap: () => _showOverdueCustomersDialog(l10n),
      //       ),
            
      //       const SizedBox(height: AppConstants.spacingSm),
            
      //       // ✅ Hint: فلتر اختيار عدد الأيام (جديد)
      //       _buildOverdueDaysFilter(l10n, isDark),
      //     ],
      //   ),
    ],
  );
}

   // ==========================================================================
  // 📉 القسم 5: العملاء المدينون
  // ==========================================================================
  Widget _buildTopDebtorsSection(AppLocalizations l10n, bool isDark) {
    if (_topDebtors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.error),
            const SizedBox(width: AppConstants.spacingSm),
            Text(
              l10n.topDebtors,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingMd),

        CustomCard(
          padding: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _topDebtors.length > 5 ? 5 : _topDebtors.length,
            separatorBuilder: (context, index) => Divider(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              height: 1,
            ),
            itemBuilder: (context, index) {
              final debtor = _topDebtors[index];
              final customerName = debtor['CustomerName'] as String;
              final remaining = debtor['Remaining'] as Decimal;
              final daysSince = (debtor['DaysSinceLastTransaction'] as num?)?.toInt() ?? 0;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.error.withOpacity(0.1),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  customerName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  l10n.daysSinceLastTransaction(daysSince),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: Text(
                  formatCurrency(remaining),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

// ==========================================================================
// 🃏 بناء بطاقة تنبيه واحدة
// ==========================================================================
Widget _buildAlertCard({
  required String title,
  required String subtitle,
  required IconData icon,
  required Color color,
  required bool isDark,
  required VoidCallback onTap,
}) {
  return CustomCard(
    onTap: onTap,
    color: color.withOpacity(0.05),
    child: Row(
      children: [
        // === الأيقونة ===
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: AppConstants.borderRadiusMd,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        
        const SizedBox(width: AppConstants.spacingMd),
        
        // === المحتوى ===
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
              ),
              const SizedBox(height: AppConstants.spacingXs),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        
        // === السهم ===
        Icon(Icons.arrow_forward_ios, size: 16, color: color),
      ],
    ),
  );
}

  // ==========================================================================
  // 💰 القسم 3: الإحصائيات المالية
  // ==========================================================================
  Widget _buildFinancialStatsSection(AppLocalizations l10n, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.financialStats,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppConstants.spacingMd),

        CustomCard(
          child: Column(
            children: [
              _buildFinancialRow(
                l10n.totalDebts,
                formatCurrency(_totalDebts),
                Icons.account_balance_wallet,
                AppColors.expense,
                isDark,
              ),
              Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              _buildFinancialRow(
                l10n.totalPayments,
                formatCurrency(_totalPayments),
                Icons.payments,
                AppColors.income,
                isDark,
              ),
              Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.trending_up,
                              color: _getCollectionRateColor(_collectionRate),
                              size: 20,
                            ),
                            const SizedBox(width: AppConstants.spacingSm),
                            Text(
                              l10n.collectionRate,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        Text(
                          '${_collectionRate.toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _getCollectionRateColor(_collectionRate),
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingSm),
                    ClipRRect(
                      borderRadius: AppConstants.borderRadiusFull,
                      child: LinearProgressIndicator(
                        value: (_collectionRate / Decimal.fromInt(100)).toDouble(),
                        backgroundColor: isDark
                            ? AppColors.surfaceDark
                            : AppColors.surfaceLight,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getCollectionRateColor(_collectionRate),
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialRow(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppConstants.spacingSm),
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Color _getCollectionRateColor(Decimal rate) {
       if (rate >= Decimal.fromInt(80)) return AppColors.success;
       if (rate >= Decimal.fromInt(50)) return AppColors.warning;
    return AppColors.error;
  }

  // ==========================================================================
  // 🏆 القسم 4: أكثر العملاء شراءً
  // ==========================================================================
  Widget _buildTopBuyersSection(AppLocalizations l10n, bool isDark) {
    if (_topBuyers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.workspace_premium, color: AppColors.success),
            const SizedBox(width: AppConstants.spacingSm),
            Text(
              l10n.topBuyers,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingMd),

        // ✅ Hint: زيادة الارتفاع لحل مشكلة overflow
        SizedBox(
          height: 150, // ✅ تم تغييره من 120 إلى 150
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            // ✅ Hint: إضافة physics للحركة السلسة
            physics: const BouncingScrollPhysics(),
            itemCount: _topBuyers.length,
            itemBuilder: (context, index) {
              final customer = _topBuyers[index];
              return _buildCustomerCard(
                customer.customerName,
                formatCurrency(customer.debt),
                AppColors.success,
                isDark,
                index + 1,
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // ⭐ القسم 6: أكثر المنتجات مبيعاً
  // ==========================================================================
  Widget _buildTopSellingProductsSection(AppLocalizations l10n, bool isDark) {
    if (_topSellingProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star, color: AppColors.warning),
            const SizedBox(width: AppConstants.spacingSm),
            Text(
              l10n.topSellingProducts,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingMd),

        // ✅ Hint: زيادة الارتفاع
        SizedBox(
          height: 160, // ✅ تم تغييره من 140 إلى 160
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _topSellingProducts.length,
            itemBuilder: (context, index) {
              final product = _topSellingProducts[index];
              return _buildProductCard(
                product.productName,
                formatCurrency(product.sellingPrice),
                '${product.quantity} ${l10n.inStock}',
                AppColors.warning,
                isDark,
                index + 1,
              );
            },
          ),
        ),
      ],
    );
  }

  // ✅ Hint: بطاقة عميل محسّنة
  Widget _buildCustomerCard(
    String name,
    String amount,
    Color color,
    bool isDark,
    int rank,
  ) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: AppConstants.spacingMd),
      child: CustomCard(
        color: color.withOpacity(0.05),
        // ✅ Hint: تقليل الـ padding
        padding: const EdgeInsets.all(AppConstants.spacingSm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // ✅ Hint: إضافة هذا
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingSm),

            // ✅ Hint: استخدام Flexible بدلاً من Expanded
            Flexible(
              child: Text(
                name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: AppConstants.spacingXs),

            Text(
              amount,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Hint: بطاقة منتج محسّنة
  Widget _buildProductCard(
    String name,
    String price,
    String stock,
    Color color,
    bool isDark,
    int rank,
  ) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: AppConstants.spacingMd),
      child: CustomCard(
        color: color.withOpacity(0.05),
        padding: const EdgeInsets.all(AppConstants.spacingSm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Icon(Icons.shopping_bag, color: color, size: 20),
              ],
            ),
            const SizedBox(height: AppConstants.spacingSm),

            Flexible(
              child: Text(
                name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: AppConstants.spacingXs),

            Text(
              price,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppConstants.spacingXs),

            Text(
              stock,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // 📈 القسم 7: رسم المبيعات الشهرية
  // ==========================================================================
  // Widget _buildMonthlySalesChart(AppLocalizations l10n, bool isDark) {
  //   if (_monthlySales.isEmpty) {
  //     return const SizedBox.shrink();
  //   }

  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         l10n.monthlySalesChart,
  //         style: Theme.of(context).textTheme.titleLarge?.copyWith(
  //               fontWeight: FontWeight.bold,
  //             ),
  //       ),
  //       const SizedBox(height: AppConstants.spacingMd),

  //       CustomCard(
  //         child: SizedBox(
  //           height: 250,
  //           child: LineChart(
  //             LineChartData(
  //               gridData: FlGridData(
  //                 show: true,
  //                 drawVerticalLine: false,
  //                 horizontalInterval: 1,
  //                 getDrawingHorizontalLine: (value) {
  //                   return FlLine(
  //                     color: isDark
  //                         ? AppColors.borderDark.withOpacity(0.3)
  //                         : AppColors.borderLight.withOpacity(0.3),
  //                     strokeWidth: 1,
  //                   );
  //                 },
  //               ),
  //               titlesData: FlTitlesData(
  //                 leftTitles: AxisTitles(
  //                   sideTitles: SideTitles(
  //                     showTitles: true,
  //                     reservedSize: 50,
  //                     getTitlesWidget: (value, meta) {
  //                       return Text(
  //                         formatCurrencyWithoutSymbol(value),
  //                         style: Theme.of(context).textTheme.bodySmall,
  //                       );
  //                     },
  //                   ),
  //                 ),
  //                 bottomTitles: AxisTitles(
  //                   sideTitles: SideTitles(
  //                     showTitles: true,
  //                     reservedSize: 30,
  //                     getTitlesWidget: (value, meta) {
  //                       final index = value.toInt();
  //                       if (index < 0 || index >= _monthlySales.length) {
  //                         return const Text('');
  //                       }
  //                       final monthStr = _monthlySales[index]['Month'] as String;
  //                       final month = monthStr.split('-').last;
  //                       return Text(
  //                         month,
  //                         style: Theme.of(context).textTheme.bodySmall,
  //                       );
  //                     },
  //                   ),
  //                 ),
  //                 rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
  //                 topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
  //               ),
  //               borderData: FlBorderData(show: false),
  //               lineBarsData: [
  //                 LineChartBarData(
  //                   spots: _monthlySales.asMap().entries.map((entry) {
  //                     final index = entry.key;
  //                     final data = entry.value;
  //                     final sales = (data['TotalSales'] as num).toDouble();
  //                     return FlSpot(index.toDouble(), sales);
  //                   }).toList(),
  //                   isCurved: true,
  //                   color: AppColors.success,
  //                   barWidth: 3,
  //                   isStrokeCapRound: true,
  //                   dotData: FlDotData(
  //                     show: true,
  //                     getDotPainter: (spot, percent, barData, index) {
  //                       return FlDotCirclePainter(
  //                         radius: 4,
  //                         color: AppColors.success,
  //                         strokeWidth: 2,
  //                         strokeColor: Colors.white,
  //                       );
  //                     },
  //                   ),
  //                   belowBarData: BarAreaData(
  //                     show: true,
  //                     color: AppColors.success.withOpacity(0.1),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // ==========================================================================
  // 📊 القسم 8: رسم توزيع الأرباح حسب الموردين
  // ==========================================================================
  Widget _buildSuppliersChart(AppLocalizations l10n, bool isDark) {
    if (_topSuppliers.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalProfit = _topSuppliers.fold<Decimal>(
       Decimal.zero,
       (sum, supplier) => sum + (supplier['TotalProfit'] as Decimal),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.profitBySupplier,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppConstants.spacingMd),

        CustomCard(
          child: Column(
            children: [
              SizedBox(
                height: 240,
                child: PieChart(
                  PieChartData(
                    sections: _topSuppliers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final supplier = entry.value;
                      final profit = supplier['TotalProfit'] as Decimal;

                     // تحويل لـ double قبل الحسابات
                      final profitDouble = profit.toDouble();
                      final totalProfitDouble = totalProfit.toDouble();
                      final percentage = (profitDouble / totalProfitDouble) * 100;

                      return PieChartSectionData(
                        value: profitDouble,
                        title: '${percentage.toStringAsFixed(1)}%',
                        color: AppColors.chartColors[index % AppColors.chartColors.length],
                        radius: 80,
                        titleStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                    sectionsSpace: 4,
                    centerSpaceRadius: 20,
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.spacingLg),

              ..._topSuppliers.asMap().entries.map((entry) {
                final index = entry.key;
                final supplier = entry.value;
                final name = supplier['SupplierName'] as String;
                final profit = supplier['TotalProfit'] as Decimal;
                final color = AppColors.chartColors[index % AppColors.chartColors.length];

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppConstants.spacingSm),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 18,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingSm),
                      Expanded(
                        child: Text(
                          name,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      Text(
                        formatCurrency(profit),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }


  // ==========================================================================
  // 🔔 حوارات التنبيهات
  // ==========================================================================

  void _showLowStockDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.inventory_2, color: AppColors.error),
            const SizedBox(width: AppConstants.spacingSm),
            Expanded(child: Text(l10n.lowStockProducts)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _lowStockProducts.length,
            itemBuilder: (context, index) {
              final product = _lowStockProducts[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.error.withOpacity(0.1),
                  child: Icon(Icons.warning, color: AppColors.error, size: 20),
                ),
                title: Text(product.productName),
                subtitle: Text('${l10n.quantity}: ${product.quantity}'),
                trailing: Text(
                  formatCurrency(product.sellingPrice),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _showOverdueCustomersDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.people_outline, color: AppColors.warning),
            const SizedBox(width: AppConstants.spacingSm),
            Expanded(child: Text(l10n.overdueCustomers)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _overdueCustomers.length,
            itemBuilder: (context, index) {
              final customer = _overdueCustomers[index];
              final name = customer['CustomerName'] as String;
              final remaining = customer['Remaining'] as Decimal;
              final days = (customer['DaysSinceLastTransaction'] as num?)?.toInt() ?? 0;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.warning.withOpacity(0.1),
                  child: Icon(Icons.person, color: AppColors.warning, size: 20),
                ),
                title: Text(name),
                subtitle: Text(l10n.daysSinceLastTransaction(days)),
                trailing: Text(
                  formatCurrency(remaining),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  // ← Hint: هذه الدالة تُضاف في نهاية الكلاس قبل الإغلاق

// ==========================================================================
// 🔍 Bottom Sheet لفلتر العملاء المتأخرين
// ==========================================================================
/// ← Hint: دالة جديدة تعرض Bottom Sheet مع فلتر الأيام وقائمة العملاء
void _showOverdueFilterSheet(AppLocalizations l10n) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (context, setSheetState) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // ← Hint: Header مع Handle
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingMd),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Handle
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.textHintDark
                              : AppColors.textHintLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      
                      const SizedBox(height: AppConstants.spacingMd),
                      
                      // العنوان
                      Row(
                        children: [
                          Icon(
                            Icons.filter_list_rounded,
                            color: AppColors.info,
                            size: 28,
                          ),
                          const SizedBox(width: AppConstants.spacingSm),
                          Expanded(
                            child: Text(
                              l10n.filterOverdueCustomers,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ← Hint: المحتوى
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(AppConstants.spacingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ← Hint: فلتر اختيار الأيام
                        _buildDaysFilterSection(l10n, isDark, setSheetState),

                        const SizedBox(height: AppConstants.spacingXl),

                        // ← Hint: قائمة العملاء المتأخرين
                        _buildOverdueCustomersListInSheet(l10n, isDark),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    ),
  );
}

// ==========================================================================
// ← Hint: بناء قسم فلتر الأيام في Bottom Sheet
// ==========================================================================
Widget _buildDaysFilterSection(
  AppLocalizations l10n,
  bool isDark,
  StateSetter setSheetState,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // العنوان
      Row(
        children: [
          Icon(
            Icons.date_range_rounded,
            color: AppColors.info,
            size: 20,
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Text(
            l10n.selectPeriod,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),

      const SizedBox(height: AppConstants.spacingMd),

      // ← Hint: أزرار اختيار سريع
      Wrap(
        spacing: AppConstants.spacingSm,
        runSpacing: AppConstants.spacingSm,
        children: [
          _buildDaysChip(7, l10n, isDark, setSheetState),
          _buildDaysChip(15, l10n, isDark, setSheetState),
          _buildDaysChip(30, l10n, isDark, setSheetState),
          _buildDaysChip(60, l10n, isDark, setSheetState),
          _buildDaysChip(90, l10n, isDark, setSheetState),
        ],
      ),

      const SizedBox(height: AppConstants.spacingMd),

      // ← Hint: زر الاختيار المخصص
      OutlinedButton.icon(
        onPressed: () => _showCustomDaysDialogInSheet(l10n, setSheetState),
        icon: const Icon(Icons.edit_calendar, size: 18),
        label: Text(l10n.customDays),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.info,
          side: BorderSide(color: AppColors.info),
        ),
      ),
    ],
  );
}

// ==========================================================================
// ← Hint: بناء Chip لاختيار الأيام في Bottom Sheet
// ==========================================================================
Widget _buildDaysChip(
  int days,
  AppLocalizations l10n,
  bool isDark,
  StateSetter setSheetState,
) {
  final isSelected = _overdueDaysThreshold == days;

  return FilterChip(
    label: Text(
      l10n.daysCount(days.toString()),
      style: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    ),
    selected: isSelected,
    onSelected: (selected) {
      if (selected) {
        // ← Hint: تحديث كل من الـ Sheet والصفحة الرئيسية
        setSheetState(() {
          _overdueDaysThreshold = days;
        });
        setState(() {
          _overdueDaysThreshold = days;
        });
        _loadDashboardData();
      }
    },
    selectedColor: AppColors.info.withOpacity(0.3),
    checkmarkColor: AppColors.info,
    backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
    side: BorderSide(
      color: isSelected ? AppColors.info : Colors.transparent,
      width: 2,
    ),
  );
}

// ==========================================================================
// ← Hint: حوار اختيار أيام مخصص في Bottom Sheet
// ==========================================================================
Future<void> _showCustomDaysDialogInSheet(
  AppLocalizations l10n,
  StateSetter setSheetState,
) async {
  final controller = TextEditingController(
    text: _overdueDaysThreshold.toString(),
  );

  final result = await showDialog<int>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.selectCustomDays),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: l10n.numberOfDays,
          hintText: '30',
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            final days = int.tryParse(controller.text);
            if (days != null && days > 0) {
              Navigator.pop(ctx, days);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.enterValidNumber),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          child: Text(l10n.apply),
        ),
      ],
    ),
  );

  if (result != null && result != _overdueDaysThreshold) {
    // ← Hint: تحديث كل من الـ Sheet والصفحة الرئيسية
    setSheetState(() {
      _overdueDaysThreshold = result;
    });
    setState(() {
      _overdueDaysThreshold = result;
    });
    _loadDashboardData();
  }
}

// ==========================================================================
// ← Hint: بناء قائمة العملاء المتأخرين في Bottom Sheet
// ==========================================================================
Widget _buildOverdueCustomersListInSheet(AppLocalizations l10n, bool isDark) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // العنوان مع العدد
      Row(
        children: [
          Icon(
            Icons.people_outline,
            color: AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Text(
            l10n.overdueCustomers,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: _overdueCustomers.isEmpty
                  ? AppColors.success
                  : AppColors.warning,
              borderRadius: AppConstants.borderRadiusFull,
            ),
            child: Text(
              '${_overdueCustomers.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: AppConstants.spacingMd),

      // ← Hint: حالة الفراغ
      if (_overdueCustomers.isEmpty)
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingXl),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.05),
            borderRadius: AppConstants.borderRadiusMd,
            border: Border.all(
              color: AppColors.success.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: AppColors.success,
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Text(
                l10n.noOverdueCustomers,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                l10n.noOverdueCustomersMessage(_overdueDaysThreshold),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
      else
        // ← Hint: قائمة العملاء
        CustomCard(
          padding: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _overdueCustomers.length,
            separatorBuilder: (context, index) => Divider(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              height: 1,
              indent: 72,
            ),
            itemBuilder: (context, index) {
              final customer = _overdueCustomers[index];
              final customerName = customer['CustomerName'] as String;
              final remaining = customer['Remaining'] as Decimal;
              final daysSince = (customer['DaysSinceLastTransaction'] as num?)
                      ?.toInt() ??
                  0;
              final phone = customer['Phone'] as String?;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingMd,
                  vertical: AppConstants.spacingSm,
                ),
                leading: CircleAvatar(
                  backgroundColor: AppColors.warning.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    color: AppColors.warning,
                    size: 24,
                  ),
                ),
                title: Text(
                  customerName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.daysSinceLastTransaction(daysSince),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    if (phone != null && phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 14,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            phone,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatCurrency(remaining),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.debt,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.error,
                            fontSize: 10,
                          ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
    ],
  );
}



}