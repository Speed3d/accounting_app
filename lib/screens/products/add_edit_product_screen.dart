// lib/screens/products/add_edit_product_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../utils/helpers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_card.dart';
import 'barcode_scanner_screen.dart';

/// 📦 شاشة إضافة/تعديل منتج - صفحة فرعية
/// ← Hint: نموذج شامل لإدخال بيانات المنتج مع دعم الصور
class AddEditProductScreen extends StatefulWidget {
  final Product? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  // ============= متغيرات النموذج =============
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // ← Hint: Controllers للحقول النصية
  final _nameController = TextEditingController();
  final _detailsController = TextEditingController();
  final _quantityController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _barcodeController = TextEditingController();

  // ============= متغيرات الحالة =============
  Supplier? _selectedSupplier;
  late Future<List<Supplier>> _suppliersFuture;
  bool _isLoading = false;

  // ← Hint: متغيرات الصورة
  File? _productImage; // الصورة الجديدة المختارة
  String? _existingImagePath; // مسار الصورة الموجودة (في حالة التعديل)
  bool _shouldDeleteImage = false; // علامة لحذف الصورة

  // ============= Getters =============
  bool get _isEditMode => widget.product != null;

  /// ← Hint: التحقق من وجود صورة (جديدة أو قديمة)
  bool get _hasImage => 
      (_productImage != null || (_existingImagePath != null && !_shouldDeleteImage));

  // ============= دورة الحياة =============
  @override
  void initState() {
    super.initState();
    _suppliersFuture = dbHelper.getAllSuppliers();
    _initializeForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _detailsController.dispose();
    _quantityController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  /// ← Hint: تهيئة النموذج بالبيانات الموجودة (في حالة التعديل)
  void _initializeForm() {
    if (_isEditMode) {
      final p = widget.product!;
      _nameController.text = p.productName;
      _detailsController.text = p.productDetails ?? '';
      _quantityController.text = p.quantity.toString();
      _costPriceController.text = p.costPrice.toString();
      _sellingPriceController.text = p.sellingPrice.toString();
      _barcodeController.text = p.barcode ?? '';
      
      // ← Hint: تحميل مسار الصورة الموجودة
      if (p.imagePath != null && p.imagePath!.isNotEmpty) {
        _existingImagePath = p.imagePath;
      }

      // ← Hint: تحميل المورد المرتبط
      _suppliersFuture.then((suppliers) {
        if (suppliers.isNotEmpty) {
          try {
            final foundSupplier = suppliers.firstWhere(
              (s) => s.supplierID == p.supplierID,
            );
            setState(() => _selectedSupplier = foundSupplier);
          } catch (_) {}
        }
      });
    }
  }

  // ============================================================
  // 📷 دوال إدارة الصور
  // ============================================================

  /// ← Hint: عرض خيارات اختيار الصورة (كاميرا أو معرض)
  Future<void> _showImageSourceDialog() async {
    final l10n = AppLocalizations.of(context)!;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.add_photo_alternate, color: AppColors.info),
            const SizedBox(width: AppConstants.spacingSm),
            Text(l10n.selectImageSource),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ← Hint: خيار الكاميرا
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppConstants.spacingSm),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: AppConstants.borderRadiusSm,
                ),
                child: const Icon(Icons.camera_alt, color: AppColors.info),
              ),
              title: Text(l10n.camera),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: AppConstants.spacingSm),
            // ← Hint: خيار المعرض
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppConstants.spacingSm),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: AppConstants.borderRadiusSm,
                ),
                child: const Icon(Icons.photo_library, color: AppColors.success),
              ),
              title: Text(l10n.gallery),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  /// ← Hint: اختيار صورة من المصدر المحدد
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 70, // ← Hint: ضغط الصورة للحفاظ على المساحة
        maxWidth: 800, // ← Hint: الحد الأقصى للعرض
      );

      if (pickedFile != null) {
        setState(() {
          _productImage = File(pickedFile.path);
          _shouldDeleteImage = false; // ← Hint: إلغاء علامة الحذف
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في اختيار الصورة: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// ← Hint: حذف الصورة المختارة
  void _removeImage() {
    setState(() {
      _productImage = null;
      if (_existingImagePath != null) {
        _shouldDeleteImage = true; // ← Hint: وضع علامة للحذف
      }
    });
  }

  /// ← Hint: حفظ الصورة في مجلد التطبيق الدائم
  /// يُرجع مسار الصورة المحفوظة أو null إذا فشل
  Future<String?> _saveImageToStorage(File imageFile) async {
    try {
      // ← Hint: الحصول على مجلد التطبيق الدائم
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String productImagesDir = path.join(appDir.path, 'product_images');

      // ← Hint: إنشاء المجلد إذا لم يكن موجوداً
      final Directory imageDirectory = Directory(productImagesDir);
      if (!await imageDirectory.exists()) {
        await imageDirectory.create(recursive: true);
      }

      // ← Hint: إنشاء اسم فريد للملف باستخدام timestamp
      final String fileName = 
          'product_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      final String newPath = path.join(productImagesDir, fileName);

      // ← Hint: نسخ الصورة إلى المجلد الدائم
      final File newImage = await imageFile.copy(newPath);

      return newImage.path;
    } catch (e) {
      debugPrint('❌ خطأ في حفظ الصورة: $e');
      return null;
    }
  }

  /// ← Hint: حذف الصورة القديمة من التخزين (عند التعديل)
  Future<void> _deleteOldImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return;

    try {
      final File oldImage = File(imagePath);
      if (await oldImage.exists()) {
        await oldImage.delete();
        debugPrint('✅ تم حذف الصورة القديمة: $imagePath');
      }
    } catch (e) {
      debugPrint('⚠️ خطأ في حذف الصورة القديمة: $e');
    }
  }

  // ============================================================
  // 📷 مسح الباركود
  // ============================================================
  Future<void> _scanBarcode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );

    if (result != null && mounted) {
      setState(() => _barcodeController.text = result);
    }
  }

  // ============================================================
  // 💾 حفظ المنتج
  // ============================================================
  Future<void> _saveProduct() async {
    final l10n = AppLocalizations.of(context)!;

    // ← Hint: التحقق من صحة البيانات
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectSupplier),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ← Hint: معالجة الباركود
      String barcodeToSave = _barcodeController.text.trim();
      if (barcodeToSave.isEmpty) {
        barcodeToSave = 'INTERNAL-${DateTime.now().millisecondsSinceEpoch}';
      }

      // ← Hint: التحقق من عدم تكرار الباركود
      final exists = await dbHelper.barcodeExists(
        barcodeToSave,
        currentProductId: _isEditMode ? widget.product!.productID : null,
      );

      if (exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.barcodeExistsError),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // ============= معالجة الصورة =============
      String? finalImagePath;

      if (_productImage != null) {
        // ← Hint: توجد صورة جديدة - حفظها
        finalImagePath = await _saveImageToStorage(_productImage!);

        // ← Hint: حذف الصورة القديمة إذا كنا في وضع التعديل
        if (_isEditMode && _existingImagePath != null) {
          await _deleteOldImage(_existingImagePath);
        }
      } else if (_shouldDeleteImage && _existingImagePath != null) {
        // ← Hint: المستخدم حذف الصورة - حذفها من التخزين
        await _deleteOldImage(_existingImagePath);
        finalImagePath = null;
      } else if (_existingImagePath != null) {
        // ← Hint: لا توجد تغييرات على الصورة - الاحتفاظ بالمسار القديم
        finalImagePath = _existingImagePath;
      }

      // ← Hint: إنشاء كائن المنتج
      final product = Product(
        productID: _isEditMode ? widget.product!.productID : null,
        productName: _nameController.text.trim(),
        barcode: barcodeToSave,
        productDetails: _detailsController.text.trim(),
        quantity: int.parse(
          convertArabicNumbersToEnglish(_quantityController.text),
        ),
        costPrice: double.parse(
          convertArabicNumbersToEnglish(_costPriceController.text),
        ),
        sellingPrice: double.parse(
          convertArabicNumbersToEnglish(_sellingPriceController.text),
        ),
        supplierID: _selectedSupplier!.supplierID!,
        imagePath: finalImagePath, // ← Hint: حفظ مسار الصورة
      );

      // ← Hint: حفظ في قاعدة البيانات
      if (_isEditMode) {
        await dbHelper.updateProduct(product);
      } else {
        await dbHelper.insertProduct(product);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(
                  child: Text(
                    _isEditMode
                        ? l10n.productUpdatedSuccess
                        : l10n.productAddedSuccess,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorOccurred(e.toString())),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ============================================================
  // 🎨 بناء الواجهة
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // ============= AppBar =============
      appBar: AppBar(
        title: Text(_isEditMode ? l10n.editProduct : l10n.addProduct),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l10n.save,
            onPressed: _isLoading ? null : _saveProduct,
          ),
        ],
      ),

      // ============= Body =============
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppConstants.screenPadding,
          children: [
            const SizedBox(height: AppConstants.spacingLg),

            // ============= المورد =============
            _buildSectionHeader(l10n.supplierInfo, Icons.store, isDark),
            const SizedBox(height: AppConstants.spacingMd),
            _buildSupplierDropdown(l10n, isDark),

            const SizedBox(height: AppConstants.spacingXl),

            // ============= معلومات المنتج =============
            _buildSectionHeader(l10n.productInfo, Icons.info_outline, isDark),
            const SizedBox(height: AppConstants.spacingMd),

            // اسم المنتج
            CustomTextField(
              controller: _nameController,
              label: l10n.productName,
              hint: l10n.enterProductName,
              prefixIcon: Icons.inventory_2_outlined,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.productNameRequired : null,
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // الباركود مع زر المسح
            CustomTextField(
              controller: _barcodeController,
              label: l10n.barcode,
              hint: l10n.scanOrEnterBarcode,
              prefixIcon: Icons.qr_code,
              suffixIcon: Icons.qr_code_scanner,
              onSuffixIconPressed: _scanBarcode,
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // التفاصيل
            CustomTextField(
              controller: _detailsController,
              label: l10n.productDetailsOptional,
              hint: l10n.enterProductDetails,
              prefixIcon: Icons.description_outlined,
              maxLines: 3,
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: AppConstants.spacingXl),

            // ============= صورة المنتج =============
            _buildSectionHeader(l10n.productImage, Icons.image_outlined, isDark),
            const SizedBox(height: AppConstants.spacingMd),
            _buildImageSection(l10n, isDark),

            const SizedBox(height: AppConstants.spacingXl),

            // ============= الكمية والأسعار =============
            _buildSectionHeader(l10n.quantityAndPrices, Icons.attach_money, isDark),
            const SizedBox(height: AppConstants.spacingMd),

            // الكمية
            CustomTextField(
              controller: _quantityController,
              label: l10n.quantity,
              hint: l10n.enterQuantity,
              prefixIcon: Icons.inventory_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              textInputAction: TextInputAction.next,
              validator: _quantityValidator,
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // سعر التكلفة
            CustomTextField(
              controller: _costPriceController,
              label: l10n.costPrice,
              hint: l10n.purchasePrice,
              prefixIcon: Icons.shopping_cart_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              validator: _priceValidator,
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // سعر البيع
            CustomTextField(
              controller: _sellingPriceController,
              label: l10n.sellingPrice,
              hint: l10n.salePrice,
              prefixIcon: Icons.sell_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              validator: _priceValidator,
            ),

            const SizedBox(height: AppConstants.spacingXl),

            // ============= ملخص الأسعار =============
            _buildPriceSummary(l10n, isDark),

            const SizedBox(height: AppConstants.spacingXl),

            // ============= زر الحفظ =============
            CustomButton(
              text: _isEditMode ? l10n.editProduct : l10n.addProduct,
              icon: _isEditMode ? Icons.update : Icons.add,
              onPressed: _saveProduct,
              isLoading: _isLoading,
              type: ButtonType.primary,
              size: ButtonSize.large,
            ),

            const SizedBox(height: AppConstants.spacingLg),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 📋 بناء رأس القسم
  // ============================================================
  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingSm),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                .withOpacity(0.1),
            borderRadius: AppConstants.borderRadiusSm,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
          ),
        ),
        const SizedBox(width: AppConstants.spacingSm),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  // ============================================================
  // 🖼️ بناء قسم الصورة
  // ============================================================
  Widget _buildImageSection(AppLocalizations l10n, bool isDark) {
    return CustomCard(
      child: Column(
        children: [
          // ← Hint: عرض معاينة الصورة
          if (_hasImage) ...[
            _buildImagePreview(isDark),
            const SizedBox(height: AppConstants.spacingMd),
          ],

          // ← Hint: أزرار الإجراءات
          Row(
            children: [
              // ← Hint: زر اختيار/تغيير الصورة
              Expanded(
                child: CustomButton(
                  text: _hasImage ? l10n.changeImage : l10n.addImage,
                  icon: _hasImage ? Icons.edit : Icons.add_photo_alternate,
                  type: ButtonType.secondary,
                  size: ButtonSize.medium,
                  onPressed: _showImageSourceDialog,
                ),
              ),

              // ← Hint: زر حذف الصورة (يظهر فقط إذا كانت هناك صورة)
              if (_hasImage) ...[
                const SizedBox(width: AppConstants.spacingSm),
                CustomButton(
                  text: l10n.delete,
                  icon: Icons.delete_outline,
                  type: ButtonType.secondary,
                  size: ButtonSize.medium,
                  onPressed: _removeImage,
                ),
              ],
            ],
          ),

          // ← Hint: ملاحظة توضيحية
          const SizedBox(height: AppConstants.spacingMd),
          Container(
            padding: AppConstants.paddingSm,
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: AppConstants.borderRadiusSm,
              border: Border.all(
                color: AppColors.info.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.info,
                ),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(
                  child: Text(
                    l10n.productImageNote,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.info,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🖼️ بناء معاينة الصورة
  // ============================================================
  Widget _buildImagePreview(bool isDark) {
    // ← Hint: تحديد مصدر الصورة (جديدة أو موجودة)
    final imageWidget = _productImage != null
        ? Image.file(
            _productImage!,
            fit: BoxFit.cover,
          )
        : (_existingImagePath != null && !_shouldDeleteImage)
            ? Image.file(
                File(_existingImagePath!),
                fit: BoxFit.cover,
              )
            : null;

    if (imageWidget == null) return const SizedBox.shrink();

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: AppConstants.borderRadiusMd,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: AppConstants.borderRadiusMd,
        child: imageWidget,
      ),
    );
  }

  // ============================================================
  // 🏢 بناء قائمة الموردين
  // ============================================================
  Widget _buildSupplierDropdown(AppLocalizations l10n, bool isDark) {
    return FutureBuilder<List<Supplier>>(
      future: _suppliersFuture,
      builder: (context, snapshot) {
        // ← Hint: حالة التحميل
        if (snapshot.connectionState == ConnectionState.waiting && !_isEditMode) {
          return Container(
            padding: AppConstants.paddingMd,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: AppConstants.borderRadiusMd,
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1.5,
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // ← Hint: حالة الخطأ
        if (snapshot.hasError) {
          return Container(
            padding: AppConstants.paddingMd,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: AppConstants.borderRadiusMd,
              border: Border.all(
                color: AppColors.error,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.error, color: AppColors.error),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(
                  child: Text(
                    l10n.errorLoadingSuppliers,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
          );
        }

        // ← Hint: حالة الفراغ
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: AppConstants.paddingMd,
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: AppConstants.borderRadiusMd,
              border: Border.all(
                color: AppColors.warning,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: AppColors.warning),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(
                  child: Text(
                    l10n.noSuppliersAddOneFirst,
                    style: const TextStyle(color: AppColors.warning),
                  ),
                ),
              ],
            ),
          );
        }

        final suppliers = snapshot.data!;
        final isValueInList = _selectedSupplier != null &&
            suppliers.any((s) => s.supplierID == _selectedSupplier!.supplierID);

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: AppConstants.borderRadiusMd,
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingMd,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Supplier>(
              value: isValueInList ? _selectedSupplier : null,
              hint: Row(
                children: [
                  Icon(
                    Icons.store,
                    size: 20,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  const SizedBox(width: AppConstants.spacingSm),
                  Text(l10n.selectSupplier),
                ],
              ),
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              items: suppliers
                  .map(
                    (supplier) => DropdownMenuItem<Supplier>(
                      value: supplier,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.info.withOpacity(0.1),
                              borderRadius: AppConstants.borderRadiusSm,
                            ),
                            child: const Icon(
                              Icons.store,
                              size: 16,
                              color: AppColors.info,
                            ),
                          ),
                          const SizedBox(width: AppConstants.spacingSm),
                          Expanded(
                            child: Text(
                              supplier.supplierName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedSupplier = value);
              },
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // 📊 بناء ملخص الأسعار
  // ============================================================
  Widget _buildPriceSummary(AppLocalizations l10n, bool isDark) {
    final costPrice = double.tryParse(
          convertArabicNumbersToEnglish(_costPriceController.text.trim()),
        ) ?? 0.0;
    final sellingPrice = double.tryParse(
          convertArabicNumbersToEnglish(_sellingPriceController.text.trim()),
        ) ?? 0.0;
    final profit = sellingPrice - costPrice;
    final profitPercentage = costPrice > 0 ? (profit / costPrice) * 100 : 0.0;

    return CustomCard(
      child: Container(
        padding: AppConstants.paddingLg,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceDark.withOpacity(0.5)
              : AppColors.surfaceLight,
          borderRadius: AppConstants.borderRadiusMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calculate,
                  color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                ),
                const SizedBox(width: AppConstants.spacingSm),
                Text(
                  l10n.pricesSummary,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.spacingLg),

            // سعر التكلفة
            _buildPriceRow(
              l10n.costPrice,
              formatCurrency(costPrice),
              AppColors.warning,
              Icons.shopping_cart_outlined,
            ),

            const SizedBox(height: AppConstants.spacingSm),

            // سعر البيع
            _buildPriceRow(
              l10n.salePrice,
              formatCurrency(sellingPrice),
              AppColors.info,
              Icons.sell_outlined,
            ),

            Divider(
              height: AppConstants.spacingLg,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),

            // الربح
            Container(
              padding: AppConstants.paddingMd,
              decoration: BoxDecoration(
                color: profit >= 0
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.error.withOpacity(0.1),
                borderRadius: AppConstants.borderRadiusMd,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        profit >= 0 ? Icons.trending_up : Icons.trending_down,
                        color: profit >= 0 ? AppColors.success : AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: AppConstants.spacingSm),
                      Text(
                        l10n.profit,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: profit >= 0 ? AppColors.success : AppColors.error,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatCurrency(profit),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: profit >= 0 ? AppColors.success : AppColors.error,
                        ),
                      ),
                      Text(
                        '${profitPercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: profit >= 0 ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ← Hint: بناء صف سعر
  Widget _buildPriceRow(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: AppConstants.spacingSm),
            Text(label),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ✅ Validators
  // ============================================================

  String? _quantityValidator(String? v) {
    final l10n = AppLocalizations.of(context)!;
    if (v == null || v.isEmpty) return l10n.fieldRequired;
    final number = int.tryParse(convertArabicNumbersToEnglish(v));
    if (number == null) return l10n.enterValidNumber;
    if (number < 0) return l10n.fieldCannotBeNegative;
    return null;
  }

  String? _priceValidator(String? v) {
    final l10n = AppLocalizations.of(context)!;
    if (v == null || v.isEmpty) return l10n.fieldRequired;
    final number = double.tryParse(convertArabicNumbersToEnglish(v));
    if (number == null) return l10n.enterValidNumber;
    if (number < 0) return l10n.fieldCannotBeNegative;
    return null;
  }
}