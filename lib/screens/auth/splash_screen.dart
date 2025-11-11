// lib/screens/auth/splash_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

// ============= استيراد الملفات =============
import '../../data/database_helper.dart';
import '../../services/device_service.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import 'create_admin_screen.dart';
import 'login_screen.dart';
import 'activation_screen.dart';

/// ===========================================================================
/// شاشة البداية (Splash Screen)
/// ===========================================================================
/// الغرض:
/// - عرض شعار الشركة واسمها أثناء تحميل التطبيق
/// - التحقق من حالة التطبيق (مفعّل، تجريبي، منتهي)
/// - التوجيه للشاشة المناسبة (إنشاء مستخدم، تسجيل دخول، تفعيل)
/// ===========================================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> 
    with SingleTickerProviderStateMixin {
  
  // ============= متغيرات الأنيميشن =============
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;      // تأثير الظهور التدريجي
  late Animation<double> _scaleAnimation;     // تأثير التكبير
  
  // ============= متغيرات البيانات =============
  String _companyName = '';                    // اسم الشركة من قاعدة البيانات
  File? _companyLogo;                          // شعار الشركة من قاعدة البيانات
  
  // ============= الثوابت =============
  static const int trialPeriodDays = 17;      // مدة الفترة التجريبية (14 يوم)
  // static const int trialPeriodDays = 14;      // مدة الفترة التجريبية (14 يوم)
  static const int splashDuration = 2500;     // مدة عرض الشاشة (2.5 ثانية)

  // ===========================================================================
  // التهيئة الأولية
  // ===========================================================================
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    
    // تأجيل التنقل حتى يتم بناء الواجهة بالكامل
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndNavigate();
    });
  }

  // ===========================================================================
  // إعداد الأنيميشن
  // ===========================================================================
  void _setupAnimations() {
    // إنشاء Controller للأنيميشن (مدة 1.5 ثانية)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // أنيميشن الظهور التدريجي (من 0 إلى 1)
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn, // منحنى سلس للظهور
      ),
    );

    // أنيميشن التكبير (من 0.5 إلى 1)
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut, // منحنى سلس للتكبير
      ),
    );

    // بدء الأنيميشن
    _animationController.forward();
  }

  // ===========================================================================
  // التنظيف عند إغلاق الشاشة
  // ===========================================================================
  @override
  void dispose() {
    _animationController.dispose(); // تنظيف الأنيميشن لتجنب تسرب الذاكرة
    super.dispose();
  }

  // ===========================================================================
  // تحميل البيانات والتنقل للشاشة المناسبة
  // ===========================================================================
  Future<void> _loadAndNavigate() async {
    final l10n = AppLocalizations.of(context)!;
    final dbHelper = DatabaseHelper.instance;
    final deviceService = DeviceService.instance;

    // ============= الخطوة 1: تحميل معلومات الشركة =============
    try {
      final settings = await dbHelper.getAppSettings();
      if (mounted) {
        setState(() {
          // جلب اسم الشركة (أو استخدام الاسم الافتراضي)
          _companyName = settings['companyName'] ?? l10n.accountingProgram;
          
          // جلب شعار الشركة (إذا كان موجوداً)
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
    if (!mounted) return; // تحقق من أن الشاشة لا تزال مفتوحة

    // ============= الخطوة 3: التحقق من حالة التطبيق =============
    try {
      final appState = await dbHelper.getAppState();
      final userCount = await dbHelper.getUserCount();
      final deviceFingerprint = await deviceService.getDeviceFingerprint();

      // --- حالة 1: التطبيق يعمل لأول مرة ---
      if (appState == null) {
        await dbHelper.initializeAppState();
        _navigateToScreen(
          userCount == 0 
            ? CreateAdminScreen(l10n: l10n)  // إنشاء مستخدم مدير
            : LoginScreen(l10n: l10n),       // تسجيل دخول
        );
        return;
      }

      // --- حالة 2: التطبيق مفعّل (لديه تاريخ انتهاء) ---
      final expiryDateString = appState['activation_expiry_date'];
      if (expiryDateString != null) {
        final expiryDate = DateTime.parse(expiryDateString);
        
        if (DateTime.now().isBefore(expiryDate)) {
          // التفعيل ساري المفعول ✅
          _navigateToScreen(LoginScreen(l10n: l10n));
        } else {
          // التفعيل منتهي ❌
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

      if (DateTime.now().isAfter(trialEndsAt)) {
        // الفترة التجريبية انتهت ❌
        _navigateToScreen(
          ActivationScreen(
            l10n: l10n,
            deviceFingerprint: deviceFingerprint,
          ),
        );
      } else {
        // الفترة التجريبية لا تزال سارية ✅
        _navigateToScreen(LoginScreen(l10n: l10n));
      }

    } catch (e) {
      debugPrint('❌ خطأ أثناء التنقل من Splash Screen: $e');
      
      // في حالة حدوث خطأ، انتقل لشاشة تسجيل الدخول
      if (mounted) {
        _navigateToScreen(LoginScreen(l10n: l10n));
      }
    }
  }

  // ===========================================================================
  // دالة مساعدة للتنقل بين الشاشات
  // ===========================================================================
  void _navigateToScreen(Widget screen) {
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  // ===========================================================================
  // بناء واجهة المستخدم
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    // الحصول على معلومات الثيم
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
              ? AppColors.gradientDark   // ألوان الوضع الليلي
              : AppColors.gradientLight, // ألوان الوضع النهاري
          ),
        ),
        
        // ============= المحتوى =============
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ============= الأنيميشن الرئيسي =============
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        // --- شعار الشركة ---
                        _buildCompanyLogo(),
                        
                        const SizedBox(height: AppConstants.spacingLg),
                        
                        // --- اسم الشركة ---
                        _buildCompanyName(),
                      ],
                    ),
                  ),
                ),
                
                // ============= مؤشر التحميل =============
                const SizedBox(height: AppConstants.spacingXl),
                _buildLoadingIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // بناء شعار الشركة
  // ===========================================================================
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

  // ===========================================================================
  // بناء اسم الشركة
  // ===========================================================================
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

  // ===========================================================================
  // بناء مؤشر التحميل
  // ===========================================================================
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