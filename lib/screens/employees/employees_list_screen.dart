// lib/screens/employees/employees_list_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../services/auth_service.dart';
import '../../utils/helpers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/status_badge.dart';
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
  final AuthService _authService = AuthService();
  late Future<List<Employee>> _employeesFuture;
  final _searchController = TextEditingController();
  List<Employee> _allEmployees = [];
  List<Employee> _filteredEmployees = [];

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
        _filteredEmployees = employees;
      });
    } catch (e) {
      // معالجة الخطأ
    }
  }

  /// البحث في قائمة الموظفين
  void _filterEmployees(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredEmployees = _allEmployees;
      } else {
        _filteredEmployees = _allEmployees.where((employee) {
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
                    size: 16,
                    color: isDark ? Colors.white : Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_allEmployees.length}',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
            return const LoadingState(message: 'جاري تحميل الموظفين...');
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
              message: 'ابدأ بإضافة أول موظف في فريقك',
              actionText: _authService.canManageEmployees 
                  ? 'إضافة موظف' 
                  : null,
              onAction: _authService.canManageEmployees 
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

      // ============= زر الإضافة =============
      floatingActionButton: _authService.canManageEmployees
          ? FloatingActionButton.extended(
              onPressed: _navigateToAddEmployee,
              icon: const Icon(Icons.add),
              label: const Text('إضافة موظف'),
              tooltip: 'إضافة موظف جديد',
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
          hintText: 'ابحث عن موظف...',
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
    final totalSalaries = _allEmployees.fold<double>(
      0,
      (sum, emp) => sum + emp.baseSalary,
    );
    
    final totalAdvances = _allEmployees.fold<double>(
      0,
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
              label: 'إجمالي الرواتب',
              value: formatCurrency(totalSalaries),
              color: AppColors.success,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: AppConstants.spacingMd),
          
          // إجمالي السلف
          Expanded(
            child: _buildStatCard(
              icon: Icons.account_balance_wallet,
              label: 'إجمالي السلف',
              value: formatCurrency(totalAdvances),
              color: totalAdvances > 0 ? AppColors.error : AppColors.info,
              isDark: isDark,
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
  }) {
    return Container(
      padding: AppConstants.paddingMd,
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
    );
  }

  // ============================================================
  // 📭 حالة عدم وجود نتائج بحث
  // ============================================================
  Widget _buildNoResultsState(AppLocalizations l10n) {
    return EmptyState(
      icon: Icons.search_off,
      title: 'لا توجد نتائج',
      message: 'جرب البحث بكلمة أخرى',
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
    final hasAdvances = employee.balance > 0;
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
                        fontSize: 12,
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
                          label: 'الراتب',
                          value: formatCurrency(employee.baseSalary),
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingSm),
                      
                      // السلف
                      Expanded(
                        child: _buildInfoChip(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'السلف',
                          value: formatCurrency(employee.balance),
                          color: advanceColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ============= سهم التنقل =============
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark 
                  ? AppColors.textSecondaryDark 
                  : AppColors.textSecondaryLight,
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
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 11,
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