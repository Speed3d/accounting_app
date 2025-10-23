// // lib/screens/customers/customer_details_screen.dart

// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../../data/database_helper.dart';
// import '../../data/models.dart';
// import '../../services/auth_service.dart';
// import '../../utils/helpers.dart';
// import '../../widgets/gradient_background.dart';
// import 'new_sale_screen.dart';
// import 'package:accounting_app/l10n/app_localizations.dart';
// import '../../theme/app_colors.dart';
// import '../../widgets/glass_container.dart';

// class CustomerDetailsScreen extends StatefulWidget {
//   final Customer customer;
//   const CustomerDetailsScreen({super.key, required this.customer});

//   @override
//   State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
// }

// class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> with SingleTickerProviderStateMixin {
//   // ... (كل متغيرات الحالة والدوال المنطقية تبقى كما هي)
//   late TabController _tabController;
//   final dbHelper = DatabaseHelper.instance;
//   final AuthService _authService = AuthService();
//   late Customer _currentCustomer;
//   late Future<List<CustomerDebt>> _debtsFuture;
//   late Future<List<CustomerPayment>> _paymentsFuture;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     _currentCustomer = widget.customer;
//     _reloadData();
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   void _reloadData() {
//     setState(() {
//       _debtsFuture = dbHelper.getDebtsForCustomer(_currentCustomer.customerID!);
//       _paymentsFuture = dbHelper.getPaymentsForCustomer(_currentCustomer.customerID!);
//       dbHelper.getCustomerById(_currentCustomer.customerID!).then((customer) {
//         if (customer != null) setState(() => _currentCustomer = customer);
//       });
//     });
//   }

//   void _recordNewSale() async {
//     final l10n = AppLocalizations.of(context)!;
//     final result = await Navigator.of(context).push<List<CartItem>>(MaterialPageRoute(builder: (context) => const NewSaleScreen()));
//     if (result == null || result.isEmpty) return;
//     final db = await dbHelper.database;
//     double totalSaleAmount = 0;
//     await db.transaction((txn) async {
//       for (var item in result) {
//         final product = item.product;
//         final quantitySold = item.quantity;
//         final salePriceForItem = product.sellingPrice * quantitySold;
//         final profitForItem = (product.sellingPrice - product.costPrice) * quantitySold;
//         totalSaleAmount += salePriceForItem;
//         final saleDetails = l10n.saleDetails(product.productName, quantitySold.toString());
//         final newDebt = CustomerDebt(customerID: _currentCustomer.customerID!, customerName: _currentCustomer.customerName, details: saleDetails, debt: salePriceForItem, dateT: DateTime.now().toIso8601String(), qty_Coustomer: quantitySold, productID: product.productID!, costPriceAtTimeOfSale: product.costPrice, profitAmount: profitForItem);
//         await txn.insert('Debt_Customer', newDebt.toMap());
//         await txn.rawUpdate('UPDATE Store_Products SET Quantity = Quantity - ? WHERE ProductID = ?', [quantitySold, product.productID]);
//       }
//       await txn.rawUpdate('UPDATE TB_Customer SET Debt = Debt + ?, Remaining = Remaining + ? WHERE CustomerID = ?', [totalSaleAmount, totalSaleAmount, _currentCustomer.customerID]);
//     });
//     await dbHelper.logActivity('تسجيل عملية بيع جديدة للزبون: ${_currentCustomer.customerName} بقيمة: ${formatCurrency(totalSaleAmount)}', userId: _authService.currentUser?.id, userName: _authService.currentUser?.fullName);
//     if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.newSaleSuccess), backgroundColor: Colors.green));
//     _reloadData();
//   }

//   void _recordNewPayment() {
//     final l10n = AppLocalizations.of(context)!;
//     final paymentController = TextEditingController();
//     final commentsController = TextEditingController();
//     final dialogFormKey = GlobalKey<FormState>();
//     showDialog(
//       context: context,
//       builder: (context) => BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
//         child: AlertDialog(
//           backgroundColor: AppColors.glassBgColor.withOpacity(0.9),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.glassBorderColor)),
//           title: Text(l10n.newPayment),
//           content: Form(
//             key: dialogFormKey,
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 TextFormField(controller: paymentController, decoration: InputDecoration(labelText: l10n.paidAmount), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) {
//                   if (v == null || v.isEmpty) return l10n.amountRequired;
//                   final amount = double.tryParse(convertArabicNumbersToEnglish(v));
//                   if (amount == null || amount <= 0) return l10n.enterValidAmount;
//                   if (amount > _currentCustomer.remaining) return l10n.amountExceedsDebt;
//                   return null;
//                 }),
//                 TextFormField(controller: commentsController, decoration: InputDecoration(labelText: l10n.notesOptional)),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel, style: TextStyle(color: AppColors.textGrey))),
//             ElevatedButton(
//               onPressed: () async {
//                 if (dialogFormKey.currentState!.validate()) {
//                   final amount = double.parse(convertArabicNumbersToEnglish(paymentController.text));
//                   final db = await dbHelper.database;
//                   await db.transaction((txn) async {
//                     final newPayment = CustomerPayment(customerID: _currentCustomer.customerID!, customerName: _currentCustomer.customerName, payment: amount, dateT: DateTime.now().toIso8601String(), comments: commentsController.text);
//                     await txn.insert('Payment_Customer', newPayment.toMap());
//                     await txn.rawUpdate('UPDATE TB_Customer SET Payment = Payment + ?, Remaining = Remaining - ? WHERE CustomerID = ?', [amount, amount, _currentCustomer.customerID]);
//                   });
//                   await dbHelper.logActivity('تسجيل دفعة للزبون: ${_currentCustomer.customerName} بقيمة: ${formatCurrency(amount)}', userId: _authService.currentUser?.id, userName: _authService.currentUser?.fullName);
//                   Navigator.of(context).pop();
//                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.paymentSuccess), backgroundColor: Colors.green));
//                   _reloadData();
//                 }
//               },
//               child: Text(l10n.save),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _handleReturnSale(CustomerDebt sale) async {
//     final l10n = AppLocalizations.of(context)!;
//     showDialog(
//       context: context,
//       builder: (ctx) => BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
//         child: AlertDialog(
//           backgroundColor: AppColors.glassBgColor.withOpacity(0.9),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.glassBorderColor)),
//           title: Text(l10n.returnConfirmTitle),
//           content: Text(l10n.returnConfirmContent(sale.details)),
//           actions: [
//             TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.cancel, style: TextStyle(color: AppColors.textGrey))),
//             TextButton(
//               onPressed: () async {
//                 Navigator.of(ctx).pop();
//                 try {
//                   await dbHelper.returnSaleItem(sale);
//                   await dbHelper.logActivity('إرجاع منتج: ${sale.details} للزبون: ${_currentCustomer.customerName}', userId: _authService.currentUser?.id, userName: _authService.currentUser?.fullName);
//                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.returnSuccess), backgroundColor: Colors.green));
//                   _reloadData();
//                 } catch (e) {
//                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorOccurred(e.toString())), backgroundColor: Colors.red));
//                 }
//               },
//               child: Text(l10n.returnItem, style: const TextStyle(color: Colors.redAccent)),
//             ),
//           ],
//         ),
//       ),
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
//       body: GradientBackground(
//         child: NestedScrollView(
//           headerSliverBuilder: (context, innerBoxIsScrolled) {
//             return [
//               // --- 3. تعديل AppBar ليكون زجاجياً ---
//               SliverAppBar(
//                 title: Text(_currentCustomer.customerName),
//                 pinned: true,
//                 floating: true,
//                 backgroundColor: Colors.transparent,
//                 flexibleSpace: const GlassContainer(borderRadius: 0, child: SizedBox.shrink()),
//                 bottom: TabBar(
//                   controller: _tabController,
//                   labelColor: theme.colorScheme.primary,
//                   unselectedLabelColor: AppColors.textGrey,
//                   indicator: UnderlineTabIndicator(borderSide: BorderSide(width: 3.0, color: theme.colorScheme.primary), insets: const EdgeInsets.symmetric(horizontal: 40.0)),
//                   tabs: [
//                     Tab(icon: const Icon(Icons.shopping_cart), text: l10n.purchases),
//                     Tab(icon: const Icon(Icons.payment), text: l10n.payments),
//                   ],
//                 ),
//               ),
//             ];
//           },
//           // --- 4. تعديل محتوى الجسم ---
//           body: TabBarView(
//             controller: _tabController,
//             children: [
//               _buildDebtsTab(l10n),
//               _buildPaymentsTab(l10n),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // --- 5. تعديل تبويب المشتريات ---
//   Widget _buildDebtsTab(AppLocalizations l10n) {
//     final theme = Theme.of(context);
//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       body: FutureBuilder<List<CustomerDebt>>(
//         future: _debtsFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white));
//           if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text(l10n.noPurchases, style: theme.textTheme.bodyLarge));
//           final debts = snapshot.data!;
//           return ListView.builder(
//             padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
//             itemCount: debts.length,
//             itemBuilder: (context, index) {
//               final debt = debts[index];
//               final isReturned = debt.isReturned == 1;
//               return Padding(
//                 padding: const EdgeInsets.only(bottom: 8.0),
//                 child: GlassContainer(
//                   borderRadius: 12,
//                   child: ListTile(
//                     leading: Icon(isReturned ? Icons.undo : Icons.receipt, color: isReturned ? AppColors.textGrey : Colors.blueAccent),
//                     title: Text(debt.details, style: TextStyle(decoration: isReturned ? TextDecoration.lineThrough : TextDecoration.none, color: isReturned ? AppColors.textGrey : null)),
//                     subtitle: Text(DateFormat('yyyy-MM-dd – hh:mm a').format(DateTime.parse(debt.dateT))),
//                     trailing: Text(
//                       formatCurrency(debt.debt),
//                       style: TextStyle(color: isReturned ? AppColors.textGrey : Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold, decoration: isReturned ? TextDecoration.lineThrough : TextDecoration.none),
//                     ),
//                     onLongPress: isReturned || !_authService.isAdmin ? null : () => _handleReturnSale(debt),
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _recordNewSale,
//         backgroundColor: theme.colorScheme.primary,
//         child: const Icon(Icons.add_shopping_cart),
//       ),
//     );
//   }

//   // --- 6. تعديل تبويب الدفعات ---
//   Widget _buildPaymentsTab(AppLocalizations l10n) {
//     final theme = Theme.of(context);
//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       body: FutureBuilder<List<CustomerPayment>>(
//         future: _paymentsFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white));
//           if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text(l10n.noPayments, style: theme.textTheme.bodyLarge));
//           final payments = snapshot.data!;
//           return ListView.builder(
//             padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
//             itemCount: payments.length,
//             itemBuilder: (context, index) {
//               final payment = payments[index];
//               return Padding(
//                 padding: const EdgeInsets.only(bottom: 8.0),
//                 child: GlassContainer(
//                   borderRadius: 12,
//                   child: ListTile(
//                     leading: const Icon(Icons.attach_money, color: Colors.greenAccent),
//                     title: Text(formatCurrency(payment.payment)),
//                     subtitle: Text(DateFormat('yyyy-MM-dd – hh:mm a').format(DateTime.parse(payment.dateT))),
//                     trailing: payment.comments != null && payment.comments!.isNotEmpty
//                         ? IconButton(
//                             icon: const Icon(Icons.comment, color: AppColors.textGrey),
//                             onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.notesOptional}: ${payment.comments}'))),
//                           )
//                         : null,
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _recordNewPayment,
//         backgroundColor: theme.colorScheme.primary,
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }
