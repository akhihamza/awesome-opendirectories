import 'dart:math';

/// A single cash flow for XIRR calculation.
class CashFlow {
  final DateTime date;
  final double amount;

  const CashFlow({required this.date, required this.amount});

  @override
  String toString() => 'CashFlow($date, $amount)';
}

/// XIRR (Extended Internal Rate of Return) calculator.
///
/// Implements Newton-Raphson with bisection fallback for
/// money-weighted return computation.
class XirrCalculator {
  XirrCalculator._();

  static const int _maxIterations = 1000;
  static const double _tolerance = 1e-10;
  static const double _dayFraction = 365.0;

  /// Calculate XIRR for a series of cash flows.
  ///
  /// Cash flows should be negative for investments (outflows)
  /// and positive for returns (inflows).
  ///
  /// Returns the annualized rate as a decimal (e.g., 0.12 for 12%).
  /// Returns null if calculation fails to converge.
  static double? calculate(List<CashFlow> cashFlows) {
    if (cashFlows.isEmpty) return null;
    if (cashFlows.length < 2) return null;

    // Must have at least one positive and one negative cash flow
    final hasPositive = cashFlows.any((cf) => cf.amount > 0);
    final hasNegative = cashFlows.any((cf) => cf.amount < 0);
    if (!hasPositive || !hasNegative) return null;

    // Sort by date
    final sorted = List<CashFlow>.from(cashFlows)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Try Newton-Raphson first
    final newtonResult = _newtonRaphson(sorted);
    if (newtonResult != null) return newtonResult;

    // Fall back to bisection method
    return _bisection(sorted);
  }

  /// Newton-Raphson method for XIRR.
  static double? _newtonRaphson(List<CashFlow> cashFlows) {
    double rate = 0.1; // Initial guess of 10%

    for (int i = 0; i < _maxIterations; i++) {
      final fValue = _npv(cashFlows, rate);
      final fDerivative = _npvDerivative(cashFlows, rate);

      if (fDerivative.abs() < _tolerance) {
        // Derivative too small, try different starting point
        rate = rate + 0.1;
        if (rate > 10.0) return null;
        continue;
      }

      final newRate = rate - fValue / fDerivative;

      // Check convergence
      if ((newRate - rate).abs() < _tolerance) {
        // Validate the result is reasonable (-99% to 10000%)
        if (newRate > -0.99 && newRate < 100.0) {
          return newRate;
        }
        return null;
      }

      // Prevent rate from going below -100%
      rate = max(newRate, -0.99);
    }

    return null;
  }

  /// Bisection method as fallback.
  static double? _bisection(List<CashFlow> cashFlows) {
    double low = -0.99;
    double high = 10.0;

    final fLow = _npv(cashFlows, low);
    final fHigh = _npv(cashFlows, high);

    // Check if solution exists in range
    if (fLow * fHigh > 0) {
      // Try expanding range
      high = 100.0;
      final fHighExpanded = _npv(cashFlows, high);
      if (fLow * fHighExpanded > 0) return null;
    }

    for (int i = 0; i < _maxIterations; i++) {
      final mid = (low + high) / 2;
      final fMid = _npv(cashFlows, mid);

      if (fMid.abs() < _tolerance || (high - low) / 2 < _tolerance) {
        return mid;
      }

      final fLowCurrent = _npv(cashFlows, low);
      if (fLowCurrent * fMid < 0) {
        high = mid;
      } else {
        low = mid;
      }
    }

    // Return best estimate even if not fully converged
    final mid = (low + high) / 2;
    if (_npv(cashFlows, mid).abs() < 0.01) {
      return mid;
    }

    return null;
  }

  /// Calculate NPV for a given rate.
  static double _npv(List<CashFlow> cashFlows, double rate) {
    final baseDate = cashFlows.first.date;
    double npv = 0;

    for (final cf in cashFlows) {
      final years = cf.date.difference(baseDate).inDays / _dayFraction;
      npv += cf.amount / pow(1 + rate, years);
    }

    return npv;
  }

  /// Calculate NPV derivative for Newton-Raphson.
  static double _npvDerivative(List<CashFlow> cashFlows, double rate) {
    final baseDate = cashFlows.first.date;
    double derivative = 0;

    for (final cf in cashFlows) {
      final years = cf.date.difference(baseDate).inDays / _dayFraction;
      if (years == 0) continue;
      derivative -= years * cf.amount / pow(1 + rate, years + 1);
    }

    return derivative;
  }
}
