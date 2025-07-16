import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/database_helper.dart';
import '../config/supabase_config.dart';

class BackupService {
  
  /// رفع النسخة الاحتياطية إلى Supabase
  static Future<bool> uploadBackup() async {
    try {
      // الحصول على مسار قاعدة البيانات
      final db = await DatabaseHelper.instance.database;
      final dbPath = db.path;
      
      // قراءة ملف قاعدة البيانات
      final dbFile = File(dbPath);
      final bytes = await dbFile.readAsBytes();
      
      // إنشاء اسم الملف مع الطابع الزمني
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'backup_$timestamp.db';
      
      // رفع قاعدة البيانات إلى Supabase Storage
      await Supabase.instance.client.storage
          .from(SupabaseConfig.bucketName)
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'application/octet-stream',
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
      return response.where((file) => file.name.startsWith('backup_') && file.name.endsWith('.db')).toList();
    } catch (e) {
      print('خطأ في جلب قائمة النسخ الاحتياطية: $e');
      return [];
    }
  }

  /// تحميل واستعادة نسخة احتياطية
  static Future<bool> restoreBackup(String fileName) async {
    try {
      // تحميل ملف قاعدة البيانات من Supabase
      final response = await Supabase.instance.client.storage
          .from(SupabaseConfig.bucketName)
          .download(fileName);
      
      // إغلاق قاعدة البيانات الحالية
      final db = await DatabaseHelper.instance.database;
      await db.close();
      
      // استبدال ملف قاعدة البيانات الحالي بالملف المستعاد
      final dbPath = db.path;
      final dbFile = File(dbPath);
      await dbFile.writeAsBytes(response);
      
      // إعادة تعيين متغير قاعدة البيانات لإعادة فتحها
      DatabaseHelper.instance.resetDatabase();
      
      return true;
    } catch (e) {
      print('خطأ في استعادة النسخة الاحتياطية: $e');
      return false;
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
