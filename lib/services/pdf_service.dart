import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/person_model.dart';
import '../models/debt_model.dart';
import '../models/installment_model.dart';
import '../models/internet_model.dart';
import '../utils/date_formatter.dart';
import '../utils/number_formatter.dart';

class PDFService {
  // طباعة تفاصيل الزبون كاملة
  static Future<void> printCustomerDetails({
    required Person person,
    required List<Debt> debts,
    required List<Installment> installments,
    required List<InternetSubscription> internetSubscriptions,
  }) async {
    try {
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
            ];
          },
        ),
      );

      await _printOrSavePDF(pdf, 'تفاصيل_الزبون_${person.name}');
    } catch (e) {
      throw Exception('خطأ في طباعة تفاصيل الزبون: $e');
    }
  }

  // طباعة الديون فقط
  static Future<void> printDebts(List<Debt> debts, {String? customerName}) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          textDirection: pw.TextDirection.rtl,
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              _buildHeader(customerName != null ? 'ديون الزبون: $customerName' : 'تقرير الديون'),
              pw.SizedBox(height: 20),
              _buildDebtsSection(debts),
              pw.SizedBox(height: 20),
              _buildDebtsSummary(debts),
            ];
          },
        ),
      );

      await _printOrSavePDF(pdf, customerName != null ? 'ديون_${customerName}' : 'تقرير_الديون');
    } catch (e) {
      throw Exception('خطأ في طباعة الديون: $e');
    }
  }

  // طباعة الأقساط فقط
  static Future<void> printInstallments(List<Installment> installments, {String? customerName}) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          textDirection: pw.TextDirection.rtl,
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              _buildHeader(customerName != null ? 'أقساط الزبون: $customerName' : 'تقرير الأقساط'),
              pw.SizedBox(height: 20),
              _buildInstallmentsSection(installments),
              pw.SizedBox(height: 20),
              _buildInstallmentsSummary(installments),
            ];
          },
        ),
      );

      await _printOrSavePDF(pdf, customerName != null ? 'أقساط_${customerName}' : 'تقرير_الأقساط');
    } catch (e) {
      throw Exception('خطأ في طباعة الأقساط: $e');
    }
  }

  // طباعة اشتراكات الإنترنت فقط
  static Future<void> printInternetSubscriptions(List<InternetSubscription> subscriptions, {String? customerName}) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          textDirection: pw.TextDirection.rtl,
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              _buildHeader(customerName != null ? 'اشتراكات الإنترنت للزبون: $customerName' : 'تقرير اشتراكات الإنترنت'),
              pw.SizedBox(height: 20),
              _buildInternetSection(subscriptions),
              pw.SizedBox(height: 20),
              _buildInternetSummary(subscriptions),
            ];
          },
        ),
      );

      await _printOrSavePDF(pdf, customerName != null ? 'اشتراكات_${customerName}' : 'تقرير_اشتراكات_الإنترنت');
    } catch (e) {
      throw Exception('خطأ في طباعة اشتراكات الإنترنت: $e');
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
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue600,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'تاريخ الطباعة: ${DateFormatter.formatDisplayDateTime(DateTime.now())}',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey700,
            ),
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
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('الاسم:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.Text(person.name, style: pw.TextStyle(fontSize: 12)),
            ],
          ),
          if (person.phone != null) ...[
            pw.SizedBox(height: 5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('الهاتف:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.Text(person.phone!, style: pw.TextStyle(fontSize: 12)),
              ],
            ),
          ],
          if (person.address != null) ...[
            pw.SizedBox(height: 5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('العنوان:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.Text(person.address!, style: pw.TextStyle(fontSize: 12)),
              ],
            ),
          ],
          if (person.notes != null) ...[
            pw.SizedBox(height: 5),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('الملاحظات:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.Text(person.notes!, style: pw.TextStyle(fontSize: 12)),
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
    double totalDebts = debts.fold(0, (sum, debt) => sum + debt.remainingAmount);
    double totalInstallments = installments.fold(0, (sum, installment) => sum + installment.remainingAmount);
    double totalInternet = internetSubscriptions.fold(0, (sum, subscription) => sum + subscription.remainingAmount);
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
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.orange800,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('إجمالي الديون المتبقية:', style: pw.TextStyle(fontSize: 12)),
              pw.Text('${NumberFormatter.format(totalDebts)} د.ع', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('إجمالي الأقساط المتبقية:', style: pw.TextStyle(fontSize: 12)),
              pw.Text('${NumberFormatter.format(totalInstallments)} د.ع', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('إجمالي اشتراكات الإنترنت المتبقية:', style: pw.TextStyle(fontSize: 12)),
              pw.Text('${NumberFormatter.format(totalInternet)} د.ع', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            ],
          ),
          pw.Divider(color: PdfColors.orange300),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('إجمالي المبلغ المتبقي:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.Text('${NumberFormatter.format(grandTotal)} د.ع', 
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.red)),
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
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.red800,
          ),
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
                _buildTableCell('المبلغ الكلي', isHeader: true),
                _buildTableCell('المبلغ المدفوع', isHeader: true),
                _buildTableCell('المبلغ المتبقي', isHeader: true),
                _buildTableCell('الحالة', isHeader: true),
                _buildTableCell('التاريخ', isHeader: true),
              ],
            ),
            ...debts.map((debt) => pw.TableRow(
              children: [
                _buildTableCell(debt.title ?? 'بدون عنوان'),
                _buildTableCell('${NumberFormatter.format(debt.amount)} د.ع'),
                _buildTableCell('${NumberFormatter.format(debt.paidAmount)} د.ع'),
                _buildTableCell('${NumberFormatter.format(debt.remainingAmount)} د.ع'),
                _buildTableCell(debt.isPaid ? 'مدفوع' : 'غير مدفوع'),
                _buildTableCell(DateFormatter.formatDisplayDate(debt.createdAt)),
              ],
            )),
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
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
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
            ...installments.map((installment) => pw.TableRow(
              children: [
                _buildTableCell(installment.productName),
                _buildTableCell('${NumberFormatter.format(installment.totalAmount)} د.ع'),
                _buildTableCell('${NumberFormatter.format(installment.paidAmount)} د.ع'),
                _buildTableCell('${NumberFormatter.format(installment.remainingAmount)} د.ع'),
                _buildTableCell(installment.isCompleted ? 'مكتمل' : 'غير مكتمل'),
                _buildTableCell(DateFormatter.formatDisplayDate(installment.createdAt)),
              ],
            )),
          ],
        ),
      ],
    );
  }

  // بناء قسم الإنترنت
  static pw.Widget _buildInternetSection(List<InternetSubscription> subscriptions) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'اشتراكات الإنترنت',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green800,
          ),
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
            ...subscriptions.map((subscription) => pw.TableRow(
              children: [
                _buildTableCell(subscription.packageName),
                _buildTableCell('${NumberFormatter.format(subscription.price)} د.ع'),
                _buildTableCell('${NumberFormatter.format(subscription.paidAmount)} د.ع'),
                _buildTableCell('${NumberFormatter.format(subscription.remainingAmount)} د.ع'),
                _buildTableCell(subscription.isExpired ? 'منتهي' : 'نشط'),
                _buildTableCell(DateFormatter.formatDisplayDate(subscription.endDate)),
              ],
            )),
          ],
        ),
      ],
    );
  }

  // بناء ملخص الديون
  static pw.Widget _buildDebtsSummary(List<Debt> debts) {
    double totalAmount = debts.fold(0, (sum, debt) => sum + debt.amount);
    double paidAmount = debts.fold(0, (sum, debt) => sum + debt.paidAmount);
    double remainingAmount = debts.fold(0, (sum, debt) => sum + debt.remainingAmount);
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
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.red800,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('عدد الديون الكلي:', style: pw.TextStyle(fontSize: 12)),
              pw.Text('${debts.length}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('عدد الديون المدفوعة:', style: pw.TextStyle(fontSize: 12)),
              pw.Text('$paidCount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('إجمالي المبلغ:', style: pw.TextStyle(fontSize: 12)),
              pw.Text('${NumberFormatter.format(totalAmount)} د.ع', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('المبلغ المدفوع:', style: pw.TextStyle(fontSize: 12)),
              pw.Text('${NumberFormatter.format(paidAmount)} د.ع', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('المبلغ المتبقي:', style: pw.TextStyle(fontSize: 12)),
              pw.Text('${NumberFormatter.format(remainingAmount)} د.ع', 
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.red)),
            ],
          ),
        ],
      ),
    );
  }

  // بناء ملخص الأقساط
  static pw.Widget _buildInstallmentsSummary(List<Installment> installments) {
    double totalAmount = installments.fold(0, (sum, installment) => sum + installment.totalAmount);
    double paidAmount = installments.fold(0, (sum, installment) => sum + installment.paidAmount);
    double remainingAmount = installments.fold(0, (sum, installment) => sum + installment.remainingAmount);
    int completedCount = installments.where((installment) => installment.isCompleted).length;

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
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('عدد الأقساط الكلي:', style: pw.TextStyle(fontSize: 12)),
              pw.Text('${installments.length}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('عدد الأقساط المكتملة:', style: pw.TextStyle(fontSize: 12)),
              pw.Text('$completedCount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('إجمالي المبلغ:', style: pw.TextStyle(fontSize: 12)),
              pw.Text('${NumberFormatter.format(totalAmount)} د.ع', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('المبلغ المدفوع:', style: pw.TextStyle(fontSize: 12)),
              pw.Text('${NumberFormatter.format(paidAmount)} د.ع', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('المبلغ المتبقي:', style: pw.TextStyle(fontSize: 12)),
              pw.Text('${NumberFormatter.format(remainingAmount)} د.ع', 
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.red)),
            ],
          ),
        ],
      ),
    );
  }

  // بناء ملخص الإنترنت
  static pw.Widget _buildInternetSummary(List<InternetSubscription> subscriptions) {
    double totalAmount = subscriptions.fold(0, (sum, subscription) => sum + subscription.price);
    double paidAmount = subscriptions.fold(0, (sum, subscription) => sum + subscription.paidAmount);
    double remainingAmount = subscriptions.fold(0, (sum, subscription) => sum + subscription.remainingAmount);
    int activeCount = subscriptions.where((subscription) => subscription.isActive && !subscription.isExpired).length;
    int expiredCount = subscriptions.where((subscription) => subscription.isExpired).length;

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
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('عدد الاشتراكات الكلي:', style: pw.TextStyle(fontSize: 12)),
              pw.Text('${subscriptions.length}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('الاشتراكات النشطة:', style: pw.TextStyle(fontSize: 12)),
              pw.Text('$activeCount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('الاشتراكات المنتهية:', style: pw.TextStyle(fontSize: 12)),
              pw.Text('$expiredCount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('إجمالي المبلغ:', style: pw.TextStyle(fontSize: 12)),
              pw.Text('${NumberFormatter.format(totalAmount)} د.ع', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('المبلغ المدفوع:', style: pw.TextStyle(fontSize: 12)),
              pw.Text('${NumberFormatter.format(paidAmount)} د.ع', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('المبلغ المتبقي:', style: pw.TextStyle(fontSize: 12)),
              pw.Text('${NumberFormatter.format(remainingAmount)} د.ع', 
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.red)),
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
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
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
}
