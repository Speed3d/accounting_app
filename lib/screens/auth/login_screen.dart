// lib/screens/auth/login_screen.dart
import 'dart:io';
import 'package:accounting_app/layouts/main_screen.dart';
import 'package:accounting_app/services/biometric_service.dart'; // ✅ Hint: إضافة BiometricService
import 'package:flutter/material.dart';
import 'package:bcrypt/bcrypt.dart';
import '../../data/database_helper.dart';
import '../../services/auth_service.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
/// ===========================================================================
/// شاشة تسجيل الدخول (Login Screen)
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
bool _isPasswordVisible = false;
bool _isLoading = false;
bool _isBiometricLoading = false; // ✅ Hint: حالة التحميل لزر البصمة
// ============= متغيرات معلومات الشركة =============
String _companyName = '';
String _companyDescription = '';
File? _companyLogo;
// ============= قاعدة البيانات =============
final dbHelper = DatabaseHelper.instance;
@override
void initState() {
super.initState();
_loadSettings();
}
Future<void> _loadSettings() async {
final l10n = widget.l10n;
try {
  final settings = await dbHelper.getAppSettings();
  
  if (mounted) {
    setState(() {
      _companyName = settings['companyName'] ?? l10n.accountingProgram;
      _companyDescription = settings['companyDescription'] ?? '';
      
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
if (!_formKey.currentState!.validate()) return;

setState(() => _isLoading = true);

try {
  final authService = AuthService();
  final username = _usernameController.text.trim();
  final password = _passwordController.text;

  final user = await dbHelper.getUserByUsername(username);
  
  if (user == null) {
    throw Exception(l10n.invalidCredentials);
  }

  final isPasswordCorrect = BCrypt.checkpw(password, user.password);
  
  if (!isPasswordCorrect) {
    throw Exception(l10n.invalidCredentials);
  }

  authService.login(user);

  if (!mounted) return;

  Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (context) => const MainScreen(),
    ),
  );

} catch (e) {
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
  if (mounted) {
    setState(() => _isLoading = false);
  }
}
}
// ===========================================================================
// ✅ Hint: معالجة تسجيل الدخول بالبصمة (دالة جديدة)
// ===========================================================================
Future<void> _handleBiometricLogin() async {
final l10n = widget.l10n;
// ✅ Hint: بدء التحميل
setState(() => _isBiometricLoading = true);

try {
  // ✅ Hint: محاولة التحقق من البصمة
  final result = await BiometricService.instance.authenticateWithBiometric();

  if (!mounted) return;

  if (result['success'] == true) {
    // ✅ Hint: نجح التحقق من البصمة - نسجل الدخول تلقائياً
    
    // ✅ Hint: جلب أول مستخدم من قاعدة البيانات (المدير عادةً)
    // يمكنك تعديل هذا المنطق حسب احتياجك
    final user = await dbHelper.getFirstUser();
    
    if (user != null) {
      // ✅ Hint: تسجيل الدخول
      AuthService().login(user);
      
      if (!mounted) return;
      
      // ✅ Hint: الانتقال للصفحة الرئيسية
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MainScreen(),
        ),
      );
    } else {
      // ✅ Hint: لا يوجد مستخدمين في قاعدة البيانات!
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.noUsersFound), // ✅ Hint: سنضيفها في الترجمة
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  } else {
    // ✅ Hint: فشل التحقق من البصمة
    final isEmulatorError = result['isEmulatorError'] == true;
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result['message'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (isEmulatorError) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.tryOnRealDevice, // ✅ Hint: سنضيفها في الترجمة
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
          backgroundColor: isEmulatorError ? AppColors.warning : AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
} catch (e) {
  debugPrint('❌ خطأ في تسجيل الدخول بالبصمة: $e');
  
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${l10n.error}: ${e.toString()}'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
} finally {
  // ✅ Hint: إيقاف التحميل
  if (mounted) {
    setState(() => _isBiometricLoading = false);
  }
}
}
@override
Widget build(BuildContext context) {
final l10n = widget.l10n;
final isDark = Theme.of(context).brightness == Brightness.dark;
return Scaffold(
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
_buildCompanyLogo(),
        const SizedBox(height: AppConstants.spacingXl),
        
        _buildCompanyInfo(l10n, isDark),
        
        const SizedBox(height: AppConstants.spacingXl),
        
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
        
        // ============= زر تسجيل الدخول الأساسي =============
        CustomButton(
          text: l10n.login,
          icon: Icons.login,
          onPressed: _handleLogin,
          isLoading: _isLoading,
          type: ButtonType.primary,
          size: ButtonSize.large,
        ),
        
        // ============= ✅ زر تسجيل الدخول بالبصمة (جديد) =============
        // ✅ Hint: يظهر فقط إذا كانت البصمة مُفعّلة
        if (BiometricService.instance.isBiometricEnabled) ...[
          const SizedBox(height: AppConstants.spacingMd),
          
          // ✅ Hint: فاصل مع نص "أو"
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: isDark 
                    ? AppColors.borderDark 
                    : AppColors.borderLight,
                  thickness: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingMd,
                ),
                child: Text(
                  l10n.or, // ✅ Hint: سنضيفها في الترجمة
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark 
                      ? AppColors.textSecondaryDark 
                      : AppColors.textSecondaryLight,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: isDark 
                    ? AppColors.borderDark 
                    : AppColors.borderLight,
                  thickness: 1,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.spacingMd),
          
          // ✅ Hint: الزر نفسه
          CustomButton(
            text: l10n.loginWithBiometric, // ✅ Hint: سنضيفها في الترجمة
            icon: Icons.fingerprint,
            onPressed: _handleBiometricLogin,
            isLoading: _isBiometricLoading,
            type: ButtonType.secondary, // ✅ Hint: نوع ثانوي (Outlined)
            size: ButtonSize.large,
          ),
        ],
      ],
    ),
  ),
);
}
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
Widget _buildCompanyInfo(AppLocalizations l10n, bool isDark) {
return Column(
children: [
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