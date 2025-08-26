
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/installment_model.dart';
import '../providers/installment_provider.dart';
import '../utils/date_formatter.dart';
import '../utils/number_formatter.dart';

class AddPaymentDialog extends StatefulWidget {
  final Installment installment;
  final Function(Installment) onPaymentAdded;

  const AddPaymentDialog({
    super.key,
    required this.installment,
    required this.onPaymentAdded,
  });

  @override
  State<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة دفعة'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'المبلغ المتبقي: ${NumberFormatter.format(widget.installment.remainingAmount)} د.ع',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'مبلغ الدفعة',
              hintText: 'أدخل مبلغ الدفعة',
              suffixText: 'د.ع',
            ),
            keyboardType: TextInputType.number,
            autofocus: true,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'ملاحظات',
              hintText: 'أدخل ملاحظات للدفعة',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('تاريخ الدفعة:'),
              const SizedBox(width: 10),
              TextButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(DateFormatter.formatDisplayDate(_selectedDate)),
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null && picked != _selectedDate) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _addPayment,
          child: const Text('إضافة'),
        ),
      ],
    );
  }

  Future<void> _addPayment() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال مبلغ صحيح.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (amount > widget.installment.remainingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('المبلغ المدفوع لا يمكن أن يكون أكبر من المبلغ المتبقي.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final provider = Provider.of<InstallmentProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final payment = InstallmentPayment(
        installmentId: widget.installment.id!,
        amount: amount,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        paymentDate: _selectedDate,
        createdAt: DateTime.now(),
      );

      await provider.addPayment(widget.installment.id!, payment);

      if (mounted) {
        navigator.pop(); // Close the add payment dialog
        messenger.showSnackBar(
          const SnackBar(
            content: Text('تم إضافة الدفعة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        // Callback to refresh the previous screen
        widget.onPaymentAdded(widget.installment);
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
