// lib/screens/settings/backup_restore_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/backup_service.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';

/// 💾 شاشة النسخ الاحتياطي والاستعادة
/// Hint: صفحة فرعية مهمة جداً - تتيح للمستخدم حفظ واستعادة بياناته
class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  // ============= المتغيرات =============
  bool _isBackingUp = false;
  bool _isRestoring = false;
  final BackupService _backupService = BackupService();
  
  // ← Hint: متغيرات لتخزين معلومات آخر نسخة احتياطية تم إنشاؤها
  String? _lastBackupFilePath;
  String? _lastBackupFileName;

  // ============= الدوال =============

  /// ← Hint: إنشاء نسخة احتياطية وحفظها في Downloads
  Future<void> _handleCreateBackup() async {
    final l10n = AppLocalizations.of(context)!;
    
    setState(() => _isBackingUp = true);

    try {
      // ← Hint: استدعاء الدالة المحدثة التي تعيد Map بدلاً من String
      final result = await _backupService.createAndShareBackup();

      if (mounted) {
        setState(() => _isBackingUp = false);
        
        if (result['status'] == 'success') {
          // ← Hint: حفظ معلومات الملف المنشأ
          setState(() {
            _lastBackupFilePath = result['filePath'];
            _lastBackupFileName = result['fileName'];
          });
          
          // ← Hint: عرض رسالة نجاح مع موقع الملف
          _showSuccessDialog(
            l10n,
            result['filePath'] as String,
            result['fileName'] as String,
          );
        } else {
          // ← Hint: عرض رسالة خطأ
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? l10n.backupFailed('خطأ غير معروف')),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBackingUp = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// ← Hint: دالة جديدة لعرض نافذة النجاح مع خيار المشاركة
  void _showSuccessDialog(AppLocalizations l10n, String filePath, String fileName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 32,
            ),
            const SizedBox(width: AppConstants.spacingMd),
            Expanded(
              child: Text(
                l10n.backupSuccessTitle,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ← Hint: رسالة النجاح
            Text(
              l10n.backupSuccessContent,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
            const SizedBox(height: AppConstants.spacingLg),
            
            // ← Hint: عرض موقع الملف
            Container(
              padding: AppConstants.paddingMd,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: AppConstants.borderRadiusMd,
                border: Border.all(
                  color: AppColors.success.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 18,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: AppConstants.spacingSm),
                      Expanded(
                        child: Text(
                          l10n.backupFileLocation,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingXs),
                  
                  // ← Hint: اسم الملف
                  Text(
                    fileName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  const SizedBox(height: AppConstants.spacingXs),
                  
                  // ← Hint: المسار الكامل مع زر النسخ
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          filePath,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryLight,
                            fontSize: 11,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.copy_rounded,
                          size: 18,
                          color: AppColors.info,
                        ),
                        onPressed: () {
                          // ← Hint: نسخ المسار إلى الحافظة
                          Clipboard.setData(ClipboardData(text: filePath));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.pathCopied),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        tooltip: l10n.copyPath,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // ← Hint: زر الإغلاق
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.close),
          ),
          
          // ← Hint: زر المشاركة
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _handleShareBackup(filePath);
            },
            icon: const Icon(Icons.share_rounded),
            label: Text(l10n.share),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// ← Hint: دالة جديدة لمشاركة الملف المحفوظ
  Future<void> _handleShareBackup(String filePath) async {
    final l10n = AppLocalizations.of(context)!;
    
    try {
      final success = await _backupService.shareBackupFile(filePath);
      
      if (mounted && !success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.shareFailed),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// استعادة البيانات من نسخة احتياطية
  /// Hint: عملية خطرة! نطلب التأكيد أولاً
  Future<void> _handleRestoreBackup() async {
    final l10n = AppLocalizations.of(context)!;

    // ============= طلب التأكيد =============
    // Hint: نستخدم AlertDialog بسيط لكن واضح وخطير
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // يجب أن يختار المستخدم
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: 28,
            ),
            const SizedBox(width: AppConstants.spacingMd),
            Expanded(child: Text(l10n.restoreConfirmTitle)),
          ],
        ),
        content: Text(
          l10n.restoreConfirmContent,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          // زر الإلغاء
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          
          // زر التأكيد (خطر!)
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: Text(
              l10n.restore,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    // إذا ألغى المستخدم، نتوقف
    if (confirm != true) return;

    // ============= تنفيذ الاستعادة =============
    setState(() => _isRestoring = true);

    try {
      final result = await _backupService.restoreBackup();

      if (mounted) {
        setState(() => _isRestoring = false);

        if (result == 'نجاح') {
          // ============= نجحت الاستعادة =============
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 28,
                  ),
                  const SizedBox(width: AppConstants.spacingMd),
                  Expanded(child: Text(l10n.restoreSuccessTitle)),
                ],
              ),
              content: Text(
                l10n.restoreSuccessContent,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.ok),
                ),
              ],
            ),
          );
        } else {
          // ============= فشلت الاستعادة =============
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.restoreFailed(result)),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRestoring = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ============= البناء =============
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // ============= App Bar =============
      appBar: AppBar(
        title: Text(l10n.backupAndRestore),
      ),

      // ============= Body =============
      body: Padding(
        padding: AppConstants.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppConstants.spacingLg),

            // ============= بطاقة النسخ الاحتياطي =============
            _BackupCard(
              title: l10n.createBackupTitle,
              subtitle: l10n.createBackupSubtitle,
              icon: Icons.cloud_upload_outlined,
              color: AppColors.info,
              isLoading: _isBackingUp,
              enabled: !_isBackingUp && !_isRestoring,
              onTap: _handleCreateBackup,
            ),

            // ← Hint: عرض زر المشاركة إذا كان هناك ملف محفوظ
            if (_lastBackupFilePath != null) ...[
              const SizedBox(height: AppConstants.spacingMd),
              CustomButton(
                text: l10n.shareLastBackup,
                icon: Icons.share_rounded,
                type: ButtonType.secondary,
                onPressed: () => _handleShareBackup(_lastBackupFilePath!),
              ),
            ],

            const SizedBox(height: AppConstants.spacingLg),

            // ============= بطاقة الاستعادة =============
            _BackupCard(
              title: l10n.restoreFromFileTitle,
              subtitle: l10n.restoreFromFileSubtitle,
              icon: Icons.cloud_download_outlined,
              color: AppColors.warning,
              isLoading: _isRestoring,
              enabled: !_isBackingUp && !_isRestoring,
              onTap: _handleRestoreBackup,
            ),

            const Spacer(),

            // ============= نصيحة =============
            Container(
              padding: AppConstants.paddingMd,
              decoration: BoxDecoration(
                color: (isDark 
                    ? AppColors.primaryDark 
                    : AppColors.primaryLight).withOpacity(0.1),
                borderRadius: AppConstants.borderRadiusMd,
                border: Border.all(
                  color: isDark 
                      ? AppColors.primaryDark.withOpacity(0.3)
                      : AppColors.primaryLight.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: isDark 
                        ? AppColors.primaryDark 
                        : AppColors.primaryLight,
                    size: AppConstants.iconSizeLg,
                  ),
                  const SizedBox(width: AppConstants.spacingMd),
                  Expanded(
                    child: Text(
                      l10n.backupTip,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark 
                            ? AppColors.textSecondaryDark 
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.spacingLg),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// --- بطاقة خيار النسخ الاحتياطي ---
// ============================================================
/// Hint: ويدجت مخصصة جميلة لعرض خيارات النسخ الاحتياطي
class _BackupCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;

  const _BackupCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomCard(
      margin: EdgeInsets.zero,
      // Hint: إذا كانت معطلة، نجعل onTap = null
      onTap: enabled ? onTap : null,
      // Hint: نغير اللون قليلاً إذا كانت معطلة
      color: enabled 
          ? null 
          : (isDark 
              ? AppColors.surfaceDark.withOpacity(0.5)
              : AppColors.surfaceLight.withOpacity(0.5)),
      child: Row(
        children: [
          // ============= الأيقونة =============
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: AppConstants.borderRadiusMd,
            ),
            child: Icon(
              icon,
              color: color,
              size: AppConstants.iconSizeLg,
            ),
          ),

          const SizedBox(width: AppConstants.spacingLg),

          // ============= العنوان والوصف =============
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    // Hint: نخفف اللون إذا كانت معطلة
                    color: enabled 
                        ? null 
                        : (isDark 
                            ? AppColors.textHintDark 
                            : AppColors.textHintLight),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXs),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark 
                        ? AppColors.textSecondaryDark 
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: AppConstants.spacingMd),

          // ============= مؤشر التحميل أو السهم =============
          // Hint: AnimatedSwitcher يعطي تأثير انتقال سلس
          AnimatedSwitcher(
            duration: AppConstants.animationNormal,
            child: isLoading
                // --- حالة التحميل ---
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                // --- حالة عادية ---
                : Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: enabled
                        ? (isDark 
                            ? AppColors.textSecondaryDark 
                            : AppColors.textSecondaryLight)
                        : (isDark 
                            ? AppColors.textHintDark 
                            : AppColors.textHintLight),
                  ),
          ),
        ],
      ),
    );
  }
}