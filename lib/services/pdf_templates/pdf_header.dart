// lib/services/pdf_templates/pdf_header.dart

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'pdf_styles.dart';

/// 📄 بناء رأس الصفحة (Header) الموحد لجميع التقارير
/// ✅ محدّث: أحجام مصغرة للطباعة
class PdfHeader {
  /// بناء الـ Header
  /// 
  /// المعاملات:
  /// - [companyName]: اسم الشركة
  /// - [reportTitle]: عنوان التقرير
  /// - [reportDate]: تاريخ التقرير
  /// - [logoFile]: ملف شعار الشركة (اختياري)
  /// - [additionalInfo]: معلومات إضافية (اختياري)
  static pw.Widget build({
    required String companyName,
    required String reportTitle,
    required String reportDate,
    File? logoFile,
    Map<String, String>? additionalInfo,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(PdfStyles.spacingSm),  // ✅ مصغر من spacingMd
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfStyles.primaryColor,
            width: 2,  // ✅ مصغر من 3
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ============= القسم الأيمن: الشعار + اسم الشركة =============
          pw.Expanded(
            flex: 3,
            child: pw.Row(
              children: [
                // الشعار (إذا كان موجوداً)
                if (logoFile != null && logoFile.existsSync()) ...[
                  pw.Container(
                    width: 45,   // ✅ مصغر من 60
                    height: 45,  // ✅ مصغر من 60
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfStyles.borderColor,
                        width: 0.75,  // ✅ مصغر من 1
                      ),
                      borderRadius: pw.BorderRadius.circular(6),  // ✅ مصغر من 8
                    ),
                    child: pw.ClipRRect(
                      horizontalRadius: 6,  // ✅ مصغر من 8
                      verticalRadius: 6,    // ✅ مصغر من 8
                      child: pw.Image(
                        pw.MemoryImage(logoFile.readAsBytesSync()),
                        fit: pw.BoxFit.cover,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: PdfStyles.spacingSm),  // ✅ مصغر من spacingMd
                ],

                // اسم الشركة
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      companyName,
                      style: PdfStyles.headingStyle(),
                    ),
                    pw.SizedBox(height: PdfStyles.spacingXs),
                    
                    // معلومات إضافية (هاتف، عنوان...)
                    if (additionalInfo != null) ...[
                      ...additionalInfo.entries.map(
                        (entry) => pw.Padding(
                          padding: const pw.EdgeInsets.only(
                            bottom: PdfStyles.spacingXs,
                          ),
                          child: pw.Text(
                            '${entry.key}: ${entry.value}',
                            style: PdfStyles.captionStyle(),  // ✅ مصغر من smallStyle
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // ============= القسم الأيسر: عنوان التقرير + التاريخ =============
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                // عنوان التقرير
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: PdfStyles.spacingSm,  // ✅ مصغر من spacingMd
                    vertical: PdfStyles.spacingXs,    // ✅ مصغر من spacingSm
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfStyles.primaryColor.shade(0.1),
                    borderRadius: pw.BorderRadius.circular(6),  // ✅ مصغر من 8
                  ),
                  child: pw.Text(
                    reportTitle,
                    style: PdfStyles.titleStyle(),
                    textAlign: pw.TextAlign.center,
                  ),
                ),

                pw.SizedBox(height: PdfStyles.spacingSm),  // ✅ مصغر من spacingMd

                // التاريخ
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: PdfStyles.spacingXs,  // ✅ مصغر من spacingSm
                    vertical: PdfStyles.spacingXs,
                  ),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color: PdfStyles.borderColor,
                      width: 0.75,  // ✅ مصغر من 1
                    ),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    'التاريخ: $reportDate',
                    style: PdfStyles.captionStyle(),  // ✅ مصغر من smallStyle
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}