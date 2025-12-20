// lib/services/account_service.dart

import 'package:accountant_touch/data/database_helper.dart';
import 'package:accountant_touch/data/models.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

/// ============================================================================
/// 🏦 خدمة إدارة الحسابات المحاسبية (AccountService)
/// ============================================================================
/// ← Hint: هذه الخدمة مسؤولة عن إدارة الحسابات المحاسبية (Chart of Accounts)
/// ← Hint: توفر دوال للحصول على الحسابات، البحث، وتحديث الأرصدة
/// ← Hint: تعمل كطبقة بين UI والـ Database
/// ============================================================================
class AccountService {
  // ==========================================================================
  // Singleton Pattern
  // ==========================================================================
  // ← Hint: نستخدم Singleton لضمان instance واحدة فقط
  AccountService._privateConstructor();
  static final AccountService instance = AccountService._privateConstructor();

  // ==========================================================================
  // Dependencies
  // ==========================================================================
  final _dbHelper = DatabaseHelper.instance;

  // ==========================================================================
  // 🔍 دوال الحصول على الحسابات
  // ==========================================================================

  /// الحصول على جميع الحسابات
  ///
  /// ← Hint: يمكن فلترة الحسابات حسب النوع أو الحالة
  /// ← Parameters:
  ///   - accountType: نوع الحساب (asset, liability, etc.)
  ///   - onlyActive: عرض النشطة فقط (افتراضياً true)
  ///   - onlyDefault: عرض الافتراضية فقط (افتراضياً false)
  Future<List<Account>> getAllAccounts({
    AccountType? accountType,
    bool onlyActive = true,
    bool onlyDefault = false,
  }) async {
    try {
      final db = await _dbHelper.database;

      // ← Hint: بناء استعلام SQL ديناميكي حسب الفلاتر
      String where = '';
      List<dynamic> whereArgs = [];

      if (accountType != null) {
        where += 'AccountType = ?';
        whereArgs.add(accountType.name);
      }

      if (onlyActive) {
        where += where.isEmpty ? 'IsActive = 1' : ' AND IsActive = 1';
      }

      if (onlyDefault) {
        where += where.isEmpty ? 'IsDefault = 1' : ' AND IsDefault = 1';
      }

      final List<Map<String, dynamic>> maps = await db.query(
        'TB_Accounts',
        where: where.isEmpty ? null : where,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'AccountCode ASC', // ← Hint: ترتيب حسب الكود
      );

      debugPrint('📊 [AccountService] تم جلب ${maps.length} حساب');

      return List.generate(maps.length, (i) => Account.fromMap(maps[i]));
    } catch (e) {
      debugPrint('❌ [AccountService] خطأ في getAllAccounts: $e');
      return [];
    }
  }

  /// الحصول على حساب محدد بواسطة ID
  ///
  /// ← Hint: يُستخدم عند الحاجة لمعلومات حساب معين
  Future<Account?> getAccountById(int accountId) async {
    try {
      final db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        'TB_Accounts',
        where: 'AccountID = ?',
        whereArgs: [accountId],
        limit: 1,
      );

      if (maps.isEmpty) {
        debugPrint('⚠️ [AccountService] لم يتم العثور على الحساب #$accountId');
        return null;
      }

      return Account.fromMap(maps.first);
    } catch (e) {
      debugPrint('❌ [AccountService] خطأ في getAccountById: $e');
      return null;
    }
  }

  /// الحصول على حساب محدد بواسطة الكود
  ///
  /// ← Hint: الكود فريد لكل حساب (مثل: "1001", "1100")
  /// ← Hint: أسرع من البحث بالـ ID في بعض الحالات
  Future<Account?> getAccountByCode(String accountCode) async {
    try {
      final db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        'TB_Accounts',
        where: 'AccountCode = ?',
        whereArgs: [accountCode],
        limit: 1,
      );

      if (maps.isEmpty) {
        debugPrint('⚠️ [AccountService] لم يتم العثور على الحساب بالكود: $accountCode');
        return null;
      }

      return Account.fromMap(maps.first);
    } catch (e) {
      debugPrint('❌ [AccountService] خطأ في getAccountByCode: $e');
      return null;
    }
  }

  // ==========================================================================
  // 🎯 دوال مختصرة للحسابات الافتراضية المهمة
  // ==========================================================================
  // ← Hint: هذه الدوال توفر وصول سريع للحسابات الأكثر استخداماً

  /// حساب الصندوق (1001) - الحساب الافتراضي للنقدية
  ///
  /// ← Hint: هذا أهم حساب في النظام - يُستخدم في معظم العمليات النقدية
  Future<Account?> getCashAccount() async {
    return await getAccountByCode('1001');
  }

  /// حساب المخزون (1100) - لتتبع قيمة المنتجات
  ///
  /// ← Hint: يتحدث تلقائياً عند شراء أو بيع المنتجات
  Future<Account?> getInventoryAccount() async {
    return await getAccountByCode('1100');
  }

  /// حساب الموردون (2001) - ديون للموردين
  ///
  /// ← Hint: يُستخدم عند الشراء الآجل من الموردين
  Future<Account?> getSuppliersAccount() async {
    return await getAccountByCode('2001');
  }

  /// حساب إيرادات المبيعات (4001) - دخل من المبيعات
  ///
  /// ← Hint: يُسجل فيه جميع إيرادات البيع
  Future<Account?> getSalesRevenueAccount() async {
    return await getAccountByCode('4001');
  }

  /// حساب تكلفة المبيعات (5001) - تكلفة المشتريات
  ///
  /// ← Hint: يُسجل فيه تكلفة شراء المنتجات
  Future<Account?> getCostOfSalesAccount() async {
    return await getAccountByCode('5001');
  }

  /// حساب خسائر المخزون (5010) - للمنتجات التالفة/المفقودة
  ///
  /// ← Hint: يُستخدم عند حذف منتج بسبب تلف أو سرقة
  Future<Account?> getInventoryLossAccount() async {
    return await getAccountByCode('5010');
  }

  // ==========================================================================
  // 📊 دوال الإحصائيات والأرصدة
  // ==========================================================================

  /// الحصول على رصيد حساب محدد
  ///
  /// ← Hint: الرصيد يتحدث تلقائياً عبر Triggers
  Future<Decimal> getAccountBalance(int accountId) async {
    try {
      final account = await getAccountById(accountId);
      return account?.balance ?? Decimal.zero;
    } catch (e) {
      debugPrint('❌ [AccountService] خطأ في getAccountBalance: $e');
      return Decimal.zero;
    }
  }

  /// الحصول على رصيد حساب بواسطة الكود
  Future<Decimal> getAccountBalanceByCode(String accountCode) async {
    try {
      final account = await getAccountByCode(accountCode);
      return account?.balance ?? Decimal.zero;
    } catch (e) {
      debugPrint('❌ [AccountService] خطأ في getAccountBalanceByCode: $e');
      return Decimal.zero;
    }
  }

  /// الحصول على إجمالي أرصدة نوع معين من الحسابات
  ///
  /// ← Hint: مفيد لحساب إجمالي الأصول، الخصوم، إلخ
  Future<Decimal> getTotalBalanceByType(AccountType accountType) async {
    try {
      final accounts = await getAllAccounts(
        accountType: accountType,
        onlyActive: true,
      );

      Decimal total = Decimal.zero;
      for (var account in accounts) {
        total += account.balance;
      }

      debugPrint('📊 [AccountService] إجمالي أرصدة ${accountType.name}: $total');
      return total;
    } catch (e) {
      debugPrint('❌ [AccountService] خطأ في getTotalBalanceByType: $e');
      return Decimal.zero;
    }
  }

  /// الحصول على إجمالي الأصول
  ///
  /// ← Hint: مجموع أرصدة جميع حسابات الأصول (الصندوق، المخزون، العملاء)
  Future<Decimal> getTotalAssets() async {
    return await getTotalBalanceByType(AccountType.asset);
  }

  /// الحصول على إجمالي الخصوم
  ///
  /// ← Hint: مجموع أرصدة جميع حسابات الخصوم (الموردون)
  Future<Decimal> getTotalLiabilities() async {
    return await getTotalBalanceByType(AccountType.liability);
  }

  /// الحصول على إجمالي حقوق الملكية
  ///
  /// ← Hint: رأس المال + الأرباح المحتجزة
  Future<Decimal> getTotalEquity() async {
    return await getTotalBalanceByType(AccountType.equity);
  }

  // ==========================================================================
  // 📋 دوال القوائم المالية
  // ==========================================================================

  /// الحصول على قائمة المركز المالي (Balance Sheet)
  ///
  /// ← Hint: تعرض الأصول، الخصوم، وحقوق الملكية
  /// ← Returns: Map يحتوي على:
  ///   - assets: قائمة حسابات الأصول
  ///   - liabilities: قائمة حسابات الخصوم
  ///   - equity: قائمة حسابات حقوق الملكية
  ///   - totalAssets: إجمالي الأصول
  ///   - totalLiabilities: إجمالي الخصوم
  ///   - totalEquity: إجمالي حقوق الملكية
  Future<Map<String, dynamic>> getBalanceSheet() async {
    try {
      debugPrint('📊 [AccountService] جاري إعداد قائمة المركز المالي...');

      final assets = await getAllAccounts(
        accountType: AccountType.asset,
        onlyActive: true,
      );

      final liabilities = await getAllAccounts(
        accountType: AccountType.liability,
        onlyActive: true,
      );

      final equity = await getAllAccounts(
        accountType: AccountType.equity,
        onlyActive: true,
      );

      final totalAssets = await getTotalAssets();
      final totalLiabilities = await getTotalLiabilities();
      final totalEquity = await getTotalEquity();

      debugPrint('✅ [AccountService] قائمة المركز المالي جاهزة');
      debugPrint('   📈 إجمالي الأصول: $totalAssets');
      debugPrint('   📉 إجمالي الخصوم: $totalLiabilities');
      debugPrint('   💰 إجمالي حقوق الملكية: $totalEquity');

      return {
        'assets': assets,
        'liabilities': liabilities,
        'equity': equity,
        'totalAssets': totalAssets,
        'totalLiabilities': totalLiabilities,
        'totalEquity': totalEquity,
        'isBalanced': (totalAssets == (totalLiabilities + totalEquity)),
      };
    } catch (e) {
      debugPrint('❌ [AccountService] خطأ في getBalanceSheet: $e');
      return {
        'assets': <Account>[],
        'liabilities': <Account>[],
        'equity': <Account>[],
        'totalAssets': Decimal.zero,
        'totalLiabilities': Decimal.zero,
        'totalEquity': Decimal.zero,
        'isBalanced': false,
      };
    }
  }

  /// الحصول على قائمة الدخل (Income Statement)
  ///
  /// ← Hint: تعرض الإيرادات والمصروفات
  /// ← Returns: Map يحتوي على:
  ///   - revenues: قائمة حسابات الإيرادات
  ///   - expenses: قائمة حسابات المصروفات
  ///   - totalRevenue: إجمالي الإيرادات
  ///   - totalExpenses: إجمالي المصروفات
  ///   - netIncome: صافي الدخل (الربح أو الخسارة)
  Future<Map<String, dynamic>> getIncomeStatement() async {
    try {
      debugPrint('📊 [AccountService] جاري إعداد قائمة الدخل...');

      final revenues = await getAllAccounts(
        accountType: AccountType.revenue,
        onlyActive: true,
      );

      final expenses = await getAllAccounts(
        accountType: AccountType.expense,
        onlyActive: true,
      );

      final totalRevenue = await getTotalBalanceByType(AccountType.revenue);
      final totalExpenses = await getTotalBalanceByType(AccountType.expense);

      // ← Hint: صافي الدخل = الإيرادات - المصروفات
      final netIncome = totalRevenue - totalExpenses;

      debugPrint('✅ [AccountService] قائمة الدخل جاهزة');
      debugPrint('   📈 إجمالي الإيرادات: $totalRevenue');
      debugPrint('   📉 إجمالي المصروفات: $totalExpenses');
      debugPrint('   💰 صافي الدخل: $netIncome');

      return {
        'revenues': revenues,
        'expenses': expenses,
        'totalRevenue': totalRevenue,
        'totalExpenses': totalExpenses,
        'netIncome': netIncome,
        'isProfit': netIncome > Decimal.zero,
      };
    } catch (e) {
      debugPrint('❌ [AccountService] خطأ في getIncomeStatement: $e');
      return {
        'revenues': <Account>[],
        'expenses': <Account>[],
        'totalRevenue': Decimal.zero,
        'totalExpenses': Decimal.zero,
        'netIncome': Decimal.zero,
        'isProfit': false,
      };
    }
  }

  // ==========================================================================
  // 🔍 دوال البحث
  // ==========================================================================

  /// البحث في الحسابات بالاسم (عربي أو إنجليزي)
  ///
  /// ← Hint: يبحث في الاسم العربي والإنجليزي
  Future<List<Account>> searchAccounts(String query) async {
    try {
      if (query.trim().isEmpty) {
        return await getAllAccounts();
      }

      final db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        'TB_Accounts',
        where: 'AccountNameAr LIKE ? OR AccountNameEn LIKE ? OR AccountCode LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: 'AccountCode ASC',
      );

      debugPrint('🔍 [AccountService] نتائج البحث عن "$query": ${maps.length} حساب');

      return List.generate(maps.length, (i) => Account.fromMap(maps[i]));
    } catch (e) {
      debugPrint('❌ [AccountService] خطأ في searchAccounts: $e');
      return [];
    }
  }

  // ==========================================================================
  // ✅ دوال التحقق
  // ==========================================================================

  /// التحقق من وجود حساب بكود معين
  ///
  /// ← Hint: مفيد قبل إضافة حساب جديد
  Future<bool> accountCodeExists(String accountCode) async {
    try {
      final account = await getAccountByCode(accountCode);
      return account != null;
    } catch (e) {
      debugPrint('❌ [AccountService] خطأ في accountCodeExists: $e');
      return false;
    }
  }

  /// التحقق من صحة معادلة الميزانية
  ///
  /// ← Hint: الأصول = الخصوم + حقوق الملكية
  /// ← Hint: يجب أن تكون هذه المعادلة صحيحة دائماً
  Future<bool> isBalanceSheetBalanced() async {
    try {
      final totalAssets = await getTotalAssets();
      final totalLiabilities = await getTotalLiabilities();
      final totalEquity = await getTotalEquity();

      final isBalanced = totalAssets == (totalLiabilities + totalEquity);

      if (!isBalanced) {
        debugPrint('⚠️ [AccountService] الميزانية غير متوازنة!');
        debugPrint('   الأصول: $totalAssets');
        debugPrint('   الخصوم + حقوق الملكية: ${totalLiabilities + totalEquity}');
      }

      return isBalanced;
    } catch (e) {
      debugPrint('❌ [AccountService] خطأ في isBalanceSheetBalanced: $e');
      return false;
    }
  }
}
