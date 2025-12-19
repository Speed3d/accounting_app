// lib/screens/settings/app_guide_screen.dart

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';

/// ============================================================================
/// 📖 شاشة دليل التطبيق - شرح شامل لجميع الميزات
/// ============================================================================
///
/// ← Hint: شاشة تعليمية توضح جميع ميزات التطبيق بشكل مبسط
/// ← Hint: مقسمة إلى أقسام مع أيقونات وأمثلة
/// ← Hint: ثنائية اللغة (عربي/إنجليزي)
///
/// ============================================================================

class AppGuideScreen extends StatelessWidget {
  const AppGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'دليل التطبيق' : 'App Guide'),
        elevation: 0,
      ),
      body: ListView(
        padding: AppConstants.screenPadding,
        children: [
          // ============================================================
          // 👋 المقدمة
          // ============================================================
          _GuideHeader(
            icon: Icons.waving_hand,
            title: isArabic ? 'مرحباً بك!' : 'Welcome!',
            subtitle: isArabic
                ? 'هنا دليلك الشامل لاستخدام تطبيق لمسة محاسب'
                : 'Your complete guide to using Accountant Touch',
            color: AppColors.primaryLight,
            isDark: isDark,
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // ============================================================
          // 📊 نظرة عامة
          // ============================================================
          _GuideSection(
            icon: Icons.analytics_outlined,
            title: isArabic ? 'نظرة عامة' : 'Overview',
            color: AppColors.info,
            isDark: isDark,
            children: [
              _GuideText(
                isArabic
                    ? ' لمسة محاسب هو تطبيق محاسبي احترافي وسهل الاستخدام، '
                        'مصمم خصيصاً لمساعدتك في إدارة حسابات شركتك أو متجرك بكل سهولة وأمان.'
                    : 'Accountant Touch is a professional and easy-to-use accounting app, '
                        'specially designed to help you manage your company or store accounts easily and securely.',
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // ============================================================
          // 💰 المبيعات
          // ============================================================
          _GuideSection(
            icon: Icons.point_of_sale,
            title: isArabic ? 'إدارة المبيعات' : 'Sales Management',
            color: AppColors.success,
            isDark: isDark,
            children: [
              _GuideFeature(
                icon: Icons.receipt_long,
                title: isArabic ? 'البيع المباشر' : 'Direct Sale',
                description: isArabic
                    ? 'قم بإنشاء فواتير مبيعات سريعة مع اختيار المنتجات والعملاء، '
                        'وطباعة الفاتورة مباشرة كملف PDF.'
                    : 'Create quick sales invoices with product and customer selection, '
                        'and print the invoice directly as PDF.',
                isDark: isDark,
              ),
              _GuideFeature(
                icon: Icons.inventory_2_outlined,
                title: isArabic ? 'إدارة المنتجات' : 'Product Management',
                description: isArabic
                    ? 'إضافة وتعديل المنتجات مع الأسعار والمخزون، ومسح الباركود.'
                    : 'Add and edit products with prices, stock, and barcode scanning.',
                isDark: isDark,
              ),
              _GuideFeature(
                icon: Icons.category_outlined,
                title: isArabic ? 'التصنيفات' : 'Categories',
                description: isArabic
                    ? 'تنظيم المنتجات في فئات لسهولة البحث والإدارة.'
                    : 'Organize products into categories for easy search and management.',
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // ============================================================
          // 🛒 المشتريات
          // ============================================================
          _GuideSection(
            icon: Icons.shopping_cart_outlined,
            title: isArabic ? 'إدارة المشتريات' : 'Purchase Management',
            color: AppColors.warning,
            isDark: isDark,
            children: [
              _GuideFeature(
                icon: Icons.add_shopping_cart,
                title: isArabic ? 'تسجيل المشتريات' : 'Record Purchases',
                description: isArabic
                    ? 'سجل جميع مشترياتك من الموردين مع التفاصيل والمبالغ.'
                    : 'Record all your purchases from suppliers with details and amounts.',
                isDark: isDark,
              ),
              _GuideFeature(
                icon: Icons.local_shipping_outlined,
                title: isArabic ? 'إدارة الموردين' : 'Supplier Management',
                description: isArabic
                    ? 'احفظ معلومات الموردين وتتبع تعاملاتك معهم.'
                    : 'Save supplier information and track your transactions with them.',
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // ============================================================
          // 👥 العملاء والموردين
          // ============================================================
          _GuideSection(
            icon: Icons.people_outline,
            title: isArabic ? 'العملاء والموردين' : 'Customers & Suppliers',
            color: AppColors.primaryLight,
            isDark: isDark,
            children: [
              _GuideFeature(
                icon: Icons.person_add_outlined,
                title: isArabic ? 'إدارة العملاء' : 'Customer Management',
                description: isArabic
                    ? 'احفظ معلومات العملاء الكاملة: الاسم، رقم الهاتف، العنوان، والبريد الإلكتروني.'
                    : 'Save complete customer information: name, phone, address, and email.',
                isDark: isDark,
              ),
              _GuideFeature(
                icon: Icons.history,
                title: isArabic ? 'سجل المعاملات' : 'Transaction History',
                description: isArabic
                    ? 'تتبع جميع المعاملات السابقة مع كل عميل أو مورد.'
                    : 'Track all previous transactions with each customer or supplier.',
                isDark: isDark,
              ),
              _GuideFeature(
                icon: Icons.account_balance_wallet_outlined,
                title: isArabic ? 'الأرصدة' : 'Balances',
                description: isArabic
                    ? 'راقب الديون والمستحقات لكل عميل ومورد.'
                    : 'Monitor debts and receivables for each customer and supplier.',
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // ============================================================
          // 📊 التقارير
          // ============================================================
          _GuideSection(
            icon: Icons.assessment_outlined,
            title: isArabic ? 'التقارير المالية' : 'Financial Reports',
            color: AppColors.info,
            isDark: isDark,
            children: [
              _GuideFeature(
                icon: Icons.trending_up,
                title: isArabic ? 'تقرير المبيعات' : 'Sales Report',
                description: isArabic
                    ? 'تقارير تفصيلية للمبيعات اليومية والشهرية والسنوية.'
                    : 'Detailed reports for daily, monthly, and yearly sales.',
                isDark: isDark,
              ),
              _GuideFeature(
                icon: Icons.trending_down,
                title: isArabic ? 'تقرير المشتريات' : 'Purchases Report',
                description: isArabic
                    ? 'متابعة جميع المشتريات والمصروفات بالتفصيل.'
                    : 'Track all purchases and expenses in detail.',
                isDark: isDark,
              ),
              _GuideFeature(
                icon: Icons.account_balance,
                title: isArabic ? 'الأرباح والخسائر' : 'Profit & Loss',
                description: isArabic
                    ? 'تقرير شامل للأرباح والخسائر مع رسوم بيانية واضحة.'
                    : 'Comprehensive profit and loss report with clear charts.',
                isDark: isDark,
              ),
              _GuideFeature(
                icon: Icons.bar_chart,
                title: isArabic ? 'رسوم بيانية' : 'Charts',
                description: isArabic
                    ? 'تصور بياناتك المالية برسوم بيانية تفاعلية.'
                    : 'Visualize your financial data with interactive charts.',
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // ============================================================
          // 💾 النسخ الاحتياطي
          // ============================================================
          _GuideSection(
            icon: Icons.backup_outlined,
            title: isArabic ? 'النسخ الاحتياطي والاستعادة' : 'Backup & Restore',
            color: AppColors.success,
            isDark: isDark,
            children: [
              _GuideFeature(
                icon: Icons.cloud_upload_outlined,
                title: isArabic ? 'نسخ احتياطي آمن' : 'Secure Backup',
                description: isArabic
                    ? 'احفظ نسخة احتياطية مشفرة من جميع بياناتك (قاعدة البيانات + الصور).'
                    : 'Save an encrypted backup of all your data (database + images).',
                isDark: isDark,
              ),
              _GuideFeature(
                icon: Icons.cloud_download_outlined,
                title: isArabic ? 'استعادة سريعة' : 'Quick Restore',
                description: isArabic
                    ? 'استعد بياناتك بكل سهولة في حالة فقدانها أو تغيير الجهاز.'
                    : 'Restore your data easily in case of loss or device change.',
                isDark: isDark,
              ),
              _GuideFeature(
                icon: Icons.lock_outlined,
                title: isArabic ? 'تشفير AES-256' : 'AES-256 Encryption',
                description: isArabic
                    ? 'جميع النسخ الاحتياطية محمية بتشفير عسكري من الدرجة الأولى.'
                    : 'All backups are protected with military-grade encryption.',
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // ============================================================
          // 🔒 الأمان والخصوصية
          // ============================================================
          _GuideSection(
            icon: Icons.security,
            title: isArabic ? 'الأمان والخصوصية' : 'Security & Privacy',
            color: AppColors.error,
            isDark: isDark,
            children: [
              _GuideFeature(
                icon: Icons.fingerprint,
                title: isArabic ? 'تسجيل الدخول بالبصمة' : 'Biometric Login',
                description: isArabic
                    ? 'سجل دخولك بسرعة وأمان باستخدام بصمة الإصبع أو Face ID.'
                    : 'Login quickly and securely using fingerprint or Face ID.',
                isDark: isDark,
              ),
              _GuideFeature(
                icon: Icons.lock_clock,
                title: isArabic ? 'القفل التلقائي' : 'Auto-Lock',
                description: isArabic
                    ? 'حماية بياناتك تلقائياً عند عدم استخدام التطبيق لفترة معينة.'
                    : 'Automatically protect your data when the app is inactive.',
                isDark: isDark,
              ),
              _GuideFeature(
                icon: Icons.storage,
                title: isArabic ? 'قاعدة بيانات مشفرة' : 'Encrypted Database',
                description: isArabic
                    ? 'جميع بياناتك محفوظة في قاعدة بيانات مشفرة بـ SQLCipher.'
                    : 'All your data is stored in a SQLCipher encrypted database.',
                isDark: isDark,
              ),
              _GuideFeature(
                icon: Icons.cloud_off_outlined,
                title: isArabic ? 'خصوصية كاملة' : 'Full Privacy',
                description: isArabic
                    ? 'بياناتك المالية تبقى على جهازك فقط، لا نشاركها مع أي طرف ثالث.'
                    : 'Your financial data stays on your device only, never shared with third parties.',
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // ============================================================
          // ⚙️ الإعدادات
          // ============================================================
          _GuideSection(
            icon: Icons.settings_outlined,
            title: isArabic ? 'الإعدادات' : 'Settings',
            color: AppColors.textSecondaryLight,
            isDark: isDark,
            children: [
              _GuideFeature(
                icon: Icons.palette_outlined,
                title: isArabic ? 'الوضع الداكن' : 'Dark Mode',
                description: isArabic
                    ? 'اختر بين الوضع الفاتح أو الداكن حسب راحتك.'
                    : 'Choose between light or dark mode for your comfort.',
                isDark: isDark,
              ),
              _GuideFeature(
                icon: Icons.translate,
                title: isArabic ? 'اللغات' : 'Languages',
                description: isArabic
                    ? 'تبديل سريع بين العربية والإنجليزية.'
                    : 'Quick switch between Arabic and English.',
                isDark: isDark,
              ),
              _GuideFeature(
                icon: Icons.attach_money,
                title: isArabic ? 'العملات' : 'Currencies',
                description: isArabic
                    ? 'اختر عملتك المفضلة: دولار، دينار، ريال، جنيه، وغيرها.'
                    : 'Choose your preferred currency: Dollar, Dinar, Riyal, Pound, and more.',
                isDark: isDark,
              ),
              _GuideFeature(
                icon: Icons.business_outlined,
                title: isArabic ? 'معلومات الشركة' : 'Company Info',
                description: isArabic
                    ? 'أضف اسم شركتك وشعارها ليظهرا في الفواتير.'
                    : 'Add your company name and logo to appear on invoices.',
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // ============================================================
          // 💡 نصائح مهمة
          // ============================================================
          _TipsSection(
            isArabic: isArabic,
            isDark: isDark,
          ),

          const SizedBox(height: AppConstants.spacingXl),

          // ============================================================
          // 📞 الدعم
          // ============================================================
          _SupportCard(
            isArabic: isArabic,
            isDark: isDark,
          ),

          const SizedBox(height: AppConstants.spacing2Xl),
        ],
      ),
    );
  }
}

// ============================================================================
// 🎯 عنوان الدليل
// ============================================================================
class _GuideHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;

  const _GuideHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: AppConstants.borderRadiusLg,
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: AppConstants.borderRadiusMd,
            ),
            child: Icon(
              icon,
              size: 48,
              color: color,
            ),
          ),
          const SizedBox(width: AppConstants.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 📦 قسم الدليل
// ============================================================================
class _GuideSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final bool isDark;
  final List<Widget> children;

  const _GuideSection({
    required this.icon,
    required this.title,
    required this.color,
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: AppConstants.borderRadiusSm,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingMd),
            // المحتوى
            ...children,
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ✨ ميزة واحدة
// ============================================================================
class _GuideFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isDark;

  const _GuideFeature({
    required this.icon,
    required this.title,
    required this.description,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.primaryLight,
            size: 24,
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 📝 نص عادي
// ============================================================================
class _GuideText extends StatelessWidget {
  final String text;
  final bool isDark;

  const _GuideText(this.text, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingSm),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              height: 1.6,
            ),
      ),
    );
  }
}

// ============================================================================
// 💡 قسم النصائح
// ============================================================================
class _TipsSection extends StatelessWidget {
  final bool isArabic;
  final bool isDark;

  const _TipsSection({
    required this.isArabic,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: AppConstants.borderRadiusMd,
        border: Border.all(
          color: AppColors.warning.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.warning),
              const SizedBox(width: AppConstants.spacingSm),
              Text(
                isArabic ? 'نصائح مهمة' : 'Important Tips',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm),
          _TipItem(
            isArabic
                ? '📌 احرص على عمل نسخة احتياطية بشكل دوري لحماية بياناتك'
                : '📌 Make regular backups to protect your data',
            isDark: isDark,
          ),
          _TipItem(
            isArabic
                ? '🔐 فعّل القفل التلقائي للحفاظ على خصوصية بياناتك'
                : '🔐 Enable auto-lock to maintain your data privacy',
            isDark: isDark,
          ),
          _TipItem(
            isArabic
                ? '📊 راجع التقارير بانتظام لمتابعة أداء عملك'
                : '📊 Review reports regularly to monitor your business performance',
            isDark: isDark,
          ),
          _TipItem(
            isArabic
                ? '✅ تأكد من تحديث معلومات العملاء والموردين باستمرار'
                : '✅ Keep customer and supplier information up to date',
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// نصيحة واحدة
// ============================================================================
class _TipItem extends StatelessWidget {
  final String text;
  final bool isDark;

  const _TipItem(this.text, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.spacingSm),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              height: 1.5,
            ),
      ),
    );
  }
}

// ============================================================================
// 📞 بطاقة الدعم
// ============================================================================
class _SupportCard extends StatelessWidget {
  final bool isArabic;
  final bool isDark;

  const _SupportCard({
    required this.isArabic,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.info.withOpacity(0.15),
            AppColors.info.withOpacity(0.05),
          ],
        ),
        borderRadius: AppConstants.borderRadiusMd,
        border: Border.all(
          color: AppColors.info.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.help_outline, size: 48, color: AppColors.info),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            isArabic ? 'هل تحتاج إلى مساعدة؟' : 'Need Help?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            isArabic
                ? 'إذا واجهت أي مشكلة أو لديك أي استفسار،\nلا تتردد في التواصل معنا'
                : 'If you encounter any issues or have questions,\nfeel free to contact us',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
