// lib/screens/employees/add_bonus_screen.dart

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

/// 🎁 شاشة إضافة/تعديل مكافأة - صفحة فرعية
/// Hint: تتيح منح مكافأة أو حافز للموظف
class AddBonusScreen extends StatefulWidget {
  final Employee employee;
  final EmployeeBonus? bonus; // إذا كان موجوداً، فإننا في وضع التعديل

  const AddBonusScreen({
    super.key,
    required this.employee,
    this.bonus,
  });

  @override
  State<AddBonusScreen> createState() => _AddBonusScreenState();
}

class _AddBonusScreenState extends State<AddBonusScreen> {
  // ============= متغيرات النموذج =============
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper.instance;

  // Controllers
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  final _dateController = TextEditingController();

  // ============= متغيرات الحالة =============
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  // ============= Getters =============
  bool get _isEditMode => widget.bonus != null;

  // ============= دورة الحياة =============
  @override
  void initState() {
    super.initState();

    if (_isEditMode) {
      // وضع التعديل - تعبئة البيانات
      final bonus = widget.bonus!;
      _amountController.text = bonus.bonusAmount.toString();
      _reasonController.text = bonus.bonusReason ?? '';
      _notesController.text = bonus.notes ?? '';
      _selectedDate = DateTime.parse(bonus.bonusDate);
    }

    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  // ============================================================
  // 📅 اختيار التاريخ
  // ============================================================
  Future<void> _selectDate(AppLocalizations l10n) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: l10n.selectDate,
      cancelText: l10n.cancel,
      confirmText: l10n.ok,
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // ============================================================
  // 💾 حفظ المكافأة
  // ============================================================
  Future<void> _saveBonus() async {
    final l10n = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = parseDecimal(
        convertArabicNumbersToEnglish(_amountController.text),
      );

      if (_isEditMode) {
        // تعديل مكافأة موجودة
        final updatedBonus = EmployeeBonus(
          bonusID: widget.bonus!.bonusID,
          employeeID: widget.employee.employeeID!,
          bonusDate: _selectedDate.toIso8601String(),
          bonusAmount: amount,
          bonusReason: _reasonController.text.trim().isNotEmpty
              ? _reasonController.text.trim()
              : null,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        );

        await dbHelper.updateBonus(updatedBonus);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.bonusUpdatedSuccess ?? 'تم تحديث المكافأة بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        // إضافة مكافأة جديدة
        final newBonus = EmployeeBonus(
          employeeID: widget.employee.employeeID!,
          bonusDate: _selectedDate.toIso8601String(),
          bonusAmount: amount,
          bonusReason: _reasonController.text.trim().isNotEmpty
              ? _reasonController.text.trim()
              : null,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        );

        await dbHelper.recordNewBonus(newBonus);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.bonusAddedSuccess ?? 'تم إضافة المكافأة بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }

      // الرجوع للصفحة السابقة
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ============= بناء الواجهة =============
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode
              ? (l10n.editBonus ?? 'تعديل مكافأة')
              : (l10n.addBonus ?? 'إضافة مكافأة'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l10n.save,
            onPressed: _isLoading ? null : _saveBonus,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppConstants.screenPadding,
          children: [
            // ============= بطاقة معلومات الموظف =============
            _buildEmployeeInfoCard(l10n, isDark),

            const SizedBox(height: AppConstants.spacingXl),

            // ============= بطاقة بيانات المكافأة =============
            _buildBonusDataCard(l10n, isDark),

            const SizedBox(height: AppConstants.spacingXl),

            // ============= زر الحفظ =============
            CustomButton(
              text: _isEditMode
                  ? (l10n.editBonus ?? 'تعديل مكافأة')
                  : (l10n.addBonus ?? 'إضافة مكافأة'),
              icon: _isEditMode ? Icons.update : Icons.add,
              onPressed: _saveBonus,
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
  // 🃏 بناء بطاقة معلومات الموظف
  // ============================================================
  Widget _buildEmployeeInfoCard(AppLocalizations l10n, bool isDark) {
    return CustomCard(
      child: Row(
        children: [
          // أيقونة
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: AppConstants.borderRadiusMd,
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.info,
              size: 32,
            ),
          ),

          const SizedBox(width: AppConstants.spacingMd),

          // معلومات الموظف
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
                const SizedBox(height: AppConstants.spacingXs),
                Text(
                  widget.employee.jobTitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🎁 بناء بطاقة بيانات المكافأة
  // ============================================================
  Widget _buildBonusDataCard(AppLocalizations l10n, bool isDark) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingSm),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: AppConstants.borderRadiusSm,
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Text(
                l10n.bonusDetails ?? 'تفاصيل المكافأة',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // حقل المبلغ
          CustomTextField(
            controller: _amountController,
            label: l10n.bonusAmount ?? 'قيمة المكافأة',
            hint: l10n.enterAmount ?? 'أدخل المبلغ',
            prefixIcon: Icons.attach_money,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.fieldRequired;
              }
              try {
                final decimal = parseDecimal(
                  convertArabicNumbersToEnglish(value),
                );
                if (decimal <= Decimal.zero) {
                  return l10n.amountMustBePositive ?? 'المبلغ يجب أن يكون أكبر من صفر';
                }
              } catch (e) {
                return l10n.enterValidNumber;
              }
              return null;
            },
          ),

          const SizedBox(height: AppConstants.spacingMd),

          // حقل السبب
          CustomTextField(
            controller: _reasonController,
            label: l10n.bonusReason ?? 'سبب المكافأة',
            hint: l10n.bonusReasonHint ?? 'مثال: تميز في الأداء، إنجاز مشروع',
            prefixIcon: Icons.star_outline,
            textInputAction: TextInputAction.next,
          ),

          const SizedBox(height: AppConstants.spacingMd),

          // حقل التاريخ
          CustomTextField(
            controller: _dateController,
            label: l10n.bonusDate ?? 'تاريخ المكافأة',
            hint: 'YYYY-MM-DD',
            prefixIcon: Icons.calendar_today,
            readOnly: true,
            onTap: () => _selectDate(l10n),
          ),

          const SizedBox(height: AppConstants.spacingMd),

          // حقل الملاحظات
          CustomTextField(
            controller: _notesController,
            label: l10n.notesOptional,
            hint: l10n.enterNotes ?? 'أدخل أي ملاحظات إضافية',
            prefixIcon: Icons.note_outlined,
            maxLines: 3,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }
}
