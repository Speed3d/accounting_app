// // lib/screens/settings/company_info_screen.dart

// import 'dart:io';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as p;
// import '../../data/database_helper.dart';
// import '../../l10n/app_localizations.dart';
// import '../../theme/app_colors.dart'; 
// import '../../widgets/glass_container.dart';
// import '../../widgets/gradient_background.dart'; 

// class CompanyInfoScreen extends StatefulWidget {
//   const CompanyInfoScreen({super.key});

//   @override
//   State<CompanyInfoScreen> createState() => _CompanyInfoScreenState();
// }

// class _CompanyInfoScreenState extends State<CompanyInfoScreen> {
//   // ... (كل المتغيرات والدوال المنطقية تبقى كما هي)
//   final _formKey = GlobalKey<FormState>();
//   final dbHelper = DatabaseHelper.instance;

//   final _companyNameController = TextEditingController();
//   final _descriptionController = TextEditingController();
//   File? _logoFile;
//   bool _isLoading = true;
//   bool _isSaving = false;

//   static const String _companyNameKey = 'companyName';
//   static const String _companyDescriptionKey = 'companyDescription';
//   static const String _companyLogoKey = 'companyLogoPath';

//   @override
//   void initState() {
//     super.initState();
//     _loadSettings();
//   }

//   @override
//   void dispose() {
//     _companyNameController.dispose();
//     _descriptionController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadSettings() async {
//     final settings = await dbHelper.getAppSettings();
//     if (mounted) {
//       setState(() {
//         _companyNameController.text = settings[_companyNameKey] ?? '';
//         _descriptionController.text = settings[_companyDescriptionKey] ?? '';
//         final logoPath = settings[_companyLogoKey];
//         if (logoPath != null && logoPath.isNotEmpty) {
//           _logoFile = File(logoPath);
//         }
//         _isLoading = false;
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
//         _logoFile = savedImage;
//       });
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorPickingImage(e.toString()))));
//       }
//     }
//   }

//   Future<void> _saveSettings() async {
//     final l10n = AppLocalizations.of(context)!;
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }
//     setState(() => _isSaving = true);

//     try {
//       await dbHelper.saveSetting(_companyNameKey, _companyNameController.text);
//       await dbHelper.saveSetting(_companyDescriptionKey, _descriptionController.text);
//       if (_logoFile != null) {
//         await dbHelper.saveSetting(_companyLogoKey, _logoFile!.path);
//       }

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(l10n.infoSavedSuccess), backgroundColor: Colors.green),
//         );
//         Navigator.of(context).pop();
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.error}: $e')));
//       }
//     } finally {
//       if (mounted) setState(() => _isSaving = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     final theme = Theme.of(context);

//     return Scaffold(
//       // 1. توحيد بنية الصفحة (نفس أسلوب باقي الصفحات)
//       backgroundColor: Colors.transparent,
//       extendBodyBehindAppBar: true,
//       body: GradientBackground(
//         child: _isLoading
//             ? const Center(child: CircularProgressIndicator(color: Colors.white))
//             : CustomScrollView(
//                 slivers: [
//                   SliverAppBar(
//                     title: Text(l10n.companyInformation),
//                     pinned: true,
//                   ),
//                   SliverToBoxAdapter(
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 20.0),
//                       child: Form(
//                         key: _formKey,
//                         child: Column(
//                           children: [
//                             const SizedBox(height: 30),
//                             // 2. ويدجت اختيار الشعار (Logo Picker)
//                             _buildLogoPicker(context),
//                             const SizedBox(height: 40),

//                             // 3. استخدام ويدجت حقل الإدخال الزجاجي المخصصة
//                             _GlassTextFormField(
//                               controller: _companyNameController,
//                               labelText: l10n.companyOrShopName,
//                               icon: Icons.text_fields,
//                               validator: (value) => (value?.isEmpty ?? true) ? l10n.fieldRequired : null,
//                             ),
//                             const SizedBox(height: 20),
//                             _GlassTextFormField(
//                               controller: _descriptionController,
//                               labelText: l10n.companyDescOptional,
//                               hintText: l10n.companyDescHint,
//                               icon: Icons.description_outlined,
//                               maxLines: 3,
//                             ),
//                             const SizedBox(height: 40),

//                             // 4. زر الحفظ المحسّن
//                             _buildSaveButton(context),
//                             const SizedBox(height: 20),
//                             Text(
//                               l10n.companyInfoHint,
//                               textAlign: TextAlign.center,
//                               style: theme.textTheme.bodyMedium,
//                             ),
//                             const SizedBox(height: 40),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//       ),
//     );
//   }

//   // ويدجت اختيار الشعار
//   Widget _buildLogoPicker(BuildContext context) {
//     final theme = Theme.of(context);
//     return Stack(
//       alignment: Alignment.center,
//       children: [
//         // خلفية زجاجية دائرية خلف الشعار
//         GlassContainer(
//           borderRadius: 80,
//           child: const SizedBox(width: 160, height: 160),
//         ),
//         // الصورة نفسها
//         CircleAvatar(
//           radius: 70,
//           backgroundColor: Colors.transparent, // شفاف لأن الخلفية الزجاجية موجودة
//           backgroundImage: _logoFile != null && _logoFile!.existsSync() ? FileImage(_logoFile!) : null,
//           child: _logoFile == null || !_logoFile!.existsSync()
//               ? Icon(Icons.business, size: 70, color: AppColors.textGrey.withOpacity(0.5))
//               : null,
//         ),
//         // زر التعديل
//         Positioned(
//           bottom: 5,
//           right: 5,
//           child: Material(
//             color: theme.colorScheme.primary,
//             borderRadius: BorderRadius.circular(30),
//             child: InkWell(
//               borderRadius: BorderRadius.circular(30),
//               onTap: _isSaving ? null : () => _showImageSourceDialog(context),
//               child: const SizedBox(
//                 width: 44,
//                 height: 44,
//                 child: Icon(Icons.camera_alt, color: Colors.white, size: 22),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // ويدجت زر الحفظ
//   Widget _buildSaveButton(BuildContext context) {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton.icon(
//         icon: _isSaving
//             ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
//             : const Icon(Icons.save, size: 20),
//         label: Text(_isSaving ? "جارٍ الحفظ..." : "حفظ التغييرات"),
//         onPressed: _isSaving ? null : _saveSettings,
//         // الأنماط تأتي من ElevatedButtonTheme في app_theme.dart
//       ),
//     );
//   }

//   // دالة عرض خيارات الصورة
//   void _showImageSourceDialog(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     showDialog(
//       context: context,
//       // استخدام AlertDialog بتصميم زجاجي
//       builder: (context) => BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
//         child: AlertDialog(
//           backgroundColor: AppColors.glassBgColor.withOpacity(0.8),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//             side: const BorderSide(color: AppColors.glassBorderColor),
//           ),
//           title: Text(l10n.chooseImageSource),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               ListTile(
//                 leading: const Icon(Icons.photo_library_outlined),
//                 title: Text(l10n.gallery),
//                 onTap: () {
//                   Navigator.of(context).pop();
//                   _pickImage(ImageSource.gallery);
//                 },
//               ),
//               ListTile(
//                 leading: const Icon(Icons.camera_alt_outlined),
//                 title: Text(l10n.camera),
//                 onTap: () {
//                   Navigator.of(context).pop();
//                   _pickImage(ImageSource.camera);
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // 5. ويدجت مخصصة لحقل الإدخال الزجاجي (الأكثر أهمية)
// class _GlassTextFormField extends StatelessWidget {
//   final TextEditingController controller;
//   final String labelText;
//   final String? hintText;
//   final IconData icon;
//   final int maxLines;
//   final String? Function(String?)? validator;

//   const _GlassTextFormField({
//     required this.controller,
//     required this.labelText,
//     this.hintText,
//     required this.icon,
//     this.maxLines = 1,
//     this.validator,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     // هذه هي الطريقة الصحيحة لتصميم حقل إدخال زجاجي.
//     // نحن لا نغلفه بـ GlassContainer، بل نجعله هو نفسه زجاجياً.
//     return TextFormField(
//       controller: controller,
//       validator: validator,
//       maxLines: maxLines,
//       style: theme.textTheme.bodyLarge, // لون النص أثناء الكتابة
//       decoration: InputDecoration(
//         // الجزء الأهم: تحديد شكل وخلفية الحقل
//         filled: true,
//         fillColor: AppColors.glassBgColor, // لون الخلفية الزجاجي
        
//         // تحديد الحدود
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(15),
//           borderSide: const BorderSide(color: AppColors.glassBorderColor, width: 1.5),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(15),
//           borderSide: const BorderSide(color: AppColors.glassBorderColor, width: 1.5),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(15),
//           borderSide: BorderSide(color: theme.colorScheme.primary, width: 2), // تمييز الحقل عند التركيز
//         ),
        
//         // الأيقونة والنصوص
//         prefixIcon: Icon(icon, color: AppColors.textGrey.withOpacity(0.8)),
//         labelText: labelText,
//         hintText: hintText,
//         labelStyle: theme.textTheme.bodyMedium,
//         hintStyle: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textGrey.withOpacity(0.5)),
//         contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
//       ),
//     );
//   }
// }
