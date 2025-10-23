// // lib/screens/settings/about_screen.dart

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:package_info_plus/package_info_plus.dart';
// import '../../data/database_helper.dart';
// import '../../l10n/app_localizations.dart';
// import '../../theme/app_colors.dart';
// import '../../widgets/glass_container.dart';
// import '../../widgets/gradient_background.dart'; 

// class AboutScreen extends StatefulWidget {
//   const AboutScreen({super.key});

//   @override
//   State<AboutScreen> createState() => _AboutScreenState();
// }

// class _AboutScreenState extends State<AboutScreen> {
//   final dbHelper = DatabaseHelper.instance;
  
//   // 1. استخدام متغيرات قابلة للإلغاء (nullable) للتعامل مع حالة التحميل
//   String? _version;
//   String? _companyName;
//   File? _companyLogo;
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadAppInfo();
//   }

//   Future<void> _loadAppInfo() async {
//     // جلب البيانات في نفس الوقت لتحسين الأداء
//     final packageInfoFuture = PackageInfo.fromPlatform();
//     final settingsFuture = dbHelper.getAppSettings();
    
//     final results = await Future.wait([packageInfoFuture, settingsFuture]);
    
//     final packageInfo = results[0] as PackageInfo;
//     final settings = results[1] as Map<String, String?>;
//     final logoPath = settings['companyLogoPath'];

//     if (mounted) {
//       setState(() {
//         _version = packageInfo.version;
//         _companyName = settings['companyName']; // قد يكون null
//         if (logoPath != null && logoPath.isNotEmpty) {
//           _companyLogo = File(logoPath);
//         }
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     final theme = Theme.of(context);

//     return Scaffold(
//       // 2. توحيد بنية الصفحة
//       backgroundColor: Colors.transparent,
//       extendBodyBehindAppBar: true,
//       body: GradientBackground(
//         child: CustomScrollView(
//           slivers: [
//             SliverAppBar(
//               title: Text(l10n.aboutTheApp),
//               pinned: true,
//             ),
//             // 3. استخدام SliverFillRemaining لتوسيط المحتوى عمودياً
//             SliverFillRemaining(
//               hasScrollBody: false,
//               child: Center(
//                 child: _isLoading
//                     ? const CircularProgressIndicator(color: Colors.white)
//                     : Padding(
//                         padding: const EdgeInsets.all(1.0),
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             const Spacer(flex: 2),
//                             // 4. استدعاء ويدجت البطاقة الزجاجية الجديدة
//                             _buildInfoCard(context, l10n),
//                             const Spacer(flex: 1),
//                             // 5. معلومات المطور في الأسفل
//                             _buildFooter(theme),
//                             const SizedBox(height: 160),
//                           ],
//                         ),
//                       ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ويدجت البطاقة الزجاجية التي تحتوي على معلومات التطبيق
//   Widget _buildInfoCard(BuildContext context, AppLocalizations l10n) {
//     final theme = Theme.of(context);
//     return GlassContainer(
//       borderRadius: 50,
//       padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
//       child: Column(
//         children: [
//           CircleAvatar(
//             radius: 40,
//             backgroundColor: AppColors.primaryPurple.withOpacity(0.5),
//             backgroundImage: _companyLogo != null && _companyLogo!.existsSync()
//                 ? FileImage(_companyLogo!)
//                 : null,
//             child: (_companyLogo == null || !_companyLogo!.existsSync())
//                 ? Icon(Icons.calculate, size: 50, color: AppColors.textGrey.withOpacity(0.8))
//                 : null,
//           ),
//           const SizedBox(height: 50),
//           Text(
//             _companyName ?? l10n.accountingProgram, // عرض اسم افتراضي إذا كان null
//             style: theme.textTheme.headlineMedium,
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 20),
//           Text(
//             'Version $_version',
//             style: theme.textTheme.bodyMedium,
//           ),
//         ],
//       ),
//     );
//   }

//   // ويدجت معلومات المطور في الأسفل
//   Widget _buildFooter(ThemeData theme) {
//     return Column(
//       children: [
//         Text('© 2025 All rights reserved', style: theme.textTheme.bodyLarge),
//         const SizedBox(height: 15),
//         Text('Developed by Sinan', style: theme.textTheme.bodyLarge),
//         const SizedBox(height: 15),
//         Text('Email: SenanXsh@gmail.com', style: theme.textTheme.bodyLarge),
//         const SizedBox(height: 15),
//         Text('Phone: 07700270555', style: theme.textTheme.bodyLarge),
//       ],
//     );
//   }
// }
