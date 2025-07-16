import 'package:flutter/foundation.dart';
import '../models/installment_model.dart';
import '../config/database_helper.dart';

class InstallmentProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Installment> _installments = [];
  Map<int, List<InstallmentPayment>> _payments = {};
  bool _isLoading = false;

  List<Installment> get installments => _installments;
  Map<int, List<InstallmentPayment>> get payments => _payments;
  bool get isLoading => _isLoading;

  Future<void> loadInstallments() async {
    if (_isLoading) return;
    _isLoading = true;
    Future.microtask(notifyListeners);

    try {
      _installments = await _dbHelper.getAllInstallments();
      // Load payments for each installment
      for (final installment in _installments) {
        if (installment.id != null) {
          _payments[installment.id!] = await _dbHelper.getInstallmentPayments(installment.id!);
        }
      }
    } catch (e) {
      debugPrint('Error loading installments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addInstallment(Installment installment) async {
    try {
      final id = await _dbHelper.insertInstallment(installment);
      final newInstallment = installment.copyWith(id: id);
      _installments.add(newInstallment);
      _payments[id] = [];
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding installment: $e');
      throw Exception('فشل في إضافة القسط');
    }
  }

  Future<void> updateInstallment(Installment installment) async {
    try {
      await _dbHelper.updateInstallment(installment);
      final index = _installments.indexWhere((i) => i.id == installment.id);
      if (index != -1) {
        _installments[index] = installment;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating installment: $e');
      throw Exception('فشل في تحديث القسط');
    }
  }

  Future<void> deleteInstallment(int id) async {
    try {
      await _dbHelper.deleteInstallment(id);
      _installments.removeWhere((installment) => installment.id == id);
      _payments.remove(id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting installment: $e');
      throw Exception('فشل في حذف القسط');
    }
  }

  Future<void> addPayment(int installmentId, InstallmentPayment payment) async {
    try {
      final paymentId = await _dbHelper.insertInstallmentPayment(payment);
      final newPayment = payment.copyWith(id: paymentId);
      
      // Update payments list
      if (_payments[installmentId] == null) {
        _payments[installmentId] = [];
      }
      _payments[installmentId]!.add(newPayment);
      
      // Update installment paid amount
      final installment = _installments.firstWhere((i) => i.id == installmentId);
      final totalPaid = _payments[installmentId]!.fold(0.0, (sum, p) => sum + p.amount);
      final isCompleted = totalPaid >= installment.totalAmount;
      
      final updatedInstallment = installment.copyWith(
        paidAmount: totalPaid,
        isCompleted: isCompleted,
        updatedAt: DateTime.now(),
      );
      
      await updateInstallment(updatedInstallment);
    } catch (e) {
      debugPrint('Error adding payment: $e');
      throw Exception('فشل في إضافة الدفعة');
    }
  }

  Future<void> deletePayment(int installmentId, int paymentId) async {
    try {
      await _dbHelper.deleteInstallmentPayment(paymentId);
      
      // Update payments list
      _payments[installmentId]?.removeWhere((p) => p.id == paymentId);
      
      // Update installment paid amount
      final installment = _installments.firstWhere((i) => i.id == installmentId);
      final totalPaid = _payments[installmentId]?.fold(0.0, (sum, p) => sum + p.amount) ?? 0.0;
      final isCompleted = totalPaid >= installment.totalAmount;
      
      final updatedInstallment = installment.copyWith(
        paidAmount: totalPaid,
        isCompleted: isCompleted,
        updatedAt: DateTime.now(),
      );
      
      await updateInstallment(updatedInstallment);
    } catch (e) {
      debugPrint('Error deleting payment: $e');
      throw Exception('فشل في حذف الدفعة');
    }
  }

  List<Installment> getInstallmentsByPersonId(int personId) {
    return _installments.where((installment) => installment.personId == personId).toList();
  }

  List<Installment> getActiveInstallments() {
    return _installments.where((installment) => !installment.isCompleted).toList();
  }

  List<InstallmentPayment> getInstallmentPayments(int installmentId) {
    return _payments[installmentId] ?? [];
  }

  double getTotalInstallmentAmount() {
    return _installments.fold(0.0, (sum, installment) => sum + installment.totalAmount);
  }

  double getTotalPaidAmount() {
    return _installments.fold(0.0, (sum, installment) => sum + installment.paidAmount);
  }

  double getTotalRemainingAmount() {
    return _installments.fold(0.0, (sum, installment) => sum + installment.remainingAmount);
  }

  double getPersonTotalInstallments(int personId) {
    return _installments
        .where((installment) => installment.personId == personId && !installment.isCompleted)
        .fold(0.0, (sum, installment) => sum + installment.remainingAmount);
  }

  // Remove installments for a specific person (called when person is deleted)
  void removeInstallmentsForPerson(int personId) {
    _installments.removeWhere((installment) => installment.personId == personId);
    // Also remove associated payments
    _payments.removeWhere((key, value) => _installments.any((i) => i.id == key && i.personId == personId));
    notifyListeners();
  }
}
