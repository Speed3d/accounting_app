// // lib/screens/products/add_edit_product_screen.dart

// import 'package:flutter/material.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
// import 'package:accounting_app/l10n/app_localizations.dart';
// import '../../data/database_helper.dart';
// import '../../data/models.dart';
// import '../../utils/helpers.dart';
// import '../../theme/app_colors.dart';
// import '../../widgets/gradient_background.dart';

// class AddEditProductScreen extends StatefulWidget {
//   final Product? product;
//   const AddEditProductScreen({super.key, this.product});

//   @override
//   State<AddEditProductScreen> createState() => _AddEditProductScreenState();
// }

// class _AddEditProductScreenState extends State<AddEditProductScreen> {
//   // ... (كل متغيرات الحالة والدوال المنطقية تبقى كما هي)
//   final _formKey = GlobalKey<FormState>();
//   final dbHelper = DatabaseHelper.instance;
//   final _nameController = TextEditingController();
//   final _detailsController = TextEditingController();
//   final _quantityController = TextEditingController();
//   final _costPriceController = TextEditingController();
//   final _sellingPriceController = TextEditingController();
//   final _barcodeController = TextEditingController();
//   Supplier? _selectedSupplier;
//   late Future<List<Supplier>> _suppliersFuture;
//   bool get _isEditMode => widget.product != null;

//   @override
//   void initState() {
//     super.initState();
//     _suppliersFuture = dbHelper.getAllSuppliers();
//     if (_isEditMode) {
//       final p = widget.product!;
//       _nameController.text = p.productName;
//       _detailsController.text = p.productDetails ?? '';
//       _quantityController.text = p.quantity.toString();
//       _costPriceController.text = p.costPrice.toString();
//       _sellingPriceController.text = p.sellingPrice.toString();
//       _barcodeController.text = p.barcode ?? '';
//       _suppliersFuture.then((suppliers) {
//         if (suppliers.isNotEmpty) {
//           try {
//             final foundSupplier = suppliers.firstWhere((s) => s.supplierID == p.supplierID);
//             setState(() => _selectedSupplier = foundSupplier);
//           } catch (_) {}
//         }
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _detailsController.dispose();
//     _quantityController.dispose();
//     _costPriceController.dispose();
//     _sellingPriceController.dispose();
//     _barcodeController.dispose();
//     super.dispose();
//   }

//   Future<void> scanBarcode() async {
//     final result = await Navigator.push<String>(context, MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()));
//     if (result != null && mounted) setState(() => _barcodeController.text = result);
//   }

//   void _saveProduct() async {
//     final l10n = AppLocalizations.of(context)!;
//     if (!_formKey.currentState!.validate()) return;
//     if (_selectedSupplier == null) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectSupplier), backgroundColor: Colors.red));
//       return;
//     }
//     String barcodeToSave = _barcodeController.text.trim();
//     if (barcodeToSave.isEmpty) barcodeToSave = 'INTERNAL-${DateTime.now().millisecondsSinceEpoch}';
//     final bool exists = await dbHelper.barcodeExists(barcodeToSave, currentProductId: _isEditMode ? widget.product!.productID : null);
//     if (exists) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.barcodeExistsError), backgroundColor: Colors.red));
//       return;
//     }
//     try {
//       final product = Product(productID: _isEditMode ? widget.product!.productID : null, productName: _nameController.text, barcode: barcodeToSave, productDetails: _detailsController.text, quantity: int.parse(convertArabicNumbersToEnglish(_quantityController.text)), costPrice: double.parse(convertArabicNumbersToEnglish(_costPriceController.text)), sellingPrice: double.parse(convertArabicNumbersToEnglish(_sellingPriceController.text)), supplierID: _selectedSupplier!.supplierID!);
//       if (_isEditMode) {
//         await dbHelper.updateProduct(product);
//       } else {
//         await dbHelper.insertProduct(product);
//       }
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEditMode ? l10n.productUpdatedSuccess : l10n.productAddedSuccess), backgroundColor: Colors.green));
//       Navigator.of(context).pop(true);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorOccurred(e.toString())), backgroundColor: Colors.red));
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
//         title: Text(_isEditMode ? l10n.editProduct : l10n.addProduct),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         actions: [IconButton(onPressed: _saveProduct, icon: const Icon(Icons.save))],
//       ),
//       body: GradientBackground(
//         child: SafeArea(
//           child: Form(
//             key: _formKey,
//             child: ListView(
//               padding: const EdgeInsets.all(20.0),
//               children: [
//                 // --- 3. تعديل تصميم القائمة المنسدلة ---
//                 _buildSuppliersDropdown(l10n),
//                 const SizedBox(height: 20),
//                 // --- 4. تطبيق التصميم الزجاجي على حقول الإدخال ---
//                 TextFormField(controller: _nameController, decoration: _getGlassInputDecoration(l10n.productName), validator: (v) => (v == null || v.isEmpty) ? l10n.productNameRequired : null),
//                 const SizedBox(height: 20),
//                 TextFormField(
//                   controller: _barcodeController,
//                   decoration: _getGlassInputDecoration(
//                     l10n.barcode,
//                     null,
//                     IconButton(icon: Icon(Icons.qr_code_scanner, color: AppColors.textGrey), onPressed: scanBarcode),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 TextFormField(controller: _detailsController, decoration: _getGlassInputDecoration(l10n.productDetailsOptional)),
//                 const SizedBox(height: 20),
//                 _buildNumberField(l10n, controller: _quantityController, labelText: l10n.quantity, allowDecimal: false),
//                 const SizedBox(height: 20),
//                 _buildNumberField(l10n, controller: _costPriceController, labelText: l10n.costPrice),
//                 const SizedBox(height: 20),
//                 _buildNumberField(l10n, controller: _sellingPriceController, labelText: l10n.sellingPrice),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSuppliersDropdown(AppLocalizations l10n) {
//     return FutureBuilder<List<Supplier>>(
//       future: _suppliersFuture,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting && !_isEditMode) {
//           return const Center(child: CircularProgressIndicator(color: Colors.white));
//         }
//         if (snapshot.hasError) return Text(l10n.errorLoadingSuppliers, style: const TextStyle(color: Colors.redAccent));
//         if (!snapshot.hasData || snapshot.data!.isEmpty) return Text(l10n.noSuppliersAddOneFirst, style: const TextStyle(color: Colors.orangeAccent));
        
//         final suppliers = snapshot.data!;
//         final isValueInList = _selectedSupplier != null && suppliers.any((s) => s.supplierID == _selectedSupplier!.supplierID);
        
//         return DropdownButtonFormField<Supplier>(
//           decoration: _getGlassInputDecoration(l10n.supplier),
//           dropdownColor: AppColors.primaryPurple,
//           value: isValueInList ? _selectedSupplier : null,
//           hint: Text(l10n.selectSupplier),
//           items: suppliers.map((supplier) => DropdownMenuItem<Supplier>(value: supplier, child: Text(supplier.supplierName))).toList(),
//           onChanged: (value) => setState(() => _selectedSupplier = value),
//           validator: (value) => (value == null) ? l10n.pleaseSelectSupplier : null,
//         );
//       },
//     );
//   }

//   Widget _buildNumberField(AppLocalizations l10n, {required TextEditingController controller, required String labelText, bool allowDecimal = true}) {
//     return TextFormField(
//       controller: controller,
//       decoration: _getGlassInputDecoration(labelText),
//       keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
//       validator: (value) {
//         if (value == null || value.isEmpty) return l10n.fieldRequired;
//         final number = num.tryParse(convertArabicNumbersToEnglish(value));
//         if (number == null) return l10n.enterValidNumber;
//         if (number < 0) return l10n.fieldCannotBeNegative;
//         return null;
//       },
//     );
//   }

//   // دالة مساعدة للحصول على تصميم موحد لحقول الإدخال الزجاجية
//   InputDecoration _getGlassInputDecoration(String labelText, [IconData? icon, Widget? suffixIcon]) {
//     final theme = Theme.of(context);
//     return InputDecoration(
//       labelText: labelText,
//       prefixIcon: icon != null ? Icon(icon, color: AppColors.textGrey.withOpacity(0.8)) : null,
//       suffixIcon: suffixIcon,
//       filled: true,
//       fillColor: AppColors.glassBgColor,
//       labelStyle: theme.textTheme.bodyMedium,
//       border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.glassBorderColor, width: 1.5)),
//       enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.glassBorderColor, width: 1.5)),
//       focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
//     );
//   }
// }

// // =================================================================================================
// // --- شاشة مسح الباركود باستخدام الكاميرا ---
// // متوافقة مع آخر إصدار من mobile_scanner
// // =================================================================================================

// class BarcodeScannerScreen extends StatefulWidget {
//   const BarcodeScannerScreen({super.key});

//   @override
//   State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
// }

// class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
//   // 🎯 إنشاء المتحكم الرئيسي للماسح
//   final MobileScannerController controller = MobileScannerController();

//   // 🔄 متغير لتجنب معالجة أكثر من نتيجة باركود بنفس الوقت
//   bool _isProcessing = false;

//   // 💡 متغير من نوع ValueNotifier لمتابعة حالة الفلاش (تشغيل/إيقاف)
//   final ValueNotifier<bool> _torchEnabled = ValueNotifier(false);

//   // 🔁 متغير آخر لمتابعة الكاميرا الحالية (أمامية / خلفية)
//   final ValueNotifier<CameraFacing> _cameraFacing =
//       ValueNotifier(CameraFacing.back);

//   @override
//   void dispose() {
//     // 🧹 تنظيف الموارد عند إغلاق الشاشة
//     controller.dispose();
//     _torchEnabled.dispose();
//     _cameraFacing.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!; // للترجمة
//     return Scaffold(
//       // ✅ جعل المحتوى خلف AppBar ليبدو بتصميم شفاف جميل
//       extendBodyBehindAppBar: true,

//       appBar: AppBar(
//         title: Text(l10n.scanBarcode),
//         backgroundColor: Colors.black.withOpacity(0.3), // شفافية جميلة
//         elevation: 0,

//         // 🔘 الأزرار في الجهة اليمنى من AppBar
//         actions: [
//           // 🔦 زر التحكم بالفلاش
//           ValueListenableBuilder<bool>(
//             valueListenable: _torchEnabled,
//             builder: (context, isOn, _) {
//               return IconButton(
//                 icon: Icon(
//                   isOn ? Icons.flash_on : Icons.flash_off,
//                   color: isOn ? Colors.yellow : Colors.grey,
//                 ),
//                 onPressed: () async {
//                   // عند الضغط على الزر نبدل حالة الفلاش
//                   await controller.toggleTorch();
//                   _torchEnabled.value = !isOn; // تحديث الحالة المرئية
//                 },
//               );
//             },
//           ),

//           // 🔁 زر تبديل الكاميرا الأمامية / الخلفية
//           ValueListenableBuilder<CameraFacing>(
//             valueListenable: _cameraFacing,
//             builder: (context, facing, _) {
//               return IconButton(
//                 icon: Icon(
//                   Icons.cameraswitch,
//                   color: Colors.white.withOpacity(0.8),
//                 ),
//                 onPressed: () async {
//                   // نبدل الكاميرا
//                   await controller.switchCamera();
//                   _cameraFacing.value = facing == CameraFacing.back
//                       ? CameraFacing.front
//                       : CameraFacing.back;
//                 },
//               );
//             },
//           ),
//         ],
//       ),

//       // 📷 مكون الكاميرا الفعلي لمسح الباركود
//       body: MobileScanner(
//         controller: controller, // نمرر المتحكم
//         onDetect: (capture) {
//           // 🧠 عند اكتشاف باركود جديد
//           if (_isProcessing) return; // لمنع التكرار
//           setState(() => _isProcessing = true);

//           final List<Barcode> barcodes = capture.barcodes;
//           if (barcodes.isNotEmpty) {
//             final barcode = barcodes.first.rawValue;
//             if (barcode != null) {
//               // ✅ إرجاع القيمة إلى الشاشة السابقة
//               Navigator.of(context).pop(barcode);
//             }
//           }
//         },
//       ),
//     );
//   }

// }
