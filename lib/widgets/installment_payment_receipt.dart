
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/person_model.dart';
import '../models/installment_model.dart';
import '../utils/date_formatter.dart';
import '../utils/number_formatter.dart';

class InstallmentPaymentReceipt {
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
    Installment installment,
    InstallmentPayment payment,
    Person person,
    DateTime printTime,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.black,
          width: 1.2,
        ),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // Store Name
          pw.Center(
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'محل كاظم السعدي لخدمات الانترنيت',
                  style: _arabicTextStyle(fontSize: 14, isBold: true),
                  textDirection: pw.TextDirection.rtl,
                  textAlign: pw.TextAlign.left,
                ),
                pw.Text(
                  '07709030073',
                  style: _arabicTextStyle(fontSize: 11),
                  textDirection: pw.TextDirection.rtl,
                  textAlign: pw.TextAlign.right,
                ),
              ],
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
                'وصل دفع قسط',
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

          // Installment Details
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildTitleValueText('اسم المنتج:', installment.productName),
                _buildTitleValueText('المبلغ الإجمالي للمنتج:', '${NumberFormatter.format(installment.totalAmount)} د.ع', textAlign: pw.TextAlign.right),
              ],
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildTitleValueText('مجموع المدفوع:', '${NumberFormatter.format(installment.paidAmount)} د.ع', color: PdfColors.green),
                _buildTitleValueText('المتبقي:', '${NumberFormatter.format(installment.remainingAmount)} د.ع', color: PdfColors.red, textAlign: pw.TextAlign.right),
              ],
            ),
          ),
          
          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 8),

          // Payment Details
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildTitleValueText('مبلغ هذه الدفعة:', '${NumberFormatter.format(payment.amount)} د.ع', isBold: true, fontSize: 14),
                _buildTitleValueText('تاريخ الدفعة:', DateFormatter.formatDisplayDateTime(payment.paymentDate), textAlign: pw.TextAlign.right),
              ],
            ),
          ),

          // Notes if available
          if (payment.notes != null && payment.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 5),
            _buildReceiptRow('الملاحظات:', payment.notes!),
          ],

          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 8),

          // Print Timestamp and Receipt ID
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'رقم الوصل: ${payment.id}',
                style: _arabicTextStyle(fontSize: 10, color: PdfColors.grey700),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                'تاريخ ووقت الطباعة: ${DateFormatter.formatDisplayDateTime(printTime)}',
                style: _arabicTextStyle(fontSize: 10, color: PdfColors.grey700),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildReceiptRow(String title, String value, {PdfColor? color, bool isBold = false, double fontSize = 11}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            title,
            style: _arabicTextStyle(fontSize: fontSize, isBold: true),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: _arabicTextStyle(fontSize: fontSize, color: color, isBold: isBold),
              textDirection: pw.TextDirection.rtl,
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTitleValueText(String title, String value, {PdfColor? color, bool isBold = false, double fontSize = 11, pw.TextAlign? textAlign}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: _arabicTextStyle(fontSize: fontSize, isBold: true),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.SizedBox(width: 4),
        pw.Text(
          value,
          style: _arabicTextStyle(fontSize: fontSize, color: color, isBold: isBold),
          textDirection: pw.TextDirection.rtl,
          textAlign: textAlign ?? pw.TextAlign.left,
        ),
      ],
    );
  }
}
