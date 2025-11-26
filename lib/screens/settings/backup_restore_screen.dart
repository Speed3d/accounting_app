// lib/screens/settings/backup_restore_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/backup_service.dart';
import '../../data/database_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';

/// 💾 شاشة النسخ الاحتياطي والاستعادة
/// ← Hint: صفحة فرعية مهمة جداً - تتيح للمستخدم حفظ واستعادة بياناته
/// ← Hint: تم تحديثها لتشمل خيارات ذكية لدمج المستخدمين
class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  // ============= المتغيرات =============
  /// ← Hint: متغير لتتبع حالة إنشاء النسخة الاحتياطية
  bool _isBackingUp = false;
  
  /// ← Hint: متغير لتتبع حالة الاستعادة
  bool _isRestoring = false;
  
  /// ← Hint: خدمة النسخ الاحتياطي
  final BackupService _backupService = BackupService();
  
  /// ← Hint: helper قاعدة البيانات للحصول على عدد المستخدمين
  final DatabaseHelper dbHelper = DatabaseHelper.instance;
  
  /// ← Hint: متغيرات لتخزين معلومات آخر نسخة احتياطية تم إنشاؤها
  String? _lastBackupFilePath;
  String? _lastBackupFileName;

  // ============= الدوال =============

  /// ← Hint: إنشاء نسخة احتياطية بسيطة (قاعدة بيانات + صور) - بدون كلمة سر
  Future<void> _handleCreateBackup() async {
    final l10n = AppLocalizations.of(context)!;

    // ← Hint: تأكيد بسيط قبل البدء
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إنشاء نسخة احتياطية'),
        content: const Text(
          'سيتم نسخ:\n'
          '• جميع البيانات من قاعدة البيانات\n'
          '• جميع الصور\n'
          '• جميع المستخدمين والصلاحيات\n\n'
          'النسخة لن تكون مشفرة بكلمة سر.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('إنشاء النسخة'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isBackingUp = true);

    // ← Hint: متغيرات لتتبع التقدم
    String currentStatus = '';
    int currentStep = 0;
    int totalSteps = 6;

    try {
      // ← Hint: استدعاء النسخ الاحتياطي البسيط (قاعدة بيانات + صور)
      final result = await _backupService.createSimpleBackup(
        onProgress: (status, current, total) {
          if (mounted) {
            setState(() {
              currentStatus = status;
              currentStep = current;
              totalSteps = total;
            });
          }
        },
      );

      if (mounted) {
        setState(() => _isBackingUp = false);

        if (result['status'] == 'success') {
          // ← Hint: حفظ معلومات الملف المنشأ
          final filePath = result['file_path'] as String;
          final fileName = filePath.split('/').last;

          setState(() {
            _lastBackupFilePath = filePath;
            _lastBackupFileName = fileName;
          });

          // ← Hint: عرض رسالة نجاح مع موقع الملف وعدد الصور
          _showSimpleSuccessDialog(
            l10n,
            filePath,
            fileName,
            result['total_images'] as int? ?? 0,
            result['file_size_formatted'] as String? ?? '',
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
  void _showSuccessDialog(
    AppLocalizations l10n,
    String filePath,
    String fileName, {
    int imagesCount = 0,
  }) {
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

            // ← Hint: عرض عدد الصور إذا كان أكبر من 0
            if (imagesCount > 0) ...[
              const SizedBox(height: AppConstants.spacingSm),
              Container(
                padding: AppConstants.paddingSm,
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: AppConstants.borderRadiusSm,
                  border: Border.all(
                    color: AppColors.info.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 16,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                    Expanded(
                      child: Text(
                        'تم حفظ $imagesCount صورة',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

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

  /// ← Hint: استعادة نسخة احتياطية بسيطة مع خيار دمج المستخدمين - بدون كلمة سر
  Future<void> _handleRestoreBackup() async {
    final l10n = AppLocalizations.of(context)!;

    // ============= الخطوة 1: اختيار ملف النسخة الاحتياطية =============
    print("🔹 الخطوة 1: اختيار الملف");
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      dialogTitle: 'اختر ملف النسخة الاحتياطية',
    );

    if (result == null || result.files.single.path == null) {
      print("ℹ️ تم إلغاء اختيار الملف");
      return;
    }

    final backupFilePath = result.files.single.path!;
    print("✅ تم اختيار الملف: $backupFilePath");

    // ============= الخطوة 2: عرض خيارات الاستعادة =============
    print("🔹 الخطوة 2: عرض خيارات الاستعادة");

    final mergeUsers = await _showSimpleRestoreOptionsDialog();

    if (mergeUsers == null) {
      print("ℹ️ تم إلغاء عملية الاستعادة");
      return;
    }

    print("✅ الخيار المختار: ${mergeUsers ? 'دمج المستخدمين' : 'استبدال المستخدمين'}");

    // ============= الخطوة 3: تأكيد نهائي =============
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ تأكيد الاستعادة'),
        content: Text(
          mergeUsers
              ? 'سيتم:\n'
                  '• استعادة جميع البيانات والصور\n'
                  '• دمج المستخدمين من النسخة مع المستخدمين الحاليين\n'
                  '• الاحتفاظ بالصلاحيات\n\n'
                  'هل تريد المتابعة؟'
              : 'سيتم:\n'
                  '• حذف جميع البيانات الحالية\n'
                  '• استبدالها بالبيانات من النسخة الاحتياطية\n'
                  '• استبدال المستخدمين\n\n'
                  '⚠️ هذا الإجراء لا يمكن التراجع عنه!\n\n'
                  'هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('تأكيد الاستعادة'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      print("ℹ️ تم إلغاء التأكيد النهائي");
      return;
    }

    // ============= الخطوة 4: تنفيذ الاستعادة =============
    print("🔹 الخطوة 4: بدء الاستعادة الفعلية");
    setState(() => _isRestoring = true);

    // ← Hint: متغيرات لتتبع التقدم
    String currentStatus = '';
    int currentStep = 0;
    int totalSteps = 7;

    try {
      final result = await _backupService.restoreSimpleBackup(
        filePath: backupFilePath,
        mergeUsers: mergeUsers,
        onProgress: (status, current, total) {
          if (mounted) {
            setState(() {
              currentStatus = status;
              currentStep = current;
              totalSteps = total;
            });
            print("📊 التقدم: $status ($current/$total)");
          }
        },
      );

      if (!mounted) return;

      setState(() => _isRestoring = false);

      if (result['status'] == 'success') {
        // ============= نجحت الاستعادة =============
        print("✅ نجحت الاستعادة");

        final totalImages = result['total_images'] as int? ?? 0;
        String successMessage = 'تمت استعادة النسخة الاحتياطية بنجاح!\n\n';

        if (totalImages > 0) {
          successMessage += '📷 تم استعادة $totalImages صورة\n';
        }

        if (mergeUsers) {
          successMessage += '👥 تم دمج المستخدمين مع الصلاحيات';
        } else {
          successMessage += '👥 تم استبدال المستخدمين';
        }

        await _showSimpleRestoreSuccessDialog(successMessage);

      } else {
        // ============= فشلت الاستعادة =============
        print("❌ فشلت الاستعادة: ${result['message']}");
        _showErrorSnackBar(result['message'] ?? 'فشل في استعادة النسخة الاحتياطية');
      }

    } catch (e) {
      print('❌ خطأ غير متوقع: $e');

      if (mounted) {
        setState(() => _isRestoring = false);
        _showErrorSnackBar('خطأ: ${e.toString()}');
      }
    }
  }

  // ==========================================================================
  // ← Hint: دالة جديدة - حوار اختيار طريقة دمج المستخدمين
  // ==========================================================================
  Future<String?> _showUserMergeDialog(
    AppLocalizations l10n,
    int currentCount,
    int backupCount,
  ) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.people_alt,
              color: AppColors.warning,
              size: 28,
            ),
            const SizedBox(width: AppConstants.spacingMd),
            Expanded(child: Text(l10n.userMergeTitle)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ← Hint: رسالة توضيحية
              Text(
                l10n.userMergeMessage(currentCount),
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: AppConstants.spacingLg),

              // ← Hint: الخيار 1 - دمج المستخدمين (الموصى به)
              _buildMergeOption(
                ctx,
                title: l10n.mergeUsers,
                subtitle: l10n.mergeUsersDescription,
                icon: Icons.merge_type,
                color: AppColors.success,
                isRecommended: true,
                onTap: () => Navigator.of(ctx).pop('merge'),
              ),

              const SizedBox(height: AppConstants.spacingMd),

              // ← Hint: الخيار 2 - الاحتفاظ بالمستخدمين الحاليين
              _buildMergeOption(
                ctx,
                title: l10n.keepCurrentUsers,
                subtitle: l10n.keepCurrentUsersDescription,
                icon: Icons.shield,
                color: AppColors.info,
                isRecommended: false,
                onTap: () => Navigator.of(ctx).pop('keep'),
              ),

              const SizedBox(height: AppConstants.spacingMd),

              // ← Hint: الخيار 3 - استبدال الكل (خطر)
              _buildMergeOption(
                ctx,
                title: l10n.replaceAllUsers,
                subtitle: l10n.replaceAllUsersDescription,
                icon: Icons.warning_amber,
                color: AppColors.error,
                isRecommended: false,
                onTap: () => Navigator.of(ctx).pop('replace'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // ← Hint: دالة مساعدة - بناء خيار الدمج
  // ==========================================================================
  Widget _buildMergeOption(
    BuildContext ctx, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isRecommended,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppConstants.borderRadiusMd,
      child: Container(
        padding: AppConstants.paddingMd,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: AppConstants.borderRadiusMd,
          border: Border.all(
            color: color.withOpacity(0.3),
            width: isRecommended ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // ← Hint: الأيقونة
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingSm),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),

            const SizedBox(width: AppConstants.spacingMd),

            // ← Hint: العنوان والوصف
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                      // ← Hint: شارة "موصى به"
                      if (isRecommended)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: AppConstants.borderRadiusFull,
                          ),
                          child: const Text(
                            '✓ موصى به',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingXs),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppConstants.spacingSm),

            // ← Hint: سهم
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // ← Hint: دالة جديدة - حوار التأكيد النهائي
  // ==========================================================================
  Future<bool?> _showFinalConfirmDialog(
    AppLocalizations l10n,
    String mergeOption,
  ) async {
    String warningMessage = '';
    Color warningColor = AppColors.info;

    if (mergeOption == 'merge') {
      warningMessage = l10n.permissionsWillBePreserved;
      warningColor = AppColors.success;
    } else if (mergeOption == 'replace') {
      warningMessage = l10n.allDataWillBeReplaced;
      warningColor = AppColors.error;
    } else {
      warningMessage = l10n.permissionsWillBePreserved;
      warningColor = AppColors.info;
    }

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: warningColor,
              size: 28,
            ),
            const SizedBox(width: AppConstants.spacingMd),
            Expanded(child: Text(l10n.restoreConfirmTitle)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.restoreConfirmContent,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Container(
              padding: AppConstants.paddingSm,
              decoration: BoxDecoration(
                color: warningColor.withOpacity(0.1),
                borderRadius: AppConstants.borderRadiusSm,
                border: Border.all(
                  color: warningColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: warningColor,
                  ),
                  const SizedBox(width: AppConstants.spacingSm),
                  Expanded(
                    child: Text(
                      warningMessage,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: warningColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: warningColor,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.restore),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // ← Hint: دالة جديدة - حوار نجاح الاستعادة
  // ==========================================================================
  Future<void> _showRestoreSuccessDialog(
    AppLocalizations l10n,
    String message,
  ) async {
    return showDialog(
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
          message,
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
  }

  // ==========================================================================
  // ← Hint: دوال مساعدة جديدة للنظام البسيط
  // ==========================================================================

  /// عرض نافذة نجاح إنشاء النسخة الاحتياطية البسيطة
  void _showSimpleSuccessDialog(
    AppLocalizations l10n,
    String filePath,
    String fileName,
    int imagesCount,
    String fileSize,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('تم إنشاء النسخة بنجاح'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📁 اسم الملف: $fileName'),
            const SizedBox(height: 8),
            Text('💾 الحجم: $fileSize'),
            const SizedBox(height: 8),
            Text('📷 عدد الصور: $imagesCount'),
            const SizedBox(height: 8),
            Text('📂 المسار: $filePath', style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  /// عرض نافذة خيارات الاستعادة البسيطة
  Future<bool?> _showSimpleRestoreOptionsDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('خيارات الاستعادة'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اختر طريقة استعادة المستخدمين:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('• استعادة البيانات والصور فقط:'),
            Text('  سيتم حذف المستخدمين القدامى واستبدالهم',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            SizedBox(height: 12),
            Text('• استعادة البيانات والصور + دمج المستخدمين:'),
            Text('  سيتم الاحتفاظ بالمستخدمين الحاليين ودمج الجدد',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('استبدال المستخدمين'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('دمج المستخدمين'),
          ),
        ],
      ),
    );
  }

  /// عرض نافذة نجاح الاستعادة البسيطة
  Future<void> _showSimpleRestoreSuccessDialog(String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('نجحت الاستعادة'),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // الخروج من التطبيق لإعادة تحميل البيانات
              SystemChannels.platform.invokeMethod('SystemNavigator.pop');
            },
            child: const Text('إعادة تشغيل التطبيق'),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // ← Hint: دالة مساعدة - عرض رسالة خطأ
  // ==========================================================================
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppConstants.borderRadiusMd,
        ),
      ),
    );
  }

  // ==========================================================
  // ← Hint: دالة لعرض نافذة إدخال كلمة المرور بشكل احترافي
  // ==========================================================
  /// [title] عنوان النافذة
  /// [subtitle] الوصف التوضيحي
  /// [isConfirmation] هل نحتاج تأكيد لكلمة المرور (عند الإنشاء نعم، عند الاستعادة لا)
  ///
  /// ← Hint: تُرجع كلمة المرور إذا أدخلها المستخدم، أو null إذا ألغى
  Future<String?> _showPasswordDialog({
    required String title,
    required String subtitle,
    required bool isConfirmation,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    // ← Hint: Controllers لحقول كلمة المرور
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    // ← Hint: متغيرات لإظهار/إخفاء كلمة المرور
    bool obscurePassword = true;
    bool obscureConfirmPassword = true;

    // ← Hint: متغير لتتبع الأخطاء
    String? errorMessage;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  color: AppColors.info,
                  size: 28,
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ← Hint: الوصف التوضيحي
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingLg),

                  // ← Hint: حقل كلمة المرور
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: l10n.password,
                      hintText: l10n.enterPassword,
                      prefixIcon: const Icon(Icons.vpn_key),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                      errorText: errorMessage,
                    ),
                    onChanged: (_) {
                      // ← Hint: إزالة رسالة الخطأ عند الكتابة
                      if (errorMessage != null) {
                        setDialogState(() => errorMessage = null);
                      }
                    },
                  ),

                  // ← Hint: حقل تأكيد كلمة المرور (فقط عند الإنشاء)
                  if (isConfirmation) ...[
                    const SizedBox(height: AppConstants.spacingMd),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: l10n.confirmPassword,
                        hintText: l10n.reEnterPassword,
                        prefixIcon: const Icon(Icons.vpn_key_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscureConfirmPassword = !obscureConfirmPassword;
                            });
                          },
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        // ← Hint: إزالة رسالة الخطأ عند الكتابة
                        if (errorMessage != null) {
                          setDialogState(() => errorMessage = null);
                        }
                      },
                    ),
                  ],

                  // ← Hint: نصيحة للمستخدم
                  const SizedBox(height: AppConstants.spacingMd),
                  Container(
                    padding: AppConstants.paddingSm,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: AppConstants.borderRadiusSm,
                      border: Border.all(
                        color: AppColors.warning.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: AppConstants.spacingSm),
                        Expanded(
                          child: Text(
                            l10n.passwordTip,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // ← Hint: زر الإلغاء
              TextButton(
                onPressed: () {
                  passwordController.dispose();
                  confirmPasswordController.dispose();
                  Navigator.of(ctx).pop(null);
                },
                child: Text(l10n.cancel),
              ),

              // ← Hint: زر التأكيد
              ElevatedButton(
                onPressed: () {
                  final password = passwordController.text;

                  // ← Hint: التحقق من أن كلمة المرور ليست فارغة
                  if (password.trim().isEmpty) {
                    setDialogState(() {
                      errorMessage = l10n.passwordCannotBeEmpty;
                    });
                    return;
                  }

                  // ← Hint: التحقق من الحد الأدنى لطول كلمة المرور
                  if (password.length < 4) {
                    setDialogState(() {
                      errorMessage = l10n.passwordTooShort;
                    });
                    return;
                  }

                  // ← Hint: التحقق من تطابق كلمتي المرور (فقط عند الإنشاء)
                  if (isConfirmation) {
                    final confirmPassword = confirmPasswordController.text;
                    if (password != confirmPassword) {
                      setDialogState(() {
                        errorMessage = l10n.passwordsDoNotMatch;
                      });
                      return;
                    }
                  }

                  // ← Hint: كل شيء على ما يرام، نرجع كلمة المرور
                  passwordController.dispose();
                  confirmPasswordController.dispose();
                  Navigator.of(ctx).pop(password);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.info,
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.confirm),
              ),
            ],
          );
        },
      ),
    );

    return result;
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
// ← Hint: ويدجت مخصصة جميلة لعرض خيارات النسخ الاحتياطي
// ============================================================
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
      // ← Hint: إذا كانت معطلة، نجعل onTap = null
      onTap: enabled ? onTap : null,
      // ← Hint: نغير اللون قليلاً إذا كانت معطلة
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
                    // ← Hint: نخفف اللون إذا كانت معطلة
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
          // ← Hint: AnimatedSwitcher يعطي تأثير انتقال سلس
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