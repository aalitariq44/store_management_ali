import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/internet_provider.dart';
import '../providers/person_provider.dart';
import '../models/internet_model.dart';
import '../models/person_model.dart';

class CustomerInternetForm extends StatefulWidget {
  final InternetSubscription? subscription;
  final int? customerId;

  const CustomerInternetForm({
    super.key,
    this.subscription,
    this.customerId,
  });

  @override
  State<CustomerInternetForm> createState() => _CustomerInternetFormState();
}

class _CustomerInternetFormState extends State<CustomerInternetForm> {
  final _formKey = GlobalKey<FormState>();
  final _packageNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _paidAmountController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();

  Person? _selectedPerson;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _paymentDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.subscription != null) {
      _packageNameController.text = widget.subscription!.packageName;
      _priceController.text = widget.subscription!.price.toString();
      _paidAmountController.text = widget.subscription!.paidAmount.toString();
      _durationController.text = widget.subscription!.durationInDays.toString();
      _notesController.text = widget.subscription!.notes ?? '';
      _startDate = widget.subscription!.startDate;
      _endDate = widget.subscription!.endDate;
      _paymentDate = widget.subscription!.paymentDate;
      
      // Set selected person
      final personProvider = Provider.of<PersonProvider>(context, listen: false);
      _selectedPerson = personProvider.getPersonById(widget.subscription!.personId);
    } else if (widget.customerId != null) {
      // Pre-select customer if provided
      final personProvider = Provider.of<PersonProvider>(context, listen: false);
      _selectedPerson = personProvider.getPersonById(widget.customerId!);
      _paidAmountController.text = '0';
      _durationController.text = '30';
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(const Duration(days: 30));
      _paymentDate = DateTime.now();
    } else {
      _paidAmountController.text = '0';
      _durationController.text = '30';
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(const Duration(days: 30));
      _paymentDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _packageNameController.dispose();
    _priceController.dispose();
    _paidAmountController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateEndDate() {
    if (_startDate != null && _durationController.text.isNotEmpty) {
      final duration = int.tryParse(_durationController.text);
      if (duration != null && duration > 0) {
        setState(() {
          _endDate = _startDate!.add(Duration(days: duration));
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context, String type) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        switch (type) {
          case 'start':
            _startDate = picked;
            _updateEndDate();
            break;
          case 'end':
            _endDate = picked;
            break;
          case 'payment':
            _paymentDate = picked;
            break;
        }
      });
    }
  }

  Future<void> _saveSubscription() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPerson == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الشخص')),
      );
      return;
    }

    if (_startDate == null || _endDate == null || _paymentDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تحديد جميع التواريخ')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final internetProvider = Provider.of<InternetProvider>(context, listen: false);
      final now = DateTime.now();
      final price = double.parse(_priceController.text);
      final paidAmount = double.parse(_paidAmountController.text);
      final duration = int.parse(_durationController.text);

      if (widget.subscription == null) {
        // إضافة اشتراك جديد
        final subscription = InternetSubscription(
          personId: _selectedPerson!.id!,
          packageName: _packageNameController.text.trim(),
          price: price,
          paidAmount: paidAmount,
          durationInDays: duration,
          startDate: _startDate!,
          endDate: _endDate!,
          paymentDate: _paymentDate!,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          createdAt: now,
          updatedAt: now,
          isActive: true,
        );
        
        await internetProvider.addSubscription(subscription);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إضافة الاشتراك بنجاح')),
          );
          Navigator.pop(context);
        }
      } else {
        // تعديل اشتراك موجود
        final updatedSubscription = widget.subscription!.copyWith(
          personId: _selectedPerson!.id!,
          packageName: _packageNameController.text.trim(),
          price: price,
          paidAmount: paidAmount,
          durationInDays: duration,
          startDate: _startDate!,
          endDate: _endDate!,
          paymentDate: _paymentDate!,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          updatedAt: now,
        );
        
        await internetProvider.updateSubscription(updatedSubscription);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث الاشتراك بنجاح')),
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
      title: Text(widget.subscription == null ? 'إضافة اشتراك جديد' : 'تعديل الاشتراك'),
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

                // Package Name
                TextFormField(
                  controller: _packageNameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الباقة *',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 100,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال اسم الباقة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Price
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'السعر *',
                    border: OutlineInputBorder(),
                    suffixText: 'ريال',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال السعر';
                    }
                    if (double.tryParse(value) == null) {
                      return 'يرجى إدخال رقم صحيح';
                    }
                    if (double.parse(value) <= 0) {
                      return 'يجب أن يكون السعر أكبر من 0';
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
                    final price = double.tryParse(_priceController.text);
                    if (price != null && double.parse(value) > price) {
                      return 'لا يمكن أن يكون المبلغ المدفوع أكبر من السعر';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Duration
                TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'المدة *',
                    border: OutlineInputBorder(),
                    suffixText: 'يوم',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _updateEndDate(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال المدة';
                    }
                    if (int.tryParse(value) == null) {
                      return 'يرجى إدخال رقم صحيح';
                    }
                    if (int.parse(value) <= 0) {
                      return 'يجب أن تكون المدة أكبر من 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Start Date
                InkWell(
                  onTap: () => _selectDate(context, 'start'),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'تاريخ البداية *',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _startDate != null
                          ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                          : 'اختر التاريخ',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // End Date
                InkWell(
                  onTap: () => _selectDate(context, 'end'),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'تاريخ الانتهاء *',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _endDate != null
                          ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                          : 'اختر التاريخ',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Date
                InkWell(
                  onTap: () => _selectDate(context, 'payment'),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'تاريخ الدفع *',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _paymentDate != null
                          ? '${_paymentDate!.day}/${_paymentDate!.month}/${_paymentDate!.year}'
                          : 'اختر التاريخ',
                    ),
                  ),
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
          onPressed: _isLoading ? null : _saveSubscription,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.subscription == null ? 'إضافة' : 'تحديث'),
        ),
      ],
    );
  }
}
