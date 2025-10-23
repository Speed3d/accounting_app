// // lib/screens/users/users_list_screen.dart

// import 'dart:io';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import '../../data/database_helper.dart';
// import '../../data/models.dart';
// import '../../services/auth_service.dart';
// import 'add_edit_user_screen.dart';
// import 'package:accounting_app/l10n/app_localizations.dart';

// import '../../theme/app_colors.dart';
// import '../../widgets/glass_container.dart';
// import '../../widgets/gradient_background.dart';

// /// UsersListScreen: شاشة عرض قائمة المستخدمين
// ///
// /// Hint: هذه الشاشة أصبحت الآن تتبع التصميم الموحد للتطبيق.
// /// تستخدم GradientScaffold للخلفية و GlassContainer لعرض العناصر.
// class UsersListScreen extends StatefulWidget {
//   const UsersListScreen({super.key});

//   @override
//   State<UsersListScreen> createState() => _UsersListScreenState();
// }

// class _UsersListScreenState extends State<UsersListScreen> {
//   final dbHelper = DatabaseHelper.instance;
//   late Future<List<User>> _usersFuture;
//   final AuthService _authService = AuthService();

//   @override
//   void initState() {
//     super.initState();
//     _loadUsers();
//   }

//   /// دالة لإعادة تحميل قائمة المستخدمين من قاعدة البيانات.
//   void _loadUsers() {
//     setState(() {
//       _usersFuture = dbHelper.getAllUsers();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     final theme = Theme.of(context);

//     // --- بناء الهيكل الرئيسي للصفحة باستخدام GradientScaffold ---
//     // الشرح: هذا الويدجت يوفر لنا الخلفية المتدرجة تلقائياً وشريط عنوان شفاف.
//     return GradientScaffold(
//       appBar: AppBar(
//         title: Text(l10n.usersList),
//         // الخصائص الأخرى (اللون، الشفافية، الظل) تأتي من AppTheme
//       ),
//       body: SafeArea(
//         // SafeArea تضمن عدم تداخل المحتوى مع حواف الشاشة العلوية والسفلية
//         child: FutureBuilder<List<User>>(
//           future: _usersFuture,
//           builder: (context, snapshot) {
//             // --- حالة التحميل ---
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator(color: Colors.white));
//             }
//             // --- حالة عدم وجود بيانات ---
//             if (!snapshot.hasData || snapshot.data!.isEmpty) {
//               return Center(child: Text(l10n.noUsers, style: theme.textTheme.bodyLarge));
//             }

//             final users = snapshot.data!;

//             // --- بناء القائمة باستخدام ListView.builder ---
//             return ListView.builder(
//               padding: const EdgeInsets.fromLTRB(12, 8, 12, 80), // Padding لتجنب الحواف والشريط السفلي
//               itemCount: users.length,
//               itemBuilder: (context, index) {
//                 final user = users[index];
//                 final imageFile = user.imagePath != null ? File(user.imagePath!) : null;
//                 final bool isCurrentUser = user.id == _authService.currentUser?.id;
//                 final String roleText = user.isAdmin ? l10n.admin : l10n.customPermissionsUser;

//                 // --- استخدام GlassContainer لكل عنصر في القائمة ---
//                 return Padding(
//                   padding: const EdgeInsets.only(bottom: 10.0),
//                   child: GlassContainer(
//                     borderRadius: 15,
//                     // تمييز بطاقة المستخدم الحالي بلون وحدود مختلفة
//                     color: isCurrentUser ? AppColors.accentBlue.withOpacity(0.15) : AppColors.glassBgColor,
//                     borderColor: isCurrentUser ? AppColors.accentBlue : AppColors.glassBorderColor,
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         radius: 25,
//                         backgroundColor: AppColors.primaryPurple.withOpacity(0.5),
//                         backgroundImage: imageFile != null && imageFile.existsSync() ? FileImage(imageFile) : null,
//                         child: (imageFile == null || !imageFile.existsSync()) ? const Icon(Icons.person, color: AppColors.textGrey) : null,
//                       ),
//                       title: Text(user.fullName + (isCurrentUser ? ' ${l10n.you}' : '')),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text('اسم المستخدم: ${user.userName}'),
//                           Text(
//                             roleText,
//                             style: TextStyle(
//                               color: user.isAdmin ? Colors.redAccent : AppColors.textGrey,
//                               fontWeight: user.isAdmin ? FontWeight.bold : FontWeight.normal,
//                             ),
//                           ),
//                         ],
//                       ),
//                       isThreeLine: true,
//                       trailing: _authService.isAdmin
//                           ? Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 IconButton(
//                                   icon: const Icon(Icons.edit, color: AppColors.accentBlue),
//                                   tooltip: l10n.edit,
//                                   onPressed: () async {
//                                     if (isCurrentUser) {
//                                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.cannotEditOwnAccount)));
//                                       return;
//                                     }
//                                     final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddEditUserScreen(user: user)));
//                                     if (result == true) _loadUsers();
//                                   },
//                                 ),
//                                 IconButton(
//                                   icon: const Icon(Icons.delete, color: Colors.redAccent),
//                                   tooltip: l10n.delete,
//                                   onPressed: () {
//                                     if (isCurrentUser) {
//                                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.cannotDeleteOwnAccount)));
//                                       return;
//                                     }
//                                     if (users.length == 1) {
//                                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.cannotDeleteLastUser), backgroundColor: Colors.orange));
//                                       return;
//                                     }
//                                     _showDeleteConfirmation(user, l10n);
//                                   },
//                                 ),
//                               ],
//                             )
//                           : null,
//                     ),
//                   ),
//                 );
//               },
//             );
//           },
//         ),
//       ),
//       floatingActionButton: _authService.isAdmin
//           ? FloatingActionButton(
//               onPressed: () async {
//                 final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AddEditUserScreen()));
//                 if (result == true) _loadUsers();
//               },
//               backgroundColor: theme.colorScheme.primary,
//               child: const Icon(Icons.add),
//             )
//           : null,
//     );
//   }

//   /// دالة لعرض مربع حوار الحذف بتصميم زجاجي.
//   void _showDeleteConfirmation(User user, AppLocalizations l10n) {
//     showDialog(
//       context: context,
//       // BackdropFilter يطبق التمويه على كل ما هو خلف مربع الحوار
//       builder: (context) => BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
//         child: AlertDialog(
//           backgroundColor: AppColors.glassBgColor.withOpacity(0.9),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//             side: const BorderSide(color: AppColors.glassBorderColor),
//           ),
//           title: Text(l10n.delete),
//           content: Text(l10n.deleteUserConfirmation(user.fullName)),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: Text(l10n.cancel, style: const TextStyle(color: AppColors.textGrey)),
//             ),
//             TextButton(
//               onPressed: () async {
//                 await dbHelper.deleteUser(user.id!);
//                 await dbHelper.logActivity(l10n.deleteUserLog(user.fullName));
//                 if (mounted) Navigator.of(context).pop();
//                 _loadUsers();
//               },
//               child: Text(l10n.delete, style: TextStyle(color: Colors.redAccent)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
