// lib/services/pdf_templates/pdf_table_builder.dart

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'pdf_styles.dart';

/// 📊 بناء الجداول الاحترافية في PDF
class PdfTableBuilder {
  /// بناء جدول بسيط
  /// 
  /// المعاملات:
  /// - [headers]: عناوين الأعمدة
  /// - [data]: بيانات الصفوف
  /// - [columnWidths]: عرض الأعمدة (اختياري)
  /// - [headerColor]: لون رأس الجدول (اختياري)
  static pw.Widget buildSimpleTable({
    required List<String> headers,
    required List<List<String>> data,
    Map<int, pw.TableColumnWidth>? columnWidths,
    PdfColor? headerColor,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfStyles.borderColor, width: 0.5),
      columnWidths: columnWidths,
      children: [
        // رأس الجدول
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: headerColor ?? PdfStyles.primaryColor,
          ),
          children: headers.map((header) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(PdfStyles.spacingSm),
              child: pw.Text(
                header,
                style: PdfStyles.tableHeaderStyle(),
                textAlign: pw.TextAlign.center,
              ),
            );
          }).toList(),
        ),

        // صفوف البيانات
        ...data.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          final isEven = index % 2 == 0;

          return pw.TableRow(
            decoration: isEven
                ? PdfStyles.tableCellDecorationEven()
                : PdfStyles.tableCellDecorationOdd(),
            children: row.map((cell) {
              return pw.Padding(
                padding: const pw.EdgeInsets.all(PdfStyles.spacingSm),
                child: pw.Text(
                  cell,
                  style: PdfStyles.tableCellStyle(),
                  textAlign: pw.TextAlign.center,
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  /// بناء جدول متقدم مع تنسيق خاص
  /// 
  /// المعاملات:
  /// - [headers]: عناوين الأعمدة
  /// - [data]: بيانات الصفوف (Map لكل صف)
  /// - [columnWidths]: عرض الأعمدة
  /// - [showTotal]: إظهار صف الإجمالي (اختياري)
  /// - [totalLabel]: تسمية الإجمالي
  /// - [totalValue]: قيمة الإجمالي
  static pw.Widget buildAdvancedTable({
    required List<String> headers,
    required List<Map<String, dynamic>> data,
    Map<int, pw.TableColumnWidth>? columnWidths,
    bool showTotal = false,
    String totalLabel = 'الإجمالي',
    String? totalValue,
  }) {
    return pw.Column(
      children: [
        // الجدول الأساسي
        pw.Table(
          border: pw.TableBorder.all(color: PdfStyles.borderColor, width: 0.5),
          columnWidths: columnWidths,
          children: [
            // رأس الجدول
            pw.TableRow(
              decoration: PdfStyles.tableHeaderDecoration(),
              children: headers.map((header) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.all(PdfStyles.spacingSm),
                  child: pw.Text(
                    header,
                    style: PdfStyles.tableHeaderStyle(),
                    textAlign: pw.TextAlign.center,
                  ),
                );
              }).toList(),
            ),

            // صفوف البيانات
            ...data.asMap().entries.map((entry) {
              final index = entry.key;
              final row = entry.value;
              final isEven = index % 2 == 0;

              return pw.TableRow(
                decoration: isEven
                    ? PdfStyles.tableCellDecorationEven()
                    : PdfStyles.tableCellDecorationOdd(),
                children: headers.map((header) {
                  final value = row[header]?.toString() ?? '';
                  return pw.Padding(
                    padding: const pw.EdgeInsets.all(PdfStyles.spacingSm),
                    child: pw.Text(
                      value,
                      style: PdfStyles.tableCellStyle(),
                      textAlign: pw.TextAlign.center,
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),

        // صف الإجمالي (اختياري)
        if (showTotal && totalValue != null) ...[
          pw.SizedBox(height: PdfStyles.spacingSm),
          pw.Container(
            padding: const pw.EdgeInsets.all(PdfStyles.spacingMd),
            decoration: pw.BoxDecoration(
              color: PdfStyles.primaryColor.shade(0.1),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  totalLabel,
                  style: PdfStyles.boldStyle(),
                ),
                pw.Text(
                  totalValue,
                  style: PdfStyles.boldStyle(color: PdfStyles.primaryColor),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// بناء جدول بعمودين (مناسب للإحصائيات)
  static pw.Widget buildTwoColumnTable({
    required Map<String, String> data,
    PdfColor? labelColor,
    PdfColor? valueColor,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfStyles.borderColor, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
      },
      children: data.entries.map((entry) {
        return pw.TableRow(
          children: [
            // العمود الأول: التسمية
            pw.Container(
              padding: const pw.EdgeInsets.all(PdfStyles.spacingSm),
              decoration: pw.BoxDecoration(
                color: PdfStyles.backgroundLight,
              ),
              child: pw.Text(
                entry.key,
                style: PdfStyles.boldStyle(
                  fontSize: PdfStyles.fontSizeSmall,
                  color: labelColor ?? PdfStyles.textSecondary,
                ),
              ),
            ),

            // العمود الثاني: القيمة
            pw.Padding(
              padding: const pw.EdgeInsets.all(PdfStyles.spacingSm),
              child: pw.Text(
                entry.value,
                style: PdfStyles.bodyStyle(
                  color: valueColor ?? PdfStyles.textPrimary,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}