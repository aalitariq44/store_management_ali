import '../config/database_helper.dart';

class DatabaseMigrationHelper {
  /// يقوم بترقية قاعدة البيانات لتحويل كلمات المرور من مشفرة إلى عادية
  /// ملاحظة: هذا سيحذف كلمات المرور الموجودة ويتطلب إعادة تعيينها
  static Future<bool> migratePasswordToPlainText() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // التحقق من وجود الجدول القديم
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='app_password'",
      );

      if (tables.isEmpty) {
        // الجدول غير موجود، لا حاجة للترقية
        return true;
      }

      // التحقق من البنية الحالية للجدول
      final columns = await db.rawQuery("PRAGMA table_info(app_password)");
      bool hasHashedPasswordColumn = false;
      bool hasPasswordColumn = false;

      for (var column in columns) {
        final columnName = column['name'] as String;
        if (columnName == 'hashed_password') {
          hasHashedPasswordColumn = true;
        } else if (columnName == 'password') {
          hasPasswordColumn = true;
        }
      }

      // إذا كان الجدول يحتوي على العمود القديم فقط
      if (hasHashedPasswordColumn && !hasPasswordColumn) {
        print('بدء ترقية قاعدة البيانات...');

        // إنشاء جدول جديد بالبنية الجديدة
        await db.execute('''
          CREATE TABLE app_password_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            password TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');

        // حذف الجدول القديم
        await db.execute('DROP TABLE app_password');

        // إعادة تسمية الجدول الجديد
        await db.execute('ALTER TABLE app_password_new RENAME TO app_password');

        print('تمت ترقية قاعدة البيانات بنجاح. يجب إعادة تعيين كلمة المرور.');
        return true;
      }

      // إذا كان الجدول محدث بالفعل
      if (hasPasswordColumn && !hasHashedPasswordColumn) {
        print('قاعدة البيانات محدثة بالفعل.');
        return true;
      }

      return true;
    } catch (e) {
      print('خطأ في ترقية قاعدة البيانات: $e');
      return false;
    }
  }

  /// يتحقق من حالة قاعدة البيانات
  static Future<Map<String, dynamic>> checkDatabaseStatus() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // التحقق من وجود الجدول
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='app_password'",
      );

      if (tables.isEmpty) {
        return {
          'tableExists': false,
          'needsMigration': false,
          'isUpToDate': true,
        };
      }

      // التحقق من البنية
      final columns = await db.rawQuery("PRAGMA table_info(app_password)");
      bool hasHashedPasswordColumn = false;
      bool hasPasswordColumn = false;

      for (var column in columns) {
        final columnName = column['name'] as String;
        if (columnName == 'hashed_password') {
          hasHashedPasswordColumn = true;
        } else if (columnName == 'password') {
          hasPasswordColumn = true;
        }
      }

      return {
        'tableExists': true,
        'hasHashedPasswordColumn': hasHashedPasswordColumn,
        'hasPasswordColumn': hasPasswordColumn,
        'needsMigration': hasHashedPasswordColumn && !hasPasswordColumn,
        'isUpToDate': hasPasswordColumn && !hasHashedPasswordColumn,
      };
    } catch (e) {
      print('خطأ في فحص قاعدة البيانات: $e');
      return {'error': true, 'message': e.toString()};
    }
  }
}
