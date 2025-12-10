// lib/screens/auth/login_screen.dart

import 'dart:io'; // ← Hint: لعرض صورة الشركة المحلية
import 'package:accountant_touch/layouts/main_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import '../../services/session_service.dart';
import '../../data/database_helper.dart'; // ← Hint: لجلب معلومات الشركة
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'register_screen.dart';
// رفع جديد

/// ============================================================================
/// شاشة تسجيل الدخول - النظام الجديد المبسط
/// ============================================================================
///
/// ← Hint: النظام الجديد - Firebase Auth فقط (لا database queries!)
/// ← Hint: تسجيل دخول بالإيميل والباسوورد
/// ← Hint: حفظ الجلسة في SessionService بعد النجاح
/// ← Hint: التوجيه مباشرة لـ MainScreen (لا login_selection!)
/// ← Hint: ✅ يعرض معلومات الشركة الفعلية من قاعدة البيانات
///
/// ============================================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // ← Hint: جلب معلومات الشركة من قاعدة البيانات
  // ==========================================================================
  /// 🏪 جلب معلومات الشركة
  ///
  /// ← Hint: تُستخدم لعرض اسم وشعار الشركة بدلاً من القيم الافتراضية
  /// ← Hint: تُجلب من جدول TB_Settings
  Future<Map<String, String?>> _getCompanyInfo() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final settings = await dbHelper.getAppSettings();

      return {
        'companyName': settings['companyName'] as String?,
        'companyLogoPath': settings['companyLogoPath'] as String?,
      };
    } catch (e) {
      debugPrint('⚠️ خطأ في جلب معلومات الشركة: $e');
      return {
        'companyName': null,
        'companyLogoPath': null,
      };
    }
  }

  /// ← Hint: دالة تسجيل الدخول - Firebase Auth + SessionService فقط
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text;

      debugPrint('🔐 محاولة تسجيل الدخول: $email');

      // 1️⃣ Hint: تسجيل الدخول عبر Firebase Authentication
      final userCredential = await firebase_auth.FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('✅ تم تسجيل الدخول في Firebase Auth بنجاح');

      // 2️⃣ Hint: حفظ الجلسة في SessionService
      // ← Hint: نستخدم البيانات من Firebase User مباشرة
      await SessionService.instance.saveSession(
        email: email,
        displayName: userCredential.user?.displayName ?? '',
        photoURL: userCredential.user?.photoURL,
      );

      debugPrint('✅ تم حفظ الجلسة بنجاح');

      if (!mounted) return;

      // 3️⃣ Hint: التوجيه مباشرة للشاشة الرئيسية
      // ← Hint: حذف كل navigation stack - المستخدم مسجل دخول بالفعل
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false, // ← Hint: حذف كل الشاشات السابقة
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      String message = 'حدث خطأ في تسجيل الدخول';

      switch (e.code) {
        case 'user-not-found':
          message = 'لا يوجد حساب بهذا الإيميل';
          break;
        case 'wrong-password':
          message = 'كلمة المرور غير صحيحة';
          break;
        case 'invalid-email':
          message = 'صيغة الإيميل غير صحيحة';
          break;
        case 'user-disabled':
          message = 'هذا الحساب معطل';
          break;
        case 'network-request-failed':
          message = 'خطأ في الاتصال بالإنترنت';
          break;
        case 'too-many-requests':
          message = 'محاولات كثيرة - حاول لاحقاً';
          break;
      }

      debugPrint('❌ خطأ Firebase Auth: ${e.code} - ${e.message}');
      if (mounted) _showErrorDialog(message);
    } catch (e) {
      debugPrint('❌ خطأ عام: $e');
      if (mounted) _showErrorDialog('خطأ: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// ← Hint: نسيت كلمة المرور - إرسال رابط الاستعادة عبر Firebase
  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showErrorDialog('الرجاء إدخال البريد الإلكتروني أولاً');
      return;
    }

    if (!email.contains('@')) {
      _showErrorDialog('صيغة البريد الإلكتروني غير صحيحة');
      return;
    }

    try {
      debugPrint('📧 إرسال رابط استعادة كلمة المرور لـ: $email');

      await firebase_auth.FirebaseAuth.instance.sendPasswordResetEmail(
        email: email.toLowerCase(),
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.mark_email_read, color: AppColors.success),
              const SizedBox(width: AppConstants.spacingSm),
              const Text('تم الإرسال'),
            ],
          ),
          content: Text(
            'تم إرسال رابط استعادة كلمة المرور إلى:\n$email\n\n'
            'الرجاء التحقق من بريدك الإلكتروني.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      String message = 'حدث خطأ في إرسال الرابط';

      switch (e.code) {
        case 'user-not-found':
          message = 'لا يوجد حساب بهذا الإيميل';
          break;
        case 'invalid-email':
          message = 'صيغة الإيميل غير صحيحة';
          break;
        case 'network-request-failed':
          message = 'خطأ في الاتصال بالإنترنت';
          break;
      }

      if (mounted) _showErrorDialog(message);
    }
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
      appBar: AppBar(title: const Text('تسجيل الدخول')),
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
                      // ← Hint: ✅ عرض شعار واسم الشركة من قاعدة البيانات
                      FutureBuilder<Map<String, String?>>(
                        future: _getCompanyInfo(),
                        builder: (context, snapshot) {
                          final companyName = snapshot.data?['companyName'] ?? 'تسجيل الدخول';
                          final companyLogoPath = snapshot.data?['companyLogoPath'];

                          // ← Hint: التحقق من وجود صورة الشركة
                          final hasCompanyLogo = companyLogoPath != null &&
                                                 companyLogoPath.isNotEmpty &&
                                                 File(companyLogoPath).existsSync();

                          return Column(
                            children: [
                              // ← Hint: شعار الشركة (محلي) أو أيقونة افتراضية
                              if (hasCompanyLogo)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(
                                    File(companyLogoPath!),
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.store,
                                      size: 100,
                                      color: AppColors.primaryLight,
                                    ),
                                  ),
                                )
                              else
                                Icon(
                                  Icons.store,
                                  size: 100,
                                  color: AppColors.primaryLight,
                                ),

                              const SizedBox(height: AppConstants.spacingXl),

                              // ← Hint: اسم الشركة من الإعدادات
                              Text(
                                companyName,
                                style: Theme.of(context).textTheme.headlineMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: AppConstants.spacingSm),

                      Text(
                        'مرحباً بعودتك',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withOpacity(0.9),
                            ),
                      ),

                      const SizedBox(height: AppConstants.spacingXl),

                      // البريد الإلكتروني
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
                        textInputAction: TextInputAction.done,
                        suffixIcon: _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        onSuffixIconPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'مطلوب';
                          return null;
                        },
                      ),

                      const SizedBox(height: AppConstants.spacingSm),

                      // نسيت كلمة المرور
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _handleForgotPassword,
                          child: Text('نسيت كلمة المرور', style: Theme.of(context).textTheme.headlineSmall),
                        ),
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

                      // فاصل
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppConstants.spacingSm),
                            child: Text(
                              'أو',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: AppConstants.spacingMd),

                      // زر إنشاء حساب جديد
                      CustomButton(
                        text: 'ليس لدي حساب - إنشاء حساب',
                        icon: Icons.person_add,
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
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
