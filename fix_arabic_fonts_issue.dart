// أداة لإصلاح مشكلة الخطوط العربية في وصل الطباعة
// هذه الأداة تقوم بتعديل طريقة تحميل الخطوط في ملف pdf_service.dart

import 'dart:io';

void main() {
  print('بدء إصلاح مشكلة الخطوط العربية...');

  final file = File('lib/services/pdf_service.dart');
  if (!file.existsSync()) {
    print('خطأ: لم يتم العثور على الملف lib/services/pdf_service.dart');
    return;
  }

  String content = file.readAsStringSync();
  bool contentChanged = false;

  // 1. إصلاح طريقة تحميل الخطوط باستخدام الطريقة المباشرة
  final String oldFontLoading = """Future<pw.Font?> tryLoad(String path) async {
      try {
        final data = await rootBundle.load(path);
        // Create a ByteData view for the font buffer to match expected type
        final byteData = ByteData.view(
          data.buffer,
          data.offsetInBytes,
          data.lengthInBytes,
        );
        print('Attempting to load font: \$path');
        final font = pw.Font.ttf(byteData);
        print('Successfully loaded font: \$path');
        return font;
      } catch (e) {
        print('Error loading font \$path: \$e');
        return null;
      }
    }""";

  final String newFontLoading = """Future<pw.Font?> tryLoad(String path) async {
      try {
        // استخدام الطريقة المباشرة لتجنب خطأ RangeError (byteOffset)
        final data = await rootBundle.load(path);
        print('Attempting to load font: \$path');
        final font = pw.Font.ttf(data);
        print('Successfully loaded font: \$path');
        return font;
      } catch (e) {
        print('Error loading font \$path: \$e');
        return null;
      }
    }""";

  if (content.contains(oldFontLoading)) {
    content = content.replaceAll(oldFontLoading, newFontLoading);
    contentChanged = true;
    print('تم إصلاح طريقة تحميل الخطوط');
  }

  // 2. إضافة تسلسل خطوط أكثر ومحاولة خطوط متعددة
  final List<String> fontCandidates = [
    "assets/fonts/NotoSansArabic-Regular.ttf",
    "assets/fonts/Amiri-Regular.ttf",
    "assets/fonts/Cairo-Regular.ttf",
    "assets/fonts/Beiruti-VariableFont_wght.ttf",
  ];

  final List<String> boldCandidates = [
    "assets/fonts/Amiri-Bold.ttf",
    "assets/fonts/Cairo-Bold.ttf",
    "assets/fonts/Cairo-SemiBold.ttf",
    "assets/fonts/NotoSansArabic-Regular.ttf",
  ];

  // تجميع سلسلة الخطوط للتحديث
  String fontCandidatesStr = fontCandidates
      .map((font) => "      '$font',")
      .join('\n');
  String boldCandidatesStr = boldCandidates
      .map((font) => "      '$font',")
      .join('\n');

  final String newFontCandidatesCode =
      """
    // ترتيب التفضيل
    final regularCandidates = [
$fontCandidatesStr
    ];
    final boldCandidates = [
$boldCandidatesStr
    ];""";

  // البحث عن نمط كود قائمة الخطوط الحالية وتحديثه
  final RegExp fontCandidatesRegex = RegExp(
    r"// ترتيب التفضيل.*?final boldCandidates = \[\s*[^\]]*\s*\];",
    dotAll: true,
  );

  if (fontCandidatesRegex.hasMatch(content)) {
    content = content.replaceAllMapped(
      fontCandidatesRegex,
      (match) => newFontCandidatesCode,
    );
    contentChanged = true;
    print('تم تحديث قائمة الخطوط المستخدمة');
  }

  // 3. تحسين معالجة الأخطاء وإضافة المزيد من رسائل التشخيص
  if (contentChanged) {
    file.writeAsStringSync(content);
    print('تم حفظ التغييرات بنجاح!');
    print('يرجى إعادة تشغيل التطبيق لتطبيق الإصلاحات.');
  } else {
    print('لم يتم إجراء أي تغييرات: ربما تم إصلاح الملف بالفعل.');
  }
}
