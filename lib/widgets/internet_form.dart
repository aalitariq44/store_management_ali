import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/internet_provider.dart';
import '../providers/person_provider.dart';
import '../models/internet_model.dart';
import '../models/person_model.dart';
import '../utils/date_formatter.dart';

class InternetForm extends StatefulWidget {
  final InternetSubscription? subscription;
  final int? customerId;
  final Person? person;

  const InternetForm({
    Key? key,
    this.subscription,
    this.customerId,
    this.person,
  }) : super(key: key);

  @override
  State<InternetForm> createState() => _InternetFormState();
}

class _InternetFormState extends State<InternetForm> {
  final _formKey = GlobalKey<FormState>();
  final _packageNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _paidAmountController = TextEditingController();
  final _notesController = TextEditingController();

  Person? _selectedPerson;
  DateTime _startDate = DateTime.now();
  DateTime _paymentDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final personProvider = Provider.of<PersonProvider>(context, listen: false);

    if (widget.subscription != null) {
      _packageNameController.text = widget.subscription!.packageName;
      _priceController.text = widget.subscription!.price.toString();
      _paidAmountController.text = widget.subscription!.paidAmount.toString();
      _notesController.text = widget.subscription!.notes ?? '';
      _startDate = widget.subscription!.startDate;
      _paymentDate = widget.subscription!.paymentDate;
      _selectedPerson = personProvider.getPersonById(
        widget.subscription!.personId,
      );
    } else if (widget.person != null) {
      _selectedPerson = widget.person;
    } else if (widget.customerId != null) {
      _selectedPerson = personProvider.getPersonById(widget.customerId!);
    }
    // Automatically set payment date one month after start date for new subscriptions
    if (widget.subscription == null) {
      _paymentDate = _startDate.add(const Duration(days: 30));
    }
  }

  @override
  void dispose() {
    _packageNameController.dispose();
    _priceController.dispose();
    _paidAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveSubscription() async {
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
      final internetProvider = Provider.of<InternetProvider>(
        context,
        listen: false,
      );
      final now = DateTime.now();
      final price = double.parse(_priceController.text);
      final paidAmount = double.parse(_paidAmountController.text);
      const duration = 30; // Default duration
      final endDate = _startDate.add(const Duration(days: duration));

      if (widget.subscription?.id == null) {
        // إضافة اشتراك جديد
        final subscription = InternetSubscription(
          personId: _selectedPerson!.id!,
          packageName: _packageNameController.text.trim(),
          price: price,
          paidAmount: paidAmount,
          durationInDays: duration,
          startDate: _startDate,
          endDate: endDate,
          paymentDate: _paymentDate,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
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
          paidAmount: paidAmount,
          durationInDays: duration,
          startDate: _startDate,
          endDate: endDate,
          paymentDate: _paymentDate,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
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
          // Update payment date automatically when start date changes
          _paymentDate = _startDate.add(const Duration(days: 30));
        } else {
          _paymentDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.subscription?.id == null
            ? 'إضافة اشتراك جديد'
            : 'تعديل الاشتراك',
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
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
                  controller: _paidAmountController,
                  decoration: const InputDecoration(
                    labelText: 'المبلغ المدفوع *',
                    hintText: 'أدخل المبلغ المدفوع',
                    suffixText: 'د.ع',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال المبلغ المدفوع';
                    }
                    final paidAmount = double.tryParse(value);
                    if (paidAmount == null || paidAmount < 0) {
                      return 'يرجى إدخال مبلغ صحيح';
                    }
                    final price = double.tryParse(_priceController.text);
                    if (price != null && paidAmount > price) {
                      return 'المبلغ المدفوع لا يمكن أن يكون أكبر من السعر';
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextButton(
                        // Disabled: payment date is auto-calculated and cannot be changed
                        onPressed: null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('تاريخ الدفع'),
                            Text(
                              DateFormatter.formatDisplayDate(_paymentDate),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
              : Text(widget.subscription?.id == null ? 'إضافة' : 'تحديث'),
        ),
      ],
    );
  }
}
