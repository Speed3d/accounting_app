// lib/screens/auth/login_screen.dart

import 'dart:io';
import 'package:accounting_app/screens/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:bcrypt/bcrypt.dart';

// ============= استيراد الملفات =============
import '../../data/database_helper.dart';
import '../../services/auth_service.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../HomeScreen/home_screen.dart';
import '../test_layout_screen.dart';

/// ===========================================================================
/// شاشة تسجيل الدخول (Login Screen)
/// ===========================================================================
/// الغرض:
/// - السماح للمستخدمين بتسجيل الدخول إلى التطبيق
/// - التحقق من بيانات الاعتماد (اسم المستخدم وكلمة المرور)
/// - عرض معلومات الشركة (الشعار والاسم والوصف)
/// - التنقل إلى الصفحة الرئيسية بعد تسجيل الدخول الناجح
/// ===========================================================================
class LoginScreen extends StatefulWidget {
  final AppLocalizations l10n;

  const LoginScreen({
    super.key,
    required this.l10n,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  
  // ============= متغيرات النموذج =============
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // ============= متغيرات الحالة =============
  bool _isPasswordVisible = false;    // إظهار/إخفاء كلمة المرور
  bool _isLoading = false;            // حالة التحميل أثناء تسجيل الدخول
  
  // ============= متغيرات معلومات الشركة =============
  String _companyName = '';           // اسم الشركة من قاعدة البيانات
  String _companyDescription = '';    // وصف الشركة
  File? _companyLogo;                 // شعار الشركة
  
  // ============= قاعدة البيانات =============
  final dbHelper = DatabaseHelper.instance;

  // ===========================================================================
  // التهيئة الأولية
  // ===========================================================================
  @override
  void initState() {
    super.initState();
    _loadSettings(); // تحميل معلومات الشركة
  }

  // ===========================================================================
  // تحميل إعدادات الشركة من قاعدة البيانات
  // ===========================================================================
  Future<void> _loadSettings() async {
    final l10n = widget.l10n;

    try {
      final settings = await dbHelper.getAppSettings();
      
      if (mounted) {
        setState(() {
          // جلب اسم الشركة (أو استخدام الاسم الافتراضي)
          _companyName = settings['companyName'] ?? l10n.accountingProgram;
          
          // جلب وصف الشركة (اختياري)
          _companyDescription = settings['companyDescription'] ?? '';
          
          // جلب شعار الشركة (إذا كان موجوداً)
          final logoPath = settings['companyLogoPath'];
          if (logoPath != null && logoPath.isNotEmpty) {
            _companyLogo = File(logoPath);
          }
        });
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل إعدادات الشركة: $e');
    }
  }

  // ===========================================================================
  // التنظيف عند إغلاق الشاشة
  // ===========================================================================
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // معالجة تسجيل الدخول
  // ===========================================================================
  Future<void> _handleLogin() async {
    final l10n = widget.l10n;

    // --- التحقق من صحة النموذج ---
    if (!_formKey.currentState!.validate()) return;

    // --- بدء التحميل ---
    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final username = _usernameController.text.trim();
      final password = _passwordController.text;

      // --- الخطوة 1: البحث عن المستخدم في قاعدة البيانات ---
      final user = await dbHelper.getUserByUsername(username);
      
      if (user == null) {
        throw Exception(l10n.invalidCredentials);
      }

      // --- الخطوة 2: التحقق من كلمة المرور ---
      final isPasswordCorrect = BCrypt.checkpw(password, user.password);
      
      if (!isPasswordCorrect) {
        throw Exception(l10n.invalidCredentials);
      }

      // --- الخطوة 3: تسجيل الدخول بنجاح ✅ ---
      authService.login(user);

      if (!mounted) return;

      // --- الخطوة 4: الانتقال إلى الصفحة الرئيسية ---
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          // builder: (context) => const HomeScreen(),
          builder: (context) => const DashboardScreen(),
        ),
      );

    } catch (e) {
      // --- عرض رسالة الخطأ ---
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
            ),
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
              child: _buildLoginForm(l10n, isDark),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // بناء نموذج تسجيل الدخول
  // ===========================================================================
  Widget _buildLoginForm(AppLocalizations l10n, bool isDark) {
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
            // --- شعار الشركة ---
            _buildCompanyLogo(),
            
            const SizedBox(height: AppConstants.spacingXl),
            
            // --- معلومات الشركة ---
            _buildCompanyInfo(l10n, isDark),
            
            const SizedBox(height: AppConstants.spacingXl),
            
            // --- حقل اسم المستخدم ---
            CustomTextField(
              controller: _usernameController,
              label: l10n.username,
              hint: l10n.username,
              prefixIcon: Icons.person_outline,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              validator: (value) => 
                (value?.isEmpty ?? true) 
                  ? l10n.pleaseEnterUsername 
                  : null,
            ),
            
            const SizedBox(height: AppConstants.spacingMd),
            
            // --- حقل كلمة المرور ---
            CustomTextField(
              controller: _passwordController,
              label: l10n.password,
              hint: l10n.password,
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
              validator: (value) => 
                (value?.isEmpty ?? true) 
                  ? l10n.pleaseEnterPassword 
                  : null,
            ),
            
            const SizedBox(height: AppConstants.spacingXl),
            
            // --- زر تسجيل الدخول ---
            CustomButton(
              text: l10n.login,
              icon: Icons.login,
              onPressed: _handleLogin,
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
  // بناء شعار الشركة
  // ===========================================================================
  Widget _buildCompanyLogo() {
    final bool hasLogo = _companyLogo != null && _companyLogo!.existsSync();

    return Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipOval(
          child: hasLogo
            ? Image.file(
                _companyLogo!,
                fit: BoxFit.cover,
              )
            : Icon(
                Icons.store,
                size: 50,
                color: AppColors.primaryLight.withOpacity(0.7),
              ),
        ),
      ),
    );
  }

  // ===========================================================================
  // بناء معلومات الشركة
  // ===========================================================================
  Widget _buildCompanyInfo(AppLocalizations l10n, bool isDark) {
    return Column(
      children: [
        // عنوان "تسجيل الدخول إلى"
        Text(
          l10n.loginTo,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark 
              ? AppColors.textSecondaryDark 
              : AppColors.textSecondaryLight,
          ),
        ),
        
        const SizedBox(height: AppConstants.spacingXs),
        
        // اسم الشركة
        Text(
          _companyName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark 
              ? AppColors.textPrimaryDark 
              : AppColors.textPrimaryLight,
          ),
        ),
        
        // وصف الشركة (إذا كان موجوداً)
        if (_companyDescription.isNotEmpty) ...[
          const SizedBox(height: AppConstants.spacingXs),
          Text(
            _companyDescription,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark 
                ? AppColors.textSecondaryDark 
                : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ],
    );
  }
}
