import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/installment_provider.dart';
import '../providers/person_provider.dart';
import '../models/installment_model.dart';
import '../widgets/installment_form.dart';
import '../utils/date_formatter.dart';
import '../utils/number_formatter.dart';

class InstallmentsScreen extends StatefulWidget {
  const InstallmentsScreen({super.key});

  @override
  State<InstallmentsScreen> createState() => _InstallmentsScreenState();
}

class _InstallmentsScreenState extends State<InstallmentsScreen> {
  bool _showOnlyActive = false;
  int? _selectedPersonId;

  void _showInstallmentForm({Installment? installment}) {
    showDialog(
      context: context,
      builder: (context) => InstallmentForm(installment: installment),
    );
  }

  void _showPaymentDialog(Installment installment) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة دفعة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('المبلغ المتبقي: ${NumberFormatter.format(installment.remainingAmount)} د.ع'),
            const SizedBox(height: 16),
            TextFormField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'مبلغ الدفعة',
                hintText: 'أدخل مبلغ الدفعة',
                suffixText: 'د.ع',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'ملاحظات',
                hintText: 'أدخل ملاحظات للدفعة',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                if (amount > installment.remainingAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'المبلغ المدفوع لا يمكن أن يكون أكبر من المبلغ المتبقي')),
                  );
                  return;
                }
                final provider = Provider.of<InstallmentProvider>(context, listen: false);
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                try {
                  final payment = InstallmentPayment(
                    installmentId: installment.id!,
                    amount: amount,
                    notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                    paymentDate: DateTime.now(),
                    createdAt: DateTime.now(),
                  );
                  
                  await provider.addPayment(installment.id!, payment);
                  
                  if (mounted) {
                    navigator.pop();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('تم إضافة الدفعة بنجاح')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('خطأ: ${e.toString()}')),
                    );
                  }
                }
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _showPaymentHistory(Installment installment) {
    final installmentProvider =
        Provider.of<InstallmentProvider>(context, listen: false);
    final payments = installmentProvider.getInstallmentPayments(installment.id!);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('سجل الدفعات'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('المنتج: ${installment.productName}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المبلغ الإجمالي:'),
                        Text(
                            '${NumberFormatter.format(installment.totalAmount)} د.ع',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المبلغ المدفوع:'),
                        Text(
                            '${NumberFormatter.format(installment.paidAmount)} د.ع',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المبلغ المتبقي:'),
                        Text(
                            '${NumberFormatter.format(installment.remainingAmount)} د.ع',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.red)),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: payments.isEmpty
                    ? const Center(child: Text('لا توجد دفعات'))
                    : ListView.builder(
                        itemCount: payments.length,
                        itemBuilder: (context, index) {
                          final payment = payments[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 4.0, horizontal: 2.0),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.monetization_on,
                                      color: Colors.green, size: 30),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${NumberFormatter.format(payment.amount)} د.ع',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'التاريخ: ${DateFormatter.formatDisplayDateTime(payment.paymentDate)}',
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12),
                                        ),
                                        if (payment.notes != null &&
                                            payment.notes!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'الملاحظات: ${payment.notes}',
                                            style: TextStyle(
                                                color: Colors.grey[700],
                                                fontSize: 12),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () {
                                      // Close the history dialog first
                                      Navigator.of(context).pop();
                                      _confirmDeletePayment(
                                          installment, payment);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePayment(Installment installment, InstallmentPayment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذه الدفعة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = Provider.of<InstallmentProvider>(context, listen: false);
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              navigator.pop(); // Close the confirmation dialog
              try {
                await provider.deletePayment(installment.id!, payment.id!);
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('تم حذف الدفعة بنجاح')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('خطأ: ${e.toString()}')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteInstallment(Installment installment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا القسط؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = Provider.of<InstallmentProvider>(context, listen: false);
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              navigator.pop();
              try {
                await provider.deleteInstallment(installment.id!);
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('تم حذف القسط بنجاح')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('خطأ: ${e.toString()}')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildFiltersBar(),
          _buildSummaryCards(),
          const SizedBox(height: 16),
          Expanded(
            child: _buildInstallmentsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showInstallmentForm(),
        tooltip: 'إضافة قسط جديد',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFiltersBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Consumer<PersonProvider>(
              builder: (context, personProvider, child) {
                return DropdownButtonFormField<int>(
                  value: _selectedPersonId,
                  decoration: const InputDecoration(
                    labelText: 'فلترة حسب الشخص',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('جميع الزبائن'),
                    ),
                    ...personProvider.persons.map((person) => DropdownMenuItem<int>(
                      value: person.id,
                      child: Text(person.name),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedPersonId = value;
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          FilterChip(
            label: const Text('الأقساط النشطة فقط'),
            selected: _showOnlyActive,
            onSelected: (selected) {
              setState(() {
                _showOnlyActive = selected;
              });
            },
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () => _showInstallmentForm(),
            icon: const Icon(Icons.add),
            label: const Text('إضافة قسط'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Consumer<InstallmentProvider>(
      builder: (context, installmentProvider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'إجمالي الأقساط',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${NumberFormatter.format(installmentProvider.getTotalInstallmentAmount())} د.ع',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'المبلغ المدفوع',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${NumberFormatter.format(installmentProvider.getTotalPaidAmount())} د.ع',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'المبلغ المتبقي',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${NumberFormatter.format(installmentProvider.getTotalRemainingAmount())} د.ع',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstallmentsList() {
    return Consumer2<InstallmentProvider, PersonProvider>(
      builder: (context, installmentProvider, personProvider, child) {
        if (installmentProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        var installments = installmentProvider.installments;

        // تطبيق الفلاتر
        if (_showOnlyActive) {
          installments = installments.where((installment) => !installment.isCompleted).toList();
        }

        if (_selectedPersonId != null) {
          installments = installments.where((installment) => installment.personId == _selectedPersonId).toList();
        }

        if (installments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.payment_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد أقساط',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _showInstallmentForm(),
                  child: const Text('إضافة قسط جديد'),
                ),
              ],
            ),
          );
        }

        return Card(
          margin: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('الشخص')),
                DataColumn(label: Text('المنتج')),
                DataColumn(label: Text('المبلغ الإجمالي')),
                DataColumn(label: Text('المبلغ المدفوع')),
                DataColumn(label: Text('المبلغ المتبقي')),
                DataColumn(label: Text('التاريخ')),
                DataColumn(label: Text('الحالة')),
                DataColumn(label: Text('الإجراءات')),
              ],
              rows: installments.map((installment) {
                final person = personProvider.getPersonById(installment.personId);
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        person?.name ?? 'غير محدد',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(Text(installment.productName)),
                    DataCell(Text('${NumberFormatter.format(installment.totalAmount)} د.ع')),
                    DataCell(Text('${NumberFormatter.format(installment.paidAmount)} د.ع')),
                    DataCell(
                      Text(
                        '${NumberFormatter.format(installment.remainingAmount)} د.ع',
                        style: TextStyle(
                          color: installment.isCompleted ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataCell(Text(DateFormatter.formatDisplayDate(installment.createdAt))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: installment.isCompleted ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          installment.isCompleted ? 'مكتمل' : 'نشط',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!installment.isCompleted) ...[
                            IconButton(
                              icon: const Icon(Icons.payment, color: Colors.green),
                              onPressed: () => _showPaymentDialog(installment),
                              tooltip: 'إضافة دفعة',
                            ),
                          ],
                          IconButton(
                            icon: const Icon(Icons.history, color: Colors.blue),
                            onPressed: () => _showPaymentHistory(installment),
                            tooltip: 'سجل الدفعات',
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showInstallmentForm(installment: installment),
                            tooltip: 'تعديل',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDeleteInstallment(installment),
                            tooltip: 'حذف',
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
