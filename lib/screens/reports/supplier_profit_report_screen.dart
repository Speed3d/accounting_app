// // lib/screens/reports/supplier_profit_report_screen.dart

// import 'package:flutter/material.dart';
// import '../../data/database_helper.dart';
// import '../../data/models.dart';
// import 'package:accounting_app/l10n/app_localizations.dart';
// import '../../utils/helpers.dart';
// import '../../widgets/gradient_background.dart';
// import 'supplier_details_report_screen.dart';
// import '../../theme/app_colors.dart';
// import '../../widgets/glass_container.dart';

// class SupplierProfitReportScreen extends StatefulWidget {
//   const SupplierProfitReportScreen({super.key});

//   @override
//   State<SupplierProfitReportScreen> createState() => _SupplierProfitReportScreenState();
// }

// class _SupplierProfitReportScreenState extends State<SupplierProfitReportScreen> {
//   // ... (كل متغيرات الحالة والدوال المنطقية تبقى كما هي)
//   final dbHelper = DatabaseHelper.instance;
//   late Future<List<SupplierProfitData>> _reportDataFuture;

//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }

//   void _loadData() {
//     setState(() {
//       _reportDataFuture = _getReportData();
//     });
//   }

//   Future<List<SupplierProfitData>> _getReportData() async {
//     final profits = await dbHelper.getProfitBySupplier();
//     final List<SupplierProfitData> reportData = [];
//     for (var profitItem in profits) {
//       final supplierId = profitItem['SupplierID'];
//       final supplierType = profitItem['SupplierType'];
//       final totalWithdrawn = await dbHelper.getTotalWithdrawnForSupplier(supplierId);
//       List<Partner> partners = [];
//       if (supplierType == 'شراكة') {
//         partners = await dbHelper.getPartnersForSupplier(supplierId);
//       }
//       reportData.add(SupplierProfitData(supplierId: supplierId, supplierName: profitItem['SupplierName'], supplierType: supplierType, totalProfit: profitItem['TotalProfit'], totalWithdrawn: totalWithdrawn, partners: partners));
//     }
//     return reportData;
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
//         title: Text(l10n.supplierProfitReport),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//       ),
//       body: GradientBackground(
//         child: SafeArea(
//           child: FutureBuilder<List<SupplierProfitData>>(
//             future: _reportDataFuture,
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator(color: Colors.white));
//               }
//               if (snapshot.hasError) {
//                 return Center(child: Text(l10n.errorOccurred(snapshot.error.toString()), style: theme.textTheme.bodyLarge));
//               }
//               if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                 return Center(child: Text(l10n.noProfitsRecorded, style: theme.textTheme.bodyLarge));
//               }

//               final reportDataList = snapshot.data!;
//               // --- 3. تعديل تصميم القائمة ---
//               // الشرح: نستخدم ListView.builder لعرض البيانات، ونغلف كل عنصر بـ GlassContainer.
//               return ListView.builder(
//                 padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
//                 itemCount: reportDataList.length,
//                 itemBuilder: (context, index) {
//                   final data = reportDataList[index];
//                   final netProfit = data.totalProfit - data.totalWithdrawn;

//                   Widget subtitleWidget;
//                   if (data.supplierType == 'شراكة' && data.partners.isNotEmpty) {
//                     final partnerNames = data.partners.map((p) => p.partnerName).join('، ');
//                     subtitleWidget = Text(l10n.partnersLabel(partnerNames), style: TextStyle(fontSize: 12, color: AppColors.textGrey));
//                   } else {
//                     subtitleWidget = Text(l10n.typeLabel(l10n.individual), style: TextStyle(color: AppColors.textGrey));
//                   }

//                   return Padding(
//                     padding: const EdgeInsets.only(bottom: 8.0),
//                     child: GlassContainer(
//                       borderRadius: 15,
//                       child: ListTile(
//                         leading: CircleAvatar(
//                           backgroundColor: data.supplierType == 'شراكة' ? AppColors.primaryPurple : AppColors.accentBlue.withOpacity(0.5),
//                           child: const Icon(Icons.business, color: Colors.white),
//                         ),
//                         title: Text(data.supplierName, style: const TextStyle(fontWeight: FontWeight.bold)),
//                         subtitle: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             subtitleWidget,
//                             Text(
//                               l10n.netProfitLabel(formatCurrency(netProfit)),
//                               style: TextStyle(color: netProfit >= 0 ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold),
//                             ),
//                           ],
//                         ),
//                         trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.textGrey),
//                         onTap: () async {
//                           await Navigator.of(context).push(
//                             MaterialPageRoute(
//                               builder: (context) => SupplierDetailsReportScreen(
//                                 supplierId: data.supplierId,
//                                 supplierName: data.supplierName,
//                                 supplierType: data.supplierType,
//                                 totalProfit: data.totalProfit,
//                                 totalWithdrawn: data.totalWithdrawn,
//                               ),
//                             ),
//                           );
//                           _loadData();
//                         },
//                       ),
//                     ),
//                   );
//                 },
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }

// class SupplierProfitData {
//   // ... (الكلاس المساعد يبقى كما هو)
//   final int supplierId;
//   final String supplierName;
//   final String supplierType;
//   final double totalProfit;
//   final double totalWithdrawn;
//   final List<Partner> partners;
//   SupplierProfitData({required this.supplierId, required this.supplierName, required this.supplierType, required this.totalProfit, required this.totalWithdrawn, required this.partners});
// }
