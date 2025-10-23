// // lib/screens/users/add_edit_user_screen.dart

// import 'dart:io';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as p;
// import 'package:bcrypt/bcrypt.dart';
// import '../../data/database_helper.dart';
// import '../../data/models.dart';
// import 'package:accounting_app/l10n/app_localizations.dart';
// import '../../theme/app_colors.dart';
// import '../../widgets/glass_container.dart';
// import '../../widgets/gradient_background.dart';

// class AddEditUserScreen extends StatefulWidget {
//   final User? user;
//   const AddEditUserScreen({super.key, this.user});

//   @override
//   State<AddEditUserScreen> createState() => _AddEditUserScreenState();
// }

// class _AddEditUserScreenState extends State<AddEditUserScreen> {
//   // ... (كل متغيرات الحالة والدوال المنطقية تبقى كما هي)
//   final _formKey = GlobalKey<FormState>();
//   final dbHelper = DatabaseHelper.instance;
//   final _fullNameController = TextEditingController();
//   final _userNameController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final Map<String, bool> _permissions = {'isAdmin': false, 'canViewSuppliers': false, 'canEditSuppliers': false, 'canViewProducts': false, 'canEditProducts': false, 'canViewCustomers': true, 'canEditCustomers': false, 'canViewReports': true, 'canManageEmployees': false, 'canViewSettings': false, 'canViewEmployeesReport': false, 'canManageExpenses': false, 'canViewCashSales': false};
//   File? _imageFile;
//   bool get _isEditMode => widget.user != null;

//   @override
//   void initState() {
//     super.initState();
//     if (_isEditMode) {
//       final u = widget.user!;
//       _fullNameController.text = u.fullName;
//       _userNameController.text = u.userName;
//       if (u.imagePath != null && u.imagePath!.isNotEmpty) _imageFile = File(u.imagePath!);
//       _permissions['isAdmin'] = u.isAdmin;
//       _permissions['canViewSuppliers'] = u.canViewSuppliers;
//       _permissions['canEditSuppliers'] = u.canEditSuppliers;
//       _permissions['canViewProducts'] = u.canViewProducts;
//       _permissions['canEditProducts'] = u.canEditProducts;
//       _permissions['canViewCustomers'] = u.canViewCustomers;
//       _permissions['canEditCustomers'] = u.canEditCustomers;
//       _permissions['canViewReports'] = u.canViewReports;
//       _permissions['canManageEmployees'] = u.canManageEmployees;
//       _permissions['canViewSettings'] = u.canViewSettings;
//       _permissions['canViewEmployeesReport'] = u.canViewEmployeesReport;
//       _permissions['canManageExpenses'] = u.canManageExpenses;
//       _permissions['canViewCashSales'] = u.canViewCashSales;
//     }
//   }

//   @override
//   void dispose() {
//     _fullNameController.dispose();
//     _userNameController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   void _saveUser() async {
//     final l10n = AppLocalizations.of(context)!;
//     if (!_formKey.currentState!.validate()) return;
//     try {
//       String passwordToSave;
//       if (_isEditMode) {
//         if (_passwordController.text.isNotEmpty) {
//           passwordToSave = BCrypt.hashpw(_passwordController.text, BCrypt.gensalt());
//         } else {
//           passwordToSave = widget.user!.password;
//         }
//       } else {
//         if (_passwordController.text.isEmpty) {
//           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.passwordRequiredForNewUser)));
//           return;
//         }
//         passwordToSave = BCrypt.hashpw(_passwordController.text, BCrypt.gensalt());
//       }
//       final user = User(id: _isEditMode ? widget.user!.id : null, fullName: _fullNameController.text, userName: _userNameController.text, password: passwordToSave, dateT: _isEditMode ? widget.user!.dateT : DateTime.now().toIso8601String(), imagePath: _imageFile?.path, isAdmin: _permissions['isAdmin']!, canViewSuppliers: _permissions['canViewSuppliers']!, canEditSuppliers: _permissions['canEditSuppliers']!, canViewProducts: _permissions['canViewProducts']!, canEditProducts: _permissions['canEditProducts']!, canViewCustomers: _permissions['canViewCustomers']!, canEditCustomers: _permissions['canEditCustomers']!, canViewReports: _permissions['canViewReports']!, canManageEmployees: _permissions['canManageEmployees']!, canViewSettings: _permissions['canViewSettings']!, canViewEmployeesReport: _permissions['canViewEmployeesReport']!, canManageExpenses: _permissions['canManageExpenses']!, canViewCashSales: _permissions['canViewCashSales']!);
//       if (_isEditMode) {
//         await dbHelper.updateUser(user);
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.userUpdatedSuccess), backgroundColor: Colors.green));
//       } else {
//         await dbHelper.insertUser(user);
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.userAddedSuccess), backgroundColor: Colors.green));
//       }
//       Navigator.of(context).pop(true);
//     } catch (e) {
//       final message = e.toString().contains('UNIQUE constraint failed') ? l10n.usernameAlreadyExists : l10n.errorOccurred(e.toString());
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     return Scaffold(
//       // --- 2. توحيد بنية الصفحة ---
//       // الشرح: نجعل Scaffold شفافاً ونضع الخلفية المتدرجة في Container.
//       backgroundColor: Colors.transparent,
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         title: Text(_isEditMode ? l10n.editUser : l10n.addUser),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         actions: [IconButton(onPressed: _saveUser, icon: const Icon(Icons.save), tooltip: l10n.save)],
//       ),
//       body: GradientBackground(
//         child: Form(
//           key: _formKey,
//           child: ListView(
//             padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 40, 16, 16),
//             children: [
//               // --- 3. تعديل تصميم واجهة اختيار الصورة ---
//               _buildImagePicker(l10n),
//               const SizedBox(height: 24),
              
//               // --- 4. تعديل تصميم حقول الإدخال ---
//               _buildGlassTextField(controller: _fullNameController, labelText: l10n.fullName, validator: (v) => (v == null || v.isEmpty) ? l10n.fieldRequired : null),
//               const SizedBox(height: 8),
//               _buildGlassTextField(controller: _userNameController, labelText: l10n.username, validator: (v) => (v == null || v.isEmpty) ? l10n.fieldRequired : null),
//               const SizedBox(height: 8),
//               _buildGlassTextField(controller: _passwordController, labelText: l10n.password, hintText: _isEditMode ? l10n.passwordHint : null, obscureText: true),
//               const Divider(height: 40, color: AppColors.glassBorderColor),
              
//               // --- 5. تعديل تصميم قسم الصلاحيات ---
//               Text(l10n.userPermissions, style: Theme.of(context).textTheme.titleLarge),
//               const SizedBox(height: 8),
//               _buildPermissionSwitch(l10n, 'isAdmin', l10n.adminPermission, l10n.adminPermissionSubtitle),
//               const Divider(color: AppColors.glassBorderColor),
              
//               // الشرح: تم تغليف كل مجموعة من الصلاحيات في GlassContainer لتجميعها بصرياً.
//               GlassContainer(
//                 borderRadius: 15,
//                 padding: const EdgeInsets.symmetric(vertical: 8),
//                 margin: const EdgeInsets.only(bottom: 8),
//                 child: Column(
//                   children: [
//                     _buildPermissionCheckbox(l10n, 'canViewSuppliers', l10n.viewSuppliers),
//                     _buildPermissionCheckbox(l10n, 'canEditSuppliers', l10n.editSuppliers),
//                   ],
//                 ),
//               ),
//               GlassContainer(
//                 borderRadius: 15,
//                 padding: const EdgeInsets.symmetric(vertical: 8),
//                 margin: const EdgeInsets.only(bottom: 8),
//                 child: Column(
//                   children: [
//                     _buildPermissionCheckbox(l10n, 'canViewProducts', l10n.viewProducts),
//                     _buildPermissionCheckbox(l10n, 'canEditProducts', l10n.editProducts),
//                   ],
//                 ),
//               ),
//               GlassContainer(
//                 borderRadius: 15,
//                 padding: const EdgeInsets.symmetric(vertical: 8),
//                 margin: const EdgeInsets.only(bottom: 8),
//                 child: Column(
//                   children: [
//                     _buildPermissionCheckbox(l10n, 'canViewCustomers', l10n.viewCustomers),
//                     _buildPermissionCheckbox(l10n, 'canEditCustomers', l10n.editCustomers),
//                   ],
//                 ),
//               ),
//               GlassContainer(
//                 borderRadius: 15,
//                 padding: const EdgeInsets.symmetric(vertical: 8),
//                 margin: const EdgeInsets.only(bottom: 8),
//                 child: Column(
//                   children: [
//                     _buildPermissionCheckbox(l10n, 'canManageEmployees', l10n.manageEmployees),
//                     _buildPermissionCheckbox(l10n, 'canViewEmployeesReport', l10n.viewEmployeesReport),
//                   ],
//                 ),
//               ),
//               GlassContainer(
//                 borderRadius: 15,
//                 padding: const EdgeInsets.symmetric(vertical: 8),
//                 margin: const EdgeInsets.only(bottom: 8),
//                 child: Column(
//                   children: [
//                     _buildPermissionCheckbox(l10n, 'canViewReports', l10n.viewReports),
//                     _buildPermissionCheckbox(l10n, 'canViewCashSales', l10n.viewCashSales),
//                     _buildPermissionCheckbox(l10n, 'canManageExpenses', l10n.manageExpenses),
//                   ],
//                 ),
//               ),
//               GlassContainer(
//                 borderRadius: 15,
//                 padding: const EdgeInsets.symmetric(vertical: 8),
//                 child: _buildPermissionCheckbox(l10n, 'canViewSettings', l10n.viewSettings),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // --- 6. الدوال المساعدة لبناء الواجهة (مع التعديلات) ---
//   Widget _buildPermissionSwitch(AppLocalizations l10n, String key, String title, String subtitle) {
//     return GlassContainer(
//       borderRadius: 15,
//       child: SwitchListTile(
//         title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
//         subtitle: Text(subtitle, style: TextStyle(color: AppColors.textGrey)),
//         value: _permissions[key]!,
//         onChanged: (bool value) {
//           setState(() {
//             _permissions[key] = value;
//             if (value) _permissions.updateAll((key, v) => true);
//           });
//         },
//         activeColor: Theme.of(context).colorScheme.primary,
//       ),
//     );
//   }

//   Widget _buildPermissionCheckbox(AppLocalizations l10n, String key, String title) {
//     final bool isAdmin = _permissions['isAdmin']!;
//     return CheckboxListTile(
//       title: Text(title),
//       value: _permissions[key]!,
//       onChanged: isAdmin ? null : (bool? value) => setState(() => _permissions[key] = value!),
//       activeColor: Theme.of(context).colorScheme.primary,
//       controlAffinity: ListTileControlAffinity.leading,
//     );
//   }

//   Widget _buildImagePicker(AppLocalizations l10n) {
//     return Center(
//       child: Stack(
//         children: [
//           GlassContainer(
//             borderRadius: 60,
//             child: CircleAvatar(
//               radius: 60,
//               backgroundColor: Colors.transparent,
//               backgroundImage: _imageFile != null && _imageFile!.existsSync() ? FileImage(_imageFile!) : null,
//               child: _imageFile == null || !_imageFile!.existsSync() ? Icon(Icons.person, size: 60, color: AppColors.textGrey.withOpacity(0.7)) : null,
//             ),
//           ),
//           Positioned(
//             bottom: 0,
//             right: 0,
//             child: CircleAvatar(
//               backgroundColor: Theme.of(context).colorScheme.primary,
//               child: IconButton(icon: const Icon(Icons.camera_alt, color: Colors.white), onPressed: () => _showImageSourceDialog(l10n)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildGlassTextField({required TextEditingController controller, required String labelText, String? hintText, String? Function(String?)? validator, bool obscureText = false}) {
//     return GlassContainer(
//       borderRadius: 15,
//       child: TextFormField(
//         controller: controller,
//         validator: validator,
//         obscureText: obscureText,
//         decoration: InputDecoration(labelText: labelText, hintText: hintText, border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
//       ),
//     );
//   }

//   Future<void> _pickImage(ImageSource source, AppLocalizations l10n) async {
//     try {
//       final pickedFile = await ImagePicker().pickImage(source: source, imageQuality: 80);
//       if (pickedFile == null) return;
//       final appDir = await getApplicationDocumentsDirectory();
//       final fileName = p.basename(pickedFile.path);
//       final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
//       setState(() => _imageFile = savedImage);
//     } catch (e) {
//       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorPickingImage(e.toString()))));
//     }
//   }

//   void _showImageSourceDialog(AppLocalizations l10n) {
//     showDialog(
//       context: context,
//       builder: (context) => BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
//         child: AlertDialog(
//           backgroundColor: AppColors.borderLight.withOpacity(0.9),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.borderLight)),
//           title: Text(l10n.imageSource),
//           content: Column(mainAxisSize: MainAxisSize.min, children: [
//             ListTile(leading: const Icon(Icons.photo_library), title: Text(l10n.gallery), onTap: () { Navigator.of(context).pop(); _pickImage(ImageSource.gallery, l10n); }),
//             ListTile(leading: const Icon(Icons.camera_alt), title: Text(l10n.camera), onTap: () { Navigator.of(context).pop(); _pickImage(ImageSource.camera, l10n); }),
//           ]),
//         ),
//       ),
//     );
//   }
// }
