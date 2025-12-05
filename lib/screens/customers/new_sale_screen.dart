// 📁 lib/screens/customers/new_sale_screen.dart

import 'dart:io';
import 'package:accountant_touch/utils/decimal_extensions.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/helpers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_state.dart';
import '../products/barcode_scanner_screen.dart';

/// 🛒 شاشة البيع للزبون - مع دعم عرض صور المنتجات
/// ← Hint: تتيح اختيار منتجات متعددة وإضافتها للسلة مع تحديد تاريخ البيع
class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final _dbHelper = DatabaseHelper.instance;

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];

  final List<CartItem> _cartItems = [];

  bool _isLoading = true;
  String? _errorMessage;

  final _searchController = TextEditingController();

  // ← Hint: متغير لحفظ تاريخ البيع المختار
  DateTime _selectedSaleDate = DateTime.now();

  // ← فلتر التصنيفات
  List<ProductCategory> _categories = [];
  ProductCategory? _selectedCategory; // null = الكل
  
  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadCategories();
  }

  /// ← Hint: تحميل التصنيفات للفلتر
  Future<void> _loadCategories() async {
    try {
      final categories = await _dbHelper.getProductCategories();
      if (mounted) {
        setState(() => _categories = categories);
      }
    } catch (e) {
      // في حال حدوث خطأ، نتجاهله ونبقي القائمة فارغة
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  /// ← Hint: تحميل المنتجات (استبعاد المنتجات ذات الكمية صفر)
  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final products = await _dbHelper.getAllProductsWithSupplierName();
      
      if (mounted) {
        setState(() {
          // ← Hint: فلترة المنتجات - استبعاد الكمية صفر
          _allProducts = products.where((product) => product.quantity > 0).toList();
          _filteredProducts = _allProducts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  
  void _filterProducts(String query) {
    setState(() {
      // تطبيق فلترة البحث
      List<Product> result = _allProducts;

      // فلترة حسب نص البحث
      if (query.isNotEmpty) {
        result = result.where((product) {
          final nameLower = product.productName.toLowerCase();
          final queryLower = query.toLowerCase();
          return nameLower.contains(queryLower);
        }).toList();
      }

      // فلترة حسب التصنيف المحدد
      if (_selectedCategory != null) {
        result = result.where((product) => product.categoryID == _selectedCategory!.categoryID).toList();
      }

      _filteredProducts = result;
    });
  }
  
  Future<void> _scanBarcodeAndAddToCart() async {
    final l10n = AppLocalizations.of(context)!;
    
    final String? barcodeScanRes = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );
    
    if (!mounted || barcodeScanRes == null) return;
    
    final product = await _dbHelper.getProductByBarcode(barcodeScanRes);
    
    if (product != null) {
      // ← Hint: التحقق من أن الكمية أكبر من صفر
      if (product.quantity > 0) {
        _addProductToCart(product, 1, l10n);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.productOutOfStock),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.productNotFound),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  
  void _addProductToCart(Product product, int quantity, AppLocalizations l10n) {
    if (quantity > product.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.quantityExceedsStock),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    setState(() {
      final index = _cartItems.indexWhere(
        (item) => item.product.productID == product.productID,
      );
      
      if (index != -1) {
        _cartItems[index] = CartItem(
          product: product,
          quantity: quantity,
        );
      } else {
        _cartItems.add(CartItem(
          product: product,
          quantity: quantity,
        ));
      }
    });
  }
  
  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }
  
  Decimal _calculateTotal() {
    return _cartItems.fold(
      Decimal.zero,
      // (sum, item) => sum + (item.product.sellingPrice * item.quantity), السابق double
      (sum, item) => sum + item.product.sellingPrice.multiplyByInt(item.quantity),
    );
  }
  
  int _getCartQuantity(int productId) {
    final cartItem = _cartItems.firstWhere(
      (item) => item.product.productID == productId,
      orElse: () => CartItem(
        product: Product(
          productID: -1,
          productName: '',
          barcode: '',
          quantity: 0,
          costPrice: Decimal.zero,
          sellingPrice: Decimal.zero,
          supplierID: 0,
        ),
        quantity: 0,
      ),
    );
    return cartItem.quantity;
  }
  
  Future<void> _showAddToCartDialog(Product product, AppLocalizations l10n) async {
    final quantityController = TextEditingController(text: '1');
    final formKey = GlobalKey<FormState>();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addWithProductName(product.productName)),
        content: Form(
          key: formKey,
          child: CustomTextField(
            controller: quantityController,
            label: l10n.quantity,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.numbers,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.fieldRequired;
              }
              
              final englishValue = convertArabicNumbersToEnglish(value);
              final quantity = int.tryParse(englishValue);
              
              if (quantity == null || quantity <= 0) {
                return l10n.enterValidNumber;
              }
              
              if (quantity > product.quantity) {
                return l10n.quantityExceedsStock;
              }
              
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
    
    if (result == true && mounted) {
      final englishValue = convertArabicNumbersToEnglish(quantityController.text);
      final quantity = int.parse(englishValue);
      _addProductToCart(product, quantity, l10n);
    }
  }
  
  Future<void> _showCartReviewDialog(AppLocalizations l10n) async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.cartIsEmpty),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.shopping_cart),
                const SizedBox(width: AppConstants.spacingSm),
                Text(l10n.reviewCart),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCartHeader(l10n),
                  const Divider(),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _cartItems.length,
                      itemBuilder: (context, index) {
                        final item = _cartItems[index];
                        return _buildCartItemRow(
                          item,
                          index,
                          l10n,
                          setDialogState,
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  _buildCartTotal(l10n),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.close),
              ),
            ],
          );
        },
      ),
    );
  }
  
  // ← Hint: دالة جديدة - اختيار تاريخ البيع
  Future<void> _selectSaleDate(BuildContext context, AppLocalizations l10n) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedSaleDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: l10n.selectSaleDate,
    );
    
    if (picked != null && picked != _selectedSaleDate) {
      setState(() {
        _selectedSaleDate = picked;
      });
    }
  }

  // ============= شريط فلتر التصنيفات =============
  Widget _buildCategoryFilter(AppLocalizations l10n) {
    if (_categories.isEmpty) {
      return const SizedBox.shrink(); // لا تعرض شيئاً إذا لم تكن هناك تصنيفات
    }

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // زر "الكل"
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: FilterChip(
              label: Text(l10n.all ?? 'الكل'),
              selected: _selectedCategory == null,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = null;
                    _filterProducts(_searchController.text);
                  });
                }
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
            ),
          ),
          // أزرار التصنيفات
          ..._categories.map((category) {
            final isSelected = _selectedCategory?.categoryID == category.categoryID;
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: FilterChip(
                label: Text(category.categoryNameAr ?? category.categoryName),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? category : null;
                    _filterProducts(_searchController.text);
                  });
                },
                selectedColor: AppColors.primary.withOpacity(0.2),
                checkmarkColor: AppColors.primary,
                avatar: category.iconName != null
                    ? Icon(
                        _getIconFromName(category.iconName!),
                        size: 18,
                        color: isSelected ? AppColors.primary : null,
                      )
                    : null,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // ← Hint: تحويل اسم الأيقونة إلى IconData
  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'fastfood':
        return Icons.fastfood;
      case 'local_drink':
        return Icons.local_drink;
      case 'cake':
        return Icons.cake;
      case 'restaurant':
        return Icons.restaurant;
      case 'coffee':
        return Icons.coffee;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chooseProducts),
        actions: [
          if (_cartItems.isNotEmpty)
            _buildCartBadge(l10n),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              // ← Hint: إرجاع السلة + التاريخ
              Navigator.of(context).pop({
                'items': _cartItems,
                'date': _selectedSaleDate,
              });
            },
            tooltip: l10n.save,
          ),
        ],
      ),
      
      body: Column(
        children: [
          _buildSearchBar(l10n),
          
          // ← Hint: قسم اختيار التاريخ
          _buildDateSelector(l10n),
          
          Expanded(
            child: _buildProductsList(l10n),
          ),
          
          if (_cartItems.isNotEmpty)
            _buildBottomBar(l10n),
        ],
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanBarcodeAndAddToCart,
        icon: const Icon(Icons.qr_code_scanner),
        label: Text(l10n.scanBarcodeToSell),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
  
  // ← Hint: ويدجت جديد - محدد التاريخ
  Widget _buildDateSelector(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isToday = _selectedSaleDate.year == DateTime.now().year &&
                    _selectedSaleDate.month == DateTime.now().month &&
                    _selectedSaleDate.day == DateTime.now().day;
    
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      child: InkWell(
        onTap: () => _selectSaleDate(context, l10n),
        borderRadius: AppConstants.borderRadiusMd,
        child: Container(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: AppConstants.borderRadiusMd,
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingSm),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: AppConstants.borderRadiusSm,
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: AppColors.info,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.saleDate,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isToday
                          ? '${l10n.today} - ${DateFormat('yyyy-MM-dd').format(_selectedSaleDate)}'
                          : DateFormat('yyyy-MM-dd').format(_selectedSaleDate),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isToday ? AppColors.success : null,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCartBadge(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(right: AppConstants.spacingSm),
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => _showCartReviewDialog(l10n),
            tooltip: l10n.reviewCart,
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                '${_cartItems.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchBar(AppLocalizations l10n) {
    return Container(
      padding: AppConstants.paddingMd,
      child: TextField(
        controller: _searchController,
        onChanged: _filterProducts,
        decoration: InputDecoration(
          hintText: l10n.searchForProduct,
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
  
  Widget _buildProductsList(AppLocalizations l10n) {
    if (_isLoading) {
      return const LoadingState(message: 'جاري تحميل المنتجات...');
    }
    
    if (_errorMessage != null) {
      return ErrorState(
        message: _errorMessage!,
        onRetry: _loadProducts,
      );
    }
    
    if (_allProducts.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        title: l10n.noProductsInStock,
        message: 'لا توجد منتجات متاحة للبيع',
      );
    }
    
    if (_filteredProducts.isEmpty) {
      return Column(
        children: [
          // شريط فلتر التصنيفات
          _buildCategoryFilter(l10n),

          // رسالة لا توجد نتائج
          Expanded(
            child: EmptyState(
              icon: Icons.search_off,
              title: l10n.noMatchingResults,
              message: 'جرب البحث بكلمة أخرى أو تغيير الفلتر',
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        // شريط فلتر التصنيفات
        _buildCategoryFilter(l10n),

        // قائمة المنتجات المفلترة
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(
              AppConstants.spacingMd,
              AppConstants.spacingSm,
              AppConstants.spacingMd,
              AppConstants.spacingXl * 3,
            ),
            itemCount: _filteredProducts.length,
            itemBuilder: (context, index) {
              final product = _filteredProducts[index];
              return _buildProductCard(product, l10n);
            },
          ),
        ),
      ],
    );
  }
  
  /// ← Hint: بناء بطاقة المنتج - مع دعم عرض الصورة
  Widget _buildProductCard(Product product, AppLocalizations l10n) {
    final cartQuantity = _getCartQuantity(product.productID!);
    final isInCart = cartQuantity > 0;
    
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      onTap: () => _showAddToCartDialog(product, l10n),
      child: Row(
        children: [
          // ← Hint: عرض صورة المنتج أو الأيقونة الافتراضية
          _buildProductImage(product, isInCart),
          
          const SizedBox(width: AppConstants.spacingMd),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                
                const SizedBox(height: AppConstants.spacingXs),
                
                Row(
                  children: [
                    Icon(
                      Icons.inventory,
                      size: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${l10n.available}: ${product.quantity}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: AppConstants.spacingMd),
                    Icon(
                      Icons.attach_money,
                      size: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatCurrency(product.sellingPrice),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          if (isInCart)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingMd,
                vertical: AppConstants.spacingSm,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: AppConstants.borderRadiusFull,
              ),
              child: Text(
                'x$cartQuantity',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // 🖼️ بناء صورة المنتج أو الأيقونة الافتراضية - النسخة الآمنة
  // ============================================================
  /// ← Hint: يعرض صورة المنتج إذا كانت موجودة، وإلا يعرض أيقونة افتراضية
  /// ← Hint: ✅✅ النسخة الآمنة بدون frameBuilder
  Widget _buildProductImage(Product product, bool isInCart) {
    // ← Hint: التحقق من وجود صورة
    final hasImage = product.imagePath != null && 
                      product.imagePath!.isNotEmpty;

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: hasImage
            ? Colors.transparent
            : (isInCart
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1)),
        borderRadius: AppConstants.borderRadiusMd,
        border: hasImage
            ? Border.all(
                color: isInCart
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.withOpacity(0.3),
                width: 1.5,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: AppConstants.borderRadiusMd,
        child: hasImage
            ? Image.file(
                File(product.imagePath!),
                fit: BoxFit.cover,
                // ← Hint: cacheWidth مناسب لحجم الصورة 50px
                cacheWidth: 100,
                cacheHeight: 100,
                // ← Hint: فقط errorBuilder - بدون frameBuilder
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('❌ خطأ في عرض صورة المنتج: ${product.productName}');
                  return Center(
                    child: Icon(
                      isInCart ? Icons.shopping_cart : Icons.inventory_2,
                      color: isInCart
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                      size: AppConstants.iconSizeMd,
                    ),
                  );
                },
              )
            : Icon(
                isInCart ? Icons.shopping_cart : Icons.inventory_2,
                color: isInCart
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
                size: AppConstants.iconSizeMd,
              ),
      ),
    );
  }
  
  Widget _buildBottomBar(AppLocalizations l10n) {
    return Container(
      padding: AppConstants.paddingMd,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.itemsCount(_cartItems.length.toString()),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.total,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            
            Text(
              formatCurrency(_calculateTotal()),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCartHeader(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              l10n.product,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              l10n.total,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCartItemRow(
    CartItem item,
    int index,
    AppLocalizations l10n,
    StateSetter setDialogState,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.productName,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n.quantity}: ${item.quantity}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    // formatCurrency(item.quantity * item.product.sellingPrice),
                    formatCurrency(item.product.sellingPrice.multiplyByInt(item.quantity)),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    setDialogState(() => _removeFromCart(index));
                    setState(() {});
                    
                    if (_cartItems.isEmpty) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCartTotal(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.spacingSm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${l10n.finalTotal}:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Flexible(
            child: Text(
              formatCurrency(_calculateTotal()),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}