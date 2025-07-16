# إعدادات سريعة لنظام الطباعة

## الحزم المطلوبة

تأكد من وجود هذه الحزم في `pubspec.yaml`:

```yaml
dependencies:
  # PDF Generation
  pdf: ^3.11.1
  printing: ^5.13.2
  path_provider: ^2.1.4
```

## الملفات المضافة

### 1. خدمة PDF الرئيسية
- `lib/services/pdf_service.dart`

### 2. ويدجت الطباعة للزبائن
- `lib/widgets/print_options_widget.dart`

### 3. ويدجت الطباعة العامة
- `lib/widgets/general_print_widget.dart`

## التعديلات على الملفات الموجودة

### 1. صفحة تفاصيل الزبون
- `lib/screens/customer_details_screen.dart`
- تمت إضافة `PrintOptionsWidget`

### 2. صفحة الديون
- `lib/screens/debts_screen.dart`
- تمت إضافة `GeneralPrintWidget(type: 'debts')`

### 3. صفحة الأقساط
- `lib/screens/installments_screen.dart`
- تمت إضافة `GeneralPrintWidget(type: 'installments')`

### 4. صفحة الإنترنت
- `lib/screens/internet_screen.dart`
- تمت إضافة `GeneralPrintWidget(type: 'internet')`

## الخطوط العربية (اختياري)

لتحسين دعم النص العربي، يمكنك إضافة خطوط عربية:

1. أنشئ مجلد `assets/fonts/`
2. ضع ملفات الخطوط العربية (مثل Noto Sans Arabic)
3. أضف الخطوط إلى `pubspec.yaml`

## الأذونات المطلوبة

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to photo library to save PDF files</string>
```

## اختبار النظام

1. شغل التطبيق
2. اذهب إلى صفحة تفاصيل أي زبون
3. جرب أزرار الطباعة المختلفة
4. تأكد من ظهور نافذة الطباعة أو حفظ الملف
5. جرب الطباعة من الصفحات العامة

## استكشاف الأخطاء

### خطأ في الاستيراد
```dart
import '../services/pdf_service.dart';
```

### خطأ في الخطوط
اجعل الخطوط اختيارية في `PDFService` أو أضف خطوط صالحة

### خطأ في الطباعة
تأكد من أن النظام يدعم الطباعة أو المعاينة

## نصائح للتطوير

1. **اختبر على منصات متعددة**: Windows, Android, Web
2. **استخدم بيانات تجريبية**: لاختبار التقارير
3. **تحقق من الأداء**: مع كميات كبيرة من البيانات
4. **اختبر الخطوط**: تأكد من دعم النص العربي
5. **اختبر الطباعة**: على طابعات مختلفة
