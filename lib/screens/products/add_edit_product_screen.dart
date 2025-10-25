// lib/screens/products/add_edit_product_screen.dart

import 'package:flutter/material.dart';
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
/// Hint: نموذج شامل لإدخال بيانات المنتج
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

  // Controllers
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

  // ============= Getters =============
  bool get _isEditMode => widget.product != null;

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

  /// تهيئة النموذج
  void _initializeForm() {
    if (_isEditMode) {
      final p = widget.product!;
      _nameController.text = p.productName;
      _detailsController.text = p.productDetails ?? '';
      _quantityController.text = p.quantity.toString();
      _costPriceController.text = p.costPrice.toString();
      _sellingPriceController.text = p.sellingPrice.toString();
      _barcodeController.text = p.barcode ?? '';

      // تحميل المورد
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

    // التحقق من صحة البيانات
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
      // معالجة الباركود
      String barcodeToSave = _barcodeController.text.trim();
      if (barcodeToSave.isEmpty) {
        barcodeToSave = 'INTERNAL-${DateTime.now().millisecondsSinceEpoch}';
      }

      // التحقق من عدم تكرار الباركود
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
      );

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
            _buildSectionHeader('معلومات المورد', Icons.store, isDark),
            const SizedBox(height: AppConstants.spacingMd),

            _buildSupplierDropdown(l10n, isDark),

            const SizedBox(height: AppConstants.spacingXl),

            // ============= معلومات المنتج =============
            _buildSectionHeader('معلومات المنتج', Icons.info_outline, isDark),
            const SizedBox(height: AppConstants.spacingMd),

            // اسم المنتج
            CustomTextField(
              controller: _nameController,
              label: l10n.productName,
              hint: 'أدخل اسم المنتج',
              prefixIcon: Icons.inventory_2_outlined,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.productNameRequired : null,
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // الباركود
             CustomTextField(
             controller: _barcodeController,
             label: l10n.barcode,
             hint: 'امسح أو أدخل الباركود',
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
              hint: 'أدخل تفاصيل المنتج',
              prefixIcon: Icons.description_outlined,
              maxLines: 3,
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: AppConstants.spacingXl),

            // ============= الكمية والأسعار =============
            _buildSectionHeader('الكمية والأسعار', Icons.attach_money, isDark),
            const SizedBox(height: AppConstants.spacingMd),

            // الكمية
            CustomTextField(
              controller: _quantityController,
              label: l10n.quantity,
              hint: 'أدخل الكمية',
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
              hint: 'سعر الشراء',
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
              hint: 'سعر البيع',
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
  // 🏢 بناء قائمة الموردين
  // ============================================================
  Widget _buildSupplierDropdown(AppLocalizations l10n, bool isDark) {
    return FutureBuilder<List<Supplier>>(
      future: _suppliersFuture,
      builder: (context, snapshot) {
        // حالة التحميل
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

        // حالة الفراغ
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
                  'ملخص الأسعار',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.spacingLg),

            // سعر التكلفة
            _buildPriceRow(
              'سعر التكلفة',
              formatCurrency(costPrice),
              AppColors.warning,
              Icons.shopping_cart_outlined,
            ),

            const SizedBox(height: AppConstants.spacingSm),

            // سعر البيع
            _buildPriceRow(
              'سعر البيع',
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
                        'الربح',
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

  /// بناء صف سعر
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