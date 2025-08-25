# تحديث نظام كلمة المرور - من مشفرة إلى عادية

## التغييرات المطبقة

تم تعديل نظام كلمة المرور في التطبيق ليحفظ كلمة المرور كنص عادي بدلاً من التشفير باستخدام SHA-256.

### الملفات المعدلة:

1. **`lib/models/password_model.dart`**
   - إزالة استيراد `crypto` و `dart:convert`
   - تغيير `hashedPassword` إلى `password`
   - إزالة دالة `hashPassword()`
   - تبسيط دالة `verifyPassword()` للمقارنة المباشرة

2. **`lib/config/database_helper.dart`**
   - تغيير العمود `hashed_password` إلى `password` في جدول `app_password`
   - تحديث أوامر إنشاء الجدول وترقيته

3. **`lib/providers/password_provider.dart`**
   - إزالة استخدام `PasswordModel.hashPassword()`
   - تحديث حفظ والتحقق من كلمة المرور
   - إضافة نظام ترقية قاعدة البيانات

4. **`lib/utils/database_migration_helper.dart` (جديد)**
   - أداة مساعدة لترقية قاعدة البيانات
   - تحقق من حالة قاعدة البيانات
   - ترقية من النظام القديم للجديد

## كيفية عمل النظام الجديد:

### قبل التحديث:
```dart
// كان يتم تشفير كلمة المرور
String hashedPassword = sha256.convert(utf8.encode(password)).toString();
await db.insert('app_password', {'hashed_password': hashedPassword});
```

### بعد التحديث:
```dart
// يتم حفظ كلمة المرور كما هي
await db.insert('app_password', {'password': password});
```

## الترقية التلقائية:

عند تشغيل التطبيق للمرة الأولى بعد التحديث:

1. سيتم فحص بنية قاعدة البيانات
2. إذا كانت تحتوي على العمود القديم `hashed_password`، سيتم:
   - إنشاء جدول جديد بالبنية الجديدة
   - حذف الجدول القديم
   - إعادة تسمية الجدول الجديد
3. سيتم طلب من المستخدم إعادة تعيين كلمة المرور

## ملاحظات أمنية مهمة:

⚠️ **تحذير**: تخزين كلمة المرور كنص عادي يقلل من الأمان. 

### البدائل الموصى بها:
1. **إذا كانت كلمة المرور أرقام فقط**: يمكن تخزينها كـ INTEGER
2. **لتحسين الأمان**: يمكن استخدام تشفير بسيط قابل للعكس
3. **للأمان الكامل**: العودة لاستخدام hashing مع bcrypt أو argon2

### تطبيق كلمة مرور رقمية فقط:

```dart
// في password_model.dart
static bool isValidNumericPassword(String password) {
  return RegExp(r'^\d+$').hasMatch(password);
}

// في password_settings_screen.dart
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'يرجى إدخال كلمة المرور';
  }
  if (!PasswordModel.isValidNumericPassword(value)) {
    return 'كلمة المرور يجب أن تحتوي على أرقام فقط';
  }
  return null;
},
```

## اختبار النظام الجديد:

1. تشغيل التطبيق للمرة الأولى
2. إنشاء كلمة مرور جديدة
3. التحقق من تسجيل الدخول
4. تغيير كلمة المرور
5. التأكد من حفظ كلمة المرور بالشكل الصحيح في قاعدة البيانات

## فحص قاعدة البيانات:

```dart
// للتحقق من حالة قاعدة البيانات
final status = await DatabaseMigrationHelper.checkDatabaseStatus();
print(status);
```

---

*تاريخ التحديث: 25 أغسطس 2025*
