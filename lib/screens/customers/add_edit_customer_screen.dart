// lib/screens/customers/add_edit_customer_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// ============= استيراد الملفات =============
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../services/auth_service.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

/// ===========================================================================
/// شاشة إضافة/تعديل عميل (Add/Edit Customer Screen)
/// ===========================================================================
/// الغرض:
/// - إضافة عميل جديد مع صورة اختيارية
/// - تعديل بيانات عميل موجود
/// - اختيار صورة من الكاميرا أو المعرض
/// - حفظ البيانات في قاعدة البيانات
/// ===========================================================================
class AddEditCustomerScreen extends StatefulWidget {
  final Customer? customer; // null = وضع الإضافة، موجود = وضع التعديل

  const AddEditCustomerScreen({
    super.key,
    this.customer,
  });

  @override
  State<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
  
  // ============= متغيرات النموذج =============
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // ============= الخدمات =============
  final dbHelper = DatabaseHelper.instance;
  final AuthService _authService = AuthService();
  
  // ============= متغيرات الحالة =============
  File? _imageFile;                    // الصورة المختارة
  bool _isLoading = false;             // حالة الحفظ
  
  // ============= Getters =============
  bool get _isEditMode => widget.customer != null;

  // ===========================================================================
  // التهيئة الأولية
  // ===========================================================================
  @override
  void initState() {
    super.initState();
    
    // إذا كنا في وضع التعديل، املأ الحقول بالبيانات الموجودة
    if (_isEditMode) {
      final customer = widget.customer!;
      _nameController.text = customer.customerName;
      _addressController.text = customer.address ?? '';
      _phoneController.text = customer.phone ?? '';
      
      // تحميل الصورة إذا كانت موجودة
      if (customer.imagePath != null && customer.imagePath!.isNotEmpty) {
        final imageFile = File(customer.imagePath!);
        if (imageFile.existsSync()) {
          _imageFile = imageFile;
        }
      }
    }
  }

  // ===========================================================================
  // التنظيف
  // ===========================================================================
  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // اختيار صورة
  // ===========================================================================
  Future<void> _pickImage(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    
    try {
      final picker = ImagePicker();
      
      // اختيار الصورة
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80, // ضغط الصورة لتوفير المساحة
      );
      
      if (pickedFile == null) return; // المستخدم ألغى العملية
      
      // حفظ الصورة في مجلد التطبيق
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'customer_${DateTime.now().millisecondsSinceEpoch}${p.extension(pickedFile.path)}';
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
      
      setState(() {
        _imageFile = savedImage;
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

  // ===========================================================================
  // حفظ العميل
  // ===========================================================================
  Future<void> _saveCustomer() async {
    final l10n = AppLocalizations.of(context)!;
    
    // التحقق من صحة النموذج
    if (!_formKey.currentState!.validate()) return;
    
    // بدء التحميل
    setState(() => _isLoading = true);
    
    try {
      String action;
      String successMessage;
      
      if (_isEditMode) {
        // ============= وضع التعديل =============
        final updatedCustomer = Customer(
          customerID: widget.customer!.customerID,
          customerName: _nameController.text.trim(),
          address: _addressController.text.trim(),
          phone: _phoneController.text.trim(),
          imagePath: _imageFile?.path,
          // الاحتفاظ بالبيانات المالية القديمة
          debt: widget.customer!.debt,
          payment: widget.customer!.payment,
          remaining: widget.customer!.remaining,
          dateT: widget.customer!.dateT,
          isActive: widget.customer!.isActive,
        );
        
        await dbHelper.updateCustomer(updatedCustomer);
        action = '${l10n.updateCustomer}: ${updatedCustomer.customerName}';
        successMessage = l10n.customerUpdatedSuccess;
        
      } else {
        // ============= وضع الإضافة =============
        final newCustomer = Customer(
          customerName: _nameController.text.trim(),
          address: _addressController.text.trim(),
          phone: _phoneController.text.trim(),
          imagePath: _imageFile?.path,
          dateT: DateTime.now().toIso8601String(),
        );
        
        await dbHelper.insertCustomer(newCustomer);
        action = '${l10n.addCustomer}: ${newCustomer.customerName}';
        successMessage = l10n.customerAddedSuccess;
      }
      
      // تسجيل النشاط
      await dbHelper.logActivity(
        action,
        userId: _authService.currentUser?.id,
        userName: _authService.currentUser?.fullName,
      );
      
      if (mounted) {
        // عرض رسالة نجاح
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: AppColors.success,
          ),
        );
        
        // العودة للصفحة السابقة مع إشعار بالنجاح
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

  // ===========================================================================
  // بناء واجهة المستخدم
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      // ============= AppBar =============
      appBar: AppBar(
        title: Text(_isEditMode ? l10n.editCustomer : l10n.addCustomer),
        actions: [
          // زر الحفظ في الـ AppBar
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l10n.save,
            onPressed: _isLoading ? null : _saveCustomer,
          ),
        ],
      ),
      
      // ============= Body =============
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppConstants.screenPadding,
          children: [
            // ============= صورة العميل =============
            _buildImageSection(l10n),
            
            const SizedBox(height: AppConstants.spacingXl),
            
            // ============= حقل اسم العميل =============
            CustomTextField(
              controller: _nameController,
              label: l10n.customerName,
              hint: l10n.enterCustomerName,
              prefixIcon: Icons.person_outline,
              textInputAction: TextInputAction.next,
              validator: (value) => 
                (value == null || value.trim().isEmpty) 
                  ? l10n.customerNameRequired 
                  : null,
            ),
            
            const SizedBox(height: AppConstants.spacingMd),
            
            // ============= حقل العنوان =============
            CustomTextField(
              controller: _addressController,
              label: l10n.addressOptional,
              hint: l10n.enterAddress,
              prefixIcon: Icons.location_on_outlined,
              textInputAction: TextInputAction.next,
              maxLines: 2,
            ),
            
            const SizedBox(height: AppConstants.spacingMd),
            
            // ============= حقل الهاتف =============
            CustomTextField(
              controller: _phoneController,
              label: l10n.phoneOptional,
              hint: l10n.enterPhone,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
            ),
            
            const SizedBox(height: AppConstants.spacingXl),
            
            // ============= زر الحفظ =============
            CustomButton(
              text: _isEditMode ? l10n.updateCustomer : l10n.addCustomer,
              icon: _isEditMode ? Icons.update : Icons.add,
              onPressed: _saveCustomer,
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

  // ===========================================================================
  // بناء قسم الصورة
  // ===========================================================================
  Widget _buildImageSection(AppLocalizations l10n) {
    return Center(
      child: Stack(
        children: [
          // ============= الصورة الرمزية =============
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
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
                    color: AppColors.primaryLight.withOpacity(0.3),
                  ),
            ),
          ),
          
          // ============= زر الكاميرا =============
          Positioned(
            bottom: 0,
            right: 0,
            child: Material(
              color: AppColors.primaryLight,
              shape: const CircleBorder(),
              elevation: 4,
              child: InkWell(
                onTap: () => _showImageSourceDialog(l10n),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // مربع حوار اختيار مصدر الصورة
  // ===========================================================================
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
              // ============= عنوان =============
              Text(
                l10n.imageSource,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              
              const SizedBox(height: AppConstants.spacingLg),
              
              // ============= خيار المعرض =============
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
              
              // ============= خيار الكاميرا =============
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
              
              // ============= زر الإلغاء =============
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