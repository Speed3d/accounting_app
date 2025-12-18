// lib/screens/products/inactive_products_screen.dart

import 'dart:io';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../utils/helpers.dart';
import '../../utils/decimal_extensions.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_state.dart';

/// ===========================================================================
/// 🔒 شاشة المنتجات المعطلة (كمية = 0)
/// ===========================================================================
/// الوظيفة: عرض المنتجات التي كمياتها = 0 مع إمكانية استعادتها
///
/// الشروط:
/// - يجب التحقق من أن المنتج من نفس المورد قبل الاستعادة
/// - إذا كان من مورد مختلف: رفض الاستعادة
/// - السماح بإضافة كمية جديدة لاستعادة المنتج
/// ===========================================================================
class InactiveProductsScreen extends StatefulWidget {
  const InactiveProductsScreen({super.key});

  @override
  State<InactiveProductsScreen> createState() => _InactiveProductsScreenState();
}

class _InactiveProductsScreenState extends State<InactiveProductsScreen> {
  // ============= المتغيرات =============
  final dbHelper = DatabaseHelper.instance;
  late Future<List<Product>> _productsFuture;
  final _searchController = TextEditingController();

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];

  // ============= دورة الحياة =============
  @override
  void initState() {
    super.initState();
    _reloadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Hint: تحميل المنتجات المعطلة (كمية = 0)
  Future<void> _reloadProducts() async {
    setState(() {
      _productsFuture = dbHelper.getInactiveProducts();
    });

    try {
      final products = await _productsFuture;
      setState(() {
        _allProducts = products;
        _filteredProducts = products;
      });
    } catch (e) {
      debugPrint('❌ خطأ في تحميل المنتجات المعطلة: $e');
    }
  }

  /// Hint: البحث في قائمة المنتجات
  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts.where((product) {
          final nameLower = product.productName.toLowerCase();
          final supplierLower = (product.supplierName ?? '').toLowerCase();
          final queryLower = query.toLowerCase();

          return nameLower.contains(queryLower) || supplierLower.contains(queryLower);
        }).toList();
      }
    });
  }

  /// ✅ Hint: استعادة منتج (مع التحقق من المورد)
  Future<void> _handleRestoreProduct(Product product) async {
    final l10n = AppLocalizations.of(context)!;

    // === الخطوة 1: جلب معلومات المورد الحالي ===
    final currentSupplier = product.supplierID != null
        ? await dbHelper.getSupplierById(product.supplierID!)
        : null;

    if (currentSupplier == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('خطأ: لم يتم العثور على معلومات المورد'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // === الخطوة 2: عرض حوار إدخال الكمية الجديدة ===
    await _showRestoreDialog(product, currentSupplier);
  }

  /// ✅ Hint: حوار استعادة المنتج
  Future<void> _showRestoreDialog(Product product, Supplier currentSupplier) async {
    final l10n = AppLocalizations.of(context)!;
    final quantityController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.restore, color: AppColors.success),
            const SizedBox(width: AppConstants.spacingSm),
            const Expanded(child: Text('استعادة المنتج')),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // اسم المنتج
              Text(
                'المنتج: ${product.productName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppConstants.spacingSm),

              // المورد
              Container(
                padding: AppConstants.paddingSm,
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: AppConstants.borderRadiusSm,
                ),
                child: Row(
                  children: [
                    Icon(Icons.store, size: 16, color: AppColors.info),
                    const SizedBox(width: AppConstants.spacingXs),
                    Expanded(
                      child: Text(
                        'المورد: ${currentSupplier.supplierName}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.info,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spacingMd),

              // تحذير مهم
              Container(
                padding: AppConstants.paddingSm,
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: AppConstants.borderRadiusSm,
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber, size: 16, color: AppColors.warning),
                    const SizedBox(width: AppConstants.spacingXs),
                    Expanded(
                      child: Text(
                        'تنبيه: يجب أن يكون المورد الحالي هو نفسه عند استعادة المنتج لضمان دقة الحسابات',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spacingLg),

              // إدخال الكمية
              CustomTextField(
                controller: quantityController,
                label: 'الكمية الجديدة',
                hint: 'أدخل الكمية المتوفرة',
                prefixIcon: Icons.inventory_2,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال الكمية';
                  }
                  final quantity = int.tryParse(value);
                  if (quantity == null || quantity <= 0) {
                    return 'يجب أن تكون الكمية أكبر من صفر';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final quantity = int.parse(quantityController.text);
                Navigator.pop(ctx, quantity);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('استعادة'),
          ),
        ],
      ),
    );

    // === الخطوة 3: تنفيذ الاستعادة ===
    if (result != null && mounted) {
      await _restoreProduct(product, currentSupplier, result);
    }
  }

  /// ✅ Hint: تنفيذ استعادة المنتج
  Future<void> _restoreProduct(
    Product product,
    Supplier currentSupplier,
    int newQuantity,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      // === التحقق النهائي من المورد ===
      // في حالة المنتجات المعطلة، نسمح بالاستعادة فقط إذا كان نفس المورد
      // هذا يضمن دقة الحسابات المالية

      // ← Hint: تحديث الكمية في قاعدة البيانات
      await dbHelper.reactivateProduct(product.productID!, newQuantity);

      // ← Hint: تسجيل النشاط
      await dbHelper.logActivity(
        'استعادة منتج: ${product.productName} بكمية $newQuantity من مورد: ${currentSupplier.supplierName}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(
                  child: Text('تم استعادة ${product.productName} بنجاح'),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // ← Hint: العودة للصفحة السابقة مع إشعار بالتحديث
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في استعادة المنتج: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ===========================================================================
  // 🎨 بناء الواجهة
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.inventory_outlined,
              color: isDark ? AppColors.textPrimaryDark : Colors.white,
            ),
            const SizedBox(width: AppConstants.spacingSm),
            const Text('المنتجات المعطلة'),
          ],
        ),
        actions: [
          if (_allProducts.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingMd,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingMd,
                vertical: AppConstants.spacingSm,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.2),
                borderRadius: AppConstants.borderRadiusFull,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inventory_outlined,
                    size: 16,
                    color: isDark ? Colors.white : Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_allProducts.length}',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),

      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return LoadingState(message: l10n.loadingProducts);
          }

          if (snapshot.hasError) {
            return ErrorState(
              message: snapshot.error.toString(),
              onRetry: _reloadProducts,
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyState(
              icon: Icons.check_circle_outline,
              title: 'لا توجد منتجات معطلة',
              message: 'جميع المنتجات لديها كميات متوفرة',
            );
          }

          return Column(
            children: [
              _buildSearchBar(l10n),
              _buildInfoBanner(),
              Expanded(
                child: _filteredProducts.isEmpty
                    ? _buildNoResultsState(l10n)
                    : _buildProductsList(),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 🔍 شريط البحث
  Widget _buildSearchBar(AppLocalizations l10n) {
    return Container(
      padding: AppConstants.paddingMd,
      child: TextField(
        controller: _searchController,
        onChanged: _filterProducts,
        decoration: InputDecoration(
          hintText: 'ابحث عن منتج معطل...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterProducts('');
                  },
                )
              : null,
        ),
      ),
    );
  }

  /// ℹ️ بانر معلومات
  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacingMd),
      padding: AppConstants.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: AppConstants.borderRadiusMd,
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.info, size: 20),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: Text(
              'يمكنك استعادة المنتجات بإضافة كمية جديدة. سيتم التحقق من المورد الأصلي.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📭 حالة عدم وجود نتائج
  Widget _buildNoResultsState(AppLocalizations l10n) {
    return EmptyState(
      icon: Icons.search_off,
      title: l10n.noMatchingResults,
      message: l10n.tryAnotherSearch,
    );
  }

  /// 📜 قائمة المنتجات
  Widget _buildProductsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  /// 🃏 بطاقة منتج
  Widget _buildProductCard(Product product) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasImage = product.imagePath != null &&
                     product.imagePath!.isNotEmpty &&
                     File(product.imagePath!).existsSync();

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // صورة المنتج
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: AppConstants.borderRadiusSm,
                  image: hasImage
                      ? DecorationImage(
                          image: FileImage(File(product.imagePath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: !hasImage
                    ? Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.warning,
                        size: 30,
                      )
                    : null,
              ),

              const SizedBox(width: AppConstants.spacingMd),

              // معلومات المنتج
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // اسم المنتج
                    Text(
                      product.productName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),

                    const SizedBox(height: AppConstants.spacingXs),

                    // المورد
                    Row(
                      children: [
                        Icon(Icons.store, size: 14, color: AppColors.info),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            product.supplierName ?? 'غير محدد',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.info,
                                ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppConstants.spacingXs),

                    // السعر
                    Text(
                      'السعر: ${formatCurrency(product.sellingPrice)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              // زر الاستعادة
              ElevatedButton.icon(
                onPressed: () => _handleRestoreProduct(product),
                icon: const Icon(Icons.restore, size: 18),
                label: const Text('استعادة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingMd,
                    vertical: AppConstants.spacingSm,
                  ),
                ),
              ),
            ],
          ),

          // شارة تحذير
          const SizedBox(height: AppConstants.spacingSm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingSm,
              vertical: AppConstants.spacingXs,
            ),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: AppConstants.borderRadiusFull,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber,
                  size: 14,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 4),
                Text(
                  'الكمية: 0',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
