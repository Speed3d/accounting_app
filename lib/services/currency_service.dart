// lib/services/currency_service.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
/// ✅ Hint: خدمة إدارة العملات - Singleton Pattern
/// الوظيفة: حفظ واسترجاع العملة المختارة وتنسيق الأرقام حسب العملة
class CurrencyService {
// ✅ Hint: تطبيق Singleton Pattern
static final CurrencyService _instance = CurrencyService._internal();
CurrencyService._internal();
factory CurrencyService() => _instance;
static CurrencyService get instance => _instance;
// ✅ Hint: مفتاح حفظ العملة في SharedPreferences
static const String _currencyKey = 'selected_currency';
// ✅ Hint: العملة الحالية (افتراضياً IQD)
Currency _currentCurrency = Currency.iqd;
/// ✅ Hint: الحصول على العملة الحالية
Currency get currentCurrency => _currentCurrency;
/// ✅ Hint: تحميل العملة المحفوظة عند بدء التطبيق
Future<void> loadSavedCurrency() async {
try {
final prefs = await SharedPreferences.getInstance();
final savedCode = prefs.getString(_currencyKey);
  if (savedCode != null) {
    // ✅ Hint: البحث عن العملة في القائمة
    _currentCurrency = Currency.values.firstWhere(
      (c) => c.code == savedCode,
      orElse: () => Currency.iqd, // افتراضياً دينار عراقي
    );
  }
} catch (e) {
  debugPrint('❌ خطأ في تحميل العملة: $e');
  _currentCurrency = Currency.iqd;
}
}
/// ✅ Hint: حفظ العملة المختارة
Future<void> setCurrency(Currency currency) async {
try {
_currentCurrency = currency;
final prefs = await SharedPreferences.getInstance();
await prefs.setString(_currencyKey, currency.code);
} catch (e) {
debugPrint('❌ خطأ في حفظ العملة: $e');
}
}
/// ✅ Hint: تنسيق الرقم حسب العملة المختارة
/// مثال: formatAmount(50000.5) -> "50,000.5 IQD" أو "$50,000.50"
String formatAmount(double amount) {
// ✅ Hint: إنشاء NumberFormat حسب نوع العملة
final formatter = NumberFormat.currency(
locale: _currentCurrency.locale,
symbol: _currentCurrency.symbol,
decimalDigits: _currentCurrency.decimalDigits,
);
return formatter.format(amount);
}
/// ✅ Hint: تنسيق الرقم بدون رمز العملة
/// مثال: formatAmountWithoutSymbol(50000.5) -> "50,000.5"
String formatAmountWithoutSymbol(double amount) {
final formatter = NumberFormat(
_currentCurrency.pattern,
_currentCurrency.locale,
);
return formatter.format(amount);
}
}
/// ✅ Hint: تعريف العملات المدعومة
enum Currency {
// ✅ Hint: دينار عراقي - بدون كسور عشرية
iqd(
code: 'IQD',
nameAr: 'دينار عراقي',
nameEn: 'Iraqi Dinar',
// symbol: 'IQD',
symbol: 'د.ع ',
locale: 'en_US',
pattern: '###,##0',
decimalDigits: 0,
),
// ✅ Hint: دولار أمريكي - بكسرين عشريين
usd(
code: 'USD',
nameAr: 'دولار أمريكي',
nameEn: 'US Dollar',
// symbol: '$', هنا كن خطا وتم وضع \
symbol: '\$',
locale: 'en_US',
pattern: '###,##0.00',
decimalDigits: 2,
),
// ✅ Hint: يورو - بكسرين عشريين
eur(
code: 'EUR',
nameAr: 'يورو',
nameEn: 'Euro',
symbol: '€',
locale: 'en_US',
pattern: '###,##0.00',
decimalDigits: 2,
),
// ✅ Hint: جنيه إسترليني
gbp(
code: 'GBP',
nameAr: 'جنيه إسترليني',
nameEn: 'British Pound',
symbol: '£',
locale: 'en_GB',
pattern: '###,##0.00',
decimalDigits: 2,
),
// ✅ Hint: ريال سعودي
sar(
code: 'SAR',
nameAr: 'ريال سعودي',
nameEn: 'Saudi Riyal',
symbol: 'SAR',
locale: 'ar_SA',
pattern: '###,##0.00',
decimalDigits: 2,
),
// ✅ Hint: درهم إماراتي
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
/// ✅ Hint: الحصول على اسم العملة حسب اللغة
String getName(bool isArabic) => isArabic ? nameAr : nameEn;
}