// lib/screens/reports/supplier_details_report_screen.dart

import 'dart:io';
import 'package:accountant_touch/services/pdf_service.dart' show PdfService;
import 'package:accountant_touch/utils/decimal_extensions.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../utils/helpers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../utils/pdf_helpers.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_state.dart';
import 'package:accountant_touch/l10n/app_localizations.dart';

/// 📊 شاشة تفاصيل تقرير المورد
/// ============================================================================
/// الوظيفة: عرض تفاصيل أرباح المورد مع إمكانية السحب
/// ============================================================================
class SupplierDetailsReportScreen extends StatefulWidget {
  final int supplierId;
  final String supplierName;
  final String supplierType;
  final Decimal totalProfit;
  final Decimal totalWithdrawn;

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
  // ============================================================================
  // 📌 المتغيرات الأساسية
  // ============================================================================
  final dbHelper = DatabaseHelper.instance;
  
  Future<List<Partner>>? _partnersFuture;
  Future<List<Map<String, dynamic>>>? _withdrawalsFuture;
  late Decimal _currentTotalWithdrawn;
  
  bool _isLoading = true;
  bool _isGeneratingPdf = false; // ✅ متغير حالة PDF

  // ============================================================================
  // 🔄 دورة حياة الصفحة
  // ============================================================================
  @override
  void initState() {
    super.initState();
    _currentTotalWithdrawn = widget.totalWithdrawn;
    _loadData();
  }

  /// تحميل البيانات من قاعدة البيانات
  void _loadData() {
    setState(() {
      _isLoading = true;
      _partnersFuture = dbHelper.getPartnersForSupplier(widget.supplierId);
      _withdrawalsFuture = dbHelper.getWithdrawalsForSupplier(widget.supplierId);
    });

    Future.wait([
      _partnersFuture!,
      _withdrawalsFuture!,
    ]).then((_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }).catchError((e) {
      debugPrint('❌ خطأ في تحميل البيانات: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  // ============================================================================
  // 🎨 بناء الواجهة الرئيسية
  // ============================================================================
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final netProfit = Decimal.parse((widget.totalProfit - _currentTotalWithdrawn).toDouble().toString());

    return Scaffold(
      // ============================================================================
      // 📱 شريط العنوان
      // ============================================================================
      appBar: AppBar(
        title: Text(widget.supplierName),
        elevation: 0,
        actions: [
          // زر التحديث
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadData,
            tooltip: 'تحديث',
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
      // 📄 محتوى الصفحة
      // ============================================================================
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: ListView(
          padding: AppConstants.screenPadding,
          children: [
            // 💰 قسم الملخص المالي
            _buildFinancialSummarySection(netProfit, l10n),

            const SizedBox(height: AppConstants.spacingXl),

            // 👥 قسم الشركاء (للشراكات فقط)
            if (isPartnership(widget.supplierType))
              _buildPartnersProfitSection(netProfit, l10n),

            // 📋 قسم سجل المسحوبات
            _buildWithdrawalsHistorySection(l10n),
          ],
        ),
      ),

      // ============================================================================
      // 🎯 زر السحب العائم
      // ============================================================================
      // Hint: للموردين الفرديين (بدون شركاء)، نمرر sharePercentage = null
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRecordWithdrawalDialog(
          l10n,
          partnerName: null, // للمورد نفسه
          sharePercentage: null, // null = مورد فردي (100%)
        ),
        icon: const Icon(Icons.arrow_downward),
        label: Text(l10n.recordWithdrawal),
        backgroundColor: AppColors.primaryLight,
      ),
    );
  }

  // ============================================================================
  // 💰 بناء قسم الملخص المالي
  // ============================================================================
  Widget _buildFinancialSummarySection(Decimal netProfit, AppLocalizations l10n) {
    return Column(
      children: [
        // --- بطاقة إجمالي الأرباح ---
        StatCard(
          label: l10n.totalProfitFromSupplier,
          value: formatCurrency(widget.totalProfit),
          icon: Icons.trending_up,
          color: AppColors.info,
          subtitle: l10n.beforeWithdrawals,
        ),

        const SizedBox(height: AppConstants.spacingMd),

        // --- بطاقة المسحوبات ---
        StatCard(
          label: l10n.totalWithdrawals,
          value: formatCurrency(_currentTotalWithdrawn),
          icon: Icons.arrow_downward,
          color: AppColors.error,
          subtitle: l10n.withdrawnAmounts,
        ),

        const Divider(height: 20, thickness: 1),

        // --- بطاقة صافي الربح ---
        CustomCard(
          color: netProfit >= Decimal.zero
              ? AppColors.success.withOpacity(0.1)
              : AppColors.error.withOpacity(0.1),
          child: Padding(
            padding: AppConstants.paddingLg,
            child: Row(
              children: [
                // أيقونة
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: netProfit >= Decimal.zero
                        ? AppColors.success.withOpacity(0.2)
                        : AppColors.error.withOpacity(0.2),
                    borderRadius: AppConstants.borderRadiusLg,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: netProfit >= Decimal.zero ? AppColors.success : AppColors.error,
                    size: 22,
                  ),
                ),

                const SizedBox(width: AppConstants.spacingMd),

                // النص والمبلغ
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.remainingNetProfit,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppConstants.spacingXs),
                      Text(
                        formatCurrency(netProfit),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: netProfit >= Decimal.zero ? AppColors.success : AppColors.error,
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
  // 👥 بناء قسم توزيع الأرباح على الشركاء
  // ============================================================================
  Widget _buildPartnersProfitSection(Decimal netProfit, AppLocalizations l10n) {
    debugPrint('🔍 [Partners Section] netProfit type: ${netProfit.runtimeType}, value: $netProfit');

    if (_partnersFuture == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<Partner>>(
      future: _partnersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return CustomCard(
            color: AppColors.error.withOpacity(0.1),
            margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
            child: Padding(
              padding: AppConstants.paddingMd,
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 40),
                  const SizedBox(width: AppConstants.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '❌ حدث خطأ في تحميل الشركاء',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          snapshot.error.toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 120,
                          child: ElevatedButton.icon(
                            onPressed: _loadData,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('إعادة المحاولة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final partners = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- عنوان القسم ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n.partnersProfitDistribution,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: AppConstants.borderRadiusFull,
                    border: Border.all(color: AppColors.info.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people, size: 20, color: AppColors.info),
                      const SizedBox(width: 4),
                      Text(
                        '${partners.length}',
                        style: const TextStyle(
                          color: AppColors.info,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // --- قائمة الشركاء ---
            ...partners.map((partner) {
            try {
              final shareDecimal = Decimal.parse(partner.sharePercentage.toString());
              debugPrint('🔍 [Partner: ${partner.partnerName}] shareDecimal: $shareDecimal (type: ${shareDecimal.runtimeType})');

              // Hint: نحسب نصيب الشريك من الربح الأصلي (قبل أي مسحوبات)
              final partnerShare = Decimal.parse((widget.totalProfit * shareDecimal / Decimal.fromInt(100)).toDouble().toString());
              debugPrint('🔍 [Partner: ${partner.partnerName}] partnerShare: $partnerShare (type: ${partnerShare.runtimeType})');

              return _buildPartnerCard(partner, partnerShare, l10n);
            } catch (e, stackTrace) {
              debugPrint('❌ [ERROR] في حساب نصيب الشريك ${partner.partnerName}: $e');
              debugPrint('❌ Stack Trace: $stackTrace');
              rethrow;
            }
            }).toList(),

            const SizedBox(height: AppConstants.spacingXl),
          ],
        );
      },
    );
  }

  // ============================================================================
  // 🧑 بناء بطاقة الشريك الواحد
  // ============================================================================
  // Hint: تم تحديث هذه الدالة لعرض رصيد الشريك المتاح بدقة
  // ← partnerShare: نصيب الشريك من صافي الربح الإجمالي
  Widget _buildPartnerCard(Partner partner, Decimal partnerShare, AppLocalizations l10n) {
    debugPrint('🔍 [Build Card] Partner: ${partner.partnerName}, partnerShare: $partnerShare (type: ${partnerShare.runtimeType})');

    ImageProvider? avatarImage;
    try {
      if (partner.imagePath != null && partner.imagePath!.isNotEmpty) {
        final imageFile = File(partner.imagePath!);
        if (imageFile.existsSync()) {
          avatarImage = FileImage(imageFile);
        }
      }
    } catch (e) {
      debugPrint('⚠️ خطأ في تحميل صورة الشريك: $e');
      avatarImage = null;
    }

    // Hint: نحسب الرصيد المتاح للشريك بشكل ديناميكي
    return FutureBuilder<Decimal>(
      future: dbHelper.getTotalWithdrawnForPartner(widget.supplierId, partner.partnerName),
      builder: (context, snapshot) {
        try {
          final partnerWithdrawn = snapshot.data ?? Decimal.zero;
          debugPrint('🔍 [Balance Calc] Partner: ${partner.partnerName}, withdrawn: $partnerWithdrawn');

          final availableBalance = Decimal.parse((partnerShare - partnerWithdrawn).toDouble().toString());
          debugPrint('🔍 [Balance Calc] Partner: ${partner.partnerName}, availableBalance: $availableBalance (type: ${availableBalance.runtimeType})');

        return CustomCard(
          margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
          child: Padding(
            padding: AppConstants.paddingMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // --- صورة الشريك ---
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primaryLight.withOpacity(0.1),
                      backgroundImage: avatarImage,
                      child: avatarImage == null
                          ? Icon(
                              Icons.person,
                              color: AppColors.primaryLight,
                              size: 22,
                            )
                          : null,
                    ),

                    const SizedBox(width: AppConstants.spacingMd),

                    // --- معلومات الشريك ---
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            partner.partnerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: AppConstants.borderRadiusSm,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.percent, size: 10, color: AppColors.success),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${partner.sharePercentage}',
                                      style: const TextStyle(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'النصيب: ${formatCurrency(partnerShare)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // --- زر السحب ---
                    SizedBox(
                      width: 75,
                      child: ElevatedButton.icon(
                        onPressed: availableBalance > Decimal.zero
                            ? () => _showRecordWithdrawalDialog(
                                  l10n,
                                  partnerName: partner.partnerName,
                                  sharePercentage: partner.sharePercentage,
                                )
                            : null,
                        icon: const Icon(Icons.arrow_downward, size: 11),
                        label: Text(l10n.withdraw),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryLight,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 0.5, vertical: 4),
                        ),
                      ),
                    ),
                  ],
                ),

                // Hint: عرض تفاصيل الرصيد في صف منفصل
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: availableBalance >= Decimal.zero
                        ? AppColors.info.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: AppConstants.borderRadiusSm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.money_off,
                            size: 14,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'المسحوب: ${formatCurrency(partnerWithdrawn)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            size: 14,
                            color: availableBalance >= Decimal.zero ? AppColors.success : AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'المتبقي: ${formatCurrency(availableBalance)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: availableBalance >= Decimal.zero ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        } catch (e, stackTrace) {
          debugPrint('❌ [ERROR] في بناء بطاقة الشريك ${partner.partnerName}: $e');
          debugPrint('❌ Stack Trace: $stackTrace');
          return CustomCard(
            margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
            child: Padding(
              padding: AppConstants.paddingMd,
              child: Text('❌ خطأ في عرض بيانات الشريك: $e', style: const TextStyle(color: AppColors.error)),
            ),
          );
        }
      },
    );
  }

  // ============================================================================
  // 📋 بناء قسم سجل المسحوبات
  // ============================================================================
  Widget _buildWithdrawalsHistorySection(AppLocalizations l10n) {
    if (_withdrawalsFuture == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.withdrawalsHistory,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppConstants.spacingMd),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _withdrawalsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return LoadingState(message: l10n.loadingData);
            }

            if (snapshot.hasError) {
              return ErrorState(
                message: snapshot.error.toString(),
                onRetry: _loadData,
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return EmptyState(
                icon: Icons.history,
                title: l10n.noWithdrawals,
                message: l10n.noWithdrawalsRecorded,
              );
            }

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

  // ============================================================================
  // 📄 بناء بطاقة المسحوب الواحد
  // ============================================================================
  // Hint: تم إضافة أزرار تعديل وحذف لكل سحب مع معالجة شاملة للأخطاء
  Widget _buildWithdrawalCard(Map<String, dynamic> withdrawal, AppLocalizations l10n) {
    final withdrawalId = withdrawal['WithdrawalID'] as int;
    final amount = withdrawal.getDecimal('WithdrawalAmount');
    final date = DateTime.parse(withdrawal['WithdrawalDate'] as String);
    final partnerName = withdrawal['PartnerName'] as String?;
    final notes = withdrawal['Notes'] as String?;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: Padding(
        padding: AppConstants.paddingMd,
        child: Column(
          children: [
            Row(
              children: [
                // أيقونة
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: AppConstants.borderRadiusMd,
                  ),
                  child: Icon(Icons.arrow_downward, color: AppColors.error, size: 24),
                ),

                const SizedBox(width: AppConstants.spacingMd),

                // التفاصيل
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partnerName ?? widget.supplierName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const SizedBox(height: AppConstants.spacingXs),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('yyyy-MM-dd').format(date),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      if (notes != null && notes.isNotEmpty) ...[
                        const SizedBox(height: AppConstants.spacingXs),
                        Row(
                          children: [
                            Icon(Icons.note, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                notes,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontStyle: FontStyle.italic,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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

            // Hint: أزرار التعديل والحذف (جديد!)
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // زر التعديل
                OutlinedButton.icon(
                  onPressed: () => _showEditWithdrawalDialog(
                    l10n,
                    withdrawal: withdrawal,
                  ),
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('تعديل'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.info,
                    side: BorderSide(color: AppColors.info.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: const Size(80, 32),
                  ),
                ),
                const SizedBox(width: 8),
                // زر الحذف
                OutlinedButton.icon(
                  onPressed: () => _showDeleteWithdrawalConfirmation(
                    l10n,
                    withdrawalId: withdrawalId,
                    amount: amount,
                    partnerName: partnerName,
                  ),
                  icon: const Icon(Icons.delete, size: 14),
                  label: const Text('حذف'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: const Size(80, 32),
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
  // 💬 نافذة تسجيل سحب جديد
  // ============================================================================
  // Hint: تم تحديث هذه الدالة لإضافة:
  // ← Date Picker لاختيار تاريخ السحب
  // ← Validation محسّن يتحقق من رصيد الشريك المحدد
  // ← sharePercentage لحساب الرصيد المتاح للشريك
  void _showRecordWithdrawalDialog(
    AppLocalizations l10n, {
    String? partnerName,
    Decimal? sharePercentage, // null للموردين الفرديين، قيمة للشركاء
  }) async {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    // Hint: التاريخ المختار (افتراضياً اليوم)
    DateTime selectedDate = DateTime.now();

    // Hint: حساب الرصيد المتاح للشريك/المورد المحدد
    final netProfit = Decimal.parse((widget.totalProfit - _currentTotalWithdrawn).toDouble().toString());
    debugPrint('🔍 [Withdrawal Dialog] netProfit: $netProfit (type: ${netProfit.runtimeType})');
    debugPrint('🔍 [Withdrawal Dialog] partnerName: $partnerName, sharePercentage: $sharePercentage');

    // Hint: إذا كان شريك، نحسب رصيده المحدد، وإلا نستخدم صافي الربح الإجمالي
    Decimal availableBalance;
    if (sharePercentage != null && partnerName != null) {
      // للشركاء: حساب الرصيد المتاح الخاص بالشريك من الربح الأصلي
      final partnerTotalShare = Decimal.parse((widget.totalProfit * sharePercentage / Decimal.fromInt(100)).toDouble().toString());
      final partnerWithdrawn = await dbHelper.getTotalWithdrawnForPartner(
        widget.supplierId,
        partnerName,
      );
      availableBalance = Decimal.parse((partnerTotalShare - partnerWithdrawn).toDouble().toString());
      debugPrint('🔍 [Partner Withdrawal] partnerTotalShare: $partnerTotalShare, withdrawn: $partnerWithdrawn, available: $availableBalance');
    } else {
      // للموردين الفرديين: الرصيد المتاح هو صافي الربح الإجمالي مطروحاً منه مسحوبات المورد
      final supplierWithdrawn = await dbHelper.getTotalWithdrawnForPartner(
        widget.supplierId,
        null, // null = مورد فردي
      );
      availableBalance = Decimal.parse((netProfit - supplierWithdrawn).toDouble().toString());
      debugPrint('🔍 [Individual Supplier] netProfit: $netProfit, withdrawn: $supplierWithdrawn, available: $availableBalance (type: ${availableBalance.runtimeType})');
    }

    debugPrint('✅ [Final] availableBalance: $availableBalance (type: ${availableBalance.runtimeType})');

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.arrow_downward, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.recordWithdrawalFor(partnerName ?? widget.supplierName),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hint: عرض الرصيد المتاح للسحب
                  Container(
                    padding: AppConstants.paddingMd,
                    decoration: BoxDecoration(
                      color: availableBalance >= Decimal.zero
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.error.withOpacity(0.1),
                      borderRadius: AppConstants.borderRadiusMd,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: availableBalance >= Decimal.zero ? AppColors.success : AppColors.error,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'الرصيد المتاح للسحب',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                formatCurrency(availableBalance),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: availableBalance >= Decimal.zero ? AppColors.success : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingMd),

                  // Hint: حقل المبلغ مع validation محسّن
                  CustomTextField(
                    controller: amountController,
                    label: l10n.withdrawnAmount,
                    hint: '0.00',
                    prefixIcon: Icons.attach_money,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.amountRequired;
                      }

                      final convertedValue = convertArabicNumbersToEnglish(value);
                      try {
                        final amount = parseDecimal(convertedValue);

                        if (amount <= Decimal.zero) {
                          return l10n.enterValidAmount;
                        }

                        // Hint: التحقق من أن المبلغ لا يتجاوز الرصيد المتاح للشريك/المورد المحدد
                        if (amount > availableBalance) {
                          return 'المبلغ يتجاوز الرصيد المتاح (${formatCurrency(availableBalance)})';
                        }
                      } catch (e) {
                        return l10n.enterValidAmount;
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: AppConstants.spacingMd),

                  // Hint: Date Picker لاختيار تاريخ السحب (جديد!)
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        helpText: 'اختر تاريخ السحب',
                        cancelText: 'إلغاء',
                        confirmText: 'تأكيد',
                      );

                      if (pickedDate != null) {
                        setDialogState(() {
                          selectedDate = pickedDate;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: AppConstants.borderRadiusMd,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: AppColors.primaryLight),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تاريخ السحب',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('yyyy-MM-dd').format(selectedDate),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingMd),

                  // حقل الملاحظات
                  CustomTextField(
                    controller: notesController,
                    label: l10n.notesOptional,
                    hint: l10n.enterNotes,
                    prefixIcon: Icons.note_outlined,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                try {
                  final withdrawalAmount = parseDecimal(
                    convertArabicNumbersToEnglish(amountController.text),
                  );

                  final withdrawalData = {
                    'SupplierID': widget.supplierId,
                    'PartnerName': partnerName,
                    'WithdrawalAmount': withdrawalAmount.toDouble(),
                    'WithdrawalDate': selectedDate.toIso8601String(), // Hint: استخدام التاريخ المختار
                    'Notes': notesController.text.trim(),
                  };

                  await dbHelper.recordProfitWithdrawal(withdrawalData);

                  if (!ctx.mounted) return;

                  Navigator.pop(ctx);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.withdrawalSuccess),
                      backgroundColor: AppColors.success,
                    ),
                  );

                  setState(() {
                    _currentTotalWithdrawn = Decimal.parse((_currentTotalWithdrawn + withdrawalAmount).toDouble().toString());
                    _loadData();
                  });
                } catch (e) {
                  if (!ctx.mounted) return;

                  Navigator.pop(ctx);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.errorOccurred(e.toString())),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save),
              label: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // ✏️ نافذة تعديل سحب موجود
  // ============================================================================
  // Hint: نافذة مشابهة لنافذة السحب لكن مع تعبئة البيانات الحالية
  void _showEditWithdrawalDialog(
    AppLocalizations l10n, {
    required Map<String, dynamic> withdrawal,
  }) async {
    final withdrawalId = withdrawal['WithdrawalID'] as int;
    final currentAmount = withdrawal.getDecimal('WithdrawalAmount');
    final currentDate = DateTime.parse(withdrawal['WithdrawalDate'] as String);
    final partnerName = withdrawal['PartnerName'] as String?;
    final currentNotes = withdrawal['Notes'] as String?;

    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController(text: currentAmount.toString());
    final notesController = TextEditingController(text: currentNotes ?? '');
    DateTime selectedDate = currentDate;

    // Hint: حساب الرصيد المتاح مع الأخذ بعين الاعتبار المبلغ الحالي
    final netProfit = Decimal.parse((widget.totalProfit - _currentTotalWithdrawn).toDouble().toString());

    // Hint: نحتاج لمعرفة نسبة الشريك لحساب رصيده
    Decimal? sharePercentage;
    if (partnerName != null) {
      final partners = await dbHelper.getPartnersForSupplier(widget.supplierId);
      final partner = partners.firstWhere(
        (p) => p.partnerName == partnerName,
        orElse: () => Partner(
          partnerName: partnerName,
          sharePercentage: Decimal.fromInt(100),
        ),
      );
      sharePercentage = partner.sharePercentage;
    }

    Decimal availableBalance;
    if (sharePercentage != null && partnerName != null) {
      // Hint: نحسب نصيب الشريك من الربح الأصلي (قبل أي مسحوبات)
      final partnerTotalShare = Decimal.parse((widget.totalProfit * sharePercentage / Decimal.fromInt(100)).toDouble().toString());
      final partnerWithdrawn = await dbHelper.getTotalWithdrawnForPartner(
        widget.supplierId,
        partnerName,
      );
      // Hint: نضيف المبلغ الحالي للرصيد المتاح (لأننا سنستبدله)
      availableBalance = Decimal.parse((partnerTotalShare - partnerWithdrawn + currentAmount).toDouble().toString());
    } else {
      final supplierWithdrawn = await dbHelper.getTotalWithdrawnForPartner(
        widget.supplierId,
        null,
      );
      availableBalance = Decimal.parse((netProfit - supplierWithdrawn + currentAmount).toDouble().toString());
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.edit, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'تعديل السحب',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // عرض الرصيد المتاح
                  Container(
                    padding: AppConstants.paddingMd,
                    decoration: BoxDecoration(
                      color: availableBalance >= Decimal.zero
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.error.withOpacity(0.1),
                      borderRadius: AppConstants.borderRadiusMd,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: availableBalance >= Decimal.zero ? AppColors.success : AppColors.error,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'الرصيد المتاح للسحب',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                formatCurrency(availableBalance),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: availableBalance >= Decimal.zero ? AppColors.success : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingMd),

                  // حقل المبلغ
                  CustomTextField(
                    controller: amountController,
                    label: l10n.withdrawnAmount,
                    hint: '0.00',
                    prefixIcon: Icons.attach_money,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.amountRequired;
                      }

                      final convertedValue = convertArabicNumbersToEnglish(value);
                      try {
                        final amount = parseDecimal(convertedValue);

                        if (amount <= Decimal.zero) {
                          return l10n.enterValidAmount;
                        }

                        if (amount > availableBalance) {
                          return 'المبلغ يتجاوز الرصيد المتاح (${formatCurrency(availableBalance)})';
                        }
                      } catch (e) {
                        return l10n.enterValidAmount;
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: AppConstants.spacingMd),

                  // Date Picker
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        helpText: 'اختر تاريخ السحب',
                        cancelText: 'إلغاء',
                        confirmText: 'تأكيد',
                      );

                      if (pickedDate != null) {
                        setDialogState(() {
                          selectedDate = pickedDate;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: AppConstants.borderRadiusMd,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: AppColors.primaryLight),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تاريخ السحب',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('yyyy-MM-dd').format(selectedDate),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingMd),

                  // حقل الملاحظات
                  CustomTextField(
                    controller: notesController,
                    label: l10n.notesOptional,
                    hint: l10n.enterNotes,
                    prefixIcon: Icons.note_outlined,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                try {
                  final newAmount = parseDecimal(
                    convertArabicNumbersToEnglish(amountController.text),
                  );

                  final updatedData = {
                    'WithdrawalAmount': newAmount.toDouble(),
                    'WithdrawalDate': selectedDate.toIso8601String(),
                    'Notes': notesController.text.trim(),
                  };

                  await dbHelper.updateProfitWithdrawal(withdrawalId, updatedData);

                  if (!ctx.mounted) return;

                  Navigator.pop(ctx);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ تم تعديل السحب بنجاح'),
                      backgroundColor: AppColors.success,
                    ),
                  );

                  // Hint: إعادة حساب المسحوب الكلي بعد التعديل
                  setState(() {
                    _currentTotalWithdrawn = Decimal.parse((_currentTotalWithdrawn - currentAmount + newAmount).toDouble().toString());
                    _loadData();
                  });
                } catch (e) {
                  if (!ctx.mounted) return;

                  Navigator.pop(ctx);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ خطأ في تعديل السحب: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('حفظ التعديلات'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // 🗑️ نافذة تأكيد حذف السحب
  // ============================================================================
  // Hint: نافذة تأكيد بسيطة مع معالجة شاملة للأخطاء
  void _showDeleteWithdrawalConfirmation(
    AppLocalizations l10n, {
    required int withdrawalId,
    required Decimal amount,
    String? partnerName,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.error, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'تأكيد الحذف',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'هل أنت متأكد من حذف هذا السحب؟',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: AppConstants.borderRadiusMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          partnerName ?? widget.supplierName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.attach_money, size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Text(
                        'المبلغ: ${formatCurrency(amount)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '⚠️ سيتم إرجاع المبلغ إلى الرصيد المتاح.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await dbHelper.deleteProfitWithdrawal(withdrawalId);

                if (!ctx.mounted) return;

                Navigator.pop(ctx);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ تم حذف السحب بنجاح'),
                    backgroundColor: AppColors.success,
                  ),
                );

                // Hint: إعادة حساب المسحوب الكلي بعد الحذف
                setState(() {
                  _currentTotalWithdrawn = Decimal.parse((_currentTotalWithdrawn - amount).toDouble().toString());
                  _loadData();
                });
              } catch (e) {
                if (!ctx.mounted) return;

                Navigator.pop(ctx);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ خطأ في حذف السحب: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            icon: const Icon(Icons.delete),
            label: const Text('حذف'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 📄 دالة توليد PDF
  // ============================================================================
  Future<void> _generatePdf() async {
    setState(() => _isGeneratingPdf = true);
    
    try {
      final l10n = AppLocalizations.of(context)!;
      
      // 1️⃣ جلب البيانات
      final partners = await _partnersFuture ?? [];
      final withdrawals = await _withdrawalsFuture ?? [];
      final netProfit = Decimal.parse((widget.totalProfit - _currentTotalWithdrawn).toDouble().toString());
      
      // 2️⃣ تحويل بيانات الشركاء
      final partnersData = partners.map((p) {
         final shareDecimal = Decimal.parse(p.sharePercentage.toString());
         // Hint: نحسب نصيب كل شريك من الربح الأصلي (قبل أي مسحوبات)
         return {
              'partnerName': p.partnerName,
              'sharePercentage': p.sharePercentage,
              'partnerShare': Decimal.parse((widget.totalProfit * shareDecimal / Decimal.fromInt(100)).toDouble().toString()),
               };
        }).toList();
      
      // 3️⃣ إنشاء PDF
      final pdf = await PdfService.instance.buildSupplierDetailsReport(
        supplierName: widget.supplierName,
        supplierType: widget.supplierType,
        totalProfit: widget.totalProfit,
        totalWithdrawn: _currentTotalWithdrawn,
        netProfit: netProfit,
        partnersData: partnersData,
        withdrawalsData: withdrawals,
      );
      
      // 4️⃣ عرض خيارات PDF
      if (!mounted) return;
      
      PdfHelpers.showPdfOptionsDialog(
        context,
        pdf,
        onSuccess: () {},
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