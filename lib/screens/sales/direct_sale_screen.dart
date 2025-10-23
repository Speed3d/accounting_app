// // lib/screens/sales/direct_sale_screen.dart

// import 'dart:typed_data';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
// import '../../data/database_helper.dart';
// import '../../data/models.dart';
// import 'package:accounting_app/l10n/app_localizations.dart';
// import '../../services/auth_service.dart';
// import '../../utils/helpers.dart';
// import '../../widgets/gradient_background.dart';
// import '../products/add_edit_product_screen.dart';
// import '../../theme/app_colors.dart';
// import '../../widgets/glass_container.dart';

// class DirectSaleScreen extends StatefulWidget {
//   const DirectSaleScreen({super.key});

//   @override
//   State<DirectSaleScreen> createState() => _DirectSaleScreenState();
// }

// class _DirectSaleScreenState extends State<DirectSaleScreen> {
//   // ... (كل متغيرات الحالة والدوال المنطقية تبقى كما هي)
//   final dbHelper = DatabaseHelper.instance;
//   final AuthService _authService = AuthService();
//   final List<CartItem> _cartItems = [];
//   late Future<List<Product>> _productsFuture;
//   bool _isProcessingSale = false;

//   @override
//   void initState() {
//     super.initState();
//     _productsFuture = dbHelper.getAllProductsWithSupplierName();
//   }

//   Future<void> _completeSale() async {
//     final l10n = AppLocalizations.of(context)!;
//     if (_cartItems.isEmpty || _isProcessingSale) {
//       if (_cartItems.isEmpty) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.cartIsEmpty)));
//       return;
//     }
//     setState(() => _isProcessingSale = true);
//     try {
//       final cashCustomer = await dbHelper.getOrCreateCashCustomer();
//       final db = await dbHelper.database;
//       final totalAmount = _calculateTotal();
//       int newInvoiceId;
//       newInvoiceId = await db.transaction((txn) async {
//         final invoiceId = await txn.insert('TB_Invoices', {'CustomerID': cashCustomer.customerID!, 'InvoiceDate': DateTime.now().toIso8601String(), 'TotalAmount': totalAmount});
//         for (var item in _cartItems) {
//           final product = item.product;
//           final quantitySold = item.quantity;
//           final salePriceForItem = product.sellingPrice * quantitySold;
//           final profitForItem = (product.sellingPrice - product.costPrice) * quantitySold;
//           await txn.insert('Debt_Customer', {'InvoiceID': invoiceId, 'CustomerID': cashCustomer.customerID!, 'ProductID': product.productID!, 'CustomerName': cashCustomer.address, 'Details': l10n.saleDetails(product.productName, quantitySold.toString()), 'Debt': salePriceForItem, 'DateT': DateTime.now().toIso8601String(), 'Qty_Coustomer': quantitySold, 'CostPriceAtTimeOfSale': product.costPrice, 'ProfitAmount': profitForItem});
//           await txn.rawUpdate('UPDATE Store_Products SET Quantity = Quantity - ? WHERE ProductID = ?', [quantitySold, product.productID]);
//         }
//         return invoiceId;
//       });
//       final pdfBytes = await _generatePdfInvoice(newInvoiceId, totalAmount, l10n);
//       await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes, name: 'Invoice-$newInvoiceId.pdf');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saleSuccess), backgroundColor: Colors.green));
//         setState(() {
//           _cartItems.clear();
//           _productsFuture = dbHelper.getAllProductsWithSupplierName();
//         });
//       }
//     } catch (e) {
//       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorOccurred(e.toString())), backgroundColor: Colors.red));
//     } finally {
//       if (mounted) setState(() => _isProcessingSale = false);
//     }
//   }

//   Future<Uint8List> _generatePdfInvoice(int invoiceId, double totalAmount, AppLocalizations l10n) async {
//     // ... (دالة توليد الفاتورة تبقى كما هي)
//     final pdf = pw.Document();
//     final font = await PdfGoogleFonts.cairoRegular();
//     final settings = await dbHelper.getAppSettings();
//     final companyName = settings['companyName'] ?? 'My Shop';
//     pdf.addPage(pw.Page(pageFormat: PdfPageFormat.a4, build: (pw.Context context) {
//       return pw.Directionality(textDirection: pw.TextDirection.rtl, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
//         pw.Text(companyName, style: pw.TextStyle(font: font, fontSize: 24, fontWeight: pw.FontWeight.bold)),
//         pw.SizedBox(height: 20),
//         pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(l10n.pdfInvoiceTitle, style: pw.TextStyle(font: font, fontSize: 18)), pw.Text('${l10n.pdfInvoiceNumber} #$invoiceId', style: const pw.TextStyle(fontSize: 16))]),
//         pw.Text('${l10n.pdfDate}: ${DateFormat('yyyy/MM/dd').format(DateTime.now())}', style: pw.TextStyle(font: font)),
//         pw.Divider(height: 20),
//         pw.Table.fromTextArray(headerStyle: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold), cellStyle: pw.TextStyle(font: font), headerAlignment: pw.Alignment.center, cellAlignment: pw.Alignment.center, headers: [l10n.pdfHeaderTotal, l10n.pdfHeaderPrice, l10n.pdfHeaderQty, l10n.pdfHeaderProduct], data: _cartItems.map((item) => [formatCurrency(item.product.sellingPrice * item.quantity), formatCurrency(item.product.sellingPrice), item.quantity.toString(), item.product.productName]).toList(), columnWidths: {3: const pw.FlexColumnWidth(2)}, cellAlignments: {3: pw.Alignment.centerRight}),
//         pw.Divider(),
//         pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [pw.Text(formatCurrency(totalAmount), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)), pw.SizedBox(width: 10), pw.Text('${l10n.pdfFooterTotal}:', style: pw.TextStyle(font: font, fontSize: 18, fontWeight: pw.FontWeight.bold))]),
//         pw.Spacer(),
//         pw.Center(child: pw.Text(l10n.pdfFooterThanks, style: pw.TextStyle(font: font))),
//       ]));
//     }));
//     return pdf.save();
//   }

//   void _handleProductTap(Product product) {
//     final l10n = AppLocalizations.of(context)!;
//     final existingIndex = _cartItems.indexWhere((item) => item.product.productID == product.productID);
//     if (existingIndex != -1) {
//       _showEditCartItemDialog(_cartItems[existingIndex], existingIndex, l10n);
//     } else {
//       if (product.quantity > 0) {
//         setState(() => _cartItems.add(CartItem(product: product, quantity: 1)));
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.quantityExceedsStock), backgroundColor: Colors.red));
//       }
//     }
//   }

//   Future<void> _scanBarcodeAndAddToCart() async {
//     final l10n = AppLocalizations.of(context)!;
//     final String? barcode = await Navigator.push<String>(context, MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()));
//     if (barcode == null || !mounted) return;
//     final product = await dbHelper.getProductByBarcode(barcode);
//     if (product != null) {
//       _handleProductTap(product);
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.productNotFound)));
//     }
//   }

//   double _calculateTotal() {
//     return _cartItems.fold(0.0, (sum, item) => sum + (item.product.sellingPrice * item.quantity));
//   }

//   // --- 2. تعديل مربعات الحوار لتكون زجاجية ---
//   // الشرح: تم تغليف AlertDialog بـ BackdropFilter وتعديل خصائصه ليتناسب مع التصميم الزجاجي.
//   void _showCartReviewDialog(AppLocalizations l10n) {
//     if (_cartItems.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.cartIsEmpty)));
//       return;
//     }
//     showDialog(context: context, builder: (context) {
//       return StatefulBuilder(builder: (BuildContext context, StateSetter setDialogState) {
//         double calculateDialogTotal() => _cartItems.fold(0.0, (sum, item) => sum + (item.product.sellingPrice * item.quantity));
//         return BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
//           child: AlertDialog(
//             backgroundColor: AppColors.glassBgColor.withOpacity(0.9),
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.glassBorderColor)),
//             title: Text(l10n.reviewCart),
//             content: SizedBox(width: double.maxFinite, child: Column(mainAxisSize: MainAxisSize.min, children: [
//               ListTile(dense: true, title: Text(l10n.product, style: const TextStyle(fontWeight: FontWeight.bold)), trailing: Text(l10n.total, style: const TextStyle(fontWeight: FontWeight.bold))),
//               const Divider(color: AppColors.glassBorderColor),
//               Flexible(child: ListView.builder(shrinkWrap: true, itemCount: _cartItems.length, itemBuilder: (context, index) {
//                 final item = _cartItems[index];
//                 return ListTile(title: Text(item.product.productName), subtitle: Text('${l10n.quantity}: ${item.quantity}'), trailing: Text(formatCurrency(item.quantity * item.product.sellingPrice), style: const TextStyle(fontWeight: FontWeight.bold)), onTap: () {
//                   Navigator.of(context).pop();
//                   _showEditCartItemDialog(item, index, l10n);
//                 });
//               })),
//               const Divider(color: AppColors.glassBorderColor),
//               Padding(padding: const EdgeInsets.only(top: 8.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//                 Text('${l10n.finalTotal}:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                 Text(formatCurrency(calculateDialogTotal()), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
//               ])),
//             ])),
//             actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.close, style: TextStyle(color: AppColors.textGrey)))],
//           ),
//         );
//       });
//     });
//   }

//   void _showEditCartItemDialog(CartItem item, int index, AppLocalizations l10n) {
//     final quantityController = TextEditingController(text: item.quantity.toString());
//     showDialog(context: context, builder: (context) {
//       return BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
//         child: AlertDialog(
//           backgroundColor: AppColors.glassBgColor.withOpacity(0.9),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.glassBorderColor)),
//           title: Text(item.product.productName),
//           content: TextFormField(controller: quantityController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.quantity, helperText: "${l10n.available}: ${item.product.quantity}"), autofocus: true),
//           actions: [
//             TextButton.icon(onPressed: () { setState(() => _cartItems.removeAt(index)); Navigator.of(context).pop(); }, icon: const Icon(Icons.delete_outline, color: Colors.redAccent), label: Text(l10n.delete, style: const TextStyle(color: Colors.redAccent))),
//             ElevatedButton(onPressed: () {
//               final quantity = int.tryParse(convertArabicNumbersToEnglish(quantityController.text)) ?? 0;
//               if (quantity <= 0) {
//                 setState(() => _cartItems.removeAt(index));
//               } else if (quantity > item.product.quantity) {
//                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.quantityExceedsStock), backgroundColor: Colors.red));
//                 return;
//               } else {
//                 setState(() => _cartItems[index] = CartItem(product: item.product, quantity: quantity));
//               }
//               Navigator.of(context).pop();
//             }, child: Text(l10n.save)),
//           ],
//         ),
//       );
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     final theme = Theme.of(context);
//     final safeArea = MediaQuery.of(context).padding;

//     return GradientScaffold(
//       appBar: AppBar(
//         title: Text("نقطة البيع المباشر"),
//         actions: [
//           IconButton(icon: const Icon(Icons.qr_code_scanner), tooltip: l10n.scanBarcode, onPressed: _scanBarcodeAndAddToCart),
//           IconButton(
//             icon: Badge(
//               label: Text(_cartItems.length.toString()),
//               isLabelVisible: _cartItems.isNotEmpty,
//               child: const Icon(Icons.shopping_cart_outlined),
//             ),
//             tooltip: l10n.reviewCart,
//             onPressed: () => _showCartReviewDialog(l10n),
//           ),
//         ],
//       ),
//       // ✅✅✅ بداية التعديل الرئيسي ✅✅✅
//       body: Stack(
//         children: [
//           // --- الطبقة الأولى: قائمة المنتجات ---
//           FutureBuilder<List<Product>>(
//             future: _productsFuture,
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator(color: Colors.white));
//               }
//               if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                 return Center(child: Text(l10n.noProductsInStock, style: theme.textTheme.bodyLarge));
//               }
//               final products = snapshot.data!;
              
//               return ListView.builder(
//                 padding: EdgeInsets.only(
//                   top: safeArea.top + kToolbarHeight + 8,
//                   left: 12,
//                   right: 12,
//                   bottom: safeArea.bottom + 8, // <-- مسافة بسيطة في الأسفل
//                 ),
//                 itemCount: products.length,
//                 itemBuilder: (context, index) {
//                   final product = products[index];
//                   final cartItemIndex = _cartItems.indexWhere((item) => item.product.productID == product.productID);
//                   final isInCart = cartItemIndex != -1;

//                   return Padding(
//                     padding: const EdgeInsets.only(bottom: 8.0),
//                     child: GlassContainer(
//                       borderRadius: 15,
//                       color: isInCart ? AppColors.accentBlue.withOpacity(0.15) : AppColors.glassBgColor,
//                       borderColor: isInCart ? AppColors.accentBlue : AppColors.glassBorderColor,
//                       child: ListTile(
//                         leading: CircleAvatar(
//                           backgroundColor: isInCart ? AppColors.accentBlue : AppColors.primaryPurple.withOpacity(0.5),
//                           child: isInCart
//                               ? Text("x${_cartItems[cartItemIndex].quantity}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
//                               : Icon(Icons.inventory_2_outlined, color: AppColors.textGrey.withOpacity(0.7)),
//                         ),
//                         title: Text(product.productName),
//                         subtitle: Text('${l10n.available}: ${product.quantity} | ${l10n.price}: ${formatCurrency(product.sellingPrice)}'),
//                         onTap: () => _handleProductTap(product),
//                       ),
//                     ),
//                   );
//                 },
//               );
//             },
//           ),

//           // --- الطبقة الثانية: زر إتمام البيع (إذا كانت السلة غير فارغة) ---
//           if (_cartItems.isNotEmpty)
//             Align(
//               alignment: Alignment.bottomCenter, // <-- يضع الزر في المنتصف السفلي
//               child: Padding(
//                 // الشرح: نضيف Padding سفلي بمقدار ارتفاع شريط التنقل + مسافة إضافية
//                 padding: EdgeInsets.only(bottom: safeArea.bottom + 80),
//                 child: FloatingActionButton.extended(
//                   onPressed: _isProcessingSale ? null : _completeSale,
//                   label: _isProcessingSale
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : Text("${"إتمام البيع"} (${formatCurrency(_calculateTotal())})"),
//                   icon: _isProcessingSale ? null : const Icon(Icons.check_circle_outline),
//                   backgroundColor: Colors.green,
//                   foregroundColor: Colors.white,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }


