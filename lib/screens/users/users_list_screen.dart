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
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      if (query.isEmpty && _filterRole == l10n.all) {
        _filteredUsers = _allUsers;
        _isSearching = false;
      } else {
        _isSearching = true;
        _filteredUsers = _allUsers.where((user) {
          final matchesSearch = query.isEmpty ||
              user.fullName.toLowerCase().contains(query.toLowerCase()) ||
              user.userName.toLowerCase().contains(query.toLowerCase());
          
          final matchesRole = _filterRole == l10n.all ||
              (_filterRole == l10n.admin && user.isAdmin) ||
              (_filterRole == l10n.user && !user.isAdmin);
          
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
                  return LoadingState(message: l10n.loadingUsers);
                }

                // حالة الخطأ
                if (snapshot.hasError) {
                  return ErrorState(
                    message: l10n.loadError,
                    onRetry: _loadUsers,
                  );
                }

                // حالة البيانات الفارغة
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return EmptyState(
                    icon: Icons.people_outline,
                    title: l10n.noUsers,
                    message: l10n.noUsers,
                    actionText: _authService.isAdmin ? l10n.addNewUser : null,
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
                        title: l10n.noResults,
                        message: l10n.noUsersMatch,
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
              label: Text(l10n.addUser),
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
            hint: l10n.searchUser,
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
              _buildFilterChip(l10n.all, Icons.people),
              const SizedBox(width: AppConstants.spacingSm),
              _buildFilterChip(l10n.admin, Icons.admin_panel_settings),
              const SizedBox(width: AppConstants.spacingSm),
              _buildFilterChip(l10n.user, Icons.person),
            ],
          ),
          
          const SizedBox(height: AppConstants.spacingMd),
          
          // إحصائيات سريعة (قابلة للنقر)
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
                      l10n.totalUsers,
                      '${users.length}',
                      Icons.people,
                      AppColors.primaryLight,
                      l10n.all, // ← الفلتر المرتبط
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingSm),
                  Expanded(
                    child: _buildQuickStat(
                      l10n.admins,
                      '$adminsCount',
                      Icons.admin_panel_settings,
                      AppColors.error,
                      l10n.admin, // ← الفلتر المرتبط
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingSm),
                  Expanded(
                    child: _buildQuickStat(
                      l10n.users,
                      '$regularCount',
                      Icons.person,
                      AppColors.info,
                      l10n.user, // ← الفلتر المرتبط
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
                size: 18,
                color: isSelected
                    ? AppColors.primaryLight
                    : Theme.of(context).iconTheme.color,
              ),
              const SizedBox(width: AppConstants.spacingXs),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
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

  /// بناء إحصائية سريعة (قابلة للنقر)
  Widget _buildQuickStat(
    String label,
    String value,
    IconData icon,
    Color color,
    String filterRole, // ← معامل جديد للفلتر
  ) {
    final isSelected = _filterRole == filterRole;
    
    return InkWell(
      onTap: () {
        setState(() {
          _filterRole = filterRole;
          _filterUsers(_searchController.text);
        });
      },
      borderRadius: AppConstants.borderRadiusMd,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingXs,
          vertical: AppConstants.spacingMd,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.2)
              : color.withOpacity(0.1),
          borderRadius: AppConstants.borderRadiusMd,
          border: Border.all(
            color: isSelected
                ? color.withOpacity(0.5)
                : color.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: isSelected ? 28 : 26,
            ),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: isSelected ? 22 : 20,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
                          size: 14,
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
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.info.withOpacity(0.2),
                              borderRadius: AppConstants.borderRadiusFull,
                            ),
                            child: Text(
                              l10n.you,
                              style: TextStyle(
                                fontSize: 14,
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
                          size: 18,
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
                    
                    // الصلاحية - مع إصلاح Overflow
                    Row(
                      children: [
                        Flexible(
                          child: StatusBadge(
                            text: user.isAdmin ? l10n.admin : l10n.customPermissionsUser,
                            type: user.isAdmin ? StatusType.error : StatusType.info,
                            small: true,
                          ),
                        ),
                        if (!user.isAdmin) ...[
                          const SizedBox(width: AppConstants.spacingSm),
                          // ✅ إضافة Flexible لحل مشكلة Overflow
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shield,
                                  size: 16,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '$permissionsCount ${l10n.permission}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
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
                      iconSize: 24,
                      tooltip: l10n.edit,
                      onPressed: () => _handleEditUser(user, isCurrentUser, l10n),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: AppColors.error,
                      iconSize: 24,
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
    final l10n = AppLocalizations.of(context)!;
    final permissions = [
      if (user.canViewSuppliers || user.canEditSuppliers)
        _PermissionItem(l10n.suppliers, 
          user.canViewSuppliers ? (user.canEditSuppliers ? l10n.viewEdit : l10n.viewOnly) : l10n.none,
          Icons.store,
          user.canEditSuppliers ? AppColors.success : AppColors.warning,
        ),
      if (user.canViewProducts || user.canEditProducts)
        _PermissionItem(l10n.products,
          user.canViewProducts ? (user.canEditProducts ? l10n.viewEdit : l10n.viewOnly) : l10n.none,
          Icons.inventory_2,
          user.canEditProducts ? AppColors.success : AppColors.warning,
        ),
      if (user.canViewCustomers || user.canEditCustomers)
        _PermissionItem(l10n.customers,
          user.canViewCustomers ? (user.canEditCustomers ? l10n.viewEdit : l10n.viewOnly) : l10n.none,
          Icons.people,
          user.canEditCustomers ? AppColors.success : AppColors.warning,
        ),
      if (user.canViewReports)
        _PermissionItem(l10n.reports, l10n.view, Icons.assessment, AppColors.info),
      if (user.canManageEmployees)
        _PermissionItem(l10n.employees, l10n.fullAccess, Icons.badge, AppColors.success),
      if (user.canViewEmployeesReport)
        _PermissionItem(l10n.employeeReports, l10n.view, Icons.description, AppColors.info),
      if (user.canManageExpenses)
        _PermissionItem(l10n.expenses, l10n.fullAccess, Icons.receipt_long, AppColors.success),
      if (user.canViewCashSales)
        _PermissionItem(l10n.cashSales, l10n.view, Icons.point_of_sale, AppColors.info),
      if (user.canViewSettings)
        _PermissionItem(l10n.settings, l10n.view, Icons.settings, AppColors.warning),
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
              l10n.noPermissions,
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
              Icon(perm.icon, size: 18, color: perm.color),
              const SizedBox(width: AppConstants.spacingXs),
              Text(
                perm.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: perm.color,
                ),
              ),
              const SizedBox(width: AppConstants.spacingXs),
              Text(
                '(${perm.level})',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
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
                    l10n.noUndo,
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
          content: Text(l10n.deleteUserSuccess(user.fullName)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      _loadUsers();
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.deleteUserError(e.toString())),
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