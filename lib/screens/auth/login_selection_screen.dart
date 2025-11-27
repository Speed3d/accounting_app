// lib/screens/auth/login_selection_screen.dart

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_button.dart';
import 'owner_login_screen.dart';
import 'sub_user_login_screen.dart';

/// ============================================================================
/// شاشة اختيار نوع تسجيل الدخول
/// ============================================================================
/// الغرض:
/// - السماح للمستخدم بتحديد نوع الحساب للدخول
/// - Owner: تسجيل دخول بالإيميل (Firebase Auth)
/// - Sub User: تسجيل دخول بـ Username (محلي)
/// ============================================================================
class LoginSelectionScreen extends StatelessWidget {
  const LoginSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
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
              padding: const EdgeInsets.all(AppConstants.spacingXl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // الشعار/الأيقونة
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance,
                      size: 70,
                      color: AppColors.primaryLight,
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingXl),

                  // اسم التطبيق
                  Text(
                    'Accountant Touch',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                  ),

                  const SizedBox(height: AppConstants.spacingSm),

                  // وصف التطبيق
                  Text(
                    'نظام محاسبة احترافي',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                  ),

                  const SizedBox(height: AppConstants.spacingXl * 2),

                  // عنوان القسم
                  Text(
                    'اختر نوع الحساب',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: AppConstants.spacingLg),

                  // زر تسجيل دخول المالك (Owner)
                  _buildOwnerButton(context, l10n),

                  const SizedBox(height: AppConstants.spacingMd),

                  // فاصل "أو"
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingMd,
                        ),
                        child: Text(
                          'أو',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: AppConstants.spacingMd),

                  // زر تسجيل دخول الموظف (Sub User)
                  _buildSubUserButton(context, l10n),

                  const SizedBox(height: AppConstants.spacingXl),

                  // ملاحظة للمستخدمين الجدد
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
                            'المالك: يمتلك حساب بإيميل ويدير التطبيق\n'
                            'الموظف: حساب فرعي بصلاحيات محدودة',
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
    );
  }

  // ==========================================================================
  // بناء زر تسجيل دخول المالك
  // ==========================================================================

  Widget _buildOwnerButton(BuildContext context, AppLocalizations l10n) {
    return CustomButton(
      text: 'تسجيل دخول المالك',
      icon: Icons.business_center,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const OwnerLoginScreen(),
          ),
        );
      },
      type: ButtonType.primary,
      size: ButtonSize.large,
    );
  }

  // ==========================================================================
  // بناء زر تسجيل دخول الموظف
  // ==========================================================================

  Widget _buildSubUserButton(BuildContext context, AppLocalizations l10n) {
    return CustomButton(
      text: 'تسجيل دخول الموظف',
      icon: Icons.badge,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SubUserLoginScreen(),
          ),
        );
      },
      type: ButtonType.secondary,
      size: ButtonSize.large,
    );
  }
}
