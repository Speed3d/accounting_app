// lib/screens/sales/direct_sale_screen.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:accountant_touch/utils/decimal_extensions.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/helpers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_state.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../products/barcode_scanner_screen.dart';

// ← Hint: تم إزالة AuthService - لا حاجة له في Direct Sale

/// 🚀 شاشة البيع السريع - مع دعم عرض صور المنتجات
/// ← Hint: تتيح بيع نقدي مباشر مع طباعة فاتورة
class DirectSaleScreen extends StatefulWidget {
  const DirectSaleScreen({super.key});

  @override
  State<DirectSaleScreen> createState() => _DirectSaleScreenState();
}

class _DirectSaleScreenState extends State<DirectSaleScreen> {
  final dbHelper = DatabaseHelper.instance;
  // ← Hint: تم إزالة AuthService
  final List<CartItem> _cartItems = [];
  late Future<List<Product>> _productsFuture;
  bool _isProcessingSale = false;

  // ← فلتر التصنيفات
  late Future<List<ProductCategory>> _categoriesFuture;
  ProductCategory? _selectedCategory; // null = الكل
  List<Product> _allProducts = []; // قائمة كل المنتجات

  @override
  void initState() {
    super.initState();
    // ← Hint: تحميل المنتجات التي لديها كمية أكبر من 0 فقط
    _productsFuture = _loadAvailableProducts();
    // ← Hint: تحميل التصنيفات للفلتر
    _categoriesFuture = dbHelper.getProductCategories();
  }

  // ← Hint: دالة لتحميل المنتجات المتوفرة فقط (الكمية > 0)
  Future<List<Product>> _loadAvailableProducts() async {
    final allProductsList = await dbHelper.getAllProductsWithSupplierName();
    final availableProducts = allProductsList.where((product) => product.quantity > 0).toList();
    // حفظ القائمة للفلترة لاحقاً
    _allProducts = availableProducts;
    return availableProducts;
  }

  // ← Hint: دالة لفلترة المنتجات بناءً على التصنيف المحدد
  List<Product> _getFilteredProducts() {
    if (_selectedCategory == null) {
      return _allProducts; // إرجاع كل المنتجات
    }
    return _allProducts.where((product) => product.categoryID == _selectedCategory!.categoryID).toList();
  }

  // ============= دالة إتمام البيع =============
  Future<void> _completeSale() async {
    final l10n = AppLocalizations.of(context)!;
    
    if (_cartItems.isEmpty || _isProcessingSale) {
      if (_cartItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.cartIsEmpty),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isProcessingSale = true);

    try {
      final cashCustomer = await dbHelper.getOrCreateCashCustomer();
      final db = await dbHelper.database;
      final totalAmount = _calculateTotal();
      int newInvoiceId;

      newInvoiceId = await db.transaction((txn) async {
        final invoiceId = await txn.insert('TB_Invoices', {
          'CustomerID': cashCustomer.customerID!,
          'InvoiceDate': DateTime.now().toIso8601String(),
          'TotalAmount': totalAmount.toDouble(),
        });

        for (var item in _cartItems) {
          final product = item.product;
          final quantitySold = item.quantity;
          final salePriceForItem = product.sellingPrice.multiplyByInt(quantitySold);
          final profitForItem = (product.sellingPrice - product.costPrice).multiplyByInt(quantitySold);


          await txn.insert('Debt_Customer', {
            'InvoiceID': invoiceId,
            'CustomerID': cashCustomer.customerID!,
            'ProductID': product.productID!,
            'CustomerName': cashCustomer.address,
            'Details': l10n.saleDetails(product.productName, quantitySold.toString()),
            'Debt': salePriceForItem.toDouble(),
            'DateT': DateTime.now().toIso8601String(),
            'Qty_Customer': quantitySold,
            'CostPriceAtTimeOfSale': product.costPrice.toDouble(),
            'ProfitAmount': profitForItem.toDouble(),
          });

          await txn.rawUpdate(
            'UPDATE Store_Products SET Quantity = Quantity - ? WHERE ProductID = ?',
            [quantitySold, product.productID],
          );
        }
        return invoiceId;
      });

      // توليد وطباعة الفاتورة
      final pdfBytes = await _generatePdfInvoice(newInvoiceId, totalAmount, l10n);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Invoice-$newInvoiceId.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.saleSuccess),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _cartItems.clear();
          // ← Hint: إعادة تحميل المنتجات المتوفرة بعد البيع
          _productsFuture = _loadAvailableProducts();
        });
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
      if (mounted) setState(() => _isProcessingSale = false);
    }
  }

  // ============= توليد PDF =============
  Future<Uint8List> _generatePdfInvoice(
    int invoiceId,
    Decimal totalAmount,
    AppLocalizations l10n,
  ) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final settings = await dbHelper.getAppSettings();
    final companyName = settings['companyName'] ?? 'My Shop';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  companyName,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      l10n.pdfInvoiceTitle,
                      style: pw.TextStyle(font: font, fontSize: 18),
                    ),
                    pw.Text(
                      '${l10n.pdfInvoiceNumber} #$invoiceId',
                      style: const pw.TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                pw.Text(
                  '${l10n.pdfDate}: ${DateFormat('yyyy/MM/dd').format(DateTime.now())}',
                  style: pw.TextStyle(font: font),
                ),
                pw.Divider(height: 20),
                pw.Table.fromTextArray(
                  headerStyle: pw.TextStyle(
                    font: font,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  cellStyle: pw.TextStyle(font: font),
                  headerAlignment: pw.Alignment.center,
                  cellAlignment: pw.Alignment.center,
                  headers: [
                    l10n.pdfHeaderTotal,
                    l10n.pdfHeaderPrice,
                    l10n.pdfHeaderQty,
                    l10n.pdfHeaderProduct,
                  ],
                  data: _cartItems
                      .map((item) => [
                            formatCurrency(item.product.sellingPrice.multiplyByInt(item.quantity)),
                            formatCurrency(item.product.sellingPrice),
                            item.quantity.toString(),
                            item.product.productName,
                          ])
                      .toList(),
                  columnWidths: {3: const pw.FlexColumnWidth(2)},
                  cellAlignments: {3: pw.Alignment.centerRight},
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text(
                      formatCurrency(totalAmount),
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green700,
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Text(
                      '${l10n.pdfFooterTotal}:',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Spacer(),
                pw.Center(
                  child: pw.Text(
                    l10n.pdfFooterThanks,
                    style: pw.TextStyle(font: font),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  // ============= التعامل مع المنتجات =============
  void _handleProductTap(Product product) {
    final l10n = AppLocalizations.of(context)!;
    final existingIndex = _cartItems.indexWhere(
      (item) => item.product.productID == product.productID,
    );

    if (existingIndex != -1) {
      _showEditCartItemDialog(_cartItems[existingIndex], existingIndex, l10n);
    } else {
      if (product.quantity > 0) {
        setState(() => _cartItems.add(CartItem(product: product, quantity: 1)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.quantityExceedsStock),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ============= مسح الباركود =============
  Future<void> _scanBarcodeAndAddToCart() async {
    final l10n = AppLocalizations.of(context)!;
    final String? barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (barcode == null || !mounted) return;

    final product = await dbHelper.getProductByBarcode(barcode);
    if (product != null) {
      _handleProductTap(product);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.productNotFound),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============= حساب الإجمالي =============
  Decimal  _calculateTotal() {
      return _cartItems.fold(
        Decimal.zero,
        (sum, item) => sum + item.product.sellingPrice.multiplyByInt(item.quantity),
      );
  }

  // ============= مربع حوار مراجعة السلة =============
  void _showCartReviewDialog(AppLocalizations l10n, bool isDark) {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.cartIsEmpty),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            Decimal calculateDialogTotal() => _cartItems.fold(
                  Decimal.zero,
                  (sum, item) => sum + item.product.sellingPrice.multiplyByInt(item.quantity),
                );

            return AlertDialog(
              title: Text(l10n.reviewCart),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    ListTile(
                      dense: true,
                      title: Text(
                        l10n.product,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Text(
                        l10n.total,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(),
                    
                    // قائمة المنتجات
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _cartItems.length,
                        itemBuilder: (context, index) {
                          final item = _cartItems[index];
                          return ListTile(
                            title: Text(item.product.productName),
                            subtitle: Text('${l10n.quantity}: ${item.quantity}'),
                            trailing: Text(
                        // formatCurrency(item.quantity * item.product.sellingPrice), 
                          // هذا سابقا اذا كانت الصيغة double
                              formatCurrency(item.product.sellingPrice.multiplyByInt(item.quantity)),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              _showEditCartItemDialog(item, index, l10n);
                            },
                          );
                        },
                      ),
                    ),
                    
                    const Divider(),
                    
                    // الإجمالي
                    Padding(
                      padding: const EdgeInsets.only(top: AppConstants.spacingMd),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${l10n.finalTotal}:',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            formatCurrency(calculateDialogTotal()),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.close),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============= مربع حوار تعديل الكمية =============
  void _showEditCartItemDialog(CartItem item, int index, AppLocalizations l10n) {
    final quantityController = TextEditingController(text: item.quantity.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item.product.productName),
          content: CustomTextField(
            controller: quantityController,
            label: l10n.quantity,
            hint: "${l10n.available}: ${item.product.quantity}",
            keyboardType: TextInputType.number,
            prefixIcon: Icons.shopping_basket,
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                setState(() => _cartItems.removeAt(index));
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              label: Text(
                l10n.delete,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
            CustomButton(
              text: l10n.save,
              type: ButtonType.primary,
              size: ButtonSize.small,
              fullWidth: false,
              onPressed: () {
                final quantity = int.tryParse(
                      convertArabicNumbersToEnglish(quantityController.text),
                    ) ??
                    0;

                if (quantity <= 0) {
                  setState(() => _cartItems.removeAt(index));
                } else if (quantity > item.product.quantity) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.quantityExceedsStock),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                } else {
                  setState(() {
                    _cartItems[index] = CartItem(
                      product: item.product,
                      quantity: quantity,
                    );
                  });
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // ============= بناء واجهة المنتج - مع دعم الصور =============
  Widget _buildProductCard(Product product, bool isDark, AppLocalizations l10n) {
    final cartItemIndex = _cartItems.indexWhere(
      (item) => item.product.productID == product.productID,
    );
    final isInCart = cartItemIndex != -1;
    final quantityInCart = isInCart ? _cartItems[cartItemIndex].quantity : 0;

    return CustomCard(
      onTap: () => _handleProductTap(product),
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      color: isInCart
          ? (isDark ? AppColors.primaryDark : AppColors.primaryLight).withOpacity(0.1)
          : null,
      child: Row(
        children: [
          // ← Hint: عرض صورة المنتج أو أيقونة/عدد
          _buildProductImage(product, isInCart, quantityInCart, isDark),
          
          const SizedBox(width: AppConstants.spacingMd),
          
          // معلومات المنتج
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppConstants.spacingXs),
                Row(
                  children: [
                    Icon(
                      Icons.inventory,
                      size: 14,
                      color: isDark
                          ? AppColors.textHintDark
                          : AppColors.textHintLight,
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
                      color: isDark
                          ? AppColors.textHintDark
                          : AppColors.textHintLight,
                    ),
                    Text(
                      formatCurrency(product.sellingPrice),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // سهم
          Icon(
            Icons.chevron_right,
            color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🖼️ بناء صورة المنتج أو أيقونة/عدد - النسخة الآمنة
  // ============================================================
  /// ← Hint: يعرض صورة المنتج إذا كانت موجودة، وإلا يعرض أيقونة أو العدد
  /// ← Hint: ✅✅ النسخة الآمنة بدون frameBuilder
  Widget _buildProductImage(
    Product product,
    bool isInCart,
    int quantityInCart,
    bool isDark,
  ) {
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
                ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight)),
        borderRadius: AppConstants.borderRadiusMd,
        border: hasImage
            ? Border.all(
                color: isInCart
                    ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
                width: isInCart ? 2 : 1,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: AppConstants.borderRadiusMd,
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(product.imagePath!),
                    fit: BoxFit.cover,
                    // ← Hint: cacheWidth مناسب لحجم الصورة 50px
                    cacheWidth: 100,
                    cacheHeight: 100,
                    // ← Hint: فقط errorBuilder - بدون frameBuilder
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('❌ خطأ في عرض صورة المنتج: ${product.productName}');
                      return Center(
                        child: isInCart
                            ? Text(
                                'x$quantityInCart',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              )
                            : Icon(
                                Icons.inventory_2_outlined,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                      );
                    },
                  ),
                  // ← Hint: عرض العدد فوق الصورة إذا كان في السلة
                  if (isInCart)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: AppConstants.borderRadiusMd,
                      ),
                      child: Center(
                        child: Text(
                          'x$quantityInCart',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              )
            : Center(
                child: isInCart
                    ? Text(
                        'x$quantityInCart',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : Icon(
                        Icons.inventory_2_outlined,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
              ),
      ),
    );
  }

  // ============= شريط فلتر التصنيفات =============
  Widget _buildCategoryFilter(AppLocalizations l10n) {
    return FutureBuilder<List<ProductCategory>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); // لا تعرض شيئاً إذا لم تكن هناك تصنيفات
        }

        final categories = snapshot.data!;

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
                      setState(() => _selectedCategory = null);
                    }
                  },
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  checkmarkColor: AppColors.primary,
                ),
              ),
              // أزرار التصنيفات
              ...categories.map((category) {
                final isSelected = _selectedCategory?.categoryID == category.categoryID;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: FilterChip(
                    label: Text(category.categoryNameAr ?? category.categoryName),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : null;
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
      },
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
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.directSalePoint),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: l10n.scanBarcode,
            onPressed: _scanBarcodeAndAddToCart,
          ),
          IconButton(
            icon: Badge(
              label: Text(_cartItems.length.toString()),
              isLabelVisible: _cartItems.isNotEmpty,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            tooltip: l10n.reviewCart,
            onPressed: () => _showCartReviewDialog(l10n, isDark),
          ),
        ],
      ),
      
      floatingActionButton: _cartItems.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isProcessingSale ? null : _completeSale,
              label: _isProcessingSale
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      '${l10n.completeSale} (${formatCurrency(_calculateTotal())})',
                    ),
              icon: _isProcessingSale ? null : const Icon(Icons.check_circle_outline),
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            )
          : null,
      
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return LoadingState(message: l10n.loadingProducts);
          }

          if (snapshot.hasError) {
            return ErrorState(
              message: l10n.errorOccurred(snapshot.error.toString()),
              onRetry: () {
                setState(() {
                  // ← Hint: إعادة تحميل المنتجات المتوفرة عند الخطأ
                  _productsFuture = _loadAvailableProducts();
                });
              },
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyState(
              icon: Icons.inventory_2_outlined,
              title: l10n.noProductsInStock,
              message: l10n.addtonewstores,
              actionText: l10n.addProduct,
              onAction: () {
                // TODO: التنقل لصفحة إضافة منتج
              },
            );
          }

          // استخدام المنتجات المفلترة بدلاً من كل المنتجات
          final filteredProducts = _getFilteredProducts();

          return Column(
            children: [
              // شريط فلتر التصنيفات
              _buildCategoryFilter(l10n),

              // قائمة المنتجات المفلترة
              Expanded(
                child: filteredProducts.isEmpty
                    ? EmptyState(
                        icon: Icons.filter_alt_off,
                        title: l10n.noProductsFound ?? 'لا توجد منتجات',
                        message: l10n.tryChangingFilters ?? 'جرب تغيير الفلتر',
                      )
                    : ListView.builder(
                        padding: AppConstants.screenPadding,
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          return _buildProductCard(filteredProducts[index], isDark, l10n);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}