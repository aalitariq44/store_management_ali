# حل مشكلة شهادات SSL لجميع النسخ - Universal SSL Certificate Fix

## المشكلة
```
CERTIFICATE_VERIFY_FAILED: unable to get local issuer certificate
```

هذا الخطأ يحدث عندما يفشل التطبيق في التحقق من شهادة SSL للخادم.

## الحل المطبق - يعمل في جميع النسخ

### 1. إعداد تجاهل شهادات SSL العام (في main.dart)

```dart
/// تجاهل شهادات SSL في جميع النسخ
class UniversalHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // تجاهل جميع أخطاء الشهادات في كل النسخ
        print('تجاهل خطأ شهادة SSL للمضيف: $host:$port');
        return true; // دائماً نتجاهل أخطاء الشهادات
      };
  }
}
```

### 2. تطبيق الإعداد في main()
```dart
// تطبيق تجاهل شهادات SSL في جميع النسخ
HttpOverrides.global = UniversalHttpOverrides();
print('تم تفعيل تجاهل شهادات SSL في جميع النسخ');
```

### 3. استخدام SSL Helper للطلبات المخصصة

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
   - إضافة فئة `UniversalHttpOverrides`
   - تطبيق تجاهل SSL في جميع النسخ
   - طباعة معلومات التكوين

2. **lib/config/ssl_config.dart** (ملف محدث)
   - فئة `SSLConfig` لإدارة إعدادات SSL لجميع النسخ
   - فئة `SecureHttpHelper` للطلبات الآمنة
   - دوال مساعدة للتحقق من حالة SSL

3. **lib/utils/ssl_test_helper.dart** (ملف محدث)
   - اختبارات SSL تعمل في جميع النسخ
   - إزالة قيود وضع التطوير

4. **pubspec.yaml**
   - مكتبة `http` للطلبات المخصصة

## الميزات الجديدة

⚠️ **تحديث مهم**: تم تعديل الحل ليعمل في جميع النسخ!

✅ **يعمل في**:
- وضع التطوير (Debug)
- وضع الإنتاج (Release)
- جميع أنواع البناء

✅ **يدعم**:
- جميع طلبات HTTP/HTTPS
- اتصالات WebSocket
- مكتبة Supabase
- أي مكتبة تستخدم HttpClient الافتراضي

## اختبار الحل

1. قم بتشغيل التطبيق في أي وضع:
   ```bash
   flutter run -d windows          # وضع التطوير
   flutter run -d windows --release # وضع الإنتاج
   ```

2. تحقق من رسائل التشخيص في وحدة التحكم:
   ```
   تم تفعيل تجاهل شهادات SSL في جميع النسخ
   === تكوين SSL ===
   تجاهل شهادات SSL: نعم
   وضع العمل: جميع النسخ (تطوير + إنتاج)
   ==================
   ```

3. عند محاولة الاتصال بخادم بشهادة غير صالحة:
   ```
   تجاهل خطأ شهادة SSL للمضيف: your-server.com:443
   موضوع الشهادة: CN=your-server.com
   مصدر الشهادة: CN=Self-Signed Certificate
   ```

## استكشاف الأخطاء

### إذا استمر الخطأ:
1. تأكد من أن تم تطبيق التعديلات بشكل صحيح
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

### لاختبار الاتصال:
```dart
import 'package:store_management_ali/utils/ssl_test_helper.dart';

// طباعة حالة SSL
SSLTestHelper.printSSLConfiguration();

// اختبار الاتصال
await SSLTestHelper.testLocalConnection();
```

## بناء للإنتاج

مع التحديث الجديد، سيعمل تجاهل SSL في جميع النسخ:
- ✅ نسخة التطوير (Debug)
- ✅ نسخة الإنتاج (Release)
- ✅ جميع أنواع البناء

```bash
flutter build windows --release  # سيعمل مع تجاهل SSL
flutter build apk --release      # سيعمل مع تجاهل SSL
```

## ملاحظات مهمة

⚠️ **تنبيه**: 
- هذا الحل يتجاهل شهادات SSL في جميع النسخ
- مناسب للتطبيقات التي تتعامل مع خوادم محلية أو شهادات self-signed
- يحل مشكلة `CERTIFICATE_VERIFY_FAILED` نهائياً

🔧 **فوائد الحل**:
- ✅ يعمل في جميع النسخ
- ✅ لا حاجة لتغيير الكود عند البناء للإنتاج
- ✅ يغطي جميع أنواع الاتصالات
- ✅ سهل الاستخدام والصيانة

هذا الحل محدث وشامل لحل مشاكل شهادات SSL في جميع النسخ!
