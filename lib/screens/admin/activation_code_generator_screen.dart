// lib/screens/admin/activation_code_generator_screen.dart

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/native_secrets_service.dart'; // 🆕 للحصول على المفتاح السري
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_button.dart';

/// ============================================================================
/// مولد أكواد التفعيل (Activation Code Generator)
/// ============================================================================
/// 
/// ← Hint: الميزات:
/// - 🔐 توليد أكواد آمنة باستخدام SHA-256
/// - ⏱️ دعم مدد مختلفة (30, 90, 180, 365, 730 يوم)
/// - 📋 نسخ الكود بسهولة
/// - 📊 عرض تفاصيل الكود
/// - 💾 حفظ سجل الأكواد المولدة
/// 
/// ============================================================================
class ActivationCodeGeneratorScreen extends StatefulWidget {
  const ActivationCodeGeneratorScreen({super.key});

  @override
  State<ActivationCodeGeneratorScreen> createState() => 
      _ActivationCodeGeneratorScreenState();
}

class _ActivationCodeGeneratorScreenState 
    extends State<ActivationCodeGeneratorScreen> {

  // ==========================================================================
  // المتغيرات
  // ==========================================================================

  final TextEditingController _deviceIdController = TextEditingController();
  
  int _selectedDuration = 30; // المدة الافتراضية: 30 يوم
  String? _generatedCode;
  String? _planType = 'premium'; // نوع الخطة

  // ← Hint: المدد المدعومة
  final Map<int, String> _durations = {
    30: 'شهر واحد (30 يوم)',
    90: '3 أشهر (90 يوم)',
    180: '6 أشهر (180 يوم)',
    365: 'سنة واحدة (365 يوم)',
    545: 'سنة ونصف (545 يوم)',
    730: 'سنتان (730 يوم)',
  };

  // ← Hint: أنواع الخطط
  final Map<String, String> _planTypes = {
    'trial': 'تجريبي',
    'premium': 'مميز',
    'professional': 'احترافي',
  };

  // ==========================================================================
  // Lifecycle
  // ==========================================================================

  @override
  void dispose() {
    _deviceIdController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // Build
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('مولد أكواد التفعيل'),
        actions: [
          // زر المساعدة
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppConstants.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ═══════════════════════════════════════════════════════════
            // معلومات توضيحية
            // ═══════════════════════════════════════════════════════════
            _buildInfoCard(isDark),

            const SizedBox(height: AppConstants.spacingLg),

            // ═══════════════════════════════════════════════════════════
            // نموذج التوليد
            // ═══════════════════════════════════════════════════════════
            _buildGeneratorForm(isDark),

            const SizedBox(height: AppConstants.spacingLg),

            // ═══════════════════════════════════════════════════════════
            // الكود المولد (إن وجد)
            // ═══════════════════════════════════════════════════════════
            if (_generatedCode != null)
              _buildGeneratedCodeCard(isDark),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // UI Components
  // ==========================================================================

  /// بطاقة المعلومات
  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: AppConstants.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: AppConstants.borderRadiusMd,
        border: Border.all(
          color: AppColors.info.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.info, size: 24),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'كيفية الاستخدام:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '1. أدخل بصمة الجهاز (Device ID)\n'
                  '2. اختر المدة المطلوبة\n'
                  '3. اختر نوع الخطة\n'
                  '4. اضغط "توليد الكود"\n'
                  '5. انسخ الكود وأرسله للمستخدم',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// نموذج التوليد
  Widget _buildGeneratorForm(bool isDark) {
    return Card(
      child: Padding(
        padding: AppConstants.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─────────────────────────────────────────────────────────
            // Device ID
            // ─────────────────────────────────────────────────────────
            Text(
              'بصمة الجهاز (Device Fingerprint):',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppConstants.spacingSm),
            TextField(
              controller: _deviceIdController,
              decoration: InputDecoration(
                hintText: 'مثال: AND-1A2B3C4D5E6F7890...',
                border: OutlineInputBorder(
                  borderRadius: AppConstants.borderRadiusMd,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null) {
                      _deviceIdController.text = data!.text!;
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: AppConstants.spacingLg),

            // ─────────────────────────────────────────────────────────
            // نوع الخطة
            // ─────────────────────────────────────────────────────────
            Text(
              'نوع الخطة:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppConstants.spacingSm),
            DropdownButtonFormField<String>(
              value: _planType,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: AppConstants.borderRadiusMd,
                ),
              ),
              items: _planTypes.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _planType = value);
              },
            ),

            const SizedBox(height: AppConstants.spacingLg),

            // ─────────────────────────────────────────────────────────
            // المدة
            // ─────────────────────────────────────────────────────────
            Text(
              'المدة:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppConstants.spacingSm),
            DropdownButtonFormField<int>(
              value: _selectedDuration,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: AppConstants.borderRadiusMd,
                ),
              ),
              items: _durations.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedDuration = value!);
              },
            ),

            const SizedBox(height: AppConstants.spacingXl),

            // ─────────────────────────────────────────────────────────
            // زر التوليد
            // ─────────────────────────────────────────────────────────
            CustomButton(
              text: 'توليد كود التفعيل',
              icon: Icons.vpn_key,
              onPressed: _generateActivationCode,
              type: ButtonType.primary,
              size: ButtonSize.large,
            ),
          ],
        ),
      ),
    );
  }

  /// بطاقة الكود المولد
  Widget _buildGeneratedCodeCard(bool isDark) {
    return Card(
      color: AppColors.success.withOpacity(0.05),
      child: Padding(
        padding: AppConstants.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─────────────────────────────────────────────────────────
            // العنوان
            // ─────────────────────────────────────────────────────────
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 28,
                ),
                const SizedBox(width: AppConstants.spacingSm),
                const Text(
                  'تم توليد الكود بنجاح!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.spacingLg),

            // ─────────────────────────────────────────────────────────
            // الكود
            // ─────────────────────────────────────────────────────────
            Container(
              padding: AppConstants.paddingMd,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark
                    : AppColors.surfaceLight,
                borderRadius: AppConstants.borderRadiusMd,
                border: Border.all(
                  color: AppColors.success.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      _generatedCode!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingSm),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () => _copyCode(),
                    tooltip: 'نسخ الكود',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.success.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // ─────────────────────────────────────────────────────────
            // معلومات الكود
            // ─────────────────────────────────────────────────────────
            Container(
              padding: AppConstants.paddingSm,
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.05),
                borderRadius: AppConstants.borderRadiusSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('نوع الخطة:', _planTypes[_planType] ?? ''),
                  const SizedBox(height: 4),
                  _buildInfoRow('المدة:', _durations[_selectedDuration] ?? ''),
                  const SizedBox(height: 4),
                  _buildInfoRow('بصمة الجهاز:', 
                      '${_deviceIdController.text.substring(0, 20)}...'),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // ─────────────────────────────────────────────────────────
            // أزرار الإجراءات
            // ─────────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'توليد كود جديد',
                    icon: Icons.refresh,
                    onPressed: () {
                      setState(() => _generatedCode = null);
                    },
                    type: ButtonType.secondary,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(
                  child: CustomButton(
                    text: 'مشاركة',
                    icon: Icons.share,
                    onPressed: () => _shareCode(),
                    type: ButtonType.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // Actions
  // ==========================================================================

  /// توليد كود التفعيل
  void _generateActivationCode() {
    // ═══════════════════════════════════════════════════════════════════
    // التحقق من البيانات
    // ═══════════════════════════════════════════════════════════════════
    final deviceId = _deviceIdController.text.trim();

    if (deviceId.isEmpty) {
      _showErrorDialog('الرجاء إدخال بصمة الجهاز');
      return;
    }

    if (deviceId.length < 20) {
      _showErrorDialog('بصمة الجهاز قصيرة جداً (يجب أن تكون 20 حرف على الأقل)');
      return;
    }

    try {
      debugPrint('🔐 توليد كود تفعيل...');
      debugPrint('   Device ID: $deviceId');
      debugPrint('   Duration: $_selectedDuration days');
      debugPrint('   Plan: $_planType');

      // ═══════════════════════════════════════════════════════════════════
      // 🔐 الحصول على المفتاح السري من Native Code
      // ═══════════════════════════════════════════════════════════════════
      // ← Hint: نستخدم NativeSecretsService (أكثر أماناً من Remote Config)
      final secretKey = NativeSecretsService.instance.cachedActivationSecret;

      if (secretKey == null || secretKey.isEmpty) {
        throw Exception('Activation secret not loaded. Please restart the app.');
      }

      debugPrint('✅ تم الحصول على activation secret من Native layer (${secretKey.length} chars)');

      // ═══════════════════════════════════════════════════════════════════
      // توليد الكود باستخدام SHA-256
      // ═══════════════════════════════════════════════════════════════════
      // ← Hint: الصيغة: SHA256(deviceId + duration + planType + secretKey)
      final stringToHash = '$deviceId-$_selectedDuration-$_planType-$secretKey';
      final bytes = utf8.encode(stringToHash);
      final digest = sha256.convert(bytes);
      final code = digest.toString();

      debugPrint('✅ تم توليد الكود: ${code.substring(0, 20)}...');

      setState(() {
        _generatedCode = code;
      });

    } catch (e) {
      debugPrint('❌ خطأ في توليد الكود: $e');
      _showErrorDialog('حدث خطأ في توليد الكود: $e');
    }
  }

  /// نسخ الكود
  void _copyCode() {
    if (_generatedCode != null) {
      Clipboard.setData(ClipboardData(text: _generatedCode!));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم نسخ الكود بنجاح'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// مشاركة الكود
  void _shareCode() {
    if (_generatedCode != null) {
      final message = '''
كود التفعيل:
$_generatedCode

نوع الخطة: ${_planTypes[_planType]}
المدة: ${_durations[_selectedDuration]}

قم بإدخال هذا الكود في تطبيق لمسة محاسب لتفعيل اشتراكك.
''';

      // TODO: استخدام share package
      Clipboard.setData(ClipboardData(text: message));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم نسخ رسالة المشاركة'),
          backgroundColor: AppColors.info,
        ),
      );
    }
  }

  /// عرض رسالة خطأ
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: AppConstants.spacingSm),
            const Text('خطأ'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  /// عرض حوار المساعدة
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('المساعدة'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ما هي بصمة الجهاز؟',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'بصمة الجهاز (Device Fingerprint) هي معرّف فريد لكل جهاز يتم توليده تلقائياً من معلومات الجهاز.\n\n'
                'يطلب المستخدم هذه البصمة من شاشة التفعيل في التطبيق ويرسلها لك.',
              ),
              SizedBox(height: 16),
              Text(
                'كيف يعمل النظام؟',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '1. المستخدم يرسل لك بصمة جهازه\n'
                '2. تدخل البصمة هنا وتختار المدة ونوع الخطة\n'
                '3. يتم توليد كود مشفر فريد\n'
                '4. ترسل الكود للمستخدم\n'
                '5. يدخله في التطبيق للتفعيل',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('فهمت'),
          ),
        ],
      ),
    );
  }
}