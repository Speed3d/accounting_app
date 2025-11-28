// lib/screens/auth/owner_login_screen.dart

import 'package:bcrypt/bcrypt.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../main_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

/// ============================================================================
/// شاشة تسجيل دخول المالك (بالإيميل)
/// ============================================================================
/// الغرض:
/// - تسجيل دخول المالك باستخدام Firebase Authentication
/// - التحقق من الاشتراك في Firestore
/// - إنشاء/تحديث المستخدم المحلي
/// - حفظ بيانات الاشتراك محلياً للعمل offline
/// ============================================================================
class OwnerLoginScreen extends StatefulWidget {
  const OwnerLoginScreen({super.key});

  @override
  State<OwnerLoginScreen> createState() => _OwnerLoginScreenState();
}

class _OwnerLoginScreenState extends State<OwnerLoginScreen> {
  // ==========================================================================
  // المتغيرات
  // ==========================================================================

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // ==========================================================================
  // التنظيف
  // ==========================================================================

  @override
  void dispose() {
    _emailController.dispose();
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
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text;

      debugPrint('🔐 محاولة تسجيل الدخول: $email');

      // 1️⃣ تسجيل الدخول عبر Firebase Auth
      final userCredential = await firebase_auth.FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('فشل تسجيل الدخول');
      }

      debugPrint('✅ تم تسجيل الدخول في Firebase بنجاح');

      // 2️⃣ التحقق من الاشتراك في Firestore
      final subscriptionStatus =
          await SubscriptionService.instance.checkSubscription(email);

      if (!subscriptionStatus.isValid) {
        // عرض رسالة خطأ حسب السبب
        if (!mounted) return;
        _showErrorDialog(
          subscriptionStatus.message ?? 'فشل التحقق من الاشتراك',
        );
        await firebase_auth.FirebaseAuth.instance.signOut();
        return;
      }

      debugPrint('✅ الاشتراك نشط وصالح');

      // 3️⃣ تسجيل/تحديث الجهاز الحالي في Firestore
      await SubscriptionService.instance.registerCurrentDevice(email);

      // 4️⃣ حفظ بيانات الاشتراك محلياً
      await SubscriptionService.instance.cacheSubscriptionLocally(
        email: email,
        plan: subscriptionStatus.plan!,
        startDate: DateTime.now(),
        endDate: subscriptionStatus.endDate,
        isActive: true,
        maxDevices: subscriptionStatus.features?['maxDevices'],
        features: subscriptionStatus.features!,
      );

      debugPrint('✅ تم حفظ الاشتراك محلياً');

      // 5️⃣ البحث عن/إنشاء المستخدم المحلي
      User? localUser = await DatabaseHelper.instance.getUserByEmail(email);

      if (localUser == null) {
        // إنشاء مستخدم جديد محلياً
        debugPrint('📝 إنشاء مستخدم محلي جديد...');

        final newUser = User(
          fullName: userCredential.user!.displayName ?? 'Owner',
          userName: email.split('@')[0], // username من الإيميل
          password: BCrypt.hashpw(password, BCrypt.gensalt()),
          dateT: DateTime.now().toIso8601String(),
          email: email,
          userType: 'owner',
          isAdmin: true, // المالك admin دائماً

          // جميع الصلاحيات = true للمالك
          canViewSuppliers: true,
          canEditSuppliers: true,
          canViewProducts: true,
          canEditProducts: true,
          canViewCustomers: true,
          canEditCustomers: true,
          canViewReports: true,
          canManageEmployees: true,
          canViewSettings: true,
          canViewEmployeesReport: true,
          canManageExpenses: true,
          canViewCashSales: true,
        );

        await DatabaseHelper.instance.insertUser(newUser);
        localUser = await DatabaseHelper.instance.getUserByEmail(email);

        debugPrint('✅ تم إنشاء المستخدم المحلي');
      } else {
        // تحديث آخر تسجيل دخول
        await DatabaseHelper.instance.updateUserLastLogin(localUser.id!);
        debugPrint('✅ تم تحديث آخر تسجيل دخول');
      }

      // 6️⃣ حفظ الجلسة
      AuthService().login(localUser!);

      debugPrint('✅ تم حفظ الجلسة');

      // 7️⃣ الانتقال للشاشة الرئيسية
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );

      debugPrint('✅ تم تسجيل الدخول بنجاح');
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth Error: ${e.code}');

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
        case 'too-many-requests':
          message = 'عدد محاولات كثيرة. حاول لاحقاً';
          break;
        case 'network-request-failed':
          message = 'خطأ في الاتصال بالإنترنت';
          break;
        default:
          message = 'خطأ: ${e.message}';
      }

      if (mounted) {
        _showErrorDialog(message);
      }
    } catch (e) {
      debugPrint('❌ خطأ عام: $e');

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
        title: const Text('تسجيل دخول المالك'),
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
                        Icons.email,
                        size: 80,
                        color: AppColors.primaryLight,
                      ),

                      const SizedBox(height: AppConstants.spacingXl),

                      // العنوان
                      Text(
                        'تسجيل الدخول',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),

                      const SizedBox(height: AppConstants.spacingSm),

                      // وصف
                      Text(
                        'سجل دخولك بالإيميل وكلمة المرور',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                      ),

                      const SizedBox(height: AppConstants.spacingXl),

                      // حقل الإيميل
                      CustomTextField(
                        controller: _emailController,
                        label: 'البريد الإلكتروني',
                        hint: 'example@company.com',
                        prefixIcon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال البريد الإلكتروني';
                          }
                          if (!value.contains('@')) {
                            return 'صيغة البريد الإلكتروني غير صحيحة';
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
                          if (value.length < 6) {
                            return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppConstants.spacingMd),

                      // نسيت كلمة المرور
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text('نسيت كلمة المرور؟'),
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

                      // تسجيل حساب جديد
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('ليس لديك حساب؟'),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: const Text('إنشاء حساب'),
                          ),
                        ],
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
