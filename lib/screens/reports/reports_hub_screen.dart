// lib/screens/reports/reports_hub_screen.dart

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_card.dart';
import '../sales/cash_sales_history_screen.dart';
import 'cash_flow_report_screen.dart';
import 'comprehensive_cash_flow_report_screen.dart';
import 'customer_sales_report_screen.dart';
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
  // ← Hint: تم إزالة AuthService

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
                size: 60,
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

    // ✅ Hint: تقرير التدفقات النقدية الشامل (جديد)
    // ✅ Hint: يجمع جميع التدفقات المالية من مصادر مختلفة
    if (true) {
      reports.add(
        ReportItem(
          title: l10n.comprehensiveCashFlowReport,
          subtitle: 'تقرير شامل لجميع التدفقات النقدية ( إيرادات ومصروفات )',
          icon: Icons.analytics,
          color: const Color(0xFF9C27B0), // Purple color
          screen: const ComprehensiveCashFlowReportScreen(),
        ),
      );
    }

    // --- تقرير الأرباح العام ---
    if (true) {
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
    if (true) {
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

      // ✅ Hint: إضافة تقرير مبيعات الزبائن (جديد)
  if (true) {
    reports.add(
      ReportItem(
        title: 'تقرير مبيعات الزبائن',
        subtitle: 'تقرير تفصيلي بمبيعات الزبائن مع إحصائيات شاملة',
        icon: Icons.people_outline,
        color: AppColors.primaryLight,
        screen: const CustomerSalesReportScreen(),
      ),
    );
  }

    // --- سجل المبيعات النقدية ---
    if (true) {
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
    if (true) {
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
    if (true) {
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
    if (true) {
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
        // تغيير حجم الكرات للجميع
        padding: const EdgeInsets.all(AppConstants.spacingSm),
        child: Row(
          children: [
            // --- أيقونة التقرير ---
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: report.color.withOpacity(0.1),
                borderRadius: AppConstants.borderRadiusLg,
              ),
              child: Icon(
                report.icon,
                color: report.color,
                size: 26,
              ),
            ),

            const SizedBox(width: AppConstants.spacingLg),

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
                      fontSize: 14,
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
              size: 20,
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