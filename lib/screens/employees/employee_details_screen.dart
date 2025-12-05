// lib/screens/employees/employee_details_screen.dart

import 'dart:io';
import 'package:accountant_touch/screens/employees/add_edit_employee_screen.dart' show AddEditEmployeeScreen;
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../utils/helpers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/status_badge.dart';
import 'add_advance_screen.dart';
import 'add_payroll_screen.dart';
import 'add_bonus_screen.dart';

/// 👤 شاشة تفاصيل الموظف - صفحة فرعية
/// Hint: تعرض معلومات الموظف، الرواتب، والسلف
class EmployeeDetailsScreen extends StatefulWidget {
  final Employee employee;

  const EmployeeDetailsScreen({super.key, required this.employee});

  @override
  State<EmployeeDetailsScreen> createState() => _EmployeeDetailsScreenState();
}

class _EmployeeDetailsScreenState extends State<EmployeeDetailsScreen>
    with SingleTickerProviderStateMixin {
  // ============= المتغيرات =============
  final dbHelper = DatabaseHelper.instance;
  // ← Hint: تم إزالة AuthService
  late TabController _tabController;
  late Employee _currentEmployee;
  late Future<List<PayrollEntry>> _payrollFuture;
  late Future<List<EmployeeAdvance>> _advancesFuture;
  late Future<List<EmployeeBonus>> _bonusesFuture;

  // ============= دورة الحياة =============
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentEmployee = widget.employee;
    _reloadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// إعادة تحميل البيانات
  void _reloadData() {
    setState(() {
      _payrollFuture = dbHelper.getPayrollForEmployee(
        _currentEmployee.employeeID!,
      );
      _advancesFuture = dbHelper.getAdvancesForEmployee(
        _currentEmployee.employeeID!,
      );
      _bonusesFuture = dbHelper.getBonusesForEmployee(
        _currentEmployee.employeeID!,
      );
    });

    // تحديث بيانات الموظف
    dbHelper.getEmployeeById(_currentEmployee.employeeID!).then((employee) {
      if (employee != null && mounted) {
        setState(() => _currentEmployee = employee);
      }
    });
  }

  // ============================================================
  // 📅 الحصول على اسم الشهر المترجم
  // ============================================================
  String _getMonthName(int month, AppLocalizations l10n) {
    switch (month) {
      case 1:
        return l10n.january;
      case 2:
        return l10n.february;
      case 3:
        return l10n.march;
      case 4:
        return l10n.april;
      case 5:
        return l10n.may;
      case 6:
        return l10n.june;
      case 7:
        return l10n.july;
      case 8:
        return l10n.august;
      case 9:
        return l10n.september;
      case 10:
        return l10n.october;
      case 11:
        return l10n.november;
      case 12:
        return l10n.december;
      default:
        return '';
    }
  }

  // ============= بناء الواجهة =============
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // ← Hint: التحقق من صلاحية التعديل/الإدارة
    final canManage = true; // ← Hint: كل مستخدم يمكنه الإدارة

    return Scaffold(
      // ============= AppBar مع TabBar =============
      appBar: AppBar(
        title: Text(_currentEmployee.fullName),
        actions: [
          // ← Hint: زر التعديل يظهر فقط لمن لديه صلاحية الإدارة
          if (canManage)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.editEmployee,
              onPressed: _navigateToEditEmployee,
            ),
        ],
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
              tabs: [
                Tab(
                  icon: const Icon(Icons.payments_outlined, size: 20),
                  text: l10n.payrollHistory,
                ),
                Tab(
                  icon: const Icon(Icons.request_quote_outlined, size: 20),
                  text: l10n.advancesHistory,
                ),
                Tab(
                  icon: const Icon(Icons.card_giftcard_outlined, size: 20),
                  text: l10n.bonusesHistory ?? 'سجل المكافآت',
                ),
              ],
            ),
          ),
        ),
      ),

      // ============= Body =============
      body: Column(
        children: [
          // بطاقة معلومات الموظف
          _buildEmployeeInfoCard(l10n, isDark),

          // التبويبات
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPayrollTab(l10n, canManage),
                _buildAdvancesTab(l10n, canManage),
                _buildBonusesTab(l10n, canManage),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🃏 بناء بطاقة معلومات الموظف
  // ============================================================
  Widget _buildEmployeeInfoCard(AppLocalizations l10n, bool isDark) {
    final hasImage = _currentEmployee.imagePath != null &&
        _currentEmployee.imagePath!.isNotEmpty;
    final imageFile = hasImage ? File(_currentEmployee.imagePath!) : null;
    final hasValidImage = imageFile != null && imageFile.existsSync();

    return Container(
      margin: AppConstants.paddingMd,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.primaryDark.withOpacity(0.1),
                  AppColors.secondaryDark.withOpacity(0.1),
                ]
              : [
                  AppColors.primaryLight.withOpacity(0.1),
                  AppColors.secondaryLight.withOpacity(0.1),
                ],
        ),
        borderRadius: AppConstants.borderRadiusLg,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Padding(
        padding: AppConstants.paddingLg,
        child: Row(
          children: [
            // ============= صورة الموظف =============
            Hero(
              tag: 'employee_${_currentEmployee.employeeID}',
              child: Container(
                width: AppConstants.avatarSizeXl,
                height: AppConstants.avatarSizeXl,
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
                    width: 3,
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
                        size: 40,
                        color: isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                      )
                    : null,
              ),
            ),

            const SizedBox(width: AppConstants.spacingLg),

            // ============= معلومات الموظف =============
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الاسم
                  Text(
                    _currentEmployee.fullName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                      _currentEmployee.jobTitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.info,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingMd),

                  // الراتب والسلف
                  Row(
                    children: [
                      // الراتب الأساسي
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.paid_outlined,
                          label: l10n.salaryLabel,
                          value: formatCurrency(_currentEmployee.baseSalary),
                          color: AppColors.success,
                        ),
                      ),

                      const SizedBox(width: AppConstants.spacingSm),

                      // السلف
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.account_balance_wallet_outlined,
                          label: l10n.advancesLabel,
                          value: formatCurrency(_currentEmployee.balance),
                          color: _currentEmployee.balance > Decimal.zero
                              ? AppColors.error
                              : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء عنصر معلومات
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingSm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppConstants.borderRadiusSm,
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
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 💰 تبويب سجل الرواتب
  // ============================================================
  Widget _buildPayrollTab(AppLocalizations l10n, bool canManage) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<List<PayrollEntry>>(
        future: _payrollFuture,
        builder: (context, snapshot) {
          // حالة التحميل
          if (snapshot.connectionState == ConnectionState.waiting) {
            return LoadingState(message: l10n.loadingMessage);
          }

          // حالة الخطأ
          if (snapshot.hasError) {
            return ErrorState(
              message: snapshot.error.toString(),
              onRetry: _reloadData,
            );
          }

          // حالة الفراغ
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyState(
              icon: Icons.payments_outlined,
              title: l10n.noPayrolls,
              message: l10n.noPayrollsMessage,
              // ← Hint: زر الإضافة يظهر فقط لمن لديه صلاحية الإدارة
              actionText: canManage ? l10n.paymentAction : null,
              onAction: canManage ? _navigateToAddPayroll : null,
            );
          }

          // عرض القائمة
          final payrolls = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            itemCount: payrolls.length,
            itemBuilder: (context, index) {
              final entry = payrolls[index];
              return _buildPayrollCard(entry, l10n);
            },
          );
        },
      ),

      // ← Hint: زر الإضافة يظهر فقط لمن لديه صلاحية الإدارة
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: _navigateToAddPayroll,
              icon: const Icon(Icons.add),
              label: Text(l10n.paymentAction),
              tooltip: l10n.addNewPayrollTooltip,
            )
          : null,
    );
  }

  /// بناء بطاقة راتب
  Widget _buildPayrollCard(PayrollEntry entry, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthName = _getMonthName(entry.payrollMonth, l10n);

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      onTap: () => _showPayrollOptionsDialog(entry, l10n),
      child: Padding(
        padding: AppConstants.paddingMd,
        child: Row(
          children: [
            // أيقونة
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: AppConstants.borderRadiusMd,
              ),
              child: const Icon(
                Icons.payment,
                color: AppColors.success,
                size: 28,
              ),
            ),

            const SizedBox(width: AppConstants.spacingMd),

            // المعلومات
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الشهر والسنة
                  Text(
                    '$monthName ${entry.payrollYear}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: AppConstants.spacingXs),

                  // تاريخ الدفع
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.paidOn(DateFormat('yyyy-MM-dd').format(DateTime.parse(entry.paymentDate))),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // المبلغ
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCurrency(entry.netSalary),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.netLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// مربع حوار خيارات الراتب (عرض التفاصيل/تعديل/حذف)
  void _showPayrollOptionsDialog(PayrollEntry entry, AppLocalizations l10n) {
    final monthName = _getMonthName(entry.payrollMonth, l10n);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusLg),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: AppConstants.paddingMd,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // عنوان
              Text(
                'راتب $monthName ${entry.payrollYear}',
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: AppConstants.spacingLg),

              // معلومات سريعة
              Container(
                padding: AppConstants.paddingMd,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: AppConstants.borderRadiusMd,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatCurrency(entry.netSalary),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      DateFormat('yyyy-MM-dd').format(
                        DateTime.parse(entry.paymentDate),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spacingLg),

              // خيار عرض التفاصيل
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppConstants.spacingSm),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: AppConstants.borderRadiusMd,
                  ),
                  child: const Icon(
                    Icons.visibility,
                    color: AppColors.info,
                  ),
                ),
                title: Text(l10n.viewDetails ?? 'عرض التفاصيل'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  _showPayrollDetailsDialog(entry, l10n);
                },
              ),

              const SizedBox(height: AppConstants.spacingSm),

              // خيار التعديل
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppConstants.spacingSm),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: AppConstants.borderRadiusMd,
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: AppColors.warning,
                  ),
                ),
                title: Text(l10n.edit),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (context) => AddPayrollScreen(
                        employee: _currentEmployee,
                        payroll: entry,
                      ),
                    ),
                  );
                  if (result == true) {
                    _reloadData();
                  }
                },
              ),

              const SizedBox(height: AppConstants.spacingSm),

              // خيار الحذف
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppConstants.spacingSm),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: AppConstants.borderRadiusMd,
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: AppColors.error,
                  ),
                ),
                title: Text(
                  l10n.delete,
                  style: const TextStyle(color: AppColors.error),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeletePayroll(entry, l10n, monthName);
                },
              ),

              const SizedBox(height: AppConstants.spacingMd),

              // زر الإلغاء
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),

              const SizedBox(height: AppConstants.spacingSm),
            ],
          ),
        ),
      ),
    );
  }

  /// تأكيد حذف الراتب
  void _confirmDeletePayroll(PayrollEntry entry, AppLocalizations l10n, String monthName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete ?? 'تأكيد الحذف'),
        content: Text(
          'هل أنت متأكد من حذف راتب $monthName ${entry.payrollYear}؟\n\nالصافي: ${formatCurrency(entry.netSalary)}\nالتاريخ: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(entry.paymentDate))}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () async {
              try {
                await dbHelper.deletePayroll(entry.payrollID!);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.payrollDeletedSuccess ?? 'تم حذف الراتب بنجاح'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  _reloadData();
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${l10n.error}: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 💳 تبويب سجل السلف
  // ============================================================
  Widget _buildAdvancesTab(AppLocalizations l10n, bool canManage) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<List<EmployeeAdvance>>(
        future: _advancesFuture,
        builder: (context, snapshot) {
          // حالة التحميل
          if (snapshot.connectionState == ConnectionState.waiting) {
            return LoadingState(message: l10n.loadingMessage);
          }

          // حالة الخطأ
          if (snapshot.hasError) {
            return ErrorState(
              message: snapshot.error.toString(),
              onRetry: _reloadData,
            );
          }

          // حالة الفراغ
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyState(
              icon: Icons.request_quote_outlined,
              title: l10n.noAdvances,
              message: l10n.noAdvancesMessage,
              // ← Hint: زر الإضافة يظهر فقط لمن لديه صلاحية الإدارة
              actionText: canManage ? l10n.addAdvanceAction : null,
              onAction: canManage ? _navigateToAddAdvance : null,
            );
          }

          // عرض القائمة
          final advances = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            itemCount: advances.length,
            itemBuilder: (context, index) {
              final advance = advances[index];
              return _buildAdvanceCard(advance, l10n);
            },
          );
        },
      ),

      // ← Hint: زر الإضافة يظهر فقط لمن لديه صلاحية الإدارة
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: _navigateToAddAdvance,
              icon: const Icon(Icons.add),
              label: Text(l10n.addAdvanceButton),
              tooltip: l10n.addNewAdvanceTooltip,
            )
          : null,
    );
  }

  /// بناء بطاقة سلفة
  Widget _buildAdvanceCard(EmployeeAdvance advance, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPaid = advance.repaymentStatus == 'مسددة بالكامل';
    final statusColor = isPaid ? AppColors.success : AppColors.warning;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      onTap: () => _showAdvanceOptionsDialog(advance, l10n),
      child: Padding(
        padding: AppConstants.paddingMd,
        child: Row(
          children: [
            // أيقونة
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: AppConstants.borderRadiusMd,
              ),
              child: Icon(
                Icons.request_quote,
                color: statusColor,
                size: 28,
              ),
            ),

            const SizedBox(width: AppConstants.spacingMd),

            // المعلومات
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // المبلغ
                  Text(
                    formatCurrency(advance.advanceAmount),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: AppConstants.spacingXs),

                  // التاريخ
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('yyyy-MM-dd').format(
                          DateTime.parse(advance.advanceDate),
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // الحالة
            StatusBadge(
              text: isPaid ? l10n.fullyPaid : l10n.unpaid,
              type: isPaid ? StatusType.success : StatusType.warning,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 📋 مربع حوار تفاصيل الراتب
  // ============================================================
  void _showPayrollDetailsDialog(PayrollEntry entry, AppLocalizations l10n) {
    final monthName = _getMonthName(entry.payrollMonth, l10n);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.payment,
              color: AppColors.success,
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Expanded(
              child: Text(
                l10n.payrollDetailsTitle(monthName, entry.payrollYear.toString()),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                l10n.baseSalary,
                formatCurrency(entry.baseSalary),
                AppColors.info,
              ),
              // تم الغاء غرض المكافئات من هنا ايضا 
              // _buildDetailRow(
              //   l10n.bonuses,
              //   formatCurrency(entry.bonuses),
              //   AppColors.success,
              // ),
              _buildDetailRow(
                l10n.deductions,
                formatCurrency(entry.deductions),
                AppColors.error,
              ),
              _buildDetailRow(
                l10n.advanceRepayment,
                formatCurrency(entry.advanceDeduction),
                AppColors.warning,
              ),

              const Divider(height: AppConstants.spacingLg),

              // الصافي
              Container(
                padding: AppConstants.paddingMd,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: AppConstants.borderRadiusMd,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.netSalaryDue,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      formatCurrency(entry.netSalary),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),

              // الملاحظات
              if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                const SizedBox(height: AppConstants.spacingMd),
                Container(
                  padding: AppConstants.paddingMd,
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                    borderRadius: AppConstants.borderRadiusMd,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.notesOptional,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(entry.notes!),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  /// بناء صف تفصيلي
  Widget _buildDetailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Text(label),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🧭 التنقل
  // ============================================================

  /// الانتقال لصفحة تعديل الموظف
  Future<void> _navigateToEditEmployee() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddEditEmployeeScreen(
          employee: _currentEmployee,
        ),
      ),
    );

    if (result == true) {
      _reloadData();
    }
  }

  /// الانتقال لصفحة إضافة راتب
  Future<void> _navigateToAddPayroll() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddPayrollScreen(employee: _currentEmployee),
      ),
    );

    if (result == true) {
      _reloadData();
    }
  }

  /// الانتقال لصفحة إضافة سلفة
  Future<void> _navigateToAddAdvance() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddAdvanceScreen(employee: _currentEmployee),
      ),
    );

    if (result == true) {
      _reloadData();
    }
  }

  /// الانتقال لصفحة إضافة مكافأة
  Future<void> _navigateToAddBonus() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddBonusScreen(employee: _currentEmployee),
      ),
    );

    if (result == true) {
      _reloadData();
    }
  }

  // ============================================================
  // 🎁 تبويب سجل المكافآت
  // ============================================================
  Widget _buildBonusesTab(AppLocalizations l10n, bool canManage) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<List<EmployeeBonus>>(
        future: _bonusesFuture,
        builder: (context, snapshot) {
          // حالة التحميل
          if (snapshot.connectionState == ConnectionState.waiting) {
            return LoadingState(message: l10n.loadingMessage);
          }

          // حالة الخطأ
          if (snapshot.hasError) {
            return ErrorState(
              message: snapshot.error.toString(),
              onRetry: _reloadData,
            );
          }

          // حالة الفراغ
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyState(
              icon: Icons.card_giftcard_outlined,
              title: l10n.noBonuses ?? 'لا توجد مكافآت',
              message: l10n.noBonusesMessage ?? 'لم يتم تسجيل أي مكافآت لهذا الموظف بعد',
              actionText: canManage ? (l10n.addBonus ?? 'إضافة مكافأة') : null,
              onAction: canManage ? _navigateToAddBonus : null,
            );
          }

          // عرض القائمة
          final bonuses = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            itemCount: bonuses.length,
            itemBuilder: (context, index) {
              final bonus = bonuses[index];
              return _buildBonusCard(bonus, l10n, canManage);
            },
          );
        },
      ),

      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: _navigateToAddBonus,
              icon: const Icon(Icons.add),
              label: Text(l10n.addBonus ?? 'إضافة مكافأة'),
              tooltip: l10n.addBonusTooltip ?? 'إضافة مكافأة جديدة',
            )
          : null,
    );
  }

  /// بناء بطاقة مكافأة
  Widget _buildBonusCard(EmployeeBonus bonus, AppLocalizations l10n, bool canManage) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      onTap: canManage ? () => _showBonusOptionsDialog(bonus, l10n) : null,
      child: Padding(
        padding: AppConstants.paddingMd,
        child: Row(
          children: [
            // أيقونة
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: AppConstants.borderRadiusMd,
              ),
              child: const Icon(
                Icons.card_giftcard,
                color: AppColors.success,
                size: 28,
              ),
            ),

            const SizedBox(width: AppConstants.spacingMd),

            // المعلومات
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // المبلغ
                  Text(
                    formatCurrency(bonus.bonusAmount),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                  ),

                  const SizedBox(height: AppConstants.spacingXs),

                  // السبب
                  if (bonus.bonusReason != null && bonus.bonusReason!.isNotEmpty)
                    Text(
                      bonus.bonusReason!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: AppConstants.spacingXs),

                  // التاريخ
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('yyyy-MM-dd').format(
                          DateTime.parse(bonus.bonusDate),
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // سهم
            if (canManage)
              Icon(
                Icons.chevron_right,
                color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
              ),
          ],
        ),
      ),
    );
  }

  /// مربع حوار خيارات السلفة (تسديد/تعديل/حذف)
  void _showAdvanceOptionsDialog(EmployeeAdvance advance, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPaid = advance.repaymentStatus == 'مسددة بالكامل';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusLg),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: AppConstants.paddingMd,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // عنوان
              Text(
                l10n.advanceOptions ?? 'خيارات السلفة',
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: AppConstants.spacingLg),

              // معلومات سريعة
              Container(
                padding: AppConstants.paddingMd,
                decoration: BoxDecoration(
                  color: (isPaid ? AppColors.success : AppColors.warning).withOpacity(0.1),
                  borderRadius: AppConstants.borderRadiusMd,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatCurrency(advance.advanceAmount),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isPaid ? AppColors.success : AppColors.warning,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          advance.repaymentStatus,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isPaid ? AppColors.success : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      DateFormat('yyyy-MM-dd').format(
                        DateTime.parse(advance.advanceDate),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spacingLg),

              // خيار التسديد (يظهر فقط للسلف غير المسددة)
              if (!isPaid) ...[
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppConstants.spacingSm),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: AppConstants.borderRadiusMd,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                    ),
                  ),
                  title: Text(l10n.repayAdvance ?? 'تسديد السلفة'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmRepayAdvance(advance, l10n);
                  },
                ),
                const SizedBox(height: AppConstants.spacingSm),
              ],

              // خيار التعديل
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppConstants.spacingSm),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: AppConstants.borderRadiusMd,
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: AppColors.info,
                  ),
                ),
                title: Text(l10n.edit),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (context) => AddAdvanceScreen(
                        employee: _currentEmployee,
                        advance: advance,
                      ),
                    ),
                  );
                  if (result == true) {
                    _reloadData();
                  }
                },
              ),

              const SizedBox(height: AppConstants.spacingSm),

              // خيار الحذف
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppConstants.spacingSm),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: AppConstants.borderRadiusMd,
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: AppColors.error,
                  ),
                ),
                title: Text(
                  l10n.delete,
                  style: const TextStyle(color: AppColors.error),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteAdvance(advance, l10n);
                },
              ),

              const SizedBox(height: AppConstants.spacingMd),

              // زر الإلغاء
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),

              const SizedBox(height: AppConstants.spacingSm),
            ],
          ),
        ),
      ),
    );
  }

  /// تأكيد تسديد السلفة
  void _confirmRepayAdvance(EmployeeAdvance advance, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmRepayment ?? 'تأكيد التسديد'),
        content: Text(
          'هل أنت متأكد من تسديد هذه السلفة؟\n\nالمبلغ: ${formatCurrency(advance.advanceAmount)}\nالتاريخ: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(advance.advanceDate))}\n\nسيتم تغيير الحالة إلى "مسددة بالكامل".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            onPressed: () async {
              try {
                await dbHelper.repayAdvance(advance.advanceID!, l10n.fullyPaid);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.advanceRepaidSuccess ?? 'تم تسديد السلفة بنجاح'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  _reloadData();
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${l10n.error}: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(l10n.confirm ?? 'تأكيد'),
          ),
        ],
      ),
    );
  }

  /// تأكيد حذف السلفة
  void _confirmDeleteAdvance(EmployeeAdvance advance, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete ?? 'تأكيد الحذف'),
        content: Text(
          'هل أنت متأكد من حذف هذه السلفة؟\n\nالمبلغ: ${formatCurrency(advance.advanceAmount)}\nالتاريخ: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(advance.advanceDate))}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () async {
              try {
                await dbHelper.deleteAdvance(advance.advanceID!);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.advanceDeletedSuccess ?? 'تم حذف السلفة بنجاح'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  _reloadData();
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${l10n.error}: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  /// مربع حوار خيارات المكافأة (تعديل/حذف)
  void _showBonusOptionsDialog(EmployeeBonus bonus, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusLg),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: AppConstants.paddingMd,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // عنوان
              Text(
                l10n.bonusOptions ?? 'خيارات المكافأة',
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: AppConstants.spacingLg),

              // معلومات سريعة
              Container(
                padding: AppConstants.paddingMd,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: AppConstants.borderRadiusMd,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatCurrency(bonus.bonusAmount),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      DateFormat('yyyy-MM-dd').format(
                        DateTime.parse(bonus.bonusDate),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spacingLg),

              // خيار التعديل
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppConstants.spacingSm),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: AppConstants.borderRadiusMd,
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: AppColors.info,
                  ),
                ),
                title: Text(l10n.edit),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (context) => AddBonusScreen(
                        employee: _currentEmployee,
                        bonus: bonus,
                      ),
                    ),
                  );
                  if (result == true) {
                    _reloadData();
                  }
                },
              ),

              const SizedBox(height: AppConstants.spacingSm),

              // خيار الحذف
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppConstants.spacingSm),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: AppConstants.borderRadiusMd,
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: AppColors.error,
                  ),
                ),
                title: Text(
                  l10n.delete,
                  style: const TextStyle(color: AppColors.error),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteBonus(bonus, l10n);
                },
              ),

              const SizedBox(height: AppConstants.spacingMd),

              // زر الإلغاء
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),

              const SizedBox(height: AppConstants.spacingSm),
            ],
          ),
        ),
      ),
    );
  }

  /// تأكيد حذف المكافأة
  void _confirmDeleteBonus(EmployeeBonus bonus, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete ?? 'تأكيد الحذف'),
        content: Text(
          l10n.deleteBonusConfirmation ??
              'هل أنت متأكد من حذف هذه المكافأة؟\n\nالمبلغ: ${formatCurrency(bonus.bonusAmount)}\nالتاريخ: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(bonus.bonusDate))}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () async {
              try {
                await dbHelper.deleteBonus(bonus.bonusID!);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.bonusDeletedSuccess ?? 'تم حذف المكافأة بنجاح'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  _reloadData();
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${l10n.error}: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}