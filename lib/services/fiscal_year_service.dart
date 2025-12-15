// lib/services/fiscal_year_service.dart

import 'package:accountant_touch/data/database_helper.dart';
import 'package:accountant_touch/data/models.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

/// ===========================================================================
/// 🏦 خدمة إدارة السنوات المالية
/// ===========================================================================
///
/// ← Hint: هذه الخدمة هي المسؤولة عن جميع عمليات السنوات المالية
/// ← Hint: تدير إنشاء، تحديث، إقفال، وترحيل السنوات المالية
/// ← Hint: توفر API بسيط وآمن للتعامل مع السنوات المالية
///
/// ===========================================================================

class FiscalYearService {
  // ==========================================================================
  // Singleton Pattern
  // ← Hint: نستخدم نمط Singleton لضمان instance واحدة فقط
  // ==========================================================================

  static final FiscalYearService _instance = FiscalYearService._internal();
  FiscalYearService._internal();
  factory FiscalYearService() => _instance;
  static FiscalYearService get instance => _instance;

  // ==========================================================================
  // ← Hint: Cache للسنة النشطة (تحديث تلقائي)
  // ==========================================================================

  FiscalYear? _activeFiscalYearCache;
  DateTime? _cacheTime;
  static const _cacheValidDuration = Duration(minutes: 5); // مدة صلاحية الـ Cache

  // ==========================================================================
  // 1️⃣ الحصول على السنة المالية النشطة
  // ← Hint: هذه الدالة هي الأكثر استخداماً - تُستدعى في كل عملية مالية
  // ==========================================================================

  /// الحصول على السنة المالية النشطة حالياً
  ///
  /// ← Hint: تستخدم Cache ذكي لتحسين الأداء (تحديث كل 5 دقائق)
  /// ← Hint: إذا لم توجد سنة نشطة، تُرجع null (حالة استثنائية)
  Future<FiscalYear?> getActiveFiscalYear({bool forceRefresh = false}) async {
    try {
      // ← Hint: التحقق من صلاحية الـ Cache
      if (!forceRefresh &&
          _activeFiscalYearCache != null &&
          _cacheTime != null &&
          DateTime.now().difference(_cacheTime!) < _cacheValidDuration) {
        debugPrint('📦 [FiscalYearService] استخدام Cache للسنة النشطة');
        return _activeFiscalYearCache;
      }

      debugPrint('🔍 [FiscalYearService] جلب السنة المالية النشطة من قاعدة البيانات...');

      final db = await DatabaseHelper.instance.database;

      // ← Hint: البحث عن السنة النشطة (IsActive = 1)
      final List<Map<String, dynamic>> maps = await db.query(
        'TB_FiscalYears',
        where: 'IsActive = ?',
        whereArgs: [1],
        limit: 1,
      );

      if (maps.isEmpty) {
        debugPrint('⚠️ [FiscalYearService] لا توجد سنة مالية نشطة!');
        return null;
      }

      final fiscalYear = FiscalYear.fromMap(maps.first);

      // ← Hint: تحديث الـ Cache
      _activeFiscalYearCache = fiscalYear;
      _cacheTime = DateTime.now();

      debugPrint('✅ [FiscalYearService] السنة النشطة: ${fiscalYear.name} (ID: ${fiscalYear.fiscalYearID})');

      return fiscalYear;
    } catch (e) {
      debugPrint('❌ [FiscalYearService] خطأ في getActiveFiscalYear: $e');
      return null;
    }
  }

  // ==========================================================================
  // 2️⃣ الحصول على جميع السنوات المالية
  // ==========================================================================

  /// الحصول على قائمة بجميع السنوات المالية
  ///
  /// ← Hint: مرتبة حسب السنة (الأحدث أولاً)
  /// ← Hint: includeInactive: هل نعرض السنوات المقفلة أيضاً؟
  Future<List<FiscalYear>> getAllFiscalYears({bool includeInactive = true}) async {
    try {
      debugPrint('📋 [FiscalYearService] جلب جميع السنوات المالية...');

      final db = await DatabaseHelper.instance.database;

      // ← Hint: إذا كنا نريد النشطة فقط
      final String? whereClause = includeInactive ? null : 'IsClosed = 0';

      final List<Map<String, dynamic>> maps = await db.query(
        'TB_FiscalYears',
        where: whereClause,
        orderBy: 'Year DESC', // ← Hint: الأحدث أولاً
      );

      final fiscalYears = maps.map((map) => FiscalYear.fromMap(map)).toList();

      debugPrint('✅ [FiscalYearService] تم جلب ${fiscalYears.length} سنة مالية');

      return fiscalYears;
    } catch (e) {
      debugPrint('❌ [FiscalYearService] خطأ في getAllFiscalYears: $e');
      return [];
    }
  }

  // ==========================================================================
  // 3️⃣ الحصول على سنة مالية محددة
  // ==========================================================================

  /// الحصول على سنة مالية بواسطة معرفها
  Future<FiscalYear?> getFiscalYearById(int fiscalYearId) async {
    try {
      final db = await DatabaseHelper.instance.database;

      final List<Map<String, dynamic>> maps = await db.query(
        'TB_FiscalYears',
        where: 'FiscalYearID = ?',
        whereArgs: [fiscalYearId],
        limit: 1,
      );

      if (maps.isEmpty) return null;

      return FiscalYear.fromMap(maps.first);
    } catch (e) {
      debugPrint('❌ [FiscalYearService] خطأ في getFiscalYearById: $e');
      return null;
    }
  }

  /// الحصول على سنة مالية بواسطة رقم السنة
  Future<FiscalYear?> getFiscalYearByYear(int year) async {
    try {
      final db = await DatabaseHelper.instance.database;

      final List<Map<String, dynamic>> maps = await db.query(
        'TB_FiscalYears',
        where: 'Year = ?',
        whereArgs: [year],
        limit: 1,
      );

      if (maps.isEmpty) return null;

      return FiscalYear.fromMap(maps.first);
    } catch (e) {
      debugPrint('❌ [FiscalYearService] خطأ في getFiscalYearByYear: $e');
      return null;
    }
  }

  // ==========================================================================
  // 4️⃣ إنشاء سنة مالية جديدة
  // ==========================================================================

  /// إنشاء سنة مالية جديدة
  ///
  /// ← Hint: year: السنة الميلادية (مثال: 2026)
  /// ← Hint: openingBalance: الرصيد الافتتاحي (من السنة السابقة)
  /// ← Hint: makeActive: هل نجعلها السنة النشطة مباشرة؟
  Future<FiscalYear?> createFiscalYear({
    required int year,
    Decimal? openingBalance,
    bool makeActive = false,
    String? notes,
  }) async {
    try {
      debugPrint('🆕 [FiscalYearService] إنشاء سنة مالية جديدة: $year');

      // ← Hint: التحقق من عدم وجود سنة بنفس الرقم
      final existingYear = await getFiscalYearByYear(year);
      if (existingYear != null) {
        debugPrint('⚠️ [FiscalYearService] سنة $year موجودة مسبقاً!');
        return null;
      }

      final db = await DatabaseHelper.instance.database;

      // ← Hint: إنشاء السنة المالية الجديدة
      final newFiscalYear = FiscalYear(
        name: 'سنة $year',
        year: year,
        startDate: DateTime(year, 1, 1),
        endDate: DateTime(year, 12, 31, 23, 59, 59),
        openingBalance: openingBalance ?? Decimal.zero,
        isActive: makeActive,
        notes: notes,
      );

      // ← Hint: إذا كانت السنة الجديدة نشطة، نُلغي تفعيل السنوات الأخرى
      if (makeActive) {
        await db.update(
          'TB_FiscalYears',
          {'IsActive': 0},
          where: 'IsActive = 1',
        );
        debugPrint('  ├─ تم إلغاء تفعيل جميع السنوات الأخرى');
      }

      // ← Hint: حفظ السنة الجديدة
      final fiscalYearId = await db.insert(
        'TB_FiscalYears',
        newFiscalYear.toMap(),
      );

      debugPrint('✅ [FiscalYearService] تم إنشاء السنة المالية (ID: $fiscalYearId)');

      // ← Hint: إعادة السنة المالية المحفوظة
      return await getFiscalYearById(fiscalYearId);
    } catch (e) {
      debugPrint('❌ [FiscalYearService] خطأ في createFiscalYear: $e');
      return null;
    }
  }

  // ==========================================================================
  // 5️⃣ تفعيل سنة مالية
  // ==========================================================================

  /// تفعيل سنة مالية محددة (وإلغاء تفعيل البقية)
  ///
  /// ← Hint: هذه العملية حساسة - تغير السنة النشطة في النظام
  Future<bool> activateFiscalYear(int fiscalYearId) async {
    try {
      debugPrint('🔄 [FiscalYearService] تفعيل السنة المالية (ID: $fiscalYearId)...');

      final db = await DatabaseHelper.instance.database;

      // ← Hint: التحقق من وجود السنة
      final fiscalYear = await getFiscalYearById(fiscalYearId);
      if (fiscalYear == null) {
        debugPrint('⚠️ [FiscalYearService] السنة المالية غير موجودة!');
        return false;
      }

      // ← Hint: التحقق من أن السنة غير مقفلة
      if (fiscalYear.isClosed) {
        debugPrint('⚠️ [FiscalYearService] لا يمكن تفعيل سنة مقفلة!');
        return false;
      }

      // ← Hint: إلغاء تفعيل جميع السنوات
      await db.update(
        'TB_FiscalYears',
        {'IsActive': 0},
      );

      // ← Hint: تفعيل السنة المطلوبة
      await db.update(
        'TB_FiscalYears',
        {'IsActive': 1},
        where: 'FiscalYearID = ?',
        whereArgs: [fiscalYearId],
      );

      // ← Hint: مسح الـ Cache
      _activeFiscalYearCache = null;
      _cacheTime = null;

      debugPrint('✅ [FiscalYearService] تم تفعيل السنة: ${fiscalYear.name}');

      return true;
    } catch (e) {
      debugPrint('❌ [FiscalYearService] خطأ في activateFiscalYear: $e');
      return false;
    }
  }

  // ==========================================================================
  // 6️⃣ إقفال سنة مالية
  // ==========================================================================

  /// إقفال سنة مالية
  ///
  /// ← Hint: هذه عملية حرجة جداً - لا يمكن التراجع عنها!
  /// ← Hint: السنة المقفلة لا يمكن إضافة/تعديل قيود فيها
  /// ← Hint: createNewYear: هل ننشئ سنة جديدة تلقائياً؟
  Future<FiscalYear?> closeFiscalYear({
    required int fiscalYearId,
    bool createNewYear = true,
  }) async {
    try {
      debugPrint('🔒 [FiscalYearService] إقفال السنة المالية (ID: $fiscalYearId)...');

      final db = await DatabaseHelper.instance.database;

      // ← Hint: الحصول على السنة المالية
      final fiscalYear = await getFiscalYearById(fiscalYearId);
      if (fiscalYear == null) {
        debugPrint('⚠️ [FiscalYearService] السنة المالية غير موجودة!');
        return null;
      }

      // ← Hint: التحقق من أن السنة غير مقفلة مسبقاً
      if (fiscalYear.isClosed) {
        debugPrint('⚠️ [FiscalYearService] السنة مقفلة مسبقاً!');
        return fiscalYear;
      }

      // ← Hint: إقفال السنة
      await db.update(
        'TB_FiscalYears',
        {
          'IsClosed': 1,
          'IsActive': 0, // ← Hint: السنة المقفلة لا يمكن أن تكون نشطة
          'ClosedAt': DateTime.now().toIso8601String(),
        },
        where: 'FiscalYearID = ?',
        whereArgs: [fiscalYearId],
      );

      debugPrint('✅ [FiscalYearService] تم إقفال السنة: ${fiscalYear.name}');

      // ← Hint: إنشاء سنة جديدة تلقائياً (إذا طُلب)
      FiscalYear? newYear;
      if (createNewYear) {
        debugPrint('  ├─ إنشاء سنة مالية جديدة...');

        newYear = await createFiscalYear(
          year: fiscalYear.year + 1,
          openingBalance: fiscalYear.closingBalance, // ← Hint: ترحيل الرصيد
          makeActive: true,
          notes: 'تم الإنشاء تلقائياً عند إقفال سنة ${fiscalYear.year}',
        );

        if (newYear != null) {
          debugPrint('  ├─ ✅ تم إنشاء ${newYear.name} (ID: ${newYear.fiscalYearID})');
        }
      }

      // ← Hint: مسح الـ Cache
      _activeFiscalYearCache = null;
      _cacheTime = null;

      return newYear ?? await getFiscalYearById(fiscalYearId);
    } catch (e) {
      debugPrint('❌ [FiscalYearService] خطأ في closeFiscalYear: $e');
      return null;
    }
  }

  // ==========================================================================
  // 7️⃣ تحديث أرصدة السنة المالية
  // ==========================================================================

  /// تحديث أرصدة السنة المالية من القيود
  ///
  /// ← Hint: هذه الدالة تُستدعى يدوياً لإعادة حساب الأرصدة
  /// ← Hint: عادة لا نحتاجها لأن الـ Triggers تحدّث تلقائياً
  /// ← Hint: مفيدة للمراجعة أو بعد استيراد بيانات
  Future<bool> recalculateFiscalYearBalances(int fiscalYearId) async {
    try {
      debugPrint('🔄 [FiscalYearService] إعادة حساب أرصدة السنة (ID: $fiscalYearId)...');

      final db = await DatabaseHelper.instance.database;

      // ← Hint: حساب إجمالي الدخل
      final incomeResult = await db.rawQuery('''
        SELECT COALESCE(SUM(Amount), 0) as total
        FROM TB_Transactions
        WHERE FiscalYearID = ? AND Direction = 'in'
      ''', [fiscalYearId]);

      final totalIncome = (incomeResult.first['total'] as num).toDouble();

      // ← Hint: حساب إجمالي المصروفات
      final expenseResult = await db.rawQuery('''
        SELECT COALESCE(SUM(Amount), 0) as total
        FROM TB_Transactions
        WHERE FiscalYearID = ? AND Direction = 'out'
      ''', [fiscalYearId]);

      final totalExpense = (expenseResult.first['total'] as num).toDouble();

      // ← Hint: حساب صافي الربح
      final netProfit = totalIncome - totalExpense;

      // ← Hint: الحصول على الرصيد الافتتاحي
      final fiscalYear = await getFiscalYearById(fiscalYearId);
      if (fiscalYear == null) return false;

      final closingBalance = fiscalYear.openingBalance.toDouble() + netProfit;

      // ← Hint: تحديث الأرصدة
      await db.update(
        'TB_FiscalYears',
        {
          'TotalIncome': totalIncome,
          'TotalExpense': totalExpense,
          'NetProfit': netProfit,
          'ClosingBalance': closingBalance,
        },
        where: 'FiscalYearID = ?',
        whereArgs: [fiscalYearId],
      );

      debugPrint('✅ [FiscalYearService] تم تحديث الأرصدة:');
      debugPrint('  ├─ إجمالي الدخل: $totalIncome');
      debugPrint('  ├─ إجمالي المصروفات: $totalExpense');
      debugPrint('  ├─ صافي الربح: $netProfit');
      debugPrint('  └─ الرصيد الختامي: $closingBalance');

      return true;
    } catch (e) {
      debugPrint('❌ [FiscalYearService] خطأ في recalculateFiscalYearBalances: $e');
      return false;
    }
  }

  // ==========================================================================
  // 8️⃣ حذف سنة مالية (خطر!)
  // ==========================================================================

  /// حذف سنة مالية (عملية خطرة جداً!)
  ///
  /// ← Hint: يُحذف جميع القيود المرتبطة بهذه السنة
  /// ← Hint: استخدم هذه الدالة بحذر شديد - لا يمكن التراجع!
  /// ← Hint: لا يمكن حذف سنة نشطة أو مقفلة
  Future<bool> deleteFiscalYear(int fiscalYearId, {bool force = false}) async {
    try {
      debugPrint('🗑️ [FiscalYearService] حذف السنة المالية (ID: $fiscalYearId)...');

      final db = await DatabaseHelper.instance.database;

      // ← Hint: الحصول على السنة
      final fiscalYear = await getFiscalYearById(fiscalYearId);
      if (fiscalYear == null) {
        debugPrint('⚠️ [FiscalYearService] السنة المالية غير موجودة!');
        return false;
      }

      // ← Hint: منع حذف السنة النشطة (إلا إذا force = true)
      if (!force && fiscalYear.isActive) {
        debugPrint('⚠️ [FiscalYearService] لا يمكن حذف السنة النشطة!');
        return false;
      }

      // ← Hint: منع حذف السنة المقفلة (إلا إذا force = true)
      if (!force && fiscalYear.isClosed) {
        debugPrint('⚠️ [FiscalYearService] لا يمكن حذف السنة المقفلة!');
        return false;
      }

      // ← Hint: حذف جميع القيود المرتبطة بهذه السنة
      final deletedTransactions = await db.delete(
        'TB_Transactions',
        where: 'FiscalYearID = ?',
        whereArgs: [fiscalYearId],
      );

      debugPrint('  ├─ تم حذف $deletedTransactions قيد مالي');

      // ← Hint: حذف السنة المالية
      await db.delete(
        'TB_FiscalYears',
        where: 'FiscalYearID = ?',
        whereArgs: [fiscalYearId],
      );

      debugPrint('✅ [FiscalYearService] تم حذف السنة: ${fiscalYear.name}');

      // ← Hint: مسح الـ Cache
      _activeFiscalYearCache = null;
      _cacheTime = null;

      return true;
    } catch (e) {
      debugPrint('❌ [FiscalYearService] خطأ في deleteFiscalYear: $e');
      return false;
    }
  }

  // ==========================================================================
  // 9️⃣ دوال مساعدة
  // ==========================================================================

  /// التحقق من أن السنة المالية مفتوحة ونشطة
  ///
  /// ← Hint: تُستخدم قبل إضافة أي قيد مالي جديد
  Future<bool> isActiveFiscalYearOpen() async {
    final activeFiscalYear = await getActiveFiscalYear();

    if (activeFiscalYear == null) {
      debugPrint('⚠️ [FiscalYearService] لا توجد سنة مالية نشطة!');
      return false;
    }

    if (activeFiscalYear.isClosed) {
      debugPrint('⚠️ [FiscalYearService] السنة المالية النشطة مقفلة!');
      return false;
    }

    return true;
  }

  /// الحصول على معرف السنة النشطة
  ///
  /// ← Hint: اختصار سريع للحصول على ID فقط
  Future<int?> getActiveFiscalYearId() async {
    final activeFiscalYear = await getActiveFiscalYear();
    return activeFiscalYear?.fiscalYearID;
  }

  /// مسح الـ Cache (بعد أي عملية تحديث)
  void clearCache() {
    _activeFiscalYearCache = null;
    _cacheTime = null;
    debugPrint('🔄 [FiscalYearService] تم مسح Cache');
  }
}
