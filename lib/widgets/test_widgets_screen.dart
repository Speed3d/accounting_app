import 'package:flutter/material.dart';
import '../layouts/main_layout.dart';
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_card.dart';
import '../widgets/loading_state.dart';
import '../widgets/status_badge.dart';

class TestWidgetsScreen extends StatefulWidget {
  const TestWidgetsScreen({super.key});

  @override
  State<TestWidgetsScreen> createState() => _TestWidgetsScreenState();
}

class _TestWidgetsScreenState extends State<TestWidgetsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'اختبار المكونات',
      currentIndex: 0,
      showBottomNav: false,
      body: ListView(
        padding: AppConstants.screenPadding,
        children: [
          // Buttons
          Text('الأزرار', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppConstants.spacingMd),
          
          CustomButton(
            text: 'زر رئيسي',
            icon: Icons.save,
            onPressed: () {},
          ),
          const SizedBox(height: AppConstants.spacingSm),
          
          CustomButton(
            text: 'زر ثانوي',
            type: ButtonType.secondary,
            icon: Icons.edit,
            onPressed: () {},
          ),
          const SizedBox(height: AppConstants.spacingSm),
          
          CustomButton(
            text: 'زر نصي',
            type: ButtonType.text,
            onPressed: () {},
          ),
          const SizedBox(height: AppConstants.spacingSm),
          
          CustomButton(
            text: 'جاري التحميل...',
            isLoading: true,
            onPressed: () {},
          ),
          
          const Divider(height: AppConstants.spacingXl),
          
          // Text Fields
          Text('حقول الإدخال', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppConstants.spacingMd),
          
          const CustomTextField(
            label: 'الاسم',
            hint: 'أدخل الاسم',
            prefixIcon: Icons.person,
          ),
          const SizedBox(height: AppConstants.spacingMd),
          
          const CustomTextField(
            label: 'البريد الإلكتروني',
            hint: 'example@email.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email,
          ),
          const SizedBox(height: AppConstants.spacingMd),
          
          const CustomTextField(
            label: 'كلمة المرور',
            hint: '••••••••',
            obscureText: true,
            prefixIcon: Icons.lock,
            suffixIcon: Icons.visibility,
          ),
          
          const Divider(height: AppConstants.spacingXl),
          
          // Cards
          Text('البطاقات', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppConstants.spacingMd),
          
          Row(
            children: [
              Expanded(
                child: InfoCard(
                  title: 'المبيعات',
                  value: '1,250',
                  icon: Icons.trending_up,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: AppConstants.spacingMd),
              Expanded(
                child: InfoCard(
                  title: 'العملاء',
                  value: '45',
                  icon: Icons.people,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMd),
          
          StatCard(
            label: 'إجمالي الأرباح',
            value: '450,000 د.ع',
            icon: Icons.attach_money,
            color: AppColors.success,
            subtitle: '+12% من الشهر الماضي',
          ),
          
          const Divider(height: AppConstants.spacingXl),
          
          // Status Badges
          Text('شارات الحالة', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppConstants.spacingMd),
          
          Wrap(
            spacing: AppConstants.spacingSm,
            runSpacing: AppConstants.spacingSm,
            children: const [
              StatusBadge(text: 'نجح', type: StatusType.success),
              StatusBadge(text: 'تحذير', type: StatusType.warning),
              StatusBadge(text: 'خطأ', type: StatusType.error),
              StatusBadge(text: 'معلومة', type: StatusType.info),
              StatusBadge(text: 'محايد', type: StatusType.neutral),
            ],
          ),
          
          const Divider(height: AppConstants.spacingXl),
          
          // Loading States
          Text('حالات التحميل', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppConstants.spacingMd),
          
          CustomButton(
            text: _isLoading ? 'إيقاف' : 'عرض التحميل',
            onPressed: () {
              setState(() {
                _isLoading = !_isLoading;
              });
            },
          ),
          const SizedBox(height: AppConstants.spacingMd),
          
          if (_isLoading)
            const SizedBox(
              height: 200,
              child: LoadingState(message: 'جاري التحميل...'),
            ),
          
          const SizedBox(height: AppConstants.spacingXl),
        ],
      ),
    );
  }
}
// ```

// **احفظ الملف** ✅

// ---

// ## 📋 ملخص ما أنجزناه:
// ```
// lib/widgets/
// ├── custom_app_bar.dart      ✅
// ├── custom_drawer.dart        ✅
// ├── custom_button.dart        ✅ جديد
// ├── custom_text_field.dart    ✅ جديد
// ├── custom_card.dart          ✅ جديد
// ├── loading_state.dart        ✅ جديد
// └── status_badge.dart         ✅ جديد