// // lib/screens/reports/reports_hub_screen.dart

// import 'package:flutter/material.dart';
// import '../../services/auth_service.dart';
// import '../../widgets/gradient_background.dart';
// import '../sales/cash_sales_history_screen.dart';
// import 'cash_flow_report_screen.dart';
// import 'employees_report_screen.dart';
// import 'expenses_screen.dart';
// import 'profit_report_screen.dart';
// import 'supplier_profit_report_screen.dart';
// import 'package:accounting_app/l10n/app_localizations.dart';
// import '../../theme/app_colors.dart';
// import '../../widgets/glass_container.dart';

// class ReportsHubScreen extends StatefulWidget {
//   const ReportsHubScreen({super.key});

//   @override
//   State<ReportsHubScreen> createState() => _ReportsHubScreenState();
// }

// class _ReportsHubScreenState extends State<ReportsHubScreen> {
//   final AuthService _authService = AuthService();

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;

//     return Scaffold(
//       // --- 2. توحيد بنية الصفحة لتتوافق مع التصميم الزجاجي ---
//       backgroundColor: Colors.transparent,
//       extendBodyBehindAppBar: true,
//       body: GradientBackground(
//         // استخدام CustomScrollView للحصول على تأثيرات تمرير أفضل
//         child: CustomScrollView(
//           slivers: [
//             // شريط العنوان الذي يندمج مع المحتوى
//             SliverAppBar(
//               title: Text(l10n.reportsHub),
//               pinned: true,
//               // باقي الخصائص (اللون، الشفافية) تأتي من الثيم
//             ),
//             // استخدام SliverList لعرض القائمة
//             SliverList(
//               delegate: SliverChildListDelegate(
//                 [
//                   // إضافة مسافة علوية لبداية القائمة
//                   const SizedBox(height: 8),
//                   // --- 3. الحفاظ على نفس منطق عرض التقارير بناءً على الصلاحيات ---
//                   if (_authService.canViewReports)
//                     _buildReportTile(
//                       context: context,
//                       title: l10n.generalProfitReport,
//                       subtitle: l10n.generalProfitReportSubtitle,
//                       icon: Icons.trending_up,
//                       onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfitReportScreen())),
//                     ),
//                   if (_authService.isAdmin)
//                     _buildReportTile(
//                       context: context,
//                       title: l10n.supplierProfitReport,
//                       subtitle: l10n.supplierProfitReportSubtitle,
//                       icon: Icons.pie_chart,
//                       onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupplierProfitReportScreen())),
//                     ),
//                   if (_authService.canViewCashSales)
//                     _buildReportTile(
//                       context: context,
//                       title: l10n.cashSalesHistory,
//                       subtitle: l10n.cashSalesHistorySubtitle,
//                       icon: Icons.point_of_sale,
//                       onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CashSalesHistoryScreen())),
//                     ),
//                   if (_authService.canViewCashSales)
//                     _buildReportTile(
//                       context: context,
//                       title: l10n.cashFlowReport,
//                       subtitle: l10n.cashFlowReportSubtitle,
//                       icon: Icons.account_balance_wallet,
//                       onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CashFlowReportScreen())),
//                     ),
//                   if (_authService.canManageExpenses)
//                     _buildReportTile(
//                       context: context,
//                       title: l10n.expensesLog,
//                       subtitle: l10n.expensesLogSubtitle,
//                       icon: Icons.receipt_long,
//                       onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExpensesScreen())),
//                     ),
//                   if (_authService.canViewEmployeesReport)
//                     _buildReportTile(
//                       context: context,
//                       title: l10n.employeesAndSalariesReport,
//                       subtitle: l10n.employeesAndSalariesReportSubtitle,
//                       icon: Icons.people_outline,
//                       onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmployeesReportScreen())),
//                     ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // --- 4. تعديل دالة بناء البطاقات لتطبيق التصميم الزجاجي ---
//   Widget _buildReportTile({
//     required BuildContext context,
//     required String title,
//     required String subtitle,
//     required IconData icon,
//     required VoidCallback onTap,
//   }) {
//     final theme = Theme.of(context);

//     // تم استبدال Card بـ GlassContainer مع الحفاظ على نفس بنية ListTile
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
//       child: GlassContainer(
//         borderRadius: 15,
//         child: ListTile(
//           contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
//           onTap: onTap,
//           // تم تعديل تصميم الأيقونة ليتناسب مع الثيم الزجاجي
//           leading: CircleAvatar(
//             radius: 28,
//             backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
//             child: Icon(icon, size: 28, color: theme.colorScheme.primary),
//           ),
//           // تم تعديل تصميم النصوص لتعتمد على الثيم
//           title: Text(
//             title,
//             style: theme.textTheme.titleMedium?.copyWith(
//               fontWeight: FontWeight.bold,
//               color: theme.colorScheme.onSurface, // لون النص الرئيسي
//             ),
//           ),
//           subtitle: Text(
//             subtitle,
//             style: theme.textTheme.bodyMedium, // لون النص الفرعي
//           ),
//           trailing: Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textGrey),
//         ),
//       ),
//     );
//   }
// }
