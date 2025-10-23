// // lib/screens/suppliers/add_edit_supplier_screen.dart

// import 'dart:io';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:path/path.dart' as p;
// import 'package:path_provider/path_provider.dart';
// import '../../data/database_helper.dart';
// import '../../data/models.dart';
// import '../../l10n/app_localizations.dart';
// import '../../services/auth_service.dart';
// import '../../widgets/gradient_background.dart';
// import 'add_edit_partner_screen.dart';
// import '../../theme/app_colors.dart';
// import '../../widgets/glass_container.dart';

// class AddEditSupplierScreen extends StatefulWidget {
//   final Supplier? supplier;
//   const AddEditSupplierScreen({super.key, this.supplier});

//   @override
//   State<AddEditSupplierScreen> createState() => _AddEditSupplierScreenState();
// }

// class _AddEditSupplierScreenState extends State<AddEditSupplierScreen> {
//   // ... (كل متغيرات الحالة والدوال المنطقية تبقى كما هي)
//   final _formKey = GlobalKey<FormState>();
//   final dbHelper = DatabaseHelper.instance;
//   final AuthService _authService = AuthService();
//   final _nameController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _notesController = TextEditingController();
//   String _supplierType = 'فردي';
//   List<Partner> _partners = [];
//   File? _imageFile;
//   bool get _isEditMode => widget.supplier != null;
//   bool get _isPartnerType => _supplierType == 'شراكة';

//   @override
//   void initState() {
//     super.initState();
//     if (_isEditMode) {
//       final s = widget.supplier!;
//       _nameController.text = s.supplierName;
//       _phoneController.text = s.phone ?? '';
//       _addressController.text = s.address ?? '';
//       _notesController.text = s.notes ?? '';
//       _supplierType = s.supplierType;
//       if (s.imagePath != null && s.imagePath!.isNotEmpty) _imageFile = File(s.imagePath!);
//       if (_isPartnerType) _loadPartners();
//     }
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _addressController.dispose();
//     _phoneController.dispose();
//     _notesController.dispose();
//     super.dispose();
//   }

//   void _loadPartners() async {
//     if (widget.supplier?.supplierID == null) return;
//     final partners = await dbHelper.getPartnersForSupplier(widget.supplier!.supplierID!);
//     setState(() => _partners = partners);
//   }

//   Future<void> _navigateAndManagePartner({Partner? existingPartner, int? index}) async {
//     final result = await Navigator.of(context).push<Partner>(MaterialPageRoute(builder: (context) => AddEditPartnerScreen(partner: existingPartner)));
//     if (result != null) {
//       setState(() {
//         if (index != null) {
//           _partners[index] = result;
//         } else {
//           _partners.add(result);
//         }
//       });
//     }
//   }

//   void _saveSupplier() async {
//     final l10n = AppLocalizations.of(context)!;
//     if (!_formKey.currentState!.validate()) return;
//     if (_isPartnerType) {
//       if (_partners.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.atLeastOnePartnerRequired), backgroundColor: Colors.red));
//         return;
//       }
//       double totalPercentage = _partners.fold(0, (sum, p) => sum + p.sharePercentage);
//       if (totalPercentage > 100) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.partnerShareTotalExceeds100(totalPercentage.toString())), backgroundColor: Colors.red));
//         return;
//       }
//     }
//     String action;
//     String successMessage;
//     if (_isEditMode) {
//       final updatedSupplier = Supplier(supplierID: widget.supplier!.supplierID, supplierName: _nameController.text, supplierType: _supplierType, address: _addressController.text, phone: _phoneController.text, notes: _notesController.text, dateAdded: widget.supplier!.dateAdded, imagePath: _imageFile?.path, isActive: widget.supplier!.isActive);
//       await dbHelper.updateSupplierWithPartners(updatedSupplier, _partners);
//       action = 'تحديث بيانات المورد: ${updatedSupplier.supplierName}';
//       successMessage = l10n.supplierUpdatedSuccess;
//     } else {
//       final newSupplier = Supplier(supplierName: _nameController.text, supplierType: _supplierType, address: _addressController.text, phone: _phoneController.text, notes: _notesController.text, dateAdded: DateTime.now().toIso8601String(), imagePath: _imageFile?.path);
//       await dbHelper.insertSupplierWithPartners(newSupplier, _partners);
//       action = 'إضافة مورد جديد: ${newSupplier.supplierName}';
//       successMessage = l10n.supplierAddedSuccess;
//     }
//     await dbHelper.logActivity(action, userId: _authService.currentUser?.id, userName: _authService.currentUser?.fullName);
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage), backgroundColor: Colors.green));
//       Navigator.of(context).pop(true);
//     }
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
//         title: Text(_isEditMode ? l10n.editSupplier : l10n.addSupplier),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         actions: [IconButton(icon: const Icon(Icons.save), onPressed: _saveSupplier, tooltip: l10n.save)],
//       ),
//       body: GradientBackground(
//         child: Form(
//           key: _formKey,
//           child: ListView(
//             padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 40, 16, 16),
//             children: [
//               // --- 3. تعديل تصميم واجهة اختيار الصورة ---
//               _buildImagePicker(),
//               const SizedBox(height: 24),
              
//               // --- 4. تعديل تصميم حقول الإدخال ---
//               _buildGlassTextField(controller: _nameController, labelText: l10n.supplierName, validator: (v) => (v == null || v.isEmpty) ? l10n.supplierNameRequired : null),
//               const SizedBox(height: 16),
              
//               // --- 5. تعديل تصميم أزرار الراديو ---
//               GlassContainer(
//                 borderRadius: 15,
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
//                   Text('${l10n.supplierType}:'),
//                   Row(children: [Radio<String>(value: 'فردي', groupValue: _supplierType, onChanged: (v) => setState(() => _supplierType = v!), activeColor: theme.colorScheme.primary), Text(l10n.individual)]),
//                   Row(children: [Radio<String>(value: 'شراكة', groupValue: _supplierType, onChanged: (v) => setState(() => _supplierType = v!), activeColor: theme.colorScheme.primary), Text(l10n.partnership)]),
//                 ]),
//               ),
//               const SizedBox(height: 16),
//               _buildGlassTextField(controller: _addressController, labelText: l10n.addressOptional),
//               const SizedBox(height: 8),
//               _buildGlassTextField(controller: _phoneController, labelText: l10n.phoneOptional, keyboardType: TextInputType.phone),
//               const SizedBox(height: 8),
//               _buildGlassTextField(controller: _notesController, labelText: l10n.notesOptional, maxLines: 3),
//               const Divider(height: 32, thickness: 0.5, color: AppColors.glassBorderColor),
              
//               // --- 6. تعديل تصميم قسم الشركاء ---
//               if (_isPartnerType) ...[
//                 _buildSectionTitle(l10n.partners),
//                 ListView.builder(
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   itemCount: _partners.length,
//                   itemBuilder: (context, index) {
//                     final partner = _partners[index];
//                     return Padding(
//                       padding: const EdgeInsets.only(bottom: 8.0),
//                       child: GlassContainer(
//                         borderRadius: 12,
//                         child: ListTile(
//                           leading: CircleAvatar(backgroundImage: partner.imagePath != null ? FileImage(File(partner.imagePath!)) : null, child: partner.imagePath == null ? const Icon(Icons.person) : null),
//                           title: Text(partner.partnerName),
//                           subtitle: Text(l10n.percentageLabel(partner.sharePercentage.toString())),
//                           onTap: () => _navigateAndManagePartner(existingPartner: partner, index: index),
//                           trailing: IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent), onPressed: () => setState(() => _partners.removeAt(index))),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//                 const SizedBox(height: 1),
//                 // الشرح: تم تعديل تصميم الزر ليتناسب مع الثيم.
//                 ElevatedButton.icon(
//                   onPressed: () => _navigateAndManagePartner(),
//                   icon: const Icon(Icons.add),
//                   label: Text(l10n.addPartner),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.accentBlue.withOpacity(0.2),
//                     foregroundColor: AppColors.accentBlue,
//                     elevation: 0,
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // --- 7. الدوال المساعدة لبناء الواجهة (مع التعديلات) ---
//   Widget _buildSectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8.0),
//       child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//     );
//   }

//   Widget _buildImagePicker() {
//     return Center(
//       child: Stack(
//         children: [
//           GlassContainer(
//             borderRadius: 60,
//             child: CircleAvatar(
//               radius: 60,
//               backgroundColor: Colors.transparent,
//               backgroundImage: _imageFile != null && _imageFile!.existsSync() ? FileImage(_imageFile!) : null,
//               child: _imageFile == null || !_imageFile!.existsSync() ? Icon(Icons.store, size: 60, color: AppColors.textGrey.withOpacity(0.7)) : null,
//             ),
//           ),
//           Positioned(
//             bottom: 0,
//             right: 0,
//             child: CircleAvatar(
//               backgroundColor: Theme.of(context).colorScheme.primary,
//               child: IconButton(icon: const Icon(Icons.camera_alt, color: Colors.white), onPressed: () => _showImageSourceDialog()),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildGlassTextField({required TextEditingController controller, required String labelText, String? Function(String?)? validator, TextInputType? keyboardType, int maxLines = 1}) {
//     return GlassContainer(
//       borderRadius: 15,
//       child: TextFormField(
//         controller: controller,
//         validator: validator,
//         keyboardType: keyboardType,
//         maxLines: maxLines,
//         decoration: InputDecoration(labelText: labelText, border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
//       ),
//     );
//   }

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
// }
