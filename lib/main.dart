import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'config/supabase_config.dart';
import 'config/ssl_config.dart';

/// تجاهل شهادات SSL للتطوير فقط
/// WARNING: هذا الكود خطير ولا يجب استخدامه في الإنتاج!
class DevelopmentHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // في وضع التطوير، نتجاهل جميع أخطاء الشهادات
        if (kDebugMode) {
          print('تجاهل خطأ شهادة SSL للمضيف: $host:$port');
          return true;
        }
        // في الإنتاج، نستخدم التحقق العادي
        return false;
      };
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تطبيق تجاهل شهادات SSL للتطوير فقط
  if (kDebugMode) {
    HttpOverrides.global = DevelopmentHttpOverrides();
    print('تم تفعيل تجاهل شهادات SSL للتطوير');
    
    // طباعة حالة تكوين SSL
    SSLConfig.printSSLStatus();
  }

  // تهيئة SQLite لسطح المكتب
  // File analyzed by Cline. Awaiting further instructions.
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
  }
  databaseFactory = databaseFactoryFfi;

  // تهيئة Supabase مع تكوين خاص للتطوير
  await Supabase.initialize(
    url: SupabaseConfig.projectUrl,
    anonKey: SupabaseConfig.apiKey,
    // تكوين إضافي للتطوير
    debug: kDebugMode,
  );

  runApp(const StoreManagementApp());
}
