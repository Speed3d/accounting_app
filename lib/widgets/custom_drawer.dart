// lib/widgets/custom_drawer.dart
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
import '../screens/auth/splash_screen.dart'; // ✅ Hint: استيراد SplashScreen
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/sales/cash_sales_history_screen.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';
/// القائمة الجانبية المخصصة مع نظام الصلاحيات
class CustomDrawer extends StatelessWidget {
const CustomDrawer({super.key});
@override
Widget build(BuildContext context) {
// ✅ Hint: جلب الترجمات من AppLocalizations
final l10n = AppLocalizations.of(context)!;
final themeProvider = context.watch<ThemeProvider>();
final isDark = themeProvider.isDarkMode;
final authService = AuthService();
return Drawer(
  child: Column(
    children: [
      // ============= Header =============
      _buildDrawerHeader(context, isDark, authService, l10n),
      
      // ============= القائمة =============
      Expanded(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ============= قسم المبيعات =============
            _buildSection(context, l10n.sales, isDark), // ✅ Hint: استخدام الترجمة
            
            _buildMenuItem(
              context,
              icon: Icons.point_of_sale,
              title: l10n.directSales, // ✅ Hint: استخدام الترجمة
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
                title: l10n.invoices, // ✅ Hint: استخدام الترجمة
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

             /////////////////////////////////////
            /// الاحصاءيات

            _buildMenuItem(
  context,
  icon: Icons.dashboard,
  title: l10n.dashboard,
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
            if (authService.canViewCustomers || 
                authService.canViewSuppliers || 
                authService.isAdmin) ...[
              _buildSection(context, l10n.customersAndSuppliers, isDark), // ✅ Hint: استخدام الترجمة
              
              if (authService.canViewCustomers || authService.isAdmin)
                _buildMenuItem(
                  context,
                  icon: Icons.people,
                  title: l10n.customers, // ✅ Hint: استخدام الترجمة
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
                  title: l10n.suppliers, // ✅ Hint: استخدام الترجمة
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
              _buildSection(context, l10n.inventory, isDark), // ✅ Hint: استخدام الترجمة
              
              _buildMenuItem(
                context,
                icon: Icons.inventory_2,
                title: l10n.products, // ✅ Hint: استخدام الترجمة
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
              _buildSection(context, l10n.employees, isDark), // ✅ Hint: استخدام الترجمة
              
              if (authService.canManageEmployees || authService.isAdmin)
                _buildMenuItem(
                  context,
                  icon: Icons.badge,
                  title: l10n.employeeManagement, // ✅ Hint: استخدام الترجمة
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
              _buildSection(context, l10n.reports, isDark), // ✅ Hint: استخدام الترجمة
              
              if (authService.canViewReports || authService.isAdmin)
                _buildMenuItem(
                  context,
                  icon: Icons.assessment,
                  title: l10n.reportsCenter, // ✅ Hint: استخدام الترجمة
                  onTap: () {
                    Navigator.pop(context);
                    
                    // ✅ Hint: التنقل الصحيح بمعالجة الأخطاء
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
                          content: Text(l10n.errorOpeningReports), // ✅ Hint: استخدام الترجمة
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
              _buildSection(context, l10n.system, isDark), // ✅ Hint: استخدام الترجمة
              
              if (authService.canViewSettings || authService.isAdmin)
                _buildMenuItem(
                  context,
                  icon: Icons.settings,
                  title: l10n.settings, // ✅ Hint: استخدام الترجمة
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
          ],
        ),
      ),
      
      // ============= Footer =============
      _buildDrawerFooter(context, isDark, l10n),
    ],
  ),
);
}
/// بناء رأس القائمة
Widget _buildDrawerHeader(
BuildContext context,
bool isDark,
AuthService authService,
AppLocalizations l10n, // ✅ Hint: إضافة معامل الترجمة
) {
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
            currentUser?.fullName ?? l10n.user, // ✅ Hint: استخدام الترجمة
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
              currentUser?.isAdmin == true 
                ? l10n.systemAdmin  // ✅ Hint: استخدام الترجمة
                : l10n.user,        // ✅ Hint: استخدام الترجمة
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
Widget _buildDrawerFooter(
BuildContext context,
bool isDark,
AppLocalizations l10n, // ✅ Hint: إضافة معامل الترجمة
) {
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
title: Text(l10n.aboutTheApp), // ✅ Hint: استخدام الترجمة
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
l10n.logout, // ✅ Hint: استخدام الترجمة
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
title: Text(l10n.logout), // ✅ Hint: استخدام الترجمة
content: Text(l10n.logoutConfirmation), // ✅ Hint: استخدام الترجمة
actions: [
TextButton(
onPressed: () => Navigator.pop(context),
child: Text(l10n.cancel), // ✅ Hint: استخدام الترجمة
),
ElevatedButton(
onPressed: () {
// تسجيل الخروج
AuthService().logout();
          // ✅ Hint: التصحيح - استخدام MaterialPageRoute بدلاً من pushNamed
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SplashScreen()),
            (route) => false,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
        ),
        child: Text(l10n.logout), // ✅ Hint: استخدام الترجمة
      ),
    ],
  ),
);
}
}
