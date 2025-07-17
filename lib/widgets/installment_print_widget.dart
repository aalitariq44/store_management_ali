import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/installment_model.dart';
import '../models/person_model.dart';
import '../providers/installment_provider.dart';
import '../providers/person_provider.dart';
import '../services/pdf_service.dart';

class InstallmentPrintWidget extends StatelessWidget {
  final Installment installment;

  const InstallmentPrintWidget({
    super.key,
    required this.installment,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.print, color: Colors.teal),
      onPressed: () => _printInstallmentDetails(context),
      tooltip: 'طباعة تفاصيل القسط',
    );
  }

  Future<void> _printInstallmentDetails(BuildContext context) async {
    final personProvider = Provider.of<PersonProvider>(context, listen: false);
    final installmentProvider = Provider.of<InstallmentProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final Person? person = personProvider.getPersonById(installment.personId);
    if (person == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('لم يتم العثور على صاحب القسط')),
      );
      return;
    }

    final List<InstallmentPayment> payments = installmentProvider.getInstallmentPayments(installment.id!);

    try {
      await PDFService.printInstallmentDetails(
        installment: installment,
        person: person,
        payments: payments,
      );
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('تم إنشاء تقرير القسط بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('خطأ في طباعة القسط: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
