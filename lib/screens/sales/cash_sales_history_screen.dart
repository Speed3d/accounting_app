// // lib/screens/sales/cash_sales_history_screen.dart

// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../../data/database_helper.dart';
// import 'package:accounting_app/l10n/app_localizations.dart';
// import '../../utils/helpers.dart';
// import '../../widgets/gradient_background.dart';
// import 'invoice_details_screen.dart';
// import '../../theme/app_colors.dart';
// import '../../widgets/glass_container.dart';

// class CashSalesHistoryScreen extends StatefulWidget {
//   const CashSalesHistoryScreen({super.key});

//   @override
//   State<CashSalesHistoryScreen> createState() => _CashSalesHistoryScreenState();
// }

// class _CashSalesHistoryScreenState extends State<CashSalesHistoryScreen> {
//   // ... (كل متغيرات الحالة والدوال المنطقية تبقى كما هي)
//   final dbHelper = DatabaseHelper.instance;
//   late Future<List<Map<String, dynamic>>> _invoicesFuture;
//   final _searchController = TextEditingController();
//   String _searchQuery = '';
//   bool _isDetailsVisible = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadInvoices();
//     _searchController.addListener(() {
//       setState(() => _searchQuery = _searchController.text);
//     });
//   }

//   void _loadInvoices() {
//     setState(() {
//       _invoicesFuture = dbHelper.getCashInvoices();
//     });
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   // --- 2. تعديل مربع حوار إلغاء الفاتورة ---
//   // الشرح: تم تغليف AlertDialog بـ BackdropFilter وتعديل خصائصه ليتناسب مع التصميم الزجاجي.
//   Future<void> _handleVoidInvoice(int invoiceId, AppLocalizations l10n) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (ctx) => BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
//         child: AlertDialog(
//           backgroundColor: AppColors.glassBgColor.withOpacity(0.9),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.glassBorderColor)),
//           title: Text(l10n.confirmVoidTitle),
//           content: Text(l10n.confirmVoidContent),
//           actions: [
//             TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancel, style: TextStyle(color: AppColors.textGrey))),
//             TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.confirmVoidAction, style: const TextStyle(color: Colors.redAccent))),
//           ],
//         ),
//       ),
//     );
//     if (confirm != true) return;
//     try {
//       await dbHelper.voidInvoice(invoiceId);
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.voidSuccess), backgroundColor: Colors.green));
//       _loadInvoices();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorOccurred(e.toString())), backgroundColor: Colors.red));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     final theme = Theme.of(context);

//     return Scaffold(
//       // --- 3. توحيد بنية الصفحة ---
//       // الشرح: نجعل Scaffold شفافاً ونضع الخلفية المتدرجة في Container.
//       backgroundColor: Colors.transparent,
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         title: Text(l10n.cashSalesHistory),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//       ),
//       body: GradientBackground(
//         child: SafeArea(
//           child: Column(
//             children: [
//               // --- 4. تعديل تصميم حقل البحث ---
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
//                 child: TextField(
//                   controller: _searchController,
//                   decoration: InputDecoration(
//                     hintText: l10n.searchByInvoiceNumber,
//                     prefixIcon: const Icon(Icons.search, color: AppColors.textGrey),
//                     filled: true,
//                     fillColor: AppColors.glassBgColor,
//                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.glassBorderColor, width: 1.5)),
//                     enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.glassBorderColor, width: 1.5)),
//                     focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
//                   ),
//                   keyboardType: TextInputType.number,
//                 ),
//               ),
              
//               // --- 5. تعديل زر إظهار/إخفاء التفاصيل ---
//               TextButton.icon(
//                 icon: Icon(_isDetailsVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textGrey),
//                 label: Text(_isDetailsVisible ? l10n.hideInvoices : l10n.showInvoices, style: TextStyle(color: AppColors.textGrey)),
//                 onPressed: () => setState(() => _isDetailsVisible = !_isDetailsVisible),
//               ),

//               if (_isDetailsVisible)
//                 Expanded(
//                   child: FutureBuilder<List<Map<String, dynamic>>>(
//                     future: _invoicesFuture,
//                     builder: (context, snapshot) {
//                       if (snapshot.connectionState == ConnectionState.waiting) {
//                         return const Center(child: CircularProgressIndicator(color: Colors.white));
//                       }
//                       if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                         return Center(child: Text(l10n.noCashInvoices, style: theme.textTheme.bodyLarge));
//                       }
//                       final filteredInvoices = snapshot.data!.where((i) => i['InvoiceID'].toString().contains(convertArabicNumbersToEnglish(_searchQuery))).toList();
//                       if (filteredInvoices.isEmpty) {
//                         return Center(child: Text(l10n.noMatchingResults, style: theme.textTheme.bodyLarge));
//                       }
//                       // --- 6. تعديل تصميم القائمة ---
//                       // الشرح: نستخدم ListView.builder لعرض البيانات، ونغلف كل عنصر بـ GlassContainer.
//                       return ListView.builder(
//                         padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
//                         itemCount: filteredInvoices.length,
//                         itemBuilder: (context, index) {
//                           final invoice = filteredInvoices[index];
//                           final isVoid = invoice['IsVoid'] == 1;
//                           final status = invoice['Status'] as String?;
//                           final titleStyle = TextStyle(fontWeight: FontWeight.bold, decoration: isVoid ? TextDecoration.lineThrough : null, color: isVoid ? AppColors.textGrey : null);
//                           final trailingStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isVoid ? AppColors.textGrey : Colors.greenAccent, decoration: isVoid ? TextDecoration.lineThrough : null);

//                           return Padding(
//                             padding: const EdgeInsets.only(bottom: 8.0),
//                             child: GlassContainer(
//                               borderRadius: 15,
//                               color: isVoid ? AppColors.glassBgColor.withOpacity(0.1) : AppColors.glassBgColor,
//                               child: ListTile(
//                                 leading: CircleAvatar(
//                                   backgroundColor: isVoid ? AppColors.primaryPurple.withOpacity(0.3) : AppColors.accentBlue.withOpacity(0.3),
//                                   child: Text('#${invoice['InvoiceID']}', style: TextStyle(fontWeight: FontWeight.bold, color: isVoid ? AppColors.textGrey : Colors.white)),
//                                 ),
//                                 title: Row(
//                                   children: [
//                                     Text(l10n.invoiceNo(invoice['InvoiceID'].toString()), style: titleStyle),
//                                     if (status == 'معدلة' && !isVoid) ...[const SizedBox(width: 8), Tooltip(message: l10n.modified, child: const Icon(Icons.edit, size: 16, color: Colors.orangeAccent))],
//                                     if (isVoid) ...[const SizedBox(width: 8), Tooltip(message: l10n.voided, child: const Icon(Icons.delete_forever, size: 16, color: Colors.redAccent))]
//                                   ],
//                                 ),
//                                 subtitle: Text(DateFormat('yyyy-MM-dd – hh:mm a').format(DateTime.parse(invoice['InvoiceDate']))),
//                                 trailing: Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     Text(formatCurrency(invoice['TotalAmount']), style: trailingStyle),
//                                     if (!isVoid) IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _handleVoidInvoice(invoice['InvoiceID'], l10n)),
//                                   ],
//                                 ),
//                                 onTap: () async {
//                                   final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => InvoiceDetailsScreen(invoiceId: invoice['InvoiceID'])));
//                                   if (result == true) _loadInvoices();
//                                 },
//                               ),
//                             ),
//                           );
//                         },
//                       );
//                     },
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
