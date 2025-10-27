// lib/screens/reports/expenses_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database_helper.dart';
import '../../utils/helpers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_state.dart';
import 'manage_categories_screen.dart';

/// 💰 شاشة سجل المصاريف
/// ---------------------------
/// صفحة فرعية تعرض:
/// 1. قائمة جميع المصاريف المسجلة
/// 2. إمكانية إضافة مصروف جديد
/// 3. إدارة فئات المصاريف
class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  // ============= المتغيرات =============
  final dbHelper = DatabaseHelper.instance;
  late Future<List<Map<String, dynamic>>> _expensesFuture;

  // ============= التهيئة =============
  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  /// تحميل قائمة المصاريف من قاعدة البيانات
  void _loadExpenses() {
    setState(() {
      _expensesFuture = dbHelper.getExpenses();
    });
  }

  // ============= البناء الرئيسي =============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- AppBar مع زر إدارة الفئات ---
      appBar: AppBar(
        title: const Text('سجل المصاريف'),
        elevation: 0,
        actions: [
          // زر إدارة فئات المصاريف
          IconButton(
            icon: const Icon(Icons.category_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageCategoriesScreen(),
                ),
              );
              // تحديث القائمة عند الرجوع
              _loadExpenses();
            },
            tooltip: 'إدارة الفئات',
          ),
        ],
      ),

      // --- الجسم: قائمة المصاريف ---
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _expensesFuture,
        builder: (context, snapshot) {
          // --- حالة التحميل ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState(message: 'جاري تحميل المصاريف...');
          }

          // --- حالة الخطأ ---
          if (snapshot.hasError) {
            return ErrorState(
              message: 'حدث خطأ أثناء تحميل البيانات',
              onRetry: _loadExpenses,
            );
          }

          // --- حالة عدم وجود مصاريف ---
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'لا توجد مصاريف',
              message: 'لم يتم تسجيل أي مصروف حتى الآن',
              actionText: 'إضافة مصروف',
              onAction: _showAddExpenseDialog,
            );
          }

          // --- عرض قائمة المصاريف ---
          final expenses = snapshot.data!;

          return ListView.builder(
            padding: AppConstants.screenPadding,
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              return _buildExpenseCard(expense);
            },
          );
        },
      ),

      // --- زر الإضافة العائم ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseDialog,
        icon: const Icon(Icons.add),
        label: const Text('إضافة مصروف'),
        tooltip: 'إضافة مصروف جديد',
      ),
    );
  }

  // ============= بناء بطاقة المصروف =============
  /// يعرض كل مصروف في بطاقة منفصلة
  Widget _buildExpenseCard(Map<String, dynamic> expense) {
    final amount = expense['Amount'] as double;
    final description = expense['Description'] as String;
    final category = expense['Category'] as String?;
    final date = DateTime.parse(expense['ExpenseDate'] as String);
    final notes = expense['Notes'] as String?;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: InkWell(
        onTap: () => _showExpenseDetails(expense),
        borderRadius: AppConstants.cardBorderRadius,
        child: Padding(
          padding: AppConstants.paddingMd,
          child: Row(
            children: [
              // --- أيقونة المصروف ---
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: AppConstants.borderRadiusMd,
                ),
                child: Icon(
                  Icons.arrow_upward,
                  color: AppColors.error,
                  size: 24,
                ),
              ),

              const SizedBox(width: AppConstants.spacingMd),

              // --- تفاصيل المصروف ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الوصف
                    Text(
                      description,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: AppConstants.spacingXs),

                    // الفئة
                    Text(
                      category ?? 'غير مصنف',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),

                    // الملاحظات (إن وجدت)
                    if (notes != null && notes.isNotEmpty) ...[
                      const SizedBox(height: AppConstants.spacingXs),
                      Text(
                        notes,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: AppConstants.spacingMd),

              // --- المبلغ والتاريخ ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // المبلغ
                  Text(
                    '- ${formatCurrency(amount)}',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingXs),

                  // التاريخ
                  Text(
                    DateFormat('yyyy-MM-dd').format(date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============= نافذة إضافة مصروف =============
  /// نافذة حوار لإضافة مصروف جديد
  void _showAddExpenseDialog() async {
    // --- جلب قائمة الفئات ---
    final categories = await dbHelper.getExpenseCategories();
    final categoryNames = categories
        .map((cat) => cat['CategoryName'] as String)
        .toList();

    if (!mounted) return;

    // --- التحقق من وجود فئات ---
    if (categoryNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إضافة فئات المصاريف أولاً'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // --- متغيرات النموذج ---
    final formKey = GlobalKey<FormState>();
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String? selectedCategory = categoryNames.first;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        // --- عنوان النافذة ---
        title: const Row(
          children: [
            Icon(Icons.add_circle_outline, size: 28),
            SizedBox(width: 12),
            Text('إضافة مصروف جديد'),
          ],
        ),

        // --- محتوى النموذج ---
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- حقل الوصف ---
                CustomTextField(
                  controller: descriptionController,
                  label: 'وصف المصروف',
                  hint: 'مثال: فاتورة كهرباء',
                  prefixIcon: Icons.description_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الوصف مطلوب';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppConstants.spacingMd),

                // --- حقل المبلغ ---
                CustomTextField(
                  controller: amountController,
                  label: 'المبلغ',
                  hint: '0.00',
                  prefixIcon: Icons.attach_money,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'المبلغ مطلوب';
                    }
                    final convertedValue = convertArabicNumbersToEnglish(value);
                    if (double.tryParse(convertedValue) == null) {
                      return 'أدخل رقماً صحيحاً';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppConstants.spacingMd),

                // --- قائمة الفئات ---
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'الفئة',
                    prefixIcon: const Icon(Icons.category_outlined),
                    border: OutlineInputBorder(
                      borderRadius: AppConstants.inputBorderRadius,
                    ),
                  ),
                  items: categoryNames.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedCategory = value;
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'اختر الفئة';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppConstants.spacingMd),

                // --- حقل الملاحظات (اختياري) ---
                CustomTextField(
                  controller: notesController,
                  label: 'ملاحظات (اختياري)',
                  hint: 'أضف ملاحظة...',
                  prefixIcon: Icons.note_outlined,
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),

        // --- أزرار الإجراءات ---
        actions: [
          // زر الإلغاء
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),

          // زر الحفظ
          ElevatedButton.icon(
            onPressed: () async {
              // --- التحقق من صحة البيانات ---
              if (!formKey.currentState!.validate()) return;

              // --- تحضير البيانات ---
              final expenseData = {
                'Description': descriptionController.text.trim(),
                'Amount': double.parse(
                  convertArabicNumbersToEnglish(amountController.text),
                ),
                'ExpenseDate': DateTime.now().toIso8601String(),
                'Category': selectedCategory,
                'Notes': notesController.text.trim(),
              };

              try {
                // --- حفظ المصروف ---
                await dbHelper.recordExpense(expenseData);

                if (!ctx.mounted) return;

                // إغلاق النافذة
                Navigator.pop(ctx);

                // رسالة نجاح
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إضافة المصروف بنجاح'),
                    backgroundColor: AppColors.success,
                  ),
                );

                // تحديث القائمة
                _loadExpenses();
              } catch (e) {
                // رسالة خطأ
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('حدث خطأ: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  // ============= نافذة تفاصيل المصروف =============
  /// عرض تفاصيل المصروف عند النقر عليه
  void _showExpenseDetails(Map<String, dynamic> expense) {
    final amount = expense['Amount'] as double;
    final description = expense['Description'] as String;
    final category = expense['Category'] as String?;
    final date = DateTime.parse(expense['ExpenseDate'] as String);
    final notes = expense['Notes'] as String?;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.receipt_long, size: 28),
            SizedBox(width: 12),
            Text('تفاصيل المصروف'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الوصف
            _buildDetailRow(
              icon: Icons.description_outlined,
              label: 'الوصف',
              value: description,
            ),

            const Divider(height: 24),

            // المبلغ
            _buildDetailRow(
              icon: Icons.attach_money,
              label: 'المبلغ',
              value: formatCurrency(amount),
              valueColor: AppColors.error,
            ),

            const Divider(height: 24),

            // الفئة
            _buildDetailRow(
              icon: Icons.category_outlined,
              label: 'الفئة',
              value: category ?? 'غير مصنف',
            ),

            const Divider(height: 24),

            // التاريخ
            _buildDetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'التاريخ',
              value: DateFormat('yyyy-MM-dd').format(date),
            ),

            // الملاحظات
            if (notes != null && notes.isNotEmpty) ...[
              const Divider(height: 24),
              _buildDetailRow(
                icon: Icons.note_outlined,
                label: 'الملاحظات',
                value: notes,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  /// صف تفصيلي موحد
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: valueColor,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}