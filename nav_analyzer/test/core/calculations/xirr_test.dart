import 'package:flutter_test/flutter_test.dart';
import 'package:nav_analyzer/core/calculations/xirr.dart';

void main() {
  group('XirrCalculator', () {
    test('returns null for empty cash flows', () {
      expect(XirrCalculator.calculate([]), isNull);
    });

    test('returns null for single cash flow', () {
      expect(
        XirrCalculator.calculate([
          CashFlow(date: DateTime(2023, 1, 1), amount: -1000),
        ]),
        isNull,
      );
    });

    test('returns null when all cash flows are positive', () {
      expect(
        XirrCalculator.calculate([
          CashFlow(date: DateTime(2023, 1, 1), amount: 1000),
          CashFlow(date: DateTime(2024, 1, 1), amount: 1100),
        ]),
        isNull,
      );
    });

    test('calculates simple investment correctly', () {
      final result = XirrCalculator.calculate([
        CashFlow(date: DateTime(2023, 1, 1), amount: -10000),
        CashFlow(date: DateTime(2024, 1, 1), amount: 11000),
      ]);

      expect(result, isNotNull);
      // Should be approximately 10%
      expect(result!, closeTo(0.10, 0.01));
    });

    test('calculates multiple investments correctly', () {
      final result = XirrCalculator.calculate([
        CashFlow(date: DateTime(2023, 1, 1), amount: -10000),
        CashFlow(date: DateTime(2023, 7, 1), amount: -5000),
        CashFlow(date: DateTime(2024, 1, 1), amount: 16500),
      ]);

      expect(result, isNotNull);
      // Positive return
      expect(result!, greaterThan(0));
    });

    test('handles negative returns', () {
      final result = XirrCalculator.calculate([
        CashFlow(date: DateTime(2023, 1, 1), amount: -10000),
        CashFlow(date: DateTime(2024, 1, 1), amount: 9000),
      ]);

      expect(result, isNotNull);
      expect(result!, closeTo(-0.10, 0.01));
    });

    test('handles SIP-like cash flows', () {
      final cashFlows = <CashFlow>[];
      // Monthly SIP of 5000 for 12 months
      for (int i = 0; i < 12; i++) {
        cashFlows.add(CashFlow(
          date: DateTime(2023, 1 + i, 1),
          amount: -5000,
        ));
      }
      // Final value after 1 year
      cashFlows.add(CashFlow(
        date: DateTime(2024, 1, 1),
        amount: 65000, // ~8% growth on SIP
      ));

      final result = XirrCalculator.calculate(cashFlows);
      expect(result, isNotNull);
      expect(result!, greaterThan(0));
    });
  });
}
