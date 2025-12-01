// lib/screens/employees/add_payroll_screen.dart

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../utils/helpers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_card.dart';

/// 💰 شاشة صرف راتب - صفحة فرعية
/// Hint: نموذج شامل لحساب وصرف راتب شهري للموظف
class AddPayrollScreen extends StatefulWidget {
  final Employee employee;

  const AddPayrollScreen({super.key, required this.employee});

  @override
  State<AddPayrollScreen> createState() => _AddPayrollScreenState();
}

class _AddPayrollScreenState extends State<AddPayrollScreen> {
  // ============= متغيرات النموذج =============
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper.instance;
  // ← Hint: تم إزالة AuthService

  // Controllers
  final _baseSalaryController = TextEditingController();
  final _bonusesController = TextEditingController(text: '0');
  final _deductionsController = TextEditingController(text: '0');
  final _advanceRepaymentController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  final _dateController = TextEditingController();

  // ============= متغيرات الحالة =============
  late int _selectedYear;
  late int _selectedMonth;
  DateTime _selectedDate = DateTime.now();
  Decimal _netSalary = Decimal.zero;
  bool _isLoading = false;

  // ============= دورة الحياة =============
  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
    _selectedMonth = DateTime.now().month;
    _baseSalaryController.text = widget.employee.baseSalary.toString();
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // الاستماع للتغييرات لحساب الصافي
    _baseSalaryController.addListener(_calculateNetSalary);
    _bonusesController.addListener(_calculateNetSalary);
    _deductionsController.addListener(_calculateNetSalary);
    _advanceRepaymentController.addListener(_calculateNetSalary);

    _calculateNetSalary();
  }

  @override
  void dispose() {
    _baseSalaryController.dispose();
    _bonusesController.dispose();
    _deductionsController.dispose();
    _advanceRepaymentController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  // ============================================================
  // 🧮 حساب صافي الراتب
  // ============================================================
  void _calculateNetSalary() {
      final baseSalary = parseDecimal(
      convertArabicNumbersToEnglish(_baseSalaryController.text),
      fallback: Decimal.zero,
     );
      final bonuses = parseDecimal(
      convertArabicNumbersToEnglish(_bonusesController.text),
      fallback: Decimal.zero,
     );
     final deductions = parseDecimal(
     convertArabicNumbersToEnglish(_deductionsController.text),
     fallback: Decimal.zero,
    );
     final advanceRepayment = parseDecimal(
     convertArabicNumbersToEnglish(_advanceRepaymentController.text),
     fallback: Decimal.zero,
    );

    setState(() {
    _netSalary = (baseSalary + bonuses) - (deductions + advanceRepayment);
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

  // ============================================================
  // 📅 الحصول على قائمة أسماء الأشهر المترجمة
  // ============================================================
  List<String> _getMonthNames(AppLocalizations l10n) {
    return [
      l10n.january,
      l10n.february,
      l10n.march,
      l10n.april,
      l10n.may,
      l10n.june,
      l10n.july,
      l10n.august,
      l10n.september,
      l10n.october,
      l10n.november,
      l10n.december,
    ];
  }

  // ============================================================
  // 💾 حفظ الراتب
  // ============================================================
  Future<void> _savePayroll() async {
    final l10n = AppLocalizations.of(context)!;

    // التحقق من صحة البيانات
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // التحقق من عدم التكرار
      final isDuplicate = await dbHelper.isPayrollDuplicate(
        widget.employee.employeeID!,
        _selectedMonth,
        _selectedYear,
      );

      if (isDuplicate) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.payrollAlreadyExists),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final baseSalary = parseDecimal(
      convertArabicNumbersToEnglish(_baseSalaryController.text),
      );
      final bonuses = parseDecimal(
      convertArabicNumbersToEnglish(_bonusesController.text),
     );
      final deductions = parseDecimal(
      convertArabicNumbersToEnglish(_deductionsController.text),
     );
      final advanceRepayment = parseDecimal(
      convertArabicNumbersToEnglish(_advanceRepaymentController.text),
     );

      final newPayroll = PayrollEntry(
        employeeID: widget.employee.employeeID!,
        paymentDate: _selectedDate.toIso8601String(),
        payrollMonth: _selectedMonth,
        payrollYear: _selectedYear,
        baseSalary: baseSalary,
        bonuses: bonuses,
        deductions: deductions,
        advanceDeduction: advanceRepayment,
        netSalary: _netSalary,
        notes: _notesController.text.trim(),
      );

      await dbHelper.recordNewPayroll(newPayroll, advanceRepayment);

      // تسجيل النشاط
      final monthName = _getMonthName(_selectedMonth, l10n);
      final action = l10n.payrollRegisteredForEmployee(
        monthName,
        widget.employee.fullName,
      );
      await dbHelper.logActivity(
        action,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(child: Text(l10n.payrollSavedSuccess)),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ============================================================
  // 📅 اختيار التاريخ
  // ============================================================
  Future<void> _pickDate() async {
    final l10n = AppLocalizations.of(context)!;
    
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: l10n.selectPaymentDate,
      cancelText: l10n.cancel,
      confirmText: l10n.confirm,
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  // ============================================================
  // 🎨 بناء الواجهة
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // ============= AppBar =============
      appBar: AppBar(
        title: Text(l10n.payrollFor(widget.employee.fullName)),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l10n.saveAndPaySalary,
            onPressed: _isLoading ? null : _savePayroll,
          ),
        ],
      ),

      // ============= Body =============
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppConstants.screenPadding,
          children: [
            const SizedBox(height: AppConstants.spacingLg),

            // ============= بطاقة صافي الراتب =============
            _buildNetSalaryCard(l10n, isDark),

            const SizedBox(height: AppConstants.spacingXl),

            // ============= بطاقة معلومات الموظف =============
            _buildEmployeeInfoCard(isDark),

            const SizedBox(height: AppConstants.spacingXl),

            // ============= اختيار الشهر والسنة =============
            _buildSectionHeader(l10n.financialPeriod, Icons.calendar_month, isDark),

            const SizedBox(height: AppConstants.spacingMd),

            Row(
              children: [
                // الشهر
                Expanded(child: _buildMonthDropdown(l10n, isDark)),
                const SizedBox(width: AppConstants.spacingMd),
                // السنة
                Expanded(child: _buildYearDropdown(l10n, isDark)),
              ],
            ),

            const SizedBox(height: AppConstants.spacingXl),

            // ============= الراتب الأساسي =============
            _buildSectionHeader(l10n.salaryComponents, Icons.attach_money, isDark),

            const SizedBox(height: AppConstants.spacingMd),

            CustomTextField(
              controller: _baseSalaryController,
              label: l10n.baseSalary,
              hint: l10n.baseSalaryHint,
              prefixIcon: Icons.account_balance_wallet_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              validator: _numberValidator,
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // المكافآت
            CustomTextField(
              controller: _bonusesController,
              label: l10n.bonuses,
              hint: l10n.bonusesAndIncentivesHint,
              prefixIcon: Icons.card_giftcard_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              validator: _numberValidator,
            ),

            const SizedBox(height: AppConstants.spacingXl),

            // ============= الخصومات =============
            _buildSectionHeader(l10n.deductionsSection, Icons.remove_circle_outline, isDark),

            const SizedBox(height: AppConstants.spacingMd),

            CustomTextField(
              controller: _deductionsController,
              label: l10n.deductions,
              hint: l10n.deductionsAndPenaltiesHint,
              prefixIcon: Icons.remove_circle_outline,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              validator: _numberValidator,
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // خصم السلف
            CustomTextField(
              controller: _advanceRepaymentController,
              label: l10n.advanceRepayment,
              hint: l10n.advanceDeductionFromSalaryHint,
              prefixIcon: Icons.request_quote_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              validator: (v) {
            if (v == null || v.isEmpty) return l10n.enterZeroIfNotRepaying;
                try {
                final amount = parseDecimal(convertArabicNumbersToEnglish(v));
                if (amount < Decimal.zero) return l10n.enterValidNumber;
                if (amount > widget.employee.balance) {
               return l10n.repaymentExceedsBalance;
               }
             } catch (e) {
            return l10n.enterValidNumber;
              }
              return null;
                
              },
            ),

            // ملاحظة رصيد السلف
            if (widget.employee.balance > Decimal.zero) ...[
              const SizedBox(height: AppConstants.spacingSm),
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingSm),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: AppConstants.borderRadiusSm,
                  border: Border.all(
                    color: AppColors.warning.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                    Expanded(
                      child: Text(
                        l10n.currentBalanceOnEmployee(
                          formatCurrency(widget.employee.balance),
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppConstants.spacingXl),

            // ============= معلومات إضافية =============
            _buildSectionHeader(l10n.additionalInformation, Icons.info_outline, isDark),

            const SizedBox(height: AppConstants.spacingMd),

            // تاريخ الدفع
            CustomTextField(
              controller: _dateController,
              label: l10n.paymentDate,
              hint: l10n.selectDate,
              prefixIcon: Icons.calendar_today,
              readOnly: true,
              onTap: _pickDate,
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // الملاحظات
            CustomTextField(
              controller: _notesController,
              label: l10n.notesOptional,
              hint: l10n.anyAdditionalNotesHint,
              prefixIcon: Icons.notes,
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),

            const SizedBox(height: AppConstants.spacingXl),

            // ============= ملخص تفصيلي =============
            _buildDetailedSummary(l10n, isDark),

            const SizedBox(height: AppConstants.spacingXl),

            // ============= زر الحفظ =============
            CustomButton(
              text: l10n.saveAndPaySalary,
              icon: Icons.payment,
              onPressed: _savePayroll,
              isLoading: _isLoading,
              type: ButtonType.primary,
              size: ButtonSize.large,
            ),

            const SizedBox(height: AppConstants.spacingLg),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 💰 بناء بطاقة صافي الراتب
  // ============================================================
  Widget _buildNetSalaryCard(AppLocalizations l10n, bool isDark) {
  final netColor = _netSalary >= Decimal.zero ? AppColors.success : AppColors.error;
    return Container(
      padding: AppConstants.paddingXl,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            netColor.withOpacity(0.2),
            netColor.withOpacity(0.05),
          ],
        ),
        borderRadius: AppConstants.borderRadiusXl,
        border: Border.all(
          color: netColor.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: netColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: netColor,
                size: 28,
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Text(
                l10n.netSalaryDue,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: netColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Text(
            formatCurrency(_netSalary),
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: netColor,
              letterSpacing: -2,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 👤 بناء بطاقة معلومات الموظف
  // ============================================================
  Widget _buildEmployeeInfoCard(bool isDark) {
    return CustomCard(
      child: Container(
        padding: AppConstants.paddingMd,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.info.withOpacity(0.1),
              AppColors.success.withOpacity(0.1),
            ],
          ),
          borderRadius: AppConstants.borderRadiusMd,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: AppColors.info,
                size: 32,
              ),
            ),
            const SizedBox(width: AppConstants.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.employee.fullName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.employee.jobTitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.info,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 📋 بناء رأس القسم
  // ============================================================
  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingSm),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                .withOpacity(0.1),
            borderRadius: AppConstants.borderRadiusSm,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
          ),
        ),
        const SizedBox(width: AppConstants.spacingSm),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  // ============================================================
  // 📅 بناء قائمة الشهر
  // ============================================================
  Widget _buildMonthDropdown(AppLocalizations l10n, bool isDark) {
    final monthNames = _getMonthNames(l10n);
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: AppConstants.borderRadiusMd,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingMd),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedMonth,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          items: List.generate(
            12,
            (index) => DropdownMenuItem(
              value: index + 1,
              child: Text(monthNames[index]),
            ),
          ),
          onChanged: (v) {
            if (v != null) {
              setState(() => _selectedMonth = v);
            }
          },
        ),
      ),
    );
  }

  // ============================================================
  // 📅 بناء قائمة السنة
  // ============================================================
  Widget _buildYearDropdown(AppLocalizations l10n, bool isDark) {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (i) => currentYear - 2 + i);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: AppConstants.borderRadiusMd,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingMd),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedYear,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          items: years
              .map(
                (y) => DropdownMenuItem(
                  value: y,
                  child: Text(y.toString()),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() => _selectedYear = v);
            }
          },
        ),
      ),
    );
  }

  // ============================================================
  // 📊 بناء الملخص التفصيلي
  // ============================================================
  Widget _buildDetailedSummary(AppLocalizations l10n, bool isDark) {
      final baseSalary = parseDecimal(
      convertArabicNumbersToEnglish(_baseSalaryController.text),
       fallback: Decimal.zero,
     );
       final bonuses = parseDecimal(
       convertArabicNumbersToEnglish(_bonusesController.text),
       fallback: Decimal.zero,
     );
       final deductions = parseDecimal(
       convertArabicNumbersToEnglish(_deductionsController.text),
      fallback: Decimal.zero,
     );
       final advanceRepayment = parseDecimal(
       convertArabicNumbersToEnglish(_advanceRepaymentController.text),
       fallback: Decimal.zero,
     );

    return CustomCard(
      child: Container(
        padding: AppConstants.paddingLg,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceDark.withOpacity(0.5)
              : AppColors.surfaceLight,
          borderRadius: AppConstants.borderRadiusMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.summarize,
                  color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                ),
                const SizedBox(width: AppConstants.spacingSm),
                Text(
                  l10n.detailedSummary,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.spacingLg),

            // الراتب الأساسي
            _buildSummaryRow(
              l10n.baseSalary,
              formatCurrency(baseSalary),
              AppColors.info,
              Icons.add_circle_outline,
            ),

            const SizedBox(height: AppConstants.spacingSm),

            // المكافآت
            _buildSummaryRow(
              l10n.bonuses,
              formatCurrency(bonuses),
              AppColors.success,
              Icons.add_circle_outline,
            ),

            const Divider(height: AppConstants.spacingLg),

            // الخصومات
            _buildSummaryRow(
              l10n.deductions,
              formatCurrency(deductions),
              AppColors.error,
              Icons.remove_circle_outline,
            ),

            const SizedBox(height: AppConstants.spacingSm),

            // خصم السلف
            _buildSummaryRow(
              l10n.advanceRepayment,
              formatCurrency(advanceRepayment),
              AppColors.warning,
              Icons.remove_circle_outline,
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
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: AppConstants.spacingSm),
                      Text(
                        l10n.netSalaryDue,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    formatCurrency(_netSalary),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء صف ملخص
  Widget _buildSummaryRow(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: AppConstants.spacingMd),
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
    );
  }

  // ============================================================
  // ✅ Validator للأرقام
  // ============================================================
  String? _numberValidator(String? v) {
    final l10n = AppLocalizations.of(context)!;
    if (v == null || v.isEmpty) return l10n.fieldRequiredEnterZero;
    if (double.tryParse(convertArabicNumbersToEnglish(v)) == null) {
      return l10n.enterValidNumber;
    }
    return null;
  }
}