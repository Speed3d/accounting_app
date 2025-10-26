// lib/widgets/custom_drawer.dart

import 'package:accounting_app/screens/customers/customers_list_screen.dart';
import 'package:accounting_app/screens/products/products_list_screen.dart';
import 'package:accounting_app/screens/sales/direct_sale_screen.dart';
import 'package:accounting_app/screens/settings/about_screen.dart';
import 'package:accounting_app/screens/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../screens/sales/cash_sales_history_screen.dart';
import '../services/auth_service.dart'; // ← جديد!
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';

/// القائمة الجانبية المخصصة مع نظام الصلاحيات
class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final authService = AuthService(); // ← جديد!

    return Drawer(
      child: Column(
        children: [
          // ============= Header =============
          _buildDrawerHeader(context, isDark, authService),
          
          // ============= القائمة =============
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // ============= قسم المبيعات =============
                // يظهر دائماً (أو يمكنك إضافة شرط إذا أردت)
                _buildSection(context, 'المبيعات', isDark),
                
                _buildMenuItem(
                  context,
                  icon: Icons.point_of_sale,
                  title: 'مبيعات مباشرة',
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
                
                // ← تحقق من صلاحية عرض المبيعات النقدية
                if (authService.canViewCashSales || authService.isAdmin)
                  _buildMenuItem(
                    context,
                    icon: Icons.receipt_long,
                    title: 'الفواتير',
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
                
                // ============= قسم العملاء والموردين =============
                // يظهر فقط إذا كان لديه أي صلاحية متعلقة بالعملاء أو الموردين
                if (authService.canViewCustomers || 
                    authService.canViewSuppliers || 
                    authService.isAdmin) ...[
                  _buildSection(context, 'العملاء والموردين', isDark),
                  
                  // ← تحقق من صلاحية عرض العملاء
                  if (authService.canViewCustomers || authService.isAdmin)
                    _buildMenuItem(
                      context,
                      icon: Icons.people,
                      title: 'العملاء',
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
                  
                  // ← تحقق من صلاحية عرض الموردين
                  if (authService.canViewSuppliers || authService.isAdmin)
                    _buildMenuItem(
                      context,
                      icon: Icons.local_shipping,
                      title: 'الموردين',
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: إضافة صفحة الموردين
                      },
                    ),
                  
                  const Divider(),
                ],
                
                // ============= قسم المخزون =============
                // ← تحقق من صلاحية عرض المنتجات
                if (authService.canViewProducts || authService.isAdmin) ...[
                  _buildSection(context, 'المخزون', isDark),
                  
                  _buildMenuItem(
                    context,
                    icon: Icons.inventory_2,
                    title: 'المنتجات',
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
                // ← تحقق من صلاحيات الموظفين
                if (authService.canManageEmployees || 
                    authService.canViewEmployeesReport || 
                    authService.isAdmin) ...[
                  _buildSection(context, 'الموظفين', isDark),
                  
                  if (authService.canManageEmployees || authService.isAdmin)
                    _buildMenuItem(
                      context,
                      icon: Icons.badge,
                      title: 'إدارة الموظفين',
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: إضافة صفحة الموظفين
                      },
                    ),
                  
                  if (authService.canViewEmployeesReport || authService.isAdmin)
                    _buildMenuItem(
                      context,
                      icon: Icons.account_balance_wallet,
                      title: 'الرواتب',
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: إضافة صفحة الرواتب
                      },
                    ),
                  
                  const Divider(),
                ],
                
                // ============= قسم التقارير =============
                // ← تحقق من صلاحيات التقارير
                if (authService.canViewReports || 
                    authService.canManageExpenses || 
                    authService.isAdmin) ...[
                  _buildSection(context, 'التقارير', isDark),
                  
                  if (authService.canViewReports || authService.isAdmin)
                    _buildMenuItem(
                      context,
                      icon: Icons.assessment,
                      title: 'مركز التقارير',
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: إضافة صفحة التقارير
                      },
                    ),
                  
                  if (authService.canViewReports || authService.isAdmin)
                    _buildMenuItem(
                      context,
                      icon: Icons.trending_up,
                      title: 'تقرير الأرباح',
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: إضافة صفحة تقرير الأرباح
                      },
                    ),
                  
                  if (authService.canViewReports || authService.isAdmin)
                    _buildMenuItem(
                      context,
                      icon: Icons.attach_money,
                      title: 'التدفق النقدي',
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: إضافة صفحة التدفق النقدي
                      },
                    ),
                  
                  if (authService.canManageExpenses || authService.isAdmin)
                    _buildMenuItem(
                      context,
                      icon: Icons.receipt,
                      title: 'المصاريف',
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: إضافة صفحة المصاريف
                      },
                    ),
                  
                  const Divider(),
                ],
                
                // ============= قسم النظام =============
                // ← تحقق من صلاحيات النظام
                if (authService.canViewSettings || authService.isAdmin) ...[
                  _buildSection(context, 'النظام', isDark),
                  
                  if (authService.canViewSettings || authService.isAdmin)
                    _buildMenuItem(
                      context,
                      icon: Icons.settings,
                      title: 'الإعدادات',
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
                  
                  if (authService.isAdmin)
                    _buildMenuItem(
                      context,
                      icon: Icons.backup,
                      title: 'النسخ الاحتياطي',
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: إضافة صفحة النسخ الاحتياطي
                      },
                    ),
                ],
              ],
            ),
          ),
          
          // ============= Footer =============
          _buildDrawerFooter(context, isDark),
        ],
      ),
    );
  }

  /// بناء رأس القائمة
  Widget _buildDrawerHeader(BuildContext context, bool isDark, AuthService authService) {
    final currentUser = authService.currentUser;
    
    return Container(
      height: AppConstants.drawerHeaderHeight,
      width: double.infinity,
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
        child: Padding(
          padding: AppConstants.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // شعار الشركة
              Container(
                width: AppConstants.logoSizeMd,
                height: AppConstants.logoSizeMd,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppConstants.borderRadiusMd,
                ),
                child: Icon(
                  Icons.store,
                  color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                  size: 32,
                ),
              ),
              
              const SizedBox(height: AppConstants.spacingMd),
              
              // اسم المستخدم
              Text(
                currentUser?.fullName ?? 'مستخدم',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: AppConstants.spacingXs),
              
              // نوع المستخدم
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: AppConstants.borderRadiusSm,
                ),
                child: Text(
                  currentUser?.isAdmin == true ? 'مدير النظام' : 'مستخدم',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
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
          fontSize: 12,
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

  /// بناء تذييل القائمة
  Widget _buildDrawerFooter(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('حول التطبيق'),
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
            title: const Text(
              'تسجيل الخروج',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  /// حوار تأكيد تسجيل الخروج
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              // تسجيل الخروج
              AuthService().logout();
              
              // العودة إلى شاشة تسجيل الدخول
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }
}