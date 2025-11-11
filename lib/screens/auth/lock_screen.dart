// lib/screens/auth/lock_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/database_helper.dart';
import '../../services/app_lock_service.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'login_screen.dart';

/// 🔒 شاشة القفل
class LockScreen extends StatefulWidget {
  final bool canGoBack;

  const LockScreen({
    super.key,
    this.canGoBack = false,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  // ← Hint: متغيرات النموذج
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();

  // ← Hint: متغيرات الحالة
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isBiometricLoading = false;
  int _failedAttempts = 0;
  bool _isLockedOut = false;
  DateTime? _lockoutEndTime;

  // ← Hint: متغيرات معلومات الشركة
  String _companyName = '';
  File? _companyLogo;
  String _lastActiveTime = '';

  final dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _calculateLastActiveTime();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // ← Hint: تحميل إعدادات الشركة
  // ==========================================================================
  Future<void> _loadSettings() async {
    try {
      final settings = await dbHelper.getAppSettings();
      
      if (mounted) {
        setState(() {
          _companyName = settings['companyName'] ?? 'التطبيق';
          
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

  // ==========================================================================
  // ← Hint: حساب وقت آخر نشاط
  // ==========================================================================
  Future<void> _calculateLastActiveTime() async {
    final l10n = AppLocalizations.of(context)!;
    
    try {
      // ← Hint: هذه دالة مساعدة - سنستخدم المنطق المباشر
      final lockService = AppLockService.instance;
      setState(() {
        _lastActiveTime = l10n.fewMinutesAgo; // افتراضي
      });
    } catch (e) {
      debugPrint('❌ خطأ في حساب الوقت: $e');
    }
  }

  // ==========================================================================
  // ← Hint: التحقق من كلمة المرور
  // ==========================================================================
  Future<void> _handleUnlock() async {
    final l10n = AppLocalizations.of(context)!;

    if (_isLockedOut) {
      _showLockoutMessage(l10n);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final password = _passwordController.text;

      final isValid = authService.verifyPassword(password);

      if (isValid) {
        // ← Hint: نجح التحقق
        await AppLockService.instance.unlockApp();
        
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        // ← Hint: فشل التحقق
        _handleFailedAttempt(l10n);
      }
    } catch (e) {
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==========================================================================
  // ← Hint: معالجة المحاولات الفاشلة
  // ==========================================================================
  void _handleFailedAttempt(AppLocalizations l10n) {
    setState(() {
      _failedAttempts++;
      _passwordController.clear();
    });

    if (_failedAttempts >= 5) {
      // ← Hint: قفل مؤقت لمدة 30 ثانية
      setState(() {
        _isLockedOut = true;
        _lockoutEndTime = DateTime.now().add(const Duration(seconds: 30));
      });

      Future.delayed(const Duration(seconds: 30), () {
        if (mounted) {
          setState(() {
            _isLockedOut = false;
            _failedAttempts = 0;
          });
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.tooManyAttempts),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.wrongPassword} (${5 - _failedAttempts} ${l10n.attemptsRemaining})'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ==========================================================================
  // ← Hint: عرض رسالة القفل المؤقت
  // ==========================================================================
  void _showLockoutMessage(AppLocalizations l10n) {
    if (_lockoutEndTime == null) return;

    final remaining = _lockoutEndTime!.difference(DateTime.now()).inSeconds;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${l10n.lockedOut} $remaining ${l10n.seconds}'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================================================
  // ← Hint: التحقق بالبصمة
  // ==========================================================================
  Future<void> _handleBiometricUnlock() async {
    final l10n = AppLocalizations.of(context)!;

    if (_isLockedOut) {
      _showLockoutMessage(l10n);
      return;
    }

    setState(() => _isBiometricLoading = true);

    try {
      final result = await BiometricService.instance.authenticateWithBiometric();

      if (!mounted) return;

      if (result['success'] == true) {
        await AppLockService.instance.unlockApp();
        Navigator.of(context).pop(true);
      } else {
        final isEmulatorError = result['isEmulatorError'] == true;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: isEmulatorError ? AppColors.warning : AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
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
      if (mounted) {
        setState(() => _isBiometricLoading = false);
      }
    }
  }

  // ==========================================================================
  // ← Hint: تسجيل الخروج
  // ==========================================================================
  Future<void> _handleLogout() async {
    final l10n = AppLocalizations.of(context)!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    AuthService().logout();
    await AppLockService.instance.reset();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => LoginScreen(l10n: l10n),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async => widget.canGoBack,
      child: Scaffold(
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
                child: _buildLockForm(l10n, isDark),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockForm(AppLocalizations l10n, bool isDark) {
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
          children: [
            // ← Hint: أيقونة القفل
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                size: 64,
                color: AppColors.error,
              ),
            ),

            const SizedBox(height: AppConstants.spacingLg),

            // ← Hint: العنوان
            Text(
              l10n.appLocked,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppConstants.spacingSm),

            // ← Hint: الوصف
            Text(
              l10n.appLockedDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark 
                  ? AppColors.textSecondaryDark 
                  : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppConstants.spacingXs),

            // ← Hint: آخر نشاط
            Text(
              '${l10n.lastActive}: $_lastActiveTime',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppConstants.spacingXl),

            // ← Hint: حقل كلمة المرور
            CustomTextField(
              controller: _passwordController,
              label: l10n.password,
              hint: l10n.enterPassword,
              prefixIcon: Icons.lock_outline,
              obscureText: !_isPasswordVisible,
              enabled: !_isLockedOut,
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

            const SizedBox(height: AppConstants.spacingLg),

            // ← Hint: زر فتح القفل
            CustomButton(
              text: l10n.unlock,
              icon: Icons.lock_open,
              onPressed: _isLockedOut ? null : _handleUnlock,
              isLoading: _isLoading,
              type: ButtonType.primary,
              size: ButtonSize.large,
            ),

            // ← Hint: زر البصمة (إذا مُفعّلة)
            if (BiometricService.instance.isBiometricEnabled) ...[
              const SizedBox(height: AppConstants.spacingMd),

              Row(
                children: [
                  Expanded(child: Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingMd),
                    child: Text(l10n.or, style: Theme.of(context).textTheme.bodySmall),
                  ),
                  Expanded(child: Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                ],
              ),

              const SizedBox(height: AppConstants.spacingMd),

              CustomButton(
                text: l10n.unlockWithBiometric,
                icon: Icons.fingerprint,
                onPressed: _isLockedOut ? null : _handleBiometricUnlock,
                isLoading: _isBiometricLoading,
                type: ButtonType.secondary,
                size: ButtonSize.large,
              ),
            ],

            const SizedBox(height: AppConstants.spacingXl),

            // ← Hint: زر تسجيل الخروج
            TextButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, size: 18),
              label: Text(l10n.logout),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}