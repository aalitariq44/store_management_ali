import 'package:flutter/foundation.dart';
import '../models/income_model.dart';
import '../config/database_helper.dart';

class IncomeProvider with ChangeNotifier {
  List<Income> _incomes = [];
  List<Income> get incomes => _incomes;

  Future<void> loadIncomes() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final incomeRecords = await db.query('incomes');
      _incomes = incomeRecords.map((record) => Income.fromMap(record)).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading incomes: $e');
      _incomes = [];
      notifyListeners();
    }
  }

  Future<void> addIncome(Income income) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final id = await db.insert('incomes', income.toMap());
      final newIncome = Income(
        id: id,
        amount: income.amount,
        description: income.description,
        date: income.date,
      );
      _incomes.add(newIncome);
      notifyListeners();
    } catch (e) {
      print('Error adding income: $e');
    }
  }

  Future<void> updateIncome(Income income) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'incomes',
        income.toMap(),
        where: 'id = ?',
        whereArgs: [income.id],
      );
      final index = _incomes.indexWhere((item) => item.id == income.id);
      if (index != -1) {
        _incomes[index] = income;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating income: $e');
    }
  }

  Future<void> deleteIncome(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete(
        'incomes',
        where: 'id = ?',
        whereArgs: [id],
      );
      _incomes.removeWhere((item) => item.id == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting income: $e');
    }
  }

  // حساب مجموع الواردات الكلي
  double getTotalIncome() {
    return _incomes.fold(0, (sum, income) => sum + income.amount);
  }

  // حساب مجموع واردات اليوم
  double getTodayIncome() {
    final today = DateTime.now();
    return _incomes
        .where((income) =>
            income.date.day == today.day &&
            income.date.month == today.month &&
            income.date.year == today.year)
        .fold(0, (sum, income) => sum + income.amount);
  }

  // حساب مجموع واردات الشهر الحالي
  double getCurrentMonthIncome() {
    final now = DateTime.now();
    return _incomes
        .where((income) =>
            income.date.month == now.month && income.date.year == now.year)
        .fold(0, (sum, income) => sum + income.amount);
  }

  // حساب مجموع واردات السنة الحالية
  double getCurrentYearIncome() {
    final now = DateTime.now();
    return _incomes
        .where((income) => income.date.year == now.year)
        .fold(0, (sum, income) => sum + income.amount);
  }
}
