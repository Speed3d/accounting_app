// lib/screens/products/add_edit_product_screen.dart

import 'dart:io';
import 'package:accountant_touch/widgets/custom_card.dart';
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
import '../../helpers/accounting_integration_helper.dart';

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

  // ✅ متغير جديد للباركود التلقائي
  bool _isAutoBarcodeEnabled = true; // ← Hint: تفعيل الباركود التلقائي افتراضياً

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
  /// ← Hint: تم تبسيط النظام - جميع المشتريات نقدية فقط
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

      // ✅ توليد باركود تلقائي إذا كان الخيار مفعّل والباركود فارغ
      String? finalBarcode;
      if (_isAutoBarcodeEnabled && _barcodeController.text.trim().isEmpty) {
        // ← Hint: توليد باركود داخلي تلقائياً
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        finalBarcode = 'INTERNAL-$timestamp';
      } else {
        finalBarcode = _barcodeController.text.trim().isEmpty
            ? null
            : _barcodeController.text.trim();
      }

      // ← Hint: التحقق من عدم تكرار الباركود (إذا تم إدخاله أو توليده)
      if (finalBarcode != null && finalBarcode.isNotEmpty) {
        final barcodeExists = await _dbHelper.barcodeExists(
          finalBarcode,
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
        barcode: finalBarcode,
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

      // ════════════════════════════════════════════════════════════════
      // حفظ في قاعدة البيانات + التكامل المحاسبي
      // ════════════════════════════════════════════════════════════════
      if (widget.product == null) {
        // ══════════════════════════════════════════════════════════════
        // إضافة منتج جديد → شراء نقدي من الصندوق
        // ══════════════════════════════════════════════════════════════
        // ← Hint: تم تبسيط النظام - جميع المشتريات نقدية من الصندوق

        // 1️⃣ حفظ المنتج في قاعدة البيانات
        final productId = await _dbHelper.insertProduct(product);

        // 2️⃣ تسجيل القيد المحاسبي للشراء (نقدي دائماً)
        final accountingSuccess = await AccountingIntegrationHelper.recordProductPurchase(
          productId: productId,
          quantity: quantity,
          costPrice: costPrice,
          purchaseType: 'cash',  // ← دائماً نقدي من الصندوق
          supplierId: _selectedSupplier!.supplierID!,
        );

        if (!accountingSuccess) {
          debugPrint('⚠️ تحذير: فشل تسجيل القيد المحاسبي للمنتج الجديد');
        }

        // 3️⃣ تسجيل في Activity Log
        await _dbHelper.logActivity(
          'تم إضافة منتج جديد: ${product.productName} (شراء نقدي من الصندوق)',
        );

      } else {
        // ══════════════════════════════════════════════════════════════
        // تعديل منتج موجود
        // ══════════════════════════════════════════════════════════════

        final oldProduct = widget.product!;

        // 1️⃣ حفظ التعديلات في قاعدة البيانات أولاً
        await _dbHelper.updateProduct(product);

        // 2️⃣ التعامل المحاسبي حسب الحالة

        // 🔸 حالة خاصة: استعادة منتج من الأرشيف (كان كميته = 0، أصبحت > 0)
        if (oldProduct.quantity == 0 && quantity > 0) {
          debugPrint('📦 استعادة منتج من الأرشيف: ${product.productName}');
          debugPrint('   الكمية القديمة: 0 → الكمية الجديدة: $quantity');

          // تسجيل قيد شراء جديد (لأن المنتج يعود للمخزون)
          final accountingSuccess = await AccountingIntegrationHelper.recordProductPurchase(
            productId: product.productID!,
            quantity: quantity,
            costPrice: costPrice,
            purchaseType: 'cash',  // نقدي دائماً
            supplierId: _selectedSupplier!.supplierID!,
          );

          if (!accountingSuccess) {
            debugPrint('⚠️ تحذير: فشل تسجيل القيد المحاسبي للمنتج المستعاد');
          } else {
            debugPrint('✅ تم تسجيل قيد شراء جديد للمنتج المستعاد');
          }

        // 🔸 حالة عادية: تعديل كمية أو سعر منتج موجود
        } else if (quantity != oldProduct.quantity || costPrice != oldProduct.costPrice) {
          debugPrint('✏️ تعديل منتج موجود: ${product.productName}');
          debugPrint('   الكمية: ${oldProduct.quantity} → $quantity');
          debugPrint('   السعر: ${oldProduct.costPrice} → $costPrice');

          final quantityDifference = quantity - oldProduct.quantity;
          final costDifference = costPrice - oldProduct.costPrice;

          final adjustmentSuccess = await AccountingIntegrationHelper.recordProductAdjustment(
            productId: product.productID!,
            costDifference: costDifference,
            quantityDifference: quantityDifference,
            adjustmentReason: 'تعديل المنتج: ${product.productName}',
          );

          if (!adjustmentSuccess) {
            debugPrint('⚠️ تحذير: فشل تسجيل القيد المحاسبي لتعديل المنتج');
          } else {
            debugPrint('✅ تم تسجيل قيد التعديل بنجاح');
          }
        }

        // 3️⃣ تسجيل في Activity Log
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
  // 🎨 بناء الواجهة الرئيسية (النسخة المحدثة بنظام البطاقات)
  // ============================================================================
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
      //   title: Text(
      //     widget.product == null ? l10n.addProduct : l10n.editProduct,
      //   ),
      // ),

      /////////////////////////////////
        title: Text(widget.product == null ? l10n.addProduct : l10n.editProduct),
        actions: [
          // زر الحفظ في الـ AppBar للتجربة ونجحت
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l10n.save,
            onPressed: _isSaving ? null : _saveProduct,
          ),
        ],
      ),
      /////////////////////////////////

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
                      // 🖼️ قسم الصورة (يبقى كما هو)
                      // ============================================================
                      _buildImageSection(l10n, isDark),

                      const SizedBox(height: AppConstants.spacingLg),

                      // ============================================================
                      // 🏪 بطاقة: اختيار المورد/الشريك
                      // ============================================================
                      _buildSupplierCard(l10n, isDark),

                      const SizedBox(height: AppConstants.spacingMd),

                      // ============================================================
                      // 📝 بطاقة: معلومات المنتج (الاسم + التفاصيل)
                      // ============================================================
                      _buildProductInfoCard(l10n, isDark),

                      const SizedBox(height: AppConstants.spacingMd),

                      // ============================================================
                      // 🎨 بطاقة: التصنيف والوحدة
                      // ============================================================
                      _buildCategoryUnitCard(l10n, isDark, languageCode),

                      const SizedBox(height: AppConstants.spacingMd),

                      // ============================================================
                      // 💰 بطاقة: الكمية والأسعار + خلاصة الربح
                      // ============================================================
                      _buildPricingCard(l10n, isDark),

                      const SizedBox(height: AppConstants.spacingMd),

                      // ============================================================
                      // 📷 بطاقة: الباركود (يدوي أو تلقائي)
                      // ============================================================
                      _buildBarcodeCard(l10n, isDark),

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

  // ============================================================================
  // 🏪 بطاقة: اختيار المورد/الشريك
  // ============================================================================
  Widget _buildSupplierCard(AppLocalizations l10n, bool isDark) {
    return CustomCard(
      child: Padding(
        padding: AppConstants.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ← Hint: عنوان البطاقة
            Row(
              children: [
                Icon(
                  Icons.store,
                  size: 20,
                  color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                ),
                const SizedBox(width: AppConstants.spacingSm),
                Text(
                  l10n.supplier,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // ← Hint: Dropdown اختيار المورد
            DropdownButtonFormField<Supplier>(
              value: _selectedSupplier,
              decoration: InputDecoration(
                labelText: 'اختر المورد',
                prefixIcon: const Icon(Icons.person),
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
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // 📝 بطاقة: معلومات المنتج (الاسم + التفاصيل)
  // ============================================================================
  Widget _buildProductInfoCard(AppLocalizations l10n, bool isDark) {
    return CustomCard(
      child: Padding(
        padding: AppConstants.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ← Hint: عنوان البطاقة
            Row(
              children: [
                Icon(
                  Icons.inventory_2,
                  size: 20,
                  color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                ),
                const SizedBox(width: AppConstants.spacingSm),
                Text(
                  'معلومات المنتج',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // ← Hint: اسم المنتج
            CustomTextField(
              controller: _nameController,
              label: l10n.productName,
              hint: 'مثال: لابتوب Dell XPS 15',
              prefixIcon: Icons.text_fields,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.fieldRequired;
                }
                return null;
              },
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // ← Hint: التفاصيل (اختياري)
            CustomTextField(
              controller: _detailsController,
              label: l10n.details,
              hint: 'تفاصيل إضافية عن المنتج (اختياري)',
              prefixIcon: Icons.description,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // 🎨 بطاقة: التصنيف والوحدة
  // ============================================================================
  Widget _buildCategoryUnitCard(
    AppLocalizations l10n,
    bool isDark,
    String languageCode,
  ) {
    return CustomCard(
      child: Padding(
        padding: AppConstants.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ← Hint: عنوان البطاقة
            Row(
              children: [
                Icon(
                  Icons.category,
                  size: 20,
                  color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                ),
                const SizedBox(width: AppConstants.spacingSm),
                Text(
                  'التصنيف والوحدة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // ← Hint: اختيار التصنيف
            DropdownButtonFormField<ProductCategory>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'التصنيف',
                prefixIcon: const Icon(Icons.category),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.settings, size: 20),
                  tooltip: 'إدارة التصنيفات',
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
              items: _categories.map((category) {
                return DropdownMenuItem<ProductCategory>(
                  value: category,
                  child: Text(category.getLocalizedName(languageCode)),
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

            // ← Hint: اختيار الوحدة
            DropdownButtonFormField<ProductUnit>(
              value: _selectedUnit,
              decoration: InputDecoration(
                labelText: 'الوحدة',
                prefixIcon: const Icon(Icons.straighten),
                border: const OutlineInputBorder(),
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
                  child: Text(unit.getLocalizedName(languageCode)),
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
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // 💰 بطاقة: الكمية والأسعار + خلاصة الربح
  // ============================================================================
  Widget _buildPricingCard(AppLocalizations l10n, bool isDark) {
    // ← Hint: حساب الخلاصة بشكل تفاعلي (Reactive)
    final quantity = int.tryParse(
          convertArabicNumbersToEnglish(_quantityController.text),
        ) ?? 0;
    final costPrice = Decimal.tryParse(
          convertArabicNumbersToEnglish(_costPriceController.text),
        ) ?? Decimal.zero;
    final sellingPrice = Decimal.tryParse(
          convertArabicNumbersToEnglish(_sellingPriceController.text),
        ) ?? Decimal.zero;

    final totalCost = costPrice.multiplyByInt(quantity);
    final totalRevenue = sellingPrice.multiplyByInt(quantity);
    final totalProfit = totalRevenue - totalCost;

    return CustomCard(
      child: Padding(
        padding: AppConstants.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ← Hint: عنوان البطاقة
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  size: 20,
                  color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                ),
                const SizedBox(width: AppConstants.spacingSm),
                Text(
                  'الكمية والأسعار',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // ← Hint: الكمية
            CustomTextField(
              controller: _quantityController,
              label: l10n.quantity,
              hint: 'مثال: 100',
              prefixIcon: Icons.inventory,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}), // ← Hint: تحديث الخلاصة عند التغيير
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

            // ← Hint: الأسعار (صف واحد)
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _costPriceController,
                    label: l10n.costPrice,
                    hint: '0',
                    prefixIcon: Icons.shopping_cart,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}), // ← Hint: تحديث الخلاصة
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
                Expanded(
                  child: CustomTextField(
                    controller: _sellingPriceController,
                    label: l10n.sellingPrice,
                    hint: '0',
                    prefixIcon: Icons.sell,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}), // ← Hint: تحديث الخلاصة
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

            const SizedBox(height: AppConstants.spacingLg),

            // ============= ✨ خلاصة الربح =============
            Container(
              padding: AppConstants.paddingMd,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.success.withOpacity(0.1) : AppColors.success.withOpacity(0.05)),
                borderRadius: AppConstants.borderRadiusMd,
                border: Border.all(
                  color: AppColors.success.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.calculate, size: 20, color: AppColors.success),
                      const SizedBox(width: AppConstants.spacingSm),
                      Text(
                        'خلاصة الربح',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingSm),
                  Divider(color: AppColors.success.withOpacity(0.2)),
                  const SizedBox(height: AppConstants.spacingSm),
                  _buildProfitRow('التكلفة الإجمالية:', formatCurrency(totalCost), AppColors.warning),
                  const SizedBox(height: AppConstants.spacingXs),
                  _buildProfitRow('الإيراد المتوقع:', formatCurrency(totalRevenue), AppColors.info),
                  const SizedBox(height: AppConstants.spacingXs),
                  Divider(color: AppColors.success.withOpacity(0.2)),
                  const SizedBox(height: AppConstants.spacingXs),
                  _buildProfitRow(
                    'الربح الصافي:',
                    formatCurrency(totalProfit),
                    totalProfit >= Decimal.zero ? AppColors.success : AppColors.error,
                    isBold: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ← Hint: دالة مساعدة لبناء صف في خلاصة الربح
  Widget _buildProfitRow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // 📷 بطاقة: الباركود (يدوي أو تلقائي)
  // ============================================================================
  Widget _buildBarcodeCard(AppLocalizations l10n, bool isDark) {
    return CustomCard(
      child: Padding(
        padding: AppConstants.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ← Hint: عنوان البطاقة
            Row(
              children: [
                Icon(
                  Icons.qr_code,
                  size: 20,
                  color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                ),
                const SizedBox(width: AppConstants.spacingSm),
                Text(
                  'الباركود',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // ← Hint: Switch لتفعيل/تعطيل الباركود التلقائي
            SwitchListTile(
              title: const Text('توليد باركود تلقائياً'),
              subtitle: const Text('إذا لم تُدخل باركوداً، سيتم توليده تلقائياً عند الحفظ'),
              value: _isAutoBarcodeEnabled,
              onChanged: (value) {
                setState(() => _isAutoBarcodeEnabled = value);
              },
              activeColor: AppColors.success,
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // ← Hint: حقل الباركود (يظهر فقط إذا كان الوضع يدوي)
            if (!_isAutoBarcodeEnabled) ...[
              CustomTextField(
                controller: _barcodeController,
                label: 'الباركود',
                hint: 'أدخل الباركود يدوياً',
                prefixIcon: Icons.tag,
              ),

              const SizedBox(height: AppConstants.spacingMd),

              // ← Hint: أزرار مسح وتوليد الباركود
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
                      label: const Text('توليد الآن'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // ← Hint: رسالة إعلامية عند تفعيل الباركود التلقائي
              Container(
                padding: AppConstants.paddingMd,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: AppConstants.borderRadiusMd,
                  border: Border.all(
                    color: AppColors.success.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.success, size: 20),
                    const SizedBox(width: AppConstants.spacingSm),
                    Expanded(
                      child: Text(
                        'سيتم توليد باركود فريد تلقائياً عند حفظ المنتج',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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