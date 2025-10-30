// lib/screens/products/products_list_screen.dart

import 'package:flutter/material.dart';
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../services/auth_service.dart';
import '../../utils/helpers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_state.dart';
import 'add_edit_product_screen.dart';

/// 📦 شاشة قائمة المنتجات - صفحة فرعية
/// Hint: تعرض جميع المنتجات النشطة مع معلوماتها الأساسية
class ProductsListScreen extends StatefulWidget {
  const ProductsListScreen({super.key});

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  // ============= المتغيرات =============
  final dbHelper = DatabaseHelper.instance;
  final AuthService _authService = AuthService();
  late Future<List<Product>> _productsFuture;
  final _searchController = TextEditingController();
  
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isAdmin = false;
  String? _selectedFilter; // null = الكل، 'low' = منخفضة

  // ============= دورة الحياة =============
  @override
  void initState() {
    super.initState();
    _isAdmin = _authService.isAdmin;
    _reloadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// تحميل قائمة المنتجات
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
      // معالجة الخطأ
    }
  }

  /// تطبيق الفلتر المحدد
  void _applyFilter() {
    if (_selectedFilter == null) {
      _filteredProducts = _allProducts;
    } else if (_selectedFilter == 'low') {
      _filteredProducts = _allProducts.where((product) {
        return product.quantity < 5;
      }).toList();
    }
    
    // إعادة تطبيق البحث إذا كان موجوداً
    if (_searchController.text.isNotEmpty) {
      _filterProducts(_searchController.text);
    }
  }

  /// تغيير الفلتر
  void _changeFilter(String? filter) {
    setState(() {
      _selectedFilter = filter;
      _applyFilter();
    });
  }

  /// البحث في قائمة المنتجات
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

  /// أرشفة منتج
  Future<void> _handleArchiveProduct(Product product) async {
    final l10n = AppLocalizations.of(context)!;

    // التحقق من عدم بيع المنتج
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

    // تأكيد الأرشفة
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
    

    // تنفيذ الأرشفة
    try {
      await dbHelper.archiveProduct(product.productID!);
      await dbHelper.logActivity(
        
        // ارشفة المنتج
        // 'أرشفة المنتج: ${product.productName}',
        l10n.archiveProductAction(product.productName),
        userId: _authService.currentUser?.id,
        userName: _authService.currentUser?.fullName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(
                  // تم ارشفة المنتج بنجاح
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
            content: Text(
              // حدث خطا في الارشفة
               l10n.productArchivedError(e.toString()),
              ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ============= بناء الواجهة =============
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // ============= AppBar =============
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
          // عدد المنتجات
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

      // ============= Body =============
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          // حالة التحميل
          if (snapshot.connectionState == ConnectionState.waiting) {
            return  LoadingState(message: l10n.loadingProducts);
          }

          // حالة الخطأ
          if (snapshot.hasError) {
            return ErrorState(
              message: snapshot.error.toString(),
              onRetry: _reloadProducts,
            );
          }

          // حالة الفراغ
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyState(
              icon: Icons.inventory_2_outlined,
              title: l10n.noActiveProducts,
              message: l10n.startByAddingProduct,
              actionText: _isAdmin ? l10n.addProduct : null,
              onAction: _isAdmin ? _navigateToAddProduct : null,
            );
          }

          // عرض القائمة
          return Column(
            children: [
              // ============= شريط البحث =============
              _buildSearchBar(l10n),

              // ============= الإحصائيات السريعة =============
              _buildQuickStats(l10n, isDark),

              // ============= قائمة المنتجات =============
              Expanded(
                child: _filteredProducts.isEmpty
                    ? _buildNoResultsState(l10n)
                    : _buildProductsList(),
              ),
            ],
          );
        },
      ),

      // ============= زر الإضافة =============
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: _navigateToAddProduct,
              icon: const Icon(Icons.add),
              label:  Text(l10n.addProduct),
              tooltip: l10n.addNewProduct,
            )
          : null,
    );
  }

  // ============================================================
  // 🔍 بناء شريط البحث
  // ============================================================
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

  // ============================================================
  // 📊 بناء الإحصائيات السريعة
  // ============================================================
  Widget _buildQuickStats(AppLocalizations l10n, bool isDark) {
    if (_allProducts.isEmpty) return const SizedBox.shrink();

    // حساب الإحصائيات
    final totalQuantity = _allProducts.fold<int>(
      0,
      (sum, product) => sum + product.quantity,
    );
    
    final lowStockCount = _allProducts.where(
      (product) => product.quantity < 10,
    ).length;

    final totalValue = _allProducts.fold<double>(
      0,
      (sum, product) => sum + (product.sellingPrice * product.quantity),
    );

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
      ),
      child: Row(
        children: [
          // إجمالي الكمية
          Expanded(
            child: _buildStatCard(
              icon: Icons.inventory_outlined,
              label: l10n.totalQuantity,
              value: totalQuantity.toString(),
              color: AppColors.info,
              isDark: isDark,
              filterType: null, // عرض الكل
            ),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          
          // منتجات منخفضة
          Expanded(
            child: _buildStatCard(
              icon: Icons.warning_amber,
              label: l10n.low,
              value: lowStockCount.toString(),
              color: lowStockCount > 0 ? AppColors.warning : AppColors.success,
              isDark: isDark,
              filterType: 'low', // فلتر المنخفضة
            ),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          
          // قيمة المخزون
          Expanded(
            child: _buildStatCard(
              icon: Icons.attach_money,
              label: l10n.value,
              value: formatCurrency(totalValue),
              color: AppColors.success,
              isDark: isDark,
              isCompact: true,
              filterType: null, // عرض الكل
            ),
          ),
        ],
      ),
    );
  }

  /// بناء بطاقة إحصائية
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

  // ============================================================
  // 📭 حالة عدم وجود نتائج بحث
  // ============================================================
  Widget _buildNoResultsState(AppLocalizations l10n) {
    return EmptyState(
      icon: Icons.search_off,
      title: l10n.noMatchingResults,
      message: l10n.tryAnotherSearch,
    );
  }

  // ============================================================
  // 📜 بناء قائمة المنتجات
  // ============================================================
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

  // ============================================================
  // 🃏 بناء بطاقة منتج
  // ============================================================
  Widget _buildProductCard(Product product) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    
    // تحديد حالة المخزون
    final isLowStock = product.quantity < 5;
    final stockColor = isLowStock ? AppColors.warning : AppColors.success;

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
                // أيقونة المنتج
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingMd),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: AppConstants.borderRadiusMd,
                  ),
                  child: const Icon(
                    Icons.inventory_2,
                    color: AppColors.info,
                    size: 28,
                  ),
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),

                      const SizedBox(height: AppConstants.spacingXs),

                      // المورد
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
                    ],
                  ),
                ),

                // أزرار الإجراءات (للمسؤول فقط)
                if (_isAdmin) ...[
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
                // الكمية
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.inventory_outlined,
                    label: l10n.quantity,
                    value: product.quantity.toString(),
                    color: stockColor,
                  ),
                ),

                // سعر الشراء
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.shopping_cart_outlined,
                    label: l10n.purchase,
                    value: formatCurrency(product.costPrice),
                    color: AppColors.warning,
                  ),
                ),

                // سعر البيع
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

  // ============================================================
  // 📋 بناء عنصر معلومات
  // ============================================================
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

  // ============================================================
  // 🧭 التنقل
  // ============================================================

  /// الانتقال لصفحة إضافة منتج جديد
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

  /// الانتقال لصفحة تعديل المنتج
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