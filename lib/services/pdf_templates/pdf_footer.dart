// lib/services/pdf_templates/pdf_footer.dart

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'pdf_styles.dart';

/// 📄 بناء تذييل الصفحة (Footer) الموحد
class PdfFooter {
  /// بناء الـ Footer
  /// 
  /// المعاملات:
  /// - [context]: سياق الصفحة (للحصول على رقم الصفحة)
  /// - [companyName]: اسم الشركة
  /// - [additionalText]: نص إضافي (اختياري)
  static pw.Widget build({
    required pw.Context context,
    required String companyName,
    String? additionalText,
  }) {
    // الحصول على رقم الصفحة
    final pageNumber = context.pageNumber;
    final totalPages = context.pagesCount;

    return pw.Container(
      padding: const pw.EdgeInsets.all(PdfStyles.spacingMd),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(
            color: PdfStyles.borderColor,
            width: 1,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // القسم الأيمن: اسم الشركة
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  companyName,
                  style: PdfStyles.smallStyle(color: PdfStyles.textSecondary),
                ),
                if (additionalText != null) ...[
                  pw.SizedBox(height: PdfStyles.spacingXs),
                  pw.Text(
                    additionalText,
                    style: PdfStyles.captionStyle(),
                  ),
                ],
              ],
            ),
          ),

          // القسم الأوسط: تاريخ ووقت الطباعة
          pw.Expanded(
            child: pw.Center(
              child: pw.Text(
                'تم الإنشاء: ${DateTime.now().toString().split('.')[0]}',
                style: PdfStyles.captionStyle(),
              ),
            ),
          ),

          // القسم الأيسر: رقم الصفحة
          pw.Expanded(
            child: pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: PdfStyles.spacingSm,
                  vertical: PdfStyles.spacingXs,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfStyles.backgroundLight,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'صفحة $pageNumber من $totalPages',
                  style: PdfStyles.smallStyle(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}