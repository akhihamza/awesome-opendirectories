import '../../core/models/nav_entry.dart';
import '../parsers/excel_nav_parser.dart';

/// Repository for NAV data.
///
/// Manages loading, caching, and querying of NAV entries.
class NavRepository {
  ExcelParseResult? _parseResult;
  String? _currentFilePath;

  /// Whether NAV data has been loaded.
  bool get isLoaded => _parseResult != null && _parseResult!.hasData;

  /// Get the current parse result.
  ExcelParseResult? get parseResult => _parseResult;

  /// Get all available fund names.
  List<String> get fundNames => _parseResult?.fundNames ?? [];

  /// Load NAV data from an Excel file.
  Future<ExcelParseResult> loadFromFile(String filePath) async {
    _currentFilePath = filePath;
    _parseResult = await ExcelNavParser.parseFile(filePath);
    return _parseResult!;
  }

  /// Get all NAV entries for a specific fund.
  List<NavEntry> getEntriesForFund(String fundName) {
    return _parseResult?.entriesForFund(fundName) ?? [];
  }

  /// Get NAV entries for a fund within a date range.
  List<NavEntry> getEntriesInRange(
    String fundName,
    DateTime start,
    DateTime end,
  ) {
    return getEntriesForFund(fundName)
        .where((e) => !e.date.isBefore(start) && !e.date.isAfter(end))
        .toList();
  }

  /// Get the latest NAV for a fund.
  NavEntry? getLatestNav(String fundName) {
    final entries = getEntriesForFund(fundName);
    if (entries.isEmpty) return null;
    entries.sort((a, b) => a.date.compareTo(b.date));
    return entries.last;
  }

  /// Get the current file path.
  String? get currentFilePath => _currentFilePath;

  /// Clear all loaded data.
  void clear() {
    _parseResult = null;
    _currentFilePath = null;
  }
}
