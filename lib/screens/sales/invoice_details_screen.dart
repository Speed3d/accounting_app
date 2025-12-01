// lib/screens/sales/invoice_details_screen.dart

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/helpers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/status_badge.dart';

/// شاشة تفاصيل الفاتورة النقدية
class InvoiceDetailsScreen extends StatefulWidget {
  final int invoiceId;
  
  const InvoiceDetailsScreen({
    super.key,
    required this.invoiceId,
  });

  @override
  State<InvoiceDetailsScreen> createState() => _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends State<InvoiceDetailsScreen> {
  final dbHelper = DatabaseHelper.instance;
  // ← Hint: تم إزالة AuthService
  late Future<List<CustomerDebt>> _salesFuture;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _salesFuture = dbHelper.getSalesForInvoice(widget.invoiceId);
  }

  /// دالة معالجة إرجاع المنتج
  Future<void> _handleReturnSale(CustomerDebt sale) async {
    final l10n = AppLocalizations.of(context)!;
    
    // عرض مربع حوار التأكيد
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: 28,
            ),
            const SizedBox(width: AppConstants.spacingMd),
            Expanded(child: Text(l10n.returnConfirmTitle)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.returnConfirmContent(sale.details)),
            const SizedBox(height: AppConstants.spacingMd),
            // صندوق التحذير
            Container(
              padding: AppConstants.paddingMd,
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: AppConstants.borderRadiusMd,
                border: Border.all(
                  color: AppColors.warning.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppConstants.spacingSm),
                  Expanded(
                    child: Text(
                      l10n.returnWarningMessage,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.warning,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.undo, size: 18),
                const SizedBox(width: AppConstants.spacingXs),
                Text(l10n.returnItem),
              ],
            ),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    // تنفيذ عملية الإرجاع
    try {
      await dbHelper.returnSaleItem(sale);
      await dbHelper.updateInvoiceStatus(widget.invoiceId, l10n.invoiceStatusModified);
      await dbHelper.logActivity(
        l10n.returnActivityLog(widget.invoiceId.toString(), sale.details),
      );
      
      setState(() {
        _hasChanged = true;
        _salesFuture = dbHelper.getSalesForInvoice(widget.invoiceId);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(child: Text(l10n.returnSuccess)),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(child: Text(l10n.errorOccurred(e.toString()))),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // استخدام PopScope لمعالجة زر الرجوع
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop && _hasChanged && Navigator.canPop(context)) {
        }
      },
  child: WillPopScope(
    onWillPop: () async {
      // ✅ نرجع القيمة للشاشة السابقة عند الضغط على زر الرجوع
      if (_hasChanged) {
        Navigator.of(context).pop(true);
        return false; // نمنع الرجوع التلقائي لأننا تعاملنا معه يدوياً
      }
      return true; // نسمح بالرجوع العادي إذا لم يكن هناك تغيير
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(l10n.detailsForInvoice(widget.invoiceId.toString())),
      ),
        body: _buildBody(l10n),
       ),
      ),
    );
  }
  
  /// بناء محتوى الصفحة
  Widget _buildBody(AppLocalizations l10n) {
    return FutureBuilder<List<CustomerDebt>>(
      future: _salesFuture,
      builder: (context, snapshot) {
        // حالة التحميل
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LoadingState(message: l10n.loadingInvoiceDetails);
        }
        
        // حالة الخطأ
        if (snapshot.hasError) {
          return ErrorState(
            message: l10n.errorOccurred(snapshot.error.toString()),
            onRetry: () {
              setState(() {
                _salesFuture = dbHelper.getSalesForInvoice(widget.invoiceId);
              });
            },
          );
        }
        
        // حالة عدم وجود بيانات
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return EmptyState(
            icon: Icons.receipt_long_outlined,
            title: l10n.noItemsInInvoice,
            message: l10n.invoiceEmptyOrCancelled,
          );
        }
        
        final sales = snapshot.data!;
        
        return Column(
          children: [
            _buildInvoiceSummary(sales, l10n),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: AppConstants.screenPadding,
                itemCount: sales.length,
                itemBuilder: (context, index) {
                  return _buildSaleItemCard(sales[index], l10n);
                },
              ),
            ),
          ],
        );
      },
    );
  }
  
  /// بناء ملخص الفاتورة
  Widget _buildInvoiceSummary(List<CustomerDebt> sales, AppLocalizations l10n) {
    // حساب المبلغ الإجمالي (بدون المرتجعات)
    final totalAmount = sales
        .where((sale) => sale.isReturned == 0)
        .fold(Decimal.zero, (sum, sale) => sum + sale.debt);
    
    // حساب المبلغ المرجع
    final returnedAmount = sales
        .where((sale) => sale.isReturned == 1)
        .fold(Decimal.zero, (sum, sale) => sum + sale.debt);
    
    final hasReturns = returnedAmount > Decimal.zero;
    
    return Container(
      padding: AppConstants.paddingLg,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // المبلغ الإجمالي
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.invoiceTotalAmount,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                formatCurrency(totalAmount + returnedAmount),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
              ),
            ],
          ),
          
          // المبلغ المرجع (إن وجد)
          if (hasReturns) ...[
            const SizedBox(height: AppConstants.spacingSm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.undo,
                      size: 16,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: AppConstants.spacingXs),
                    Text(
                      l10n.returnedAmount,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.error,
                          ),
                    ),
                  ],
                ),
                Text(
                  '- ${formatCurrency(returnedAmount)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.netAmount,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  formatCurrency(totalAmount),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.info,
                      ),
                ),
              ],
            ),
          ],
          
          // عدد البنود
          const SizedBox(height: AppConstants.spacingMd),
          StatusBadge(
            text: l10n.itemsCount2(sales.length),
            type: StatusType.info,
            small: true,
          ),
        ],
      ),
    );
  }
  
  /// بناء بطاقة البند
  Widget _buildSaleItemCard(CustomerDebt sale, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isReturned = sale.isReturned == 1;
    
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      // ✅ تم إزالة onTap من هنا لحل التعارض
      color: isReturned
          ? (isDark ? AppColors.borderDark : AppColors.borderLight).withOpacity(0.3)
          : null,
      child: InkWell(
        onLongPress: isReturned ? null : () => _handleReturnSale(sale),
        borderRadius: AppConstants.cardBorderRadius,
        child: Padding(
          padding: AppConstants.paddingMd,
          child: Row(
            children: [
              // أيقونة الحالة
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isReturned
                      ? AppColors.error.withOpacity(0.1)
                      : AppColors.success.withOpacity(0.1),
                  borderRadius: AppConstants.borderRadiusMd,
                  border: Border.all(
                    color: isReturned
                        ? AppColors.error.withOpacity(0.3)
                        : AppColors.success.withOpacity(0.3),
                  ),
                ),
                child: Icon(
                  isReturned ? Icons.undo : Icons.receipt_long,
                  color: isReturned ? AppColors.error : AppColors.success,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: AppConstants.spacingMd),
              
              // معلومات البند
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // اسم المنتج
                    Text(
                      sale.details,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            decoration: isReturned ? TextDecoration.lineThrough : null,
                            color: isReturned
                                ? (isDark ? AppColors.textHintDark : AppColors.textHintLight)
                                : null,
                          ),
                    ),
                    
                    const SizedBox(height: AppConstants.spacingXs),
                    
                    // التاريخ
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: isDark
                              ? AppColors.textHintDark
                              : AppColors.textHintLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('yyyy-MM-dd').format(DateTime.parse(sale.dateT)),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isReturned
                                    ? (isDark ? AppColors.textHintDark : AppColors.textHintLight)
                                    : null,
                              ),
                        ),
                      ],
                    ),
                    
                    // شارة الحالة
                    if (isReturned) ...[
                      const SizedBox(height: AppConstants.spacingSm),
                      StatusBadge(
                        text: l10n.returnedStatus,
                        type: StatusType.error,
                        small: true,
                      ),
                    ],
                  ],
                ),
              ),
              
              // السعر
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(sale.debt),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isReturned
                              ? (isDark ? AppColors.textHintDark : AppColors.textHintLight)
                              : AppColors.success,
                          decoration: isReturned ? TextDecoration.lineThrough : null,
                        ),
                  ),
                  
                  // تلميح للإرجاع
                  if (!isReturned) ...[
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      l10n.longPressToReturn,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: isDark
                                ? AppColors.textHintDark
                                : AppColors.textHintLight,
                          ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}