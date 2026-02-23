import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/models/analysis_result.dart';
import '../../core/utils/number_utils.dart';

/// Use case for exporting analysis results to CSV.
class ExportCsvUseCase {
  /// Export analysis result to a CSV file.
  /// Returns the file path.
  Future<String> execute(AnalysisResult result) async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = '${result.fundName.replaceAll(' ', '_')}_$timestamp.csv';
    final filePath = '${dir.path}/$fileName';

    final rows = <List<String>>[];

    // Summary section
    rows.add(['Fund Analysis Report']);
    rows.add(['Fund', result.fundName]);
    rows.add([
      'Total Invested',
      NumberUtils.formatNumber(result.totalInvested),
    ]);
    rows.add([
      'Total Units',
      NumberUtils.formatUnits(result.totalUnits),
    ]);
    rows.add([
      'Average Cost',
      NumberUtils.formatNumber(result.averageCost),
    ]);
    rows.add([
      'Latest NAV',
      NumberUtils.formatNumber(result.latestNav, decimals: 4),
    ]);
    rows.add([
      'Portfolio Value',
      NumberUtils.formatNumber(result.portfolioValue),
    ]);
    rows.add([
      'Unrealized P/L',
      NumberUtils.formatNumber(result.unrealizedPnL),
    ]);
    rows.add([
      'P/L %',
      NumberUtils.formatPercent(result.unrealizedPnLPercent),
    ]);
    if (result.xirr != null) {
      rows.add([
        'XIRR',
        NumberUtils.formatPercent(result.xirr! * 100),
      ]);
    }
    rows.add([]);

    // Purchases section
    rows.add(['Purchases']);
    rows.add(['Date', 'Type', 'Net Amount', 'NAV', 'Units', 'Balance']);
    for (final p in result.purchases) {
      rows.add([
        DateFormat('dd-MMM-yyyy').format(p.priceDate),
        p.type.name,
        NumberUtils.formatNumber(p.netAmount),
        NumberUtils.formatNumber(p.nav, decimals: 4),
        NumberUtils.formatUnits(p.units),
        NumberUtils.formatUnits(p.balance),
      ]);
    }
    rows.add([]);

    // Monthly returns section
    rows.add(['Monthly Returns']);
    rows.add(['Month', 'Start NAV', 'End NAV', 'Return %']);
    for (final r in result.monthlyReturns) {
      rows.add([
        DateFormat('MMM yyyy').format(r.month),
        NumberUtils.formatNumber(r.startNav, decimals: 4),
        NumberUtils.formatNumber(r.endNav, decimals: 4),
        NumberUtils.formatPercent(r.returnPercent),
      ]);
    }
    rows.add([]);

    // NAV history section
    rows.add(['NAV History']);
    rows.add(['Date', 'NAV']);
    for (final n in result.filteredNavHistory) {
      rows.add([
        DateFormat('dd-MMM-yyyy').format(n.date),
        NumberUtils.formatNumber(n.nav, decimals: 4),
      ]);
    }

    final csvContent = const ListToCsvConverter().convert(rows);
    await File(filePath).writeAsString(csvContent);

    return filePath;
  }
}
