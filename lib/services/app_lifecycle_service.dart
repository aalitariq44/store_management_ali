import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'backup_service.dart';

class AppLifecycleService {
  static bool _isBackupInProgress = false;

  /// إنشاء نسخة احتياطية عند الخروج من التطبيق
  static Future<bool> createBackupOnExit({
    required BuildContext context,
    bool showDialog = true,
  }) async {
    if (_isBackupInProgress) {
      return false;
    }

    _isBackupInProgress = true;

    try {
      if (showDialog && context.mounted) {
        // عرض حوار التأكيد
        final shouldBackup = await _showExitConfirmationDialog(context);
        if (!shouldBackup) {
          _isBackupInProgress = false;
          return false;
        }

        // عرض مؤشر النسخ الاحتياطي
        if (context.mounted) {
          _showBackupProgressDialog(context);
        }
      }

      // إنشاء النسخة الاحتياطية
      final errorMessage = await BackupService.uploadBackup();

      if (context.mounted) {
        Navigator.of(context).pop(); // إغلاق مؤشر التقدم
      }

      if (errorMessage == null) {
        // تنظيف النسخ القديمة
        await BackupService.cleanupOldBackups();

        if (context.mounted) {
          _showSuccessMessage(context);
        }

        // إعطاء وقت قصير لعرض الرسالة
        await Future.delayed(const Duration(milliseconds: 1500));
        _exitApplication(); // الخروج بعد رسالة النجاح
      } else {
        if (context.mounted) {
          await _showErrorMessage(context, 'فشل في إنشاء النسخة الاحتياطية: $errorMessage');
        } else {
          _exitApplication(); // الخروج حتى لو لم يكن السياق متاحًا لعرض الرسالة
        }
      }
    } catch (e, stackTrace) {
      if (context.mounted) {
        Navigator.of(context).pop(); // إغلاق مؤشر التقدم إذا كان مفتوحاً
        await _showErrorMessage(context, 'خطأ غير متوقع في إنشاء النسخة الاحتياطية: $e\nتتبع الخطأ: $stackTrace');
      } else {
        _exitApplication(); // الخروج حتى لو لم يكن السياق متاحًا لعرض الرسالة
      }
    } finally {
      _isBackupInProgress = false;
    }
    return true; // Return true to satisfy the Future<bool> return type, but exit is handled internally.
  }

  /// عرض حوار تأكيد الخروج مع النسخ الاحتياطي
  static Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.exit_to_app, color: Colors.orange),
            SizedBox(width: 10),
            Text('الخروج من التطبيق'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'سيتم الخروج من التطبيق بعد عمل نسخة احتياطية للبيانات.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.backup, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'هذا سيضمن حفظ جميع بياناتك في السحابة',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.backup),
            label: const Text('متابعة مع النسخ الاحتياطي'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// عرض مؤشر تقدم النسخ الاحتياطي
  static void _showBackupProgressDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'جاري إنشاء النسخة الاحتياطية...',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'يرجى الانتظار حتى اكتمال العملية',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// عرض رسالة نجاح
  static void _showSuccessMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text('تم إنشاء النسخة الاحتياطية بنجاح! سيتم إغلاق التطبيق'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 1500),
      ),
    );
  }

  /// عرض رسالة خطأ
  static Future<void> _showErrorMessage(BuildContext context, String message) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 10),
            Text('فشل النسخ الاحتياطي'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // إغلاق الحوار
              _exitApplication(); // الخروج من التطبيق
            },
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  /// وظيفة مساعدة للخروج من التطبيق
  static void _exitApplication() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      exit(0);
    } else {
      SystemNavigator.pop();
    }
  }

  /// إغلاق التطبيق بعد النسخ الاحتياطي
  static Future<void> exitAppWithBackup(BuildContext context) async {
    await createBackupOnExit(context: context);
    // The createBackupOnExit function now handles showing messages and exiting the app.
    // No need for additional exit logic here.
  }

  /// إغلاق التطبيق فوراً بدون نسخ احتياطي
  static void exitAppImmediately() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      exit(0);
    } else {
      SystemNavigator.pop();
    }
  }

  /// تحقق من حالة النسخ الاحتياطي
  static bool get isBackupInProgress => _isBackupInProgress;
}
