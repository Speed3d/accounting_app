// // lib/screens/employees/add_edit_employee_screen.dart

// import 'dart:io';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';
// import 'package:path/path.dart' as p;
// import 'package:path_provider/path_provider.dart';
// import '../../data/database_helper.dart';
// import '../../data/models.dart';
// import '../../services/auth_service.dart';
// import '../../utils/helpers.dart';
// import 'package:accounting_app/l10n/app_localizations.dart';
// import '../../theme/app_colors.dart';
// import '../../widgets/glass_container.dart';
// import '../../widgets/gradient_background.dart';

// class AddEditEmployeeScreen extends StatefulWidget {
//   final Employee? employee;
//   const AddEditEmployeeScreen({super.key, this.employee});

//   @override
//   State<AddEditEmployeeScreen> createState() => _AddEditEmployeeScreenState();
// }

// class _AddEditEmployeeScreenState extends State<AddEditEmployeeScreen> {
//   // ... (كل متغيرات الحالة والدوال المنطقية تبقى كما هي)
//   final _formKey = GlobalKey<FormState>();
//   final dbHelper = DatabaseHelper.instance;
//   final AuthService _authService = AuthService();
//   final _nameController = TextEditingController();
//   final _jobTitleController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _salaryController = TextEditingController();
//   final _hireDateController = TextEditingController();
//   File? _imageFile;
//   DateTime? _selectedHireDate;
//   bool get _isEditMode => widget.employee != null;

//   @override
//   void initState() {
//     super.initState();
//     if (_isEditMode) {
//       final e = widget.employee!;
//       _nameController.text = e.fullName;
//       _jobTitleController.text = e.jobTitle;
//       _addressController.text = e.address ?? '';
//       _phoneController.text = e.phone ?? '';
//       _salaryController.text = e.baseSalary.toString();
//       _selectedHireDate = DateTime.parse(e.hireDate);
//       _hireDateController.text = DateFormat('yyyy-MM-dd').format(_selectedHireDate!);
//       if (e.imagePath != null && e.imagePath!.isNotEmpty) {
//         _imageFile = File(e.imagePath!);
//       }
//     } else {
//       _selectedHireDate = DateTime.now();
//       _hireDateController.text = DateFormat('yyyy-MM-dd').format(_selectedHireDate!);
//     }
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _jobTitleController.dispose();
//     _addressController.dispose();
//     _phoneController.dispose();
//     _salaryController.dispose();
//     _hireDateController.dispose();
//     super.dispose();
//   }

//   Future<void> _saveEmployee() async {
//     final l10n = AppLocalizations.of(context)!;
//     if (!_formKey.currentState!.validate()) return;

//     try {
//       final employee = Employee(
//         employeeID: _isEditMode ? widget.employee!.employeeID : null,
//         fullName: _nameController.text,
//         jobTitle: _jobTitleController.text,
//         address: _addressController.text,
//         phone: _phoneController.text,
//         baseSalary: double.parse(convertArabicNumbersToEnglish(_salaryController.text)),
//         hireDate: _selectedHireDate!.toIso8601String(),
//         imagePath: _imageFile?.path,
//         balance: _isEditMode ? widget.employee!.balance : 0.0,
//       );

//       String action;
//       String successMessage;
//       if (_isEditMode) {
//         await dbHelper.updateEmployee(employee);
//         action = 'تحديث بيانات الموظف: ${employee.fullName}';
//         successMessage = l10n.employeeUpdatedSuccess;
//       } else {
//         await dbHelper.insertEmployee(employee);
//         action = 'إضافة موظف جديد: ${employee.fullName}';
//         successMessage = l10n.employeeAddedSuccess;
//       }

//       await dbHelper.logActivity(action, userId: _authService.currentUser?.id, userName: _authService.currentUser?.fullName);

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage), backgroundColor: Colors.green));
//         Navigator.of(context).pop(true);
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorOccurred(e.toString())), backgroundColor: Colors.red));
//       }
//     }
//   }

//   Future<void> _pickHireDate() async {
//     final pickedDate = await showDatePicker(
//       context: context,
//       initialDate: _selectedHireDate ?? DateTime.now(),
//       firstDate: DateTime(2000),
//       lastDate: DateTime.now(),
//     );
//     if (pickedDate != null && pickedDate != _selectedHireDate) {
//       setState(() {
//         _selectedHireDate = pickedDate;
//         _hireDateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
//       });
//     }
//   }

//   Future<void> _pickImage(ImageSource source) async {
//     final l10n = AppLocalizations.of(context)!;
//     try {
//       final pickedFile = await ImagePicker().pickImage(source: source, imageQuality: 80);
//       if (pickedFile == null) return;
//       final appDir = await getApplicationDocumentsDirectory();
//       final fileName = p.basename(pickedFile.path);
//       final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
//       setState(() {
//         _imageFile = savedImage;
//       });
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorPickingImage(e.toString()))));
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
//         title: Text(_isEditMode ? l10n.editEmployee : l10n.addEmployee),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         actions: [
//           IconButton(onPressed: _saveEmployee, icon: const Icon(Icons.save), tooltip: l10n.save)
//         ],
//       ),
//       body: GradientBackground(
//         child: SafeArea(
//           child: Form(
//             key: _formKey,
//             child: ListView(
//               padding: const EdgeInsets.symmetric(horizontal: 20.0),
//               children: [
//                 const SizedBox(height: 20),
//                 // --- 3. تعديل تصميم منتقي الصور ---
//                 Center(
//                   child: Stack(
//                     children: [
//                       GlassContainer(
//                         borderRadius: 70,
//                         child: CircleAvatar(
//                           radius: 70,
//                           backgroundColor: Colors.transparent,
//                           backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
//                           child: _imageFile == null ? Icon(Icons.badge, size: 70, color: AppColors.textGrey.withOpacity(0.5)) : null,
//                         ),
//                       ),
//                       Positioned(
//                         bottom: 0,
//                         right: 0,
//                         child: Material(
//                           color: theme.colorScheme.primary,
//                           borderRadius: BorderRadius.circular(30),
//                           child: InkWell(
//                             borderRadius: BorderRadius.circular(30),
//                             onTap: () => _showImageSourceDialog(l10n),
//                             child: const SizedBox(width: 44, height: 44, child: Icon(Icons.camera_alt, color: Colors.white, size: 22)),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 32),

//                 // --- 4. تطبيق التصميم الزجاجي على حقول الإدخال ---
//                 TextFormField(controller: _nameController, decoration: _getGlassInputDecoration(l10n.employeeName), validator: (v) => (v == null || v.isEmpty) ? l10n.employeeNameRequired : null),
//                 const SizedBox(height: 20),
//                 TextFormField(controller: _jobTitleController, decoration: _getGlassInputDecoration(l10n.jobTitle), validator: (v) => (v == null || v.isEmpty) ? l10n.jobTitleRequired : null),
//                 const SizedBox(height: 20),
//                 TextFormField(controller: _addressController, decoration: _getGlassInputDecoration(l10n.addressOptional)),
//                 const SizedBox(height: 20),
//                 TextFormField(controller: _phoneController, decoration: _getGlassInputDecoration(l10n.phoneOptional), keyboardType: TextInputType.phone),
//                 const SizedBox(height: 20),
//                 TextFormField(controller: _salaryController, decoration: _getGlassInputDecoration(l10n.baseSalary, Icons.attach_money), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) {
//                   if (v == null || v.isEmpty) return l10n.baseSalaryRequired;
//                   if (double.tryParse(convertArabicNumbersToEnglish(v)) == null) return l10n.enterValidNumber;
//                   return null;
//                 }),
//                 const SizedBox(height: 20),
//                 TextFormField(controller: _hireDateController, decoration: _getGlassInputDecoration(l10n.hireDate, Icons.calendar_today), readOnly: true, onTap: _pickHireDate),
//                 const SizedBox(height: 40),
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
//               ListTile(leading: const Icon(Icons.photo_library), title: Text(l10n.gallery), onTap: () { Navigator.of(context).pop(); _pickImage(ImageSource.gallery); }),
//               ListTile(leading: const Icon(Icons.camera_alt), title: Text(l10n.camera), onTap: () { Navigator.of(context).pop(); _pickImage(ImageSource.camera); }),
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
