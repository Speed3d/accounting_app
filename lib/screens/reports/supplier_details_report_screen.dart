// lib/screens/reports/supplier_details_report_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../utils/helpers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_state.dart';
import 'package:accounting_app/l10n/app_localizations.dart';

/// 📊 شاشة تفاصيل تقرير المورد
class SupplierDetailsReportScreen extends StatefulWidget {
  final int supplierId;
  final String supplierName;
  final String supplierType;
  final double totalProfit;
  final double totalWithdrawn;

  const SupplierDetailsReportScreen({
    super.key,
    required this.supplierId,
    required this.supplierName,
    required this.supplierType,
    required this.totalProfit,
    required this.totalWithdrawn,
  });

  @override
  State<SupplierDetailsReportScreen> createState() =>
      _SupplierDetailsReportScreenState();
}

class _SupplierDetailsReportScreenState
    extends State<SupplierDetailsReportScreen> {
  // المتغيرات
  final dbHelper = DatabaseHelper.instance;
  
  // ✅ التعديل 1: تغيير من late إلى nullable لتجنب crash
  Future<List<Partner>>? _partnersFuture;
  late Future<List<Map<String, dynamic>>> _withdrawalsFuture;
  late double _currentTotalWithdrawn;

  @override
  void initState() {
    super.initState();
    _currentTotalWithdrawn = widget.totalWithdrawn;
    _loadData();
  }

  /// تحميل بيانات الشركاء والمسحوبات
  void _loadData() {
    // ✅ التعديل 2: استبدال المقارنة المباشرة بدالة isPartnership()
    if (isPartnership(widget.supplierType)) {
      _partnersFuture = dbHelper.getPartnersForSupplier(widget.supplierId);
    }
    _withdrawalsFuture = dbHelper.getWithdrawalsForSupplier(widget.supplierId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final netProfit = widget.totalProfit - _currentTotalWithdrawn;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.supplierName),
        elevation: 0,
      ),

      body: ListView(
        padding: AppConstants.screenPadding,
        children: [
          // بطاقة الملخص المالي
          _buildFinancialSummarySection(netProfit, l10n),

          const SizedBox(height: AppConstants.spacingXl),

          // ✅ التعديل 3: استبدال المقارنة المباشرة بدالة isPartnership()
          if (isPartnership(widget.supplierType))
            _buildPartnersProfitSection(netProfit, l10n),

          // قسم سجل المسحوبات
          _buildWithdrawalsHistorySection(l10n),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRecordWithdrawalDialog(l10n),
        icon: const Icon(Icons.arrow_downward),
        label: Text(l10n.recordWithdrawal), // ✅ تم التدوين
        tooltip: l10n.recordGeneralWithdrawal, // ✅ تم التدوين
      ),
    );
  }

  /// قسم الملخص المالي
  Widget _buildFinancialSummarySection(double netProfit, AppLocalizations l10n) {
    return Column(
      children: [
        // بطاقة إجمالي الأرباح
        StatCard(
          label: l10n.totalProfitFromSupplier, // ✅ تم التدوين
          value: formatCurrency(widget.totalProfit),
          icon: Icons.trending_up,
          color: AppColors.info,
          subtitle: l10n.beforeWithdrawals, // ✅ تم التدوين
        ),

        const SizedBox(height: AppConstants.spacingMd),

        // بطاقة المسحوبات
        StatCard(
          label: l10n.totalWithdrawals, // ✅ تم التدوين
          value: formatCurrency(_currentTotalWithdrawn),
          icon: Icons.arrow_downward,
          color: AppColors.error,
          subtitle: l10n.withdrawnAmounts, // ✅ تم التدوين
        ),

        const Divider(height: 32),

        // بطاقة صافي الربح المتبقي
        CustomCard(
          color: netProfit >= 0
              ? AppColors.success.withOpacity(0.1)
              : AppColors.error.withOpacity(0.1),
          child: Padding(
            padding: AppConstants.paddingLg,
            child: Row(
              children: [
                // أيقونة
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
                    Icons.account_balance_wallet,
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
                        l10n.remainingNetProfit, // ✅ تم التدوين
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

  /// قسم توزيع الأرباح على الشركاء
  Widget _buildPartnersProfitSection(double netProfit, AppLocalizations l10n) {
    // ✅ التعديل 4: إضافة تحقق من null لتجنب crash
    if (_partnersFuture == null) return const SizedBox.shrink();
    
    return FutureBuilder<List<Partner>>(
      future: _partnersFuture,
      builder: (context, snapshot) {
        // إخفاء القسم إذا لم توجد بيانات
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final partners = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عنوان القسم
            Text(
              l10n.partnersProfitDistribution, // ✅ تم التدوين
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // قائمة الشركاء
            ...partners.map((partner) {
              final partnerShare = netProfit * (partner.sharePercentage / 100);

              return CustomCard(
                margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
                child: ListTile(
                  contentPadding: AppConstants.listTilePadding,
                  
                  // أيقونة الشريك
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryLight.withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      color: AppColors.primaryLight,
                    ),
                  ),

                  // اسم الشريك والنسبة
                  title: Text(
                    partner.partnerName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    // ✅ تم التدوين بشكل منفصل
                    '${l10n.sharePercentage}: ${partner.sharePercentage}% • '
                    '${l10n.partnerShare(formatCurrency(partnerShare))}',
                  ),

                  // زر السحب
                  trailing: ElevatedButton(
                    onPressed: () => _showRecordWithdrawalDialog(
                      l10n,
                      partnerName: partner.partnerName,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Text(l10n.withdraw), // ✅ تم التدوين
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: AppConstants.spacingXl),
          ],
        );
      },
    );
  }

  /// قسم سجل المسحوبات
  Widget _buildWithdrawalsHistorySection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان القسم
        Text(
          l10n.withdrawalsHistory, // ✅ تم التدوين
          style: Theme.of(context).textTheme.headlineSmall,
        ),

        const SizedBox(height: AppConstants.spacingMd),

        // قائمة المسحوبات
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _withdrawalsFuture,
          builder: (context, snapshot) {
            // حالة التحميل
            if (snapshot.connectionState == ConnectionState.waiting) {
              return LoadingState(message: l10n.loadingData); // ✅ تم التدوين
            }

            // حالة عدم وجود مسحوبات
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return EmptyState(
                icon: Icons.history,
                title: l10n.noWithdrawals, // ✅ تم التدوين
                message: l10n.noWithdrawalsRecorded, // ✅ تم التدوين
              );
            }

            // عرض قائمة المسحوبات
            final withdrawals = snapshot.data!;

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: withdrawals.length,
              itemBuilder: (context, index) {
                return _buildWithdrawalCard(withdrawals[index], l10n);
              },
            );
          },
        ),
      ],
    );
  }

  /// بطاقة السحب الواحد
  Widget _buildWithdrawalCard(
    Map<String, dynamic> withdrawal,
    AppLocalizations l10n,
  ) {
    final amount = withdrawal['WithdrawalAmount'] as double;
    final date = DateTime.parse(withdrawal['WithdrawalDate'] as String);
    final partnerName = withdrawal['PartnerName'] as String?;
    final notes = withdrawal['Notes'] as String?;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: Padding(
        padding: AppConstants.paddingMd,
        child: Row(
          children: [
            // أيقونة السحب
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: AppConstants.borderRadiusMd,
              ),
              child: Icon(
                Icons.arrow_downward,
                color: AppColors.error,
                size: 24,
              ),
            ),

            const SizedBox(width: AppConstants.spacingMd),

            // تفاصيل السحب
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // المستفيد
                  Text(
                    partnerName ?? widget.supplierName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingXs),

                  // التاريخ
                  Text(
                    DateFormat('yyyy-MM-dd').format(date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),

                  // الملاحظات (إن وجدت)
                  if (notes != null && notes.isNotEmpty) ...[
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      notes,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: AppConstants.spacingMd),

            // المبلغ
            Text(
              formatCurrency(amount),
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// نافذة تسجيل سحب جديد
  void _showRecordWithdrawalDialog(AppLocalizations l10n, {String? partnerName}) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    
    final netProfit = widget.totalProfit - _currentTotalWithdrawn;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        // عنوان النافذة
        title: Row(
          children: [
            const Icon(Icons.arrow_downward, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                // ✅ تم التدوين
                l10n.recordWithdrawalFor(partnerName ?? widget.supplierName),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),

        // محتوى النموذج
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // عرض صافي الربح المتاح
                Container(
                  padding: AppConstants.paddingMd,
                  decoration: BoxDecoration(
                    color: netProfit >= 0
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: AppConstants.borderRadiusMd,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: netProfit >= 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              // ✅ تم التدوين
                              l10n.availableNetProfit(formatCurrency(netProfit)),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              formatCurrency(netProfit),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
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

                const SizedBox(height: AppConstants.spacingMd),

                // حقل المبلغ المسحوب
                CustomTextField(
                  controller: amountController,
                  label: l10n.withdrawnAmount, // ✅ تم التدوين
                  hint: '0.00',
                  prefixIcon: Icons.attach_money,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.amountRequired; // ✅ تم التدوين
                    }

                    final convertedValue = convertArabicNumbersToEnglish(value);
                    final amount = double.tryParse(convertedValue);

                    if (amount == null || amount <= 0) {
                      return l10n.enterValidAmount; // ✅ تم التدوين
                    }

                    if (amount > netProfit) {
                      return l10n.amountExceedsProfit; // ✅ تم التدوين
                    }

                    return null;
                  },
                ),

                const SizedBox(height: AppConstants.spacingMd),

                // حقل الملاحظات
                CustomTextField(
                  controller: notesController,
                  label: l10n.notesOptional, // ✅ تم التدوين
                  hint: l10n.enterNotes, // ✅ تم التدوين
                  prefixIcon: Icons.note_outlined,
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),

        // أزرار الإجراءات
        actions: [
          // زر الإلغاء
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel), // ✅ تم التدوين
          ),

          // زر الحفظ
          ElevatedButton.icon(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              try {
                // تحضير البيانات
                final withdrawalData = {
                  'SupplierID': widget.supplierId,
                  'PartnerName': partnerName,
                  'WithdrawalAmount': double.parse(
                    convertArabicNumbersToEnglish(amountController.text),
                  ),
                  'WithdrawalDate': DateTime.now().toIso8601String(),
                  'Notes': notesController.text.trim(),
                };

                // حفظ السحب
                await dbHelper.recordProfitWithdrawal(withdrawalData);

                if (!ctx.mounted) return;

                Navigator.pop(ctx);

                // رسالة نجاح
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.withdrawalSuccess), // ✅ تم التدوين
                    backgroundColor: AppColors.success,
                  ),
                );

                // تحديث الإحصائيات
                setState(() {
                  _currentTotalWithdrawn += withdrawalData['WithdrawalAmount'] as double;
                  _loadData();
                });
              } catch (e) {
                if (!ctx.mounted) return;

                Navigator.pop(ctx);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.errorOccurred(e.toString())), // ✅ تم التدوين
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            icon: const Icon(Icons.save),
            label: Text(l10n.save), // ✅ تم التدوين
          ),
        ],
      ),
    );
  }
}