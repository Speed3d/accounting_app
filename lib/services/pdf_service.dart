// lib/services/pdf_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/database_helper.dart';
import 'pdf_templates/pdf_footer.dart';
import 'pdf_templates/pdf_header.dart';
import 'pdf_templates/pdf_styles.dart';
import 'pdf_templates/pdf_table_builder.dart';

/// 📄 خدمة PDF الرئيسية - Singleton Pattern
/// Hint: هذه الخدمة هي القلب النابض لنظام PDF
class PdfService {
  // ============= Singleton Pattern =============
  static final PdfService _instance = PdfService._internal();
  PdfService._internal();
  factory PdfService() => _instance;
  static PdfService get instance => _instance;

  // ============= المتغيرات =============
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  // الخطوط (سيتم تحميلها مرة واحدة فقط)
  pw.Font? _arabicFont;
  pw.Font? _arabicFontBold;
  
  bool _fontsLoaded = false;

  // ============= تحميل الخطوط العربية =============
  
  /// ✅ Hint: تحميل الخطوط من الـ Assets
  /// يجب استدعاء هذه الدالة مرة واحدة عند بدء التطبيق
  Future<void> loadFonts() async {
    if (_fontsLoaded) return; // تجنب التحميل المتكرر

    try {
      // ✅ Hint: تحميل خط Amiri العربي (عادي وغامق)
      _arabicFont = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Amiri-Regular.ttf'),
      );
      
      _arabicFontBold = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Amiri-Bold.ttf'),
      );

      _fontsLoaded = true;
    } catch (e) {
      print('❌ خطأ في تحميل الخطوط: $e');
      // في حالة الفشل، سنستخدم الخط الافتراضي
      _fontsLoaded = false;
    }
  }

  // ============= الدوال المساعدة =============

  /// الحصول على بيانات الشركة من قاعدة البيانات
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

  /// الحصول على شعار الشركة
  File? _getCompanyLogo(String logoPath) {
    if (logoPath.isEmpty) return null;
    
    final file = File(logoPath);
    return file.existsSync() ? file : null;
  }

  /// تنسيق التاريخ
  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd', 'ar').format(date);
  }

  /// تنسيق الوقت
  String _formatTime(DateTime date) {
    return DateFormat('HH:mm:ss', 'ar').format(date);
  }

  /// تنسيق العملة
  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'ar');
    return '${formatter.format(amount)} د.ع';
  }

  // ============= بناء صفحة PDF أساسية =============
  
  /// ✅ بناء مستند PDF كامل
  /// 
  /// المعاملات:
  /// - [reportTitle]: عنوان التقرير
  /// - [content]: محتوى التقرير (Widget)
  /// - [pageFormat]: حجم الصفحة (افتراضي A4)
  /// - [orientation]: اتجاه الصفحة (افتراضي عمودي)
  Future<pw.Document> buildPdfDocument({
    required String reportTitle,
    required List<pw.Widget> content,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    pw.PageOrientation orientation = pw.PageOrientation.portrait,
  }) async {
    // تحميل الخطوط إذا لم تكن محملة
    if (!_fontsLoaded) {
      await loadFonts();
    }

    // الحصول على بيانات الشركة
    final companyData = await _getCompanyData();
    final logoFile = _getCompanyLogo(companyData['logoPath']!);

    // إنشاء مستند PDF
    final pdf = pw.Document(
      title: reportTitle,
      author: companyData['name'],
      creator: 'نظام المحاسبة',
      theme: pw.ThemeData.withFont(
        base: _arabicFont,
        bold: _arabicFontBold,
      ),
    );

    // بناء معلومات الشركة الإضافية للـ Header
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

    // إضافة الصفحات
    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        textDirection: pw.TextDirection.rtl, // ✅ دعم العربية
        orientation: orientation,
        
        // Header الموحد
        header: (context) => PdfHeader.build(
          companyName: companyData['name']!,
          reportTitle: reportTitle,
          reportDate: _formatDate(DateTime.now()),
          logoFile: logoFile,
          additionalInfo: additionalInfo.isNotEmpty ? additionalInfo : null,
        ),
        
        // Footer الموحد
        footer: (context) => PdfFooter.build(
          context: context,
          companyName: companyData['name']!,
          additionalText: companyData['registration']!.isNotEmpty
              ? 'س.ت: ${companyData['registration']}'
              : null,
        ),
        
        // المحتوى
        build: (context) => content,
      ),
    );

    return pdf;
  }

  // ============= حفظ ومشاركة PDF =============

  /// حفظ PDF في الجهاز
  Future<File> savePdf({
    required pw.Document pdf,
    required String fileName,
  }) async {
    try {
      // الحصول على مجلد Downloads
      final directory = await getExternalStorageDirectory();
      final downloadsPath = Directory('${directory!.parent.parent.parent.parent.path}/Download');
      
      // التأكد من وجود المجلد
      if (!downloadsPath.existsSync()) {
        downloadsPath.createSync(recursive: true);
      }

      // إنشاء اسم الملف مع التاريخ
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fullFileName = '${fileName}_$timestamp.pdf';
      final file = File('${downloadsPath.path}/$fullFileName');

      // حفظ الملف
      await file.writeAsBytes(await pdf.save());

      return file;
    } catch (e) {
      print('❌ خطأ في حفظ PDF: $e');
      rethrow;
    }
  }

  /// مشاركة PDF
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

  /// طباعة PDF
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

  /// معاينة PDF (عرض في شاشة Preview)
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

  /// ✅ مثال: بناء تقرير بسيط
  /// Hint: سنستخدم هذا النمط لكل التقارير
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
        // الملخص
        pw.Container(
          padding: const pw.EdgeInsets.all(PdfStyles.spacingMd),
          decoration: pw.BoxDecoration(
            color: PdfStyles.primaryColor.shade(0.05),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            summary,
            style: PdfStyles.bodyStyle(),
            textAlign: pw.TextAlign.center,
          ),
        ),

        pw.SizedBox(height: PdfStyles.spacingLg),

        // الإحصائيات
        if (statistics.isNotEmpty) ...[
          pw.Text(
            'الإحصائيات',
            style: PdfStyles.headingStyle(),
          ),
          pw.SizedBox(height: PdfStyles.spacingMd),
          PdfTableBuilder.buildTwoColumnTable(data: statistics),
          pw.SizedBox(height: PdfStyles.spacingXl),
        ],

        // الجدول
        pw.Text(
          'التفاصيل',
          style: PdfStyles.headingStyle(),
        ),
        pw.SizedBox(height: PdfStyles.spacingMd),
        PdfTableBuilder.buildSimpleTable(
          headers: tableHeaders,
          data: tableData,
        ),
      ],
    );
  }

  ///  ========================================
  ///  بناء تقرير مبيعات الزبائن ✅
  /// ========================================

     
Future<pw.Document> buildCustomerSalesReport({
  required List<Map<String, dynamic>> salesData,
  required Map<String, dynamic> statistics,
  String? customerName,
  String? productName,
  String? supplierName,
  DateTime? startDate,
  DateTime? endDate,
}) async {
  // بناء عنوان التقرير
  String reportTitle = 'تقرير مبيعات الزبائن';
  
  // بناء ملخص الفلاتر
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
  
  // بناء المحتوى
  final content = <pw.Widget>[
    // ============= قسم الفلاتر المطبقة =============
    if (filterSummary.isNotEmpty) ...[
      pw.Container(
        padding: const pw.EdgeInsets.all(PdfStyles.spacingMd),
        decoration: pw.BoxDecoration(
          color: PdfStyles.primaryColor.shade(0.05),
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(
            color: PdfStyles.primaryColor.shade(0.2),
            width: 1,
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
            pw.SizedBox(height: PdfStyles.spacingSm),
            ...filterSummary.map(
              (filter) => pw.Padding(
                padding: const pw.EdgeInsets.only(
                  bottom: PdfStyles.spacingXs,
                ),
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: 4,
                      height: 4,
                      decoration: pw.BoxDecoration(
                        color: PdfStyles.primaryColor,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.SizedBox(width: PdfStyles.spacingSm),
                    pw.Text(
                      filter,
                      style: PdfStyles.bodyStyle(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: PdfStyles.spacingXl),
    ],
    
    // ============= قسم الإحصائيات =============
    pw.Text(
      'الإحصائيات العامة',
      style: PdfStyles.headingStyle(),
    ),
    pw.SizedBox(height: PdfStyles.spacingMd),
    
    pw.Row(
      children: [
        // البطاقة الأولى
        pw.Expanded(
          child: _buildStatCard(
            title: 'إجمالي المبيعات',
            value: _formatCurrency(statistics['totalSales']),
            color: PdfStyles.successColor,
          ),
        ),
        pw.SizedBox(width: PdfStyles.spacingMd),
        
        // البطاقة الثانية
        pw.Expanded(
          child: _buildStatCard(
            title: 'إجمالي الربح',
            value: _formatCurrency(statistics['totalProfit']),
            color: PdfStyles.primaryColor,
          ),
        ),
      ],
    ),
    
    pw.SizedBox(height: PdfStyles.spacingMd),
    
    pw.Row(
      children: [
        // البطاقة الثالثة
        pw.Expanded(
          child: _buildStatCard(
            title: 'عدد المعاملات',
            value: statistics['totalTransactions'].toString(),
            color: PdfStyles.secondaryColor,
          ),
        ),
        pw.SizedBox(width: PdfStyles.spacingMd),
        
        // البطاقة الرابعة
        pw.Expanded(
          child: _buildStatCard(
            title: 'متوسط قيمة المعاملة',
            value: _formatCurrency(statistics['averageTransaction']),
            color: PdfStyles.warningColor,
          ),
        ),
      ],
    ),
    
    pw.SizedBox(height: PdfStyles.spacingXl),
    
    // ============= قسم تفاصيل المبيعات =============
    pw.Text(
      'تفاصيل المبيعات (${salesData.length} معاملة)',
      style: PdfStyles.headingStyle(),
    ),
    pw.SizedBox(height: PdfStyles.spacingMd),
    
    // جدول المبيعات
    if (salesData.isEmpty)
      pw.Container(
        padding: const pw.EdgeInsets.all(PdfStyles.spacingXl),
        decoration: pw.BoxDecoration(
          color: PdfStyles.backgroundLight,
          borderRadius: pw.BorderRadius.circular(8),
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
    
    pw.SizedBox(height: PdfStyles.spacingXl),
    
    // ============= ملاحظات ختامية =============
    pw.Container(
      padding: const pw.EdgeInsets.all(PdfStyles.spacingMd),
      decoration: pw.BoxDecoration(
        color: PdfStyles.backgroundLight,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          pw.Icon(
            pw.IconData(0xe88f), // info icon
            size: 16,
            color: PdfStyles.textSecondary,
          ),
          pw.SizedBox(width: PdfStyles.spacingSm),
          pw.Expanded(
            child: pw.Text(
              'هذا التقرير تم إنشاؤه آلياً بواسطة نظام المحاسبة. جميع الأرقام محسوبة من قاعدة البيانات.',
              style: PdfStyles.smallStyle(color: PdfStyles.textSecondary),
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

/// بناء بطاقة إحصائية ملونة
pw.Widget _buildStatCard({
  required String title,
  required String value,
  required PdfColor color,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(PdfStyles.spacingMd),
    decoration: pw.BoxDecoration(
      color: color.shade(0.1),
      borderRadius: pw.BorderRadius.circular(8),
      border: pw.Border.all(
        color: color.shade(0.3),
        width: 1,
      ),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: PdfStyles.smallStyle(color: color),
        ),
        pw.SizedBox(height: PdfStyles.spacingSm),
        pw.Text(
          value,
          style: PdfStyles.boldStyle(
            fontSize: PdfStyles.fontSizeHeading,
            color: color,
          ),
        ),
      ],
    ),
  );
}

/// بناء جدول المبيعات التفصيلي
pw.Widget _buildSalesTable(List<Map<String, dynamic>> salesData) {
  return pw.Table(
    border: pw.TableBorder.all(
      color: PdfStyles.borderColor,
      width: 0.5,
    ),
    columnWidths: {
      0: const pw.FixedColumnWidth(30),  // #
      1: const pw.FixedColumnWidth(70),  // التاريخ
      2: const pw.FlexColumnWidth(2),    // الزبون
      3: const pw.FlexColumnWidth(2),    // المنتج
      4: const pw.FixedColumnWidth(40),  // الكمية
      5: const pw.FixedColumnWidth(70),  // المبلغ
      6: const pw.FixedColumnWidth(70),  // الربح
    },
    children: [
      // رأس الجدول
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
      
      // صفوف البيانات
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
            _buildTableCell(
              _formatCurrency((sale['amount'] as num).toDouble()),
            ),
            _buildTableCell(
              _formatCurrency((sale['profit'] as num).toDouble()),
            ),
          ],
        );
      }),
    ],
  );
}

/// بناء خلية رأس الجدول
pw.Widget _buildTableHeaderCell(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(PdfStyles.spacingSm),
    child: pw.Text(
      text,
      style: PdfStyles.tableHeaderStyle(),
      textAlign: pw.TextAlign.center,
    ),
  );
}

/// بناء خلية الجدول العادية
pw.Widget _buildTableCell(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(PdfStyles.spacingSm),
    child: pw.Text(
      text,
      style: PdfStyles.tableCellStyle(),
      textAlign: pw.TextAlign.center,
    ),
  );
}


// lib/services/pdf_service.dart
// أضف هذه الدوال في نهاية كلاس PdfService قبل القوس الأخير

// ============================================================================
// 💰 تقرير التدفق النقدي
// ============================================================================
Future<pw.Document> buildCashFlowReport({
  required List<Map<String, dynamic>> transactions,
  required double totalCashSales,
  required double totalDebtPayments,
  required double totalCashIn,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final content = <pw.Widget>[
    // ============= قسم الفترة الزمنية =============
    pw.Container(
      padding: const pw.EdgeInsets.all(PdfStyles.spacingMd),
      decoration: pw.BoxDecoration(
        color: PdfStyles.primaryColor.shade(0.05),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Icon(
            pw.IconData(0xe916), // calendar icon
            size: 20,
            color: PdfStyles.primaryColor,
          ),
          pw.SizedBox(width: PdfStyles.spacingSm),
          pw.Text(
            'الفترة: ${_formatDate(startDate)} - ${_formatDate(endDate)}',
            style: PdfStyles.boldStyle(color: PdfStyles.primaryColor),
          ),
        ],
      ),
    ),

    pw.SizedBox(height: PdfStyles.spacingXl),

    // ============= قسم الإحصائيات =============
    pw.Text('الإحصائيات العامة', style: PdfStyles.headingStyle()),
    pw.SizedBox(height: PdfStyles.spacingMd),

    pw.Row(
      children: [
        pw.Expanded(
          child: _buildStatCard(
            title: 'المبيعات النقدية',
            value: _formatCurrency(totalCashSales),
            color: PdfStyles.secondaryColor,
          ),
        ),
        pw.SizedBox(width: PdfStyles.spacingMd),
        pw.Expanded(
          child: _buildStatCard(
            title: 'تسديدات الديون',
            value: _formatCurrency(totalDebtPayments),
            color: PdfStyles.warningColor,
          ),
        ),
      ],
    ),

    pw.SizedBox(height: PdfStyles.spacingMd),

    _buildStatCard(
      title: 'إجمالي التدفق النقدي',
      value: _formatCurrency(totalCashIn),
      color: PdfStyles.successColor,
    ),

    pw.SizedBox(height: PdfStyles.spacingXl),

    // ============= قسم التفاصيل =============
    pw.Text(
      'تفاصيل المعاملات (${transactions.length} معاملة)',
      style: PdfStyles.headingStyle(),
    ),
    pw.SizedBox(height: PdfStyles.spacingMd),

    if (transactions.isEmpty)
      pw.Container(
        padding: const pw.EdgeInsets.all(PdfStyles.spacingXl),
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

/// بناء جدول التدفق النقدي
pw.Widget _buildCashFlowTable(List<Map<String, dynamic>> transactions) {
  return pw.Table(
    border: pw.TableBorder.all(color: PdfStyles.borderColor, width: 0.5),
    columnWidths: {
      0: const pw.FixedColumnWidth(30),
      1: const pw.FlexColumnWidth(2),
      2: const pw.FlexColumnWidth(3),
      3: const pw.FixedColumnWidth(80),
      4: const pw.FixedColumnWidth(70),
    },
    children: [
      // رأس الجدول
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

      // صفوف البيانات
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
              padding: const pw.EdgeInsets.all(PdfStyles.spacingSm),
              child: pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 6,
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
                    style: PdfStyles.smallStyle(
                      color: isCashSale
                          ? PdfStyles.secondaryColor
                          : PdfStyles.warningColor,
                    ),
                  ),
                ),
              ),
            ),
            _buildTableCell(trans['description'] ?? ''),
            _buildTableCell(
              _formatDate(DateTime.parse(trans['date'])),
            ),
            _buildTableCell(_formatCurrency(trans['amount'])),
          ],
        );
      }),
    ],
  );
}

// ============================================================================
// 📊 تقرير الأرباح العام
// ============================================================================
Future<pw.Document> buildProfitReport({
  required double totalProfit,
  required double totalExpenses,
  required double totalWithdrawals,
  required double netProfit,
  required List<Map<String, dynamic>> salesData,
}) async {
  final content = <pw.Widget>[
    // ============= قسم الملخص المالي =============
    pw.Text('الملخص المالي', style: PdfStyles.headingStyle()),
    pw.SizedBox(height: PdfStyles.spacingMd),

    _buildStatCard(
      title: 'إجمالي الأرباح من المبيعات',
      value: _formatCurrency(totalProfit),
      color: PdfStyles.secondaryColor,
    ),

    pw.SizedBox(height: PdfStyles.spacingMd),

    pw.Row(
      children: [
        pw.Expanded(
          child: _buildStatCard(
            title: 'المصاريف العامة',
            value: _formatCurrency(totalExpenses),
            color: PdfStyles.errorColor,
          ),
        ),
        pw.SizedBox(width: PdfStyles.spacingMd),
        pw.Expanded(
          child: _buildStatCard(
            title: 'مسحوبات الأرباح',
            value: _formatCurrency(totalWithdrawals),
            color: PdfStyles.warningColor,
          ),
        ),
      ],
    ),

    pw.Divider(height: 32),

    // النتيجة النهائية
    pw.Container(
      padding: const pw.EdgeInsets.all(PdfStyles.spacingLg),
      decoration: pw.BoxDecoration(
        color: netProfit >= 0
            ? PdfStyles.successColor.shade(0.1)
            : PdfStyles.errorColor.shade(0.1),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: netProfit >= 0
              ? PdfStyles.successColor.shade(0.3)
              : PdfStyles.errorColor.shade(0.3),
          width: 2,
        ),
      ),
      child: pw.Row(
        children: [
          pw.Icon(
            netProfit >= 0
                ? pw.IconData(0xe5ca) // trending_up
                : pw.IconData(0xe5c7), // trending_down
            size: 40,
            color: netProfit >= 0
                ? PdfStyles.successColor
                : PdfStyles.errorColor,
          ),
          pw.SizedBox(width: PdfStyles.spacingMd),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'صافي الربح',
                  style: PdfStyles.bodyStyle(),
                ),
                pw.SizedBox(height: PdfStyles.spacingXs),
                pw.Text(
                  _formatCurrency(netProfit),
                  style: PdfStyles.boldStyle(
                    fontSize: 24,
                    color: netProfit >= 0
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

    pw.SizedBox(height: PdfStyles.spacingXl),

    // ============= تفاصيل المبيعات =============
    if (salesData.isNotEmpty) ...[
      pw.Text(
        'تفاصيل المبيعات (${salesData.length} عملية)',
        style: PdfStyles.headingStyle(),
      ),
      pw.SizedBox(height: PdfStyles.spacingMd),
      _buildSalesDetailTable(salesData),
    ],
  ];

  return await buildPdfDocument(
    reportTitle: 'تقرير الأرباح العام',
    content: content,
  );
}

/// بناء جدول تفاصيل المبيعات للأرباح
pw.Widget _buildSalesDetailTable(List<Map<String, dynamic>> salesData) {
  return pw.Table(
    border: pw.TableBorder.all(color: PdfStyles.borderColor, width: 0.5),
    columnWidths: {
      0: const pw.FixedColumnWidth(30),
      1: const pw.FlexColumnWidth(2),
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
            _buildTableCell(
              _formatDate(DateTime.parse(sale['dateT'])),
            ),
            _buildTableCell(_formatCurrency(sale['debt'])),
            _buildTableCell(_formatCurrency(sale['profitAmount'])),
          ],
        );
      }),
    ],
  );
}

// ============================================================================
// 🏢 تقرير أرباح الموردين
// ============================================================================
Future<pw.Document> buildSupplierProfitReport({
  required List<Map<String, dynamic>> suppliersData,
}) async {
  final content = <pw.Widget>[
    pw.Text(
      'ملخص أرباح الموردين (${suppliersData.length} مورد)',
      style: PdfStyles.headingStyle(),
    ),
    pw.SizedBox(height: PdfStyles.spacingMd),

    _buildSuppliersProfitTable(suppliersData),
  ];

  return await buildPdfDocument(
    reportTitle: 'تقرير أرباح الموردين',
    content: content,
  );
}

/// بناء جدول أرباح الموردين
pw.Widget _buildSuppliersProfitTable(List<Map<String, dynamic>> data) {
  return pw.Table(
    border: pw.TableBorder.all(color: PdfStyles.borderColor, width: 0.5),
    columnWidths: {
      0: const pw.FixedColumnWidth(30),
      1: const pw.FlexColumnWidth(3),
      2: const pw.FlexColumnWidth(2),
      3: const pw.FixedColumnWidth(80),
      4: const pw.FixedColumnWidth(80),
      5: const pw.FixedColumnWidth(80),
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
        final netProfit = supplier['totalProfit'] - supplier['totalWithdrawn'];

        return pw.TableRow(
          decoration: isEven
              ? PdfStyles.tableCellDecorationEven()
              : PdfStyles.tableCellDecorationOdd(),
          children: [
            _buildTableCell((index + 1).toString()),
            _buildTableCell(supplier['supplierName'] ?? ''),
            pw.Container(
              padding: const pw.EdgeInsets.all(PdfStyles.spacingSm),
              child: pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 6,
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
                    style: PdfStyles.smallStyle(),
                  ),
                ),
              ),
            ),
            _buildTableCell(_formatCurrency(supplier['totalProfit'])),
            _buildTableCell(_formatCurrency(supplier['totalWithdrawn'])),
            _buildTableCell(_formatCurrency(netProfit)),
          ],
        );
      }),
    ],
  );
}

// ============================================================================
// 👥 تقرير الموظفين
// ============================================================================
Future<pw.Document> buildEmployeesReport({
  required double totalSalaries,
  required double totalAdvances,
  required int employeesCount,
  required List<Map<String, dynamic>> employeesData,
}) async {
  final content = <pw.Widget>[
    // ============= الإحصائيات =============
    pw.Text('الإحصائيات العامة', style: PdfStyles.headingStyle()),
    pw.SizedBox(height: PdfStyles.spacingMd),

    pw.Row(
      children: [
        pw.Expanded(
          child: _buildStatCard(
            title: 'إجمالي الرواتب المدفوعة',
            value: _formatCurrency(totalSalaries),
            color: PdfStyles.successColor,
          ),
        ),
        pw.SizedBox(width: PdfStyles.spacingMd),
        pw.Expanded(
          child: _buildStatCard(
            title: 'إجمالي السلف المستحقة',
            value: _formatCurrency(totalAdvances),
            color: PdfStyles.warningColor,
          ),
        ),
      ],
    ),

    pw.SizedBox(height: PdfStyles.spacingMd),

    _buildStatCard(
      title: 'عدد الموظفين النشطين',
      value: employeesCount.toString(),
      color: PdfStyles.secondaryColor,
    ),

    pw.SizedBox(height: PdfStyles.spacingXl),

    // ============= قائمة الموظفين =============
    pw.Text(
      'قائمة الموظفين (${employeesData.length} موظف)',
      style: PdfStyles.headingStyle(),
    ),
    pw.SizedBox(height: PdfStyles.spacingMd),

    _buildEmployeesTable(employeesData),
  ];

  return await buildPdfDocument(
    reportTitle: 'تقرير الموظفين',
    content: content,
  );
}

/// بناء جدول الموظفين
pw.Widget _buildEmployeesTable(List<Map<String, dynamic>> data) {
  return pw.Table(
    border: pw.TableBorder.all(color: PdfStyles.borderColor, width: 0.5),
    columnWidths: {
      0: const pw.FixedColumnWidth(30),
      1: const pw.FlexColumnWidth(3),
      2: const pw.FlexColumnWidth(2),
      3: const pw.FixedColumnWidth(80),
      4: const pw.FixedColumnWidth(80),
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
            _buildTableCell(_formatCurrency(employee['baseSalary'] ?? 0)),
            _buildTableCell(_formatCurrency(employee['balance'] ?? 0)),
          ],
        );
      }),
    ],
  );
}

// بحاجة الى تعديله لنستطيع طباعة تفاصيل سحب الشركاء و الموردين
  Future buildSupplierDetailsReport({required String supplierName, required String supplierType, required double totalProfit, required double totalWithdrawn, required double netProfit, required List<Map<String, Object>> partnersData, required List<Map<String, dynamic>> withdrawalsData}) async {}




}
