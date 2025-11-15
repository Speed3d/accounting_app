// lib/screens/reports/customer_sales_report_screen.dart

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../services/pdf_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_state.dart';

/// 📊 شاشة تقرير مبيعات الزبائن
class CustomerSalesReportScreen extends StatefulWidget {
  const CustomerSalesReportScreen({super.key});

  @override
  State<CustomerSalesReportScreen> createState() => _CustomerSalesReportScreenState();
}

class _CustomerSalesReportScreenState extends State<CustomerSalesReportScreen> {
  // ============= المتغيرات =============
  final dbHelper = DatabaseHelper.instance;
  
  // حالة التحميل
  bool _isLoading = false;
  bool _isGeneratingPdf = false;
  
  // البيانات
  List<Map<String, dynamic>> _salesData = [];
  Map<String, dynamic> _statistics = {};
  
  // الفلاتر
  Customer? _selectedCustomer;
  Product? _selectedProduct;
  Supplier? _selectedSupplier;
  DateTime? _startDate;
  DateTime? _endDate;
  
  // قوائم البيانات للفلاتر
  List<Customer> _customers = [];
  List<Product> _products = [];
  List<Supplier> _suppliers = [];
  
  // حالة الفلاتر
  bool _showFilters = true;

  // ============= دورة الحياة =============
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  /// تحميل البيانات الأولية
  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    try {
      // تحميل القوائم للفلاتر
      final customers = await dbHelper.getAllCustomers();
      final products = await dbHelper.getAllProductsWithSupplierName();
      final suppliers = await dbHelper.getAllSuppliers();
      
      setState(() {
        _customers = customers;
        _products = products;
        _suppliers = suppliers;
      });
      
      // تحميل البيانات الافتراضية (كل الزبائن)
      await _loadReportData();
      
    } catch (e) {
      _showErrorSnackBar('خطأ في تحميل البيانات: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// تحميل بيانات التقرير
  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    
    try {
      // جلب البيانات من قاعدة البيانات
      final salesData = await dbHelper.getCustomerSalesReport(
        customerId: _selectedCustomer?.customerID,
        productId: _selectedProduct?.productID,
        supplierId: _selectedSupplier?.supplierID,
        startDate: _startDate,
        endDate: _endDate,
      );
      
      // جلب الإحصائيات
      final statistics = await dbHelper.getCustomerSalesStatistics(
        customerId: _selectedCustomer?.customerID,
        productId: _selectedProduct?.productID,
        supplierId: _selectedSupplier?.supplierID,
        startDate: _startDate,
        endDate: _endDate,
      );
      
      setState(() {
        _salesData = salesData;
        _statistics = statistics;
      });
      
    } catch (e) {
      _showErrorSnackBar('خطأ في تحميل التقرير: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// مسح الفلاتر
  void _clearFilters() {
    setState(() {
      _selectedCustomer = null;
      _selectedProduct = null;
      _selectedSupplier = null;
      _startDate = null;
      _endDate = null;
    });
    _loadReportData();
  }

  /// توليد PDF
  Future<void> _generatePdf() async {
    if (_salesData.isEmpty) {
      _showErrorSnackBar('لا توجد بيانات لتصديرها');
      return;
    }
    
    setState(() => _isGeneratingPdf = true);
    
    try {
      final pdf = await PdfService.instance.buildCustomerSalesReport(
        salesData: _salesData,
        statistics: _statistics,
        customerName: _selectedCustomer?.customerName,
        productName: _selectedProduct?.productName,
        supplierName: _selectedSupplier?.supplierName,
        startDate: _startDate,
        endDate: _endDate,
      );
      
      // عرض خيارات PDF
      _showPdfOptionsDialog(pdf);
      
    } catch (e) {
      _showErrorSnackBar('خطأ في إنشاء PDF: $e');
    } finally {
      setState(() => _isGeneratingPdf = false);
    }
  }

  /// عرض خيارات PDF
  void _showPdfOptionsDialog(pw.Document pdf) {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.picture_as_pdf, color: AppColors.error),
            SizedBox(width: 8),
            Text('خيارات PDF'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // معاينة
            ListTile(
              leading: const Icon(Icons.visibility, color: AppColors.info),
              title: const Text('معاينة'),
              subtitle: const Text('عرض PDF قبل الحفظ'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await PdfService.instance.previewPdf(
                    pdf: pdf,
                    fileName: 'customer_sales_report',
                  );
                } catch (e) {
                  _showErrorSnackBar('خطأ في المعاينة: $e');
                }
              },
            ),
            
            const Divider(),
            
            // حفظ
            ListTile(
              leading: const Icon(Icons.save, color: AppColors.success),
              title: const Text('حفظ'),
              subtitle: const Text('حفظ في مجلد التنزيلات'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final file = await PdfService.instance.savePdf(
                    pdf: pdf,
                    fileName: 'customer_sales_report',
                  );
                  _showSuccessSnackBar('تم الحفظ في: ${file.path}');
                } catch (e) {
                  _showErrorSnackBar('خطأ في الحفظ: $e');
                }
              },
            ),
            
            const Divider(),
            
            // طباعة
            ListTile(
              leading: const Icon(Icons.print, color: AppColors.primaryLight),
              title: const Text('طباعة'),
              subtitle: const Text('طباعة مباشرة'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await PdfService.instance.printPdf(pdf: pdf);
                } catch (e) {
                  _showErrorSnackBar('خطأ في الطباعة: $e');
                }
              },
            ),
            
            const Divider(),
            
            // مشاركة
            ListTile(
              leading: const Icon(Icons.share, color: AppColors.secondaryLight),
              title: const Text('مشاركة'),
              subtitle: const Text('مشاركة عبر التطبيقات'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await PdfService.instance.sharePdf(
                    pdf: pdf,
                    fileName: 'customer_sales_report',
                  );
                } catch (e) {
                  _showErrorSnackBar('خطأ في المشاركة: $e');
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  // ============= رسائل Snackbar =============
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============= البناء =============
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير مبيعات الزبائن'),
        actions: [
          // زر تبديل الفلاتر
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() => _showFilters = !_showFilters);
            },
            tooltip: _showFilters ? 'إخفاء الفلاتر' : 'إظهار الفلاتر',
          ),
          
          // زر PDF
          IconButton(
            icon: _isGeneratingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf),
            onPressed: _isGeneratingPdf ? null : _generatePdf,
            tooltip: 'تصدير PDF',
          ),
        ],
      ),
      
      body: _isLoading
          ? const LoadingState(message: 'جاري تحميل البيانات...')
          : Column(
              children: [
                // ============= قسم الفلاتر =============
                if (_showFilters) _buildFiltersSection(),
                
                // ============= قسم الإحصائيات =============
                _buildStatisticsSection(),
                
                // ============= قسم البيانات =============
                Expanded(
                  child: _buildDataSection(),
                ),
              ],
            ),
    );
  }

  // ============= قسم الفلاتر =============
  Widget _buildFiltersSection() {
    return CustomCard(
      margin: AppConstants.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس القسم
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.filter_alt,
                    color: AppColors.primaryLight,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'الفلاتر',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              
              // زر مسح الفلاتر
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('مسح الكل'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
              ),
            ],
          ),
          
          const Divider(),
          
          // الفلاتر
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // فلتر الزبون
              _buildFilterChip(
                label: _selectedCustomer?.customerName ?? 'كل الزبائن',
                icon: Icons.person,
                onTap: () => _showCustomerPicker(),
                isActive: _selectedCustomer != null,
              ),
              
              // فلتر المنتج
              _buildFilterChip(
                label: _selectedProduct?.productName ?? 'كل المنتجات',
                icon: Icons.inventory_2,
                onTap: () => _showProductPicker(),
                isActive: _selectedProduct != null,
              ),
              
              // فلتر المورد
              _buildFilterChip(
                label: _selectedSupplier?.supplierName ?? 'كل الموردين',
                icon: Icons.store,
                onTap: () => _showSupplierPicker(),
                isActive: _selectedSupplier != null,
              ),
              
              // فلتر التاريخ - من
              _buildFilterChip(
                label: _startDate != null
                    ? 'من: ${DateFormat('yyyy-MM-dd').format(_startDate!)}'
                    : 'من تاريخ',
                icon: Icons.calendar_today,
                onTap: () => _pickStartDate(),
                isActive: _startDate != null,
              ),
              
              // فلتر التاريخ - إلى
              _buildFilterChip(
                label: _endDate != null
                    ? 'إلى: ${DateFormat('yyyy-MM-dd').format(_endDate!)}'
                    : 'إلى تاريخ',
                icon: Icons.calendar_today,
                onTap: () => _pickEndDate(),
                isActive: _endDate != null,
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // زر البحث
          CustomButton(
            text: 'تطبيق الفلاتر',
            icon: Icons.search,
            onPressed: _loadReportData,
            size: ButtonSize.small,
          ),
        ],
      ),
    );
  }

  /// بناء رقاقة فلتر
  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppConstants.borderRadiusMd,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryLight.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: AppConstants.borderRadiusMd,
          border: Border.all(
            color: isActive
                ? AppColors.primaryLight
                : Theme.of(context).dividerColor,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? AppColors.primaryLight
                  : Theme.of(context).iconTheme.color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? AppColors.primaryLight
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============= قسم الإحصائيات =============
  Widget _buildStatisticsSection() {
    return CustomCard(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الإحصائيات',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          
          const SizedBox(height: 12),
          
          // الصف الأول
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  label: 'إجمالي المبيعات',
                  value: formatCurrency(_statistics['totalSales'] ?? 0.0),
                  icon: Icons.attach_money,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem(
                  label: 'إجمالي الربح',
                  value: formatCurrency(_statistics['totalProfit'] ?? 0.0),
                  icon: Icons.trending_up,
                  color: AppColors.primaryLight,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // الصف الثاني
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  label: 'عدد المعاملات',
                  value: '${_statistics['totalTransactions'] ?? 0}',
                  icon: Icons.receipt,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem(
                  label: 'متوسط المعاملة',
                  value: formatCurrency(_statistics['averageTransaction'] ?? 0.0),
                  icon: Icons.analytics,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// بناء عنصر إحصائي
  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppConstants.borderRadiusMd,
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ============= قسم البيانات =============
  Widget _buildDataSection() {
    if (_salesData.isEmpty) {
      return const EmptyState(
        icon: Icons.info_outline,
        title: 'لا توجد بيانات',
        message: 'لا توجد مبيعات تطابق الفلاتر المحددة',
      );
    }
    
    return ListView.builder(
      padding: AppConstants.screenPadding,
      itemCount: _salesData.length,
      itemBuilder: (context, index) {
        final sale = _salesData[index];
        return _buildSaleCard(sale);
      },
    );
  }

  /// بناء بطاقة مبيعة
  Widget _buildSaleCard(Map<String, dynamic> sale) {
    final date = DateTime.parse(sale['saleDate']);
    final amount = sale['amount'] as Decimal;
    final profit = sale['profit'] as Decimal;
    final quantity = sale['quantity'];
    
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الرأس
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // التاريخ
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.1),
                  borderRadius: AppConstants.borderRadiusSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: AppColors.primaryLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('yyyy-MM-dd').format(date),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // الكمية
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: AppConstants.borderRadiusSm,
                ),
                child: Text(
                  'الكمية: $quantity',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // الزبون والمنتج
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: AppColors.textSecondaryLight),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  sale['customerName'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 4),
          
          Row(
            children: [
              const Icon(Icons.inventory_2, size: 16, color: AppColors.textSecondaryLight),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  sale['productName'] ?? '',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          
          const Divider(height: 16),
          
          // المبالغ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // المبلغ
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'المبلغ',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  Text(
                    formatCurrency(amount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              
              // الربح
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'الربح',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  Text(
                    formatCurrency(profit),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============= دوال اختيار الفلاتر =============
  
  /// اختيار زبون
  Future<void> _showCustomerPicker() async {
    final selected = await showDialog<Customer>(
      context: context,
      builder: (ctx) => _buildPickerDialog(
        title: 'اختر زبون',
        items: _customers,
        itemBuilder: (customer) => ListTile(
          leading: const Icon(Icons.person),
          title: Text(customer.customerName),
          subtitle: customer.phone != null && customer.phone!.isNotEmpty
              ? Text(customer.phone!)
              : null,
          onTap: () => Navigator.pop(ctx, customer),
        ),
      ),
    );
    
    if (selected != null) {
      setState(() => _selectedCustomer = selected);
    }
  }

  /// اختيار منتج
  Future<void> _showProductPicker() async {
    final selected = await showDialog<Product>(
      context: context,
      builder: (ctx) => _buildPickerDialog(
        title: 'اختر منتج',
        items: _products,
        itemBuilder: (product) => ListTile(
          leading: const Icon(Icons.inventory_2),
          title: Text(product.productName),
          subtitle: Text(product.supplierName ?? ''),
          onTap: () => Navigator.pop(ctx, product),
        ),
      ),
    );
    
    if (selected != null) {
      setState(() => _selectedProduct = selected);
    }
  }

  /// اختيار مورد
  Future<void> _showSupplierPicker() async {
    final selected = await showDialog<Supplier>(
      context: context,
      builder: (ctx) => _buildPickerDialog(
        title: 'اختر مورد',
        items: _suppliers,
        itemBuilder: (supplier) => ListTile(
          leading: const Icon(Icons.store),
          title: Text(supplier.supplierName),
          subtitle: Text(supplier.supplierType),
          onTap: () => Navigator.pop(ctx, supplier),
        ),
      ),
    );
    
    if (selected != null) {
      setState(() => _selectedSupplier = selected);
    }
  }

  /// بناء حوار اختيار
  Widget _buildPickerDialog<T>({
    required String title,
    required List<T> items,
    required Widget Function(T) itemBuilder,
  }) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: items.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('لا توجد عناصر'),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) => itemBuilder(items[index]),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
      ],
    );
  }

  /// اختيار تاريخ البداية
  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  /// اختيار تاريخ النهاية
  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }
}