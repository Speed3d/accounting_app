// lib/screens/reports/employees_report_screen.dart

import 'package:flutter/material.dart';
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../utils/helpers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_state.dart';
import '../employees/employee_details_screen.dart';

/// 📊 شاشة تقرير الموظفين
/// ---------------------------
/// صفحة فرعية تعرض:
/// 1. ملخص إحصائيات الموظفين (رواتب، سلف، عدد الموظفين)
/// 2. قائمة تفصيلية بجميع الموظفين النشطين
class EmployeesReportScreen extends StatefulWidget {
  const EmployeesReportScreen({super.key});

  @override
  State<EmployeesReportScreen> createState() => _EmployeesReportScreenState();
}

class _EmployeesReportScreenState extends State<EmployeesReportScreen> {
  // ============= المتغيرات =============
  final dbHelper = DatabaseHelper.instance;
  
  // Future للبيانات الإحصائية
  late Future<double> _totalSalariesFuture;
  late Future<double> _totalAdvancesFuture;
  late Future<int> _employeesCountFuture;
  late Future<List<Employee>> _employeesListFuture;

  // ============= التهيئة =============
  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  /// تحميل بيانات التقرير من قاعدة البيانات
  void _loadReportData() {
    setState(() {
      _totalSalariesFuture = dbHelper.getTotalNetSalariesPaid();
      _totalAdvancesFuture = dbHelper.getTotalActiveAdvancesBalance();
      _employeesCountFuture = dbHelper.getActiveEmployeesCount();
      _employeesListFuture = dbHelper.getAllActiveEmployees();
    });
  }

  // ============= البناء الرئيسي =============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- AppBar بسيط ---
      appBar: AppBar(
        title: const Text('تقرير الموظفين'),
        elevation: 0,
      ),
      
      // --- الجسم مع إمكانية السحب للتحديث ---
      body: RefreshIndicator(
        onRefresh: () async => _loadReportData(),
        child: ListView(
          padding: AppConstants.screenPadding,
          children: [
            // 📊 قسم الإحصائيات الملخصة
            _buildSummarySection(),
            
            const SizedBox(height: AppConstants.spacingXl),
            
            // 📋 عنوان قائمة الموظفين
            Text(
              'كشف الموظفين',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            
            const SizedBox(height: AppConstants.spacingMd),
            
            // 👥 قائمة الموظفين التفصيلية
            _buildDetailedEmployeesList(),
          ],
        ),
      ),
    );
  }

  // ============= قسم الإحصائيات الملخصة =============
  /// يعرض 3 بطاقات إحصائية:
  /// 1. إجمالي الرواتب المدفوعة
  /// 2. إجمالي السلف المستحقة
  /// 3. عدد الموظفين النشطين
  Widget _buildSummarySection() {
    return Column(
      children: [
        // --- الصف الأول: الرواتب والسلف ---
        Row(
          children: [
            // بطاقة الرواتب
            Expanded(
              child: FutureBuilder<double>(
                future: _totalSalariesFuture,
                builder: (context, snapshot) {
                  // عرض حالة التحميل
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildSummaryCardSkeleton();
                  }
                  
                  // عرض البيانات
                  return StatCard(
                    label: 'إجمالي الرواتب',
                    value: formatCurrency(snapshot.data ?? 0),
                    icon: Icons.payments,
                    color: AppColors.success,
                    subtitle: 'المدفوعة',
                  );
                },
              ),
            ),
            
            const SizedBox(width: AppConstants.spacingSm),
            
            // بطاقة السلف
            Expanded(
              child: FutureBuilder<double>(
                future: _totalAdvancesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildSummaryCardSkeleton();
                  }
                  
                  return StatCard(
                    label: 'رصيد السلف',
                    value: formatCurrency(snapshot.data ?? 0),
                    icon: Icons.account_balance_wallet_outlined, // ← أيقونة أنحف!
                    color: AppColors.warning,
                    subtitle: 'المستحقة',
                  );
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppConstants.spacingMd),
        
        // --- الصف الثاني: عدد الموظفين ---
        FutureBuilder<int>(
          future: _employeesCountFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildSummaryCardSkeleton();
            }
            
            return StatCard(
              label: 'الموظفين النشطين',
              value: snapshot.data?.toString() ?? '0',
              icon: Icons.people,
              color: AppColors.info,
              subtitle: 'موظف',
            );
          },
        ),
      ],
    );
  }

  /// بطاقة هيكلية تظهر أثناء التحميل
  Widget _buildSummaryCardSkeleton() {
    return CustomCard(
      child: Column(
        children: [
          const ShimmerLoading(width: 40, height: 40),
          const SizedBox(height: AppConstants.spacingSm),
          ShimmerLoading(
            width: double.infinity,
            height: 16,
          ),
          const SizedBox(height: AppConstants.spacingXs),
          ShimmerLoading(
            width: double.infinity,
            height: 24,
          ),
        ],
      ),
    );
  }

  // ============= قائمة الموظفين التفصيلية =============
  /// تعرض جدول بأسماء الموظفين مع رواتبهم وسلفهم
  /// مع إمكانية النقر للانتقال لصفحة التفاصيل
  Widget _buildDetailedEmployeesList() {
    return FutureBuilder<List<Employee>>(
      future: _employeesListFuture,
      builder: (context, snapshot) {
        // --- حالة التحميل ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingState(message: 'جاري تحميل البيانات...');
        }
        
        // --- حالة الخطأ ---
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'حدث خطأ: ${snapshot.error}',
              style: TextStyle(color: AppColors.error),
            ),
          );
        }
        
        // --- حالة عدم وجود موظفين ---
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const EmptyState(
            icon: Icons.people_outline,
            title: 'لا يوجد موظفين',
            message: 'لم يتم تسجيل أي موظف نشط حتى الآن',
          );
        }
        
        // --- عرض قائمة الموظفين ---
        final employees = snapshot.data!;
        
        return CustomCard(
          padding: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true, // لعدم أخذ مساحة زائدة
            physics: const NeverScrollableScrollPhysics(), // لتعطيل التمرير الداخلي
            itemCount: employees.length,
            
            // --- الفاصل بين العناصر ---
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: AppConstants.spacingMd,
              endIndent: AppConstants.spacingMd,
            ),
            
            // --- بناء كل عنصر موظف ---
            itemBuilder: (context, index) {
              final employee = employees[index];
              
              return ListTile(
                contentPadding: AppConstants.listTilePadding,
                
                // الأيقونة الشخصية
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryLight.withOpacity(0.1),
                  child: Text(
                    employee.fullName[0].toUpperCase(),
                    style: TextStyle(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // اسم الموظف
                title: Text(
                  employee.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                // الراتب ورصيد السلف
                subtitle: Text(
                  'الراتب: ${formatCurrency(employee.baseSalary)} | '
                  'السلف: ${formatCurrency(employee.balance)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                
                // سهم للانتقال
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                ),
                
                // عند النقر: الانتقال لصفحة تفاصيل الموظف
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EmployeeDetailsScreen(
                        employee: employee,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}