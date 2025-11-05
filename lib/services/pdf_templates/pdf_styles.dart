// lib/services/pdf_templates/pdf_styles.dart

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// 🎨 الألوان والأنماط الموحدة لـ PDF
/// Hint: نستخدم نفس ألوان التطبيق للتناسق
class PdfStyles {
  PdfStyles._(); // منع الإنشاء

  // ============= الألوان =============
  
  /// اللون الأساسي (الأخضر)
  static final PdfColor primaryColor = PdfColor.fromHex('#10B981');
  
  /// اللون الثانوي (الأزرق)
  static final PdfColor secondaryColor = PdfColor.fromHex('#3B82F6');
  
  /// لون النجاح
  static final PdfColor successColor = PdfColor.fromHex('#10B981');
  
  /// لون التحذير
  static final PdfColor warningColor = PdfColor.fromHex('#F59E0B');
  
  /// لون الخطأ
  static final PdfColor errorColor = PdfColor.fromHex('#EF4444');
  
  /// لون النص الرئيسي
  static const PdfColor textPrimary = PdfColors.grey900;
  
  /// لون النص الثانوي
  static const PdfColor textSecondary = PdfColors.grey600;
  
  /// لون النص الخفيف
  static const PdfColor textHint = PdfColors.grey400;
  
  /// لون الحدود
  static const PdfColor borderColor = PdfColors.grey300;
  
  /// لون الخلفية الخفيفة
  static const PdfColor backgroundLight = PdfColors.grey50;

  // ============= أحجام الخطوط =============
  
  static const double fontSizeTitle = 20.0;      // عنوان التقرير
  static const double fontSizeHeading = 16.0;    // عناوين الأقسام
  static const double fontSizeSubheading = 14.0; // عناوين فرعية
  static const double fontSizeBody = 12.0;       // النص العادي
  static const double fontSizeSmall = 10.0;      // النصوص الصغيرة
  static const double fontSizeCaption = 8.0;     // التعليقات

  // ============= المسافات =============
  
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // ============= أنماط النصوص =============
  
  /// نمط عنوان التقرير
  static pw.TextStyle titleStyle({PdfColor? color}) => pw.TextStyle(
        fontSize: fontSizeTitle,
        fontWeight: pw.FontWeight.bold,
        color: color ?? primaryColor,
      );

  /// نمط العناوين الرئيسية
  static pw.TextStyle headingStyle({PdfColor? color}) => pw.TextStyle(
        fontSize: fontSizeHeading,
        fontWeight: pw.FontWeight.bold,
        color: color ?? textPrimary,
      );

  /// نمط العناوين الفرعية
  static pw.TextStyle subheadingStyle({PdfColor? color}) => pw.TextStyle(
        fontSize: fontSizeSubheading,
        fontWeight: pw.FontWeight.bold,
        color: color ?? textPrimary,
      );

  /// نمط النص العادي
  static pw.TextStyle bodyStyle({PdfColor? color}) => pw.TextStyle(
        fontSize: fontSizeBody,
        color: color ?? textPrimary,
      );

  /// نمط النص الصغير
  static pw.TextStyle smallStyle({PdfColor? color}) => pw.TextStyle(
        fontSize: fontSizeSmall,
        color: color ?? textSecondary,
      );

  /// نمط التعليقات
  static pw.TextStyle captionStyle({PdfColor? color}) => pw.TextStyle(
        fontSize: fontSizeCaption,
        color: color ?? textHint,
      );

  /// نمط النص الغامق
  static pw.TextStyle boldStyle({double? fontSize, PdfColor? color}) =>
      pw.TextStyle(
        fontSize: fontSize ?? fontSizeBody,
        fontWeight: pw.FontWeight.bold,
        color: color ?? textPrimary,
      );

  // ============= أنماط الجداول =============
  
  /// نمط رأس الجدول
  static pw.TextStyle tableHeaderStyle() => pw.TextStyle(
        fontSize: fontSizeBody,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      );

  /// نمط خلايا الجدول
  static pw.TextStyle tableCellStyle() => pw.TextStyle(
        fontSize: fontSizeSmall,
        color: textPrimary,
      );

  /// ديكور رأس الجدول
  static pw.BoxDecoration tableHeaderDecoration() => pw.BoxDecoration(
        color: primaryColor,
        border: pw.Border.all(color: borderColor, width: 0.5),
      );

  /// ديكور خلايا الجدول (الصفوف الزوجية)
  static pw.BoxDecoration tableCellDecorationEven() => pw.BoxDecoration(
        color: backgroundLight,
        border: pw.Border.all(color: borderColor, width: 0.5),
      );

  /// ديكور خلايا الجدول (الصفوف الفردية)
  static pw.BoxDecoration tableCellDecorationOdd() => pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: borderColor, width: 0.5),
      );

  // ============= خطوط متعددة اللغات =============
  
  /// ✅ Hint: سنحمّل الخطوط العربية في PdfService
  /// هذه فقط أسماء مرجعية
  static const String arabicFont = 'Amiri';
  static const String englishFont = 'Roboto';
}