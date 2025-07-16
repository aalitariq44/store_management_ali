import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/debt_model.dart';
import '../models/installment_model.dart';
import '../models/internet_model.dart';
import '../providers/debt_provider.dart';
import '../providers/installment_provider.dart';
import '../providers/internet_provider.dart';
import '../services/pdf_service.dart';

class GeneralPrintWidget extends StatefulWidget {
  final String type; // 'debts', 'installments', 'internet'

  const GeneralPrintWidget({
    super.key,
    required this.type,
  });

  @override
  State<GeneralPrintWidget> createState() => _GeneralPrintWidgetState();
}

class _GeneralPrintWidgetState extends State<GeneralPrintWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPrintButton(
            context,
            'طباعة الكل',
            Icons.print,
            Colors.blue,
            () => _printAll(),
          ),
          _buildPrintButton(
            context,
            'طباعة المحدد',
            Icons.print_outlined,
            Colors.orange,
            () => _printSelected(),
          ),
        ],
      ),
    );
  }

  Widget _buildPrintButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _printAll() async {
    try {
      _showLoadingDialog(context, 'جاري تحضير التقرير...');

      bool dataFound = false;
      switch (widget.type) {
        case 'debts':
          dataFound = await _printAllDebts();
          break;
        case 'installments':
          dataFound = await _printAllInstallments();
          break;
        case 'internet':
          dataFound = await _printAllInternet();
          break;
      }

      if (!mounted) return;
      Navigator.of(context).pop(); // إغلاق نافذة التحميل

      if (dataFound) {
        _showSuccessSnackBar(context, 'تم تحضير التقرير بنجاح');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // إغلاق نافذة التحميل
      _showErrorSnackBar(context, 'خطأ في طباعة التقرير: $e');
    }
  }

  Future<bool> _printAllDebts() async {
    final debtProvider = Provider.of<DebtProvider>(context, listen: false);
    final debts = debtProvider.debts;

    if (debts.isEmpty) {
      _showInfoSnackBar(context, 'لا توجد ديون للطباعة');
      return false;
    }

    await PDFService.printDebts(debts);
    return true;
  }

  Future<bool> _printAllInstallments() async {
    final installmentProvider =
        Provider.of<InstallmentProvider>(context, listen: false);
    final installments = installmentProvider.installments;

    if (installments.isEmpty) {
      _showInfoSnackBar(context, 'لا توجد أقساط للطباعة');
      return false;
    }

    await PDFService.printInstallments(installments);
    return true;
  }

  Future<bool> _printAllInternet() async {
    final internetProvider =
        Provider.of<InternetProvider>(context, listen: false);
    final subscriptions = internetProvider.subscriptions;

    if (subscriptions.isEmpty) {
      _showInfoSnackBar(context, 'لا توجد اشتراكات إنترنت للطباعة');
      return false;
    }

    await PDFService.printInternetSubscriptions(subscriptions);
    return true;
  }

  void _printSelected() {
    _showSelectionDialog();
  }

  void _showSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('طباعة محددة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('اختر نوع التقرير:'),
              const SizedBox(height: 16),
              _buildSelectionOption(
                'المدفوع فقط',
                Icons.check_circle,
                Colors.green,
                () {
                  Navigator.of(dialogContext).pop();
                  _printPaidOnly();
                },
              ),
              const SizedBox(height: 8),
              _buildSelectionOption(
                'غير المدفوع فقط',
                Icons.pending,
                Colors.red,
                () {
                  Navigator.of(dialogContext).pop();
                  _printUnpaidOnly();
                },
              ),
              const SizedBox(height: 8),
              _buildSelectionOption(
                'حسب التاريخ',
                Icons.date_range,
                Colors.blue,
                () {
                  Navigator.of(dialogContext).pop();
                  _printByDate();
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
        );
      },
    );
  }

  Widget _buildSelectionOption(
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

  Future<void> _printPaidOnly() async {
    try {
      _showLoadingDialog(context, 'جاري تحضير تقرير المدفوعات...');

      bool dataFound = false;
      switch (widget.type) {
        case 'debts':
          final debtProvider = Provider.of<DebtProvider>(context, listen: false);
          final paidDebts =
              debtProvider.debts.where((debt) => debt.isPaid).toList();
          if (paidDebts.isEmpty) {
            _showInfoSnackBar(context, 'لا توجد ديون مدفوعة');
          } else {
            await PDFService.printDebts(paidDebts);
            dataFound = true;
          }
          break;
        case 'installments':
          final installmentProvider =
              Provider.of<InstallmentProvider>(context, listen: false);
          final completedInstallments = installmentProvider.installments
              .where((installment) => installment.isCompleted)
              .toList();
          if (completedInstallments.isEmpty) {
            _showInfoSnackBar(context, 'لا توجد أقساط مكتملة');
          } else {
            await PDFService.printInstallments(completedInstallments);
            dataFound = true;
          }
          break;
        case 'internet':
          final internetProvider =
              Provider.of<InternetProvider>(context, listen: false);
          final paidSubscriptions = internetProvider.subscriptions
              .where((subscription) => subscription.remainingAmount <= 0)
              .toList();
          if (paidSubscriptions.isEmpty) {
            _showInfoSnackBar(context, 'لا توجد اشتراكات مدفوعة بالكامل');
          } else {
            await PDFService.printInternetSubscriptions(paidSubscriptions);
            dataFound = true;
          }
          break;
      }

      if (!mounted) return;
      Navigator.of(context).pop(); // إغلاق نافذة التحميل
      if (dataFound) {
        _showSuccessSnackBar(context, 'تم تحضير تقرير المدفوعات بنجاح');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // إغلاق نافذة التحميل
      _showErrorSnackBar(context, 'خطأ في طباعة التقرير: $e');
    }
  }

  Future<void> _printUnpaidOnly() async {
    try {
      _showLoadingDialog(context, 'جاري تحضير تقرير غير المدفوعات...');

      bool dataFound = false;
      switch (widget.type) {
        case 'debts':
          final debtProvider = Provider.of<DebtProvider>(context, listen: false);
          final unpaidDebts =
              debtProvider.debts.where((debt) => !debt.isPaid).toList();
          if (unpaidDebts.isEmpty) {
            _showInfoSnackBar(context, 'لا توجد ديون غير مدفوعة');
          } else {
            await PDFService.printDebts(unpaidDebts);
            dataFound = true;
          }
          break;
        case 'installments':
          final installmentProvider =
              Provider.of<InstallmentProvider>(context, listen: false);
          final incompleteInstallments = installmentProvider.installments
              .where((installment) => !installment.isCompleted)
              .toList();
          if (incompleteInstallments.isEmpty) {
            _showInfoSnackBar(context, 'لا توجد أقساط غير مكتملة');
          } else {
            await PDFService.printInstallments(incompleteInstallments);
            dataFound = true;
          }
          break;
        case 'internet':
          final internetProvider =
              Provider.of<InternetProvider>(context, listen: false);
          final unpaidSubscriptions = internetProvider.subscriptions
              .where((subscription) => subscription.remainingAmount > 0)
              .toList();
          if (unpaidSubscriptions.isEmpty) {
            _showInfoSnackBar(context, 'لا توجد اشتراكات غير مدفوعة');
          } else {
            await PDFService.printInternetSubscriptions(unpaidSubscriptions);
            dataFound = true;
          }
          break;
      }

      if (!mounted) return;
      Navigator.of(context).pop(); // إغلاق نافذة التحميل
      if (dataFound) {
        _showSuccessSnackBar(context, 'تم تحضير تقرير غير المدفوعات بنجاح');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // إغلاق نافذة التحميل
      _showErrorSnackBar(context, 'خطأ في طباعة التقرير: $e');
    }
  }

  Future<void> _printByDate() async {
    final DateTimeRange? dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
    );

    if (dateRange == null) return;
    if (!mounted) return;

    try {
      _showLoadingDialog(context, 'جاري تحضير تقرير حسب التاريخ...');

      bool dataFound = false;
      switch (widget.type) {
        case 'debts':
          final debtProvider = Provider.of<DebtProvider>(context, listen: false);
          final debtsInRange = debtProvider.debts
              .where((debt) =>
                  debt.createdAt.isAfter(dateRange.start) &&
                  debt.createdAt
                      .isBefore(dateRange.end.add(const Duration(days: 1))))
              .toList();
          if (debtsInRange.isEmpty) {
            _showInfoSnackBar(context, 'لا توجد ديون في الفترة المحددة');
          } else {
            await PDFService.printDebts(debtsInRange);
            dataFound = true;
          }
          break;
        case 'installments':
          final installmentProvider =
              Provider.of<InstallmentProvider>(context, listen: false);
          final installmentsInRange = installmentProvider.installments
              .where((installment) =>
                  installment.createdAt.isAfter(dateRange.start) &&
                  installment.createdAt
                      .isBefore(dateRange.end.add(const Duration(days: 1))))
              .toList();
          if (installmentsInRange.isEmpty) {
            _showInfoSnackBar(context, 'لا توجد أقساط في الفترة المحددة');
          } else {
            await PDFService.printInstallments(installmentsInRange);
            dataFound = true;
          }
          break;
        case 'internet':
          final internetProvider =
              Provider.of<InternetProvider>(context, listen: false);
          final subscriptionsInRange = internetProvider.subscriptions
              .where((subscription) =>
                  subscription.createdAt.isAfter(dateRange.start) &&
                  subscription.createdAt
                      .isBefore(dateRange.end.add(const Duration(days: 1))))
              .toList();
          if (subscriptionsInRange.isEmpty) {
            _showInfoSnackBar(context, 'لا توجد اشتراكات في الفترة المحددة');
          } else {
            await PDFService.printInternetSubscriptions(subscriptionsInRange);
            dataFound = true;
          }
          break;
      }

      if (!mounted) return;
      Navigator.of(context).pop(); // إغلاق نافذة التحميل
      if (dataFound) {
        _showSuccessSnackBar(context, 'تم تحضير التقرير حسب التاريخ بنجاح');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // إغلاق نافذة التحميل
      _showErrorSnackBar(context, 'خطأ في طباعة التقرير: $e');
    }
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(child: Text(message)),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
