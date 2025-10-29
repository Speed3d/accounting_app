// lib/screens/suppliers/add_edit_partner_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/helpers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_text_field.dart';

/// شاشة إضافة أو تعديل شريك
class AddEditPartnerScreen extends StatefulWidget {
  final Partner? partner;
  
  const AddEditPartnerScreen({super.key, this.partner});

  @override
  State<AddEditPartnerScreen> createState() => _AddEditPartnerScreenState();
}

class _AddEditPartnerScreenState extends State<AddEditPartnerScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _shareController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  
  // State
  File? _imageFile;
  bool _isSaving = false;
  
  // Getters
  bool get _isEditMode => widget.partner != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _loadPartnerData();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shareController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// تحميل بيانات الشريك في حالة التعديل
  void _loadPartnerData() {
    final partner = widget.partner!;
    _nameController.text = partner.partnerName;
    _shareController.text = partner.sharePercentage.toString();
    _addressController.text = partner.partnerAddress ?? '';
    _phoneController.text = partner.partnerPhone ?? '';
    _notesController.text = partner.notes ?? '';
    
    if (partner.imagePath != null && partner.imagePath!.isNotEmpty) {
      _imageFile = File(partner.imagePath!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? l10n.editPartnerInfo : l10n.addNewPartner),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _savePartner,
            tooltip: l10n.save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppConstants.screenPadding,
          children: [
            // ============= صورة الشريك =============
            _buildImagePicker(l10n),
            
            const SizedBox(height: AppConstants.spacingXl),
            
            // ============= المعلومات الأساسية =============
            _buildBasicInfoSection(l10n),
            
            const SizedBox(height: AppConstants.spacingXl),
            
            // ============= نسبة الشراكة =============
            _buildShareSection(l10n),
            
            const SizedBox(height: AppConstants.spacingXl),
            
            // ============= معلومات إضافية =============
            _buildAdditionalInfoSection(l10n),
            
            const SizedBox(height: AppConstants.spacingXl),
            
            // ============= زر الحفظ =============
            _buildSaveButton(l10n),
            
            const SizedBox(height: AppConstants.spacingXl),
          ],
        ),
      ),
    );
  }

  /// بناء منتقي الصورة
  Widget _buildImagePicker(AppLocalizations l10n) {
    final hasImage = _imageFile != null && _imageFile!.existsSync();
    
    return Center(
      child: GestureDetector(
        onTap: () => _showImageSourceDialog(l10n),
        child: Stack(
          children: [
            // الصورة الرئيسية
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.info.withOpacity(0.3),
                  width: 3,
                ),
                image: hasImage
                    ? DecorationImage(
                        image: FileImage(_imageFile!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: !hasImage
                  ? Icon(
                      Icons.person,
                      size: 60,
                      color: AppColors.info.withOpacity(0.5),
                    )
                  : null,
            ),
            
            // زر الكاميرا
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.info,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 3,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.camera_alt),
                  color: Colors.white,
                  iconSize: 20,
                  onPressed: () => _showImageSourceDialog(l10n),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء قسم المعلومات الأساسية
  Widget _buildBasicInfoSection(AppLocalizations l10n) {
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
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: AppConstants.borderRadiusSm,
                ),
                child: Icon(
                  Icons.person_outline,
                  color: AppColors.info,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Text(
                l10n.partnerInfo,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.spacingLg),
          
          // اسم الشريك
          CustomTextField(
            controller: _nameController,
            label: l10n.partnerName,
            hint: l10n.enterPartnerName,
            prefixIcon: Icons.person,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.partnerNameRequired;
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  /// بناء قسم نسبة الشراكة
  Widget _buildShareSection(AppLocalizations l10n) {
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
                child: Icon(
                  Icons.percent,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Text(
                l10n.sharePercentage,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.spacingMd),
          
          // معلومة مساعدة
          Container(
            padding: AppConstants.paddingSm,
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: AppConstants.borderRadiusSm,
              border: Border.all(
                color: AppColors.info.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.info,
                ),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(
                  child: Text(
                    l10n.percentageMustBeBetween1And100,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppConstants.spacingMd),
          
          // حقل النسبة
          CustomTextField(
            controller: _shareController,
            label: l10n.sharePercentage,
            hint: l10n.enterPartnerShare,
            prefixIcon: Icons.percent,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.fieldRequired;
              }
              
              final normalizedValue = convertArabicNumbersToEnglish(value);
              final amount = double.tryParse(normalizedValue);
              
              if (amount == null || amount <= 0 || amount > 100) {
                return l10n.percentageMustBeBetween1And100;
              }
              
              return null;
            },
          ),
          
          const SizedBox(height: AppConstants.spacingSm),
          
          // عرض مرئي للنسبة
          if (_shareController.text.isNotEmpty)
            _buildPercentageVisualizer(),
        ],
      ),
    );
  }

  /// بناء عرض مرئي للنسبة المئوية
  Widget _buildPercentageVisualizer() {
    final normalizedValue = convertArabicNumbersToEnglish(_shareController.text);
    final percentage = double.tryParse(normalizedValue) ?? 0;
    final l10n = AppLocalizations.of(context)!;
    
    if (percentage <= 0 || percentage > 100) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.invalidShare,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingXs),
        ClipRRect(
          borderRadius: AppConstants.borderRadiusFull,
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 8,
            backgroundColor: AppColors.success.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
          ),
        ),
      ],
    );
  }

  /// بناء قسم المعلومات الإضافية
  Widget _buildAdditionalInfoSection(AppLocalizations l10n) {
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
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: AppConstants.borderRadiusSm,
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: AppColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Text(
                l10n.additionalInfo,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.spacingLg),
          
          // العنوان
          CustomTextField(
            controller: _addressController,
            label: l10n.addressOptional,
            hint: l10n.enterAddress,
            prefixIcon: Icons.location_on,
            maxLines: 2,
          ),
          
          const SizedBox(height: AppConstants.spacingMd),
          
          // رقم الهاتف
          CustomTextField(
            controller: _phoneController,
            label: l10n.phoneOptional,
            hint: l10n.enterPhoneNumber,
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          
          const SizedBox(height: AppConstants.spacingMd),
          
          // الملاحظات
          CustomTextField(
            controller: _notesController,
            label: l10n.notesOptional,
            hint: l10n.enterNotes,
            prefixIcon: Icons.note,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  /// بناء زر الحفظ
  Widget _buildSaveButton(AppLocalizations l10n) {
    return CustomButton(
      text: _isEditMode ? l10n.updatePartner : l10n.createPartner,
      icon: _isEditMode ? Icons.update : Icons.add,
      isLoading: _isSaving,
      onPressed: _savePartner,
    );
  }

  /// عرض مربع حوار اختيار مصدر الصورة
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
          padding: AppConstants.paddingLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // العنوان
              Text(
                l10n.imageSource,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: AppConstants.spacingLg),
              
              // الخيارات
              Row(
                children: [
                  Expanded(
                    child: _buildImageSourceOption(
                      icon: Icons.photo_library,
                      label: l10n.gallery,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery, l10n);
                      },
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingMd),
                  Expanded(
                    child: _buildImageSourceOption(
                      icon: Icons.camera_alt,
                      label: l10n.camera,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera, l10n);
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppConstants.spacingMd),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء خيار مصدر الصورة
  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppConstants.borderRadiusMd,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        decoration: BoxDecoration(
          color: AppColors.info.withOpacity(0.1),
          borderRadius: AppConstants.borderRadiusMd,
          border: Border.all(
            color: AppColors.info.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.info, size: 40),
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  /// اختيار صورة
  Future<void> _pickImage(ImageSource source, AppLocalizations l10n) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
      );
      
      if (pickedFile == null) return;
      
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = p.basename(pickedFile.path);
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
      
      setState(() => _imageFile = savedImage);
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorPickingImage(e.toString())),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// حفظ الشريك
  void _savePartner() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      final partner = Partner(
        partnerID: _isEditMode ? widget.partner!.partnerID : null,
        supplierID: _isEditMode ? widget.partner!.supplierID : null,
        partnerName: _nameController.text.trim(),
        sharePercentage: double.parse(
          convertArabicNumbersToEnglish(_shareController.text.trim()),
        ),
        partnerAddress: _addressController.text.trim(),
        partnerPhone: _phoneController.text.trim(),
        imagePath: _imageFile?.path,
        notes: _notesController.text.trim(),
        dateAdded: _isEditMode 
            ? widget.partner!.dateAdded 
            : DateTime.now().toIso8601String(),
      );
      
      Navigator.of(context).pop(partner);
      
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}