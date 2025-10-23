// // lib/screens/reports/expenses_screen.dart

// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../../data/database_helper.dart';
// import '../../utils/helpers.dart';
// import '../../widgets/gradient_background.dart';
// import 'manage_categories_screen.dart';
// import 'package:accounting_app/l10n/app_localizations.dart';
// import '../../theme/app_colors.dart';
// import '../../widgets/glass_container.dart';

// class ExpensesScreen extends StatefulWidget {
//   const ExpensesScreen({super.key});
//   @override
//   State<ExpensesScreen> createState() => _ExpensesScreenState();
// }

// class _ExpensesScreenState extends State<ExpensesScreen> {
//   // ... (كل متغيرات الحالة والدوال المنطقية تبقى كما هي)
//   final dbHelper = DatabaseHelper.instance;
//   late Future<List<Map<String, dynamic>>> _expensesFuture;

//   @override
//   void initState() {
//     super.initState();
//     _loadExpenses();
//   }

//   void _loadExpenses() {
//     setState(() {
//       _expensesFuture = dbHelper.getExpenses();
//     });
//   }

//   // --- 2. تعديل مربع الحوار للتصميم الزجاجي ---
//   void _showAddExpenseDialog(AppLocalizations l10n) async {
//     final categories = await dbHelper.getExpenseCategories();
//     final categoryNames = categories.map((cat) => cat['CategoryName'] as String).toList();

//     if (!mounted) return;

//     final formKey = GlobalKey<FormState>();
//     final descriptionController = TextEditingController();
//     final amountController = TextEditingController();
//     final notesController = TextEditingController();
//     String? selectedCategory = categoryNames.isNotEmpty ? categoryNames.first : null;

//     showDialog(
//       context: context,
//       // استخدام BackdropFilter لجعل الخلفية ضبابية
//       builder: (ctx) => BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
//         child: AlertDialog(
//           backgroundColor: AppColors.glassBgColor.withOpacity(0.9),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//             side: const BorderSide(color: AppColors.glassBorderColor),
//           ),
//           title: Text(l10n.newExpense),
//           content: Form(
//             key: formKey,
//             child: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // استخدام ويدجت حقل الإدخال الزجاجي المخصصة
//                   _buildGlassTextFormField(controller: descriptionController, labelText: l10n.expenseDescription, validator: (v) => (v == null || v.isEmpty) ? l10n.descriptionRequired : null),
//                   const SizedBox(height: 16),
//                   _buildGlassTextFormField(controller: amountController, labelText: l10n.amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) {
//                     if (v == null || v.isEmpty) return l10n.amountRequired;
//                     if (double.tryParse(convertArabicNumbersToEnglish(v)) == null) return l10n.enterValidNumber;
//                     return null;
//                   }),
//                   const SizedBox(height: 16),
//                   if (categoryNames.isNotEmpty)
//                     // تعديل تصميم DropdownButton
//                     DropdownButtonFormField<String>(
//                       value: selectedCategory,
//                       decoration: _getGlassInputDecoration(l10n.category),
//                       dropdownColor: AppColors.primaryPurple,
//                       items: categoryNames.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
//                       onChanged: (value) => selectedCategory = value,
//                       validator: (v) => v == null ? l10n.selectCategory : null,
//                     )
//                   else
//                     Padding(padding: const EdgeInsets.only(top: 16.0), child: Text(l10n.addCategoriesFirst, style: TextStyle(color: Colors.red.shade300))),
//                   const SizedBox(height: 16),
//                   _buildGlassTextFormField(controller: notesController, labelText: l10n.notesOptional),
//                 ],
//               ),
//             ),
//           ),
//           actions: [
//             TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.cancel, style: TextStyle(color: AppColors.textGrey))),
//             ElevatedButton(
//               onPressed: () async {
//                 if (formKey.currentState!.validate()) {
//                   if (selectedCategory == null && categoryNames.isNotEmpty) return;
//                   final data = {
//                     'Description': descriptionController.text,
//                     'Amount': double.parse(convertArabicNumbersToEnglish(amountController.text)),
//                     'ExpenseDate': DateTime.now().toIso8601String(),
//                     'Category': selectedCategory,
//                     'Notes': notesController.text,
//                   };
//                   await dbHelper.recordExpense(data);
//                   Navigator.of(ctx).pop();
//                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.expenseAddedSuccess), backgroundColor: Colors.green));
//                   _loadExpenses();
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
//     final theme = Theme.of(context);

//     return Scaffold(
//       // --- 3. توحيد بنية الصفحة ---
//       backgroundColor: Colors.transparent,
//       extendBodyBehindAppBar: true,
//       body: GradientBackground(
//         child: CustomScrollView(
//           slivers: [
//             SliverAppBar(
//               title: Text(l10n.expensesLog),
//               pinned: true,
//               actions: [
//                 IconButton(
//                   icon: const Icon(Icons.category_outlined),
//                   onPressed: () async {
//                     await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ManageCategoriesScreen()));
//                   },
//                   tooltip: l10n.manageCategories,
//                 ),
//               ],
//             ),
//             // --- 4. استخدام SliverList لعرض قائمة المصاريف ---
//             FutureBuilder<List<Map<String, dynamic>>>(
//               future: _expensesFuture,
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Colors.white)));
//                 }
//                 if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                   return SliverFillRemaining(child: Center(child: Text(l10n.noExpenses, style: theme.textTheme.bodyLarge)));
//                 }
//                 final expenses = snapshot.data!;
//                 return SliverList(
//                   delegate: SliverChildBuilderDelegate(
//                     (context, index) {
//                       final expense = expenses[index];
//                       // --- 5. تعديل تصميم عنصر القائمة ---
//                       return Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
//                         child: GlassContainer(
//                           borderRadius: 15,
//                           child: ListTile(
//                             leading: const CircleAvatar(
//                               backgroundColor: Color.fromARGB(50, 239, 83, 80),
//                               child: Icon(Icons.arrow_upward, color: Colors.redAccent),
//                             ),
//                             title: Text(expense['Description']),
//                             subtitle: Text(expense['Category'] ?? l10n.unclassified, style: theme.textTheme.bodySmall),
//                             trailing: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               crossAxisAlignment: CrossAxisAlignment.end,
//                               children: [
//                                 Text(
//                                   '- ${formatCurrency(expense['Amount'])}',
//                                   style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
//                                 ),
//                                 Text(DateFormat('yyyy-MM-dd').format(DateTime.parse(expense['ExpenseDate'])), style: theme.textTheme.bodySmall),
//                               ],
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                     childCount: expenses.length,
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//       // --- 6. تعديل تصميم الزر العائم ---
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _showAddExpenseDialog(l10n),
//         backgroundColor: theme.colorScheme.primary,
//         foregroundColor: theme.colorScheme.onPrimary,
//         tooltip: l10n.addExpense,
//         child: const Icon(Icons.add),
//       ),
//     );
//   }

//   // دالة مساعدة لبناء حقول الإدخال الزجاجية داخل مربع الحوار
//   Widget _buildGlassTextFormField({required TextEditingController controller, required String labelText, String? Function(String?)? validator, TextInputType? keyboardType}) {
//     return TextFormField(
//       controller: controller,
//       decoration: _getGlassInputDecoration(labelText),
//       validator: validator,
//       keyboardType: keyboardType,
//     );
//   }

//   // دالة مساعدة للحصول على تصميم موحد لحقول الإدخال الزجاجية
//   InputDecoration _getGlassInputDecoration(String labelText) {
//     final theme = Theme.of(context);
//     return InputDecoration(
//       labelText: labelText,
//       filled: true,
//       fillColor: AppColors.glassBgColor,
//       border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.glassBorderColor)),
//       enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.glassBorderColor)),
//       focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
//     );
//   }
// }
