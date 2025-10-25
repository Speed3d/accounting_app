// lib/screens/sales/invoice_details_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../utils/helpers.dart';

// ✅ استيراد النظام الجديد
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/status_badge.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

/// =================================================================================================
/// 📋 شاشة تفاصيل الفاتورة - Invoice Details Screen
/// =================================================================================================
/// الوظيفة: عرض تفاصيل فاتورة نقدية مع إمكانية إرجاع المنتجات
/// 
/// المميزات:
/// - ✅ عرض جميع بنود الفاتورة
/// - ✅ تمييز البنود المرجعة
/// - ✅ إمكانية إرجاع بند (Long Press)
/// - ✅ تحديث حالة الفاتورة تلقائياً
/// - ✅ دعم الثيم الداكن
/// =================================================================================================
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
  // =================================================================================================
  // 📦 المتغيرات الأساسية
  // =================================================================================================
  
  final dbHelper = DatabaseHelper.instance;
  final AuthService _authService = AuthService();
  late Future<List<CustomerDebt>> _salesFuture;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _salesFuture = dbHelper.getSalesForInvoice(widget.invoiceId);
  }

  // =================================================================================================
  // 🔄 معالجة الإرجاع - Return Handling
  // =================================================================================================
  
  /// Hint: دالة للتعامل مع طلب إرجاع بند من الفاتورة
  Future<void> _handleReturnSale(CustomerDebt sale) async {
    final l10n = AppLocalizations.of(context)!;
    
    // === عرض مربع حوار التأكيد ===
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
                      'سيتم إرجاع المنتج للمخزن وتحديث حالة الفاتورة',
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
    
    // === تنفيذ الإرجاع ===
    try {
      await dbHelper.returnSaleItem(sale);
      await dbHelper.updateInvoiceStatus(widget.invoiceId, 'معدلة');
      await dbHelper.logActivity(
        'إرجاع منتج من فاتورة نقدية #${widget.invoiceId}: ${sale.details}',
        userId: _authService.currentUser?.id,
        userName: _authService.currentUser?.fullName,
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

  // =================================================================================================
  // 🎨 بناء واجهة المستخدم - UI Building
  // =================================================================================================
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // ✅ استخدام PopScope بدلاً من WillPopScope (deprecated)
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop && _hasChanged) {
          // يمكن إضافة منطق إضافي هنا إذا لزم الأمر
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.detailsForInvoice(widget.invoiceId.toString())),
          // ✅ زر الرجوع يظهر تلقائياً
        ),
        body: _buildBody(l10n),
      ),
    );
  }
  
  /// Hint: بناء جسم الصفحة
  Widget _buildBody(AppLocalizations l10n) {
    return FutureBuilder<List<CustomerDebt>>(
      future: _salesFuture,
      builder: (context, snapshot) {
        // === حالة التحميل ===
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingState(message: 'جاري تحميل تفاصيل الفاتورة...');
        }
        
        // === حالة الخطأ ===
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
        
        // === حالة عدم وجود بيانات ===
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'لا توجد بنود في هذه الفاتورة',
            message: 'الفاتورة فارغة أو تم إلغاؤها',
          );
        }
        
        final sales = snapshot.data!;
        
        // === عرض القائمة ===
        return Column(
          children: [
            // معلومات الفاتورة
            _buildInvoiceSummary(sales, l10n),
            
            const Divider(height: 1),
            
            // قائمة البنود
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
  
  // =================================================================================================
  // 🃏 بطاقات العرض - Display Cards
  // =================================================================================================
  
  /// Hint: بناء ملخص الفاتورة في الأعلى
  Widget _buildInvoiceSummary(List<CustomerDebt> sales, AppLocalizations l10n) {
    final totalAmount = sales
        .where((sale) => sale.isReturned == 0)
        .fold(0.0, (sum, sale) => sum + sale.debt);
    
    final returnedAmount = sales
        .where((sale) => sale.isReturned == 1)
        .fold(0.0, (sum, sale) => sum + sale.debt);
    
    final hasReturns = returnedAmount > 0;
    
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
                'إجمالي الفاتورة:',
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
                      'المبلغ المرجع:',
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
                  'الصافي:',
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
            text: 'عدد البنود: ${sales.length}',
            type: StatusType.info,
            small: true,
          ),
        ],
      ),
    );
  }
  
  /// Hint: بناء بطاقة بند من بنود الفاتورة
  Widget _buildSaleItemCard(CustomerDebt sale, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isReturned = sale.isReturned == 1;
    
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      onTap: isReturned ? null : () => _handleReturnSale(sale),
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
                        text: 'مُرجع',
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
                      'اضغط مطولاً للإرجاع',
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