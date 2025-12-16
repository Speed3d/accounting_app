// lib/screens/fiscal_years/fiscal_years_screen.dart

import 'package:accountant_touch/data/models.dart';
import 'package:accountant_touch/services/currency_service.dart';
import 'package:accountant_touch/services/fiscal_year_service.dart';
import 'package:accountant_touch/theme/app_colors.dart';
import 'package:accountant_touch/theme/app_constants.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 📅 شاشة إدارة السنوات المالية
///
/// ← Hint: تعرض قائمة بجميع السنوات المالية مع إمكانية:
/// ← Hint: - إنشاء سنة مالية جديدة
/// ← Hint: - تفعيل سنة مالية
/// ← Hint: - إقفال سنة مالية
/// ← Hint: - عرض تفاصيل كل سنة
class FiscalYearsScreen extends StatefulWidget {
  const FiscalYearsScreen({super.key});

  @override
  State<FiscalYearsScreen> createState() => _FiscalYearsScreenState();
}

class _FiscalYearsScreenState extends State<FiscalYearsScreen> {
  final _fiscalYearService = FiscalYearService.instance;
  final _currencyService = CurrencyService.instance;
  List<FiscalYear> _fiscalYears = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFiscalYears();
  }

  /// تحميل السنوات المالية من قاعدة البيانات
  Future<void> _loadFiscalYears() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final years = await _fiscalYearService.getAllFiscalYears(
        includeInactive: true,
      );

      setState(() {
        _fiscalYears = years;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ في تحميل السنوات المالية: $e';
        _isLoading = false;
      });
    }
  }

  /// عرض نافذة إنشاء سنة مالية جديدة
  void _showCreateFiscalYearDialog() {
    final yearController = TextEditingController();
    final openingBalanceController = TextEditingController(text: '0');
    final notesController = TextEditingController();
    bool makeActive = _fiscalYears.isEmpty; // تفعيل تلقائياً إذا كانت أول سنة

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_circle_outline, color: AppColors.primaryLight),
            SizedBox(width: 12),
            Text('إنشاء سنة مالية جديدة'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ← Hint: حقل السنة
              TextField(
                controller: yearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'السنة *',
                  hintText: '2025',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),

              // ← Hint: حقل الرصيد الافتتاحي
              TextField(
                controller: openingBalanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'الرصيد الافتتاحي',
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.account_balance_wallet),
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),

              // ← Hint: حقل الملاحظات
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات',
                  hintText: 'ملاحظات اختيارية...',
                  prefixIcon: Icon(Icons.note_outlined),
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),

              // ← Hint: خيار تفعيل السنة
              StatefulBuilder(
                builder: (context, setDialogState) => CheckboxListTile(
                  title: const Text('تفعيل هذه السنة'),
                  subtitle: const Text('جعلها السنة النشطة حالياً'),
                  value: makeActive,
                  onChanged: (value) {
                    setDialogState(() => makeActive = value ?? false);
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final yearText = yearController.text.trim();
              if (yearText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('الرجاء إدخال السنة')),
                );
                return;
              }

              final year = int.tryParse(yearText);
              if (year == null || year < 2000 || year > 2100) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('الرجاء إدخال سنة صحيحة (2000-2100)')),
                );
                return;
              }

              final openingBalance = Decimal.tryParse(
                openingBalanceController.text.trim(),
              ) ?? Decimal.zero;

              Navigator.pop(context);

              // ← Hint: إنشاء السنة المالية
              try {
                final newYear = await _fiscalYearService.createFiscalYear(
                  year: year,
                  openingBalance: openingBalance,
                  makeActive: makeActive,
                  notes: notesController.text.trim().isNotEmpty
                      ? notesController.text.trim()
                      : null,
                );

                if (newYear != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم إنشاء سنة $year بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadFiscalYears();
                } else {
                  throw Exception('فشل إنشاء السنة المالية');
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('خطأ: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('إنشاء'),
          ),
        ],
      ),
    );
  }

  /// تفعيل سنة مالية
  Future<void> _activateFiscalYear(FiscalYear year) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفعيل سنة مالية'),
        content: Text(
          'هل تريد تفعيل سنة ${year.year}؟\n\n'
          'سيتم إلغاء تفعيل السنة الحالية تلقائياً.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تفعيل'),
          ),
        ],
      ),
    );

    if (confirm == true && year.fiscalYearID != null) {
      try {
        final success = await _fiscalYearService.activateFiscalYear(
          year.fiscalYearID!,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم تفعيل سنة ${year.year}'),
              backgroundColor: Colors.green,
            ),
          );
          _loadFiscalYears();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// إقفال سنة مالية
  Future<void> _closeFiscalYear(FiscalYear year) async {
    if (year.isClosed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هذه السنة مقفلة بالفعل')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ إقفال سنة مالية'),
        content: Text(
          'هل تريد إقفال سنة ${year.year}؟\n\n'
          '⚠️ تنبيه: لن تتمكن من إضافة قيود جديدة لهذه السنة بعد الإقفال.\n\n'
          'سيتم إنشاء سنة ${year.year + 1} تلقائياً بالرصيد الختامي.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إقفال السنة'),
          ),
        ],
      ),
    );

    if (confirm == true && year.fiscalYearID != null) {
      try {
        final closedYear = await _fiscalYearService.closeFiscalYear(
          fiscalYearId: year.fiscalYearID!,
          createNewYear: true,
        );

        if (closedYear != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم إقفال سنة ${year.year} وإنشاء سنة ${year.year + 1}'),
              backgroundColor: Colors.green,
            ),
          );
          _loadFiscalYears();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('السنوات المالية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
            onPressed: _loadFiscalYears,
          ),
        ],
      ),
      body: _buildBody(isDark),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateFiscalYearDialog,
        icon: const Icon(Icons.add),
        label: const Text('سنة جديدة'),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFiscalYears,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (_fiscalYears.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 80,
              color: isDark ? Colors.grey[700] : Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'لا توجد سنوات مالية',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'اضغط على الزر أدناه لإنشاء سنة مالية جديدة',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: AppConstants.screenPadding,
      itemCount: _fiscalYears.length,
      itemBuilder: (context, index) {
        final year = _fiscalYears[index];
        return _buildFiscalYearCard(year, isDark);
      },
    );
  }

  Widget _buildFiscalYearCard(FiscalYear year, bool isDark) {
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      elevation: year.isActive ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: year.isActive
            ? const BorderSide(color: AppColors.primaryLight, width: 2)
            : BorderSide.none,
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: year.isActive
                ? AppColors.primaryLight.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            year.isActive ? Icons.check_circle : Icons.calendar_today,
            color: year.isActive ? AppColors.primaryLight : Colors.grey,
          ),
        ),
        title: Row(
          children: [
            Text(
              year.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: year.isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (year.isActive) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'نشطة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            if (year.isClosed) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'مقفلة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${dateFormat.format(year.startDate)} - ${dateFormat.format(year.endDate)}',
        ),
        children: [
          Builder(
            builder: (context) {
              // ✅ إضافة try-catch للحماية من الأخطاء
              try {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ← Hint: معلومات مالية مع CurrencyService
                      _buildInfoRow(
                        'الرصيد الافتتاحي',
                        _currencyService.formatAmount(year.openingBalance),
                        Icons.trending_up,
                        Colors.blue,
                      ),
                      const Divider(),
                      _buildInfoRow(
                        'إجمالي الدخل',
                        _currencyService.formatAmount(year.totalIncome),
                        Icons.arrow_downward,
                        Colors.green,
                      ),
                      const Divider(),
                      _buildInfoRow(
                        'إجمالي المصروفات',
                        _currencyService.formatAmount(year.totalExpense),
                        Icons.arrow_upward,
                        Colors.red,
                      ),
                      const Divider(),
                      _buildInfoRow(
                        'صافي الربح',
                        _currencyService.formatAmount(year.netProfit),
                        Icons.account_balance,
                        year.netProfit >= Decimal.zero ? Colors.green : Colors.red,
                      ),
                      const Divider(),
                      _buildInfoRow(
                        'الرصيد الختامي',
                        _currencyService.formatAmount(year.closingBalance),
                        Icons.account_balance_wallet,
                        Colors.purple,
                      ),

                      const SizedBox(height: 16),

                      // ← Hint: أزرار الإجراءات
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (!year.isActive && !year.isClosed)
                            ElevatedButton.icon(
                              onPressed: () => _activateFiscalYear(year),
                              icon: const Icon(Icons.play_arrow, size: 18),
                              label: const Text('تفعيل'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryLight,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          if (year.isActive && !year.isClosed)
                            ElevatedButton.icon(
                              onPressed: () => _closeFiscalYear(year),
                              icon: const Icon(Icons.lock_outline, size: 18),
                              label: const Text('إقفال'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              } catch (e) {
                debugPrint('❌ خطأ في عرض تفاصيل السنة المالية: $e');
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'حدث خطأ في عرض التفاصيل',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
