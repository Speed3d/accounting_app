import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';

/// القائمة الجانبية المخصصة
class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

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
                // قسم الرئيسية
                _buildSection(context, 'القسم الرئيسي', isDark),
                _buildMenuItem(
                  context,
                  icon: Icons.dashboard,
                  title: 'لوحة التحكم',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: التنقل للصفحة
                  },
                ),
                
                const Divider(),
                
                // قسم المبيعات
                _buildSection(context, 'المبيعات', isDark),
                _buildMenuItem(
                  context,
                  icon: Icons.point_of_sale,
                  title: 'مبيعات مباشرة',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: التنقل للصفحة
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.receipt_long,
                  title: 'الفواتير',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                
                const Divider(),
                
                // قسم العملاء
                _buildSection(context, 'العملاء والموردين', isDark),
                _buildMenuItem(
                  context,
                  icon: Icons.people,
                  title: 'العملاء',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.local_shipping,
                  title: 'الموردين',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                
                const Divider(),
                
                // قسم المنتجات
                _buildSection(context, 'المخزون', isDark),
                _buildMenuItem(
                  context,
                  icon: Icons.inventory_2,
                  title: 'المنتجات',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                
                const Divider(),
                
                // قسم الموظفين
                _buildSection(context, 'الموظفين', isDark),
                _buildMenuItem(
                  context,
                  icon: Icons.badge,
                  title: 'إدارة الموظفين',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.account_balance_wallet,
                  title: 'الرواتب',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                
                const Divider(),
                
                // قسم التقارير
                _buildSection(context, 'التقارير', isDark),
                _buildMenuItem(
                  context,
                  icon: Icons.assessment,
                  title: 'مركز التقارير',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.trending_up,
                  title: 'تقرير الأرباح',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.attach_money,
                  title: 'التدفق النقدي',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                
                const Divider(),
                
                // قسم الإعدادات
                _buildSection(context, 'النظام', isDark),
                _buildMenuItem(
                  context,
                  icon: Icons.settings,
                  title: 'الإعدادات',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.backup,
                  title: 'النسخ الاحتياطي',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
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
  Widget _buildDrawerHeader(BuildContext context, bool isDark) {
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
              
              // اسم الشركة
              Text(
                'نظام المحاسبة', // TODO: جلب من قاعدة البيانات
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: AppConstants.spacingXs),
              
              // وصف الشركة
              Text(
                'إدارة شاملة لأعمالك', // TODO: جلب من قاعدة البيانات
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
              // TODO: فتح صفحة حول التطبيق
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
              // TODO: تسجيل الخروج
            },
          ),
        ],
      ),
    );
  }
}