import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/debt_provider.dart';
import '../providers/person_provider.dart';
import '../models/debt_model.dart';
import '../models/person_model.dart';
import '../widgets/debt_form.dart';
import '../widgets/add_debt_strip.dart'; // New import
// تمت إزالة أزرار الطباعة من جسم الصفحة ونقلها إلى AppBar
import '../widgets/print_actions.dart';
import '../widgets/debt_details_dialog.dart';
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد دفع الدين'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('هل أنت متأكد من دفع هذا الدين كاملاً؟'),
            const SizedBox(height: 16),
            Text(
              'المبلغ: ${NumberFormatter.format(debt.amount)} د.ع',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              final debtProvider = Provider.of<DebtProvider>(
                context,
                listen: false,
              );
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              try {
                await debtProvider.payDebt(debt.id!);
                if (mounted) {
                  Navigator.pop(context);
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('تم دفع الدين بنجاح')),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              'تأكيد الدفع',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showDebtDetailsDialog(Debt debt, Person? person) {
    showDialog(
      context: context,
      builder: (context) => DebtDetailsDialog(debt: debt, person: person),
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
              final debtProvider = Provider.of<DebtProvider>(
                context,
                listen: false,
              );
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
      appBar: AppBar(
        title: const Text('الديون'),
        actions: [
          TextButton.icon(
            onPressed: () => PrintActions.printAll(context, 'debts'),
            icon: const Icon(Icons.print, color: Colors.blueAccent),
            label: const Text(
              'طباعة الكل',
              style: TextStyle(color: Colors.blueAccent),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => PrintActions.showSelectionDialog(context, 'debts'),
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
          _buildFiltersAndActionsBar(), // Renamed and modified
          _buildSummaryCards(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: AddDebtStrip(
              onDebtAdded: (newDebt) {
                // Optionally refresh the list or update state if needed
                // The provider will automatically notify listeners, so a direct setState might not be necessary
                // but we can trigger a rebuild if filters need to be re-applied or similar.
                Provider.of<DebtProvider>(context, listen: false).loadDebts();
              },
            ),
          ),
          Expanded(child: _buildDebtsList()),
        ],
      ),
      // FloatingActionButton is no longer needed as AddDebtStrip handles adding debts
    );
  }

  Widget _buildFiltersAndActionsBar() {
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
            label: const Text('الديون المستحقة فقط'),
            selected: _showOnlyUnpaid,
            onSelected: (selected) {
              setState(() {
                _showOnlyUnpaid = selected;
              });
            },
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
                          'المبلغ المستحق',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${NumberFormatter.format(debtProvider.getTotalRemainingAmount())} د.ع',
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
          debts = debts
              .where((debt) => debt.personId == _selectedPersonId)
              .toList();
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
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                // The button to add new debt is now in the AddDebtStrip
              ],
            ),
          );
        }

        return Card(
          margin: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('ت')),
                DataColumn(label: Text('الشخص')),
                DataColumn(label: Text('العنوان')),
                DataColumn(label: Text('المبلغ')),
                DataColumn(label: Text('تاريخ الإنشاء')),
                DataColumn(label: Text('تاريخ الدفع')),
                DataColumn(label: Text('الحالة')),
                DataColumn(label: Text('الإجراءات')),
              ],
              rows: debts.asMap().entries.map((entry) {
                final index = entry.key;
                final debt = entry.value;
                final person = personProvider.getPersonById(debt.personId);
                return DataRow(
                  onSelectChanged: (selected) {
                    if (selected != null && selected) {
                      _showDebtDetailsDialog(debt, person);
                    }
                  },
                  cells: [
                    DataCell(Text('${index + 1}')),
                    DataCell(
                      Text(
                        person?.name ?? 'غير محدد',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(Text(debt.title ?? 'لا يوجد')),
                    DataCell(
                      Text('${NumberFormatter.format(debt.amount)} د.ع'),
                    ),
                    DataCell(
                      Text(DateFormatter.formatDisplayDate(debt.createdAt)),
                    ),
                    DataCell(
                      Text(
                        debt.paymentDate != null
                            ? DateFormatter.formatDisplayDate(debt.paymentDate!)
                            : 'لم يدفع بعد',
                        style: TextStyle(
                          color: debt.isPaid ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
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
                              icon: const Icon(
                                Icons.payment,
                                color: Colors.green,
                              ),
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
