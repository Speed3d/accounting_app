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
  late Future<List<EmployeeBonus>> _bonusesFuture; // ← Hint: تاب المكافآت الجديد

  // ============= دورة الحياة =============
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // ← Hint: تغيير من 2 إلى 3 تابات
    _currentEmployee = widget.employee;
    _reloadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// إعادة تحميل البيانات
  /// ← Hint: يتم استدعاؤها عند التهيئة وبعد كل عملية إضافة/تعديل/حذف
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
      ); // ← Hint: تحميل المكافآت
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
                // ← Hint: تاب المكافآت الجديد
                const Tab(
                  icon: Icon(Icons.card_giftcard_outlined, size: 20),
                  text: 'المكافآت',
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
                _buildBonusesTab(l10n, canManage), // ← Hint: تاب المكافآت الجديد
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
      onTap: () => _showPayrollDetailsDialog(entry, l10n),
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
              _buildDetailRow(
                l10n.bonuses,
                formatCurrency(entry.bonuses),
                AppColors.success,
              ),
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
  // 🎁 تبويب سجل المكافآت
  // ← Hint: تاب جديد لعرض وإدارة مكافآت الموظف
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
              title: 'لا توجد مكافآت',
              message: 'لم يتم منح أي مكافآت لهذا الموظف بعد',
              actionText: canManage ? 'منح مكافأة' : null,
              onAction: canManage ? _showAddBonusDialog : null,
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

      // ← Hint: زر الإضافة يظهر فقط لمن لديه صلاحية الإدارة
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: _showAddBonusDialog,
              icon: const Icon(Icons.add),
              label: const Text('منح مكافأة'),
              tooltip: 'إضافة مكافأة جديدة',
            )
          : null,
    );
  }

  /// ← Hint: بناء بطاقة مكافأة مع أزرار تعديل وحذف
  Widget _buildBonusCard(EmployeeBonus bonus, AppLocalizations l10n, bool canManage) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: Padding(
        padding: AppConstants.paddingMd,
        child: Column(
          children: [
            Row(
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
                            DateFormat('yyyy-MM-dd').format(DateTime.parse(bonus.bonusDate)),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),

                      // السبب إن وُجد
                      if (bonus.bonusReason != null && bonus.bonusReason!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                bonus.bonusReason!,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // ← Hint: أزرار التعديل والحذف
            if (canManage) ...[
              const Divider(height: AppConstants.spacingLg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showEditBonusDialog(bonus),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('تعديل'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.info,
                      minimumSize: const Size(80, 32),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingSm),
                  OutlinedButton.icon(
                    onPressed: () => _showDeleteBonusDialog(bonus),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('حذف'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      minimumSize: const Size(80, 32),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🎁 دوال إدارة المكافآت (Add/Edit/Delete)
  // ============================================================

  /// ← Hint: عرض dialog لإضافة مكافأة جديدة
  Future<void> _showAddBonusDialog() async {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.card_giftcard, color: AppColors.success),
                  SizedBox(width: AppConstants.spacingSm),
                  Text('منح مكافأة'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // المبلغ
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'المبلغ *',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: AppConstants.spacingMd),

                    // التاريخ
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null) {
                          setState(() => selectedDate = pickedDate);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'التاريخ',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                      ),
                    ),

                    const SizedBox(height: AppConstants.spacingMd),

                    // السبب
                    TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        labelText: 'السبب (اختياري)',
                        prefixIcon: Icon(Icons.info_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: AppConstants.spacingMd),

                    // الملاحظات
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات (اختياري)',
                        prefixIcon: Icon(Icons.note),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (amountController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يرجى إدخال المبلغ')),
                      );
                      return;
                    }

                    final amount = parseDecimal(
                      convertArabicNumbersToEnglish(amountController.text),
                    );

                    if (amount <= Decimal.zero) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يجب أن يكون المبلغ أكبر من صفر')),
                      );
                      return;
                    }

                    final bonus = EmployeeBonus(
                      employeeID: _currentEmployee.employeeID!,
                      bonusDate: selectedDate.toIso8601String(),
                      bonusAmount: amount,
                      bonusReason: reasonController.text.isNotEmpty
                          ? reasonController.text
                          : null,
                      notes: notesController.text.isNotEmpty
                          ? notesController.text
                          : null,
                    );

                    try {
                      await dbHelper.recordNewBonus(bonus);
                      Navigator.pop(ctx, true);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('خطأ: $e')),
                      );
                    }
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      _reloadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم منح المكافأة بنجاح')),
      );
    }
  }

  /// ← Hint: عرض dialog لتعديل مكافأة
  Future<void> _showEditBonusDialog(EmployeeBonus bonus) async {
    final amountController = TextEditingController(
      text: bonus.bonusAmount.toString(),
    );
    final reasonController = TextEditingController(
      text: bonus.bonusReason ?? '',
    );
    final notesController = TextEditingController(
      text: bonus.notes ?? '',
    );
    DateTime selectedDate = DateTime.parse(bonus.bonusDate);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.edit, color: AppColors.info),
                  SizedBox(width: AppConstants.spacingSm),
                  Text('تعديل المكافأة'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'المبلغ *',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null) {
                          setState(() => selectedDate = pickedDate);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'التاريخ',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        labelText: 'السبب (اختياري)',
                        prefixIcon: Icon(Icons.info_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات (اختياري)',
                        prefixIcon: Icon(Icons.note),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (amountController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يرجى إدخال المبلغ')),
                      );
                      return;
                    }

                    final amount = parseDecimal(
                      convertArabicNumbersToEnglish(amountController.text),
                    );

                    if (amount <= Decimal.zero) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يجب أن يكون المبلغ أكبر من صفر')),
                      );
                      return;
                    }

                    try {
                      await dbHelper.editBonus(
                        bonusID: bonus.bonusID!,
                        newDate: selectedDate.toIso8601String(),
                        newAmount: amount,
                        newReason: reasonController.text.isNotEmpty
                            ? reasonController.text
                            : null,
                        newNotes: notesController.text.isNotEmpty
                            ? notesController.text
                            : null,
                      );
                      Navigator.pop(ctx, true);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('خطأ: $e')),
                      );
                    }
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      _reloadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تعديل المكافأة بنجاح')),
      );
    }
  }

  /// ← Hint: عرض dialog لحذف مكافأة
  Future<void> _showDeleteBonusDialog(EmployeeBonus bonus) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.error),
            SizedBox(width: AppConstants.spacingSm),
            Text('تأكيد الحذف'),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف هذه المكافأة؟\nالمبلغ: ${formatCurrency(bonus.bonusAmount)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await dbHelper.deleteBonus(bonus.bonusID!);
                Navigator.pop(ctx, true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('خطأ: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      _reloadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف المكافأة بنجاح')),
      );
    }
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
}