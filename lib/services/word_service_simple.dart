import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/installment_model.dart';
import '../models/person_model.dart';
import '../utils/date_formatter.dart';
import '../utils/number_formatter.dart';

class WordServiceSimple {
  /// إنشاء مستند Word بسيط باستخدام HTML
  static Future<void> createPaymentsDocumentHTML({
    required Installment installment,
    required Person person,
    required List<InstallmentPayment> payments,
  }) async {
    try {
      // إنشاء محتوى HTML
      String htmlContent = _generateHTMLContent(installment, person, payments);

      // حفظ الملف كـ HTML مع امتداد .doc ليتم فتحه في Word
      final String fileName =
          'دفعات_${person.name}_${installment.productName}_${DateTime.now().millisecondsSinceEpoch}.doc';
      final String savedFilePath = await _saveHTMLFile(htmlContent, fileName);

      // فتح الملف
      await _openFile(savedFilePath);
    } catch (e) {
      throw Exception('خطأ في إنشاء مستند Word: $e');
    }
  }

  /// إنشاء محتوى HTML للمستند
  static String _generateHTMLContent(
    Installment installment,
    Person person,
    List<InstallmentPayment> payments,
  ) {
    return '''
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>دفعات ${person.name}</title>
    <style>
        body {
            font-family: 'Arial', sans-serif;
            direction: rtl;
            text-align: right;
            margin: 20px;
            line-height: 1.6;
        }
        .header {
            text-align: center;
            background-color: #f39c12;
            color: white;
            padding: 20px;
            margin-bottom: 30px;
            border-radius: 10px;
        }
        .header h1 {
            margin: 0;
            font-size: 24px;
        }
        .info-section {
            background-color: #f8f9fa;
            padding: 15px;
            margin-bottom: 20px;
            border-radius: 8px;
            border: 1px solid #dee2e6;
        }
        .info-row {
            display: flex;
            justify-content: space-between;
            margin: 8px 0;
            padding: 5px 0;
            border-bottom: 1px dotted #ccc;
        }
        .info-label {
            font-weight: bold;
            color: #495057;
        }
        .info-value {
            color: #212529;
        }
        .payments-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
            background-color: white;
        }
        .payments-table th,
        .payments-table td {
            border: 1px solid #ddd;
            padding: 12px;
            text-align: center;
        }
        .payments-table th {
            background-color: #f39c12;
            color: white;
            font-weight: bold;
        }
        .payments-table tr:nth-child(even) {
            background-color: #f8f9fa;
        }
        .section-title {
            color: #f39c12;
            font-size: 18px;
            font-weight: bold;
            margin: 20px 0 10px 0;
            padding-bottom: 5px;
            border-bottom: 2px solid #f39c12;
        }
        .summary {
            background-color: #e7f3ff;
            padding: 15px;
            border-radius: 8px;
            border-right: 4px solid #007bff;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>محلات نيويورك</h1>
    </div>

    <div class="section-title">بيانات الزبون</div>
    <div class="info-section">
        <div class="info-row">
            <span class="info-label">إسم الزبون:</span>
            <span class="info-value">${person.name}</span>
        </div>
        <div class="info-row">
            <span class="info-label">رقم الزبون:</span>
            <span class="info-value">${person.id ?? 'غير محدد'}</span>
        </div>
        <div class="info-row">
            <span class="info-label">رقم هاتف الزبون:</span>
            <span class="info-value">${person.phone ?? 'غير محدد'}</span>
        </div>
        <div class="info-row">
            <span class="info-label">عنوان الزبون:</span>
            <span class="info-value">${person.address ?? 'غير محدد'}</span>
        </div>
    </div>

    <div class="section-title">بيانات السلعة</div>
    <div class="info-section">
        <div class="info-row">
            <span class="info-label">إسم السلعة:</span>
            <span class="info-value">${installment.productName}</span>
        </div>
        <div class="info-row">
            <span class="info-label">سعر السلعة:</span>
            <span class="info-value">${NumberFormatter.format(installment.totalAmount)} د.ع</span>
        </div>
        <div class="info-row">
            <span class="info-label">تاريخ الشراء:</span>
            <span class="info-value">${DateFormatter.formatDisplayDate(installment.createdAt)}</span>
        </div>
    </div>

    <div class="section-title">سجل الدفعات</div>
    <table class="payments-table">
        <thead>
            <tr>
                <th>ت</th>
                <th>مبلغ الدفعة</th>
                <th>تاريخ الدفع</th>
                <th>ملاحظات</th>
            </tr>
        </thead>
        <tbody>
            ${_generatePaymentsRows(payments)}
        </tbody>
    </table>

    <div class="summary">
        <div class="info-row">
            <span class="info-label">إجمالي المبلغ:</span>
            <span class="info-value">${NumberFormatter.format(installment.totalAmount)} د.ع</span>
        </div>
        <div class="info-row">
            <span class="info-label">المبلغ المدفوع:</span>
            <span class="info-value" style="color: green;">${NumberFormatter.format(installment.paidAmount)} د.ع</span>
        </div>
        <div class="info-row">
            <span class="info-label">المبلغ المتبقي:</span>
            <span class="info-value" style="color: red;">${NumberFormatter.format(installment.remainingAmount)} د.ع</span>
        </div>
    </div>
</body>
</html>
''';
  }

  /// إنشاء صفوف جدول الدفعات
  static String _generatePaymentsRows(List<InstallmentPayment> payments) {
    if (payments.isEmpty) {
      return '<tr><td colspan="4">لا توجد دفعات مسجلة</td></tr>';
    }

    String rows = '';
    for (int i = 0; i < payments.length; i++) {
      final payment = payments[i];
      rows +=
          '''
        <tr>
            <td>${i + 1}</td>
            <td>${NumberFormatter.format(payment.amount)} د.ع</td>
            <td>${DateFormatter.formatDisplayDate(payment.paymentDate)}</td>
            <td>${payment.notes ?? 'لا توجد ملاحظات'}</td>
        </tr>
      ''';
    }
    return rows;
  }

  /// حفظ ملف HTML مع امتداد .doc
  static Future<String> _saveHTMLFile(
    String htmlContent,
    String fileName,
  ) async {
    try {
      // الحصول على مجلد المستندات
      final Directory? documentsDir =
          await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();

      // إنشاء مجلد للمستندات إذا لم يكن موجوداً
      final Directory paymentsDir = Directory(
        path.join(documentsDir!.path, 'الدفعات'),
      );
      if (!await paymentsDir.exists()) {
        await paymentsDir.create(recursive: true);
      }

      // مسار الملف الكامل
      final String filePath = path.join(paymentsDir.path, fileName);

      // كتابة الملف
      final File file = File(filePath);
      await file.writeAsString(htmlContent, encoding: utf8);

      return filePath;
    } catch (e) {
      throw Exception('خطأ في حفظ ملف Word: $e');
    }
  }

  /// فتح الملف باستخدام التطبيق الافتراضي
  static Future<void> _openFile(String filePath) async {
    try {
      final Uri fileUri = Uri.file(filePath);

      if (await canLaunchUrl(fileUri)) {
        await launchUrl(fileUri);
      } else {
        // محاولة فتح الملف بطريقة أخرى على Windows
        if (Platform.isWindows) {
          await Process.run('cmd', ['/c', 'start', filePath]);
        } else {
          throw Exception(
            'لا يمكن فتح الملف. تأكد من وجود تطبيق متوافق لفتح ملفات Word.',
          );
        }
      }
    } catch (e) {
      throw Exception('خطأ في فتح الملف: $e');
    }
  }
}
