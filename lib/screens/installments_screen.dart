import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/installment_provider.dart';
import '../providers/person_provider.dart';
import '../providers/password_provider.dart';
import '../models/installment_model.dart';
import '../widgets/installment_form.dart';
// تمت إزالة أزرار الطباعة من جسم الصفحة ونقلها إلى AppBar
import '../widgets/print_actions.dart';
// تمت إزالة ودجت الطباعة كزر منفصل، والآن الطباعة ضمن قائمة الزر الأيمن
import '../services/word_service_simple.dart';
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
            Text(
              'المبلغ المتبقي: ${NumberFormatter.format(installment.remainingAmount)} د.ع',
            ),
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
                        'المبلغ المدفوع لا يمكن أن يكون أكبر من المبلغ المتبقي',
                      ),
                    ),
                  );
                  return;
                }
                final provider = Provider.of<InstallmentProvider>(
                  context,
                  listen: false,
                );
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                try {
                  final payment = InstallmentPayment(
                    installmentId: installment.id!,
                    amount: amount,
                    notes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                    paymentDate: DateTime.now(),
                    createdAt: DateTime.now(),
                  );

                  await provider.addPayment(installment.id!, payment);

                  if (mounted) {
                    navigator.pop(); // Close the add payment dialog
                    messenger.showSnackBar(
                      const SnackBar(content: Text('تم إضافة الدفعة بنجاح')),
                    );
                    // Re-open the payment history dialog
                    _showPaymentHistory(installment);
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
    final installmentProvider = Provider.of<InstallmentProvider>(
      context,
      listen: false,
    );
    final payments = installmentProvider.getInstallmentPayments(
      installment.id!,
    );

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
                    Text(
                      'المنتج: ${installment.productName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المبلغ الإجمالي:'),
                        Text(
                          '${NumberFormatter.format(installment.totalAmount)} د.ع',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
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
                            color: Colors.green,
                          ),
                        ),
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
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
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
                          final paymentNumber = index + 1; // Add payment number
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 4.0,
                              horizontal: 2.0,
                            ),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  // Display payment number
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$paymentNumber',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.monetization_on,
                                    color: Colors.green,
                                    size: 30,
                                  ),
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
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (payment.notes != null &&
                                            payment.notes!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'الملاحظات: ${payment.notes}',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      // Close the history dialog first
                                      Navigator.of(context).pop();
                                      _confirmDeletePayment(
                                        installment,
                                        payment,
                                      );
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
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // Close history dialog
              _showPaymentDialog(installment); // Open add payment dialog
            },
            icon: const Icon(Icons.add_card),
            label: const Text('إضافة دفعة'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPasswordConfirmationDialog({
    required String title,
    required String content,
    required VoidCallback onConfirmed,
  }) async {
    final passwordController = TextEditingController();
    final passwordProvider = Provider.of<PasswordProvider>(
      context,
      listen: false,
    );
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(content),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) async {
                  final password = passwordController.text;
                  if (password.isEmpty) return;

                  final isCorrect = await passwordProvider.verifyPassword(
                    password,
                  );
                  Navigator.of(context).pop(isCorrect);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final password = passwordController.text;
                if (password.isEmpty) return;

                final isCorrect = await passwordProvider.verifyPassword(
                  password,
                );
                Navigator.of(context).pop(isCorrect);
              },
              child: const Text('تأكيد'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      onConfirmed();
    } else if (confirmed == false) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('كلمة المرور غير صحيحة.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmDeletePayment(
    Installment installment,
    InstallmentPayment payment,
  ) {
    _showPasswordConfirmationDialog(
      title: 'تأكيد كلمة المرور',
      content: 'الرجاء إدخال كلمة المرور لحذف هذه الدفعة.',
      onConfirmed: () {
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
                  final provider = Provider.of<InstallmentProvider>(
                    context,
                    listen: false,
                  );
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
      },
    );
  }

  void _confirmDeleteInstallment(Installment installment) {
    _showPasswordConfirmationDialog(
      title: 'تأكيد كلمة المرور',
      content: 'الرجاء إدخال كلمة المرور لحذف هذا القسط.',
      onConfirmed: () {
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
                  final provider = Provider.of<InstallmentProvider>(
                    context,
                    listen: false,
                  );
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأقساط'),
        actions: [
          TextButton.icon(
            onPressed: () => PrintActions.printAll(context, 'installments'),
            icon: const Icon(Icons.print, color: Colors.blueAccent),
            label: const Text(
              'طباعة الكل',
              style: TextStyle(color: Colors.blueAccent),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () =>
                PrintActions.showSelectionDialog(context, 'installments'),
            icon: const Icon(Icons.print_outlined, color: Colors.blueAccent),
            label: const Text(
              'طباعة المحدد',
              style: TextStyle(color: Colors.blueAccent),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltersBar(),
          _buildSummaryCards(),
          Expanded(child: _buildInstallmentsList()),
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
                    ...personProvider.persons.map(
                      (person) => DropdownMenuItem<int>(
                        value: person.id,
                        child: Text(person.name),
                      ),
                    ),
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
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: Colors.green),
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
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: Colors.red),
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
          installments = installments
              .where((installment) => !installment.isCompleted)
              .toList();
        }

        if (_selectedPersonId != null) {
          installments = installments
              .where((installment) => installment.personId == _selectedPersonId)
              .toList();
        }

        if (installments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'لا توجد أقساط',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
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
              ],
              rows: installments.map((installment) {
                final person = personProvider.getPersonById(
                  installment.personId,
                );
                return DataRow(
                  cells: [
                    _contextMenuCell(
                      Text(
                        person?.name ?? 'غير محدد',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      installment,
                      person,
                    ),
                    _contextMenuCell(
                      Text(installment.productName),
                      installment,
                      person,
                    ),
                    _contextMenuCell(
                      Text(
                        '${NumberFormatter.format(installment.totalAmount)} د.ع',
                      ),
                      installment,
                      person,
                    ),
                    _contextMenuCell(
                      Text(
                        '${NumberFormatter.format(installment.paidAmount)} د.ع',
                      ),
                      installment,
                      person,
                    ),
                    _contextMenuCell(
                      Text(
                        '${NumberFormatter.format(installment.remainingAmount)} د.ع',
                        style: TextStyle(
                          color: installment.isCompleted
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      installment,
                      person,
                    ),
                    _contextMenuCell(
                      Text(
                        DateFormatter.formatDisplayDate(installment.createdAt),
                      ),
                      installment,
                      person,
                    ),
                    _contextMenuCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: installment.isCompleted
                              ? Colors.green
                              : Colors.orange,
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
                      installment,
                      person,
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

  DataCell _contextMenuCell(
    Widget child,
    Installment installment,
    dynamic person,
  ) {
    return DataCell(
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showPaymentHistory(installment),
        onSecondaryTapDown: (details) {
          _showInstallmentContextMenu(
            details.globalPosition,
            installment,
            person,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: child,
        ),
      ),
    );
  }

  Future<void> _showInstallmentContextMenu(
    Offset position,
    Installment installment,
    dynamic person,
  ) async {
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        if (!installment.isCompleted)
          const PopupMenuItem<String>(
            value: 'add_payment',
            child: ListTile(
              leading: Icon(Icons.payment, color: Colors.green),
              title: Text('إضافة دفعة'),
            ),
          ),
        const PopupMenuItem<String>(
          value: 'history',
          child: ListTile(
            leading: Icon(Icons.history, color: Colors.blue),
            title: Text('سجل الدفعات'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit, color: Colors.blue),
            title: Text('تعديل'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('حذف'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'print',
          child: ListTile(
            leading: Icon(Icons.print, color: Colors.teal),
            title: Text('طباعة الدفعات'),
          ),
        ),
      ],
    );

    if (selected == null) return;

    switch (selected) {
      case 'add_payment':
        _showPaymentDialog(installment);
        break;
      case 'history':
        _showPaymentHistory(installment);
        break;
      case 'edit':
        _showInstallmentForm(installment: installment);
        break;
      case 'delete':
        _confirmDeleteInstallment(installment);
        break;
      case 'print':
        _printInstallment(installment);
        break;
    }
  }

  Future<void> _printInstallment(Installment installment) async {
    final personProvider = Provider.of<PersonProvider>(context, listen: false);
    final installmentProvider = Provider.of<InstallmentProvider>(
      context,
      listen: false,
    );
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final person = personProvider.getPersonById(installment.personId);
    if (person == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('لم يتم العثور على صاحب القسط')),
      );
      return;
    }

    final payments = installmentProvider.getInstallmentPayments(
      installment.id!,
    );

    try {
      // استخدام خدمة Word بدلاً من PDF
      await WordServiceSimple.createPaymentsDocumentHTML(
        installment: installment,
        person: person,
        payments: payments,
      );
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('تم إنشاء مستند Word وفتحه بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('خطأ في إنشاء مستند Word: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
