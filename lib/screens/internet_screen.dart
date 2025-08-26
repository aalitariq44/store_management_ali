import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/internet_provider.dart';
import '../providers/person_provider.dart';
import '../models/internet_model.dart';
import '../widgets/internet_form.dart';
// تمت إزالة أزرار الطباعة من جسم الصفحة ونقلها إلى AppBar
import '../widgets/print_actions.dart';
import '../utils/date_formatter.dart';
import '../utils/number_formatter.dart';
import '../services/pdf_service.dart';

class InternetScreen extends StatefulWidget {
  const InternetScreen({super.key});

  @override
  State<InternetScreen> createState() => _InternetScreenState();
}

class _InternetScreenState extends State<InternetScreen> {
  String _selectedFilter = 'all'; // all, active, expired
  int? _selectedPersonId;

  void _showInternetForm({InternetSubscription? subscription}) {
    showDialog(
      context: context,
      builder: (context) => InternetForm(subscription: subscription),
    );
  }

  // ignore: unused_element
  void _showRenewDialog(InternetSubscription subscription) {
    final newSubscription = subscription.copyWith(
      id: null,
      paidAmount: 0.0,
      startDate: DateTime.now(),
      paymentDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _showInternetForm(subscription: newSubscription);
  }

  void _showPaymentDialog(InternetSubscription subscription) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('دفع اشتراك'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'المبلغ المتبقي: ${NumberFormatter.format(subscription.remainingAmount)} د.ع',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'المبلغ المدفوع',
                  hintText: 'أدخل المبلغ المدفوع',
                  suffixText: 'د.ع',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال المبلغ';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'يرجى إدخال مبلغ صحيح';
                  }
                  if (amount > subscription.remainingAmount) {
                    return 'المبلغ المدفوع أكبر من المبلغ المتبقي';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final amount = double.parse(amountController.text);
                final internetProvider = Provider.of<InternetProvider>(
                  context,
                  listen: false,
                );
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                try {
                  await internetProvider.payForSubscription(
                    subscription.id!,
                    amount,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('تم دفع المبلغ بنجاح')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('خطأ: ${e.toString()}')),
                    );
                  }
                }
              }
            },
            child: const Text('دفع'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSubscription(InternetSubscription subscription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا الاشتراك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final internetProvider = Provider.of<InternetProvider>(
                context,
                listen: false,
              );
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              try {
                await internetProvider.deleteSubscription(subscription.id!);
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('تم حذف الاشتراك بنجاح')),
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

  void _showSubscriptionDetails(
    BuildContext context,
    InternetSubscription subscription,
  ) {
    final personProvider = Provider.of<PersonProvider>(context, listen: false);
    final person = personProvider.getPersonById(subscription.personId);

    String statusText;
    Color statusColor;
    if (subscription.isExpired) {
      statusText = 'منتهي';
      statusColor = Colors.red;
    } else if (subscription.isExpiringSoon) {
      statusText = 'ينتهي قريباً';
      statusColor = Colors.orange;
    } else {
      statusText = 'نشط';
      statusColor = Colors.green;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفاصيل الاشتراك'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              _buildDetailRow('الشخص:', person?.name ?? 'غير محدد'),
              _buildDetailRow('الباقة:', subscription.packageName),
              _buildDetailRow(
                'السعر:',
                '${NumberFormatter.format(subscription.price)} د.ع',
              ),
              _buildDetailRow(
                'المبلغ المدفوع:',
                '${NumberFormatter.format(subscription.paidAmount)} د.ع',
              ),
              _buildDetailRow(
                'المبلغ المتبقي:',
                '${NumberFormatter.format(subscription.remainingAmount)} د.ع',
              ),
              _buildDetailRow(
                'تاريخ البداية:',
                DateFormatter.formatDisplayDate(subscription.startDate),
              ),
              _buildDetailRow(
                'تاريخ الانتهاء:',
                DateFormatter.formatDisplayDate(subscription.endDate),
              ),
              Row(
                children: [
                  const Text(
                    'الحالة:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (subscription.notes != null && subscription.notes!.isNotEmpty)
                _buildDetailRow('ملاحظات:', subscription.notes!),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('إغلاق'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اشتراكات الإنترنت'),
        actions: [
          TextButton.icon(
            onPressed: () => PrintActions.printAll(context, 'internet'),
            icon: const Icon(Icons.print, color: Colors.blueAccent),
            label: const Text(
              'طباعة الكل',
              style: TextStyle(color: Colors.blueAccent),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () =>
                PrintActions.showSelectionDialog(context, 'internet'),
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
          _buildFiltersBar(),
          _buildSummaryCards(),
          Expanded(child: _buildSubscriptionsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showInternetForm(),
        tooltip: 'إضافة اشتراك جديد',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFiltersBar() {
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
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedFilter,
              decoration: const InputDecoration(
                labelText: 'فلترة حسب الحالة',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('جميع الاشتراكات')),
                DropdownMenuItem(
                  value: 'active',
                  child: Text('الاشتراكات النشطة'),
                ),
                DropdownMenuItem(
                  value: 'expired',
                  child: Text('الاشتراكات المنتهية'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () => _showInternetForm(),
            icon: const Icon(Icons.add),
            label: const Text('إضافة اشتراك'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Consumer<InternetProvider>(
      builder: (context, internetProvider, child) {
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
                          'الاشتراكات النشطة',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${internetProvider.getActiveSubscriptions().length}',
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
                          'الاشتراكات المنتهية',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${internetProvider.getExpiredSubscriptions().length}',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: Colors.red),
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
                          'الإيرادات الشهرية',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${NumberFormatter.format(internetProvider.getTotalActiveSubscriptionsRevenue())} د.ع',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: Colors.blue),
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

  Widget _buildSubscriptionsList() {
    return Consumer2<InternetProvider, PersonProvider>(
      builder: (context, internetProvider, personProvider, child) {
        if (internetProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        var subscriptions = internetProvider.subscriptions;

        // تطبيق الفلاتر
        switch (_selectedFilter) {
          case 'active':
            subscriptions = internetProvider.getActiveSubscriptions();
            break;
          case 'expired':
            subscriptions = internetProvider.getExpiredSubscriptions();
            break;
        }

        if (_selectedPersonId != null) {
          subscriptions = subscriptions
              .where(
                (subscription) => subscription.personId == _selectedPersonId,
              )
              .toList();
        }

        if (subscriptions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'لا توجد اشتراكات',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _showInternetForm(),
                  child: const Text('إضافة اشتراك جديد'),
                ),
              ],
            ),
          );
        }

        return Card(
          margin: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('الشخص')),
                DataColumn(label: Text('السعر')),
                DataColumn(label: Text('المبلغ المدفوع')),
                DataColumn(label: Text('المبلغ المتبقي')),
                DataColumn(label: Text('تاريخ البداية')),
                DataColumn(label: Text('الحالة')),
                DataColumn(label: Text('الإجراءات')),
              ],
              rows: subscriptions.map((subscription) {
                final person = personProvider.getPersonById(
                  subscription.personId,
                );

                Color statusColor;
                String statusText;

                if (subscription.isExpired) {
                  statusColor = Colors.red;
                  statusText = 'منتهي';
                } else if (subscription.isExpiringSoon) {
                  statusColor = Colors.orange;
                  statusText = 'ينتهي قريباً';
                } else {
                  statusColor = Colors.green;
                  statusText = 'نشط';
                }
                final bool isFullyPaid = subscription.remainingAmount == 0;

                return DataRow(
                  onSelectChanged: (selected) {
                    if (selected != null && selected) {
                      _showSubscriptionDetails(context, subscription);
                    }
                  },
                  color: MaterialStateProperty.resolveWith<Color?>((
                    Set<MaterialState> states,
                  ) {
                    if (states.contains(MaterialState.selected)) {
                      return Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.2);
                    }
                    if (isFullyPaid) {
                      return Colors.green.shade100;
                    }
                    return null;
                  }),
                  cells: [
                    DataCell(
                      Text(
                        person?.name ?? 'غير محدد',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(
                      Text('${NumberFormatter.format(subscription.price)} د.ع'),
                    ),
                    DataCell(
                      Text(
                        '${NumberFormatter.format(subscription.paidAmount)} د.ع',
                      ),
                    ),
                    DataCell(
                      Text(
                        '${NumberFormatter.format(subscription.remainingAmount)} د.ع',
                      ),
                    ),
                    DataCell(
                      Text(
                        DateFormatter.formatDisplayDate(subscription.startDate),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusText,
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
                          if (!isFullyPaid)
                            IconButton(
                              icon: const Icon(
                                Icons.payment,
                                color: Colors.green,
                              ),
                              onPressed: () => _showPaymentDialog(subscription),
                              tooltip: 'دفع',
                            ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle_outline,
                              color: Colors.green,
                            ),
                            onPressed: () => _showInternetForm(
                              subscription: InternetSubscription(
                                personId: subscription.personId,
                                startDate: DateTime.now(),
                                endDate: DateTime.now().add(
                                  const Duration(days: 30),
                                ),
                                price: subscription.price,
                                paidAmount: 0,
                                packageName: subscription.packageName,
                                notes: '',
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now(),
                                durationInDays: 30,
                                paymentDate: DateTime.now(),
                              ),
                            ),
                            tooltip: 'إضافة اشتراك جديد',
                          ),
                          IconButton(
                            icon: const Icon(Icons.print, color: Colors.purple),
                            onPressed: () => _printSubscriptionReceipt(subscription),
                            tooltip: 'طباعة وصل',
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () =>
                                _showInternetForm(subscription: subscription),
                            tooltip: 'تعديل',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _confirmDeleteSubscription(subscription),
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

  // طباعة وصل اشتراك
  void _printSubscriptionReceipt(InternetSubscription subscription) async {
    try {
      final personProvider = Provider.of<PersonProvider>(context, listen: false);
      final person = personProvider.getPersonById(subscription.personId);
      
      if (person == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطأ: لم يتم العثور على الزبون')),
        );
        return;
      }

      await PDFService.showInternetSubscriptionReceiptPreview(
        context: context,
        subscription: subscription,
        person: person,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في عرض المعاينة: ${e.toString()}')),
      );
    }
  }
}
