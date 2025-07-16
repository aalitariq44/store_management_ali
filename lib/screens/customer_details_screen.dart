import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/person_model.dart';
import '../models/debt_model.dart';
import '../models/installment_model.dart';
import '../models/internet_model.dart';
import '../providers/debt_provider.dart';
import '../providers/installment_provider.dart';
import '../providers/internet_provider.dart';
import '../utils/date_formatter.dart';
import '../utils/number_formatter.dart';
import '../widgets/customer_debt_form.dart';
import '../widgets/customer_installment_form.dart';
import '../widgets/customer_internet_form.dart';
import '../widgets/debt_form.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final Person person;

  const CustomerDetailsScreen({
    super.key,
    required this.person,
  });

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      Provider.of<DebtProvider>(context, listen: false).loadDebts(),
      Provider.of<InstallmentProvider>(context, listen: false).loadInstallments(),
      Provider.of<InternetProvider>(context, listen: false).loadSubscriptions(),
    ]);
  }

  void _showDebtForm({Debt? debt}) {
    showDialog(
      context: context,
      builder: (context) => DebtForm(debt: debt),
    );
  }

  void _showInstallmentForm({Installment? installment}) {
    showDialog(
      context: context,
      builder: (context) => CustomerInstallmentForm(
        installment: installment,
        customerId: widget.person.id,
      ),
    );
  }

  void _showInternetForm({InternetSubscription? subscription}) {
    showDialog(
      context: context,
      builder: (context) => CustomerInternetForm(
        subscription: subscription,
        customerId: widget.person.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تفاصيل الزبون - ${widget.person.name}'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Row(
        children: [
          // Left sidebar with customer info and summary
          SizedBox(
            width: 320, // كان 400، تم تصغيره
            child: SingleChildScrollView( // أضف هذا الـ Scroll
              child: Column(
                children: [
                  _buildCustomerInfo(),
                  _buildSummaryCards(),
                  _buildQuickActions(),
                ],
              ),
            ),
          ),
          // Vertical divider
          const VerticalDivider(width: 1),
          // Main content area with tabs
          Expanded(
            child: Column(
              children: [
                _buildDesktopTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDebtsTab(),
                      _buildInstallmentsTab(),
                      _buildInternetTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue[100],
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.person.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'مسجل منذ: ${DateFormatter.formatDisplayDate(widget.person.createdAt)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.phone, 'الهاتف', widget.person.phone ?? 'غير محدد'),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.location_on, 'العنوان', widget.person.address ?? 'غير محدد'),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.note, 'الملاحظات', widget.person.notes ?? 'لا توجد ملاحظات'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: Consumer3<DebtProvider, InstallmentProvider, InternetProvider>(
        builder: (context, debtProvider, installmentProvider, internetProvider, child) {
          final customerDebts = debtProvider.debts
              .where((debt) => debt.personId == widget.person.id)
              .toList();
          final customerInstallments = installmentProvider.installments
              .where((installment) => installment.personId == widget.person.id)
              .toList();
          final customerSubscriptions = internetProvider.subscriptions
              .where((subscription) => subscription.personId == widget.person.id)
              .toList();

          final totalDebts = customerDebts.fold(0.0, (sum, debt) => sum + debt.remainingAmount);
          final totalInstallments = customerInstallments.fold(0.0, (sum, installment) => sum + installment.remainingAmount);
          final totalInternet = customerSubscriptions.fold(0.0, (sum, subscription) => sum + subscription.remainingAmount);
          final totalOutstanding = totalDebts + totalInstallments + totalInternet;

          return Column(
            children: [
              _buildSummaryCard(
                'إجمالي الديون المتبقية',
                totalDebts,
                customerDebts.length,
                Icons.money_off,
                Colors.red,
              ),
              const SizedBox(height: 8),
              _buildSummaryCard(
                'إجمالي الأقساط المتبقية',
                totalInstallments,
                customerInstallments.length,
                Icons.payment,
                Colors.blue,
              ),
              const SizedBox(height: 8),
              _buildSummaryCard(
                'إجمالي الإنترنت المتبقي',
                totalInternet,
                customerSubscriptions.length,
                Icons.wifi,
                Colors.green,
              ),
              const SizedBox(height: 8),
              _buildSummaryCard(
                'إجمالي المبلغ المتبقي',
                totalOutstanding,
                customerDebts.length + customerInstallments.length + customerSubscriptions.length,
                Icons.account_balance_wallet,
                Colors.orange,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, int count, IconData icon, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), // تم تصغير البادينج
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${NumberFormatter.format(amount)} د.ع',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'إجراءات سريعة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildQuickActionButton(
                'إضافة دين',
                Icons.money_off,
                Colors.red,
                () => _showDebtForm(),
              ),
              const SizedBox(height: 8),
              _buildQuickActionButton(
                'إضافة قسط',
                Icons.payment,
                Colors.blue,
                () => _showInstallmentForm(),
              ),
              const SizedBox(height: 8),
              _buildQuickActionButton(
                'إضافة اشتراك إنترنت',
                Icons.wifi,
                Colors.green,
                () => _showInternetForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: color),
        label: Text(title),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: color.withOpacity(0.5)),
          foregroundColor: color,
        ),
      ),
    );
  }

  Widget _buildDesktopTabBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          _buildDesktopTab('الديون', Icons.money_off, 0),
          const SizedBox(width: 16),
          _buildDesktopTab('الأقساط', Icons.payment, 1),
          const SizedBox(width: 16),
          _buildDesktopTab('الإنترنت', Icons.wifi, 2),
          const Spacer(),
          Consumer3<DebtProvider, InstallmentProvider, InternetProvider>(
            builder: (context, debtProvider, installmentProvider, internetProvider, child) {
              final customerDebts = debtProvider.debts
                  .where((debt) => debt.personId == widget.person.id)
                  .toList();
              final customerInstallments = installmentProvider.installments
                  .where((installment) => installment.personId == widget.person.id)
                  .toList();
              final customerSubscriptions = internetProvider.subscriptions
                  .where((subscription) => subscription.personId == widget.person.id)
                  .toList();

              final totalCount = customerDebts.length + customerInstallments.length + customerSubscriptions.length;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'إجمالي العناصر: $totalCount',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue[700],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTab(String title, IconData icon, int index) {
    final isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () => _tabController.animateTo(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[700] : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtsTab() {
    return Consumer<DebtProvider>(
      builder: (context, debtProvider, child) {
        if (debtProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final customerDebts = debtProvider.debts
            .where((debt) => debt.personId == widget.person.id)
            .toList();

        return Column(
          children: [
            _buildDesktopTabHeader('الديون', customerDebts.length, () => _showDebtForm()),
            Expanded(
              child: customerDebts.isEmpty
                  ? _buildEmptyState('لا توجد ديون', Icons.money_off)
                  : _buildDebtsDataTable(customerDebts),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInstallmentsTab() {
    return Consumer<InstallmentProvider>(
      builder: (context, installmentProvider, child) {
        if (installmentProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final customerInstallments = installmentProvider.installments
            .where((installment) => installment.personId == widget.person.id)
            .toList();

        return Column(
          children: [
            _buildDesktopTabHeader('الأقساط', customerInstallments.length, () => _showInstallmentForm()),
            Expanded(
              child: customerInstallments.isEmpty
                  ? _buildEmptyState('لا توجد أقساط', Icons.payment)
                  : _buildInstallmentsDataTable(customerInstallments),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInternetTab() {
    return Consumer<InternetProvider>(
      builder: (context, internetProvider, child) {
        if (internetProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final customerSubscriptions = internetProvider.subscriptions
            .where((subscription) => subscription.personId == widget.person.id)
            .toList();

        return Column(
          children: [
            _buildDesktopTabHeader('اشتراكات الإنترنت', customerSubscriptions.length, () => _showInternetForm()),
            Expanded(
              child: customerSubscriptions.isEmpty
                  ? _buildEmptyState('لا توجد اشتراكات', Icons.wifi)
                  : _buildInternetDataTable(customerSubscriptions),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDesktopTabHeader(String title, int count, VoidCallback onAdd) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$title ($count)',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('إضافة جديد'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtsDataTable(List<Debt> debts) {
    final personName = widget.person.name;
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('الشخص')),
              DataColumn(label: Text('المبلغ الأصلي')),
              DataColumn(label: Text('المبلغ المدفوع')),
              DataColumn(label: Text('المبلغ المتبقي')),
              DataColumn(label: Text('التاريخ')),
              DataColumn(label: Text('الحالة')),
              DataColumn(label: Text('الإجراءات')),
            ],
            rows: debts.map((debt) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      personName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataCell(Text('${NumberFormatter.format(debt.amount)} د.ع')),
                  DataCell(Text('${NumberFormatter.format(debt.paidAmount)} د.ع')),
                  DataCell(
                    Text(
                      '${NumberFormatter.format(debt.remainingAmount)} د.ع',
                      style: TextStyle(
                        color: debt.isPaid ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataCell(Text(DateFormatter.formatDisplayDate(debt.createdAt))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: debt.isPaid ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        debt.isPaid ? 'مدفوع' : 'مستحق',
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
                        if (!debt.isPaid) ...[
                          IconButton(
                            icon: const Icon(Icons.payment, color: Colors.green),
                            onPressed: () => _showPaymentDialog(debt),
                            tooltip: 'دفع',
                          ),
                        ],
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showDebtForm(debt: debt),
                          tooltip: 'تعديل',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeleteDebt(debt),
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
      ),
    );
  }

  void _showPaymentDialog(Debt debt) {
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('دفع دين'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('المبلغ المتبقي: ${NumberFormatter.format(debt.remainingAmount)} د.ع'),
            const SizedBox(height: 16),
            TextFormField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'المبلغ المدفوع',
                hintText: 'أدخل المبلغ المدفوع',
                suffixText: 'د.ع',
              ),
              keyboardType: TextInputType.number,
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
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                try {
                  await Provider.of<DebtProvider>(context, listen: false)
                      .payDebt(debt.id!, amount);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم دفع المبلغ بنجاح')),
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
            child: const Text('دفع'),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentsDataTable(List<Installment> installments) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('المنتج')),
              DataColumn(label: Text('المبلغ الكلي')),
              DataColumn(label: Text('المدفوع')),
              DataColumn(label: Text('المتبقي')),
              DataColumn(label: Text('التاريخ')),
              DataColumn(label: Text('الحالة')),
              DataColumn(label: Text('الإجراءات')),
            ],
            rows: installments.map((installment) {
              return DataRow(
                cells: [
                  DataCell(Text(installment.productName)),
                  DataCell(Text(NumberFormatter.format(installment.totalAmount))),
                  DataCell(Text(NumberFormatter.format(installment.paidAmount))),
                  DataCell(Text(NumberFormatter.format(installment.remainingAmount))),
                  DataCell(Text(DateFormatter.formatDisplayDate(installment.createdAt))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: installment.isCompleted ? Colors.green : Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        installment.isCompleted ? 'مكتمل' : 'جاري',
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
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showInstallmentForm(installment: installment),
                          tooltip: 'تعديل',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeleteInstallment(installment),
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
      ),
    );
  }

  Widget _buildInternetDataTable(List<InternetSubscription> subscriptions) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('الباقة')),
              DataColumn(label: Text('السعر')),
              DataColumn(label: Text('المدفوع')),
              DataColumn(label: Text('المتبقي')),
              DataColumn(label: Text('البداية')),
              DataColumn(label: Text('الانتهاء')),
              DataColumn(label: Text('الحالة')),
              DataColumn(label: Text('الإجراءات')),
            ],
            rows: subscriptions.map((subscription) {
              return DataRow(
                cells: [
                  DataCell(Text(subscription.packageName)),
                  DataCell(Text(NumberFormatter.format(subscription.price))),
                  DataCell(Text(NumberFormatter.format(subscription.paidAmount))),
                  DataCell(Text(NumberFormatter.format(subscription.remainingAmount))),
                  DataCell(Text(DateFormatter.formatDisplayDate(subscription.startDate))),
                  DataCell(Text(DateFormatter.formatDisplayDate(subscription.endDate))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: subscription.isExpired
                            ? Colors.red
                            : subscription.isExpiringSoon
                                ? Colors.orange
                                : Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        subscription.isExpired
                            ? 'منتهي'
                            : subscription.isExpiringSoon
                                ? 'ينتهي قريباً'
                                : 'نشط',
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
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDebt(Debt debt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا الدين؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Provider.of<DebtProvider>(context, listen: false)
                    .deleteDebt(debt.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف الدين بنجاح')),
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

  void _confirmDeleteInstallment(Installment installment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا القسط؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Provider.of<InstallmentProvider>(context, listen: false)
                    .deleteInstallment(installment.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف القسط بنجاح')),
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
}
