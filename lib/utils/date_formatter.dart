import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');
  static final DateFormat _displayDateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _displayDateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  static String formatTime(DateTime time) {
    return _timeFormat.format(time);
  }

  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }

  static String formatDisplayDate(DateTime date) {
    return _displayDateFormat.format(date);
  }

  static String formatDisplayDateTime(DateTime dateTime) {
    return _displayDateTimeFormat.format(dateTime);
  }

  static DateTime parseDate(String dateString) {
    return _dateFormat.parse(dateString);
  }

  static DateTime parseDateTime(String dateTimeString) {
    return _dateTimeFormat.parse(dateTimeString);
  }

  static String formatDateRange(DateTime startDate, DateTime endDate) {
    return '${formatDisplayDate(startDate)} - ${formatDisplayDate(endDate)}';
  }

  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} يوم${difference.inDays > 1 ? '' : ''}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ساعة${difference.inHours > 1 ? '' : ''}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} دقيقة${difference.inMinutes > 1 ? '' : ''}';
    } else {
      return 'الآن';
    }
  }

  static String getDaysUntil(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays} يوم${difference.inDays > 1 ? '' : ''}';
    } else if (difference.inDays == 0) {
      return 'اليوم';
    } else {
      return 'منتهي الصلاحية';
    }
  }

  static bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  static bool isYesterday(DateTime dateTime) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day;
  }

  static bool isTomorrow(DateTime dateTime) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return dateTime.year == tomorrow.year &&
        dateTime.month == tomorrow.month &&
        dateTime.day == tomorrow.day;
  }

  static String getRelativeDate(DateTime dateTime) {
    if (isToday(dateTime)) {
      return 'اليوم';
    } else if (isYesterday(dateTime)) {
      return 'أمس';
    } else if (isTomorrow(dateTime)) {
      return 'غداً';
    } else {
      return formatDisplayDate(dateTime);
    }
  }
}
