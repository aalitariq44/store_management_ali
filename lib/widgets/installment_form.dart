import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/installment_provider.dart';
import '../providers/person_provider.dart';
import '../models/installment_model.dart';
import '../models/person_model.dart';

class InstallmentForm extends StatefulWidget {
  final Installment? installment;

  const InstallmentForm({super.key, this.installment});

  @override
  State<InstallmentForm> createState() => _InstallmentFormState();
}

class _InstallmentFormState extends State<InstallmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _paidAmountController = TextEditingController();
  final _notesController = TextEditingController();

  Person? _selectedPerson;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.installment != null) {
      _productNameController.text = widget.installment!.productName;
      _totalAmountController.text = widget.installment!.totalAmount.toString();
      _paidAmountController.text = widget.installment!.paidAmount.toString();
      _notesController.text = widget.installment!.notes ?? '';
      
      // Set selected person
      final personProvider = Provider.of<PersonProvider>(context, listen: false);
      _selectedPerson = personProvider.getPersonById(widget.installment!.personId);
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _totalAmountController.dispose();
    _paidAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveInstallment() async {
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
      final installmentProvider = Provider.of<InstallmentProvider>(context, listen: false);
      final now = DateTime.now();
      final totalAmount = double.parse(_totalAmountController.text);
      final paidAmount = double.tryParse(_paidAmountController.text) ?? 0.0;
      final isCompleted = paidAmount >= totalAmount;

      if (widget.installment == null) {
        // إضافة قسط جديد
        final installment = Installment(
          personId: _selectedPerson!.id!,
          productName: _productNameController.text.trim(),
          totalAmount: totalAmount,
          paidAmount: paidAmount,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          createdAt: now,
          updatedAt: now,
          isCompleted: isCompleted,
        );
        
        await installmentProvider.addInstallment(installment);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إضافة القسط بنجاح')),
          );
          Navigator.pop(context);
        }
      } else {
        // تعديل قسط موجود
        final updatedInstallment = widget.installment!.copyWith(
          personId: _selectedPerson!.id!,
          productName: _productNameController.text.trim(),
          totalAmount: totalAmount,
          paidAmount: paidAmount,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          updatedAt: now,
          isCompleted: isCompleted,
        );
        
        await installmentProvider.updateInstallment(updatedInstallment);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث القسط بنجاح')),
          );
          Navigator.pop(context);
        }
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.installment == null ? 'إضافة قسط جديد' : 'تعديل القسط'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer<PersonProvider>(
                builder: (context, personProvider, child) {
                  return DropdownButtonFormField<Person>(
                    value: _selectedPerson,
                    decoration: const InputDecoration(
                      labelText: 'الشخص *',
                      hintText: 'اختر الشخص',
                    ),
                    items: personProvider.persons.map((person) => DropdownMenuItem<Person>(
                      value: person,
                      child: Text(person.name),
                    )).toList(),
                    onChanged: (person) {
                      setState(() {
                        _selectedPerson = person;
                      });
                    },
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
                controller: _paidAmountController,
                decoration: const InputDecoration(
                  labelText: 'المبلغ المدفوع',
                  hintText: 'أدخل المبلغ المدفوع',
                  suffixText: 'د.ع',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final paidAmount = double.tryParse(value);
                    if (paidAmount == null || paidAmount < 0) {
                      return 'يرجى إدخال مبلغ صحيح';
                    }
                    final totalAmount = double.tryParse(_totalAmountController.text) ?? 0;
                    if (paidAmount > totalAmount) {
                      return 'المبلغ المدفوع لا يمكن أن يكون أكبر من المبلغ الإجمالي';
                    }
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
