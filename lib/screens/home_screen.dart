import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/person_provider.dart';
import '../providers/debt_provider.dart';
import '../providers/installment_provider.dart';
import '../providers/internet_provider.dart';
import 'persons_screen.dart';
import 'debts_screen.dart';
import 'installments_screen.dart';
import 'internet_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const PersonsScreen(),
    const DebtsScreen(),
    const InstallmentsScreen(),
    const InternetScreen(),
  ];

  final List<String> _titles = [
    'إدارة الزبائن',
    'إدارة الديون',
    'إدارة الأقساط',
    'اشتراكات الإنترنت',
  ];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final personProvider = Provider.of<PersonProvider>(context, listen: false);
    final debtProvider = Provider.of<DebtProvider>(context, listen: false);
    final installmentProvider = Provider.of<InstallmentProvider>(context, listen: false);
    final internetProvider = Provider.of<InternetProvider>(context, listen: false);

    await Future.wait([
      personProvider.loadPersons(),
      debtProvider.loadDebts(),
      installmentProvider.loadInstallments(),
      internetProvider.loadSubscriptions(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
            tooltip: 'تحديث البيانات',
          ),
        ],
      ),
      body: Row(
        children: [
          _buildSidebar(),
          const VerticalDivider(width: 1),
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: Colors.grey[50],
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildDashboardSummary(),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _buildSidebarItem(
                  icon: Icons.people,
                  title: 'الزبائن',
                  index: 0,
                ),
                _buildSidebarItem(
                  icon: Icons.account_balance_wallet,
                  title: 'الديون',
                  index: 1,
                ),
                _buildSidebarItem(
                  icon: Icons.payment,
                  title: 'الأقساط',
                  index: 2,
                ),
                _buildSidebarItem(
                  icon: Icons.wifi,
                  title: 'اشتراكات الإنترنت',
                  index: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardSummary() {
    return Consumer4<PersonProvider, DebtProvider, InstallmentProvider, InternetProvider>(
      builder: (context, personProvider, debtProvider, installmentProvider, internetProvider, child) {
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ملخص المحل',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                _buildSummaryItem(
                  'الزبائن',
                  '${personProvider.persons.length}',
                  Icons.people,
                ),
                _buildSummaryItem(
                  'الديون المستحقة',
                  '${debtProvider.getTotalRemainingAmount().toStringAsFixed(2)} د.ع',
                  Icons.account_balance_wallet,
                  color: Colors.red,
                ),
                _buildSummaryItem(
                  'الأقساط المتبقية',
                  '${installmentProvider.getTotalRemainingAmount().toStringAsFixed(2)} د.ع',
                  Icons.payment,
                  color: Colors.orange,
                ),
                _buildSummaryItem(
                  'اشتراكات فعالة',
                  '${internetProvider.getActiveSubscriptions().length}',
                  Icons.wifi,
                  color: Colors.green,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color ?? Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[800],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
