// 💾 lib/screens/settings/backup_restore_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/backup_service.dart';
import '../../services/encryption_service.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';

/// 💾 شاشة النسخ الاحتياطي والاستعادة - الإصدار 2.0
///
/// ← Hint: واجهة جديدة كلياً لنظام النسخ الاحتياطي المشفر
/// ← Hint: تدعم كلمة السر وتقييم قوتها
/// ← Hint: واجهة جميلة وسهلة الاستخدام
///
/// 📝 للمستقبل:
/// - إضافة dark mode support محسّن
/// - إضافة animation effects
/// - إضافة backup history
/// - إضافة cloud backup integration
class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  // ============================================================================
  // 🔧 المتغيرات
  // ============================================================================

  /// ← Hint: حالة النسخ الاحتياطي
  bool _isBackingUp = false;

  /// ← Hint: حالة الاستعادة
  bool _isRestoring = false;

  /// ← Hint: خدمة النسخ الاحتياطي
  final BackupService _backupService = BackupService();

  /// ← Hint: معلومات آخر نسخة تم إنشاؤها
  String? _lastBackupFilePath;
  String? _lastBackupFileName;

  /// ← Hint: progress للعمليات
  String _currentStatus = '';
  int _currentStep = 0;
  int _totalSteps = 0;

  // ============================================================================
  // 💾 إنشاء نسخة احتياطية
  // ============================================================================

  /// معالج إنشاء نسخة احتياطية مشفرة
  ///
  /// ← Hint: يطلب كلمة سر من المستخدم
  /// ← Hint: يعرض قوة كلمة السر
  /// ← Hint: ينشئ نسخة مشفرة بالكامل
  Future<void> _handleCreateBackup() async {
    final l10n = AppLocalizations.of(context)!;

    // ══════════════════════════════════════════════════════════
    // 1️⃣ طلب كلمة السر
    // ══════════════════════════════════════════════════════════

    final password = await _showPasswordDialog(
      title: 'تأمين النسخة الاحتياطية',
      subtitle: 'أدخل كلمة سر قوية لحماية بياناتك',
      isConfirmation: true,
    );

    if (password == null) return;

    // ══════════════════════════════════════════════════════════
    // 2️⃣ تأكيد النسخ الاحتياطي
    // ══════════════════════════════════════════════════════════

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.backup_rounded, color: Colors.blue),
            SizedBox(width: 12),
            Text('إنشاء نسخة احتياطية'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('سيتم نسخ:'),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 18),
                SizedBox(width: 8),
                Text('✓ جميع البيانات من قاعدة البيانات'),
              ],
            ),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 18),
                SizedBox(width: 8),
                Text('✓ جميع الصور'),
              ],
            ),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 18),
                SizedBox(width: 8),
                Text('✓ جميع ملفات PDF'),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.lock_rounded, color: Colors.orange, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text('النسخة ستكون مشفرة بالكامل')),
              ],
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
            child: const Text('إنشاء النسخة'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // ══════════════════════════════════════════════════════════
    // 3️⃣ بدء عملية النسخ الاحتياطي
    // ══════════════════════════════════════════════════════════

    setState(() {
      _isBackingUp = true;
      _currentStatus = 'جاري البدء...';
      _currentStep = 0;
      _totalSteps = 10;
    });

    try {
      final result = await _backupService.createEncryptedBackup(
        password: password,
        onProgress: (status, current, total) {
          if (mounted) {
            setState(() {
              _currentStatus = status;
              _currentStep = current;
              _totalSteps = total;
            });
          }
        },
      );

      if (!mounted) return;

      setState(() => _isBackingUp = false);

      if (result['status'] == 'success') {
        // ← Hint: حفظ معلومات الملف
        setState(() {
          _lastBackupFilePath = result['file_path'];
          _lastBackupFileName = result['file_name'];
        });

        // ← Hint: عرض نافذة النجاح
        await _showSuccessDialog(
          title: 'تمت العملية بنجاح!',
          content: 'تم إنشاء النسخة الاحتياطية المشفرة بنجاح',
          details: [
            'اسم الملف: ${result['file_name']}',
            'الحجم: ${result['file_size_formatted']}',
            'الصور: ${result['total_images']} صورة',
            'PDF: ${result['total_pdfs']} ملف',
            'قوة التشفير: ${result['password_strength']}',
          ],
          filePath: result['file_path'],
        );
      } else {
        _showErrorSnackBar(result['message'] ?? 'فشل في إنشاء النسخة');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBackingUp = false);
        _showErrorSnackBar('خطأ: ${e.toString()}');
      }
    }
  }

  // ============================================================================
  // 🔄 استعادة نسخة احتياطية
  // ============================================================================

  /// معالج استعادة نسخة احتياطية مشفرة
  ///
  /// ← Hint: يطلب اختيار ملف
  /// ← Hint: يطلب كلمة السر
  /// ← Hint: يستعيد كل شيء
  Future<void> _handleRestoreBackup() async {
    final l10n = AppLocalizations.of(context)!;

    // ══════════════════════════════════════════════════════════
    // 1️⃣ اختيار ملف النسخة الاحتياطية
    // ══════════════════════════════════════════════════════════

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['aab', 'zip'],
      dialogTitle: 'اختر ملف النسخة الاحتياطية',
    );

    if (result == null || result.files.single.path == null) {
      return;
    }

    final backupFilePath = result.files.single.path!;
    final backupFileName = backupFilePath.split('/').last;

    // ══════════════════════════════════════════════════════════
    // 2️⃣ عرض معلومات النسخة (إن أمكن)
    // ══════════════════════════════════════════════════════════

    final backupInfo = await _backupService.getBackupInfo(backupFilePath);

    if (backupInfo['status'] != 'success') {
      _showErrorSnackBar('فشل في قراءة معلومات النسخة: ${backupInfo['message']}');
      return;
    }

    // ══════════════════════════════════════════════════════════
    // 3️⃣ طلب كلمة السر
    // ══════════════════════════════════════════════════════════

    final password = await _showPasswordDialog(
      title: 'استعادة النسخة الاحتياطية',
      subtitle: 'أدخل كلمة السر المستخدمة عند إنشاء النسخة',
      isConfirmation: false,
    );

    if (password == null) return;

    // ══════════════════════════════════════════════════════════
    // 4️⃣ تأكيد نهائي
    // ══════════════════════════════════════════════════════════

    final confirmRestore = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('⚠️ تأكيد الاستعادة'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'سيتم:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('• حذف جميع البيانات الحالية'),
            const Text('• استبدالها بالبيانات من النسخة الاحتياطية'),
            const Text('• استبدال جميع الصور'),
            const Text('• استبدال جميع ملفات PDF'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⚠️ هذا الإجراء لا يمكن التراجع عنه!',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'الملف: $backupFileName',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              'الحجم: ${backupInfo['file_size_formatted']}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
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
              backgroundColor: Colors.orange,
            ),
            child: const Text('تأكيد الاستعادة'),
          ),
        ],
      ),
    );

    if (confirmRestore != true) return;

    // ══════════════════════════════════════════════════════════
    // 5️⃣ بدء عملية الاستعادة
    // ══════════════════════════════════════════════════════════

    setState(() {
      _isRestoring = true;
      _currentStatus = 'جاري البدء...';
      _currentStep = 0;
      _totalSteps = 11;
    });

    try {
      final restoreResult = await _backupService.restoreEncryptedBackup(
        filePath: backupFilePath,
        password: password,
        onProgress: (status, current, total) {
          if (mounted) {
            setState(() {
              _currentStatus = status;
              _currentStep = current;
              _totalSteps = total;
            });
          }
        },
      );

      if (!mounted) return;

      setState(() => _isRestoring = false);

      if (restoreResult['status'] == 'success') {
        await _showRestoreSuccessDialog(
          'تمت استعادة النسخة الاحتياطية بنجاح!\n\n'
          '📷 تم استعادة ${restoreResult['total_images']} صورة\n'
          '📄 تم استعادة ${restoreResult['total_pdfs']} ملف PDF',
        );
      } else {
        _showErrorSnackBar(restoreResult['message'] ?? 'فشل في الاستعادة');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRestoring = false);
        _showErrorSnackBar('خطأ: ${e.toString()}');
      }
    }
  }

  // ============================================================================
  // 🎨 نوافذ الحوار
  // ============================================================================

  /// نافذة إدخال كلمة السر
  ///
  /// ← Hint: تعرض مؤشر قوة كلمة السر
  /// ← Hint: تدعم تأكيد كلمة السر
  Future<String?> _showPasswordDialog({
    required String title,
    required String subtitle,
    required bool isConfirmation,
  }) async {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool obscurePassword = true;
    bool obscureConfirmPassword = true;
    String? errorMessage;

    // ← Hint: متغيرات قوة كلمة السر
    int passwordStrength = 0;
    String strengthText = '';
    String strengthFeedback = '';

    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.lock_outline, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(child: Text(title)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ← Hint: الوصف
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  // ← Hint: حقل كلمة السر
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'كلمة السر',
                      hintText: 'أدخل كلمة سر قوية',
                      prefixIcon: const Icon(Icons.vpn_key),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility : Icons.visibility_off,
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
                    onChanged: (value) {
                      // ← Hint: تحديث قوة كلمة السر
                      final strength = EncryptionService.checkPasswordStrength(value);
                      setDialogState(() {
                        passwordStrength = strength['strength'];
                        strengthText = strength['strengthText'];
                        strengthFeedback = strength['feedback'];
                        if (errorMessage != null) errorMessage = null;
                      });
                    },
                  ),

                  // ← Hint: مؤشر قوة كلمة السر
                  if (passwordController.text.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildPasswordStrengthIndicator(
                      passwordStrength,
                      strengthText,
                      strengthFeedback,
                    ),
                  ],

                  // ← Hint: حقل تأكيد كلمة السر
                  if (isConfirmation) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'تأكيد كلمة السر',
                        hintText: 'أعد إدخال كلمة السر',
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
                    ),
                  ],

                  // ← Hint: نصيحة
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '⚠️ احفظ كلمة السر في مكان آمن!\nلن تتمكن من استعادة البيانات بدونها.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  passwordController.dispose();
                  confirmPasswordController.dispose();
                  Navigator.of(ctx).pop(null);
                },
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  final password = passwordController.text;

                  // ← Hint: التحقق من الطول الأدنى
                  if (password.length < 6) {
                    setDialogState(() {
                      errorMessage = 'كلمة السر يجب أن تكون 6 أحرف على الأقل';
                    });
                    return;
                  }

                  // ← Hint: التحقق من التطابق
                  if (isConfirmation) {
                    final confirmPassword = confirmPasswordController.text;
                    if (password != confirmPassword) {
                      setDialogState(() {
                        errorMessage = 'كلمتا السر غير متطابقتين';
                      });
                      return;
                    }
                  }

                  passwordController.dispose();
                  confirmPasswordController.dispose();
                  Navigator.of(ctx).pop(password);
                },
                child: const Text('تأكيد'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// مؤشر قوة كلمة السر
  Widget _buildPasswordStrengthIndicator(
    int strength,
    String strengthText,
    String feedback,
  ) {
    Color getColor() {
      switch (strength) {
        case 0:
        case 1:
          return Colors.red;
        case 2:
          return Colors.orange;
        case 3:
          return Colors.blue;
        case 4:
          return Colors.green;
        default:
          return Colors.grey;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: strength / 4,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(getColor()),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              strengthText,
              style: TextStyle(
                color: getColor(),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          feedback,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  /// نافذة النجاح
  Future<void> _showSuccessDialog({
    required String title,
    required String content,
    required List<String> details,
    String? filePath,
  }) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(content),
            const SizedBox(height: 16),
            ...details.map((detail) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('• $detail', style: const TextStyle(fontSize: 13)),
                )),
            if (filePath != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'المسار:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              Text(
                filePath,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('حسناً'),
          ),
          if (filePath != null)
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _shareBackup(filePath);
              },
              icon: const Icon(Icons.share),
              label: const Text('مشاركة'),
            ),
        ],
      ),
    );
  }

  /// نافذة نجاح الاستعادة
  ///
  /// ← Hint: تغلق التطبيق بالكامل ليُعاد فتحه يدوياً
  /// ← Hint: هذا ضروري لإعادة تهيئة قاعدة البيانات
  Future<void> _showRestoreSuccessDialog(String message) async {
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 16),
            const Text(
              'سيتم إغلاق التطبيق الآن.\nالرجاء فتحه مرة أخرى.',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.orange,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              // ← Hint: إغلاق التطبيق بالكامل
              // ← Hint: المستخدم سيعيد فتحه يدوياً
              exit(0);
            },
            icon: const Icon(Icons.restart_alt),
            label: const Text('إغلاق التطبيق'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// مشاركة ملف النسخة الاحتياطية
  Future<void> _shareBackup(String filePath) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        _showErrorSnackBar('الملف غير موجود');
        return;
      }

      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'نسخة احتياطية - ${filePath.split('/').last}',
      );
    } catch (e) {
      _showErrorSnackBar('خطأ في المشاركة: ${e.toString()}');
    }
  }

  /// عرض رسالة خطأ
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================================
  // 🎨 البناء
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('النسخ الاحتياطي والاستعادة'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // ← Hint: المحتوى الرئيسي
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ← Hint: بطاقة النسخ الاحتياطي
                _buildBackupCard(isDark),

                const SizedBox(height: 16),

                // ← Hint: زر المشاركة (إذا كان هناك ملف)
                if (_lastBackupFilePath != null)
                  ElevatedButton.icon(
                    onPressed: () => _shareBackup(_lastBackupFilePath!),
                    icon: const Icon(Icons.share),
                    label: const Text('مشاركة آخر نسخة'),
                  ),

                const SizedBox(height: 24),

                // ← Hint: بطاقة الاستعادة
                _buildRestoreCard(isDark),

                const Spacer(),

                // ← Hint: معلومات
                _buildInfoBox(isDark),

                const SizedBox(height: 16),
              ],
            ),
          ),

          // ← Hint: شاشة التحميل
          if (_isBackingUp || _isRestoring)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(24),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 24),
                        Text(
                          _isBackingUp ? 'جاري إنشاء النسخة...' : 'جاري الاستعادة...',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _currentStatus,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: _totalSteps > 0 ? _currentStep / _totalSteps : 0,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_currentStep / $_totalSteps',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// بطاقة النسخ الاحتياطي
  Widget _buildBackupCard(bool isDark) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: _isBackingUp || _isRestoring ? null : _handleCreateBackup,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.backup_rounded,
                  color: Colors.blue,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'إنشاء نسخة احتياطية',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'نسخ احتياطي مشفر لجميع البيانات',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// بطاقة الاستعادة
  Widget _buildRestoreCard(bool isDark) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: _isBackingUp || _isRestoring ? null : _handleRestoreBackup,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.restore_rounded,
                  color: Colors.orange,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'استعادة نسخة احتياطية',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'استعادة البيانات من نسخة مشفرة',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// صندوق المعلومات
  Widget _buildInfoBox(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'النسخ الاحتياطي مشفر بالكامل ويمكن نقله لأي جهاز آخر',
              style: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.grey[800],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
