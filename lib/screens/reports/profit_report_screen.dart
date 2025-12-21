// lib/screens/reports/profit_report_screen.dart

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../utils/helpers.dart';
import '../../utils/pdf_helpers.dart';
import '../../services/pdf_service.dart';
import '../../services/account_service.dart';
import '../../services/currency_service.dart';
import '../../providers/accounting_view_provider.dart';
import '../../l10n/app_localizations.dart';
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
  // ============================================================================
  // المتغيرات
  // ============================================================================
  final dbHelper = DatabaseHelper.instance;
  late Future<FinancialSummary> _summaryFuture;
  bool _isDetailsVisible = false; // للتحكم في إظهار/إخفاء التفاصيل
  bool _isGeneratingPdf = false; // ✅ متغير حالة PDF

  // ← Hint: متغيرات للبيانات المحاسبية (جديد)
  Account? _cashAccount;
  Account? _inventoryAccount;
  Account? _suppliersAccount;
  Decimal _totalAssets = Decimal.zero;
  Decimal _totalLiabilities = Decimal.zero;

  // ============================================================================
  // التهيئة
  // ============================================================================
  @override
  void initState() {
    super.initState();
    _loadFinancialSummary();
    _loadAccountingData(); // ← تحميل البيانات المحاسبية
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
      grossProfit: results[0] as Decimal,
      totalExpenses: results[1] as Decimal,
      totalWithdrawals: results[2] as Decimal,
      sales: results[3] as List<CustomerDebt>,
    );
  }

  /// ============================================================================
  /// تحميل البيانات المحاسبية (جديد)
  /// ============================================================================
  /// ← Hint: يجلب أرصدة الحسابات من النظام المحاسبي
  Future<void> _loadAccountingData() async {
    try {
      final accountService = AccountService.instance;

      // جلب الحسابات المهمة
      _cashAccount = await accountService.getCashAccount();
      _inventoryAccount = await accountService.getInventoryAccount();
      _suppliersAccount = await accountService.getSuppliersAccount();

      // جلب الإحصائيات
      _totalAssets = await accountService.getTotalAssets();
      _totalLiabilities = await accountService.getTotalLiabilities();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل البيانات المحاسبية: $e');
    }
  }

  // ============================================================================
  // البناء الرئيسي
  // ============================================================================
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      // ============================================================================
      // AppBar مع زر التحديث و PDF
      // ============================================================================
      appBar: AppBar(
        title: Text(l10n.generalProfitReport),
        elevation: 0,
        actions: [
          // زر التحديث
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFinancialSummary,
            tooltip: l10n.refresh,
          ),
          // ✅ زر PDF
          IconButton(
            icon: _isGeneratingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf),
            onPressed: _isGeneratingPdf ? null : _generatePdf,
            tooltip: 'تصدير PDF',
          ),
        ],
      ),

      // ============================================================================
      // الجسم: الملخص المالي والتفاصيل
      // ============================================================================
      body: FutureBuilder<FinancialSummary>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          // --- حالة التحميل ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return LoadingState(
              message: l10n.calculatingProfits,
            );
          }

          // --- حالة الخطأ ---
          if (snapshot.hasError) {
            return ErrorState(
              message: l10n.errorOccurred(snapshot.error.toString()),
              onRetry: _loadFinancialSummary,
            );
          }

          // --- حالة عدم وجود بيانات ---
          if (!snapshot.hasData) {
            return EmptyState(
              icon: Icons.trending_up,
              title: l10n.noData,
              message: l10n.noOperationsRecorded,
            );
          }

          // --- عرض البيانات ---
          final summary = snapshot.data!;
          final netProfit = summary.grossProfit -
              summary.totalExpenses -
              summary.totalWithdrawals;

          // ← Hint: استخدام Consumer للوصول إلى AccountingViewProvider
          return Consumer<AccountingViewProvider>(
            builder: (context, accountingProvider, child) {
              return SingleChildScrollView(
                padding: AppConstants.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 💰 قسم الملخص المالي
                    _buildFinancialSummarySection(summary, netProfit, l10n),

                    const SizedBox(height: AppConstants.spacingXl),

                    // 🔍 زر إظهار/إخفاء التفاصيل
                    _buildToggleDetailsButton(l10n),

                    // 📋 قائمة تفاصيل المبيعات
                    if (_isDetailsVisible) ...[
                      const SizedBox(height: AppConstants.spacingMd),
                      _buildSalesList(summary.sales, l10n),
                    ],

                    // ═══════════════════════════════════════════════════
                    // ✨ قسم التفاصيل المحاسبية (جديد)
                    // ═══════════════════════════════════════════════════
                    // ← Hint: يظهر فقط إذا فعّل المستخدم "العرض المحاسبي"
                    if (accountingProvider.showAccountingView) ...[
                      const SizedBox(height: AppConstants.spacingXl),
                      const Divider(thickness: 2, height: 40),
                      _buildAccountingSection(l10n),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ============================================================================
  // قسم الملخص المالي
  // ============================================================================
  /// يعرض 4 بطاقات إحصائية:
  /// 1. إجمالي الأرباح من المبيعات
  /// 2. إجمالي المصاريف العامة
  /// 3. إجمالي مسحوبات الأرباح
  /// 4. صافي الربح (النتيجة النهائية)
  Widget _buildFinancialSummarySection(
    FinancialSummary summary,
    Decimal netProfit,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- بطاقة إجمالي الأرباح ---
        StatCard(
          label: l10n.totalProfitsFromSales,
          value: formatCurrency(summary.grossProfit),
          icon: Icons.trending_up,
          color: AppColors.info,
          subtitle: l10n.beforeExpenses,
        ),

        const SizedBox(height: AppConstants.spacingMd),

        // --- بطاقة المصاريف ---
        StatCard(
          label: l10n.totalGeneralExpenses,
          value: formatCurrency(summary.totalExpenses),
          icon: Icons.receipt_long,
          color: AppColors.error,
          subtitle: l10n.billsAndExpenses,
        ),

        const SizedBox(height: AppConstants.spacingMd),

        // --- بطاقة المسحوبات ---
        StatCard(
          label: l10n.totalProfitWithdrawals,
          value: formatCurrency(summary.totalWithdrawals),
          icon: Icons.account_balance_wallet,
          color: AppColors.warning,
          subtitle: l10n.forSuppliersAndPartners,
        ),

        const Divider(height: 32),

        // --- بطاقة صافي الربح (النتيجة النهائية) ---
        CustomCard(
          color: netProfit >= Decimal.zero
              ? AppColors.success.withOpacity(0.1)
              : AppColors.error.withOpacity(0.1),
          child: Padding(
            padding: AppConstants.paddingSm,
            child: Row(
              children: [
                // أيقونة النتيجة
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: netProfit >= Decimal.zero
                        ? AppColors.success.withOpacity(0.2)
                        : AppColors.error.withOpacity(0.2),
                    borderRadius: AppConstants.borderRadiusLg,
                  ),
                  child: Icon(
                    netProfit >= Decimal.zero
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: netProfit >= Decimal.zero
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
                        l10n.netProfit,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppConstants.spacingXs),
                      Text(
                        formatCurrency(netProfit),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: netProfit >= Decimal.zero
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

  // ============================================================================
  // زر إظهار/إخفاء التفاصيل
  // ============================================================================
  /// زر لتبديل عرض قائمة تفاصيل المبيعات
  Widget _buildToggleDetailsButton(AppLocalizations l10n) {
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
            ? l10n.hideSalesDetails
            : l10n.showSalesDetails,
      ),
    );
  }

  // ============================================================================
  // قائمة تفاصيل المبيعات
  // ============================================================================
  /// يعرض جدول بجميع عمليات البيع مع الربح لكل عملية
  Widget _buildSalesList(List<CustomerDebt> sales, AppLocalizations l10n) {
    // --- حالة عدم وجود مبيعات ---
    if (sales.isEmpty) {
      return EmptyState(
        icon: Icons.shopping_cart_outlined,
        title: l10n.noSales,
        message: l10n.noSalesRecorded,
      );
    }

    // --- عرض قائمة المبيعات ---
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان القائمة
        Text(
          l10n.salesDetailsCount(sales.length.toString()),
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
            return _buildSaleCard(sale, l10n);
          },
        ),
      ],
    );
  }

  // ============================================================================
  // بطاقة المبيعة الواحدة
  // ============================================================================
  /// يعرض تفاصيل عملية بيع واحدة
  Widget _buildSaleCard(CustomerDebt sale, AppLocalizations l10n) {
    final saleDate = DateTime.parse(sale.dateT);

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: Padding(
        padding: AppConstants.paddingSm,
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
                    '${sale.customerName ?? l10n.notRegistered} • '
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
                  l10n.fromAmount(formatCurrency(sale.debt)),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // قسم التفاصيل المحاسبية (جديد)
  // ============================================================================
  /// ← Hint: يعرض أرصدة الحسابات والإحصائيات المالية من النظام المحاسبي
  /// يظهر فقط عندما يفعّل المستخدم "العرض المحاسبي" في الإعدادات
  Widget _buildAccountingSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- عنوان القسم ---
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withOpacity(0.1),
                borderRadius: AppConstants.borderRadiusMd,
              ),
              child: Icon(
                Icons.account_balance,
                color: AppColors.primaryDark,
                size: 24,
              ),
            ),
            const SizedBox(width: AppConstants.spacingMd),
            Text(
              'التفاصيل المحاسبية',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),

        const SizedBox(height: AppConstants.spacingLg),

        // --- بطاقة حساب الصندوق (النقدية) ---
        _buildAccountCard(
          title: 'حساب الصندوق',
          accountCode: _cashAccount?.accountCode ?? '----',
          balance: _cashAccount?.balance ?? Decimal.zero,
          icon: Icons.account_balance_wallet,
          color: AppColors.success,
        ),

        const SizedBox(height: AppConstants.spacingMd),

        // --- بطاقة حساب المخزون ---
        _buildAccountCard(
          title: 'حساب المخزون',
          accountCode: _inventoryAccount?.accountCode ?? '----',
          balance: _inventoryAccount?.balance ?? Decimal.zero,
          icon: Icons.inventory_2,
          color: AppColors.info,
        ),

        const SizedBox(height: AppConstants.spacingMd),

        // --- بطاقة حساب الموردين ---
        _buildAccountCard(
          title: 'حساب الموردين',
          accountCode: _suppliersAccount?.accountCode ?? '----',
          balance: _suppliersAccount?.balance ?? Decimal.zero,
          icon: Icons.people_outline,
          color: AppColors.warning,
        ),

        const Divider(height: 32, thickness: 2),

        // --- ملخص الأصول والخصوم ---
        Row(
          children: [
            // إجمالي الأصول
            Expanded(
              child: CustomCard(
                color: AppColors.success.withOpacity(0.05),
                child: Padding(
                  padding: AppConstants.paddingSm,
                  child: Column(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: AppColors.success,
                        size: 32,
                      ),
                      const SizedBox(height: AppConstants.spacingXs),
                      Text(
                        'إجمالي الأصول',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppConstants.spacingXs),
                      Text(
                        formatCurrency(_totalAssets),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: AppConstants.spacingMd),

            // إجمالي الخصوم
            Expanded(
              child: CustomCard(
                color: AppColors.error.withOpacity(0.05),
                child: Padding(
                  padding: AppConstants.paddingSm,
                  child: Column(
                    children: [
                      Icon(
                        Icons.trending_down,
                        color: AppColors.error,
                        size: 32,
                      ),
                      const SizedBox(height: AppConstants.spacingXs),
                      Text(
                        'إجمالي الخصوم',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppConstants.spacingXs),
                      Text(
                        formatCurrency(_totalLiabilities),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppConstants.spacingMd),

        // --- ملاحظة توضيحية ---
        CustomCard(
          color: AppColors.info.withOpacity(0.05),
          child: Padding(
            padding: AppConstants.paddingSm,
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.info,
                  size: 20,
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: Text(
                    'هذه البيانات مأخوذة من النظام المحاسبي ذو القيد المزدوج',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.info,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// بطاقة حساب واحد
  Widget _buildAccountCard({
    required String title,
    required String accountCode,
    required Decimal balance,
    required IconData icon,
    required Color color,
  }) {
    return CustomCard(
      child: Padding(
        padding: AppConstants.paddingSm,
        child: Row(
          children: [
            // --- أيقونة الحساب ---
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: AppConstants.borderRadiusMd,
              ),
              child: Icon(
                icon,
                color: color,
                size: 26,
              ),
            ),

            const SizedBox(width: AppConstants.spacingMd),

            // --- تفاصيل الحساب ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // اسم الحساب
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingXs),
                  // رقم الحساب
                  Text(
                    'رقم الحساب: $accountCode',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // --- الرصيد ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'الرصيد',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppConstants.spacingXs),
                Text(
                  formatCurrency(balance),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: balance >= Decimal.zero ? color : AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // 📄 دالة توليد PDF
  // ============================================================================
  Future<void> _generatePdf() async {
    setState(() => _isGeneratingPdf = true);
    
    try {
      // 1️⃣ جلب البيانات
      final summary = await _summaryFuture;
      final netProfit = summary.grossProfit - 
          summary.totalExpenses - 
          summary.totalWithdrawals;
      
      // 2️⃣ تحويل sales إلى Map
      final salesData = summary.sales.map((sale) => {
        'details': sale.details,
        'customerName': sale.customerName,
        'dateT': sale.dateT,
        'debt': sale.debt,
        'profitAmount': sale.profitAmount,
      }).toList();
      
      // 3️⃣ إنشاء PDF
      final pdf = await PdfService.instance.buildProfitReport(
        totalProfit: summary.grossProfit,
        totalExpenses: summary.totalExpenses,
        totalWithdrawals: summary.totalWithdrawals,
        netProfit: netProfit,
        salesData: salesData,
      );
      
      // 4️⃣ عرض خيارات PDF
      if (!mounted) return;
      
      PdfHelpers.showPdfOptionsDialog(
        context,
        pdf,
        onSuccess: () {
          // يمكنك إضافة كود هنا عند نجاح العملية
        },
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(error)),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
      
    } catch (e) {
      // في حالة حدوث خطأ
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('خطأ في إنشاء PDF: $e')),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }
}

// ============================================================================
// نموذج بيانات الملخص المالي
// ============================================================================
/// كلاس مساعد لتمثيل الملخص المالي الشامل
class FinancialSummary {
  final Decimal grossProfit; // إجمالي الأرباح قبل المصاريف
  final Decimal totalExpenses; // إجمالي المصاريف العامة
  final Decimal totalWithdrawals; // إجمالي مسحوبات الأرباح
  final List<CustomerDebt> sales; // قائمة جميع المبيعات

  FinancialSummary({
    required this.grossProfit,
    required this.totalExpenses,
    required this.totalWithdrawals,
    required this.sales,
  });
}