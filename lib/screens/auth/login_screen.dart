// lib/screens/auth/login_screen.dart

import 'package:accountant_touch/layouts/main_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart'; // 🆕 للغات
import '../../services/device_service.dart'; // 🆕 للحصول على device fingerprint
import '../../services/session_service.dart';
import '../../services/subscription_service.dart'; // 🆕 للتحقق من الاشتراك
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'register_screen.dart';
import 'activation_screen.dart'; // 🆕 شاشة التفعيل (إذا كان الاشتراك منتهي)

/// ============================================================================
/// شاشة تسجيل الدخول - النظام الجديد المبسط
/// ============================================================================
///
/// ← Hint: النظام الجديد - Firebase Auth فقط (لا database queries!)
/// ← Hint: تسجيل دخول بالإيميل والباسوورد
/// ← Hint: 🆕 التحقق من الاشتراك بعد تسجيل الدخول
/// ← Hint: حفظ الجلسة في SessionService بعد النجاح
/// ← Hint: التوجيه مباشرة لـ MainScreen (إذا كان الاشتراك نشط)
/// ← Hint: التوجيه لـ ActivationScreen (إذا كان الاشتراك منتهي)
///
/// ============================================================================
class LoginScreen extends StatefulWidget {
  final String? companyName;
  final String? companyLogoPath;

  const LoginScreen({
    super.key,
    this.companyName,
    this.companyLogoPath,
  });

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

  /// ============================================================================
  /// 🆕 دالة تسجيل الدخول - محدثة مع التحقق من الاشتراك
  /// ============================================================================
  /// ← Hint: الخطوات:
  /// 1. تسجيل الدخول عبر Firebase Authentication
  /// 2. حفظ الجلسة في SessionService
  /// 3. 🆕 التحقق من الاشتراك في Firestore
  /// 4. التوجيه حسب حالة الاشتراك
  /// ============================================================================
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text;

      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('🔐 الخطوة 1/4: محاولة تسجيل الدخول: $email');
      debugPrint('═══════════════════════════════════════════════════════════');

      // ════════════════════════════════════════════════════════════════════
      // 1️⃣ تسجيل الدخول عبر Firebase Authentication
      // ← Hint: Firebase Auth هو المصدر الوحيد للحقيقة
      // ════════════════════════════════════════════════════════════════════
      final userCredential = await firebase_auth.FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('✅ الخطوة 1/4: تم تسجيل الدخول في Firebase Auth بنجاح');

      // ════════════════════════════════════════════════════════════════════
      // 2️⃣ حفظ الجلسة في SessionService
      // ← Hint: نستخدم البيانات من Firebase User مباشرة
      // ════════════════════════════════════════════════════════════════════
      debugPrint('💾 الخطوة 2/4: حفظ الجلسة في SessionService...');
      
      await SessionService.instance.saveSession(
        email: email,
        displayName: userCredential.user?.displayName ?? '',
        photoURL: userCredential.user?.photoURL,
      );

      debugPrint('✅ الخطوة 2/4: تم حفظ الجلسة بنجاح');

      // ════════════════════════════════════════════════════════════════════
      // 3️⃣ 🆕 التحقق من الاشتراك في Firestore
      // ← Hint: هنا نفحص صلاحية الاشتراك قبل السماح بالدخول
      // ════════════════════════════════════════════════════════════════════
      debugPrint('🔍 الخطوة 3/4: التحقق من الاشتراك في Firestore...');
      
      final subscriptionStatus = await SubscriptionService.instance
          .checkSubscription(email)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              // ← Hint: إذا فشل الاتصال بالإنترنت، نسمح بالدخول (fail-safe)
              // ← Hint: النظام يعمل محلياً، Firestore اختياري
              debugPrint('⏱️ Timeout في التحقق من الاشتراك - السماح بالدخول');
              return SubscriptionStatus.error(
                message: 'فشل الاتصال بخادم الاشتراكات',
              );
            },
          );

      debugPrint('✅ الخطوة 3/4: تم التحقق من الاشتراك');
      debugPrint('📊 حالة الاشتراك: ${subscriptionStatus.statusType}');

      if (!mounted) return;

      // ════════════════════════════════════════════════════════════════════
      // 4️⃣ التوجيه حسب حالة الاشتراك
      // ← Hint: نفحص نوع الحالة ونتخذ القرار المناسب
      // ════════════════════════════════════════════════════════════════════
      debugPrint('🧭 الخطوة 4/4: التوجيه حسب حالة الاشتراك...');

      // ────────────────────────────────────────────────────────────────────
      // ✅ الحالة 1: الاشتراك نشط وصالح
      // ────────────────────────────────────────────────────────────────────
      if (subscriptionStatus.isValid && subscriptionStatus.isActive) {
        debugPrint('✅ الاشتراك نشط - التوجيه لـ MainScreen');
        debugPrint('   Plan: ${subscriptionStatus.plan}');
        
        if (subscriptionStatus.endDate != null) {
          final daysRemaining = subscriptionStatus.endDate!
              .difference(DateTime.now())
              .inDays;
          debugPrint('   الأيام المتبقية: $daysRemaining يوم');
        }

        debugPrint('═══════════════════════════════════════════════════════════');
        debugPrint('🎉 تم تسجيل الدخول بنجاح!');
        debugPrint('═══════════════════════════════════════════════════════════');

        // ← Hint: التوجيه للشاشة الرئيسية
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
        return;
      }

      // ────────────────────────────────────────────────────────────────────
      // ❌ الحالة 2: الاشتراك منتهي
      // ────────────────────────────────────────────────────────────────────
      if (subscriptionStatus.isExpired) {
        debugPrint('❌ الاشتراك منتهي - التوجيه لـ ActivationScreen');
        debugPrint('═══════════════════════════════════════════════════════════');

        // ← Hint: إظهار رسالة تنبيه للمستخدم
        await _showSubscriptionExpiredDialog(
          email: email,
          endDate: subscriptionStatus.endDate,
        );
        return;
      }

      // ────────────────────────────────────────────────────────────────────
      // 🚫 الحالة 3: الاشتراك موقوف
      // ────────────────────────────────────────────────────────────────────
      if (subscriptionStatus.isSuspended) {
        debugPrint('🚫 الاشتراك موقوف - عرض رسالة');
        debugPrint('═══════════════════════════════════════════════════════════');

        _showErrorDialog(
          subscriptionStatus.message ?? 'تم إيقاف الاشتراك',
        );
        return;
      }

      // ────────────────────────────────────────────────────────────────────
      // 🔄 الحالة 4: يحتاج اتصال بالإنترنت
      // ────────────────────────────────────────────────────────────────────
      if (subscriptionStatus.requiresOnline) {
        final l10n = AppLocalizations.of(context)!;
        debugPrint('🌐 يحتاج التحقق عبر الإنترنت');
        debugPrint('═══════════════════════════════════════════════════════════');

        _showErrorDialog(l10n.login_online_check_required);
        return;
      }

      // ────────────────────────────────────────────────────────────────────
      // ⚠️ الحالة 5: لا يوجد اشتراك (مستخدم جديد)
      // ────────────────────────────────────────────────────────────────────
      if (subscriptionStatus.statusType == 'not_found') {
        debugPrint('⚠️ لا يوجد اشتراك - توجيه لشاشة التفعيل');
        debugPrint('═══════════════════════════════════════════════════════════');

        await _showNoSubscriptionDialog(email: email);
        return;
      }

      // ────────────────────────────────────────────────────────────────────
      // ⚠️ الحالة 6: خطأ في الاتصال (fail-safe - السماح بالدخول)
      // ────────────────────────────────────────────────────────────────────
      if (subscriptionStatus.statusType == 'error') {
        final l10n = AppLocalizations.of(context)!;
        debugPrint('⚠️ خطأ في التحقق من الاشتراك - السماح بالدخول (offline mode)');
        debugPrint('═══════════════════════════════════════════════════════════');

        // ← Hint: نعرض تنبيه بسيط ونسمح بالدخول
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.login_offline_mode_warning),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 3),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
        return;
      }

      // ────────────────────────────────────────────────────────────────────
      // 🔴 الحالة الافتراضية: حالة غير متوقعة
      // ────────────────────────────────────────────────────────────────────
      final l10n = AppLocalizations.of(context)!;
      debugPrint('🔴 حالة غير متوقعة: ${subscriptionStatus.statusType}');
      _showErrorDialog(l10n.login_unexpected_error);

    } on firebase_auth.FirebaseAuthException catch (e) {
      // ════════════════════════════════════════════════════════════════════
      // معالجة أخطاء Firebase Authentication
      // ════════════════════════════════════════════════════════════════════
      final l10n = AppLocalizations.of(context)!;
      String message = l10n.login_error_general;

      switch (e.code) {
        case 'user-not-found':
          message = l10n.login_error_user_not_found;
          break;
        case 'wrong-password':
          message = l10n.login_error_wrong_password;
          break;
        case 'invalid-email':
          message = l10n.login_error_invalid_email;
          break;
        case 'user-disabled':
          message = l10n.login_error_user_disabled;
          break;
        case 'network-request-failed':
          message = l10n.login_error_network;
          break;
        case 'too-many-requests':
          message = l10n.login_error_too_many_requests;
          break;
      }

      debugPrint('❌ خطأ Firebase Auth: ${e.code} - ${e.message}');
      if (mounted) _showErrorDialog(message);
    } catch (e, stackTrace) {
      debugPrint('❌ خطأ عام: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) _showErrorDialog('خطأ: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// ============================================================================
  /// 🆕 عرض رسالة "الاشتراك منتهي" مع التوجيه لشاشة التفعيل
  /// ============================================================================
  /// ← Hint: يُعرض عندما يكون الاشتراك منتهي
  /// ← Hint: يوفر زر للتوجيه لشاشة التفعيل
  /// ============================================================================
  Future<void> _showSubscriptionExpiredDialog({
    required String email,
    DateTime? endDate,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    
    return showDialog(
      context: context,
      barrierDismissible: false, // ← Hint: لا يمكن الإغلاق بالنقر خارجه
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppConstants.borderRadiusLg,
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: 28,
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Expanded(
              child: Text(
                l10n.login_subscription_expired_title,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getSubscriptionExpiredMessage(endDate: endDate),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Container(
              padding: AppConstants.paddingMd,
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: AppConstants.borderRadiusMd,
                border: Border.all(
                  color: AppColors.warning.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: AppConstants.spacingSm),
                  Expanded(
                    child: Text(
                      l10n.login_subscription_expired_info,
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // ← Hint: إغلاق الحوار
              // ← Hint: العودة لشاشة الدخول (المستخدم يبقى في LoginScreen)
            },
            child: Text(l10n.login_subscription_expired_cancel),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context); // ← Hint: إغلاق الحوار

              // ← Hint: الحصول على device fingerprint لشاشة التفعيل
              final deviceFingerprint = 
                  await DeviceService.instance.getDeviceFingerprint();

              // ← Hint: التوجيه لشاشة التفعيل
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActivationScreen(
                      l10n: AppLocalizations.of(context)!,
                      deviceFingerprint: deviceFingerprint,
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.vpn_key),
            label: Text(l10n.login_subscription_expired_renew),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
            ),
          ),
        ],
      ),
    );
  }

  /// ============================================================================
  /// 🆕 عرض رسالة "لا يوجد اشتراك" (مستخدم جديد)
  /// ============================================================================
  /// ← Hint: يُعرض عندما لا يوجد اشتراك في Firestore
  /// ← Hint: يوفر زر للتوجيه لشاشة التفعيل
  /// ============================================================================
  Future<void> _showNoSubscriptionDialog({required String email}) async {
    final l10n = AppLocalizations.of(context)!;
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppConstants.borderRadiusLg,
        ),
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: AppColors.info,
              size: 28,
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Expanded(
              child: Text(
                l10n.login_no_subscription_title,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.login_no_subscription_message),
            const SizedBox(height: AppConstants.spacingMd),
            Container(
              padding: AppConstants.paddingMd,
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: AppConstants.borderRadiusMd,
                border: Border.all(
                  color: AppColors.info.withOpacity(0.3),
                ),
              ),
              child: Text(
                l10n.login_no_subscription_info,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.login_no_subscription_cancel),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);

              // ← Hint: الحصول على device fingerprint لشاشة التفعيل
              final deviceFingerprint = 
                  await DeviceService.instance.getDeviceFingerprint();

              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActivationScreen(
                      l10n: AppLocalizations.of(context)!,
                      deviceFingerprint: deviceFingerprint,
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.vpn_key),
            label: Text(l10n.login_no_subscription_activate),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
            ),
          ),
        ],
      ),
    );
  }

  /// ← Hint: دالة مساعدة لتنسيق التاريخ
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// ← Hint: دالة مساعدة للحصول على رسالة انتهاء الاشتراك بناءً على اللغة
  String _getSubscriptionExpiredMessage({DateTime? endDate}) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'ar') {
      return endDate != null 
          ? 'انتهت صلاحية اشتراكك في ${_formatDate(endDate)}.'
          : 'انتهت صلاحية اشتراكك.';
    } else {
      return endDate != null 
          ? 'Your subscription expired on ${_formatDate(endDate)}.'
          : 'Your subscription expired.';
    }
  }

  /// ← Hint: دالة مساعدة للحصول على رسالة نسيت كلمة المرور بناءً على اللغة
  String _getForgotPasswordMessage(String email) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'ar') {
      return 'تم إرسال رابط استعادة كلمة المرور إلى:\n$email\n\nالرجاء التحقق من بريدك الإلكتروني.';
    } else {
      return 'Password reset link sent to:\n$email\n\nPlease check your email.';
    }
  }

  /// ← Hint: نسيت كلمة المرور - إرسال رابط الاستعادة عبر Firebase
  Future<void> _handleForgotPassword() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showErrorDialog(l10n.login_forgot_password_empty);
      return;
    }

    if (!email.contains('@')) {
      _showErrorDialog(l10n.login_forgot_password_invalid);
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
              Text(l10n.login_forgot_password_sent_title),
            ],
          ),
          content: Text(
            _getForgotPasswordMessage(email),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.login_forgot_password_sent_button),
            ),
          ],
        ),
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      String message = l10n.login_forgot_password_error_general;

      switch (e.code) {
        case 'user-not-found':
          message = l10n.login_forgot_password_error_user_not_found;
          break;
        case 'invalid-email':
          message = l10n.login_forgot_password_error_invalid;
          break;
        case 'network-request-failed':
          message = l10n.login_forgot_password_error_network;
          break;
      }

      if (mounted) _showErrorDialog(message);
    }
  }

  void _showErrorDialog(String message) {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: AppConstants.spacingSm),
            Text(l10n.login_error_dialog_title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.login_error_button),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.login_screen_title)),
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
                      // شعار الشركة أو أيقونة افتراضية
                      if (widget.companyLogoPath != null)
                        Image.asset(
                          widget.companyLogoPath!,
                          height: 100,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.account_circle,
                            size: 100,
                            color: AppColors.primaryLight,
                          ),
                        )
                      else
                        Icon(
                          Icons.account_circle,
                          size: 100,
                          color: AppColors.primaryLight,
                        ),

                      const SizedBox(height: AppConstants.spacingXl),

                      // اسم الشركة أو عنوان افتراضي
                      Text(
                        widget.companyName ?? l10n.login_screen_title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),

                      const SizedBox(height: AppConstants.spacingSm),

                      Text(
                        l10n.login_welcome_back,
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
                        label: l10n.login_email_label,
                        hint: l10n.login_email_hint,
                        prefixIcon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.isEmpty) return l10n.login_validation_required;
                          if (!v.contains('@')) return l10n.login_validation_email_invalid;
                          return null;
                        },
                      ),

                      const SizedBox(height: AppConstants.spacingMd),

                      // كلمة المرور
                      CustomTextField(
                        controller: _passwordController,
                        label: l10n.login_password_label,
                        hint: l10n.login_password_hint,
                        prefixIcon: Icons.lock,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        suffixIcon: _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        onSuffixIconPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                        validator: (v) {
                          if (v == null || v.isEmpty) return l10n.login_validation_required;
                          return null;
                        },
                      ),

                      const SizedBox(height: AppConstants.spacingSm),

                      // نسيت كلمة المرور
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _handleForgotPassword,
                          child: Text(l10n.login_forgot_password, 
                              style: Theme.of(context).textTheme.headlineSmall),
                        ),
                      ),

                      const SizedBox(height: AppConstants.spacingLg),

                      // زر تسجيل الدخول
                      CustomButton(
                        text: l10n.login_button_text,
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
                              l10n.login_divider_text,
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
                        text: l10n.login_no_account_button,
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