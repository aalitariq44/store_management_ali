import 'package:intl/intl.dart';

class NumberFormatter {
  static String format(double number) {
    final format = NumberFormat("#,##0.##", "en_US");
    return format.format(number);
  }
}
