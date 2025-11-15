// lib/screens/sales/cash_sales_history_screen.dart

import 'package:accounting_app/utils/decimal_extensions.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database_helper.dart';
import 'package:accounting_app/l10n/app_localizations.dart';
import '../../utils/helpers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/status_badge.dart';
import 'invoice_details_screen.dart';

/// 📋 شاشة سجل المبيعات النقدية
/// Hint: هذه صفحة فرعية، لذا نستخدم Scaffold العادي (وليس MainLayout)
class CashSalesHistoryScreen extends StatefulWidget {
  const CashSalesHistoryScreen({super.key});

  @override
  State<CashSalesHistoryScreen> createState() => _CashSalesHistoryScreenState();
}

class _CashSalesHistoryScreenState extends State<CashSalesHistoryScreen> {
  // ============= المتغيرات =============
  final dbHelper = DatabaseHelper.instance;
  late Future<List<Map<String, dynamic>>> _invoicesFuture;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isDetailsVisible = true;

  // ============= دورة الحياة =============
  @override
  void initState() {
    super.initState();
    _loadInvoices();
    // Hint: نستمع للتغييرات في حقل البحث لتحديث النتائج فوراً
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============= الدوال =============
  
  /// تحميل الفواتير من قاعدة البيانات
  void _loadInvoices() {
    setState(() {
      _invoicesFuture = dbHelper.getCashInvoices();
    });
  }

  /// معالجة إلغاء الفاتورة
  /// Hint: نستخدم مربع حوار بالتصميم الجديد للتأكيد
  Future<void> _handleVoidInvoice(int invoiceId, AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmVoidTitle),
        content: Text(l10n.confirmVoidContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: Text(l10n.confirmVoidAction),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await dbHelper.voidInvoice(invoiceId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.voidSuccess),
            backgroundColor: AppColors.success,
          ),
        );
        _loadInvoices();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorOccurred(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ============= البناء =============
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // ============= App Bar =============
      // Hint: AppBar بسيط مع عنوان فقط (بدون CustomAppBar لأنها صفحة فرعية)
      appBar: AppBar(
        title: Text(l10n.cashSalesHistory),
        // Hint: الألوان تأتي تلقائياً من الثيم الموحد
      ),

      // ============= Body =============
      body: Column(
        children: [
          // ============= حقل البحث =============
          // Hint: نستخدم SearchTextField الجاهز مع padding موحد
          Padding(
            padding: AppConstants.paddingHorizontalMd.copyWith(
              top: AppConstants.spacingMd,
              bottom: AppConstants.spacingSm,
            ),
            child: SearchTextField(
              hint: l10n.searchByInvoiceNumber,
              controller: _searchController,
              onClear: () {
                setState(() => _searchQuery = '');
              },
            ),
          ),

          // ============= زر إظهار/إخفاء =============
          // Hint: TextButton بسيط مع أيقونة
          TextButton.icon(
            icon: Icon(
              _isDetailsVisible 
                  ? Icons.visibility_off_outlined 
                  : Icons.visibility_outlined,
            ),
            label: Text(
              _isDetailsVisible ? l10n.hideInvoices : l10n.showInvoices,
            ),
            onPressed: () => setState(() => _isDetailsVisible = !_isDetailsVisible),
          ),

          // ============= القائمة =============
          if (_isDetailsVisible)
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _invoicesFuture,
                builder: (context, snapshot) {
                  // --- حالة التحميل ---
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return  LoadingState(message: l10n.invoicesloaded);
                  }

                  // --- حالة الخطأ ---
                  if (snapshot.hasError) {
                    return ErrorState(
                      message: snapshot.error.toString(),
                      onRetry: _loadInvoices,
                    );
                  }

                  // --- حالة عدم وجود بيانات ---
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return EmptyState(
                      icon: Icons.receipt_long,
                      title: l10n.noCashInvoices,
                      message: l10n.nocashrecordedyet,
                    );
                  }

                  // --- تصفية النتائج حسب البحث ---
                  final filteredInvoices = snapshot.data!.where((invoice) {
                    final invoiceId = invoice['InvoiceID'].toString();
                    final searchText = convertArabicNumbersToEnglish(_searchQuery);
                    return invoiceId.contains(searchText);
                  }).toList();

                  // --- حالة عدم وجود نتائج بحث ---
                  if (filteredInvoices.isEmpty) {
                    return EmptyState(
                      icon: Icons.search_off,
                      title: l10n.noMatchingResults,
                      message: l10n.trysearchinvoice,
                    );
                  }

                  // ============= عرض القائمة =============
                  return ListView.builder(
                    padding: AppConstants.screenPadding,
                    itemCount: filteredInvoices.length,
                    itemBuilder: (context, index) {
                      return _buildInvoiceCard(
                        context,
                        filteredInvoices[index],
                        l10n,
                        isDark,
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ============= بطاقة الفاتورة =============
  /// Hint: نبني كل فاتورة في Card منفصل لسهولة القراءة والصيانة
  Widget _buildInvoiceCard(
    BuildContext context,
    Map<String, dynamic> invoice,
    AppLocalizations l10n,
    bool isDark,
  ) {
    // --- استخراج البيانات ---
    final invoiceId = invoice['InvoiceID'] as int;
    final totalAmount = invoice.getDecimal('TotalAmount');
    final invoiceDate = DateTime.parse(invoice['InvoiceDate'] as String);
    final isVoid = invoice['IsVoid'] == 1;
    final status = invoice['Status'] as String?;

    // --- تحديد الألوان والأنماط حسب الحالة ---
    final Color primaryColor = isVoid 
        ? AppColors.textHintLight 
        : (isDark ? AppColors.primaryDark : AppColors.primaryLight);
    
    final TextStyle titleStyle = TextStyle(
      fontWeight: FontWeight.bold,
      decoration: isVoid ? TextDecoration.lineThrough : null,
      color: isVoid 
          ? (isDark ? AppColors.textHintDark : AppColors.textHintLight)
          : null,
    );

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      onTap: isVoid ? null : () async {
        // Hint: ننتقل لشاشة التفاصيل وننتظر النتيجة
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => InvoiceDetailsScreen(invoiceId: invoiceId),
          ),
        );
        // Hint: إذا تم التعديل، نعيد تحميل القائمة
        if (result == true) _loadInvoices();
      },
      child: Column(
        children: [
          // ============= العنوان =============
          Row(
            children: [
              // --- أيقونة الفاتورة ---
              CircleAvatar(
                backgroundColor: primaryColor.withOpacity(0.1),
                child: Text(
                  '#$invoiceId',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    fontSize: 14,
                  ),
                ),
              ),
              
              const SizedBox(width: AppConstants.spacingMd),
              
              // --- رقم الفاتورة ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          l10n.invoiceNo(invoiceId.toString()),
                          style: titleStyle,
                        ),
                        
                        // --- شارة الحالة ---
                        if (status == l10n.edit && !isVoid) ...[
                          const SizedBox(width: AppConstants.spacingSm),
                           StatusBadge(
                            text: l10n.edit,
                            type: StatusType.warning,
                            small: true,
                          ),
                        ],
                        
                        if (isVoid) ...[
                          const SizedBox(width: AppConstants.spacingSm),
                           StatusBadge(
                            text: l10n.cancel,
                            type: StatusType.error,
                            small: true,
                          ),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: AppConstants.spacingXs),
                    
                    // --- التاريخ ---
                    Text(
                      DateFormat('yyyy-MM-dd – hh:mm a').format(invoiceDate),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              
              // --- المبلغ ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(totalAmount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isVoid 
                          ? (isDark ? AppColors.textHintDark : AppColors.textHintLight)
                          : AppColors.success,
                      decoration: isVoid ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  
                  // --- زر الحذف ---
                  if (!isVoid)
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                        size: 20,
                      ),
                      onPressed: () => _handleVoidInvoice(invoiceId, l10n),
                      tooltip: l10n.cancel,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}