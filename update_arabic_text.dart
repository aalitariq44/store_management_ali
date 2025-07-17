import 'dart:io';

void main() {
  final file = File('lib/services/pdf_service.dart');
  String content = file.readAsStringSync();
  
  // قائمة التحديثات المطلوبة
  final replacements = {
    // تحديث TextStyle للنصوص العادية
    "style: pw.TextStyle(fontSize: 12)": "style: _arabicTextStyle(fontSize: 12), textDirection: pw.TextDirection.rtl",
    "style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)": "style: _arabicTextStyle(fontSize: 12, isBold: true), textDirection: pw.TextDirection.rtl",
    "style: pw.TextStyle(fontSize: 14)": "style: _arabicTextStyle(fontSize: 14), textDirection: pw.TextDirection.rtl",
    "style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)": "style: _arabicTextStyle(fontSize: 14, isBold: true), textDirection: pw.TextDirection.rtl",
    
    // تحديث عناوين الأقسام
    '''pw.Text(
            'ملخص الأقساط',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),''': '''pw.Text(
            'ملخص الأقساط',
            style: _arabicTextStyle(
              fontSize: 16,
              isBold: true,
              color: PdfColors.blue800,
            ),
            textDirection: pw.TextDirection.rtl,
          ),''',
          
    '''pw.Text(
            'ملخص اشتراكات الإنترنت',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
            ),
          ),''': '''pw.Text(
            'ملخص اشتراكات الإنترنت',
            style: _arabicTextStyle(
              fontSize: 16,
              isBold: true,
              color: PdfColors.green800,
            ),
            textDirection: pw.TextDirection.rtl,
          ),''',
  };
  
  // تطبيق جميع التحديثات
  replacements.forEach((oldText, newText) {
    content = content.replaceAll(oldText, newText);
  });
  
  // حفظ الملف
  file.writeAsStringSync(content);
  print('تم تحديث الملف بنجاح!');
}
