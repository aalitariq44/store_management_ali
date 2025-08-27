import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/backup_service.dart';

class BackupProvider extends ChangeNotifier {
  List<FileObject> _backupFiles = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<FileObject> get backupFiles => _backupFiles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// جلب قائمة النسخ الاحتياطية
  Future<void> loadBackupFiles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _backupFiles = await BackupService.getBackupFiles();
    } catch (e) {
      _errorMessage = 'خطأ في جلب قائمة النسخ الاحتياطية: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// إنشاء نسخة احتياطية جديدة
  /// يعيد رسالة خطأ مفصلة إذا فشل، أو null إذا نجح.
  Future<String?> createBackup() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final errorMessage = await BackupService.uploadBackup();
      if (errorMessage == null) {
        // تنظيف النسخ القديمة
        await BackupService.cleanupOldBackups();
        // إعادة تحميل قائمة النسخ
        await loadBackupFiles();
        return null; // النجاح
      } else {
        _errorMessage = errorMessage;
        return errorMessage; // الفشل مع رسالة خطأ مفصلة
      }
    } catch (e, stackTrace) {
      _errorMessage = 'خطأ غير متوقع في إنشاء النسخة الاحتياطية: $e\nتتبع الخطأ: $stackTrace';
      return _errorMessage; // الفشل مع رسالة خطأ مفصلة
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// استعادة نسخة احتياطية
  Future<bool> restoreBackup(String fileName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await BackupService.restoreBackup(fileName);
      return success;
    } catch (e) {
      _errorMessage = 'خطأ في استعادة النسخة الاحتياطية: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// حذف نسخة احتياطية
  Future<bool> deleteBackup(String fileName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await BackupService.deleteBackup(fileName);
      if (success) {
        // إعادة تحميل قائمة النسخ
        await loadBackupFiles();
      }
      return success;
    } catch (e) {
      _errorMessage = 'خطأ في حذف النسخة الاحتياطية: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// مسح رسالة الخطأ
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
