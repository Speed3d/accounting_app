// lib/layouts/main_screen.dart

import 'package:flutter/material.dart';
import '../layouts/main_layout.dart';
import '../screens/HomeScreen/home_screen.dart';
import '../screens/reports/reports_hub_screen.dart'; // ← أضف هذا

// ✅ GlobalKey للوصول للـ State من أي مكان
final GlobalKey<_MainScreenState> mainScreenKey = GlobalKey<_MainScreenState>();

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key); // ← بدون super.key، استخدم key

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages;
  
  final List<String> _titles = [
    'الرئيسية',
    'المبيعات', 
    'التقارير',
    'المزيد',
  ];

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeScreen(),
      const Scaffold(body: Center(child: Text('المبيعات - قريباً'))), // أو SalesHubScreen إذا جاهز
      const ReportsHubScreen(), // ← استخدم الصفحة الحقيقية
      const Scaffold(body: Center(child: Text('المزيد - قريباً'))),
    ];
  }

  // ✅ دالة عامة لتغيير الـ Tab من أي مكان
  void changeTab(int index) {
    if (index >= 0 && index < _pages.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: _titles[_currentIndex],
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