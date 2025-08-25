import 'package:flutter/foundation.dart';
import '../models/person_model.dart';
import '../config/database_helper.dart';
import 'debt_provider.dart';
import 'installment_provider.dart';
// import 'internet_provider.dart'; // مخفي مؤقتاً

class PersonProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Person> _persons = [];
  bool _isLoading = false;

  // References to other providers for cascading updates
  DebtProvider? _debtProvider;
  InstallmentProvider? _installmentProvider;
  // InternetProvider? _internetProvider; // مخفي مؤقتاً

  List<Person> get persons => _persons;
  bool get isLoading => _isLoading;

  // Set references to other providers for cascading updates
  void setOtherProviders({
    DebtProvider? debtProvider,
    InstallmentProvider? installmentProvider,
    // InternetProvider? internetProvider, // مخفي مؤقتاً
  }) {
    _debtProvider = debtProvider;
    _installmentProvider = installmentProvider;
    // _internetProvider = internetProvider; // مخفي مؤقتاً
  }

  Future<void> loadPersons() async {
    if (_isLoading) return;
    _isLoading = true;
    Future.microtask(notifyListeners);

    try {
      _persons = await _dbHelper.getAllPersons();
    } catch (e) {
      debugPrint('Error loading persons: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPerson(Person person) async {
    try {
      final id = await _dbHelper.insertPerson(person);
      final newPerson = person.copyWith(id: id);
      _persons.add(newPerson);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding person: $e');
      throw Exception('فشل في إضافة الشخص');
    }
  }

  Future<void> updatePerson(Person person) async {
    try {
      await _dbHelper.updatePerson(person);
      final index = _persons.indexWhere((p) => p.id == person.id);
      if (index != -1) {
        _persons[index] = person;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating person: $e');
      throw Exception('فشل في تحديث الشخص');
    }
  }

  Future<void> deletePerson(int id) async {
    try {
      // Delete person from database (this will cascade delete related data)
      await _dbHelper.deletePerson(id);

      // Remove person from local list
      _persons.removeWhere((person) => person.id == id);

      // Update other providers to remove cached data
      _debtProvider?.removeDebtsForPerson(id);
      _installmentProvider?.removeInstallmentsForPerson(id);
      // _internetProvider?.removeSubscriptionsForPerson(id); // مخفي مؤقتاً

      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting person: $e');
      throw Exception('فشل في حذف الشخص وبياناته المرتبطة');
    }
  }

  Future<List<Person>> searchPersons(String query) async {
    if (query.isEmpty) return _persons;

    try {
      return await _dbHelper.searchPersons(query);
    } catch (e) {
      debugPrint('Error searching persons: $e');
      return [];
    }
  }

  Person? getPersonById(int id) {
    try {
      return _persons.firstWhere((person) => person.id == id);
    } catch (e) {
      return null;
    }
  }

  String getPersonName(int id) {
    final person = getPersonById(id);
    return person?.name ?? 'غير محدد';
  }
}
