import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:provider/provider.dart';
import '../providers/debt_provider.dart';
import '../providers/person_provider.dart';
import '../models/debt_model.dart';
import '../models/person_model.dart';
import '../utils/date_formatter.dart';

class AddDebtStrip extends StatefulWidget {
  final int? initialPersonId;
  final Function(Debt) onDebtAdded;

  const AddDebtStrip({
    super.key,
    this.initialPersonId,
    required this.onDebtAdded,
  });

  @override
  State<AddDebtStrip> createState() => _AddDebtStripState();
}

class _AddDebtStripState extends State<AddDebtStrip> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _dateController = TextEditingController();

  Person? _selectedPerson;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormatter.formatDisplayDate(_selectedDate);
    if (widget.initialPersonId != null) {
      final personProvider = Provider.of<PersonProvider>(context, listen: false);
      _selectedPerson = personProvider.getPersonById(widget.initialPersonId!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormatter.formatDisplayDate(_selectedDate);
      });
    }
  }

  Future<void> _addDebt() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPerson == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الزبون')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final debtProvider = Provider.of<DebtProvider>(context, listen: false);
      final amount = double.parse(_amountController.text);

      final debt = Debt(
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        personId: _selectedPerson!.id!,
        amount: amount,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: _selectedDate,
        updatedAt: DateTime.now(),
        isPaid: amount <= 0,
      );

      await debtProvider.addDebt(debt);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة الدين بنجاح')),
        );
        widget.onDebtAdded(debt); // Notify parent widget
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearForm() {
    _titleController.clear();
    _amountController.clear();
    _notesController.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _dateController.text = DateFormatter.formatDisplayDate(_selectedDate);
      // Keep selected person if initialPersonId was provided, otherwise clear
      if (widget.initialPersonId == null) {
        _selectedPerson = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Consumer<PersonProvider>(
                builder: (context, personProvider, child) {
                  return DropdownSearch<Person>(
                    dropdownDecoratorProps: const DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        labelText: 'الزبون',
                        hintText: 'اختر زبون',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
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
                    onChanged: widget.initialPersonId != null
                        ? null
                        : (Person? data) {
                            setState(() {
                              _selectedPerson = data;
                            });
                          },
                    selectedItem: _selectedPerson,
                    validator: (value) {
                      if (value == null) {
                        return 'مطلوب';
                      }
                      return null;
                    },
                    enabled: widget.initialPersonId == null, // Disable if initialPersonId is provided
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'عنوان الدين',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'مطلوب';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'المبلغ',
                  hintText: '0.00',
                  suffixText: 'د.ع',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'مطلوب';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'مبلغ غير صحيح';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات',
                  hintText: 'ملاحظات إضافية (اختياري)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: 'تاريخ الدين',
                      border: OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              height: 48, // Adjust height to match other fields
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _addDebt,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'إضافة دين',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
