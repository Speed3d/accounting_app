// lib/layouts/main_screen.dart

import 'package:accounting_app/screens/auth/lock_screen.dart'; // ← Hint: إضافة
import 'package:accounting_app/screens/dashboard/dashboard_screen.dart';
import 'package:accounting_app/screens/reports/reports_hub_screen.dart';
import 'package:accounting_app/screens/sales/direct_sale_screen.dart';
import 'package:accounting_app/services/app_lock_service.dart'; // ← Hint: إضافة
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../layouts/main_layout.dart';
import '../screens/HomeScreen/home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

// ← Hint: إضافة WidgetsBindingObserver
class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // ← Hint: إضافة Observer
    WidgetsBinding.instance.addObserver(this);

    _pages = [
      const HomeScreen(),
      const DashboardScreen(),
      const DirectSaleScreen(),
      const ReportsHubScreen(useScaffold: false),
    ];

    // ← Hint: التحقق من القفل عند البداية
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLockStatus();
    });
  }

  @override
  void dispose() {
    // ← Hint: إزالة Observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ← Hint: دالة جديدة - مراقبة حالة التطبيق
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      // ← Hint: الخروج من التطبيق
      AppLockService.instance.saveLastActiveTime();
      debugPrint('🔒 تم حفظ وقت الخروج');
    } else if (state == AppLifecycleState.resumed) {
      // ← Hint: العودة للتطبيق
      debugPrint('🔓 العودة للتطبيق - التحقق من القفل');
      _checkLockStatus();
    }
  }

  // ← Hint: دالة جديدة - التحقق من حالة القفل
  Future<void> _checkLockStatus() async {
    final shouldLock = await AppLockService.instance.shouldLockApp();

    if (shouldLock && mounted) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => const LockScreen(canGoBack: false),
          fullscreenDialog: true,
        ),
      );

      // ← Hint: إذا لم ينجح فتح القفل، نخرج من التطبيق
      if (result != true && mounted) {
        debugPrint('⚠️ لم يتم فتح القفل - الخروج');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final titles = [
      l10n.homePage,
      l10n.statistics,
      l10n.sales,
      l10n.reports,
    ];

    return MainLayout(
      title: titles[_currentIndex],
      body: _pages[_currentIndex],
      currentIndex: _currentIndex,
      showAppBar: true,
      showDrawer: true,
      showBottomNav: true,
      onBottomNavTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
    );
  }
}