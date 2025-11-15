import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:decimal/decimal.dart';

/// ✅ خدمة إدارة العملات - محدثة لدعم Decimal
class CurrencyService {
  static final CurrencyService _instance = CurrencyService._internal();
  CurrencyService._internal();
  factory CurrencyService() => _instance;
  static CurrencyService get instance => _instance;

  static const String _currencyKey = 'selected_currency';
  Currency _currentCurrency = Currency.iqd;

  Currency get currentCurrency => _currentCurrency;

  Future<void> loadSavedCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_currencyKey);
      
      if (savedCode != null) {
        _currentCurrency = Currency.values.firstWhere(
          (c) => c.code == savedCode,
          orElse: () => Currency.iqd,
        );
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل العملة: $e');
      _currentCurrency = Currency.iqd;
    }
  }

  Future<void> setCurrency(Currency currency) async {
    try {
      _currentCurrency = currency;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currencyKey, currency.code);
    } catch (e) {
      debugPrint('❌ خطأ في حفظ العملة: $e');
    }
  }

  /// ✅ تنسيق Decimal كعملة
  String formatAmount(Decimal amount) {
    try {
      final formatter = NumberFormat.currency(
        locale: _currentCurrency.locale,
        symbol: _currentCurrency.symbol,
        decimalDigits: _currentCurrency.decimalDigits,
      );
      
      // ⚠️ NumberFormat يحتاج double
      return formatter.format(amount.toDouble());
    } catch (e) {
      debugPrint('❌ خطأ في تنسيق المبلغ: $e');
      return '${_currentCurrency.symbol}0';
    }
  }

  /// ✅ تنسيق بدون رمز العملة
  String formatAmountWithoutSymbol(Decimal amount) {
    try {
      final formatter = NumberFormat(
        _currentCurrency.pattern,
        _currentCurrency.locale,
      );
      return formatter.format(amount.toDouble());
    } catch (e) {
      debugPrint('❌ خطأ في تنسيق المبلغ: $e');
      return '0';
    }
  }
}

// ✅ Enum بدون تغيير
enum Currency {
  iqd(
    code: 'IQD',
    nameAr: 'دينار عراقي',
    nameEn: 'Iraqi Dinar',
    symbol: 'د.ع ',
    locale: 'en_US',
    pattern: '###,##0',
    decimalDigits: 0,
  ),
  usd(
    code: 'USD',
    nameAr: 'دولار أمريكي',
    nameEn: 'US Dollar',
    symbol: '\$',
    locale: 'en_US',
    pattern: '###,##0.00',
    decimalDigits: 2,
  ),
  eur(
    code: 'EUR',
    nameAr: 'يورو',
    nameEn: 'Euro',
    symbol: '€',
    locale: 'en_US',
    pattern: '###,##0.00',
    decimalDigits: 2,
  ),
  gbp(
    code: 'GBP',
    nameAr: 'جنيه إسترليني',
    nameEn: 'British Pound',
    symbol: '£',
    locale: 'en_GB',
    pattern: '###,##0.00',
    decimalDigits: 2,
  ),
  sar(
    code: 'SAR',
    nameAr: 'ريال سعودي',
    nameEn: 'Saudi Riyal',
    symbol: 'SAR',
    locale: 'ar_SA',
    pattern: '###,##0.00',
    decimalDigits: 2,
  ),
  aed(
    code: 'AED',
    nameAr: 'درهم إماراتي',
    nameEn: 'UAE Dirham',
    symbol: 'AED',
    locale: 'ar_AE',
    pattern: '###,##0.00',
    decimalDigits: 2,
  );

  const Currency({
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.symbol,
    required this.locale,
    required this.pattern,
    required this.decimalDigits,
  });

  final String code;
  final String nameAr;
  final String nameEn;
  final String symbol;
  final String locale;
  final String pattern;
  final int decimalDigits;

  String getName(bool isArabic) => isArabic ? nameAr : nameEn;
}