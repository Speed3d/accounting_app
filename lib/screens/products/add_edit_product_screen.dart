// lib/screens/products/add_edit_product_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../services/auth_service.dart';
import '../../utils/helpers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_card.dart';
import 'barcode_scanner_screen.dart';

/// ===========================================================================
/// شاشة إضافة/تعديل منتج (Add/Edit Product Screen)
/// ===========================================================================
/// الغرض:
/// - إضافة منتج جديد مع صورة اختيارية
/// - تعديل بيانات منتج موجود
/// - اختيار صورة من الكاميرا أو المعرض
/// - حفظ البيانات في قاعدة البيانات
/// ===========================================================================
class AddEditProductScreen extends StatefulWidget {
  final Product? product; // null = وضع الإضافة، موجود = وضع التعديل

  const AddEditProductScreen({
    super.key,
    this.product,
  });

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  
  // ============= متغيرات النموذج =============
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _detailsController = TextEditingController();
  final _quantityController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _barcodeController = TextEditingController();
  
  // ============= الخدمات =============
  final dbHelper = DatabaseHelper.instance;
  final AuthService _authService = AuthService();
  
  // ============= متغيرات الحالة =============
  File? _imageFile;                    // الصورة المختارة
  bool _isLoading = false;             // حالة الحفظ
  Supplier? _selectedSupplier;         // المورد المختار
  late Future<List<Supplier>> _suppliersFuture; // قائمة الموردين
  
  // ============= Getters =============
  bool get _isEditMode => widget.product != null;

  // ===========================================================================
  // التهيئة الأولية
  // ===========================================================================
  @override
  void initState() {
    super.initState();
    _suppliersFuture = dbHelper.getAllSuppliers();
    
    // إذا كنا في وضع التعديل، املأ الحقول بالبيانات الموجودة
    if (_isEditMode) {
      final product = widget.product!;
      _nameController.text = product.productName;
      _detailsController.text = product.productDetails ?? '';
      _quantityController.text = product.quantity.toString();
      _costPriceController.text = product.costPrice.toString();
      _sellingPriceController.text = product.sellingPrice.toString();
      _barcodeController.text = product.barcode ?? '';
      
      // تحميل الصورة إذا كانت موجودة
      if (product.imagePath != null && product.imagePath!.isNotEmpty) {
        final imageFile = File(product.imagePath!);
        if (imageFile.existsSync()) {
          _imageFile = imageFile;
        }
      }
      
      // تحميل المورد المرتبط
      _suppliersFuture.then((suppliers) {
        if (suppliers.isNotEmpty) {
          try {
            final foundSupplier = suppliers.firstWhere(
              (s) => s.supplierID == product.supplierID,
            );
            setState(() => _selectedSupplier = foundSupplier);
          } catch (_) {}
        }
      });
    }
  }

  // ===========================================================================
  // التنظيف
  // ===========================================================================
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

  // ===========================================================================
  // اختيار صورة
  // ===========================================================================
  Future<void> _pickImage(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    
    try {
      final picker = ImagePicker();
      
      // اختيار الصورة
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80, // ضغط الصورة لتوفير المساحة
      );
      
      if (pickedFile == null) return; // المستخدم ألغى العملية
      
      // حفظ الصورة في مجلد التطبيق
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}${p.extension(pickedFile.path)}';
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
      
      setState(() {
        _imageFile = savedImage;
      });
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorPickingImage(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ===========================================================================
  // مسح الباركود
  // ===========================================================================
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

  // ===========================================================================
  // حفظ المنتج
  // ===========================================================================
  Future<void> _saveProduct() async {
    final l10n = AppLocalizations.of(context)!;
    
    // التحقق من صحة النموذج
    if (!_formKey.currentState!.validate()) return;
    
    // التحقق من اختيار المورد
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectSupplier),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    // بدء التحميل
    setState(() => _isLoading = true);
    
    try {
      // إنشاء باركود تلقائي إذا كان فارغاً
      String barcodeToSave = _barcodeController.text.trim();
      if (barcodeToSave.isEmpty) {
        barcodeToSave = 'INTERNAL-${DateTime.now().millisecondsSinceEpoch}';
      }
      
      // التحقق من تكرار الباركود
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

      String action;
      String successMessage;
      
      if (_isEditMode) {
        // ============= وضع التعديل =============
        final updatedProduct = Product(
          productID: widget.product!.productID,
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
          imagePath: _imageFile?.path,
        );
        
        await dbHelper.updateProduct(updatedProduct);
        action = '${l10n.editProduct}: ${updatedProduct.productName}';
        successMessage = l10n.productUpdatedSuccess;
        
      } else {
        // ============= وضع الإضافة =============
        final newProduct = Product(
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
          imagePath: _imageFile?.path,
        );
        
        await dbHelper.insertProduct(newProduct);
        action = '${l10n.addProduct}: ${newProduct.productName}';
        successMessage = l10n.productAddedSuccess;
      }
      
      // تسجيل النشاط
      await dbHelper.logActivity(
        action,
        userId: _authService.currentUser?.id,
        userName: _authService.currentUser?.fullName,
      );
      
      if (mounted) {
        // عرض رسالة نجاح
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: AppColors.success,
          ),
        );
        
        // العودة للصفحة السابقة مع إشعار بالنجاح
        Navigator.of(context).pop(true);
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ===========================================================================
  // بناء واجهة المستخدم
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      // ============= AppBar =============
      appBar: AppBar(
        title: Text(_isEditMode ? l10n.editProduct : l10n.addProduct),
        actions: [
          // زر الحفظ في الـ AppBar
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
            // ============= صورة المنتج =============
            _buildImageSection(l10n),
            
            const SizedBox(height: AppConstants.spacingXl),
            
            // ============= قسم المورد =============
            _buildSupplierSection(l10n),
            
            const SizedBox(height: AppConstants.spacingXl),
            
            // ============= قسم معلومات المنتج =============
            _buildProductInfoSection(l10n),
            
            const SizedBox(height: AppConstants.spacingXl),
            
            // ============= قسم الكميات والأسعار =============
            _buildPricesSection(l10n),
            
            const SizedBox(height: AppConstants.spacingXl),
            
            // ============= ملخص الأسعار =============
            _buildPriceSummary(l10n),
            
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

  // ===========================================================================
  // بناء قسم الصورة
  // ===========================================================================
  Widget _buildImageSection(AppLocalizations l10n) {
    return Center(
      child: Stack(
        children: [
          // ============= الصورة الرمزية =============
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child: _imageFile != null
                ? Image.file(
                    _imageFile!,
                    fit: BoxFit.cover,
                  )
                : Icon(
                    Icons.inventory_2,
                    size: 70,
                    color: AppColors.primaryLight.withOpacity(0.3),
                  ),
            ),
          ),
          
          // ============= زر الكاميرا =============
          Positioned(
            bottom: 0,
            right: 0,
            child: Material(
              color: AppColors.primaryLight,
              shape: const CircleBorder(),
              elevation: 4,
              child: InkWell(
                onTap: () => _showImageSourceDialog(l10n),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // بناء قسم المورد
  // ===========================================================================
  Widget _buildSupplierSection(AppLocalizations l10n) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingSm),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: AppConstants.borderRadiusSm,
                ),
                child: const Icon(
                  Icons.store,
                  color: AppColors.info,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Text(
                l10n.supplierInfo,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.spacingLg),
          
          // قائمة الموردين
          _buildSupplierDropdown(l10n),
        ],
      ),
    );
  }

  // ===========================================================================
  // بناء قائمة الموردين المنسدلة
  // ===========================================================================
  Widget _buildSupplierDropdown(AppLocalizations l10n) {
    return FutureBuilder<List<Supplier>>(
      future: _suppliersFuture,
      builder: (context, snapshot) {
        // حالة التحميل
        if (snapshot.connectionState == ConnectionState.waiting && !_isEditMode) {
          return Container(
            padding: AppConstants.paddingMd,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: AppConstants.borderRadiusMd,
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1.5,
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // حالة الخطأ
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

        // حالة البيانات الفارغة
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
            color: Theme.of(context).cardColor,
            borderRadius: AppConstants.borderRadiusMd,
            border: Border.all(
              color: Theme.of(context).dividerColor,
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
                    color: Theme.of(context).hintColor,
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

  // ===========================================================================
  // بناء قسم معلومات المنتج
  // ===========================================================================
  Widget _buildProductInfoSection(AppLocalizations l10n) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingSm),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: AppConstants.borderRadiusSm,
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Text(
                l10n.productInfo,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.spacingLg),
          
          // اسم المنتج
          CustomTextField(
            controller: _nameController,
            label: l10n.productName,
            hint: l10n.enterProductName,
            prefixIcon: Icons.inventory_2_outlined,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.productNameRequired;
              }
              return null;
            },
          ),
          
          const SizedBox(height: AppConstants.spacingMd),
          
          // الباركود
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
          
          // تفاصيل المنتج
          CustomTextField(
            controller: _detailsController,
            label: l10n.productDetailsOptional,
            hint: l10n.enterProductDetails,
            prefixIcon: Icons.description_outlined,
            maxLines: 3,
            textInputAction: TextInputAction.next,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // بناء قسم الكميات والأسعار
  // ===========================================================================
  Widget _buildPricesSection(AppLocalizations l10n) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingSm),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: AppConstants.borderRadiusSm,
                ),
                child: const Icon(
                  Icons.attach_money,
                  color: AppColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Text(
                l10n.quantityAndPrices,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.spacingLg),
          
          // الكمية
          CustomTextField(
            controller: _quantityController,
            label: l10n.quantity,
            hint: l10n.enterQuantity,
            prefixIcon: Icons.inventory_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.fieldRequired;
              }
              final number = int.tryParse(convertArabicNumbersToEnglish(value));
              if (number == null) {
                return l10n.enterValidNumber;
              }
              if (number < 0) {
                return l10n.fieldCannotBeNegative;
              }
              return null;
            },
          ),
          
          const SizedBox(height: AppConstants.spacingMd),
          
          // سعر الشراء
          CustomTextField(
            controller: _costPriceController,
            label: l10n.costPrice,
            hint: l10n.purchasePrice,
            prefixIcon: Icons.shopping_cart_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.fieldRequired;
              }
              final number = double.tryParse(convertArabicNumbersToEnglish(value));
              if (number == null) {
                return l10n.enterValidNumber;
              }
              if (number < 0) {
                return l10n.fieldCannotBeNegative;
              }
              return null;
            },
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
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.fieldRequired;
              }
              final number = double.tryParse(convertArabicNumbersToEnglish(value));
              if (number == null) {
                return l10n.enterValidNumber;
              }
              if (number < 0) {
                return l10n.fieldCannotBeNegative;
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // بناء ملخص الأسعار
  // ===========================================================================
  Widget _buildPriceSummary(AppLocalizations l10n) {
    final costPrice = Decimal.tryParse(
          // convertArabicNumbersToEnglish(_costPriceController.text.trim()),
          convertArabicNumbersToEnglish(_costPriceController.text.trim()),
        ) ?? Decimal.zero;
    final sellingPrice = double.tryParse(
          convertArabicNumbersToEnglish(_sellingPriceController.text.trim()),
        ) ?? 0.0;
    final profit = sellingPrice - costPrice;
    final profitPercentage = costPrice > 0 ? (profit / costPrice) * 100 : 0.0;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingSm),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.1),
                  borderRadius: AppConstants.borderRadiusSm,
                ),
                child: const Icon(
                  Icons.calculate,
                  color: AppColors.primaryLight,
                  size: 20,
                ),
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
          
          // سعر الشراء
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
            color: Theme.of(context).dividerColor,
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
    );
  }

  // ===========================================================================
  // بناء صف السعر
  // ===========================================================================
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

  // ===========================================================================
  // مربع حوار اختيار مصدر الصورة
  // ===========================================================================
  void _showImageSourceDialog(AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusLg),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: AppConstants.paddingMd,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ============= عنوان =============
              Text(
                l10n.imageSource,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              
              const SizedBox(height: AppConstants.spacingLg),
              
              // ============= خيار المعرض =============
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppConstants.spacingSm),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: AppConstants.borderRadiusMd,
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: AppColors.info,
                  ),
                ),
                title: Text(l10n.gallery),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              
              const SizedBox(height: AppConstants.spacingSm),
              
              // ============= خيار الكاميرا =============
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppConstants.spacingSm),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: AppConstants.borderRadiusMd,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: AppColors.success,
                  ),
                ),
                title: Text(l10n.camera),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              
              const SizedBox(height: AppConstants.spacingMd),
              
              // ============= زر الإلغاء =============
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.cancel),
              ),
              
              const SizedBox(height: AppConstants.spacingSm),
            ],
          ),
        ),
      ),
    );
  }
}