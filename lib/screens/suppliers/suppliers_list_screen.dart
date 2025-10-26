// lib/screens/suppliers/suppliers_list_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../services/auth_service.dart';
import '../../layouts/main_layout.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/custom_text_field.dart';
import 'add_edit_supplier_screen.dart';
import 'package:accounting_app/l10n/app_localizations.dart';

/// شاشة قائمة الموردين
class SuppliersListScreen extends StatefulWidget {
  const SuppliersListScreen({super.key});

  @override
  State<SuppliersListScreen> createState() => _SuppliersListScreenState();
}

class _SuppliersListScreenState extends State<SuppliersListScreen> {
  final dbHelper = DatabaseHelper.instance;
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  
  late Future<List<Supplier>> _suppliersFuture;
  late bool _isAdmin;
  List<Supplier> _allSuppliers = [];
  List<Supplier> _filteredSuppliers = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _isAdmin = _authService.isAdmin;
    _loadSuppliers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// تحميل الموردين من قاعدة البيانات
  void _loadSuppliers() {
    setState(() {
      _suppliersFuture = dbHelper.getAllSuppliers();
    });
  }

  /// البحث في الموردين
  void _filterSuppliers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSuppliers = _allSuppliers;
        _isSearching = false;
      } else {
        _isSearching = true;
        _filteredSuppliers = _allSuppliers.where((supplier) {
          return supplier.supplierName.toLowerCase().contains(query.toLowerCase()) ||
                 supplier.supplierType.contains(query) ||
                 (supplier.phone?.contains(query) ?? false);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MainLayout(
      title: l10n.suppliersList,
      currentIndex: -1, // ليس في الـ Bottom Navigation
      showBottomNav: false,
      body: Column(
        children: [
          // ============= شريط البحث والإحصائيات =============
          _buildHeader(l10n),
          
          // ============= قائمة الموردين =============
          Expanded(
            child: FutureBuilder<List<Supplier>>(
              future: _suppliersFuture,
              builder: (context, snapshot) {
                // حالة التحميل
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingState(message: 'جاري تحميل الموردين...');
                }

                // حالة الخطأ
                if (snapshot.hasError) {
                  return ErrorState(
                    message: 'حدث خطأ أثناء تحميل البيانات',
                    onRetry: _loadSuppliers,
                  );
                }

                // حالة البيانات الفارغة
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return EmptyState(
                    icon: Icons.store_outlined,
                    title: l10n.noActiveSuppliers,
                    message: 'لا يوجد موردين حالياً',
                    actionText: _isAdmin ? 'إضافة مورد جديد' : null,
                    onAction: _isAdmin ? _navigateToAddSupplier : null,
                  );
                }

                // حفظ البيانات للبحث
                _allSuppliers = snapshot.data!;
                final displayList = _isSearching ? _filteredSuppliers : _allSuppliers;

                // عرض القائمة
                return RefreshIndicator(
                  onRefresh: () async {
                    _loadSuppliers();
                  },
                  child: displayList.isEmpty
                      ? EmptyState(
                          icon: Icons.search_off,
                          title: 'لا توجد نتائج',
                          message: 'لم يتم العثور على موردين بهذا الاسم',
                        )
                      : ListView.builder(
                          padding: AppConstants.screenPadding,
                          itemCount: displayList.length,
                          itemBuilder: (context, index) {
                            return _buildSupplierCard(displayList[index], l10n);
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
      
      // ============= زر الإضافة =============
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: _navigateToAddSupplier,
              icon: const Icon(Icons.add),
              label: const Text('إضافة مورد'),
            )
          : null,
    );
  }

  /// بناء الهيدر مع البحث والإحصائيات
  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: AppConstants.paddingMd,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Column(
        children: [
          // شريط البحث
          SearchTextField(
            controller: _searchController,
            hint: 'البحث عن مورد...',
            onChanged: _filterSuppliers,
            onClear: () {
              setState(() {
                _searchController.clear();
                _isSearching = false;
                _filteredSuppliers = _allSuppliers;
              });
            },
          ),
          
          const SizedBox(height: AppConstants.spacingMd),
          
          // إحصائيات سريعة
          FutureBuilder<List<Supplier>>(
            future: _suppliersFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              
              final suppliers = snapshot.data!;
              final partnershipCount = suppliers.where((s) => s.supplierType == 'شراكة').length;
              final individualCount = suppliers.where((s) => s.supplierType == 'فردي').length;
              
              return Row(
                children: [
                  Expanded(
                    child: _buildQuickStat(
                      'إجمالي الموردين',
                      '${suppliers.length}',
                      Icons.store,
                      AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingSm),
                  Expanded(
                    child: _buildQuickStat(
                      'شراكات',
                      '$partnershipCount',
                      Icons.handshake,
                      AppColors.info,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingSm),
                  Expanded(
                    child: _buildQuickStat(
                      'أفراد',
                      '$individualCount',
                      Icons.person,
                      AppColors.warning,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// بناء إحصائية سريعة
  Widget _buildQuickStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical: AppConstants.spacingMd,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppConstants.borderRadiusMd,
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppConstants.spacingXs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// بناء بطاقة المورد
  Widget _buildSupplierCard(Supplier supplier, AppLocalizations l10n) {
    final imageFile = supplier.imagePath != null && supplier.imagePath!.isNotEmpty 
        ? File(supplier.imagePath!) 
        : null;
    
    final hasImage = imageFile != null && imageFile.existsSync();

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      onTap: () {
        // TODO: الانتقال لصفحة تفاصيل المورد
      },
      child: Row(
        children: [
          // ============= صورة المورد =============
          Hero(
            tag: 'supplier-${supplier.supplierID}',
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.1),
                borderRadius: AppConstants.borderRadiusMd,
                image: hasImage
                    ? DecorationImage(
                        image: FileImage(imageFile),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: !hasImage
                  ? Icon(
                      Icons.store,
                      color: AppColors.primaryLight,
                      size: 30,
                    )
                  : null,
            ),
          ),
          
          const SizedBox(width: AppConstants.spacingMd),
          
          // ============= معلومات المورد =============
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الاسم
                Text(
                  supplier.supplierName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: AppConstants.spacingXs),
                
                // النوع
                Row(
                  children: [
                    StatusBadge(
                      text: supplier.supplierType,
                      type: supplier.supplierType == 'شراكة' 
                          ? StatusType.info 
                          : StatusType.neutral,
                      small: true,
                    ),
                    
                    if (supplier.phone != null && supplier.phone!.isNotEmpty) ...[
                      const SizedBox(width: AppConstants.spacingSm),
                      Icon(
                        Icons.phone,
                        size: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: AppConstants.spacingXs),
                      Expanded(
                        child: Text(
                          supplier.phone!,
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                
                // الشركاء (إذا كان شراكة)
                if (supplier.supplierType == 'شراكة' && supplier.partners.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.spacingXs),
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: AppConstants.spacingXs),
                      Text(
                        '${supplier.partners.length} شريك',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // ============= أزرار الإجراءات (للمدير فقط) =============
          if (_isAdmin) ...[
            const SizedBox(width: AppConstants.spacingSm),
            Column(
              children: [
                // زر التعديل
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  color: AppColors.info,
                  iconSize: 20,
                  tooltip: l10n.edit,
                  onPressed: () => _navigateToEditSupplier(supplier),
                ),
                
                // زر الأرشفة
                IconButton(
                  icon: const Icon(Icons.archive_outlined),
                  color: AppColors.error,
                  iconSize: 20,
                  tooltip: l10n.archive,
                  onPressed: () => _handleArchiveSupplier(supplier),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// الانتقال لإضافة مورد جديد
  Future<void> _navigateToAddSupplier() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddEditSupplierScreen(),
      ),
    );
    
    if (result == true) {
      _loadSuppliers();
    }
  }

  /// الانتقال لتعديل مورد
  Future<void> _navigateToEditSupplier(Supplier supplier) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditSupplierScreen(supplier: supplier),
      ),
    );
    
    if (result == true) {
      _loadSuppliers();
    }
  }

  /// معالجة أرشفة المورد
  Future<void> _handleArchiveSupplier(Supplier supplier) async {
    final l10n = AppLocalizations.of(context)!;
    
    // التحقق من وجود منتجات نشطة
    final hasProducts = await dbHelper.hasActiveProducts(supplier.supplierID!);
    
    if (hasProducts) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.cannotArchiveSupplierWithActiveProducts),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    // عرض مربع حوار التأكيد
    if (!mounted) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildArchiveConfirmDialog(supplier, l10n),
    );
    
    if (confirmed == true) {
      await _archiveSupplier(supplier, l10n);
    }
  }

  /// بناء مربع حوار تأكيد الأرشفة
  Widget _buildArchiveConfirmDialog(Supplier supplier, AppLocalizations l10n) {
    return AlertDialog(
      icon: const Icon(
        Icons.archive_outlined,
        size: 48,
        color: AppColors.warning,
      ),
      title: Text(l10n.archive),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.archiveSupplierConfirmation(supplier.supplierName),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Container(
            padding: AppConstants.paddingSm,
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: AppConstants.borderRadiusSm,
              border: Border.all(
                color: AppColors.warning.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(
                  child: Text(
                    'يمكنك استعادة المورد لاحقاً من مركز الأرشيف',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          child: Text(l10n.archive),
        ),
      ],
    );
  }

  /// تنفيذ عملية الأرشفة
  Future<void> _archiveSupplier(Supplier supplier, AppLocalizations l10n) async {
    try {
      await dbHelper.archiveSupplier(supplier.supplierID!);
      await dbHelper.logActivity(
        l10n.archiveSupplierLog(supplier.supplierName),
        userId: _authService.currentUser?.id,
        userName: _authService.currentUser?.fullName,
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم أرشفة المورد "${supplier.supplierName}" بنجاح'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      _loadSuppliers();
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء الأرشفة: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}