// // lib/screens/settings/backup_restore_screen.dart

// import 'dart:ui';
// import 'package:flutter/material.dart';
// import '../../services/backup_service.dart';
// import '../../l10n/app_localizations.dart';
// import '../../theme/app_colors.dart';
// import '../../widgets/glass_container.dart';
// import '../../widgets/gradient_background.dart'; 

// class BackupRestoreScreen extends StatefulWidget {
//   const BackupRestoreScreen({super.key});

//   @override
//   State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
// }

// class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
//   bool _isBackingUp = false;
//   bool _isRestoring = false;
//   final BackupService _backupService = BackupService();

//   // 1. دالة موحدة لعرض مربعات الحوار الزجاجية
//   Future<T?> _showGlassDialog<T>({
//     required BuildContext context,
//     required String title,
//     required String content,
//     List<Widget>? actions,
//     bool barrierDismissible = true,
//   }) {
//     return showDialog<T>(
//       context: context,
//       barrierDismissible: barrierDismissible,
//       builder: (context) => BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
//         child: AlertDialog(
//           backgroundColor: AppColors.glassBgColor.withOpacity(0.85),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//             side: const BorderSide(color: AppColors.glassBorderColor),
//           ),
//           title: Text(title),
//           content: Text(content, style: Theme.of(context).textTheme.bodyMedium),
//           actions: actions,
//         ),
//       ),
//     );
//   }

//   Future<void> _handleCreateBackup() async {
//     final l10n = AppLocalizations.of(context)!;
//     setState(() => _isBackingUp = true);

//     final result = await _backupService.createAndShareBackup();

//     if (mounted) {
//       setState(() => _isBackingUp = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(result == 'نجاح' ? l10n.backupStarted : l10n.backupFailed(result)),
//           backgroundColor: result == 'نجاح' ? Colors.green : Colors.orange,
//         ),
//       );
//     }
//   }

//   Future<void> _handleRestoreBackup() async {
//     final l10n = AppLocalizations.of(context)!;

//     // 2. استخدام مربع الحوار الزجاجي الجديد للتأكيد
//     final confirm = await _showGlassDialog<bool>(
//       context: context,
//       title: l10n.restoreConfirmTitle,
//       content: l10n.restoreConfirmContent,
//       actions: [
//         TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(true),
//           child: Text(l10n.restore, style: const TextStyle(color: Colors.redAccent)),
//         ),
//       ],
//     );

//     if (confirm != true) return;

//     setState(() => _isRestoring = true);
//     final result = await _backupService.restoreBackup();
//     if (mounted) {
//       setState(() => _isRestoring = false);
      
//       if (result == 'نجاح') {
//         // استخدام مربع الحوار الزجاجي لإعلام النجاح
//         await _showGlassDialog(
//           context: context,
//           barrierDismissible: false,
//           title: l10n.restoreSuccessTitle,
//           content: l10n.restoreSuccessContent,
//           actions: [
//             TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.ok)),
//           ],
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(l10n.restoreFailed(result)),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     final theme = Theme.of(context);

//     return Scaffold(
//       // 3. توحيد بنية الصفحة
//       backgroundColor: Colors.transparent,
//       extendBodyBehindAppBar: true,
//       body: GradientBackground(
//         child: CustomScrollView(
//           slivers: [
//             SliverAppBar(
//               title: Text(l10n.backupAndRestore),
//               pinned: true,
//             ),
//             SliverFillRemaining( // 4. استخدام SliverFillRemaining
//               hasScrollBody: false, // لأن المحتوى قليل
//               child: Padding(
//                 padding: const EdgeInsets.all(20.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     const SizedBox(height: 20),
//                     // 5. استدعاء ويدجت البطاقة الجديدة والمبسطة
//                     _OptionCard(
//                       title: l10n.createBackupTitle,
//                       subtitle: l10n.createBackupSubtitle,
//                       icon: Icons.cloud_upload_outlined,
//                       isLoading: _isBackingUp,
//                       onTap: _isBackingUp || _isRestoring ? null : _handleCreateBackup,
//                     ),
//                     const SizedBox(height: 20),
//                     _OptionCard(
//                       title: l10n.restoreFromFileTitle,
//                       subtitle: l10n.restoreFromFileSubtitle,
//                       icon: Icons.cloud_download_outlined,
//                       isLoading: _isRestoring,
//                       onTap: _isBackingUp || _isRestoring ? null : _handleRestoreBackup,
//                     ),
//                     const Spacer(),
//                     Text(
//                       l10n.backupTip,
//                       textAlign: TextAlign.center,
//                       style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textGrey.withOpacity(0.7)),
//                     ),
//                     const SizedBox(height: 20),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // 6. ويدجت مخصصة ومبسطة لبطاقات الخيارات
// class _OptionCard extends StatelessWidget {
//   final String title;
//   final String subtitle;
//   final IconData icon;
//   final bool isLoading;
//   final VoidCallback? onTap;

//   const _OptionCard({
//     required this.title,
//     required this.subtitle,
//     required this.icon,
//     this.isLoading = false,
//     this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
    
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(20),
//       // استخدام GlassContainer مباشرة!
//       child: GlassContainer(
//         borderRadius: 20,
//         padding: const EdgeInsets.all(20.0),
//         child: Row(
//           children: [
//             // الأيقونة تأخذ لونها من الثيم الرئيسي
//             Icon(icon, size: 40, color: theme.colorScheme.primary),
//             const SizedBox(width: 20),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(title, style: theme.textTheme.titleLarge),
//                   const SizedBox(height: 4),
//                   Text(subtitle, style: theme.textTheme.bodyMedium),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 16),
//             // عرض مؤشر التحميل أو أيقونة السهم
//             AnimatedSwitcher(
//               duration: const Duration(milliseconds: 300),
//               child: isLoading
//                   ? const SizedBox(
//                       width: 24,
//                       height: 24,
//                       child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
//                     )
//                   : const Icon(Icons.arrow_forward_ios, size: 16),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
