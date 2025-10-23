// 📁 lib/screens/customers/new_sale_screen.dart

import 'package:flutter/material.dart';
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/helpers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_state.dart';
import '../products/barcode_scanner_screen.dart';
// import '../products/barcode_scanner_screen.dart';

/// =================================================================================================
/// 🛒 شاشة اختيار المنتجات للبيع - New Sale Screen
/// =================================================================================================
/// الوظيفة: اختيار المنتجات وإضافتها إلى سلة المشتريات
/// 
/// المميزات:
/// - ✅ عرض قائمة المنتجات المتاحة
/// - ✅ إضافة منتج إلى السلة مع تحديد الكمية
/// - ✅ مسح الباركود للإضافة السريعة
/// - ✅ مراجعة السلة قبل الحفظ
/// - ✅ حساب الإجمالي تلقائياً
/// - ✅ التحقق من توفر الكمية المطلوبة
/// =================================================================================================
class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  // =================================================================================================
  // 📦 المتغيرات الأساسية
  // =================================================================================================
  
  /// Hint: نسخة من قاعدة البيانات
  final _dbHelper = DatabaseHelper.instance;
  
  /// Hint: قائمة جميع المنتجات المتاحة
  List<Product> _allProducts = [];
  
  /// Hint: قائمة المنتجات المفلترة (حسب البحث)
  List<Product> _filteredProducts = [];
  
  /// Hint: سلة المشتريات
  final List<CartItem> _cartItems = [];
  
  /// Hint: حالة التحميل
  bool _isLoading = true;
  
  /// Hint: رسالة الخطأ
  String? _errorMessage;
  
  /// Hint: متحكم حقل البحث
  final _searchController = TextEditingController();
  
  // =================================================================================================
  // 🔄 دورة حياة الصفحة - Lifecycle
  // =================================================================================================
  
  @override
  void initState() {
    super.initState();
    _loadProducts();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  // =================================================================================================
  // 📥 تحميل البيانات - Data Loading
  // =================================================================================================
  
  /// Hint: تحميل قائمة المنتجات من قاعدة البيانات
  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final products = await _dbHelper.getAllProductsWithSupplierName();
      
      if (mounted) {
        setState(() {
          _allProducts = products;
          _filteredProducts = products;
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
  
  // =================================================================================================
  // 🔍 البحث - Search Functionality
  // =================================================================================================
  
  /// Hint: تصفية المنتجات حسب نص البحث
  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts.where((product) {
          final nameLower = product.productName.toLowerCase();
          final queryLower = query.toLowerCase();
          return nameLower.contains(queryLower);
        }).toList();
      }
    });
  }
  
  // =================================================================================================
  // 📷 مسح الباركود - Barcode Scanning
  // =================================================================================================
  
  /// Hint: فتح كاميرا مسح الباركود وإضافة المنتج للسلة
  Future<void> _scanBarcodeAndAddToCart() async {
    final l10n = AppLocalizations.of(context)!;
    
  //   // === الخطوة 1: فتح شاشة مسح الباركود ===
    final String? barcodeScanRes = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );
    
    if (!mounted || barcodeScanRes == null) return;
    
    // === الخطوة 2: البحث عن المنتج بالباركود ===
    final product = await _dbHelper.getProductByBarcode(barcodeScanRes);
    
    if (product != null) {
      // === الخطوة 3: إضافة المنتج للسلة ===
      _addProductToCart(product, 1, l10n);
    } else {
      // === المنتج غير موجود ===
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
  
  // =================================================================================================
  // 🛒 إدارة السلة - Cart Management
  // =================================================================================================
  
  /// Hint: إضافة منتج إلى السلة (أو تحديث الكمية إذا كان موجوداً)
  void _addProductToCart(Product product, int quantity, AppLocalizations l10n) {
    // === التحقق من توفر الكمية ===
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
      // === البحث عن المنتج في السلة ===
      final index = _cartItems.indexWhere(
        (item) => item.product.productID == product.productID,
      );
      
      if (index != -1) {
        // === المنتج موجود: تحديث الكمية ===
        _cartItems[index] = CartItem(
          product: product,
          quantity: quantity,
        );
      } else {
        // === المنتج جديد: إضافته ===
        _cartItems.add(CartItem(
          product: product,
          quantity: quantity,
        ));
      }
    });
  }
  
  /// Hint: حذف منتج من السلة
  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }
  
  /// Hint: حساب الإجمالي
  double _calculateTotal() {
    return _cartItems.fold(
      0.0,
      (sum, item) => sum + (item.product.sellingPrice * item.quantity),
    );
  }
  
  /// Hint: الحصول على كمية منتج معين في السلة
  int _getCartQuantity(int productId) {
    final cartItem = _cartItems.firstWhere(
      (item) => item.product.productID == productId,
      orElse: () => CartItem(
        product: Product(
          productID: -1,
          productName: '',
          barcode: '',
          quantity: 0,
          costPrice: 0,
          sellingPrice: 0,
          supplierID: 0,
        ),
        quantity: 0,
      ),
    );
    return cartItem.quantity;
  }
  
  // =================================================================================================
  // 💬 مربعات الحوار - Dialogs
  // =================================================================================================
  
  /// Hint: عرض مربع حوار لإضافة منتج (مع تحديد الكمية)
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
            // autofocus: true,
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
    
    // Hint: إذا تم التأكيد، نضيف المنتج
    if (result == true && mounted) {
      final englishValue = convertArabicNumbersToEnglish(quantityController.text);
      final quantity = int.parse(englishValue);
      _addProductToCart(product, quantity, l10n);
    }
  }
  
  /// Hint: عرض مربع حوار مراجعة السلة
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
                  // === رأس الجدول ===
                  _buildCartHeader(l10n),
                  
                  const Divider(),
                  
                  // === قائمة المنتجات ===
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
                  
                  // === الإجمالي ===
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
  
  // =================================================================================================
  // 🎨 بناء واجهة المستخدم - UI Building
  // =================================================================================================
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      // === AppBar ===
      appBar: AppBar(
        title: Text(l10n.chooseProducts),
        actions: [
          // === أيقونة السلة مع عداد ===
          if (_cartItems.isNotEmpty)
            _buildCartBadge(l10n),
          
          // === زر الحفظ ===
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              // Hint: إرجاع السلة إلى الصفحة السابقة
              Navigator.of(context).pop(_cartItems);
            },
            tooltip: l10n.save,
          ),
        ],
      ),
      
      // === الجسم ===
      body: Column(
        children: [
          // === شريط البحث ===
          _buildSearchBar(l10n),
          
          // === قائمة المنتجات ===
          Expanded(
            child: _buildProductsList(l10n),
          ),
          
          // === شريط الإجمالي السفلي ===
          if (_cartItems.isNotEmpty)
            _buildBottomBar(l10n),
        ],
      ),
      
      // === زر مسح الباركود ===
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanBarcodeAndAddToCart,
        icon: const Icon(Icons.qr_code_scanner),
        label: Text(l10n.scanBarcodeToSell),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
  
  // =================================================================================================
  // 🧩 مكونات الواجهة - UI Components
  // =================================================================================================
  
  /// Hint: بناء أيقونة السلة مع عداد المنتجات
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
  
  /// Hint: بناء شريط البحث
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
  
  /// Hint: بناء قائمة المنتجات
  Widget _buildProductsList(AppLocalizations l10n) {
    // === حالة التحميل ===
    if (_isLoading) {
      return const LoadingState(message: 'جاري تحميل المنتجات...');
    }
    
    // === حالة الخطأ ===
    if (_errorMessage != null) {
      return ErrorState(
        message: _errorMessage!,
        onRetry: _loadProducts,
      );
    }
    
    // === حالة عدم وجود منتجات ===
    if (_allProducts.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        title: l10n.noProductsInStock,
        message: 'لا توجد منتجات متاحة للبيع',
      );
    }
    
    // === حالة عدم وجود نتائج بحث ===
    if (_filteredProducts.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: l10n.noMatchingResults,
        message: 'جرب البحث بكلمة أخرى',
      );
    }
    
    // === عرض القائمة ===
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        AppConstants.spacingMd,
        AppConstants.spacingSm,
        AppConstants.spacingMd,
        AppConstants.spacingXl * 3, // مسافة للزر العائم
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildProductCard(product, l10n);
      },
    );
  }
  
  /// Hint: بناء بطاقة منتج واحد
  Widget _buildProductCard(Product product, AppLocalizations l10n) {
    final cartQuantity = _getCartQuantity(product.productID!);
    final isInCart = cartQuantity > 0;
    
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      onTap: () => _showAddToCartDialog(product, l10n),
      child: Row(
        children: [
          // === الأيقونة ===
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            decoration: BoxDecoration(
              color: isInCart
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: AppConstants.borderRadiusMd,
            ),
            child: Icon(
              isInCart ? Icons.shopping_cart : Icons.inventory_2,
              color: isInCart
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
              size: AppConstants.iconSizeLg,
            ),
          ),
          
          const SizedBox(width: AppConstants.spacingMd),
          
          // === المعلومات ===
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
                
                // الكمية والسعر
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
          
          // === الكمية في السلة ===
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
  
  /// Hint: بناء شريط الإجمالي السفلي
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
            // عدد الأصناف
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
            
            // الإجمالي
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
  
  // =================================================================================================
  // 🛒 مكونات مربع حوار السلة - Cart Dialog Components
  // =================================================================================================
  
  /// Hint: رأس جدول السلة
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
            flex: 2,
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
  
  /// Hint: صف منتج واحد في السلة
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
          // المعلومات
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.productName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n.quantity}: ${item.quantity}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          
          // الإجمالي وزر الحذف
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  formatCurrency(item.quantity * item.product.sellingPrice),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppColors.error,
                  onPressed: () {
                    setDialogState(() => _removeFromCart(index));
                    setState(() {});
                    
                    // إغلاق الحوار إذا أصبحت السلة فارغة
                    if (_cartItems.isEmpty) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Hint: الإجمالي النهائي في السلة
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
          Text(
            formatCurrency(_calculateTotal()),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
