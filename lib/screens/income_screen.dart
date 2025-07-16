import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/income_model.dart';
import '../providers/income_provider.dart';
import '../utils/number_formatter.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  
  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  void _resetForm() {
    _amountController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedDate = DateTime.now();
    });
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  Future<void> _addIncome() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text.replaceAll(',', ''));
      final description = _descriptionController.text.trim();

      final income = Income(
        amount: amount,
        description: description,
        date: _selectedDate,
      );

      await Provider.of<IncomeProvider>(context, listen: false).addIncome(income);
      _resetForm();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت إضافة الوارد بنجاح'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  
  Future<void> _deleteIncome(Income income) async {
    await Provider.of<IncomeProvider>(context, listen: false).deleteIncome(income.id!);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف الوارد بنجاح'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth > 800;
          if (isDesktop) {
            return _buildDesktopLayout();
          } else {
            return _buildMobileLayout();
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummaryCards(),
                const SizedBox(height: 24),
                _buildAddIncomeForm(),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'سجل الواردات',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Expanded(child: _buildIncomeList()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 20),
          _buildAddIncomeForm(),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),
          Text(
            'سجل الواردات',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: _buildIncomeList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCards() {
    return Consumer<IncomeProvider>(
      builder: (context, incomeProvider, _) {
        final summaryData = [
          {
            'title': 'واردات اليوم',
            'value':
                '${NumberFormatter.format(incomeProvider.getTodayIncome())} د.ع',
            'color': Colors.green,
            'icon': Icons.today,
          },
          {
            'title': 'واردات الشهر',
            'value':
                '${NumberFormatter.format(incomeProvider.getCurrentMonthIncome())} د.ع',
            'color': Colors.blue,
            'icon': Icons.calendar_month,
          },
          {
            'title': 'واردات السنة',
            'value':
                '${NumberFormatter.format(incomeProvider.getCurrentYearIncome())} د.ع',
            'color': Colors.purple,
            'icon': Icons.calendar_today,
          },
          {
            'title': 'إجمالي الواردات',
            'value':
                '${NumberFormatter.format(incomeProvider.getTotalIncome())} د.ع',
            'color': Colors.amber,
            'icon': Icons.account_balance,
          },
        ];

        return LayoutBuilder(builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth > 600;
          int crossAxisCount = isDesktop ? 2 : 2;
          double childAspectRatio = isDesktop ? 2.2 : 1.6;

          return Container(
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.1)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'ملخص الواردات',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: summaryData.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final data = summaryData[index];
                    return _buildSummaryCard(
                      data['title'] as String,
                      data['value'] as String,
                      data['color'] as MaterialColor,
                      data['icon'] as IconData,
                    );
                  },
                ),
              ],
            ),
          );
        });
      },
    );
  }
  
  Widget _buildSummaryCard(
      String title, String value, MaterialColor color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color.shade800, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: color.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: color.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAddIncomeForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                'إضافة وارد جديد',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 600) {
                    return _buildDesktopAddIncome();
                  } else {
                    return _buildMobileAddIncome();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopAddIncome() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildAmountField(),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: _buildDescriptionField(),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _buildDateField(),
        ),
        const SizedBox(width: 16),
        _buildAddButton(),
      ],
    );
  }

  Widget _buildMobileAddIncome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildAmountField(),
        const SizedBox(height: 16),
        _buildDescriptionField(),
        const SizedBox(height: 16),
        _buildDateField(),
        const SizedBox(height: 24),
        _buildAddButton(),
      ],
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: const InputDecoration(
        labelText: 'المبلغ',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.attach_money),
        suffixText: 'د.ع',
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'الرجاء إدخال المبلغ';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'الوصف',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.description),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'الرجاء إدخال الوصف';
        }
        return null;
      },
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                DateFormat('yyyy-MM-dd').format(_selectedDate),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton.icon(
      onPressed: _addIncome,
      icon: const Icon(Icons.add),
      label: const Text('إضافة'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 16),
      ),
    );
  }
  
  Widget _buildIncomeList() {
    return Consumer<IncomeProvider>(
      builder: (context, incomeProvider, _) {
        if (incomeProvider.incomes.isEmpty) {
          return const Center(
            child: Text('لا توجد واردات مسجلة حتى الآن'),
          );
        }
        
        // Sort incomes by date (newest first)
        final sortedIncomes = List<Income>.from(incomeProvider.incomes)
          ..sort((a, b) => b.date.compareTo(a.date));

        return Material(
          elevation: 1,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListView.separated(
            itemCount: sortedIncomes.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final income = sortedIncomes[index];
              return _buildIncomeListItem(income);
            },
          ),
        );
      },
    );
  }
  
  Widget _buildIncomeListItem(Income income) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      leading: CircleAvatar(
        backgroundColor: Colors.green.shade50,
        child: const Icon(Icons.arrow_upward, color: Colors.green),
      ),
      title: Text(
        income.description,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          DateFormat('EEEE, d MMMM yyyy', 'ar').format(income.date),
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${NumberFormatter.format(income.amount)} د.ع',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _showDeleteConfirmation(income),
            tooltip: 'حذف الوارد',
            splashRadius: 24,
          ),
        ],
      ),
    );
  }
  
  void _showDeleteConfirmation(Income income) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا الوارد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteIncome(income);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
