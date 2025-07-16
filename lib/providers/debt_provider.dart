import 'package:flutter/foundation.dart';
import '../models/debt_model.dart';
import '../config/database_helper.dart';

class DebtProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Debt> _debts = [];
  bool _isLoading = false;

  List<Debt> get debts => _debts;
  bool get isLoading => _isLoading;

  Future<void> loadDebts() async {
    if (_isLoading) return;
    _isLoading = true;
    Future.microtask(notifyListeners);

    try {
      _debts = await _dbHelper.getAllDebts();
    } catch (e) {
      debugPrint('Error loading debts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addDebt(Debt debt) async {
    try {
      final id = await _dbHelper.insertDebt(debt);
      final newDebt = debt.copyWith(id: id);
      _debts.insert(0, newDebt);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding debt: $e');
      throw Exception('فشل في إضافة الدين');
    }
  }

  Future<void> updateDebt(Debt debt) async {
    try {
      await _dbHelper.updateDebt(debt);
      final index = _debts.indexWhere((d) => d.id == debt.id);
      if (index != -1) {
        _debts[index] = debt;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating debt: $e');
      throw Exception('فشل في تحديث الدين');
    }
  }

  Future<void> deleteDebt(int id) async {
    try {
      await _dbHelper.deleteDebt(id);
      _debts.removeWhere((debt) => debt.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting debt: $e');
      throw Exception('فشل في حذف الدين');
    }
  }

  Future<void> payDebt(int id, double amount) async {
    try {
      final debt = _debts.firstWhere((d) => d.id == id);
      final newPaidAmount = debt.paidAmount + amount;
      final isPaid = newPaidAmount >= debt.amount;
      
      final updatedDebt = debt.copyWith(
        paidAmount: newPaidAmount,
        isPaid: isPaid,
        updatedAt: DateTime.now(),
      );
      
      await updateDebt(updatedDebt);
    } catch (e) {
      debugPrint('Error paying debt: $e');
      throw Exception('فشل في دفع الدين');
    }
  }

  List<Debt> getDebtsByPersonId(int personId) {
    return _debts.where((debt) => debt.personId == personId).toList();
  }

  List<Debt> getUnpaidDebts() {
    return _debts.where((debt) => !debt.isPaid).toList();
  }

  double getTotalDebtAmount() {
    return _debts.fold(0.0, (sum, debt) => sum + debt.amount);
  }

  double getTotalPaidAmount() {
    return _debts.fold(0.0, (sum, debt) => sum + debt.paidAmount);
  }

  double getTotalRemainingAmount() {
    return _debts.fold(0.0, (sum, debt) => sum + debt.remainingAmount);
  }

  double getPersonTotalDebt(int personId) {
    return _debts
        .where((debt) => debt.personId == personId && !debt.isPaid)
        .fold(0.0, (sum, debt) => sum + debt.remainingAmount);
  }
}
