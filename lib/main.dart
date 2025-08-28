import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'config/supabase_config.dart';
import 'config/ssl_config.dart';

/// تجاهل شهادات SSL في جميع النسخ
/// تم تخصيص هذا الكود لتجاهل مشاكل شهادات SSL
class UniversalHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // تجاهل جميع أخطاء الشهادات في كل النسخ
        print('تجاهل خطأ شهادة SSL للمضيف: $host:$port');
        print('موضوع الشهادة: ${cert.subject}');
        print('مصدر الشهادة: ${cert.issuer}');
        return true; // دائماً نتجاهل أخطاء الشهادات
      };
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تطبيق تجاهل شهادات SSL في جميع النسخ
  HttpOverrides.global = UniversalHttpOverrides();
  print('تم تفعيل تجاهل شهادات SSL في جميع النسخ');

  // طباعة حالة تكوين SSL
  SSLConfig.printSSLStatus();

  // تهيئة SQLite لسطح المكتب
  // File analyzed by Cline. Awaiting further instructions.
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
  }
  databaseFactory = databaseFactoryFfi;

  // تهيئة Supabase مع تجاهل شهادات SSL
  await Supabase.initialize(
    url: SupabaseConfig.projectUrl,
    anonKey: SupabaseConfig.apiKey,
    // تكوين للجميع
    debug: true,
  );

  runApp(const StoreManagementApp());
}
