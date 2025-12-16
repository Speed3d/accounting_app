// lib/screens/fiscal_years/transactions_screen.dart

import 'package:accountant_touch/data/models.dart';
import 'package:accountant_touch/services/currency_service.dart';
import 'package:accountant_touch/services/fiscal_year_service.dart';
import 'package:accountant_touch/services/transaction_service.dart';
import 'package:accountant_touch/theme/app_colors.dart';
import 'package:accountant_touch/theme/app_constants.dart';
import 'package:accountant_touch/utils/helpers.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 📋 شاشة القيود المالية
///
/// ← Hint: تعرض قائمة بجميع القيود المالية مع إمكانية:
/// ← Hint: - الفلترة حسب النوع والاتجاه والسنة المالية
/// ← Hint: - البحث والفرز
/// ← Hint: - عرض تفاصيل كل قيد
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _transactionService = TransactionService.instance;
  final _fiscalYearService = FiscalYearService.instance;
  final _currencyService = CurrencyService.instance;

  List<FinancialTransaction> _transactions = [];
  FiscalYear? _activeFiscalYear;
  bool _isLoading = true;
  String? _errorMessage;

  // ← Hint: معايير الفلترة
  int? _selectedFiscalYearId;
  TransactionType? _selectedType;
  String? _selectedDirection; // "in" or "out"

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// تحميل البيانات
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ← Hint: تحميل السنة المالية النشطة
      final activeFiscalYear = await _fiscalYearService.getActiveFiscalYear();

      setState(() {
        _activeFiscalYear = activeFiscalYear;
        _selectedFiscalYearId = activeFiscalYear?.fiscalYearID;
      });

      // ← Hint: تحميل القيود
      await _loadTransactions();
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ في تحميل البيانات: $e';
        _isLoading = false;
      });
    }
  }

  /// تحميل القيود المالية
  Future<void> _loadTransactions() async {
    try {
      final transactions = await _transactionService.getTransactions(
        fiscalYearId: _selectedFiscalYearId,
        type: _selectedType,
        direction: _selectedDirection,
        orderBy: 'Date DESC',
      );

      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ في تحميل القيود: $e';
        _isLoading = false;
      });
    }
  }

  /// عرض نافذة الفلترة
  void _showFilterDialog() async {
    // ← Hint: جلب جميع السنوات المالية للفلتر
    final allFiscalYears = await _fiscalYearService.getAllFiscalYears();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        int? tempFiscalYearId = _selectedFiscalYearId;
        TransactionType? tempType = _selectedType;
        String? tempDirection = _selectedDirection;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.filter_list, color: AppColors.primaryLight),
                SizedBox(width: 12),
                Text('فلترة القيود'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ← Hint: اختيار السنة المالية
                  const Text(
                    'السنة المالية:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    value: tempFiscalYearId,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('جميع السنوات'),
                      ),
                      ...allFiscalYears.map((year) => DropdownMenuItem<int?>(
                            value: year.fiscalYearID,
                            child: Text(year.name),
                          )),
                    ],
                    onChanged: (value) {
                      setDialogState(() => tempFiscalYearId = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // ← Hint: اختيار نوع القيد
                  const Text(
                    'نوع القيد:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<TransactionType?>(
                    value: tempType,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<TransactionType?>(
                        value: null,
                        child: Text('جميع الأنواع'),
                      ),
                      ...TransactionType.values.map((type) =>
                          DropdownMenuItem<TransactionType?>(
                            value: type,
                            child: Text(_getTypeNameArabic(type)),
                          )),
                    ],
                    onChanged: (value) {
                      setDialogState(() => tempType = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // ← Hint: اختيار الاتجاه (دخل/مصروف)
                  const Text(
                    'الاتجاه:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    value: tempDirection,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.swap_vert),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('الكل'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'in',
                        child: Text('دخل'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'out',
                        child: Text('مصروف'),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() => tempDirection = value);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setDialogState(() {
                    tempFiscalYearId = _activeFiscalYear?.fiscalYearID;
                    tempType = null;
                    tempDirection = null;
                  });
                },
                child: const Text('إعادة تعيين'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedFiscalYearId = tempFiscalYearId;
                    _selectedType = tempType;
                    _selectedDirection = tempDirection;
                  });
                  Navigator.pop(context);
                  _loadTransactions();
                },
                child: const Text('تطبيق'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('القيود المالية'),
        actions: [
          // ← Hint: عرض عدد القيود
          if (_transactions.isNotEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_transactions.length} قيد',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'فلترة',
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildBody(isDark),
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
              onPressed: _loadData,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 80,
              color: isDark ? Colors.grey[700] : Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'لا توجد قيود مالية',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              _selectedFiscalYearId != null
                  ? 'لا توجد قيود في السنة المالية المحددة'
                  : 'ابدأ بإضافة عمليات مالية\nلتظهر القيود هنا تلقائياً',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // ← Hint: حساب الإحصائيات
    final totalIncome = _transactions
        .where((t) => t.direction == 'in')
        .fold<Decimal>(Decimal.zero, (sum, t) => sum + t.amount);
    final totalExpense = _transactions
        .where((t) => t.direction == 'out')
        .fold<Decimal>(Decimal.zero, (sum, t) => sum + t.amount);
    final netProfit = totalIncome - totalExpense;

    return Column(
      children: [
        // ← Hint: ملخص مالي
        Container(
          margin: AppConstants.screenPadding,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'دخل',
                  totalIncome,
                  Colors.green,
                  Icons.arrow_downward,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: isDark ? Colors.grey[700] : Colors.grey[300],
              ),
              Expanded(
                child: _buildSummaryItem(
                  'مصروف',
                  totalExpense,
                  Colors.red,
                  Icons.arrow_upward,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: isDark ? Colors.grey[700] : Colors.grey[300],
              ),
              Expanded(
                child: _buildSummaryItem(
                  'صافي',
                  netProfit,
                  netProfit >= Decimal.zero ? Colors.green : Colors.red,
                  Icons.account_balance,
                ),
              ),
            ],
          ),
        ),

        // ← Hint: قائمة القيود
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _transactions.length,
            itemBuilder: (context, index) {
              final transaction = _transactions[index];
              return _buildTransactionCard(transaction, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
    String label,
    Decimal amount,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          formatCurrency(amount),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(FinancialTransaction transaction, bool isDark) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
    final isIncome = transaction.direction == 'in';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isIncome
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isIncome
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIncome ? Colors.green : Colors.red,
            size: 24,
          ),
        ),
        title: Text(
          transaction.description,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(
              Icons.category,
              size: 14,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(_getTypeNameArabic(transaction.type)),
            const SizedBox(width: 12),
            Icon(
              Icons.access_time,
              size: 14,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(dateFormat.format(transaction.date)),
          ],
        ),
        trailing: Text(
          '${isIncome ? '+' : '-'}${formatCurrency(transaction.amount)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (transaction.notes != null) ...[
                  _buildDetailRow(
                    'ملاحظات',
                    transaction.notes!,
                    Icons.note,
                    Colors.blue,
                  ),
                  const Divider(),
                ],
                _buildDetailRow(
                  'التصنيف',
                  _getCategoryNameArabic(transaction.category),
                  Icons.style,
                  Colors.purple,
                ),
                const Divider(),
                if (transaction.referenceType != null) ...[
                  _buildDetailRow(
                    'نوع المرجع',
                    transaction.referenceType!,
                    Icons.link,
                    Colors.orange,
                  ),
                  if (transaction.referenceId != null) ...[
                    const Divider(),
                    _buildDetailRow(
                      'رقم المرجع',
                      '#${transaction.referenceId}',
                      Icons.tag,
                      Colors.orange,
                    ),
                  ],
                  const Divider(),
                ],
                _buildDetailRow(
                  'رقم القيد',
                  '#${transaction.transactionID}',
                  Icons.numbers,
                  Colors.grey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// ترجمة نوع القيد إلى العربية
  String _getTypeNameArabic(TransactionType type) {
    switch (type) {
      case TransactionType.sale:
        return 'مبيعة';
      case TransactionType.saleReturn:
        return 'مرتجع مبيعات';
      case TransactionType.customerPayment:
        return 'دفعة زبون';
      case TransactionType.salary:
        return 'راتب';
      case TransactionType.employeeAdvance:
        return 'سلفة';
      case TransactionType.advanceRepayment:
        return 'تسديد سلفة';
      case TransactionType.employeeBonus:
        return 'مكافأة';
      case TransactionType.expense:
        return 'مصروف';
      case TransactionType.openingBalance:
        return 'رصيد افتتاحي';
      case TransactionType.closingBalance:
        return 'رصيد ختامي';
      case TransactionType.other:
        return 'أخرى';
    }
  }

  /// ترجمة تصنيف القيد إلى العربية
  String _getCategoryNameArabic(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.revenue:
        return 'إيرادات';
      case TransactionCategory.costOfGoodsSold:
        return 'تكلفة البضاعة المباعة';
      case TransactionCategory.operatingExpense:
        return 'مصروفات تشغيلية';
      case TransactionCategory.salaryExpense:
        return 'مصروفات رواتب';
      case TransactionCategory.advanceExpense:
        return 'سلف';
      case TransactionCategory.customerDebt:
        return 'ديون عملاء';
      case TransactionCategory.returnExpense:
        return 'مرتجعات';
      case TransactionCategory.balanceTransfer:
        return 'نقل رصيد';
      case TransactionCategory.miscellaneous:
        return 'متنوعة';
    }
  }
}
