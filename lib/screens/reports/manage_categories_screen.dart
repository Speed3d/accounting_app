// lib/screens/reports/manage_categories_screen.dart

import 'package:flutter/material.dart';
import '../../data/database_helper.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_state.dart';

/// 📂 شاشة إدارة فئات المصاريف
/// ---------------------------
/// صفحة فرعية تتيح:
/// 1. عرض جميع فئات المصاريف
/// 2. إضافة فئة جديدة
/// 3. تعديل فئة موجودة
/// 4. حذف فئة
class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  // ============= المتغيرات =============
  final dbHelper = DatabaseHelper.instance;
  late Future<List<Map<String, dynamic>>> _categoriesFuture;

  // ============= التهيئة =============
  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  /// تحميل قائمة الفئات من قاعدة البيانات
  void _loadCategories() {
    setState(() {
      _categoriesFuture = dbHelper.getExpenseCategories();
    });
  }

  // ============= البناء الرئيسي =============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- AppBar بسيط ---
      appBar: AppBar(
        title: const Text('إدارة فئات المصاريف'),
        elevation: 0,
      ),

      // --- الجسم: قائمة الفئات ---
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          // --- حالة التحميل ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState(message: 'جاري تحميل الفئات...');
          }

          // --- حالة الخطأ ---
          if (snapshot.hasError) {
            return ErrorState(
              message: 'حدث خطأ أثناء تحميل البيانات',
              onRetry: _loadCategories,
            );
          }

          // --- حالة عدم وجود فئات ---
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyState(
              icon: Icons.category_outlined,
              title: 'لا توجد فئات',
              message: 'لم يتم إضافة أي فئة للمصاريف حتى الآن',
              actionText: 'إضافة فئة',
              onAction: () => _showCategoryDialog(),
            );
          }

          // --- عرض قائمة الفئات ---
          final categories = snapshot.data!;

          return ListView.builder(
            padding: AppConstants.screenPadding,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryCard(category);
            },
          );
        },
      ),

      // --- زر الإضافة العائم ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(),
        icon: const Icon(Icons.add),
        label: const Text('إضافة فئة'),
        tooltip: 'إضافة فئة جديدة',
      ),
    );
  }

  // ============= بناء بطاقة الفئة =============
  /// يعرض كل فئة في بطاقة مع أزرار التعديل والحذف
  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final categoryId = category['CategoryID'] as int;
    final categoryName = category['CategoryName'] as String;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: ListTile(
        contentPadding: AppConstants.listTilePadding,
        
        // --- أيقونة الفئة ---
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.1),
            borderRadius: AppConstants.borderRadiusMd,
          ),
          child: Icon(
            Icons.label,
            color: AppColors.primaryLight,
            size: 24,
          ),
        ),

        // --- اسم الفئة ---
        title: Text(
          categoryName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),

        // --- أزرار التعديل والحذف ---
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // زر التعديل
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              color: AppColors.info,
              tooltip: 'تعديل',
              onPressed: () => _showCategoryDialog(
                existingCategory: category,
              ),
            ),

            // زر الحذف
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: AppColors.error,
              tooltip: 'حذف',
              onPressed: () => _handleDeleteCategory(
                categoryId,
                categoryName,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============= نافذة إضافة/تعديل فئة =============
  /// نافذة حوار لإضافة فئة جديدة أو تعديل فئة موجودة
  void _showCategoryDialog({Map<String, dynamic>? existingCategory}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(
      text: existingCategory?['CategoryName'],
    );
    final isEditing = existingCategory != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        // --- عنوان النافذة ---
        title: Row(
          children: [
            Icon(
              isEditing ? Icons.edit : Icons.add_circle_outline,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(isEditing ? 'تعديل الفئة' : 'إضافة فئة جديدة'),
          ],
        ),

        // --- محتوى النموذج ---
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- حقل اسم الفئة ---
              CustomTextField(
                controller: nameController,
                label: 'اسم الفئة',
                hint: 'مثال: فواتير، إيجار، صيانة',
                prefixIcon: Icons.label_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'اسم الفئة مطلوب';
                  }
                  return null;
                },
              ),
            ],
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

              try {
                final categoryName = nameController.text.trim();

                // --- حفظ أو تحديث الفئة ---
                if (isEditing) {
                  await dbHelper.updateExpenseCategory(
                    existingCategory['CategoryID'],
                    categoryName,
                  );
                } else {
                  await dbHelper.addExpenseCategory(categoryName);
                }

                if (!ctx.mounted) return;

                // إغلاق النافذة
                Navigator.pop(ctx);

                // رسالة نجاح
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEditing
                          ? 'تم تعديل الفئة بنجاح'
                          : 'تم إضافة الفئة بنجاح',
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );

                // تحديث القائمة
                _loadCategories();
              } catch (e) {
                // --- معالجة خطأ الفئة المكررة ---
                if (!ctx.mounted) return;

                Navigator.pop(ctx);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('هذه الفئة موجودة بالفعل'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              }
            },
            icon: Icon(isEditing ? Icons.check : Icons.save),
            label: Text(isEditing ? 'تحديث' : 'حفظ'),
          ),
        ],
      ),
    );
  }

  // ============= حذف فئة =============
  /// نافذة تأكيد حذف فئة
  void _handleDeleteCategory(int categoryId, String categoryName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        // --- أيقونة التحذير ---
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.warning,
          size: 48,
        ),

        // --- عنوان التأكيد ---
        title: const Text('تأكيد الحذف'),

        // --- رسالة التأكيد ---
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'هل أنت متأكد من حذف الفئة؟',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Container(
              padding: AppConstants.paddingMd,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: AppConstants.borderRadiusMd,
              ),
              child: Text(
                categoryName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              'سيتم حذف الفئة نهائياً ولن يمكن استرجاعها',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),

        // --- أزرار الإجراءات ---
        actions: [
          // زر الإلغاء
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),

          // زر الحذف
          ElevatedButton.icon(
            onPressed: () async {
              try {
                // --- حذف الفئة ---
                await dbHelper.deleteExpenseCategory(categoryId);

                if (!ctx.mounted) return;

                // إغلاق النافذة
                Navigator.pop(ctx);

                // رسالة نجاح
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف الفئة بنجاح'),
                    backgroundColor: AppColors.success,
                  ),
                );

                // تحديث القائمة
                _loadCategories();
              } catch (e) {
                // --- معالجة الخطأ ---
                if (!ctx.mounted) return;

                Navigator.pop(ctx);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('حدث خطأ: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.delete),
            label: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}