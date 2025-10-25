// lib/screens/settings/settings_screen.dart

import 'package:accounting_app/screens/archive/archive_center_screen.dart';
import 'package:accounting_app/screens/settings/about_screen.dart';
import 'package:accounting_app/screens/settings/backup_restore_screen.dart';
import 'package:accounting_app/screens/settings/company_info_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';

/// 🎨 شاشة الإعدادات - صفحة فرعية
/// Hint: نستخدم Scaffold عادي لأنها ليست من الصفحات الرئيسية الأربعة
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // ============= AppBar بسيط مع سهم رجوع =============
      appBar: AppBar(
        title: Text(l10n.settings),
        // سهم الرجوع يظهر تلقائياً
      ),

      // ============= المحتوى =============
      body: ListView(
        padding: AppConstants.screenPadding,
        children: [
          const SizedBox(height: AppConstants.spacingMd),

          // ============================================================
          // 🎨 قسم المظهر
          // ============================================================
          _buildSectionHeader(
            context,
            title: 'المظهر',
            icon: Icons.palette_outlined,
            isDark: isDark,
          ),
          const SizedBox(height: AppConstants.spacingSm),
          
          _SettingsCard(
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return _buildThemeTile(context, themeProvider);
              },
            ),
          ),
          
          const SizedBox(height: AppConstants.spacingLg),

          // ============================================================
          // 🌍 قسم اللغة
          // ============================================================
          _buildSectionHeader(
            context,
            title: l10n.language,
            icon: Icons.translate,
            isDark: isDark,
          ),
          const SizedBox(height: AppConstants.spacingSm),
          
          _SettingsCard(
            child: Consumer<LocaleProvider>(
              builder: (context, localeProvider, child) {
                return _buildLanguageTile(context, localeProvider, l10n);
              },
            ),
          ),
          
          const SizedBox(height: AppConstants.spacingLg),

          // ============================================================
          // 📊 قسم إدارة البيانات
          // ============================================================
          _buildSectionHeader(
            context,
            title: l10n.dataManagement,
            icon: Icons.storage_outlined,
            isDark: isDark,
          ),
          const SizedBox(height: AppConstants.spacingSm),
          
          _SettingsCard(
            child: Column(
              children: [
                _SettingsLinkTile(
                  title: l10n.companyInformation,
                  subtitle: l10n.changeAppNameAndLogo,
                  icon: Icons.business_outlined,
                  iconColor: AppColors.info,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CompanyInfoScreen(),
                      ),
                    );
                  },
                ),
                
                _buildDivider(isDark),
                
                _SettingsLinkTile(
                  title: l10n.backupAndRestore,
                  subtitle: l10n.saveAndRestoreAppData,
                  icon: Icons.backup_outlined,
                  iconColor: AppColors.success,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BackupRestoreScreen(),
                      ),
                    );
                  },
                ),

                  _SettingsLinkTile(
                  title: l10n.archive,
                  subtitle: l10n.archiveCenter,
                  icon: Icons.archive,
                  iconColor: AppColors.info,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ArchiveCenterScreen(),
                      ),
                    );
                  },
                ),
                
                _buildDivider(isDark),

              ],
            ),
          ),

          // --- مساحة إضافية في الأسفل ---
          const SizedBox(height: AppConstants.spacingXl),

          // ============================================================
          //  قسم حول
          // ============================================================
          _buildSectionHeader(
            context,
            title: l10n.about,
            icon: Icons.storage_outlined,
            isDark: isDark,
          ),
          const SizedBox(height: AppConstants.spacingSm),
          
          _SettingsCard(
            child: Column(
              children: [
                _SettingsLinkTile(
                  title: l10n.about,
                  subtitle: l10n.aboutTheApp,
                  icon: Icons.info_outline,
                  iconColor: AppColors.info,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AboutScreen(),
                      ),
                    );
                  },
                ),
                
                // _buildDivider(isDark),

              ],
            ),
          ),

          const SizedBox(height: AppConstants.spacingXl),

          // 📌 معلومات الإصدار
          _buildVersionInfo(context, isDark),
          
          const SizedBox(height: AppConstants.spacingXl),
        ],
      ),
    );
  }

  // ============================================================
  // 🎨 بناء رأس القسم مع أيقونة
  // ============================================================
  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingSm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                  .withOpacity(0.1),
              borderRadius: AppConstants.borderRadiusSm,
            ),
            child: Icon(
              icon,
              size: 16,
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            ),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🌓 بناء خيار تبديل الثيم
  // ============================================================
  Widget _buildThemeTile(BuildContext context, ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.primaryDark.withOpacity(0.05),
                  AppColors.secondaryDark.withOpacity(0.05),
                ]
              : [
                  AppColors.primaryLight.withOpacity(0.05),
                  AppColors.secondaryLight.withOpacity(0.05),
                ],
        ),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMd,
          vertical: AppConstants.spacingSm,
        ),
        title: Text(
          'الوضع الليلي',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Text(
          isDark
              ? 'مفعّل - العيون مرتاحة 😌'
              : 'معطّل - استمتع بالنور ☀️',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        secondary: Container(
          padding: const EdgeInsets.all(AppConstants.spacingSm),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.primaryDark.withOpacity(0.2)
                : AppColors.primaryLight.withOpacity(0.2),
            borderRadius: AppConstants.borderRadiusMd,
          ),
          child: Icon(
            isDark ? Icons.dark_mode : Icons.light_mode,
            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
          ),
        ),
        value: isDark,
        onChanged: (value) {
          themeProvider.toggleTheme();
        },
      ),
    );
  }

  // ============================================================
  // 🌍 بناء خيار تغيير اللغة
  // ============================================================
  Widget _buildLanguageTile(
    BuildContext context,
    LocaleProvider localeProvider,
    AppLocalizations l10n,
  ) {
    final currentLocale = localeProvider.locale;
    final isArabic = currentLocale?.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      leading: Container(
        padding: const EdgeInsets.all(AppConstants.spacingSm),
        decoration: BoxDecoration(
          color: AppColors.info.withOpacity(0.1),
          borderRadius: AppConstants.borderRadiusMd,
        ),
        child: const Icon(
          Icons.language_outlined,
          color: AppColors.info,
        ),
      ),
      title: Text(
        l10n.changeLanguage,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: Row(
        children: [
          Icon(
            isArabic ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: isArabic ? AppColors.success : AppColors.textSecondaryLight,
          ),
          const SizedBox(width: 4),
          Text(
            isArabic ? 'العربية' : 'English',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isArabic ? AppColors.success : null,
                  fontWeight: isArabic ? FontWeight.w600 : null,
                ),
          ),
        ],
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      ),
      onTap: () {
        // تبديل اللغة
        final newLocale = isArabic
            ? const Locale('en')
            : const Locale('ar');
        localeProvider.setLocale(newLocale);

        // إظهار رسالة تأكيد جميلة
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: AppConstants.spacingSm),
                Text(
                  isArabic
                      ? 'Language changed to English'
                      : 'تم تغيير اللغة إلى العربية',
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  // ============================================================
  // 📏 بناء خط فاصل
  // ============================================================
  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
    );
  }

  // ============================================================
  // ℹ️ معلومات الإصدار
  // ============================================================
  Widget _buildVersionInfo(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.code,
            size: 32,
            color: isDark
                ? AppColors.textHintDark
                : AppColors.textHintLight,
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            'نظام المحاسبة الذكي',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppConstants.spacingXs),
          Text(
            'الإصدار 1.0.0',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textHintDark
                      : AppColors.textHintLight,
                ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 📋 ويدجت بطاقة الإعدادات
// ============================================================
class _SettingsCard extends StatelessWidget {
  final Widget child;

  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      child: child,
    );
  }
}

// ============================================================
// 🔗 ويدجت عنصر قائمة ينقلك لصفحة أخرى
// ============================================================
class _SettingsLinkTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _SettingsLinkTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      leading: Container(
        padding: const EdgeInsets.all(AppConstants.spacingSm),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: AppConstants.borderRadiusMd,
        ),
        child: Icon(
          icon,
          size: 22,
          color: iconColor,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      ),
      onTap: onTap,
    );
  }
}