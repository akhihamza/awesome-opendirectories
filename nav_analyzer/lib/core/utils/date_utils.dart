import 'package:intl/intl.dart';

/// Utility functions for date parsing and formatting.
class AppDateUtils {
  AppDateUtils._();

  static final List<DateFormat> _formats = [
    DateFormat('dd-MMM-yyyy'),
    DateFormat('dd/MM/yyyy'),
    DateFormat('yyyy-MM-dd'),
    DateFormat('MM/dd/yyyy'),
    DateFormat('dd-MM-yyyy'),
    DateFormat('d-MMM-yyyy'),
    DateFormat('dd MMM yyyy'),
    DateFormat('d MMM yyyy'),
    DateFormat('yyyy/MM/dd'),
    DateFormat('MMM dd, yyyy'),
  ];

  /// Try to parse a date string using multiple formats.
  /// Returns null if no format matches.
  static DateTime? tryParse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // Try ISO format first
    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return iso;

    for (final fmt in _formats) {
      try {
        return fmt.parseStrict(trimmed);
      } catch (_) {
        // Try next format
      }
    }

    // Try parsing Excel serial date number
    final serial = double.tryParse(trimmed);
    if (serial != null && serial > 30000 && serial < 60000) {
      return _excelSerialToDate(serial.toInt());
    }

    return null;
  }

  /// Parse or throw.
  static DateTime parse(String input) {
    final result = tryParse(input);
    if (result == null) {
      throw FormatException('Cannot parse date: "$input"');
    }
    return result;
  }

  /// Convert Excel serial date number to DateTime.
  static DateTime _excelSerialToDate(int serial) {
    // Excel epoch is 1899-12-30 (accounting for the 1900 leap year bug)
    final base = DateTime(1899, 12, 30);
    return base.add(Duration(days: serial));
  }

  /// Format date for display.
  static String format(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Format date as short month-year.
  static String formatMonthYear(DateTime date) {
    return DateFormat('MMM yyyy').format(date);
  }

  /// Get the last day of a month.
  static DateTime endOfMonth(int year, int month) {
    return DateTime(year, month + 1, 0);
  }

  /// Check if two dates are in the same month.
  static bool sameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  /// Get DateTime with only date part (no time).
  static DateTime dateOnly(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }
}
