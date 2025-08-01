import 'package:flutter/material.dart';
import '../config/database_helper.dart';
import '../models/password_model.dart';

class PasswordProvider with ChangeNotifier {
  bool _isFirstTime = true;
  bool _isAuthenticated = false;

  bool get isFirstTime => _isFirstTime;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> initialize() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query('app_password', limit: 1);
      _isFirstTime = result.isEmpty;
    } catch (e) {
      if (e.toString().contains('no such table')) {
        // إذا كان الجدول غير موجود، قم بإنشائه
        final db = await DatabaseHelper.instance.database;
        await db.execute('''
          CREATE TABLE app_password (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            hashed_password TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        _isFirstTime = true; // الجدول جديد، لذا هو أول مرة
      } else {
        // لأي خطأ آخر، أعد طرحه
        rethrow;
      }
    } finally {
      notifyListeners();
    }
  }

  Future<bool> setPassword(String password) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final hashedPassword = PasswordModel.hashPassword(password);
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final result = await db.query('app_password', limit: 1);

      if (result.isEmpty) {
        // إنشاء كلمة مرور جديدة
        await db.insert('app_password', {
          'hashed_password': hashedPassword,
          'created_at': timestamp,
          'updated_at': timestamp,
        });
      } else {
        // تحديث كلمة المرور الموجودة
        await db.update(
          'app_password',
          {
            'hashed_password': hashedPassword,
            'updated_at': timestamp,
          },
          where: 'id = ?',
          whereArgs: [result.first['id']],
        );
      }

      _isFirstTime = false;
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      print('خطأ في حفظ كلمة المرور: $e');
      return false;
    }
  }

  Future<bool> verifyPassword(String password) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query('app_password', limit: 1);
      
      if (result.isEmpty) {
        return false;
      }

      final hashedPassword = result.first['hashed_password'] as String;
      final isValid = PasswordModel.verifyPassword(password, hashedPassword);
      
      if (isValid) {
        _isAuthenticated = true;
        notifyListeners();
      }
      
      return isValid;
    } catch (e) {
      print('خطأ في التحقق من كلمة المرور: $e');
      return false;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      // التحقق من كلمة المرور القديمة
      final isOldPasswordValid = await verifyPassword(oldPassword);
      if (!isOldPasswordValid) {
        return false;
      }

      // تحديث كلمة المرور
      return await setPassword(newPassword);
    } catch (e) {
      print('خطأ في تغيير كلمة المرور: $e');
      return false;
    }
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }
}
