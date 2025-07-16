import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/database_helper.dart';
import '../config/supabase_config.dart';

class BackupService {
  static const String _backupFileName = 'store_backup.json';
  
  /// إنشاء نسخة احتياطية من قاعدة البيانات
  static Future<Map<String, dynamic>> createBackup() async {
    final db = await DatabaseHelper.instance.database;
    
    // جلب البيانات من كل جدول
    final persons = await db.query('persons');
    final debts = await db.query('debts');
    final installments = await db.query('installments');
    final internetSubscriptions = await db.query('internet_subscriptions');
    
    // إنشاء الهيكل الخاص بالنسخة الاحتياطية
    final backupData = {
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0.0',
      'data': {
        'persons': persons,
        'debts': debts,
        'installments': installments,
        'internet_subscriptions': internetSubscriptions,
      }
    };
    
    return backupData;
  }

  /// رفع النسخة الاحتياطية إلى Supabase
  static Future<bool> uploadBackup() async {
    try {
      // إنشاء النسخة الاحتياطية
      final backupData = await createBackup();
      
      // تحويل البيانات إلى JSON
      final jsonString = jsonEncode(backupData);
      final bytes = utf8.encode(jsonString);
      
      // إنشاء اسم الملف مع الطابع الزمني
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'backup_$timestamp.json';
      
      // رفع الملف إلى Supabase Storage
      final response = await Supabase.instance.client.storage
          .from(SupabaseConfig.bucketName)
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'application/json',
              upsert: true,
            ),
          );
      
      return true;
    } catch (e) {
      print('خطأ في رفع النسخة الاحتياطية: $e');
      return false;
    }
  }

  /// جلب قائمة النسخ الاحتياطية المتاحة
  static Future<List<FileObject>> getBackupFiles() async {
    try {
      final response = await Supabase.instance.client.storage
          .from(SupabaseConfig.bucketName)
          .list();
      
      // تصفية ملفات النسخ الاحتياطية فقط
      return response.where((file) => file.name.startsWith('backup_')).toList();
    } catch (e) {
      print('خطأ في جلب قائمة النسخ الاحتياطية: $e');
      return [];
    }
  }

  /// تحميل واستعادة نسخة احتياطية
  static Future<bool> restoreBackup(String fileName) async {
    try {
      // تحميل الملف من Supabase
      final response = await Supabase.instance.client.storage
          .from(SupabaseConfig.bucketName)
          .download(fileName);
      
      // تحويل البيانات من JSON
      final jsonString = utf8.decode(response);
      final backupData = jsonDecode(jsonString);
      
      // استعادة البيانات إلى قاعدة البيانات
      await _restoreFromBackupData(backupData);
      
      return true;
    } catch (e) {
      print('خطأ في استعادة النسخة الاحتياطية: $e');
      return false;
    }
  }

  /// استعادة البيانات من النسخة الاحتياطية
  static Future<void> _restoreFromBackupData(Map<String, dynamic> backupData) async {
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

  /// حذف نسخة احتياطية
  static Future<bool> deleteBackup(String fileName) async {
    try {
      await Supabase.instance.client.storage
          .from(SupabaseConfig.bucketName)
          .remove([fileName]);
      
      return true;
    } catch (e) {
      print('خطأ في حذف النسخة الاحتياطية: $e');
      return false;
    }
  }

  /// تنظيف النسخ الاحتياطية القديمة (الاحتفاظ بآخر 10 نسخ)
  static Future<void> cleanupOldBackups() async {
    try {
      final backupFiles = await getBackupFiles();
      
      if (backupFiles.length > 10) {
        // ترتيب الملفات حسب تاريخ الإنشاء
        backupFiles.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
        
        // حذف الملفات القديمة
        final filesToDelete = backupFiles.skip(10).toList();
        for (final file in filesToDelete) {
          await deleteBackup(file.name);
        }
      }
    } catch (e) {
      print('خطأ في تنظيف النسخ الاحتياطية القديمة: $e');
    }
  }
}
