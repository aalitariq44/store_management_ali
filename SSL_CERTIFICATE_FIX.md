# حل مشكلة شهادات SSL في التطوير - SSL Certificate Fix Guide

## المشكلة
```
CERTIFICATE_VERIFY_FAILED: unable to get local issuer certificate
```

هذا الخطأ يحدث عندما يفشل التطبيق في التحقق من شهادة SSL للخادم المحلي أو خادم التطوير.

## الحل المطبق

### 1. إعداد تجاهل شهادات SSL العام (في main.dart)

```dart
/// تجاهل شهادات SSL للتطوير فقط
class DevelopmentHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        if (kDebugMode) {
          print('تجاهل خطأ شهادة SSL للمضيف: $host:$port');
          return true; // تجاهل جميع أخطاء الشهادات في التطوير
        }
        return false; // التحقق العادي في الإنتاج
      };
  }
}
```

### 2. تطبيق الإعداد في main()
```dart
if (kDebugMode) {
  HttpOverrides.global = DevelopmentHttpOverrides();
  print('تم تفعيل تجاهل شهادات SSL للتطوير');
}
```

### 3. استخدام SSL Helper للطلبات المخصصة

إذا كنت تحتاج لإرسال طلبات HTTP مخصصة، استخدم `SecureHttpHelper`:

```dart
import 'package:store_management_ali/config/ssl_config.dart';

// مثال على استخدام GET
final response = await SecureHttpHelper.get(
  Uri.parse('https://your-server.com/api/data'),
  headers: {'Authorization': 'Bearer your-token'},
);

// مثال على استخدام POST
final postResponse = await SecureHttpHelper.post(
  Uri.parse('https://your-server.com/api/upload'),
  headers: {'Content-Type': 'application/json'},
  body: json.encode({'key': 'value'}),
);
```

## الملفات المعدلة

1. **lib/main.dart**
   - إضافة فئة `DevelopmentHttpOverrides`
   - تطبيق تجاهل SSL في وضع التطوير فقط
   - طباعة معلومات التكوين

2. **lib/config/ssl_config.dart** (ملف جديد)
   - فئة `SSLConfig` لإدارة إعدادات SSL
   - فئة `SecureHttpHelper` للطلبات الآمنة
   - دوال مساعدة للتحقق من حالة SSL

3. **pubspec.yaml**
   - إضافة مكتبة `http` للطلبات المخصصة

## الأمان والاعتبارات المهمة

⚠️ **تحذير مهم**: هذا الحل يعمل فقط في وضع التطوير (`kDebugMode = true`)

✅ **آمن للاستخدام لأن**:
- يعمل فقط في وضع التطوير
- لا يؤثر على الإنتاج
- يتم التحقق من `kDebugMode` قبل تجاهل الشهادات

✅ **يدعم**:
- جميع طلبات HTTP/HTTPS
- اتصالات WebSocket
- مكتبة Supabase
- أي مكتبة تستخدم HttpClient الافتراضي

## اختبار الحل

1. قم بتشغيل التطبيق في وضع التطوير:
   ```bash
   flutter run -d windows
   ```

2. تحقق من رسائل التشخيص في وحدة التحكم:
   ```
   تم تفعيل تجاهل شهادات SSL للتطوير
   === تكوين SSL ===
   وضع التطوير: نعم
   تجاهل شهادات SSL: نعم
   ==================
   ```

3. عند محاولة الاتصال بخادم بشهادة غير صالحة، ستظهر رسالة:
   ```
   تجاهل خطأ شهادة SSL للمضيف: your-server.com:443
   ```

## استكشاف الأخطاء

### إذا استمر الخطأ:
1. تأكد من أنك تشغل التطبيق في وضع التطوير (Debug mode)
2. تحقق من ظهور رسائل SSL في وحدة التحكم
3. أعد تشغيل التطبيق بعد التعديلات

### للتحقق من حالة SSL برمجياً:
```dart
import 'package:store_management_ali/config/ssl_config.dart';

if (SSLConfig.isSSLBypassEnabled()) {
  print('تجاهل SSL مفعل');
} else {
  print('تجاهل SSL غير مفعل');
}
```

## بناء للإنتاج

عند بناء التطبيق للإنتاج، سيتم تلقائياً:
- إلغاء تفعيل تجاهل شهادات SSL
- استخدام التحقق الطبيعي من الشهادات
- ضمان الأمان الكامل

```bash
flutter build windows --release
```

هذا الحل آمن وفعال لحل مشاكل شهادات SSL في بيئة التطوير فقط.
