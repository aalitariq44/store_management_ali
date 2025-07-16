import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../config/database_helper.dart';
import '../utils/file_helper.dart';

class ExportImportHelper {
  /// تصدير البيانات إلى ملف JSON محلي
  static Future<bool> exportToJsonFile(String filePath) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // جلب البيانات من كل جدول
      final persons = await db.query('persons');
      final debts = await db.query('debts');
      final installments = await db.query('installments');
      final internetSubscriptions = await db.query('internet_subscriptions');
      
      // إنشاء هيكل البيانات
      final data = {
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'data': {
          'persons': persons,
          'debts': debts,
          'installments': installments,
          'internet_subscriptions': internetSubscriptions,
        }
      };
      
      // تحويل إلى JSON وحفظ في الملف
      final jsonString = jsonEncode(data);
      final file = File(filePath);
      await file.writeAsString(jsonString);
      
      return true;
    } catch (e) {
      print('خطأ في تصدير البيانات: $e');
      return false;
    }
  }

  /// استيراد البيانات من ملف JSON محلي
  static Future<bool> importFromJsonFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('الملف غير موجود: $filePath');
        return false;
      }
      
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString);
      
      // استعادة البيانات إلى قاعدة البيانات
      await _restoreFromData(data);
      
      return true;
    } catch (e) {
      print('خطأ في استيراد البيانات: $e');
      return false;
    }
  }

  /// تصدير البيانات إلى ملف CSV
  static Future<bool> exportToCSV(String tableName, String filePath) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final data = await db.query(tableName);
      
      if (data.isEmpty) {
        print('لا توجد بيانات للتصدير');
        return false;
      }
      
      // إنشاء محتوى CSV
      final headers = data.first.keys.toList();
      final csvContent = StringBuffer();
      
      // إضافة العناوين
      csvContent.writeln(headers.join(','));
      
      // إضافة البيانات
      for (final row in data) {
        final values = headers.map((header) => row[header]?.toString() ?? '').toList();
        csvContent.writeln(values.join(','));
      }
      
      // حفظ الملف
      final file = File(filePath);
      await file.writeAsString(csvContent.toString());
      
      return true;
    } catch (e) {
      print('خطأ في تصدير CSV: $e');
      return false;
    }
  }

  /// إنشاء نسخة احتياطية محلية
  static Future<bool> createLocalBackup({String? customPath}) async {
    try {
      final backupDir = customPath ?? path.join(
        FileHelper.getAppDataPath(),
        'backups'
      );
      
      await FileHelper.createDirectoryIfNotExists(backupDir);
      
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupPath = path.join(backupDir, 'backup_$timestamp.json');
      
      return await exportToJsonFile(backupPath);
    } catch (e) {
      print('خطأ في إنشاء النسخة الاحتياطية المحلية: $e');
      return false;
    }
  }

  /// استعادة نسخة احتياطية محلية
  static Future<bool> restoreLocalBackup(String backupPath) async {
    try {
      return await importFromJsonFile(backupPath);
    } catch (e) {
      print('خطأ في استعادة النسخة الاحتياطية المحلية: $e');
      return false;
    }
  }

  /// الحصول على قائمة النسخ الاحتياطية المحلية
  static Future<List<FileSystemEntity>> getLocalBackups() async {
    try {
      final backupDir = path.join(
        FileHelper.getAppDataPath(),
        'backups'
      );
      
      final directory = Directory(backupDir);
      if (!await directory.exists()) {
        return [];
      }
      
      final files = await directory.list().toList();
      return files.where((file) => 
        file.path.endsWith('.json') && 
        path.basename(file.path).startsWith('backup_')
      ).toList();
    } catch (e) {
      print('خطأ في جلب قائمة النسخ الاحتياطية المحلية: $e');
      return [];
    }
  }

  /// استعادة البيانات من بنية البيانات
  static Future<void> _restoreFromData(Map<String, dynamic> backupData) async {
    final db = await DatabaseHelper.instance.database;
    
    // مسح البيانات الحالية
    await db.delete('persons');
    await db.delete('debts');
    await db.delete('installments');
    await db.delete('internet_subscriptions');
    
    // استعادة البيانات
    final data = backupData['data'];
    
    // استعادة الأشخاص
    for (final person in data['persons']) {
      await db.insert('persons', person);
    }
    
    // استعادة الديون
    for (final debt in data['debts']) {
      await db.insert('debts', debt);
    }
    
    // استعادة الأقساط
    for (final installment in data['installments']) {
      await db.insert('installments', installment);
    }
    
    // استعادة اشتراكات الإنترنت
    for (final subscription in data['internet_subscriptions']) {
      await db.insert('internet_subscriptions', subscription);
    }
  }

  /// تنظيف النسخ الاحتياطية المحلية القديمة
  static Future<void> cleanupLocalBackups({int keepCount = 5}) async {
    try {
      final backups = await getLocalBackups();
      
      if (backups.length <= keepCount) {
        return;
      }
      
      // ترتيب النسخ حسب تاريخ الإنشاء
      backups.sort((a, b) => 
        File(b.path).lastModifiedSync().compareTo(File(a.path).lastModifiedSync())
      );
      
      // حذف النسخ القديمة
      final filesToDelete = backups.skip(keepCount).toList();
      for (final file in filesToDelete) {
        await file.delete();
      }
    } catch (e) {
      print('خطأ في تنظيف النسخ الاحتياطية المحلية: $e');
    }
  }
}
