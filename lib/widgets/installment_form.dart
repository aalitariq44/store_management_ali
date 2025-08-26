import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/installment_provider.dart';
import '../providers/person_provider.dart';
import '../models/installment_model.dart';
import '../models/person_model.dart';

class InstallmentForm extends StatefulWidget {
  final Installment? installment;
  final int? personId;
  final Person? person;

  const InstallmentForm({
    super.key,
    this.installment,
    this.personId,
    this.person,
  });

  @override
  State<InstallmentForm> createState() => _InstallmentFormState();
}

class _InstallmentFormState extends State<InstallmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _notesController = TextEditingController();

  Person? _selectedPerson;
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final personProvider = Provider.of<PersonProvider>(context, listen: false);

    if (widget.installment != null) {
      _productNameController.text = widget.installment!.productName;
      _totalAmountController.text = widget.installment!.totalAmount.toString();
      _notesController.text = widget.installment!.notes ?? '';
      _selectedPerson = personProvider.getPersonById(
        widget.installment!.personId,
      );
      _selectedDate = widget.installment!.createdAt;
    } else if (widget.person != null) {
      _selectedPerson = widget.person;
    } else if (widget.personId != null) {
      _selectedPerson = personProvider.getPersonById(widget.personId!);
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _totalAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveInstallment() async {
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
      final installmentProvider = Provider.of<InstallmentProvider>(
        context,
        listen: false,
      );
      final now = DateTime.now();
      final totalAmount = double.parse(_totalAmountController.text);

      if (widget.installment == null) {
        // إضافة قسط جديد
        final installment = Installment(
          personId: _selectedPerson!.id!,
          productName: _productNameController.text.trim(),
          totalAmount: totalAmount,
          paidAmount: 0.0,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          createdAt: _selectedDate,
          updatedAt: now,
          isCompleted: totalAmount <= 0,
        );

        await installmentProvider.addInstallment(installment);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('تم إضافة القسط بنجاح')));
          Navigator.pop(context);
        }
      } else {
        // تعديل قسط موجود
        final updatedInstallment = widget.installment!.copyWith(
          personId: _selectedPerson!.id!,
          productName: _productNameController.text.trim(),
          totalAmount: totalAmount,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          createdAt: _selectedDate, // Keep original creation date
          updatedAt: now,
          isCompleted: widget.installment!.paidAmount >= totalAmount,
        );

        await installmentProvider.updateInstallment(updatedInstallment);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('تم تحديث القسط بنجاح')));
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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.installment == null ? 'إضافة قسط جديد' : 'تعديل القسط',
      ),
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
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText: 'الزبون',
                          hintText: 'اضغط لاختيار زبون',
                          border: OutlineInputBorder(),
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
                      onChanged: (Person? data) {
                        setState(() {
                          _selectedPerson = data;
                        });
                      },
                      selectedItem: _selectedPerson,
                      validator: (value) {
                        if (value == null) {
                          return 'يرجى اختيار الزبون';
                        }
                        return null;
                      },
                    );
                  },
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _productNameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المنتج *',
                  hintText: 'أدخل اسم المنتج',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال اسم المنتج';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _totalAmountController,
                decoration: const InputDecoration(
                  labelText: 'المبلغ الإجمالي *',
                  hintText: 'أدخل المبلغ الإجمالي',
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'تاريخ الإضافة: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ],
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
          onPressed: _isLoading ? null : _saveInstallment,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.installment == null ? 'إضافة' : 'تحديث'),
        ),
      ],
    );
  }
}
