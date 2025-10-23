// // lib/screens/customers/add_edit_customer_screen.dart

// import 'dart:io';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as p;
// import '../../data/database_helper.dart';
// import '../../data/models.dart';
// import '../../services/auth_service.dart';
// import 'package:accounting_app/l10n/app_localizations.dart';
// import '../../theme/app_colors.dart';
// import '../../widgets/glass_container.dart';
// import '../../widgets/gradient_background.dart';

// class AddEditCustomerScreen extends StatefulWidget {
//   final Customer? customer;
//   const AddEditCustomerScreen({super.key, this.customer});

//   @override
//   State<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
// }

// class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
//   // ... (كل متغيرات الحالة والدوال المنطقية تبقى كما هي)
//   final _formKey = GlobalKey<FormState>();
//   final dbHelper = DatabaseHelper.instance;
//   final AuthService _authService = AuthService();
//   final _nameController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _phoneController = TextEditingController();
//   File? _imageFile;
//   bool get _isEditMode => widget.customer != null;

//   @override
//   void initState() {
//     super.initState();
//     if (_isEditMode) {
//       final c = widget.customer!;
//       _nameController.text = c.customerName;
//       _addressController.text = c.address ?? '';
//       _phoneController.text = c.phone ?? '';
//       if (c.imagePath != null && c.imagePath!.isNotEmpty) {
//         _imageFile = File(c.imagePath!);
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _addressController.dispose();
//     _phoneController.dispose();
//     super.dispose();
//   }

//   Future<void> _pickImage(ImageSource source, AppLocalizations l10n) async {
//     try {
//       final picker = ImagePicker();
//       final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
//       if (pickedFile == null) return;
//       final appDir = await getApplicationDocumentsDirectory();
//       final fileName = p.basename(pickedFile.path);
//       final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
//       setState(() => _imageFile = savedImage);
//     } catch (e) {
//       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorPickingImage(e.toString()))));
//     }
//   }

//   void _saveCustomer() async {
//     final l10n = AppLocalizations.of(context)!;
//     if (_formKey.currentState!.validate()) {
//       String action;
//       String successMessage;
//       if (_isEditMode) {
//         final updatedCustomer = Customer(customerID: widget.customer!.customerID, customerName: _nameController.text, address: _addressController.text, phone: _phoneController.text, imagePath: _imageFile?.path, debt: widget.customer!.debt, payment: widget.customer!.payment, remaining: widget.customer!.remaining, dateT: widget.customer!.dateT, isActive: widget.customer!.isActive);
//         await dbHelper.updateCustomer(updatedCustomer);
//         action = 'تحديث بيانات الزبون: ${updatedCustomer.customerName}';
//         successMessage = l10n.customerUpdatedSuccess;
//       } else {
//         final newCustomer = Customer(customerName: _nameController.text, address: _addressController.text, phone: _phoneController.text, imagePath: _imageFile?.path, dateT: DateTime.now().toIso8601String());
//         await dbHelper.insertCustomer(newCustomer);
//         action = 'إضافة زبون جديد: ${newCustomer.customerName}';
//         successMessage = l10n.customerAddedSuccess;
//       }
//       await dbHelper.logActivity(action, userId: _authService.currentUser?.id, userName: _authService.currentUser?.fullName);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage), backgroundColor: Colors.green));
//         Navigator.of(context).pop(true);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     final theme = Theme.of(context);

//     return Scaffold(
//       // --- 2. توحيد بنية الصفحة ---
//       backgroundColor: Colors.transparent,
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         title: Text(_isEditMode ? l10n.editCustomer : l10n.addCustomer),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         actions: [
//           IconButton(icon: const Icon(Icons.save), tooltip: l10n.save, onPressed: _saveCustomer)
//         ],
//       ),
//       // صفحات الاضافة هكذا تكون
//       body: GradientBackground(
//         child: SafeArea(
//           child: Form(
//             key: _formKey,
//             child: ListView(
//               padding: const EdgeInsets.all(20.0),
//               children: [
//                 // --- 3. تعديل تصميم الصورة الرمزية ---
//                 Center(
//                   child: Stack(
//                     children: [
//                       GlassContainer(
//                         borderRadius: 60,
//                         child: CircleAvatar(
//                           radius: 60,
//                           backgroundColor: Colors.transparent,
//                           backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
//                           child: _imageFile == null ? Icon(Icons.person, size: 60, color: AppColors.textGrey.withOpacity(0.5)) : null,
//                         ),
//                       ),
//                       Positioned(
//                         bottom: 0,
//                         right: 0,
//                         child: CircleAvatar(
//                           backgroundColor: theme.colorScheme.primary,
//                           child: IconButton(
//                             icon: const Icon(Icons.camera_alt, color: Colors.white),
//                             onPressed: () => _showImageSourceDialog(l10n),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 32),
//                 // --- 4. تطبيق التصميم الزجاجي على حقول الإدخال ---
//                 TextFormField(
//                   controller: _nameController,
//                   decoration: _getGlassInputDecoration(l10n.customerName, Icons.person_outline),
//                   validator: (v) => (v == null || v.isEmpty) ? l10n.customerNameRequired : null,
//                 ),
//                 const SizedBox(height: 20),
//                 TextFormField(
//                   controller: _addressController,
//                   decoration: _getGlassInputDecoration(l10n.addressOptional, Icons.location_on_outlined),
//                 ),
//                 const SizedBox(height: 20),
//                 TextFormField(
//                   controller: _phoneController,
//                   decoration: _getGlassInputDecoration(l10n.phoneOptional, Icons.phone_outlined),
//                   keyboardType: TextInputType.phone,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // --- 5. تعديل مربع حوار اختيار مصدر الصورة ---
//   void _showImageSourceDialog(AppLocalizations l10n) {
//     showDialog(
//       context: context,
//       builder: (context) => BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
//         child: AlertDialog(
//           backgroundColor: AppColors.glassBgColor.withOpacity(0.9),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.glassBorderColor)),
//           title: Text(l10n.imageSource),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               ListTile(
//                 leading: const Icon(Icons.photo_library),
//                 title: Text(l10n.gallery),
//                 onTap: () {
//                   Navigator.of(context).pop();
//                   _pickImage(ImageSource.gallery, l10n);
//                 },
//               ),
//               ListTile(
//                 leading: const Icon(Icons.camera_alt),
//                 title: Text(l10n.camera),
//                 onTap: () {
//                   Navigator.of(context).pop();
//                   _pickImage(ImageSource.camera, l10n);
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // دالة مساعدة للحصول على تصميم موحد لحقول الإدخال الزجاجية
//   InputDecoration _getGlassInputDecoration(String labelText, [IconData? icon]) {
//     final theme = Theme.of(context);
//     return InputDecoration(
//       labelText: labelText,
//       prefixIcon: icon != null ? Icon(icon, color: AppColors.textGrey.withOpacity(0.8)) : null,
//       filled: true,
//       fillColor: AppColors.glassBgColor,
//       labelStyle: theme.textTheme.bodyMedium,
//       border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.glassBorderColor, width: 1.5)),
//       enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.glassBorderColor, width: 1.5)),
//       focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
//     );
//   }
// }
