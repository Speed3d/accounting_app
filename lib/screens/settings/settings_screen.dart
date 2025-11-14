// lib/screens/settings/settings_screen.dart

import 'package:accounting_app/screens/archive/archive_center_screen.dart';
import 'package:accounting_app/screens/settings/about_screen.dart';
import 'package:accounting_app/screens/settings/app_lock_settings_screen.dart'; // ← Hint: إضافة استيراد إعدادات القفل
import 'package:accounting_app/screens/settings/backup_restore_screen.dart';
import 'package:accounting_app/screens/settings/company_info_screen.dart';
import 'package:accounting_app/services/biometric_service.dart';
import 'package:accounting_app/services/currency_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';

/// 🎨 شاشة الإعدادات - صفحة فرعية
/// ← Hint: هذه الشاشة تعرض جميع إعدادات التطبيق مقسمة إلى أقسام
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ← Hint: متغير لتتبع حالة البصمة
  bool _isBiometricEnabled = false;

  @override
  void initState() {
    super.initState();
    // ← Hint: تحميل حالة البصمة عند بناء الصفحة
    _isBiometricEnabled = BiometricService.instance.isBiometricEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),

      body: ListView(
        padding: AppConstants.screenPadding,
        children: [
          const SizedBox(height: AppConstants.spacingMd),

          // ============================================================
          // 🎨 قسم المظهر
          // ← Hint: يحتوي على تبديل الثيم (فاتح/داكن)
          // ============================================================
          _buildSectionHeader(
            context,
            title: l10n.appearance,
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
          // ← Hint: يحتوي على تبديل اللغة (عربي/إنجليزي)
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
          // 💰 قسم العملة
          // ← Hint: يحتوي على اختيار العملة (دولار، دينار، إلخ)
          // ============================================================
          _buildSectionHeader(
            context,
            title: l10n.currency,
            icon: Icons.attach_money,
            isDark: isDark,
          ),
          const SizedBox(height: AppConstants.spacingSm),
          
          _SettingsCard(
            child: _buildCurrencyTile(context, l10n, isDark),
          ),
          
          const SizedBox(height: AppConstants.spacingLg),

          // ============================================================
          // 🔐 قسم الأمان والخصوصية
          // ← Hint: يحتوي على البصمة والقفل التلقائي
          // ============================================================
          _buildSectionHeader(
            context,
            title: l10n.security,
            icon: Icons.security,
            isDark: isDark,
          ),
          const SizedBox(height: AppConstants.spacingSm),
          
          _SettingsCard(
            child: Column(
              children: [
                // ← Hint: خيار تفعيل/إيقاف البصمة
                _buildBiometricTile(context, l10n, isDark),
                
                _buildDivider(isDark),
                
                // ← Hint: رابط لصفحة إعدادات القفل التلقائي (جديد)
                _SettingsLinkTile(
                  title: l10n.appLockSettings,
                  subtitle: l10n.appLockSettingsDescription,
                  icon: Icons.lock_clock,
                  iconColor: AppColors.warning,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AppLockSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppConstants.spacingLg),

          // ============================================================
          // 📊 قسم إدارة البيانات
          // ← Hint: يحتوي على معلومات الشركة، النسخ الاحتياطي، الأرشفة
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
                // ← Hint: رابط لصفحة معلومات الشركة
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
                
                // ← Hint: رابط لصفحة النسخ الاحتياطي والاستعادة
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

                _buildDivider(isDark),

                // ← Hint: رابط لصفحة الأرشيف
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
              ],
            ),
          ),

          const SizedBox(height: AppConstants.spacingXl),

          // ============================================================
          // ℹ️ قسم حول التطبيق
          // ← Hint: يحتوي على معلومات التطبيق
          // ============================================================
          _buildSectionHeader(
            context,
            title: l10n.about,
            icon: Icons.info_outline,
            isDark: isDark,
          ),
          const SizedBox(height: AppConstants.spacingSm),
          
          _SettingsCard(
            child: Column(
              children: [
                // ← Hint: رابط لصفحة حول التطبيق
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
              ],
            ),
          ),

          const SizedBox(height: AppConstants.spacingXl),

          // ← Hint: معلومات الإصدار في الأسفل
          _buildVersionInfo(context, isDark),
          
          const SizedBox(height: AppConstants.spacingXl),
        ],
      ),
    );
  }

  // ============================================================
  // 🎨 بناء رأس القسم مع أيقونة
  // ← Hint: دالة مساعدة لبناء عنوان كل قسم بشكل موحد
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
          // ← Hint: أيقونة القسم مع خلفية ملونة
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
          // ← Hint: عنوان القسم
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
  // ← Hint: SwitchListTile مع Consumer للتحديث التلقائي
  // ============================================================
  Widget _buildThemeTile(BuildContext context, ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;
    final l10n = AppLocalizations.of(context)!;

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
          l10n.darkMode,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          isDark ? l10n.darkModeEnabled : l10n.darkModeDisabled,
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
          // ← Hint: تبديل الثيم عبر ThemeProvider
          themeProvider.toggleTheme();
        },
      ),
    );
  }

  // ============================================================
  // 🌍 بناء خيار تغيير اللغة
  // ← Hint: ListTile قابل للضغط مع Consumer
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
        // ← Hint: تبديل اللغة
        final newLocale = isArabic
          ? const Locale('en')
          : const Locale('ar');
        localeProvider.setLocale(newLocale);

        // ← Hint: عرض رسالة تأكيد
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
  // 💰 بناء خيار اختيار العملة
  // ← Hint: يفتح Dialog لاختيار العملة
  // ============================================================
  Widget _buildCurrencyTile(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
  ) {
    // ← Hint: الحصول على العملة الحالية من CurrencyService
    final currentCurrency = CurrencyService.instance.currentCurrency;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      leading: Container(
        padding: const EdgeInsets.all(AppConstants.spacingSm),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: AppConstants.borderRadiusMd,
        ),
        child: const Icon(
          Icons.attach_money,
          color: AppColors.success,
        ),
      ),
      title: Text(
        l10n.currency,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Row(
        children: [
          const Icon(
            Icons.check_circle,
            size: 14,
            color: AppColors.success,
          ),
          const SizedBox(width: 4),
          Text(
            '${currentCurrency.getName(isArabic)} (${currentCurrency.symbol})',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
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
        // ← Hint: عرض حوار اختيار العملة
        _showCurrencyDialog(context, l10n, isArabic);
      },
    );
  }

  // ============================================================
  // 🔐 بناء خيار تفعيل البصمة
  // ← Hint: SwitchListTile مع دوال async للتفعيل/الإيقاف
  // ============================================================
  Widget _buildBiometricTile(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      title: Text(
        l10n.biometricLogin,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        _isBiometricEnabled
          ? l10n.biometricEnabled
          : l10n.biometricDisabled,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      secondary: Container(
        padding: const EdgeInsets.all(AppConstants.spacingSm),
        decoration: BoxDecoration(
          color: (_isBiometricEnabled ? AppColors.success : AppColors.error)
            .withOpacity(0.1),
          borderRadius: AppConstants.borderRadiusMd,
        ),
        child: Icon(
          Icons.fingerprint,
          color: _isBiometricEnabled ? AppColors.success : AppColors.error,
        ),
      ),
      value: _isBiometricEnabled,
      onChanged: (value) async {
        if (value) {
          // ← Hint: تفعيل البصمة
          await _enableBiometric(context, l10n);
        } else {
          // ← Hint: إلغاء تفعيل البصمة
          await _disableBiometric(context, l10n);
        }
      },
    );
  }

  // ============================================================
  // 💰 عرض حوار اختيار العملة
  // ← Hint: AlertDialog مع ListView للعملات المتاحة
  // ============================================================
  void _showCurrencyDialog(
    BuildContext context,
    AppLocalizations l10n,
    bool isArabic,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.selectCurrency),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: Currency.values.length,
            itemBuilder: (context, index) {
              final currency = Currency.values[index];
              final isSelected = currency == CurrencyService.instance.currentCurrency;

              return ListTile(
                leading: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? AppColors.success : AppColors.textSecondaryLight,
                ),
                title: Text(currency.getName(isArabic)),
                subtitle: Text('${currency.symbol} - ${currency.code}'),
                onTap: () async {
                  // ← Hint: حفظ العملة المختارة
                  await CurrencyService.instance.setCurrency(currency);
                  
                  if (!mounted) return;
                  
                  // ← Hint: إغلاق الحوار
                  Navigator.pop(ctx);
                  
                  // ← Hint: تحديث الواجهة
                  setState(() {});
                  
                  // ← Hint: عرض رسالة نجاح
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: AppConstants.spacingSm),
                          Text(l10n.currencyChanged),
                        ],
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🔐 تفعيل البصمة (مع معالجة خطأ المحاكي)
  // ← Hint: دالة async تتعامل مع BiometricService
  // ============================================================
  Future<void> _enableBiometric(BuildContext context, AppLocalizations l10n) async {
    final result = await BiometricService.instance.enableBiometric();
    
    if (!mounted) return;

    if (result['success'] == true) {
      // ← Hint: نجح التفعيل
      setState(() {
        _isBiometricEnabled = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: AppConstants.spacingSm),
              Text(result['message']),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // ← Hint: فشل التفعيل - التحقق إذا كان الخطأ بسبب المحاكي
      final isEmulatorError = result['isEmulatorError'] == true;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result['message'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (isEmulatorError) ...[
                const SizedBox(height: 4),
                const Text(
                  'يمكنك تجربة الميزة على جهاز حقيقي',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
          backgroundColor: isEmulatorError ? AppColors.warning : AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ============================================================
  // 🔐 إلغاء تفعيل البصمة
  // ← Hint: دالة async مع حوار تأكيد
  // ============================================================
  Future<void> _disableBiometric(BuildContext context, AppLocalizations l10n) async {
    // ← Hint: عرض حوار تأكيد أولاً
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.disableBiometric),
        content: Text(l10n.disableBiometricConfirmation),
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
            child: Text(l10n.disable),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // ← Hint: إلغاء التفعيل
    await BiometricService.instance.disableBiometric();

    if (!mounted) return;

    setState(() {
      _isBiometricEnabled = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: AppConstants.spacingSm),
            Text(l10n.biometricDisabledSuccess),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // 📏 بناء خط فاصل
  // ← Hint: Divider بسيط بين العناصر
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
  // ← Hint: عرض معلومات التطبيق في الأسفل
  // ============================================================
  Widget _buildVersionInfo(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context)!;

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
            l10n.appTitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.spacingXs),
          const SizedBox(height: AppConstants.spacingXs),
          Text(
            l10n.appVersion,
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
// ← Hint: Card بسيط لتغليف كل قسم
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
// ← Hint: ListTile قابل لإعادة الاستخدام مع أيقونة وسهم
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