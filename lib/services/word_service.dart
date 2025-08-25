import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:docx_template/docx_template.dart';
import '../models/installment_model.dart';
import '../models/person_model.dart';
import '../utils/date_formatter.dart';
import '../utils/number_formatter.dart';

class WordService {
  /// ملء قالب Word بدفعات القسط وفتحه
  static Future<void> fillPaymentsTemplate({
    required Installment installment,
    required Person person,
    required List<InstallmentPayment> payments,
  }) async {
    try {
      // قراءة قالب Word من assets
      final ByteData templateData = await rootBundle.load(
        'assets/template/Payments.docx',
      );
      final Uint8List templateBytes = templateData.buffer.asUint8List();

      // إنشاء كائن القالب
      final docxTemplate = await DocxTemplate.fromBytes(templateBytes);

      // تحضير البيانات لملء القالب
      final content = Content();

      // بيانات الزبون
      content
        ..add(TextContent('name_Customer', person.name))
        ..add(TextContent('number_Customer', person.id?.toString() ?? ''))
        ..add(TextContent('phone_Customer', person.phone ?? 'غير محدد'))
        ..add(TextContent('adrees_Customer', person.address ?? 'غير محدد'));

      // بيانات القسط
      content
        ..add(TextContent('name_Item', installment.productName))
        ..add(
          TextContent(
            'prace_Item',
            NumberFormatter.format(installment.totalAmount),
          ),
        )
        ..add(
          TextContent(
            'date_Item',
            DateFormatter.formatDisplayDate(installment.createdAt),
          ),
        );

      // إضافة جدول الدفعات
      List<RowContent> paymentsTableRows = [];

      for (int i = 0; i < payments.length; i++) {
        final payment = payments[i];
        paymentsTableRows.add(
          RowContent({
            'row_number': TextContent('', (i + 1).toString()),
            'prace': TextContent('', NumberFormatter.format(payment.amount)),
            'date': TextContent(
              '',
              DateFormatter.formatDisplayDate(payment.paymentDate),
            ),
            'notes': TextContent('', payment.notes ?? 'لا توجد ملاحظات'),
          }),
        );
      }

      // إضافة البيانات للجدول
      content.add(TableContent('payments_table', paymentsTableRows));

      // ملء القالب بالبيانات
      final generatedDocBytes = await docxTemplate.generate(content);
      if (generatedDocBytes == null) {
        throw Exception('فشل في إنشاء المستند');
      }

      // حفظ الملف المولد
      final String fileName =
          'دفعات_${person.name}_${installment.productName}_${DateTime.now().millisecondsSinceEpoch}.docx';
      final String savedFilePath = await _saveWordFile(
        generatedDocBytes,
        fileName,
      );

      // فتح الملف
      await _openWordFile(savedFilePath);
    } catch (e) {
      throw Exception('خطأ في إنشاء مستند Word: $e');
    }
  }

  /// حفظ ملف Word في مجلد مؤقت
  static Future<String> _saveWordFile(
    List<int> docBytes,
    String fileName,
  ) async {
    try {
      // الحصول على مجلد مؤقت
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = tempDir.path;

      // إنشاء مجلد للمستندات إذا لم يكن موجوداً
      final Directory documentsDir = Directory(
        path.join(tempPath, 'documents'),
      );
      if (!await documentsDir.exists()) {
        await documentsDir.create(recursive: true);
      }

      // مسار الملف الكامل
      final String filePath = path.join(documentsDir.path, fileName);

      // كتابة الملف
      final File file = File(filePath);
      await file.writeAsBytes(docBytes);

      return filePath;
    } catch (e) {
      throw Exception('خطأ في حفظ ملف Word: $e');
    }
  }

  /// فتح ملف Word باستخدام التطبيق الافتراضي
  static Future<void> _openWordFile(String filePath) async {
    try {
      final Uri fileUri = Uri.file(filePath);

      if (await canLaunchUrl(fileUri)) {
        await launchUrl(fileUri);
      } else {
        throw Exception(
          'لا يمكن فتح ملف Word. تأكد من وجود Microsoft Word أو تطبيق متوافق.',
        );
      }
    } catch (e) {
      throw Exception('خطأ في فتح ملف Word: $e');
    }
  }

  /// إنشاء ملف Word للدفعات مع تنسيق مخصص (بديل في حالة عدم وجود قالب)
  static Future<void> createPaymentsDocument({
    required Installment installment,
    required Person person,
    required List<InstallmentPayment> payments,
  }) async {
    try {
      // هذه دالة بديلة لإنشاء مستند Word بدون قالب
      // يمكن استخدامها في حالة عدم وجود القالب أو فشل في قراءته

      // إنشاء محتوى نصي بسيط
      String documentText =
          '''
محلات نيويورك

بيانات الزبون:
الاسم: ${person.name}
رقم الزبون: ${person.id ?? 'غير محدد'}
رقم الهاتف: ${person.phone ?? 'غير محدد'}
العنوان: ${person.address ?? 'غير محدد'}

بيانات السلعة:
اسم السلعة: ${installment.productName}
سعر السلعة: ${NumberFormatter.format(installment.totalAmount)} د.ع
تاريخ الشراء: ${DateFormatter.formatDisplayDate(installment.createdAt)}

سجل الدفعات:
''';

      for (int i = 0; i < payments.length; i++) {
        final payment = payments[i];
        documentText +=
            '''
${i + 1}. مبلغ الدفعة: ${NumberFormatter.format(payment.amount)} د.ع
   تاريخ الدفع: ${DateFormatter.formatDisplayDate(payment.paymentDate)}
   ملاحظات: ${payment.notes ?? 'لا توجد ملاحظات'}

''';
      }

      // حفظ كملف نصي مؤقتاً (يمكن تطويره لاحقاً)
      final String fileName =
          'دفعات_${person.name}_${installment.productName}.txt';
      await _saveTextFile(documentText, fileName);
    } catch (e) {
      throw Exception('خطأ في إنشاء مستند الدفعات: $e');
    }
  }

  /// حفظ ملف نصي (دالة مساعدة)
  static Future<void> _saveTextFile(String content, String fileName) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath = path.join(tempDir.path, fileName);

      final File file = File(filePath);
      await file.writeAsString(content, encoding: utf8);

      // فتح الملف
      final Uri fileUri = Uri.file(filePath);
      if (await canLaunchUrl(fileUri)) {
        await launchUrl(fileUri);
      }
    } catch (e) {
      throw Exception('خطأ في حفظ الملف النصي: $e');
    }
  }
}
