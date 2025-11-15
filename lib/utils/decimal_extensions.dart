// import 'package:decimal/decimal.dart';

import 'package:decimal/decimal.dart';
import 'package:flutter/widgets.dart';
import 'package:rational/rational.dart';


/// ========================================================================
/// Extension للتحويل الآمن من/إلى Decimal
/// ========================================================================

extension DecimalConversion on Decimal {
  /// تحويل إلى double للتخزين في SQLite
  double toSqliteDouble() => toDouble();
  
  /// تحويل إلى String للتخزين البديل
  String toSqliteString() => toString();
  
  /// تحويل للعرض مع عدد محدد من الكسور
  String toDisplay({int decimals = 2}) => toStringAsFixed(decimals);
  
  /// تحويل للعرض بدون أصفار زائدة
  String toDisplayClean() {
    final str = toString();
    if (str.contains('.')) {
      return str.replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return str;
  }
}

/// ========================================================================
/// Extension لقراءة Decimal من Map بشكل آمن
/// ========================================================================

extension MapDecimalParsing on Map<String, dynamic> {
  /// قراءة Decimal من Map مع معالجة جميع الحالات
  Decimal getDecimal(String key, {Decimal? fallback}) {
    final value = this[key];
    final defaultValue = fallback ?? Decimal.zero;
    
    if (value == null) return defaultValue;
    
    // إذا كانت القيمة بالفعل Decimal
    if (value is Decimal) return value;
    
    // إذا كانت رقم (int أو double)
    if (value is num) {
      try {
        return Decimal.parse(value.toString());
      } catch (e) {
        debugPrint('⚠️ خطأ في تحويل num إلى Decimal: $value');
        return defaultValue;
      }
    }
    
    // إذا كانت String
    if (value is String) {
      try {
        return Decimal.parse(value);
      } catch (e) {
        debugPrint('⚠️ خطأ في تحويل String إلى Decimal: $value');
        return defaultValue;
      }
    }
    
    debugPrint('⚠️ نوع غير مدعوم للتحويل إلى Decimal: ${value.runtimeType}');
    return defaultValue;
  }
  
  /// قراءة Decimal اختياري (يمكن أن يكون null)
  Decimal? getDecimalOrNull(String key) {
    final value = this[key];
    if (value == null) return null;
    
    try {
      if (value is Decimal) return value;
      if (value is num) return Decimal.parse(value.toString());
      if (value is String) return Decimal.parse(value);
    } catch (e) {
      debugPrint('⚠️ خطأ في تحويل القيمة إلى Decimal: $value');
    }
    
    return null;
  }
}

/// ========================================================================
/// Decimal Helper Functions
/// ========================================================================

class DecimalHelper {
  /// تحويل آمن من dynamic إلى Decimal
  static Decimal fromDynamic(dynamic value, {Decimal? fallback}) {
    final defaultValue = fallback ?? Decimal.zero;
    
    if (value == null) return defaultValue;
    if (value is Decimal) return value;
    
    try {
      if (value is num) return Decimal.parse(value.toString());
      if (value is String) return Decimal.parse(value);
    } catch (e) {
      debugPrint('⚠️ فشل تحويل القيمة إلى Decimal: $value');
    }
    
    return defaultValue;
  }
  
  /// تقريب Decimal لعدد معين من الكسور
  static Rational round(Decimal value, {int decimals = 2}) {
  final multiplier = Decimal.fromInt(10).pow(decimals).toDecimal();
  return (value * multiplier).round() / multiplier;
}
  
  /// التحقق من أن Decimal صالح (ليس infinity أو NaN)
  static bool isValid(Decimal value) {
    try {
      final doubleValue = value.toDouble();
      return doubleValue.isFinite;
    } catch (e) {
      return false;
    }
  }
  
  /// مقارنة Decimal مع tolerance صغير
  static bool isEqual(Decimal a, Decimal b, {Decimal? tolerance}) {
    final tol = tolerance ?? Decimal.parse('0.001');
    return (a - b).abs() < tol;
  }
  
  /// إنشاء Decimal من percentage
  static Decimal fromPercentage(num percentage) {
      final r = Decimal.parse(percentage.toString()) / Decimal.fromInt(100);
  return r.toDecimal();
  }
  
  /// تحويل Decimal إلى percentage
  static Decimal toPercentage(Decimal value) {
    return value * Decimal.fromInt(100);
  }
}

/// ========================================================================
/// Extension للعمليات الحسابية السريعة
/// ========================================================================

extension DecimalMath on Decimal {
  /// ضرب في عدد صحيح
  Decimal multiplyByInt(int value) {
    return this * Decimal.fromInt(value);
  }
  
  /// قسمة على عدد صحيح
  Decimal divideByInt(int value) {
    return (this / Decimal.fromInt(value)).toDecimal();
  }
  
  /// حساب النسبة المئوية
  Decimal percentage(num percent) {
    return this * DecimalHelper.fromPercentage(percent);
  }
  
  /// التقريب لأقرب عدد صحيح
  Decimal roundToInt() {
    return Decimal.fromInt(toDouble().round());
  }
  
  /// التقريب لأعلى
  Decimal ceil() {
    return Decimal.fromInt(toDouble().ceil());
  }
  
  /// التقريب لأسفل
  Decimal floor() {
    return Decimal.fromInt(toDouble().floor());
  }
}

/// ========================================================================
/// Constants
/// ========================================================================

class DecimalConstants {
  static final Decimal zero = Decimal.zero;
  static final Decimal one = Decimal.one;
  static final Decimal ten = Decimal.fromInt(10);
  static final Decimal hundred = Decimal.fromInt(100);
  static final Decimal thousand = Decimal.fromInt(1000);
}