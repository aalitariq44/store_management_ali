import 'package:flutter/foundation.dart';
import '../models/person_model.dart';
import '../config/database_helper.dart';

class PersonProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Person> _persons = [];
  bool _isLoading = false;

  List<Person> get persons => _persons;
  bool get isLoading => _isLoading;

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
      await _dbHelper.deletePerson(id);
      _persons.removeWhere((person) => person.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting person: $e');
      throw Exception('فشل في حذف الشخص');
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
