import 'package:flutter/material.dart';
import '../models/debt_model.dart';
import '../models/person_model.dart';
import '../utils/date_formatter.dart';
import '../utils/number_formatter.dart';

class DebtDetailsDialog extends StatelessWidget {
  final Debt debt;
  final Person? person;

  const DebtDetailsDialog({
    super.key,
    required this.debt,
    required this.person,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تفاصيل الدين'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(context, 'الزبون:', person?.name ?? 'غير محدد'),
            _buildDetailRow(context, 'العنوان:', debt.title ?? 'لا يوجد'),
            _buildDetailRow(
              context,
              'المبلغ:',
              '${NumberFormatter.format(debt.amount)} د.ع',
            ),
            _buildDetailRow(
              context,
              'الحالة:',
              debt.isPaid ? 'مدفوع' : 'مستحق',
            ),
            _buildDetailRow(
              context,
              'تاريخ الإنشاء:',
              DateFormatter.formatDateTime(debt.createdAt),
            ),
            if (debt.paymentDate != null)
              _buildDetailRow(
                context,
                'تاريخ الدفع:',
                DateFormatter.formatDateTime(debt.paymentDate!),
                valueColor: Colors.green,
              ),
            _buildDetailRow(
              context,
              'آخر تحديث:',
              DateFormatter.formatDateTime(debt.updatedAt),
            ),
            const SizedBox(height: 16),
            const Text(
              'الملاحظات:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              debt.notes != null && debt.notes!.isNotEmpty
                  ? debt.notes!
                  : 'لا توجد ملاحظات',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: TextStyle(color: valueColor)),
          ),
        ],
      ),
    );
  }
}
