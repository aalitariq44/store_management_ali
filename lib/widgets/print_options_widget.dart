import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/person_model.dart';
import '../models/debt_model.dart';
import '../models/installment_model.dart';
import '../models/internet_model.dart';
import '../providers/debt_provider.dart';
import '../providers/installment_provider.dart';
import '../providers/internet_provider.dart';
import '../services/pdf_service.dart';

class PrintOptionsWidget extends StatelessWidget {
  final Person person;

  const PrintOptionsWidget({
    super.key,
    required this.person,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.print, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'خيارات الطباعة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPrintButton(
                  context,
                  'طباعة كامل التفاصيل',
                  Icons.description,
                  Colors.blue,
                  () => _printFullDetails(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPrintButton(
                  context,
                  'طباعة الديون فقط',
                  Icons.account_balance_wallet,
                  Colors.red,
                  () => _printDebtsOnly(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPrintButton(
                  context,
                  'طباعة الأقساط فقط',
                  Icons.payment,
                  Colors.orange,
                  () => _printInstallmentsOnly(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPrintButton(
                  context,
                  'طباعة الإنترنت فقط',
                  Icons.wifi,
                  Colors.green,
                  () => _printInternetOnly(context),
                ),
              ),
            ],
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
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
        textAlign: TextAlign.center,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _printFullDetails(BuildContext context) async {
    try {
      _showLoadingDialog(context, 'جاري تحضير تفاصيل الزبون...');
      
      final debtProvider = Provider.of<DebtProvider>(context, listen: false);
      final installmentProvider = Provider.of<InstallmentProvider>(context, listen: false);
      final internetProvider = Provider.of<InternetProvider>(context, listen: false);

      final debts = debtProvider.getDebtsByPersonId(person.id!);
      final installments = installmentProvider.getInstallmentsByPersonId(person.id!);
      final internetSubscriptions = internetProvider.getSubscriptionsByPersonId(person.id!);

      await PDFService.printCustomerDetails(
        person: person,
        debts: debts,
        installments: installments,
        internetSubscriptions: internetSubscriptions,
      );

      Navigator.of(context).pop(); // إغلاق نافذة التحميل
      _showSuccessSnackBar(context, 'تم تحضير PDF بنجاح');
    } catch (e) {
      Navigator.of(context).pop(); // إغلاق نافذة التحميل
      _showErrorSnackBar(context, 'خطأ في طباعة التفاصيل: $e');
    }
  }

  Future<void> _printDebtsOnly(BuildContext context) async {
    try {
      _showLoadingDialog(context, 'جاري تحضير تقرير الديون...');
      
      final debtProvider = Provider.of<DebtProvider>(context, listen: false);
      final debts = debtProvider.getDebtsByPersonId(person.id!);

      if (debts.isEmpty) {
        Navigator.of(context).pop();
        _showInfoSnackBar(context, 'لا توجد ديون لهذا الزبون');
        return;
      }

      await PDFService.printDebts(debts, customerName: person.name);

      Navigator.of(context).pop(); // إغلاق نافذة التحميل
      _showSuccessSnackBar(context, 'تم تحضير تقرير الديون بنجاح');
    } catch (e) {
      Navigator.of(context).pop(); // إغلاق نافذة التحميل
      _showErrorSnackBar(context, 'خطأ في طباعة الديون: $e');
    }
  }

  Future<void> _printInstallmentsOnly(BuildContext context) async {
    try {
      _showLoadingDialog(context, 'جاري تحضير تقرير الأقساط...');
      
      final installmentProvider = Provider.of<InstallmentProvider>(context, listen: false);
      final installments = installmentProvider.getInstallmentsByPersonId(person.id!);

      if (installments.isEmpty) {
        Navigator.of(context).pop();
        _showInfoSnackBar(context, 'لا توجد أقساط لهذا الزبون');
        return;
      }

      await PDFService.printInstallments(installments, customerName: person.name);

      Navigator.of(context).pop(); // إغلاق نافذة التحميل
      _showSuccessSnackBar(context, 'تم تحضير تقرير الأقساط بنجاح');
    } catch (e) {
      Navigator.of(context).pop(); // إغلاق نافذة التحميل
      _showErrorSnackBar(context, 'خطأ في طباعة الأقساط: $e');
    }
  }

  Future<void> _printInternetOnly(BuildContext context) async {
    try {
      _showLoadingDialog(context, 'جاري تحضير تقرير الإنترنت...');
      
      final internetProvider = Provider.of<InternetProvider>(context, listen: false);
      final internetSubscriptions = internetProvider.getSubscriptionsByPersonId(person.id!);

      if (internetSubscriptions.isEmpty) {
        Navigator.of(context).pop();
        _showInfoSnackBar(context, 'لا توجد اشتراكات إنترنت لهذا الزبون');
        return;
      }

      await PDFService.printInternetSubscriptions(internetSubscriptions, customerName: person.name);

      Navigator.of(context).pop(); // إغلاق نافذة التحميل
      _showSuccessSnackBar(context, 'تم تحضير تقرير الإنترنت بنجاح');
    } catch (e) {
      Navigator.of(context).pop(); // إغلاق نافذة التحميل
      _showErrorSnackBar(context, 'خطأ في طباعة الإنترنت: $e');
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
              Text(message),
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
