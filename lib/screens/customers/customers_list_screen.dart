// 📁 lib/screens/customers/customers_list_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../services/auth_service.dart';
import '../../utils/helpers.dart';
import '../../l10n/app_localizations.dart';
import '../../layouts/main_layout.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/status_badge.dart';
import 'add_edit_customer_screen.dart';
import 'customer_details_screen.dart';

/// =================================================================================================
/// 📋 شاشة قائمة الزبائن - Customers List Screen
/// =================================================================================================
/// الوظيفة: عرض قائمة بجميع الزبائن النشطين مع إمكانية البحث والتعديل والأرشفة
/// 
/// المميزات:
/// - ✅ عرض قائمة الزبائن مع صورهم وأرصدتهم
/// - ✅ تمييز الرصيد (دائن/مدين/متوازن) بألوان مختلفة
/// - ✅ إمكانية البحث عن زبون معين
/// - ✅ صلاحيات مخصصة (عرض/تعديل) حسب نوع المستخدم
/// - ✅ أرشفة الزبائن (مع منع أرشفة من لديه ديون)
/// =================================================================================================
class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({super.key});

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  // =================================================================================================
  // 📦 المتغيرات الأساسية
  // =================================================================================================
  
  /// Hint: نسخة وحيدة من قاعدة البيانات للوصول للزبائن
  final _dbHelper = DatabaseHelper.instance;
  
  /// Hint: خدمة المصادقة للتحقق من صلاحيات المستخدم
  final _authService = AuthService();
  
  /// Hint: قائمة الزبائن التي سيتم عرضها (مع دعم البحث)
  List<Customer> _allCustomers = [];
  List<Customer> _filteredCustomers = [];
  
  /// Hint: حالة التحميل (true = جاري التحميل، false = انتهى)
  bool _isLoading = true;
  
  /// Hint: رسالة الخطأ (إن وجدت)
  String? _errorMessage;
  
  /// Hint: متحكم حقل البحث
  final _searchController = TextEditingController();
  
  // =================================================================================================
  // 🔄 دورة حياة الصفحة - Lifecycle
  // =================================================================================================
  
  @override
  void initState() {
    super.initState();
    // Hint: تحميل بيانات الزبائن عند فتح الصفحة لأول مرة
    _loadCustomers();
  }
  
  @override
  void dispose() {
    // Hint: تنظيف الموارد عند مغادرة الصفحة لمنع تسرب الذاكرة
    _searchController.dispose();
    super.dispose();
  }
  
  // =================================================================================================
  // 📥 تحميل البيانات - Data Loading
  // =================================================================================================
  
  /// Hint: دالة لتحميل قائمة الزبائن من قاعدة البيانات
  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Hint: جلب جميع الزبائن النشطين من قاعدة البيانات
      final customers = await _dbHelper.getAllCustomers();
      
      setState(() {
        _allCustomers = customers;
        // Hint: في البداية، القائمة المفلترة = القائمة الكاملة
        _filteredCustomers = customers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
  
  // =================================================================================================
  // 🔍 البحث - Search Functionality
  // =================================================================================================
  
  /// Hint: دالة للبحث في قائمة الزبائن حسب الاسم أو رقم الهاتف
  void _filterCustomers(String query) {
    setState(() {
      if (query.isEmpty) {
        // Hint: إذا كان حقل البحث فارغ، نعرض كل الزبائن
        _filteredCustomers = _allCustomers;
      } else {
        // Hint: البحث في الاسم أو رقم الهاتف (case-insensitive)
        _filteredCustomers = _allCustomers.where((customer) {
          final nameLower = customer.customerName.toLowerCase();
          final phoneLower = customer.phone?.toLowerCase() ?? '';
          final queryLower = query.toLowerCase();
          
          return nameLower.contains(queryLower) || phoneLower.contains(queryLower);
        }).toList();
      }
    });
  }
  
  // =================================================================================================
  // 🗑️ الأرشفة - Archive Functionality
  // =================================================================================================
  
  /// Hint: دالة للتعامل مع طلب أرشفة زبون
  /// تتحقق من عدم وجود ديون قبل السماح بالأرشفة
  Future<void> _handleArchiveCustomer(Customer customer) async {
    final l10n = AppLocalizations.of(context)!;
    
    // === الخطوة 1: التحقق من عدم وجود ديون ===
    if (customer.remaining > 0) {
      // Hint: لا يمكن أرشفة زبون لديه دين متبقي
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.cannotArchiveCustomerWithDebt),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    
    // === الخطوة 2: عرض مربع حوار التأكيد ===
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.archiveConfirmTitle),
        content: Text(l10n.archiveConfirmContent(customer.customerName)),
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
            child: Text(l10n.archive),
          ),
        ],
      ),
    );
    
    // === الخطوة 3: تنفيذ الأرشفة إذا تم التأكيد ===
    if (confirm == true && mounted) {
      try {
        // Hint: أرشفة الزبون في قاعدة البيانات (تغيير IsActive إلى 0)
        await _dbHelper.archiveCustomer(customer.customerID!);
        
        // Hint: تسجيل الإجراء في سجل النشاطات
        await _dbHelper.logActivity(
          'أرشفة الزبون: ${customer.customerName}',
          userId: _authService.currentUser?.id,
          userName: _authService.currentUser?.fullName,
        );
        
        // Hint: إعادة تحميل القائمة لإخفاء الزبون المؤرشف
        _loadCustomers();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم أرشفة ${customer.customerName} بنجاح'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في الأرشفة: $e'),
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
    
    return MainLayout(
      // === تكوين الـ Layout ===
      title: l10n.customersList,
      currentIndex: 0, // Hint: موقع الصفحة في الـ BottomNav (الرئيسية)
      
      // === المحتوى الأساسي ===
      body: _buildBody(l10n),
      
      // === زر الإضافة العائم ===
      // Hint: يظهر فقط إذا كان المستخدم لديه صلاحية تعديل الزبائن
      floatingActionButton: (_authService.canEditCustomers || _authService.isAdmin)
          ? FloatingActionButton(
              onPressed: _navigateToAddCustomer,
              child: const Icon(Icons.add),
              tooltip: l10n.addCustomer,
            )
          : null,
    );
  }
  
  /// Hint: بناء جسم الصفحة (حسب الحالة: تحميل/خطأ/بيانات)
  Widget _buildBody(AppLocalizations l10n) {
    // === حالة التحميل ===
    if (_isLoading) {
      return const LoadingState(message: 'جاري تحميل الزبائن...');
    }
    
    // === حالة الخطأ ===
    if (_errorMessage != null) {
      return ErrorState(
        message: _errorMessage!,
        onRetry: _loadCustomers,
      );
    }
    
    // === حالة عدم وجود زبائن ===
    if (_allCustomers.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: l10n.noActiveCustomers,
        message: 'ابدأ بإضافة أول زبون لك',
        actionText: (_authService.canEditCustomers || _authService.isAdmin) 
            ? l10n.addCustomer 
            : null,
        onAction: (_authService.canEditCustomers || _authService.isAdmin) 
            ? _navigateToAddCustomer 
            : null,
      );
    }
    
    // === حالة عرض البيانات ===
    return Column(
      children: [
        // === شريط البحث ===
        _buildSearchBar(l10n),
        
        // === القائمة ===
        Expanded(
          child: _filteredCustomers.isEmpty
              ? _buildNoResultsState(l10n)
              : _buildCustomersList(),
        ),
      ],
    );
  }
  
  /// Hint: بناء شريط البحث
  Widget _buildSearchBar(AppLocalizations l10n) {
    return Container(
      padding: AppConstants.paddingMd,
      child: TextField(
        controller: _searchController,
        onChanged: _filterCustomers,
        decoration: InputDecoration(
          hintText: l10n.searchForProduct, // TODO: إضافة نص مخصص للزبائن في الترجمة
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterCustomers('');
                  },
                )
              : null,
        ),
      ),
    );
  }
  
  /// Hint: بناء حالة "لا توجد نتائج بحث"
  Widget _buildNoResultsState(AppLocalizations l10n) {
    return EmptyState(
      icon: Icons.search_off,
      title: l10n.noMatchingResults,
      message: 'جرب البحث بكلمة أخرى',
    );
  }
  
  /// Hint: بناء قائمة الزبائن
  Widget _buildCustomersList() {
    return ListView.builder(
      padding: AppConstants.screenPadding,
      itemCount: _filteredCustomers.length,
      itemBuilder: (context, index) {
        final customer = _filteredCustomers[index];
        return _buildCustomerCard(customer);
      },
    );
  }
  
  // =================================================================================================
  // 🃏 بطاقة الزبون - Customer Card
  // =================================================================================================
  
  /// Hint: بناء بطاقة عرض معلومات زبون واحد
  Widget _buildCustomerCard(Customer customer) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // === حساب حالة الرصيد ===
    final balanceInfo = _calculateBalanceInfo(customer, l10n);
    
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      onTap: () => _navigateToCustomerDetails(customer),
      child: Row(
        children: [
          // === صورة الزبون ===
          _buildCustomerAvatar(customer),
          
          const SizedBox(width: AppConstants.spacingMd),
          
          // === معلومات الزبون ===
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الاسم
                Text(
                  customer.customerName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                
                const SizedBox(height: AppConstants.spacingXs),
                
                // رقم الهاتف
                Text(
                  '${l10n.phone}: ${customer.phone ?? l10n.unregistered}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                
                const SizedBox(height: AppConstants.spacingSm),
                
                // شارة الرصيد
                StatusBadge(
                  text: balanceInfo['text'],
                  type: balanceInfo['type'],
                  small: true,
                ),
              ],
            ),
          ),
          
          // === أزرار الإجراءات ===
          if (_authService.canEditCustomers || _authService.isAdmin) ...[
            const SizedBox(width: AppConstants.spacingSm),
            _buildActionButtons(customer),
          ],
        ],
      ),
    );
  }
  
  /// Hint: بناء صورة الزبون (Avatar)
  Widget _buildCustomerAvatar(Customer customer) {
    final imageFile = customer.imagePath != null && customer.imagePath!.isNotEmpty
        ? File(customer.imagePath!)
        : null;
    
    final hasValidImage = imageFile != null && imageFile.existsSync();
    
    return Container(
      width: AppConstants.avatarSizeMd,
      height: AppConstants.avatarSizeMd,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: CircleAvatar(
        radius: AppConstants.avatarSizeMd / 2,
        backgroundImage: hasValidImage ? FileImage(imageFile) : null,
        child: !hasValidImage
            ? Icon(
                Icons.person,
                size: AppConstants.iconSizeLg,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              )
            : null,
      ),
    );
  }
  
  /// Hint: بناء أزرار الإجراءات (تعديل/أرشفة)
  Widget _buildActionButtons(Customer customer) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // زر التعديل
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          color: AppColors.info,
          onPressed: () => _navigateToEditCustomer(customer),
          tooltip: 'تعديل',
        ),
        
        // زر الأرشفة
        if (_authService.isAdmin)
          IconButton(
            icon: const Icon(Icons.archive_outlined, size: 20),
            color: AppColors.error,
            onPressed: () => _handleArchiveCustomer(customer),
            tooltip: 'أرشفة',
          ),
      ],
    );
  }
  
  // =================================================================================================
  // 🧮 دوال مساعدة - Helper Functions
  // =================================================================================================
  
  /// Hint: حساب معلومات الرصيد (النص واللون والنوع)
  Map<String, dynamic> _calculateBalanceInfo(Customer customer, AppLocalizations l10n) {
    if (customer.remaining > 0) {
      // === حالة: الزبون مدين (له دين علينا) ===
      return {
        'text': '${l10n.remainingOnHim}: ${formatCurrency(customer.remaining)}',
        'type': StatusType.error, // أحمر
      };
    } else if (customer.remaining < 0) {
      // === حالة: الزبون دائن (لنا دين عليه) ===
      return {
        'text': '${l10n.remainingForHim}: ${formatCurrency(-customer.remaining)}',
        'type': StatusType.info, // أزرق
      };
    } else {
      // === حالة: الرصيد متوازن ===
      return {
        'text': '${l10n.balance}: 0',
        'type': StatusType.success, // أخضر
      };
    }
  }
  
  // =================================================================================================
  // 🧭 التنقل - Navigation
  // =================================================================================================
  
  /// Hint: الانتقال لصفحة إضافة زبون جديد
  Future<void> _navigateToAddCustomer() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const AddEditCustomerScreen(),
      ),
    );
    
    // Hint: إذا تم الإضافة بنجاح، نعيد تحميل القائمة
    if (result == true) {
      _loadCustomers();
    }
  }
  
  /// Hint: الانتقال لصفحة تعديل زبون
  Future<void> _navigateToEditCustomer(Customer customer) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddEditCustomerScreen(customer: customer),
      ),
    );
    
    // Hint: إذا تم التعديل بنجاح، نعيد تحميل القائمة
    if (result == true) {
      _loadCustomers();
    }
  }
  
  /// Hint: الانتقال لصفحة تفاصيل الزبون
  Future<void> _navigateToCustomerDetails(Customer customer) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomerDetailsScreen(customer: customer),
      ),
    );
    
    // Hint: نعيد التحميل بعد العودة لضمان تحديث أي تغييرات
    _loadCustomers();
  }
}