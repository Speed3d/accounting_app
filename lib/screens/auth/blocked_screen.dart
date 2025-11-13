// lib/screens/auth/blocked_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../services/device_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_button.dart';

/// 🚫 شاشة الحظر عند كشف التلاعب بالوقت
/// ← Hint: تعرض معلومات الدعم الفني للمستخدم
class BlockedScreen extends StatefulWidget {
  final String reason;        // سبب الحظر
  final String? message;      // رسالة إضافية

  const BlockedScreen({
    super.key,
    required this.reason,
    this.message,
  });

  @override
  State<BlockedScreen> createState() => _BlockedScreenState();
}

class _BlockedScreenState extends State<BlockedScreen> {
  String _deviceFingerprint = '';

  // ← Hint: معلومات الدعم الفني
  static const String supportName = 'سنان اياد جميل';
  static const String supportEmail = 'senanXsh@gmail.com';
  static const String supportPhone = '07700270555';
  static const String supportPhoneWithCode = '+9647700270555'; // للواتساب
  static const String supportFacebook = 'https://www.facebook.com/hardlovesniper';

  @override
  void initState() {
    super.initState();
    _loadDeviceFingerprint();
  }

  // ==========================================================================
  // ← Hint: تحميل بصمة الجهاز
  // ==========================================================================
  Future<void> _loadDeviceFingerprint() async {
    try {
      final fingerprint = await DeviceService.instance.getDeviceFingerprint();
      if (mounted) {
        setState(() {
          _deviceFingerprint = fingerprint;
        });
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل بصمة الجهاز: $e');
    }
  }

  // ==========================================================================
  // ← Hint: نسخ بصمة الجهاز
  // ==========================================================================
  void _copyFingerprint() {
    Clipboard.setData(ClipboardData(text: _deviceFingerprint));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم نسخ بصمة الجهاز إلى الحافظة'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ==========================================================================
  // ← Hint: فتح البريد الإلكتروني
  // ==========================================================================
  Future<void> _openEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: {
        'subject': 'طلب إعادة تفعيل التطبيق',
        'body': 'مرحباً،\n\n'
            'أحتاج لإعادة تفعيل التطبيق بسبب: ${widget.reason}\n\n'
            'بصمة الجهاز: $_deviceFingerprint\n\n'
            'شكراً لك.',
      },
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showError('لا يمكن فتح تطبيق البريد الإلكتروني');
      }
    } catch (e) {
      _showError('خطأ في فتح البريد: $e');
    }
  }

  // ==========================================================================
  // ← Hint: فتح واتساب
  // ==========================================================================
  Future<void> _openWhatsApp() async {
    final message = Uri.encodeComponent(
      'مرحباً،\n\n'
      'أحتاج لإعادة تفعيل التطبيق بسبب: ${widget.reason}\n\n'
      'بصمة الجهاز: $_deviceFingerprint\n\n'
      'شكراً لك.'
    );

    final uri = Uri.parse('https://wa.me/$supportPhoneWithCode?text=$message');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showError('لا يمكن فتح واتساب');
      }
    } catch (e) {
      _showError('خطأ في فتح واتساب: $e');
    }
  }

  // ==========================================================================
  // ← Hint: فتح صفحة الفيسبوك
  // ==========================================================================
  Future<void> _openFacebook() async {
    final uri = Uri.parse(supportFacebook);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showError('لا يمكن فتح الفيسبوك');
      }
    } catch (e) {
      _showError('خطأ في فتح الفيسبوك: $e');
    }
  }

  // ==========================================================================
  // ← Hint: الاتصال بالهاتف
  // ==========================================================================
  Future<void> _makePhoneCall() async {
    final uri = Uri(scheme: 'tel', path: supportPhone);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showError('لا يمكن إجراء المكالمة');
      }
    } catch (e) {
      _showError('خطأ في إجراء المكالمة: $e');
    }
  }

  // ==========================================================================
  // ← Hint: عرض رسالة خطأ
  // ==========================================================================
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      // ← Hint: منع الرجوع من شاشة الحظر
      onWillPop: () async => false,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: isDark 
                ? AppColors.gradientDark 
                : AppColors.gradientLight,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: context.isMobile 
                    ? AppConstants.spacingLg 
                    : AppConstants.spacingXl,
                  vertical: AppConstants.spacingXl,
                ),
                child: _buildBlockedContent(l10n, isDark),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlockedContent(AppLocalizations l10n, bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 550),
      padding: AppConstants.paddingXl,
      decoration: BoxDecoration(
        color: isDark
          ? AppColors.cardDark.withOpacity(0.5)
          : Colors.white.withOpacity(0.9),
        borderRadius: AppConstants.borderRadiusXl,
        border: Border.all(
          color: isDark
            ? AppColors.borderDark.withOpacity(0.5)
            : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ← Hint: أيقونة الحظر
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.block,
              size: 80,
              color: AppColors.error,
            ),
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // ← Hint: العنوان
          Text(
            l10n.appBlocked,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.error,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppConstants.spacingMd),

          // ← Hint: الوصف
          Text(
            l10n.appBlockedDescription,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppConstants.spacingXl),

          // ← Hint: قسم الأسباب
          _buildReasonsSection(isDark),

          const SizedBox(height: AppConstants.spacingXl),

          // ← Hint: قسم بصمة الجهاز
          _buildFingerprintSection(isDark),

          const SizedBox(height: AppConstants.spacingXl),

          // ← Hint: قسم معلومات الدعم
          _buildSupportSection(l10n, isDark),

          const SizedBox(height: AppConstants.spacingXl),

          // ← Hint: أزرار الاتصال
          _buildContactButtons(),
        ],
      ),
    );
  }

  // ==========================================================================
  // ← Hint: قسم الأسباب المحتملة
  // ==========================================================================
  Widget _buildReasonsSection(bool isDark) {
    return Container(
      padding: AppConstants.paddingMd,
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
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Text(
                'الأسباب المحتملة:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm),
          _buildReasonItem('• تم تغيير تاريخ ووقت الجهاز'),
          _buildReasonItem('• محاولات متكررة للتلاعب'),
          _buildReasonItem('• محاولة التلاعب بملفات التطبيق'),
          if (widget.message != null) ...[
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              'التفاصيل: ${widget.message}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.warning,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReasonItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  // ==========================================================================
  // ← Hint: قسم بصمة الجهاز
  // ==========================================================================
  Widget _buildFingerprintSection(bool isDark) {
    return Container(
      padding: AppConstants.paddingMd,
      decoration: BoxDecoration(
        color: isDark 
          ? AppColors.surfaceDark 
          : AppColors.surfaceLight,
        borderRadius: AppConstants.borderRadiusMd,
        border: Border.all(
          color: isDark 
            ? AppColors.borderDark 
            : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'بصمة الجهاز (Device ID):',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  _deviceFingerprint.isNotEmpty 
                    ? _deviceFingerprint 
                    : 'جاري التحميل...',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: _deviceFingerprint.isNotEmpty 
                  ? _copyFingerprint 
                  : null,
                tooltip: 'نسخ',
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingXs),
          Text(
            'قم بنسخ هذه البصمة وإرسالها للدعم الفني',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // ← Hint: قسم معلومات الدعم
  // ==========================================================================
  Widget _buildSupportSection(AppLocalizations l10n, bool isDark) {
    return Container(
      padding: AppConstants.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: AppConstants.borderRadiusMd,
        border: Border.all(
          color: AppColors.info.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.support_agent,
                color: AppColors.info,
                size: 24,
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Text(
                l10n.technicalSupport,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMd),
          _buildSupportInfoItem(Icons.person, supportName),
          _buildSupportInfoItem(Icons.email, supportEmail),
          _buildSupportInfoItem(Icons.phone, supportPhone),
        ],
      ),
    );
  }

  Widget _buildSupportInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.info),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: SelectableText(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // ← Hint: أزرار الاتصال
  // ==========================================================================
  Widget _buildContactButtons() {
    return Column(
      children: [
        // ← Hint: زر واتساب
        CustomButton(
          text: 'تواصل عبر واتساب',
          icon: Icons.chat,
          onPressed: _openWhatsApp,
          type: ButtonType.primary,
          size: ButtonSize.large,
        ),

        const SizedBox(height: AppConstants.spacingMd),

        // ← Hint: صف الأزرار الأخرى
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'البريد',
                icon: Icons.email,
                onPressed: _openEmail,
                type: ButtonType.secondary,
                size: ButtonSize.medium,
              ),
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Expanded(
              child: CustomButton(
                text: 'اتصال',
                icon: Icons.phone,
                onPressed: _makePhoneCall,
                type: ButtonType.secondary,
                size: ButtonSize.medium,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppConstants.spacingSm),

        // ← Hint: زر فيسبوك
        TextButton.icon(
          onPressed: _openFacebook,
          icon: const Icon(Icons.facebook, size: 20),
          label: const Text('تواصل عبر فيسبوك'),
        ),
      ],
    );
  }
}