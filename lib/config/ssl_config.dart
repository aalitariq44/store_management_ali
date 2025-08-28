import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// تكوين SSL للتطوير
/// هذا الملف يحتوي على الإعدادات اللازمة لتجاهل شهادات SSL في التطوير
class SSLConfig {
  /// إنشاء HTTP Client مع تجاهل شهادات SSL للتطوير
  static http.Client createHttpClient() {
    if (kDebugMode) {
      // في وضع التطوير، نتجاهل شهادات SSL
      final HttpClient httpClient = HttpClient()
        ..badCertificateCallback = (X509Certificate cert, String host, int port) {
          print('تجاهل شهادة SSL للمضيف: $host:$port');
          return true; // تجاهل جميع أخطاء الشهادات
        };
      
      return IOClient(httpClient);
    } else {
      // في الإنتاج، نستخدم العميل العادي
      return http.Client();
    }
  }

  /// تكوين HttpClient مخصص للاستخدام المباشر
  static HttpClient createHttpClientDirect() {
    final HttpClient httpClient = HttpClient();
    
    if (kDebugMode) {
      httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) {
        print('تجاهل شهادة SSL للمضيف: $host:$port');
        print('تفاصيل الشهادة: ${cert.subject}');
        return true;
      };
      
      // إعدادات إضافية للتطوير
      httpClient.connectionTimeout = const Duration(seconds: 30);
      httpClient.idleTimeout = const Duration(seconds: 30);
    }
    
    return httpClient;
  }

  /// تحقق من حالة الاتصال الآمن
  static bool isSSLBypassEnabled() {
    return kDebugMode && HttpOverrides.current != null;
  }

  /// طباعة معلومات تكوين SSL
  static void printSSLStatus() {
    if (kDebugMode) {
      print('=== تكوين SSL ===');
      print('وضع التطوير: ${kDebugMode ? 'نعم' : 'لا'}');
      print('تجاهل شهادات SSL: ${isSSLBypassEnabled() ? 'نعم' : 'لا'}');
      print('==================');
    }
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
    return _client.delete(url, headers: headers, body: body, encoding: encoding);
  }

  /// إغلاق العميل
  static void close() {
    _client.close();
  }
}
