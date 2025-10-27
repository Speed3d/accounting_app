// lib/screens/reports/reports_hub_screen.dart

import 'package:flutter/material.dart';
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
/// 🔴 ملاحظة: هذه صفحة رئيسية، لذلك يتم عرضها عبر MainLayout
/// في ملف main_screen.dart (الصفحة الرئيسية 3 من 4)
/// 
/// تعرض قائمة بجميع التقارير المتاحة حسب صلاحيات المستخدم:
/// 1. تقرير الأرباح العام
/// 2. تقرير أرباح الموردين (للمدير فقط)
/// 3. سجل المبيعات النقدية
/// 4. تقرير التدفق النقدي
/// 5. سجل المصاريف
/// 6. تقرير الموظفين والرواتب
class ReportsHubScreen extends StatefulWidget {
  const ReportsHubScreen({super.key});

  @override
  State<ReportsHubScreen> createState() => _ReportsHubScreenState();
}

class _ReportsHubScreenState extends State<ReportsHubScreen> {
  // ============= المتغيرات =============
  final AuthService _authService = AuthService();

  // ============= البناء الرئيسي =============
  /// ملاحظة: هذه الصفحة تُعرض داخل MainLayout
  /// لذلك نحن نبني فقط محتوى الـ body
  @override
  Widget build(BuildContext context) {
    // --- جمع التقارير المتاحة حسب الصلاحيات ---
    final availableReports = _getAvailableReports();

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
                'لا يوجد تقارير متاحة',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                'ليس لديك صلاحية للوصول إلى أي تقرير',
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
    final reports = <ReportItem>[];

    // --- تقرير الأرباح العام ---
    if (_authService.canViewReports || _authService.isAdmin) {
      reports.add(
        ReportItem(
          title: 'تقرير الأرباح العام',
          subtitle: 'عرض إجمالي الأرباح وتفاصيل المبيعات',
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
          title: 'تقرير أرباح الموردين',
          subtitle: 'توزيع الأرباح حسب المورد والشريك',
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
          title: 'سجل المبيعات النقدية',
          subtitle: 'الفواتير والمبيعات النقدية المباشرة',
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
          title: 'تقرير التدفق النقدي',
          subtitle: 'المقبوضات النقدية والتسديدات',
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
          title: 'سجل المصاريف',
          subtitle: 'جميع المصاريف والنفقات المسجلة',
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
          title: 'تقرير الموظفين والرواتب',
          subtitle: 'كشف الموظفين والرواتب والسلف',
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