import 'package:intl/intl.dart';

class NumberFormatter {
  static String format(double number) {
    // First, format the number to ensure it has a thousands separator and up to 2 decimal places.
    final format = NumberFormat("#,##0.00", "en_US");
    String formatted = format.format(number);

    // Then, remove any trailing zeros and the decimal point if it's not needed.
    if (formatted.contains('.')) {
      // Remove trailing zeros from the fractional part.
      while (formatted.endsWith('0')) {
        formatted = formatted.substring(0, formatted.length - 1);
      }
      // If the last character is a decimal point, remove it as well.
      if (formatted.endsWith('.')) {
        formatted = formatted.substring(0, formatted.length - 1);
      }
    }

    return formatted;
  }
}
