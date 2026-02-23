import 'dart:isolate';

import '../../core/calculations/nav_calculator.dart';
import '../../core/models/analysis_result.dart';
import '../../core/models/nav_entry.dart';
import '../../core/models/transaction_entry.dart';

/// Use case for performing fund analysis.
///
/// Encapsulates the analysis logic and runs it in an isolate.
class AnalyzeFundUseCase {
  /// Execute the analysis.
  Future<AnalysisResult> execute({
    required String fundName,
    required List<NavEntry> navHistory,
    required List<TransactionEntry> transactions,
    required double outlierK,
    required bool filterOutliers,
    int? lastNMonths,
  }) async {
    // Run computation in isolate to avoid UI freeze
    return Isolate.run(() => NavCalculator.analyze(
          fundName: fundName,
          navHistory: navHistory,
          transactions: transactions,
          outlierK: outlierK,
          filterOutliers: filterOutliers,
          lastNMonths: lastNMonths,
        ));
  }
}
