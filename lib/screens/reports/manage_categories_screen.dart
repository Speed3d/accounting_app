// // lib/screens/reports/manage_categories_screen.dart

// import 'dart:ui'; 
// import 'package:flutter/material.dart';
// import '../../data/database_helper.dart';
// import 'package:accounting_app/l10n/app_localizations.dart';
// import '../../theme/app_colors.dart';
// import '../../widgets/glass_container.dart';
// import '../../widgets/gradient_background.dart';

// class ManageCategoriesScreen extends StatefulWidget {
//   const ManageCategoriesScreen({super.key});

//   @override
//   State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
// }

// class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
//   // ... (كل متغيرات الحالة والدوال المنطقية تبقى كما هي)
//   final dbHelper = DatabaseHelper.instance;
//   late Future<List<Map<String, dynamic>>> _categoriesFuture;

//   @override
//   void initState() {
//     super.initState();
//     _loadCategories();
//   }

//   void _loadCategories() {
//     setState(() {
//       _categoriesFuture = dbHelper.getExpenseCategories();
//     });
//   }

//   // --- 2. تعديل مربعات الحوار لتكون زجاجية ---
//   // الشرح: تم تغليف AlertDialog بـ BackdropFilter لتطبيق تأثير التمويه على الخلفية.
//   // تم تعديل خصائص AlertDialog (اللون، الشكل) لتتناسب مع التصميم الزجاجي.
//   void _showCategoryDialog(AppLocalizations l10n, {Map<String, dynamic>? existingCategory}) {
//     final formKey = GlobalKey<FormState>();
//     final nameController = TextEditingController(text: existingCategory?['CategoryName']);
//     final isEditing = existingCategory != null;

//     showDialog(
//       context: context,
//       builder: (ctx) => BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
//         child: AlertDialog(
//           backgroundColor: AppColors.glassBgColor.withOpacity(0.9),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.glassBorderColor)),
//           title: Text(isEditing ? l10n.editCategory : l10n.addCategory),
//           content: Form(
//             key: formKey,
//             child: TextFormField(
//               controller: nameController,
//               decoration: InputDecoration(labelText: l10n.categoryName),
//               validator: (v) => (v == null || v.isEmpty) ? l10n.categoryNameRequired : null,
//             ),
//           ),
//           actions: [
//             TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.cancel, style: TextStyle(color: AppColors.textGrey))),
//             ElevatedButton(
//               onPressed: () async {
//                 if (formKey.currentState!.validate()) {
//                   try {
//                     if (isEditing) {
//                       await dbHelper.updateExpenseCategory(existingCategory['CategoryID'], nameController.text);
//                     } else {
//                       await dbHelper.addExpenseCategory(nameController.text);
//                     }
//                     Navigator.of(ctx).pop();
//                     _loadCategories();
//                   } catch (e) {
//                     Navigator.of(ctx).pop();
//                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.categoryExistsError), backgroundColor: Colors.red));
//                   }
//                 }
//               },
//               child: Text(l10n.save),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _handleDeleteCategory(int id, String name, AppLocalizations l10n) {
//     showDialog(
//       context: context,
//       builder: (ctx) => BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
//         child: AlertDialog(
//           backgroundColor: AppColors.glassBgColor.withOpacity(0.9),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.glassBorderColor)),
//           title: Text(l10n.confirmDeleteTitle),
//           content: Text(l10n.confirmDeleteCategory(name)),
//           actions: [
//             TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.cancel, style: TextStyle(color: AppColors.textGrey))),
//             TextButton(
//               onPressed: () async {
//                 await dbHelper.deleteExpenseCategory(id);
//                 Navigator.of(ctx).pop();
//                 _loadCategories();
//               },
//               child: Text(l10n.delete, style: const TextStyle(color: Colors.redAccent)),
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
//       // الشرح: نجعل Scaffold شفافاً ونضع الخلفية المتدرجة في Container
//       // ليغطي الشاشة بأكملها، مما يضمن ظهور التأثير الزجاجي بشكل صحيح.
//       backgroundColor: Colors.transparent,
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         title: Text(l10n.manageExpenseCategories),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//       ),
//       body: GradientBackground(
//         child: SafeArea(
//           child: FutureBuilder<List<Map<String, dynamic>>>(
//             future: _categoriesFuture,
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator(color: Colors.white));
//               }
//               if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                 return Center(child: Text(l10n.noCategories, style: theme.textTheme.bodyLarge));
//               }
//               final categories = snapshot.data!;
//               // --- 4. تعديل تصميم القائمة ---
//               // الشرح: نستخدم ListView.builder لعرض البيانات، ونغلف كل عنصر بـ GlassContainer.
//               return ListView.builder(
//                 padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
//                 itemCount: categories.length,
//                 itemBuilder: (context, index) {
//                   final category = categories[index];
//                   final categoryId = category['CategoryID'];
//                   final categoryName = category['CategoryName'];
//                   return Padding(
//                     padding: const EdgeInsets.only(bottom: 8.0),
//                     child: GlassContainer(
//                       borderRadius: 15,
//                       child: ListTile(
//                         title: Text(categoryName),
//                         trailing: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             IconButton(icon: const Icon(Icons.edit_outlined, color: AppColors.accentBlue), onPressed: () => _showCategoryDialog(l10n, existingCategory: category)),
//                             IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _handleDeleteCategory(categoryId, categoryName, l10n)),
//                           ],
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               );
//             },
//           ),
//         ),
//       ),
//       // --- 5. تعديل تصميم الزر العائم ---
//       // الشرح: نعدل لون الزر العائم ليعتمد على اللون الرئيسي من الثيم.
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _showCategoryDialog(l10n),
//         backgroundColor: theme.colorScheme.primary,
//         tooltip: l10n.addCategory,
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }
