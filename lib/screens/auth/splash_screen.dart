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
/// ← Hint: النسخة المصححة بدون أخطاء مع فحص ذكي للمستخدمين
/// ===========================================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> 
    with SingleTickerProviderStateMixin {
  
  // ← Hint: متحكم الأنيميشن - للتحكم في حركة العناصر على الشاشة
  late AnimationController _animationController;
  
  // ← Hint: أنيميشن التلاشي - لظهور العناصر تدريجياً
  late Animation<double> _fadeAnimation;
  
  // ← Hint: أنيميشن التكبير - لتكبير الشعار من الصغير للحجم الطبيعي
  late Animation<double> _scaleAnimation;
  
  // ← Hint: اسم الشركة - يتم تحميله من قاعدة البيانات
  String _companyName = '';
  
  // ← Hint: شعار الشركة - ملف صورة إذا كان موجوداً
  File? _companyLogo;
  
  // ← Hint: عدد أيام الفترة التجريبية قبل طلب التفعيل
  // static const int trialPeriodDays = 14;
  static const int trialPeriodDays = 19;

  // ← Hint: مدة عرض شاشة البداية بالميلي ثانية (2.5 ثانية)
  static const int splashDuration = 2500;

  @override
  void initState() {
    super.initState();
    // ← Hint: تهيئة الأنيميشن عند بداية الشاشة
    _setupAnimations();
    
    // ← Hint: تنفيذ التحميل والتنقل بعد بناء الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndNavigate();
    });
  }

  // ← Hint: إعداد أنيميشن التلاشي والتكبير
  void _setupAnimations() {
    // ← Hint: إنشاء متحكم الأنيميشن بمدة 1.5 ثانية
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // ← Hint: أنيميشن التلاشي من 0 (شفاف) إلى 1 (مرئي)
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    // ← Hint: أنيميشن التكبير من 0.5 (نصف الحجم) إلى 1 (الحجم الكامل)
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // ← Hint: بدء تشغيل الأنيميشن
    _animationController.forward();
  }

  @override
  void dispose() {
    // ← Hint: تنظيف الموارد عند إغلاق الشاشة
    _animationController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // ← Hint: تحميل البيانات والتنقل (محسّن ومصحح!)
  // ← Hint: هذه الدالة تتحقق من حالة التطبيق وتقرر أي شاشة يجب عرضها
  // ===========================================================================
  Future<void> _loadAndNavigate() async {
    final l10n = AppLocalizations.of(context)!;
    final dbHelper = DatabaseHelper.instance;
    final deviceService = DeviceService.instance;
    final timeService = TimeValidationService.instance;

    // ============= الخطوة 1: تحميل معلومات الشركة =============
    // ← Hint: تحميل اسم الشركة والشعار من قاعدة البيانات
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
    // ← Hint: الانتظار لعرض شاشة البداية لمدة محددة
    await Future.delayed(const Duration(milliseconds: splashDuration));
    if (!mounted) return;

    // ============= الخطوة 3: تهيئة خدمة التحقق من الوقت =============
    // ← Hint: تهيئة خدمة التحقق من الوقت للكشف عن التلاعب
    debugPrint('🔄 بدء تهيئة TimeValidationService...');
    await timeService.initialize();

    // ============= الخطوة 4: كشف التلاعب (سريع - بدون NTP!) =============
    // ← Hint: فحص سريع للتأكد من عدم تلاعب المستخدم بالوقت
    debugPrint('🔍 فحص التلاعب...');
    final manipulationResult = await timeService.detectManipulation();

    if (manipulationResult['isManipulated'] == true) {
      // ← Hint: تم رصد تلاعب - نتحقق من المحاولات المتبقية
      final attemptsRemaining = timeService.getAttemptsRemaining();
      
      // ← Hint: استخدام دالة getter بدلاً من المتغير الخاص
      final currentAttempts = timeService.getSuspiciousAttempts();
      debugPrint('⚠️ تحذير #$currentAttempts - المحاولات المتبقية: $attemptsRemaining');

      if (attemptsRemaining <= 0) {
        // ← Hint: تجاوز الحد الأقصى للمحاولات - حظر نهائي
        debugPrint('🚫 حظر نهائي - تجاوز الحد الأقصى');
        _navigateToScreen(
          BlockedScreen(
            reason: manipulationResult['reason'] ?? 'unknown',
            message: manipulationResult['message'],
          ),
        );
        return;
      } else {
        // ← Hint: مازالت هناك محاولات متبقية - عرض تحذير
        debugPrint('⚠️ تحذير - المحاولات المتبقية: $attemptsRemaining');
        _showManipulationWarning(
          l10n,
          manipulationResult['message'] ?? 'تم رصد تلاعب',
          attemptsRemaining,
        );
      }
    }

    // ============= الخطوة 5: التحقق من الحاجة للإنترنت =============
    // ← Hint: إذا مر 7 أيام بدون اتصال، نطلب من المستخدم الاتصال
    if (timeService.shouldRequireInternet()) {
      debugPrint('⚠️ يتطلب اتصال بالإنترنت - مر 7 أيام');
      _showInternetRequiredDialog(l10n);
      return;
    }

    // ============= الخطوة 6: الحصول على الوقت (سريع جداً!) =============
    // ← Hint: الحصول على الوقت الحقيقي (من NTP أو drift)
    DateTime realTime;
    try {
      // ← Hint: timeout مع معالجة صحيحة - ننتظر 3 ثوان فقط
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
    // ← Hint: هذه المزامنة تحدث في الخلفية ولا تؤثر على سرعة الشاشة
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

      // ============= ✅ الإصلاح 1: فحص ذكي للمستخدمين =============
      // ← Hint: نتحقق من عدد المستخدمين أولاً قبل أي شيء
      // ← Hint: هذا يحل مشكلة قاعدة البيانات الموجودة بدون مستخدمين
      if (userCount == 0) {
        // ← Hint: لا يوجد مستخدمين - نذهب لإنشاء المدير
        // ← Hint: حتى لو كانت قاعدة البيانات موجودة
        debugPrint('ℹ️ لا يوجد مستخدمين - التوجه لإنشاء المدير');
        
        // ← Hint: إذا لم يكن هناك appState، نقوم بتهيئته
        if (appState == null) {
          await dbHelper.initializeAppState();
        }
        
        _navigateToScreen(CreateAdminScreen(l10n: l10n));
        return;
      }

      // ← Hint: هنا نعلم أن هناك مستخدمين على الأقل
      // ← Hint: نتابع الفحص العادي للتفعيل

      // --- حالة 1: التطبيق يعمل لأول مرة ---
      // ← Hint: التطبيق جديد تماماً - لا توجد بيانات حالة
      if (appState == null) {
        await dbHelper.initializeAppState();
        _navigateToScreen(LoginScreen(l10n: l10n));
        return;
      }

      // --- حالة 2: التطبيق مفعّل ---
      // ← Hint: نتحقق من وجود تاريخ انتهاء التفعيل
      final expiryDateString = appState['activation_expiry_date'];
      if (expiryDateString != null) {
        final expiryDate = DateTime.parse(expiryDateString);
        
        // ← Hint: مقارنة الوقت الحالي مع تاريخ انتهاء التفعيل
        if (realTime.isBefore(expiryDate)) {
          // ← Hint: التفعيل ساري - انتقل لشاشة تسجيل الدخول
          _navigateToScreen(LoginScreen(l10n: l10n));
        } else {
          // ← Hint: التفعيل منتهي - اذهب لشاشة التفعيل
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
      // ← Hint: لا يوجد تفعيل - نستخدم الفترة التجريبية
      final firstRunDate = DateTime.parse(appState['first_run_date']);
      final trialEndsAt = firstRunDate.add(
        const Duration(days: trialPeriodDays),
      );

      // ← Hint: التحقق من انتهاء الفترة التجريبية
      if (realTime.isAfter(trialEndsAt)) {
        // ← Hint: الفترة التجريبية انتهت - يجب التفعيل
        _navigateToScreen(
          ActivationScreen(
            l10n: l10n,
            deviceFingerprint: deviceFingerprint,
          ),
        );
      } else {
        // ← Hint: الفترة التجريبية مازالت سارية
        _navigateToScreen(LoginScreen(l10n: l10n));
      }

    } catch (e) {
      debugPrint('❌ خطأ أثناء التنقل من Splash Screen: $e');
      
      // ← Hint: في حالة حدوث أي خطأ، نذهب لشاشة تسجيل الدخول كحل افتراضي
      if (mounted) {
        _navigateToScreen(LoginScreen(l10n: l10n));
      }
    }
  }

  // ===========================================================================
  // ← Hint: عرض تحذير التلاعب
  // ← Hint: تعرض للمستخدم رسالة تحذير مع عدد المحاولات المتبقية
  // ===========================================================================
  void _showManipulationWarning(
    AppLocalizations l10n,
    String message,
    int attemptsRemaining,
  ) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false, // ← Hint: لا يمكن إغلاق التحذير بالنقر خارجه
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
            // ← Hint: صندوق يعرض المحاولات المتبقية بتنسيق واضح
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
  // ← Hint: تظهر عندما يمر 7 أيام بدون اتصال بالإنترنت
  // ===========================================================================
  void _showInternetRequiredDialog(AppLocalizations l10n) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false, // ← Hint: يجب على المستخدم إما الاتصال أو الإلغاء
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
              
              // ← Hint: محاولة المزامنة الإجبارية مع الإنترنت
              final success = await TimeValidationService.instance.forceSync();
              
              if (success && mounted) {
                // ← Hint: نجحت المزامنة - إعادة التحميل
                _loadAndNavigate();
              } else if (mounted) {
                // ← Hint: فشلت المزامنة - عرض رسالة خطأ
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

  // ← Hint: دالة مساعدة للانتقال إلى شاشة جديدة
  // ← Hint: تستخدم pushReplacement لإزالة splash من المسار
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
        // ← Hint: خلفية متدرجة اللون حسب الوضع (فاتح/داكن)
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
                // ← Hint: أنيميشن التكبير والتلاشي للشعار واسم الشركة
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

  // ← Hint: بناء شعار الشركة
  // ← Hint: يعرض الصورة إذا كانت موجودة، وإلا يعرض أيقونة افتراضية
  Widget _buildCompanyLogo() {
    final bool hasLogo = _companyLogo != null && _companyLogo!.existsSync();

    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle, // ← Hint: شكل دائري للشعار
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

  // ← Hint: بناء اسم الشركة
  // ← Hint: يعرض اسم الشركة في صندوق شفاف
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

  // ← Hint: بناء مؤشر التحميل
  // ← Hint: دائرة دوارة تشير إلى أن التطبيق يعمل
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