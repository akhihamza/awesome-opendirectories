import 'package:flutter_test/flutter_test.dart';
import 'package:nav_analyzer/core/models/nav_entry.dart';
import 'package:nav_analyzer/core/utils/outlier_filter.dart';

void main() {
  group('OutlierFilter', () {
    test('returns same list for small datasets', () {
      final entries = [
        NavEntry(fundName: 'Test', date: DateTime(2023, 1, 1), nav: 10.0),
        NavEntry(fundName: 'Test', date: DateTime(2023, 1, 2), nav: 10.5),
      ];

      final result = OutlierFilter.filter(entries);
      expect(result.length, equals(2));
    });

    test('removes extreme outliers', () {
      final entries = <NavEntry>[];
      // Normal range: 10-12
      for (int i = 0; i < 100; i++) {
        entries.add(NavEntry(
          fundName: 'Test',
          date: DateTime(2023, 1, 1).add(Duration(days: i)),
          nav: 10.0 + (i % 20) * 0.1,
        ));
      }
      // Add extreme outlier
      entries.add(NavEntry(
        fundName: 'Test',
        date: DateTime(2023, 5, 1),
        nav: 100.0,
      ));

      final result = OutlierFilter.filter(entries, k: 1.5);
      expect(result.length, lessThan(entries.length));
      expect(result.every((e) => e.nav < 50), isTrue);
    });

    test('getBounds returns correct values', () {
      final entries = List.generate(
        100,
        (i) => NavEntry(
          fundName: 'Test',
          date: DateTime(2023, 1, 1).add(Duration(days: i)),
          nav: 10.0 + i * 0.1,
        ),
      );

      final bounds = OutlierFilter.getBounds(entries, 1.5);
      expect(bounds.lower, lessThan(bounds.upper));
    });
  });
}
