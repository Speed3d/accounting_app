// lib/screens/auth/activation_screen.dart

import 'dart:convert';
import 'package:accountant_touch/layouts/main_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../services/device_service.dart';
import '../../services/native_secrets_service.dart'; // 🆕 للحصول على المفتاح السري
import '../../services/session_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_button.dart';

/// ============================================================================
/// شاشة التفعيل المحسّنة - نسخة احترافية
/// ============================================================================
/// 
/// ← Hint: الميزات:
/// - 🎨 تصميم احترافي جميل
/// - 📋 عرض معلومات الخطط والأسعار
/// - 🔐 نموذج إدخال كود التفعيل
/// - 📱 عرض Device Fingerprint مع نسخ سهل
/// - ✅ التحقق من الكود باستخدام SHA-256
/// - 🎯 تجربة مستخدم محسّنة
/// 
/// ============================================================================
class ActivationScreen extends StatefulWidget {
  final AppLocalizations l10n;
  final String deviceFingerprint;

  const ActivationScreen({
    super.key,
    required this.l10n,
    required this.deviceFingerprint,
  });

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> 
    with SingleTickerProviderStateMixin {

  // ==========================================================================
  // المتغيرات
  // ==========================================================================

  final TextEditingController _activationCodeController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = false;
  bool _showDeviceId = false;
  int _currentStep = 1; // 1: معلومات, 2: إدخال الكود

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ← Hint: معلومات الخطط
  final List<Map<String, dynamic>> _plans = [
    {
      'id': 'trial',
      'name': 'تجريبي',
      'nameEn': 'Trial',
      'duration': '14 يوم',
      'price': 'مجاناً',
      'color': AppColors.warning,
      'icon': Icons.access_time,
      'features': [
        'جميع الميزات الأساسية',
        'دعم فني محدود',
        'جهاز واحد فقط',
        'صالح لـ 14 يوم',
      ],
    },
    {
      'id': 'premium',
      'name': 'مميز',
      'nameEn': 'Premium',
      'duration': 'شهر - سنة',
      'price': 'حسب المدة',
      'color': AppColors.info,
      'icon': Icons.workspace_premium,
      'features': [
        'جميع الميزات',
        'دعم فني 24/7',
        'حتى 3 أجهزة',
        'نسخ احتياطي سحابي',
        'تقارير متقدمة',
      ],
      'popular': true,
    },
    {
      'id': 'professional',
      'name': 'احترافي',
      'nameEn': 'Professional',
      'duration': 'سنة - سنتان',
      'price': 'أفضل قيمة',
      'color': AppColors.success,
      'icon': Icons.business_center,
      'features': [
        'جميع ميزات المميز',
        'أجهزة غير محدودة',
        'تدريب مخصص',
        'أولوية الدعم الفني',
        'تخصيصات حسب الطلب',
      ],
    },
  ];

  // ==========================================================================
  // Lifecycle
  // ==========================================================================

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _activationCodeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  // ==========================================================================
  // Build
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: isDark ? AppColors.gradientDark : AppColors.gradientLight,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _currentStep == 1
                ? _buildStep1PlansInfo(isDark)
                : _buildStep2ActivationForm(isDark),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // الخطوة 1: معلومات الخطط
  // ==========================================================================

  Widget _buildStep1PlansInfo(bool isDark) {
    return Column(
      children: [
        // ═══════════════════════════════════════════════════════════
        // Header
        // ═══════════════════════════════════════════════════════════
        _buildHeader(),

        // ═══════════════════════════════════════════════════════════
        // العنوان
        // ═══════════════════════════════════════════════════════════
        Padding(
          padding: AppConstants.paddingLg,
          child: Column(
            children: [
              const Text(
                'اختر خطتك المناسبة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                'استمتع بجميع ميزات التطبيق',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        // ═══════════════════════════════════════════════════════════
        // قائمة الخطط
        // ═══════════════════════════════════════════════════════════
        Expanded(
          child: ListView.builder(
            padding: AppConstants.paddingMd,
            itemCount: _plans.length,
            itemBuilder: (context, index) {
              return _buildPlanCard(_plans[index], isDark);
            },
          ),
        ),

        // ═══════════════════════════════════════════════════════════
        // زر "لدي كود تفعيل"
        // ═══════════════════════════════════════════════════════════
        Padding(
          padding: AppConstants.paddingLg,
          child: CustomButton(
            text: 'لدي كود تفعيل',
            icon: Icons.vpn_key,
            onPressed: () {
              setState(() => _currentStep = 2);
              _animationController.reset();
              _animationController.forward();
            },
            type: ButtonType.primary,
            size: ButtonSize.large,
          ),
        ),
      ],
    );
  }

  /// Header مع زر الرجوع
  Widget _buildHeader() {
    return Container(
      padding: AppConstants.paddingMd,
      child: Row(
        children: [
          if (_currentStep == 2)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                setState(() => _currentStep = 1);
                _animationController.reset();
                _animationController.forward();
              },
            )
          else
            const SizedBox(width: 48), // مسافة فارغة للتوازن
          
          const Spacer(),
          
          const Icon(Icons.card_membership, color: Colors.white, size: 32),
          
          const Spacer(),
          
          const SizedBox(width: 48), // مسافة فارغة للتوازن
        ],
      ),
    );
  }

  /// بطاقة الخطة
  Widget _buildPlanCard(Map<String, dynamic> plan, bool isDark) {
    final isPopular = plan['popular'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // البطاقة الرئيسية
          Container(
            padding: AppConstants.paddingLg,
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: AppConstants.borderRadiusLg,
              border: isPopular
                  ? Border.all(color: plan['color'], width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─────────────────────────────────────────────────────
                // الأيقونة والاسم
                // ─────────────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: plan['color'].withOpacity(0.1),
                        borderRadius: AppConstants.borderRadiusMd,
                      ),
                      child: Icon(
                        plan['icon'],
                        color: plan['color'],
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan['name'],
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            plan['duration'],
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // السعر
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: plan['color'].withOpacity(0.15),
                        borderRadius: AppConstants.borderRadiusFull,
                      ),
                      child: Text(
                        plan['price'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: plan['color'],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppConstants.spacingMd),
                
                const Divider(),
                
                const SizedBox(height: AppConstants.spacingSm),

                // ─────────────────────────────────────────────────────
                // الميزات
                // ─────────────────────────────────────────────────────
                ...List.generate(
                  plan['features'].length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppConstants.spacingSm,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: plan['color'],
                          size: 18,
                        ),
                        const SizedBox(width: AppConstants.spacingSm),
                        Expanded(
                          child: Text(
                            plan['features'][index],
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // شارة "الأكثر شعبية"
          if (isPopular)
            Positioned(
              top: -12,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: plan['color'],
                  borderRadius: AppConstants.borderRadiusFull,
                  boxShadow: [
                    BoxShadow(
                      color: plan['color'].withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  '⭐ الأكثر شعبية',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================================================
  // الخطوة 2: نموذج التفعيل
  // ==========================================================================

  Widget _buildStep2ActivationForm(bool isDark) {
    return Column(
      children: [
        // ═══════════════════════════════════════════════════════════
        // Header
        // ═══════════════════════════════════════════════════════════
        _buildHeader(),

        Expanded(
          child: SingleChildScrollView(
            padding: AppConstants.paddingLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─────────────────────────────────────────────────────
                // العنوان
                // ─────────────────────────────────────────────────────
                const Icon(
                  Icons.vpn_key,
                  color: Colors.white,
                  size: 64,
                ),
                const SizedBox(height: AppConstants.spacingMd),
                
                const Text(
                  'تفعيل الاشتراك',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppConstants.spacingSm),
                
                Text(
                  'أدخل كود التفعيل الذي حصلت عليه',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppConstants.spacingXl),

                // ─────────────────────────────────────────────────────
                // البطاقة الرئيسية
                // ─────────────────────────────────────────────────────
                Container(
                  padding: AppConstants.paddingLg,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: AppConstants.borderRadiusLg,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ═══════════════════════════════════════════════
                      // الخطوة 1: Device Fingerprint
                      // ═══════════════════════════════════════════════
                      _buildStepHeader(
                        '1',
                        'بصمة الجهاز',
                        'انسخ هذا الرمز وأرسله للمطور',
                        isDark,
                      ),

                      const SizedBox(height: AppConstants.spacingMd),

                      _buildDeviceIdCard(isDark),

                      const SizedBox(height: AppConstants.spacingXl),

                      // ═══════════════════════════════════════════════
                      // الخطوة 2: Activation Code
                      // ═══════════════════════════════════════════════
                      _buildStepHeader(
                        '2',
                        'كود التفعيل',
                        'أدخل الكود الذي حصلت عليه',
                        isDark,
                      ),

                      const SizedBox(height: AppConstants.spacingMd),

                      TextField(
                        controller: _activationCodeController,
                        decoration: InputDecoration(
                          hintText: 'أدخل كود التفعيل هنا...',
                          prefixIcon: const Icon(Icons.vpn_key),
                          border: OutlineInputBorder(
                            borderRadius: AppConstants.borderRadiusMd,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceLight,
                        ),
                        maxLines: 3,
                        textDirection: TextDirection.ltr,
                      ),

                      const SizedBox(height: AppConstants.spacingXl),

                      // ═══════════════════════════════════════════════
                      // زر التفعيل
                      // ═══════════════════════════════════════════════
                      CustomButton(
                        text: 'تفعيل الاشتراك',
                        icon: Icons.check_circle,
                        onPressed: _isLoading ? null : _activateSubscription,
                        type: ButtonType.primary,
                        size: ButtonSize.large,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppConstants.spacingLg),

                // ─────────────────────────────────────────────────────
                // رسالة مساعدة
                // ─────────────────────────────────────────────────────
                Container(
                  padding: AppConstants.paddingMd,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: AppConstants.borderRadiusMd,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.white.withOpacity(0.9),
                        size: 20,
                      ),
                      const SizedBox(width: AppConstants.spacingSm),
                      Expanded(
                        child: Text(
                          'للحصول على كود التفعيل، يرجى التواصل مع الدعم الفني '
                          'وإرسال بصمة جهازك.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// رأس الخطوة
  Widget _buildStepHeader(
    String stepNumber,
    String title,
    String subtitle,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppConstants.spacingSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? Colors.white
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// بطاقة Device ID
  Widget _buildDeviceIdCard(bool isDark) {
    return Container(
      padding: AppConstants.paddingMd,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
        borderRadius: AppConstants.borderRadiusMd,
        border: Border.all(
          color: AppColors.primaryLight.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.fingerprint,
                color: AppColors.primaryLight,
                size: 20,
              ),
              const SizedBox(width: AppConstants.spacingSm),
              const Text(
                'بصمة جهازك:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _showDeviceId ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _showDeviceId = !_showDeviceId);
                },
                tooltip: _showDeviceId ? 'إخفاء' : 'إظهار',
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.spacingSm),
          
          SelectableText(
            _showDeviceId
                ? widget.deviceFingerprint
                : '•' * 40,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
          
          const SizedBox(height: AppConstants.spacingMd),
          
          CustomButton(
            text: 'نسخ بصمة الجهاز',
            icon: Icons.copy,
            onPressed: () => _copyDeviceId(),
            type: ButtonType.secondary,
            size: ButtonSize.small,
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // Actions
  // ==========================================================================

  /// نسخ Device ID
  void _copyDeviceId() {
    Clipboard.setData(ClipboardData(text: widget.deviceFingerprint));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم نسخ بصمة الجهاز بنجاح'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// تفعيل الاشتراك
  Future<void> _activateSubscription() async {
    final code = _activationCodeController.text.trim();

    if (code.isEmpty) {
      _showErrorDialog('الرجاء إدخال كود التفعيل');
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('🔐 التحقق من كود التفعيل...');
      debugPrint('   Code: ${code.substring(0, 20)}...');
      debugPrint('   Device: ${widget.deviceFingerprint}');

      // ═══════════════════════════════════════════════════════════════════
      // التحقق من الكود باستخدام SHA-256
      // ═══════════════════════════════════════════════════════════════════
      final validationResult = await _validateActivationCode(code);

      if (!validationResult['valid']) {
        throw Exception(validationResult['message'] ?? 'كود غير صالح');
      }

      // ═══════════════════════════════════════════════════════════════════
      // الحصول على معلومات الاشتراك من الكود
      // ═══════════════════════════════════════════════════════════════════
      final duration = validationResult['duration'] as int;
      final planType = validationResult['planType'] as String;

      debugPrint('✅ الكود صالح');
      debugPrint('   Duration: $duration days');
      debugPrint('   Plan: $planType');

      // ═══════════════════════════════════════════════════════════════════
      // الحصول على معلومات المستخدم
      // ═══════════════════════════════════════════════════════════════════
      final email = await SessionService.instance.getEmail();
      
      if (email == null || email.isEmpty) {
        throw Exception('لم يتم العثور على معلومات المستخدم');
      }

      // ═══════════════════════════════════════════════════════════════════
      // إنشاء/تحديث الاشتراك في Firestore
      // ═══════════════════════════════════════════════════════════════════
      final now = DateTime.now();
      final endDate = now.add(Duration(days: duration));

      // ← Hint: استخدام Timestamp.now() بدلاً من serverTimestamp داخل Arrays
      debugPrint('📝 إنشاء الاشتراك في Firestore...');

      await _firestore.collection('subscriptions').doc(email).set({
        // ─────────────────────────────────────────────────────────────────
        // المعلومات الأساسية
        // ─────────────────────────────────────────────────────────────────
        'email': email,
        'plan': planType,
        'status': 'active',
        'isActive': true,

        // ─────────────────────────────────────────────────────────────────
        // التواريخ
        // ─────────────────────────────────────────────────────────────────
        'startDate': Timestamp.fromDate(now),
        'endDate': Timestamp.fromDate(endDate),
        'activatedAt': FieldValue.serverTimestamp(), // ✅ خارج Array - صحيح
        'updatedAt': FieldValue.serverTimestamp(),   // ✅ خارج Array - صحيح
        'createdAt': FieldValue.serverTimestamp(),

        // ─────────────────────────────────────────────────────────────────
        // معلومات التفعيل
        // ─────────────────────────────────────────────────────────────────
        'activationCode': code, // للمرجع فقط
        'deviceId': widget.deviceFingerprint, // الجهاز الأول

        // ─────────────────────────────────────────────────────────────────
        // الأجهزة
        // ─────────────────────────────────────────────────────────────────
        'maxDevices': planType == 'trial' ? 1 : (planType == 'premium' ? 3 : 999),
        'currentDevices': [
          {
            'deviceId': widget.deviceFingerprint,
            'activatedAt': Timestamp.now(), // ✅ استخدام Timestamp.now() داخل Array
            'lastLoginAt': Timestamp.now(), // ✅ استخدام Timestamp.now()
            'isActive': true,
            'deviceName': 'Unknown', // سيتم تحديثه لاحقاً
            'deviceModel': 'Unknown',
            'deviceBrand': 'Unknown',
          }
        ],

        // ─────────────────────────────────────────────────────────────────
        // الميزات
        // ─────────────────────────────────────────────────────────────────
        'features': {
          'backupEnabled': true,
          'reportsEnabled': true,
          'multiDeviceEnabled': planType != 'trial',
          'canCreateSubUsers': true,
          'maxSubUsers': planType == 'trial' ? 3 : (planType == 'premium' ? 10 : -1),
          'canExportData': true,
          'canUseAdvancedReports': planType != 'trial',
          'supportPriority': planType == 'trial' ? 'standard' : 'priority',
        },

        // ─────────────────────────────────────────────────────────────────
        // سجل الدفع (اختياري - للمرجع)
        // ─────────────────────────────────────────────────────────────────
        'paymentHistory': [],

        // ─────────────────────────────────────────────────────────────────
        // ملاحظات
        // ─────────────────────────────────────────────────────────────────
        'notes': 'تم التفعيل من التطبيق في ${DateTime.now().toIso8601String()}',
      }, SetOptions(merge: true));

      debugPrint('✅ تم تفعيل الاشتراك في Firestore');

      if (!mounted) return;

      // ═══════════════════════════════════════════════════════════════════
      // عرض رسالة نجاح
      // ═══════════════════════════════════════════════════════════════════
      await _showSuccessDialog(planType, duration);

      // ═══════════════════════════════════════════════════════════════════
      // الانتقال للشاشة الرئيسية
      // ═══════════════════════════════════════════════════════════════════
      if (!mounted) return;
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );

    } catch (e, stackTrace) {
      debugPrint('❌ خطأ في التفعيل: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (mounted) {
        _showErrorDialog('فشل التفعيل: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// التحقق من صحة كود التفعيل
  Future<Map<String, dynamic>> _validateActivationCode(String code) async {
    try {
      // ═══════════════════════════════════════════════════════════════════
      // 🔐 الحصول على المفتاح السري من Native Code
      // ═══════════════════════════════════════════════════════════════════
      // ← Hint: نستخدم NativeSecretsService (أكثر أماناً من Remote Config)
      final secretKey = NativeSecretsService.instance.cachedActivationSecret;

      if (secretKey == null || secretKey.isEmpty) {
        throw Exception('Activation secret not loaded');
      }

      debugPrint('🔐 استخدام activation secret من Native layer');

      // ═══════════════════════════════════════════════════════════════════
      // جرب جميع المدد والخطط الممكنة
      // ═══════════════════════════════════════════════════════════════════
      final possibleDurations = [30, 90, 180, 365, 545, 730];
      final possiblePlans = ['trial', 'premium', 'professional'];

      for (final duration in possibleDurations) {
        for (final plan in possiblePlans) {
          // ← Hint: توليد الكود المتوقع
          final expectedString = '${widget.deviceFingerprint}-$duration-$plan-$secretKey';
          final bytes = utf8.encode(expectedString);
          final digest = sha256.convert(bytes);
          final expectedCode = digest.toString();

          // ← Hint: مقارنة الكود
          if (code == expectedCode) {
            return {
              'valid': true,
              'duration': duration,
              'planType': plan,
            };
          }
        }
      }

      // ← Hint: الكود غير صالح
      return {
        'valid': false,
        'message': 'كود التفعيل غير صحيح أو منتهي الصلاحية',
      };

    } catch (e) {
      return {
        'valid': false,
        'message': 'خطأ في التحقق من الكود: $e',
      };
    }
  }

  /// عرض رسالة نجاح
  Future<void> _showSuccessDialog(String planType, int duration) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppConstants.borderRadiusLg,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 50,
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),
            const Text(
              'تم التفعيل بنجاح!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              'تم تفعيل اشتراكك ${_getPlanDisplayName(planType)} '
              'لمدة $duration يوم',
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingLg),
            CustomButton(
              text: 'ابدأ الاستخدام',
              icon: Icons.arrow_forward,
              onPressed: () => Navigator.pop(context),
              type: ButtonType.primary,
            ),
          ],
        ),
      ),
    );
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

  // ==========================================================================
  // Helpers
  // ==========================================================================

  String _getPlanDisplayName(String plan) {
    switch (plan.toLowerCase()) {
      case 'trial': return 'التجريبي';
      case 'premium': return 'المميز';
      case 'professional': return 'الاحترافي';
      default: return plan;
    }
  }
}