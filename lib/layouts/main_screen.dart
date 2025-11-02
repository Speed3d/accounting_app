// lib/layouts/main_screen.dart
import 'package:accounting_app/screens/reports/reports_hub_screen.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart'; // ✅ Hint: استيراد ملف الترجمة
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
// ✅ Hint: إزالة _titles من هنا لأننا سنستخدم الترجمة مباشرة في build
@override
void initState() {
super.initState();
_pages = [
const HomeScreen(),
const Scaffold(body: Center(child: Text('المبيعات - قريباً'))), // ✅ Hint: سيتم تدوينها لاحقاً
const ReportsHubScreen(useScaffold: false),
const Scaffold(body: Center(child: Text('المزيد - قريباً'))), // ✅ Hint: سيتم تدوينها لاحقاً
];
}
@override
Widget build(BuildContext context) {
// ✅ Hint: جلب الترجمات من AppLocalizations
final l10n = AppLocalizations.of(context)!;
// ✅ Hint: قائمة العناوين المترجمة
final titles = [
  l10n.homePage,
  l10n.sales,
  l10n.reports,
  l10n.more,
];

return MainLayout(
  title: titles[_currentIndex], // ✅ Hint: استخدام العنوان المترجم
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