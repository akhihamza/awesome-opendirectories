import 'package:flutter_test/flutter_test.dart';
import 'package:nav_analyzer/core/utils/date_utils.dart';

void main() {
  group('AppDateUtils', () {
    test('parses dd-MMM-yyyy format', () {
      final date = AppDateUtils.tryParse('15-Jan-2023');
      expect(date, isNotNull);
      expect(date!.day, equals(15));
      expect(date.month, equals(1));
      expect(date.year, equals(2023));
    });

    test('parses dd/MM/yyyy format', () {
      final date = AppDateUtils.tryParse('15/01/2023');
      expect(date, isNotNull);
      expect(date!.day, equals(15));
      expect(date.month, equals(1));
      expect(date.year, equals(2023));
    });

    test('parses ISO format', () {
      final date = AppDateUtils.tryParse('2023-01-15');
      expect(date, isNotNull);
      expect(date!.year, equals(2023));
    });

    test('returns null for invalid input', () {
      expect(AppDateUtils.tryParse(''), isNull);
      expect(AppDateUtils.tryParse('not a date'), isNull);
    });

    test('format returns expected string', () {
      final formatted = AppDateUtils.format(DateTime(2023, 1, 15));
      expect(formatted, equals('15 Jan 2023'));
    });

    test('sameMonth returns true for same month', () {
      expect(
        AppDateUtils.sameMonth(DateTime(2023, 3, 1), DateTime(2023, 3, 28)),
        isTrue,
      );
    });

    test('sameMonth returns false for different months', () {
      expect(
        AppDateUtils.sameMonth(DateTime(2023, 3, 1), DateTime(2023, 4, 1)),
        isFalse,
      );
    });
  });
}
