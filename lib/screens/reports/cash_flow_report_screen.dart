// lib/screens/reports/cash_flow_report_screen.dart

import 'package:accountant_touch/utils/decimal_extensions.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database_helper.dart';
import 'package:accountant_touch/l10n/app_localizations.dart';
import '../../utils/helpers.dart';
import '../../utils/pdf_helpers.dart';
import '../../services/pdf_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_state.dart';

/// شاشة تقرير التدفق النقدي
class CashFlowReportScreen extends StatefulWidget {
  const CashFlowReportScreen({super.key});

  @override
  State<CashFlowReportScreen> createState() => _CashFlowReportScreenState();
}

class _CashFlowReportScreenState extends State<CashFlowReportScreen> {
  // ============================================================================
  // المتغيرات الأساسية
  // ============================================================================
  final dbHelper = DatabaseHelper.instance;
  late Future<List<Map<String, dynamic>>> _transactionsFuture;
  
  DateTime _startDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  DateTime _endDate = DateTime.now();
  bool _isDetailsVisible = false;
  bool _isGeneratingPdf = false; // ✅ متغير حالة PDF

  // ============================================================================
  // دورة الحياة
  // ============================================================================
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// تحميل البيانات من قاعدة البيانات
  void _loadData() {
    setState(() {
      _transactionsFuture = dbHelper.getCashFlowTransactions(
        startDate: _startDate,
        endDate: _endDate,
      );
    });
  }

  /// فتح نافذة اختيار نطاق التاريخ
  Future<void> _pickDateRange() async {
      final isDark = Theme.of(context).brightness == Brightness.dark;
  
  final newDateRange = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2020),
    lastDate: DateTime.now().add(const Duration(days: 1)),
    initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: isDark
              ? ColorScheme.dark(
                  primary: Theme.of(context).primaryColor,
                  onPrimary: Colors.white,
                  surface: const Color(0xFF1E1E1E),
                  onSurface: Colors.white,
                )
              : ColorScheme.light(
                  primary: Theme.of(context).primaryColor,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black87,
                ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: isDark ? Colors.white : Theme.of(context).primaryColor,
            ),
          ),
        ),
        child: child!,
      );
    },
  );

  if (newDateRange != null) {
    setState(() {
      _startDate = newDateRange.start;
      _endDate = newDateRange.end;
    });
    _loadData();
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
      // AppBar
      // ============================================================================
      appBar: AppBar(
        title: Text(l10n.cashFlowReport),
        actions: [
          // زر اختيار نطاق التاريخ
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _pickDateRange,
            tooltip: l10n.selectDateRange,
          ),
          // زر التحديث
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
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
      // المحتوى
      // ============================================================================
      body: Column(
        children: [
          // معلومات الفترة الزمنية المحددة
          _buildDateRangeInfo(l10n),
          
          // محتوى التقرير
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _transactionsFuture,
              builder: (context, snapshot) {
                // حالة التحميل
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return LoadingState(message: l10n.loadingData);
                }

                // حالة الخطأ
                if (snapshot.hasError) {
                  return ErrorState(
                    message: l10n.errorOccurred(snapshot.error.toString()),
                    onRetry: _loadData,
                  );
                }

                // حالة عدم وجود بيانات
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return EmptyState(
                    icon: Icons.account_balance_wallet,
                    title: l10n.noTransactions,
                    message: l10n.noTransactionsInPeriod,
                  );
                }

                // حساب الإجماليات
                Decimal totalCashSales = Decimal.zero;
                Decimal totalDebtPayments = Decimal.zero;
                
                for (var trans in snapshot.data!) {

                  if (trans['type'] == 'CASH_SALE') {
                    // totalCashSales += trans['amount'];
       // totalCashSales += Decimal.parse(trans['amount'].toString());   //هذا حل  
                    totalCashSales += trans.getDecimal('amount');  // ✅ أفضل
                    
                  } else if (trans['type'] == 'DEBT_PAYMENT') {
                    // totalDebtPayments += trans['amount'];
        // totalDebtPayments += Decimal.parse(trans['amount'].toString());   //هذا حل
                    totalDebtPayments += trans.getDecimal('amount');  // ✅ أفضل
                  }
                }
                
                final totalCashIn = totalCashSales + totalDebtPayments;

                return ListView(
                  padding: AppConstants.screenPadding,
                  children: [
                    // بطاقة إجمالي المبيعات النقدية
                    _buildSummaryCard(
                      l10n.totalCashSales,
                      totalCashSales,
                      Icons.point_of_sale,
                      AppColors.info,
                    ),
                    
                    const SizedBox(height: AppConstants.spacingSm),
                    
                    // بطاقة إجمالي تسديدات الديون
                    _buildSummaryCard(
                      l10n.totalDebtPayments,
                      totalDebtPayments,
                      Icons.payments,
                      AppColors.warning,
                    ),
                    
                    const SizedBox(height: AppConstants.spacingSm),
                    
                    // بطاقة الإجمالي الكلي للتدفق النقدي
                    _buildSummaryCard(
                      l10n.totalCashInflow,
                      totalCashIn,
                      Icons.account_balance_wallet,
                      AppColors.success,
                      isTotal: true,
                    ),
                    
                    const SizedBox(height: AppConstants.spacingLg),
                    
                    const Divider(),
                    
                    // زر إظهار/إخفاء التفاصيل
                    _buildToggleDetailsButton(l10n),
                    
                    // قائمة التفاصيل (إن كانت ظاهرة)
                    if (_isDetailsVisible) ...[
                      const SizedBox(height: AppConstants.spacingMd),
                      _buildTransactionsList(snapshot.data!, l10n),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Widgets مساعدة
  // ============================================================================

  /// بناء عرض معلومات الفترة الزمنية
  Widget _buildDateRangeInfo(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: AppConstants.paddingMd,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.4),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).splashColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 16,
            // color: Theme.of(context).primaryColor, يجب تعديل لون  هذا اللون
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Text(
            '${DateFormat('yyyy-MM-dd').format(_startDate)} - ${DateFormat('yyyy-MM-dd').format(_endDate)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء بطاقة ملخص
  Widget _buildSummaryCard(
    String title,
    Decimal amount,
    IconData icon,
    Color color, {
    bool isTotal = false,
  }) {
    return CustomCard(
      color: isTotal 
          ? color.withOpacity(0.1) 
          : null,
      child: Row(
        children: [
          // أيقونة البطاقة
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: AppConstants.borderRadiusMd,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          
          const SizedBox(width: AppConstants.spacingMd),
          
          // النصوص
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXs),
                Text(
                  formatCurrency(amount),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // مؤشر الزيادة
          if (amount > Decimal.zero)
            Icon(
              Icons.trending_up,
              color: color,
              size: 32,
            ),
        ],
      ),
    );
  }

  /// زر إظهار/إخفاء التفاصيل
  Widget _buildToggleDetailsButton(AppLocalizations l10n) {
    return InkWell(
      onTap: () {
        setState(() {
          _isDetailsVisible = !_isDetailsVisible;
        });
      },
      borderRadius: AppConstants.borderRadiusMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppConstants.spacingMd,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isDetailsVisible 
                  ? Icons.visibility_off_outlined 
                  : Icons.visibility_outlined,
              size: 20,
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Text(
              _isDetailsVisible ? l10n.hideDetails : l10n.showDetails,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء قائمة المعاملات التفصيلية
  Widget _buildTransactionsList(
    List<Map<String, dynamic>> transactions,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // رأس القائمة
        Padding(
          padding: const EdgeInsets.only(bottom: AppConstants.spacingMd),
          child: Row(
            children: [
              Icon(
                Icons.list,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Text(
                l10n.transactionDetails,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: AppConstants.borderRadiusFull,
                ),
                child: Text(
                  '${transactions.length}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // قائمة البطاقات
        ...transactions.map((trans) {
          final isCashSale = trans['type'] == 'CASH_SALE';
          
          // استخراج اسم الزبون
          final description = isCashSale
              ? l10n.cashSaleDescription(trans['id'].toString())
              : l10n.debtPaymentDescription(
                  trans['description'].toString().split(': ').last,
                );

          return Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.spacingSm),
            child: CustomCard(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              child: Row(
                children: [
                  // أيقونة نوع المعاملة
                  Container(
                    padding: const EdgeInsets.all(AppConstants.spacingSm),
                    decoration: BoxDecoration(
                      color: isCashSale
                          ? AppColors.info.withOpacity(0.1)
                          : AppColors.warning.withOpacity(0.1),
                      borderRadius: AppConstants.borderRadiusSm,
                    ),
                    child: Icon(
                      isCashSale ? Icons.point_of_sale : Icons.payments,
                      color: isCashSale ? AppColors.info : AppColors.warning,
                      size: 20,
                    ),
                  ),
                  
                  const SizedBox(width: AppConstants.spacingMd),
                  
                  // تفاصيل المعاملة
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppConstants.spacingXs),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('yyyy-MM-dd').format(
                                DateTime.parse(trans['date']),
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // المبلغ والشارة
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        // formatCurrency(trans['amount']),
                        formatCurrency(trans.getDecimal('amount')),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingXs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: AppConstants.borderRadiusFull,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_downward,
                              size: 10,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              l10n.cashIn,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  // ============================================================================
  // 📄 دالة توليد PDF
  // ============================================================================
  Future<void> _generatePdf() async {
    setState(() => _isGeneratingPdf = true);
    
    try {
      // 1️⃣ جلب البيانات
      final transactions = await _transactionsFuture;
      
      // 2️⃣ حساب الإجماليات
      Decimal totalCashSales = Decimal.zero;
      Decimal totalDebtPayments = Decimal.zero;
      
      for (var trans in transactions) {

        if (trans['type'] == 'CASH_SALE') {
          // totalCashSales += trans['amount'];
          totalCashSales += trans.getDecimal('amount');

        } else if (trans['type'] == 'DEBT_PAYMENT') {
          // totalDebtPayments += trans['amount'];
          totalDebtPayments += trans.getDecimal('amount');
        }
      }
      
      final totalCashIn = totalCashSales + totalDebtPayments;
      
      // 3️⃣ إنشاء PDF
      final pdf = await PdfService.instance.buildCashFlowReport(
        transactions: transactions,
        totalCashSales: totalCashSales,
        totalDebtPayments: totalDebtPayments,
        totalCashIn: totalCashIn,
        startDate: _startDate,
        endDate: _endDate,
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