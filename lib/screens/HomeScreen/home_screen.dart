// lib/screens/HomeScreen/home_screen.dart

import 'package:accountant_touch/screens/admin/activation_code_generator_screen.dart';
import 'package:accountant_touch/screens/admin/subscriptions_admin_screen.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../customers/customers_list_screen.dart';
import '../employees/employees_list_screen.dart';
import '../products/products_list_screen.dart';
import '../reports/reports_hub_screen.dart';
import '../sales/direct_sale_screen.dart';
import '../suppliers/suppliers_list_screen.dart';
import '../settings/settings_screen.dart';

// ← Hint: تم إزالة AuthService - كل مستخدم admin الآن

/// الصفحة الرئيسية (Home Screen) - بدون Layout
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ← Hint: تم إزالة AuthService - لا حاجة لفحص الصلاحيات

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
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: AppConstants.spacingLg,
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

  // ← Hint: تم إزالة فحوصات الصلاحيات - كل مستخدم يمكنه الوصول لكل الصفحات
  List<Map<String, dynamic>> _getMenuItems(AppLocalizations l10n) {
    return [
      // ← Hint: تم حذف صفحة Users - لا حاجة لها في النظام الجديد

      {
        'title': l10n.suppliers,
        'icon': Icons.local_shipping,
        'color': AppColors.warning,
        'page': const SuppliersListScreen(),
      },
      {
        'title': l10n.products,
        'icon': Icons.inventory_2,
        'color': AppColors.primaryLight,
        'page': const ProductsListScreen(),
      },
      {
        'title': l10n.employees,
        'icon': Icons.badge,
        'color': AppColors.secondaryLight,
        'page': const EmployeesListScreen(),
      },
      {
        'title': l10n.customers,
        'icon': Icons.groups,
        'color': AppColors.success,
        'page': const CustomersListScreen(),
      },
      {
        'title': l10n.directselling,
        'icon': Icons.point_of_sale,
        'color': AppColors.profit,
        'page': const DirectSaleScreen(),
      },
      {
        'title': l10n.reports,
        'icon': Icons.assessment,
        'color': AppColors.income,
        'page': const ReportsHubScreen(),
      },
      {
        'title': l10n.settings,
        'icon': Icons.settings,
        'color': Colors.grey,
        'page': const SettingsScreen(),
      },


      //  //=====================================================
      //  // صفحات التطوير - افعلها للنسخة الخاصة بي
      //  //=====================================================

      // { 
      //   'title': l10n.activationcodegenerator,
      //   'icon': Icons.manage_accounts,
      //   'color': const Color.fromARGB(255, 103, 237, 94),
      //   'page': const ActivationCodeGeneratorScreen(),
      // },
      //  { 
      //   'title': l10n.subscriptionmanagement,
      //   'icon': Icons.verified,
      //   'color': const Color.fromARGB(255, 242, 147, 46),
      //   'page': const SubscriptionsAdminScreen(),
      // },

      //  //=====================================================
      //  // صفحات التطوير
      //  //=====================================================

    ];
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
            color: isDark ? AppColors.borderDark : const Color.fromARGB(255, 214, 221, 232),
            width: 3,
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
              width: 85,
              height: 80,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: color),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingMd,
              ),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
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