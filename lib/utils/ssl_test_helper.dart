import 'package:flutter/foundation.dart';
import 'package:store_management_ali/config/ssl_config.dart';
import 'dart:convert';

/// ملف اختبار لتجربة تجاهل شهادات SSL
class SSLTestHelper {
  /// اختبار الاتصال مع خادم محلي
  static Future<void> testLocalConnection() async {
    if (!kDebugMode) {
      print('هذا الاختبار يعمل فقط في وضع التطوير');
      return;
    }

    try {
      print('بدء اختبار الاتصال مع تجاهل SSL...');
      
      // مثال على طلب GET لخادم محلي
      final response = await SecureHttpHelper.get(
        Uri.parse('https://localhost:3000/api/test'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('نجح الاتصال! كود الاستجابة: ${response.statusCode}');
      print('محتوى الاستجابة: ${response.body}');
      
    } catch (e) {
      print('فشل الاختبار: $e');
    }
  }

  /// اختبار طلب POST
  static Future<void> testPostRequest() async {
    if (!kDebugMode) {
      print('هذا الاختبار يعمل فقط في وضع التطوير');
      return;
    }

    try {
      print('بدء اختبار طلب POST...');
      
      final testData = {
        'message': 'اختبار تجاهل SSL',
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await SecureHttpHelper.post(
        Uri.parse('https://localhost:3000/api/data'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(testData),
      );

      print('نجح إرسال POST! كود الاستجابة: ${response.statusCode}');
      
    } catch (e) {
      print('فشل اختبار POST: $e');
    }
  }

  /// طباعة حالة تكوين SSL
  static void printSSLConfiguration() {
    print('\n=== معلومات تكوين SSL ===');
    print('وضع التطوير: ${kDebugMode ? 'مفعل' : 'معطل'}');
    print('تجاهل شهادات SSL: ${SSLConfig.isSSLBypassEnabled() ? 'مفعل' : 'معطل'}');
    
    if (kDebugMode) {
      print('✅ تم تكوين تجاهل SSL بنجاح للتطوير');
      print('📝 الاتصالات مع الخوادم المحلية ستعمل بدون مشاكل شهادات SSL');
    } else {
      print('🔒 تكوين الإنتاج - التحقق من شهادات SSL مفعل');
    }
    print('============================\n');
  }
}

/// استخدام هذا الكلاس في main.dart أو أي مكان آخر:
/// 
/// ```dart
/// import 'package:store_management_ali/utils/ssl_test_helper.dart';
/// 
/// // في main() أو في أي مكان تريد الاختبار
/// if (kDebugMode) {
///   SSLTestHelper.printSSLConfiguration();
///   // await SSLTestHelper.testLocalConnection();
/// }
/// ```
