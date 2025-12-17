// lib/screens/reports/expenses_screen.dart

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database_helper.dart';
import '../../services/fiscal_year_service.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/helpers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_state.dart';
import 'manage_categories_screen.dart';

/// 💰 شاشة سجل المصاريف
/// ---------------------------
/// **الوظيفة الأساسية:**
/// صفحة فرعية متخصصة في إدارة وعرض جميع المصاريف المالية للمشروع
/// 
/// **الأقسام الرئيسية:**
/// 1. قائمة المصاريف: عرض جميع المصاريف المسجلة مرتبة زمنياً
/// 2. إضافة مصروف: نموذج شامل لتسجيل مصروف جديد
/// 3. إدارة الفئات: زر للانتقال لشاشة إدارة فئات المصاريف
/// 
/// **الميزات:**
/// - ✅ عرض تفصيلي لكل مصروف (الوصف، المبلغ، الفئة، التاريخ، الملاحظات)
/// - ✅ فلترة وبحث حسب الفئة
/// - ✅ إضافة/تعديل المصاريف
/// - ✅ دعم الأرقام العربية والإنجليزية
/// - ✅ Validation كامل للبيانات المدخلة
/// - ✅ Pull to Refresh
/// - ✅ Empty State عند عدم وجود بيانات
/// 
/// **الاستخدام:**
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (context) => const ExpensesScreen()),
/// );
/// ```
class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  // ============================================================================
  // 📦 المتغيرات - Variables
  // ============================================================================
  
  /// Hint: مثيل من DatabaseHelper للتعامل مع قاعدة البيانات
  final dbHelper = DatabaseHelper.instance;
  
  /// Hint: Future يحمل قائمة المصاريف من قاعدة البيانات
  /// يتم تحديثه عند كل عملية إضافة/حذف/تعديل
  late Future<List<Map<String, dynamic>>> _expensesFuture;

  // ============================================================================
  // 🎬 دورة الحياة - Lifecycle
  // ============================================================================
  
  @override
  void initState() {
    super.initState();
    // Hint: تحميل البيانات عند بداية الصفحة
    _loadExpenses();
  }

  // ============================================================================
  // 🔄 دوال التحميل - Loading Functions
  // ============================================================================
  
  /// دالة لتحميل قائمة المصاريف من قاعدة البيانات
  /// 
  /// **الوظيفة:**
  /// - تستدعي دالة getExpenses() من DatabaseHelper
  /// - تحفظ النتيجة في _expensesFuture
  /// - تستدعي setState() لإعادة بناء الواجهة
  /// 
  /// **متى تُستدعى:**
  /// - عند فتح الشاشة (في initState)
  /// - بعد إضافة مصروف جديد
  /// - عند Pull to Refresh
  /// - بعد العودة من شاشة إدارة الفئات
  void _loadExpenses() {
    setState(() {
      // Hint: جلب البيانات من قاعدة البيانات وحفظها في Future
      _expensesFuture = dbHelper.getExpenses();
    });
  }

  // ============================================================================
  // 🎨 البناء الرئيسي - Main Build
  // ============================================================================
  
  @override
  Widget build(BuildContext context) {
    // Hint: جلب نصوص الترجمة من ملف l10n
    // إذا كان null (في حالة عدم وجود ترجمة)، نستخدم نصوص افتراضية
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      // ============================================================================
      // 📱 AppBar - الشريط العلوي
      // ============================================================================
      appBar: AppBar(
        // Hint: العنوان يأتي من ملف الترجمة، أو نص افتراضي
        title: Text(l10n?.expenseRecord ?? 'سجل المصاريف'),
        elevation: 0,
        actions: [
          // ============================================================================
          // 🗂️ زر إدارة فئات المصاريف
          // ============================================================================
          // Hint: هذا الزر ينقل المستخدم لشاشة منفصلة لإدارة الفئات
          IconButton(
            icon: const Icon(Icons.category_outlined),
            onPressed: () async {
              // Hint: الانتقال لشاشة إدارة الفئات
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageCategoriesScreen(),
                ),
              );
              // Hint: عند الرجوع، نُحدث قائمة المصاريف (لأن الفئات قد تكون تغيرت)
              _loadExpenses();
            },
            tooltip: l10n?.manageCategories ?? 'إدارة الفئات',
          ),
        ],
      ),

      // ============================================================================
      // 📋 الجسم الرئيسي - Body
      // ============================================================================
      body: RefreshIndicator(
        // Hint: Pull to Refresh - السحب للأسفل لإعادة التحميل
        onRefresh: () async => _loadExpenses(),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _expensesFuture,
          builder: (context, snapshot) {
            // ============================================================================
            // ⏳ حالة التحميل - Loading State
            // ============================================================================
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Hint: عرض مؤشر التحميل أثناء جلب البيانات
              return LoadingState(
                message: l10n?.loadingExpenses ?? 'جاري تحميل المصاريف...',
              );
            }

            // ============================================================================
            // ❌ حالة الخطأ - Error State
            // ============================================================================
            if (snapshot.hasError) {
              // Hint: عرض رسالة خطأ إذا فشل جلب البيانات
              return ErrorState(
                message: l10n?.loadError ?? 'حدث خطأ أثناء تحميل البيانات',
                onRetry: _loadExpenses,
              );
            }

            // ============================================================================
            // 📭 حالة عدم وجود بيانات - Empty State
            // ============================================================================
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              // Hint: عرض رسالة وأيقونة عند عدم وجود مصاريف
              return EmptyState(
                icon: Icons.receipt_long_outlined,
                title: l10n?.noExpenses ?? 'لا توجد مصاريف',
                message: l10n?.noExpensesMessage ?? 'لم يتم تسجيل أي مصروف حتى الآن',
                actionText: l10n?.addExpense ?? 'إضافة مصروف',
                onAction: _showAddExpenseDialog,
              );
            }

            // ============================================================================
            // ✅ حالة عرض البيانات - Data Display
            // ============================================================================
            final expenses = snapshot.data!;

            return ListView.builder(
              padding: AppConstants.screenPadding,
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final expense = expenses[index];
                // Hint: بناء بطاقة لكل مصروف
                return _buildExpenseCard(expense);
              },
            );
          },
        ),
      ),

      // ============================================================================
      // ➕ زر الإضافة العائم - FAB
      // ============================================================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseDialog,
        icon: const Icon(Icons.add),
        label: Text(l10n?.addExpense ?? 'إضافة مصروف'),
        tooltip: l10n?.newExpense ?? 'مصروف جديد',
      ),
    );
  }

  // ============================================================================
  // 🎴 بناء بطاقة المصروف - Expense Card Builder
  // ============================================================================
  
  /// دالة لبناء بطاقة عرض مصروف واحد
  /// 
  /// **المعاملات:**
  /// - expense: Map يحتوي على بيانات المصروف من قاعدة البيانات
  /// 
  /// **البيانات المعروضة:**
  /// - أيقونة السهم للأعلى (ترمز للصرف)
  /// - الوصف (Description)
  /// - الفئة (Category)
  /// - الملاحظات (Notes) - اختيارية
  /// - المبلغ (Amount) - باللون الأحمر
  /// - التاريخ (ExpenseDate)
  /// 
  /// **التفاعل:**
  /// - عند النقر: فتح نافذة تفاصيل المصروف
  Widget _buildExpenseCard(Map<String, dynamic> expense) {
    final l10n = AppLocalizations.of(context);
    
    // Hint: استخراج البيانات من Map
    // final amount = expense['Amount'] as Decimal;
    final amount = Decimal.parse(expense['Amount'].toString());
    final description = expense['Description'] as String;
    final category = expense['Category'] as String?;
    final date = DateTime.parse(expense['ExpenseDate'] as String);
    final notes = expense['Notes'] as String?;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: InkWell(
        // Hint: عند النقر على البطاقة، نعرض تفاصيل المصروف كاملة
        onTap: () => _showExpenseDetails(expense),
        borderRadius: AppConstants.cardBorderRadius,
        child: Padding(
          padding: AppConstants.paddingSm,
          child: Row(
            children: [
              // ============================================================================
              // 🔴 أيقونة المصروف
              // ============================================================================
              // Hint: حاوية دائرية بخلفية حمراء فاتحة وأيقونة سهم للأعلى
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
                  size: 28,
                ),
              ),

              const SizedBox(width: AppConstants.spacingMd),

              // ============================================================================
              // 📄 تفاصيل المصروف (الوصف، الفئة، الملاحظات)
              // ============================================================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- الوصف ---
                    // Hint: نص غامق يظهر وصف المصروف
                    Text(
                      description,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: AppConstants.spacingXs),

                    // --- الفئة ---
                    // Hint: نص صغير يظهر اسم الفئة أو "غير مصنف" إذا كانت null
                    Text(
                      category ?? (l10n?.unclassified ?? 'غير مصنف'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),

                    // --- الملاحظات (اختيارية) ---
                    // Hint: تظهر فقط إذا كانت موجودة وليست فارغة
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

              // ============================================================================
              // 💵 المبلغ والتاريخ
              // ============================================================================
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // --- المبلغ ---
                  // Hint: نعرض المبلغ باللون الأحمر مع إشارة ناقص (-)
                  Text(
                    '- ${formatCurrency(amount)}',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingXs),

                  // --- التاريخ ---
                  // Hint: نعرض التاريخ بصيغة yyyy-MM-dd
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

  // ============================================================================
  // ➕ نافذة إضافة مصروف - Add Expense Dialog
  // ============================================================================
  
  /// دالة لعرض نافذة حوار لإضافة مصروف جديد
  /// 
  /// **الخطوات:**
  /// 1. جلب قائمة الفئات من قاعدة البيانات
  /// 2. التحقق من وجود فئات (إلزامي)
  /// 3. عرض نموذج بالحقول التالية:
  ///    - الوصف (مطلوب)
  ///    - المبلغ (مطلوب، رقمي)
  ///    - الفئة (مطلوب، من قائمة منسدلة)
  ///    - الملاحظات (اختياري)
  /// 4. Validation شامل
  /// 5. حفظ المصروف في قاعدة البيانات
  /// 6. تحديث القائمة
  void _showAddExpenseDialog() async {
    final l10n = AppLocalizations.of(context);
    
    // ============================================================================
    // 📂 الخطوة 1: جلب قائمة الفئات
    // ============================================================================
    // Hint: نحتاج لعرض الفئات في قائمة منسدلة (Dropdown)
    final categories = await dbHelper.getExpenseCategories();
    final categoryNames = categories
        .map((cat) => cat['CategoryName'] as String)
        .toList();

    if (!mounted) return;

    // ============================================================================
    // ⚠️ الخطوة 2: التحقق من وجود فئات
    // ============================================================================
    // Hint: إذا لم تكن هناك فئات، نطلب من المستخدم إضافتها أولاً
    if (categoryNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.addCategoriesFirst ?? 'يرجى إضافة فئات المصاريف أولاً'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // ============================================================================
    // 📝 الخطوة 3: تعريف متغيرات النموذج
    // ============================================================================
    final formKey = GlobalKey<FormState>();
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String? selectedCategory = categoryNames.first;

    // ============================================================================
    // 🪟 الخطوة 4: عرض نافذة الحوار
    // ============================================================================
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        // --- عنوان النافذة ---
        title: Row(
          children: [
            const Icon(Icons.add_circle_outline, size: 28),
            const SizedBox(width: 12),
            Text(l10n?.addExpense ?? 'إضافة مصروف'),
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
                // ============================================================================
                // 📄 حقل الوصف
                // ============================================================================
                // Hint: حقل نصي إلزامي لوصف المصروف
                CustomTextField(
                  controller: descriptionController,
                  label: l10n?.expenseDescription ?? 'وصف المصروف',
                  hint: l10n?.expenseDescriptionHint ?? 'مثال: فاتورة كهرباء',
                  prefixIcon: Icons.description_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n?.descriptionRequired ?? 'الوصف مطلوب';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppConstants.spacingMd),

                // ============================================================================
                // 💵 حقل المبلغ
                // ============================================================================
                // Hint: حقل رقمي إلزامي، يدعم الأرقام العربية والإنجليزية
                CustomTextField(
                  controller: amountController,
                  label: l10n?.amount ?? 'المبلغ',
                  hint: '0.00',
                  prefixIcon: Icons.attach_money,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n?.amountRequired ?? 'المبلغ مطلوب';
                    }
                    // Hint: تحويل الأرقام العربية إلى إنجليزية قبل التحقق
                    final convertedValue = convertArabicNumbersToEnglish(value);
                    if (double.tryParse(convertedValue) == null) {
                      return l10n?.enterValidNumber ?? 'أدخل رقماً صحيحاً';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppConstants.spacingMd),

                // ============================================================================
                // 🗂️ قائمة الفئات المنسدلة
                // ============================================================================
                // Hint: Dropdown لاختيار فئة المصروف
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: l10n?.category ?? 'الفئة',
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
                      return l10n?.selectCategory ?? 'اختر الفئة';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppConstants.spacingMd),

                // ============================================================================
                // 📝 حقل الملاحظات (اختياري)
                // ============================================================================
                // Hint: حقل نصي متعدد الأسطر للملاحظات الإضافية
                CustomTextField(
                  controller: notesController,
                  label: l10n?.notesOptional ?? 'ملاحظات (اختياري)',
                  hint: l10n?.addNote ?? 'أضف ملاحظة...',
                  prefixIcon: Icons.note_outlined,
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),

        // ============================================================================
        // 🔘 أزرار الإجراءات
        // ============================================================================
        actions: [
          // --- زر الإلغاء ---
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n?.cancel ?? 'إلغاء'),
          ),

          // --- زر الحفظ ---
          ElevatedButton.icon(
            onPressed: () async {
              // ============================================================================
              // ✅ التحقق من صحة البيانات
              // ============================================================================
              if (!formKey.currentState!.validate()) return;

              // ============================================================================
              // 📦 تحضير البيانات للحفظ
              // ============================================================================
              // ← Hint: الحصول على السنة المالية النشطة
              final activeFiscalYearId = await FiscalYearService.instance.getActiveFiscalYearId();

              final expenseData = {
                'Description': descriptionController.text.trim(),
                'Amount': parseDecimal(  // ✅ صحيح
                 convertArabicNumbersToEnglish(amountController.text),
                 ).toDouble(),  // للتخزين في قاعدة البيانات REAL
                'ExpenseDate': DateTime.now().toIso8601String(),
                'Category': selectedCategory,
                'Notes': notesController.text.trim(),
                'FiscalYearID': activeFiscalYearId ?? 1, // ← Hint: إضافة السنة المالية
              };

              try {
                // ============================================================================
                // 💾 حفظ المصروف في قاعدة البيانات
                // ============================================================================
                await dbHelper.recordExpense(expenseData);

                if (!ctx.mounted) return;

                // إغلاق النافذة
                Navigator.pop(ctx);

                // رسالة نجاح
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n?.expenseAddedSuccess ?? 'تم إضافة المصروف بنجاح'),
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
                    content: Text('${l10n?.errorOccurred ?? "حدث خطأ"}: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            icon: const Icon(Icons.save),
            label: Text(l10n?.save ?? 'حفظ'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 📋 نافذة تفاصيل المصروف - Expense Details Dialog
  // ============================================================================
  
  /// دالة لعرض نافذة حوار بتفاصيل المصروف الكاملة
  /// 
  /// **المعاملات:**
  /// - expense: Map يحتوي على بيانات المصروف
  /// 
  /// **البيانات المعروضة:**
  /// - الوصف
  /// - المبلغ (باللون الأحمر)
  /// - الفئة
  /// - التاريخ
  /// - الملاحظات (إن وجدت)
  void _showExpenseDetails(Map<String, dynamic> expense) {
    final l10n = AppLocalizations.of(context);
    
    // Hint: استخراج البيانات من Map
    final amount = expense['Amount'] as Decimal;
    final description = expense['Description'] as String;
    final category = expense['Category'] as String?;
    final date = DateTime.parse(expense['ExpenseDate'] as String);
    final notes = expense['Notes'] as String?;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        // --- عنوان النافذة ---
        title: Row(
          children: [
            const Icon(Icons.receipt_long, size: 28),
            const SizedBox(width: 12),
            Text(l10n?.expenseDetails ?? 'تفاصيل المصروف'),
          ],
        ),
        
        // --- محتوى التفاصيل ---
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الوصف
            _buildDetailRow(
              icon: Icons.description_outlined,
              label: l10n?.description ?? 'الوصف',
              value: description,
            ),

            const Divider(height: 24),

            // المبلغ
            _buildDetailRow(
              icon: Icons.attach_money,
              label: l10n?.amount ?? 'المبلغ',
              value: formatCurrency(amount),
              valueColor: AppColors.error,
            ),

            const Divider(height: 24),

            // الفئة
            _buildDetailRow(
              icon: Icons.category_outlined,
              label: l10n?.category ?? 'الفئة',
              value: category ?? (l10n?.unclassified ?? 'غير مصنف'),
            ),

            const Divider(height: 24),

            // التاريخ
            _buildDetailRow(
              icon: Icons.calendar_today_outlined,
              label: l10n?.date ?? 'التاريخ',
              value: DateFormat('yyyy-MM-dd').format(date),
            ),

            // الملاحظات (إن وجدت)
            if (notes != null && notes.isNotEmpty) ...[
              const Divider(height: 24),
              _buildDetailRow(
                icon: Icons.note_outlined,
                label: l10n?.notes ?? 'الملاحظات',
                value: notes,
              ),
            ],
          ],
        ),
        
        // --- زر الإغلاق ---
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n?.close ?? 'إغلاق'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 🧩 صف تفصيلي موحد - Detail Row Widget
  // ============================================================================
  
  /// Widget مساعد لعرض صف تفصيلي (Label + Value + Icon)
  /// 
  /// **الاستخدام:**
  /// يُستخدم في نافذة تفاصيل المصروف لعرض كل حقل بشكل موحد
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- الأيقونة ---
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        
        // --- Label والقيمة ---
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label (عنوان الحقل)
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              
              // Value (القيمة الفعلية)
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