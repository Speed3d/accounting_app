// lib/screens/reports/supplier_profit_report_screen.dart

import 'package:flutter/material.dart';
import '../../data/database_helper.dart';
import '../../data/models.dart';
import 'package:accounting_app/l10n/app_localizations.dart';
import '../../utils/helpers.dart';
import 'supplier_details_report_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_state.dart';

class SupplierProfitReportScreen extends StatefulWidget {
  const SupplierProfitReportScreen({super.key});

  @override
  State<SupplierProfitReportScreen> createState() => _SupplierProfitReportScreenState();
}

class _SupplierProfitReportScreenState extends State<SupplierProfitReportScreen> {
  final dbHelper = DatabaseHelper.instance;
  late Future<List<SupplierProfitData>> _reportDataFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _reportDataFuture = _getReportData();
    });
  }

  Future<List<SupplierProfitData>> _getReportData() async {
    final profits = await dbHelper.getProfitBySupplier();
    final List<SupplierProfitData> reportData = [];
    
    for (var profitItem in profits) {
      final supplierId = profitItem['SupplierID'];
      final supplierType = profitItem['SupplierType'];
      final totalWithdrawn = await dbHelper.getTotalWithdrawnForSupplier(supplierId);
      
      List<Partner> partners = [];
      if (supplierType == 'شراكة') {
        partners = await dbHelper.getPartnersForSupplier(supplierId);
      }
      
      reportData.add(SupplierProfitData(
        supplierId: supplierId,
        supplierName: profitItem['SupplierName'],
        supplierType: supplierType,
        totalProfit: profitItem['TotalProfit'],
        totalWithdrawn: totalWithdrawn,
        partners: partners,
      ));
    }
    
    return reportData;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // ============= AppBar =============
      appBar: AppBar(
        title: Text(l10n.supplierProfitReport),
        actions: [
          // زر تحديث البيانات
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'تحديث',
          ),
        ],
      ),
      
      // ============= Body =============
      body: FutureBuilder<List<SupplierProfitData>>(
        future: _reportDataFuture,
        builder: (context, snapshot) {
          // حالة التحميل
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState(message: 'جاري تحميل البيانات...');
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
              icon: Icons.trending_up,
              title: l10n.noProfitsRecorded,
              message: 'لا توجد أرباح مسجلة للموردين بعد',
            );
          }

          final reportDataList = snapshot.data!;
          
          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: ListView.builder(
              padding: AppConstants.screenPadding,
              itemCount: reportDataList.length,
              itemBuilder: (context, index) {
                final data = reportDataList[index];
                return _buildSupplierCard(context, data, isDark, l10n);
              },
            ),
          );
        },
      ),
    );
  }

  /// بناء بطاقة المورد
  Widget _buildSupplierCard(
    BuildContext context,
    SupplierProfitData data,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final netProfit = data.totalProfit - data.totalWithdrawn;
    
    // تحديد لون المورد حسب النوع
    final supplierColor = data.supplierType == 'شراكة' 
        ? AppColors.secondaryLight 
        : AppColors.info;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SupplierDetailsReportScreen(
              supplierId: data.supplierId,
              supplierName: data.supplierName,
              supplierType: data.supplierType,
              totalProfit: data.totalProfit,
              totalWithdrawn: data.totalWithdrawn,
            ),
          ),
        );
        _loadData(); // تحديث البيانات عند العودة
      },
      child: Column(
        children: [
          // ============= الصف الأول: المعلومات الأساسية =============
          Row(
            children: [
              // أيقونة المورد
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: supplierColor.withOpacity(0.1),
                  borderRadius: AppConstants.borderRadiusMd,
                ),
                child: Icon(
                  data.supplierType == 'شراكة' 
                      ? Icons.people 
                      : Icons.business,
                  color: supplierColor,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: AppConstants.spacingMd),
              
              // اسم المورد ونوعه
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // اسم المورد
                    Text(
                      data.supplierName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: AppConstants.spacingXs),
                    
                    // نوع المورد أو الشركاء
                    _buildSupplierSubtitle(data, isDark, l10n),
                  ],
                ),
              ),
              
              // سهم الانتقال
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isDark 
                    ? AppColors.textSecondaryDark 
                    : AppColors.textSecondaryLight,
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.spacingMd),
          
          // ============= الصف الثاني: الأرقام المالية =============
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            decoration: BoxDecoration(
              color: isDark 
                  ? AppColors.backgroundDark 
                  : AppColors.surfaceLight,
              borderRadius: AppConstants.borderRadiusMd,
            ),
            child: Row(
              children: [
                // إجمالي الأرباح
                Expanded(
                  child: _buildFinancialItem(
                    context,
                    label: 'إجمالي الأرباح',
                    value: formatCurrency(data.totalProfit),
                    color: AppColors.info,
                    icon: Icons.trending_up,
                  ),
                ),
                
                // خط فاصل
                Container(
                  width: 1,
                  height: 40,
                  color: isDark 
                      ? AppColors.borderDark 
                      : AppColors.borderLight,
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingMd,
                  ),
                ),
                
                // المسحوبات
                Expanded(
                  child: _buildFinancialItem(
                    context,
                    label: 'المسحوبات',
                    value: formatCurrency(data.totalWithdrawn),
                    color: AppColors.warning,
                    icon: Icons.arrow_downward,
                  ),
                ),
                
                // خط فاصل
                Container(
                  width: 1,
                  height: 40,
                  color: isDark 
                      ? AppColors.borderDark 
                      : AppColors.borderLight,
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingMd,
                  ),
                ),
                
                // صافي الربح
                Expanded(
                  child: _buildFinancialItem(
                    context,
                    label: 'صافي الربح',
                    value: formatCurrency(netProfit),
                    color: netProfit >= 0 ? AppColors.success : AppColors.error,
                    icon: netProfit >= 0 
                        ? Icons.check_circle 
                        : Icons.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// بناء النص الفرعي للمورد (نوعه أو شركاؤه)
  Widget _buildSupplierSubtitle(
    SupplierProfitData data,
    bool isDark,
    AppLocalizations l10n,
  ) {
    if (data.supplierType == 'شراكة' && data.partners.isNotEmpty) {
      final partnerNames = data.partners.map((p) => p.partnerName).join('، ');
      return Text(
        l10n.partnersLabel(partnerNames),
        style: TextStyle(
          fontSize: 12,
          color: isDark 
              ? AppColors.textSecondaryDark 
              : AppColors.textSecondaryLight,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    } else {
      return Text(
        l10n.typeLabel(l10n.individual),
        style: TextStyle(
          fontSize: 12,
          color: isDark 
              ? AppColors.textSecondaryDark 
              : AppColors.textSecondaryLight,
        ),
      );
    }
  }

  /// بناء عنصر مالي (رقم مع أيقونة وعنوان)
  Widget _buildFinancialItem(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        // الأيقونة
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        
        const SizedBox(height: AppConstants.spacingXs),
        
        // العنوان
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AppConstants.spacingXs),
        
        // القيمة
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// كلاس مساعد لحمل بيانات المورد
class SupplierProfitData {
  final int supplierId;
  final String supplierName;
  final String supplierType;
  final double totalProfit;
  final double totalWithdrawn;
  final List<Partner> partners;

  SupplierProfitData({
    required this.supplierId,
    required this.supplierName,
    required this.supplierType,
    required this.totalProfit,
    required this.totalWithdrawn,
    required this.partners,
  });
}