// // lib/screens/products/products_list_screen.dart

// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:accounting_app/l10n/app_localizations.dart';
// import '../../data/database_helper.dart';
// import '../../data/models.dart';
// import '../../services/auth_service.dart';
// import '../../utils/helpers.dart';
// import '../../widgets/gradient_background.dart';
// import 'add_edit_product_screen.dart';
// import '../../theme/app_colors.dart';
// import '../../widgets/glass_container.dart';

// class ProductsListScreen extends StatefulWidget {
//   const ProductsListScreen({super.key});

//   @override
//   State<ProductsListScreen> createState() => _ProductsListScreenState();
// }

// class _ProductsListScreenState extends State<ProductsListScreen> {
//   // ... (كل متغيرات الحالة والدوال المنطقية تبقى كما هي)
//   final dbHelper = DatabaseHelper.instance;
//   late Future<List<Product>> _productsFuture;
//   final _searchController = TextEditingController();
//   String _searchQuery = '';
//   final AuthService _authService = AuthService();
//   late bool _isAdmin;

//   @override
//   void initState() {
//     super.initState();
//     _isAdmin = _authService.isAdmin;
//     _reloadProducts();
//     _searchController.addListener(() {
//       setState(() => _searchQuery = _searchController.text);
//     });
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   void _reloadProducts() {
//     setState(() {
//       _productsFuture = dbHelper.getAllProductsWithSupplierName();
//     });
//   }

//   void _handleArchiveProduct(Product product) async {
//     final l10n = AppLocalizations.of(context)!;
//     final isSold = await dbHelper.isProductSold(product.productID!);
//     if (isSold) {
//       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.cannotArchiveSoldProduct), backgroundColor: Colors.red));
//     } else {
//       if (mounted) {
//         // --- 2. تعديل مربع الحوار ليكون زجاجياً ---
//         showDialog(
//           context: context,
//           builder: (ctx) => BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
//             child: AlertDialog(
//               backgroundColor: AppColors.glassBgColor.withOpacity(0.9),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.glassBorderColor)),
//               title: Text(l10n.confirmArchive),
//               content: Text(l10n.archiveProductConfirmation(product.productName)),
//               actions: [
//                 TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.cancel, style: TextStyle(color: AppColors.textGrey))),
//                 TextButton(
//                   onPressed: () async {
//                     await dbHelper.archiveProduct(product.productID!);
//                     await dbHelper.logActivity('أرشفة المنتج: ${product.productName}', userId: _authService.currentUser?.id, userName: _authService.currentUser?.fullName);
//                     if (mounted) Navigator.of(ctx).pop();
//                     _reloadProducts();
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

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     final theme = Theme.of(context);

//     return Scaffold(
//       // --- 3. توحيد بنية الصفحة ---
//       backgroundColor: Colors.transparent,
//       extendBodyBehindAppBar: true,
//       body: GradientBackground(
//         child: Column(
//           children: [
//             // --- 4. تعديل AppBar ليكون زجاجياً ---
//             AppBar(
//               title: Text(l10n.productsList),
//               backgroundColor: Colors.transparent,
//               elevation: 0,
//             ),
//             // --- 5. تعديل تصميم حقل البحث ---
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//               child: TextField(
//                 controller: _searchController,
//                 decoration: InputDecoration(
//                   hintText: l10n.searchForProduct,
//                   prefixIcon: const Icon(Icons.search, color: AppColors.textGrey),
//                   filled: true,
//                   fillColor: AppColors.glassBgColor,
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.glassBorderColor, width: 1.5)),
//                   enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.glassBorderColor, width: 1.5)),
//                   focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
//                 ),
//               ),
//             ),
//             // --- 6. تعديل تصميم القائمة ---
//             Expanded(
//               child: FutureBuilder<List<Product>>(
//                 future: _productsFuture,
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator(color: Colors.white));
//                   }
//                   if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                     return Center(child: Text(l10n.noActiveProducts, style: theme.textTheme.bodyLarge));
//                   }
//                   final filteredProducts = snapshot.data!.where((p) => p.productName.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
//                   if (filteredProducts.isEmpty) {
//                     return Center(child: Text(l10n.noMatchingResults, style: theme.textTheme.bodyLarge));
//                   }
//                   return ListView.builder(
//                     padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
//                     itemCount: filteredProducts.length,
//                     itemBuilder: (context, index) {
//                       final product = filteredProducts[index];
//                       return Padding(
//                         padding: const EdgeInsets.only(bottom: 8.0),
//                         child: GlassContainer(
//                           borderRadius: 15,
//                           child: ListTile(
//                             title: Text(product.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
//                             subtitle: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(l10n.supplierLabel(product.supplierName ?? l10n.undefined)),
//                                 Text('${l10n.quantityLabel(product.quantity.toString())} | ${l10n.sellingPriceLabel(formatCurrency(product.sellingPrice))}'),
//                               ],
//                             ),
//                             trailing: _isAdmin
//                                 ? Row(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       IconButton(icon: const Icon(Icons.edit, color: AppColors.accentBlue), onPressed: () async {
//                                         final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddEditProductScreen(product: product)));
//                                         if (result == true) _reloadProducts();
//                                       }),
//                                       IconButton(icon: const Icon(Icons.archive, color: Colors.redAccent), onPressed: () => _handleArchiveProduct(product)),
//                                     ],
//                                   )
//                                 : null,
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//       // --- 7. تعديل تصميم الزر العائم ---
//       floatingActionButton: _isAdmin
//           ? FloatingActionButton(
//               onPressed: () async {
//                 final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AddEditProductScreen()));
//                 if (result == true) _reloadProducts();
//               },
//               backgroundColor: theme.colorScheme.primary,
//               child: const Icon(Icons.add),
//             )
//           : null,
//     );
//   }
// }
