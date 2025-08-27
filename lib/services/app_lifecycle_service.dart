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
      final success = await BackupService.uploadBackup();

      if (context.mounted) {
        Navigator.of(context).pop(); // إغلاق مؤشر التقدم
      }

      if (success) {
        // تنظيف النسخ القديمة
        await BackupService.cleanupOldBackups();

        if (context.mounted) {
          _showSuccessMessage(context);
        }

        // إعطاء وقت قصير لعرض الرسالة
        await Future.delayed(const Duration(milliseconds: 1500));

        return true;
      } else {
        if (context.mounted) {
          _showErrorMessage(context, 'فشل في إنشاء النسخة الاحتياطية');
        }
        return false;
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // إغلاق مؤشر التقدم إذا كان مفتوحاً
        _showErrorMessage(context, 'خطأ في إنشاء النسخة الاحتياطية: $e');
      }
      return false;
    } finally {
      _isBackupInProgress = false;
    }
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
  static void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// إغلاق التطبيق بعد النسخ الاحتياطي
  static Future<void> exitAppWithBackup(BuildContext context) async {
    final success = await createBackupOnExit(context: context);

    if (success) {
      // إغلاق التطبيق
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        exit(0);
      } else {
        SystemNavigator.pop();
      }
    }
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
