// lib/widgets/custom_drawer.dart
import 'dart:io';
import 'package:accounting_app/l10n/app_localizations.dart';
import 'package:accounting_app/screens/customers/customers_list_screen.dart';
import 'package:accounting_app/screens/employees/employees_list_screen.dart';
import 'package:accounting_app/screens/products/products_list_screen.dart';
import 'package:accounting_app/screens/reports/reports_hub_screen.dart';
import 'package:accounting_app/screens/sales/direct_sale_screen.dart';
import 'package:accounting_app/screens/settings/about_screen.dart';
import 'package:accounting_app/screens/settings/settings_screen.dart';
import 'package:accounting_app/screens/suppliers/suppliers_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../screens/auth/splash_screen.dart'; 
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/sales/cash_sales_history_screen.dart';
import '../screens/test_pdf_screen.dart';
import '../services/auth_service.dart';
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
    final authService = AuthService();

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
                
                if (authService.canViewCashSales || authService.isAdmin)
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
                if (authService.canViewCustomers || 
                    authService.canViewSuppliers || 
                    authService.isAdmin) ...[
                  _buildSection(context, l10n.customersAndSuppliers, isDark), 
                  
                  if (authService.canViewCustomers || authService.isAdmin)
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
                  
                  if (authService.canViewSuppliers || authService.isAdmin)
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
                ],
                
                // ============= قسم المخزون =============
                if (authService.canViewProducts || authService.isAdmin) ...[
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
                ],
                
                // ============= قسم الموظفين =============
                if (authService.canManageEmployees || 
                    authService.canViewEmployeesReport || 
                    authService.isAdmin) ...[
                  _buildSection(context, l10n.employees, isDark), 
                  
                  if (authService.canManageEmployees || authService.isAdmin)
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
                ],
                
                // ============= قسم التقارير =============
                if (authService.canViewReports || 
                    authService.canManageExpenses || 
                    authService.isAdmin) ...[
                  _buildSection(context, l10n.reports, isDark), 
                  
                  if (authService.canViewReports || authService.isAdmin)
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
                ],
                
                // ============= قسم النظام =============
                if (authService.canViewSettings || authService.isAdmin) ...[
                  _buildSection(context, l10n.system, isDark), 
                  
                  if (authService.canViewSettings || authService.isAdmin)
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
                ],
                
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
  // ✅ 📋 بناء رأس القائمة الجانبية (مُحسّن ومصغّر)
  // ============================================================
  Widget _buildDrawerHeader(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    final user = AuthService().currentUser;
    
    // ✅ التحقق من وجود صورة المستخدم
    final hasUserImage = user?.imagePath != null && 
                         user!.imagePath!.isNotEmpty && 
                         File(user.imagePath!).existsSync();

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
                    ? Image.file(
                        File(user!.imagePath!),
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

            const SizedBox(height: AppConstants.spacingMd), // تقليل المسافة

            // ✅ اسم المستخدم (حجم أصغر)
            Text(
              user?.fullName ?? l10n.user,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16, // تقليل من 18 إلى 16
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 2), // تقليل المسافة

            // ✅ اسم المستخدم (Username)
            Text(
              user?.userName ?? l10n.undefined,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12, // تقليل من 13 إلى 12
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: AppConstants.spacingSm),

            // ✅ شارة الصلاحية (مصغّرة)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3, // تقليل من 4 إلى 3
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
                  Icon(
                    user?.isAdmin == true ? Icons.admin_panel_settings : Icons.person,
                    color: Colors.white,
                    size: 12, // تقليل من 14 إلى 12
                  ),
                  const SizedBox(width: 6),
                  Text(
                    user?.isAdmin == true ? l10n.systemAdmin : l10n.user,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11, // تقليل من 12 إلى 11
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
            onPressed: () {
              AuthService().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const SplashScreen()),
                (route) => false,
              );
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