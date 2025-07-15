import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/debt_provider.dart';
import '../providers/person_provider.dart';
import '../models/debt_model.dart';
import '../models/person_model.dart';

class CustomerDebtForm extends StatefulWidget {
  final Debt? debt;
  final int? customerId;

  const CustomerDebtForm({
    super.key,
    this.debt,
    this.customerId,
  });

  @override
  State<CustomerDebtForm> createState() => _CustomerDebtFormState();
}

class _CustomerDebtFormState extends State<CustomerDebtForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _paidAmountController = TextEditingController();
  final _notesController = TextEditingController();

  Person? _selectedPerson;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.debt != null) {
      _titleController.text = widget.debt!.title ?? '';
      _amountController.text = widget.debt!.amount.toString();
      _paidAmountController.text = widget.debt!.paidAmount.toString();
      _notesController.text = widget.debt!.notes ?? '';
      
      // Set selected person
      final personProvider = Provider.of<PersonProvider>(context, listen: false);
      _selectedPerson = personProvider.getPersonById(widget.debt!.personId);
    } else if (widget.customerId != null) {
      // Pre-select customer if provided
      final personProvider = Provider.of<PersonProvider>(context, listen: false);
      _selectedPerson = personProvider.getPersonById(widget.customerId!);
      _paidAmountController.text = '0';
    } else {
      _paidAmountController.text = '0';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _paidAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveDebt() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPerson == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الشخص')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final debtProvider = Provider.of<DebtProvider>(context, listen: false);
      final now = DateTime.now();
      final amount = double.parse(_amountController.text);
      final paidAmount = double.parse(_paidAmountController.text);

      if (widget.debt == null) {
        // إضافة دين جديد
        final debt = Debt(
          title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
          personId: _selectedPerson!.id!,
          amount: amount,
          paidAmount: paidAmount,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          createdAt: now,
          updatedAt: now,
          isPaid: paidAmount >= amount,
        );
        
        await debtProvider.addDebt(debt);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إضافة الدين بنجاح')),
          );
          Navigator.pop(context);
        }
      } else {
        // تعديل دين موجود
        final updatedDebt = widget.debt!.copyWith(
          title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
          personId: _selectedPerson!.id!,
          amount: amount,
          paidAmount: paidAmount,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          updatedAt: now,
          isPaid: paidAmount >= amount,
        );
        
        await debtProvider.updateDebt(updatedDebt);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث الدين بنجاح')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.debt == null ? 'إضافة دين جديد' : 'تعديل الدين'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Person Selection
                Consumer<PersonProvider>(
                  builder: (context, personProvider, child) {
                    return DropdownButtonFormField<Person>(
                      value: _selectedPerson,
                      decoration: const InputDecoration(
                        labelText: 'الشخص *',
                        border: OutlineInputBorder(),
                      ),
                      items: personProvider.persons
                          .map((person) => DropdownMenuItem(
                                value: person,
                                child: Text(person.name),
                              ))
                          .toList(),
                      onChanged: widget.customerId == null
                          ? (Person? person) {
                              setState(() {
                                _selectedPerson = person;
                              });
                            }
                          : null, // Disable if pre-selected
                      validator: (value) {
                        if (value == null) {
                          return 'يرجى اختيار الشخص';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'العنوان (اختياري)',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 100,
                ),
                const SizedBox(height: 16),

                // Amount
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'المبلغ *',
                    border: OutlineInputBorder(),
                    suffixText: 'ريال',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال المبلغ';
                    }
                    if (double.tryParse(value) == null) {
                      return 'يرجى إدخال رقم صحيح';
                    }
                    if (double.parse(value) < 0) {
                      return 'يجب أن يكون المبلغ أكبر من أو يساوي 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Paid Amount
                TextFormField(
                  controller: _paidAmountController,
                  decoration: const InputDecoration(
                    labelText: 'المبلغ المدفوع *',
                    border: OutlineInputBorder(),
                    suffixText: 'ريال',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال المبلغ المدفوع';
                    }
                    if (double.tryParse(value) == null) {
                      return 'يرجى إدخال رقم صحيح';
                    }
                    if (double.parse(value) < 0) {
                      return 'يجب أن يكون المبلغ المدفوع أكبر من أو يساوي 0';
                    }
                    final amount = double.tryParse(_amountController.text);
                    if (amount != null && double.parse(value) > amount) {
                      return 'لا يمكن أن يكون المبلغ المدفوع أكبر من المبلغ الكلي';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات (اختياري)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  maxLength: 500,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveDebt,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.debt == null ? 'إضافة' : 'تحديث'),
        ),
      ],
    );
  }
}
