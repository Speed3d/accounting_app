// 📁 lib/screens/customers/customer_details_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../services/auth_service.dart';
import '../../utils/helpers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/status_badge.dart';
import 'new_sale_screen.dart';

/// =================================================================================================
/// 📋 شاشة تفاصيل الزبون - Customer Details Screen
/// =================================================================================================
/// الوظيفة: عرض تفاصيل زبون معين مع سجل المشتريات والدفعات
/// 
/// المميزات:
/// - ✅ عرض معلومات الزبون الأساسية (الاسم، الرصيد، الصورة)
/// - ✅ تبويبات منفصلة للمشتريات والدفعات
/// - ✅ إضافة عملية بيع جديدة
/// - ✅ تسجيل دفعة جديدة
/// - ✅ إرجاع منتج (للمدير فقط)
/// - ✅ تحديث تلقائي للبيانات
/// =================================================================================================
class CustomerDetailsScreen extends StatefulWidget {
  final Customer customer;
  
  const CustomerDetailsScreen({
    super.key,
    required this.customer,
  });

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen>
    with SingleTickerProviderStateMixin {
  // =================================================================================================
  // 📦 المتغيرات الأساسية
  // =================================================================================================
  
  /// Hint: متحكم التبويبات (المشتريات/الدفعات)
  late TabController _tabController;
  
  /// Hint: نسخة من قاعدة البيانات
  final _dbHelper = DatabaseHelper.instance;
  
  /// Hint: خدمة المصادقة للصلاحيات
  final _authService = AuthService();
  
  /// Hint: بيانات الزبون الحالية (قد تتغير بعد العمليات)
  late Customer _currentCustomer;
  
  /// Hint: قوائم المشتريات والدفعات
  List<CustomerDebt> _debts = [];
  List<CustomerPayment> _payments = [];
  
  /// Hint: حالات التحميل
  bool _isLoadingDebts = true;
  bool _isLoadingPayments = true;
  
  /// Hint: رسائل الأخطاء
  String? _debtsError;
  String? _paymentsError;
  
  // =================================================================================================
  // 🔄 دورة حياة الصفحة - Lifecycle
  // =================================================================================================
  
  @override
  void initState() {
    super.initState();
    
    // Hint: إنشاء متحكم التبويبات (تبويبين: مشتريات ودفعات)
    _tabController = TabController(length: 2, vsync: this);
    
    // Hint: نسخ بيانات الزبون الأولية
    _currentCustomer = widget.customer;
    
    // Hint: تحميل البيانات
    _reloadData();
  }
  
  @override
  void dispose() {
    // Hint: تنظيف الموارد
    _tabController.dispose();
    super.dispose();
  }
  
  // =================================================================================================
  // 📥 تحميل البيانات - Data Loading
  // =================================================================================================
  
  /// Hint: دالة لإعادة تحميل جميع بيانات الزبون
  Future<void> _reloadData() async {
    // === تحميل بيانات الزبون المحدثة ===
    _loadCustomerData();
    
    // === تحميل المشتريات ===
    _loadDebts();
    
    // === تحميل الدفعات ===
    _loadPayments();
  }
  
  /// Hint: تحميل بيانات الزبون الأساسية (لتحديث الرصيد)
  Future<void> _loadCustomerData() async {
    try {
      final customer = await _dbHelper.getCustomerById(_currentCustomer.customerID!);
      if (customer != null && mounted) {
        setState(() {
          _currentCustomer = customer;
        });
      }
    } catch (e) {
      debugPrint('خطأ في تحميل بيانات الزبون: $e');
    }
  }
  
  /// Hint: تحميل قائمة المشتريات
  Future<void> _loadDebts() async {
    setState(() {
      _isLoadingDebts = true;
      _debtsError = null;
    });
    
    try {
      final debts = await _dbHelper.getDebtsForCustomer(_currentCustomer.customerID!);
      
      if (mounted) {
        setState(() {
          _debts = debts;
          _isLoadingDebts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _debtsError = e.toString();
          _isLoadingDebts = false;
        });
      }
    }
  }
  
  /// Hint: تحميل قائمة الدفعات
  Future<void> _loadPayments() async {
    setState(() {
      _isLoadingPayments = true;
      _paymentsError = null;
    });
    
    try {
      final payments = await _dbHelper.getPaymentsForCustomer(_currentCustomer.customerID!);
      
      if (mounted) {
        setState(() {
          _payments = payments;
          _isLoadingPayments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _paymentsError = e.toString();
          _isLoadingPayments = false;
        });
      }
    }
  }
  
  // =================================================================================================
  // 🛒 تسجيل عملية بيع - Record New Sale
  // =================================================================================================
  
  /// Hint: فتح شاشة اختيار المنتجات وتسجيل عملية بيع جديدة
  Future<void> _recordNewSale() async {
    final l10n = AppLocalizations.of(context)!;
    
    // === الخطوة 1: فتح شاشة اختيار المنتجات ===
    final result = await Navigator.of(context).push<List<CartItem>>(
      MaterialPageRoute(
        builder: (context) => const NewSaleScreen(),
      ),
    );
    
    // Hint: إذا ألغى المستخدم أو لم يختر منتجات
    if (result == null || result.isEmpty) return;
    
    // === الخطوة 2: تسجيل العملية في قاعدة البيانات ===
    try {
      final db = await _dbHelper.database;
      double totalSaleAmount = 0;
      
      // Hint: استخدام Transaction لضمان تنفيذ كل العمليات معاً
      await db.transaction((txn) async {
        for (var item in result) {
          final product = item.product;
          final quantitySold = item.quantity;
          
          // حساب القيم
          final salePriceForItem = product.sellingPrice * quantitySold;
          final profitForItem = (product.sellingPrice - product.costPrice) * quantitySold;
          totalSaleAmount += salePriceForItem;
          
          // تفاصيل البيع
          final saleDetails = l10n.saleDetails(
            product.productName,
            quantitySold.toString(),
          );
          
          // === إدراج سجل الدين (المشتريات) ===
          final newDebt = CustomerDebt(
            customerID: _currentCustomer.customerID!,
            customerName: _currentCustomer.customerName,
            details: saleDetails,
            debt: salePriceForItem,
            dateT: DateTime.now().toIso8601String(),
            qty_Coustomer: quantitySold,
            productID: product.productID!,
            costPriceAtTimeOfSale: product.costPrice,
            profitAmount: profitForItem,
          );
          await txn.insert('Debt_Customer', newDebt.toMap());
          
          // === تحديث كمية المنتج في المخزن ===
          await txn.rawUpdate(
            'UPDATE Store_Products SET Quantity = Quantity - ? WHERE ProductID = ?',
            [quantitySold, product.productID],
          );
        }
        
        // === تحديث رصيد الزبون ===
        await txn.rawUpdate(
          'UPDATE TB_Customer SET Debt = Debt + ?, Remaining = Remaining + ? WHERE CustomerID = ?',
          [totalSaleAmount, totalSaleAmount, _currentCustomer.customerID],
        );
      });
      
      // === الخطوة 3: تسجيل النشاط ===
      await _dbHelper.logActivity(
        l10n.newSaleActivityLog(_currentCustomer.customerName, formatCurrency(totalSaleAmount)),
        userId: _authService.currentUser?.id,
        userName: _authService.currentUser?.fullName,
      );
      
      // === الخطوة 4: إظهار رسالة نجاح ===
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.newSaleSuccess),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // === الخطوة 5: تحديث البيانات ===
        _reloadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.saleRecordError(e.toString())),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  
  // =================================================================================================
  // 💰 تسجيل دفعة - Record New Payment
  // =================================================================================================
  
  /// Hint: فتح مربع حوار لتسجيل دفعة جديدة
  Future<void> _recordNewPayment() async {
    final l10n = AppLocalizations.of(context)!;
    
    final paymentController = TextEditingController();
    final commentsController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.newPayment),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // === حقل المبلغ المدفوع ===
              CustomTextField(
                controller: paymentController,
                label: l10n.paidAmount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.attach_money,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.amountRequired;
                  }
                  
                  final amount = double.tryParse(convertArabicNumbersToEnglish(value));
                  if (amount == null || amount <= 0) {
                    return l10n.enterValidAmount;
                  }
                  
                  // Hint: التحقق من أن المبلغ لا يتجاوز الدين
                  if (amount > _currentCustomer.remaining) {
                    return l10n.amountExceedsDebt;
                  }
                  
                  return null;
                },
              ),
              
              const SizedBox(height: AppConstants.spacingMd),
              
              // === حقل الملاحظات ===
              CustomTextField(
                controller: commentsController,
                label: l10n.notesOptional,
                prefixIcon: Icons.note,
                maxLines: 3,
              ),
            ],
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
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    
    // Hint: إذا تم التأكيد، نقوم بحفظ الدفعة
    if (result == true && mounted) {
      try {
        final amount = double.parse(
          convertArabicNumbersToEnglish(paymentController.text),
        );
        
        final db = await _dbHelper.database;
        
        // === استخدام Transaction ===
        await db.transaction((txn) async {
          // إدراج سجل الدفعة
          final newPayment = CustomerPayment(
            customerID: _currentCustomer.customerID!,
            customerName: _currentCustomer.customerName,
            payment: amount,
            dateT: DateTime.now().toIso8601String(),
            comments: commentsController.text,
          );
          await txn.insert('Payment_Customer', newPayment.toMap());
          
          // تحديث رصيد الزبون
          await txn.rawUpdate(
            'UPDATE TB_Customer SET Payment = Payment + ?, Remaining = Remaining - ? WHERE CustomerID = ?',
            [amount, amount, _currentCustomer.customerID],
          );
        });
        
        // تسجيل النشاط
        await _dbHelper.logActivity(
          l10n.paymentActivityLog(_currentCustomer.customerName, formatCurrency(amount)),
          userId: _authService.currentUser?.id,
          userName: _authService.currentUser?.fullName,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.paymentSuccess),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          _reloadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.paymentRecordError(e.toString())),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
  
  // =================================================================================================
  // ↩️ إرجاع منتج - Return Sale
  // =================================================================================================
  
  /// Hint: التعامل مع طلب إرجاع منتج (للمدير فقط)
  Future<void> _handleReturnSale(CustomerDebt sale) async {
    final l10n = AppLocalizations.of(context)!;
    
    // === عرض مربع حوار التأكيد ===
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.returnConfirmTitle),
        content: Text(l10n.returnConfirmContent(sale.details)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: Text(l10n.returnItem),
          ),
        ],
      ),
    );
    
    // === تنفيذ الإرجاع إذا تم التأكيد ===
    if (confirm == true && mounted) {
      try {
        // Hint: دالة returnSaleItem تقوم بكل العمليات اللازمة
        await _dbHelper.returnSaleItem(sale);
        
        // تسجيل النشاط
        await _dbHelper.logActivity(
          l10n.returnActivityLog(sale.details, _currentCustomer.customerName),
          userId: _authService.currentUser?.id,
          userName: _authService.currentUser?.fullName,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.returnSuccess),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          _reloadData();
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
      }
    }
  }
  
  // =================================================================================================
  // 🎨 بناء واجهة المستخدم - UI Building
  // =================================================================================================
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      // === AppBar مع التبويبات ===
      appBar: AppBar(
        title: Text(_currentCustomer.customerName),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.shopping_cart),
              text: l10n.purchases,
            ),
            Tab(
              icon: const Icon(Icons.payment),
              text: l10n.payments,
            ),
          ],
        ),
      ),
      
      // === جسم الصفحة ===
      body: Column(
        children: [
          // === بطاقة معلومات الزبون ===
          _buildCustomerInfoCard(l10n),
          
          const Divider(height: 1),
          
          // === محتوى التبويبات ===
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDebtsTab(l10n),
                _buildPaymentsTab(l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // =================================================================================================
  // 🃏 بطاقة معلومات الزبون - Customer Info Card
  // =================================================================================================
  
  /// Hint: عرض معلومات الزبون الأساسية في أعلى الصفحة
  Widget _buildCustomerInfoCard(AppLocalizations l10n) {
    // حساب حالة الرصيد
    String balanceText;
    StatusType balanceType;
    
    if (_currentCustomer.remaining > 0) {
      balanceText = '${l10n.remainingOnHim}: ${formatCurrency(_currentCustomer.remaining)}';
      balanceType = StatusType.error;
    } else if (_currentCustomer.remaining < 0) {
      balanceText = '${l10n.remainingForHim}: ${formatCurrency(-_currentCustomer.remaining)}';
      balanceType = StatusType.info;
    } else {
      balanceText = '${l10n.balance}: 0';
      balanceType = StatusType.success;
    }
    
    return CustomCard(
      margin: AppConstants.paddingMd,
      child: Row(
        children: [
          // === الأيقونة ===
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: AppConstants.borderRadiusMd,
            ),
            child: Icon(
              Icons.account_balance_wallet,
              color: Theme.of(context).colorScheme.primary,
              size: AppConstants.iconSizeLg,
            ),
          ),
          
          const SizedBox(width: AppConstants.spacingMd),
          
          // === المعلومات ===
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.currentBalance,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppConstants.spacingXs),
                StatusBadge(
                  text: balanceText,
                  type: balanceType,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // =================================================================================================
  // 🛒 تبويب المشتريات - Debts Tab
  // =================================================================================================
  
  Widget _buildDebtsTab(AppLocalizations l10n) {
    return Scaffold(
      // === المحتوى ===
      body: _buildDebtsContent(l10n),
      
      // === زر الإضافة ===
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _recordNewSale,
        icon: const Icon(Icons.add_shopping_cart),
        label: Text(l10n.newSale),
      ),
    );
  }
  
  /// Hint: بناء محتوى تبويب المشتريات
  Widget _buildDebtsContent(AppLocalizations l10n) {
    // === حالة التحميل ===
    if (_isLoadingDebts) {
      return LoadingState(message: l10n.loadingPurchases);
    }
    
    // === حالة الخطأ ===
    if (_debtsError != null) {
      return ErrorState(
        message: _debtsError!,
        onRetry: _loadDebts,
      );
    }
    
    // === حالة عدم وجود مشتريات ===
    if (_debts.isEmpty) {
      return EmptyState(
        icon: Icons.shopping_cart_outlined,
        title: l10n.noPurchases,
        message: l10n.nopurchasesyetrecorded,
      );
    }
    
    // === عرض القائمة ===
    return ListView.builder(
      padding: AppConstants.screenPadding,
      itemCount: _debts.length,
      itemBuilder: (context, index) {
        final debt = _debts[index];
        return _buildDebtCard(debt, l10n);
      },
    );
  }
  
  /// Hint: بناء بطاقة عملية شراء واحدة
  Widget _buildDebtCard(CustomerDebt debt, AppLocalizations l10n) {
    final isReturned = debt.isReturned == 1;
    final dateTime = DateTime.parse(debt.dateT);
    final formattedDate = DateFormat('yyyy-MM-dd – hh:mm a').format(dateTime);
    
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === الصف الأول: الأيقونة والتفاصيل ===
          Row(
            children: [
              // الأيقونة
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingSm),
                decoration: BoxDecoration(
                  color: isReturned
                      ? Colors.grey.withOpacity(0.1)
                      : AppColors.info.withOpacity(0.1),
                  borderRadius: AppConstants.borderRadiusSm,
                ),
                child: Icon(
                  isReturned ? Icons.undo : Icons.receipt_long,
                  color: isReturned ? Colors.grey : AppColors.info,
                  size: 20,
                ),
              ),
              
              const SizedBox(width: AppConstants.spacingMd),
              
              // التفاصيل
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.details,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            decoration: isReturned
                                ? TextDecoration.lineThrough
                                : null,
                            color: isReturned ? Colors.grey : null,
                          ),
                    ),
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      formattedDate,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              
              // المبلغ
              Text(
                formatCurrency(debt.debt),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isReturned ? Colors.grey : AppColors.error,
                      fontWeight: FontWeight.bold,
                      decoration: isReturned
                          ? TextDecoration.lineThrough
                          : null,
                    ),
              ),
            ],
          ),
          
          // === زر الإرجاع (للمدير فقط) ===
          if (!isReturned && _authService.isAdmin) ...[
            const SizedBox(height: AppConstants.spacingMd),
            const Divider(height: 1),
            const SizedBox(height: AppConstants.spacingSm),
            CustomButton(
              text: l10n.returnItem,
              type: ButtonType.text,
              icon: Icons.undo,
              onPressed: () => _handleReturnSale(debt),
              fullWidth: false,
            ),
          ],
        ],
      ),
    );
  }
  
  // =================================================================================================
  // 💰 تبويب الدفعات - Payments Tab
  // =================================================================================================
  
  Widget _buildPaymentsTab(AppLocalizations l10n) {
    return Scaffold(
      // === المحتوى ===
      body: _buildPaymentsContent(l10n),
      
      // === زر الإضافة ===
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _recordNewPayment,
        icon: const Icon(Icons.add),
        label: Text(l10n.newPayment),
      ),
    );
  }
  
  /// Hint: بناء محتوى تبويب الدفعات
  Widget _buildPaymentsContent(AppLocalizations l10n) {
    // === حالة التحميل ===
    if (_isLoadingPayments) {
      return LoadingState(message: l10n.loadingPayments);
    }
    
    // === حالة الخطأ ===
    if (_paymentsError != null) {
      return ErrorState(
        message: _paymentsError!,
        onRetry: _loadPayments,
      );
    }
    
    // === حالة عدم وجود دفعات ===
    if (_payments.isEmpty) {
      return EmptyState(
        icon: Icons.payment,
        title: l10n.noPayments,
        message: l10n.nopaymentsyetrecorded,
      );
    }
    
    // === عرض القائمة ===
    return ListView.builder(
      padding: AppConstants.screenPadding,
      itemCount: _payments.length,
      itemBuilder: (context, index) {
        final payment = _payments[index];
        return _buildPaymentCard(payment, l10n);
      },
    );
  }
  
  /// Hint: بناء بطاقة دفعة واحدة
  Widget _buildPaymentCard(CustomerPayment payment, AppLocalizations l10n) {
    final dateTime = DateTime.parse(payment.dateT);
    final formattedDate = DateFormat('yyyy-MM-dd – hh:mm a').format(dateTime);
    final hasComments = payment.comments != null && payment.comments!.isNotEmpty;
    
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: Row(
        children: [
          // === الأيقونة ===
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingSm),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: AppConstants.borderRadiusSm,
            ),
            child: const Icon(
              Icons.attach_money,
              color: AppColors.success,
              size: 20,
            ),
          ),
          
          const SizedBox(width: AppConstants.spacingMd),
          
          // === المعلومات ===
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatCurrency(payment.payment),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppConstants.spacingXs),
                Text(
                  formattedDate,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                
                // === الملاحظات (إن وجدت) ===
                if (hasComments) ...[
                  const SizedBox(height: AppConstants.spacingXs),
                  Text(
                    '📝 ${payment.comments}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          
          // === زر عرض الملاحظات (إن وجدت) ===
          if (hasComments)
            IconButton(
              icon: const Icon(Icons.comment_outlined),
              color: Theme.of(context).colorScheme.primary,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.notesOptional),
                    content: Text(payment.comments!),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(l10n.close),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}