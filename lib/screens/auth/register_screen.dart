// lib/screens/auth/register_screen.dart

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

/// ============================================================================
/// شاشة تسجيل حساب جديد (Owner Registration)
/// ============================================================================
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text;
      final fullName = _fullNameController.text.trim();

      debugPrint('📝 إنشاء حساب جديد: $email');

      // إنشاء حساب في Firebase
      final userCredential = await firebase_auth.FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // تحديث الاسم
      await userCredential.user?.updateDisplayName(fullName);

      debugPrint('✅ تم إنشاء الحساب بنجاح');

      if (!mounted) return;

      // عرض رسالة نجاح
      _showSuccessDialog();
    } on firebase_auth.FirebaseAuthException catch (e) {
      String message = 'حدث خطأ في التسجيل';

      switch (e.code) {
        case 'email-already-in-use':
          message = 'هذا الإيميل مستخدم بالفعل';
          break;
        case 'invalid-email':
          message = 'صيغة الإيميل غير صحيحة';
          break;
        case 'weak-password':
          message = 'كلمة المرور ضعيفة';
          break;
      }

      if (mounted) _showErrorDialog(message);
    } catch (e) {
      if (mounted) _showErrorDialog('خطأ: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: AppConstants.spacingSm),
            const Text('نجح'),
          ],
        ),
        content: const Text(
          'تم إنشاء الحساب بنجاح!\n\n'
          'يرجى التواصل مع المطور لتفعيل الاشتراك.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // إغلاق Dialog
              Navigator.pop(context); // العودة لشاشة الدخول
            },
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب جديد')),
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
                    children: [
                      Icon(Icons.person_add, size: 80, color: AppColors.primaryLight),
                      const SizedBox(height: AppConstants.spacingXl),
                      Text('إنشاء حساب جديد', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: AppConstants.spacingXl),

                      // الاسم الكامل
                      CustomTextField(
                        controller: _fullNameController,
                        label: 'الاسم الكامل',
                        hint: 'أحمد محمد',
                        prefixIcon: Icons.person,
                        textInputAction: TextInputAction.next,
                        validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: AppConstants.spacingMd),

                      // الإيميل
                      CustomTextField(
                        controller: _emailController,
                        label: 'البريد الإلكتروني',
                        hint: 'example@company.com',
                        prefixIcon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'مطلوب';
                          if (!v.contains('@')) return 'صيغة غير صحيحة';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppConstants.spacingMd),

                      // كلمة المرور
                      CustomTextField(
                        controller: _passwordController,
                        label: 'كلمة المرور',
                        hint: '••••••••',
                        prefixIcon: Icons.lock,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'مطلوب';
                          if (v.length < 6) return '6 أحرف على الأقل';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppConstants.spacingMd),

                      // تأكيد كلمة المرور
                      CustomTextField(
                        controller: _confirmPasswordController,
                        label: 'تأكيد كلمة المرور',
                        hint: '••••••••',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleRegister(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'مطلوب';
                          if (v != _passwordController.text) return 'غير متطابقة';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppConstants.spacingLg),

                      // زر التسجيل
                      CustomButton(
                        text: 'إنشاء الحساب',
                        icon: Icons.person_add,
                        onPressed: _handleRegister,
                        isLoading: _isLoading,
                        type: ButtonType.primary,
                        size: ButtonSize.large,
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
