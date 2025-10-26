// lib/screens/users/users_list_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/custom_text_field.dart';
import 'add_edit_user_screen.dart';
import 'package:accounting_app/l10n/app_localizations.dart';

/// شاشة قائمة المستخدمين
class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final dbHelper = DatabaseHelper.instance;
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  
  late Future<List<User>> _usersFuture;
  List<User> _allUsers = [];
  List<User> _filteredUsers = [];
  bool _isSearching = false;
  String _filterRole = 'الكل'; // الكل، مدير، مستخدم

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// تحميل المستخدمين من قاعدة البيانات
  void _loadUsers() {
    setState(() {
      _usersFuture = dbHelper.getAllUsers();
    });
  }

  /// البحث والفلترة في المستخدمين
  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty && _filterRole == 'الكل') {
        _filteredUsers = _allUsers;
        _isSearching = false;
      } else {
        _isSearching = true;
        _filteredUsers = _allUsers.where((user) {
          final matchesSearch = query.isEmpty ||
              user.fullName.toLowerCase().contains(query.toLowerCase()) ||
              user.userName.toLowerCase().contains(query.toLowerCase());
          
          final matchesRole = _filterRole == 'الكل' ||
              (_filterRole == 'مدير' && user.isAdmin) ||
              (_filterRole == 'مستخدم' && !user.isAdmin);
          
          return matchesSearch && matchesRole;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      // ============= AppBar =============
      appBar: AppBar(
        title: Text(l10n.usersList),
        centerTitle: false,
      ),
      
      // ============= Body =============
      body: Column(
        children: [
          // ============= شريط البحث والفلترة =============
          _buildHeader(l10n),
          
          // ============= قائمة المستخدمين =============
          Expanded(
            child: FutureBuilder<List<User>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                // حالة التحميل
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingState(message: 'جاري تحميل المستخدمين...');
                }

                // حالة الخطأ
                if (snapshot.hasError) {
                  return ErrorState(
                    message: 'حدث خطأ أثناء تحميل البيانات',
                    onRetry: _loadUsers,
                  );
                }

                // حالة البيانات الفارغة
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return EmptyState(
                    icon: Icons.people_outline,
                    title: l10n.noUsers,
                    message: 'لا يوجد مستخدمين حالياً',
                    actionText: _authService.isAdmin ? 'إضافة مستخدم جديد' : null,
                    onAction: _authService.isAdmin ? _navigateToAddUser : null,
                  );
                }

                // حفظ البيانات للبحث
                _allUsers = snapshot.data!;
                final displayList = _isSearching ? _filteredUsers : _allUsers;

                // عرض القائمة
                return displayList.isEmpty
                    ? EmptyState(
                        icon: Icons.search_off,
                        title: 'لا توجد نتائج',
                        message: 'لم يتم العثور على مستخدمين بهذه المعايير',
                      )
                    : ListView.builder(
                        padding: AppConstants.screenPadding,
                        itemCount: displayList.length,
                        itemBuilder: (context, index) {
                          return _buildUserCard(displayList[index], l10n);
                        },
                      );
              },
            ),
          ),
        ],
      ),
      
      // ============= زر الإضافة =============
      floatingActionButton: _authService.isAdmin
          ? FloatingActionButton.extended(
              onPressed: _navigateToAddUser,
              icon: const Icon(Icons.person_add),
              label: const Text('إضافة مستخدم'),
            )
          : null,
    );
  }

  /// بناء الهيدر مع البحث والفلترة
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
            hint: 'البحث عن مستخدم...',
            onChanged: _filterUsers,
            onClear: () {
              setState(() {
                _searchController.clear();
                _filterUsers('');
              });
            },
          ),
          
          const SizedBox(height: AppConstants.spacingMd),
          
          // فلاتر الصلاحيات
          Row(
            children: [
              _buildFilterChip('الكل', Icons.people),
              const SizedBox(width: AppConstants.spacingSm),
              _buildFilterChip('مدير', Icons.admin_panel_settings),
              const SizedBox(width: AppConstants.spacingSm),
              _buildFilterChip('مستخدم', Icons.person),
            ],
          ),
          
          const SizedBox(height: AppConstants.spacingMd),
          
          // إحصائيات سريعة
          FutureBuilder<List<User>>(
            future: _usersFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              
              final users = snapshot.data!;
              final adminsCount = users.where((u) => u.isAdmin).length;
              final regularCount = users.length - adminsCount;
              
              return Row(
                children: [
                  Expanded(
                    child: _buildQuickStat(
                      'إجمالي المستخدمين',
                      '${users.length}',
                      Icons.people,
                      AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingSm),
                  Expanded(
                    child: _buildQuickStat(
                      'المدراء',
                      '$adminsCount',
                      Icons.admin_panel_settings,
                      AppColors.error,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingSm),
                  Expanded(
                    child: _buildQuickStat(
                      'المستخدمين',
                      '$regularCount',
                      Icons.person,
                      AppColors.info,
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

  /// بناء رقاقة الفلتر
  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _filterRole == label;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _filterRole = label;
            _filterUsers(_searchController.text);
          });
        },
        borderRadius: AppConstants.borderRadiusMd,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingSm,
            vertical: AppConstants.spacingMd,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryLight.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: AppConstants.borderRadiusMd,
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryLight
                  : Theme.of(context).dividerColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? AppColors.primaryLight
                    : Theme.of(context).iconTheme.color,
              ),
              const SizedBox(width: AppConstants.spacingXs),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? AppColors.primaryLight
                        : Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء إحصائية سريعة
  Widget _buildQuickStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingXs,
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
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppConstants.spacingXs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// بناء بطاقة المستخدم
  Widget _buildUserCard(User user, AppLocalizations l10n) {
    final imageFile = user.imagePath != null && user.imagePath!.isNotEmpty
        ? File(user.imagePath!)
        : null;
    
    final hasImage = imageFile != null && imageFile.existsSync();
    final isCurrentUser = user.id == _authService.currentUser?.id;
    
    // حساب عدد الصلاحيات الممنوحة
    final permissionsCount = _countActivePermissions(user);

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      color: isCurrentUser 
          ? AppColors.info.withOpacity(0.05)
          : null,
      child: Column(
        children: [
          // ============= معلومات المستخدم الأساسية =============
          Row(
            children: [
              // صورة المستخدم
              Stack(
                children: [
                  Hero(
                    tag: 'user-${user.id}',
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: user.isAdmin
                            ? AppColors.error.withOpacity(0.1)
                            : AppColors.info.withOpacity(0.1),
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
                              Icons.person,
                              color: user.isAdmin ? AppColors.error : AppColors.info,
                              size: 30,
                            )
                          : null,
                    ),
                  ),
                  
                  // شارة المدير
                  if (user.isAdmin)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).cardColor,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(width: AppConstants.spacingMd),
              
              // معلومات المستخدم
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الاسم
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.fullName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: AppConstants.spacingXs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.info.withOpacity(0.2),
                              borderRadius: AppConstants.borderRadiusFull,
                            ),
                            child: Text(
                              l10n.you,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.info,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: AppConstants.spacingXs),
                    
                    // اسم المستخدم
                    Row(
                      children: [
                        Icon(
                          Icons.alternate_email,
                          size: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: AppConstants.spacingXs),
                        Expanded(
                          child: Text(
                            user.userName,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppConstants.spacingXs),
                    
                    // الصلاحية
                    Row(
                      children: [
                        StatusBadge(
                          text: user.isAdmin ? l10n.admin : l10n.customPermissionsUser,
                          type: user.isAdmin ? StatusType.error : StatusType.info,
                          small: true,
                        ),
                        if (!user.isAdmin) ...[
                          const SizedBox(width: AppConstants.spacingSm),
                          Icon(
                            Icons.shield,
                            size: 14,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: AppConstants.spacingXs),
                          Text(
                            '$permissionsCount صلاحية',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // أزرار الإجراءات (للمدير فقط)
              if (_authService.isAdmin) ...[
                const SizedBox(width: AppConstants.spacingSm),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      color: AppColors.info,
                      iconSize: 20,
                      tooltip: l10n.edit,
                      onPressed: () => _handleEditUser(user, isCurrentUser, l10n),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: AppColors.error,
                      iconSize: 20,
                      tooltip: l10n.delete,
                      onPressed: () => _handleDeleteUser(user, isCurrentUser, l10n),
                    ),
                  ],
                ),
              ],
            ],
          ),
          
          // ============= عرض الصلاحيات (للمستخدمين غير المدراء) =============
          if (!user.isAdmin) ...[
            const SizedBox(height: AppConstants.spacingMd),
            Divider(height: 1, color: Theme.of(context).dividerColor),
            const SizedBox(height: AppConstants.spacingMd),
            _buildPermissionsSection(user),
          ],
        ],
      ),
    );
  }

  /// بناء قسم الصلاحيات
  Widget _buildPermissionsSection(User user) {
    final permissions = [
      if (user.canViewSuppliers || user.canEditSuppliers)
        _PermissionItem('الموردين', 
          user.canViewSuppliers ? (user.canEditSuppliers ? 'عرض وتعديل' : 'عرض فقط') : 'لا يوجد',
          Icons.store,
          user.canEditSuppliers ? AppColors.success : AppColors.warning,
        ),
      if (user.canViewProducts || user.canEditProducts)
        _PermissionItem('المنتجات',
          user.canViewProducts ? (user.canEditProducts ? 'عرض وتعديل' : 'عرض فقط') : 'لا يوجد',
          Icons.inventory_2,
          user.canEditProducts ? AppColors.success : AppColors.warning,
        ),
      if (user.canViewCustomers || user.canEditCustomers)
        _PermissionItem('العملاء',
          user.canViewCustomers ? (user.canEditCustomers ? 'عرض وتعديل' : 'عرض فقط') : 'لا يوجد',
          Icons.people,
          user.canEditCustomers ? AppColors.success : AppColors.warning,
        ),
      if (user.canViewReports)
        _PermissionItem('التقارير', 'عرض', Icons.assessment, AppColors.info),
      if (user.canManageEmployees)
        _PermissionItem('الموظفين', 'إدارة كاملة', Icons.badge, AppColors.success),
      if (user.canViewEmployeesReport)
        _PermissionItem('تقارير الموظفين', 'عرض', Icons.description, AppColors.info),
      if (user.canManageExpenses)
        _PermissionItem('المصاريف', 'إدارة كاملة', Icons.receipt_long, AppColors.success),
      if (user.canViewCashSales)
        _PermissionItem('المبيعات النقدية', 'عرض', Icons.point_of_sale, AppColors.info),
      if (user.canViewSettings)
        _PermissionItem('الإعدادات', 'عرض', Icons.settings, AppColors.warning),
    ];

    if (permissions.isEmpty) {
      return Container(
        padding: AppConstants.paddingSm,
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: AppConstants.borderRadiusSm,
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber, size: 16, color: AppColors.warning),
            const SizedBox(width: AppConstants.spacingSm),
            Text(
              'لا توجد صلاحيات ممنوحة',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: AppConstants.spacingSm,
      runSpacing: AppConstants.spacingSm,
      children: permissions.map((perm) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingSm,
            vertical: AppConstants.spacingXs,
          ),
          decoration: BoxDecoration(
            color: perm.color.withOpacity(0.1),
            borderRadius: AppConstants.borderRadiusSm,
            border: Border.all(
              color: perm.color.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(perm.icon, size: 14, color: perm.color),
              const SizedBox(width: AppConstants.spacingXs),
              Text(
                perm.name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: perm.color,
                ),
              ),
              const SizedBox(width: AppConstants.spacingXs),
              Text(
                '(${perm.level})',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: perm.color.withOpacity(0.7),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// حساب عدد الصلاحيات النشطة
  int _countActivePermissions(User user) {
    if (user.isAdmin) return 0; // المدير لديه كل الصلاحيات
    
    int count = 0;
    if (user.canViewSuppliers) count++;
    if (user.canEditSuppliers) count++;
    if (user.canViewProducts) count++;
    if (user.canEditProducts) count++;
    if (user.canViewCustomers) count++;
    if (user.canEditCustomers) count++;
    if (user.canViewReports) count++;
    if (user.canManageEmployees) count++;
    if (user.canViewSettings) count++;
    if (user.canViewEmployeesReport) count++;
    if (user.canManageExpenses) count++;
    if (user.canViewCashSales) count++;
    
    return count;
  }

  /// معالجة تعديل المستخدم
  Future<void> _handleEditUser(User user, bool isCurrentUser, AppLocalizations l10n) async {
    // if (isCurrentUser) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text(l10n.cannotEditOwnAccount),
    //       backgroundColor: AppColors.warning,
    //       behavior: SnackBarBehavior.floating,
    //     ),
    //   );
    //   return;
    // }
    
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditUserScreen(user: user),
      ),
    );
    
    if (result == true) {
      _loadUsers();
    }
  }

  /// معالجة حذف المستخدم
  Future<void> _handleDeleteUser(User user, bool isCurrentUser, AppLocalizations l10n) async {
    if (isCurrentUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.cannotDeleteOwnAccount),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    if (_allUsers.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.cannotDeleteLastUser),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDeleteConfirmDialog(user, l10n),
    );
    
    if (confirmed == true) {
      await _deleteUser(user, l10n);
    }
  }

  /// بناء مربع حوار تأكيد الحذف
  Widget _buildDeleteConfirmDialog(User user, AppLocalizations l10n) {
    return AlertDialog(
      icon: const Icon(
        Icons.delete_outline,
        size: 48,
        color: AppColors.error,
      ),
      title: Text(l10n.delete),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.deleteUserConfirmation(user.fullName),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Container(
            padding: AppConstants.paddingSm,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: AppConstants.borderRadiusSm,
              border: Border.all(
                color: AppColors.error.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber,
                  size: 16,
                  color: AppColors.error,
                ),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(
                  child: Text(
                    'هذا الإجراء لا يمكن التراجع عنه',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
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
          child: Text(l10n.delete),
        ),
      ],
    );
  }

  /// تنفيذ عملية الحذف
  Future<void> _deleteUser(User user, AppLocalizations l10n) async {
    try {
      await dbHelper.deleteUser(user.id!);
      await dbHelper.logActivity(l10n.deleteUserLog(user.fullName));
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حذف المستخدم "${user.fullName}" بنجاح'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      _loadUsers();
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء الحذف: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// الانتقال لإضافة مستخدم جديد
  Future<void> _navigateToAddUser() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddEditUserScreen(),
      ),
    );
    
    if (result == true) {
      _loadUsers();
    }
  }
}

/// نموذج لعنصر الصلاحية
class _PermissionItem {
  final String name;
  final String level;
  final IconData icon;
  final Color color;

  _PermissionItem(this.name, this.level, this.icon, this.color);
}