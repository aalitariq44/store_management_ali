import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/person_provider.dart';
import '../providers/debt_provider.dart';
import '../providers/installment_provider.dart';
import '../providers/internet_provider.dart';
import '../providers/income_provider.dart';
import '../providers/password_provider.dart';
import '../services/backup_service.dart';
import '../utils/number_formatter.dart';
import 'persons_screen.dart';
import 'debts_screen.dart';
import 'installments_screen.dart';
import 'internet_screen.dart';
import 'income_screen.dart';
import 'backup_screen.dart';
import 'password_settings_screen.dart';

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
    const IncomeScreen(),
  ];

  final List<String> _titles = [
    'إدارة الزبائن',
    'إدارة الديون',
    'إدارة الأقساط',
    'اشتراكات الإنترنت',
    'الواردات',
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
    final incomeProvider = Provider.of<IncomeProvider>(context, listen: false);

    await Future.wait([
      personProvider.loadPersons(),
      debtProvider.loadDebts(),
      installmentProvider.loadInstallments(),
      internetProvider.loadSubscriptions(),
      incomeProvider.loadIncomes(),
    ]);
  }

  void _showBackupOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'خيارات النسخ الاحتياطي',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.backup, color: Colors.green),
              title: const Text('إنشاء نسخة احتياطية'),
              subtitle: const Text('حفظ البيانات الحالية في السحابة'),
              onTap: () {
                Navigator.of(context).pop();
                _createQuickBackup();
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder, color: Colors.blue),
              title: const Text('إدارة النسخ الاحتياطية'),
              subtitle: const Text('عرض واستعادة النسخ المحفوظة'),
              onTap: () {
                Navigator.of(context).pop();
                _openBackupScreen();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createQuickBackup() async {
    // عرض مؤشر التحميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('جاري إنشاء النسخة الاحتياطية...'),
          ],
        ),
      ),
    );

    try {
      final success = await BackupService.uploadBackup();
      if (mounted) {
        Navigator.of(context).pop(); // إغلاق مؤشر التحميل
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إنشاء النسخة الاحتياطية بنجاح'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // تنظيف النسخ القديمة
          await BackupService.cleanupOldBackups();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('فشل في إنشاء النسخة الاحتياطية'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // إغلاق مؤشر التحميل
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إنشاء النسخة الاحتياطية: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openBackupScreen() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const BackupScreen(),
      ),
    );

    // إذا تم استعادة نسخة احتياطية، أعد تحميل البيانات
    if (result == true) {
      await _loadAllData();
    }
  }

  void _openPasswordSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PasswordSettingsScreen(),
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              final passwordProvider = Provider.of<PasswordProvider>(context, listen: false);
              passwordProvider.logout();
            },
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.blue[700], // توحيد اللون مع صفحة التفاصيل
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openPasswordSettings,
            tooltip: 'إعدادات كلمة المرور',
          ),
          IconButton(
            icon: const Icon(Icons.backup),
            onPressed: _showBackupOptions,
            tooltip: 'النسخ الاحتياطية',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
            tooltip: 'تحديث البيانات',
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('تسجيل الخروج'),
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
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
                _buildSidebarItem(
                  icon: Icons.trending_up,
                  title: 'الواردات',
                  index: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardSummary() {
    return Consumer<IncomeProvider>(
      builder: (context, incomeProvider, child) {
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
                      '${NumberFormatter.format(debtProvider.getTotalRemainingAmount())} د.ع',
                      Icons.account_balance_wallet,
                      color: Colors.red,
                    ),
                    _buildSummaryItem(
                      'الأقساط المتبقية',
                      '${NumberFormatter.format(installmentProvider.getTotalRemainingAmount())} د.ع',
                      Icons.payment,
                      color: Colors.orange,
                    ),
                    _buildSummaryItem(
                      'اشتراكات فعالة',
                      '${internetProvider.getActiveSubscriptions().length}',
                      Icons.wifi,
                      color: Colors.green,
                    ),
                    _buildSummaryItem(
                      'واردات اليوم',
                      '${NumberFormatter.format(incomeProvider.getTodayIncome())} د.ع',
                      Icons.trending_up,
                      color: Colors.blue,
                    ),
                    _buildSummaryItem(
                      'واردات الشهر',
                      '${NumberFormatter.format(incomeProvider.getCurrentMonthIncome())} د.ع',
                      Icons.calendar_today,
                      color: Colors.purple,
                    ),
                  ],
                ),
              ),
            );
          },
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
