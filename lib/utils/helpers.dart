import 'package:decimal/decimal.dart';
import 'package:flutter/widgets.dart';
import '../services/currency_service.dart';
import 'decimal_extensions.dart';

// ✅ تحويل الأرقام العربية (بدون تغيير)
String convertArabicNumbersToEnglish(String input) {
  const arabicNumbers = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  const englishNumbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  for (int i = 0; i < arabicNumbers.length; i++) {
    input = input.replaceAll(arabicNumbers[i], englishNumbers[i]);
  }
  return input;
}

/// ✅ تنسيق Decimal كعملة
String formatCurrency(Decimal amount) {
  return CurrencyService.instance.formatAmount(amount);
}

/// ✅ تنسيق بدون رمز العملة
String formatCurrencyWithoutSymbol(Decimal amount) {
  return CurrencyService.instance.formatAmountWithoutSymbol(amount);
}

/// ✅ تحويل String إلى Decimal بشكل آمن
Decimal parseDecimal(String value, {Decimal? fallback}) {
  try {
    final normalized = convertArabicNumbersToEnglish(value.trim());
    return Decimal.parse(normalized);
  } catch (e) {
    debugPrint('⚠️ خطأ في تحويل String إلى Decimal: $value');
    return fallback ?? Decimal.zero;
  }
}

/// ✅ تحويل dynamic إلى Decimal
Decimal toDecimal(dynamic value, {Decimal? fallback}) {
  return DecimalHelper.fromDynamic(value, fallback: fallback);
}

// ✅ دوال للتحقق من نوع المورد (بدون تغيير)
bool isPartnership(String? supplierType) {
  if (supplierType == null || supplierType.isEmpty) return false;
  final normalized = supplierType.trim().toLowerCase();
  return normalized == 'شراكة' ||
      normalized == 'partnership' ||
      normalized.contains('شراك') ||
      normalized.contains('partner');
}

bool isIndividual(String? supplierType) {
  if (supplierType == null || supplierType.isEmpty) return false;
  final normalized = supplierType.trim().toLowerCase();
  return normalized == 'فردي' ||
      normalized == 'individual' ||
      normalized.contains('فرد') ||
      normalized.contains('individ');
}