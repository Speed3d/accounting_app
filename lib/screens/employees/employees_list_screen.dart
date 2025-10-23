// // lib/screens/employees/employees_list_screen.dart

// import 'dart:io';
// import 'package:flutter/material.dart';
// import '../../data/database_helper.dart';
// import '../../data/models.dart';
// import '../../services/auth_service.dart';
// import '../../utils/helpers.dart';
// import '../../widgets/gradient_background.dart';
// import 'add_edit_employee_screen.dart';
// import 'employee_details_screen.dart';
// import 'package:accounting_app/l10n/app_localizations.dart';
// import '../../theme/app_colors.dart';
// import '../../widgets/glass_container.dart';

// class EmployeesListScreen extends StatefulWidget {
//   const EmployeesListScreen({super.key});

//   @override
//   State<EmployeesListScreen> createState() => _EmployeesListScreenState();
// }

// class _EmployeesListScreenState extends State<EmployeesListScreen> {
//   // ... (كل متغيرات الحالة والدوال المنطقية تبقى كما هي)
//   final dbHelper = DatabaseHelper.instance;
//   final AuthService _authService = AuthService();
//   late Future<List<Employee>> _employeesFuture;

//   @override
//   void initState() {
//     super.initState();
//     _loadEmployees();
//   }

//   void _loadEmployees() {
//     setState(() {
//       _employeesFuture = dbHelper.getAllActiveEmployees();
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
//         child: CustomScrollView(
//           slivers: [
//             // --- 3. تعديل AppBar ليكون زجاجياً ---
//             SliverAppBar(
//               title: Text(l10n.employeesList),
//               pinned: true,
//               floating: true,
//             ),
//             // --- 4. استخدام FutureBuilder مع SliverList ---
//             FutureBuilder<List<Employee>>(
//               future: _employeesFuture,
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Colors.white)));
//                 }
//                 if (snapshot.hasError) {
//                   return SliverFillRemaining(child: Center(child: Text(l10n.errorOccurred(snapshot.error.toString()), style: theme.textTheme.bodyLarge)));
//                 }
//                 if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                   return SliverFillRemaining(child: Center(child: Text(l10n.noEmployees, style: theme.textTheme.bodyLarge)));
//                 }

//                 final employees = snapshot.data!;
//                 return SliverList(
//                   delegate: SliverChildBuilderDelegate(
//                     (context, index) {
//                       final employee = employees[index];
//                       final imageFile = employee.imagePath != null && employee.imagePath!.isNotEmpty ? File(employee.imagePath!) : null;

//                       // --- 5. تعديل تصميم عنصر القائمة ---
//                       return Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
//                         child: GlassContainer(
//                           borderRadius: 15,
//                           child: ListTile(
//                             contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                             leading: GlassContainer(
//                               borderRadius: 30,
//                               child: CircleAvatar(
//                                 radius: 30,
//                                 backgroundColor: Colors.transparent,
//                                 backgroundImage: imageFile != null && imageFile.existsSync() ? FileImage(imageFile) : null,
//                                 child: (imageFile == null || !imageFile.existsSync()) ? Icon(Icons.badge, color: AppColors.textGrey.withOpacity(0.5), size: 30) : null,
//                               ),
//                             ),
//                             title: Text(employee.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
//                             subtitle: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 const SizedBox(height: 4),
//                                 Text(l10n.jobTitleLabel(employee.jobTitle), style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
//                                 const SizedBox(height: 6),
//                                 Text(l10n.baseSalaryLabel(formatCurrency(employee.baseSalary))),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   l10n.advancesBalanceLabel(formatCurrency(employee.balance)),
//                                   style: TextStyle(color: employee.balance > 0 ? Colors.redAccent : Colors.greenAccent, fontWeight: FontWeight.bold),
//                                 ),
//                               ],
//                             ),
//                             isThreeLine: true,
//                             trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.textGrey, size: 18),
//                             onTap: () async {
//                               await Navigator.of(context).push(MaterialPageRoute(builder: (context) => EmployeeDetailsScreen(employee: employee)));
//                               _loadEmployees();
//                             },
//                           ),
//                         ),
//                       );
//                     },
//                     childCount: employees.length,
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//       // --- 6. تعديل تصميم الزر العائم ---
//       floatingActionButton: _authService.canManageEmployees
//           ? FloatingActionButton(
//               onPressed: () async {
//                 final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AddEditEmployeeScreen()));
//                 if (result == true) _loadEmployees();
//               },
//               backgroundColor: theme.colorScheme.primary,
//               child: const Icon(Icons.add),
//             )
//           : null,
//     );
//   }
// }
