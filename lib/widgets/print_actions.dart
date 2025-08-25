import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/debt_provider.dart';
import '../providers/installment_provider.dart';
import '../providers/internet_provider.dart';
import '../services/pdf_service.dart' as pdf_service;

/// أزرار وإجراءات الطباعة لنقلها إلى الـ AppBar بدل وجود أزرار كبيرة في الصفحة.
/// تدعم الأنواع: debts, installments, internet
class PrintActions {
  static Future<void> printAll(BuildContext context, String type) async {
    try {
      _showLoadingDialog(context, 'جاري تحضير التقرير...');
      bool dataFound = false;
      switch (type) {
        case 'debts':
          final provider = Provider.of<DebtProvider>(context, listen: false);
          if (provider.debts.isEmpty) {
            _showInfoSnackBar(context, 'لا توجد ديون للطباعة');
          } else {
            await pdf_service.PDFService.printDebts(provider.debts);
            dataFound = true;
          }
          break;
        case 'installments':
          final provider = Provider.of<InstallmentProvider>(
            context,
            listen: false,
          );
          if (provider.installments.isEmpty) {
            _showInfoSnackBar(context, 'لا توجد أقساط للطباعة');
          } else {
            await pdf_service.PDFService.printInstallments(
              provider.installments,
            );
            dataFound = true;
          }
          break;
        case 'internet':
          final provider = Provider.of<InternetProvider>(
            context,
            listen: false,
          );
          if (provider.subscriptions.isEmpty) {
            _showInfoSnackBar(context, 'لا توجد اشتراكات إنترنت للطباعة');
          } else {
            await pdf_service.PDFService.printInternetSubscriptions(
              provider.subscriptions,
            );
            dataFound = true;
          }
          break;
      }
      if (!context.mounted) return;
      Navigator.of(context).pop();
      if (dataFound) {
        _showSuccessSnackBar(context, 'تم تحضير التقرير بنجاح');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        _showErrorSnackBar(context, 'خطأ في طباعة التقرير: $e');
      }
    }
  }

  static void showSelectionDialog(BuildContext context, String type) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('طباعة محددة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('اختر نوع التقرير:'),
            const SizedBox(height: 16),
            _buildSelectionButton(
              dialogContext,
              'المدفوع فقط',
              Icons.check_circle,
              Colors.green,
              () {
                Navigator.of(dialogContext).pop();
                _printPaidOnly(context, type);
              },
            ),
            const SizedBox(height: 8),
            _buildSelectionButton(
              dialogContext,
              'غير المدفوع فقط',
              Icons.pending,
              Colors.red,
              () {
                Navigator.of(dialogContext).pop();
                _printUnpaidOnly(context, type);
              },
            ),
            const SizedBox(height: 8),
            _buildSelectionButton(
              dialogContext,
              'حسب التاريخ',
              Icons.date_range,
              Colors.blue,
              () {
                Navigator.of(dialogContext).pop();
                _printByDate(context, type);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  static Widget _buildSelectionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }

  static Future<void> _printPaidOnly(BuildContext context, String type) async {
    try {
      _showLoadingDialog(context, 'جاري تحضير تقرير المدفوعات...');
      bool dataFound = false;
      switch (type) {
        case 'debts':
          final provider = Provider.of<DebtProvider>(context, listen: false);
          final paid = provider.debts.where((d) => d.isPaid).toList();
          if (paid.isEmpty) {
            _showInfoSnackBar(context, 'لا توجد ديون مدفوعة');
          } else {
            await pdf_service.PDFService.printDebts(paid);
            dataFound = true;
          }
          break;
        case 'installments':
          final provider = Provider.of<InstallmentProvider>(
            context,
            listen: false,
          );
          final completed = provider.installments
              .where((i) => i.isCompleted)
              .toList();
          if (completed.isEmpty) {
            _showInfoSnackBar(context, 'لا توجد أقساط مكتملة');
          } else {
            await pdf_service.PDFService.printInstallments(completed);
            dataFound = true;
          }
          break;
        case 'internet':
          final provider = Provider.of<InternetProvider>(
            context,
            listen: false,
          );
          final paidSubs = provider.subscriptions
              .where((s) => s.remainingAmount <= 0)
              .toList();
          if (paidSubs.isEmpty) {
            _showInfoSnackBar(context, 'لا توجد اشتراكات مدفوعة بالكامل');
          } else {
            await pdf_service.PDFService.printInternetSubscriptions(paidSubs);
            dataFound = true;
          }
          break;
      }
      if (!context.mounted) return;
      Navigator.of(context).pop();
      if (dataFound)
        _showSuccessSnackBar(context, 'تم تحضير تقرير المدفوعات بنجاح');
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        _showErrorSnackBar(context, 'خطأ في طباعة التقرير: $e');
      }
    }
  }

  static Future<void> _printUnpaidOnly(
    BuildContext context,
    String type,
  ) async {
    try {
      _showLoadingDialog(context, 'جاري تحضير تقرير غير المدفوعات...');
      bool dataFound = false;
      switch (type) {
        case 'debts':
          final provider = Provider.of<DebtProvider>(context, listen: false);
          final unpaid = provider.debts.where((d) => !d.isPaid).toList();
          if (unpaid.isEmpty) {
            _showInfoSnackBar(context, 'لا توجد ديون غير مدفوعة');
          } else {
            await pdf_service.PDFService.printDebts(unpaid);
            dataFound = true;
          }
          break;
        case 'installments':
          final provider = Provider.of<InstallmentProvider>(
            context,
            listen: false,
          );
          final incomplete = provider.installments
              .where((i) => !i.isCompleted)
              .toList();
          if (incomplete.isEmpty) {
            _showInfoSnackBar(context, 'لا توجد أقساط غير مكتملة');
          } else {
            await pdf_service.PDFService.printInstallments(incomplete);
            dataFound = true;
          }
          break;
        case 'internet':
          final provider = Provider.of<InternetProvider>(
            context,
            listen: false,
          );
          final unpaidSubs = provider.subscriptions
              .where((s) => s.remainingAmount > 0)
              .toList();
          if (unpaidSubs.isEmpty) {
            _showInfoSnackBar(context, 'لا توجد اشتراكات غير مدفوعة');
          } else {
            await pdf_service.PDFService.printInternetSubscriptions(unpaidSubs);
            dataFound = true;
          }
          break;
      }
      if (!context.mounted) return;
      Navigator.of(context).pop();
      if (dataFound)
        _showSuccessSnackBar(context, 'تم تحضير تقرير غير المدفوعات بنجاح');
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        _showErrorSnackBar(context, 'خطأ في طباعة التقرير: $e');
      }
    }
  }

  static Future<void> _printByDate(BuildContext context, String type) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
    );
    if (range == null) return;

    try {
      _showLoadingDialog(context, 'جاري تحضير تقرير حسب التاريخ...');
      bool dataFound = false;
      switch (type) {
        case 'debts':
          final provider = Provider.of<DebtProvider>(context, listen: false);
          final list = provider.debts
              .where(
                (d) =>
                    d.createdAt.isAfter(range.start) &&
                    d.createdAt.isBefore(
                      range.end.add(const Duration(days: 1)),
                    ),
              )
              .toList();
          if (list.isEmpty) {
            _showInfoSnackBar(context, 'لا توجد ديون في الفترة المحددة');
          } else {
            await pdf_service.PDFService.printDebts(list);
            dataFound = true;
          }
          break;
        case 'installments':
          final provider = Provider.of<InstallmentProvider>(
            context,
            listen: false,
          );
          final list = provider.installments
              .where(
                (i) =>
                    i.createdAt.isAfter(range.start) &&
                    i.createdAt.isBefore(
                      range.end.add(const Duration(days: 1)),
                    ),
              )
              .toList();
          if (list.isEmpty) {
            _showInfoSnackBar(context, 'لا توجد أقساط في الفترة المحددة');
          } else {
            await pdf_service.PDFService.printInstallments(list);
            dataFound = true;
          }
          break;
        case 'internet':
          final provider = Provider.of<InternetProvider>(
            context,
            listen: false,
          );
          final list = provider.subscriptions
              .where(
                (s) =>
                    s.createdAt.isAfter(range.start) &&
                    s.createdAt.isBefore(
                      range.end.add(const Duration(days: 1)),
                    ),
              )
              .toList();
          if (list.isEmpty) {
            _showInfoSnackBar(context, 'لا توجد اشتراكات في الفترة المحددة');
          } else {
            await pdf_service.PDFService.printInternetSubscriptions(list);
            dataFound = true;
          }
          break;
      }
      if (!context.mounted) return;
      Navigator.of(context).pop();
      if (dataFound)
        _showSuccessSnackBar(context, 'تم تحضير التقرير حسب التاريخ بنجاح');
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        _showErrorSnackBar(context, 'خطأ في طباعة التقرير: $e');
      }
    }
  }

  // Helpers
  static void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  static void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void _showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
