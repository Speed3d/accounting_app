// // lib/screens/customers/customers_list_screen.dart

// import 'dart:io';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import '../../data/database_helper.dart';
// import '../../data/models.dart';
// import '../../services/auth_service.dart';
// import '../../utils/helpers.dart';
// import '../../widgets/gradient_background.dart';
// import 'add_edit_customer_screen.dart';
// import 'customer_details_screen.dart';
// import 'package:accounting_app/l10n/app_localizations.dart';
// import '../../theme/app_colors.dart';
// import '../../widgets/glass_container.dart';

// class CustomersListScreen extends StatefulWidget {
//   const CustomersListScreen({super.key});

//   @override
//   State<CustomersListScreen> createState() => _CustomersListScreenState();
// }

// class _CustomersListScreenState extends State<CustomersListScreen> {
//   // ... (كل متغيرات الحالة والدوال المنطقية تبقى كما هي)
//   final dbHelper = DatabaseHelper.instance;
//   late Future<List<Customer>> _customersFuture;
//   final AuthService _authService = AuthService();
//   late bool _isAdmin;

//   @override
//   void initState() {
//     super.initState();
//     _isAdmin = _authService.isAdmin;
//     _loadCustomers();
//   }

//   void _loadCustomers() {
//     setState(() {
//       _customersFuture = dbHelper.getAllCustomers();
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
//       // صفحات الاضافة هكذا تكون
//       body: GradientBackground(
//         child: CustomScrollView(
//           slivers: [
//             // --- 3. تعديل AppBar ليكون زجاجياً ---
//             SliverAppBar(
//               title: Text(l10n.customersList),
//               pinned: true,
//               floating: true,
//             ),
//             // --- 4. استخدام FutureBuilder مع SliverList ---
//             FutureBuilder<List<Customer>>(
//               future: _customersFuture,
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Colors.white)));
//                 }
//                 if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                   return SliverFillRemaining(child: Center(child: Text(l10n.noActiveCustomers, style: theme.textTheme.bodyLarge)));
//                 }

//                 final customers = snapshot.data!;
//                 return SliverList(
//                   delegate: SliverChildBuilderDelegate(
//                     (context, index) {
//                       final customer = customers[index];
//                       final imageFile = customer.imagePath != null && customer.imagePath!.isNotEmpty ? File(customer.imagePath!) : null;

//                       String balanceText;
//                       Color balanceColor;
//                       if (customer.remaining > 0) {
//                         balanceText = '${l10n.remainingOnHim}: ${formatCurrency(customer.remaining)}';
//                         balanceColor = Colors.redAccent;
//                       } else if (customer.remaining < 0) {
//                         balanceText = '${l10n.remainingForHim}: ${formatCurrency(-customer.remaining)}';
//                         balanceColor = Colors.lightBlueAccent;
//                       } else {
//                         balanceText = '${l10n.balance}: 0';
//                         balanceColor = Colors.greenAccent;
//                       }

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
//                                 child: (imageFile == null || !imageFile.existsSync()) ? Icon(Icons.person, color: AppColors.textGrey.withOpacity(0.5), size: 30) : null,
//                               ),
//                             ),
//                             title: Text(customer.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
//                             subtitle: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 const SizedBox(height: 4),
//                                 Text('${l10n.phone}: ${customer.phone ?? l10n.unregistered}'),
//                                 const SizedBox(height: 4),
//                                 Text(balanceText, style: TextStyle(color: balanceColor, fontWeight: FontWeight.bold)),
//                               ],
//                             ),
//                             isThreeLine: true,
//                             onTap: () async {
//                               await Navigator.of(context).push(MaterialPageRoute(builder: (context) => CustomerDetailsScreen(customer: customer)));
//                               _loadCustomers();
//                             },
//                             trailing: _isAdmin
//                                 ? Row(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       IconButton(icon: const Icon(Icons.edit, color: AppColors.accentBlue), onPressed: () async {
//                                         final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddEditCustomerScreen(customer: customer)));
//                                         if (result == true) _loadCustomers();
//                                       }),
//                                       IconButton(icon: const Icon(Icons.archive, color: Colors.redAccent), onPressed: () => _handleArchiveCustomer(customer)),
//                                     ],
//                                   )
//                                 : null,
//                           ),
//                         ),
//                       );
//                     },
//                     childCount: customers.length,
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//       // --- 6. تعديل تصميم الزر العائم ---
//       floatingActionButton: FloatingActionButton(
//         onPressed: () async {
//           final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AddEditCustomerScreen()));
//           if (result == true) _loadCustomers();
//         },
//         backgroundColor: theme.colorScheme.primary,
//         child: const Icon(Icons.add),
//       ),
//     );
//   }

//   // --- 7. تعديل مربع حوار الأرشفة ---
//   void _handleArchiveCustomer(Customer customer) async {
//     final l10n = AppLocalizations.of(context)!;
//     if (customer.remaining > 0) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.cannotArchiveCustomerWithDebt), backgroundColor: Colors.red));
//       return;
//     }

//     showDialog(
//       context: context,
//       builder: (ctx) => BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
//         child: AlertDialog(
//           backgroundColor: AppColors.glassBgColor.withOpacity(0.9),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.glassBorderColor)),
//           title: Text(l10n.archiveConfirmTitle),
//           content: Text(l10n.archiveConfirmContent(customer.customerName)),
//           actions: [
//             TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.cancel, style: TextStyle(color: AppColors.textGrey))),
//             TextButton(
//               onPressed: () async {
//                 await dbHelper.archiveCustomer(customer.customerID!);
//                 await dbHelper.logActivity('أرشفة الزبون: ${customer.customerName}', userId: _authService.currentUser?.id, userName: _authService.currentUser?.fullName);
//                 Navigator.of(ctx).pop();
//                 _loadCustomers();
//               },
//               child: Text(l10n.archive, style: const TextStyle(color: Colors.redAccent)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
