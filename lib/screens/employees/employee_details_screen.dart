// // lib/screens/employees/employee_details_screen.dart

// import 'dart:io';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../../data/database_helper.dart';
// import '../../data/models.dart';
// import '../../services/auth_service.dart';
// import '../../utils/helpers.dart';
// import '../../widgets/gradient_background.dart';
// import 'add_advance_screen.dart';
// import 'add_edit_employee_screen.dart';
// import 'add_payroll_screen.dart';
// import 'package:accounting_app/l10n/app_localizations.dart';
// import '../../theme/app_colors.dart';
// import '../../widgets/glass_container.dart';

// class EmployeeDetailsScreen extends StatefulWidget {
//   final Employee employee;
//   const EmployeeDetailsScreen({super.key, required this.employee});

//   @override
//   State<EmployeeDetailsScreen> createState() => _EmployeeDetailsScreenState();
// }

// class _EmployeeDetailsScreenState extends State<EmployeeDetailsScreen> with SingleTickerProviderStateMixin {
//   // ... (كل متغيرات الحالة والدوال المنطقية تبقى كما هي)
//   final dbHelper = DatabaseHelper.instance;
//   final AuthService _authService = AuthService();
//   late TabController _tabController;
//   late Employee _currentEmployee;
//   late Future<List<PayrollEntry>> _payrollFuture;
//   late Future<List<EmployeeAdvance>> _advancesFuture;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     _currentEmployee = widget.employee;
//     _reloadData();
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   void _reloadData() {
//     setState(() {
//       _payrollFuture = dbHelper.getPayrollForEmployee(_currentEmployee.employeeID!);
//       _advancesFuture = dbHelper.getAdvancesForEmployee(_currentEmployee.employeeID!);
//       dbHelper.getEmployeeById(_currentEmployee.employeeID!).then((employee) {
//         if (employee != null) setState(() => _currentEmployee = employee);
//       });
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     final theme = Theme.of(context);

//     return Scaffold(
//       // --- 2. توحيد بنية الصفحة ---
//       backgroundColor: Colors.transparent,
//       extendBodyBehindAppBar: true,
//       body: GradientBackground(
//         child: NestedScrollView(
//           headerSliverBuilder: (context, innerBoxIsScrolled) {
//             return [
//               // --- 3. تعديل AppBar ليكون زجاجياً ---
//               SliverAppBar(
//                 title: Text(_currentEmployee.fullName),
//                 pinned: true,
//                 floating: true,
//                 backgroundColor: Colors.transparent,
//                 flexibleSpace: const GlassContainer(borderRadius: 0, child: SizedBox.shrink()),
//                 actions: [
//                   IconButton(
//                     icon: const Icon(Icons.edit_outlined),
//                     tooltip: l10n.editEmployee,
//                     onPressed: () async {
//                       final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddEditEmployeeScreen(employee: _currentEmployee)));
//                       if (result == true) _reloadData();
//                     },
//                   ),
//                 ],
//                 bottom: TabBar(
//                   controller: _tabController,
//                   labelColor: theme.colorScheme.primary,
//                   unselectedLabelColor: AppColors.textGrey,
//                   indicator: UnderlineTabIndicator(borderSide: BorderSide(width: 3.0, color: theme.colorScheme.primary), insets: const EdgeInsets.symmetric(horizontal: 40.0)),
//                   tabs: [
//                     Tab(icon: const Icon(Icons.payments_outlined), text: l10n.payrollHistory),
//                     Tab(icon: const Icon(Icons.request_quote_outlined), text: l10n.advancesHistory),
//                   ],
//                 ),
//               ),
//             ];
//           },
//           // --- 4. تعديل محتوى الجسم ---
//           body: Column(
//             children: [
//               _buildEmployeeInfoCard(l10n),
//               Expanded(
//                 child: TabBarView(
//                   controller: _tabController,
//                   children: [
//                     _buildPayrollTab(l10n),
//                     _buildAdvancesTab(l10n),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // --- 5. تعديل بطاقة معلومات الموظف ---
//   Widget _buildEmployeeInfoCard(AppLocalizations l10n) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
//       child: GlassContainer(
//         borderRadius: 15,
//         padding: const EdgeInsets.all(16.0),
//         child: Row(
//           children: [
//             GlassContainer(
//               borderRadius: 40,
//               child: CircleAvatar(
//                 radius: 40,
//                 backgroundColor: Colors.transparent,
//                 backgroundImage: _currentEmployee.imagePath != null && _currentEmployee.imagePath!.isNotEmpty ? FileImage(File(_currentEmployee.imagePath!)) : null,
//                 child: _currentEmployee.imagePath == null || _currentEmployee.imagePath!.isEmpty ? Icon(Icons.badge, size: 40, color: AppColors.textGrey.withOpacity(0.5)) : null,
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(_currentEmployee.fullName, style: Theme.of(context).textTheme.titleLarge),
//                   const SizedBox(height: 4),
//                   Text(l10n.baseSalaryLabel(formatCurrency(_currentEmployee.baseSalary)), style: Theme.of(context).textTheme.bodyMedium),
//                   Text(
//                     l10n.advancesBalanceLabel(formatCurrency(_currentEmployee.balance)),
//                     style: TextStyle(color: _currentEmployee.balance > 0 ? Colors.redAccent : Colors.greenAccent, fontWeight: FontWeight.bold),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // --- 6. تعديل تبويب سجل الرواتب ---
//   Widget _buildPayrollTab(AppLocalizations l10n) {
//     final List<String> months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
//     final theme = Theme.of(context);

//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       body: FutureBuilder<List<PayrollEntry>>(
//         future: _payrollFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white));
//           if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text(l10n.noPayrolls, style: theme.textTheme.bodyLarge));
          
//           final payrolls = snapshot.data!;
//           return ListView.builder(
//             padding: const EdgeInsets.fromLTRB(12, 8, 12, 80), // مسافة سفلية للزر العائم
//             itemCount: payrolls.length,
//             itemBuilder: (context, index) {
//               final entry = payrolls[index];
//               return Padding(
//                 padding: const EdgeInsets.only(bottom: 8.0),
//                 child: GlassContainer(
//                   borderRadius: 12,
//                   child: ListTile(
//                     leading: const Icon(Icons.payment, color: Colors.greenAccent),
//                     title: Text(l10n.payrollOfMonth(months[entry.payrollMonth - 1], entry.payrollYear.toString()), style: const TextStyle(fontWeight: FontWeight.bold)),
//                     subtitle: Text(l10n.paidOn(DateFormat('yyyy-MM-dd').format(DateTime.parse(entry.paymentDate)))),
//                     trailing: Text(formatCurrency(entry.netSalary), style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold)),
//                     onTap: () => _showPayrollDetailsDialog(l10n, entry, months),
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () async {
//           final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddPayrollScreen(employee: _currentEmployee)));
//           if (result == true) _reloadData();
//         },
//         backgroundColor: theme.colorScheme.primary,
//         child: const Icon(Icons.add),
//       ),
//     );
//   }

//   // --- 7. تعديل تبويب سجل السلف ---
//   Widget _buildAdvancesTab(AppLocalizations l10n) {
//     final theme = Theme.of(context);
//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       body: FutureBuilder<List<EmployeeAdvance>>(
//         future: _advancesFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white));
//           if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text(l10n.noAdvances, style: theme.textTheme.bodyLarge));

//           final advances = snapshot.data!;
//           return ListView.builder(
//             padding: const EdgeInsets.fromLTRB(12, 8, 12, 80), // مسافة سفلية للزر العائم
//             itemCount: advances.length,
//             itemBuilder: (context, index) {
//               final advance = advances[index];
//               final statusText = advance.repaymentStatus == 'مسددة بالكامل' ? l10n.fullyPaid : l10n.unpaid;
//               return Padding(
//                 padding: const EdgeInsets.only(bottom: 8.0),
//                 child: GlassContainer(
//                   borderRadius: 12,
//                   child: ListTile(
//                     leading: const Icon(Icons.request_quote, color: Colors.orangeAccent),
//                     title: Text(l10n.advanceAmountLabel(formatCurrency(advance.advanceAmount))),
//                     subtitle: Text(l10n.advanceDateLabel(DateFormat('yyyy-MM-dd').format(DateTime.parse(advance.advanceDate)))),
//                     trailing: Text(statusText, style: TextStyle(color: advance.repaymentStatus == 'مسددة بالكامل' ? Colors.greenAccent : Colors.orangeAccent, fontWeight: FontWeight.bold)),
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () async {
//           final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddAdvanceScreen(employee: _currentEmployee)));
//           if (result == true) _reloadData();
//         },
//         backgroundColor: theme.colorScheme.primary,
//         child: const Icon(Icons.add),
//       ),
//     );
//   }

//   // --- 8. تعديل مربع حوار تفاصيل الراتب ---
//   void _showPayrollDetailsDialog(AppLocalizations l10n, PayrollEntry entry, List<String> months) {
//     showDialog(
//       context: context,
//       builder: (context) => BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
//         child: AlertDialog(
//           backgroundColor: AppColors.glassBgColor.withOpacity(0.9),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.glassBorderColor)),
//           title: Text(l10n.payrollDetailsFor(months[entry.payrollMonth - 1])),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text('${l10n.baseSalary}: ${formatCurrency(entry.baseSalary)}'),
//               Text('${l10n.bonuses}: ${formatCurrency(entry.bonuses)}'),
//               Text('${l10n.deductions}: ${formatCurrency(entry.deductions)}'),
//               Text('${l10n.advanceRepayment}: ${formatCurrency(entry.advanceDeduction)}'),
//               const Divider(color: AppColors.glassBorderColor),
//               Text('${l10n.netSalaryDue}: ${formatCurrency(entry.netSalary)}', style: const TextStyle(fontWeight: FontWeight.bold)),
//               if(entry.notes != null && entry.notes!.isNotEmpty) ...[
//                 const SizedBox(height: 8),
//                 Text('${l10n.notesOptional}: ${entry.notes}'),
//               ]
//             ],
//           ),
//           actions: [
//             TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.close, style: TextStyle(color: AppColors.textGrey))),
//           ],
//         ),
//       ),
//     );
//   }
// }
