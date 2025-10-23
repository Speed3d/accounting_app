// // lib/screens/reports/employees_report_screen.dart

// import 'package:flutter/material.dart';
// import '../../data/database_helper.dart';
// import '../../data/models.dart';
// import '../../utils/helpers.dart';
// import '../../widgets/gradient_background.dart';
// import '../employees/employee_details_screen.dart';
// import 'package:accounting_app/l10n/app_localizations.dart';
// import '../../theme/app_colors.dart';
// import '../../widgets/glass_container.dart';

// class EmployeesReportScreen extends StatefulWidget {
//   const EmployeesReportScreen({super.key});

//   @override
//   State<EmployeesReportScreen> createState() => _EmployeesReportScreenState();
// }

// class _EmployeesReportScreenState extends State<EmployeesReportScreen> {
//   // ... (كل متغيرات الحالة والدوال المنطقية تبقى كما هي)
//   final dbHelper = DatabaseHelper.instance;
//   late Future<double> _totalSalariesFuture;
//   late Future<double> _totalAdvancesFuture;
//   late Future<int> _employeesCountFuture;
//   late Future<List<Employee>> _employeesListFuture;

//   @override
//   void initState() {
//     super.initState();
//     _loadReportData();
//   }

//   void _loadReportData() {
//     setState(() {
//       _totalSalariesFuture = dbHelper.getTotalNetSalariesPaid();
//       _totalAdvancesFuture = dbHelper.getTotalActiveAdvancesBalance();
//       _employeesCountFuture = dbHelper.getActiveEmployeesCount();
//       _employeesListFuture = dbHelper.getAllActiveEmployees();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;

//     return Scaffold(
//       // --- 2. توحيد بنية الصفحة لتتوافق مع التصميم الزجاجي ---
//       backgroundColor: Colors.transparent,
//       extendBodyBehindAppBar: true,
//       body: GradientBackground(
//         // استخدام RefreshIndicator مع CustomScrollView
//         child: RefreshIndicator(
//           onRefresh: () async => _loadReportData(),
//           backgroundColor: AppColors.lightPurple,
//           color: Colors.white,
//           child: CustomScrollView(
//             slivers: [
//               SliverAppBar(
//                 title: Text(l10n.employeesReport),
//                 pinned: true,
//               ),
//               // استخدام SliverToBoxAdapter لعرض المحتوى غير القابل للتمرير داخل CustomScrollView
//               SliverToBoxAdapter(
//                 child: Padding(
//                   padding: const EdgeInsets.all(12.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _buildSummarySection(l10n),
//                       const Divider(height: 32, color: AppColors.glassBorderColor, indent: 16, endIndent: 16),
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                         child: Text(
//                           l10n.employeesStatement,
//                           // تعديل نمط الخط ليتناسب مع الثيم
//                           style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textGrey),
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       _buildDetailedEmployeesList(l10n),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // --- 3. تعديل قسم الملخص ليعتمد على الثيم ---
//   Widget _buildSummarySection(AppLocalizations l10n) {
//     return Column(
//       children: [
//         Row(
//           children: [
//             Expanded(
//               child: FutureBuilder<double>(
//                 future: _totalSalariesFuture,
//                 builder: (context, snapshot) => _buildSummaryCard(
//                   title: l10n.totalSalariesPaid,
//                   value: snapshot.hasData ? formatCurrency(snapshot.data!) : '...',
//                   icon: Icons.payments,
//                   color: Colors.greenAccent, // استخدام ألوان مشرقة
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: FutureBuilder<double>(
//                 future: _totalAdvancesFuture,
//                 builder: (context, snapshot) => _buildSummaryCard(
//                   title: l10n.totalAdvancesBalance,
//                   value: snapshot.hasData ? formatCurrency(snapshot.data!) : '...',
//                   icon: Icons.request_quote,
//                   color: Colors.orangeAccent, // استخدام ألوان مشرقة
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 12),
//         FutureBuilder<int>(
//           future: _employeesCountFuture,
//           builder: (context, snapshot) => _buildSummaryCard(
//             title: l10n.activeEmployeesCount,
//             value: snapshot.hasData ? snapshot.data!.toString() : '...',
//             icon: Icons.people,
//             color: Colors.lightBlueAccent, // استخدام ألوان مشرقة
//             isWide: true,
//           ),
//         ),
//       ],
//     );
//   }

//   // --- 4. تعديل دالة بناء بطاقات الملخص للتصميم الزجاجي ---
//   Widget _buildSummaryCard({
//     required String title,
//     required String value,
//     required IconData icon,
//     required Color color,
//     bool isWide = false,
//   }) {
//     final theme = Theme.of(context);
//     // استخدام GlassContainer بدلاً من Card
//     return GlassContainer(
//       borderRadius: 15,
//       padding: const EdgeInsets.all(16.0),
//       child: isWide
//           ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//               Icon(icon, color: color, size: 24),
//               const SizedBox(width: 12),
//               Text('$title: ', style: theme.textTheme.bodyLarge),
//               Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
//             ])
//           : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//               Icon(icon, color: color, size: 28),
//               const SizedBox(height: 8),
//               Text(title, style: theme.textTheme.bodyMedium),
//               Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
//             ]),
//     );
//   }

//   // --- 5. تعديل قائمة الموظفين التفصيلية للتصميم الزجاجي ---
//   Widget _buildDetailedEmployeesList(AppLocalizations l10n) {
//     return FutureBuilder<List<Employee>>(
//       future: _employeesListFuture,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator(color: Colors.white));
//         }
//         if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(l10n.noEmployeesToDisplay, style: Theme.of(context).textTheme.bodyLarge)));
//         }
//         final employees = snapshot.data!;
//         // استخدام GlassContainer كخلفية للقائمة بأكملها
//         return GlassContainer(
//           borderRadius: 15,
//           child: ListView.separated(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: employees.length,
//             separatorBuilder: (context, index) => const Divider(indent: 16, endIndent: 16, color: AppColors.glassBorderColor, height: 1),
//             itemBuilder: (context, index) {
//               final employee = employees[index];
//               return ListTile(
//                 title: Text(employee.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
//                 subtitle: Text('${l10n.salaryLabel(formatCurrency(employee.baseSalary))} | ${l10n.advancesBalanceLabel(formatCurrency(employee.balance))}'),
//                 trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textGrey),
//                 onTap: () {
//                   Navigator.of(context).push(
//                     MaterialPageRoute(builder: (context) => EmployeeDetailsScreen(employee: employee)),
//                   );
//                 },
//               );
//             },
//           ),
//         );
//       },
//     );
//   }
// }
