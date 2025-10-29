// lib/screens/settings/company_info_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../data/database_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_state.dart';

/// 🏢 شاشة معلومات الشركة
/// Hint: صفحة فرعية - نستخدم Scaffold عادي
class CompanyInfoScreen extends StatefulWidget {
  const CompanyInfoScreen({super.key});

  @override
  State<CompanyInfoScreen> createState() => _CompanyInfoScreenState();
}

class _CompanyInfoScreenState extends State<CompanyInfoScreen> {
  // ============= المتغيرات =============
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper.instance;
  
  final _companyNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  File? _logoFile;
  bool _isLoading = true;
  bool _isSaving = false;

  // مفاتيح الإعدادات في قاعدة البيانات
  static const String _companyNameKey = 'companyName';
  static const String _companyDescriptionKey = 'companyDescription';
  static const String _companyLogoKey = 'companyLogoPath';

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
    super.dispose();
  }

  // ============= الدوال =============
  
  /// تحميل الإعدادات المحفوظة من قاعدة البيانات
  Future<void> _loadSettings() async {
    final settings = await dbHelper.getAppSettings();
    if (mounted) {
      setState(() {
        _companyNameController.text = settings[_companyNameKey] ?? '';
        _descriptionController.text = settings[_companyDescriptionKey] ?? '';
        
        // تحميل الشعار إذا كان موجوداً
        final logoPath = settings[_companyLogoKey];
        if (logoPath != null && logoPath.isNotEmpty) {
          _logoFile = File(logoPath);
        }
        
        _isLoading = false;
      });
    }
  }

  /// اختيار صورة من الكاميرا أو المعرض
  /// Hint: نستخدم image_picker لاختيار الصورة ثم نحفظها في مجلد التطبيق
  Future<void> _pickImage(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    
    try {
      // اختيار الصورة
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80, // ضغط الصورة لتوفير المساحة
      );
      
      if (pickedFile == null) return;

      // حفظ الصورة في مجلد التطبيق
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = p.basename(pickedFile.path);
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

  /// حفظ الإعدادات في قاعدة البيانات
  Future<void> _saveSettings() async {
    final l10n = AppLocalizations.of(context)!;
    
    // التحقق من صحة البيانات
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      // حفظ اسم الشركة
      await dbHelper.saveSetting(
        _companyNameKey,
        _companyNameController.text,
      );
      
      // حفظ الوصف
      await dbHelper.saveSetting(
        _companyDescriptionKey,
        _descriptionController.text,
      );
      
      // حفظ مسار الشعار
      if (_logoFile != null) {
        await dbHelper.saveSetting(
          _companyLogoKey,
          _logoFile!.path,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.infoSavedSuccess),
            backgroundColor: AppColors.success,
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
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// عرض مربع حوار اختيار مصدر الصورة
  /// Hint: نستخدم AlertDialog عادي بالثيم الموحد
  void _showImageSourceDialog() {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.chooseImageSource),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // خيار المعرض
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.gallery),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            
            // خيار الكاميرا
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
      // ============= App Bar =============
      appBar: AppBar(
        title: Text(l10n.companyInformation),
      ),

      // ============= Body =============
      body: _isLoading
          // --- حالة التحميل ---
          ?  LoadingState(message: l10n.loadingData)
          
          // --- المحتوى الرئيسي ---
          : SingleChildScrollView(
              padding: AppConstants.screenPadding,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppConstants.spacingLg),
                    
                    // ============= اختيار الشعار =============
                    _buildLogoPicker(isDark),
                    
                    const SizedBox(height: AppConstants.spacingXl),
                    
                    // ============= اسم الشركة =============
                    CustomTextField(
                      controller: _companyNameController,
                      label: l10n.companyOrShopName,
                      prefixIcon: Icons.business,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.fieldRequired;
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: AppConstants.spacingLg),
                    
                    // ============= وصف الشركة =============
                    CustomTextField(
                      controller: _descriptionController,
                      label: l10n.companyDescOptional,
                      hint: l10n.companyDescHint,
                      prefixIcon: Icons.description_outlined,
                      maxLines: 3,
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
                    
                    // ============= نص توضيحي =============
                    Text(
                      l10n.companyInfoHint,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark 
                            ? AppColors.textSecondaryDark 
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    
                    const SizedBox(height: AppConstants.spacingXl),
                  ],
                ),
              ),
            ),
    );
  }

  // ============= ويدجت اختيار الشعار =============
  /// Hint: تصميم جميل لاختيار وعرض شعار الشركة
  Widget _buildLogoPicker(bool isDark) {
    // تحديد الألوان حسب الثيم
    final primaryColor = isDark 
        ? AppColors.primaryDark 
        : AppColors.primaryLight;
    
    final backgroundColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;

    return Center(
      child: Stack(
        children: [
          // ============= الخلفية =============
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark 
                    ? AppColors.borderDark 
                    : AppColors.borderLight,
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
                  // --- الشعار الموجود ---
                  ? Image.file(
                      _logoFile!,
                      fit: BoxFit.cover,
                    )
                  // --- أيقونة افتراضية ---
                  : Icon(
                      Icons.business,
                      size: 60,
                      color: isDark
                          ? AppColors.textHintDark
                          : AppColors.textHintLight,
                    ),
            ),
          ),
          
          // ============= زر التعديل =============
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
        ],
      ),
    );
  }
}