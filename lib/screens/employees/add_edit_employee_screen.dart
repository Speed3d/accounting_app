// lib/screens/employees/add_edit_employee_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../services/auth_service.dart';
import '../../utils/helpers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

/// 👤 شاشة إضافة/تعديل موظف - صفحة فرعية
/// Hint: نموذج شامل لإدخال بيانات الموظف
class AddEditEmployeeScreen extends StatefulWidget {
  final Employee? employee;

  const AddEditEmployeeScreen({super.key, this.employee});

  @override
  State<AddEditEmployeeScreen> createState() => _AddEditEmployeeScreenState();
}

class _AddEditEmployeeScreenState extends State<AddEditEmployeeScreen> {
  // ============= متغيرات النموذج =============
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper.instance;
  final AuthService _authService = AuthService();

  // Controllers
  final _nameController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _salaryController = TextEditingController();
  final _hireDateController = TextEditingController();

  // ============= متغيرات الحالة =============
  File? _imageFile;
  DateTime? _selectedHireDate;
  bool _isLoading = false;

  // ============= Getters =============
  bool get _isEditMode => widget.employee != null;

  // ============= دورة الحياة =============
  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _jobTitleController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _salaryController.dispose();
    _hireDateController.dispose();
    super.dispose();
  }

  /// تهيئة النموذج
  void _initializeForm() {
    if (_isEditMode) {
      final e = widget.employee!;
      _nameController.text = e.fullName;
      _jobTitleController.text = e.jobTitle;
      _addressController.text = e.address ?? '';
      _phoneController.text = e.phone ?? '';
      _salaryController.text = e.baseSalary.toString();
      _selectedHireDate = DateTime.parse(e.hireDate);
      _hireDateController.text = DateFormat('yyyy-MM-dd').format(_selectedHireDate!);
      
      // تحميل الصورة
      if (e.imagePath != null && e.imagePath!.isNotEmpty) {
        final imageFile = File(e.imagePath!);
        if (imageFile.existsSync()) {
          _imageFile = imageFile;
        }
      }
    } else {
      _selectedHireDate = DateTime.now();
      _hireDateController.text = DateFormat('yyyy-MM-dd').format(_selectedHireDate!);
    }
  }

  // ============================================================
  // 💾 حفظ الموظف
  // ============================================================
  Future<void> _saveEmployee() async {
    final l10n = AppLocalizations.of(context)!;

    // التحقق من صحة البيانات
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final employee = Employee(
        employeeID: _isEditMode ? widget.employee!.employeeID : null,
        fullName: _nameController.text.trim(),
        jobTitle: _jobTitleController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        baseSalary: double.parse(
          convertArabicNumbersToEnglish(_salaryController.text),
        ),
        hireDate: _selectedHireDate!.toIso8601String(),
        imagePath: _imageFile?.path,
        balance: _isEditMode ? widget.employee!.balance : 0.0,
      );

      String action;
      String successMessage;

      if (_isEditMode) {
        await dbHelper.updateEmployee(employee);
        // action = 'تحديث بيانات الموظف: ${employee.fullName}';
        action = l10n.updateEmployeeAction(employee.fullName);
        successMessage = l10n.employeeUpdatedSuccess;
      } else {
        await dbHelper.insertEmployee(employee);
        // action = 'إضافة موظف جديد: ${employee.fullName}';
        action = l10n.addEmployeeAction(employee.fullName);
        successMessage = l10n.employeeAddedSuccess;
      }

      // تسجيل النشاط
      await dbHelper.logActivity(
        action,
        userId: _authService.currentUser?.id,
        userName: _authService.currentUser?.fullName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(child: Text(successMessage)),
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
  // 📅 اختيار تاريخ التعيين
  // ============================================================
  Future<void> _pickHireDate() async {
    final l10n = AppLocalizations.of(context)!;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedHireDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: l10n.selectHiringDate,
      cancelText: l10n.cancel,
      confirmText: l10n.ok,
    );

    if (pickedDate != null && pickedDate != _selectedHireDate) {
      setState(() {
        _selectedHireDate = pickedDate;
        _hireDateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  // ============================================================
  // 📷 اختيار صورة
  // ============================================================
  Future<void> _pickImage(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      // حفظ الصورة في مجلد التطبيق
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'employee_${DateTime.now().millisecondsSinceEpoch}${p.extension(pickedFile.path)}';
      final savedImage = await File(pickedFile.path).copy(
        '${appDir.path}/$fileName',
      );

      setState(() {
        _imageFile = savedImage;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorPickingImage(e.toString())),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
        title: Text(_isEditMode ? l10n.editEmployee : l10n.addEmployee),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l10n.save,
            onPressed: _isLoading ? null : _saveEmployee,
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

            // ============= صورة الموظف =============
            _buildImagePicker(l10n, isDark),

            const SizedBox(height: AppConstants.spacingXl),

            // ============= قسم المعلومات الشخصية =============
            _buildSectionHeader(l10n.personalInfo, Icons.person_outline, isDark),
            const SizedBox(height: AppConstants.spacingMd),

            // الاسم الكامل
            CustomTextField(
              controller: _nameController,
              label: l10n.employeeName,
              hint: l10n.enterFullName,
              prefixIcon: Icons.badge_outlined,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.employeeNameRequired : null,
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // رقم الهاتف
            CustomTextField(
              controller: _phoneController,
              label: l10n.phoneOptional,
              hint: l10n.enterPhoneNumber,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // العنوان
            CustomTextField(
              controller: _addressController,
              label: l10n.addressOptional,
              hint: l10n.enterAddress,
              prefixIcon: Icons.location_on_outlined,
              maxLines: 2,
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: AppConstants.spacingXl),

            // ============= قسم الوظيفة =============
            _buildSectionHeader(l10n.jobInfo, Icons.work_outline, isDark),
            const SizedBox(height: AppConstants.spacingMd),

            // المسمى الوظيفي
            CustomTextField(
              controller: _jobTitleController,
              label: l10n.jobTitle,
              hint: l10n.enterJobTitle,
              prefixIcon: Icons.work_outline,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.jobTitleRequired : null,
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // تاريخ التعيين
            CustomTextField(
              controller: _hireDateController,
              label: l10n.hireDate,
              hint: l10n.selectDate,
              prefixIcon: Icons.calendar_today,
              readOnly: true,
              onTap: _pickHireDate,
            ),

            const SizedBox(height: AppConstants.spacingXl),

            // ============= قسم الراتب =============
            _buildSectionHeader(l10n.financialInfo, Icons.attach_money, isDark),
            const SizedBox(height: AppConstants.spacingMd),

            // الراتب الأساسي
            CustomTextField(
              controller: _salaryController,
              label: l10n.baseSalary,
              hint: l10n.enterBasicSalary,
              prefixIcon: Icons.paid_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return l10n.baseSalaryRequired;
                }
                if (double.tryParse(convertArabicNumbersToEnglish(v)) == null) {
                  return l10n.enterValidNumber;
                }
                return null;
              },
            ),

            const SizedBox(height: AppConstants.spacingXl),

            // ============= زر الحفظ =============
            CustomButton(
              text: _isEditMode ? l10n.editEmployee : l10n.addEmployee,
              icon: _isEditMode ? Icons.update : Icons.add,
              onPressed: _saveEmployee,
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
  // 🖼️ بناء منتقي الصورة
  // ============================================================
  Widget _buildImagePicker(AppLocalizations l10n, bool isDark) {
    return Center(
      child: Stack(
        children: [
          // الصورة الرمزية
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppColors.primaryDark.withOpacity(0.3),
                        AppColors.secondaryDark.withOpacity(0.3),
                      ]
                    : [
                        AppColors.primaryLight.withOpacity(0.3),
                        AppColors.secondaryLight.withOpacity(0.3),
                      ],
              ),
              border: Border.all(
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                      .withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: _imageFile != null
                  ? Image.file(
                      _imageFile!,
                      fit: BoxFit.cover,
                    )
                  : Icon(
                      Icons.person,
                      size: 70,
                      color: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                    ),
            ),
          ),

          // زر الكاميرا
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                shape: BoxShape.circle,
                boxShadow: AppConstants.shadowMd,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: () => _showImageSourceDialog(l10n),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
  // 📷 مربع حوار اختيار مصدر الصورة
  // ============================================================
  void _showImageSourceDialog(AppLocalizations l10n) {
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
              // العنوان
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppConstants.spacingLg),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: AppConstants.borderRadiusFull,
                ),
              ),

              Text(
                l10n.imageSource,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: AppConstants.spacingLg),

              // خيار المعرض
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppConstants.spacingSm),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: AppConstants.borderRadiusMd,
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: AppColors.info,
                  ),
                ),
                title: Text(l10n.gallery),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),

              const SizedBox(height: AppConstants.spacingSm),

              // خيار الكاميرا
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppConstants.spacingSm),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: AppConstants.borderRadiusMd,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: AppColors.success,
                  ),
                ),
                title: Text(l10n.camera),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),

              const SizedBox(height: AppConstants.spacingMd),

              // زر الإلغاء
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.cancel),
              ),

              const SizedBox(height: AppConstants.spacingSm),
            ],
          ),
        ),
      ),
    );
  }
}