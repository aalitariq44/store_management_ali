import 'package:flutter/foundation.dart';
import '../models/internet_model.dart';
import '../config/database_helper.dart';

class InternetProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<InternetSubscription> _subscriptions = [];
  bool _isLoading = false;

  List<InternetSubscription> get subscriptions => _subscriptions;
  bool get isLoading => _isLoading;

  Future<void> loadSubscriptions() async {
    if (_isLoading) return;
    _isLoading = true;
    Future.microtask(notifyListeners);

    try {
      _subscriptions = await _dbHelper.getAllInternetSubscriptions();
    } catch (e) {
      debugPrint('Error loading subscriptions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSubscription(InternetSubscription subscription) async {
    try {
      final id = await _dbHelper.insertInternetSubscription(subscription);
      final newSubscription = subscription.copyWith(id: id);
      _subscriptions.add(newSubscription);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding subscription: $e');
      throw Exception('فشل في إضافة الاشتراك');
    }
  }

  Future<void> updateSubscription(InternetSubscription subscription) async {
    try {
      await _dbHelper.updateInternetSubscription(subscription);
      final index = _subscriptions.indexWhere((s) => s.id == subscription.id);
      if (index != -1) {
        _subscriptions[index] = subscription;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating subscription: $e');
      throw Exception('فشل في تحديث الاشتراك');
    }
  }

  Future<void> deleteSubscription(int id) async {
    try {
      await _dbHelper.deleteInternetSubscription(id);
      _subscriptions.removeWhere((subscription) => subscription.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting subscription: $e');
      throw Exception('فشل في حذف الاشتراك');
    }
  }

  Future<void> payForSubscription(int subscriptionId, double amount) async {
    try {
      final subscription = _subscriptions.firstWhere((s) => s.id == subscriptionId);
      final newPaidAmount = subscription.paidAmount + amount;
      
      if (newPaidAmount > subscription.price) {
        throw Exception('المبلغ المدفوع يتجاوز سعر الاشتراك');
      }

      final updatedSubscription = subscription.copyWith(
        paidAmount: newPaidAmount,
        updatedAt: DateTime.now(),
      );
      
      await updateSubscription(updatedSubscription);
    } catch (e) {
      debugPrint('Error paying for subscription: $e');
      throw Exception('فشل في عملية الدفع');
    }
  }

  Future<void> activateSubscription(int id) async {
    try {
      final subscription = _subscriptions.firstWhere((s) => s.id == id);
      final activeSubscription = subscription.copyWith(
        isActive: true,
        updatedAt: DateTime.now(),
      );
      
      await updateSubscription(activeSubscription);
    } catch (e) {
      debugPrint('Error activating subscription: $e');
      throw Exception('فشل في تفعيل الاشتراك');
    }
  }

  List<InternetSubscription> getSubscriptionsByPersonId(int personId) {
    return _subscriptions.where((subscription) => subscription.personId == personId).toList();
  }

  List<InternetSubscription> getActiveSubscriptions() {
    return _subscriptions.where((subscription) => subscription.isActive).toList();
  }

  List<InternetSubscription> getExpiredSubscriptions() {
    return _subscriptions.where((subscription) => subscription.isExpired && subscription.isActive).toList();
  }

  List<InternetSubscription> getExpiringSoonSubscriptions() {
    return _subscriptions.where((subscription) => subscription.isExpiringSoon && subscription.isActive && !subscription.isExpired).toList();
  }

  double getTotalActiveSubscriptionsRevenue() {
    return getActiveSubscriptions().fold(0.0, (sum, subscription) => sum + subscription.price);
  }

  double getPersonTotalActiveSubscriptions(int personId) {
    return _subscriptions
        .where((subscription) => subscription.personId == personId && subscription.isActive)
        .fold(0.0, (sum, subscription) => sum + subscription.price);
  }

  int getPersonActiveSubscriptionsCount(int personId) {
    return _subscriptions
        .where((subscription) => subscription.personId == personId && subscription.isActive)
        .length;
  }
}
