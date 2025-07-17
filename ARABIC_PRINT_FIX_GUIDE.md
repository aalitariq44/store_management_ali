# دليل حل مشكلة الطباعة العربية

## المشكلة
كانت اللغة العربية تظهر مشوهة في ملفات PDF المطبوعة بسبب عدم استخدام خطوط عربية مناسبة.

## الحل المطبق

### 1. إضافة الخطوط العربية في pubspec.yaml
```yaml
fonts:
  - family: NotoSansArabic
    fonts:
      - asset: assets/fonts/NotoSansArabic-Regular.ttf
  - family: Amiri
    fonts:
      - asset: assets/fonts/Amiri-Regular.ttf
      - asset: assets/fonts/Amiri-Bold.ttf
        weight: 700
  - family: Cairo
    fonts:
      - asset: assets/fonts/Cairo-Regular.ttf
      - asset: assets/fonts/Cairo-Bold.ttf
        weight: 700
```

### 2. تعديلات في PDFService

#### أ) إضافة متغيرات الخطوط
```dart
static pw.Font? _arabicFont;
static pw.Font? _arabicBoldFont;
```

#### ب) دالة تحميل الخطوط
```dart
static Future<void> _loadArabicFonts() async {
  if (_arabicFont == null || _arabicBoldFont == null) {
    try {
      // تحميل خط Amiri أولاً
      final regularFont = await rootBundle.load("assets/fonts/Amiri-Regular.ttf");
      final boldFont = await rootBundle.load("assets/fonts/Amiri-Bold.ttf");
      
      _arabicFont = pw.Font.ttf(regularFont);
      _arabicBoldFont = pw.Font.ttf(boldFont);
    } catch (e) {
      // في حالة الفشل، نجرب Cairo
      try {
        final regularFont = await rootBundle.load("assets/fonts/Cairo-Regular.ttf");
        final boldFont = await rootBundle.load("assets/fonts/Cairo-Bold.ttf");
        
        _arabicFont = pw.Font.ttf(regularFont);
        _arabicBoldFont = pw.Font.ttf(boldFont);
      } catch (e2) {
        // أخيراً نجرب NotoSansArabic
        try {
          final arabicFont = await rootBundle.load("assets/fonts/NotoSansArabic-Regular.ttf");
          _arabicFont = pw.Font.ttf(arabicFont);
          _arabicBoldFont = _arabicFont;
        } catch (e3) {
          print('فشل في تحميل الخطوط العربية: $e3');
        }
      }
    }
  }
}
```

#### ج) دالة مساعدة لأنماط النص
```dart
static pw.TextStyle _arabicTextStyle({
  double fontSize = 12,
  bool isBold = false,
  PdfColor? color,
}) {
  return pw.TextStyle(
    font: isBold ? _arabicBoldFont : _arabicFont,
    fontSize: fontSize,
    fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
    color: color,
  );
}
```

### 3. التحديثات المطبقة

#### تحديث جميع دوال الطباعة لتحميل الخطوط:
- `printCustomerDetails()` - تحميل الخطوط قبل إنشاء PDF
- `printDebts()` - تحميل الخطوط قبل إنشاء PDF
- `printInstallments()` - تحميل الخطوط قبل إنشاء PDF
- `printInternetSubscriptions()` - تحميل الخطوط قبل إنشاء PDF

#### تحديث جميع النصوص لاستخدام الخطوط العربية:
- استخدام `_arabicTextStyle()` بدلاً من `pw.TextStyle()`
- إضافة `textDirection: pw.TextDirection.rtl` لجميع النصوص العربية
- تحديث `_buildTableCell()` لدعم العربية
- تحديث جميع عناوين الأقسام والملخصات

## النتائج المتوقعة

### قبل التطبيق:
- النص العربي يظهر كمربعات أو رموز غريبة
- ترتيب الكلمات من اليسار إلى اليمين (خاطئ)
- عدم وضوح النص

### بعد التطبيق:
- النص العربي يظهر بوضوح تام
- ترتيب صحيح من اليمين إلى اليسار (RTL)
- خطوط جميلة وواضحة
- دعم النص العريض والعادي

## كيفية الاختبار

1. شغل التطبيق
2. اذهب إلى أي صفحة طباعة
3. اطبع تقرير أو استخدم صفحة الاختبار المضافة
4. تحقق من وضوح النص العربي في PDF

## الملفات المعدلة

- `pubspec.yaml` - إضافة تعريفات الخطوط
- `lib/services/pdf_service.dart` - التعديل الرئيسي
- `lib/screens/print_test_screen.dart` - صفحة اختبار جديدة (اختيارية)

## ملاحظات مهمة

1. **التراجع التدريجي**: إذا فشل تحميل خط، يجرب الخط التالي
2. **الأداء**: الخطوط تحمل مرة واحدة فقط وتحفظ في الذاكرة
3. **التوافق**: يعمل على جميع المنصات (Windows, Android, iOS, Web)
4. **الصيانة**: سهولة إضافة خطوط جديدة أو تعديل الموجودة

## استكشاف الأخطاء

### إذا ظهرت رسالة "فشل في تحميل الخطوط العربية":
1. تأكد من وجود ملفات الخطوط في `assets/fonts/`
2. تأكد من تعريف الخطوط في `pubspec.yaml`
3. شغل `flutter pub get` لتحديث الـ assets
4. تأكد من صحة أسماء ملفات الخطوط

### إذا كان النص ما زال مشوهاً:
1. تأكد من إضافة `textDirection: pw.TextDirection.rtl`
2. تأكد من استخدام `_arabicTextStyle()` بدلاً من `pw.TextStyle()`
3. تحقق من console للرسائل المتعلقة بالخطوط

## المزايا المضافة

1. **مرونة في الخطوط**: دعم متعدد للخطوط العربية
2. **أداء محسن**: تحميل الخطوط مرة واحدة
3. **سهولة الصيانة**: دالة مساعدة للأنماط
4. **صفحة اختبار**: لاختبار سريع للطباعة
5. **دعم شامل**: RTL + خطوط عربية صحيحة
