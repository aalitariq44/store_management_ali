import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/installment_provider.dart';
import '../providers/person_provider.dart';
import '../models/installment_model.dart';
import '../models/person_model.dart';

class CustomerInstallmentForm extends StatefulWidget {
  final Installment? installment;
  final int? customerId;

  const CustomerInstallmentForm({
    super.key,
    this.installment,
    this.customerId,
  });

  @override
  State<CustomerInstallmentForm> createState() => _CustomerInstallmentFormState();
}

class _CustomerInstallmentFormState extends State<CustomerInstallmentForm> {
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
      final paidAmount = double.parse(_paidAmountController.text);

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
          isCompleted: paidAmount >= totalAmount,
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
          isCompleted: paidAmount >= totalAmount,
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
      title: Text(widget.installment == null ? 'إضافة قسط جديد' : 'تعديل القسط'),
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

                // Product Name
                TextFormField(
                  controller: _productNameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المنتج *',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 100,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال اسم المنتج';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Total Amount
                TextFormField(
                  controller: _totalAmountController,
                  decoration: const InputDecoration(
                    labelText: 'المبلغ الكلي *',
                    border: OutlineInputBorder(),
                    suffixText: 'ريال',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال المبلغ الكلي';
                    }
                    if (double.tryParse(value) == null) {
                      return 'يرجى إدخال رقم صحيح';
                    }
                    if (double.parse(value) <= 0) {
                      return 'يجب أن يكون المبلغ أكبر من 0';
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
                    final totalAmount = double.tryParse(_totalAmountController.text);
                    if (totalAmount != null && double.parse(value) > totalAmount) {
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
