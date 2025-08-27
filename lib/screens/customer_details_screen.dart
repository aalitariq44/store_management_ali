import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/person_model.dart';
import '../models/debt_model.dart';
import '../models/installment_model.dart';
import '../models/internet_model.dart';
import '../providers/debt_provider.dart';
import '../providers/installment_provider.dart';
import '../providers/internet_provider.dart';
import '../providers/person_provider.dart';
import '../providers/password_provider.dart';
import '../utils/date_formatter.dart';
import '../utils/number_formatter.dart';
import '../widgets/internet_form.dart';
import '../widgets/debt_form.dart';
import '../widgets/installment_form.dart';
// تمت إزالة أزرار الإجراءات في الجداول واستبدالها بقوائم بالزر الأيمن
// import '../widgets/installment_print_widget.dart';
import '../services/pdf_service.dart';
import '../widgets/print_options_widget.dart';
import '../widgets/debt_details_dialog.dart';
import '../widgets/add_payment_dialog.dart';
import '../widgets/add_debt_strip.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final Person person;

  const CustomerDetailsScreen({super.key, required this.person});

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
      Provider.of<InstallmentProvider>(
        context,
        listen: false,
      ).loadInstallments(),
      Provider.of<InternetProvider>(context, listen: false).loadSubscriptions(),
    ]);
  }

  void _showDebtForm({Debt? debt}) {
    showDialog(
      context: context,
      builder: (context) => DebtForm(
        debt: debt,
        personId: widget.person.id,
        person: widget.person,
      ),
    );
  }

  void _showInstallmentForm({Installment? installment}) {
    showDialog(
      context: context,
      builder: (context) => InstallmentForm(
        installment: installment,
        personId: widget.person.id,
        person: widget.person,
      ),
    );
  }

  void _showInternetForm({InternetSubscription? subscription}) {
    showDialog(
      context: context,
      builder: (context) => InternetForm(
        subscription: subscription,
        customerId: widget.person.id,
        person: widget.person,
      ),
    );
  }

  void _showDebtDetailsDialog(Debt debt) {
    showDialog(
      context: context,
      builder: (context) =>
          DebtDetailsDialog(debt: debt, person: widget.person),
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
            child: SingleChildScrollView(
              // أضف هذا الـ Scroll
              child: Column(
                children: [
                  _buildCustomerInfo(),
                  _buildSummaryCards(),
                  PrintOptionsWidget(person: widget.person),
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
              _buildInfoRow(
                Icons.phone,
                'الهاتف',
                widget.person.phone ?? 'غير محدد',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.location_on,
                'العنوان',
                widget.person.address ?? 'غير محدد',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.note,
                'الملاحظات',
                widget.person.notes ?? 'لا توجد ملاحظات',
              ),
              const SizedBox(height: 12),
              // Add customer ID row
              _buildInfoRow(
                Icons.perm_identity,
                'رقم الزبون',
                widget.person.id.toString(),
              ),
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
        builder:
            (
              context,
              debtProvider,
              installmentProvider,
              internetProvider,
              child,
            ) {
              final customerDebts = debtProvider.debts
                  .where((debt) => debt.personId == widget.person.id)
                  .toList();
              final customerInstallments = installmentProvider.installments
                  .where(
                    (installment) => installment.personId == widget.person.id,
                  )
                  .toList();
              final customerSubscriptions = internetProvider.subscriptions
                  .where(
                    (subscription) => subscription.personId == widget.person.id,
                  )
                  .toList();

              final totalDebts = customerDebts.fold(
                0.0,
                (sum, debt) => sum + debt.remainingAmount,
              );
              final totalInstallments = customerInstallments.fold(
                0.0,
                (sum, installment) => sum + installment.remainingAmount,
              );
              final totalInternet = customerSubscriptions.fold(
                0.0,
                (sum, subscription) => sum + subscription.remainingAmount,
              );
              final totalOutstanding =
                  totalDebts + totalInstallments + totalInternet;

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
                    customerDebts.length +
                        customerInstallments.length +
                        customerSubscriptions.length,
                    Icons.account_balance_wallet,
                    Colors.orange,
                  ),
                ],
              );
            },
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    double amount,
    int count,
    IconData icon,
    Color color,
  ) {
    return Card(
      color: Colors.white, // Changed to white background
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: 2), // Added colored border
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 12,
        ), // تم تصغير البادينج
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _buildQuickActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
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
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
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
            builder:
                (
                  context,
                  debtProvider,
                  installmentProvider,
                  internetProvider,
                  child,
                ) {
                  final customerDebts = debtProvider.debts
                      .where((debt) => debt.personId == widget.person.id)
                      .toList();
                  final customerInstallments = installmentProvider.installments
                      .where(
                        (installment) =>
                            installment.personId == widget.person.id,
                      )
                      .toList();
                  final customerSubscriptions = internetProvider.subscriptions
                      .where(
                        (subscription) =>
                            subscription.personId == widget.person.id,
                      )
                      .toList();

                  final totalCount =
                      customerDebts.length +
                      customerInstallments.length +
                      customerSubscriptions.length;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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
            AddDebtStrip(
              initialPersonId: widget.person.id,
              onDebtAdded: (debt) {
                _loadData(); // Refresh data after a debt is added
              },
            ),
            _buildDesktopTabHeader(
              'الديون',
              customerDebts.length,
              () => _showDebtForm(),
            ),
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
    return Consumer2<InstallmentProvider, PersonProvider>(
      builder: (context, installmentProvider, personProvider, child) {
        if (installmentProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final customerInstallments = installmentProvider.installments
            .where((installment) => installment.personId == widget.person.id)
            .toList();

        return Column(
          children: [
            _buildDesktopTabHeader(
              'الأقساط',
              customerInstallments.length,
              () => _showInstallmentForm(),
            ),
            Expanded(
              child: customerInstallments.isEmpty
                  ? _buildEmptyState('لا توجد أقساط', Icons.payment)
                  : _buildInstallmentsDataTable(
                      customerInstallments,
                      personProvider,
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInternetTab() {
    return Consumer2<InternetProvider, PersonProvider>(
      builder: (context, internetProvider, personProvider, child) {
        if (internetProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final customerSubscriptions = internetProvider.subscriptions
            .where((subscription) => subscription.personId == widget.person.id)
            .toList();

        return Column(
          children: [
            _buildDesktopTabHeader(
              'اشتراكات الإنترنت',
              customerSubscriptions.length,
              () => _showInternetForm(),
            ),
            Expanded(
              child: customerSubscriptions.isEmpty
                  ? _buildEmptyState('لا توجد اشتراكات', Icons.wifi)
                  : _buildInternetDataTable(
                      customerSubscriptions,
                      personProvider,
                    ),
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
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$title ($count)',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

    final rows = debts.map((debt) {
      return DataRow(
        onSelectChanged: (selected) {
          if (selected != null && selected) {
            _showDebtDetailsDialog(debt);
          }
        },
        cells: [
          DataCell(
            Text(
              personName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataCell(Text(debt.title ?? 'لا يوجد عنوان')),
          DataCell(Text('${NumberFormatter.format(debt.amount)} د.ع')),
          DataCell(Text(DateFormatter.formatDisplayDate(debt.createdAt))),
          DataCell(
            Text(
              debt.paymentDate != null
                  ? DateFormatter.formatDisplayDate(debt.paymentDate!)
                  : 'لم يدفع بعد',
              style: TextStyle(color: debt.isPaid ? Colors.green : Colors.grey),
            ),
          ),
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
          // تمت إزالة عمود الإجراءات واستبدال كل الخلايا بدعم القائمة بالزر الأيمن
        ],
      );
    }).toList();

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('الشخص')),
              DataColumn(label: Text('عنوان الدين')),
              DataColumn(label: Text('المبلغ')),
              DataColumn(label: Text('تاريخ الإنشاء')),
              DataColumn(label: Text('تاريخ الدفع')),
              DataColumn(label: Text('الحالة')),
            ],
            rows: rows.map((row) {
              final debtIndex = rows.indexOf(row);
              final debt = debts[debtIndex];
              // غلف كل خلية بإيماءة النقر بالزر الأيمن
              return DataRow(
                cells: row.cells.take(6).map((cell) {
                  return DataCell(
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onSecondaryTapDown: (details) {
                        _showDebtContextMenu(details.globalPosition, debt);
                      },
                      child: cell.child,
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showPaymentDialog(Debt debt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد دفع الدين'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('هل أنت متأكد من دفع هذا الدين كاملاً؟'),
            const SizedBox(height: 16),
            Text(
              'المبلغ: ${NumberFormatter.format(debt.amount)} د.ع',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              try {
                await Provider.of<DebtProvider>(
                  context,
                  listen: false,
                ).payDebt(debt.id!);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم دفع الدين بنجاح')),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              'تأكيد الدفع',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentsDataTable(
    List<Installment> installments,
    PersonProvider personProvider,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('الشخص')),
              DataColumn(label: Text('المنتج')),
              DataColumn(label: Text('المبلغ الإجمالي')),
              DataColumn(label: Text('المبلغ المدفوع')),
              DataColumn(label: Text('المبلغ المتبقي')),
              DataColumn(label: Text('التاريخ')),
              DataColumn(label: Text('الحالة')),
            ],
            rows: installments.map((installment) {
              final person = personProvider.getPersonById(installment.personId);
              return DataRow(
                cells: [
                  DataCell(
                    _wrapContextMenu(
                      installment,
                      person,
                      Text(
                        person?.name ?? 'غير محدد',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  DataCell(
                    _wrapContextMenu(
                      installment,
                      person,
                      Text(installment.productName),
                    ),
                  ),
                  DataCell(
                    _wrapContextMenu(
                      installment,
                      person,
                      Text(
                        '${NumberFormatter.format(installment.totalAmount)} د.ع',
                      ),
                    ),
                  ),
                  DataCell(
                    _wrapContextMenu(
                      installment,
                      person,
                      Text(
                        '${NumberFormatter.format(installment.paidAmount)} د.ع',
                      ),
                    ),
                  ),
                  DataCell(
                    _wrapContextMenu(
                      installment,
                      person,
                      Text(
                        '${NumberFormatter.format(installment.remainingAmount)} د.ع',
                        style: TextStyle(
                          color: installment.isCompleted
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    _wrapContextMenu(
                      installment,
                      person,
                      Text(
                        DateFormatter.formatDisplayDate(installment.createdAt),
                      ),
                    ),
                  ),
                  DataCell(
                    _wrapContextMenu(
                      installment,
                      person,
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: installment.isCompleted
                              ? Colors.green
                              : Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          installment.isCompleted ? 'مكتمل' : 'نشط',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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

  void _showInstallmentPaymentDialog(Installment installment) {
    showDialog(
      context: context,
      builder: (context) => AddPaymentDialog(
        installment: installment,
        onPaymentAdded: (updatedInstallment, payment) {
          if (mounted) {
            Navigator.of(context).pop(); // Close the add payment dialog
            _printInstallmentPaymentReceipt(updatedInstallment, payment);
          }
        },
      ),
    );
  }

  Future<void> _printInstallmentPaymentReceipt(
    Installment installment,
    InstallmentPayment payment,
  ) async {
    final person = widget.person;
    try {
      await PDFService.showInstallmentPaymentReceiptPreview(
        context: context,
        installment: installment,
        payment: payment,
        person: person,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في طباعة الوصل: $e')),
        );
      }
    }
  }

  void _confirmDeletePayment(
    Installment installment,
    InstallmentPayment payment,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذه الدفعة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = Provider.of<InstallmentProvider>(
                context,
                listen: false,
              );
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              navigator.pop(); // Close the confirmation dialog
              try {
                await provider.deletePayment(installment.id!, payment.id!);
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('تم حذف الدفعة بنجاح')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
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

  void _showPaymentHistory(Installment installment) {
    final installmentProvider = Provider.of<InstallmentProvider>(
      context,
      listen: false,
    );
    final latestInstallment = installmentProvider.installments.firstWhere(
      (i) => i.id == installment.id,
      orElse: () => installment,
    );
    final payments = installmentProvider.getInstallmentPayments(
      latestInstallment.id!,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('سجل الدفعات'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المنتج: ${latestInstallment.productName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المبلغ الإجمالي:'),
                        Text(
                          '${NumberFormatter.format(latestInstallment.totalAmount)} د.ع',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المبلغ المدفوع:'),
                        Text(
                          '${NumberFormatter.format(latestInstallment.paidAmount)} د.ع',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المبلغ المتبقي:'),
                        Text(
                          '${NumberFormatter.format(latestInstallment.remainingAmount)} د.ع',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: payments.isEmpty
                    ? const Center(child: Text('لا توجد دفعات'))
                    : ListView.builder(
                        itemCount: payments.length,
                        itemBuilder: (context, index) {
                          final payment = payments[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 4.0,
                              horizontal: 2.0,
                            ),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Text(
                                    '${index + 1}.', // Sequence number
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.monetization_on,
                                    color: Colors.green,
                                    size: 30,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${NumberFormatter.format(payment.amount)} د.ع',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'التاريخ: ${DateFormatter.formatDisplayDateTime(payment.paymentDate)}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (payment.notes != null &&
                                            payment.notes!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'الملاحظات: ${payment.notes}',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.print,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          _printInstallmentPaymentReceipt(
                                            latestInstallment,
                                            payment,
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          // Close the history dialog first
                                          Navigator.of(context).pop();
                                          _confirmDeletePayment(
                                            latestInstallment,
                                            payment,
                                          );
                                        },
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context); // Close history dialog
              _showInstallmentPaymentDialog(
                latestInstallment,
              ); // Open add payment dialog
              await installmentProvider.loadInstallments(); // Refresh data
            },
            icon: const Icon(Icons.add_card),
            label: const Text('إضافة دفعة'),
          ),
        ],
      ),
    );
  }

  Widget _buildInternetDataTable(
    List<InternetSubscription> subscriptions,
    PersonProvider personProvider,
  ) {
    // نفس الأعمدة والشكل الموجود في internet_screen
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('الشخص')),
              DataColumn(label: Text('السعر')),
              DataColumn(label: Text('المبلغ المدفوع')),
              DataColumn(label: Text('المبلغ المتبقي')),
              DataColumn(label: Text('تاريخ البداية')),
              DataColumn(label: Text('الحالة')),
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
                    _showSubscriptionDetails(context, subscription, person);
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
                    _wrapSubscriptionContextMenu(
                      subscription,
                      person,
                      Text(
                        person?.name ?? 'غير محدد',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  DataCell(
                    _wrapSubscriptionContextMenu(
                      subscription,
                      person,
                      Text('${NumberFormatter.format(subscription.price)} د.ع'),
                    ),
                  ),
                  DataCell(
                    _wrapSubscriptionContextMenu(
                      subscription,
                      person,
                      Text(
                        '${NumberFormatter.format(subscription.paidAmount)} د.ع',
                      ),
                    ),
                  ),
                  DataCell(
                    _wrapSubscriptionContextMenu(
                      subscription,
                      person,
                      Text(
                        '${NumberFormatter.format(subscription.remainingAmount)} د.ع',
                      ),
                    ),
                  ),
                  DataCell(
                    _wrapSubscriptionContextMenu(
                      subscription,
                      person,
                      Text(
                        DateFormatter.formatDisplayDate(subscription.startDate),
                      ),
                    ),
                  ),
                  DataCell(
                    _wrapSubscriptionContextMenu(
                      subscription,
                      person,
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
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showSubscriptionDetails(
    BuildContext context,
    InternetSubscription subscription,
    Person? person,
  ) {
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

  // ===== قوائم السياق (الديون) =====
  Future<void> _showDebtContextMenu(Offset position, Debt debt) async {
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        if (!debt.isPaid)
          const PopupMenuItem<String>(
            value: 'pay',
            child: ListTile(
              leading: Icon(Icons.payment, color: Colors.green),
              title: Text('دفع'),
            ),
          ),
        const PopupMenuItem<String>(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit, color: Colors.blue),
            title: Text('تعديل'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('حذف'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'details',
          child: ListTile(
            leading: Icon(Icons.receipt_long, color: Colors.teal),
            title: Text('تفاصيل'),
          ),
        ),
      ],
    );
    if (selected == null) return;
    switch (selected) {
      case 'pay':
        _showPaymentDialog(debt);
        break;
      case 'edit':
        _showDebtForm(debt: debt);
        break;
      case 'delete':
        _confirmDeleteDebt(debt);
        break;
      case 'details':
        _showDebtDetailsDialog(debt);
        break;
    }
  }

  // ===== قوائم السياق (الأقساط) =====
  Widget _wrapContextMenu(
    Installment installment,
    Person? person,
    Widget child,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showPaymentHistory(installment),
      onSecondaryTapDown: (details) {
        _showInstallmentContextMenu(
          details.globalPosition,
          installment,
          person,
        );
      },
      child: child,
    );
  }

  Future<void> _showInstallmentContextMenu(
    Offset position,
    Installment installment,
    Person? person,
  ) async {
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        if (!installment.isCompleted)
          const PopupMenuItem<String>(
            value: 'add_payment',
            child: ListTile(
              leading: Icon(Icons.payment, color: Colors.green),
              title: Text('إضافة دفعة'),
            ),
          ),
        const PopupMenuItem<String>(
          value: 'history',
          child: ListTile(
            leading: Icon(Icons.history, color: Colors.blue),
            title: Text('سجل الدفعات'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit, color: Colors.blue),
            title: Text('تعديل'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('حذف'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'print',
          child: ListTile(
            leading: Icon(Icons.print, color: Colors.teal),
            title: Text('طباعة'),
          ),
        ),
      ],
    );
    if (selected == null) return;
    switch (selected) {
      case 'add_payment':
        _showInstallmentPaymentDialog(installment);
        break;
      case 'history':
        _showPaymentHistory(installment);
        break;
      case 'edit':
        _showInstallmentForm(installment: installment);
        break;
      case 'delete':
        _confirmDeleteInstallment(installment);
        break;
      case 'print':
        _printInstallment(installment);
        break;
    }
  }

  Future<void> _printInstallment(Installment installment) async {
    final installmentProvider = Provider.of<InstallmentProvider>(
      context,
      listen: false,
    );
    final personProvider = Provider.of<PersonProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final person =
        personProvider.getPersonById(installment.personId) ?? widget.person;
    final payments = installmentProvider.getInstallmentPayments(
      installment.id!,
    );
    try {
      await PDFService.printInstallmentDetails(
        installment: installment,
        person: person,
        payments: payments,
      );
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('تم إنشاء تقرير القسط بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('خطأ في طباعة القسط: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ===== قوائم السياق (الاشتراكات) =====
  Widget _wrapSubscriptionContextMenu(
    InternetSubscription subscription,
    Person? person,
    Widget child,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (details) {
        _showSubscriptionContextMenu(
          details.globalPosition,
          subscription,
          person,
        );
      },
      child: child,
    );
  }

  Future<void> _showSubscriptionContextMenu(
    Offset position,
    InternetSubscription subscription,
    Person? person,
  ) async {
    final bool isFullyPaid = subscription.remainingAmount == 0;
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        if (!isFullyPaid)
          const PopupMenuItem<String>(
            value: 'pay',
            child: ListTile(
              leading: Icon(Icons.payment, color: Colors.green),
              title: Text('دفع'),
            ),
          ),
        const PopupMenuItem<String>(
          value: 'add_new',
          child: ListTile(
            leading: Icon(Icons.add_circle_outline, color: Colors.green),
            title: Text('تجديد الاشتراك '),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit, color: Colors.blue),
            title: Text('تعديل'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'print',
          child: ListTile(
            leading: Icon(Icons.print, color: Colors.purple),
            title: Text('طباعة وصل'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('حذف'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'details',
          child: ListTile(
            leading: Icon(Icons.info, color: Colors.teal),
            title: Text('تفاصيل'),
          ),
        ),
      ],
    );
    if (selected == null) return;
    switch (selected) {
      case 'pay':
        _showInternetPaymentDialog(subscription);
        break;
      case 'add_new':
        _showInternetForm(
          subscription: InternetSubscription(
            personId: subscription.personId,
            startDate: DateTime.now(),
            endDate: DateTime.now().add(const Duration(days: 30)),
            price: subscription.price,
            paidAmount: 0,
            packageName: subscription.packageName,
            notes: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            durationInDays: 30,
            paymentDate: DateTime.now().add(const Duration(days: 30)),
          ),
        );
        break;
      case 'edit':
        _showInternetForm(subscription: subscription);
        break;
      case 'print':
        _printInternetSubscriptionReceipt(subscription);
        break;
      case 'delete':
        _confirmDeleteSubscription(subscription);
        break;
      case 'details':
        _showSubscriptionDetails(context, subscription, person);
        break;
    }
  }

  void _showInternetPaymentDialog(InternetSubscription subscription) {
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

  Future<void> _showPasswordConfirmationDialog({
    required String title,
    required String content,
    required VoidCallback onConfirmed,
  }) async {
    final passwordController = TextEditingController();
    final passwordProvider = Provider.of<PasswordProvider>(
      context,
      listen: false,
    );
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(content),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) async {
                  final password = passwordController.text;
                  if (password.isEmpty) return;

                  final isCorrect = await passwordProvider.verifyPassword(
                    password,
                  );
                  Navigator.of(context).pop(isCorrect);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final password = passwordController.text;
                if (password.isEmpty) return;

                final isCorrect = await passwordProvider.verifyPassword(
                  password,
                );
                Navigator.of(context).pop(isCorrect);
              },
              child: const Text('تأكيد'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      onConfirmed();
    } else if (confirmed == false) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('كلمة المرور غير صحيحة.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmDeleteDebt(Debt debt) {
    _showPasswordConfirmationDialog(
      title: 'تأكيد كلمة المرور',
      content: 'الرجاء إدخال كلمة المرور لحذف هذا الدين.',
      onConfirmed: () {
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
                  final provider = Provider.of<DebtProvider>(
                    context,
                    listen: false,
                  );
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(context);
                  try {
                    await provider.deleteDebt(debt.id!);
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('تم حذف الدين بنجاح')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
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
      },
    );
  }

  void _confirmDeleteInstallment(Installment installment) {
    _showPasswordConfirmationDialog(
      title: 'تأكيد كلمة المرور',
      content: 'الرجاء إدخال كلمة المرور لحذف هذا القسط.',
      onConfirmed: () {
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
                  final provider = Provider.of<InstallmentProvider>(
                    context,
                    listen: false,
                  );
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(context);
                  try {
                    await provider.deleteInstallment(installment.id!);
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('تم حذف القسط بنجاح')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
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
      },
    );
  }

  void _confirmDeleteSubscription(InternetSubscription subscription) {
    _showPasswordConfirmationDialog(
      title: 'تأكيد كلمة المرور',
      content: 'الرجاء إدخال كلمة المرور لحذف هذا الاشتراك.',
      onConfirmed: () {
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
                  final provider = Provider.of<InternetProvider>(
                    context,
                    listen: false,
                  );
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(context);
                  try {
                    await provider.deleteSubscription(subscription.id!);
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('تم حذف الاشتراك بنجاح')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
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
      },
    );
  }

  // طباعة وصل اشتراك إنترنت
  void _printInternetSubscriptionReceipt(
    InternetSubscription subscription,
  ) async {
    try {
      await PDFService.showInternetSubscriptionReceiptPreview(
        context: context,
        subscription: subscription,
        person: widget.person,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في عرض المعاينة: ${e.toString()}')),
        );
      }
    }
  }

  // Widget to show empty state with icon and message
  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
