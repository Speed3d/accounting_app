// lib/screens/auth/splash_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import '../../data/database_helper.dart';
import '../../services/device_service.dart';
import '../../services/time_validation_service.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import 'create_admin_screen.dart';
import 'login_screen.dart';
import 'activation_screen.dart';
import 'blocked_screen.dart';

/// ===========================================================================
/// شاشة البداية (Splash Screen) - محسّنة للأداء
/// ← Hint: النسخة المصححة بدون أخطاء
/// ===========================================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> 
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  String _companyName = '';
  File? _companyLogo;
  
  // عدد ايام الافتراضية لتفعيل التطبيق
  // static const int trialPeriodDays = 14;
  static const int trialPeriodDays = 19;

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
  // ← Hint: تحميل البيانات والتنقل (محسّن ومصحح!)
  // ===========================================================================
  Future<void> _loadAndNavigate() async {
    final l10n = AppLocalizations.of(context)!;
    final dbHelper = DatabaseHelper.instance;
    final deviceService = DeviceService.instance;
    final timeService = TimeValidationService.instance;

    // ============= الخطوة 1: تحميل معلومات الشركة =============
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

    // ============= الخطوة 2: الانتظار لإكمال الأنيميشن =============
    await Future.delayed(const Duration(milliseconds: splashDuration));
    if (!mounted) return;

    // ============= الخطوة 3: تهيئة خدمة التحقق من الوقت =============
    debugPrint('🔄 بدء تهيئة TimeValidationService...');
    await timeService.initialize();

    // ============= الخطوة 4: كشف التلاعب (سريع - بدون NTP!) =============
    debugPrint('🔍 فحص التلاعب...');
    final manipulationResult = await timeService.detectManipulation();

    if (manipulationResult['isManipulated'] == true) {
      final attemptsRemaining = timeService.getAttemptsRemaining();
      
      // ← Hint: استخدام دالة getter بدلاً من المتغير الخاص
      final currentAttempts = timeService.getSuspiciousAttempts();
      debugPrint('⚠️ تحذير #$currentAttempts - المحاولات المتبقية: $attemptsRemaining');

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

    // ============= الخطوة 5: التحقق من الحاجة للإنترنت =============
    if (timeService.shouldRequireInternet()) {
      debugPrint('⚠️ يتطلب اتصال بالإنترنت - مر 7 أيام');
      _showInternetRequiredDialog(l10n);
      return;
    }

    // ============= الخطوة 6: الحصول على الوقت (سريع جداً!) =============
    DateTime realTime;
    try {
      // ← Hint: timeout مع معالجة صحيحة
      realTime = await timeService.getRealTime().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('⏱️ انتهى وقت NTP - استخدام وقت الجهاز');
          // ← Hint: في حالة timeout، نستخدم وقت الجهاز
          // getRealTime نفسها ستستخدم drift داخلياً إذا فشلت
          return DateTime.now();
        },
      );
    } catch (e) {
      debugPrint('⚠️ خطأ في الحصول على الوقت: $e');
      realTime = DateTime.now();
    }

    debugPrint('⏰ الوقت المستخدم: $realTime');

    // ← Hint: بدء مزامنة في الخلفية (لا تُوقف التطبيق!)
    timeService.backgroundSync().then((_) {
      debugPrint('✅ اكتملت المزامنة الخلفية');
    }).catchError((e) {
      debugPrint('⚠️ فشلت المزامنة الخلفية (لا مشكلة): $e');
    });

    // ============= الخطوة 7: التحقق من حالة التطبيق =============
    try {
      final appState = await dbHelper.getAppState();
      final userCount = await dbHelper.getUserCount();
      final deviceFingerprint = await deviceService.getDeviceFingerprint();

      // --- حالة 1: التطبيق يعمل لأول مرة ---
      if (appState == null) {
        await dbHelper.initializeAppState();
        _navigateToScreen(
          userCount == 0 
            ? CreateAdminScreen(l10n: l10n)
            : LoginScreen(l10n: l10n),
        );
        return;
      }

      // --- حالة 2: التطبيق مفعّل ---
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

      // --- حالة 3: الفترة التجريبية ---
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
      
      if (mounted) {
        _navigateToScreen(LoginScreen(l10n: l10n));
      }
    }
  }

  // ===========================================================================
  // ← Hint: عرض تحذير التلاعب
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

  // ===========================================================================
  // ← Hint: عرض رسالة الحاجة للإنترنت
  // ===========================================================================
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