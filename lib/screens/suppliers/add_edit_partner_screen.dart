// // lib/screens/suppliers/add_edit_partner_screen.dart

// import 'dart:io';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:path/path.dart' as p;
// import 'package:path_provider/path_provider.dart';
// import '../../data/models.dart';
// import '../../l10n/app_localizations.dart';
// import '../../utils/helpers.dart';
// import '../../theme/app_colors.dart';
// import '../../widgets/glass_container.dart';
// import '../../widgets/gradient_background.dart';

// class AddEditPartnerScreen extends StatefulWidget {
//   final Partner? partner;
//   const AddEditPartnerScreen({super.key, this.partner});

//   @override
//   State<AddEditPartnerScreen> createState() => _AddEditPartnerScreenState();
// }

// class _AddEditPartnerScreenState extends State<AddEditPartnerScreen> {
//   // ... (كل متغيرات الحالة والدوال المنطقية تبقى كما هي)
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _shareController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _notesController = TextEditingController();
//   File? _imageFile;
//   bool get _isEditMode => widget.partner != null;

//   @override
//   void initState() {
//     super.initState();
//     if (_isEditMode) {
//       final p = widget.partner!;
//       _nameController.text = p.partnerName;
//       _shareController.text = p.sharePercentage.toString();
//       _addressController.text = p.partnerAddress ?? '';
//       _phoneController.text = p.partnerPhone ?? '';
//       _notesController.text = p.notes ?? '';
//       if (p.imagePath != null && p.imagePath!.isNotEmpty) _imageFile = File(p.imagePath!);
//     }
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _shareController.dispose();
//     _addressController.dispose();
//     _phoneController.dispose();
//     _notesController.dispose();
//     super.dispose();
//   }

//   Future<void> _pickImage(ImageSource source) async {
//     final l10n = AppLocalizations.of(context)!;
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

//   void _savePartner() {
//     if (!_formKey.currentState!.validate()) return;
//     final partner = Partner(
//       partnerID: _isEditMode ? widget.partner!.partnerID : null,
//       supplierID: _isEditMode ? widget.partner!.supplierID : null,
//       partnerName: _nameController.text,
//       sharePercentage: double.parse(convertArabicNumbersToEnglish(_shareController.text)),
//       partnerAddress: _addressController.text,
//       partnerPhone: _phoneController.text,
//       imagePath: _imageFile?.path,
//       notes: _notesController.text,
//       dateAdded: _isEditMode ? widget.partner!.dateAdded : DateTime.now().toIso8601String(),
//     );
//     Navigator.of(context).pop(partner);
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
//         title: Text(_isEditMode ? "تعديل بيانات الشريك" : "إضافة شريك جديد"),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         actions: [IconButton(icon: const Icon(Icons.save), onPressed: _savePartner, tooltip: l10n.save)],
//       ),
//       body: GradientBackground(
//         child: Form(
//           key: _formKey,
//           child: ListView(
//             padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 40, 16, 16),
//             children: [
//               // --- 3. تعديل تصميم الصورة الرمزية ---
//               Center(
//                 child: Stack(
//                   children: [
//                     GlassContainer(
//                       borderRadius: 60,
//                       child: CircleAvatar(
//                         radius: 60,
//                         backgroundColor: Colors.transparent,
//                         backgroundImage: _imageFile != null && _imageFile!.existsSync() ? FileImage(_imageFile!) : null,
//                         child: _imageFile == null || !_imageFile!.existsSync() ? Icon(Icons.person, size: 60, color: AppColors.textGrey.withOpacity(0.7)) : null,
//                       ),
//                     ),
//                     Positioned(
//                       bottom: 0,
//                       right: 0,
//                       child: CircleAvatar(
//                         backgroundColor: theme.colorScheme.primary,
//                         child: IconButton(icon: const Icon(Icons.camera_alt, color: Colors.white), onPressed: () => _showImageSourceDialog()),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 24),

//               // --- 4. تعديل تصميم حقول الإدخال ---
//               // الشرح: نستخدم دالة مساعدة `_buildGlassTextField` لتطبيق التصميم الزجاجي على كل حقل.
//               _buildGlassTextField(
//                 controller: _nameController,
//                 labelText: l10n.partnerName,
//                 validator: (v) => (v == null || v.isEmpty) ? l10n.partnerNameRequired : null,
//               ),
//               const SizedBox(height: 16),
//               _buildGlassTextField(
//                 controller: _shareController,
//                 labelText: l10n.sharePercentage,
//                 keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                 validator: (v) {
//                   if (v == null || v.isEmpty) return l10n.fieldRequired;
//                   final amount = double.tryParse(convertArabicNumbersToEnglish(v));
//                   if (amount == null || amount <= 0 || amount > 100) return l10n.percentageMustBeBetween1And100;
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),
//               _buildGlassTextField(controller: _addressController, labelText: l10n.addressOptional),
//               const SizedBox(height: 16),
//               _buildGlassTextField(controller: _phoneController, labelText: l10n.phoneOptional, keyboardType: TextInputType.phone),
//               const SizedBox(height: 16),
//               _buildGlassTextField(controller: _notesController, labelText: l10n.notesOptional, maxLines: 3),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // --- 5. دالة مساعدة لبناء حقول الإدخال الزجاجية ---
//   // الشرح: هذه الدالة تأخذ كل خصائص TextFormField وتغلفه بـ GlassContainer لتطبيق التصميم.
//   Widget _buildGlassTextField({
//     required TextEditingController controller,
//     required String labelText,
//     String? Function(String?)? validator,
//     TextInputType? keyboardType,
//     int maxLines = 1,
//   }) {
//     return GlassContainer(
//       borderRadius: 15,
//       child: TextFormField(
//         controller: controller,
//         validator: validator,
//         keyboardType: keyboardType,
//         maxLines: maxLines,
//         decoration: InputDecoration(
//           labelText: labelText,
//           border: InputBorder.none,
//           contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//         ),
//       ),
//     );
//   }

//   // --- 6. تعديل مربع حوار اختيار مصدر الصورة ---
//   // الشرح: تم تغليف AlertDialog بـ BackdropFilter وتعديل خصائصه ليتناسب مع التصميم الزجاجي.
//   void _showImageSourceDialog() {
//     final l10n = AppLocalizations.of(context)!;
//     showDialog(
//       context: context,
//       builder: (context) => BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
//         child: AlertDialog(
//           backgroundColor: AppColors.glassBgColor.withOpacity(0.9),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.glassBorderColor)),
//           title: Text(l10n.imageSource),
//           content: Column(mainAxisSize: MainAxisSize.min, children: [
//             ListTile(leading: const Icon(Icons.photo_library), title: Text(l10n.gallery), onTap: () { Navigator.of(context).pop(); _pickImage(ImageSource.gallery); }),
//             ListTile(leading: const Icon(Icons.camera_alt), title: Text(l10n.camera), onTap: () { Navigator.of(context).pop(); _pickImage(ImageSource.camera); }),
//           ]),
//         ),
//       ),
//     );
//   }
// }
