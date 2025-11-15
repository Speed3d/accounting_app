// lib/services/pdf_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:decimal/decimal.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/database_helper.dart';
import '../utils/decimal_extensions.dart';
import 'pdf_templates/pdf_footer.dart';
import 'pdf_templates/pdf_header.dart';
import 'pdf_templates/pdf_styles.dart';
import 'pdf_templates/pdf_table_builder.dart';

/// ========================================================================
/// 📄 خدمة PDF الرئيسية - Singleton Pattern
/// Hint: محدثة بالكامل لدعم Decimal
/// ========================================================================
class PdfService {
  // ============= Singleton Pattern =============
  static final PdfService _instance = PdfService._internal();
  PdfService._internal();
  factory PdfService() => _instance;
  static PdfService get instance => _instance;

  // ============= المتغيرات =============
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  // Hint: الخطوط (سيتم تحميلها مرة واحدة فقط)
  pw.Font? _arabicFont;
  pw.Font? _arabicFontBold;
  
  bool _fontsLoaded = false;

  // ============= تحميل الخطوط العربية =============
  
  /// ✅ Hint: تحميل الخطوط من الـ Assets
  Future<void> loadFonts() async {
    if (_fontsLoaded) return;

    try {
      _arabicFont = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Amiri-Regular.ttf'),
      );
      
      _arabicFontBold = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Amiri-Bold.ttf'),
      );

      _fontsLoaded = true;
    } catch (e) {
      print('❌ خطأ في تحميل الخطوط: $e');
      _fontsLoaded = false;
    }
  }

  // ============= الدوال المساعدة =============

  /// Hint: الحصول على بيانات الشركة
  Future<Map<String, String>> _getCompanyData() async {
    final settings = await _dbHelper.getAppSettings();
    
    return {
      'name': settings['companyName'] ?? 'اسم الشركة',
      'description': settings['companyDescription'] ?? '',
      'phone': settings['companyPhone'] ?? '',
      'address': settings['companyAddress'] ?? '',
      'email': settings['companyEmail'] ?? '',
      'registration': settings['companyRegistrationNumber'] ?? '',
      'logoPath': settings['companyLogoPath'] ?? '',
    };
  }

  /// Hint: الحصول على شعار الشركة
  File? _getCompanyLogo(String logoPath) {
    if (logoPath.isEmpty) return null;
    
    final file = File(logoPath);
    return file.existsSync() ? file : null;
  }

  /// Hint: تنسيق التاريخ
  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd', 'ar').format(date);
  }

  /// Hint: تنسيق الوقت
  String _formatTime(DateTime date) {
    return DateFormat('HH:mm:ss', 'ar').format(date);
  }

  /// ✅ Hint: تنسيق العملة - محدث لـ Decimal
  String _formatCurrency(Decimal amount) {
    final formatter = NumberFormat('#,##0.00', 'ar');
    return '${formatter.format(amount.toDouble())} د.ع';
  }

  /// ✅ Hint: تنسيق العملة من dynamic - محدث
  String _formatCurrencyDynamic(dynamic amount) {
    if (amount is Decimal) {
      return _formatCurrency(amount);
    }
    final decimal = DecimalHelper.fromDynamic(amount);
    return _formatCurrency(decimal);
  }

  // ============= بناء صفحة PDF أساسية =============
  
  /// ✅ Hint: بناء مستند PDF كامل
  Future<pw.Document> buildPdfDocument({
    required String reportTitle,
    required List<pw.Widget> content,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    pw.PageOrientation orientation = pw.PageOrientation.portrait,
  }) async {
    if (!_fontsLoaded) {
      await loadFonts();
    }

    final companyData = await _getCompanyData();
    final logoFile = _getCompanyLogo(companyData['logoPath']!);

    final pdf = pw.Document(
      title: reportTitle,
      author: companyData['name'],
      creator: 'نظام المحاسبة',
      theme: pw.ThemeData.withFont(
        base: _arabicFont,
        bold: _arabicFontBold,
      ),
    );

    final additionalInfo = <String, String>{};
    if (companyData['phone']!.isNotEmpty) {
      additionalInfo['هاتف'] = companyData['phone']!;
    }
    if (companyData['address']!.isNotEmpty) {
      additionalInfo['العنوان'] = companyData['address']!;
    }
    if (companyData['email']!.isNotEmpty) {
      additionalInfo['بريد'] = companyData['email']!;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        textDirection: pw.TextDirection.rtl,
        orientation: orientation,
        
        header: (context) => PdfHeader.build(
          companyName: companyData['name']!,
          reportTitle: reportTitle,
          reportDate: _formatDate(DateTime.now()),
          logoFile: logoFile,
          additionalInfo: additionalInfo.isNotEmpty ? additionalInfo : null,
        ),
        
        footer: (context) => PdfFooter.build(
          context: context,
          companyName: companyData['name']!,
          additionalText: companyData['registration']!.isNotEmpty
              ? 'س.ت: ${companyData['registration']}'
              : null,
        ),
        
        build: (context) => content,
      ),
    );

    return pdf;
  }

  // ============= حفظ ومشاركة PDF =============

  /// Hint: حفظ PDF في الجهاز
  Future<File> savePdf({
    required pw.Document pdf,
    required String fileName,
  }) async {
    try {
      final directory = await getExternalStorageDirectory();
      final downloadsPath = Directory('${directory!.parent.parent.parent.parent.path}/Download');
      
      if (!downloadsPath.existsSync()) {
        downloadsPath.createSync(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fullFileName = '${fileName}_$timestamp.pdf';
      final file = File('${downloadsPath.path}/$fullFileName');

      await file.writeAsBytes(await pdf.save());

      return file;
    } catch (e) {
      print('❌ خطأ في حفظ PDF: $e');
      rethrow;
    }
  }

  /// Hint: مشاركة PDF
  Future<void> sharePdf({
    required pw.Document pdf,
    required String fileName,
  }) async {
    try {
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: '$fileName.pdf',
      );
    } catch (e) {
      print('❌ خطأ في مشاركة PDF: $e');
      rethrow;
    }
  }

  /// Hint: طباعة PDF
  Future<void> printPdf({
    required pw.Document pdf,
  }) async {
    try {
      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
      );
    } catch (e) {
      print('❌ خطأ في طباعة PDF: $e');
      rethrow;
    }
  }

  /// Hint: معاينة PDF
  Future<void> previewPdf({
    required pw.Document pdf,
    required String fileName,
  }) async {
    try {
      await Printing.layoutPdf(
        name: fileName,
        onLayout: (format) async => pdf.save(),
      );
    } catch (e) {
      print('❌ خطأ في معاينة PDF: $e');
      rethrow;
    }
  }

  // ============= دوال بناء التقارير المختلفة =============

  /// ✅ Hint: تقرير بسيط
  Future<pw.Document> buildSimpleReport({
    required String reportTitle,
    required String summary,
    required Map<String, String> statistics,
    required List<String> tableHeaders,
    required List<List<String>> tableData,
  }) async {
    return await buildPdfDocument(
      reportTitle: reportTitle,
      content: [
        pw.Container(
          padding: const pw.EdgeInsets.all(PdfStyles.spacingSm),
          decoration: pw.BoxDecoration(
            color: PdfStyles.primaryColor.shade(0.05),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Text(
            summary,
            style: PdfStyles.bodyStyle(),
            textAlign: pw.TextAlign.center,
          ),
        ),

        pw.SizedBox(height: PdfStyles.spacingLg),

        if (statistics.isNotEmpty) ...[
          pw.Text('الإحصائيات', style: PdfStyles.headingStyle()),
          pw.SizedBox(height: PdfStyles.spacingMd),
          PdfTableBuilder.buildTwoColumnTable(data: statistics),
          pw.SizedBox(height: PdfStyles.spacingXl),
        ],

        pw.Text('التفاصيل', style: PdfStyles.headingStyle()),
        pw.SizedBox(height: PdfStyles.spacingMd),
        PdfTableBuilder.buildSimpleTable(
          headers: tableHeaders,
          data: tableData,
        ),
      ],
    );
  }

  // ============================================================================
  // 📊 تقرير مبيعات الزبائن ✅ محدث لـ Decimal
  // ============================================================================
     
  Future<pw.Document> buildCustomerSalesReport({
    required List<Map<String, dynamic>> salesData,
    required Map<String, dynamic> statistics,
    String? customerName,
    String? productName,
    String? supplierName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String reportTitle = 'تقرير مبيعات الزبائن';
    
    List<String> filterSummary = [];
    
    if (customerName != null) {
      filterSummary.add('الزبون: $customerName');
    }
    if (productName != null) {
      filterSummary.add('المنتج: $productName');
    }
    if (supplierName != null) {
      filterSummary.add('المورد: $supplierName');
    }
    if (startDate != null || endDate != null) {
      String dateRange = '';
      if (startDate != null && endDate != null) {
        dateRange = 'من ${_formatDate(startDate)} إلى ${_formatDate(endDate)}';
      } else if (startDate != null) {
        dateRange = 'من ${_formatDate(startDate)}';
      } else if (endDate != null) {
        dateRange = 'حتى ${_formatDate(endDate)}';
      }
      filterSummary.add(dateRange);
    }
    
    final content = <pw.Widget>[
      if (filterSummary.isNotEmpty) ...[
        pw.Container(
          padding: const pw.EdgeInsets.all(PdfStyles.spacingSm),
          decoration: pw.BoxDecoration(
            color: PdfStyles.primaryColor.shade(0.05),
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(
              color: PdfStyles.primaryColor.shade(0.2),
              width: 0.75,
            ),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'الفلاتر المطبقة:',
                style: PdfStyles.boldStyle(
                  fontSize: PdfStyles.fontSizeSubheading,
                ),
              ),
              pw.SizedBox(height: PdfStyles.spacingXs),
              ...filterSummary.map(
                (filter) => pw.Padding(
                  padding: const pw.EdgeInsets.only(
                    bottom: PdfStyles.spacingXs,
                  ),
                  child: pw.Row(
                    children: [
                      pw.Container(
                        width: 3,
                        height: 3,
                        decoration: pw.BoxDecoration(
                          color: PdfStyles.primaryColor,
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                      pw.SizedBox(width: PdfStyles.spacingXs),
                      pw.Text(filter, style: PdfStyles.bodyStyle()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: PdfStyles.spacingLg),
      ],
      
      pw.Text('الإحصائيات العامة', style: PdfStyles.headingStyle()),
      pw.SizedBox(height: PdfStyles.spacingSm),
      
      pw.Row(
        children: [
          pw.Expanded(
            child: _buildStatCard(
              title: 'إجمالي المبيعات',
              value: _formatCurrencyDynamic(statistics['totalSales']),
              color: PdfStyles.successColor,
            ),
          ),
          pw.SizedBox(width: PdfStyles.spacingSm),
          
          pw.Expanded(
            child: _buildStatCard(
              title: 'إجمالي الربح',
              value: _formatCurrencyDynamic(statistics['totalProfit']),
              color: PdfStyles.primaryColor,
            ),
          ),
        ],
      ),
      
      pw.SizedBox(height: PdfStyles.spacingSm),
      
      pw.Row(
        children: [
          pw.Expanded(
            child: _buildStatCard(
              title: 'عدد المعاملات',
              value: statistics['totalTransactions'].toString(),
              color: PdfStyles.secondaryColor,
            ),
          ),
          pw.SizedBox(width: PdfStyles.spacingSm),
          
          pw.Expanded(
            child: _buildStatCard(
              title: 'متوسط قيمة المعاملة',
              value: _formatCurrencyDynamic(statistics['averageTransaction']),
              color: PdfStyles.warningColor,
            ),
          ),
        ],
      ),
      
      pw.SizedBox(height: PdfStyles.spacingLg),
      
      pw.Text(
        'تفاصيل المبيعات (${salesData.length} معاملة)',
        style: PdfStyles.headingStyle(),
      ),
      pw.SizedBox(height: PdfStyles.spacingSm),
      
      if (salesData.isEmpty)
        pw.Container(
          padding: const pw.EdgeInsets.all(PdfStyles.spacingLg),
          decoration: pw.BoxDecoration(
            color: PdfStyles.backgroundLight,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Center(
            child: pw.Text(
              'لا توجد بيانات لعرضها',
              style: PdfStyles.bodyStyle(color: PdfStyles.textSecondary),
            ),
          ),
        )
      else
        _buildSalesTable(salesData),
      
      pw.SizedBox(height: PdfStyles.spacingLg),
      
      pw.Container(
        padding: const pw.EdgeInsets.all(PdfStyles.spacingSm),
        decoration: pw.BoxDecoration(
          color: PdfStyles.backgroundLight,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Row(
          children: [
            pw.Icon(
              pw.IconData(0xe88f),
              size: 12,
              color: PdfStyles.textSecondary,
            ),
            pw.SizedBox(width: PdfStyles.spacingXs),
            pw.Expanded(
              child: pw.Text(
                'هذا التقرير تم إنشاؤه آلياً بواسطة نظام المحاسبة. جميع الأرقام محسوبة من قاعدة البيانات.',
                style: PdfStyles.captionStyle(color: PdfStyles.textSecondary),
              ),
            ),
          ],
        ),
      ),
    ];
    
    return await buildPdfDocument(
      reportTitle: reportTitle,
      content: content,
    );
  }

  /// Hint: بناء بطاقة إحصائية
  pw.Widget _buildStatCard({
    required String title,
    required String value,
    required PdfColor color,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(
        horizontal: PdfStyles.spacingSm,
        vertical: PdfStyles.spacingXs,
      ),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1),
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(
          color: color.shade(0.3),
          width: 0.75,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            title,
            style: PdfStyles.captionStyle(color: color),
          ),
          pw.SizedBox(height: PdfStyles.spacingXs),
          pw.Text(
            value,
            style: PdfStyles.boldStyle(
              fontSize: PdfStyles.fontSizeSubheading,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Hint: بناء جدول المبيعات
  pw.Widget _buildSalesTable(List<Map<String, dynamic>> salesData) {
    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfStyles.borderColor,
        width: 0.5,
      ),
      columnWidths: {
        0: const pw.FixedColumnWidth(25),
        1: const pw.FixedColumnWidth(60),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FixedColumnWidth(35),
        5: const pw.FixedColumnWidth(60),
        6: const pw.FixedColumnWidth(60),
      },
      children: [
        pw.TableRow(
          decoration: PdfStyles.tableHeaderDecoration(),
          children: [
            _buildTableHeaderCell('#'),
            _buildTableHeaderCell('التاريخ'),
            _buildTableHeaderCell('الزبون'),
            _buildTableHeaderCell('المنتج'),
            _buildTableHeaderCell('الكمية'),
            _buildTableHeaderCell('المبلغ'),
            _buildTableHeaderCell('الربح'),
          ],
        ),
        
        ...salesData.asMap().entries.map((entry) {
          final index = entry.key;
          final sale = entry.value;
          final isEven = index % 2 == 0;
          
          return pw.TableRow(
            decoration: isEven
                ? PdfStyles.tableCellDecorationEven()
                : PdfStyles.tableCellDecorationOdd(),
            children: [
              _buildTableCell((index + 1).toString()),
              _buildTableCell(
                _formatDate(DateTime.parse(sale['saleDate'])),
              ),
              _buildTableCell(sale['customerName'] ?? ''),
              _buildTableCell(sale['productName'] ?? ''),
              _buildTableCell(sale['quantity'].toString()),
              _buildTableCell(_formatCurrencyDynamic(sale['amount'])),
              _buildTableCell(_formatCurrencyDynamic(sale['profit'])),
            ],
          );
        }),
      ],
    );
  }

  /// Hint: بناء خلية رأس الجدول
  pw.Widget _buildTableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
        horizontal: PdfStyles.spacingXs,
        vertical: PdfStyles.spacingXs,
      ),
      child: pw.Text(
        text,
        style: PdfStyles.tableHeaderStyle(),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Hint: بناء خلية الجدول العادية
  pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
        horizontal: PdfStyles.spacingXs,
        vertical: PdfStyles.spacingXs,
      ),
      child: pw.Text(
        text,
        style: PdfStyles.tableCellStyle(),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // ============================================================================
  // 💰 تقرير التدفق النقدي ✅ محدث لـ Decimal
  // ============================================================================
  
  Future<pw.Document> buildCashFlowReport({
    required List<Map<String, dynamic>> transactions,
    required Decimal totalCashSales,
    required Decimal totalDebtPayments,
    required Decimal totalCashIn,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final content = <pw.Widget>[
      pw.Container(
        padding: const pw.EdgeInsets.all(PdfStyles.spacingSm),
        decoration: pw.BoxDecoration(
          color: PdfStyles.primaryColor.shade(0.05),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Icon(
              pw.IconData(0xe916),
              size: 16,
              color: PdfStyles.primaryColor,
            ),
            pw.SizedBox(width: PdfStyles.spacingXs),
            pw.Text(
              'الفترة: ${_formatDate(startDate)} - ${_formatDate(endDate)}',
              style: PdfStyles.boldStyle(color: PdfStyles.primaryColor),
            ),
          ],
        ),
      ),

      pw.SizedBox(height: PdfStyles.spacingLg),

      pw.Text('الإحصائيات العامة', style: PdfStyles.headingStyle()),
      pw.SizedBox(height: PdfStyles.spacingSm),

      pw.Row(
        children: [
          pw.Expanded(
            child: _buildStatCard(
              title: 'المبيعات النقدية',
              value: _formatCurrency(totalCashSales),
              color: PdfStyles.secondaryColor,
            ),
          ),
          pw.SizedBox(width: PdfStyles.spacingSm),
          pw.Expanded(
            child: _buildStatCard(
              title: 'تسديدات الديون',
              value: _formatCurrency(totalDebtPayments),
              color: PdfStyles.warningColor,
            ),
          ),
        ],
      ),

      pw.SizedBox(height: PdfStyles.spacingSm),

      _buildStatCard(
        title: 'إجمالي التدفق النقدي',
        value: _formatCurrency(totalCashIn),
        color: PdfStyles.successColor,
      ),

      pw.SizedBox(height: PdfStyles.spacingLg),

      pw.Text(
        'تفاصيل المعاملات (${transactions.length} معاملة)',
        style: PdfStyles.headingStyle(),
      ),
      pw.SizedBox(height: PdfStyles.spacingSm),

      if (transactions.isEmpty)
        pw.Container(
          padding: const pw.EdgeInsets.all(PdfStyles.spacingLg),
          child: pw.Center(
            child: pw.Text(
              'لا توجد معاملات في هذه الفترة',
              style: PdfStyles.bodyStyle(color: PdfStyles.textSecondary),
            ),
          ),
        )
      else
        _buildCashFlowTable(transactions),
    ];

    return await buildPdfDocument(
      reportTitle: 'تقرير التدفق النقدي',
      content: content,
    );
  }

  /// Hint: بناء جدول التدفق النقدي
  pw.Widget _buildCashFlowTable(List<Map<String, dynamic>> transactions) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfStyles.borderColor, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(25),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(3),
        3: const pw.FixedColumnWidth(70),
        4: const pw.FixedColumnWidth(60),
      },
      children: [
        pw.TableRow(
          decoration: PdfStyles.tableHeaderDecoration(),
          children: [
            _buildTableHeaderCell('#'),
            _buildTableHeaderCell('النوع'),
            _buildTableHeaderCell('الوصف'),
            _buildTableHeaderCell('التاريخ'),
            _buildTableHeaderCell('المبلغ'),
          ],
        ),

        ...transactions.asMap().entries.map((entry) {
          final index = entry.key;
          final trans = entry.value;
          final isEven = index % 2 == 0;
          final isCashSale = trans['type'] == 'CASH_SALE';

          return pw.TableRow(
            decoration: isEven
                ? PdfStyles.tableCellDecorationEven()
                : PdfStyles.tableCellDecorationOdd(),
            children: [
              _buildTableCell((index + 1).toString()),
              pw.Container(
                padding: const pw.EdgeInsets.all(PdfStyles.spacingXs),
                child: pw.Center(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: pw.BoxDecoration(
                      color: isCashSale
                          ? PdfStyles.secondaryColor.shade(0.2)
                          : PdfStyles.warningColor.shade(0.2),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      isCashSale ? 'نقدي' : 'تسديد',
                      style: PdfStyles.captionStyle(
                        color: isCashSale
                            ? PdfStyles.secondaryColor
                            : PdfStyles.warningColor,
                      ),
                    ),
                  ),
                ),
              ),
              _buildTableCell(trans['description'] ?? ''),
              _buildTableCell(_formatDate(DateTime.parse(trans['date']))),
              _buildTableCell(_formatCurrencyDynamic(trans['amount'])),
            ],
          );
        }),
      ],
    );
  }

  // ============================================================================
  // 📊 تقرير الأرباح العام ✅ محدث لـ Decimal
  // ============================================================================
  
  Future<pw.Document> buildProfitReport({
    required Decimal totalProfit,
    required Decimal totalExpenses,
    required Decimal totalWithdrawals,
    required Decimal netProfit,
    required List<Map<String, dynamic>> salesData,
  }) async {
    final content = <pw.Widget>[
      pw.Text('الملخص المالي', style: PdfStyles.headingStyle()),
      pw.SizedBox(height: PdfStyles.spacingSm),

      _buildStatCard(
        title: 'إجمالي الأرباح من المبيعات',
        value: _formatCurrency(totalProfit),
        color: PdfStyles.secondaryColor,
      ),

      pw.SizedBox(height: PdfStyles.spacingSm),

      pw.Row(
        children: [
          pw.Expanded(
            child: _buildStatCard(
              title: 'المصاريف العامة',
              value: _formatCurrency(totalExpenses),
              color: PdfStyles.errorColor,
            ),
          ),
          pw.SizedBox(width: PdfStyles.spacingSm),
          pw.Expanded(
            child: _buildStatCard(
              title: 'مسحوبات الأرباح',
              value: _formatCurrency(totalWithdrawals),
              color: PdfStyles.warningColor,
            ),
          ),
        ],
      ),

      pw.Divider(height: 24),

      pw.Container(
        padding: const pw.EdgeInsets.all(PdfStyles.spacingMd),
        decoration: pw.BoxDecoration(
          color: netProfit >= Decimal.zero
              ? PdfStyles.successColor.shade(0.1)
              : PdfStyles.errorColor.shade(0.1),
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(
            color: netProfit >= Decimal.zero
                ? PdfStyles.successColor.shade(0.3)
                : PdfStyles.errorColor.shade(0.3),
            width: 1.5,
          ),
        ),
        child: pw.Row(
          children: [
            pw.Icon(
              netProfit >= Decimal.zero
                  ? pw.IconData(0xe5ca)
                  : pw.IconData(0xe5c7),
              size: 30,
              color: netProfit >= Decimal.zero
                  ? PdfStyles.successColor
                  : PdfStyles.errorColor,
            ),
            pw.SizedBox(width: PdfStyles.spacingSm),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('صافي الربح', style: PdfStyles.bodyStyle()),
                  pw.SizedBox(height: PdfStyles.spacingXs),
                  pw.Text(
                    _formatCurrency(netProfit),
                    style: PdfStyles.boldStyle(
                      fontSize: 18,
                      color: netProfit >= Decimal.zero
                          ? PdfStyles.successColor
                          : PdfStyles.errorColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      pw.SizedBox(height: PdfStyles.spacingLg),

      if (salesData.isNotEmpty) ...[
        pw.Text(
          'تفاصيل المبيعات (${salesData.length} عملية)',
          style: PdfStyles.headingStyle(),
        ),
        pw.SizedBox(height: PdfStyles.spacingSm),
        _buildSalesDetailTable(salesData),
      ],
    ];

    return await buildPdfDocument(
      reportTitle: 'تقرير الأرباح العام',
      content: content,
    );
  }

  /// Hint: بناء جدول تفاصيل المبيعات
  pw.Widget _buildSalesDetailTable(List<Map<String, dynamic>> salesData) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfStyles.borderColor, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(25),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FixedColumnWidth(60),
        4: const pw.FixedColumnWidth(60),
        5: const pw.FixedColumnWidth(60),
      },
      children: [
        pw.TableRow(
          decoration: PdfStyles.tableHeaderDecoration(),
          children: [
            _buildTableHeaderCell('#'),
            _buildTableHeaderCell('المنتج'),
            _buildTableHeaderCell('الزبون'),
            _buildTableHeaderCell('التاريخ'),
            _buildTableHeaderCell('المبلغ'),
            _buildTableHeaderCell('الربح'),
          ],
        ),
        ...salesData.asMap().entries.map((entry) {
          final index = entry.key;
          final sale = entry.value;
          final isEven = index % 2 == 0;

          return pw.TableRow(
            decoration: isEven
                ? PdfStyles.tableCellDecorationEven()
                : PdfStyles.tableCellDecorationOdd(),
            children: [
              _buildTableCell((index + 1).toString()),
              _buildTableCell(sale['details'] ?? ''),
              _buildTableCell(sale['customerName'] ?? ''),
              _buildTableCell(_formatDate(DateTime.parse(sale['dateT']))),
              _buildTableCell(_formatCurrencyDynamic(sale['debt'])),
              _buildTableCell(_formatCurrencyDynamic(sale['profitAmount'])),
            ],
          );
        }),
      ],
    );
  }

  // ============================================================================
  // 🏢 تقرير أرباح الموردين ✅ محدث لـ Decimal
  // ============================================================================
  
  Future<pw.Document> buildSupplierProfitReport({
    required List<Map<String, dynamic>> suppliersData,
  }) async {
    final content = <pw.Widget>[
      pw.Text(
        'ملخص أرباح الموردين (${suppliersData.length} مورد)',
        style: PdfStyles.headingStyle(),
      ),
      pw.SizedBox(height: PdfStyles.spacingSm),

      _buildSuppliersProfitTable(suppliersData),
    ];

    return await buildPdfDocument(
      reportTitle: 'تقرير أرباح الموردين',
      content: content,
    );
  }

  /// Hint: بناء جدول أرباح الموردين
  pw.Widget _buildSuppliersProfitTable(List<Map<String, dynamic>> data) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfStyles.borderColor, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(25),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FixedColumnWidth(70),
        4: const pw.FixedColumnWidth(70),
        5: const pw.FixedColumnWidth(70),
      },
      children: [
        pw.TableRow(
          decoration: PdfStyles.tableHeaderDecoration(),
          children: [
            _buildTableHeaderCell('#'),
            _buildTableHeaderCell('اسم المورد'),
            _buildTableHeaderCell('النوع'),
            _buildTableHeaderCell('إجمالي الربح'),
            _buildTableHeaderCell('المسحوبات'),
            _buildTableHeaderCell('صافي الربح'),
          ],
        ),
        ...data.asMap().entries.map((entry) {
          final index = entry.key;
          final supplier = entry.value;
          final isEven = index % 2 == 0;
          
          final totalProfit = DecimalHelper.fromDynamic(supplier['totalProfit']);
          final totalWithdrawn = DecimalHelper.fromDynamic(supplier['totalWithdrawn']);
          final netProfit = totalProfit - totalWithdrawn;

          return pw.TableRow(
            decoration: isEven
                ? PdfStyles.tableCellDecorationEven()
                : PdfStyles.tableCellDecorationOdd(),
            children: [
              _buildTableCell((index + 1).toString()),
              _buildTableCell(supplier['supplierName'] ?? ''),
              pw.Container(
                padding: const pw.EdgeInsets.all(PdfStyles.spacingXs),
                child: pw.Center(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: pw.BoxDecoration(
                      color: supplier['supplierType'] == 'شراكة'
                          ? PdfStyles.secondaryColor.shade(0.2)
                          : PdfStyles.primaryColor.shade(0.2),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      supplier['supplierType'] ?? '',
                      style: PdfStyles.captionStyle(),
                    ),
                  ),
                ),
              ),
              _buildTableCell(_formatCurrency(totalProfit)),
              _buildTableCell(_formatCurrency(totalWithdrawn)),
              _buildTableCell(_formatCurrency(netProfit)),
            ],
          );
        }),
      ],
    );
  }

  // ============================================================================
  // 👥 تقرير الموظفين ✅ محدث لـ Decimal
  // ============================================================================
  
  Future<pw.Document> buildEmployeesReport({
    required Decimal totalSalaries,
    required Decimal totalAdvances,
    required int employeesCount,
    required List<Map<String, dynamic>> employeesData,
  }) async {
    final content = <pw.Widget>[
      pw.Text('الإحصائيات العامة', style: PdfStyles.headingStyle()),
      pw.SizedBox(height: PdfStyles.spacingSm),

      pw.Row(
        children: [
          pw.Expanded(
            child: _buildStatCard(
              title: 'إجمالي الرواتب المدفوعة',
              value: _formatCurrency(totalSalaries),
              color: PdfStyles.successColor,
            ),
          ),
          pw.SizedBox(width: PdfStyles.spacingSm),
          pw.Expanded(
            child: _buildStatCard(
              title: 'إجمالي السلف المستحقة',
              value: _formatCurrency(totalAdvances),
              color: PdfStyles.warningColor,
            ),
          ),
        ],
      ),

      pw.SizedBox(height: PdfStyles.spacingSm),

      _buildStatCard(
        title: 'عدد الموظفين النشطين',
        value: employeesCount.toString(),
        color: PdfStyles.secondaryColor,
      ),

      pw.SizedBox(height: PdfStyles.spacingLg),

      pw.Text(
        'قائمة الموظفين (${employeesData.length} موظف)',
        style: PdfStyles.headingStyle(),
      ),
      pw.SizedBox(height: PdfStyles.spacingSm),

      _buildEmployeesTable(employeesData),
    ];

    return await buildPdfDocument(
      reportTitle: 'تقرير الموظفين',
      content: content,
    );
  }

  /// Hint: بناء جدول الموظفين
  pw.Widget _buildEmployeesTable(List<Map<String, dynamic>> data) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfStyles.borderColor, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(25),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FixedColumnWidth(70),
        4: const pw.FixedColumnWidth(70),
      },
      children: [
        pw.TableRow(
          decoration: PdfStyles.tableHeaderDecoration(),
          children: [
            _buildTableHeaderCell('#'),
            _buildTableHeaderCell('الاسم'),
            _buildTableHeaderCell('المنصب'),
            _buildTableHeaderCell('الراتب الأساسي'),
            _buildTableHeaderCell('رصيد السلف'),
          ],
        ),
        ...data.asMap().entries.map((entry) {
          final index = entry.key;
          final employee = entry.value;
          final isEven = index % 2 == 0;

          return pw.TableRow(
            decoration: isEven
                ? PdfStyles.tableCellDecorationEven()
                : PdfStyles.tableCellDecorationOdd(),
            children: [
              _buildTableCell((index + 1).toString()),
              _buildTableCell(employee['fullName'] ?? ''),
              _buildTableCell(employee['jobTitle'] ?? ''),
              _buildTableCell(_formatCurrencyDynamic(employee['baseSalary'] ?? 0)),
              _buildTableCell(_formatCurrencyDynamic(employee['balance'] ?? 0)),
            ],
          );
        }),
      ],
    );
  }

  // ============================================================================
  // 🏢 تقرير تفاصيل المورد ✅ محدث لـ Decimal
  // ============================================================================
  
  Future<pw.Document> buildSupplierDetailsReport({
    required String supplierName,
    required String supplierType,
    required Decimal totalProfit,
    required Decimal totalWithdrawn,
    required Decimal netProfit,
    required List<Map<String, Object>> partnersData,
    required List<Map<String, dynamic>> withdrawalsData,
  }) async {
    final isPartnership = supplierType.contains('شراكة') || supplierType.contains('partnership');
    final supplierColor = isPartnership ? PdfStyles.secondaryColor : PdfStyles.primaryColor;
    
    final content = <pw.Widget>[
      pw.Container(
        padding: const pw.EdgeInsets.all(PdfStyles.spacingSm),
        decoration: pw.BoxDecoration(
          color: supplierColor.shade(0.05),
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(
            color: supplierColor.shade(0.2),
            width: 0.75,
          ),
        ),
        child: pw.Row(
          children: [
            pw.Icon(
              isPartnership ? pw.IconData(0xe7fb) : pw.IconData(0xe0af),
              size: 24,
              color: supplierColor,
            ),
            pw.SizedBox(width: PdfStyles.spacingSm),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    supplierName,
                    style: PdfStyles.boldStyle(
                      fontSize: PdfStyles.fontSizeHeading,
                    ),
                  ),
                  pw.SizedBox(height: PdfStyles.spacingXs),
                  pw.Text(
                    'النوع: $supplierType',
                    style: PdfStyles.captionStyle(color: supplierColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      pw.SizedBox(height: PdfStyles.spacingLg),

      pw.Text('الملخص المالي', style: PdfStyles.headingStyle()),
      pw.SizedBox(height: PdfStyles.spacingSm),

      pw.Row(
        children: [
          pw.Expanded(
            child: _buildStatCard(
              title: 'إجمالي الأرباح',
              value: _formatCurrency(totalProfit),
              color: PdfStyles.successColor,
            ),
          ),
          pw.SizedBox(width: PdfStyles.spacingSm),
          pw.Expanded(
            child: _buildStatCard(
              title: 'المسحوبات',
              value: _formatCurrency(totalWithdrawn),
              color: PdfStyles.errorColor,
            ),
          ),
        ],
      ),

      pw.SizedBox(height: PdfStyles.spacingSm),

      pw.Container(
        padding: const pw.EdgeInsets.all(PdfStyles.spacingMd),
        decoration: pw.BoxDecoration(
          color: netProfit >= Decimal.zero
              ? PdfStyles.successColor.shade(0.1)
              : PdfStyles.errorColor.shade(0.1),
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(
            color: netProfit >= Decimal.zero
                ? PdfStyles.successColor.shade(0.3)
                : PdfStyles.errorColor.shade(0.3),
            width: 1.5,
          ),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Row(
              children: [
                pw.Icon(
                  pw.IconData(0xe850),
                  size: 24,
                  color: netProfit >= Decimal.zero ? PdfStyles.successColor : PdfStyles.errorColor,
                ),
                pw.SizedBox(width: PdfStyles.spacingSm),
                pw.Text(
                  'صافي الربح المتبقي',
                  style: PdfStyles.boldStyle(),
                ),
              ],
            ),
            pw.Text(
              _formatCurrency(netProfit),
              style: PdfStyles.boldStyle(
                fontSize: PdfStyles.fontSizeHeading,
                color: netProfit >= Decimal.zero ? PdfStyles.successColor : PdfStyles.errorColor,
              ),
            ),
          ],
        ),
      ),

      pw.SizedBox(height: PdfStyles.spacingLg),

      if (isPartnership && partnersData.isNotEmpty) ...[
        pw.Text(
          'توزيع الأرباح على الشركاء (${partnersData.length} شريك)',
          style: PdfStyles.headingStyle(),
        ),
        pw.SizedBox(height: PdfStyles.spacingSm),
        _buildPartnersTable(partnersData),
        pw.SizedBox(height: PdfStyles.spacingLg),
      ],

      pw.Text(
        'سجل المسحوبات (${withdrawalsData.length} عملية)',
        style: PdfStyles.headingStyle(),
      ),
      pw.SizedBox(height: PdfStyles.spacingSm),

      if (withdrawalsData.isEmpty)
        pw.Container(
          padding: const pw.EdgeInsets.all(PdfStyles.spacingLg),
          decoration: pw.BoxDecoration(
            color: PdfStyles.backgroundLight,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Center(
            child: pw.Text(
              'لا توجد مسحوبات مسجلة',
              style: PdfStyles.bodyStyle(color: PdfStyles.textSecondary),
            ),
          ),
        )
      else
        _buildWithdrawalsTable(withdrawalsData, supplierName),

      pw.SizedBox(height: PdfStyles.spacingLg),

      pw.Container(
        padding: const pw.EdgeInsets.all(PdfStyles.spacingSm),
        decoration: pw.BoxDecoration(
          color: PdfStyles.backgroundLight,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Row(
          children: [
            pw.Icon(
              pw.IconData(0xe88f),
              size: 12,
              color: PdfStyles.textSecondary,
            ),
            pw.SizedBox(width: PdfStyles.spacingXs),
            pw.Expanded(
              child: pw.Text(
                'هذا التقرير يعرض تفاصيل الأرباح والمسحوبات للمورد/الشراكة. جميع الأرقام محدثة حتى تاريخ الطباعة.',
                style: PdfStyles.captionStyle(color: PdfStyles.textSecondary),
              ),
            ),
          ],
        ),
      ),
    ];

    return await buildPdfDocument(
      reportTitle: 'تقرير تفاصيل: $supplierName',
      content: content,
    );
  }

  /// Hint: بناء جدول الشركاء
  pw.Widget _buildPartnersTable(List<Map<String, Object>> partnersData) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfStyles.borderColor, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(25),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FixedColumnWidth(70),
        3: const pw.FixedColumnWidth(80),
      },
      children: [
        pw.TableRow(
          decoration: PdfStyles.tableHeaderDecoration(),
          children: [
            _buildTableHeaderCell('#'),
            _buildTableHeaderCell('اسم الشريك'),
            _buildTableHeaderCell('النسبة %'),
            _buildTableHeaderCell('نصيب الربح'),
          ],
        ),
        ...partnersData.asMap().entries.map((entry) {
          final index = entry.key;
          final partner = entry.value;
          final isEven = index % 2 == 0;

          return pw.TableRow(
            decoration: isEven
                ? PdfStyles.tableCellDecorationEven()
                : PdfStyles.tableCellDecorationOdd(),
            children: [
              _buildTableCell((index + 1).toString()),
              _buildTableCell(partner['partnerName'].toString()),
              pw.Container(
                padding: const pw.EdgeInsets.all(PdfStyles.spacingXs),
                child: pw.Center(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfStyles.successColor.shade(0.2),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      '${partner['sharePercentage']}%',
                      style: PdfStyles.captionStyle(color: PdfStyles.successColor),
                    ),
                  ),
                ),
              ),
              _buildTableCell(
                _formatCurrencyDynamic(partner['partnerShare']),
              ),
            ],
          );
        }),
      ],
    );
  }

  /// Hint: بناء جدول المسحوبات
  pw.Widget _buildWithdrawalsTable(List<Map<String, dynamic>> withdrawalsData, String supplierName) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfStyles.borderColor, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(25),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FixedColumnWidth(70),
        3: const pw.FixedColumnWidth(70),
        4: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: PdfStyles.tableHeaderDecoration(),
          children: [
            _buildTableHeaderCell('#'),
            _buildTableHeaderCell('المستفيد'),
            _buildTableHeaderCell('التاريخ'),
            _buildTableHeaderCell('المبلغ'),
            _buildTableHeaderCell('ملاحظات'),
          ],
        ),
        ...withdrawalsData.asMap().entries.map((entry) {
          final index = entry.key;
          final withdrawal = entry.value;
          final isEven = index % 2 == 0;
          
          final partnerName = withdrawal['PartnerName'] as String?;
          final amount = DecimalHelper.fromDynamic(withdrawal['WithdrawalAmount']);
          final date = DateTime.parse(withdrawal['WithdrawalDate'] as String);
          final notes = withdrawal['Notes'] as String?;

          return pw.TableRow(
            decoration: isEven
                ? PdfStyles.tableCellDecorationEven()
                : PdfStyles.tableCellDecorationOdd(),
            children: [
              _buildTableCell((index + 1).toString()),
              _buildTableCell(partnerName ?? supplierName),
              _buildTableCell(_formatDate(date)),
              pw.Padding(
                padding: const pw.EdgeInsets.all(PdfStyles.spacingXs),
                child: pw.Text(
                  _formatCurrency(amount),
                  style: PdfStyles.tableCellStyle().copyWith(
                    color: PdfStyles.errorColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              _buildTableCell(notes ?? '-'),
            ],
          );
        }),
      ],
    );
  }
}