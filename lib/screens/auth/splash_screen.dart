// lib/screens/auth/splash_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/database_helper.dart';
import '../../services/device_service.dart';
import '../../services/firebase_service.dart';
import '../../services/time_validation_service.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';

import 'login_selection_screen.dart';  // 🆕 بدلاً من login_screen
import 'register_screen.dart';  // 🆕
import 'blocked_screen.dart';

/// ===========================================================================
/// شاشة البداية (Splash Screen) - نسخة محسّنة ونظيفة
/// ===========================================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> 
    with SingleTickerProviderStateMixin {
  
  // ==========================================================================
  // المتغيرات
  // ==========================================================================
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  String _companyName = '';
  File? _companyLogo;
  
  static const int trialPeriodDays = 14;
  static const int splashDuration = 1500; // ← مُخفّض من 2500 إلى 1500

  // ==========================================================================
  // Lifecycle
  // ==========================================================================

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndNavigate();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // الأنيميشن
  // ==========================================================================

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // ← مُخفّض من 1500
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  // ==========================================================================
  // المنطق الرئيسي - محسّن للأداء
  // ==========================================================================

  Future<void> _loadAndNavigate() async {
    try {
      final l10n = AppLocalizations.of(context)!;
      
      // ← Hint: كل الخدمات معرّفة مرة واحدة
      final dbHelper = DatabaseHelper.instance;
      final deviceService = DeviceService.instance;
      final timeService = TimeValidationService.instance;
      final firebaseService = FirebaseService.instance;

      // ======================================================================
      // المرحلة 1: تحميل بيانات الشركة (سريع - محلي)
      // ======================================================================
      
      await _loadCompanyInfo(dbHelper, l10n);

      // ======================================================================
      // المرحلة 2: انتظار الأنيميشن (متوازي)
      // ======================================================================
      
      await Future.delayed(const Duration(milliseconds: splashDuration));
      if (!mounted) return;

      // ======================================================================
      // المرحلة 3: Firebase Remote Config (سريع - مع timeout)
      // ======================================================================
      
      await _checkFirebaseUpdates(firebaseService);

      // ======================================================================
      // المرحلة 4: فحص حالة التطبيق (Kill Switch)
      // ======================================================================
      
      final appStatus = await _checkAppStatus(firebaseService);
      if (!mounted) return;
      
      // ← Hint: إذا فشل الفحص، نعرض الحوار ونوقف
      if (!appStatus['canContinue']) return;

      // ======================================================================
      // المرحلة 5: Root Detection (سريع - اختياري)
      // ======================================================================
      
      await _checkRootStatus(deviceService, l10n, firebaseService);
      if (!mounted) return;

      // ======================================================================
      // المرحلة 6: Time Validation (محسّن - بدون NTP في البداية)
      // ======================================================================
      
      await timeService.initialize();
      
      final manipulationResult = await timeService.detectManipulation();
      
      if (manipulationResult['isManipulated'] == true) {
        _handleTimeManipulation(
          l10n, 
          manipulationResult, 
          timeService, 
          deviceService, 
          firebaseService
        );
        return;
      }

      // ← Hint: NTP في الخلفية (لا نوقف التطبيق!)
      final realTime = await _getRealTimeWithFallback(timeService);

      // ← Hint: مزامنة خلفية (fire and forget)
      timeService.backgroundSync().catchError((e) {
        debugPrint('⚠️ خطأ في المزامنة الخلفية (غير حرج): $e');
      });

      // ======================================================================
      // المرحلة 7: التحقق من الحاجة للإنترنت
      // ======================================================================
      
      if (timeService.shouldRequireInternet()) {
        _showInternetRequiredDialog(l10n);
        return;
      }

      // ======================================================================
      // المرحلة 8: منطق التنقل (النهائي)
      // ======================================================================
      
      await _handleNavigation(
        dbHelper, 
        deviceService, 
        realTime, 
        l10n
      );

    } catch (e, stackTrace) {
      _handleCriticalError(e, stackTrace);
    }
  }

  // ==========================================================================
  // الدوال المساعدة - منظمة
  // ==========================================================================

  /// تحميل معلومات الشركة
  Future<void> _loadCompanyInfo(
    DatabaseHelper dbHelper, 
    AppLocalizations l10n
  ) async {
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
      debugPrint('⚠️ خطأ في تحميل معلومات الشركة: $e');
    }
  }

  /// فحص تحديثات Firebase (محسّن - بدون تأخير)
  Future<void> _checkFirebaseUpdates(FirebaseService firebaseService) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastFetch = prefs.getInt('last_config_fetch') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // ← Hint: تحديث كل 24 ساعة فقط (ليس كل Hot Restart!)
      final shouldRefresh = lastFetch == 0 || 
        (now - lastFetch) > (24 * 60 * 60 * 1000);

      if (shouldRefresh) {
        debugPrint('🔄 تحديث Remote Config...');
        
        final refreshed = await firebaseService.forceRefreshConfig().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            debugPrint('⏱️ Timeout - استخدام Cache');
            return false;
          },
        );
        
        if (refreshed) {
          await prefs.setInt('last_config_fetch', now);
          debugPrint('✅ تم التحديث');
        }
      } else {
        final hoursSince = ((now - lastFetch) / (60 * 60 * 1000)).round();
        debugPrint('ℹ️ استخدام Cache (آخر تحديث: منذ $hoursSince ساعة)');
      }
    } catch (e) {
      debugPrint('⚠️ خطأ في Firebase refresh: $e');
    }
  }

  /// فحص حالة التطبيق (Kill Switch)
  Future<Map<String, dynamic>> _checkAppStatus(
    FirebaseService firebaseService
  ) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      final appStatus = await firebaseService.checkAppStatus(
        currentVersion: currentVersion,
      ).timeout(
        const Duration(seconds: 3),
        onTimeout: () => {
          'canContinue': true,
          'isActive': true,
        },
      );

      // 1️⃣ جهاز محظور
      if (appStatus['isBlocked'] == true) {
        _showKillSwitchDialog(
          title: 'الجهاز محظور',
          message: appStatus['message'] ?? 'تم حظر هذا الجهاز',
          canClose: false,
          icon: Icons.block,
          iconColor: AppColors.error,
        );
        return {'canContinue': false};
      }

      // 2️⃣ وضع صيانة أو موقوف
      if (appStatus['isActive'] != true) {
        final reason = appStatus['reason'] ?? '';
        final isMaintenanceMode = reason == 'maintenance';
        
        _showKillSwitchDialog(
          title: isMaintenanceMode ? 'وضع الصيانة' : 'التطبيق متوقف',
          message: appStatus['message'] ?? 'التطبيق متوقف مؤقتاً',
          canClose: false,
          icon: isMaintenanceMode ? Icons.engineering : Icons.block,
          iconColor: isMaintenanceMode ? AppColors.warning : AppColors.error,
        );
        return {'canContinue': false};
      }

      // 3️⃣ يحتاج تحديث
      if (appStatus['needsUpdate'] == true) {
        final forceUpdate = appStatus['forceUpdate'] == true;
        final isCritical = appStatus['reason'] == 'critical_update';
        
        _showUpdateDialog(
          message: appStatus['message'] ?? 'يتوفر تحديث جديد',
          required: forceUpdate,
          minVersion: appStatus['minVersion'] ?? '',
          isCritical: isCritical,
        );
        
        if (forceUpdate) {
          return {'canContinue': false};
        }
      }

      return {'canContinue': true};
      
    } catch (e) {
      debugPrint('⚠️ خطأ في فحص حالة التطبيق: $e');
      return {'canContinue': true}; // fail-safe
    }
  }

  /// فحص Root (اختياري - بدون إيقاف)
  Future<void> _checkRootStatus(
    DeviceService deviceService,
    AppLocalizations l10n,
    FirebaseService firebaseService,
  ) async {
    try {
      final isRooted = await deviceService.isDeviceRooted().timeout(
        const Duration(seconds: 2),
        onTimeout: () => false,
      );
      
      if (isRooted) {
        debugPrint('⚠️ الجهاز مُخترق (Rooted)');
        
        firebaseService.logSuspiciousActivity(
          reason: 'rooted_device',
          deviceId: await deviceService.getDeviceFingerprint(),
          additionalInfo: {'action': 'device_root_detected'},
        );

        if (mounted) {
          _showRootWarningDialog(l10n);
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    } catch (e) {
      debugPrint('⚠️ خطأ في فحص Root: $e');
    }
  }

  /// الحصول على الوقت الحقيقي (مع fallback سريع)
  Future<DateTime> _getRealTimeWithFallback(
    TimeValidationService timeService
  ) async {
    try {
      return await timeService.getRealTime().timeout(
        const Duration(seconds: 2), // ← timeout قصير جداً
        onTimeout: () {
          debugPrint('⏱️ NTP timeout - استخدام وقت الجهاز');
          return DateTime.now();
        },
      );
    } catch (e) {
      debugPrint('⚠️ خطأ في الحصول على الوقت: $e');
      return DateTime.now();
    }
  }

  /// معالجة التلاعب بالوقت
  void _handleTimeManipulation(
    AppLocalizations l10n,
    Map<String, dynamic> manipulationResult,
    TimeValidationService timeService,
    DeviceService deviceService,
    FirebaseService firebaseService,
  ) {
    final attemptsRemaining = timeService.getAttemptsRemaining();
    final currentAttempts = timeService.getSuspiciousAttempts();
    
    debugPrint('⚠️ تحذير #$currentAttempts - المتبقي: $attemptsRemaining');

    firebaseService.logSuspiciousActivity(
      reason: manipulationResult['reason'] ?? 'time_manipulation',
      deviceId: deviceService.getDeviceFingerprint().toString(),
      additionalInfo: {
        'attempts': currentAttempts,
        'message': manipulationResult['message'] ?? 'Unknown',
      },
    );

    if (attemptsRemaining <= 0) {
      _navigateToScreen(
        BlockedScreen(
          reason: manipulationResult['reason'] ?? 'unknown',
          message: manipulationResult['message'],
        ),
      );
    } else {
      _showManipulationWarning(
        l10n,
        manipulationResult['message'] ?? 'تم رصد تلاعب',
        attemptsRemaining,
      );
    }
  }

  /// 🆕 منطق التنقل النهائي (النظام الجديد - Email-based)
  Future<void> _handleNavigation(
    DatabaseHelper dbHelper,
    DeviceService deviceService,
    DateTime realTime,
    AppLocalizations l10n,
  ) async {
    try {
      debugPrint('🧭 بدء منطق التنقل...');

      final userCount = await dbHelper.getUserCount();
      final hasOwner = await dbHelper.hasOwner();

      debugPrint('📊 عدد المستخدمين: $userCount | يوجد Owner: $hasOwner');

      // 1️⃣ لا يوجد أي مستخدمين → توجيه للتسجيل
      if (userCount == 0) {
        debugPrint('➡️ لا يوجد مستخدمين → RegisterScreen');
        _navigateToScreen(const RegisterScreen());
        return;
      }

      // 2️⃣ يوجد مستخدمون لكن لا يوجد Owner → توجيه للتسجيل
      if (!hasOwner) {
        debugPrint('➡️ لا يوجد Owner → RegisterScreen');
        _navigateToScreen(const RegisterScreen());
        return;
      }

      // 3️⃣ ✅ كل شيء تمام → توجيه لشاشة اختيار نوع الدخول
      // 🆕 Hint: تمرير معلومات الشركة من TB_Settings إلى LoginSelectionScreen
      debugPrint('➡️ كل شيء طبيعي → LoginSelectionScreen');
      _navigateToScreen(LoginSelectionScreen(
        companyName: _companyName.isNotEmpty ? _companyName : null,
        companyLogoPath: _companyLogo?.path,
      ));

    } catch (e, stackTrace) {
      debugPrint('❌ خطأ في التنقل: $e');
      FirebaseService.instance.logError(e, stackTrace, reason: 'navigation_error');

      // Fallback: التوجيه لشاشة التسجيل
      if (mounted) {
        _navigateToScreen(const RegisterScreen());
      }
    }
  }

  /// معالجة الأخطاء الحرجة
  void _handleCriticalError(dynamic error, StackTrace stackTrace) {
    debugPrint('❌ خطأ حرج في Splash Screen: $error');
    debugPrint('Stack trace: $stackTrace');
    
    FirebaseService.instance.logError(
      error, 
      stackTrace, 
      reason: 'splash_critical_error',
      fatal: true,
    );

    if (mounted) {
      _showErrorDialog(error.toString());
    }
  }

  // ==========================================================================
  // حوارات الـ UI
  // ==========================================================================

  void _showKillSwitchDialog({
    required String title,
    required String message,
    required bool canClose,
    IconData? icon,
    Color? iconColor,
  }) {
    if (!mounted) return;
    
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
              Icon(icon ?? Icons.block, color: iconColor ?? AppColors.error, size: 28),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(child: Text(title, style: TextStyle(color: iconColor ?? AppColors.error))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppConstants.spacingLg),
              Icon(icon ?? Icons.engineering, size: 64, color: iconColor ?? AppColors.warning),
            ],
          ),
          actions: canClose ? [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ] : [],
        ),
      ),
    );
  }

  void _showUpdateDialog({
    required String message,
    required bool required,
    required String minVersion,
    bool isCritical = false,
  }) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: !required,
      builder: (context) => WillPopScope(
        onWillPop: () async => !required,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppConstants.borderRadiusLg),
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
              if (isCritical) ...[
                Container(
                  padding: AppConstants.paddingSm,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: AppConstants.borderRadiusSm,
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
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
                  style: TextStyle(color: AppColors.info, fontWeight: FontWeight.bold),
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
            Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
            const SizedBox(width: AppConstants.spacingSm),
            const Text('تحذير'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: AppConstants.spacingMd),
            Container(
              padding: AppConstants.paddingMd,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: AppConstants.borderRadiusMd,
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
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
            Icon(Icons.wifi_off, color: AppColors.error, size: 28),
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
                    content: const Text('فشل الاتصال. حاول مرة أخرى'),
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

  void _showRootWarningDialog(AppLocalizations l10n) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppConstants.borderRadiusLg),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
            const SizedBox(width: AppConstants.spacingSm),
            const Text('تحذير أمني'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تم كشف أن هذا الجهاز مُخترق (Rooted/Jailbroken)',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Container(
              padding: AppConstants.paddingMd,
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: AppConstants.borderRadiusMd,
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWarningItem('• قد لا تعمل بعض الميزات بشكل صحيح'),
                  _buildWarningItem('• بياناتك قد تكون في خطر'),
                  _buildWarningItem('• نوصي باستخدام جهاز آمن'),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              'يمكنك الاستمرار على مسؤوليتك الخاصة',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('فهمت، المتابعة'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String errorMessage) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 28),
            const SizedBox(width: AppConstants.spacingSm),
            const Text('خطأ'),
          ],
        ),
        content: Text(
          'حدث خطأ غير متوقع:\n$errorMessage\n\nسيتم إعادة المحاولة...',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadAndNavigate();
            },
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.warning,
        ),
      ),
    );
  }

  void _navigateToScreen(Widget screen) {
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  // ==========================================================================
  // UI
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
          ? Image.file(_companyLogo!, fit: BoxFit.cover)
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