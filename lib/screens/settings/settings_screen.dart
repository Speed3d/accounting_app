import 'package:accounting_app/screens/settings/backup_restore_screen.dart';
import 'package:accounting_app/screens/settings/company_info_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_constants.dart';
import '../../layouts/main_layout.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MainLayout(
      title: l10n.settings,
      currentIndex: 3, // المزيد
      showBottomNav: true,
      body: ListView(
        padding: AppConstants.screenPadding,
        children: [
          const SizedBox(height: AppConstants.spacingMd),
          
          // ============================================================
          // --- قسم المظهر ---
          // ============================================================
          _SectionTitle(title: 'المظهر'),
          const SizedBox(height: AppConstants.spacingSm),
          
          _SettingsCard(
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return SwitchListTile(
                  title: Text(
                    'الوضع الليلي',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'تفعيل أو إيقاف المظهر الداكن',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  secondary: Icon(
                    themeProvider.isDarkMode 
                        ? Icons.dark_mode 
                        : Icons.light_mode,
                  ),
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                );
              },
            ),
          ),
          
          const SizedBox(height: AppConstants.spacingLg),

          // ============================================================
          // --- قسم اللغة ---
          // ============================================================
          _SectionTitle(title: l10n.language),
          const SizedBox(height: AppConstants.spacingSm),
          
          _SettingsCard(
            child: Consumer<LocaleProvider>(
              builder: (context, localeProvider, child) {
                final currentLocale = localeProvider.locale;
                final isArabic = currentLocale?.languageCode == 'ar';
                
                return ListTile(
                  leading: const Icon(Icons.language_outlined),
                  title: Text(
                    l10n.changeLanguage,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    isArabic ? 'العربية' : 'English',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // تبديل اللغة
                    final newLocale = isArabic 
                        ? const Locale('en') 
                        : const Locale('ar');
                    localeProvider.setLocale(newLocale);
                    
                    // إظهار رسالة تأكيد
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isArabic 
                              ? 'Language changed to English' 
                              : 'تم تغيير اللغة إلى العربية',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          const SizedBox(height: AppConstants.spacingLg),

          // ============================================================
          // --- قسم إدارة البيانات ---
          // ============================================================
          _SectionTitle(title: l10n.dataManagement),
          const SizedBox(height: AppConstants.spacingSm),
          
          _SettingsCard(
            child: Column(
              children: [
                _SettingsLinkTile(
                  title: l10n.companyInformation,
                  subtitle: l10n.changeAppNameAndLogo,
                  icon: Icons.business_outlined,
                  onTap: () { () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CompanyInfoScreen(),
                      ),
                    );
                  },
                ),
                
                const Divider(height: 1),
                _SettingsLinkTile(
                  title: l10n.archiveCenter,
                  subtitle: l10n.restoreArchivedItems,
                  icon: Icons.archive_outlined,
                  onTap: () { () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ArchiveCenterScreen(),
                      ),
                    );
                  },
                ),

                const Divider(height: 1),
                _SettingsLinkTile(
                  title: l10n.backupAndRestore,
                  subtitle: l10n.saveAndRestoreAppData,
                  icon: Icons.storage_outlined,
                  onTap: () { () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BackupRestoreScreen(),
                      ),
                    );
                  },
                ),
          
          const SizedBox(height: AppConstants.spacingLg),

          // ============================================================
          // --- قسم حول التطبيق ---
          // ============================================================
          _SectionTitle(title: l10n.about),
          const SizedBox(height: AppConstants.spacingSm),
          
          // --- حول التطبيق ---
          _SettingsLinkTile(
            title: l10n.aboutTheApp,
            subtitle: "معلومات التطبيق والمطور",
            icon: Icons.info_outline,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AboutScreen(),
              ),
            ),
          ),

          // --- مساحة إضافية في الأسفل ---
          const SizedBox(height: AppConstants.spacingXl),
        ],
      ),
    );
  }
}

// ============================================================
// --- ويدجت عنوان القسم ---
// ============================================================
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingSm),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ============================================================
// --- ويدجت بطاقة الإعدادات ---
// ============================================================
class _SettingsCard extends StatelessWidget {
  final Widget child;
  
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: child,
    );
  }
}

// ============================================================
// --- ويدجت عنصر قائمة ينقلك لصفحة أخرى ---
// ============================================================
class _SettingsLinkTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _SettingsLinkTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}