// lib/screens/auth/sub_user_login_screen.dart

import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/material.dart';
import '../../data/database_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../main_screen.dart';

/// ============================================================================
/// شاشة تسجيل دخول الموظف (Sub User) - محلي فقط
/// ============================================================================
/// الغرض:
/// - تسجيل دخول الموظف باستخدام Username + Password المحلي
/// - لا يحتاج اتصال بالإنترنت
/// - مرتبط بحساب المالك
/// ============================================================================
class SubUserLoginScreen extends StatefulWidget {
  const SubUserLoginScreen({super.key});

  @override
  State<SubUserLoginScreen> createState() => _SubUserLoginScreenState();
}

class _SubUserLoginScreenState extends State<SubUserLoginScreen> {
  // ==========================================================================
  // المتغيرات
  // ==========================================================================

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // ==========================================================================
  // التنظيف
  // ==========================================================================

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // معالجة تسجيل الدخول
  // ==========================================================================

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final username = _usernameController.text.trim();
      final password = _passwordController.text;

      debugPrint('🔐 محاولة تسجيل دخول موظف: $username');

      // 1️⃣ البحث عن المستخدم في قاعدة البيانات المحلية
      final user = await DatabaseHelper.instance.getUserByUsername(username);

      if (user == null) {
        debugPrint('❌ اسم المستخدم غير موجود');
        if (mounted) {
          _showErrorDialog('اسم المستخدم غير موجود');
        }
        return;
      }

      // 2️⃣ التحقق من أنه sub_user وليس owner
      if (user.userType == 'owner') {
        debugPrint('❌ هذا حساب مالك');
        if (mounted) {
          _showErrorDialog(
            'هذا حساب مالك. يرجى استخدام تسجيل دخول المالك.',
          );
        }
        return;
      }

      // 3️⃣ التحقق من كلمة المرور
      final isPasswordCorrect = BCrypt.checkpw(password, user.password);

      if (!isPasswordCorrect) {
        debugPrint('❌ كلمة المرور غير صحيحة');
        if (mounted) {
          _showErrorDialog('كلمة المرور غير صحيحة');
        }
        return;
      }

      // 4️⃣ التحقق من أن المستخدم نشط (إذا تم إضافة IsActive في المستقبل)
      // TODO: يمكن إضافة check للـ IsActive هنا

      // 5️⃣ تحديث آخر تسجيل دخول
      await DatabaseHelper.instance.updateUserLastLogin(user.id!);

      debugPrint('✅ تم تحديث آخر تسجيل دخول');

      // 6️⃣ حفظ الجلسة
      AuthService().login(user);

      debugPrint('✅ تم حفظ الجلسة');

      // 7️⃣ الانتقال للشاشة الرئيسية
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );

      debugPrint('✅ تم تسجيل دخول الموظف بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ: $e');

      if (mounted) {
        _showErrorDialog('خطأ: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==========================================================================
  // عرض رسالة خطأ
  // ==========================================================================

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppConstants.borderRadiusLg,
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: AppConstants.spacingSm),
            const Text('خطأ'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // بناء الواجهة
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل دخول الموظف'),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: isDark ? AppColors.gradientDark : AppColors.gradientLight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spacingLg),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // أيقونة
                      Icon(
                        Icons.badge,
                        size: 80,
                        color: AppColors.secondaryLight,
                      ),

                      const SizedBox(height: AppConstants.spacingXl),

                      // العنوان
                      Text(
                        'تسجيل دخول الموظف',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),

                      const SizedBox(height: AppConstants.spacingSm),

                      // وصف
                      Text(
                        'أدخل اسم المستخدم وكلمة المرور الخاصة بك',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                      ),

                      const SizedBox(height: AppConstants.spacingXl),

                      // حقل اسم المستخدم
                      CustomTextField(
                        controller: _usernameController,
                        label: 'اسم المستخدم',
                        hint: 'ahmed_cashier',
                        prefixIcon: Icons.person,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال اسم المستخدم';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppConstants.spacingMd),

                      // حقل كلمة المرور
                      CustomTextField(
                        controller: _passwordController,
                        label: 'كلمة المرور',
                        hint: '••••••••',
                        prefixIcon: Icons.lock,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        suffixIcon: _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        onSuffixIconPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال كلمة المرور';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppConstants.spacingLg),

                      // زر تسجيل الدخول
                      CustomButton(
                        text: 'تسجيل الدخول',
                        icon: Icons.login,
                        onPressed: _handleLogin,
                        isLoading: _isLoading,
                        type: ButtonType.primary,
                        size: ButtonSize.large,
                      ),

                      const SizedBox(height: AppConstants.spacingMd),

                      // ملاحظة
                      Container(
                        padding: const EdgeInsets.all(AppConstants.spacingMd),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: AppConstants.borderRadiusMd,
                          border: Border.all(
                            color: AppColors.info.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.info,
                              size: 20,
                            ),
                            const SizedBox(width: AppConstants.spacingSm),
                            Expanded(
                              child: Text(
                                'إذا نسيت كلمة المرور، تواصل مع المدير.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
