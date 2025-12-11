// lib/screens/onboarding/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../setup/initial_setup_screen.dart'; // ← Hint: التهيئة الأولية

/// ============================================================================
/// 🎓 شاشة Onboarding - شرح تمهيدي للمستخدمين الجدد
/// ============================================================================
///
/// ← Hint: تُعرض فقط في أول فتح للتطبيق
/// ← Hint: تشرح الميزات الرئيسية بشكل مبسط وجذاب
/// ← Hint: يمكن تخطيها أو التمرير خلالها
///
/// ============================================================================

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  /// ← Hint: مفتاح حفظ حالة Onboarding في SharedPreferences
  static const String _keyOnboardingComplete = 'onboarding_completed';

  /// ============================================================================
  /// 🔍 فحص إذا تم إكمال Onboarding سابقاً
  /// ============================================================================
  /// ← Hint: استخدم هذه الدالة في splash_screen للتحقق
  static Future<bool> isCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyOnboardingComplete) ?? false;
    } catch (e) {
      debugPrint('❌ [Onboarding] خطأ في قراءة حالة Onboarding: $e');
      return false;
    }
  }

  /// ============================================================================
  /// 🔄 إعادة تعيين Onboarding (للتجربة فقط - احذف في الإنتاج)
  /// ============================================================================
  static Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyOnboardingComplete);
      debugPrint('✅ [Onboarding] تم إعادة تعيين Onboarding');
    } catch (e) {
      debugPrint('❌ [Onboarding] خطأ في إعادة تعيين Onboarding: $e');
    }
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _introKey = GlobalKey<IntroductionScreenState>();

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // ← Hint: قائمة صفحات Onboarding
    final pages = [
      _buildPage(
        title: isArabic ? 'مرحباً بك في Accountant Touch' : 'Welcome to Accountant Touch',
        body: isArabic
            ? 'تطبيقك المحاسبي الشامل لإدارة حسابات شركتك بكل سهولة واحترافية'
            : 'Your complete accounting app for managing your business accounts easily and professionally',
        icon: Icons.waving_hand,
        color: AppColors.primaryLight,
      ),
      _buildPage(
        title: isArabic ? 'إدارة المبيعات والمشتريات' : 'Sales & Purchases Management',
        body: isArabic
            ? 'سجل جميع عمليات البيع والشراء، وأنشئ فواتير احترافية بضغطة زر واحدة'
            : 'Record all sales and purchases, create professional invoices with one click',
        icon: Icons.receipt_long,
        color: AppColors.success,
      ),
      _buildPage(
        title: isArabic ? 'تتبع العملاء والموردين' : 'Track Customers & Suppliers',
        body: isArabic
            ? 'احفظ معلومات العملاء والموردين، وراقب الأرصدة والمستحقات بدقة'
            : 'Save customer and supplier information, monitor balances and receivables accurately',
        icon: Icons.people_outline,
        color: AppColors.info,
      ),
      _buildPage(
        title: isArabic ? 'تقارير مالية تفصيلية' : 'Detailed Financial Reports',
        body: isArabic
            ? 'احصل على تقارير شاملة للمبيعات والمشتريات والأرباح مع رسوم بيانية واضحة'
            : 'Get comprehensive reports for sales, purchases, and profits with clear charts',
        icon: Icons.analytics_outlined,
        color: AppColors.warning,
      ),
      _buildPage(
        title: isArabic ? 'نسخ احتياطي آمن' : 'Secure Backup',
        body: isArabic
            ? 'احمِ بياناتك بنسخ احتياطية مشفرة، واستعدها بسهولة في أي وقت'
            : 'Protect your data with encrypted backups, restore easily anytime',
        icon: Icons.backup_outlined,
        color: AppColors.success,
      ),
      _buildPage(
        title: isArabic ? 'أمان وخصوصية تامة' : 'Complete Security & Privacy',
        body: isArabic
            ? 'قاعدة بيانات مشفرة، قفل تلقائي، وبصمة الإصبع لحماية معلوماتك المالية'
            : 'Encrypted database, auto-lock, and fingerprint to protect your financial information',
        icon: Icons.security,
        color: AppColors.error,
      ),
    ];

    return IntroductionScreen(
      key: _introKey,
      pages: pages,

      // ← Hint: إعدادات عامة
      showSkipButton: true,
      showBackButton: true,
      showNextButton: true,

      // ← Hint: النصوص
      skip: Text(
        isArabic ? 'تخطي' : 'Skip',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      next: Icon(
        isArabic ? Icons.arrow_back : Icons.arrow_forward,
        color: AppColors.primaryLight,
      ),
      back: Icon(
        isArabic ? Icons.arrow_forward : Icons.arrow_back,
        color: AppColors.textSecondaryLight,
      ),
      done: Text(
        isArabic ? 'ابدأ الآن' : 'Get Started',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.primaryLight,
        ),
      ),

      // ← Hint: الأحداث
      onDone: () => _completeOnboarding(),
      onSkip: () => _completeOnboarding(),

      // ← Hint: التصميم
      dotsDecorator: DotsDecorator(
        size: const Size.square(10.0),
        activeSize: const Size(20.0, 10.0),
        activeColor: AppColors.primaryLight,
        color: AppColors.borderLight,
        spacing: const EdgeInsets.symmetric(horizontal: 3.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
      ),

      // ← Hint: السلوك
      freeze: false,
      animationDuration: 400,
      isProgressTap: true,
      isProgress: true,

      // ← Hint: التخطيط
      globalBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
      controlsMargin: const EdgeInsets.all(16),
      controlsPadding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
      dotsContainerDecorator: const BoxDecoration(
        color: Colors.transparent,
      ),
    );
  }

  /// ============================================================================
  /// 🎨 بناء صفحة Onboarding واحدة
  /// ============================================================================
  PageViewModel _buildPage({
    required String title,
    required String body,
    required IconData icon,
    required Color color,
  }) {
    return PageViewModel(
      titleWidget: Padding(
        padding: const EdgeInsets.only(top: AppConstants.spacingLg),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
            height: 1.4,
          ),
        ),
      ),
      bodyWidget: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingLg),
        child: Text(
          body,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            height: 1.6,
          ),
        ),
      ),
      decoration: PageDecoration(
        titlePadding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
        bodyPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        imagePadding: const EdgeInsets.only(top: 80.0),
        pageColor: Colors.transparent,
      ),
      image: _buildIcon(icon, color),
    );
  }

  /// ============================================================================
  /// 🎨 بناء أيقونة الصفحة مع تصميم جميل
  /// ============================================================================
  Widget _buildIcon(IconData icon, Color color) {
    return Center(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withOpacity(0.3),
              color.withOpacity(0.1),
              Colors.transparent,
            ],
            stops: const [0.3, 0.6, 1.0],
          ),
        ),
        child: Center(
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 80,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  /// ============================================================================
  /// ✅ إكمال Onboarding والانتقال للتهيئة
  /// ============================================================================
  Future<void> _completeOnboarding() async {
    try {
      // ← Hint: حفظ حالة إكمال Onboarding
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(OnboardingScreen._keyOnboardingComplete, true);

      if (!mounted) return;

      // ← Hint: الانتقال لشاشة التهيئة الأولية
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const InitialSetupScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('❌ [Onboarding] خطأ في حفظ حالة Onboarding: $e');
    }
  }
}
