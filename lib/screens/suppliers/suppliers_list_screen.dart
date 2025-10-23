// // lib/screens/suppliers/suppliers_list_screen.dart

// import 'dart:io';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import '../../data/database_helper.dart';
// import '../../data/models.dart';
// import '../../services/auth_service.dart';
// import '../../widgets/gradient_background.dart';
// import 'add_edit_supplier_screen.dart';
// import 'package:accounting_app/l10n/app_localizations.dart';
// import '../../theme/app_colors.dart';
// import '../../widgets/glass_container.dart';

// class SuppliersListScreen extends StatefulWidget {
//   const SuppliersListScreen({super.key});

//   @override
//   State<SuppliersListScreen> createState() => _SuppliersListScreenState();
// }

// class _SuppliersListScreenState extends State<SuppliersListScreen> {
//   // ... (كل متغيرات الحالة والدوال المنطقية تبقى كما هي)
//   final dbHelper = DatabaseHelper.instance;
//   final AuthService _authService = AuthService();
//   late Future<List<Supplier>> _suppliersFuture;
//   late bool _isAdmin;

//   @override
//   void initState() {
//     super.initState();
//     _isAdmin = _authService.isAdmin;
//     _loadSuppliers();
//   }

//   void _loadSuppliers() {
//     setState(() {
//       _suppliersFuture = dbHelper.getAllSuppliers();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     final theme = Theme.of(context);

//     return Scaffold(
//       // --- 2. توحيد بنية الصفحة ---
//       // الشرح: نجعل Scaffold شفافاً ونضع الخلفية المتدرجة في Container.
//       backgroundColor: Colors.transparent,
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         title: Text(l10n.suppliersList),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//       ),
//       body: GradientBackground(
//         child: SafeArea(
//           child: FutureBuilder<List<Supplier>>(
//             future: _suppliersFuture,
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator(color: Colors.white));
//               }
//               if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                 return Center(child: Text(l10n.noActiveSuppliers, style: theme.textTheme.bodyLarge));
//               }
//               final suppliers = snapshot.data!;
//               // --- 3. تعديل تصميم القائمة ---
//               // الشرح: نستخدم ListView.builder لعرض البيانات، ونغلف كل عنصر بـ GlassContainer.
//               return ListView.builder(
//                 padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
//                 itemCount: suppliers.length,
//                 itemBuilder: (context, index) {
//                   final supplier = suppliers[index];
//                   final imageFile = supplier.imagePath != null && supplier.imagePath!.isNotEmpty ? File(supplier.imagePath!) : null;
//                   return Padding(
//                     padding: const EdgeInsets.only(bottom: 8.0),
//                     child: GlassContainer(
//                       borderRadius: 15,
//                       child: ListTile(
//                         leading: CircleAvatar(
//                           radius: 25,
//                           backgroundColor: AppColors.primaryPurple.withOpacity(0.5),
//                           backgroundImage: imageFile != null && imageFile.existsSync() ? FileImage(imageFile) : null,
//                           child: (imageFile == null || !imageFile.existsSync()) ? const Icon(Icons.store, color: AppColors.textGrey) : null,
//                         ),
//                         title: Text(supplier.supplierName),
//                         subtitle: Text(l10n.typeLabel(supplier.supplierType == 'شراكة' ? l10n.partnership : l10n.individual)),
//                         trailing: _isAdmin
//                             ? Row(mainAxisSize: MainAxisSize.min, children: [
//                                 IconButton(icon: const Icon(Icons.edit, color: AppColors.accentBlue), tooltip: l10n.edit, onPressed: () async {
//                                   final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddEditSupplierScreen(supplier: supplier)));
//                                   if (result == true) _loadSuppliers();
//                                 }),
//                                 IconButton(icon: const Icon(Icons.archive, color: Colors.redAccent), tooltip: l10n.archive, onPressed: () => _handleArchiveSupplier(supplier)),
//                               ])
//                             : null,
//                       ),
//                     ),
//                   );
//                 },
//               );
//             },
//           ),
//         ),
//       ),
//       // --- 4. تعديل تصميم الزر العائم ---
//       floatingActionButton: _isAdmin
//           ? FloatingActionButton(
//               onPressed: () async {
//                 final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AddEditSupplierScreen()));
//                 if (result == true) _loadSuppliers();
//               },
//               backgroundColor: theme.colorScheme.primary,
//               child: const Icon(Icons.add_business),
//             )
//           : null,
//     );
//   }

//   // --- 5. تعديل مربع حوار الأرشفة ---
//   // الشرح: تم تغليف AlertDialog بـ BackdropFilter وتعديل خصائصه ليتناسب مع التصميم الزجاجي.
//   void _handleArchiveSupplier(Supplier supplier) async {
//     final l10n = AppLocalizations.of(context)!;
//     final hasProducts = await dbHelper.hasActiveProducts(supplier.supplierID!);
//     if (hasProducts) {
//       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.cannotArchiveSupplierWithActiveProducts), backgroundColor: Colors.red));
//     } else {
//       if (mounted) {
//         showDialog(
//           context: context,
//           builder: (context) => BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
//             child: AlertDialog(
//               backgroundColor: AppColors.glassBgColor.withOpacity(0.9),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.glassBorderColor)),
//               title: Text(l10n.archive),
//               content: Text(l10n.archiveSupplierConfirmation(supplier.supplierName)),
//               actions: [
//                 TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel, style: TextStyle(color: AppColors.textGrey))),
//                 TextButton(
//                   onPressed: () async {
//                     await dbHelper.archiveSupplier(supplier.supplierID!);
//                     await dbHelper.logActivity(l10n.archiveSupplierLog(supplier.supplierName), userId: _authService.currentUser?.id, userName: _authService.currentUser?.fullName);
//                     if (mounted) Navigator.of(context).pop();
//                     _loadSuppliers();
//                   },
//                   child: Text(l10n.archive, style: const TextStyle(color: Colors.redAccent)),
//                 ),
//               ],
//             ),
//           ),
//         );
//       }
//     }
//   }
// }
