// lib/screens/archive/archive_center_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_state.dart';

/// 🗄️ شاشة مركز الأرشيف - صفحة فرعية
/// Hint: تعرض العناصر المؤرشفة مع إمكانية استعادتها
class ArchiveCenterScreen extends StatefulWidget {
  const ArchiveCenterScreen({super.key});

  @override
  State<ArchiveCenterScreen> createState() => _ArchiveCenterScreenState();
}

class _ArchiveCenterScreenState extends State<ArchiveCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // ============= AppBar مع TabBar =============
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.archive_outlined,
              color: isDark ? AppColors.textPrimaryDark : Colors.white,
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Text(l10n.archiveCenter),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.borderDark : Colors.white24,
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: isDark ? AppColors.primaryDark : Colors.white,
              unselectedLabelColor: isDark
                  ? AppColors.textSecondaryDark
                  : Colors.white70,
              indicatorColor: isDark ? AppColors.primaryDark : Colors.white,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              tabs: [
                Tab(
                  icon: const Icon(Icons.people_outline, size: 20),
                  text: l10n.customers,
                ),
                Tab(
                  icon: const Icon(Icons.store_outlined, size: 20),
                  text: l10n.suppliers,
                ),
                Tab(
                  icon: const Icon(Icons.inventory_2_outlined, size: 20),
                  text: l10n.products,
                ),
                Tab(
                  icon: const Icon(Icons.badge_outlined, size: 20),
                  text: l10n.employees ?? 'الموظفين',
                ),
              ],
            ),
          ),
        ),
      ),

      // ============= Body =============
      body: TabBarView(
        controller: _tabController,
        children: [
          _ArchivedItemsList(itemType: _ItemType.customer, l10n: l10n),
          _ArchivedItemsList(itemType: _ItemType.supplier, l10n: l10n),
          _ArchivedItemsList(itemType: _ItemType.product, l10n: l10n),
          _ArchivedItemsList(itemType: _ItemType.employee, l10n: l10n),
        ],
      ),
    );
  }
}

// ============================================================
// 📋 أنواع العناصر المؤرشفة
// ============================================================
enum _ItemType { customer, supplier, product, employee }

// ============================================================
// 📜 قائمة العناصر المؤرشفة
// ============================================================
class _ArchivedItemsList extends StatefulWidget {
  final _ItemType itemType;
  final AppLocalizations l10n;
  

  const _ArchivedItemsList({
    required this.itemType,
    required this.l10n,
  });

  @override
  State<_ArchivedItemsList> createState() => _ArchivedItemsListState();
}

class _ArchivedItemsListState extends State<_ArchivedItemsList> {
  
  final dbHelper = DatabaseHelper.instance;
  // ← Hint: تم إزالة AuthService
  late Future<List<dynamic>> _archivedItemsFuture;
  

  @override
  void initState() {
    super.initState();
    _loadArchivedItems();
  }

  /// تحميل العناصر المؤرشفة
  void _loadArchivedItems() {
    setState(() {
      switch (widget.itemType) {
        case _ItemType.customer:
          _archivedItemsFuture = dbHelper.getArchivedCustomers();
          break;
        case _ItemType.supplier:
          _archivedItemsFuture = dbHelper.getArchivedSuppliers();
          break;
        case _ItemType.product:
          _archivedItemsFuture =
              dbHelper.getArchivedProductsWithSupplierName();
          break;
        case _ItemType.employee:
          _archivedItemsFuture = dbHelper.getArchivedEmployees();
          break;
      }
    });
  }

  /// استعادة عنصر من الأرشيف
  Future<void> _restoreItem(dynamic item) async {
    // تحديد بيانات العنصر
    String tableName;
    String idColumn;
    int id;
    String name;

    switch (widget.itemType) {
      case _ItemType.customer:
        tableName = 'TB_Customer';
        idColumn = 'CustomerID';
        id = (item as Customer).customerID!;
        name = item.customerName;
        break;
      case _ItemType.supplier:
        tableName = 'TB_Suppliers';
        idColumn = 'SupplierID';
        id = (item as Supplier).supplierID!;
        name = item.supplierName;
        break;
      case _ItemType.product:
        tableName = 'Store_Products';
        idColumn = 'ProductID';
        id = (item as Product).productID!;
        name = item.productName;
        break;
      case _ItemType.employee:
        tableName = 'TB_Employees';
        idColumn = 'EmployeeID';
        id = (item as Employee).employeeID!;
        name = item.fullName;
        break;
    }

    // تأكيد الاستعادة
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.l10n.restore),
        // content: Text('هل تريد استعادة "$name"؟'),
        content: Text(l10n.restoreConfirm(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(widget.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(widget.l10n.restore),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // تنفيذ الاستعادة
    try {
      await dbHelper.restoreItem(tableName, idColumn, id);
      await dbHelper.logActivity(
        // 'استعادة العنصر: $name',
        l10n.restoreConfirm(name),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(
                  child: Text(widget.l10n.itemRestoredSuccess(name)),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      _loadArchivedItems();
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // content: Text('خطأ في الاستعادة: $e'),
            content: Text(l10n.errorArchiveRestor(e.toString())),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<dynamic>>(
      future: _archivedItemsFuture,
      builder: (context, snapshot) {
        // حالة التحميل
        if (snapshot.connectionState == ConnectionState.waiting) {
          return  LoadingState(message: l10n.loading);
        }

        // حالة الخطأ
        if (snapshot.hasError) {
          return ErrorState(
            message: snapshot.error.toString(),
            onRetry: _loadArchivedItems,
          );
        }

        // حالة الفراغ
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        // عرض القائمة
        final items = snapshot.data!;
        return ListView.builder(
          padding: AppConstants.screenPadding,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildListItem(item);
          },
        );
      },
    );
  }

  // ============================================================
  // 🎨 بناء حالة الفراغ
  // ============================================================
  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    IconData icon;
    String message;

    switch (widget.itemType) {
      case _ItemType.customer:
        icon = Icons.people_outline;
        message = l10n.noarchivedcustomers;
        break;
      case _ItemType.supplier:
        icon = Icons.store_outlined;
        message = l10n.noarchivedsuppliers;
        break;
      case _ItemType.product:
        icon = Icons.inventory_2_outlined;
        message = l10n.noarchivedproducts;
        break;
      case _ItemType.employee:
        icon = Icons.badge_outlined;
        message = 'لا يوجد موظفين مؤرشفين';
        break;
    }

    return EmptyState(
      icon: icon,
      title: widget.l10n.noArchivedItems,
      message: message,
    );
  }

  // ============================================================
  // 🃏 بناء عنصر القائمة
  // ============================================================
  Widget _buildListItem(dynamic item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // تحديد بيانات العرض
    String title = '';
    String subtitle = '';
    File? imageFile;
    IconData icon = Icons.help;
    Color iconColor = AppColors.info;

    if (item is Customer) {
      title = item.customerName;
      subtitle = widget.l10n.archivedCustomer;
      icon = Icons.person_outline;
      iconColor = AppColors.info;
      if (item.imagePath != null && item.imagePath!.isNotEmpty) {
        imageFile = File(item.imagePath!);
      }
    } else if (item is Supplier) {
      title = item.supplierName;
      subtitle = widget.l10n.archivedSupplier;
      icon = Icons.store_outlined;
      iconColor = AppColors.warning;
      if (item.imagePath != null && item.imagePath!.isNotEmpty) {
        imageFile = File(item.imagePath!);
      }
    } else if (item is Product) {
      title = item.productName;
      subtitle = widget.l10n.archivedProduct(
        item.supplierName ?? widget.l10n.unknown,
      );
      icon = Icons.inventory_2_outlined;
      iconColor = AppColors.success;
    } else if (item is Employee) {
      title = item.fullName;
      subtitle = 'موظف مؤرشف - ${item.jobTitle}';
      icon = Icons.badge_outlined;
      iconColor = AppColors.primary;
      if (item.imagePath != null && item.imagePath!.isNotEmpty) {
        imageFile = File(item.imagePath!);
      }
    }

    final hasValidImage = imageFile != null && imageFile.existsSync();

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMd,
          vertical: AppConstants.spacingSm,
        ),
        
        // ============= صورة/أيقونة العنصر =============
        leading: Container(
          width: AppConstants.avatarSizeMd,
          height: AppConstants.avatarSizeMd,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: iconColor.withOpacity(0.3),
              width: 2,
            ),
            image: hasValidImage
                ? DecorationImage(
                    image: FileImage(imageFile!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: !hasValidImage
              ? Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                )
              : null,
        ),
        
        // ============= معلومات العنصر =============
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Row(
          children: [
            Icon(
              Icons.archive_outlined,
              size: 14,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        
        // ============= زر الاستعادة =============
        trailing: Container(
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: AppConstants.borderRadiusMd,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: AppConstants.borderRadiusMd,
              onTap: () => _restoreItem(item),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingMd,
                  vertical: AppConstants.spacingSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.restore,
                      size: 18,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: AppConstants.spacingXs),
                    Text(
                      widget.l10n.restore,
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}