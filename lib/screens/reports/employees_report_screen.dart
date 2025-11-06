// lib/screens/reports/employees_report_screen.dart
// النسخة المحدثة مع دعم PDF

import 'package:flutter/material.dart';
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/helpers.dart';
import '../../utils/pdf_helpers.dart';
import '../../services/pdf_service.dart';
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
/// 
/// 🌐 دعم متعدد اللغات:
/// - تستخدم AppLocalizations للحصول على النصوص المترجمة
/// - تدعم العربية والإنجليزية مع تبديل الاتجاه تلقائياً
class EmployeesReportScreen extends StatefulWidget {
  const EmployeesReportScreen({super.key});

  @override
  State<EmployeesReportScreen> createState() => _EmployeesReportScreenState();
}

class _EmployeesReportScreenState extends State<EmployeesReportScreen> {
  // ============================================================================
  // المتغيرات
  // ============================================================================
  final dbHelper = DatabaseHelper.instance;
  
  // Future للبيانات الإحصائية
  late Future<double> _totalSalariesFuture;
  late Future<double> _totalAdvancesFuture;
  late Future<int> _employeesCountFuture;
  late Future<List<Employee>> _employeesListFuture;
  
  bool _isGeneratingPdf = false; // ✅ متغير حالة PDF

  // ============================================================================
  // التهيئة
  // ============================================================================
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

  // ============================================================================
  // البناء الرئيسي
  // ============================================================================
  @override
  Widget build(BuildContext context) {
    // 🌐 الحصول على الترجمات الحالية
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      // ============================================================================
      // AppBar
      // ============================================================================
      appBar: AppBar(
        title: Text(l10n.employees_report_title),
        elevation: 0,
        actions: [
          // زر التحديث
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReportData,
            tooltip: l10n.refresh,
          ),
          // ✅ زر PDF
          IconButton(
            icon: _isGeneratingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf),
            onPressed: _isGeneratingPdf ? null : _generatePdf,
            tooltip: 'تصدير PDF',
          ),
        ],
      ),
      
      // ============================================================================
      // الجسم مع إمكانية السحب للتحديث
      // ============================================================================
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
              l10n.employees_list_title,
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

  // ============================================================================
  // قسم الإحصائيات الملخصة
  // ============================================================================
  /// يعرض 3 بطاقات إحصائية:
  /// 1. إجمالي الرواتب المدفوعة
  /// 2. إجمالي السلف المستحقة
  /// 3. عدد الموظفين النشطين
  Widget _buildSummarySection() {
    // 🌐 الحصول على الترجمات
    final l10n = AppLocalizations.of(context)!;
    
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
                    label: l10n.stat_total_salaries,
                    value: formatCurrency(snapshot.data ?? 0),
                    icon: Icons.payments,
                    color: AppColors.success,
                    subtitle: l10n.stat_salaries_paid,
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
                    label: l10n.stat_advances_balance,
                    value: formatCurrency(snapshot.data ?? 0),
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppColors.warning,
                    subtitle: l10n.stat_advances_due,
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
              label: l10n.stat_active_employees,
              value: snapshot.data?.toString() ?? '0',
              icon: Icons.people,
              color: AppColors.info,
              subtitle: l10n.stat_employee_unit,
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

  // ============================================================================
  // قائمة الموظفين التفصيلية
  // ============================================================================
  /// تعرض جدول بأسماء الموظفين مع رواتبهم وسلفهم
  /// مع إمكانية النقر للانتقال لصفحة التفاصيل
  Widget _buildDetailedEmployeesList() {
    // 🌐 الحصول على الترجمات
    final l10n = AppLocalizations.of(context)!;
    
    return FutureBuilder<List<Employee>>(
      future: _employeesListFuture,
      builder: (context, snapshot) {
        // --- حالة التحميل ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LoadingState(
            message: l10n.loading_data,
          );
        }
        
        // --- حالة الخطأ ---
        if (snapshot.hasError) {
          return Center(
            child: Text(
              '${l10n.error_occurred}: ${snapshot.error}',
              style: TextStyle(color: AppColors.error),
            ),
          );
        }
        
        // --- حالة عدم وجود موظفين ---
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return EmptyState(
            icon: Icons.people_outline,
            title: l10n.no_employees_title,
            message: l10n.no_employees_message,
          );
        }
        
        // --- عرض قائمة الموظفين ---
        final employees = snapshot.data!;
        
        return CustomCard(
          padding: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
                  '${l10n.employee_salary_label}: ${formatCurrency(employee.baseSalary)} | '
                  '${l10n.employee_advances_label}: ${formatCurrency(employee.balance)}',
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

  // ============================================================================
  // 📄 دالة توليد PDF
  // ============================================================================
  Future<void> _generatePdf() async {
    setState(() => _isGeneratingPdf = true);
    
    try {
      // 1️⃣ جلب جميع البيانات
      final totalSalaries = await _totalSalariesFuture;
      final totalAdvances = await _totalAdvancesFuture;
      final employeesCount = await _employeesCountFuture;
      final employees = await _employeesListFuture;
      
      // 2️⃣ تحويل بيانات الموظفين إلى Map
      final employeesData = employees.map((emp) => {
        'fullName': emp.fullName,
        'jobTitle': emp.jobTitle,
        'baseSalary': emp.baseSalary,
        'balance': emp.balance,
      }).toList();
      
      // 3️⃣ إنشاء PDF
      final pdf = await PdfService.instance.buildEmployeesReport(
        totalSalaries: totalSalaries,
        totalAdvances: totalAdvances,
        employeesCount: employeesCount,
        employeesData: employeesData,
      );
      
      // 4️⃣ عرض خيارات PDF
      if (!mounted) return;
      
      PdfHelpers.showPdfOptionsDialog(
        context,
        pdf,
        onSuccess: () {
          // يمكنك إضافة كود هنا عند نجاح العملية
        },
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(error)),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
      
    } catch (e) {
      // في حالة حدوث خطأ
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('خطأ في إنشاء PDF: $e')),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }
}