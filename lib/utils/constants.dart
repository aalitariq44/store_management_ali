class AppConstants {
  static const String appName = 'إدارة المحل';
  static const String appVersion = '1.0.0';
  
  // رسائل النسخ الاحتياطي
  static const String backupCreated = 'تم إنشاء النسخة الاحتياطية بنجاح';
  static const String backupFailed = 'فشل في إنشاء النسخة الاحتياطية';
  static const String backupRestored = 'تم استعادة النسخة الاحتياطية بنجاح';
  static const String backupRestoreFailed = 'فشل في استعادة النسخة الاحتياطية';
  static const String backupDeleted = 'تم حذف النسخة الاحتياطية بنجاح';
  static const String backupDeleteFailed = 'فشل في حذف النسخة الاحتياطية';
  static const String noBackupsFound = 'لا توجد نسخ احتياطية';
  
  // رسائل التأكيد
  static const String confirmRestore = 'هل أنت متأكد من أنك تريد استعادة هذه النسخة الاحتياطية؟\nسيتم حذف جميع البيانات الحالية.';
  static const String confirmDelete = 'هل أنت متأكد من أنك تريد حذف هذه النسخة الاحتياطية؟';
  
  // عناوين الأزرار
  static const String confirm = 'تأكيد';
  static const String cancel = 'إلغاء';
  static const String backup = 'نسخة احتياطية';
  static const String restore = 'استعادة';
  static const String delete = 'حذف';
  static const String refresh = 'تحديث';
  
  // رسائل التحميل
  static const String creatingBackup = 'جاري إنشاء النسخة الاحتياطية...';
  static const String restoringBackup = 'جاري استعادة النسخة الاحتياطية...';
  static const String deletingBackup = 'جاري حذف النسخة الاحتياطية...';
  static const String loadingBackups = 'جاري تحميل النسخ الاحتياطية...';
}
