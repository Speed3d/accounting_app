// lib/screens/reports/employees_report_screen.dart
// النسخة المحدثة مع دعم PDF ونظام الفلترة

import 'package:decimal/decimal.dart';
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
/// 1. ملخص إحصائيات الموظفين (رواتب، سلف، مكافآت، خصومات، عدد الموظفين)
/// 2. قائمة تفصيلية بجميع الموظفين النشطين مع نظام فلترة
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
  late Future<Decimal> _totalSalariesFuture;
  late Future<Decimal> _totalAdvancesFuture;
  late Future<Decimal> _totalBonusesFuture; // ← Hint: إجمالي المكافآت القديمة (من TB_Payroll)
  late Future<Decimal> _totalEmployeeBonusesFuture; // ← Hint: إجمالي المكافآت الجديدة (من TB_Employee_Bonuses)
  late Future<Decimal> _totalDeductionsFuture; // ← Hint: إجمالي الخصومات
  late Future<int> _employeesCountFuture;
  late Future<List<Employee>> _employeesListFuture;
  
  bool _isGeneratingPdf = false;
  String? _selectedFilter; // ← Hint: الفلتر المحدد (null = الكل، 'advances' = سلف، 'bonuses' = مكافآت، 'deductions' = خصومات)
  
  // ← Hint: قائمة الموظفين الكاملة والمفلترة
  List<Employee> _allEmployees = [];
  List<Employee> _filteredEmployees = [];

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
      _totalBonusesFuture = dbHelper.getTotalBonuses(); // ← Hint: المكافآت القديمة (من TB_Payroll)
      _totalEmployeeBonusesFuture = dbHelper.getTotalEmployeeBonuses(); // ← Hint: المكافآت الجديدة (من TB_Employee_Bonuses)
      _totalDeductionsFuture = dbHelper.getTotalDeductions(); // ← Hint: تحميل الخصومات
      _employeesCountFuture = dbHelper.getActiveEmployeesCount();
      _employeesListFuture = dbHelper.getAllActiveEmployees();
    });

    // ← Hint: تحميل قائمة الموظفين وتطبيق الفلتر
    _loadAndFilterEmployees();
  }

  /// ← Hint: تحميل قائمة الموظفين وتطبيق الفلتر المحدد
  Future<void> _loadAndFilterEmployees() async {
    try {
      final employees = await _employeesListFuture;
      setState(() {
        _allEmployees = employees;
        _applyFilter();
      });
    } catch (e) {
      // معالجة الخطأ
    }
  }

  /// ← Hint: تطبيق الفلتر على قائمة الموظفين حسب النوع المحدد
  void _applyFilter() {
    if (_selectedFilter == null) {
      // عرض الكل
      _filteredEmployees = _allEmployees;
    } else if (_selectedFilter == 'advances') {
      // عرض الموظفين الذين عليهم سلف فقط
      _filteredEmployees = _allEmployees.where((employee) {
        return employee.balance > Decimal.zero;
      }).toList();
    } else if (_selectedFilter == 'bonuses') {
      // ← Hint: عرض الموظفين الذين استلموا مكافآت
      // يتطلب جلب بيانات من جدول TB_Payroll
      _filterEmployeesWithBonuses();
      return;
    } else if (_selectedFilter == 'deductions') {
      // ← Hint: عرض الموظفين الذين تم خصم منهم
      _filterEmployeesWithDeductions();
      return;
    }
  }

  /// ← Hint: فلترة الموظفين الذين لديهم مكافآت (من كلا المصدرين)
  Future<void> _filterEmployeesWithBonuses() async {
    final db = await dbHelper.database;

    // جلب IDs الموظفين الذين لديهم مكافآت قديمة من TB_Payroll
    final payrollResult = await db.rawQuery('''
      SELECT DISTINCT EmployeeID
      FROM TB_Payroll
      WHERE Bonuses > 0
    ''');

    // جلب IDs الموظفين الذين لديهم مكافآت جديدة من TB_Employee_Bonuses
    final bonusesResult = await db.rawQuery('''
      SELECT DISTINCT EmployeeID
      FROM TB_Employee_Bonuses
    ''');

    // دمج IDs من كلا المصدرين
    final employeeIdsWithBonuses = <int>{
      ...payrollResult.map((row) => row['EmployeeID'] as int),
      ...bonusesResult.map((row) => row['EmployeeID'] as int),
    };

    setState(() {
      _filteredEmployees = _allEmployees.where((employee) {
        return employeeIdsWithBonuses.contains(employee.employeeID);
      }).toList();
    });
  }

  /// ← Hint: فلترة الموظفين الذين لديهم خصومات
  Future<void> _filterEmployeesWithDeductions() async {
    final db = await dbHelper.database;
    
    // جلب IDs الموظفين الذين لديهم خصومات من جدول الرواتب
    final result = await db.rawQuery('''
      SELECT DISTINCT EmployeeID
      FROM TB_Payroll
      WHERE Deductions > 0
    ''');
    
    final employeeIdsWithDeductions = result.map((row) => row['EmployeeID'] as int).toSet();
    
    setState(() {
      _filteredEmployees = _allEmployees.where((employee) {
        return employeeIdsWithDeductions.contains(employee.employeeID);
      }).toList();
    });
  }

  /// ← Hint: تغيير الفلتر وتطبيقه
  void _changeFilter(String? filter) {
    setState(() {
      _selectedFilter = filter;
      _applyFilter();
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
            
            // 📋 عنوان قائمة الموظفين مع عدد الموظفين المفلترين
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.employees_list_title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                // ← Hint: عرض عدد الموظفين المفلترين
                if (_filteredEmployees.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingMd,
                      vertical: AppConstants.spacingSm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: AppConstants.borderRadiusFull,
                    ),
                    child: Text(
                      '${_filteredEmployees.length}',
                      style: TextStyle(
                        color: AppColors.info,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
              ],
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
  /// يعرض 5 بطاقات إحصائية:
  /// 1. إجمالي الرواتب المدفوعة
  /// 2. إجمالي السلف المستحقة
  /// 3. إجمالي المكافآت
  /// 4. إجمالي الخصومات
  /// 5. عدد الموظفين النشطين
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
              child: FutureBuilder<Decimal>(
                future: _totalSalariesFuture,
                builder: (context, snapshot) {
                  // عرض حالة التحميل
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildSummaryCardSkeleton();
                  }
                  
                  // عرض البيانات
                  return StatCard(
                    label: l10n.stat_total_salaries,
                    value: formatCurrency(snapshot.data ?? Decimal.zero),
                    icon: Icons.payments,
                    color: AppColors.success,
                    subtitle: l10n.stat_salaries_paid,
                    onTap: () => _changeFilter(null), // ← Hint: عند النقر، عرض الكل
                    isSelected: _selectedFilter == null,
                  );
                },
              ),
            ),
            
            const SizedBox(width: AppConstants.spacingSm),
            
            // بطاقة السلف
            Expanded(
              child: FutureBuilder<Decimal>(
                future: _totalAdvancesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildSummaryCardSkeleton();
                  }
                  
                  return StatCard(
                    label: l10n.stat_advances_balance,
                    value: formatCurrency(snapshot.data ?? Decimal.zero),
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppColors.warning,
                    subtitle: l10n.stat_advances_due,
                    onTap: () => _changeFilter('advances'), // ← Hint: فلتر السلف
                    isSelected: _selectedFilter == 'advances',
                  );
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppConstants.spacingMd),
        
        // --- الصف الثاني: المكافآت والخصومات ---
        Row(
          children: [
            // ← Hint: بطاقة المكافآت (دمج من المصدرين)
            Expanded(
              child: FutureBuilder<List<Decimal>>(
                future: Future.wait([
                  _totalBonusesFuture, // القديمة من TB_Payroll
                  _totalEmployeeBonusesFuture, // الجديدة من TB_Employee_Bonuses
                ]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildSummaryCardSkeleton();
                  }

                  // جمع المكافآت من كلا المصدرين
                  final oldBonuses = snapshot.data?[0] ?? Decimal.zero;
                  final newBonuses = snapshot.data?[1] ?? Decimal.zero;
                  final totalBonuses = oldBonuses + newBonuses;

                  return StatCard(
                    label: 'إجمالي المكافآت',
                    value: formatCurrency(totalBonuses),
                    icon: Icons.card_giftcard,
                    color: AppColors.info,
                    subtitle: 'مكافآت مدفوعة',
                    onTap: () => _changeFilter('bonuses'), // ← Hint: فلتر المكافآت
                    isSelected: _selectedFilter == 'bonuses',
                  );
                },
              ),
            ),
            
            const SizedBox(width: AppConstants.spacingSm),
            
            // ← Hint: بطاقة الخصومات
            Expanded(
              child: FutureBuilder<Decimal>(
                future: _totalDeductionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildSummaryCardSkeleton();
                  }
                  
                  return StatCard(
                    label: 'إجمالي الخصومات',
                    value: formatCurrency(snapshot.data ?? Decimal.zero),
                    icon: Icons.remove_circle_outline,
                    color: AppColors.error,
                    subtitle: 'خصومات مطبقة',
                    onTap: () => _changeFilter('deductions'), // ← Hint: فلتر الخصومات
                    isSelected: _selectedFilter == 'deductions',
                  );
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppConstants.spacingMd),
        
        // --- الصف الثالث: عدد الموظفين ---
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
              onTap: () => _changeFilter(null), // ← Hint: عند النقر، عرض الكل
              isSelected: _selectedFilter == null,
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
  /// ← Hint: الآن تعرض القائمة المفلترة حسب الاختيار
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
        
        // ← Hint: استخدام القائمة المفلترة بدلاً من القائمة الكاملة
        // إذا كانت القائمة المفلترة فارغة، عرض رسالة
        if (_filteredEmployees.isEmpty) {
          String filterMessage = '';
          if (_selectedFilter == 'advances') {
            filterMessage = 'لا يوجد موظفين عليهم سلف';
          } else if (_selectedFilter == 'bonuses') {
            filterMessage = 'لا يوجد موظفين استلموا مكافآت';
          } else if (_selectedFilter == 'deductions') {
            filterMessage = 'لا يوجد موظفين تم خصم منهم';
          }
          
          return EmptyState(
            icon: Icons.filter_list_off,
            title: 'لا توجد نتائج',
            message: filterMessage,
          );
        }
        
        // --- عرض قائمة الموظفين المفلترة ---
        return CustomCard(
          padding: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredEmployees.length,
            
            // --- الفاصل بين العناصر ---
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: AppConstants.spacingMd,
              endIndent: AppConstants.spacingMd,
            ),
            
            // --- بناء كل عنصر موظف ---
            itemBuilder: (context, index) {
              final employee = _filteredEmployees[index];
              
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

// ============================================================================
// ← Hint: Widget مخصص لبطاقة الإحصائيات مع دعم التحديد والنقر
// ============================================================================
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;
  final VoidCallback? onTap; // ← Hint: دالة عند النقر
  final bool isSelected; // ← Hint: هل البطاقة محددة

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: AppConstants.borderRadiusMd,
      child: CustomCard(
        // ← Hint: تغيير لون الحدود عند التحديد
        child: Container(
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: color, width: 2)
                : null,
            borderRadius: AppConstants.borderRadiusMd,
          ),
          padding: AppConstants.paddingMd,
          child: Column(
            children: [
              // الأيقونة
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingSm),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: AppConstants.borderRadiusMd,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              
              const SizedBox(height: AppConstants.spacingSm),
              
              // التسمية
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppConstants.spacingXs),
              
              // القيمة
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppConstants.spacingXs),
              
              // النص الفرعي
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color.withOpacity(0.7),
                      fontSize: 11,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}