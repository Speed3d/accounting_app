// lib/screens/reports/reports_hub_screen.dart

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_card.dart';
import '../sales/cash_sales_history_screen.dart';
import 'cash_flow_report_screen.dart';
import 'employees_report_screen.dart';
import 'expenses_screen.dart';
import 'profit_report_screen.dart';
import 'supplier_profit_report_screen.dart';

/// 📊 مركز التقارير - الصفحة الرئيسية
/// ---------------------------
/// يمكن عرضها بطريقتين:
/// 1. من خلال MainLayout (من الشريط السفلي) - بدون Scaffold
/// 2. مباشرة (من الأزرار أو القائمة الجانبية) - تحتاج Scaffold
class ReportsHubScreen extends StatefulWidget {
  final bool useScaffold; // ✅ إضافة متغير للتحكم في استخدام Scaffold
  
  const ReportsHubScreen({
    super.key, 
    this.useScaffold = true, // ✅ القيمة الافتراضية true
  });

  @override
  State<ReportsHubScreen> createState() => _ReportsHubScreenState();
}

class _ReportsHubScreenState extends State<ReportsHubScreen> {
  // ============= المتغيرات =============
  final AuthService _authService = AuthService();

  // ============= البناء الرئيسي =============
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // --- جمع التقارير المتاحة حسب الصلاحيات ---
    final availableReports = _getAvailableReports();
    
    // --- المحتوى الأساسي ---
    Widget content = _buildContent(availableReports);
    
    // ✅ إذا كنا نحتاج Scaffold (عند الفتح المباشر)
    if (widget.useScaffold) {
      return Scaffold(
        appBar: AppBar(
          title:  Text(l10n.reportingCenter),
          centerTitle: false,
        ),
        body: content,
      );
    }
    
    // ✅ إذا كنا داخل MainLayout (لا نحتاج Scaffold)
    return content;
  }
  
  // ============= بناء المحتوى =============
  Widget _buildContent(List<ReportItem> availableReports) {
     final l10n = AppLocalizations.of(context)!;
    // --- حالة عدم وجود تقارير متاحة ---
    if (availableReports.isEmpty) {
      return Center(
        child: Padding(
          padding: AppConstants.paddingXl,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Theme.of(context).iconTheme.color?.withOpacity(0.3),
              ),
              const SizedBox(height: AppConstants.spacingLg),
              Text(
                l10n.noreportsavailable,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                l10n.donotpermissionreports,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // --- عرض قائمة التقارير ---
    return ListView.builder(
      padding: AppConstants.screenPadding,
      itemCount: availableReports.length,
      itemBuilder: (context, index) {
        final report = availableReports[index];
        return _buildReportCard(report);
      },
    );
  }

  // ============= جمع التقارير المتاحة =============
  /// يُرجع قائمة بالتقارير المتاحة حسب صلاحيات المستخدم
  List<ReportItem> _getAvailableReports() {
    final l10n = AppLocalizations.of(context)!;
    final reports = <ReportItem>[];

    // --- تقرير الأرباح العام ---
    if (_authService.canViewReports || _authService.isAdmin) {
      reports.add(
        ReportItem(
          title: l10n.generalProfitReport,
          subtitle: l10n.generalProfitReport_desc,
          icon: Icons.trending_up,
          color: AppColors.success,
          screen: const ProfitReportScreen(),
        ),
      );
    }

    // --- تقرير أرباح الموردين (للمدير فقط) ---
    if (_authService.isAdmin) {
      reports.add(
        ReportItem(
          title: l10n.supplierProfitReport,
          subtitle: l10n.supplierProfitReport_desc,
          icon: Icons.pie_chart,
          color: AppColors.info,
          screen: const SupplierProfitReportScreen(),
        ),
      );
    }

    // --- سجل المبيعات النقدية ---
    if (_authService.canViewCashSales || _authService.isAdmin) {
      reports.add(
        ReportItem(
          title: l10n.cashSalesRecord,
          subtitle: l10n.cashSalesRecord_desc,
          icon: Icons.point_of_sale,
          color: AppColors.primaryLight,
          screen: const CashSalesHistoryScreen(),
        ),
      );
    }

    // --- تقرير التدفق النقدي ---
    if (_authService.canViewCashSales || _authService.isAdmin) {
      reports.add(
        ReportItem(
          title: l10n.cashFlowReport,
          subtitle: l10n.cashFlowReport_desc,
          icon: Icons.account_balance_wallet,
          color: AppColors.secondaryLight,
          screen: const CashFlowReportScreen(),
        ),
      );
    }

    // --- سجل المصاريف ---
    if (_authService.canManageExpenses || _authService.isAdmin) {
      reports.add(
        ReportItem(
          title: l10n.expenseRecord,
          subtitle: l10n.expenseRecord_desc,
          icon: Icons.receipt_long,
          color: AppColors.error,
          screen: const ExpensesScreen(),
        ),
      );
    }

    // --- تقرير الموظفين والرواتب ---
    if (_authService.canViewEmployeesReport || _authService.isAdmin) {
      reports.add(
        ReportItem(
          title: l10n.employeePayrollReport,
          subtitle: l10n.employeePayrollReport_desc,
          icon: Icons.people_outline,
          color: AppColors.warning,
          screen: const EmployeesReportScreen(),
        ),
      );
    }

    return reports;
  }

  // ============= بناء بطاقة التقرير =============
  /// يعرض كل تقرير في بطاقة أنيقة مع أيقونة ملونة
  Widget _buildReportCard(ReportItem report) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => report.screen),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Row(
          children: [
            // --- أيقونة التقرير ---
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: report.color.withOpacity(0.1),
                borderRadius: AppConstants.borderRadiusLg,
              ),
              child: Icon(
                report.icon,
                color: report.color,
                size: 28,
              ),
            ),

            const SizedBox(width: AppConstants.spacingMd),

            // --- تفاصيل التقرير ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // عنوان التقرير
                  Text(
                    report.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingXs),

                  // وصف التقرير
                  Text(
                    report.subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // --- سهم للانتقال ---
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ============= نموذج بيانات التقرير =============
/// كلاس مساعد لتمثيل بيانات كل تقرير
class ReportItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget screen;

  ReportItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.screen,
  });
}