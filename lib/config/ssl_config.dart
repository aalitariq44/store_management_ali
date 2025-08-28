import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// تكوين SSL لجميع النسخ
/// هذا الملف يحتوي على الإعدادات اللازمة لتجاهل شهادات SSL في جميع النسخ
class SSLConfig {
  /// إنشاء HTTP Client مع تجاهل شهادات SSL لجميع النسخ
  static http.Client createHttpClient() {
    // تجاهل شهادات SSL في جميع النسخ
    final HttpClient httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        print('تجاهل شهادة SSL للمضيف: $host:$port');
        print('تفاصيل الشهادة: ${cert.subject}');
        return true; // تجاهل جميع أخطاء الشهادات
      };

    return IOClient(httpClient);
  }

  /// تكوين HttpClient مخصص للاستخدام المباشر
  static HttpClient createHttpClientDirect() {
    final HttpClient httpClient = HttpClient();

    // تجاهل شهادات SSL في جميع النسخ
    httpClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
          print('تجاهل شهادة SSL للمضيف: $host:$port');
          print('تفاصيل الشهادة: ${cert.subject}');
          return true; // دائماً نتجاهل أخطاء الشهادات
        };

    // إعدادات إضافية للاتصال
    httpClient.connectionTimeout = const Duration(seconds: 30);
    httpClient.idleTimeout = const Duration(seconds: 30);

    return httpClient;
  }

  /// تحقق من حالة الاتصال الآمن
  static bool isSSLBypassEnabled() {
    return HttpOverrides.current != null;
  }

  /// طباعة معلومات تكوين SSL
  static void printSSLStatus() {
    print('=== تكوين SSL ===');
    print('تجاهل شهادات SSL: ${isSSLBypassEnabled() ? 'نعم' : 'لا'}');
    print('وضع العمل: جميع النسخ (تطوير + إنتاج)');
    print('==================');
  }
}

/// فئة مساعدة لإنشاء طلبات HTTP آمنة
class SecureHttpHelper {
  static final http.Client _client = SSLConfig.createHttpClient();

  /// إرسال طلب GET
  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return _client.get(url, headers: headers);
  }

  /// إرسال طلب POST
  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return _client.post(url, headers: headers, body: body, encoding: encoding);
  }

  /// إرسال طلب PUT
  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return _client.put(url, headers: headers, body: body, encoding: encoding);
  }

  /// إرسال طلب DELETE
  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return _client.delete(
      url,
      headers: headers,
      body: body,
      encoding: encoding,
    );
  }

  /// إغلاق العميل
  static void close() {
    _client.close();
  }
}
