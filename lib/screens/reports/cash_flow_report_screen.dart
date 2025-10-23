// // lib/screens/reports/cash_flow_report_screen.dart

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../../data/database_helper.dart';
// import 'package:accounting_app/l10n/app_localizations.dart';
// import '../../utils/helpers.dart';
// import '../../theme/app_colors.dart';
// import '../../widgets/glass_container.dart';
// import '../../widgets/gradient_background.dart';

// class CashFlowReportScreen extends StatefulWidget {
//   const CashFlowReportScreen({super.key});

//   @override
//   State<CashFlowReportScreen> createState() => _CashFlowReportScreenState();
// }

// class _CashFlowReportScreenState extends State<CashFlowReportScreen> {
//   // ... (كل متغيرات الحالة والدوال المنطقية تبقى كما هي)
//   final dbHelper = DatabaseHelper.instance;
//   late Future<List<Map<String, dynamic>>> _transactionsFuture;
//   DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
//   DateTime _endDate = DateTime.now();
//   bool _isDetailsVisible = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }

//   void _loadData() {
//     setState(() {
//       _transactionsFuture = dbHelper.getCashFlowTransactions(startDate: _startDate, endDate: _endDate);
//     });
//   }

//   Future<void> _pickDateRange() async {
//     final newDateRange = await showDateRangePicker(
//       context: context,
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now().add(const Duration(days: 1)),
//       initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
//       // يمكنك تخصيص تصميم أداة اختيار التاريخ هنا لتتناسب مع الثيم
//     );

//     if (newDateRange != null) {
//       setState(() {
//         _startDate = newDateRange.start;
//         _endDate = newDateRange.end;
//       });
//       _loadData();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     final theme = Theme.of(context);

//     return Scaffold(
//       // --- 2. توحيد بنية الصفحة لتتوافق مع التصميم الزجاجي ---
//       backgroundColor: Colors.transparent,
//       extendBodyBehindAppBar: true,
//       body: GradientBackground(
//         child: Column(
//           children: [
//             // --- 3. استخدام AppBar مخصص داخل الجسم ليكون جزءاً من التصميم ---
//             _buildGlassAppBar(l10n, theme),
            
//             // --- قسم الملخصات ---
//             FutureBuilder<List<Map<String, dynamic>>>(
//               future: _transactionsFuture,
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) {
//                   return const Expanded(child: Center(child: CircularProgressIndicator(color: Colors.white)));
//                 }
                
//                 double totalCashSales = 0;
//                 double totalDebtPayments = 0;
//                 for (var trans in snapshot.data!) {
//                   if (trans['type'] == 'CASH_SALE') {
//                     totalCashSales += trans['amount'];
//                   } else if (trans['type'] == 'DEBT_PAYMENT') {
//                     totalDebtPayments += trans['amount'];
//                   }
//                 }
//                 final totalCashIn = totalCashSales + totalDebtPayments;

//                 return Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 12.0),
//                   child: Column(
//                     children: [
//                       // --- 4. تعديل دالة بناء بطاقات الملخص للتصميم الزجاجي ---
//                       _buildSummaryCard(l10n.totalCashSales, totalCashSales, Icons.point_of_sale, Colors.tealAccent),
//                       _buildSummaryCard(l10n.totalDebtPayments, totalDebtPayments, Icons.payments, Colors.lightBlueAccent),
//                       _buildSummaryCard(l10n.totalCashInflow, totalCashIn, Icons.account_balance_wallet, Colors.greenAccent, isTotal: true),
//                     ],
//                   ),
//                 );
//               },
//             ),
//             const Divider(color: AppColors.glassBorderColor, indent: 20, endIndent: 20),
            
//             // --- 5. تعديل زر إظهار/إخفاء التفاصيل ---
//             TextButton.icon(
//               icon: Icon(_isDetailsVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textGrey),
//               label: Text(_isDetailsVisible ? l10n.hideDetails : l10n.showDetails, style: TextStyle(color: AppColors.textGrey)),
//               onPressed: () => setState(() => _isDetailsVisible = !_isDetailsVisible),
//             ),

//             // --- 6. تعديل قائمة المعاملات للتصميم الزجاجي ---
//             if (_isDetailsVisible)
//               Expanded(
//                 child: FutureBuilder<List<Map<String, dynamic>>>(
//                   future: _transactionsFuture,
//                   builder: (context, snapshot) {
//                     if (snapshot.connectionState == ConnectionState.waiting) {
//                       return const Center(child: CircularProgressIndicator(color: Colors.white));
//                     }
//                     if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                       return Center(child: Text(l10n.noTransactions, style: theme.textTheme.bodyLarge));
//                     }

//                     final transactions = snapshot.data!;
//                     return ListView.builder(
//                       padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
//                       itemCount: transactions.length,
//                       itemBuilder: (context, index) {
//                         final trans = transactions[index];
//                         final isCashSale = trans['type'] == 'CASH_SALE';
//                         final description = isCashSale
//                             ? l10n.cashSaleDescription(trans['id'].toString())
//                             : l10n.debtPaymentDescription(trans['description'].toString().replaceFirst('تسديد من الزبون: ', ''));

//                         // استخدام GlassContainer لكل عنصر في القائمة
//                         return Padding(
//                           padding: const EdgeInsets.only(bottom: 8.0),
//                           child: GlassContainer(
//                             borderRadius: 12,
//                             child: ListTile(
//                               leading: Icon(
//                                 isCashSale ? Icons.point_of_sale : Icons.payments,
//                                 color: isCashSale ? Colors.tealAccent : Colors.lightBlueAccent,
//                               ),
//                               title: Text(description, style: theme.textTheme.bodyMedium),
//                               subtitle: Text(DateFormat('yyyy-MM-dd').format(DateTime.parse(trans['date'])), style: theme.textTheme.bodySmall),
//                               trailing: Text(
//                                 '+ ${formatCurrency(trans['amount'])}',
//                                 style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16),
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ويدجت مخصصة لبناء شريط العنوان الزجاجي
//   Widget _buildGlassAppBar(AppLocalizations l10n, ThemeData theme) {
//     return GlassContainer(
//       borderRadius: 0,
//       child: AppBar(
//         title: Text(l10n.cashFlowReport),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.date_range),
//             onPressed: _pickDateRange,
//             tooltip: l10n.selectDateRange,
//           ),
//         ],
//       ),
//     );
//   }

//   // دالة بناء بطاقات الملخص المعدلة
//   Widget _buildSummaryCard(String title, double amount, IconData icon, Color color, {bool isTotal = false}) {
//     final theme = Theme.of(context);
//     return Padding(
//       padding: const EdgeInsets.only(top: 8.0),
//       child: GlassContainer(
//         borderRadius: 15,
//         // إضافة تأثير إضافي للبطاقة الإجمالية
//         child: Container(
//           decoration: isTotal ? BoxDecoration(
//             borderRadius: BorderRadius.circular(15),
//             gradient: LinearGradient(
//               colors: [color.withOpacity(0.3), Colors.transparent],
//               begin: Alignment.centerLeft,
//               end: Alignment.centerRight,
//             )
//           ) : null,
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Row(
//                   children: [
//                     Icon(icon, color: color, size: 28),
//                     const SizedBox(width: 12),
//                     Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
//                   ],
//                 ),
//                 Text(
//                   formatCurrency(amount),
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
