import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/debt_provider.dart';
import '../providers/person_provider.dart';
import '../models/debt_model.dart';
import '../widgets/debt_form.dart';
import '../utils/date_formatter.dart';
import '../utils/number_formatter.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  bool _showOnlyUnpaid = false;
  int? _selectedPersonId;

  void _showDebtForm({Debt? debt}) {
    showDialog(
      context: context,
      builder: (context) => DebtForm(debt: debt),
    );
  }

  void _showPaymentDialog(Debt debt) {
    final TextEditingController amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('دفع دين'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('المبلغ المتبقي: ${NumberFormatter.format(debt.remainingAmount)} د.ع'),
            const SizedBox(height: 16),
            TextFormField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'المبلغ المدفوع',
                hintText: 'أدخل المبلغ المدفوع',
                suffixText: 'د.ع',
              ),
              keyboardType: TextInputType.number,
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
                final debtProvider = Provider.of<DebtProvider>(context, listen: false);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                try {
                  await debtProvider.payDebt(debt.id!, amount);
                  if (mounted) {
                    Navigator.pop(context);
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('تم دفع المبلغ بنجاح')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('خطأ: ${e.toString()}')),
                    );
                  }
                }
              }
            },
            child: const Text('دفع'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDebt(Debt debt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا الدين؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final debtProvider = Provider.of<DebtProvider>(context, listen: false);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              try {
                await debtProvider.deleteDebt(debt.id!);
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('تم حذف الدين بنجاح')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
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
            child: _buildDebtsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDebtForm(),
        tooltip: 'إضافة دين جديد',
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
            label: const Text('الديون المستحقة فقط'),
            selected: _showOnlyUnpaid,
            onSelected: (selected) {
              setState(() {
                _showOnlyUnpaid = selected;
              });
            },
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () => _showDebtForm(),
            icon: const Icon(Icons.add),
            label: const Text('إضافة دين'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Consumer<DebtProvider>(
      builder: (context, debtProvider, child) {
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
                          'إجمالي الديون',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${NumberFormatter.format(debtProvider.getTotalDebtAmount())} د.ع',
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
                          '${NumberFormatter.format(debtProvider.getTotalPaidAmount())} د.ع',
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
                          '${NumberFormatter.format(debtProvider.getTotalRemainingAmount())} د.ع',
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

  Widget _buildDebtsList() {
    return Consumer2<DebtProvider, PersonProvider>(
      builder: (context, debtProvider, personProvider, child) {
        if (debtProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        var debts = debtProvider.debts;

        // تطبيق الفلاتر
        if (_showOnlyUnpaid) {
          debts = debts.where((debt) => !debt.isPaid).toList();
        }

        if (_selectedPersonId != null) {
          debts = debts.where((debt) => debt.personId == _selectedPersonId).toList();
        }

        if (debts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد ديون',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _showDebtForm(),
                  child: const Text('إضافة دين جديد'),
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
                DataColumn(label: Text('المبلغ الأصلي')),
                DataColumn(label: Text('المبلغ المدفوع')),
                DataColumn(label: Text('المبلغ المتبقي')),
                DataColumn(label: Text('التاريخ')),
                DataColumn(label: Text('الحالة')),
                DataColumn(label: Text('الإجراءات')),
              ],
              rows: debts.map((debt) {
                final person = personProvider.getPersonById(debt.personId);
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        person?.name ?? 'غير محدد',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(Text('${NumberFormatter.format(debt.amount)} د.ع')),
                    DataCell(Text('${NumberFormatter.format(debt.paidAmount)} د.ع')),
                    DataCell(
                      Text(
                        '${NumberFormatter.format(debt.remainingAmount)} د.ع',
                        style: TextStyle(
                          color: debt.isPaid ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataCell(Text(DateFormatter.formatDisplayDate(debt.createdAt))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: debt.isPaid ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          debt.isPaid ? 'مدفوع' : 'مستحق',
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
                          if (!debt.isPaid) ...[
                            IconButton(
                              icon: const Icon(Icons.payment, color: Colors.green),
                              onPressed: () => _showPaymentDialog(debt),
                              tooltip: 'دفع',
                            ),
                          ],
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showDebtForm(debt: debt),
                            tooltip: 'تعديل',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDeleteDebt(debt),
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
