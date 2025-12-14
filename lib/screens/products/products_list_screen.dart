// lib/screens/products/products_list_screen.dart

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
import '../../widgets/loading_state.dart';
import 'add_edit_product_screen.dart';
import 'manage_categories_units_screen.dart';

// ← Hint: تم إزالة AuthService - كل مستخدم admin الآن

/// ===========================================================================
/// 📦 شاشة قائمة المنتجات - صفحة فرعية
/// Hint: محدثة بالكامل لدعم Decimal
/// Hint: تعرض جميع المنتجات النشطة مع معلوماتها الأساسية وصورها
/// ===========================================================================
class ProductsListScreen extends StatefulWidget {
  const ProductsListScreen({super.key});

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  // ============= المتغيرات =============
  final dbHelper = DatabaseHelper.instance;
  // ← Hint: تم إزالة AuthService
  late Future<List<Product>> _productsFuture;
  final _searchController = TextEditingController();

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  String? _selectedFilter; // null = الكل، 'low' = منخفضة

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

  /// Hint: تحميل قائمة المنتجات
  Future<void> _reloadProducts() async {
    setState(() {
      _productsFuture = dbHelper.getAllProductsWithSupplierName();
    });

    try {
      final products = await _productsFuture;
      setState(() {
        _allProducts = products;
        _applyFilter();
      });
    } catch (e) {
      debugPrint('❌ خطأ في تحميل المنتجات: $e');
    }
  }

  /// Hint: تطبيق الفلتر المحدد
  void _applyFilter() {
    if (_selectedFilter == null) {
      _filteredProducts = _allProducts;
    } else if (_selectedFilter == 'low') {
      _filteredProducts = _allProducts.where((product) {
        return product.quantity < 5;
      }).toList();
    }
    
    if (_searchController.text.isNotEmpty) {
      _filterProducts(_searchController.text);
    }
  }

  /// Hint: تغيير الفلتر
  void _changeFilter(String? filter) {
    setState(() {
      _selectedFilter = filter;
      _applyFilter();
    });
  }

  /// Hint: البحث في قائمة المنتجات
  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _applyFilter();
      } else {
        List<Product> baseList = _selectedFilter == null 
            ? _allProducts 
            : _allProducts.where((p) => p.quantity < 10).toList();
            
        _filteredProducts = baseList.where((product) {
          final nameLower = product.productName.toLowerCase();
          final supplierLower = (product.supplierName ?? '').toLowerCase();
          final barcodeLower = (product.barcode ?? '').toLowerCase();
          final queryLower = query.toLowerCase();
          
          return nameLower.contains(queryLower) || 
                 supplierLower.contains(queryLower) ||
                 barcodeLower.contains(queryLower);
        }).toList();
      }
    });
  }

  /// Hint: أرشفة منتج
  Future<void> _handleArchiveProduct(Product product) async {
    final l10n = AppLocalizations.of(context)!;

    final isSold = await dbHelper.isProductSold(product.productID!);
    if (isSold) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.cannotArchiveSoldProduct),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmArchive),
        content: Text(l10n.archiveProductConfirmation(product.productName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(l10n.archive),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await dbHelper.archiveProduct(product.productID!);
      // ← Hint: لا حاجة لـ userId و userName - يتم جلبهم تلقائياً من SessionService
      await dbHelper.logActivity(
        l10n.archiveProductAction(product.productName),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(
                  child: Text(l10n.productArchivedSuccess(product.productName)),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      _reloadProducts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.productArchivedError(e.toString())),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ===========================================================================
  // Hint: بناء الواجهة
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
              Icons.inventory_2_outlined,
              color: isDark ? AppColors.textPrimaryDark : Colors.white,
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Text(l10n.productsList),
          ],
        ),
        actions: [
          // ← Hint: زر إدارة التصنيفات والوحدات
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'إدارة التصنيفات والوحدات',
            onPressed: _navigateToManageCategories,
          ),

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
                    Icons.inventory_2,
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
              icon: Icons.inventory_2_outlined,
              title: l10n.noActiveProducts,
              message: l10n.startByAddingProduct,
              actionText: l10n.addProduct,
              onAction: _navigateToAddProduct,
            );
          }

          return Column(
            children: [
              _buildSearchBar(l10n),
              _buildQuickStats(l10n, isDark),
              Expanded(
                child: _filteredProducts.isEmpty
                    ? _buildNoResultsState(l10n)
                    : _buildProductsList(),
              ),
            ],
          );
        },
      ),

      // ← Hint: كل مستخدم يمكنه الإضافة
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddProduct,
        icon: const Icon(Icons.add),
        label: Text(l10n.addProduct),
        tooltip: l10n.addNewProduct,
      ),
    );
  }

  // ===========================================================================
  // 🔍 Hint: بناء شريط البحث
  // ===========================================================================
  Widget _buildSearchBar(AppLocalizations l10n) {
    return Container(
      padding: AppConstants.paddingMd,
      child: TextField(
        controller: _searchController,
        onChanged: _filterProducts,
        decoration: InputDecoration(
          hintText: l10n.searchForProduct2,
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

  // ===========================================================================
  // 📊 Hint: بناء الإحصائيات السريعة - محدث لـ Decimal
  // ===========================================================================
  Widget _buildQuickStats(AppLocalizations l10n, bool isDark) {
    if (_allProducts.isEmpty) return const SizedBox.shrink();

    // Hint: حساب إجمالي الكمية (int - بدون تغيير)
    final totalQuantity = _allProducts.fold<int>(
      0,
      (sum, product) => sum + product.quantity,
    );
    
    // Hint: عد المنتجات منخفضة المخزون
    final lowStockCount = _allProducts.where(
      (product) => product.quantity < 10,
    ).length;

    // Hint: ✅ حساب قيمة المخزون باستخدام Decimal
    final totalValue = _allProducts.fold<Decimal>(
      Decimal.zero,
      (sum, product) {
        // Hint: sellingPrice (Decimal) × quantity (int)
        final productValue = product.sellingPrice.multiplyByInt(product.quantity);
        return sum + productValue;
      },
    );

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
      ),
      child: Row(
        children: [
          // Hint: إجمالي الكمية
          Expanded(
            child: _buildStatCard(
              icon: Icons.inventory_outlined,
              label: l10n.totalQuantity,
              value: totalQuantity.toString(),
              color: AppColors.info,
              isDark: isDark,
              filterType: null,
            ),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          
          // Hint: منتجات منخفضة
          Expanded(
            child: _buildStatCard(
              icon: Icons.warning_amber,
              label: l10n.low,
              value: lowStockCount.toString(),
              color: lowStockCount > 0 ? AppColors.warning : AppColors.success,
              isDark: isDark,
              filterType: 'low',
            ),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          
          // Hint: ✅ قيمة المخزون - تنسيق Decimal
          Expanded(
            child: _buildStatCard(
              icon: Icons.attach_money,
              label: l10n.value,
              value: formatCurrency(totalValue),
              color: AppColors.success,
              isDark: isDark,
              isCompact: true,
              filterType: null,
            ),
          ),
        ],
      ),
    );
  }

  /// Hint: بناء بطاقة إحصائية
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    bool isCompact = false,
    String? filterType,
  }) {
    final isSelected = _selectedFilter == filterType;
    
    return InkWell(
      onTap: () => _changeFilter(filterType),
      borderRadius: AppConstants.borderRadiusSm,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacingSm),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : color.withOpacity(0.1),
          borderRadius: AppConstants.borderRadiusSm,
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: isCompact ? 11 : 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 📭 Hint: حالة عدم وجود نتائج بحث
  // ===========================================================================
  Widget _buildNoResultsState(AppLocalizations l10n) {
    return EmptyState(
      icon: Icons.search_off,
      title: l10n.noMatchingResults,
      message: l10n.tryAnotherSearch,
    );
  }

  // ===========================================================================
  // 📜 Hint: بناء قائمة المنتجات
  // ===========================================================================
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

  // ===========================================================================
  // 🃏 Hint: بناء بطاقة منتج - مع دعم الصور والـ Decimal
  // ===========================================================================
  Widget _buildProductCard(Product product) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
  final l10n = AppLocalizations.of(context)!;
  
  // ← Hint: تحديد حالة المخزون
  final isLowStock = product.quantity < 5;
  final stockColor = isLowStock ? AppColors.warning : AppColors.success;

  // ← Hint: الحصول على كود اللغة الحالية
  final languageCode = Localizations.localeOf(context).languageCode;

  return CustomCard(
    margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ============= رأس البطاقة =============
        Padding(
          padding: AppConstants.paddingMd,
          child: Row(
            children: [
              // Hint: عرض صورة المنتج أو الأيقونة الافتراضية
              _buildProductImage(product, isDark),

              const SizedBox(width: AppConstants.spacingMd),

              // Hint: معلومات المنتج
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),

                    const SizedBox(height: AppConstants.spacingXs),

                    // ← Hint: اسم المورد
                    Row(
                      children: [
                        Icon(
                          Icons.store,
                          size: 18,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            l10n.supplierLabel(
                              product.supplierName ?? l10n.undefined,
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // ✅ عرض التصنيف والوحدة (إن وجدا)
                    if (product.categoryName != null || product.unitName != null)
                      const SizedBox(height: AppConstants.spacingXs),

                    // ← Hint: عرض التصنيف والوحدة في صف واحد
                    if (product.categoryName != null || product.unitName != null)
                      Row(
                        children: [
                          // ← Hint: التصنيف
                          if (product.categoryName != null) ...[
                            Icon(
                              Icons.category,
                              size: 14,
                              color: AppColors.info,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              product.categoryName!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.info,
                                  ),
                            ),
                          ],

                          // ← Hint: فاصل بين التصنيف والوحدة
                          if (product.categoryName != null && product.unitName != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppConstants.spacingSm,
                              ),
                              child: Text(
                                '•',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),

                          // ← Hint: الوحدة
                          if (product.unitName != null) ...[
                            Icon(
                              Icons.straighten,
                              size: 14,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              product.unitName!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.success,
                                  ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),

              // Hint: أزرار الإجراءات
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                color: AppColors.info,
                tooltip: l10n.edit,
                onPressed: () => _navigateToEditProduct(product),
              ),
              IconButton(
                icon: const Icon(Icons.archive_outlined),
                color: AppColors.error,
                tooltip: l10n.archive,
                onPressed: () => _handleArchiveProduct(product),
              ),
            ],
          ),
        ),

        Divider(
          height: 1,
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),

        // ============= معلومات تفصيلية =============
        Padding(
          padding: AppConstants.paddingMd,
          child: Row(
            children: [
              // Hint: الكمية (int - بدون تغيير)
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.inventory_outlined,
                  label: l10n.quantity,
                  value: product.quantity.toString(),
                  color: stockColor,
                ),
              ),

              // Hint: ✅ سعر الشراء - Decimal
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.shopping_cart_outlined,
                  label: l10n.purchase,
                  value: formatCurrency(product.costPrice),
                  color: AppColors.warning,
                ),
              ),

              // Hint: ✅ سعر البيع - Decimal
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.sell_outlined,
                  label: l10n.sell,
                  value: formatCurrency(product.sellingPrice),
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),

        // ============= الباركود (إن وجد) =============
        if (product.barcode != null && product.barcode!.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(
              AppConstants.spacingMd,
              0,
              AppConstants.spacingMd,
              AppConstants.spacingMd,
            ),
            padding: const EdgeInsets.all(AppConstants.spacingSm),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceDark.withOpacity(0.5)
                  : AppColors.surfaceLight,
              borderRadius: AppConstants.borderRadiusSm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.qr_code,
                  size: 18,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 4),
                Text(
                  product.barcode!,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
  }

  // ===========================================================================
  // 🖼️ Hint: بناء صورة المنتج أو الأيقونة الافتراضية - محسّنة
  // Hint: يعرض صورة المنتج إذا كانت موجودة، وإلا يعرض أيقونة افتراضية
  // Hint: ✅ محسّنة مع cacheWidth للأداء العالي
  // ===========================================================================
  Widget _buildProductImage(Product product, bool isDark) {
    // Hint: التحقق من وجود صورة
    final hasImage = product.imagePath != null && 
                      product.imagePath!.isNotEmpty;

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: hasImage 
            ? Colors.transparent 
            : AppColors.info.withOpacity(0.1),
        borderRadius: AppConstants.borderRadiusMd,
        border: hasImage
            ? Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: AppConstants.borderRadiusMd,
        child: hasImage
            ? Image.file(
                File(product.imagePath!),
                fit: BoxFit.cover,
                // Hint: cacheWidth مناسب لحجم الصورة 60px
                // Hint: نستخدم 120 (ضعف الحجم) للحصول على جودة جيدة على الشاشات عالية الكثافة
                cacheWidth: 120,
                cacheHeight: 120,
                // Hint: عرض placeholder بسيط أثناء التحميل
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  // Hint: إذا تم التحميل مباشرة، عرض الصورة فوراً
                  if (wasSynchronouslyLoaded) return child;
                  // Hint: إذا لم يتم التحميل بعد، عرض أيقونة تحميل صغيرة
                  return frame != null
                      ? child
                      : Container(
                          color: isDark 
                              ? AppColors.surfaceDark 
                              : AppColors.surfaceLight,
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                },
                // Hint: معالجة الأخطاء - عرض أيقونة broken_image
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('❌ خطأ في عرض صورة المنتج: ${product.productName}');
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: AppColors.error,
                      size: 28,
                    ),
                  );
                },
              )
            : const Center(
                child: Icon(
                  Icons.inventory_2,
                  color: AppColors.info,
                  size: 28,
                ),
              ),
      ),
    );
  }

  // ===========================================================================
  // 📋 Hint: بناء عنصر معلومات
  // ===========================================================================
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingSm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppConstants.borderRadiusSm,
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 🧭 Hint: التنقل
  // ===========================================================================

  /// Hint: الانتقال لصفحة إضافة منتج جديد
  /// Hint: الانتقال لصفحة إدارة التصنيفات والوحدات
  Future<void> _navigateToManageCategories() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ManageCategoriesUnitsScreen(),
      ),
    );
    // ← Hint: إعادة تحميل المنتجات بعد تعديل التصنيفات/الوحدات
    _reloadProducts();
  }

  Future<void> _navigateToAddProduct() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const AddEditProductScreen(),
      ),
    );

    if (result == true) {
      _reloadProducts();
    }
  }

  /// Hint: الانتقال لصفحة تعديل المنتج
  Future<void> _navigateToEditProduct(Product product) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddEditProductScreen(product: product),
      ),
    );

    if (result == true) {
      _reloadProducts();
    }
  }
}