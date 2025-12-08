// lib/screens/settings/about_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../data/database_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_state.dart';

/// 📱 شاشة حول التطبيق - صفحة فرعية
/// Hint: تعرض معلومات التطبيق، الشركة، والمطور
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final dbHelper = DatabaseHelper.instance;
  
  // ============= متغيرات الحالة =============
  String? _version;
  String? _buildNumber;
  String? _companyName;
  String? _companyDescription;
  File? _companyLogo;
  bool _isLoading = true;

  // ============= دورة الحياة =============
  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  /// تحميل معلومات التطبيق والشركة
  Future<void> _loadAppInfo() async {
    try {
      // جلب البيانات بشكل متوازي لتحسين الأداء
      final packageInfoFuture = PackageInfo.fromPlatform();
      final settingsFuture = dbHelper.getAppSettings();
      
      final results = await Future.wait([packageInfoFuture, settingsFuture]);
      
      final packageInfo = results[0] as PackageInfo;
      final settings = results[1] as Map<String, String?>;
      
      if (mounted) {
        setState(() {
          _version = packageInfo.version;
          _buildNumber = packageInfo.buildNumber;
          _companyName = settings['companyName'];
          _companyDescription = settings['companyDescription'];
          
          // تحميل الشعار
          final logoPath = settings['companyLogoPath'];
          if (logoPath != null && logoPath.isNotEmpty) {
            final logoFile = File(logoPath);
            if (logoFile.existsSync()) {
              _companyLogo = logoFile;
            }
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============= بناء الواجهة =============
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // ============= AppBar =============
      appBar: AppBar(
        title: Text(l10n.aboutTheApp),
      ),

      // ============= Body =============
      body: _isLoading
          ? LoadingState(message: l10n.loading)
          : SingleChildScrollView(
              padding: AppConstants.screenPadding,
              child: Column(
                children: [
                  const SizedBox(height: AppConstants.spacingXl),
                  
                  // ============= شعار التطبيق =============
                  _buildAppLogo(isDark),
                  
                  const SizedBox(height: AppConstants.spacingXl),
                  
                  // ============= معلومات التطبيق =============
                  _buildAppInfoCard(l10n, isDark),
                  
                  const SizedBox(height: AppConstants.spacingLg),
                  
                  // ============= معلومات الشركة =============
                  if (_companyName != null && _companyName!.isNotEmpty)
                    _buildCompanyInfoCard(isDark),
                  
                  const SizedBox(height: AppConstants.spacingLg),
                  
                  // ============= معلومات المطور =============
                  _buildDeveloperCard(isDark),
                  
                  const SizedBox(height: AppConstants.spacingXl),
                  
                  // ============= حقوق النشر =============
                  _buildCopyright(isDark),
                  
                  // const SizedBox(height: AppConstants.spacingXl), ---- للتجربة   
                  SizedBox(height: MediaQuery.of(context).padding.bottom + AppConstants.spacingXl),
                ],
              ),
            ),
    );
  }

  // ============================================================
  // 🎨 بناء شعار التطبيق
  // ============================================================
  Widget _buildAppLogo(bool isDark) {
    return Hero(
      tag: 'app_logo',
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.primaryDark,
                    AppColors.secondaryDark,
                  ]
                : [
                    AppColors.primaryLight,
                    AppColors.secondaryLight,
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                  .withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipOval(
          child: _companyLogo != null
              ? Image.file(
                  _companyLogo!,
                  fit: BoxFit.cover,
                )
              : Icon(
                  Icons.store,
                  size: 60,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }

  // ============================================================
  // 📱 بناء بطاقة معلومات التطبيق
  // ============================================================
  Widget _buildAppInfoCard(AppLocalizations l10n, bool isDark) {
    final l10n = AppLocalizations.of(context)!;

    return CustomCard(
      child: Column(
        children: [
          // العنوان
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Text(
                l10n.aboutTheApp,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.spacingLg),
          
          // اسم التطبيق
          Text(
            l10n.accountingProgram,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppConstants.spacingMd),
          
          // رقم الإصدار
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingMd,
              vertical: AppConstants.spacingSm,
            ),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                  .withOpacity(0.1),
              borderRadius: AppConstants.borderRadiusFull,
            ),
            child: Text(
              // 'الإصدار ${_version ?? '1.0.0'} (${_buildNumber ?? '1'})',
              l10n.appVersion,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                  ),
            ),
          ),
          
          const SizedBox(height: AppConstants.spacingLg),
          
          // الوصف
          Text(
            l10n.appDescription,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🏢 بناء بطاقة معلومات الشركة
  // ============================================================
  Widget _buildCompanyInfoCard(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان
          Row(
            children: [
              Icon(
                Icons.business,
                color: AppColors.info,
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Text(
                l10n.companyInfo,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.spacingLg),
          
          // اسم الشركة
          _buildInfoRow(
            icon: Icons.store_outlined,
            label: l10n.companyName,
            value: _companyName ?? l10n.notSpecified,
            isDark: isDark,
          ),
          
          // الوصف
          if (_companyDescription != null && _companyDescription!.isNotEmpty) ...[
            const SizedBox(height: AppConstants.spacingMd),
            _buildInfoRow(
              icon: Icons.description_outlined,
              label: l10n.description,
              value: _companyDescription!,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // 👨‍💻 بناء بطاقة معلومات المطور
  // ============================================================
  Widget _buildDeveloperCard(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان
          Row(
            children: [
              Icon(
                Icons.code,
                color: AppColors.success,
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Text(
                l10n.developerInfo,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.spacingLg),
          
          // الاسم
          _buildInfoRow(
            icon: Icons.person_outline,
            label: l10n.developer,
            value: 'Sinan',
            isDark: isDark,
          ),
          
          const SizedBox(height: AppConstants.spacingMd),
          
          // البريد الإلكتروني
          _buildInfoRow(
            icon: Icons.email_outlined,
            label: l10n.email,
            value: 'SenanXsh@gmail.com',
            isDark: isDark,
            isLink: true,
          ),
          
          const SizedBox(height: AppConstants.spacingMd),
          
          // رقم الهاتف
          _buildInfoRow(
            icon: Icons.phone_outlined,
            label: l10n.phone,
            value: '07700270555',
            isDark: isDark,
            isLink: true,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 📋 بناء صف معلومات
  // ============================================================
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    bool isLink = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingSm),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                .withOpacity(0.1),
            borderRadius: AppConstants.borderRadiusSm,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
          ),
        ),
        const SizedBox(width: AppConstants.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
              ),
              const SizedBox(height: AppConstants.spacingXs),

              // للضغط على الرقم او الايميل للنسخ
              GestureDetector(
                 onTap: isLink ? () {
                 Clipboard.setData(ClipboardData(text: value));
                 ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('تم نسخ: $value')),
                 );
               } : null,
               //--------------------------------
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isLink
                          ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                          : null,
                    ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // © حقوق النشر
  // ============================================================
  Widget _buildCopyright(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Divider(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          thickness: 1,
        ),
        const SizedBox(height: AppConstants.spacingMd),
        Text(
          l10n.rightsReserved,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
        ),
        const SizedBox(height: AppConstants.spacingSm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.madeWith,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textHintDark
                        : AppColors.textHintLight,
                  ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.favorite,
              size: 14,
              color: AppColors.error,
            ),
            const SizedBox(width: 4),
            Text(
              l10n.madeInIraq,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textHintDark
                        : AppColors.textHintLight,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}