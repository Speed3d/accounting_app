// lib/screens/test_pdf_screen.dart

import 'package:flutter/material.dart';
import '../services/pdf_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';
import '../widgets/custom_button.dart';

/// 🧪 شاشة اختبار PDF
class TestPdfScreen extends StatefulWidget {
  const TestPdfScreen({super.key});

  @override
  State<TestPdfScreen> createState() => _TestPdfScreenState();
}

class _TestPdfScreenState extends State<TestPdfScreen> {
  bool _isGenerating = false;

  /// توليد تقرير تجريبي
  Future<void> _generateTestReport() async {
    setState(() => _isGenerating = true);

    try {
      // بيانات تجريبية
      final pdf = await PdfService.instance.buildSimpleReport(
        reportTitle: 'تقرير تجريبي',
        summary: 'هذا تقرير تجريبي لاختبار نظام PDF. جميع البيانات وهمية.',
        statistics: {
          'إجمالي المبيعات': '1,250,000 د.ع',
          'عدد المعاملات': '45',
          'إجمالي الربح': '350,000 د.ع',
          'متوسط قيمة المعاملة': '27,777 د.ع',
        },
        tableHeaders: ['#', 'التاريخ', 'الزبون', 'المبلغ', 'الحالة'],
        tableData: [
          ['1', '2025-01-15', 'أحمد محمد', '50,000', 'مكتمل'],
          ['2', '2025-01-14', 'فاطمة علي', '75,000', 'مكتمل'],
          ['3', '2025-01-13', 'خالد حسن', '30,000', 'قيد الانتظار'],
          ['4', '2025-01-12', 'سارة أحمد', '100,000', 'مكتمل'],
          ['5', '2025-01-11', 'محمد عمر', '45,000', 'مكتمل'],
        ],
      );

      // معاينة PDF
      await PdfService.instance.previewPdf(
        pdf: pdf,
        fileName: 'test_report',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('تم إنشاء التقرير بنجاح!'),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار PDF'),
      ),
      body: Center(
        child: Padding(
          padding: AppConstants.screenPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.picture_as_pdf,
                size: 80,
                color: AppColors.error,
              ),
              
              const SizedBox(height: AppConstants.spacingXl),
              
              const Text(
                'اختبار نظام PDF',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: AppConstants.spacingSm),
              
              const Text(
                'قم بإنشاء تقرير تجريبي للتأكد من عمل النظام',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              
              const SizedBox(height: AppConstants.spacingXl),
              
              CustomButton(
                text: 'إنشاء تقرير تجريبي',
                icon: Icons.file_download,
                onPressed: _generateTestReport,
                isLoading: _isGenerating,
              ),
            ],
          ),
        ),
      ),
    );
  }
}