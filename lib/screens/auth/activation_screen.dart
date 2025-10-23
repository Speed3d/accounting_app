// lib/screens/auth/activation_screen.dart

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============= استيراد الملفات =============
import '../../data/database_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'splash_screen.dart';

/// ===========================================================================
/// شاشة تفعيل التطبيق (Activation Screen)
/// ===========================================================================
/// الغرض:
/// - تفعيل التطبيق بعد انتهاء الفترة التجريبية
/// - عرض بصمة الجهاز (Device Fingerprint) للمستخدم
/// - التحقق من كود التفعيل المدخل
/// - تمديد فترة الاستخدام حسب الكود الصحيح
/// ===========================================================================
/// آلية العمل:
/// 1. المستخدم يرسل بصمة الجهاز للمطور
/// 2. المطور يولد كود تفعيل باستخدام: SHA256(fingerprint + duration + secret)
/// 3. المستخدم يدخل الكود في التطبيق
/// 4. التطبيق يتحقق من الكود ويفعّل التطبيق
/// ===========================================================================
class ActivationScreen extends StatefulWidget {
  final AppLocalizations l10n;
  final String deviceFingerprint;  // بصمة الجهاز الفريدة

  const ActivationScreen({
    super.key,
    required this.l10n,
    required this.deviceFingerprint,
  });

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  
  // ============= متغيرات النموذج =============
  final _formKey = GlobalKey<FormState>();
  final _activationCodeController = TextEditingController();
  
  // ============= متغيرات الحالة =============
  bool _isLoading = false;           // حالة التحميل أثناء التحقق من الكود
  
  // ============= الثوابت =============
  /// المفتاح السري المستخدم في توليد أكواد التفعيل
  /// ⚠️ هذا المفتاح يجب أن يكون متطابقاً مع المفتاح في كود المطور
  static const String _secretKey = "MY_APP_SHAHAD_2025_SECRET";

  // ===========================================================================
  // التنظيف عند إغلاق الشاشة
  // ===========================================================================
  @override
  void dispose() {
    _activationCodeController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // معالجة التفعيل
  // ===========================================================================
  Future<void> _handleActivation() async {
    // --- التحقق من صحة النموذج ---
    if (!_formKey.currentState!.validate()) return;

    // --- بدء التحميل ---
    setState(() => _isLoading = true);

    try {
      final enteredCode = _activationCodeController.text.trim().toLowerCase();
      
      // ============= الخطوة 1: المدد المدعومة (بالأيام) =============
      // يمكنك تعديل هذه المدد حسب احتياجك
      const supportedDurations = [
        730,  // سنتان
        545,  // سنة ونصف
        365,  // سنة
        180,  // 6 أشهر
        90,   // 3 أشهر
        30,   // شهر واحد
      ];
      
      int? matchedDuration;

      // ============= الخطوة 2: التحقق من الكود =============
      for (var duration in supportedDurations) {
        // --- توليد الكود المتوقع ---
        final stringToHash = '${widget.deviceFingerprint}-$duration-$_secretKey';
        final bytes = utf8.encode(stringToHash);
        final digest = sha256.convert(bytes);
        final generatedCode = digest.toString();

        // --- مقارنة الكود المدخل مع الكود المتوقع ---
        if (enteredCode == generatedCode) {
          matchedDuration = duration;
          break; // تم العثور على تطابق ✅
        }
      }

      // ============= الخطوة 3: معالجة النتيجة =============
      if (matchedDuration != null) {
        // --- التفعيل ناجح ✅ ---
        await DatabaseHelper.instance.activateApp(
          durationInDays: matchedDuration,
        );

        if (!mounted) return;

        // --- عرض رسالة نجاح ---
        await _showSuccessDialog(matchedDuration);
        
      } else {
        // --- الكود غير صحيح ❌ ---
        if (mounted) {
          _showErrorSnackBar(
            'كود التفعيل غير صحيح أو منتهي الصلاحية. الرجاء المحاولة مرة أخرى.',
          );
        }
      }

    } catch (e) {
      // --- معالجة الأخطاء ---
      if (mounted) {
        _showErrorSnackBar('حدث خطأ أثناء التفعيل: ${e.toString()}');
      }
      debugPrint('❌ خطأ في التفعيل: $e');
    } finally {
      // --- إيقاف التحميل ---
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ===========================================================================
  // عرض رسالة نجاح التفعيل
  // ===========================================================================
  Future<void> _showSuccessDialog(int duration) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // لا يمكن إغلاقه بالنقر خارجه
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppConstants.borderRadiusLg,
        ),
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 28,
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Text(
              widget.l10n.success,
              style: TextStyle(color: AppColors.success),
            ),
          ],
        ),
        content: Text(
          'تم تفعيل التطبيق بنجاح لمدة $duration يوماً!\n'
          'سيتم إعادة تشغيل التطبيق الآن.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              // الانتقال لـ Splash Screen وإزالة جميع الصفحات السابقة
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const SplashScreen(),
                ),
                (route) => false,
              );
            },
            child: Text(widget.l10n.ok),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // عرض رسالة خطأ
  // ===========================================================================
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

  // ===========================================================================
  // نسخ بصمة الجهاز للحافظة
  // ===========================================================================
  void _copyFingerprint() {
    Clipboard.setData(ClipboardData(text: widget.deviceFingerprint));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم نسخ بصمة الجهاز إلى الحافظة'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: AppConstants.borderRadiusMd,
        ),
      ),
    );
  }

  // ===========================================================================
  // بناء واجهة المستخدم
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // ============= الخلفية المتدرجة =============
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
        
        // ============= المحتوى =============
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: context.isMobile 
                  ? AppConstants.spacingLg 
                  : AppConstants.spacingXl,
                vertical: AppConstants.spacingXl,
              ),
              child: _buildActivationForm(isDark),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // بناء نموذج التفعيل
  // ===========================================================================
  Widget _buildActivationForm(bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
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
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- رأس الصفحة ---
            _buildHeader(isDark),
            
            const SizedBox(height: AppConstants.spacingXl),
            
            // --- بصمة الجهاز ---
            _buildFingerprintSection(isDark),
            
            const SizedBox(height: AppConstants.spacingXl),
            
            // --- حقل كود التفعيل ---
            CustomTextField(
              controller: _activationCodeController,
              label: 'كود التفعيل',
              hint: 'أدخل كود التفعيل هنا',
              prefixIcon: Icons.vpn_key,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'حقل كود التفعيل لا يمكن أن يكون فارغاً';
                }
                return null;
              },
            ),
            
            const SizedBox(height: AppConstants.spacingLg),
            
            // --- ملاحظة ---
            _buildInstructionsNote(isDark),
            
            const SizedBox(height: AppConstants.spacingXl),
            
            // --- زر التفعيل ---
            CustomButton(
              text: 'تفعيل التطبيق',
              icon: Icons.check_circle_outline,
              onPressed: _handleActivation,
              isLoading: _isLoading,
              type: ButtonType.primary,
              size: ButtonSize.large,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // بناء رأس الصفحة
  // ===========================================================================
  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        // أيقونة القفل مع الساعة
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.lock_clock,
            size: 50,
            color: AppColors.error,
          ),
        ),
        
        const SizedBox(height: AppConstants.spacingMd),
        
        // عنوان "انتهت الفترة التجريبية"
        Text(
          'انتهت الفترة التجريبية',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.error,
          ),
        ),
        
        const SizedBox(height: AppConstants.spacingSm),
        
        // نص توضيحي
        Text(
          'لتتمكن من متابعة استخدام التطبيق، يرجى تفعيله '
          'باستخدام الكود الذي حصلت عليه من المطور.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark 
              ? AppColors.textSecondaryDark 
              : AppColors.textSecondaryLight,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // بناء قسم بصمة الجهاز
  // ===========================================================================
  Widget _buildFingerprintSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان القسم
        Text(
          'بصمة الجهاز (Device Fingerprint):',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: AppConstants.spacingSm),
        
        // نص توضيحي
        Text(
          'أرسل هذه البصمة للمطور للحصول على كود التفعيل',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark 
              ? AppColors.textSecondaryDark 
              : AppColors.textSecondaryLight,
          ),
        ),
        
        const SizedBox(height: AppConstants.spacingMd),
        
        // حاوية بصمة الجهاز
        Container(
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
          child: Row(
            children: [
              // النص (قابل للتحديد)
              Expanded(
                child: SelectableText(
                  widget.deviceFingerprint,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(width: AppConstants.spacingSm),
              
              // زر النسخ
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: _copyFingerprint,
                tooltip: 'نسخ',
                style: IconButton.styleFrom(
                  backgroundColor: isDark 
                    ? AppColors.primaryDark.withOpacity(0.1)
                    : AppColors.primaryLight.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // بناء ملاحظة التعليمات
  // ===========================================================================
  Widget _buildInstructionsNote(bool isDark) {
    return Container(
      padding: AppConstants.paddingMd,
      decoration: BoxDecoration(
        color: isDark 
          ? AppColors.info.withOpacity(0.1)
          : AppColors.info.withOpacity(0.05),
        borderRadius: AppConstants.borderRadiusMd,
        border: Border.all(
          color: AppColors.info.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: AppColors.info,
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'خطوات التفعيل:',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXs),
                Text(
                  '1. انسخ بصمة الجهاز أعلاه\n'
                  '2. أرسلها للمطور\n'
                  '3. سيرسل لك كود التفعيل\n'
                  '4. الصق الكود في الحقل أعلاه',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark 
                      ? AppColors.textSecondaryDark 
                      : AppColors.textSecondaryLight,
                    height: 1.6,
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
