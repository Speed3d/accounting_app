// lib/screens/auth/splash_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart'; // ← Hint: إضافة للحصول على version
import '../../data/database_helper.dart';
import '../../services/device_service.dart';
import '../../services/firebase_service.dart'; // ← Hint: إضافة Firebase Service
import '../../services/time_validation_service.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import 'create_admin_screen.dart';
import 'login_screen.dart';
import 'activation_screen.dart';
import 'blocked_screen.dart';

/// ===========================================================================
/// شاشة البداية (Splash Screen) - محسّنة مع Firebase Kill Switch
/// ← Hint: النسخة المحدثة مع فحص حالة التطبيق عن بُعد
/// ===========================================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> 
    with SingleTickerProviderStateMixin {
  
  // ← Hint: متحكم الأنيميشن
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  // ← Hint: بيانات الشركة
  String _companyName = '';
  File? _companyLogo;
  
  // ← Hint: عدد أيام الفترة التجريبية
  static const int trialPeriodDays = 14;

  // ← Hint: مدة عرض شاشة البداية
  static const int splashDuration = 2500;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndNavigate();
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // ← Hint: تحميل البيانات والتنقل (محسّن مع Firebase!)
  // ===========================================================================
  Future<void> _loadAndNavigate() async {
    final l10n = AppLocalizations.of(context)!;
    final dbHelper = DatabaseHelper.instance;
    final deviceService = DeviceService.instance;
    final timeService = TimeValidationService.instance;
    final firebaseService = FirebaseService.instance; // ← Hint: Firebase Service

      // 🧪 اختبار - اطبع الإصدار
  final packageInfo = await PackageInfo.fromPlatform();
  debugPrint('════════════════════════════════');
  debugPrint('📱 معلومات التطبيق:');
  debugPrint('   - الإصدار: ${packageInfo.version}');
  debugPrint('   - رقم البناء: ${packageInfo.buildNumber}');
  debugPrint('   - اسم التطبيق: ${packageInfo.appName}');
  debugPrint('   - Package: ${packageInfo.packageName}');
  debugPrint('════════════════════════════════');
    
    try {
  // ============================================================================
  // 🔥 الخطوة 0.1: Force Refresh Remote Config (جديد!)
  //  : يجبر Firebase على جلب أحدث القيم بدون اعتماد على Cache
  //  : حل مشكلة عدم تحديث Kill Switch على الهواتف الحقيقية
  // ============================================================================
  
  debugPrint('🔄 إجبار تحديث Remote Config...');

  try {
    final refreshed = await firebaseService.forceRefreshConfig();
    if (refreshed) {
      debugPrint('✅ تم تحديث Remote Config بنجاح');

    } else {
      debugPrint('ℹ️ لا توجد تحديثات جديدة في Remote Config');
    }

  } catch (e) {
    debugPrint('⚠️ فشل تحديث Remote Config: $e');
    debugPrint('ℹ️ سيتم استخدام القيم المخزنة (Cache)');
    //  : لا نوقف التطبيق - نكمل بالقيم المخزنة
  }
  
  debugPrint('🔥 فحص حالة التطبيق من Firebase...');
  
  final packageInfo = await PackageInfo.fromPlatform();
  final currentVersion = packageInfo.version;
  
  debugPrint('ℹ️ إصدار التطبيق الحالي: $currentVersion');

  final appStatus = await firebaseService.checkAppStatus(
    currentVersion: currentVersion,

      );

      // ========================================================================
       // 🔥 Kill Switch المتقدم - معالجة جميع الحالات
      // ========================================================================

      // 1️⃣ التحقق من الجهاز المحظور
      if (appStatus['isBlocked'] == true) {
         debugPrint('🚫 جهاز محظور - منع الدخول');
  
      if (!mounted) return;
  
     _showKillSwitchDialog(
        title: 'الجهاز محظور',
        message: appStatus['message'] ?? 'تم حظر هذا الجهاز',
        canClose: false,
        icon: Icons.block,
        iconColor: AppColors.error,
       );
  
      return; // ← إيقاف التنفيذ
     }

    // 2️⃣ التحقق من وضع الصيانة أو التطبيق موقوف
    if (appStatus['isActive'] != true) {
    final reason = appStatus['reason'] ?? '';
    debugPrint('🚫 التطبيق موقوف - السبب: $reason');
  
    if (!mounted) return;
  
     // ← Hint: اختيار الأيقونة حسب السبب
     IconData icon;
     Color iconColor;
  
    if (reason == 'maintenance') {
       icon = Icons.engineering;
       iconColor = AppColors.warning;
      } else {
       icon = Icons.block;
       iconColor = AppColors.error;
      }
  
      _showKillSwitchDialog(
        title: reason == 'maintenance' ? 'وضع الصيانة' : 'التطبيق متوقف',
        message: appStatus['message'] ?? 'التطبيق متوقف مؤقتاً',
        canClose: false,
        icon: icon,
        iconColor: iconColor,
      );
  
      return; // ← إيقاف التنفيذ
  }

   // 3️⃣ التحقق من التحديثات
    if (appStatus['needsUpdate'] == true) {
     final forceUpdate = appStatus['forceUpdate'] == true;
     final minVersion = appStatus['minVersion'] ?? '';
     final reason = appStatus['reason'] ?? '';
  
     debugPrint('ℹ️ يوجد تحديث متاح (إجباري: $forceUpdate)');
  
     if (!mounted) return;
  
    _showUpdateDialog(
      message: appStatus['message'] ?? 'يتوفر تحديث جديد',
      required: forceUpdate,
      minVersion: minVersion,
      isCritical: reason == 'critical_update',
    );
  
    if (forceUpdate) {
    return; // ← منع الدخول إذا كان التحديث إجباري
    }
  
    // ← Hint: إذا لم يكن إجباري، نكمل...
  }

     debugPrint('✅ التطبيق نشط وجاهز للاستخدام');
      

      
    } catch (e) {
      // ← Hint: في حالة خطأ، نكمل (fail-safe)
      debugPrint('⚠️ خطأ في فحص حالة التطبيق: $e');
      debugPrint('ℹ️ سيتم المتابعة بشكل طبيعي');
    }

    // ============================================================================
    // الخطوة 1: تحميل معلومات الشركة
    // ============================================================================
    
    try {
      final settings = await dbHelper.getAppSettings();
      if (mounted) {
        setState(() {
          _companyName = settings['companyName'] ?? l10n.accountingProgram;
          
          final logoPath = settings['companyLogoPath'];
          if (logoPath != null && logoPath.isNotEmpty) {
            _companyLogo = File(logoPath);
          }
        });
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل إعدادات الشركة: $e');
    }

    // ============================================================================
    // الخطوة 2: الانتظار لإكمال الأنيميشن
    // ============================================================================
    
    await Future.delayed(const Duration(milliseconds: splashDuration));
    if (!mounted) return;

    // ============================================================================
    // الخطوة 3: تهيئة خدمة التحقق من الوقت
    // ============================================================================
    
    debugPrint('🔄 بدء تهيئة TimeValidationService...');
    await timeService.initialize();

    // ============================================================================
    // الخطوة 4: كشف التلاعب (سريع - بدون NTP!)
    // ============================================================================
    
    debugPrint('🔍 فحص التلاعب...');
    final manipulationResult = await timeService.detectManipulation();

    if (manipulationResult['isManipulated'] == true) {
      final attemptsRemaining = timeService.getAttemptsRemaining();
      final currentAttempts = timeService.getSuspiciousAttempts();
      
      debugPrint('⚠️ تحذير #$currentAttempts - المحاولات المتبقية: $attemptsRemaining');

      // ← Hint: 🔥 تسجيل محاولة مشبوهة في Firebase Crashlytics
      firebaseService.logSuspiciousActivity(
        reason: manipulationResult['reason'] ?? 'time_manipulation',
        deviceId: await deviceService.getDeviceFingerprint(),
        additionalInfo: {
          'attempts': currentAttempts,
          'message': manipulationResult['message'] ?? 'Unknown',
        },
      );

      if (attemptsRemaining <= 0) {
        debugPrint('🚫 حظر نهائي - تجاوز الحد الأقصى');
        _navigateToScreen(
          BlockedScreen(
            reason: manipulationResult['reason'] ?? 'unknown',
            message: manipulationResult['message'],
          ),
        );
        return;
      } else {
        debugPrint('⚠️ تحذير - المحاولات المتبقية: $attemptsRemaining');
        _showManipulationWarning(
          l10n,
          manipulationResult['message'] ?? 'تم رصد تلاعب',
          attemptsRemaining,
        );
      }
    }

    // ============================================================================
    // الخطوة 5: التحقق من الحاجة للإنترنت
    // ============================================================================
    
    if (timeService.shouldRequireInternet()) {
      debugPrint('⚠️ يتطلب اتصال بالإنترنت - مر 7 أيام');
      _showInternetRequiredDialog(l10n);
      return;
    }

    // ============================================================================
    // الخطوة 6: الحصول على الوقت (سريع جداً!)
    // ============================================================================
    
    DateTime realTime;
    try {
      realTime = await timeService.getRealTime().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('⏱️ انتهى وقت NTP - استخدام وقت الجهاز');
          return DateTime.now();
        },
      );
    } catch (e) {
      debugPrint('⚠️ خطأ في الحصول على الوقت: $e');
      realTime = DateTime.now();
    }

    debugPrint('⏰ الوقت المستخدم: $realTime');

    // ← Hint: بدء مزامنة في الخلفية
    timeService.backgroundSync().then((_) {
      debugPrint('✅ اكتملت المزامنة الخلفية');
    }).catchError((e) {
      debugPrint('⚠️ فشلت المزامنة الخلفية (لا مشكلة): $e');
    });

    // ============================================================================
    // الخطوة 7: التحقق من حالة التطبيق
    // ============================================================================
    
    try {
      final appState = await dbHelper.getAppState();
      final userCount = await dbHelper.getUserCount();
      final deviceFingerprint = await deviceService.getDeviceFingerprint();

      // ========================================================================
      // فحص ذكي للمستخدمين
      // ========================================================================
      
      if (userCount == 0) {
        debugPrint('ℹ️ لا يوجد مستخدمين - التوجه لإنشاء المدير');
        
        if (appState == null) {
          await dbHelper.initializeAppState();
        }
        
        _navigateToScreen(CreateAdminScreen(l10n: l10n));
        return;
      }

      // ========================================================================
      // التحقق من التفعيل
      // ========================================================================
      
      if (appState == null) {
        await dbHelper.initializeAppState();
        _navigateToScreen(LoginScreen(l10n: l10n));
        return;
      }

      final expiryDateString = appState['activation_expiry_date'];
      if (expiryDateString != null) {
        final expiryDate = DateTime.parse(expiryDateString);
        
        if (realTime.isBefore(expiryDate)) {
          _navigateToScreen(LoginScreen(l10n: l10n));
        } else {
          _navigateToScreen(
            ActivationScreen(
              l10n: l10n,
              deviceFingerprint: deviceFingerprint,
            ),
          );
        }
        return;
      }

      // ========================================================================
      // الفترة التجريبية
      // ========================================================================
      
      final firstRunDate = DateTime.parse(appState['first_run_date']);
      final trialEndsAt = firstRunDate.add(
        const Duration(days: trialPeriodDays),
      );

      if (realTime.isAfter(trialEndsAt)) {
        _navigateToScreen(
          ActivationScreen(
            l10n: l10n,
            deviceFingerprint: deviceFingerprint,
          ),
        );
      } else {
        _navigateToScreen(LoginScreen(l10n: l10n));
      }

    } catch (e) {
      debugPrint('❌ خطأ أثناء التنقل من Splash Screen: $e');
      
      // ← Hint: 🔥 تسجيل الخطأ في Firebase
      firebaseService.logError(
        e,
        StackTrace.current,
        reason: 'Splash navigation error',
      );
      
      if (mounted) {
        _navigateToScreen(LoginScreen(l10n: l10n));
      }
    }
  }

  // ===========================================================================
  // 🔥 دوال Kill Switch (جديدة!)
  // ===========================================================================
  
/// عرض حوار Kill Switch المحسّن
void _showKillSwitchDialog({
  required String title,
  required String message,
  required bool canClose,
  IconData? icon,
  Color? iconColor,
}) {
  showDialog(
    context: context,
    barrierDismissible: canClose,
    builder: (context) => WillPopScope(
      onWillPop: () async => canClose,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppConstants.borderRadiusLg,
        ),
        title: Row(
          children: [
            Icon(
              icon ?? Icons.block,
              color: iconColor ?? AppColors.error,
              size: 28,
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: iconColor ?? AppColors.error),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppConstants.spacingLg),
            // ← Hint: أيقونة كبيرة في الوسط
            Icon(
              icon ?? Icons.engineering,
              size: 64,
              color: iconColor ?? AppColors.warning,
            ),
          ],
        ),
        actions: [
          if (canClose)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
        ],
      ),
    ),
  );
}

  /// عرض حوار التحديث
/// عرض حوار التحديث المحسّن
void _showUpdateDialog({
  required String message,
  required bool required,
  required String minVersion,
  bool isCritical = false,
}) {
  showDialog(
    context: context,
    barrierDismissible: !required,
    builder: (context) => WillPopScope(
      onWillPop: () async => !required,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppConstants.borderRadiusLg,
        ),
        title: Row(
          children: [
            Icon(
              isCritical ? Icons.security_update : Icons.system_update,
              color: isCritical ? AppColors.error : AppColors.info,
              size: 28,
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Expanded(
              child: Text(
                isCritical ? 'تحديث أمني مهم' : (required ? 'تحديث إجباري' : 'تحديث متاح'),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ← Hint: رسالة مخصصة للتحديثات الأمنية
            if (isCritical) ...[
              Container(
                padding: AppConstants.paddingSm,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: AppConstants.borderRadiusSm,
                  border: Border.all(
                    color: AppColors.error.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: AppColors.error, size: 20),
                    const SizedBox(width: AppConstants.spacingSm),
                    Expanded(
                      child: Text(
                        'هذا التحديث يحتوي على إصلاحات أمنية مهمة',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),
            ],
            
            Text(message),
            const SizedBox(height: AppConstants.spacingMd),
            Container(
              padding: AppConstants.paddingSm,
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: AppConstants.borderRadiusSm,
              ),
              child: Text(
                'الإصدار المطلوب: $minVersion',
                style: TextStyle(
                  color: AppColors.info,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (!required)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('لاحقاً'),
            ),
          ElevatedButton(
            onPressed: () {
              // ← Hint: TODO - فتح متجر التطبيقات
              debugPrint('TODO: فتح متجر التطبيقات');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isCritical 
                ? AppColors.error 
                : (required ? AppColors.error : AppColors.info),
            ),
            child: const Text('تحديث الآن'),
          ),
        ],
      ),
    ),
  );
}

  // ===========================================================================
  // الدوال الموجودة مسبقاً (بدون تغيير)
  // ===========================================================================
  
  void _showManipulationWarning(
    AppLocalizations l10n,
    String message,
    int attemptsRemaining,
  ) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: 28,
            ),
            const SizedBox(width: AppConstants.spacingSm),
            const Text('تحذير'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Container(
              padding: AppConstants.paddingMd,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: AppConstants.borderRadiusMd,
                border: Border.all(
                  color: AppColors.error.withOpacity(0.3),
                ),
              ),
              child: Text(
                '⚠️ المحاولات المتبقية: $attemptsRemaining\n'
                'بعد ذلك سيتم حظر التطبيق نهائياً',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showInternetRequiredDialog(AppLocalizations l10n) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.wifi_off,
              color: AppColors.error,
              size: 28,
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Text(l10n.internetRequired),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'لم يتم الاتصال بالإنترنت منذ 7 أيام',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              'يجب الاتصال بالإنترنت لمتابعة استخدام التطبيق',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final success = await TimeValidationService.instance.forceSync();
              
              if (success && mounted) {
                _loadAndNavigate();
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('فشل الاتصال بالإنترنت. حاول مرة أخرى'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('حاول الاتصال'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  void _navigateToScreen(Widget screen) {
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

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
            colors: isDark 
              ? AppColors.gradientDark
              : AppColors.gradientLight,
          ),
        ),
        
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        _buildCompanyLogo(),
                        const SizedBox(height: AppConstants.spacingLg),
                        _buildCompanyName(),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: AppConstants.spacingXl),
                _buildLoadingIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyLogo() {
    final bool hasLogo = _companyLogo != null && _companyLogo!.existsSync();

    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: hasLogo
          ? Image.file(
              _companyLogo!,
              fit: BoxFit.cover,
            )
          : Icon(
              Icons.store,
              size: 70,
              color: AppColors.primaryLight.withOpacity(0.7),
            ),
      ),
    );
  }

  Widget _buildCompanyName() {
    if (_companyName.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingLg,
        vertical: AppConstants.spacingMd,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: AppConstants.borderRadiusLg,
      ),
      child: Text(
        _companyName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 30,
      height: 30,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(
          Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }
}