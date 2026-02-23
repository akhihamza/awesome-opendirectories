import '../models/nav_entry.dart';

/// IQR-based outlier filter for NAV data.
class OutlierFilter {
  OutlierFilter._();

  /// Filter NAV entries using IQR method.
  ///
  /// [k] is the IQR multiplier (typically 1.5 for mild outliers, 3.0 for extreme).
  /// Returns filtered list with outliers removed.
  static List<NavEntry> filter(List<NavEntry> entries, {double k = 1.5}) {
    if (entries.length < 4) return List.from(entries);

    final navValues = entries.map((e) => e.nav).toList()..sort();
    final n = navValues.length;

    final q1 = _percentile(navValues, 0.25);
    final q3 = _percentile(navValues, 0.75);
    final iqr = q3 - q1;

    final lowerBound = q1 - k * iqr;
    final upperBound = q3 + k * iqr;

    return entries
        .where((e) => e.nav >= lowerBound && e.nav <= upperBound)
        .toList();
  }

  /// Calculate percentile using linear interpolation.
  static double _percentile(List<double> sorted, double p) {
    final n = sorted.length;
    final index = p * (n - 1);
    final lower = index.floor();
    final upper = index.ceil();

    if (lower == upper) return sorted[lower];

    final fraction = index - lower;
    return sorted[lower] * (1 - fraction) + sorted[upper] * fraction;
  }

  /// Get the outlier bounds for display purposes.
  static ({double lower, double upper}) getBounds(
      List<NavEntry> entries, double k) {
    final navValues = entries.map((e) => e.nav).toList()..sort();

    final q1 = _percentile(navValues, 0.25);
    final q3 = _percentile(navValues, 0.75);
    final iqr = q3 - q1;

    return (lower: q1 - k * iqr, upper: q3 + k * iqr);
  }
}
