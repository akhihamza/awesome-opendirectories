import 'package:intl/intl.dart';

/// Utility functions for number parsing and formatting.
class NumberUtils {
  NumberUtils._();

  /// Parse a number string that may contain commas and spaces.
  /// Returns null if parsing fails.
  static double? tryParse(String input) {
    if (input.trim().isEmpty) return null;

    // Remove commas, spaces, and currency symbols
    String cleaned = input.trim();
    cleaned = cleaned.replaceAll(RegExp(r'[,\s]'), '');
    cleaned = cleaned.replaceAll(RegExp(r'(PKR|Rs\.?|USD|\$)'), '');
    cleaned = cleaned.trim();

    // Handle parentheses for negative numbers
    if (cleaned.startsWith('(') && cleaned.endsWith(')')) {
      cleaned = '-${cleaned.substring(1, cleaned.length - 1)}';
    }

    return double.tryParse(cleaned);
  }

  /// Parse or throw.
  static double parse(String input) {
    final result = tryParse(input);
    if (result == null) {
      throw FormatException('Cannot parse number: "$input"');
    }
    return result;
  }

  /// Format currency with commas and 2 decimal places.
  static String formatCurrency(double value, {String symbol = 'PKR'}) {
    final fmt = NumberFormat('#,##0.00');
    final sign = value < 0 ? '-' : '';
    return '$sign$symbol ${fmt.format(value.abs())}';
  }

  /// Format number with commas.
  static String formatNumber(double value, {int decimals = 2}) {
    final fmt = NumberFormat('#,##0.${'0' * decimals}');
    return fmt.format(value);
  }

  /// Format percentage.
  static String formatPercent(double value, {int decimals = 2}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  /// Format units (4 decimal places).
  static String formatUnits(double value) {
    return NumberFormat('#,##0.0000').format(value);
  }
}
