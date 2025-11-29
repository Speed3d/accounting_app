// lib/screens/auth/register_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'login_selection_screen.dart';

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

      // 1️⃣ إنشاء حساب في Firebase Authentication
      final userCredential = await firebase_auth.FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2️⃣ تحديث الاسم في Firebase Profile
      await userCredential.user?.updateDisplayName(fullName);

      debugPrint('✅ تم إنشاء الحساب في Firebase Auth بنجاح');

      // 3️⃣ Hint: التحقق من flag التفعيل التلقائي في Remote Config
      // (يمكن تغييره لاحقاً من Firebase Console بدون تحديث التطبيق)
      // ملاحظة: في البداية القيمة الافتراضية false، قم بتفعيلها من Firebase Console
      final autoActivate = FirebaseService.instance.remoteConfig
              .getBool('auto_activate_trial');

      debugPrint('🔍 auto_activate_trial = $autoActivate');

      if (autoActivate) {
        // 4️⃣ Hint: التفعيل التلقائي - إنشاء subscription في Firestore
        // (يعمل على Spark Plan المجاني - لا يحتاج Cloud Functions)
        debugPrint('🚀 إنشاء اشتراك تجريبي تلقائياً...');

        await _createTrialSubscription(
          email: email,
          displayName: fullName,
        );

        debugPrint('✅ تم إنشاء الاشتراك التجريبي بنجاح');
      } else {
        debugPrint('ℹ️ التفعيل التلقائي معطل - يحتاج تفعيل يدوي');
      }

      if (!mounted) return;

      // 5️⃣ عرض رسالة نجاح مع/بدون تفعيل
      _showSuccessDialog(autoActivated: autoActivate);
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
          message = 'كلمة المرور ضعيفة جداً';
          break;
        case 'network-request-failed':
          message = 'خطأ في الاتصال بالإنترنت';
          break;
      }

      if (mounted) _showErrorDialog(message);
    } catch (e) {
      debugPrint('❌ خطأ عام: $e');
      if (mounted) _showErrorDialog('خطأ: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Hint: دالة مساعدة لإنشاء اشتراك تجريبي تلقائياً في Firestore
  /// (يعمل فقط على Spark Plan - لا يحتاج Blaze Plan)
  Future<void> _createTrialSubscription({
    required String email,
    required String displayName,
  }) async {
    final firestore = FirebaseFirestore.instance;

    // Hint: حساب تاريخ الانتهاء (+14 يوم من الآن)
    final now = DateTime.now();
    final endDate = now.add(const Duration(days: 14));

    // Hint: بنية subscription كاملة (متوافقة مع SubscriptionService)
    await firestore.collection('subscriptions').doc(email).set({
      'email': email,
      'displayName': displayName,

      // Hint: معلومات الخطة
      'plan': 'trial',
      'status': 'active',
      'isActive': true,

      // Hint: التواريخ (Firestore Timestamp للدقة)
      'startDate': Timestamp.fromDate(now),
      'endDate': Timestamp.fromDate(endDate),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),

      // Hint: إعدادات الأجهزة (Professional: 3 أجهزة للتجربة)
      'maxDevices': 3,
      'currentDevices': [], // Hint: سيمتلئ عند تسجيل الدخول

      // Hint: المميزات المتاحة في الفترة التجريبية
      'features': {
        'canCreateSubUsers': true,
        'maxSubUsers': 10,
        'canExportData': true,
        'canUseAdvancedReports': true,
        'supportPriority': 'standard',
      },

      // Hint: سجل الدفعات (فارغ للتجربة المجانية)
      'paymentHistory': [
        {
          'amount': 0,
          'currency': 'USD',
          'method': 'auto_trial',
          'paidAt': Timestamp.fromDate(now),
          'receiptUrl': null,
        }
      ],

      'notes': 'تفعيل تجريبي تلقائي - 14 يوم',
    });
  }

  /// Hint: عرض رسالة نجاح مع التعامل الصحيح للـ Navigation
  /// (تجنب الشاشة السوداء بعد الإنشاء)
  void _showSuccessDialog({required bool autoActivated}) {
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
        content: Text(
          autoActivated
              ? 'تم إنشاء الحساب بنجاح!\n\n'
                  '✅ تم تفعيل الاشتراك التجريبي لمدة 14 يوم.\n\n'
                  'يمكنك الآن تسجيل الدخول والبدء باستخدام التطبيق.'
              : 'تم إنشاء الحساب بنجاح!\n\n'
                  'يرجى التواصل مع المطور لتفعيل الاشتراك.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Hint: إغلاق Dialog

              // Hint: الانتقال لشاشة تسجيل الدخول مع حذف كل navigation stack
              // (يمنع الشاشة السوداء ويضمن navigation صحيح)
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginSelectionScreen(),
                ),
                (route) => false, // Hint: حذف كل الشاشات السابقة
              );
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
                        suffixIcon: _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        onSuffixIconPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
                        suffixIcon: _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        onSuffixIconPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
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

                      const SizedBox(height: AppConstants.spacingMd),

                      // فاصل
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingSm),
                            child: Text(
                              'أو',
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: AppConstants.spacingMd),

                      // زر تسجيل الدخول
                      CustomButton(
                        text: 'لدي حساب - تسجيل الدخول',
                        icon: Icons.login,
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginSelectionScreen(),
                            ),
                          );
                        },
                        type: ButtonType.secondary,
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
