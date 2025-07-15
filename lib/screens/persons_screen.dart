import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/person_provider.dart';
import '../models/person_model.dart';
import '../widgets/person_form.dart';
import '../utils/date_formatter.dart';

class PersonsScreen extends StatefulWidget {
  const PersonsScreen({super.key});

  @override
  State<PersonsScreen> createState() => _PersonsScreenState();
}

class _PersonsScreenState extends State<PersonsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Person> _filteredPersons = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _isSearching = false;
        _filteredPersons = [];
      });
    } else {
      _searchPersons(_searchController.text);
    }
  }

  Future<void> _searchPersons(String query) async {
    setState(() {
      _isSearching = true;
    });

    final personProvider = Provider.of<PersonProvider>(context, listen: false);
    final results = await personProvider.searchPersons(query);

    setState(() {
      _filteredPersons = results;
      _isSearching = false;
    });
  }

  void _showPersonForm({Person? person}) {
    showDialog(
      context: context,
      builder: (context) => PersonForm(person: person),
    );
  }

  void _confirmDeletePerson(Person person) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف "${person.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Provider.of<PersonProvider>(context, listen: false)
                    .deletePerson(person.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف الشخص بنجاح')),
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
          _buildSearchBar(),
          const SizedBox(height: 16),
          Expanded(
            child: _buildPersonsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPersonForm(),
        tooltip: 'إضافة شخص جديد',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'البحث عن شخص...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () => _showPersonForm(),
            icon: const Icon(Icons.add),
            label: const Text('إضافة شخص'),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonsList() {
    return Consumer<PersonProvider>(
      builder: (context, personProvider, child) {
        if (personProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final persons = _isSearching || _searchController.text.isNotEmpty
            ? _filteredPersons
            : personProvider.persons;

        if (persons.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _searchController.text.isNotEmpty
                      ? 'لا توجد نتائج للبحث'
                      : 'لا توجد أشخاص مسجلين',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                if (_searchController.text.isEmpty)
                  ElevatedButton(
                    onPressed: () => _showPersonForm(),
                    child: const Text('إضافة شخص جديد'),
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
                DataColumn(label: Text('الاسم')),
                DataColumn(label: Text('الهاتف')),
                DataColumn(label: Text('العنوان')),
                DataColumn(label: Text('تاريخ الإضافة')),
                DataColumn(label: Text('الإجراءات')),
              ],
              rows: persons.map((person) => DataRow(
                cells: [
                  DataCell(
                    Text(
                      person.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataCell(Text(person.phone ?? '-')),
                  DataCell(Text(person.address ?? '-')),
                  DataCell(Text(DateFormatter.formatDisplayDate(person.createdAt))),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showPersonForm(person: person),
                          tooltip: 'تعديل',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeletePerson(person),
                          tooltip: 'حذف',
                        ),
                      ],
                    ),
                  ),
                ],
              )).toList(),
            ),
          ),
        );
      },
    );
  }
}
