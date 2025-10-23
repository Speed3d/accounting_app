// // lib/screens/reports/profit_report_screen.dart

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../../data/database_helper.dart';
// import '../../data/models.dart';
// import '../../utils/helpers.dart';
// import 'package:accounting_app/l10n/app_localizations.dart';
// import '../../theme/app_colors.dart';
// import '../../widgets/glass_container.dart';
// import '../../widgets/gradient_background.dart';

// class ProfitReportScreen extends StatefulWidget {
//   const ProfitReportScreen({super.key});
//   @override
//   State<ProfitReportScreen> createState() => _ProfitReportScreenState();
// }

// class _ProfitReportScreenState extends State<ProfitReportScreen> {
//   // ... (كل متغيرات الحالة والدوال المنطقية تبقى كما هي)
//   final dbHelper = DatabaseHelper.instance;
//   late Future<FinancialSummary> _summaryFuture;
//   bool _isDetailsVisible = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadFinancialSummary();
//   }

//   void _loadFinancialSummary() {
//     setState(() {
//       _summaryFuture = _getFinancialSummary();
//     });
//   }

//   Future<FinancialSummary> _getFinancialSummary() async {
//     final results = await Future.wait([
//       dbHelper.getTotalProfit(),
//       dbHelper.getTotalExpenses(),
//       dbHelper.getTotalAllProfitWithdrawals(),
//       dbHelper.getAllSales(),
//     ]);
//     return FinancialSummary(grossProfit: results[0] as double, totalExpenses: results[1] as double, totalWithdrawals: results[2] as double, sales: results[3] as List<CustomerDebt>);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     final theme = Theme.of(context);

//     return Scaffold(
//       // --- 2. توحيد بنية الصفحة ---
//       // الشرح: نجعل Scaffold شفافاً ونضع الخلفية المتدرجة في Container
//       // ليغطي الشاشة بأكملها، مما يضمن ظهور التأثير الزجاجي بشكل صحيح.
//       backgroundColor: Colors.transparent,
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         title: Text(l10n.generalProfitReport),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         actions: [
//           IconButton(icon: const Icon(Icons.refresh), onPressed: _loadFinancialSummary, tooltip: l10n.refresh),
//         ],
//       ),
//       body: GradientBackground(
//         child: SafeArea(
//           child: FutureBuilder<FinancialSummary>(
//             future: _summaryFuture,
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator(color: Colors.white));
//               }
//               if (snapshot.hasError) {
//                 return Center(child: Text(l10n.errorOccurred(snapshot.error.toString()), style: theme.textTheme.bodyLarge));
//               }
//               if (!snapshot.hasData) {
//                 return Center(child: Text(l10n.noDataToShow, style: theme.textTheme.bodyLarge));
//               }

//               final summary = snapshot.data!;
//               final netProfit = summary.grossProfit - summary.totalExpenses - summary.totalWithdrawals;

//               return Column(
//                 children: [
//                   // --- 3. تعديل بطاقة الملخص المالي ---
//                   // الشرح: نمرر البيانات إلى دالة بناء البطاقة الزجاجية.
//                   _buildFinancialSummaryCard(l10n, summary, netProfit),
//                   const Divider(color: AppColors.glassBorderColor, indent: 20, endIndent: 20),
                  
//                   // --- 4. تعديل زر إظهار/إخفاء التفاصيل ---
//                   TextButton.icon(
//                     icon: Icon(_isDetailsVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textGrey),
//                     label: Text(_isDetailsVisible ? l10n.hideSalesDetails : l10n.showSalesDetails, style: TextStyle(color: AppColors.textGrey)),
//                     onPressed: () => setState(() => _isDetailsVisible = !_isDetailsVisible),
//                   ),

//                   // --- 5. تعديل قائمة تفاصيل المبيعات ---
//                   if (_isDetailsVisible)
//                     Expanded(
//                       child: _buildSalesList(l10n, summary.sales),
//                     ),
//                 ],
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   // --- 6. تعديل دالة بناء بطاقة الملخص المالي ---
//   // الشرح: نستبدل Card بـ GlassContainer ونعدل الألوان لتكون أكثر إشراقاً.
//   Widget _buildFinancialSummaryCard(AppLocalizations l10n, FinancialSummary summary, double netProfit) {
//     return GlassContainer(
//       borderRadius: 15,
//       margin: const EdgeInsets.all(12.0),
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         children: [
//           _buildSummaryRow(l10n.grossProfitFromSales, summary.grossProfit, Colors.blueAccent),
//           const SizedBox(height: 8),
//           _buildSummaryRow(l10n.totalGeneralExpenses, summary.totalExpenses, Colors.redAccent),
//           const SizedBox(height: 8),
//           _buildSummaryRow(l10n.totalProfitWithdrawals, summary.totalWithdrawals, Colors.orangeAccent),
//           const Divider(height: 20, thickness: 0.5, color: AppColors.glassBorderColor),
//           _buildSummaryRow(l10n.netProfit, netProfit, Colors.greenAccent, isTotal: true),
//         ],
//       ),
//     );
//   }

//   Widget _buildSummaryRow(String title, double amount, Color color, {bool isTotal = false}) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(title, style: TextStyle(fontSize: 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
//         Text(formatCurrency(amount), style: TextStyle(fontSize: isTotal ? 22 : 18, fontWeight: FontWeight.bold, color: color)),
//       ],
//     );
//   }

//   // --- 7. تعديل دالة بناء قائمة تفاصيل المبيعات ---
//   // الشرح: نغلف كل عنصر في القائمة بـ GlassContainer.
//   Widget _buildSalesList(AppLocalizations l10n, List<CustomerDebt> sales) {
//     if (sales.isEmpty) {
//       return Center(child: Text(l10n.noSalesRecorded, style: Theme.of(context).textTheme.bodyLarge));
//     }
//     return ListView.builder(
//       padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
//       itemCount: sales.length,
//       itemBuilder: (context, index) {
//         final sale = sales[index];
//         return Padding(
//           padding: const EdgeInsets.only(bottom: 8.0),
//           child: GlassContainer(
//             borderRadius: 12,
//             child: ListTile(
//               leading: const CircleAvatar(
//                 backgroundColor: AppColors.primaryPurple,
//                 child: Icon(Icons.receipt, color: AppColors.accentBlue),
//               ),
//               title: Text(sale.details),
//               subtitle: Text('${l10n.customerLabel(sale.customerName ?? l10n.unregistered)} | ${l10n.dateLabel(DateFormat('yyyy-MM-dd').format(DateTime.parse(sale.dateT)))}'),
//               trailing: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   Text(l10n.profitLabel(formatCurrency(sale.profitAmount)), style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
//                   Text(l10n.saleLabel(formatCurrency(sale.debt)), style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// class FinancialSummary {
//   final double grossProfit;
//   final double totalExpenses;
//   final double totalWithdrawals;
//   final List<CustomerDebt> sales;
//   FinancialSummary({required this.grossProfit, required this.totalExpenses, required this.totalWithdrawals, required this.sales});
// }
