import 'dart:io';
import 'package:path/path.dart' as path;

class FileHelper {
  /// الحصول على مسار مجلد المستندات
  static String getDocumentsPath() {
    if (Platform.isWindows) {
      return path.join(Platform.environment['USERPROFILE']!, 'Documents');
    } else if (Platform.isLinux || Platform.isMacOS) {
      return path.join(Platform.environment['HOME']!, 'Documents');
    }
    return '';
  }

  /// الحصول على مسار مجلد التطبيق
  static String getAppDataPath() {
    if (Platform.isWindows) {
      return path.join(Platform.environment['APPDATA']!, 'StoreManagement');
    } else if (Platform.isLinux) {
      return path.join(Platform.environment['HOME']!, '.local', 'share', 'StoreManagement');
    } else if (Platform.isMacOS) {
      return path.join(Platform.environment['HOME']!, 'Library', 'Application Support', 'StoreManagement');
    }
    return '';
  }

  /// إنشاء مجلد إذا لم يكن موجوداً
  static Future<Directory> createDirectoryIfNotExists(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  /// فحص وجود ملف
  static Future<bool> fileExists(String filePath) async {
    final file = File(filePath);
    return await file.exists();
  }

  /// حذف ملف
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('خطأ في حذف الملف: $e');
      return false;
    }
  }

  /// نسخ ملف
  static Future<bool> copyFile(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      
      if (await sourceFile.exists()) {
        await sourceFile.copy(destinationPath);
        return true;
      }
      return false;
    } catch (e) {
      print('خطأ في نسخ الملف: $e');
      return false;
    }
  }

  /// الحصول على حجم الملف
  static Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      print('خطأ في الحصول على حجم الملف: $e');
      return 0;
    }
  }

  /// تنسيق حجم الملف
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// الحصول على امتداد الملف
  static String getFileExtension(String filePath) {
    return path.extension(filePath);
  }

  /// الحصول على اسم الملف بدون امتداد
  static String getFileNameWithoutExtension(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }

  /// الحصول على اسم الملف مع الامتداد
  static String getFileName(String filePath) {
    return path.basename(filePath);
  }
}
