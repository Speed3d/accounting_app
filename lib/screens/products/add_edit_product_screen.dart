// lib/screens/products/add_edit_product_screen.dart

import 'dart:io';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/helpers.dart';
import '../../utils/decimal_extensions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_state.dart';
import 'barcode_scanner_screen.dart';
import 'manage_categories_units_screen.dart';

/// ============================================================================
/// 📦 شاشة إضافة/تعديل منتج (النسخة المحدثة)
/// ============================================================================
/// ← Hint: تتيح إضافة منتج جديد أو تعديل منتج موجود
/// ← Hint: مع دعم التصنيفات والوحدات المبسطة
/// ← Hint: الأسماء تتغير تلقائياً حسب اللغة (عربي/إنجليزي)
class AddEditProductScreen extends StatefulWidget {
  final Product? product;  // ← Hint: null = إضافة، قيمة = تعديل

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  // ============= المتغيرات =============
  final _dbHelper = DatabaseHelper.instance;
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  // ← Hint: Controllers للحقول النصية
  late TextEditingController _nameController;
  late TextEditingController _detailsController;
  late TextEditingController _barcodeController;
  late TextEditingController _quantityController;
  late TextEditingController _costPriceController;
  late TextEditingController _sellingPriceController;

  // ← Hint: متغيرات الموردين
  List<Supplier> _suppliers = [];
  Supplier? _selectedSupplier;
  bool _isLoadingSuppliers = true;

  // ✅ متغيرات التصنيفات والوحدات (النسخة المبسطة)
  List<ProductCategory> _categories = [];
  List<ProductUnit> _units = [];
  ProductCategory? _selectedCategory;
  ProductUnit? _selectedUnit;

  // ← Hint: مسار الصورة
  String? _imagePath;
  bool _isSaving = false;

  // ============= دورة الحياة =============
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadSuppliers();
    _loadCategoriesAndUnits();  // ← Hint: تحميل التصنيفات والوحدات
  }

  @override
  void dispose() {
    _nameController.dispose();
    _detailsController.dispose();
    _barcodeController.dispose();
    _quantityController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
  }

  /// ============================================================================
  /// تهيئة Controllers
  /// ============================================================================
  /// ← Hint: إذا كنا في وضع التعديل، نملأ الحقول بالقيم الحالية
  void _initializeControllers() {
    if (widget.product != null) {
      // ← Hint: وضع التعديل
      _nameController = TextEditingController(text: widget.product!.productName);
      _detailsController = TextEditingController(text: widget.product!.productDetails ?? '');
      _barcodeController = TextEditingController(text: widget.product!.barcode ?? '');
      _quantityController = TextEditingController(text: widget.product!.quantity.toString());
      _costPriceController = TextEditingController(text: widget.product!.costPrice.toString());
      _sellingPriceController = TextEditingController(text: widget.product!.sellingPrice.toString());
      _imagePath = widget.product!.imagePath;
    } else {
      // ← Hint: وضع الإضافة
      _nameController = TextEditingController();
      _detailsController = TextEditingController();
      _barcodeController = TextEditingController();
      _quantityController = TextEditingController(text: '1');
      _costPriceController = TextEditingController(text: '0');
      _sellingPriceController = TextEditingController(text: '0');
    }
  }

  /// ============================================================================
  /// تحميل قائمة الموردين
  /// ============================================================================
  Future<void> _loadSuppliers() async {
    try {
      final suppliers = await _dbHelper.getAllSuppliers();
      
      if (mounted) {
        setState(() {
          _suppliers = suppliers;
          _isLoadingSuppliers = false;

          // ← Hint: إذا كنا في وضع التعديل، نحدد المورد الحالي
          if (widget.product != null) {
            _selectedSupplier = _suppliers.firstWhere(
              (supplier) => supplier.supplierID == widget.product!.supplierID,
              orElse: () => _suppliers.isNotEmpty ? _suppliers.first : Supplier(
                supplierName: '',
                supplierType: '',
                dateAdded: DateTime.now().toIso8601String(),
              ),
            );
          } else {
            // ← Hint: في وضع الإضافة، نختار الأول افتراضياً
            _selectedSupplier = _suppliers.isNotEmpty ? _suppliers.first : null;
          }
        });
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الموردين: $e');
      if (mounted) {
        setState(() => _isLoadingSuppliers = false);
      }
    }
  }

  /// ============================================================================
  /// تحميل التصنيفات والوحدات (النسخة المبسطة)
  /// ============================================================================
  /// ← Hint: يتم تحميلها مرة واحدة عند فتح الشاشة
  /// ← Hint: إذا كنا في وضع التعديل، نحدد القيم الحالية
  Future<void> _loadCategoriesAndUnits() async {
    try {
      final categories = await _dbHelper.getProductCategories();
      final units = await _dbHelper.getProductUnits();

      if (mounted) {
        setState(() {
          _categories = categories;
          _units = units;

          // ← Hint: إذا كنا في وضع التعديل، نحدد القيم الحالية
          if (widget.product != null) {
            // ← Hint: البحث عن التصنيف الحالي
            if (widget.product!.categoryID != null) {
              _selectedCategory = _categories.firstWhere(
                (cat) => cat.categoryID == widget.product!.categoryID,
                orElse: () => _categories.isNotEmpty ? _categories.first : ProductCategory(
                  categoryNameAr: '',
                  categoryNameEn: '',
                ),
              );
            } else {
              _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
            }

            // ← Hint: البحث عن الوحدة الحالية
            if (widget.product!.unitID != null) {
              _selectedUnit = _units.firstWhere(
                (unit) => unit.unitID == widget.product!.unitID,
                orElse: () => _units.isNotEmpty ? _units.first : ProductUnit(
                  unitNameAr: '',
                  unitNameEn: '',
                ),
              );
            } else {
              _selectedUnit = _units.isNotEmpty ? _units.first : null;
            }
          } else {
            // ← Hint: في وضع الإضافة، نختار الأول افتراضياً
            _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
            _selectedUnit = _units.isNotEmpty ? _units.first : null;
          }
        });
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل التصنيفات والوحدات: $e');
    }
  }

  /// ============================================================================
  /// اختيار صورة من المعرض
  /// ============================================================================
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,  // ← Hint: ضغط الصورة لتوفير المساحة
      );

      if (image != null && mounted) {
        setState(() => _imagePath = image.path);
      }
    } catch (e) {
      debugPrint('❌ خطأ في اختيار الصورة: $e');
    }
  }

  /// ============================================================================
  /// التقاط صورة بالكاميرا
  /// ============================================================================
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (image != null && mounted) {
        setState(() => _imagePath = image.path);
      }
    } catch (e) {
      debugPrint('❌ خطأ في التقاط الصورة: $e');
    }
  }

  /// ============================================================================
  /// مسح الباركود
  /// ============================================================================
  Future<void> _scanBarcode() async {
    final String? barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );

    if (barcode != null && mounted) {
      _barcodeController.text = barcode;
    }
  }

  /// ============================================================================
  /// توليد باركود داخلي تلقائي
  /// ============================================================================
  /// ← Hint: يُستخدم عند عدم وجود باركود للمنتج
  /// ← Hint: الصيغة: INTERNAL-{timestamp}
  Future<void> _generateInternalBarcode() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final internalBarcode = 'INTERNAL-$timestamp';
    
    setState(() {
      _barcodeController.text = internalBarcode;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم توليد باركود داخلي تلقائياً'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// ============================================================================
  /// دالة الحفظ (محدثة لحفظ التصنيف والوحدة)
  /// ============================================================================
  Future<void> _saveProduct() async {
    final l10n = AppLocalizations.of(context)!;

    // ← Hint: التحقق من صحة النموذج
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // ← Hint: التحقق من اختيار مورد
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectSupplier ?? 'يرجى اختيار المورد'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // ← Hint: تحويل النصوص إلى Decimal
      final costPrice = Decimal.parse(
        convertArabicNumbersToEnglish(_costPriceController.text),
      );
      final sellingPrice = Decimal.parse(
        convertArabicNumbersToEnglish(_sellingPriceController.text),
      );
      final quantity = int.parse(
        convertArabicNumbersToEnglish(_quantityController.text),
      );

      // ← Hint: التحقق من صحة الأسعار
      if (costPrice < Decimal.zero) {
        throw Exception('سعر الشراء لا يمكن أن يكون سالباً');
      }

      if (sellingPrice < Decimal.zero) {
        throw Exception('سعر البيع لا يمكن أن يكون سالباً');
      }

      if (quantity < 0) {
        throw Exception('الكمية لا يمكن أن تكون سالبة');
      }

      // ← Hint: التحقق من عدم تكرار الباركود (إذا تم إدخاله)
      if (_barcodeController.text.isNotEmpty) {
        final barcodeExists = await _dbHelper.barcodeExists(
          _barcodeController.text,
          currentProductId: widget.product?.productID,
        );

        if (barcodeExists) {
          throw Exception('الباركود موجود بالفعل لمنتج آخر');
        }
      }

      // ← Hint: إنشاء كائن المنتج
      final product = Product(
        productID: widget.product?.productID,
        productName: _nameController.text.trim(),
        productDetails: _detailsController.text.trim().isEmpty 
            ? null 
            : _detailsController.text.trim(),
        barcode: _barcodeController.text.trim().isEmpty 
            ? null 
            : _barcodeController.text.trim(),
        quantity: quantity,
        costPrice: costPrice,
        sellingPrice: sellingPrice,
        supplierID: _selectedSupplier!.supplierID!,
        imagePath: _imagePath,
        isActive: true,
        // ✅ حفظ التصنيف والوحدة
        categoryID: _selectedCategory?.categoryID,
        unitID: _selectedUnit?.unitID,
      );

      // ← Hint: حفظ في قاعدة البيانات
      if (widget.product == null) {
        // ← Hint: إضافة منتج جديد
        await _dbHelper.insertProduct(product);
        await _dbHelper.logActivity(
          'تم إضافة منتج جديد: ${product.productName}',
        );
      } else {
        // ← Hint: تعديل منتج موجود
        await _dbHelper.updateProduct(product);
        await _dbHelper.logActivity(
          'تم تعديل المنتج: ${product.productName}',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product == null
                  ? l10n.productAddedSuccess
                  : l10n.productUpdatedSuccess,
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('❌ خطأ في حفظ المنتج: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // ============================================================================
  // بناء الواجهة
  // ============================================================================
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product == null ? l10n.addProduct : l10n.editProduct,
        ),
      ),
      
      body: _isLoadingSuppliers
          ? LoadingState(message: l10n.loadingMessage)
          : _suppliers.isEmpty
              ? EmptyState(
                  icon: Icons.store_outlined,
                  title: 'لا يوجد موردين',
                  message: 'يرجى إضافة مورد أولاً قبل إضافة المنتجات',
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: AppConstants.paddingLg,
                    children: [
                      // ============================================================
                      // 🖼️ قسم الصورة
                      // ============================================================
                      _buildImageSection(l10n, isDark),

                      const SizedBox(height: AppConstants.spacingXl),

                      // ============================================================
                      // 📝 اسم المنتج
                      // ============================================================
                      CustomTextField(
                        controller: _nameController,
                        label: l10n.productName,
                        hint: 'مثال: لابتوب Dell XPS 15',
                        prefixIcon: Icons.inventory_2,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.fieldRequired;
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppConstants.spacingMd),

                      // ============================================================
                      // 📄 التفاصيل (اختياري)
                      // ============================================================
                      CustomTextField(
                        controller: _detailsController,
                        label: l10n.details,
                        hint: 'تفاصيل إضافية عن المنتج (اختياري)',
                        prefixIcon: Icons.description,
                        maxLines: 3,
                      ),

                      const SizedBox(height: AppConstants.spacingMd),

                      // ============================================================
                      // 🏪 اختيار المورد
                      // ============================================================
                      DropdownButtonFormField<Supplier>(
                        value: _selectedSupplier,
                        decoration: InputDecoration(
                          labelText: l10n.supplier,
                          prefixIcon: const Icon(Icons.store),
                          border: const OutlineInputBorder(),
                        ),
                        items: _suppliers.map((supplier) {
                          return DropdownMenuItem<Supplier>(
                            value: supplier,
                            child: Text(supplier.supplierName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedSupplier = value);
                        },
                        validator: (value) {
                          if (value == null) {
                            return l10n.pleaseSelectSupplier ?? 'يرجى اختيار المورد';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppConstants.spacingMd),

                      // ============================================================
                      // ✅ Dropdown التصنيف (النسخة المبسطة)
                      // ============================================================
                      // ← Hint: يعرض قائمة التصنيفات النشطة
                      // ← Hint: الأسماء تتغير تلقائياً حسب اللغة
                      DropdownButtonFormField<ProductCategory>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'التصنيف',
                          prefixIcon: const Icon(Icons.category),
                          border: const OutlineInputBorder(),
                          // ← Hint: زر للذهاب لصفحة إدارة التصنيفات
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.settings, size: 20),
                            tooltip: 'إدارة التصنيفات',
                            onPressed: () async {
                              // ← Hint: الانتقال لصفحة الإدارة
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ManageCategoriesUnitsScreen(),
                                ),
                              );
                              // ← Hint: إعادة تحميل القوائم بعد العودة
                              _loadCategoriesAndUnits();
                            },
                          ),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem<ProductCategory>(
                            value: category,
                            child: Row(
                              children: [
                                const Icon(Icons.category, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  // ← Hint: عرض الاسم حسب اللغة الحالية
                                  category.getLocalizedName(languageCode),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedCategory = value);
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'يرجى اختيار التصنيف';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppConstants.spacingMd),

                      // ============================================================
                      // ✅ Dropdown الوحدة (النسخة المبسطة)
                      // ============================================================
                      // ← Hint: نفس التصميم كما في التصنيف
                      DropdownButtonFormField<ProductUnit>(
                        value: _selectedUnit,
                        decoration: InputDecoration(
                          labelText: 'الوحدة',
                          prefixIcon: const Icon(Icons.straighten),
                          border: const OutlineInputBorder(),
                          // ← Hint: زر للذهاب لصفحة إدارة الوحدات
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.settings, size: 20),
                            tooltip: 'إدارة الوحدات',
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ManageCategoriesUnitsScreen(),
                                ),
                              );
                              _loadCategoriesAndUnits();
                            },
                          ),
                        ),
                        items: _units.map((unit) {
                          return DropdownMenuItem<ProductUnit>(
                            value: unit,
                            child: Row(
                              children: [
                                const Icon(Icons.straighten, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  // ← Hint: عرض الاسم حسب اللغة الحالية
                                  unit.getLocalizedName(languageCode),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedUnit = value);
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'يرجى اختيار الوحدة';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppConstants.spacingMd),

                      // ============================================================
                      // 🔢 الكمية
                      // ============================================================
                      CustomTextField(
                        controller: _quantityController,
                        label: l10n.quantity,
                        hint: 'مثال: 100',
                        prefixIcon: Icons.inventory,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.fieldRequired;
                          }
                          
                          final englishValue = convertArabicNumbersToEnglish(value);
                          final quantity = int.tryParse(englishValue);
                          
                          if (quantity == null) {
                            return l10n.enterValidNumber;
                          }
                          
                          if (quantity < 0) {
                            return 'الكمية لا يمكن أن تكون سالبة';
                          }
                          
                          return null;
                        },
                      ),

                      const SizedBox(height: AppConstants.spacingMd),

                      // ============================================================
                      // 💰 الأسعار (صف واحد)
                      // ============================================================
                      Row(
                        children: [
                          // سعر الشراء
                          Expanded(
                            child: CustomTextField(
                              controller: _costPriceController,
                              label: l10n.costPrice,
                              hint: '0.00',
                              prefixIcon: Icons.shopping_cart,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return l10n.fieldRequired;
                                }
                                
                                final englishValue = convertArabicNumbersToEnglish(value);
                                final price = Decimal.tryParse(englishValue);
                                
                                if (price == null) {
                                  return l10n.enterValidNumber;
                                }
                                
                                if (price < Decimal.zero) {
                                  return 'السعر لا يمكن أن يكون سالباً';
                                }
                                
                                return null;
                              },
                            ),
                          ),

                          const SizedBox(width: AppConstants.spacingMd),

                          // سعر البيع
                          Expanded(
                            child: CustomTextField(
                              controller: _sellingPriceController,
                              label: l10n.sellingPrice,
                              hint: '0.00',
                              prefixIcon: Icons.sell,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return l10n.fieldRequired;
                                }
                                
                                final englishValue = convertArabicNumbersToEnglish(value);
                                final price = Decimal.tryParse(englishValue);
                                
                                if (price == null) {
                                  return l10n.enterValidNumber;
                                }
                                
                                if (price < Decimal.zero) {
                                  return 'السعر لا يمكن أن يكون سالباً';
                                }
                                
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppConstants.spacingMd),

            // ============================================================
            // 📷 الباركود
            // ============================================================
              CustomTextField(
                 controller: _barcodeController,
                   label: l10n.barcode,
                   hint: 'اختياري - امسح أو أدخل يدوياً',
                   prefixIcon: Icons.qr_code,
                   ),

               const SizedBox(height: AppConstants.spacingSm),

                    // ← Hint: أزرار الباركود
                     Row(
                      children: [
                       Expanded(
                        child: OutlinedButton.icon(
                        onPressed: _scanBarcode,
                        icon: const Icon(Icons.qr_code_scanner, size: 20),
                        label: const Text('مسح الباركود'),
                        style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                     ),
                   ),
                const SizedBox(width: AppConstants.spacingSm),
                       Expanded(
                        child: OutlinedButton.icon(
                         onPressed: _generateInternalBarcode,
                          icon: const Icon(Icons.auto_awesome, size: 20),
                          label: const Text('توليد تلقائي'),
                          style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                         ),
                        ),
                       ],
                      ),

                      const SizedBox(height: AppConstants.spacingXl),

                      // ============================================================
                      // 💾 زر الحفظ
                      // ============================================================
                      CustomButton(
                        text: widget.product == null ? l10n.add : l10n.save,
                        onPressed: _isSaving ? null : _saveProduct,
                        type: ButtonType.primary,
                        isLoading: _isSaving,
                      ),

                      const SizedBox(height: AppConstants.spacingMd),
                    ],
                  ),
                ),
    );
  }

  /// ============================================================================
  /// بناء قسم الصورة
  /// ============================================================================
  Widget _buildImageSection(AppLocalizations l10n, bool isDark) {
    return Column(
      children: [
        // ← Hint: عرض الصورة أو placeholder
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: AppConstants.borderRadiusMd,
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: _imagePath != null
              ? ClipRRect(
                  borderRadius: AppConstants.borderRadiusMd,
                  child: Image.file(
                    File(_imagePath!),
                    fit: BoxFit.cover,
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 64,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(height: AppConstants.spacingSm),
                      Text(
                        'لا توجد صورة',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
        ),

        const SizedBox(height: AppConstants.spacingMd),

        // ← Hint: أزرار اختيار الصورة
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImageFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('من المعرض'),
              ),
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImageFromCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text('من الكاميرا'),
              ),
            ),
            if (_imagePath != null) ...[
              const SizedBox(width: AppConstants.spacingSm),
              IconButton(
                onPressed: () {
                  setState(() => _imagePath = null);
                },
                icon: const Icon(Icons.delete_outline),
                color: AppColors.error,
                tooltip: 'حذف الصورة',
              ),
            ],
          ],
        ),
      ],
    );
  }
}