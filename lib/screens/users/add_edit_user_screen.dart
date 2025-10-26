// lib/screens/users/add_edit_user_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:bcrypt/bcrypt.dart';
import '../../data/database_helper.dart';
import '../../data/models.dart';
import 'package:accounting_app/l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_service.dart'; // ← مهم جداً!

/// 📄 صفحة إضافة/تعديل مستخدم
class AddEditUserScreen extends StatefulWidget {
  final User? user;
  const AddEditUserScreen({super.key, this.user});

  @override
  State<AddEditUserScreen> createState() => _AddEditUserScreenState();
}

class _AddEditUserScreenState extends State<AddEditUserScreen> {
  // ============= المتغيرات =============
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper.instance;
  final _authService = AuthService(); // ← جديد!
  final _fullNameController = TextEditingController();
  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  final Map<String, bool> _permissions = {
    'isAdmin': false,
    'canViewSuppliers': false,
    'canEditSuppliers': false,
    'canViewProducts': false,
    'canEditProducts': false,
    'canViewCustomers': true,
    'canEditCustomers': false,
    'canViewReports': true,
    'canManageEmployees': false,
    'canViewSettings': false,
    'canViewEmployeesReport': false,
    'canManageExpenses': false,
    'canViewCashSales': false,
  };
  
  File? _imageFile;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isEditingSelf = false; // ← جديد: هل يعدل نفسه؟
  
  bool get _isEditMode => widget.user != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _loadUserData();
      _checkIfEditingSelf(); // ← التحقق الجديد!
    }
  }

  void _loadUserData() {
    final u = widget.user!;
    _fullNameController.text = u.fullName;
    _userNameController.text = u.userName;
    
    if (u.imagePath != null && u.imagePath!.isNotEmpty) {
      _imageFile = File(u.imagePath!);
    }
    
    _permissions['isAdmin'] = u.isAdmin;
    _permissions['canViewSuppliers'] = u.canViewSuppliers;
    _permissions['canEditSuppliers'] = u.canEditSuppliers;
    _permissions['canViewProducts'] = u.canViewProducts;
    _permissions['canEditProducts'] = u.canEditProducts;
    _permissions['canViewCustomers'] = u.canViewCustomers;
    _permissions['canEditCustomers'] = u.canEditCustomers;
    _permissions['canViewReports'] = u.canViewReports;
    _permissions['canManageEmployees'] = u.canManageEmployees;
    _permissions['canViewSettings'] = u.canViewSettings;
    _permissions['canViewEmployeesReport'] = u.canViewEmployeesReport;
    _permissions['canManageExpenses'] = u.canManageExpenses;
    _permissions['canViewCashSales'] = u.canViewCashSales;
  }

  // ============= ✅ التحقق الصحيح: هل يعدل نفسه؟ =============
  void _checkIfEditingSelf() {
    if (widget.user == null) return;
    
    // الحصول على المستخدم المسجل دخوله حالياً
    final currentUser = _authService.currentUser;
    
    if (currentUser == null) return;
    
    // التحقق: هل ID المستخدم الذي يتم تعديله = ID المستخدم الحالي؟
    // وهل هو مدير؟
    if (widget.user!.id == currentUser.id && widget.user!.isAdmin) {
      setState(() => _isEditingSelf = true);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _userNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============= حفظ المستخدم =============
  void _saveUser() async {
    final l10n = AppLocalizations.of(context)!;
    
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      String passwordToSave;
      
      if (_isEditMode) {
        if (_passwordController.text.isNotEmpty) {
          passwordToSave = BCrypt.hashpw(_passwordController.text, BCrypt.gensalt());
        } else {
          passwordToSave = widget.user!.password;
        }
      } else {
        if (_passwordController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.passwordRequiredForNewUser),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }
        passwordToSave = BCrypt.hashpw(_passwordController.text, BCrypt.gensalt());
      }
      
      final user = User(
        id: _isEditMode ? widget.user!.id : null,
        fullName: _fullNameController.text,
        userName: _userNameController.text,
        password: passwordToSave,
        dateT: _isEditMode ? widget.user!.dateT : DateTime.now().toIso8601String(),
        imagePath: _imageFile?.path,
        // ← إذا كان يعدل نفسه، نحتفظ بصلاحياته كما هي
        isAdmin: _isEditingSelf ? true : _permissions['isAdmin']!,
        canViewSuppliers: _isEditingSelf ? true : _permissions['canViewSuppliers']!,
        canEditSuppliers: _isEditingSelf ? true : _permissions['canEditSuppliers']!,
        canViewProducts: _isEditingSelf ? true : _permissions['canViewProducts']!,
        canEditProducts: _isEditingSelf ? true : _permissions['canEditProducts']!,
        canViewCustomers: _isEditingSelf ? true : _permissions['canViewCustomers']!,
        canEditCustomers: _isEditingSelf ? true : _permissions['canEditCustomers']!,
        canViewReports: _isEditingSelf ? true : _permissions['canViewReports']!,
        canManageEmployees: _isEditingSelf ? true : _permissions['canManageEmployees']!,
        canViewSettings: _isEditingSelf ? true : _permissions['canViewSettings']!,
        canViewEmployeesReport: _isEditingSelf ? true : _permissions['canViewEmployeesReport']!,
        canManageExpenses: _isEditingSelf ? true : _permissions['canManageExpenses']!,
        canViewCashSales: _isEditingSelf ? true : _permissions['canViewCashSales']!,
      );
      
      if (_isEditMode) {
        await dbHelper.updateUser(user);
        
        // ← مهم: تحديث بيانات المستخدم في AuthService إذا كان يعدل نفسه
        if (_isEditingSelf) {
          _authService.login(user);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.userUpdatedSuccess),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        await dbHelper.insertUser(user);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.userAddedSuccess),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
      
      if (mounted) Navigator.of(context).pop(true);
      
    } catch (e) {
      final message = e.toString().contains('UNIQUE constraint failed')
          ? l10n.usernameAlreadyExists
          : l10n.errorOccurred(e.toString());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? l10n.editUser : l10n.addUser),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _saveUser,
            icon: _isLoading
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppConstants.screenPadding,
          children: [
            // ============= تنبيه تعديل الملف الشخصي =============
            if (_isEditingSelf) _buildSelfEditBanner(l10n),
            
            // ============= صورة المستخدم =============
            _buildImagePicker(l10n),
            
            const SizedBox(height: AppConstants.spacingXl),
            
            // ============= المعلومات الأساسية =============
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.basicInformation ?? 'المعلومات الأساسية',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  
                  const SizedBox(height: AppConstants.spacingMd),
                  
                  CustomTextField(
                    controller: _fullNameController,
                    label: l10n.fullName,
                    prefixIcon: Icons.person,
                    validator: (v) => (v == null || v.isEmpty) 
                        ? l10n.fieldRequired 
                        : null,
                  ),
                  
                  const SizedBox(height: AppConstants.spacingMd),
                  
                  CustomTextField(
                    controller: _userNameController,
                    label: l10n.username,
                    prefixIcon: Icons.account_circle,
                    validator: (v) => (v == null || v.isEmpty) 
                        ? l10n.fieldRequired 
                        : null,
                  ),
                  
                  const SizedBox(height: AppConstants.spacingMd),
                  
                  CustomTextField(
                    controller: _passwordController,
                    label: l10n.password,
                    hint: _isEditMode ? l10n.passwordHint : null,
                    prefixIcon: Icons.lock,
                    obscureText: _obscurePassword,
                    suffixIcon: _obscurePassword 
                        ? Icons.visibility 
                        : Icons.visibility_off,
                    onSuffixIconTap: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppConstants.spacingLg),
            
            // ============= الصلاحيات (مخفية إذا كان يعدل نفسه) =============
            if (!_isEditingSelf) ...[
              Text(
                l10n.userPermissions,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              
              const SizedBox(height: AppConstants.spacingMd),
              
              // صلاحية الإدارة
              _buildAdminPermission(l10n),
              
              const SizedBox(height: AppConstants.spacingMd),
              
              // الموردين
              _buildPermissionGroup(
                l10n,
                title: l10n.suppliersManagement ?? 'إدارة الموردين',
                icon: Icons.local_shipping,
                permissions: [
                  _PermissionItem('canViewSuppliers', l10n.viewSuppliers),
                  _PermissionItem('canEditSuppliers', l10n.editSuppliers),
                ],
              ),
              
              const SizedBox(height: AppConstants.spacingSm),
              
              // المنتجات
              _buildPermissionGroup(
                l10n,
                title: l10n.productsManagement ?? 'إدارة المنتجات',
                icon: Icons.inventory_2,
                permissions: [
                  _PermissionItem('canViewProducts', l10n.viewProducts),
                  _PermissionItem('canEditProducts', l10n.editProducts),
                ],
              ),
              
              const SizedBox(height: AppConstants.spacingSm),
              
              // العملاء
              _buildPermissionGroup(
                l10n,
                title: l10n.customersManagement ?? 'إدارة العملاء',
                icon: Icons.people,
                permissions: [
                  _PermissionItem('canViewCustomers', l10n.viewCustomers),
                  _PermissionItem('canEditCustomers', l10n.editCustomers),
                ],
              ),
              
              const SizedBox(height: AppConstants.spacingSm),
              
              // الموظفين
              _buildPermissionGroup(
                l10n,
                title: l10n.employeesManagement ?? 'إدارة الموظفين',
                icon: Icons.badge,
                permissions: [
                  _PermissionItem('canManageEmployees', l10n.manageEmployees),
                  _PermissionItem('canViewEmployeesReport', l10n.viewEmployeesReport),
                ],
              ),
              
              const SizedBox(height: AppConstants.spacingSm),
              
              // التقارير والمبيعات
              _buildPermissionGroup(
                l10n,
                title: l10n.reportsAndSales ?? 'التقارير والمبيعات',
                icon: Icons.assessment,
                permissions: [
                  _PermissionItem('canViewReports', l10n.viewReports),
                  _PermissionItem('canViewCashSales', l10n.viewCashSales),
                  _PermissionItem('canManageExpenses', l10n.manageExpenses),
                ],
              ),
              
              const SizedBox(height: AppConstants.spacingSm),
              
              // الإعدادات
              _buildPermissionGroup(
                l10n,
                title: l10n.systemSettings ?? 'إعدادات النظام',
                icon: Icons.settings,
                permissions: [
                  _PermissionItem('canViewSettings', l10n.viewSettings),
                ],
              ),
            ],
            
            const SizedBox(height: AppConstants.spacingXl),
            
            // ============= زر الحفظ =============
            CustomButton(
              text: _isEditingSelf 
                  ? (l10n.updateProfile ?? 'تحديث الملف الشخصي')
                  : (_isEditMode ? l10n.updateUser : l10n.addUser),
              onPressed: _saveUser,
              isLoading: _isLoading,
              icon: Icons.save,
            ),
            
            const SizedBox(height: AppConstants.spacingLg),
          ],
        ),
      ),
    );
  }

  // ============= تنبيه تعديل الملف الشخصي =============
  Widget _buildSelfEditBanner(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingLg),
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
        children: [
          Icon(
            Icons.account_circle,
            color: AppColors.info,
            size: 32,
          ),
          const SizedBox(width: AppConstants.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.editingYourProfile ?? 'تعديل ملفك الشخصي',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXs),
                Text(
                  l10n.selfEditNote ?? 
                  'يمكنك تعديل اسمك، اسم المستخدم، كلمة المرور، والصورة الشخصية. الصلاحيات محمية.',
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

  // ============= Image Picker =============
  Widget _buildImagePicker(AppLocalizations l10n) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _isEditingSelf
                    ? AppColors.info
                    : Theme.of(context).primaryColor.withOpacity(0.3),
                width: 3,
              ),
            ),
            child: ClipOval(
              child: _imageFile != null && _imageFile!.existsSync()
                  ? Image.file(
                      _imageFile!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
                      ),
                    ),
            ),
          ),
          if (_isEditingSelf)
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.info,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
                boxShadow: AppConstants.shadowMd,
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                onPressed: () => _showImageSourceDialog(l10n),
                tooltip: l10n.changeImage ?? 'تغيير الصورة',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============= صلاحية الإدارة =============
  Widget _buildAdminPermission(AppLocalizations l10n) {
    return CustomCard(
      color: _permissions['isAdmin']! 
          ? Theme.of(context).primaryColor.withOpacity(0.1) 
          : null,
      child: SwitchListTile(
        title: Text(
          l10n.adminPermission,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          l10n.adminPermissionSubtitle,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        value: _permissions['isAdmin']!,
        onChanged: (bool value) {
          setState(() {
            _permissions['isAdmin'] = value;
            if (value) {
              // إذا أصبح مدير، يحصل على كل الصلاحيات
              _permissions.updateAll((key, v) => true);
            }
          });
        },
        secondary: Icon(
          Icons.admin_panel_settings,
          color: _permissions['isAdmin']! 
              ? Theme.of(context).primaryColor 
              : null,
        ),
      ),
    );
  }

  // ============= مجموعة صلاحيات =============
  Widget _buildPermissionGroup(
    AppLocalizations l10n, {
    required String title,
    required IconData icon,
    required List<_PermissionItem> permissions,
  }) {
    final bool isAdmin = _permissions['isAdmin']!;
    
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: AppConstants.spacingSm),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          
          const Divider(height: AppConstants.spacingMd),
          
          ...permissions.map((permission) {
            return CheckboxListTile(
              title: Text(permission.label),
              value: _permissions[permission.key]!,
              onChanged: isAdmin 
                  ? null 
                  : (bool? value) {
                      setState(() {
                        _permissions[permission.key] = value!;
                      });
                    },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            );
          }).toList(),
        ],
      ),
    );
  }

  // ============= حوار اختيار مصدر الصورة =============
  void _showImageSourceDialog(AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: AppConstants.paddingLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.imageSource,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              
              const SizedBox(height: AppConstants.spacingLg),
              
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(l10n.gallery),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery, l10n);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: AppConstants.borderRadiusMd,
                ),
              ),
              
              const SizedBox(height: AppConstants.spacingSm),
              
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(l10n.camera),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera, l10n);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: AppConstants.borderRadiusMd,
                ),
              ),
              
              const SizedBox(height: AppConstants.spacingMd),
            ],
          ),
        ),
      ),
    );
  }

  // ============= اختيار الصورة =============
  Future<void> _pickImage(ImageSource source, AppLocalizations l10n) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
      );
      
      if (pickedFile == null) return;
      
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = p.basename(pickedFile.path);
      final savedImage = await File(pickedFile.path).copy(
        '${appDir.path}/$fileName',
      );
      
      setState(() => _imageFile = savedImage);
      
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
}

// ============= Helper Class =============
class _PermissionItem {
  final String key;
  final String label;
  
  _PermissionItem(this.key, this.label);
}