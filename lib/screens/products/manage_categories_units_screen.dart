// lib/screens/products/manage_categories_units_screen.dart

import 'package:flutter/material.dart';
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../services/translation_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_state.dart';

/// ============================================================================
/// 🎨 شاشة إدارة التصنيفات والوحدات (النسخة المبسطة)
/// ============================================================================
/// ← Hint: تتيح إضافة وتعديل وحذف التصنيفات والوحدات بطريقة بسيطة
/// ← Hint: لا ألوان، لا أيقونات، فقط اسم عربي + اسم إنجليزي
class ManageCategoriesUnitsScreen extends StatefulWidget {
  const ManageCategoriesUnitsScreen({super.key});

  @override
  State<ManageCategoriesUnitsScreen> createState() => _ManageCategoriesUnitsScreenState();
}

class _ManageCategoriesUnitsScreenState extends State<ManageCategoriesUnitsScreen>
    with SingleTickerProviderStateMixin {
  // ============= المتغيرات =============
  final dbHelper = DatabaseHelper.instance;
  final translationService = TranslationService();
  late TabController _tabController;
  late Future<List<ProductCategory>> _categoriesFuture;
  late Future<List<ProductUnit>> _unitsFuture;

  // ← Hint: حالة إظهار/إخفاء العناصر المعطلة
  bool _showInactiveCategories = false;
  bool _showInactiveUnits = false;

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
      // ← Hint: activeOnly معكوسة: true = نشطة فقط، false = الكل
      _categoriesFuture = dbHelper.getProductCategories(
        activeOnly: !_showInactiveCategories,
      );
      _unitsFuture = dbHelper.getProductUnits(
        activeOnly: !_showInactiveUnits,
      );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // ← Hint: Toggle لإظهار/إخفاء العناصر المعطلة
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingMd,
              vertical: AppConstants.spacingSm,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.cardDark.withOpacity(0.5)
                  : Colors.grey.shade100,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.borderDark : Colors.grey.shade300,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'إظهار التصنيفات المعطلة',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Switch(
                  value: _showInactiveCategories,
                  onChanged: (value) {
                    setState(() {
                      _showInactiveCategories = value;
                      _reloadData();
                    });
                  },
                  activeColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                ),
              ],
            ),
          ),

          // ← Hint: القائمة
          Expanded(
            child: FutureBuilder<List<ProductCategory>>(
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
              message: 'ابدأ بإضافة تصنيف جديد',
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
          ),
        ],
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

  /// ============================================================================
  /// 🃏 بناء بطاقة تصنيف (النسخة المبسطة)
  /// ============================================================================
  /// ← Hint: تعرض معلومات التصنيف مع أزرار تعديل وحذف
  /// ← Hint: بدون ألوان أو أيقونات - فقط الاسم العربي والإنجليزي
  Widget _buildCategoryCard(ProductCategory category, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = category.isActive;
    final languageCode = Localizations.localeOf(context).languageCode;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: Padding(
        padding: AppConstants.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============= الاسم المترجم (حسب اللغة الحالية) =============
            Row(
              children: [
                // ← Hint: أيقونة بسيطة موحدة
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingMd),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.info.withOpacity(0.1)
                        : AppColors.textSecondaryLight.withOpacity(0.1),
                    borderRadius: AppConstants.borderRadiusMd,
                  ),
                  child: Icon(
                    Icons.category,  // ← Hint: نفس الأيقونة للكل
                    color: isActive ? AppColors.info : AppColors.textSecondaryLight,
                    size: 28,
                  ),
                ),

                const SizedBox(width: AppConstants.spacingMd),

                // ← Hint: المعلومات
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ← Hint: الاسم حسب اللغة الحالية
                      Text(
                        category.getLocalizedName(languageCode),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),

                      const SizedBox(height: AppConstants.spacingXs),

                      // ← Hint: عرض الاسمين معاً
                      Text(
                        '${category.categoryNameAr} / ${category.categoryNameEn}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

                // ← Hint: حالة التفعيل
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
                    isActive ? 'نشط' : 'معطل',
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
                // ← Hint: زر التعديل
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
                
                // ← Hint: زر التعطيل/التفعيل
                OutlinedButton.icon(
                  onPressed: () => _toggleCategoryStatus(category),
                  icon: Icon(
                    isActive ? Icons.visibility_off : Icons.visibility,
                    size: 16,
                  ),
                  label: Text(isActive ? 'تعطيل' : 'تفعيل'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isActive ? AppColors.warning : AppColors.success,
                    minimumSize: const Size(80, 32),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                
                // ← Hint: زر الحذف (فقط إذا لم تكن مرتبطة بمنتجات)
                OutlinedButton.icon(
                  onPressed: () => _deleteCategoryPermanently(category),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('حذف'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // ← Hint: Toggle لإظهار/إخفاء العناصر المعطلة
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingMd,
              vertical: AppConstants.spacingSm,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.cardDark.withOpacity(0.5)
                  : Colors.grey.shade100,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.borderDark : Colors.grey.shade300,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'إظهار الوحدات المعطلة',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Switch(
                  value: _showInactiveUnits,
                  onChanged: (value) {
                    setState(() {
                      _showInactiveUnits = value;
                      _reloadData();
                    });
                  },
                  activeColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                ),
              ],
            ),
          ),

          // ← Hint: القائمة
          Expanded(
            child: FutureBuilder<List<ProductUnit>>(
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
              message: 'ابدأ بإضافة وحدة جديدة',
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
          ),
        ],
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

  /// ============================================================================
  /// 🃏 بناء بطاقة وحدة (النسخة المبسطة)
  /// ============================================================================
  /// ← Hint: تعرض معلومات الوحدة مع أزرار تعديل وحذف
  Widget _buildUnitCard(ProductUnit unit, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = unit.isActive;
    final languageCode = Localizations.localeOf(context).languageCode;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: Padding(
        padding: AppConstants.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // ← Hint: أيقونة بسيطة موحدة
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingMd),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.textSecondaryLight.withOpacity(0.1),
                    borderRadius: AppConstants.borderRadiusMd,
                  ),
                  child: Icon(
                    Icons.straighten,  // ← Hint: نفس الأيقونة للكل
                    color: isActive ? AppColors.success : AppColors.textSecondaryLight,
                    size: 28,
                  ),
                ),

                const SizedBox(width: AppConstants.spacingMd),

                // ← Hint: المعلومات
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ← Hint: الاسم حسب اللغة الحالية
                      Text(
                        unit.getLocalizedName(languageCode),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),

                      const SizedBox(height: AppConstants.spacingXs),

                      // ← Hint: عرض الاسمين معاً
                      Text(
                        '${unit.unitNameAr} / ${unit.unitNameEn}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

                // ← Hint: حالة التفعيل
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
                    isActive ? 'نشط' : 'معطل',
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
                    foregroundColor: isActive ? AppColors.warning : AppColors.success,
                    minimumSize: const Size(80, 32),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                OutlinedButton.icon(
                  onPressed: () => _deleteUnitPermanently(unit),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('حذف'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
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

  /// ============================================================================
  /// عرض dialog لإضافة تصنيف جديد (النسخة المبسطة)
  /// ============================================================================
  /// ← Hint: فقط اسمين: عربي + إنجليزي، بدون ألوان أو أيقونات
  Future<void> _showAddCategoryDialog() async {
    final nameArController = TextEditingController();
    final nameEnController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // ← Hint: متغيرات لتتبع حالة الترجمة والتعديل اليدوي
    bool isTranslating = false;
    bool userEditedAr = false;
    bool userEditedEn = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.category, color: AppColors.success),
                  SizedBox(width: AppConstants.spacingSm),
                  Text('إضافة تصنيف جديد'),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ← Hint: الاسم بالعربي (إجباري)
                    TextFormField(
                      controller: nameArController,
                      decoration: InputDecoration(
                        labelText: 'الاسم بالعربي *',
                        hintText: 'مثال: أجهزة كهربائية',
                        prefixIcon: const Icon(Icons.text_fields),
                        border: const OutlineInputBorder(),
                        suffixIcon: isTranslating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.translate, size: 20),
                                tooltip: 'ترجمة إلى الإنجليزية',
                                onPressed: () async {
                                  final text = nameArController.text.trim();
                                  if (text.isEmpty) return;

                                  setDialogState(() => isTranslating = true);

                                  final translated = await translationService.translateToEnglish(text);

                                  setDialogState(() => isTranslating = false);

                                  if (translated != null && !userEditedEn) {
                                    setDialogState(() {
                                      nameEnController.text = translated;
                                    });
                                  }
                                },
                              ),
                      ),
                      onChanged: (value) {
                        userEditedAr = true;
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال الاسم بالعربي';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppConstants.spacingMd),

                    // ← Hint: الاسم بالإنجليزي (إجباري)
                    TextFormField(
                      controller: nameEnController,
                      decoration: InputDecoration(
                        labelText: 'الاسم بالإنجليزي *',
                        hintText: 'Example: Electrical Appliances',
                        prefixIcon: const Icon(Icons.text_fields),
                        border: const OutlineInputBorder(),
                        suffixIcon: isTranslating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.translate, size: 20),
                                tooltip: 'ترجمة إلى العربية',
                                onPressed: () async {
                                  final text = nameEnController.text.trim();
                                  if (text.isEmpty) return;

                                  setDialogState(() => isTranslating = true);

                                  final translated = await translationService.translateToArabic(text);

                                  setDialogState(() => isTranslating = false);

                                  if (translated != null && !userEditedAr) {
                                    setDialogState(() {
                                      nameArController.text = translated;
                                    });
                                  }
                                },
                              ),
                      ),
                      onChanged: (value) {
                        userEditedEn = true;
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال الاسم بالإنجليزي';
                        }
                        return null;
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
                    if (formKey.currentState!.validate()) {
                      try {
                        await dbHelper.addProductCategory(
                          ProductCategory(
                            categoryNameAr: nameArController.text.trim(),
                            categoryNameEn: nameEnController.text.trim(),
                            isActive: true,
                          ),
                        );
                        Navigator.pop(ctx, true);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('خطأ: $e')),
                        );
                      }
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
        const SnackBar(
          content: Text('تم إضافة التصنيف بنجاح'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  /// ============================================================================
  /// عرض dialog لتعديل تصنيف (النسخة المبسطة)
  /// ============================================================================
  Future<void> _showEditCategoryDialog(ProductCategory category) async {
    final nameArController = TextEditingController(text: category.categoryNameAr);
    final nameEnController = TextEditingController(text: category.categoryNameEn);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.edit, color: AppColors.info),
              SizedBox(width: AppConstants.spacingSm),
              Text('تعديل التصنيف'),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameArController,
                  decoration: const InputDecoration(
                    labelText: 'الاسم بالعربي *',
                    prefixIcon: Icon(Icons.text_fields),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال الاسم بالعربي';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.spacingMd),
                TextFormField(
                  controller: nameEnController,
                  decoration: const InputDecoration(
                    labelText: 'الاسم بالإنجليزي *',
                    prefixIcon: Icon(Icons.text_fields),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال الاسم بالإنجليزي';
                    }
                    return null;
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
                if (formKey.currentState!.validate()) {
                  try {
                    await dbHelper.editProductCategory(
                      category.copyWith(
                        categoryNameAr: nameArController.text.trim(),
                        categoryNameEn: nameEnController.text.trim(),
                      ),
                    );
                    Navigator.pop(ctx, true);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطأ: $e')),
                    );
                  }
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
        const SnackBar(
          content: Text('تم تعديل التصنيف بنجاح'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  /// تبديل حالة تفعيل التصنيف
  /// ← Hint: تعطيل/تفعيل بدون حذف نهائي
  Future<void> _toggleCategoryStatus(ProductCategory category) async {
    try {
      await dbHelper.editProductCategory(
        category.copyWith(isActive: !category.isActive),
      );
      _reloadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(category.isActive ? 'تم تعطيل التصنيف' : 'تم تفعيل التصنيف'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  /// ============================================================================
  /// حذف تصنيف نهائياً (مع التحقق من عدم وجود منتجات مرتبطة)
  /// ============================================================================
  /// ← Hint: يتحقق أولاً من عدم وجود منتجات تستخدم هذا التصنيف
  Future<void> _deleteCategoryPermanently(ProductCategory category) async {
    // ← Hint: عد المنتجات المرتبطة بهذا التصنيف
    final productCount = await dbHelper.countProductsByCategory(category.categoryID!);

    if (productCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا يمكن حذف التصنيف لوجود $productCount منتج مرتبط به. قم بتغيير تصنيف المنتجات أولاً أو استخدم زر "تعطيل".',
          ),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    // ← Hint: تأكيد الحذف
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف التصنيف "${category.categoryNameAr}" نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // ← Hint: حذف نهائي من قاعدة البيانات
      final db = await dbHelper.database;
      await db.delete(
        'TB_ProductCategory',
        where: 'CategoryID = ?',
        whereArgs: [category.categoryID],
      );

      _reloadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف التصنيف نهائياً'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  // ============================================================
  // 📏 دوال إدارة الوحدات
  // ============================================================

  /// عرض dialog لإضافة وحدة جديدة (النسخة المبسطة)
  Future<void> _showAddUnitDialog() async {
    final nameArController = TextEditingController();
    final nameEnController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // ← Hint: متغيرات لتتبع حالة الترجمة والتعديل اليدوي
    bool isTranslating = false;
    bool userEditedAr = false;
    bool userEditedEn = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.straighten, color: AppColors.success),
                  SizedBox(width: AppConstants.spacingSm),
                  Text('إضافة وحدة جديدة'),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameArController,
                      decoration: InputDecoration(
                        labelText: 'الاسم بالعربي *',
                        hintText: 'مثال: لتر، متر، علبة',
                        prefixIcon: const Icon(Icons.text_fields),
                        border: const OutlineInputBorder(),
                        suffixIcon: isTranslating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.translate, size: 20),
                                tooltip: 'ترجمة إلى الإنجليزية',
                                onPressed: () async {
                                  final text = nameArController.text.trim();
                                  if (text.isEmpty) return;

                                  setDialogState(() => isTranslating = true);

                                  final translated = await translationService.translateToEnglish(text);

                                  setDialogState(() => isTranslating = false);

                                  if (translated != null && !userEditedEn) {
                                    setDialogState(() {
                                      nameEnController.text = translated;
                                    });
                                  }
                                },
                              ),
                      ),
                      onChanged: (value) {
                        userEditedAr = true;
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال الاسم بالعربي';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppConstants.spacingMd),

                    TextFormField(
                      controller: nameEnController,
                      decoration: InputDecoration(
                        labelText: 'الاسم بالإنجليزي *',
                        hintText: 'Example: Liter, Meter, Box',
                        prefixIcon: const Icon(Icons.text_fields),
                        border: const OutlineInputBorder(),
                        suffixIcon: isTranslating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.translate, size: 20),
                                tooltip: 'ترجمة إلى العربية',
                                onPressed: () async {
                                  final text = nameEnController.text.trim();
                                  if (text.isEmpty) return;

                                  setDialogState(() => isTranslating = true);

                                  final translated = await translationService.translateToArabic(text);

                                  setDialogState(() => isTranslating = false);

                                  if (translated != null && !userEditedAr) {
                                    setDialogState(() {
                                      nameArController.text = translated;
                                    });
                                  }
                                },
                              ),
                      ),
                      onChanged: (value) {
                        userEditedEn = true;
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال الاسم بالإنجليزي';
                        }
                        return null;
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
                    if (formKey.currentState!.validate()) {
                      try {
                        await dbHelper.addProductUnit(
                          ProductUnit(
                            unitNameAr: nameArController.text.trim(),
                            unitNameEn: nameEnController.text.trim(),
                            isActive: true,
                          ),
                        );
                        Navigator.pop(ctx, true);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('خطأ: $e')),
                        );
                      }
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
        const SnackBar(
          content: Text('تم إضافة الوحدة بنجاح'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  /// عرض dialog لتعديل وحدة
  Future<void> _showEditUnitDialog(ProductUnit unit) async {
    final nameArController = TextEditingController(text: unit.unitNameAr);
    final nameEnController = TextEditingController(text: unit.unitNameEn);
    final formKey = GlobalKey<FormState>();

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
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameArController,
                  decoration: const InputDecoration(
                    labelText: 'الاسم بالعربي *',
                    prefixIcon: Icon(Icons.text_fields),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال الاسم بالعربي';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.spacingMd),
                TextFormField(
                  controller: nameEnController,
                  decoration: const InputDecoration(
                    labelText: 'الاسم بالإنجليزي *',
                    prefixIcon: Icon(Icons.text_fields),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال الاسم بالإنجليزي';
                    }
                    return null;
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
                if (formKey.currentState!.validate()) {
                  try {
                    await dbHelper.editProductUnit(
                      unit.copyWith(
                        unitNameAr: nameArController.text.trim(),
                        unitNameEn: nameEnController.text.trim(),
                      ),
                    );
                    Navigator.pop(ctx, true);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطأ: $e')),
                    );
                  }
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
        const SnackBar(
          content: Text('تم تعديل الوحدة بنجاح'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  /// تبديل حالة تفعيل الوحدة
  Future<void> _toggleUnitStatus(ProductUnit unit) async {
    try {
      await dbHelper.editProductUnit(
        unit.copyWith(isActive: !unit.isActive),
      );
      _reloadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(unit.isActive ? 'تم تعطيل الوحدة' : 'تم تفعيل الوحدة'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  /// حذف وحدة نهائياً (مع التحقق من عدم وجود منتجات مرتبطة)
  Future<void> _deleteUnitPermanently(ProductUnit unit) async {
    // ← Hint: عد المنتجات المرتبطة بهذه الوحدة
    final productCount = await dbHelper.countProductsByUnit(unit.unitID!);

    if (productCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا يمكن حذف الوحدة لوجود $productCount منتج يستخدمها. قم بتغيير وحدة المنتجات أولاً أو استخدم زر "تعطيل".',
          ),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف الوحدة "${unit.unitNameAr}" نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final db = await dbHelper.database;
      await db.delete(
        'TB_ProductUnit',
        where: 'UnitID = ?',
        whereArgs: [unit.unitID],
      );

      _reloadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف الوحدة نهائياً'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
      );
    }
  }
}