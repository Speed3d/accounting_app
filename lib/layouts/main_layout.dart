import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_drawer.dart';

/// الـ Layout الأساسي للتطبيق
/// يحتوي على: AppBar, Drawer, Body, BottomNavigationBar
class MainLayout extends StatefulWidget {
  final Widget body;
  final String title;
  final int currentIndex;
  final Function(int)? onBottomNavTap;
  final List<Widget>? actions;
  final bool showAppBar;
  final bool showDrawer;
  final bool showBottomNav;
  final FloatingActionButton? floatingActionButton;

  const MainLayout({
    super.key,
    required this.body,
    required this.title,
    this.currentIndex = 0,
    this.onBottomNavTap,
    this.actions,
    this.showAppBar = true,
    this.showDrawer = true,
    this.showBottomNav = true,
    this.floatingActionButton,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();


  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      key: _scaffoldKey,
      
      // ============= App Bar =============
      appBar: widget.showAppBar
          ? CustomAppBar(
              title: widget.title,
              actions: widget.actions,
              onMenuTap: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            )
          : null,
      
      // ============= Drawer =============
      drawer: widget.showDrawer ? const CustomDrawer() : null,
      
      // ============= Body =============
      body: widget.body,
      
      // ============= Bottom Navigation =============
      bottomNavigationBar: widget.showBottomNav
          ? _buildBottomNavigationBar(isDark)
          : null,
      
      // ============= FAB =============
      floatingActionButton: widget.floatingActionButton,
    );
  }

  /// بناء الشريط السفلي
  Widget _buildBottomNavigationBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: widget.currentIndex,
        onTap: widget.onBottomNavTap,
        type: BottomNavigationBarType.fixed,
        items: [
          // الرئيسية
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: 'الرئيسية',
          ),
          
          // المبيعات
          BottomNavigationBarItem(
            icon: const Icon(Icons.point_of_sale_outlined),
            activeIcon: const Icon(Icons.point_of_sale),
            label: 'المبيعات',
          ),
          
          // التقارير
          BottomNavigationBarItem(
            icon: const Icon(Icons.assessment_outlined),
            activeIcon: const Icon(Icons.assessment),
            label: 'التقارير',
          ),
          
          // المزيد
          BottomNavigationBarItem(
            icon: const Icon(Icons.menu),
            activeIcon: const Icon(Icons.menu_open),
            label: 'المزيد',
          ),
        ],
      ),
    );
  }
}