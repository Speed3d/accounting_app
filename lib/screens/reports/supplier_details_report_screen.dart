// // lib/screens/reports/supplier_details_report_screen.dart

// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../../data/database_helper.dart';
// import '../../data/models.dart';
// import 'package:accounting_app/l10n/app_localizations.dart';
// import '../../utils/helpers.dart';
// import '../../theme/app_colors.dart';
// import '../../widgets/glass_container.dart';
// import '../../widgets/gradient_background.dart';

// class SupplierDetailsReportScreen extends StatefulWidget {

//   final int supplierId;
//   final String supplierName;
//   final String supplierType;
//   final double totalProfit;
//   final double totalWithdrawn;

//   const SupplierDetailsReportScreen({super.key, required this.supplierId, required this.supplierName, required this.supplierType, required this.totalProfit, required this.totalWithdrawn});

//   @override
//   State<SupplierDetailsReportScreen> createState() => _SupplierDetailsReportScreenState();
// }

// class _SupplierDetailsReportScreenState extends State<SupplierDetailsReportScreen> {
//   // ... (كل متغيرات الحالة والدوال المنطقية تبقى كما هي)
//   final dbHelper = DatabaseHelper.instance;
//   late Future<List<Partner>> _partnersFuture;
//   late Future<List<Map<String, dynamic>>> _withdrawalsFuture;
//   late double _currentTotalWithdrawn;

//   @override
//   void initState() {
//     super.initState();
//     _currentTotalWithdrawn = widget.totalWithdrawn;
//     _loadData();
//   }

//   void _loadData() {
//     if (widget.supplierType == 'شراكة') {
//       _partnersFuture = dbHelper.getPartnersForSupplier(widget.supplierId);
//     }
//     _withdrawalsFuture = dbHelper.getWithdrawalsForSupplier(widget.supplierId);
//   }

//   // --- 2. تعديل مربع حوار تسجيل السحب ---
//   // الشرح: تم تغليف AlertDialog بـ BackdropFilter وتعديل خصائصه ليتناسب مع التصميم الزجاجي.
//   void _showRecordWithdrawalDialog(AppLocalizations l10n, {String? partnerName}) {
//     final amountController = TextEditingController();
//     final notesController = TextEditingController();
//     final formKey = GlobalKey<FormState>();
//     final netProfit = widget.totalProfit - _currentTotalWithdrawn;

//     showDialog(
//       context: context,
//       builder: (ctx) => BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
//         child: AlertDialog(
//           backgroundColor: AppColors.glassBgColor.withOpacity(0.9),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.glassBorderColor)),
//           title: Text(l10n.recordWithdrawalFor(partnerName ?? widget.supplierName)),
//           content: Form(
//             key: formKey,
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(l10n.availableNetProfit(formatCurrency(netProfit)), style: TextStyle(color: netProfit >= 0 ? Colors.greenAccent : Colors.redAccent)),
//                 TextFormField(controller: amountController, decoration: InputDecoration(labelText: l10n.withdrawnAmount), keyboardType: TextInputType.number, validator: (v) {
//                   if (v == null || v.isEmpty) return l10n.amountRequired;
//                   final amount = double.tryParse(convertArabicNumbersToEnglish(v));
//                   if (amount == null || amount <= 0) return l10n.enterValidNumber;
//                   if (amount > netProfit) return l10n.amountExceedsProfit;
//                   return null;
//                 }),
//                 TextFormField(controller: notesController, decoration: InputDecoration(labelText: l10n.notesOptional)),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.cancel, style: TextStyle(color: AppColors.textGrey))),
//             ElevatedButton(
//               onPressed: () async {
//                 if (formKey.currentState!.validate()) {
//                   final data = {'SupplierID': widget.supplierId, 'PartnerName': partnerName, 'WithdrawalAmount': double.parse(convertArabicNumbersToEnglish(amountController.text)), 'WithdrawalDate': DateTime.now().toIso8601String(), 'Notes': notesController.text};
//                   await dbHelper.recordProfitWithdrawal(data);
//                   Navigator.of(ctx).pop();
//                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.withdrawalSuccess), backgroundColor: Colors.green));
//                   setState(() {
//                     _currentTotalWithdrawn += data['WithdrawalAmount'] as double;
//                     _loadData();
//                   });
//                 }
//               },
//               child: Text(l10n.save),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     final netProfit = widget.totalProfit - _currentTotalWithdrawn;

//     return Scaffold(
//       // --- 3. توحيد بنية الصفحة ---
//       // الشرح: نجعل Scaffold شفافاً ونضع الخلفية المتدرجة في Container.
//       backgroundColor: Colors.transparent,
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         title: Text(widget.supplierName),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//       ),
//       body: GradientBackground(
//         child: SafeArea(
//           child: ListView(
//             padding: const EdgeInsets.fromLTRB(0, 8, 0, 80),
//             children: [
//               _buildFinancialSummaryCard(l10n, netProfit),
//               if (widget.supplierType == 'شراكة') _buildPartnersProfitSection(l10n, netProfit),
//               const Divider(color: AppColors.glassBorderColor, indent: 20, endIndent: 20, height: 20),
//               _buildWithdrawalsHistorySection(l10n),
//             ],
//           ),
//         ),
//       ),
//       // --- 4. تعديل تصميم الزر العائم ---
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () => _showRecordWithdrawalDialog(l10n),
//         label: Text(l10n.recordGeneralWithdrawal),
//         icon: const Icon(Icons.arrow_downward),
//         backgroundColor: Theme.of(context).colorScheme.primary,
//       ),
//     );
//   }

//   // --- 5. تعديل دالة بناء بطاقة الملخص المالي ---
//   // الشرح: نستبدل Card بـ GlassContainer ونعدل الألوان لتكون أكثر إشراقاً.
//   Widget _buildFinancialSummaryCard(AppLocalizations l10n, double netProfit) {
//     return GlassContainer(
//       borderRadius: 15,
//       margin: const EdgeInsets.all(12.0),
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         children: [
//           _buildSummaryRow(l10n.totalProfitFromSupplier, widget.totalProfit, Colors.blueAccent),
//           _buildSummaryRow(l10n.totalWithdrawals, _currentTotalWithdrawn, Colors.redAccent),
//           const Divider(height: 20, thickness: 0.5, color: AppColors.glassBorderColor),
//           _buildSummaryRow(l10n.remainingNetProfit, netProfit, Colors.greenAccent, isTotal: true),
//         ],
//       ),
//     );
//   }

//   Widget _buildSummaryRow(String title, double amount, Color color, {bool isTotal = false}) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(title, style: TextStyle(fontSize: 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
//         Text(formatCurrency(amount), style: TextStyle(fontSize: isTotal ? 20 : 18, fontWeight: FontWeight.bold, color: color)),
//       ],
//     );
//   }

//   // --- 6. تعديل دالة بناء قسم أرباح الشركاء ---
//   // الشرح: نغلف كل ListTile بـ GlassContainer ونعدل تصميم زر السحب.
//   Widget _buildPartnersProfitSection(AppLocalizations l10n, double netProfit) {
//     return FutureBuilder<List<Partner>>(
//       future: _partnersFuture,
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) return const SizedBox.shrink();
//         final partners = snapshot.data!;
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               child: Text(l10n.partnersProfitDistribution, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             ),
//             ...partners.map((partner) {
//               final partnerShare = netProfit * (partner.sharePercentage / 100);
//               return Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//                 child: GlassContainer(
//                   borderRadius: 12,
//                   child: ListTile(
//                     leading: const Icon(Icons.person, color: AppColors.accentBlue),
//                     title: Text(partner.partnerName),
//                     subtitle: Text(l10n.partnerShare(formatCurrency(partnerShare))),
//                     trailing: ElevatedButton(
//                       onPressed: () => _showRecordWithdrawalDialog(l10n, partnerName: partner.partnerName),
//                       style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentBlue.withOpacity(0.2), foregroundColor: AppColors.accentBlue, elevation: 0),
//                       child: Text(l10n.withdraw),
//                     ),
//                   ),
//                 ),
//               );
//             }).toList(),
//           ],
//         );
//       },
//     );
//   }

//   // --- 7. تعديل دالة بناء قسم سجل المسحوبات ---
//   // الشرح: نغلف كل ListTile بـ GlassContainer.
//   Widget _buildWithdrawalsHistorySection(AppLocalizations l10n) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//           child: Text(l10n.withdrawalsHistory, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//         ),
//         FutureBuilder<List<Map<String, dynamic>>>(
//           future: _withdrawalsFuture,
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white));
//             if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(l10n.noWithdrawals, style: Theme.of(context).textTheme.bodyLarge)));
//             final withdrawals = snapshot.data!;
//             return ListView.builder(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               itemCount: withdrawals.length,
//               itemBuilder: (context, index) {
//                 final item = withdrawals[index];
//                 return Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//                   child: GlassContainer(
//                     borderRadius: 12,
//                     child: ListTile(
//                       leading: const Icon(Icons.arrow_upward, color: Colors.redAccent),
//                       title: Text(l10n.withdrawalAmountLabel(formatCurrency(item['WithdrawalAmount']))),
//                       subtitle: Text(l10n.withdrawalForLabel(item['PartnerName'] ?? widget.supplierName)),
//                       trailing: Text(DateFormat('yyyy-MM-dd').format(DateTime.parse(item['WithdrawalDate']))),
//                     ),
//                   ),
//                 );
//               },
//             );
//           },
//         ),
//       ],
//     );
//   }
// }
