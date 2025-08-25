import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:provider/provider.dart';
import '../providers/debt_provider.dart';
import '../providers/person_provider.dart';
import '../models/debt_model.dart';
import '../models/person_model.dart';

class DebtForm extends StatefulWidget {
  final Debt? debt;
  final int? personId;
  final Person? person;

  const DebtForm({super.key, this.debt, this.personId, this.person});

  @override
  State<DebtForm> createState() => _DebtFormState();
}

class _DebtFormState extends State<DebtForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  Person? _selectedPerson;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final personProvider = Provider.of<PersonProvider>(context, listen: false);

    if (widget.debt != null) {
      _titleController.text = widget.debt!.title ?? '';
      _amountController.text = widget.debt!.amount.toString();
      _notesController.text = widget.debt!.notes ?? '';
      _selectedPerson = personProvider.getPersonById(widget.debt!.personId);
    } else if (widget.person != null) {
      _selectedPerson = widget.person;
    } else if (widget.personId != null) {
      _selectedPerson = personProvider.getPersonById(widget.personId!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveDebt() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPerson == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى اختيار الشخص')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final debtProvider = Provider.of<DebtProvider>(context, listen: false);
      final now = DateTime.now();
      final amount = double.parse(_amountController.text);

      if (widget.debt == null) {
        // إضافة دين جديد
        final debt = Debt(
          title: _titleController.text.trim().isEmpty
              ? null
              : _titleController.text.trim(),
          personId: _selectedPerson!.id!,
          amount: amount,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          createdAt: now,
          updatedAt: now,
          isPaid: amount <= 0,
        );

        await debtProvider.addDebt(debt);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('تم إضافة الدين بنجاح')));
          Navigator.pop(context);
        }
      } else {
        // تعديل دين موجود
        final updatedDebt = widget.debt!.copyWith(
          title: _titleController.text.trim().isEmpty
              ? null
              : _titleController.text.trim(),
          personId: _selectedPerson!.id!,
          amount: amount,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          updatedAt: now,
        );

        await debtProvider.updateDebt(updatedDebt);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('تم تحديث الدين بنجاح')));
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.debt == null ? 'إضافة دين جديد' : 'تعديل الدين'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.person != null)
                TextFormField(
                  initialValue: widget.person!.name,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'الشخص',
                    border: OutlineInputBorder(),
                  ),
                )
              else
                Consumer<PersonProvider>(
                  builder: (context, personProvider, child) {
                    return DropdownSearch<Person>(
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          controller: TextEditingController(),
                          decoration: const InputDecoration(
                            hintText: "ابحث عن شخص",
                          ),
                        ),
                      ),
                      items: personProvider.persons,
                      itemAsString: (Person u) => u.name,
                      onChanged: (Person? data) {
                        setState(() {
                          _selectedPerson = data;
                        });
                      },
                      selectedItem: _selectedPerson,
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
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'العنوان',
                  hintText: 'أدخل عنوان الدين',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال العنوان';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'المبلغ الأصلي *',
                  hintText: 'أدخل المبلغ الأصلي',
                  suffixText: 'د.ع',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال المبلغ';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'يرجى إدخال مبلغ صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات',
                  hintText: 'أدخل ملاحظات إضافية',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
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
