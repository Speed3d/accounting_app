// // lib/screens/sales/invoice_details_screen.dart

// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../../data/database_helper.dart';
// import '../../data/models.dart';
// import '../../l10n/app_localizations.dart';
// import '../../services/auth_service.dart';
// import '../../utils/helpers.dart';
// import '../../theme/app_colors.dart';
// import '../../widgets/glass_container.dart';
// import '../../widgets/gradient_background.dart';

// class InvoiceDetailsScreen extends StatefulWidget {
//   final int invoiceId;
//   const InvoiceDetailsScreen({super.key, required this.invoiceId});

//   @override
//   State<InvoiceDetailsScreen> createState() => _InvoiceDetailsScreenState();
// }

// class _InvoiceDetailsScreenState extends State<InvoiceDetailsScreen> {
//   // ... (كل متغيرات الحالة والدوال المنطقية تبقى كما هي)
//   final dbHelper = DatabaseHelper.instance;
//   final AuthService _authService = AuthService();
//   late Future<List<CustomerDebt>> _salesFuture;
//   bool _hasChanged = false;

//   @override
//   void initState() {
//     super.initState();
//     _salesFuture = dbHelper.getSalesForInvoice(widget.invoiceId);
//   }

//   // --- 2. تعديل مربع حوار تأكيد الإرجاع ---
//   // الشرح: تم تغليف AlertDialog بـ BackdropFilter وتعديل خصائصه ليتناسب مع التصميم الزجاجي.
//   Future<void> _handleReturnSale(CustomerDebt sale) async {
//     final l10n = AppLocalizations.of(context)!;
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (ctx) => BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
//         child: AlertDialog(
//           backgroundColor: AppColors.glassBgColor.withOpacity(0.9),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.glassBorderColor)),
//           title: Text(l10n.returnConfirmTitle),
//           content: Text(l10n.returnConfirmContent(sale.details)),
//           actions: [
//             TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancel, style: TextStyle(color: AppColors.textGrey))),
//             TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.returnItem, style: const TextStyle(color: Colors.redAccent))),
//           ],
//         ),
//       ),
//     );
//     if (confirm != true) return;
//     try {
//       await dbHelper.returnSaleItem(sale);
//       await dbHelper.updateInvoiceStatus(widget.invoiceId, 'معدلة');
//       await dbHelper.logActivity('إرجاع منتج من فاتورة نقدية #${widget.invoiceId}: ${sale.details}', userId: _authService.currentUser?.id, userName: _authService.currentUser?.fullName);
//       setState(() {
//         _hasChanged = true;
//         _salesFuture = dbHelper.getSalesForInvoice(widget.invoiceId);
//       });
//       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.returnSuccess), backgroundColor: Colors.green));
//     } catch (e) {
//       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorOccurred(e.toString())), backgroundColor: Colors.red));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     final theme = Theme.of(context);

//     return WillPopScope(
//       onWillPop: () async {
//         Navigator.of(context).pop(_hasChanged);
//         return true;
//       },
//       child: Scaffold(
//         // --- 3. توحيد بنية الصفحة ---
//         // الشرح: نجعل Scaffold شفافاً ونضع الخلفية المتدرجة في Container.
//         backgroundColor: Colors.transparent,
//         extendBodyBehindAppBar: true,
//         appBar: AppBar(
//           title: Text("تفاصيل الفاتورة #${widget.invoiceId}"),
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//         ),
//         body: GradientBackground(
//           child: SafeArea(
//             child: FutureBuilder<List<CustomerDebt>>(
//               future: _salesFuture,
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator(color: Colors.white));
//                 }
//                 if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                   return Center(child: Text("لا توجد بنود في هذه الفاتورة.", style: theme.textTheme.bodyLarge));
//                 }
//                 final sales = snapshot.data!;
//                 // --- 4. تعديل تصميم القائمة ---
//                 // الشرح: نستخدم ListView.builder لعرض البيانات، ونغلف كل عنصر بـ GlassContainer.
//                 return ListView.builder(
//                   padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
//                   itemCount: sales.length,
//                   itemBuilder: (context, index) {
//                     final sale = sales[index];
//                     final isReturned = sale.isReturned == 1;
//                     return Padding(
//                       padding: const EdgeInsets.only(bottom: 8.0),
//                       child: GlassContainer(
//                         borderRadius: 15,
//                         color: isReturned ? AppColors.glassBgColor.withOpacity(0.1) : AppColors.glassBgColor,
//                         child: ListTile(
//                           leading: Icon(isReturned ? Icons.undo : Icons.receipt_long, color: isReturned ? AppColors.textGrey : AppColors.accentBlue),
//                           title: Text(sale.details, style: TextStyle(decoration: isReturned ? TextDecoration.lineThrough : null, color: isReturned ? AppColors.textGrey : null)),
//                           subtitle: Text(DateFormat('yyyy-MM-dd').format(DateTime.parse(sale.dateT))),
//                           trailing: Text(
//                             formatCurrency(sale.debt),
//                             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isReturned ? AppColors.textGrey : Colors.redAccent, decoration: isReturned ? TextDecoration.lineThrough : null),
//                           ),
//                           onLongPress: isReturned ? null : () => _handleReturnSale(sale),
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
