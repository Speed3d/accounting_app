// lib/screens/products/manage_categories_units_screen.dart

import 'package:flutter/material.dart';
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_state.dart';

/// 🎨 شاشة إدارة التصنيفات والوحدات
/// ← Hint: تتيح إضافة وتعديل وحذف التصنيفات والوحدات للمنتجات
class ManageCategoriesUnitsScreen extends StatefulWidget {
  const ManageCategoriesUnitsScreen({super.key});

  @override
  State<ManageCategoriesUnitsScreen> createState() => _ManageCategoriesUnitsScreenState();
}

class _ManageCategoriesUnitsScreenState extends State<ManageCategoriesUnitsScreen>
    with SingleTickerProviderStateMixin {
  // ============= المتغيرات =============
  final dbHelper = DatabaseHelper.instance;
  late TabController _tabController;
  late Future<List<ProductCategory>> _categoriesFuture;
  late Future<List<ProductUnit>> _unitsFuture;

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

  /// إعادة تحميل البيانات
  /// ← Hint: يتم استدعاؤها عند التهيئة وبعد كل عملية إضافة/تعديل/حذف
  void _reloadData() {
    setState(() {
      _categoriesFuture = dbHelper.getProductCategories();
      _unitsFuture = dbHelper.getProductUnits();
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
        title: const Text('إدارة التصنيفات والوحدات'),
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
                  icon: Icon(Icons.category_outlined, size: 20),
                  text: 'التصنيفات',
                ),
                Tab(
                  icon: Icon(Icons.straighten_outlined, size: 20),
                  text: 'الوحدات',
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
          _buildCategoriesTab(l10n),
          _buildUnitsTab(l10n),
        ],
      ),
    );
  }

  // ============================================================
  // 🏷️ تبويب التصنيفات
  // ============================================================
  Widget _buildCategoriesTab(AppLocalizations l10n) {
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
              icon: Icons.category_outlined,
              title: 'لا توجد تصنيفات',
              message: 'لم يتم إضافة أي تصنيفات بعد',
              actionText: 'إضافة تصنيف',
              onAction: _showAddCategoryDialog,
            );
          }

          // عرض القائمة
          final categories = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryCard(category, l10n);
            },
          );
        },
      ),

      // ← Hint: زر الإضافة
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCategoryDialog,
        icon: const Icon(Icons.add),
        label: const Text('إضافة تصنيف'),
        tooltip: 'إضافة تصنيف جديد',
      ),
    );
  }

  /// بناء بطاقة تصنيف
  /// ← Hint: تعرض معلومات التصنيف مع أزرار تعديل وحذف
  Widget _buildCategoryCard(ProductCategory category, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = category.isActive;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: Padding(
        padding: AppConstants.paddingMd,
        child: Column(
          children: [
            Row(
              children: [
                // أيقونة التصنيف
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingMd),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.textSecondaryLight.withOpacity(0.1),
                    borderRadius: AppConstants.borderRadiusMd,
                  ),
                  child: Icon(
                    _getIconFromName(category.iconName),
                    color: isActive ? AppColors.success : AppColors.textSecondaryLight,
                    size: 28,
                  ),
                ),

                const SizedBox(width: AppConstants.spacingMd),

                // المعلومات
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // الاسم بالعربي
                      Text(
                        category.categoryNameAr,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),

                      const SizedBox(height: AppConstants.spacingXs),

                      // الاسم بالإنجليزي
                      Text(
                        category.categoryName,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

                // حالة التفعيل
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingSm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: AppConstants.borderRadiusFull,
                  ),
                  child: Text(
                    isActive ? 'نشط' : 'غير نشط',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive ? AppColors.success : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),

            // ← Hint: أزرار التعديل والحذف
            const Divider(height: AppConstants.spacingLg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showEditCategoryDialog(category),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('تعديل'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.info,
                    minimumSize: const Size(80, 32),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                OutlinedButton.icon(
                  onPressed: () => _toggleCategoryStatus(category),
                  icon: Icon(
                    isActive ? Icons.visibility_off : Icons.visibility,
                    size: 16,
                  ),
                  label: Text(isActive ? 'تعطيل' : 'تفعيل'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isActive ? AppColors.error : AppColors.success,
                    minimumSize: const Size(80, 32),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 📏 تبويب الوحدات
  // ============================================================
  Widget _buildUnitsTab(AppLocalizations l10n) {
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
              icon: Icons.straighten_outlined,
              title: 'لا توجد وحدات',
              message: 'لم يتم إضافة أي وحدات بعد',
              actionText: 'إضافة وحدة',
              onAction: _showAddUnitDialog,
            );
          }

          // عرض القائمة
          final units = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            itemCount: units.length,
            itemBuilder: (context, index) {
              final unit = units[index];
              return _buildUnitCard(unit, l10n);
            },
          );
        },
      ),

      // ← Hint: زر الإضافة
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUnitDialog,
        icon: const Icon(Icons.add),
        label: const Text('إضافة وحدة'),
        tooltip: 'إضافة وحدة جديدة',
      ),
    );
  }

  /// بناء بطاقة وحدة
  /// ← Hint: تعرض معلومات الوحدة مع أزرار تعديل وحذف
  Widget _buildUnitCard(ProductUnit unit, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = unit.isActive;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: Padding(
        padding: AppConstants.paddingMd,
        child: Column(
          children: [
            Row(
              children: [
                // أيقونة الوحدة
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingMd),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.info.withOpacity(0.1)
                        : AppColors.textSecondaryLight.withOpacity(0.1),
                    borderRadius: AppConstants.borderRadiusMd,
                  ),
                  child: Icon(
                    Icons.straighten,
                    color: isActive ? AppColors.info : AppColors.textSecondaryLight,
                    size: 28,
                  ),
                ),

                const SizedBox(width: AppConstants.spacingMd),

                // المعلومات
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // الاسم بالعربي
                      Text(
                        unit.unitNameAr,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),

                      const SizedBox(height: AppConstants.spacingXs),

                      // الاسم بالإنجليزي
                      Text(
                        unit.unitName,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

                // حالة التفعيل
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingSm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: AppConstants.borderRadiusFull,
                  ),
                  child: Text(
                    isActive ? 'نشط' : 'غير نشط',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive ? AppColors.success : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),

            // ← Hint: أزرار التعديل والحذف
            const Divider(height: AppConstants.spacingLg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showEditUnitDialog(unit),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('تعديل'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.info,
                    minimumSize: const Size(80, 32),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                OutlinedButton.icon(
                  onPressed: () => _toggleUnitStatus(unit),
                  icon: Icon(
                    isActive ? Icons.visibility_off : Icons.visibility,
                    size: 16,
                  ),
                  label: Text(isActive ? 'تعطيل' : 'تفعيل'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isActive ? AppColors.error : AppColors.success,
                    minimumSize: const Size(80, 32),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🎨 دوال إدارة التصنيفات
  // ============================================================

  /// عرض dialog لإضافة تصنيف جديد
  Future<void> _showAddCategoryDialog() async {
    final nameArController = TextEditingController();
    final nameEnController = TextEditingController();
    String selectedIcon = 'category';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.category, color: AppColors.success),
                  SizedBox(width: AppConstants.spacingSm),
                  Text('إضافة تصنيف جديد'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // الاسم بالعربي
                    TextField(
                      controller: nameArController,
                      decoration: const InputDecoration(
                        labelText: 'الاسم بالعربي *',
                        prefixIcon: Icon(Icons.text_fields),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: AppConstants.spacingMd),

                    // الاسم بالإنجليزي
                    TextField(
                      controller: nameEnController,
                      decoration: const InputDecoration(
                        labelText: 'الاسم بالإنجليزي *',
                        prefixIcon: Icon(Icons.text_fields),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: AppConstants.spacingMd),

                    // اختيار الأيقونة
                    DropdownButtonFormField<String>(
                      value: selectedIcon,
                      decoration: const InputDecoration(
                        labelText: 'الأيقونة',
                        prefixIcon: Icon(Icons.insert_emoticon),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'category', child: Row(children: [Icon(Icons.category), SizedBox(width: 8), Text('تصنيف')])),
                        DropdownMenuItem(value: 'shopping_bag', child: Row(children: [Icon(Icons.shopping_bag), SizedBox(width: 8), Text('حقيبة')])),
                        DropdownMenuItem(value: 'devices', child: Row(children: [Icon(Icons.devices), SizedBox(width: 8), Text('أجهزة')])),
                        DropdownMenuItem(value: 'checkroom', child: Row(children: [Icon(Icons.checkroom), SizedBox(width: 8), Text('ملابس')])),
                        DropdownMenuItem(value: 'restaurant', child: Row(children: [Icon(Icons.restaurant), SizedBox(width: 8), Text('طعام')])),
                        DropdownMenuItem(value: 'build', child: Row(children: [Icon(Icons.build), SizedBox(width: 8), Text('أدوات')])),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedIcon = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameArController.text.isEmpty || nameEnController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يرجى إدخال جميع الحقول المطلوبة')),
                      );
                      return;
                    }

                    try {
                      await dbHelper.insertProductCategory(
                        ProductCategory(
                          categoryName: nameEnController.text,
                          categoryNameAr: nameArController.text,
                          iconName: selectedIcon,
                          isActive: true,
                        ),
                      );
                      Navigator.pop(ctx, true);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('خطأ: $e')),
                      );
                    }
                  },
                  child: const Text('حفظ'),
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
        const SnackBar(content: Text('تم إضافة التصنيف بنجاح')),
      );
    }
  }

  /// عرض dialog لتعديل تصنيف
  Future<void> _showEditCategoryDialog(ProductCategory category) async {
    final nameArController = TextEditingController(text: category.categoryNameAr);
    final nameEnController = TextEditingController(text: category.categoryName);
    String selectedIcon = category.iconName ?? 'category';

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
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameArController,
                      decoration: const InputDecoration(
                        labelText: 'الاسم بالعربي *',
                        prefixIcon: Icon(Icons.text_fields),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    TextField(
                      controller: nameEnController,
                      decoration: const InputDecoration(
                        labelText: 'الاسم بالإنجليزي *',
                        prefixIcon: Icon(Icons.text_fields),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    DropdownButtonFormField<String>(
                      value: selectedIcon,
                      decoration: const InputDecoration(
                        labelText: 'الأيقونة',
                        prefixIcon: Icon(Icons.insert_emoticon),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'category', child: Row(children: [Icon(Icons.category), SizedBox(width: 8), Text('تصنيف')])),
                        DropdownMenuItem(value: 'shopping_bag', child: Row(children: [Icon(Icons.shopping_bag), SizedBox(width: 8), Text('حقيبة')])),
                        DropdownMenuItem(value: 'devices', child: Row(children: [Icon(Icons.devices), SizedBox(width: 8), Text('أجهزة')])),
                        DropdownMenuItem(value: 'checkroom', child: Row(children: [Icon(Icons.checkroom), SizedBox(width: 8), Text('ملابس')])),
                        DropdownMenuItem(value: 'restaurant', child: Row(children: [Icon(Icons.restaurant), SizedBox(width: 8), Text('طعام')])),
                        DropdownMenuItem(value: 'build', child: Row(children: [Icon(Icons.build), SizedBox(width: 8), Text('أدوات')])),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedIcon = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameArController.text.isEmpty || nameEnController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يرجى إدخال جميع الحقول المطلوبة')),
                      );
                      return;
                    }

                    try {
                      await dbHelper.updateProductCategory(
                        category.copyWith(
                          categoryName: nameEnController.text,
                          categoryNameAr: nameArController.text,
                          iconName: selectedIcon,
                        ),
                      );
                      Navigator.pop(ctx, true);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('خطأ: $e')),
                      );
                    }
                  },
                  child: const Text('حفظ'),
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

  /// تبديل حالة تفعيل التصنيف
  Future<void> _toggleCategoryStatus(ProductCategory category) async {
    try {
      await dbHelper.updateProductCategory(
        category.copyWith(isActive: !category.isActive),
      );
      _reloadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(category.isActive ? 'تم تعطيل التصنيف' : 'تم تفعيل التصنيف'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e')),
      );
    }
  }

  // ============================================================
  // 📏 دوال إدارة الوحدات
  // ============================================================

  /// عرض dialog لإضافة وحدة جديدة
  Future<void> _showAddUnitDialog() async {
    final nameArController = TextEditingController();
    final nameEnController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.straighten, color: AppColors.success),
              SizedBox(width: AppConstants.spacingSm),
              Text('إضافة وحدة جديدة'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // الاسم بالعربي
              TextField(
                controller: nameArController,
                decoration: const InputDecoration(
                  labelText: 'الاسم بالعربي *',
                  hintText: 'مثال: قطعة، كيلو، متر',
                  prefixIcon: Icon(Icons.text_fields),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: AppConstants.spacingMd),

              // الاسم بالإنجليزي
              TextField(
                controller: nameEnController,
                decoration: const InputDecoration(
                  labelText: 'الاسم بالإنجليزي *',
                  hintText: 'Example: piece, kg, meter',
                  prefixIcon: Icon(Icons.text_fields),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameArController.text.isEmpty || nameEnController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى إدخال جميع الحقول المطلوبة')),
                  );
                  return;
                }

                try {
                  await dbHelper.insertProductUnit(
                    ProductUnit(
                      unitName: nameEnController.text,
                      unitNameAr: nameArController.text,
                      isActive: true,
                    ),
                  );
                  Navigator.pop(ctx, true);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ: $e')),
                  );
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );

    if (result == true && mounted) {
      _reloadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إضافة الوحدة بنجاح')),
      );
    }
  }

  /// عرض dialog لتعديل وحدة
  Future<void> _showEditUnitDialog(ProductUnit unit) async {
    final nameArController = TextEditingController(text: unit.unitNameAr);
    final nameEnController = TextEditingController(text: unit.unitName);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
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
              TextField(
                controller: nameArController,
                decoration: const InputDecoration(
                  labelText: 'الاسم بالعربي *',
                  prefixIcon: Icon(Icons.text_fields),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              TextField(
                controller: nameEnController,
                decoration: const InputDecoration(
                  labelText: 'الاسم بالإنجليزي *',
                  prefixIcon: Icon(Icons.text_fields),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameArController.text.isEmpty || nameEnController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى إدخال جميع الحقول المطلوبة')),
                  );
                  return;
                }

                try {
                  await dbHelper.updateProductUnit(
                    unit.copyWith(
                      unitName: nameEnController.text,
                      unitNameAr: nameArController.text,
                    ),
                  );
                  Navigator.pop(ctx, true);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ: $e')),
                  );
                }
              },
              child: const Text('حفظ'),
            ),
          ],
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

  /// تبديل حالة تفعيل الوحدة
  Future<void> _toggleUnitStatus(ProductUnit unit) async {
    try {
      await dbHelper.updateProductUnit(
        unit.copyWith(isActive: !unit.isActive),
      );
      _reloadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(unit.isActive ? 'تم تعطيل الوحدة' : 'تم تفعيل الوحدة'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e')),
      );
    }
  }

  // ============================================================
  // 🛠️ دوال مساعدة
  // ============================================================

  /// الحصول على الأيقونة من اسمها
  /// ← Hint: يحول اسم الأيقونة (String) إلى IconData
  IconData _getIconFromName(String? iconName) {
    switch (iconName) {
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'devices':
        return Icons.devices;
      case 'checkroom':
        return Icons.checkroom;
      case 'restaurant':
        return Icons.restaurant;
      case 'build':
        return Icons.build;
      default:
        return Icons.category;
    }
  }
}
