// lib/widgets/custom_drawer.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth; // 🆕 Firebase Auth
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
import '../screens/test_pdf_screen.dart';
import '../services/session_service.dart'; // 🆕 استبدال AuthService بـ SessionService
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';

/// القائمة الجانبية المخصصة مع نظام الصلاحيات
class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    // ← Hint: النظام الجديد - لا توجد صلاحيات محلية (كل مستخدم = owner/admin)

    return Drawer(
      child: Column(
        children: [
          // ============= Header =============
          _buildDrawerHeader(context, isDark),
          
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

                // ← Hint: إزالة فحص الصلاحيات - كل مستخدم يمكنه الوصول
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

            //     // زر تم عمله لاختبار وانشار ملف PDF
            //     //================================================
            //     _buildMenuItem(
            //     context,
            //     icon: Icons.bug_report,
            //     title: '🧪 اختبار PDF',
            //     onTap: () {
            //      Navigator.pop(context);
            //      Navigator.push(
            //      context,
            //      MaterialPageRoute(
            //      builder: (context) => const TestPdfScreen(),
            //     ),
            //    );
            //  },
            // ),
                // const Divider(),


                // ============= قسم العملاء والموردين =============
                // ← Hint: إزالة فحص الصلاحيات - كل القوائم مفتوحة للجميع
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
                
                // ✅ مسافة إضافية قبل Footer لرفع الأزرار للأعلى
                const SizedBox(height: AppConstants.spacingXl),
              ],
            ),
          ),
          
          // ============= Footer (مرفوع للأعلى) =============
          _buildDrawerFooter(context, isDark, l10n),
          const SizedBox(height: AppConstants.spacingSm),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ 📋 بناء رأس القائمة الجانبية (النظام الجديد - SessionService)
  // ← Hint: النظام الجديد يستخدم FutureBuilder للحصول على البيانات من SessionService
  // ============================================================
  Widget _buildDrawerHeader(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<Map<String, String?>>(
      future: _getUserInfo(),
      builder: (context, snapshot) {
        final email = snapshot.data?['email'] ?? '';
        final displayName = snapshot.data?['displayName'] ?? l10n.user;
        final photoURL = snapshot.data?['photoURL'];

        // ← Hint: لا توجد صور محلية بعد الآن - فقط من Firebase Storage
        final hasUserImage = photoURL != null && photoURL.isNotEmpty;

    return Container(
      width: double.infinity,
      // ✅ تصغير الـ padding لتقليل المساحة
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingMd,
        AppConstants.spacingXl + 2, // تقليل من 20 إلى 10
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ صورة المستخدم الحقيقية (مصغّرة)
            Container(
              width: 60, // تقليل من 70 إلى 60
              height: 60,
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
                    blurRadius: 10,
                    offset: const Offset(0, 4),
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
                              size: 30,
                              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                            );
                          },
                        )
                      : Icon(
                          Icons.person,
                          size: 30,
                          color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                        ),
                ),
              ),

              const SizedBox(height: AppConstants.spacingMd),

              // ✅ اسم المستخدم (حجم أصغر)
              Text(
                displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 2),

              // ✅ البريد الإلكتروني (Email)
              Text(
                email,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: AppConstants.spacingSm),

              // ✅ شارة الصلاحية (Admin دائماً في النظام الجديد)
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
                      size: 12,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.systemAdmin,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
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
          fontSize: 14,
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

  /// ✅ بناء تذييل القائمة (مرفوع للأعلى)
  Widget _buildDrawerFooter(
    BuildContext context,
    bool isDark,
    AppLocalizations l10n, 
  ) {
    return Container(
      // ✅ إضافة padding من الأسفل لرفع الأزرار
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
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.aboutTheApp), 
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
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: Text(
              l10n.logout, 
              style: const TextStyle(color: AppColors.error),
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
  /// ← Hint: النظام الجديد يستخدم Firebase Auth + SessionService
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
                // ← Hint: 1. تسجيل الخروج من Firebase Auth
                await firebase_auth.FirebaseAuth.instance.signOut();

                // ← Hint: 2. مسح الجلسة المحلية
                await SessionService.instance.clearSession();

                debugPrint('✅ تم تسجيل الخروج بنجاح');

                if (context.mounted) {
                  // ← Hint: 3. العودة لشاشة البداية
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