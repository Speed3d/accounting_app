// lib/screens/suppliers/add_edit_supplier_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_text_field.dart';
import 'add_edit_partner_screen.dart';

/// شاشة إضافة أو تعديل مورد
class AddEditSupplierScreen extends StatefulWidget {
  final Supplier? supplier;
  
  const AddEditSupplierScreen({super.key, this.supplier});

  @override
  State<AddEditSupplierScreen> createState() => _AddEditSupplierScreenState();
}

class _AddEditSupplierScreenState extends State<AddEditSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper.instance;
  final AuthService _authService = AuthService();
  
  // Controllers
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  
  // State
  String _supplierType = 'فردي'; // نوع المورد: فردي أو شراكة
  List<Partner> _partners = [];
  File? _imageFile;
  bool _isSaving = false;
  
  // Getters
  bool get _isEditMode => widget.supplier != null;
  bool get _isPartnerType => _supplierType == 'شراكة';

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _loadSupplierData();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// تحميل بيانات المورد في حالة التعديل
  void _loadSupplierData() {
    final supplier = widget.supplier!;
    _nameController.text = supplier.supplierName;
    _phoneController.text = supplier.phone ?? '';
    _addressController.text = supplier.address ?? '';
    _notesController.text = supplier.notes ?? '';
    _supplierType = supplier.supplierType;
    
    if (supplier.imagePath != null && supplier.imagePath!.isNotEmpty) {
      _imageFile = File(supplier.imagePath!);
    }
    
    if (_isPartnerType) {
      _loadPartners();
    }
  }

  /// تحميل الشركاء
  Future<void> _loadPartners() async {
    if (widget.supplier?.supplierID == null) return;
    
    final partners = await dbHelper.getPartnersForSupplier(widget.supplier!.supplierID!);
    setState(() => _partners = partners);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? l10n.editSupplier : l10n.addSupplier),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveSupplier,
            tooltip: l10n.save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppConstants.screenPadding,
          children: [
            // صورة المورد
            _buildImagePicker(l10n),
            
            const SizedBox(height: AppConstants.spacingXl),
            
            // معلومات المورد الأساسية
            _buildBasicInfoSection(l10n),
            
            const SizedBox(height: AppConstants.spacingXl),
            
            // نوع المورد
            _buildSupplierTypeSection(l10n),
            
            const SizedBox(height: AppConstants.spacingXl),
            
            // معلومات إضافية
            _buildAdditionalInfoSection(l10n),
            
            // قسم الشركاء (إذا كان النوع شراكة)
            if (_isPartnerType) ...[
              const SizedBox(height: AppConstants.spacingXl),
              _buildPartnersSection(l10n),
            ],
            
            const SizedBox(height: AppConstants.spacingXl),
            
            // زر الحفظ
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
                color: AppColors.primaryLight.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryLight.withOpacity(0.3),
                  width: 4,
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
                      Icons.store,
                      size: 60,
                      color: AppColors.primaryLight.withOpacity(0.5),
                    )
                  : null,
            ),
            
            // زر الكاميرا
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
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
                  color: AppColors.primaryLight.withOpacity(0.1),
                  borderRadius: AppConstants.borderRadiusSm,
                ),
                child: Icon(
                  Icons.info_outline,
                  color: AppColors.primaryLight,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Text(
                l10n.basicInfo,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.spacingLg),
          
          // اسم المورد
          CustomTextField(
            controller: _nameController,
            label: l10n.supplierName,
            hint: l10n.enterSupplierName,
            prefixIcon: Icons.store,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.supplierNameRequired;
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  /// بناء قسم نوع المورد
  Widget _buildSupplierTypeSection(AppLocalizations l10n) {
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
                  Icons.category_outlined,
                  color: AppColors.info,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Text(
                l10n.supplierType,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.spacingMd),
          
          // خيارات النوع
          Row(
            children: [
              Expanded(
                child: _buildTypeOption(
                  icon: Icons.person,
                  label: l10n.individual,
                  value: 'فردي', // نوع: فردي (شخص واحد)
                  isSelected: _supplierType == 'فردي',
                ),
              ),
              const SizedBox(width: AppConstants.spacingMd),
              Expanded(
                child: _buildTypeOption(
                  icon: Icons.handshake,
                  label: l10n.partnership,
                  value: 'شراكة', // نوع: شراكة (عدة شركاء)
                  isSelected: _supplierType == 'شراكة',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// بناء خيار نوع المورد
  Widget _buildTypeOption({
    required IconData icon,
    required String label,
    required String value,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _supplierType = value;
          if (value == 'فردي') { // إذا تم اختيار "فردي"
            _partners.clear(); // مسح قائمة الشركاء
          } else if (value == 'شراكة' && _isEditMode) { // إذا تم اختيار "شراكة" في وضع التعديل
            _loadPartners(); // تحميل الشركاء من قاعدة البيانات
          }
        });
      },
      borderRadius: AppConstants.borderRadiusMd,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMd,
          vertical: AppConstants.spacingLg,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryLight.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: AppConstants.borderRadiusMd,
          border: Border.all(
            color: isSelected
                ? AppColors.primaryLight
                : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primaryLight
                  : Theme.of(context).iconTheme.color,
              size: 32,
            ),
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? AppColors.primaryLight
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
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
                l10n.additionalInfoOptional,
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

  /// بناء قسم الشركاء
  Widget _buildPartnersSection(AppLocalizations l10n) {
    final totalPercentage = _partners.fold<double>(
      0.0,
      (sum, partner) => sum + partner.sharePercentage,
    );
    final isPercentageValid = totalPercentage <= 100;
    
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم مع الإحصائيات
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingSm),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: AppConstants.borderRadiusSm,
                ),
                child: Icon(
                  Icons.people,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.partners,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      l10n.partnersCount(_partners.length),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              // نسبة الشراكة
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingMd,
                  vertical: AppConstants.spacingSm,
                ),
                decoration: BoxDecoration(
                  color: isPercentageValid
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  borderRadius: AppConstants.borderRadiusFull,
                  border: Border.all(
                    color: isPercentageValid
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPercentageValid ? Icons.check_circle : Icons.warning,
                      size: 16,
                      color: isPercentageValid
                          ? AppColors.success
                          : AppColors.error,
                    ),
                    const SizedBox(width: AppConstants.spacingXs),
                    Text(
                      '${totalPercentage.toStringAsFixed(1)}%', // مجموع النسب المئوية
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isPercentageValid
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.spacingMd),
          
          // تنبيه إذا لم يكن هناك شركاء
          if (_partners.isEmpty)
            Container(
              padding: AppConstants.paddingMd,
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: AppConstants.borderRadiusMd,
                border: Border.all(
                  color: AppColors.warning.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: AppConstants.spacingMd),
                  Expanded(
                    child: Text(
                      l10n.atLeastOnePartnerRequired,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            // قائمة الشركاء
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _partners.length,
              separatorBuilder: (context, index) => const SizedBox(
                height: AppConstants.spacingSm,
              ),
              itemBuilder: (context, index) {
                return _buildPartnerItem(_partners[index], index, l10n);
              },
            ),
          
          const SizedBox(height: AppConstants.spacingMd),
          
          // زر إضافة شريك
          CustomButton(
            text: l10n.addPartner,
            icon: Icons.person_add,
            type: ButtonType.secondary,
            onPressed: _navigateToAddPartner,
          ),
        ],
      ),
    );
  }

  /// بناء عنصر شريك
  Widget _buildPartnerItem(Partner partner, int index, AppLocalizations l10n) {
    final hasImage = partner.imagePath != null && 
                      partner.imagePath!.isNotEmpty &&
                      File(partner.imagePath!).existsSync();
    
    return Container(
      padding: AppConstants.paddingMd,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppConstants.borderRadiusMd,
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        children: [
          // صورة الشريك
          CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.info.withOpacity(0.1),
            backgroundImage: hasImage ? FileImage(File(partner.imagePath!)) : null,
            child: !hasImage
                ? Icon(
                    Icons.person,
                    color: AppColors.info,
                  )
                : null,
          ),
          
          const SizedBox(width: AppConstants.spacingMd),
          
          // معلومات الشريك
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partner.partnerName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXs),
                Row(
                  children: [
                    Icon(
                      Icons.percent,
                      size: 14,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: AppConstants.spacingXs),
                    Text(
                      l10n.percentageLabel(partner.sharePercentage.toString()),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // أزرار الإجراءات
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                color: AppColors.info,
                iconSize: 20,
                tooltip: l10n.edit,
                onPressed: () => _navigateToEditPartner(partner, index),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: AppColors.error,
                iconSize: 20,
                tooltip: 'حذف', // نص زر الحذف
                onPressed: () => _confirmDeletePartner(index, partner.partnerName),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// بناء زر الحفظ
  Widget _buildSaveButton(AppLocalizations l10n) {
    return CustomButton(
      text: _isEditMode ? l10n.updateSupplier : l10n.createSupplier,
      icon: _isEditMode ? Icons.update : Icons.add,
      isLoading: _isSaving,
      onPressed: _saveSupplier,
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
          color: AppColors.primaryLight.withOpacity(0.1),
          borderRadius: AppConstants.borderRadiusMd,
          border: Border.all(
            color: AppColors.primaryLight.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryLight, size: 40),
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
        ),
      );
    }
  }

  /// الانتقال لإضافة شريك
  Future<void> _navigateToAddPartner() async {
    final result = await Navigator.of(context).push<Partner>(
      MaterialPageRoute(
        builder: (context) => const AddEditPartnerScreen(),
      ),
    );
    
    if (result != null) {
      setState(() => _partners.add(result));
    }
  }

  /// الانتقال لتعديل شريك
  Future<void> _navigateToEditPartner(Partner partner, int index) async {
    final result = await Navigator.of(context).push<Partner>(
      MaterialPageRoute(
        builder: (context) => AddEditPartnerScreen(partner: partner),
      ),
    );
    
    if (result != null) {
      setState(() => _partners[index] = result);
    }
  }

  /// تأكيد حذف شريك (حذف من القائمة المحلية فقط - لا يحذف من قاعدة البيانات)
  Future<void> _confirmDeletePartner(int index, String partnerName) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.delete_outline,
          size: 48,
          color: AppColors.error,
        ),
        title: Text(l10n.deletePartner),
        content: Text(l10n.confirmDeletePartner(partnerName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      // حذف من القائمة المحلية فقط (لن يتم الحذف من قاعدة البيانات للحفاظ على الارتباطات)
      setState(() => _partners.removeAt(index));
    }
  }

  /// حفظ المورد
  Future<void> _saveSupplier() async {
    final l10n = AppLocalizations.of(context)!;
    
    // التحقق من صحة النموذج
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // التحقق من الشراكة
    if (_isPartnerType) {
      if (_partners.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.atLeastOnePartnerRequired),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      
      final totalPercentage = _partners.fold<double>(
        
        0.0,
        (sum, partner) => sum + partner.sharePercentage,
      );
      
      if (totalPercentage > 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.partnerShareTotalExceeds100(totalPercentage.toString())),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      
      
      // تحذير إذا كانت النسب أقل من 100%
      if (totalPercentage < 100) {
        
        final proceed = await showDialog<bool>(
          
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(
              Icons.warning_outlined,
              size: 48,
              color: AppColors.warning,
            ),
            title: Text(l10n.warning),
            content: Text(
              l10n.partnerShareWarning(totalPercentage.toStringAsFixed(1))
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                ),
                
                child: Text(l10n.continueButton),
              ),
            ],
          ),
        );
        
        if (proceed != true) return;
      }
    }
    
    setState(() => _isSaving = true);
    
    try {
      String action;
      String successMessage;
      
      if (_isEditMode) {
        // تحديث مورد موجود
        final updatedSupplier = Supplier(
          supplierID: widget.supplier!.supplierID,
          supplierName: _nameController.text.trim(),
          supplierType: _supplierType,
          address: _addressController.text.trim(),
          phone: _phoneController.text.trim(),
          notes: _notesController.text.trim(),
          dateAdded: widget.supplier!.dateAdded,
          imagePath: _imageFile?.path,
          isActive: widget.supplier!.isActive,
        );
        
        await dbHelper.updateSupplierWithPartners(updatedSupplier, _partners);
        action = l10n.activityUpdateSupplier(updatedSupplier.supplierName);
        successMessage = l10n.supplierUpdatedSuccess;
      } else {
        // إضافة مورد جديد
        final newSupplier = Supplier(
          supplierName: _nameController.text.trim(),
          supplierType: _supplierType,
          address: _addressController.text.trim(),
          phone: _phoneController.text.trim(),
          notes: _notesController.text.trim(),
          dateAdded: DateTime.now().toIso8601String(),
          imagePath: _imageFile?.path,
        );
        
        await dbHelper.insertSupplierWithPartners(newSupplier, _partners);
        action = l10n.activityAddSupplier(newSupplier.supplierName);
        successMessage = l10n.supplierAddedSuccess;
      }
      
      // تسجيل النشاط
      await dbHelper.logActivity(
        action,
        userId: _authService.currentUser?.id,
        userName: _authService.currentUser?.fullName,
      );
      
      if (!mounted) return;
      
      // عرض رسالة النجاح
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // العودة للصفحة السابقة
      Navigator.of(context).pop(true);
      
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorSaving(e.toString())),
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