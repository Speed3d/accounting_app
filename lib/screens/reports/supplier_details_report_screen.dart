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

/// 📊 شاشة تفاصيل تقرير المورد
/// ---------------------------
/// صفحة فرعية تعرض:
/// 1. ملخص مالي للمورد (الأرباح، المسحوبات، الصافي)
/// 2. توزيع الأرباح على الشركاء (للشراكات)
/// 3. سجل جميع المسحوبات
/// 4. إمكانية تسجيل سحب جديد
class SupplierDetailsReportScreen extends StatefulWidget {
  final int supplierId;
  final String supplierName;
  final String supplierType; // "فردي" أو "شراكة"
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
  // ============= المتغيرات =============
  final dbHelper = DatabaseHelper.instance;
  late Future<List<Partner>> _partnersFuture;
  late Future<List<Map<String, dynamic>>> _withdrawalsFuture;
  late double _currentTotalWithdrawn; // المبلغ المسحوب الحالي

  // ============= التهيئة =============
  @override
  void initState() {
    super.initState();
    _currentTotalWithdrawn = widget.totalWithdrawn;
    _loadData();
  }

  /// تحميل بيانات الشركاء والمسحوبات
  void _loadData() {
    // جلب الشركاء فقط إذا كان النوع "شراكة"
    if (widget.supplierType == 'شراكة') {
      _partnersFuture = dbHelper.getPartnersForSupplier(widget.supplierId);
    }
    // جلب سجل المسحوبات
    _withdrawalsFuture = dbHelper.getWithdrawalsForSupplier(widget.supplierId);
  }

  // ============= البناء الرئيسي =============
  @override
  Widget build(BuildContext context) {
    // حساب صافي الربح المتبقي
    final netProfit = widget.totalProfit - _currentTotalWithdrawn;

    return Scaffold(
      // --- AppBar مع اسم المورد ---
      appBar: AppBar(
        title: Text(widget.supplierName),
        elevation: 0,
      ),

      // --- الجسم: الملخص + الشركاء + السجل ---
      body: ListView(
        padding: AppConstants.screenPadding,
        children: [
          // 💰 بطاقة الملخص المالي
          _buildFinancialSummarySection(netProfit),

          const SizedBox(height: AppConstants.spacingXl),

          // 👥 قسم توزيع الأرباح على الشركاء (للشراكات فقط)
          if (widget.supplierType == 'شراكة')
            _buildPartnersProfitSection(netProfit),

          // 📋 قسم سجل المسحوبات
          _buildWithdrawalsHistorySection(),
        ],
      ),

      // --- زر تسجيل سحب جديد ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRecordWithdrawalDialog(),
        icon: const Icon(Icons.arrow_downward),
        label: const Text('تسجيل سحب'),
        tooltip: 'تسجيل سحب عام',
      ),
    );
  }

  // ============= قسم الملخص المالي =============
  /// يعرض 3 معلومات مالية:
  /// 1. إجمالي الأرباح من المورد
  /// 2. إجمالي المسحوبات
  /// 3. صافي الربح المتبقي
  Widget _buildFinancialSummarySection(double netProfit) {
    return Column(
      children: [
        // --- بطاقة إجمالي الأرباح ---
        StatCard(
          label: 'إجمالي الأرباح من المورد',
          value: formatCurrency(widget.totalProfit),
          icon: Icons.trending_up,
          color: AppColors.info,
          subtitle: 'قبل المسحوبات',
          // iconSize: 22,
        ),

        const SizedBox(height: AppConstants.spacingMd),

        // --- بطاقة المسحوبات ---
        StatCard(
          label: 'إجمالي المسحوبات',
          value: formatCurrency(_currentTotalWithdrawn),
          icon: Icons.arrow_downward,
          color: AppColors.error,
          subtitle: 'المبالغ المسحوبة',
          // iconSize: 22,
        ),

        const Divider(height: 32),

        // --- بطاقة صافي الربح المتبقي ---
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
                        'صافي الربح المتبقي',
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

  // ============= قسم توزيع الأرباح على الشركاء =============
  /// يعرض قائمة الشركاء مع نصيب كل شريك من الأرباح
  /// مع زر لتسجيل سحب لكل شريك
  Widget _buildPartnersProfitSection(double netProfit) {
    return FutureBuilder<List<Partner>>(
      future: _partnersFuture,
      builder: (context, snapshot) {
        // إخفاء القسم إذا لم توجد بيانات
        if (!snapshot.hasData) return const SizedBox.shrink();

        final partners = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عنوان القسم
            Text(
              'توزيع الأرباح على الشركاء',
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // قائمة الشركاء
            ...partners.map((partner) {
              // حساب نصيب الشريك
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
                    'النسبة: ${partner.sharePercentage}% • '
                    'النصيب: ${formatCurrency(partnerShare)}',
                  ),

                  // زر السحب
                  trailing: ElevatedButton(
                    onPressed: () => _showRecordWithdrawalDialog(
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
                    child: const Text('سحب'),
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

  // ============= قسم سجل المسحوبات =============
  /// يعرض جميع عمليات السحب السابقة
  Widget _buildWithdrawalsHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان القسم
        Text(
          'سجل المسحوبات',
          style: Theme.of(context).textTheme.headlineSmall,
        ),

        const SizedBox(height: AppConstants.spacingMd),

        // قائمة المسحوبات
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _withdrawalsFuture,
          builder: (context, snapshot) {
            // --- حالة التحميل ---
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingState(message: 'جاري تحميل السجل...');
            }

            // --- حالة عدم وجود مسحوبات ---
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const EmptyState(
                icon: Icons.history,
                title: 'لا توجد مسحوبات',
                message: 'لم يتم تسجيل أي عملية سحب حتى الآن',
              );
            }

            // --- عرض قائمة المسحوبات ---
            final withdrawals = snapshot.data!;

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: withdrawals.length,
              itemBuilder: (context, index) {
                final withdrawal = withdrawals[index];
                return _buildWithdrawalCard(withdrawal);
              },
            );
          },
        ),
      ],
    );
  }

  // ============= بطاقة السحب الواحد =============
  /// يعرض تفاصيل عملية سحب واحدة
  Widget _buildWithdrawalCard(Map<String, dynamic> withdrawal) {
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
            // --- أيقونة السحب ---
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

            // --- تفاصيل السحب ---
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

            // --- المبلغ ---
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

  // ============= نافذة تسجيل سحب جديد =============
  /// نافذة حوار لتسجيل عملية سحب جديدة
  void _showRecordWithdrawalDialog({String? partnerName}) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    
    // حساب صافي الربح المتاح
    final netProfit = widget.totalProfit - _currentTotalWithdrawn;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        // --- عنوان النافذة ---
        title: Row(
          children: [
            const Icon(Icons.arrow_downward, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'سحب أرباح ${partnerName ?? widget.supplierName}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),

        // --- محتوى النموذج ---
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- عرض صافي الربح المتاح ---
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
                              'الربح الصافي المتاح:',
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

                // --- حقل المبلغ المسحوب ---
                CustomTextField(
                  controller: amountController,
                  label: 'المبلغ المسحوب',
                  hint: '0.00',
                  prefixIcon: Icons.attach_money,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'المبلغ مطلوب';
                    }

                    final convertedValue = convertArabicNumbersToEnglish(value);
                    final amount = double.tryParse(convertedValue);

                    if (amount == null || amount <= 0) {
                      return 'أدخل مبلغاً صحيحاً';
                    }

                    if (amount > netProfit) {
                      return 'المبلغ يتجاوز الربح المتاح';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: AppConstants.spacingMd),

                // --- حقل الملاحظات (اختياري) ---
                CustomTextField(
                  controller: notesController,
                  label: 'ملاحظات (اختياري)',
                  hint: 'أضف ملاحظة...',
                  prefixIcon: Icons.note_outlined,
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),

        // --- أزرار الإجراءات ---
        actions: [
          // زر الإلغاء
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),

          // زر الحفظ
          ElevatedButton.icon(
            onPressed: () async {
              // --- التحقق من صحة البيانات ---
              if (!formKey.currentState!.validate()) return;

              try {
                // --- تحضير البيانات ---
                final withdrawalData = {
                  'SupplierID': widget.supplierId,
                  'PartnerName': partnerName,
                  'WithdrawalAmount': double.parse(
                    convertArabicNumbersToEnglish(amountController.text),
                  ),
                  'WithdrawalDate': DateTime.now().toIso8601String(),
                  'Notes': notesController.text.trim(),
                };

                // --- حفظ السحب ---
                await dbHelper.recordProfitWithdrawal(withdrawalData);

                if (!ctx.mounted) return;

                // إغلاق النافذة
                Navigator.pop(ctx);

                // رسالة نجاح
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم تسجيل السحب بنجاح'),
                    backgroundColor: AppColors.success,
                  ),
                );

                // تحديث الإحصائيات
                setState(() {
                  _currentTotalWithdrawn += withdrawalData['WithdrawalAmount'] as double;
                  _loadData();
                });
              } catch (e) {
                // --- معالجة الخطأ ---
                if (!ctx.mounted) return;

                Navigator.pop(ctx);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('حدث خطأ: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}