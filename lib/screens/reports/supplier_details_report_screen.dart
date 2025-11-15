// lib/screens/reports/supplier_details_report_screen.dart

import 'dart:io';
import 'package:accounting_app/services/pdf_service.dart' show PdfService;
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
import 'package:accounting_app/l10n/app_localizations.dart';

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
    final netProfit = widget.totalProfit - _currentTotalWithdrawn;

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRecordWithdrawalDialog(l10n),
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
              final shareDecimal = Decimal.parse(partner.sharePercentage.toString());
              final partnerShare = (netProfit * shareDecimal / Decimal.fromInt(100)).toDecimal();
              return _buildPartnerCard(partner, partnerShare, l10n);
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
  Widget _buildPartnerCard(Partner partner, Decimal partnerShare, AppLocalizations l10n) {
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

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: Padding(
        padding: AppConstants.paddingMd,
        child: Row(
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
                onPressed: () => _showRecordWithdrawalDialog(
                  l10n,
                  partnerName: partner.partnerName,
                ),
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
      ),
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
  Widget _buildWithdrawalCard(Map<String, dynamic> withdrawal, AppLocalizations l10n) {
    final amount = withdrawal['WithdrawalAmount'] as Decimal;
    final date = DateTime.parse(withdrawal['WithdrawalDate'] as String);
    final partnerName = withdrawal['PartnerName'] as String?;
    final notes = withdrawal['Notes'] as String?;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: Padding(
        padding: AppConstants.paddingMd,
        child: Row(
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
      ),
    );
  }

  // ============================================================================
  // 💬 نافذة تسجيل سحب جديد
  // ============================================================================
  void _showRecordWithdrawalDialog(AppLocalizations l10n, {String? partnerName}) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    final netProfit = widget.totalProfit - _currentTotalWithdrawn;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
                // عرض صافي الربح
                Container(
                  padding: AppConstants.paddingMd,
                  decoration: BoxDecoration(
                    color: netProfit >= Decimal.zero
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: AppConstants.borderRadiusMd,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: netProfit >= Decimal.zero ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'صافي الربح المتاح',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              formatCurrency(netProfit),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: netProfit >= Decimal.zero ? AppColors.success : AppColors.error,
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

                    if (amount > netProfit) {
                    return l10n.amountExceedsProfit;
                     }
                   } catch (e) {
                      return l10n.enterValidAmount;
                  }

                    return null;
                  },
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
                final withdrawalData = {
                  'SupplierID': widget.supplierId,
                  'PartnerName': partnerName,
                  'WithdrawalAmount': parseDecimal(
                    convertArabicNumbersToEnglish(amountController.text),
                  ),
                  'WithdrawalDate': DateTime.now().toIso8601String(),
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
                  _currentTotalWithdrawn += withdrawalData['WithdrawalAmount'] as Decimal;
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
      final netProfit = widget.totalProfit - _currentTotalWithdrawn;
      
      // 2️⃣ تحويل بيانات الشركاء
      final partnersData = partners.map((p) {
         final shareDecimal = Decimal.parse(p.sharePercentage.toString());
         return {
              'partnerName': p.partnerName,
              'sharePercentage': p.sharePercentage,
              'partnerShare': (netProfit * shareDecimal / Decimal.fromInt(100)).toDecimal(),
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