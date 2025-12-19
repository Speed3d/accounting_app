// lib/screens/settings/profile_settings_screen.dart

import 'package:accountant_touch/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';

import '../../services/session_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

/// ============================================================================
/// شاشة تعديل الملف الشخصي - النظام الجديد
/// ============================================================================
///
/// ← Hint: تسمح للمستخدم بتعديل:
/// ← 1. الاسم الكامل (displayName) عبر Firebase Auth
/// ← 2. كلمة المرور عبر Firebase Auth
/// ← Hint: لا توجد صلاحيات أو أنواع مستخدمين (كل مستخدم = Owner/Admin)
///
/// ============================================================================
class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _nameFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoadingName = false;
  bool _isLoadingPassword = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  String _currentEmail = '';
  String _currentDisplayName = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// ← Hint: تحميل معلومات المستخدم من SessionService
  Future<void> _loadUserInfo() async {
    try {
      final email = await SessionService.instance.getEmail();
      final displayName = await SessionService.instance.getDisplayName();

      setState(() {
        _currentEmail = email ?? '';
        _currentDisplayName = displayName ?? '';
        _nameController.text = _currentDisplayName;
      });
    } catch (e) {
      debugPrint('❌ خطأ في تحميل معلومات المستخدم: $e');
    }
  }

  /// ← Hint: تحديث الاسم في Firebase Auth + SessionService
  Future<void> _handleUpdateName() async {
    if (!_nameFormKey.currentState!.validate()) return;

    setState(() => _isLoadingName = true);

    try {
      final newName = _nameController.text.trim();

      debugPrint('🔄 تحديث الاسم إلى: $newName');

      // 1️⃣ Hint: تحديث الاسم في Firebase Auth
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      final l10n = AppLocalizations.of(context)!;
      if (user == null) {
        throw Exception(l10n.userNotFound);
      }

      await user.updateDisplayName(newName);
      await user.reload(); // ← Hint: إعادة تحميل المستخدم للحصول على البيانات الجديدة

      debugPrint('✅ تم تحديث الاسم في Firebase Auth');

      // 2️⃣ Hint: تحديث الاسم في SessionService (المخزن المحلي)
      await SessionService.instance.updateDisplayName(newName);

      debugPrint('✅ تم تحديث الاسم في SessionService');

      if (!mounted) return;

      // 3️⃣ Hint: عرض رسالة نجاح
      _showSuccessDialog(l10n.nameUpdatedSuccess);

      setState(() {
        _currentDisplayName = newName;
      });
    } on firebase_auth.FirebaseAuthException catch (e) {
      final l10n = AppLocalizations.of(context)!;
      String message = l10n.nameUpdateError;

      switch (e.code) {
        case 'network-request-failed':
          message = l10n.internetError;
          break;
      }

      debugPrint('❌ خطأ Firebase Auth: ${e.code} - ${e.message}');
      if (mounted) _showErrorDialog(message);
    } catch (e) {
      debugPrint('❌ خطأ عام: $e');
      if (mounted) _showErrorDialog('خطأ: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoadingName = false);
    }
  }

  /// ← Hint: تغيير كلمة المرور عبر Firebase Auth
  Future<void> _handleChangePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _isLoadingPassword = true);

    try {
      final currentPassword = _currentPasswordController.text;
      final newPassword = _newPasswordController.text;

      debugPrint('🔐 محاولة تغيير كلمة المرور');

      // 1️⃣ Hint: إعادة المصادقة أولاً (Firebase يطلب ذلك لتغيير الباسوورد)
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      final l10n = AppLocalizations.of(context)!;
      if (user == null || user.email == null) {
        throw Exception(l10n.userNotFound);
      }

      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      debugPrint('✅ تمت إعادة المصادقة بنجاح');

      // 2️⃣ Hint: تحديث كلمة المرور
      await user.updatePassword(newPassword);

      debugPrint('✅ تم تحديث كلمة المرور بنجاح');

      if (!mounted) return;

      // 3️⃣ Hint: عرض رسالة نجاح
      _showSuccessDialog('تم تغيير كلمة المرور بنجاح!');

      // 4️⃣ Hint: مسح الحقول
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } on firebase_auth.FirebaseAuthException catch (e) {
      final l10n = AppLocalizations.of(context)!;
      String message = l10n.passwordChangedSuccess;

      switch (e.code) {
        case 'wrong-password':
          message = l10n.currentPasswordWrong;
          break;
        case 'weak-password':
          message = l10n.newPasswordWeak;
          break;
        case 'requires-recent-login':
          message = l10n.reloginRequired;
          break;
        case 'network-request-failed':
          message = l10n.internetError;
          break;
      }

      debugPrint('❌ خطأ Firebase Auth: ${e.code} - ${e.message}');
      if (mounted) _showErrorDialog(message);
    } catch (e) {
      debugPrint('❌ خطأ عام: $e');
      if (mounted) _showErrorDialog('خطأ: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoadingPassword = false);
    }
  }

  void _showSuccessDialog(String message) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: AppConstants.spacingSm),
            Text(l10n.success),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:  Text(l10n.ok),
          ),
        ],
      ),
    );
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
             Text(l10n.error),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:  Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title:  Text(l10n.profileuser),
      ),
      body: ListView(
        padding: AppConstants.screenPadding,
        children: [
          const SizedBox(height: AppConstants.spacingLg),

          // ============= معلومات المستخدم الحالية =============
          _buildUserInfoCard(isDark),

          const SizedBox(height: AppConstants.spacingXl),

          // ============= تعديل الاسم =============
          _buildSectionHeader(l10n.editName, Icons.person_outline, isDark),
          const SizedBox(height: AppConstants.spacingSm),
          _buildNameForm(),

          const SizedBox(height: AppConstants.spacingXl),

          // ============= تغيير كلمة المرور =============
          _buildSectionHeader(l10n.changePassword, Icons.lock_outline, isDark),
          const SizedBox(height: AppConstants.spacingSm),
          _buildPasswordForm(),

          const SizedBox(height: AppConstants.spacingXl),
        ],
      ),
    );
  }

  /// ← Hint: عرض معلومات المستخدم الحالية
  Widget _buildUserInfoCard(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: AppConstants.paddingLg,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: AppConstants.borderRadiusLg,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          // صورة المستخدم (أيقونة افتراضية)
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight.withOpacity(0.1),
              border: Border.all(
                color: AppColors.primaryLight,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.person,
              size: 40,
              color: AppColors.primaryLight,
            ),
          ),

          const SizedBox(height: AppConstants.spacingMd),

          // الاسم
          Text(
            _currentDisplayName.isNotEmpty ? _currentDisplayName : l10n.user,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppConstants.spacingSm),

          // البريد الإلكتروني
          Text(
            _currentEmail,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppConstants.spacingSm),

          // شارة Admin
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.1),
              borderRadius: AppConstants.borderRadiusFull,
              border: Border.all(
                color: AppColors.primaryLight,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  size: 16,
                  color: AppColors.primaryLight,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.admin,
                  style: TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ← Hint: عنوان القسم
  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
        const SizedBox(width: AppConstants.spacingSm),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  /// ← Hint: نموذج تعديل الاسم
  Widget _buildNameForm() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: AppConstants.paddingLg,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.cardDark
            : AppColors.cardLight,
        borderRadius: AppConstants.borderRadiusLg,
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.borderDark
              : AppColors.borderLight,
        ),
      ),
      child: Form(
        key: _nameFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomTextField(
              controller: _nameController,
              label: l10n.fullName,
              hint: l10n.sinanayad,
              prefixIcon: Icons.person,
              textInputAction: TextInputAction.done,
              validator: (v) {
                if (v == null || v.isEmpty) return l10n.requiredd;
                if (v.length < 2) return l10n.nameTooShort;
                return null;
              },
            ),

            const SizedBox(height: AppConstants.spacingLg),

            CustomButton(
              text: l10n.saveName,
              icon: Icons.save,
              onPressed: _handleUpdateName,
              isLoading: _isLoadingName,
              type: ButtonType.primary,
              size: ButtonSize.large,
            ),
          ],
        ),
      ),
    );
  }

  /// ← Hint: نموذج تغيير كلمة المرور
  Widget _buildPasswordForm() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: AppConstants.paddingLg,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.cardDark
            : AppColors.cardLight,
        borderRadius: AppConstants.borderRadiusLg,
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.borderDark
              : AppColors.borderLight,
        ),
      ),
      child: Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // كلمة المرور الحالية
            CustomTextField(
              controller: _currentPasswordController,
              label: l10n.currentPassword,
              hint: '••••••••',
              prefixIcon: Icons.lock,
              obscureText: _obscureCurrentPassword,
              textInputAction: TextInputAction.next,
              suffixIcon: _obscureCurrentPassword
                  ? Icons.visibility
                  : Icons.visibility_off,
              onSuffixIconPressed: () => setState(
                  () => _obscureCurrentPassword = !_obscureCurrentPassword),
              validator: (v) {
                if (v == null || v.isEmpty) return l10n.requiredd;
                return null;
              },
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // كلمة المرور الجديدة
            CustomTextField(
              controller: _newPasswordController,
              label: l10n.newPassword,
              hint: '••••••••',
              prefixIcon: Icons.lock_outline,
              obscureText: _obscureNewPassword,
              textInputAction: TextInputAction.next,
              suffixIcon:
                  _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
              onSuffixIconPressed: () =>
                  setState(() => _obscureNewPassword = !_obscureNewPassword),
              validator: (v) {
                if (v == null || v.isEmpty) return l10n.requiredd;
                if (v.length < 6) return l10n.passwordMinLength;
                return null;
              },
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // تأكيد كلمة المرور
            CustomTextField(
              controller: _confirmPasswordController,
              label: l10n.confirmNewPassword,
              hint: '••••••••',
              prefixIcon: Icons.lock_outline,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              suffixIcon: _obscureConfirmPassword
                  ? Icons.visibility
                  : Icons.visibility_off,
              onSuffixIconPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
              validator: (v) {
                if (v == null || v.isEmpty) return l10n.requiredd;
                if (v != _newPasswordController.text) return l10n.passwordsNotMatch;
                return null;
              },
            ),

            const SizedBox(height: AppConstants.spacingLg),

            CustomButton(
              text: l10n.changePassword,
              icon: Icons.vpn_key,
              onPressed: _handleChangePassword,
              isLoading: _isLoadingPassword,
              type: ButtonType.primary,
              size: ButtonSize.large,
            ),
          ],
        ),
      ),
    );
  }
}
