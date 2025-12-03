// lib/screens/settings/product_settings_screen.dart

import 'package:flutter/material.dart';
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_state.dart';

/// ⚙️ شاشة إعدادات المنتجات - صفحة فرعية
/// ← Hint: تتيح إدارة الوحدات والتصنيفات للمنتجات
/// ← Hint: تحتوي على تابات للوحدات والتصنيفات مع إمكانية الإضافة/التعديل/الحذف
class ProductSettingsScreen extends StatefulWidget {
  const ProductSettingsScreen({super.key});

  @override
  State<ProductSettingsScreen> createState() => _ProductSettingsScreenState();
}

class _ProductSettingsScreenState extends State<ProductSettingsScreen>
    with SingleTickerProviderStateMixin {
  // ============= المتغيرات =============
  final dbHelper = DatabaseHelper.instance;
  late TabController _tabController;
  late Future<List<ProductUnit>> _unitsFuture;
  late Future<List<ProductCategory>> _categoriesFuture;

  // ============= دورة الحياة =============
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _reloadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// ← Hint: إعادة تحميل البيانات
  void _reloadData() {
    setState(() {
      _unitsFuture = dbHelper.getProductUnits(activeOnly: false);
      _categoriesFuture = dbHelper.getProductCategories(activeOnly: false);
    });
  }

  // ============= بناء الواجهة =============
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // ============= AppBar مع TabBar =============
      appBar: AppBar(
        title: const Text('إعدادات المنتجات'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.borderDark : Colors.white24,
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: isDark ? AppColors.primaryDark : Colors.white,
              unselectedLabelColor: isDark
                  ? AppColors.textSecondaryDark
                  : Colors.white70,
              indicatorColor: isDark ? AppColors.primaryDark : Colors.white,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(
                  icon: Icon(Icons.straighten, size: 20),
                  text: 'الوحدات',
                ),
                Tab(
                  icon: Icon(Icons.category, size: 20),
                  text: 'التصنيفات',
                ),
              ],
            ),
          ),
        ),
      ),

      // ============= Body =============
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUnitsTab(l10n, isDark),
          _buildCategoriesTab(l10n, isDark),
        ],
      ),
    );
  }

  // ============================================================
  // 📏 تبويب الوحدات
  // ============================================================
  Widget _buildUnitsTab(AppLocalizations l10n, bool isDark) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<List<ProductUnit>>(
        future: _unitsFuture,
        builder: (context, snapshot) {
          // حالة التحميل
          if (snapshot.connectionState == ConnectionState.waiting) {
            return LoadingState(message: l10n.loadingMessage);
          }

          // حالة الخطأ
          if (snapshot.hasError) {
            return ErrorState(
              message: snapshot.error.toString(),
              onRetry: _reloadData,
            );
          }

          // حالة الفراغ
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyState(
              icon: Icons.straighten,
              title: 'لا توجد وحدات',
              message: 'لم يتم إضافة أي وحدات قياس بعد',
              actionText: 'إضافة وحدة',
              onAction: () => _showAddUnitDialog(l10n),
            );
          }

          // عرض القائمة
          final units = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            itemCount: units.length,
            itemBuilder: (context, index) {
              final unit = units[index];
              return _buildUnitCard(unit, l10n, isDark);
            },
          );
        },
      ),

      // ← Hint: زر الإضافة
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUnitDialog(l10n),
        icon: const Icon(Icons.add),
        label: const Text('إضافة وحدة'),
        tooltip: 'إضافة وحدة قياس جديدة',
      ),
    );
  }

  /// ← Hint: بناء بطاقة وحدة قياس
  Widget _buildUnitCard(ProductUnit unit, AppLocalizations l10n, bool isDark) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: Padding(
        padding: AppConstants.paddingMd,
        child: Row(
          children: [
            // أيقونة
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              decoration: BoxDecoration(
                color: unit.isActive
                    ? AppColors.info.withOpacity(0.1)
                    : AppColors.error.withOpacity(0.1),
                borderRadius: AppConstants.borderRadiusMd,
              ),
              child: Icon(
                Icons.straighten,
                color: unit.isActive ? AppColors.info : AppColors.error,
                size: 28,
              ),
            ),

            const SizedBox(width: AppConstants.spacingMd),

            // المعلومات
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unit.unitNameAr,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppConstants.spacingXs),
                  Text(
                    unit.unitName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (!unit.isActive) ...[
                    const SizedBox(height: AppConstants.spacingXs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingSm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: AppConstants.borderRadiusFull,
                      ),
                      child: const Text(
                        'غير نشط',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // أزرار التعديل والحذف
            Row(
              children: [
                IconButton(
                  onPressed: () => _showEditUnitDialog(unit, l10n),
                  icon: const Icon(Icons.edit, size: 20),
                  color: AppColors.info,
                  tooltip: 'تعديل',
                ),
                IconButton(
                  onPressed: () => _showDeleteUnitDialog(unit, l10n),
                  icon: const Icon(Icons.delete, size: 20),
                  color: AppColors.error,
                  tooltip: 'حذف',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 📂 تبويب التصنيفات
  // ============================================================
  Widget _buildCategoriesTab(AppLocalizations l10n, bool isDark) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<List<ProductCategory>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          // حالة التحميل
          if (snapshot.connectionState == ConnectionState.waiting) {
            return LoadingState(message: l10n.loadingMessage);
          }

          // حالة الخطأ
          if (snapshot.hasError) {
            return ErrorState(
              message: snapshot.error.toString(),
              onRetry: _reloadData,
            );
          }

          // حالة الفراغ
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyState(
              icon: Icons.category,
              title: 'لا توجد تصنيفات',
              message: 'لم يتم إضافة أي تصنيفات بعد',
              actionText: 'إضافة تصنيف',
              onAction: () => _showAddCategoryDialog(l10n),
            );
          }

          // عرض القائمة
          final categories = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryCard(category, l10n, isDark);
            },
          );
        },
      ),

      // ← Hint: زر الإضافة
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(l10n),
        icon: const Icon(Icons.add),
        label: const Text('إضافة تصنيف'),
        tooltip: 'إضافة تصنيف جديد',
      ),
    );
  }

  /// ← Hint: بناء بطاقة تصنيف
  Widget _buildCategoryCard(
      ProductCategory category, AppLocalizations l10n, bool isDark) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: Padding(
        padding: AppConstants.paddingMd,
        child: Row(
          children: [
            // أيقونة
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              decoration: BoxDecoration(
                color: category.isActive
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.error.withOpacity(0.1),
                borderRadius: AppConstants.borderRadiusMd,
              ),
              child: Icon(
                Icons.category,
                color: category.isActive ? AppColors.success : AppColors.error,
                size: 28,
              ),
            ),

            const SizedBox(width: AppConstants.spacingMd),

            // المعلومات
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.categoryNameAr,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppConstants.spacingXs),
                  Text(
                    category.categoryName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (!category.isActive) ...[
                    const SizedBox(height: AppConstants.spacingXs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingSm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: AppConstants.borderRadiusFull,
                      ),
                      child: const Text(
                        'غير نشط',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // أزرار التعديل والحذف
            Row(
              children: [
                IconButton(
                  onPressed: () => _showEditCategoryDialog(category, l10n),
                  icon: const Icon(Icons.edit, size: 20),
                  color: AppColors.info,
                  tooltip: 'تعديل',
                ),
                IconButton(
                  onPressed: () => _showDeleteCategoryDialog(category, l10n),
                  icon: const Icon(Icons.delete, size: 20),
                  color: AppColors.error,
                  tooltip: 'حذف',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 📏 دوال إدارة الوحدات
  // ============================================================

  /// ← Hint: عرض dialog لإضافة وحدة جديدة
  Future<void> _showAddUnitDialog(AppLocalizations l10n) async {
    final nameArController = TextEditingController();
    final nameEnController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.straighten, color: AppColors.info),
            SizedBox(width: AppConstants.spacingSm),
            Text('إضافة وحدة قياس'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // الاسم بالعربية
            TextField(
              controller: nameArController,
              decoration: const InputDecoration(
                labelText: 'الاسم بالعربية *',
                prefixIcon: Icon(Icons.translate),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // الاسم بالإنجليزية
            TextField(
              controller: nameEnController,
              decoration: const InputDecoration(
                labelText: 'الاسم بالإنجليزية *',
                prefixIcon: Icon(Icons.translate),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameArController.text.isEmpty ||
                  nameEnController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى إدخال جميع الحقول')),
                );
                return;
              }

              try {
                final unit = ProductUnit(
                  unitNameAr: nameArController.text.trim(),
                  unitName: nameEnController.text.trim(),
                );
                await dbHelper.addProductUnit(unit);
                Navigator.pop(ctx, true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('خطأ: $e')),
                );
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      _reloadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إضافة الوحدة بنجاح')),
      );
    }
  }

  /// ← Hint: عرض dialog لتعديل وحدة
  Future<void> _showEditUnitDialog(
      ProductUnit unit, AppLocalizations l10n) async {
    final nameArController = TextEditingController(text: unit.unitNameAr);
    final nameEnController = TextEditingController(text: unit.unitName);
    bool isActive = unit.isActive;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.edit, color: AppColors.info),
                  SizedBox(width: AppConstants.spacingSm),
                  Text('تعديل الوحدة'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // الاسم بالعربية
                  TextField(
                    controller: nameArController,
                    decoration: const InputDecoration(
                      labelText: 'الاسم بالعربية *',
                      prefixIcon: Icon(Icons.translate),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingMd),

                  // الاسم بالإنجليزية
                  TextField(
                    controller: nameEnController,
                    decoration: const InputDecoration(
                      labelText: 'الاسم بالإنجليزية *',
                      prefixIcon: Icon(Icons.translate),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingMd),

                  // حالة النشاط
                  SwitchListTile(
                    title: const Text('نشط'),
                    value: isActive,
                    onChanged: (value) {
                      setState(() => isActive = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameArController.text.isEmpty ||
                        nameEnController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يرجى إدخال جميع الحقول')),
                      );
                      return;
                    }

                    try {
                      final updatedUnit = ProductUnit(
                        unitID: unit.unitID,
                        unitNameAr: nameArController.text.trim(),
                        unitName: nameEnController.text.trim(),
                        isActive: isActive,
                      );
                      await dbHelper.editProductUnit(updatedUnit);
                      Navigator.pop(ctx, true);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('خطأ: $e')),
                      );
                    }
                  },
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      _reloadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تعديل الوحدة بنجاح')),
      );
    }
  }

  /// ← Hint: عرض dialog لحذف وحدة
  Future<void> _showDeleteUnitDialog(
      ProductUnit unit, AppLocalizations l10n) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.error),
            SizedBox(width: AppConstants.spacingSm),
            Text('تأكيد الحذف'),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف وحدة "${unit.unitNameAr}"؟\nقد يؤثر ذلك على المنتجات المرتبطة بها.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await dbHelper.deleteProductUnit(unit.unitID!);
                Navigator.pop(ctx, true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('خطأ: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      _reloadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الوحدة بنجاح')),
      );
    }
  }

  // ============================================================
  // 📂 دوال إدارة التصنيفات
  // ============================================================

  /// ← Hint: عرض dialog لإضافة تصنيف جديد
  Future<void> _showAddCategoryDialog(AppLocalizations l10n) async {
    final nameArController = TextEditingController();
    final nameEnController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.category, color: AppColors.success),
            SizedBox(width: AppConstants.spacingSm),
            Text('إضافة تصنيف'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // الاسم بالعربية
            TextField(
              controller: nameArController,
              decoration: const InputDecoration(
                labelText: 'الاسم بالعربية *',
                prefixIcon: Icon(Icons.translate),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // الاسم بالإنجليزية
            TextField(
              controller: nameEnController,
              decoration: const InputDecoration(
                labelText: 'الاسم بالإنجليزية *',
                prefixIcon: Icon(Icons.translate),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameArController.text.isEmpty ||
                  nameEnController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى إدخال جميع الحقول')),
                );
                return;
              }

              try {
                final category = ProductCategory(
                  categoryNameAr: nameArController.text.trim(),
                  categoryName: nameEnController.text.trim(),
                );
                await dbHelper.addProductCategory(category);
                Navigator.pop(ctx, true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('خطأ: $e')),
                );
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      _reloadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إضافة التصنيف بنجاح')),
      );
    }
  }

  /// ← Hint: عرض dialog لتعديل تصنيف
  Future<void> _showEditCategoryDialog(
      ProductCategory category, AppLocalizations l10n) async {
    final nameArController =
        TextEditingController(text: category.categoryNameAr);
    final nameEnController =
        TextEditingController(text: category.categoryName);
    bool isActive = category.isActive;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.edit, color: AppColors.info),
                  SizedBox(width: AppConstants.spacingSm),
                  Text('تعديل التصنيف'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // الاسم بالعربية
                  TextField(
                    controller: nameArController,
                    decoration: const InputDecoration(
                      labelText: 'الاسم بالعربية *',
                      prefixIcon: Icon(Icons.translate),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingMd),

                  // الاسم بالإنجليزية
                  TextField(
                    controller: nameEnController,
                    decoration: const InputDecoration(
                      labelText: 'الاسم بالإنجليزية *',
                      prefixIcon: Icon(Icons.translate),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingMd),

                  // حالة النشاط
                  SwitchListTile(
                    title: const Text('نشط'),
                    value: isActive,
                    onChanged: (value) {
                      setState(() => isActive = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameArController.text.isEmpty ||
                        nameEnController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يرجى إدخال جميع الحقول')),
                      );
                      return;
                    }

                    try {
                      final updatedCategory = ProductCategory(
                        categoryID: category.categoryID,
                        categoryNameAr: nameArController.text.trim(),
                        categoryName: nameEnController.text.trim(),
                        isActive: isActive,
                      );
                      await dbHelper.editProductCategory(updatedCategory);
                      Navigator.pop(ctx, true);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('خطأ: $e')),
                      );
                    }
                  },
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      _reloadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تعديل التصنيف بنجاح')),
      );
    }
  }

  /// ← Hint: عرض dialog لحذف تصنيف
  Future<void> _showDeleteCategoryDialog(
      ProductCategory category, AppLocalizations l10n) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.error),
            SizedBox(width: AppConstants.spacingSm),
            Text('تأكيد الحذف'),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف تصنيف "${category.categoryNameAr}"؟\nقد يؤثر ذلك على المنتجات المرتبطة به.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await dbHelper.deleteProductCategory(category.categoryID!);
                Navigator.pop(ctx, true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('خطأ: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      _reloadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف التصنيف بنجاح')),
      );
    }
  }
}
