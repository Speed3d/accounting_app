// lib/widgets/custom_drawer.dart
import 'dart:io';
import 'package:accountant_touch/screens/admin/activation_code_generator_screen.dart';
import 'package:accountant_touch/screens/admin/subscriptions_admin_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:accountant_touch/l10n/app_localizations.dart';
import 'package:accountant_touch/screens/customers/customers_list_screen.dart';
import 'package:accountant_touch/screens/employees/employees_list_screen.dart';
import 'package:accountant_touch/screens/products/products_list_screen.dart';
import 'package:accountant_touch/screens/reports/reports_hub_screen.dart';
import 'package:accountant_touch/screens/sales/direct_sale_screen.dart';
import 'package:accountant_touch/screens/settings/about_screen.dart';
import 'package:accountant_touch/screens/settings/settings_screen.dart';
import 'package:accountant_touch/screens/suppliers/suppliers_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../screens/auth/splash_screen.dart'; 
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/sales/cash_sales_history_screen.dart';
import '../services/session_service.dart';
import '../services/subscription_service.dart'; // 🆕 للحصول على معلومات الاشتراك
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';

/// ============================================================================
/// القائمة الجانبية المخصصة مع نظام الصلاحيات
/// ============================================================================
/// 
/// ← Hint: التحديثات الجديدة:
/// - 🆕 عرض معلومات الاشتراك (نوع الخطة، تاريخ الانتهاء، الأيام المتبقية)
/// - 🆕 مؤشر بصري ملون حسب حالة الاشتراك
/// - 🆕 تصميم جميل ومتناسق مع الثيم
/// 
/// ============================================================================
class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Drawer(
      child: Column(
        children: [
          // ============= Header =============
          _buildDrawerHeader(context, isDark),
          
          // ============= 🆕 معلومات الاشتراك =============
          _buildSubscriptionCard(context, isDark, l10n),
          
          // ============= القائمة =============
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // ============= قسم المبيعات =============
                _buildSection(context, l10n.sales, isDark), 
                
                _buildMenuItem(
                  context,
                  icon: Icons.point_of_sale,
                  title: l10n.directSales, 
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DirectSaleScreen(),
                      ),
                    );
                  },
                ),

                _buildMenuItem(
                  context,
                  icon: Icons.receipt_long,
                  title: l10n.invoices,
                  onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CashSalesHistoryScreen(),
                        ),
                      );
                    },
                  ),
                
                const Divider(),

                // ============= الإحصائيات =============
                _buildMenuItem(
                  context,
                  icon: Icons.dashboard,
                  title: l10n.statisticsinformation,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DashboardScreen(),
                      ),
                    );
                  },
                ),
                
                const Divider(),

                // ============= قسم العملاء والموردين =============
                _buildSection(context, l10n.customersAndSuppliers, isDark),

                _buildMenuItem(
                  context,
                  icon: Icons.people,
                  title: l10n.customers,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CustomersListScreen(),
                      ),
                    );
                  },
                ),

                _buildMenuItem(
                  context,
                  icon: Icons.local_shipping,
                  title: l10n.suppliers,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SuppliersListScreen(),
                      ),
                    );
                  },
                ),

                const Divider(),

                // ============= قسم المخزون =============
                _buildSection(context, l10n.inventory, isDark),

                _buildMenuItem(
                  context,
                  icon: Icons.inventory_2,
                  title: l10n.products,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProductsListScreen(),
                      ),
                    );
                  },
                ),

                const Divider(),

                // ============= قسم الموظفين =============
                _buildSection(context, l10n.employees, isDark),

                _buildMenuItem(
                  context,
                  icon: Icons.badge,
                  title: l10n.employeeManagement,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EmployeesListScreen(),
                      ),
                    );
                  },
                ),

                const Divider(),

                // ============= قسم التقارير =============
                _buildSection(context, l10n.reports, isDark),

                _buildMenuItem(
                  context,
                  icon: Icons.assessment,
                  title: l10n.reportsCenter,
                  onTap: () {
                    Navigator.pop(context);

                    try {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReportsHubScreen(),
                        ),
                      );
                    } catch (e) {
                      debugPrint('❌ خطأ في فتح التقارير: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.errorOpeningReports),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                ),

                const Divider(),

                // ============= قسم النظام =============
                _buildSection(context, l10n.system, isDark),

                _buildMenuItem(
                  context,
                  icon: Icons.settings,
                  title: l10n.settings,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),

                  _buildMenuItem(
                  context,
                  icon: Icons.info_outline,
                  title: l10n.aboutTheApp,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutScreen(),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: AppConstants.spacingXl),

      //  //=====================================================
      //  // صفحات التطوير - افعلها للنسخة الخاصة بي
      //  //=====================================================

      //               _buildMenuItem(
      //             context,
      //             icon: Icons.manage_accounts,
      //             title: l10n.activationcodegenerator,
      //             onTap: () {
      //               Navigator.pop(context);
      //               Navigator.push(
      //                 context,
      //                 MaterialPageRoute(
      //                   builder: (context) => const ActivationCodeGeneratorScreen(),
      //                 ),
      //               );
      //             },
      //           ),

      //               _buildMenuItem(
      //             context,
      //             icon: Icons.verified,
      //             title: l10n.subscriptionmanagement,
      //             onTap: () {
      //               Navigator.pop(context);
      //               Navigator.push(
      //                 context,
      //                 MaterialPageRoute(
      //                   builder: (context) => const SubscriptionsAdminScreen(),
      //                 ),
      //               );
      //             },
      //           ),

      //  //=====================================================
      //  // صفحات التطوير - افعلها للنسخة الخاصة بي
      //  //=====================================================

              ],
            ),
          ),
          
          // ============= Footer =============
          _buildDrawerFooter(context, isDark, l10n),
          const SizedBox(height: AppConstants.spacingSm),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ 📋 بناء رأس القائمة الجانبية (محسّن - مدمج)
  // ============================================================
  Widget _buildDrawerHeader(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<Map<String, String?>>(
      future: _getUserInfo(),
      builder: (context, snapshot) {
        final email = snapshot.data?['email'] ?? '';
        final displayName = snapshot.data?['displayName'] ?? l10n.user;
        final photoURL = snapshot.data?['photoURL'];

        final hasUserImage = photoURL != null && photoURL.isNotEmpty;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            AppConstants.spacingMd,
            AppConstants.spacingLg,
            AppConstants.spacingMd,
            AppConstants.spacingMd,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark ? AppColors.gradientDark : AppColors.gradientLight,
            ),
          ),
          child: SafeArea(
            bottom: false, // تقليل المسافة تحت صفة المستخدم
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ صورة المستخدم
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: hasUserImage
                        ? Image.network(
                            photoURL!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                size: 20,
                                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                              );
                            },
                          )
                        : Icon(
                            Icons.person,
                            size: 20,
                            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                          ),
                  ),
                ),

                const SizedBox(height: AppConstants.spacingXs),

                // ✅ اسم المستخدم
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // const SizedBox(height: 2),

                // ✅ البريد الإلكتروني
                Text(
                  email,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: AppConstants.spacingXs),

                // ✅ شارة الصلاحية
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: AppConstants.borderRadiusFull,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.systemAdmin,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ← Hint: دالة مساعدة للحصول على معلومات المستخدم من SessionService
  Future<Map<String, String?>> _getUserInfo() async {
    try {
      final email = await SessionService.instance.getEmail();
      final displayName = await SessionService.instance.getDisplayName();
      final photoURL = await SessionService.instance.getPhotoURL();

      return {
        'email': email ?? '',
        'displayName': displayName ?? '',
        'photoURL': photoURL,
      };
    } catch (e) {
      debugPrint('⚠️ خطأ في الحصول على معلومات المستخدم: $e');
      return {
        'email': '',
        'displayName': '',
        'photoURL': null,
      };
    }
  }

  // ============================================================
  // 🆕 بناء بطاقة معلومات الاشتراك (جديد - تصميم جميل)
  // ============================================================
  /// 
  /// ← Hint: يعرض:
  /// - نوع الخطة (تجريبي / مميز / احترافي)
  /// - حالة الاشتراك (نشط / منتهي / موقوف)
  /// - تاريخ الانتهاء
  /// - الأيام المتبقية مع مؤشر Progress Bar
  /// - مؤشر بصري ملون (أخضر / أصفر / أحمر)
  /// 
  Widget _buildSubscriptionCard(
    BuildContext context,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return FutureBuilder<SubscriptionStatus?>(
      future: _getSubscriptionStatus(),
      builder: (context, snapshot) {
        // ← Hint: أثناء التحميل - عرض شيمر بسيط
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSubscriptionCardShimmer(isDark);
        }

        // ← Hint: في حالة الخطأ أو عدم وجود بيانات - لا نعرض شيء
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final subscription = snapshot.data!;

        // ← Hint: إذا لم يكن هناك اشتراك - لا نعرض شيء
        if (subscription.statusType == 'not_found' || 
            subscription.statusType == 'error') {
          return const SizedBox.shrink();
        }

        // ═══════════════════════════════════════════════════════════
        // حساب معلومات الاشتراك
        // ═══════════════════════════════════════════════════════════

        final planName = _getPlanDisplayName(subscription.plan ?? 'unknown');
        final isActive = subscription.isActive;
        final endDate = subscription.endDate;
        
        // ← Hint: حساب الأيام المتبقية
        int? daysRemaining;
        double? progressPercentage;
        
        if (endDate != null) {
          daysRemaining = endDate.difference(DateTime.now()).inDays;
          
          // ← Hint: حساب النسبة المئوية (افتراضياً trial = 14 يوم)
          const totalDays = 14; // يمكن جلبها من Remote Config
          progressPercentage = (daysRemaining / totalDays).clamp(0.0, 1.0);
        }

        // ← Hint: تحديد اللون حسب الحالة
        Color statusColor;
        IconData statusIcon;
        String statusText;

        if (!isActive || (daysRemaining != null && daysRemaining <= 0)) {
          // منتهي
          statusColor = AppColors.error;
          statusIcon = Icons.cancel;
          statusText = 'منتهي';
        } else if (daysRemaining != null && daysRemaining <= 3) {
          // قرب الانتهاء
          statusColor = AppColors.warning;
          statusIcon = Icons.warning_amber;
          statusText = 'ينتهي قريباً';
        } else {
          // نشط
          statusColor = AppColors.success;
          statusIcon = Icons.check_circle;
          statusText = 'نشط';
        }

        // ═══════════════════════════════════════════════════════════
        // بناء البطاقة
        // ═══════════════════════════════════════════════════════════

        return Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingMd,
            vertical: AppConstants.spacingSm,
          ),
          padding: AppConstants.paddingMd,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.cardDark.withOpacity(0.5)
                : Colors.white,
            borderRadius: AppConstants.borderRadiusMd,
            border: Border.all(
              color: statusColor.withOpacity(0.3),
              width: 2.5, // سمك الاطار
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─────────────────────────────────────────────────────
              // السطر الأول: نوع الخطة + حالة الاشتراك
              // ─────────────────────────────────────────────────────
              Row(
                children: [
                  // أيقونة الخطة
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: AppConstants.borderRadiusSm,
                    ),
                    child: Icon(
                      _getPlanIcon(subscription.plan ?? 'unknown'),
                      size: 18,
                      color: statusColor,
                    ),
                  ),

                  const SizedBox(width: AppConstants.spacingSm),

                  // اسم الخطة
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          planName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // حالة الاشتراك
                        Row(
                          children: [
                            Icon(
                              statusIcon,
                              size: 12,
                              color: statusColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 11,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // الأيام المتبقية (Badge)
                  if (daysRemaining != null && daysRemaining > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: AppConstants.borderRadiusSm,
                      ),
                      child: Text(
                        '$daysRemaining يوم',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                ],
              ),

              // ─────────────────────────────────────────────────────
              // Progress Bar (إذا كان هناك تاريخ انتهاء)
              // ─────────────────────────────────────────────────────
              if (endDate != null && daysRemaining != null && daysRemaining > 0) ...[
                const SizedBox(height: AppConstants.spacingSm),
                
                // Progress Bar
                ClipRRect(
                  borderRadius: AppConstants.borderRadiusSm,
                  child: LinearProgressIndicator(
                    value: progressPercentage,
                    backgroundColor: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    minHeight: 6,
                  ),
                ),
              ],

              // ─────────────────────────────────────────────────────
              // تاريخ الانتهاء
              // ─────────────────────────────────────────────────────
              if (endDate != null) ...[
                const SizedBox(height: AppConstants.spacingSm),
                
                Row(
                  children: [
                    Icon(
                      Icons.event,
                      size: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ينتهي في: ${_formatDate(endDate)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ],

              // ─────────────────────────────────────────────────────
              // رسالة تحذيرية (إذا كان قرب الانتهاء أو منتهي)
              // ─────────────────────────────────────────────────────
              if (daysRemaining != null && daysRemaining <= 3) ...[
                const SizedBox(height: AppConstants.spacingSm),
                
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: AppConstants.borderRadiusSm,
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        daysRemaining <= 0
                            ? Icons.error_outline
                            : Icons.info_outline,
                        size: 14,
                        color: statusColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          daysRemaining <= 0
                              ? 'يرجى تجديد الاشتراك للمتابعة'
                              : 'اشتراكك ينتهي قريباً - فكر في التجديد',
                          style: TextStyle(
                            fontSize: 11,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// ← Hint: عرض شيمر أثناء التحميل
  Widget _buildSubscriptionCardShimmer(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      padding: AppConstants.paddingMd,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardDark.withOpacity(0.3)
            : Colors.grey.shade100,
        borderRadius: AppConstants.borderRadiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: AppConstants.borderRadiusSm,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: AppConstants.borderRadiusSm,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 60,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: AppConstants.borderRadiusSm,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ← Hint: دالة للحصول على معلومات الاشتراك
  Future<SubscriptionStatus?> _getSubscriptionStatus() async {
    try {
      final email = await SessionService.instance.getEmail();
      
      if (email == null || email.isEmpty) {
        return null;
      }

      // ← Hint: التحقق من الاشتراك (مع timeout قصير)
      final subscription = await SubscriptionService.instance
          .checkSubscription(email)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => SubscriptionStatus.error(
              message: 'Timeout',
            ),
          );

      return subscription;
    } catch (e) {
      debugPrint('⚠️ خطأ في جلب معلومات الاشتراك: $e');
      return null;
    }
  }

  /// ← Hint: تحويل اسم الخطة للعرض
  String _getPlanDisplayName(String plan) {
    switch (plan.toLowerCase()) {
      case 'trial':
        return 'اشتراك تجريبي';
      case 'premium':
        return 'اشتراك مميز';
      case 'professional':
        return 'اشتراك احترافي';
      case 'lifetime':
        return 'اشتراك دائم';
      default:
        return 'اشتراك';
    }
  }

  /// ← Hint: أيقونة الخطة
  IconData _getPlanIcon(String plan) {
    switch (plan.toLowerCase()) {
      case 'trial':
        return Icons.access_time;
      case 'premium':
        return Icons.workspace_premium;
      case 'professional':
        return Icons.business_center;
      case 'lifetime':
        return Icons.all_inclusive;
      default:
        return Icons.card_membership;
    }
  }

  /// ← Hint: تنسيق التاريخ
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// بناء عنوان القسم
  Widget _buildSection(BuildContext context, String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingMd,
        AppConstants.spacingLg,
        AppConstants.spacingMd,
        AppConstants.spacingSm,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// بناء عنصر القائمة
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? badge,
  }) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(title),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: AppConstants.borderRadiusFull,
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: AppConstants.borderRadiusMd,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingXs,
      ),
    );
  }

  /// ✅ بناء تذييل القائمة
  Widget _buildDrawerFooter(
    BuildContext context,
    bool isDark,
    AppLocalizations l10n, 
  ) {
    return Container(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingXl),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: Text(
              l10n.logout, 
              style: const TextStyle(color: AppColors.error),
            ),
              contentPadding: const EdgeInsets.symmetric(
    horizontal: AppConstants.spacingMd,
    vertical: 0,  // ← صفر لتقليل المسافة
  ),
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog(context, l10n);
            },
          ),
        ],
      ),
    );
  }

  /// حوار تأكيد تسجيل الخروج
  void _showLogoutDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // 1. تسجيل الخروج من Firebase Auth
                await firebase_auth.FirebaseAuth.instance.signOut();

                // 2. مسح الجلسة المحلية
                await SessionService.instance.clearSession();

                debugPrint('✅ تم تسجيل الخروج بنجاح');

                if (context.mounted) {
                  // 3. العودة لشاشة البداية
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const SplashScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                debugPrint('❌ خطأ في تسجيل الخروج: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }
}