import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/internet_provider.dart';
import '../providers/person_provider.dart';
import '../models/internet_model.dart';
import '../widgets/internet_form.dart';
import '../utils/date_formatter.dart';

class InternetScreen extends StatefulWidget {
  const InternetScreen({super.key});

  @override
  State<InternetScreen> createState() => _InternetScreenState();
}

class _InternetScreenState extends State<InternetScreen> {
  String _selectedFilter = 'all'; // all, active, expired, archived
  int? _selectedPersonId;

  void _showInternetForm({InternetSubscription? subscription}) {
    showDialog(
      context: context,
      builder: (context) => InternetForm(subscription: subscription),
    );
  }

  void _showRenewDialog(InternetSubscription subscription) {
    final TextEditingController durationController = TextEditingController(text: subscription.durationInDays.toString());
    final TextEditingController priceController = TextEditingController(text: subscription.price.toString());
    DateTime startDate = DateTime.now();
    DateTime paymentDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('تجديد الاشتراك'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('الباقة: ${subscription.packageName}'),
              const SizedBox(height: 16),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'السعر',
                  hintText: 'أدخل السعر',
                  suffixText: 'د.ع',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: durationController,
                decoration: const InputDecoration(
                  labelText: 'المدة بالأيام',
                  hintText: 'أدخل المدة بالأيام',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (selectedDate != null) {
                          setState(() {
                            startDate = selectedDate;
                          });
                        }
                      },
                      child: Text('تاريخ البداية: ${DateFormatter.formatDisplayDate(startDate)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: paymentDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (selectedDate != null) {
                          setState(() {
                            paymentDate = selectedDate;
                          });
                        }
                      },
                      child: Text('تاريخ الدفع: ${DateFormatter.formatDisplayDate(paymentDate)}'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final duration = int.tryParse(durationController.text);
                final price = double.tryParse(priceController.text);
                if (duration != null && price != null) {
                  try {
                    final endDate = startDate.add(Duration(days: duration));
                    await Provider.of<InternetProvider>(context, listen: false)
                        .renewSubscription(subscription.id!, startDate, endDate, paymentDate);
                    
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم تجديد الاشتراك بنجاح')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('خطأ: ${e.toString()}')),
                      );
                    }
                  }
                }
              },
              child: const Text('تجديد'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmArchiveSubscription(InternetSubscription subscription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الأرشفة'),
        content: const Text('هل أنت متأكد من أرشفة هذا الاشتراك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Provider.of<InternetProvider>(context, listen: false)
                    .archiveSubscription(subscription.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم أرشفة الاشتراك بنجاح')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('أرشفة'),
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
              Navigator.pop(context);
              try {
                await Provider.of<InternetProvider>(context, listen: false)
                    .deleteSubscription(subscription.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف الاشتراك بنجاح')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildFiltersBar(),
          _buildSummaryCards(),
          const SizedBox(height: 16),
          Expanded(
            child: _buildSubscriptionsList(),
          ),
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
                      child: Text('جميع الأشخاص'),
                    ),
                    ...personProvider.persons.map((person) => DropdownMenuItem<int>(
                      value: person.id,
                      child: Text(person.name),
                    )),
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
              DropdownMenuItem(value: 'active', child: Text('الاشتراكات النشطة')),
              DropdownMenuItem(value: 'expired', child: Text('الاشتراكات المنتهية')),
              DropdownMenuItem(value: 'archived', child: Text('الاشتراكات المؤرشفة')),
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
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.green,
                          ),
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
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.red,
                          ),
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
                          '${internetProvider.getTotalActiveSubscriptionsRevenue().toStringAsFixed(2)} د.ع',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.blue,
                          ),
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
          case 'archived':
            subscriptions = internetProvider.getArchivedSubscriptions();
            break;
        }

        if (_selectedPersonId != null) {
          subscriptions = subscriptions.where((subscription) => subscription.personId == _selectedPersonId).toList();
        }

        if (subscriptions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد اشتراكات',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
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
                DataColumn(label: Text('الباقة')),
                DataColumn(label: Text('السعر')),
                DataColumn(label: Text('المدة')),
                DataColumn(label: Text('تاريخ البداية')),
                DataColumn(label: Text('تاريخ الانتهاء')),
                DataColumn(label: Text('الحالة')),
                DataColumn(label: Text('الإجراءات')),
              ],
              rows: subscriptions.map((subscription) {
                final person = personProvider.getPersonById(subscription.personId);
                
                Color statusColor;
                String statusText;
                
                if (subscription.isArchived) {
                  statusColor = Colors.grey;
                  statusText = 'مؤرشف';
                } else if (subscription.isExpired) {
                  statusColor = Colors.red;
                  statusText = 'منتهي';
                } else if (subscription.isExpiringSoon) {
                  statusColor = Colors.orange;
                  statusText = 'ينتهي قريباً';
                } else {
                  statusColor = Colors.green;
                  statusText = 'نشط';
                }

                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        person?.name ?? 'غير محدد',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(Text(subscription.packageName)),
                    DataCell(Text('${subscription.price.toStringAsFixed(2)} د.ع')),
                    DataCell(Text('${subscription.durationInDays} يوم')),
                    DataCell(Text(DateFormatter.formatDisplayDate(subscription.startDate))),
                    DataCell(Text(DateFormatter.formatDisplayDate(subscription.endDate))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                          if (!subscription.isArchived) ...[
                            IconButton(
                              icon: const Icon(Icons.refresh, color: Colors.blue),
                              onPressed: () => _showRenewDialog(subscription),
                              tooltip: 'تجديد',
                            ),
                            IconButton(
                              icon: const Icon(Icons.archive, color: Colors.orange),
                              onPressed: () => _confirmArchiveSubscription(subscription),
                              tooltip: 'أرشفة',
                            ),
                          ],
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showInternetForm(subscription: subscription),
                            tooltip: 'تعديل',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDeleteSubscription(subscription),
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
}
