// lib/utils/pdf_helpers.dart

import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import '../services/pdf_service.dart';
import '../theme/app_colors.dart';

class PdfHelpers {
  static void showPdfOptionsDialog(
    BuildContext context,
    pw.Document pdf, {
    VoidCallback? onSuccess,
    Function(String)? onError,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.picture_as_pdf, color: AppColors.error),
            SizedBox(width: 8),
            Text('خيارات PDF'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // معاينة
            ListTile(
              leading: const Icon(Icons.visibility, color: AppColors.info),
              title: const Text('معاينة'),
              subtitle: const Text('عرض PDF قبل الحفظ'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await PdfService.instance.previewPdf(
                    pdf: pdf,
                    fileName: 'report',
                  );
                  onSuccess?.call();
                } catch (e) {
                  onError?.call('خطأ في المعاينة: $e');
                }
              },
            ),
            
            const Divider(),
            
            // حفظ
            ListTile(
              leading: const Icon(Icons.save, color: AppColors.success),
              title: const Text('حفظ'),
              subtitle: const Text('حفظ في مجلد التنزيلات'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final file = await PdfService.instance.savePdf(
                    pdf: pdf,
                    fileName: 'report',
                  );
                  onSuccess?.call();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم الحفظ في: ${file.path}'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } catch (e) {
                  onError?.call('خطأ في الحفظ: $e');
                }
              },
            ),
            
            const Divider(),
            
            // طباعة
            ListTile(
              leading: const Icon(Icons.print, color: AppColors.primaryLight),
              title: const Text('طباعة'),
              subtitle: const Text('طباعة مباشرة'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await PdfService.instance.printPdf(pdf: pdf);
                  onSuccess?.call();
                } catch (e) {
                  onError?.call('خطأ في الطباعة: $e');
                }
              },
            ),
            
            const Divider(),
            
            // مشاركة
            ListTile(
              leading: const Icon(Icons.share, color: AppColors.secondaryLight),
              title: const Text('مشاركة'),
              subtitle: const Text('مشاركة عبر التطبيقات'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await PdfService.instance.sharePdf(
                    pdf: pdf,
                    fileName: 'report',
                  );
                  onSuccess?.call();
                } catch (e) {
                  onError?.call('خطأ في المشاركة: $e');
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }
}