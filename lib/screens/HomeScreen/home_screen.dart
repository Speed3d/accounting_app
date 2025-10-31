// lib/screens/HomeScreen/home_screen.dart

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../customers/customers_list_screen.dart';
import '../employees/employees_list_screen.dart';
import '../products/products_list_screen.dart';
import '../reports/reports_hub_screen.dart';
import '../sales/direct_sale_screen.dart';
import '../suppliers/suppliers_list_screen.dart';
import '../users/users_list_screen.dart';
import '../settings/settings_screen.dart';

/// الصفحة الرئيسية (Home Screen) - بدون Layout
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // ارجع المحتوى مباشرة بدون MainLayout ❗
    return _buildBody(l10n);
  }

  Widget _buildBody(AppLocalizations l10n) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: AppConstants.screenPadding,
            // لعرض اسم المستخدم في صفحة الهوم في الاعلى 
            // child: _buildWelcomeSection(l10n),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: AppConstants.spacingMd,
            vertical: AppConstants.spacingSm,
          ),
          sliver: _buildMenuGrid(l10n),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: AppConstants.spacingXl),
        ),
      ],
    );
  }

  Widget _buildMenuGrid(AppLocalizations l10n) {
    final menuItems = _getMenuItems(l10n);

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.isMobile ? 2 : 3,
        mainAxisSpacing: AppConstants.spacingMd,
        crossAxisSpacing: AppConstants.spacingMd,
        childAspectRatio: 1.1,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = menuItems[index];
          return _buildMenuItem(
            context: context,
            title: item['title'],
            icon: item['icon'],
            color: item['color'],
            onTap: () {
              final page = item['page'];
              _navigateToPage(page);
            },
          );
        },
        childCount: menuItems.length,
      ),
    );
  }

  List<Map<String, dynamic>> _getMenuItems(AppLocalizations l10n) {
    final items = <Map<String, dynamic>>[];

    if (_authService.isAdmin) {
      items.add({
        'title': l10n.users,
        'icon': Icons.people_alt,
        'color': AppColors.info,
        'page': const UsersListScreen(), // ✅ أضف const
      });
    }

    if (_authService.canViewSuppliers) {
      items.add({
        'title': l10n.suppliers,
        'icon': Icons.local_shipping,
        'color': AppColors.warning,
        'page': const SuppliersListScreen(), // ✅ أضف const
      });
    }

    if (_authService.canViewProducts) {
      items.add({
        'title': l10n.products,
        'icon': Icons.inventory_2,
        'color': AppColors.primaryLight,
        'page': const ProductsListScreen(), // ✅ أضف const
      });
    }

    if (_authService.canManageEmployees) {
      items.add({
        'title': l10n.employees,
        'icon': Icons.badge,
        'color': AppColors.secondaryLight,
        'page': const EmployeesListScreen(), // ✅ أضف const
      });
    }

    if (_authService.canViewCustomers) {
      items.add({
        'title': l10n.customers,
        'icon': Icons.groups,
        'color': AppColors.success,
        'page': const CustomersListScreen(),
      });
    }

    if (_authService.canViewCustomers) {
      items.add({
        'title': l10n.directselling,
        'icon': Icons.point_of_sale,
        'color': AppColors.profit,
        'page': const DirectSaleScreen(), // ✅ أضف const
      });
    }

    // ✅✅✅ التعديل المهم - إضافة زر التقارير بشكل صحيح ✅✅✅
    if (_authService.canViewReports || _authService.isAdmin) {
      items.add({
        'title': l10n.reports,
        'icon': Icons.assessment,
        'color': AppColors.income,
        'page': const ReportsHubScreen(), // ✅ أضف const هنا
      });
    }

    if (_authService.canViewSettings) {
      items.add({
        'title': l10n.settings,
        'icon': Icons.settings,
        'color': Colors.grey,
        'page': const SettingsScreen(), // ✅ أضف const
      });
    }

    return items;
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: AppConstants.borderRadiusMd,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: AppConstants.borderRadiusMd,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingSm,
              ),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPage(dynamic page) {
    if (page == null) {
      // ✅ معالجة أفضل للخطأ
      debugPrint('❌ Error: Page is null');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('هذه الميزة قيد التطوير'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppConstants.borderRadiusMd,
          ),
        ),
      );
      return;
    }

    // ✅ إضافة معالجة أفضل للأخطاء
    try {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => page as Widget),
      );
    } catch (e) {
      debugPrint('❌ Navigation error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في فتح الصفحة: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}