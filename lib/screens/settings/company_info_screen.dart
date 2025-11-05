// lib/screens/settings/company_info_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ Hint: للـ TextInputFormatter
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/database_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_state.dart';

/// 🏢 شاشة معلومات الشركة - نسخة محسّنة
/// Hint: تحتوي على جميع البيانات المطلوبة للـ PDF الاحترافي
class CompanyInfoScreen extends StatefulWidget {
  const CompanyInfoScreen({super.key});

  @override
  State<CompanyInfoScreen> createState() => _CompanyInfoScreenState();
}

class _CompanyInfoScreenState extends State<CompanyInfoScreen> {
  // ============= المتغيرات =============
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper.instance;
  
  // ✅ Hint: الحقول الأساسية (موجودة بالفعل)
  final _companyNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // ✅ Hint: الحقول الجديدة
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  
  File? _logoFile;
  bool _isLoading = true;
  bool _isSaving = false;

  // ============= مفاتيح الإعدادات =============
  // Hint: نستخدم نفس النمط الموجود
  static const String _companyNameKey = 'companyName';
  static const String _companyDescriptionKey = 'companyDescription';
  static const String _companyLogoKey = 'companyLogoPath';
  
  // ✅ Hint: المفاتيح الجديدة
  static const String _companyPhoneKey = 'companyPhone';
  static const String _companyAddressKey = 'companyAddress';
  static const String _companyEmailKey = 'companyEmail';
  static const String _companyRegistrationKey = 'companyRegistrationNumber';

  // ============= دورة الحياة =============
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _registrationNumberController.dispose();
    super.dispose();
  }

  // ============= الدوال =============
  
  /// ✅ تحميل الإعدادات المحفوظة (محدّثة)
  Future<void> _loadSettings() async {
    try {
      final settings = await dbHelper.getAppSettings();
      
      if (mounted) {
        setState(() {
          // الحقول الموجودة
          _companyNameController.text = settings[_companyNameKey] ?? '';
          _descriptionController.text = settings[_companyDescriptionKey] ?? '';
          
          // ✅ Hint: الحقول الجديدة
          _phoneController.text = settings[_companyPhoneKey] ?? '';
          _addressController.text = settings[_companyAddressKey] ?? '';
          _emailController.text = settings[_companyEmailKey] ?? '';
          _registrationNumberController.text = settings[_companyRegistrationKey] ?? '';
          
          // تحميل الشعار
          final logoPath = settings[_companyLogoKey];
          if (logoPath != null && logoPath.isNotEmpty) {
            final file = File(logoPath);
            if (file.existsSync()) {
              _logoFile = file;
            }
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل البيانات: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// اختيار صورة (نفس الدالة الموجودة)
  Future<void> _pickImage(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024, // ✅ Hint: تحديد أقصى عرض لتوفير المساحة
        maxHeight: 1024,
      );
      
      if (pickedFile == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'company_logo_${DateTime.now().millisecondsSinceEpoch}.png';
      final savedImage = await File(pickedFile.path).copy(
        '${appDir.path}/$fileName',
      );

      setState(() {
        _logoFile = savedImage;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorPickingImage(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// ✅ حفظ الإعدادات (محدّثة)
  Future<void> _saveSettings() async {
    final l10n = AppLocalizations.of(context)!;
    
    // التحقق من صحة البيانات
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      // ✅ Hint: حفظ جميع الحقول
      await dbHelper.saveSetting(_companyNameKey, _companyNameController.text.trim());
      await dbHelper.saveSetting(_companyDescriptionKey, _descriptionController.text.trim());
      await dbHelper.saveSetting(_companyPhoneKey, _phoneController.text.trim());
      await dbHelper.saveSetting(_companyAddressKey, _addressController.text.trim());
      await dbHelper.saveSetting(_companyEmailKey, _emailController.text.trim());
      await dbHelper.saveSetting(_companyRegistrationKey, _registrationNumberController.text.trim());
      
      // حفظ مسار الشعار
      if (_logoFile != null) {
        await dbHelper.saveSetting(_companyLogoKey, _logoFile!.path);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: AppConstants.spacingSm),
                Text(l10n.infoSavedSuccess),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// عرض حوار اختيار مصدر الصورة
  void _showImageSourceDialog() {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.chooseImageSource),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.gallery),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l10n.camera),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============= البناء =============
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.companyInformation),
        actions: [
          // ✅ Hint: زر الحفظ في الـ AppBar
          IconButton(
            onPressed: _isSaving ? null : _saveSettings,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            tooltip: l10n.save,
          ),
        ],
      ),

      body: _isLoading
          ? LoadingState(message: l10n.loadingData)
          : SingleChildScrollView(
              padding: AppConstants.screenPadding,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppConstants.spacingLg),
                    
                    // ============= الشعار =============
                    _buildLogoPicker(isDark),
                    
                    const SizedBox(height: AppConstants.spacingXl),
                    
                    // ============= القسم الأول: المعلومات الأساسية =============
                    _buildSectionHeader(
                      context,
                      title: l10n.basicInformation,
                      icon: Icons.business,
                      isDark: isDark,
                    ),
                    
                    const SizedBox(height: AppConstants.spacingMd),
                    
                    // اسم الشركة
                    CustomTextField(
                      controller: _companyNameController,
                      label: l10n.companyOrShopName,
                      hint: 'مثال: شركة النور للتجارة',
                      prefixIcon: Icons.business,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.fieldRequired;
                        }
                        if (value.trim().length < 3) {
                          return 'الاسم يجب أن يكون 3 أحرف على الأقل';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: AppConstants.spacingMd),
                    
                    // وصف الشركة
                    CustomTextField(
                      controller: _descriptionController,
                      label: l10n.companyDescOptional,
                      hint: l10n.companyDescHint,
                      prefixIcon: Icons.description_outlined,
                      maxLines: 3,
                      textInputAction: TextInputAction.next,
                    ),
                    
                    const SizedBox(height: AppConstants.spacingXl),
                    
                    // ============= القسم الثاني: معلومات الاتصال =============
                    _buildSectionHeader(
                      context,
                      // title: l10n.contactInformation,
                      title: l10n.basicInformation, 
                      icon: Icons.contact_phone,
                      isDark: isDark,
                    ),
                    
                    const SizedBox(height: AppConstants.spacingMd),
                    
                    // رقم الهاتف
                    CustomTextField(
                      controller: _phoneController,
                      label: l10n.phone,
                      hint: '07XX XXX XXXX',
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly, // ✅ Hint: أرقام فقط
                        LengthLimitingTextInputFormatter(15), // ✅ Hint: حد أقصى 15 رقم
                      ],
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (value.length < 10) {
                            return 'رقم الهاتف غير صحيح';
                          }
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: AppConstants.spacingMd),
                    
                    // البريد الإلكتروني
                    CustomTextField(
                      controller: _emailController,
                      label: l10n.email,
                      hint: 'example@company.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          // ✅ Hint: التحقق من صحة البريد الإلكتروني
                          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(value)) {
                            return 'البريد الإلكتروني غير صحيح';
                          }
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: AppConstants.spacingMd),
                    
                    // العنوان
                    CustomTextField(
                      controller: _addressController,
                      label: l10n.address, 
                      hint: 'مثال: بغداد - الكرادة - شارع الرئيسي',
                      prefixIcon: Icons.location_on_outlined,
                      maxLines: 2,
                      textInputAction: TextInputAction.next,
                    ),
                    
                    const SizedBox(height: AppConstants.spacingXl),
                    
                    // ============= القسم الثالث: المعلومات القانونية =============
                    _buildSectionHeader(
                      context,
                      title: l10n.legalInformation,
                      icon: Icons.gavel,
                      isDark: isDark,
                    ),
                    
                    const SizedBox(height: AppConstants.spacingMd),
                    
                    // رقم السجل التجاري
                    CustomTextField(
                      controller: _registrationNumberController,
                      label: l10n.commercialRegistrationNumber,
                      hint: 'مثال: 123456789',
                      prefixIcon: Icons.badge_outlined,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                    ),
                    
                    const SizedBox(height: AppConstants.spacingXl),
                    
                    // ============= زر الحفظ =============
                    CustomButton(
                      text: l10n.saveChanges,
                      icon: Icons.save,
                      onPressed: _saveSettings,
                      isLoading: _isSaving,
                    ),
                    
                    const SizedBox(height: AppConstants.spacingLg),
                    
                    // ============= ملاحظة توضيحية =============
                    _buildInfoNote(context, l10n, isDark),
                    
                    const SizedBox(height: AppConstants.spacingXl),
                  ],
                ),
              ),
            ),
    );
  }

  // ============= ويدجت رأس القسم =============
  /// ✅ Hint: تصميم احترافي لرأس كل قسم
  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                .withOpacity(0.1),
            borderRadius: AppConstants.borderRadiusMd,
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
          ),
        ),
        const SizedBox(width: AppConstants.spacingMd),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  // ============= ويدجت اختيار الشعار (محسّن) =============
  Widget _buildLogoPicker(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final backgroundColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Column(
      children: [
        // ✅ Hint: عنوان توضيحي
        Text(
          l10n.companyLogo,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppConstants.spacingSm),
        Text(
          'يُنصح باستخدام صورة مربعة (512 × 512 بكسل)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
        ),
        const SizedBox(height: AppConstants.spacingMd),
        
        // الشعار
        Center(
          child: Stack(
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _logoFile != null && _logoFile!.existsSync()
                      ? Image.file(_logoFile!, fit: BoxFit.cover)
                      : Icon(
                          Icons.business,
                          size: 60,
                          color: isDark
                              ? AppColors.textHintDark
                              : AppColors.textHintLight,
                        ),
                ),
              ),
              
              // زر التعديل
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: AppConstants.shadowMd,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(50),
                      onTap: _isSaving ? null : _showImageSourceDialog,
                      child: const Padding(
                        padding: EdgeInsets.all(AppConstants.spacingMd),
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // ✅ Hint: زر حذف الشعار (جديد)
              if (_logoFile != null)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      boxShadow: AppConstants.shadowMd,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(50),
                        onTap: _isSaving
                            ? null
                            : () {
                                setState(() {
                                  _logoFile = null;
                                });
                              },
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ============= ملاحظة توضيحية =============
  Widget _buildInfoNote(BuildContext context, AppLocalizations l10n, bool isDark) {
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
          const SizedBox(width: AppConstants.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ملاحظة هامة',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppConstants.spacingXs),
                Text(
                  l10n.companyInfoHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.info,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}