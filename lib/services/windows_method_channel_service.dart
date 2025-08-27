import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'app_lifecycle_service.dart';

class WindowsMethodChannelService {
  static const MethodChannel _channel = MethodChannel('app_lifecycle');
  static BuildContext? _context;

  /// تهيئة الخدمة مع context
  static void initialize(BuildContext context) {
    _context = context;
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  /// معالج استقبال الرسائل من Windows
  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'windowClosing':
        await _handleWindowClosing();
        break;
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: 'Method ${call.method} not implemented',
        );
    }
  }

  /// التعامل مع حدث إغلاق النافذة
  static Future<void> _handleWindowClosing() async {
    if (_context == null) return;

    try {
      // محاولة إنشاء نسخة احتياطية قبل الإغلاق
      final success = await AppLifecycleService.createBackupOnExit(
        context: _context!,
        showDialog: true,
      );

      if (success) {
        // إغلاق التطبيق بعد النسخ الاحتياطي الناجح
        await forceCloseWindow();
      }
      // إذا فشل النسخ الاحتياطي أو ألغى المستخدم، لا نغلق النافذة
    } catch (e) {
      print('خطأ في معالجة إغلاق النافذة: $e');
      // في حالة الخطأ، اعرض رسالة للمستخدم ولا تغلق النافذة
      if (_context != null) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          SnackBar(
            content: Text('خطأ في معالجة إغلاق التطبيق: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// إغلاق النافذة بالقوة (بعد إنجاز النسخ الاحتياطي)
  static Future<void> forceCloseWindow() async {
    try {
      await _channel.invokeMethod('forceClose');
    } catch (e) {
      print('خطأ في إغلاق النافذة: $e');
      // كحل احتياطي، استخدم طريقة Flutter العادية
      AppLifecycleService.exitAppImmediately();
    }
  }

  /// تحديث الـ context (مفيد عند تغيير الشاشات)
  static void updateContext(BuildContext context) {
    _context = context;
  }

  /// تنظيف الموارد
  static void dispose() {
    _context = null;
  }
}
