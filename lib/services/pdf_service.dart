import 'dart:io';
// ignore: unused_shown_name
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import '../models/person_model.dart';
import '../models/debt_model.dart';
import '../models/installment_model.dart';
import '../models/internet_model.dart';
import '../utils/date_formatter.dart';
import '../utils/number_formatter.dart';
import '../widgets/pdf_preview_dialog.dart';

class PDFService {
  // متغيرات الخطوط العربية
  static pw.Font? _arabicFont;
  static pw.Font? _arabicBoldFont;

  // تحميل الخطوط العربية
  static Future<void> _loadArabicFonts() async {
    if (_arabicFont == null || _arabicBoldFont == null) {
      try {
        // تحميل خط Amiri العادي والعريض
        final regularFont = await rootBundle.load(
          "assets/fonts/Amiri-Regular.ttf",
        );
        final boldFont = await rootBundle.load("assets/fonts/Amiri-Bold.ttf");

        _arabicFont = pw.Font.ttf(regularFont);
        _arabicBoldFont = pw.Font.ttf(boldFont);
      } catch (e) {
        // في حالة فشل تحميل خط Amiri، نجرب Cairo
        try {
          final regularFont = await rootBundle.load(
            "assets/fonts/Cairo-Regular.ttf",
          );
          final boldFont = await rootBundle.load("assets/fonts/Cairo-Bold.ttf");

          _arabicFont = pw.Font.ttf(regularFont);
          _arabicBoldFont = pw.Font.ttf(boldFont);
        } catch (e2) {
          // في حالة فشل جميع الخطوط، نجرب NotoSansArabic
          try {
            final arabicFont = await rootBundle.load(
              "assets/fonts/NotoSansArabic-Regular.ttf",
            );
            _arabicFont = pw.Font.ttf(arabicFont);
            _arabicBoldFont = _arabicFont; // نستخدم نفس الخط للعريض
          } catch (e3) {
            print('فشل في تحميل الخطوط العربية: $e3');
            // سنستخدم الخط الافتراضي
          }
        }
      }
    }
  }

  // دالة مساعدة لإنشاء نمط النص العربي
  static pw.TextStyle _arabicTextStyle({
    double fontSize = 12,
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.TextStyle(
      font: isBold ? _arabicBoldFont : _arabicFont,
      fontSize: fontSize,
      fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: color,
    );
  }

  // طباعة تفاصيل الزبون كاملة
  static Future<void> printCustomerDetails({
    required Person person,
    required List<Debt> debts,
    required List<Installment> installments,
    required List<InternetSubscription> internetSubscriptions,
  }) async {
    try {
      // تحميل الخطوط العربية أولاً
      await _loadArabicFonts();

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          textDirection: pw.TextDirection.rtl,
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              _buildHeader('تفاصيل الزبون: ${person.name}'),
              pw.SizedBox(height: 20),
              _buildCustomerInfo(person),
              pw.SizedBox(height: 20),
              _buildFinancialSummary(
                debts,
                installments,
                internetSubscriptions,
              ),
              pw.SizedBox(height: 20),
              if (debts.isNotEmpty) ...[
                _buildDebtsSection(debts),
                pw.SizedBox(height: 20),
              ],
              if (installments.isNotEmpty) ...[
                _buildInstallmentsSection(installments),
                pw.SizedBox(height: 20),
              ],
              if (internetSubscriptions.isNotEmpty) ...[
                _buildInternetSection(internetSubscriptions),
              ],
            ];
          },
        ),
      );

      await _printOrSavePDF(pdf, 'تفاصيل_الزبون_${person.name}');
    } catch (e) {
      throw Exception('خطأ في طباعة تفاصيل الزبون: $e');
    }
  }

  // معاينة تفاصيل الزبون كاملة (بدون طباعة مباشرة)
  static Future<bool?> showCustomerDetailsPreview({
    required BuildContext context,
    required Person person,
    required List<Debt> debts,
    required List<Installment> installments,
    required List<InternetSubscription> internetSubscriptions,
  }) async {
    try {
      await _loadArabicFonts();

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          textDirection: pw.TextDirection.rtl,
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context ctx) => [
            _buildHeader('تفاصيل الزبون: ${person.name}'),
            pw.SizedBox(height: 20),
            _buildCustomerInfo(person),
            pw.SizedBox(height: 20),
            _buildFinancialSummary(debts, installments, internetSubscriptions),
            pw.SizedBox(height: 20),
            if (debts.isNotEmpty) ...[
              _buildDebtsSection(debts),
              pw.SizedBox(height: 20),
            ],
            if (installments.isNotEmpty) ...[
              _buildInstallmentsSection(installments),
              pw.SizedBox(height: 20),
            ],
            if (internetSubscriptions.isNotEmpty) ...[
              _buildInternetSection(internetSubscriptions),
            ],
          ],
        ),
      );

      return await PDFPreviewDialog.show(
        context: context,
        pdf: pdf,
        title: 'تفاصيل الزبون - ${person.name}',
      );
    } catch (e) {
      throw Exception('خطأ في معاينة تفاصيل الزبون: $e');
    }
  }

  // طباعة الديون فقط
  static Future<void> printDebts(
    List<Debt> debts, {
    String? customerName,
  }) async {
    try {
      // تحميل الخطوط العربية أولاً
      await _loadArabicFonts();

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          textDirection: pw.TextDirection.rtl,
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              _buildHeader(
                customerName != null
                    ? 'ديون الزبون: $customerName'
                    : 'تقرير الديون',
              ),
              pw.SizedBox(height: 20),
              _buildDebtsSection(debts),
              pw.SizedBox(height: 20),
              _buildDebtsSummary(debts),
            ];
          },
        ),
      );

      await _printOrSavePDF(
        pdf,
        customerName != null ? 'ديون_${customerName}' : 'تقرير_الديون',
      );
    } catch (e) {
      throw Exception('خطأ في طباعة الديون: $e');
    }
  }

  // معاينة الديون فقط
  static Future<bool?> showDebtsPreview(
    BuildContext context,
    List<Debt> debts, {
    String? customerName,
  }) async {
    try {
      await _loadArabicFonts();
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          textDirection: pw.TextDirection.rtl,
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context ctx) => [
            _buildHeader(
              customerName != null
                  ? 'ديون الزبون: $customerName'
                  : 'تقرير الديون',
            ),
            pw.SizedBox(height: 20),
            _buildDebtsSection(debts),
            pw.SizedBox(height: 20),
            _buildDebtsSummary(debts),
          ],
        ),
      );
      return await PDFPreviewDialog.show(
        context: context,
        pdf: pdf,
        title: customerName != null
            ? 'ديون الزبون - $customerName'
            : 'تقرير الديون',
      );
    } catch (e) {
      throw Exception('خطأ في معاينة الديون: $e');
    }
  }

  // طباعة الأقساط فقط
  static Future<void> printInstallments(
    List<Installment> installments, {
    String? customerName,
  }) async {
    try {
      // تحميل الخطوط العربية أولاً
      await _loadArabicFonts();

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          textDirection: pw.TextDirection.rtl,
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              _buildHeader(
                customerName != null
                    ? 'أقساط الزبون: $customerName'
                    : 'تقرير الأقساط',
              ),
              pw.SizedBox(height: 20),
              _buildInstallmentsSection(installments),
              pw.SizedBox(height: 20),
              _buildInstallmentsSummary(installments),
            ];
          },
        ),
      );

      await _printOrSavePDF(
        pdf,
        customerName != null ? 'أقساط_${customerName}' : 'تقرير_الأقساط',
      );
    } catch (e) {
      throw Exception('خطأ في طباعة الأقساط: $e');
    }
  }

  // معاينة الأقساط فقط
  static Future<bool?> showInstallmentsPreview(
    BuildContext context,
    List<Installment> installments, {
    String? customerName,
  }) async {
    try {
      await _loadArabicFonts();
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          textDirection: pw.TextDirection.rtl,
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context ctx) => [
            _buildHeader(
              customerName != null
                  ? 'أقساط الزبون: $customerName'
                  : 'تقرير الأقساط',
            ),
            pw.SizedBox(height: 20),
            _buildInstallmentsSection(installments),
            pw.SizedBox(height: 20),
            _buildInstallmentsSummary(installments),
          ],
        ),
      );
      return await PDFPreviewDialog.show(
        context: context,
        pdf: pdf,
        title: customerName != null
            ? 'أقساط الزبون - $customerName'
            : 'تقرير الأقساط',
      );
    } catch (e) {
      throw Exception('خطأ في معاينة الأقساط: $e');
    }
  }

  // طباعة اشتراكات الإنترنت فقط
  static Future<void> printInternetSubscriptions(
    List<InternetSubscription> subscriptions, {
    String? customerName,
  }) async {
    try {
      // تحميل الخطوط العربية أولاً
      await _loadArabicFonts();

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          textDirection: pw.TextDirection.rtl,
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              _buildHeader(
                customerName != null
                    ? 'اشتراكات الإنترنت للزبون: $customerName'
                    : 'تقرير اشتراكات الإنترنت',
              ),
              pw.SizedBox(height: 20),
              _buildInternetSection(subscriptions),
              pw.SizedBox(height: 20),
              _buildInternetSummary(subscriptions),
            ];
          },
        ),
      );

      await _printOrSavePDF(
        pdf,
        customerName != null
            ? 'اشتراكات_${customerName}'
            : 'تقرير_اشتراكات_الإنترنت',
      );
    } catch (e) {
      throw Exception('خطأ في طباعة اشتراكات الإنترنت: $e');
    }
  }

  // معاينة اشتراكات الإنترنت فقط
  static Future<bool?> showInternetSubscriptionsPreview(
    BuildContext context,
    List<InternetSubscription> subscriptions, {
    String? customerName,
  }) async {
    try {
      await _loadArabicFonts();
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          textDirection: pw.TextDirection.rtl,
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context ctx) => [
            _buildHeader(
              customerName != null
                  ? 'اشتراكات الإنترنت للزبون: $customerName'
                  : 'تقرير اشتراكات الإنترنت',
            ),
            pw.SizedBox(height: 20),
            _buildInternetSection(subscriptions),
            pw.SizedBox(height: 20),
            _buildInternetSummary(subscriptions),
          ],
        ),
      );
      return await PDFPreviewDialog.show(
        context: context,
        pdf: pdf,
        title: customerName != null
            ? 'اشتراكات الإنترنت - $customerName'
            : 'تقرير اشتراكات الإنترنت',
      );
    } catch (e) {
      throw Exception('خطأ في معاينة اشتراكات الإنترنت: $e');
    }
  }

  // بناء رأس الصفحة
  static pw.Widget _buildHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'نظام إدارة المتجر',
            style: pw.TextStyle(
              font: _arabicBoldFont,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            title,
            style: pw.TextStyle(
              font: _arabicBoldFont,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue600,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'تاريخ الطباعة: ${DateFormatter.formatDisplayDateTime(DateTime.now())}',
            style: pw.TextStyle(
              font: _arabicFont,
              fontSize: 12,
              color: PdfColors.grey700,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  // بناء معلومات الزبون
  static pw.Widget _buildCustomerInfo(Person person) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'معلومات الزبون',
            style: _arabicTextStyle(
              fontSize: 16,
              isBold: true,
              color: PdfColors.blue800,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'الاسم:',
                style: _arabicTextStyle(fontSize: 12, isBold: true),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                person.name,
                style: _arabicTextStyle(fontSize: 12),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
          if (person.phone != null) ...[
            pw.SizedBox(height: 5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'الهاتف:',
                  style: _arabicTextStyle(fontSize: 12, isBold: true),
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.Text(
                  person.phone!,
                  style: _arabicTextStyle(fontSize: 12),
                  textDirection: pw.TextDirection.rtl,
                ),
              ],
            ),
          ],
          if (person.address != null) ...[
            pw.SizedBox(height: 5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'العنوان:',
                  style: _arabicTextStyle(fontSize: 12, isBold: true),
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.Text(
                  person.address!,
                  style: _arabicTextStyle(fontSize: 12),
                  textDirection: pw.TextDirection.rtl,
                ),
              ],
            ),
          ],
          if (person.notes != null) ...[
            pw.SizedBox(height: 5),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'الملاحظات:',
                  style: _arabicTextStyle(fontSize: 12, isBold: true),
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.Text(
                  person.notes!,
                  style: _arabicTextStyle(fontSize: 12),
                  textDirection: pw.TextDirection.rtl,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // بناء ملخص مالي
  static pw.Widget _buildFinancialSummary(
    List<Debt> debts,
    List<Installment> installments,
    List<InternetSubscription> internetSubscriptions,
  ) {
    double totalDebts = debts.fold(
      0,
      (sum, debt) => sum + debt.remainingAmount,
    );
    double totalInstallments = installments.fold(
      0,
      (sum, installment) => sum + installment.remainingAmount,
    );
    double totalInternet = internetSubscriptions.fold(
      0,
      (sum, subscription) => sum + subscription.remainingAmount,
    );
    double grandTotal = totalDebts + totalInstallments + totalInternet;

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.orange50,
        border: pw.Border.all(color: PdfColors.orange200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'الملخص المالي',
            style: _arabicTextStyle(
              fontSize: 16,
              isBold: true,
              color: PdfColors.orange800,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'إجمالي الديون المتبقية:',
                style: _arabicTextStyle(fontSize: 12),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                '${NumberFormatter.format(totalDebts)} د.ع',
                style: _arabicTextStyle(fontSize: 12, isBold: true),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'إجمالي الأقساط المتبقية:',
                style: _arabicTextStyle(fontSize: 12),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                '${NumberFormatter.format(totalInstallments)} د.ع',
                style: _arabicTextStyle(fontSize: 12, isBold: true),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'إجمالي اشتراكات الإنترنت المتبقية:',
                style: _arabicTextStyle(fontSize: 12),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                '${NumberFormatter.format(totalInternet)} د.ع',
                style: _arabicTextStyle(fontSize: 12, isBold: true),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
          pw.Divider(color: PdfColors.orange300),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'إجمالي المبلغ المتبقي:',
                style: _arabicTextStyle(fontSize: 14, isBold: true),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                '${NumberFormatter.format(grandTotal)} د.ع',
                style: _arabicTextStyle(
                  fontSize: 14,
                  isBold: true,
                  color: PdfColors.red,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // بناء قسم الديون
  static pw.Widget _buildDebtsSection(List<Debt> debts) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'الديون',
          style: _arabicTextStyle(
            fontSize: 16,
            isBold: true,
            color: PdfColors.red800,
          ),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.5),
            4: const pw.FlexColumnWidth(1.5),
            5: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('العنوان', isHeader: true),
                _buildTableCell('المبلغ', isHeader: true),
                _buildTableCell('الحالة', isHeader: true),
                _buildTableCell('تاريخ الإنشاء', isHeader: true),
                _buildTableCell('تاريخ الدفع', isHeader: true),
              ],
            ),
            ...debts.map(
              (debt) => pw.TableRow(
                children: [
                  _buildTableCell(debt.title ?? 'بدون عنوان'),
                  _buildTableCell('${NumberFormatter.format(debt.amount)} د.ع'),
                  _buildTableCell(debt.isPaid ? 'مدفوع' : 'غير مدفوع'),
                  _buildTableCell(
                    DateFormatter.formatDisplayDate(debt.createdAt),
                  ),
                  _buildTableCell(
                    debt.paymentDate != null
                        ? DateFormatter.formatDisplayDate(debt.paymentDate!)
                        : 'لم يدفع بعد',
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // بناء قسم الأقساط
  static pw.Widget _buildInstallmentsSection(List<Installment> installments) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'الأقساط',
          style: _arabicTextStyle(
            fontSize: 16,
            isBold: true,
            color: PdfColors.blue800,
          ),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.5),
            4: const pw.FlexColumnWidth(1.5),
            5: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('المنتج', isHeader: true),
                _buildTableCell('المبلغ الكلي', isHeader: true),
                _buildTableCell('المبلغ المدفوع', isHeader: true),
                _buildTableCell('المبلغ المتبقي', isHeader: true),
                _buildTableCell('الحالة', isHeader: true),
                _buildTableCell('التاريخ', isHeader: true),
              ],
            ),
            ...installments.map(
              (installment) => pw.TableRow(
                children: [
                  _buildTableCell(installment.productName),
                  _buildTableCell(
                    '${NumberFormatter.format(installment.totalAmount)} د.ع',
                  ),
                  _buildTableCell(
                    '${NumberFormatter.format(installment.paidAmount)} د.ع',
                  ),
                  _buildTableCell(
                    '${NumberFormatter.format(installment.remainingAmount)} د.ع',
                  ),
                  _buildTableCell(
                    installment.isCompleted ? 'مكتمل' : 'غير مكتمل',
                  ),
                  _buildTableCell(
                    DateFormatter.formatDisplayDate(installment.createdAt),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // بناء قسم الإنترنت
  static pw.Widget _buildInternetSection(
    List<InternetSubscription> subscriptions,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'اشتراكات الإنترنت',
          style: _arabicTextStyle(
            fontSize: 16,
            isBold: true,
            color: PdfColors.green800,
          ),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.5),
            4: const pw.FlexColumnWidth(1.5),
            5: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('الباقة', isHeader: true),
                _buildTableCell('السعر', isHeader: true),
                _buildTableCell('المبلغ المدفوع', isHeader: true),
                _buildTableCell('المبلغ المتبقي', isHeader: true),
                _buildTableCell('الحالة', isHeader: true),
                _buildTableCell('تاريخ الانتهاء', isHeader: true),
              ],
            ),
            ...subscriptions.map(
              (subscription) => pw.TableRow(
                children: [
                  _buildTableCell(subscription.packageName),
                  _buildTableCell(
                    '${NumberFormatter.format(subscription.price)} د.ع',
                  ),
                  _buildTableCell(
                    '${NumberFormatter.format(subscription.paidAmount)} د.ع',
                  ),
                  _buildTableCell(
                    '${NumberFormatter.format(subscription.remainingAmount)} د.ع',
                  ),
                  _buildTableCell(subscription.isExpired ? 'منتهي' : 'نشط'),
                  _buildTableCell(
                    DateFormatter.formatDisplayDate(subscription.endDate),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // بناء ملخص الديون
  static pw.Widget _buildDebtsSummary(List<Debt> debts) {
    double totalAmount = debts.fold(0, (sum, debt) => sum + debt.amount);
    double paidAmount = debts
        .where((debt) => debt.isPaid)
        .fold(0, (sum, debt) => sum + debt.amount);
    double remainingAmount = debts
        .where((debt) => !debt.isPaid)
        .fold(0, (sum, debt) => sum + debt.amount);
    int paidCount = debts.where((debt) => debt.isPaid).length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.red50,
        border: pw.Border.all(color: PdfColors.red200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ملخص الديون',
            style: _arabicTextStyle(
              fontSize: 16,
              isBold: true,
              color: PdfColors.red800,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'عدد الديون الكلي:',
                style: _arabicTextStyle(fontSize: 12),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                '${debts.length}',
                style: _arabicTextStyle(fontSize: 12, isBold: true),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'عدد الديون المدفوعة:',
                style: _arabicTextStyle(fontSize: 12),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                '$paidCount',
                style: _arabicTextStyle(fontSize: 12, isBold: true),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'إجمالي المبلغ:',
                style: _arabicTextStyle(fontSize: 12),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                '${NumberFormatter.format(totalAmount)} د.ع',
                style: _arabicTextStyle(fontSize: 12, isBold: true),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'المبلغ المدفوع:',
                style: _arabicTextStyle(fontSize: 12),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                '${NumberFormatter.format(paidAmount)} د.ع',
                style: _arabicTextStyle(fontSize: 12, isBold: true),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'المبلغ المتبقي:',
                style: _arabicTextStyle(fontSize: 12),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                '${NumberFormatter.format(remainingAmount)} د.ع',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                  color: PdfColors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // بناء ملخص الأقساط
  static pw.Widget _buildInstallmentsSummary(List<Installment> installments) {
    double totalAmount = installments.fold(
      0,
      (sum, installment) => sum + installment.totalAmount,
    );
    double paidAmount = installments.fold(
      0,
      (sum, installment) => sum + installment.paidAmount,
    );
    double remainingAmount = installments.fold(
      0,
      (sum, installment) => sum + installment.remainingAmount,
    );
    int completedCount = installments
        .where((installment) => installment.isCompleted)
        .length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ملخص الأقساط',
            style: _arabicTextStyle(
              fontSize: 16,
              isBold: true,
              color: PdfColors.blue800,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'عدد الأقساط الكلي:',
                style: _arabicTextStyle(fontSize: 12),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                '${installments.length}',
                style: _arabicTextStyle(fontSize: 12, isBold: true),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'عدد الأقساط المكتملة:',
                style: _arabicTextStyle(fontSize: 12),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                '$completedCount',
                style: _arabicTextStyle(fontSize: 12, isBold: true),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'إجمالي المبلغ:',
                style: _arabicTextStyle(fontSize: 12),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                '${NumberFormatter.format(totalAmount)} د.ع',
                style: _arabicTextStyle(fontSize: 12, isBold: true),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'المبلغ المدفوع:',
                style: _arabicTextStyle(fontSize: 12),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                '${NumberFormatter.format(paidAmount)} د.ع',
                style: _arabicTextStyle(fontSize: 12, isBold: true),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'المبلغ المتبقي:',
                style: _arabicTextStyle(fontSize: 12),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                '${NumberFormatter.format(remainingAmount)} د.ع',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                  color: PdfColors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // بناء ملخص الإنترنت
  static pw.Widget _buildInternetSummary(
    List<InternetSubscription> subscriptions,
  ) {
    double totalAmount = subscriptions.fold(
      0,
      (sum, subscription) => sum + subscription.price,
    );
    double paidAmount = subscriptions.fold(
      0,
      (sum, subscription) => sum + subscription.paidAmount,
    );
    double remainingAmount = subscriptions.fold(
      0,
      (sum, subscription) => sum + subscription.remainingAmount,
    );
    int activeCount = subscriptions
        .where(
          (subscription) => subscription.isActive && !subscription.isExpired,
        )
        .length;
    int expiredCount = subscriptions
        .where((subscription) => subscription.isExpired)
        .length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        border: pw.Border.all(color: PdfColors.green200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ملخص اشتراكات الإنترنت',
            style: _arabicTextStyle(
              fontSize: 16,
              isBold: true,
              color: PdfColors.green800,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'عدد الاشتراكات الكلي:',
                style: _arabicTextStyle(fontSize: 12),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                '${subscriptions.length}',
                style: _arabicTextStyle(fontSize: 12, isBold: true),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'الاشتراكات النشطة:',
                style: _arabicTextStyle(fontSize: 12),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                '$activeCount',
                style: _arabicTextStyle(fontSize: 12, isBold: true),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'الاشتراكات المنتهية:',
                style: _arabicTextStyle(fontSize: 12),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                '$expiredCount',
                style: _arabicTextStyle(fontSize: 12, isBold: true),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'إجمالي المبلغ:',
                style: _arabicTextStyle(fontSize: 12),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                '${NumberFormatter.format(totalAmount)} د.ع',
                style: _arabicTextStyle(fontSize: 12, isBold: true),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'المبلغ المدفوع:',
                style: _arabicTextStyle(fontSize: 12),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                '${NumberFormatter.format(paidAmount)} د.ع',
                style: _arabicTextStyle(fontSize: 12, isBold: true),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'المبلغ المتبقي:',
                style: _arabicTextStyle(fontSize: 12),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                '${NumberFormatter.format(remainingAmount)} د.ع',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                  color: PdfColors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // بناء خلية الجدول
  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: _arabicTextStyle(fontSize: isHeader ? 11 : 10, isBold: isHeader),
        textAlign: pw.TextAlign.center,
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }

  // طباعة أو حفظ PDF
  static Future<void> _printOrSavePDF(pw.Document pdf, String fileName) async {
    if (Platform.isAndroid || Platform.isIOS) {
      // للجوال: حفظ في مجلد Downloads
      final output = await getExternalStorageDirectory();
      final file = File('${output?.path}/$fileName.pdf');
      await file.writeAsBytes(await pdf.save());

      // إظهار خيار الطباعة
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } else {
      // للديسكتوب: إظهار نافذة الطباعة مباشرة
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    }
  }

  // طباعة تفاصيل قسط واحد مع دفعاته
  static Future<void> printInstallmentDetails({
    required Installment installment,
    required Person person,
    required List<InstallmentPayment> payments,
  }) async {
    try {
      await _loadArabicFonts();

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          textDirection: pw.TextDirection.rtl,
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              _buildHeader('تفاصيل القسط'),
              pw.SizedBox(height: 20),
              _buildCustomerInfo(person),
              pw.SizedBox(height: 20),
              _buildSingleInstallmentSummary(installment),
              pw.SizedBox(height: 20),
              if (payments.isNotEmpty) ...[
                _buildInstallmentPaymentsSection(payments),
              ],
            ];
          },
        ),
      );

      await _printOrSavePDF(
        pdf,
        'تفاصيل_قسط_${person.name}_${installment.productName}',
      );
    } catch (e) {
      throw Exception('خطأ في طباعة تفاصيل القسط: $e');
    }
  }

  // بناء ملخص قسط واحد
  static pw.Widget _buildSingleInstallmentSummary(Installment installment) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'تفاصيل القسط: ${installment.productName}',
            style: _arabicTextStyle(
              fontSize: 16,
              isBold: true,
              color: PdfColors.blue800,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 10),
          _buildSummaryRow(
            'المبلغ الإجمالي:',
            '${NumberFormatter.format(installment.totalAmount)} د.ع',
          ),
          _buildSummaryRow(
            'المبلغ المدفوع:',
            '${NumberFormatter.format(installment.paidAmount)} د.ع',
            color: PdfColors.green,
          ),
          _buildSummaryRow(
            'المبلغ المتبقي:',
            '${NumberFormatter.format(installment.remainingAmount)} د.ع',
            color: PdfColors.red,
          ),
          _buildSummaryRow(
            'الحالة:',
            installment.isCompleted ? 'مكتمل' : 'نشط',
          ),
          _buildSummaryRow(
            'تاريخ الإنشاء:',
            DateFormatter.formatDisplayDate(installment.createdAt),
          ),
        ],
      ),
    );
  }

  // بناء قسم دفعات القسط
  static pw.Widget _buildInstallmentPaymentsSection(
    List<InstallmentPayment> payments,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'سجل الدفعات',
          style: _arabicTextStyle(
            fontSize: 16,
            isBold: true,
            color: PdfColors.green800,
          ),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(3),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('تاريخ الدفعة', isHeader: true),
                _buildTableCell('المبلغ', isHeader: true),
                _buildTableCell('الملاحظات', isHeader: true),
              ],
            ),
            ...payments.map(
              (payment) => pw.TableRow(
                children: [
                  _buildTableCell(
                    DateFormatter.formatDisplayDateTime(payment.paymentDate),
                  ),
                  _buildTableCell(
                    '${NumberFormatter.format(payment.amount)} د.ع',
                  ),
                  _buildTableCell(payment.notes ?? 'لا توجد'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper for summary rows
  static pw.Widget _buildSummaryRow(
    String title,
    String value, {
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            title,
            style: _arabicTextStyle(fontSize: 12, isBold: true),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.Text(
            value,
            style: _arabicTextStyle(fontSize: 12, color: color),
            textDirection: pw.TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  // طباعة وصل اشتراك إنترنت صغير (A5 مع وصلين)
  static Future<void> printInternetSubscriptionReceipt({
    required InternetSubscription subscription,
    required Person person,
  }) async {
    try {
      // تحميل الخطوط العربية أولاً
      await _loadArabicFonts();

      final pdf = pw.Document();
      final printTime = DateTime.now();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a5,
          textDirection: pw.TextDirection.rtl,
          build: (pw.Context context) {
            return pw.Column(
              children: [
                // الوصل الأول
                _buildReceiptCard(subscription, person, printTime),
                pw.SizedBox(height: 10),
                // خط فاصل
                pw.Container(
                  height: 1,
                  width: double.infinity,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color: PdfColors.grey300,
                      style: pw.BorderStyle.dashed,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                // الوصل الثاني (نفس المحتوى)
                _buildReceiptCard(subscription, person, printTime),
              ],
            );
          },
        ),
      );

      await _printOrSavePDF(
        pdf,
        'وصل_اشتراك_${person.name}_${subscription.id}',
      );
    } catch (e) {
      throw Exception('خطأ في طباعة وصل الاشتراك: $e');
    }
  }

  // عرض معاينة وصل اشتراك إنترنت مع إمكانية الطباعة
  static Future<bool?> showInternetSubscriptionReceiptPreview({
    required BuildContext context,
    required InternetSubscription subscription,
    required Person person,
  }) async {
    try {
      // تحميل الخطوط العربية أولاً
      await _loadArabicFonts();

      final pdf = pw.Document();
      final printTime = DateTime.now();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a5,
          textDirection: pw.TextDirection.rtl,
          build: (pw.Context context) {
            return pw.Column(
              children: [
                // الوصل الأول
                _buildReceiptCard(subscription, person, printTime),
                pw.SizedBox(height: 10),
                // خط فاصل
                pw.Container(
                  height: 1,
                  width: double.infinity,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color: PdfColors.grey300,
                      style: pw.BorderStyle.dashed,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                // الوصل الثاني (نفس المحتوى)
                _buildReceiptCard(subscription, person, printTime),
              ],
            );
          },
        ),
      );

      // عرض نافذة المعاينة
      return await PDFPreviewDialog.show(
        context: context,
        pdf: pdf,
        title: 'وصل اشتراك إنترنت - ${person.name}',
      );
    } catch (e) {
      throw Exception('خطأ في عرض معاينة وصل الاشتراك: $e');
    }
  }

  // بناء كارت الوصل
  static pw.Widget _buildReceiptCard(
    InternetSubscription subscription,
    Person person,
    DateTime printTime,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // رأس الوصل
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

          // معلومات الزبون
          _buildReceiptRow('اسم الزبون:', person.name),
          _buildReceiptRow('رقم الزبون:', '${person.id}'),

          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 8),

          // تفاصيل الاشتراك
          _buildReceiptRow('نوع الاشتراك:', subscription.packageName),
          _buildReceiptRow(
            'سعر الاشتراك:',
            '${NumberFormatter.format(subscription.price)} د.ع',
          ),
          _buildReceiptRow(
            'تاريخ البداية:',
            DateFormatter.formatDisplayDate(subscription.startDate),
          ),
          _buildReceiptRow(
            'تاريخ الدفع:',
            DateFormatter.formatDisplayDate(subscription.paymentDate),
          ),
          _buildReceiptRow(
            'المبلغ المدفوع:',
            '${NumberFormatter.format(subscription.paidAmount)} د.ع',
          ),

          // الملاحظات إذا وجدت
          if (subscription.notes != null && subscription.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 5),
            _buildReceiptRow('الملاحظات:', subscription.notes!),
          ],

          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 8),

          // تاريخ ووقت الطباعة
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

  // بناء صف في الوصل
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
              textAlign: pw.TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}
