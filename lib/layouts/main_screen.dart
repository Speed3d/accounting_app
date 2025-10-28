// lib/layouts/main_screen.dart

import 'package:accounting_app/screens/reports/reports_hub_screen.dart';
import 'package:flutter/material.dart';
import '../layouts/main_layout.dart';
import '../screens/HomeScreen/home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

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
      const Scaffold(body: Center(child: Text('المبيعات - قريباً'))),
      // ✅ تمرير useScaffold: false لأنها داخل MainLayout
      const ReportsHubScreen(useScaffold: false), 
      const Scaffold(body: Center(child: Text('المزيد - قريباً'))),
    ];
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