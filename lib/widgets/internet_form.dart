import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/internet_provider.dart';
import '../providers/person_provider.dart';
import '../models/internet_model.dart';
import '../models/person_model.dart';
import '../utils/date_formatter.dart';

class InternetForm extends StatefulWidget {
  final InternetSubscription? subscription;

  const InternetForm({super.key, this.subscription});

  @override
  State<InternetForm> createState() => _InternetFormState();
}

class _InternetFormState extends State<InternetForm> {
  final _formKey = GlobalKey<FormState>();
  final _packageNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();

  Person? _selectedPerson;
  DateTime _startDate = DateTime.now();
  DateTime _paymentDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.subscription != null) {
      _packageNameController.text = widget.subscription!.packageName;
      _priceController.text = widget.subscription!.price.toString();
      _durationController.text = widget.subscription!.durationInDays.toString();
      _notesController.text = widget.subscription!.notes ?? '';
      _startDate = widget.subscription!.startDate;
      _paymentDate = widget.subscription!.paymentDate;
      
      // Set selected person
      final personProvider = Provider.of<PersonProvider>(context, listen: false);
      _selectedPerson = personProvider.getPersonById(widget.subscription!.personId);
    }
  }

  @override
  void dispose() {
    _packageNameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveSubscription() async {
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
      final internetProvider = Provider.of<InternetProvider>(context, listen: false);
      final now = DateTime.now();
      final price = double.parse(_priceController.text);
      final duration = int.parse(_durationController.text);
      final endDate = _startDate.add(Duration(days: duration));

      if (widget.subscription == null) {
        // إضافة اشتراك جديد
        final subscription = InternetSubscription(
          personId: _selectedPerson!.id!,
          packageName: _packageNameController.text.trim(),
          price: price,
          durationInDays: duration,
          startDate: _startDate,
          endDate: endDate,
          paymentDate: _paymentDate,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          createdAt: now,
          updatedAt: now,
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
          durationInDays: duration,
          startDate: _startDate,
          endDate: endDate,
          paymentDate: _paymentDate,
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

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _paymentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _paymentDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.subscription == null ? 'إضافة اشتراك جديد' : 'تعديل الاشتراك'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
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
                  controller: _packageNameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الباقة *',
                    hintText: 'أدخل اسم الباقة',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال اسم الباقة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'السعر *',
                    hintText: 'أدخل السعر',
                    suffixText: 'د.ع',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال السعر';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'يرجى إدخال سعر صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'المدة بالأيام *',
                    hintText: 'أدخل المدة بالأيام',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال المدة';
                    }
                    final duration = int.tryParse(value);
                    if (duration == null || duration <= 0) {
                      return 'يرجى إدخال مدة صحيحة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => _selectDate(context, true),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('تاريخ البداية'),
                            Text(
                              DateFormatter.formatDisplayDate(_startDate),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextButton(
                        onPressed: () => _selectDate(context, false),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('تاريخ الدفع'),
                            Text(
                              DateFormatter.formatDisplayDate(_paymentDate),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.info, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('تاريخ الانتهاء المتوقع:'),
                              Text(
                                DateFormatter.formatDisplayDate(
                                  _startDate.add(Duration(days: int.tryParse(_durationController.text) ?? 0)),
                                ),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
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
