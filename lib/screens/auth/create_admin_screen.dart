// lib/screens/auth/create_admin_screen.dart

import 'package:flutter/material.dart';
import 'package:bcrypt/bcrypt.dart';

// ============= استيراد الملفات =============
import '../../data/database_helper.dart';
import '../../data/models.dart' as models;
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'login_screen.dart';

/// ===========================================================================
/// شاشة إنشاء حساب المدير (Create Admin Screen)
/// ===========================================================================
/// الغرض:
/// - إنشاء أول مستخدم في النظام (المدير الأساسي)
/// - تعيين جميع الصلاحيات للمدير تلقائياً
/// - التحقق من صحة البيانات المدخلة
/// - تشفير كلمة المرور قبل حفظها
/// - التوجيه لشاشة تسجيل الدخول بعد الإنشاء الناجح
/// ===========================================================================
class CreateAdminScreen extends StatefulWidget {
  final AppLocalizations l10n;

  const CreateAdminScreen({
    super.key,
    required this.l10n,
  });

  @override
  State<CreateAdminScreen> createState() => _CreateAdminScreenState();
}

class _CreateAdminScreenState extends State<CreateAdminScreen> {
  
  // ============= متغيرات النموذج =============
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // ============= متغيرات الحالة =============
  bool _isPasswordVisible = false;    // إظهار/إخفاء كلمة المرور
  bool _isLoading = false;            // حالة التحميل أثناء إنشاء الحساب

  // ===========================================================================
  // التنظيف عند إغلاق الشاشة
  // ===========================================================================
  @override
  void dispose() {
    _fullNameController.dispose();
    _userNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // معالجة إنشاء حساب المدير
  // ===========================================================================
  Future<void> _handleCreateAdmin() async {
    final l10n = widget.l10n;

    // --- التحقق من صحة النموذج ---
    if (!_formKey.currentState!.validate()) return;

    // --- بدء التحميل ---
    setState(() => _isLoading = true);

    try {
      // ============= الخطوة 1: جمع البيانات =============
      final fullName = _fullNameController.text.trim();
      final userName = _userNameController.text.trim();
      final password = _passwordController.text;

      // ============= الخطوة 2: تشفير كلمة المرور =============
      // استخدام BCrypt لتشفير كلمة المرور بشكل آمن
      final String hashedPassword = BCrypt.hashpw(
        password,
        BCrypt.gensalt(),
      );

      // ============= الخطوة 3: إنشاء كائن المستخدم (المدير) =============
      // المدير يحصل على جميع الصلاحيات تلقائياً
      final adminUser = models.User(
        fullName: fullName,
        userName: userName,
        password: hashedPassword,
        dateT: DateTime.now().toIso8601String(),
        
        // --- صلاحيات المدير (الكل = true) ---
        isAdmin: true,                      // مدير النظام
        canViewSuppliers: true,             // عرض الموردين
        canEditSuppliers: true,             // تعديل الموردين
        canViewProducts: true,              // عرض المنتجات
        canEditProducts: true,              // تعديل المنتجات
        canViewCustomers: true,             // عرض العملاء
        canEditCustomers: true,             // تعديل العملاء
        canViewReports: true,               // عرض التقارير
        canManageEmployees: true,           // إدارة الموظفين
        canViewSettings: true,              // عرض الإعدادات
        canViewEmployeesReport: true,       // عرض تقارير الموظفين
        canManageExpenses: true,            // إدارة المصروفات
        canViewCashSales: true,             // عرض المبيعات النقدية
      );

      // ============= الخطوة 4: حفظ المستخدم في قاعدة البيانات =============
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.insertUser(adminUser);

      if (!mounted) return;

      // ============= الخطوة 5: عرض رسالة نجاح =============
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.adminCreatedSuccess),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppConstants.borderRadiusMd,
          ),
        ),
      );

      // ============= الخطوة 6: الانتقال لشاشة تسجيل الدخول =============
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LoginScreen(l10n: l10n),
        ),
      );

    } catch (e) {
      // --- معالجة الأخطاء ---
      if (mounted) {
        // رسالة خطأ خاصة لحالة اسم المستخدم المكرر
        final errorMessage = e.toString().contains('UNIQUE constraint failed')
            ? l10n.usernameExists
            : l10n.unexpectedError(e.toString());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppConstants.borderRadiusMd,
            ),
          ),
        );
      }
    } finally {
      // --- إيقاف التحميل ---
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
    final l10n = widget.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // ============= الخلفية المتدرجة =============
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: isDark 
              ? AppColors.gradientDark 
              : AppColors.gradientLight,
          ),
        ),
        
        // ============= المحتوى =============
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: context.isMobile 
                  ? AppConstants.spacingLg 
                  : AppConstants.spacingXl,
                vertical: AppConstants.spacingXl,
              ),
              child: _buildAdminForm(l10n, isDark),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // بناء نموذج إنشاء المدير
  // ===========================================================================
  Widget _buildAdminForm(AppLocalizations l10n, bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 450),
      padding: AppConstants.paddingXl,
      decoration: BoxDecoration(
        color: isDark 
          ? AppColors.cardDark.withOpacity(0.5)
          : Colors.white.withOpacity(0.9),
        borderRadius: AppConstants.borderRadiusXl,
        border: Border.all(
          color: isDark 
            ? AppColors.borderDark.withOpacity(0.5)
            : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- الأيقونة والعنوان ---
            _buildHeader(l10n, isDark),
            
            const SizedBox(height: AppConstants.spacingXl),
            
            // --- حقل الاسم الكامل ---
            CustomTextField(
              controller: _fullNameController,
              label: l10n.fullName,
              hint: 'مثال: سنان اياد',
              prefixIcon: Icons.person_outline,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              validator: (value) => 
                (value?.isEmpty ?? true) 
                  ? l10n.fullNameRequired 
                  : null,
            ),
            
            const SizedBox(height: AppConstants.spacingMd),
            
            // --- حقل اسم المستخدم ---
            CustomTextField(
              controller: _userNameController,
              label: l10n.usernameForLogin,
              hint: 'مثال: admin',
              prefixIcon: Icons.account_circle_outlined,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              validator: (value) => 
                (value?.isEmpty ?? true) 
                  ? l10n.usernameRequired 
                  : null,
            ),
            
            const SizedBox(height: AppConstants.spacingMd),
            
            // --- حقل كلمة المرور ---
            CustomTextField(
              controller: _passwordController,
              label: l10n.chooseStrongPassword,
              hint: '••••••••',
              prefixIcon: Icons.lock_outline,
              obscureText: !_isPasswordVisible,
              textInputAction: TextInputAction.done,
              suffixIcon: _isPasswordVisible 
                ? Icons.visibility_off 
                : Icons.visibility,
              onSuffixIconTap: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.passwordRequired;
                }
                if (value.length < 4) {
                  return l10n.passwordTooShort;
                }
                return null;
              },
            ),
            
            const SizedBox(height: AppConstants.spacingXl),
            
            // --- ملاحظة أمان ---
            _buildSecurityNote(isDark),
            
            const SizedBox(height: AppConstants.spacingLg),
            
            // --- زر إنشاء الحساب ---
            CustomButton(
              text: l10n.createAdminAndStart,
              icon: Icons.check_circle_outline,
              onPressed: _handleCreateAdmin,
              isLoading: _isLoading,
              type: ButtonType.primary,
              size: ButtonSize.large,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // بناء رأس الصفحة (الأيقونة والعنوان)
  // ===========================================================================
  Widget _buildHeader(AppLocalizations l10n, bool isDark) {
    return Column(
      children: [
        // أيقونة الدرع (رمز الأمان)
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.shield_outlined,
            size: 50,
            color: isDark 
              ? AppColors.primaryDark 
              : AppColors.primaryLight,
          ),
        ),
        
        const SizedBox(height: AppConstants.spacingMd),
        
        // عنوان "إعداد حساب المدير"
        Text(
          l10n.setupAdminAccount,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark 
              ? AppColors.textPrimaryDark 
              : AppColors.textPrimaryLight,
          ),
        ),
        
        const SizedBox(height: AppConstants.spacingXs),
        
        // نص ترحيبي
        Text(
          l10n.welcomeSetup,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark 
              ? AppColors.textSecondaryDark 
              : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // بناء ملاحظة الأمان
  // ===========================================================================
  Widget _buildSecurityNote(bool isDark) {
    return Container(
      padding: AppConstants.paddingMd,
      decoration: BoxDecoration(
        color: isDark 
          ? AppColors.info.withOpacity(0.1)
          : AppColors.info.withOpacity(0.05),
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
            size: 20,
            color: AppColors.info,
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: Text(
              'سيحصل هذا المستخدم على جميع الصلاحيات كمدير للنظام',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark 
                  ? AppColors.textSecondaryDark 
                  : AppColors.textSecondaryLight,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
