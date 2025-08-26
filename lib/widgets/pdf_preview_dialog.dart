import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

class PDFPreviewDialog extends StatelessWidget {
  final pw.Document pdf;
  final String title;

  const PDFPreviewDialog({Key? key, required this.pdf, required this.title})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            // رأس النافذة
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // منطقة معاينة PDF
            Expanded(
              child: Container(
                color: Colors.grey[100],
                child: PdfPreview(
                  build: (format) => pdf.save(),
                  allowPrinting: true,
                  allowSharing: true,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  actions: [
                    // زر الطباعة المخصص
                    PdfPreviewAction(
                      icon: const Icon(Icons.print),
                      onPressed: (context, build, pageFormat) async {
                        // إظهار حوار تأكيد الطباعة
                        final confirmed = await _showPrintConfirmDialog(
                          context,
                        );
                        if (confirmed == true) {
                          await Printing.layoutPdf(
                            onLayout: (format) => build(format),
                          );
                          // إغلاق نافذة المعاينة بعد الطباعة
                          if (context.mounted) {
                            Navigator.of(context).pop(true);
                          }
                        }
                      },
                    ),
                    // زر الحفظ
                    PdfPreviewAction(
                      icon: const Icon(Icons.save),
                      onPressed: (context, build, pageFormat) async {
                        await _savePDF(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
            // شريط الأزرار السفلي
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final confirmed = await _showPrintConfirmDialog(context);
                      if (confirmed == true) {
                        await Printing.layoutPdf(
                          onLayout: (format) => pdf.save(),
                        );
                        if (context.mounted) {
                          Navigator.of(context).pop(true);
                        }
                      }
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('طباعة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await _savePDF(context);
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('حفظ'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close),
                    label: const Text('إغلاق'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // إظهار حوار تأكيد الطباعة
  Future<bool?> _showPrintConfirmDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.print, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('تأكيد الطباعة'),
            ],
          ),
          content: const Text('هل أنت متأكد من أنك تريد طباعة هذا المستند؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('طباعة'),
            ),
          ],
        );
      },
    );
  }

  // حفظ PDF
  Future<void> _savePDF(BuildContext context) async {
    try {
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: '${title}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الملف بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حفظ الملف: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // دالة ثابتة لإظهار نافذة المعاينة
  static Future<bool?> show({
    required BuildContext context,
    required pw.Document pdf,
    required String title,
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PDFPreviewDialog(pdf: pdf, title: title);
      },
    );
  }
}
