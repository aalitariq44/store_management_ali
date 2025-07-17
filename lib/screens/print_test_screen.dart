import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/pdf_service.dart';
import 'models/person_model.dart';
import 'models/debt_model.dart';
import 'models/installment_model.dart';
import 'models/internet_model.dart';

class PrintTestScreen extends StatelessWidget {
  const PrintTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار نظام الطباعة العربية'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.print, size: 48, color: Colors.blue),
                    SizedBox(height: 16),
                    Text(
                      'اختبار نظام الطباعة العربية',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'هذا الاختبار سيقوم بإنشاء تقرير PDF باللغة العربية لاختبار الخطوط',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _testPrint(context),
              icon: const Icon(Icons.print),
              label: const Text('اختبار طباعة تقرير تجريبي'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _testFontLoading(context),
              icon: const Icon(Icons.font_download),
              label: const Text('اختبار تحميل الخطوط العربية'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _testPrint(BuildContext context) async {
    try {
      // إظهار رسالة التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('جاري إنشاء التقرير التجريبي...'),
            ],
          ),
        ),
      );

      // إنشاء بيانات تجريبية
      final testPerson = Person(
        id: 1,
        name: 'أحمد محمد الجاسم',
        phone: '07901234567',
        address: 'بغداد - الكرادة - شارع التجارة',
        notes: 'زبون مميز',
        createdAt: DateTime.now(),
      );

      final testDebts = [
        Debt(
          id: 1,
          personId: 1,
          title: 'دين شراء بضائع',
          amount: 1500000,
          paidAmount: 500000,
          remainingAmount: 1000000,
          isPaid: false,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        Debt(
          id: 2,
          personId: 1,
          title: 'دين خدمات',
          amount: 750000,
          paidAmount: 750000,
          remainingAmount: 0,
          isPaid: true,
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
        ),
      ];

      final testInstallments = [
        Installment(
          id: 1,
          personId: 1,
          productName: 'جهاز كمبيوتر محمول',
          totalAmount: 2000000,
          paidAmount: 800000,
          remainingAmount: 1200000,
          isCompleted: false,
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
        ),
      ];

      final testInternet = [
        InternetSubscription(
          id: 1,
          personId: 1,
          packageName: 'باقة الإنترنت الذهبية',
          price: 100000,
          paidAmount: 100000,
          remainingAmount: 0,
          isActive: true,
          expiryDate: DateTime.now().add(const Duration(days: 30)),
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ];

      // طباعة التقرير
      await PDFService.printCustomerDetails(
        person: testPerson,
        debts: testDebts,
        installments: testInstallments,
        internetSubscriptions: testInternet,
      );

      // إغلاق رسالة التحميل
      Navigator.pop(context);

      // إظهار رسالة النجاح
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إنشاء التقرير بنجاح! تحقق من نافذة الطباعة.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // إغلاق رسالة التحميل
      Navigator.pop(context);

      // إظهار رسالة الخطأ
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('خطأ في الطباعة'),
          content: Text('حدث خطأ أثناء إنشاء التقرير:\n$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('موافق'),
            ),
          ],
        ),
      );
    }
  }

  void _testFontLoading(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('جاري اختبار تحميل الخطوط...'),
            ],
          ),
        ),
      );

      // هذا سيختبر تحميل الخطوط
      // يمكنك إضافة اختبار مخصص هنا

      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('اختبار الخطوط'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('الخطوط المضافة:'),
              Text('• Amiri (عادي وعريض)'),
              Text('• Cairo (عادي وعريض)'),
              Text('• NotoSansArabic'),
              SizedBox(height: 16),
              Text('يتم تحميل الخطوط تلقائياً عند الطباعة'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('موافق'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('خطأ في اختبار الخطوط'),
          content: Text('حدث خطأ: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('موافق'),
            ),
          ],
        ),
      );
    }
  }
}
