import 'package:flutter/material.dart';
import '../layouts/main_layout.dart';
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';

/// صفحة اختبار الـ Layout
class TestLayoutScreen extends StatefulWidget {
  const TestLayoutScreen({super.key});

  @override
  State<TestLayoutScreen> createState() => _TestLayoutScreenState();
}

class _TestLayoutScreenState extends State<TestLayoutScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: _getTitle(),
      currentIndex: _currentIndex,
      onBottomNavTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      body: _getBody(),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('بيع جديد'),
            )
          : null,
    );
  }

  /// الحصول على العنوان حسب الصفحة
  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'الرئيسية';
      case 1:
        return 'المبيعات';
      case 2:
        return 'التقارير';
      case 3:
        return 'المزيد';
      default:
        return 'نظام المحاسبة';
    }
  }

  /// الحصول على المحتوى حسب الصفحة
  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return _buildSalesPage();
      case 2:
        return _buildReportsPage();
      case 3:
        return _buildMorePage();
      default:
        return _buildHomePage();
    }
  }

  /// صفحة الرئيسية
  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: AppConstants.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ملخص سريع
          Text(
            'ملخص اليوم',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppConstants.spacingMd),
          
          // Cards الملخص
          Row(
            children: [
              Expanded(child: _buildSummaryCard('المبيعات', '1,250 د.ع', Icons.trending_up, AppColors.success)),
              const SizedBox(width: AppConstants.spacingMd),
              Expanded(child: _buildSummaryCard('المشتريات', '850 د.ع', Icons.shopping_cart, AppColors.error)),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Row(
            children: [
              Expanded(child: _buildSummaryCard('الأرباح', '400 د.ع', Icons.attach_money, AppColors.info)),
              const SizedBox(width: AppConstants.spacingMd),
              Expanded(child: _buildSummaryCard('العملاء', '45', Icons.people, AppColors.warning)),
            ],
          ),
          
          const SizedBox(height: AppConstants.spacingLg),
          
          // آخر العمليات
          Text(
            'آخر العمليات',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppConstants.spacingMd),
          
          _buildTransactionCard('بيع #1234', '150,000 د.ع', 'منذ ساعة'),
          _buildTransactionCard('بيع #1233', '75,500 د.ع', 'منذ ساعتين'),
          _buildTransactionCard('بيع #1232', '200,000 د.ع', 'منذ 3 ساعات'),
        ],
      ),
    );
  }

  /// صفحة المبيعات
  Widget _buildSalesPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.point_of_sale, size: 80, color: AppColors.primaryLight),
          const SizedBox(height: AppConstants.spacingLg),
          Text(
            'صفحة المبيعات',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            'قم بإنشاء فاتورة بيع جديدة',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  /// صفحة التقارير
  Widget _buildReportsPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assessment, size: 80, color: AppColors.info),
          const SizedBox(height: AppConstants.spacingLg),
          Text(
            'صفحة التقارير',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            'عرض التقارير والإحصائيات',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  /// صفحة المزيد
  Widget _buildMorePage() {
    return ListView(
      padding: AppConstants.screenPadding,
      children: [
        Text(
          'إعدادات سريعة',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppConstants.spacingMd),
        
        _buildSettingsCard(Icons.store, 'معلومات الشركة', () {}),
        _buildSettingsCard(Icons.person, 'المستخدمين', () {}),
        _buildSettingsCard(Icons.backup, 'النسخ الاحتياطي', () {}),
        _buildSettingsCard(Icons.settings, 'الإعدادات', () {}),
      ],
    );
  }

  /// Card الملخص
  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: AppConstants.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: AppConstants.borderRadiusSm,
                  ),
                  child: Icon(Icons.arrow_upward, color: color, size: 16),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card العملية
  Widget _buildTransactionCard(String title, String amount, String time) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight.withOpacity(0.1),
          child: const Icon(Icons.receipt, color: AppColors.primaryLight),
        ),
        title: Text(title),
        subtitle: Text(time),
        trailing: Text(
          amount,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.success,
          ),
        ),
        onTap: () {},
      ),
    );
  }

  /// Card الإعدادات
  Widget _buildSettingsCard(IconData icon, String title, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}