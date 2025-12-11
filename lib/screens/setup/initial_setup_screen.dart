// lib/screens/setup/initial_setup_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database_helper.dart';
import '../../providers/locale_provider.dart';
import '../../services/currency_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../auth/register_screen.dart';

/// ============================================================================
/// ⚙️ شاشة التهيئة الأولية - معالج خطوة بخطوة
/// ============================================================================
///
/// ← Hint: تُعرض بعد Onboarding مباشرة
/// ← Hint: تساعد المستخدم على إعداد:
///    1. اللغة
///    2. العملة
///    3. معلومات الشركة (اسم + شعار)
///
/// ============================================================================

class InitialSetupScreen extends StatefulWidget {
  const InitialSetupScreen({super.key});

  /// ← Hint: مفتاح حفظ حالة الإعداد في SharedPreferences
  static const String _keySetupComplete = 'initial_setup_completed';

  /// ============================================================================
  /// 🔍 فحص إذا تم إكمال الإعداد سابقاً
  /// ============================================================================
  static Future<bool> isCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keySetupComplete) ?? false;
    } catch (e) {
      debugPrint('❌ [InitialSetup] خطأ في قراءة حالة الإعداد: $e');
      return false;
    }
  }

  /// ============================================================================
  /// 🔄 إعادة تعيين الإعداد (للتجربة فقط)
  /// ============================================================================
  static Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySetupComplete);
      debugPrint('✅ [InitialSetup] تم إعادة تعيين الإعداد');
    } catch (e) {
      debugPrint('❌ [InitialSetup] خطأ في إعادة تعيين الإعداد: $e');
    }
  }

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;

  // ← Hint: بيانات الإعداد
  Locale _selectedLocale = const Locale('ar');
  Currency _selectedCurrency = Currency.usd;
  final _companyNameController = TextEditingController();
  File? _companyLogo;

  @override
  void dispose() {
    _pageController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ← Hint: مؤشر التقدم
            _buildProgressIndicator(isDark),

            // ← Hint: المحتوى
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // ← منع السحب
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                children: [
                  _buildWelcomePage(isDark),
                  _buildLanguagePage(isDark),
                  _buildCurrencyPage(isDark),
                  _buildCompanyInfoPage(isDark),
                ],
              ),
            ),

            // ← Hint: أزرار التنقل
            _buildNavigationButtons(isDark),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // 📊 مؤشر التقدم
  // ============================================================================
  Widget _buildProgressIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'خطوة ${_currentPage + 1} من $_totalPages',
                style: TextStyle(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (_currentPage > 0)
                TextButton(
                  onPressed: _skipSetup,
                  child: Text(
                    'تخطي',
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / _totalPages,
              minHeight: 6,
              backgroundColor: isDark ? AppColors.borderDark : AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 👋 صفحة الترحيب
  // ============================================================================
  Widget _buildWelcomePage(bool isDark) {
    return _PageTemplate(
      icon: Icons.settings_suggest,
      iconColor: AppColors.primaryLight,
      title: 'مرحباً! دعنا نبدأ الإعداد',
      subtitle: 'سنساعدك في إعداد التطبيق في 3 خطوات بسيطة',
      isDark: isDark,
      children: [
        _InfoCard(
          icon: Icons.language,
          title: 'اختيار اللغة',
          description: 'اختر لغتك المفضلة للتطبيق',
          color: AppColors.info,
          isDark: isDark,
        ),
        const SizedBox(height: AppConstants.spacingMd),
        _InfoCard(
          icon: Icons.attach_money,
          title: 'تحديد العملة',
          description: 'اختر العملة الرئيسية لحساباتك',
          color: AppColors.success,
          isDark: isDark,
        ),
        const SizedBox(height: AppConstants.spacingMd),
        _InfoCard(
          icon: Icons.business,
          title: 'معلومات الشركة',
          description: 'أضف اسم شركتك وشعارها (اختياري)',
          color: AppColors.warning,
          isDark: isDark,
        ),
      ],
    );
  }

  // ============================================================================
  // 🌍 صفحة اختيار اللغة
  // ============================================================================
  Widget _buildLanguagePage(bool isDark) {
    return _PageTemplate(
      icon: Icons.language,
      iconColor: AppColors.info,
      title: 'اختر لغة التطبيق',
      subtitle: 'يمكنك تغييرها لاحقاً من الإعدادات',
      isDark: isDark,
      children: [
        _SelectionCard(
          title: 'العربية',
          subtitle: 'Arabic - اللغة الرسمية',
          icon: Icons.check_circle,
          isSelected: _selectedLocale.languageCode == 'ar',
          color: AppColors.success,
          isDark: isDark,
          onTap: () {
            setState(() => _selectedLocale = const Locale('ar'));
          },
        ),
        const SizedBox(height: AppConstants.spacingMd),
        _SelectionCard(
          title: 'English',
          subtitle: 'الإنجليزية - Secondary language',
          icon: Icons.check_circle_outline,
          isSelected: _selectedLocale.languageCode == 'en',
          color: AppColors.info,
          isDark: isDark,
          onTap: () {
            setState(() => _selectedLocale = const Locale('en'));
          },
        ),
      ],
    );
  }

  // ============================================================================
  // 💰 صفحة اختيار العملة
  // ============================================================================
  Widget _buildCurrencyPage(bool isDark) {
    return _PageTemplate(
      icon: Icons.attach_money,
      iconColor: AppColors.success,
      title: 'اختر عملتك الرئيسية',
      subtitle: 'ستُستخدم في جميع المعاملات المالية',
      isDark: isDark,
      children: [
        ...Currency.values.map((currency) {
          final isArabic = _selectedLocale.languageCode == 'ar';
          return Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.spacingSm),
            child: _SelectionCard(
              title: '${currency.getName(isArabic)} (${currency.symbol})',
              subtitle: currency.code,
              icon: Icons.monetization_on,
              isSelected: _selectedCurrency == currency,
              color: AppColors.warning,
              isDark: isDark,
              onTap: () {
                setState(() => _selectedCurrency = currency);
              },
            ),
          );
        }),
      ],
    );
  }

  // ============================================================================
  // 🏢 صفحة معلومات الشركة
  // ============================================================================
  Widget _buildCompanyInfoPage(bool isDark) {
    return _PageTemplate(
      icon: Icons.business,
      iconColor: AppColors.warning,
      title: 'معلومات شركتك',
      subtitle: 'اختياري - يمكن إضافتها لاحقاً',
      isDark: isDark,
      children: [
        // ← Hint: حقل اسم الشركة
        TextField(
          controller: _companyNameController,
          decoration: InputDecoration(
            labelText: 'اسم الشركة أو المتجر',
            hintText: 'مثال: محلات الأمل التجارية',
            prefixIcon: const Icon(Icons.store),
            border: OutlineInputBorder(
              borderRadius: AppConstants.borderRadiusMd,
            ),
          ),
          textInputAction: TextInputAction.done,
        ),

        const SizedBox(height: AppConstants.spacingLg),

        // ← Hint: شعار الشركة
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            borderRadius: AppConstants.borderRadiusMd,
          ),
          child: Column(
            children: [
              if (_companyLogo != null)
                ClipRRect(
                  borderRadius: AppConstants.borderRadiusMd,
                  child: Image.file(
                    _companyLogo!,
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Icon(
                  Icons.add_photo_alternate,
                  size: 64,
                  color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
                ),
              const SizedBox(height: AppConstants.spacingMd),
              Text(
                _companyLogo != null ? 'شعار الشركة' : 'إضافة شعار (اختياري)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_companyLogo != null)
                    TextButton.icon(
                      onPressed: () {
                        setState(() => _companyLogo = null);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('إزالة'),
                    ),
                  TextButton.icon(
                    onPressed: _pickCompanyLogo,
                    icon: Icon(_companyLogo != null ? Icons.edit : Icons.upload),
                    label: Text(_companyLogo != null ? 'تغيير' : 'اختيار صورة'),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppConstants.spacingMd),

        // ← Hint: ملاحظة
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: AppConstants.borderRadiusSm,
            border: Border.all(color: AppColors.info.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.info, size: 20),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Text(
                  'يمكنك تعديل هذه المعلومات في أي وقت من الإعدادات',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // 🔘 أزرار التنقل
  // ============================================================================
  Widget _buildNavigationButtons(bool isDark) {
    final isLastPage = _currentPage == _totalPages - 1;
    final isFirstPage = _currentPage == 0;

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // ← Hint: زر الرجوع
          if (!isFirstPage)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousPage,
                icon: const Icon(Icons.arrow_back),
                label: const Text('السابق'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

          if (!isFirstPage) const SizedBox(width: AppConstants.spacingMd),

          // ← Hint: زر التالي/الإنهاء
          Expanded(
            flex: isFirstPage ? 1 : 1,
            child: ElevatedButton.icon(
              onPressed: isLastPage ? _completeSetup : _nextPage,
              icon: Icon(isLastPage ? Icons.check : Icons.arrow_forward),
              label: Text(isLastPage ? 'ابدأ الآن' : 'التالي'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 📸 اختيار شعار الشركة
  // ============================================================================
  Future<void> _pickCompanyLogo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _companyLogo = File(image.path);
        });
        debugPrint('✅ [InitialSetup] تم اختيار شعار الشركة');
      }
    } catch (e) {
      debugPrint('❌ [InitialSetup] خطأ في اختيار الصورة: $e');
    }
  }

  // ============================================================================
  // ⏭️ التنقل بين الصفحات
  // ============================================================================
  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipSetup() {
    _completeSetup();
  }

  // ============================================================================
  // ✅ إكمال الإعداد
  // ============================================================================
  Future<void> _completeSetup() async {
    try {
      debugPrint('🎯 [InitialSetup] حفظ الإعدادات...');

      // ← Hint: 1️⃣ حفظ اللغة
      final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
      await localeProvider.setLocale(_selectedLocale);
      debugPrint('✅ [InitialSetup] تم حفظ اللغة: ${_selectedLocale.languageCode}');

      // ← Hint: 2️⃣ حفظ العملة
      await CurrencyService.instance.setCurrency(_selectedCurrency);
      debugPrint('✅ [InitialSetup] تم حفظ العملة: ${_selectedCurrency.code}');

      // ← Hint: 3️⃣ حفظ معلومات الشركة
      final companyName = _companyNameController.text.trim();
      if (companyName.isNotEmpty || _companyLogo != null) {
        final dbHelper = DatabaseHelper.instance;

        if (companyName.isNotEmpty) {
          await dbHelper.updateCompanyName(companyName);
          debugPrint('✅ [InitialSetup] تم حفظ اسم الشركة: $companyName');
        }

        if (_companyLogo != null) {
          await dbHelper.updateCompanyLogo(_companyLogo!.path);
          debugPrint('✅ [InitialSetup] تم حفظ شعار الشركة');
        }
      }

      // ← Hint: 4️⃣ حفظ حالة إكمال الإعداد
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(InitialSetupScreen._keySetupComplete, true);
      debugPrint('✅ [InitialSetup] تم إكمال الإعداد الأولي');

      if (!mounted) return;

      // ← Hint: 5️⃣ الانتقال لشاشة التسجيل
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RegisterScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('❌ [InitialSetup] خطأ في حفظ الإعدادات: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('حدث خطأ في حفظ الإعدادات'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

// ============================================================================
// 📄 قالب الصفحة
// ============================================================================
class _PageTemplate extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isDark;
  final List<Widget> children;

  const _PageTemplate({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ← Hint: الأيقونة
          Center(
            child: Container(
              padding: const EdgeInsets.all(AppConstants.spacingLg),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: iconColor),
            ),
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // ← Hint: العنوان
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppConstants.spacingSm),

          // ← Hint: الوصف
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppConstants.spacingXl),

          // ← Hint: المحتوى
          ...children,
        ],
      ),
    );
  }
}

// ============================================================================
// ℹ️ بطاقة معلومات
// ============================================================================
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool isDark;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppConstants.borderRadiusMd,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingSm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: AppConstants.borderRadiusSm,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppConstants.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
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

// ============================================================================
// ✅ بطاقة اختيار
// ============================================================================
class _SelectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppConstants.borderRadiusMd,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: AppConstants.borderRadiusMd,
          border: Border.all(
            color: isSelected ? color : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? color : AppColors.textHintLight,
              size: 28,
            ),
            const SizedBox(width: AppConstants.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected ? color : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
