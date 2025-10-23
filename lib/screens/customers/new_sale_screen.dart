// // lib/screens/customers/new_sale_screen.dart

// import 'dart:ui';
// import 'package:flutter/material.dart';
// import '../../data/database_helper.dart';
// import '../../data/models.dart';
// import 'package:accounting_app/l10n/app_localizations.dart';
// import '../../utils/helpers.dart';
// import '../../widgets/gradient_background.dart';
// import '../products/add_edit_product_screen.dart';
// import '../../theme/app_colors.dart';
// import '../../widgets/glass_container.dart';

// class NewSaleScreen extends StatefulWidget {
//   const NewSaleScreen({super.key});

//   @override
//   State<NewSaleScreen> createState() => _NewSaleScreenState();
// }

// class _NewSaleScreenState extends State<NewSaleScreen> {
//   // ... (كل متغيرات الحالة والدوال المنطقية تبقى كما هي)
//   final dbHelper = DatabaseHelper.instance;
//   late Future<List<Product>> _productsFuture;
//   final List<CartItem> _cartItems = [];

//   @override
//   void initState() {
//     super.initState();
//     _productsFuture = dbHelper.getAllProductsWithSupplierName();
//   }

//   Future<void> scanBarcodeAndAddToCart() async {
//     final l10n = AppLocalizations.of(context)!;
//     final String? barcodeScanRes = await Navigator.push<String>(context, MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()));
//     if (!mounted || barcodeScanRes == null) return;
//     final product = await dbHelper.getProductByBarcode(barcodeScanRes);
//     if (product != null) {
//       setState(() {
//         final index = _cartItems.indexWhere((item) => item.product.productID == product.productID);
//         if (index != -1) {
//           final existingItem = _cartItems[index];
//           if (existingItem.quantity < product.quantity) {
//             _cartItems[index] = CartItem(product: product, quantity: existingItem.quantity + 1);
//           } else {
//             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.quantityExceedsStock), backgroundColor: Colors.red));
//           }
//         } else {
//           _cartItems.add(CartItem(product: product, quantity: 1));
//         }
//       });
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.productNotFound), backgroundColor: Colors.orange));
//     }
//   }

//   void _addToCart(Product product, AppLocalizations l10n) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         final quantityController = TextEditingController(text: '1');
//         return BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
//           child: AlertDialog(
//             backgroundColor: AppColors.glassBgColor.withOpacity(0.9),
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.glassBorderColor)),
//             title: Text(l10n.addWithProductName(product.productName)),
//             content: TextField(
//               controller: quantityController,
//               keyboardType: TextInputType.number,
//               decoration: InputDecoration(labelText: l10n.quantity),
//               autofocus: true,
//             ),
//             actions: [
//               TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel, style: TextStyle(color: AppColors.textGrey))),
//               ElevatedButton(
//                 onPressed: () {
//                   final englishValue = convertArabicNumbersToEnglish(quantityController.text);
//                   final quantity = int.tryParse(englishValue) ?? 0;
//                   if (quantity <= 0) return;
//                   if (quantity > product.quantity) {
//                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.quantityExceedsStock), backgroundColor: Colors.red));
//                     return;
//                   }
//                   setState(() {
//                     final index = _cartItems.indexWhere((item) => item.product.productID == product.productID);
//                     if (index != -1) {
//                       _cartItems[index] = CartItem(product: product, quantity: quantity);
//                     } else {
//                       _cartItems.add(CartItem(product: product, quantity: quantity));
//                     }
//                   });
//                   Navigator.of(context).pop();
//                 },
//                 child: Text(l10n.add),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   double _calculateTotal() {
//     return _cartItems.fold(0.0, (sum, item) => sum + (item.product.sellingPrice * item.quantity));
//   }

//   void _showCartReviewDialog(AppLocalizations l10n) {
//     if (_cartItems.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.cartIsEmpty)));
//       return;
//     }
//     showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (BuildContext context, StateSetter setDialogState) {
//             double calculateDialogTotal() {
//               return _cartItems.fold(0.0, (sum, item) => sum + (item.product.sellingPrice * item.quantity));
//             }
//             return BackdropFilter(
//               filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
//               child: AlertDialog(
//                 backgroundColor: AppColors.glassBgColor.withOpacity(0.9),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.glassBorderColor)),
//                 title: Text(l10n.reviewCart),
//                 content: SizedBox(
//                   width: double.maxFinite,
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       ListTile(dense: true, title: Text(l10n.product, style: const TextStyle(fontWeight: FontWeight.bold)), trailing: Text(l10n.total, style: const TextStyle(fontWeight: FontWeight.bold))),
//                       const Divider(color: AppColors.glassBorderColor),
//                       Flexible(
//                         child: ListView.builder(
//                           shrinkWrap: true,
//                           itemCount: _cartItems.length,
//                           itemBuilder: (context, index) {
//                             final item = _cartItems[index];
//                             return ListTile(
//                               title: Text(item.product.productName),
//                               subtitle: Text('${l10n.quantity}: ${item.quantity}'),
//                               trailing: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Text(formatCurrency(item.quantity * item.product.sellingPrice), style: const TextStyle(fontWeight: FontWeight.bold)),
//                                   const SizedBox(width: 8),
//                                   IconButton(
//                                     icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
//                                     onPressed: () {
//                                       setDialogState(() => _cartItems.removeAt(index));
//                                       setState(() {});
//                                       if (_cartItems.isEmpty) Navigator.of(context).pop();
//                                     },
//                                   ),
//                                 ],
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                       const Divider(color: AppColors.glassBorderColor),
//                       Padding(
//                         padding: const EdgeInsets.only(top: 8.0),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text('${l10n.finalTotal}:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                             Text(formatCurrency(calculateDialogTotal()), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.close, style: TextStyle(color: AppColors.textGrey)))],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     final theme = Theme.of(context);

//     return Scaffold(
//       // --- 2. توحيد بنية الصفحة ---
//       backgroundColor: Colors.transparent,
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         title: Text(l10n.chooseProducts),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         actions: [
//           if (_cartItems.isNotEmpty)
//             Center(
//               child: Stack(
//                 alignment: Alignment.center,
//                 children: [
//                   IconButton(icon: const Icon(Icons.shopping_cart_checkout), onPressed: () => _showCartReviewDialog(l10n)),
//                   Positioned(
//                     top: 8,
//                     right: 4,
//                     child: Container(
//                       padding: const EdgeInsets.all(2),
//                       decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(10)),
//                       constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
//                       child: Text('${_cartItems.length}', style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
//                     ),
//                   )
//                 ],
//               ),
//             ),
//           IconButton(icon: const Icon(Icons.save), onPressed: () => Navigator.of(context).pop(_cartItems)),
//         ],
//       ),
//       // --- 3. تعديل تصميم الزر العائم ---
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: scanBarcodeAndAddToCart,
//         label: Text(l10n.scanBarcodeToSell),
//         icon: const Icon(Icons.qr_code_scanner),
//         backgroundColor: theme.colorScheme.primary,
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
//       body: GradientBackground(
//         child: Column(
//           children: [
//             Expanded(
//               child: SafeArea(
//                 bottom: false, // لمنع SafeArea من إضافة مسافة سفلية تتعارض مع شريط الإجمالي
//                 child: FutureBuilder<List<Product>>(
//                   future: _productsFuture,
//                   builder: (context, snapshot) {
//                     if (snapshot.connectionState == ConnectionState.waiting) {
//                       return const Center(child: CircularProgressIndicator(color: Colors.white));
//                     }
//                     if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                       return Center(child: Text(l10n.noProductsInStock, style: theme.textTheme.bodyLarge));
//                     }
//                     final products = snapshot.data!;
//                     // --- 4. تعديل تصميم القائمة ---
//                     return ListView.builder(
//                       padding: const EdgeInsets.fromLTRB(12, 8, 12, 80), // مسافة سفلية للزر العائم
//                       itemCount: products.length,
//                       itemBuilder: (context, index) {
//                         final product = products[index];
//                         final cartItem = _cartItems.firstWhere((item) => item.product.productID == product.productID, orElse: () => CartItem(product: product, quantity: 0));
//                         return Padding(
//                           padding: const EdgeInsets.only(bottom: 8.0),
//                           child: GlassContainer(
//                             borderRadius: 12,
//                             child: ListTile(
//                               title: Text(product.productName),
//                               subtitle: Text('${l10n.available}: ${product.quantity} | ${l10n.price}: ${formatCurrency(product.sellingPrice)}'),
//                               trailing: Text(
//                                 'x${cartItem.quantity}',
//                                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cartItem.quantity > 0 ? theme.colorScheme.primary : AppColors.textGrey),
//                               ),
//                               onTap: () => _addToCart(product, l10n),
//                             ),
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 ),
//               ),
//             ),
//             // --- 5. تعديل تصميم شريط الإجمالي ---
//             if (_cartItems.isNotEmpty)
//               GlassContainer(
//                 borderRadius: 0,
//                 padding: const EdgeInsets.fromLTRB(20, 16, 20, 32), // مسافة سفلية إضافية
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(l10n.itemsCount(_cartItems.length.toString()), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                     Text('${l10n.total}: ${formatCurrency(_calculateTotal())}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
//                   ],
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
