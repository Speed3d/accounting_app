// import 'package:accounting_app/theme/app_colors.dart';
// import 'package:flutter/material.dart';
// import 'package:accounting_app/l10n/app_localizations.dart';
// import 'package:accounting_app/providers/locale_provider.dart';
// import 'package:accounting_app/providers/theme_provider.dart';
// import 'package:accounting_app/widgets/glass_container.dart'; 
// import '../archive/archive_center_screen.dart';
// import 'about_screen.dart';
// import 'backup_restore_screen.dart';
// import 'company_info_screen.dart';

// class SettingsScreen extends StatelessWidget {
//   const SettingsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     final theme = Theme.of(context);

//     return Scaffold(
//       // --- خلفية شفافة للسماح بظهور التدرج من الخلف ---
//       backgroundColor: Colors.transparent,
//       extendBodyBehindAppBar: true,
      
//       // --- استخدام CustomScrollView لدمج AppBar مع القائمة ---
//       body: Container(
//         // --- التدرج اللوني حسب الثيم الحالي ---
//         // Hint: هنا نحتاج للتحقق من الثيم الحالي لاستخدام الألوان الصحيحة
//         // إذا كان الوضع فاتحاً، استخدم البنفسجي
//         // إذا كان الوضع ليلياً، استخدم الرصاصي
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             // Hint: نستخدم Theme.of(context).brightness للتحقق من الثيم الحالي
//             colors: theme.brightness == Brightness.light
//                 // --- الوضع الفاتح: تدرج بنفسجي ---
//                 ? [AppColors.lightPurple, AppColors.primaryPurple]
//                 // --- الوضع الليلي: تدرج رصاصي ---
//                 : [AppColors.darkScaffoldBg, AppColors.darkCardBg],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: CustomScrollView(
//           slivers: [
//             // --- شريط العنوان ---
//             // Hint: SliverAppBar يسمح بظهور AppBar مع التمرير
//             SliverAppBar(
//               pinned: true,
//               title: Text(l10n.settings),
//             ),

//             // --- قائمة الإعدادات ---
//             SliverList(
//               delegate: SliverChildListDelegate(
//                 [
//                   // ============================================================
//                   // --- قسم المظهر ---
//                   // ============================================================
//                   _SectionTitle(title: "المظهر"),
//                   _SettingsSwitchTile(
//                     title: "الوضع الليلي",
//                     subtitle: "تفعيل أو إيقاف المظهر الداكن",
//                     icon: Icons.brightness_4_outlined,
//                     // --- التحقق من الثيم الحالي ---
//                     // Hint: إذا كان الثيم الحالي هو dark، يكون المفتاح مشغل (true)
//                     value: ThemeProvider.instance.themeMode == ThemeMode.dark,
//                     onChanged: (isDark) {
//                       // --- تغيير الثيم بناءً على حالة المفتاح ---
//                       ThemeProvider.instance.setThemeMode(
//                         isDark ? ThemeMode.dark : ThemeMode.light,
//                       );
//                     },
//                   ),
//                   const SizedBox(height: 20),

//                   // ============================================================
//                   // --- قسم اللغة ---
//                   // ============================================================
//                   _SectionTitle(title: l10n.language),
//                   ValueListenableBuilder<Locale?>(
//                     valueListenable: LocaleProvider.instance.locale,
//                     builder: (context, currentLocale, child) {
//                       return _SettingsLinkTile(
//                         title: l10n.changeLanguage,
//                         subtitle: currentLocale?.languageCode == 'ar' ? 'العربية' : 'English',
//                         icon: Icons.language_outlined,
//                         onTap: () {
//                           // --- تبديل اللغة ---
//                           final newLocale = currentLocale?.languageCode == 'ar' 
//                             ? const Locale('en') 
//                             : const Locale('ar');
//                           LocaleProvider.instance.setLocale(newLocale);
//                         },
//                       );
//                     },
//                   ),
//                   const SizedBox(height: 20),

//                   // ============================================================
//                   // --- قسم إدارة البيانات ---
//                   // ============================================================
//                   _SectionTitle(title: l10n.dataManagement),
//                   _SettingsLinkTile(
//                     title: l10n.companyInformation,
//                     subtitle: l10n.changeAppNameAndLogo,
//                     icon: Icons.business_outlined,
//                     onTap: () => Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (_) => const CompanyInfoScreen()),
//                     ),
//                   ),
//                   _SettingsLinkTile(
//                     title: l10n.archiveCenter,
//                     subtitle: l10n.restoreArchivedItems,
//                     icon: Icons.archive_outlined,
//                     onTap: () => Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (_) => const ArchiveCenterScreen()),
//                     ),
//                   ),
//                   _SettingsLinkTile(
//                     title: l10n.backupAndRestore,
//                     subtitle: l10n.saveAndRestoreAppData,
//                     icon: Icons.storage_outlined,
//                     onTap: () => Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (_) => const BackupRestoreScreen()),
//                     ),
//                   ),
//                   const SizedBox(height: 20),

//                   // ============================================================
//                   // --- قسم حول التطبيق ---
//                   // ============================================================
//                   _SectionTitle(title: l10n.about),
//                   _SettingsLinkTile(
//                     title: l10n.aboutTheApp,
//                     subtitle: "معلومات التطبيق والمطور",
//                     icon: Icons.info_outline,
//                     onTap: () => Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (_) => const AboutScreen()),
//                     ),
//                   ),
//                   const SizedBox(height: 30),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ============================================================
// // --- ويدجت عنوان القسم ---
// // ============================================================
// /// ويدجت مخصصة لعناوين الأقسام
// /// الفائدة: تجنب تكرار نفس الكود
// class _SectionTitle extends StatelessWidget {
//   final String title;
//   const _SectionTitle({required this.title});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 8.0),
//       child: Text(
//         title,
//         style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//           // --- اللون يتغير حسب الثيم ---
//           // Hint: في الوضع الفاتح يكون بنفسجي فاتح
//           //       في الوضع الليلي يكون رصاصي فاتح
//           color: Theme.of(context).brightness == Brightness.light
//               ? AppColors.lightTextSecondary
//               : AppColors.darkTextSecondary,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//     );
//   }
// }

// // ============================================================
// // --- ويدجت عنصر قائمة ينقلك لصفحة أخرى ---
// // ============================================================
// /// ويدجت مخصصة لعناصر الإعدادات التي تحتوي على رابط
// /// تحتوي على أيقونة، عنوان، وسهم للأمام
// class _SettingsLinkTile extends StatelessWidget {
//   final String title;
//   final String subtitle;
//   final IconData icon;
//   final VoidCallback onTap;

//   const _SettingsLinkTile({
//     required this.title,
//     required this.subtitle,
//     required this.icon,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
    
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
//       // --- استخدام GlassContainer للتأثير الزجاجي ---
//       // Hint: GlassContainer توفر تأثير زجاج شفاف جميل
//       child: GlassContainer(
//         borderRadius: 15,
//         child: ListTile(
//           // --- الأيقونة على اليسار ---
//           leading: Icon(
//             icon,
//             color: theme.textTheme.bodyMedium?.color,
//           ),
//           // --- العنوان ---
//           title: Text(
//             title,
//             style: theme.textTheme.bodyLarge?.copyWith(
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           // --- النص الثانوي (الوصف) ---
//           subtitle: Text(
//             subtitle,
//             style: theme.textTheme.bodyMedium,
//           ),
//           // --- السهم على اليمين ---
//           trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//           // --- الإجراء عند الضغط ---
//           onTap: onTap,
//           dense: true,
//         ),
//       ),
//     );
//   }
// }

// // ============================================================
// // --- ويدجت عنصر قائمة يحتوي على مفتاح تبديل ---
// // ============================================================
// /// ويدجت مخصصة لعناصر الإعدادات التي تحتوي على مفتاح تبديل (Switch)
// /// مثل: تشغيل/إيقاف الوضع الليلي
// class _SettingsSwitchTile extends StatelessWidget {
//   final String title;
//   final String subtitle;
//   final IconData icon;
//   final bool value; // القيمة الحالية للمفتاح
//   final ValueChanged<bool> onChanged; // الدالة التي تُستدعى عند التغيير

//   const _SettingsSwitchTile({
//     required this.title,
//     required this.subtitle,
//     required this.icon,
//     required this.value,
//     required this.onChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
    
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
//       // --- استخدام GlassContainer ---
//       child: GlassContainer(
//         borderRadius: 15,
//         child: SwitchListTile(
//           // --- الأيقونة على اليسار ---
//           secondary: Icon(
//             icon,
//             color: theme.textTheme.bodyMedium?.color,
//           ),
//           // --- العنوان ---
//           title: Text(
//             title,
//             style: theme.textTheme.bodyLarge?.copyWith(
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           // --- النص الثانوي ---
//           subtitle: Text(
//             subtitle,
//             style: theme.textTheme.bodyMedium,
//           ),
//           // --- قيمة المفتاح (مشغل أم مطفأ) ---
//           value: value,
//           // --- الدالة عند تغيير المفتاح ---
//           onChanged: onChanged,
//           // --- لون المفتاح عندما يكون مشغلاً ---
//           activeColor: theme.colorScheme.primary,
//         ),
//       ),
//     );
//   }
// }