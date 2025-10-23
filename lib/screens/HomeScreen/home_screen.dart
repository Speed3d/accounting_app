// lib/screens/HomeScreen/home_screen.dart

import 'package:flutter/material.dart';

// ============= استيراد الملفات =============
import '../../services/auth_service.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../layouts/main_layout.dart';
import '../../widgets/custom_card.dart';

// استيراد الصفحات
import '../customers/customers_list_screen.dart';
import '../employees/employees_list_screen.dart';
import '../products/products_list_screen.dart';
import '../reports/reports_hub_screen.dart';
import '../sales/direct_sale_screen.dart';
import '../suppliers/suppliers_list_screen.dart';
import '../users/users_list_screen.dart';
import '../settings/settings_screen.dart';

/// ===========================================================================
/// الصفحة الرئيسية (Home Screen)
/// ===========================================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  
  // ============= الخدمات =============
  final AuthService _authService = AuthService();
  
  // ============= متغيرات الحالة =============
  int _currentBottomNavIndex = 0;

  // ===========================================================================
  // بناء واجهة المستخدم
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MainLayout(
      title: l10n.homePage,
      currentIndex: _currentBottomNavIndex,
      onBottomNavTap: (index) {
        setState(() {
          _currentBottomNavIndex = index;
        });
        _handleBottomNavTap(index);
      },
      body: _buildBody(l10n),
    );
  }

  // ===========================================================================
  // بناء محتوى الصفحة
  // ===========================================================================
  Widget _buildBody(AppLocalizations l10n) {
    return CustomScrollView(
      slivers: [
        // ============= رسالة ترحيبية =============
        SliverToBoxAdapter(
          child: Padding(
            padding: AppConstants.screenPadding,
            child: _buildWelcomeSection(l10n),
          ),
        ),

        // ============= الشبكة الرئيسية للأقسام =============
        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: AppConstants.spacingMd,
            vertical: AppConstants.spacingSm,
          ),
          sliver: _buildMenuGrid(l10n),
        ),

        // ============= مسافة إضافية في الأسفل =============
        const SliverToBoxAdapter(
          child: SizedBox(height: AppConstants.spacingXl),
        ),
      ],
    );
  }

  // ===========================================================================
  // بناء قسم الترحيب
  // ===========================================================================
  Widget _buildWelcomeSection(AppLocalizations l10n) {
    final userName = _authService.currentUser?.fullName ?? 'المستخدم';
    final isAdmin = _authService.isAdmin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- تحية المستخدم ---
        Text(
          'مرحباً، $userName 👋',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: AppConstants.spacingXs),
        
        // --- نص توضيحي ---
        Row(
          children: [
            Icon(
              isAdmin ? Icons.verified_user : Icons.person,
              size: 16,
              color: isAdmin ? AppColors.success : AppColors.info,
            ),
            const SizedBox(width: AppConstants.spacingXs),
            Text(
              isAdmin ? 'مدير النظام' : 'مستخدم',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isAdmin ? AppColors.success : AppColors.info,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppConstants.spacingMd),
        
        const Divider(),
      ],
    );
  }

  // ===========================================================================
  // بناء شبكة القوائم
  // ===========================================================================
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

  // ===========================================================================
  // الحصول على عناصر القائمة حسب الصلاحيات
  // ===========================================================================
  List<Map<String, dynamic>> _getMenuItems(AppLocalizations l10n) {
    final items = <Map<String, dynamic>>[];

    // --- المستخدمين (المدير فقط) ---
    if (_authService.isAdmin) {
      items.add({
        'title': l10n.users,
        'icon': Icons.people_alt,
        'color': AppColors.info,
        // 'page': UsersListScreen(),
      });
    }

     if (_authService.isAdmin) {
      items.add({
        'title': l10n.homePage,
        'icon': Icons.home,
        'color': AppColors.info,
        'page': HomeScreen(),
      });
    }

    // --- الموردين ---
    if (_authService.canViewSuppliers) {
      items.add({
        'title': l10n.suppliers,
        'icon': Icons.local_shipping,
        'color': AppColors.warning,
        // 'page': SuppliersListScreen(),
      });
    }

    // --- المنتجات ---
    if (_authService.canViewProducts) {
      items.add({
        'title': l10n.products,
        'icon': Icons.inventory_2,
        'color': AppColors.primaryLight,
        // 'page': ProductsListScreen(),
      });
    }

    // --- الموظفين ---
    if (_authService.canManageEmployees) {
      items.add({
        'title': l10n.employees,
        'icon': Icons.badge,
        'color': AppColors.secondaryLight,
        // 'page': EmployeesListScreen(),
      });
    }

    // --- العملاء ---
    if (_authService.canViewCustomers) {
      items.add({
        'title': l10n.customers,
        'icon': Icons.groups,
        'color': AppColors.success,
        'page': CustomersListScreen(),
      });
    }

    // --- بيع مباشر ---
    if (_authService.canViewCustomers) {
      items.add({
        'title': 'بيع مباشر',
        'icon': Icons.point_of_sale,
        'color': AppColors.profit,
        // 'page': DirectSaleScreen(),
      });
    }

    // --- التقارير ---
    if (_authService.canViewReports) {
      items.add({
        'title': l10n.reports,
        'icon': Icons.assessment,
        'color': AppColors.income,
        // 'page': ReportsHubScreen(),
      });
    }

    // --- الإعدادات ---
    if (_authService.canViewSettings) {
      items.add({
        'title': l10n.settings,
        'icon': Icons.settings,
        'color': Colors.grey,
        // 'page': SettingsScreen(),
      });
    }

    return items;
  }

  // ===========================================================================
  // بناء عنصر القائمة
  // ===========================================================================
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
          color: isDark 
            ? AppColors.cardDark 
            : AppColors.cardLight,
          borderRadius: AppConstants.borderRadiusMd,
          border: Border.all(
            color: isDark 
              ? AppColors.borderDark 
              : AppColors.borderLight,
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
            // --- الأيقونة في دائرة ملونة ---
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            
            const SizedBox(height: AppConstants.spacingMd),
            
            // --- عنوان القسم ---
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

  // ===========================================================================
  // التنقل إلى الصفحة
  // ===========================================================================
  void _navigateToPage(dynamic page) {
    if (page == null) {
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

    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => page as Widget),
    );
  }

  // ===========================================================================
  // ✅ معالجة نقرات BottomNavigationBar
  // ===========================================================================
  void _handleBottomNavTap(int index) {
    switch (index) {
      case 0:
        // الرئيسية (نفس الصفحة - لا نفعل شيء)
        break;
      
      case 1:
        // المبيعات
        if (_authService.canViewCustomers) {
          // _navigateToPage(DirectSaleScreen());
        } else {
          _showNoPermissionMessage();
        }
        break;
      
      case 2:
        // التقارير
        if (_authService.canViewReports) {
          // _navigateToPage(ReportsHubScreen());
        } else {
          _showNoPermissionMessage();
        }
        break;
      
      case 3:
        // المزيد (يفتح Drawer)
        Scaffold.of(context).openDrawer();
        break;
    }
  }
  
  // ===========================================================================
  // عرض رسالة عدم وجود صلاحية
  // ===========================================================================
  void _showNoPermissionMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('ليس لديك صلاحية للوصول إلى هذه الميزة'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppConstants.borderRadiusMd,
        ),
      ),
    );
  }
}