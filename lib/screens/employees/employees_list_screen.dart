// lib/screens/employees/employees_list_screen.dart

import 'dart:io';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../utils/helpers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_state.dart';
import 'add_edit_employee_screen.dart';
import 'employee_details_screen.dart';

/// 👥 شاشة قائمة الموظفين - صفحة فرعية
/// Hint: تعرض جميع الموظفين النشطين مع معلوماتهم الأساسية
class EmployeesListScreen extends StatefulWidget {
  const EmployeesListScreen({super.key});

  @override
  State<EmployeesListScreen> createState() => _EmployeesListScreenState();
}

class _EmployeesListScreenState extends State<EmployeesListScreen> {
  // ============= المتغيرات =============
  final dbHelper = DatabaseHelper.instance;
  // ← Hint: تم إزالة AuthService
  late Future<List<Employee>> _employeesFuture;
  final _searchController = TextEditingController();
  List<Employee> _allEmployees = [];
  List<Employee> _filteredEmployees = [];
  String? _selectedFilter; // null = الكل (totalSalaries)، 'advances' = موظفين عليهم سلف

  // ============= دورة الحياة =============
  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// تحميل قائمة الموظفين
  Future<void> _loadEmployees() async {
    setState(() {
      _employeesFuture = dbHelper.getAllActiveEmployees();
    });

    try {
      final employees = await _employeesFuture;
      setState(() {
        _allEmployees = employees;
        _applyFilter();
      });
    } catch (e) {
      // معالجة الخطأ
    }
  }

  /// تطبيق الفلتر المحدد
  void _applyFilter() {
    if (_selectedFilter == null) {
      // عرض الكل
      _filteredEmployees = _allEmployees;
    } else if (_selectedFilter == 'advances') {
      // عرض الموظفين الذين عليهم سلف فقط
      _filteredEmployees = _allEmployees.where((employee) {
        return employee.balance > Decimal.zero;
      }).toList();
    }
    
    // إعادة تطبيق البحث إذا كان موجوداً
    if (_searchController.text.isNotEmpty) {
      _filterEmployees(_searchController.text);
    }
  }

  /// تغيير الفلتر
  void _changeFilter(String? filter) {
    setState(() {
      _selectedFilter = filter;
      _applyFilter();
    });
  }

  /// البحث في قائمة الموظفين
  void _filterEmployees(String query) {
    setState(() {
      if (query.isEmpty) {
        _applyFilter();
      } else {
        List<Employee> baseList = _selectedFilter == null 
            ? _allEmployees 
            : _allEmployees.where((e) => e.balance > Decimal.zero).toList();
            
        _filteredEmployees = baseList.where((employee) {
          final nameLower = employee.fullName.toLowerCase();
          final jobTitleLower = employee.jobTitle.toLowerCase();
          final queryLower = query.toLowerCase();
          
          return nameLower.contains(queryLower) || 
                 jobTitleLower.contains(queryLower);
        }).toList();
      }
    });
  }

  // ============= بناء الواجهة =============
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // ============= AppBar =============
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.badge_outlined,
              color: isDark ? AppColors.textPrimaryDark : Colors.white,
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Text(l10n.employeesList),
          ],
        ),
        actions: [
          // عدد الموظفين
          if (_allEmployees.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingMd,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingMd,
                vertical: AppConstants.spacingSm,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.2),
                borderRadius: AppConstants.borderRadiusFull,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people,
                    size: 18,
                    color: isDark ? Colors.white : Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_allEmployees.length}',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),

      // ============= Body =============
      body: FutureBuilder<List<Employee>>(
        future: _employeesFuture,
        builder: (context, snapshot) {
          // حالة التحميل
          if (snapshot.connectionState == ConnectionState.waiting) {
            return  LoadingState(message: l10n.loadingEmployees);
          }

          // حالة الخطأ
          if (snapshot.hasError) {
            return ErrorState(
              message: snapshot.error.toString(),
              onRetry: _loadEmployees,
            );
          }

          // حالة الفراغ
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyState(
              icon: Icons.badge_outlined,
              title: l10n.noEmployees,
              message: l10n.startByAddingEmployee,
              // ← Hint: زر الإضافة يظهر فقط لمن لديه صلاحية الإدارة
              actionText: true 
                  ? l10n.addEmployee 
                  : null,
              onAction: true 
                  ? _navigateToAddEmployee 
                  : null,
            );
          }

          // عرض القائمة
          return Column(
            children: [
              // ============= شريط البحث =============
              _buildSearchBar(l10n),

              // ============= الإحصائيات السريعة =============
              _buildQuickStats(l10n, isDark),

              // ============= قائمة الموظفين =============
              Expanded(
                child: _filteredEmployees.isEmpty
                    ? _buildNoResultsState(l10n)
                    : _buildEmployeesList(),
              ),
            ],
          );
        },
      ),

      // ← Hint: زر الإضافة يظهر فقط لمن لديه صلاحية الإدارة
      floatingActionButton: true
          ? FloatingActionButton.extended(
              onPressed: _navigateToAddEmployee,
              icon: const Icon(Icons.add),
              label:  Text(l10n.addEmployee),
              tooltip: l10n.addNewEmployee,
            )
          : null,
    );
  }

  // ============================================================
  // 🔍 بناء شريط البحث
  // ============================================================
  Widget _buildSearchBar(AppLocalizations l10n) {
    return Container(
      padding: AppConstants.paddingMd,
      child: TextField(
        controller: _searchController,
        onChanged: _filterEmployees,
        decoration: InputDecoration(
          hintText: l10n.searchNewEmployee2,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterEmployees('');
                  },
                )
              : null,
        ),
      ),
    );
  }

  // ============================================================
  // 📊 بناء الإحصائيات السريعة
  // ============================================================
  Widget _buildQuickStats(AppLocalizations l10n, bool isDark) {
    if (_allEmployees.isEmpty) return const SizedBox.shrink();

    // حساب الإحصائيات
    final totalSalaries = _allEmployees.fold<Decimal>(
       Decimal.zero,
       (sum, emp) => sum + emp.baseSalary,
    );
    
    final totalAdvances = _allEmployees.fold<Decimal>(
       Decimal.zero,
       (sum, emp) => sum + emp.balance, 
    );

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
      ),
      child: Row(
        children: [
          // إجمالي الرواتب
          Expanded(
            child: _buildStatCard(
              icon: Icons.attach_money,
              label: l10n.totalSalaries,
              value: formatCurrency(totalSalaries),
              color: AppColors.success,
              isDark: isDark,
              filterType: null, // عرض الكل
            ),
          ),
          const SizedBox(width: AppConstants.spacingMd),
          
          // إجمالي السلف
          Expanded(
            child: _buildStatCard(
              icon: Icons.account_balance_wallet,
              label: l10n.totalAdvances,
              value: formatCurrency(totalAdvances),
              color: totalAdvances > Decimal.zero ? AppColors.error : AppColors.info,
              isDark: isDark,
              filterType: 'advances', // فلتر السلف
            ),
          ),
        ],
      ),
    );
  }

  /// بناء بطاقة إحصائية
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    String? filterType,
  }) {
    final isSelected = _selectedFilter == filterType;
    
    return InkWell(
      onTap: () => _changeFilter(filterType),
      borderRadius: AppConstants.borderRadiusMd,
      child: Container(
        padding: AppConstants.paddingMd,
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : color.withOpacity(0.1),
          borderRadius: AppConstants.borderRadiusMd,
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 📭 حالة عدم وجود نتائج بحث
  // ============================================================
  Widget _buildNoResultsState(AppLocalizations l10n) {
    return EmptyState(
      icon: Icons.search_off,
      title: l10n.noResults,
      message: l10n.tryAnotherSearch,
    );
  }

  // ============================================================
  // 📜 بناء قائمة الموظفين
  // ============================================================
  Widget _buildEmployeesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      itemCount: _filteredEmployees.length,
      itemBuilder: (context, index) {
        final employee = _filteredEmployees[index];
        return _buildEmployeeCard(employee);
      },
    );
  }

  // ============================================================
  // 🃏 بناء بطاقة موظف
  // ============================================================
  Widget _buildEmployeeCard(Employee employee) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    
    // تحميل الصورة
    final imageFile = employee.imagePath != null && 
                      employee.imagePath!.isNotEmpty
        ? File(employee.imagePath!)
        : null;
    final hasValidImage = imageFile != null && imageFile.existsSync();

    // حساب حالة السلف
    final hasAdvances = employee.balance > Decimal.zero;
    final advanceColor = hasAdvances ? AppColors.error : AppColors.success;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      onTap: () => _navigateToEmployeeDetails(employee),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Row(
          children: [
            // ============= صورة الموظف =============
            Hero(
              tag: 'employee_${employee.employeeID}',
              child: Container(
                width: AppConstants.avatarSizeLg,
                height: AppConstants.avatarSizeLg,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                          .withOpacity(0.3),
                      (isDark ? AppColors.secondaryDark : AppColors.secondaryLight)
                          .withOpacity(0.3),
                    ],
                  ),
                  border: Border.all(
                    color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
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
                        Icons.person,
                        size: 32,
                        color: isDark 
                            ? AppColors.primaryDark 
                            : AppColors.primaryLight,
                      )
                    : null,
              ),
            ),

            const SizedBox(width: AppConstants.spacingMd),

            // ============= معلومات الموظف =============
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الاسم
                  Text(
                    employee.fullName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: AppConstants.spacingXs),

                  // المسمى الوظيفي
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingSm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: AppConstants.borderRadiusFull,
                    ),
                    child: Text(
                      employee.jobTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.info,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingSm),

                  // الراتب والسلف
                  Row(
                    children: [
                      // الراتب الأساسي
                      Expanded(
                        child: _buildInfoChip(
                          icon: Icons.paid_outlined,
                          label: l10n.salary,
                          value: formatCurrency(employee.baseSalary),
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingSm),
                      
                      // السلف
                      Expanded(
                        child: _buildInfoChip(
                          icon: Icons.account_balance_wallet_outlined,
                          label: l10n.advance,
                          value: formatCurrency(employee.balance),
                          color: advanceColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ============= قائمة الخيارات =============
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              onSelected: (value) {
                if (value == 'archive') {
                  _confirmArchiveEmployee(employee, l10n);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'archive',
                  child: Row(
                    children: [
                      const Icon(Icons.archive_outlined, color: AppColors.warning),
                      const SizedBox(width: AppConstants.spacingSm),
                      Text(l10n.archive ?? 'أرشفة'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 📋 بناء شريحة معلومات
  // ============================================================
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical: AppConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppConstants.borderRadiusSm,
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 📦 أرشفة الموظف
  // ============================================================

  /// تأكيد أرشفة الموظف بعد التحقق من الالتزامات المالية
  Future<void> _confirmArchiveEmployee(Employee employee, AppLocalizations l10n) async {
    try {
      // التحقق من وجود التزامات مالية
      final hasObligations = await dbHelper.employeeHasFinancialObligations(employee.employeeID!);

      if (!mounted) return;

      if (hasObligations) {
        // عرض تحذير بوجود التزامات مالية
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                const SizedBox(width: AppConstants.spacingSm),
                Text(l10n.warning ?? 'تحذير'),
              ],
            ),
            content: Text(
              'الموظف ${employee.fullName} لديه التزامات مالية (رواتب، سلف، أو مكافآت). لا يمكن أرشفته حالياً.',
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.ok ?? 'حسناً'),
              ),
            ],
          ),
        );
        return;
      }

      // عرض حوار تأكيد الأرشفة
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.archive_outlined, color: AppColors.warning),
              const SizedBox(width: AppConstants.spacingSm),
              Text(l10n.confirmArchive ?? 'تأكيد الأرشفة'),
            ],
          ),
          content: Text(
            'هل أنت متأكد من أرشفة الموظف ${employee.fullName}؟\nيمكنك استعادته لاحقاً من إعدادات الأرشفة.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel ?? 'إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
              ),
              child: Text(l10n.archive ?? 'أرشفة'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        // تنفيذ الأرشفة
        await dbHelper.archiveEmployee(employee.employeeID!);

        // عرض رسالة نجاح
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم أرشفة ${employee.fullName} بنجاح'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // إعادة تحميل القائمة
        _loadEmployees();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ============================================================
  // 🧭 التنقل
  // ============================================================

  /// الانتقال لصفحة إضافة موظف جديد
  Future<void> _navigateToAddEmployee() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const AddEditEmployeeScreen(),
      ),
    );

    if (result == true) {
      _loadEmployees();
    }
  }

  /// الانتقال لصفحة تفاصيل الموظف
  Future<void> _navigateToEmployeeDetails(Employee employee) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EmployeeDetailsScreen(employee: employee),
      ),
    );

    // إعادة التحميل بعد العودة
    _loadEmployees();
  }
}