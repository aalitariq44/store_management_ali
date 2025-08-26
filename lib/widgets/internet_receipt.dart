import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/person_model.dart';
import '../models/internet_model.dart';
import '../utils/date_formatter.dart';
import '../utils/number_formatter.dart';

class InternetReceipt {
  static pw.Font? _arabicFont;
  static pw.Font? _arabicBoldFont;

  static void setFonts(pw.Font? arabicFont, pw.Font? arabicBoldFont) {
    _arabicFont = arabicFont;
    _arabicBoldFont = arabicBoldFont;
  }

  static pw.TextStyle _arabicTextStyle({
    double fontSize = 12,
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.TextStyle(
      font: isBold ? _arabicBoldFont : _arabicFont,
      fontFallback: [
        if (_arabicFont != null) _arabicFont!,
        if (_arabicBoldFont != null) _arabicBoldFont!,
      ],
      fontSize: fontSize,
      fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: color,
    );
  }

  static pw.Widget buildReceiptCard(
    InternetSubscription subscription,
    Person person,
    DateTime printTime,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6), // تقليل الحشوة الداخلية
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.black,
          width: 1.2,
        ), // تقليل سماكة الحافة
        borderRadius: pw.BorderRadius.circular(4), // تقليل نصف القطر
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // Store Name
          pw.Center(
            child: pw.Text(
              'محل كاظم السعدي لخدمات الانترنيت',
              style: _arabicTextStyle(fontSize: 14, isBold: true),
              textDirection: pw.TextDirection.rtl,
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 5),

          // Receipt Header
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue100,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Center(
              child: pw.Text(
                'وصل اشتراك إنترنت',
                style: _arabicTextStyle(
                  fontSize: 16,
                  isBold: true,
                  color: PdfColors.blue800,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
            ),
          ),
          pw.SizedBox(height: 10),

          // Customer Information
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Text(
                      'اسم الزبون:',
                      style: _arabicTextStyle(fontSize: 11, isBold: true),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.SizedBox(width: 4),
                    pw.Text(
                      person.name,
                      style: _arabicTextStyle(fontSize: 11),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Text(
                      'رقم الزبون:',
                      style: _arabicTextStyle(fontSize: 11, isBold: true),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.SizedBox(width: 4),
                    pw.Text(
                      '${person.id}',
                      style: _arabicTextStyle(fontSize: 11),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 8),

          // Subscription Details: نوع الاشتراك مقابل سعر الاشتراك
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Text(
                      'نوع الاشتراك:',
                      style: _arabicTextStyle(fontSize: 11, isBold: true),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.SizedBox(width: 4),
                    pw.Text(
                      subscription.packageName,
                      style: _arabicTextStyle(fontSize: 11),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Text(
                      'سعر الاشتراك:',
                      style: _arabicTextStyle(fontSize: 11, isBold: true),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.SizedBox(width: 4),
                    pw.Text(
                      '${NumberFormatter.format(subscription.price)} د.ع',
                      style: _arabicTextStyle(fontSize: 11),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Dates: تاريخ البداية مقابل تاريخ الانتهاء
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Text(
                      'تاريخ البداية:',
                      style: _arabicTextStyle(fontSize: 11, isBold: true),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.SizedBox(width: 4),
                    pw.Text(
                      DateFormatter.formatDisplayDate(subscription.startDate),
                      style: _arabicTextStyle(fontSize: 11),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Text(
                      'تاريخ الانتهاء:',
                      style: _arabicTextStyle(fontSize: 11, isBold: true),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.SizedBox(width: 4),
                    pw.Text(
                      DateFormatter.formatDisplayDate(subscription.paymentDate),
                      style: _arabicTextStyle(fontSize: 11),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildReceiptRow(
            'المبلغ المدفوع:',
            '${NumberFormatter.format(subscription.paidAmount)} د.ع',
          ),

          // Notes if available
          if (subscription.notes != null && subscription.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 5),
            _buildReceiptRow('الملاحظات:', subscription.notes!),
          ],

          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 8),

          // Print Timestamp
          pw.Center(
            child: pw.Text(
              'تاريخ ووقت الطباعة: ${DateFormatter.formatDisplayDateTime(printTime)}',
              style: _arabicTextStyle(fontSize: 10, color: PdfColors.grey700),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildReceiptRow(String title, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            title,
            style: _arabicTextStyle(fontSize: 11, isBold: true),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: _arabicTextStyle(fontSize: 11),
              textDirection: pw.TextDirection.rtl,
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
