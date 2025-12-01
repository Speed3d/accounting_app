// lib/screens/employees/add_advance_screen.dart

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

/// 💳 شاشة إضافة سلفة - صفحة فرعية
/// Hint: نموذج لتسجيل سلفة جديدة للموظف
class AddAdvanceScreen extends StatefulWidget {
  final Employee employee;

  const AddAdvanceScreen({super.key, required this.employee});

  @override
  State<AddAdvanceScreen> createState() => _AddAdvanceScreenState();
}

class _AddAdvanceScreenState extends State<AddAdvanceScreen> {
  // ============= متغيرات النموذج =============
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper.instance;
  // ← Hint: تم إزالة AuthService

  // Controllers
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _dateController = TextEditingController();

  // ============= متغيرات الحالة =============
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  // ============= دورة الحياة =============
  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  // ============================================================
  // 💾 حفظ السلفة
  // ============================================================
  Future<void> _saveAdvance() async {
    final l10n = AppLocalizations.of(context)!;

    // التحقق من صحة البيانات
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = parseDecimal(
       convertArabicNumbersToEnglish(_amountController.text),
      );
      final l10n = AppLocalizations.of(context)!;
      final newAdvance = EmployeeAdvance(
        employeeID: widget.employee.employeeID!,
        advanceDate: _selectedDate.toIso8601String(),
        advanceAmount: amount,
        repaymentStatus: l10n.unpaid,
        notes: _notesController.text.trim(),
      );

      await dbHelper.recordNewAdvance(newAdvance);

      // تسجيل النشاط
      // final action = 'تسجيل سلفة للموظف: ${widget.employee.fullName} بقيمة: ${formatCurrency(amount)}';
      final action = l10n.advanceRegisteredForEmployee(
      widget.employee.fullName,
      formatCurrency(amount),
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
                Expanded(child: Text(l10n.advanceAddedSuccess)),
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
      helpText: l10n.selectAdvanceDate,
      cancelText: l10n.cancel,
      confirmText: l10n.ok,
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
        title: Text(l10n.newAdvanceFor(widget.employee.fullName)),
        
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l10n.saveAdvance,
            onPressed: _isLoading ? null : _saveAdvance,
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

            // ============= بطاقة معلومات الموظف =============
            _buildEmployeeInfoCard(isDark),

            const SizedBox(height: AppConstants.spacingXl),

            // ============= قسم بيانات السلفة =============
            _buildSectionHeader(l10n.advanceData, Icons.request_quote, isDark),
            const SizedBox(height: AppConstants.spacingMd),

            // المبلغ
            CustomTextField(
              controller: _amountController,
              label: l10n.advanceAmount,
              hint: l10n.enterAdvanceAmount,
              prefixIcon: Icons.attach_money,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return l10n.amountRequired;
                }
                final amount = double.tryParse(
                  convertArabicNumbersToEnglish(v),
                );
                if (amount == null || amount <= 0) {
                  return l10n.enterValidAmount;
                }
                return null;
              },
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // التاريخ
            CustomTextField(
              controller: _dateController,
              label: l10n.advanceDate,
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
              hint: l10n.enterAdvanceNotes,
              prefixIcon: Icons.notes,
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),

            const SizedBox(height: AppConstants.spacingXl),

            // ============= ملخص السلفة =============
            _buildSummaryCard(l10n, isDark),

            const SizedBox(height: AppConstants.spacingXl),

            // ============= زر الحفظ =============
            CustomButton(
              text: l10n.saveAdvance,
              icon: Icons.save,
              onPressed: _saveAdvance,
              isLoading: _isLoading,
              type: ButtonType.primary,
              size: ButtonSize.large,
            ),

            const SizedBox(height: AppConstants.spacingLg),

            // ============= تنبيه =============
            _buildWarningNote(isDark),

            const SizedBox(height: AppConstants.spacingLg),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 👤 بناء بطاقة معلومات الموظف
  // ============================================================
  Widget _buildEmployeeInfoCard(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return CustomCard(
      child: Container(
        padding: AppConstants.paddingMd,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.warning.withOpacity(0.1),
              AppColors.info.withOpacity(0.1),
            ],
          ),
          borderRadius: AppConstants.borderRadiusMd,
        ),
        child: Row(
          children: [
            // أيقونة الموظف
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

            // المعلومات
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.addNewAdvanceTooltip,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.employee.fullName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
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
                      widget.employee.jobTitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // الرصيد الحالي
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  l10n.currentBalance,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatCurrency(widget.employee.balance),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.employee.balance > Decimal.zero
                        ? AppColors.error
                        : AppColors.success,
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
  // 📋 بناء رأس القسم
  // ============================================================
  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingSm),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: AppConstants.borderRadiusSm,
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppColors.warning,
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
  // 📊 بناء بطاقة الملخص
  // ============================================================
  Widget _buildSummaryCard(AppLocalizations l10n, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    // حساب الرصيد المتوقع بعد السلفة
    final currentAmount = parseDecimal(
     convertArabicNumbersToEnglish(_amountController.text.trim()),
     fallback: Decimal.zero,
     );
    final currentBalance = widget.employee.balance;
    final expectedBalance = currentAmount > Decimal.zero
    ? currentBalance + currentAmount
    : currentBalance;

    return CustomCard(
      child: Container(
        padding: AppConstants.paddingLg,
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.05),
          borderRadius: AppConstants.borderRadiusMd,
          border: Border.all(
            color: AppColors.warning.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calculate,
                  color: AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: AppConstants.spacingSm),
                Text(
                  l10n.financialSummary,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // الرصيد الحالي
            _buildSummaryRow(
              l10n.currentBalance,
              formatCurrency(currentBalance),
              AppColors.info,
              isDark,
            ),

            const SizedBox(height: AppConstants.spacingSm),

            // مبلغ السلفة
            _buildSummaryRow(
              l10n.advanceAmount,
              currentAmount > Decimal.zero ? formatCurrency(currentAmount) : '---',
              AppColors.warning,
              isDark,
            ),

            Divider(
              height: AppConstants.spacingLg,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),

            // الرصيد المتوقع
            _buildSummaryRow(
              l10n.expectedBalance,
              formatCurrency(expectedBalance),
              expectedBalance > Decimal.zero ? AppColors.error : AppColors.success,
              isDark,
              isBold: true,
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
    bool isDark, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isBold ? FontWeight.bold : null,
              ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ⚠️ بناء ملاحظة تحذيرية
  // ============================================================
  Widget _buildWarningNote(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: AppConstants.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: AppConstants.borderRadiusMd,
        border: Border.all(
          color: AppColors.info.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.info,
            size: 20,
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: Text(
              // 'سيتم خصم قيمة السلفة تلقائياً من الرواتب القادمة حتى تسديدها بالكامل',
              l10n.autoDeductAdvance,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.info,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}