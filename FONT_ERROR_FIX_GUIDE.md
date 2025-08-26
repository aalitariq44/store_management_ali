# دليل إصلاح مشكلة RangeError في طباعة النص العربي

## المشكلة
عند محاولة طباعة وثائق بها نصوص عربية، تظهر رسالة خطأ:
```
RangeError (byteOffset): Index out of range: index should be less than 212609: 212615
```

هذه المشكلة تحدث بسبب تعامل مكتبة PDF مع البيانات الثنائية للخطوط العربية، ويحدث خطأ عند محاولة الوصول لجزء من البيانات خارج النطاق المسموح.

## الحل المطبق

### 1. تعديل طريقة تحميل الخطوط
تم تغيير طريقة تحميل الخطوط في ملف `PDFService` لتجنب حدوث خطأ `RangeError`:

```dart
// الطريقة القديمة - تسبب خطأ RangeError
final data = await rootBundle.load(path);
final byteData = ByteData.view(
  data.buffer,
  data.offsetInBytes,
  data.lengthInBytes,
);
final font = pw.Font.ttf(byteData);

// الطريقة الجديدة - تعمل بدون مشاكل
final data = await rootBundle.load(path);
final font = pw.Font.ttf(data);
```

### 2. تحسين دعم الخطوط المتعددة
- تم تحديث قائمة الخطوط لتشمل أكثر من خط عربي
- يتم المحاولة بالترتيب حتى نجد خط يعمل
- إضافة رسائل تشخيص لمساعدة المطورين في تتبع المشكلات

## كيفية التحقق من حل المشكلة

1. تأكد من تحديث ملف `pdf_service.dart` بالطريقة الجديدة لتحميل الخطوط
2. قم بتشغيل التطبيق وتجربة طباعة وصل إنترنت أو أي تقرير يحتوي على نصوص عربية
3. تحقق من عدم ظهور رسالة الخطأ وظهور النص العربي بشكل صحيح

## تشخيص مشاكل الخطوط

إذا استمرت مشكلة الطباعة، يمكن استخدام إحدى الطرق التالية:

1. **تشغيل أداة إصلاح الخطوط**:
   ```
   dart fix_arabic_fonts_issue.dart
   ```

2. **التحقق من وجود الخطوط**:
   ```dart
   bool notoExists = await rootBundle.loadString('assets/fonts/NotoSansArabic-Regular.ttf')
     .then((_) => true).catchError((_) => false);
   print('Noto Sans Arabic exists: $notoExists');
   ```

3. **تفعيل التشخيص المفصل**:
   أضف السطر التالي في بداية الدالة التي تقوم بالطباعة:
   ```dart
   print('تفاصيل الخطوط: arabicFont=${_arabicFont != null}, arabicBoldFont=${_arabicBoldFont != null}');
   ```

## الخطوط العربية المدعومة

تم تضمين العديد من الخطوط العربية في التطبيق:
- Noto Sans Arabic
- Amiri (Regular, Bold, Italic, BoldItalic)
- Cairo (بأوزان متعددة)
- Beiruti

## للمطورين

عند تعديل نظام الطباعة، يرجى مراعاة النقاط التالية:
1. استخدم الطريقة المباشرة لتحميل الخطوط كما هو موضح أعلاه
2. تجنب استخدام `ByteData.view` عند التعامل مع بيانات الخطوط
3. تأكد دائمًا من تعريف اتجاه النص `textDirection: pw.TextDirection.rtl`
4. اختبر الطباعة على جميع المنصات المدعومة
