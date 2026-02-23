import 'dart:io';
import 'dart:isolate';

import 'package:excel/excel.dart';

import '../../core/models/nav_entry.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/number_utils.dart';

/// Parser for MUFAP-format NAV Excel files.
///
/// Expected columns: Fund, Validity Date, NAV, Offer, Repurchase
/// Header row may be on row 1 or row 2.
class ExcelNavParser {
  ExcelNavParser._();

  /// Parse NAV entries from an Excel file path.
  /// Runs heavy parsing in an isolate to avoid UI blocking.
  static Future<ExcelParseResult> parseFile(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    return Isolate.run(() => _parseBytes(bytes));
  }

  /// Parse NAV entries from raw bytes (for use in isolate).
  static ExcelParseResult _parseBytes(List<int> bytes) {
    final excel = Excel.decodeBytes(bytes);
    final allEntries = <NavEntry>[];
    final fundNames = <String>{};
    final errors = <String>[];

    for (final sheetName in excel.tables.keys) {
      final sheet = excel.tables[sheetName];
      if (sheet == null || sheet.rows.isEmpty) continue;

      // Detect header row (row 0 or row 1)
      final headerResult = _detectHeaderRow(sheet);
      if (headerResult == null) {
        errors.add('Sheet "$sheetName": Could not detect header row');
        continue;
      }

      final headerRowIndex = headerResult.rowIndex;
      final columnMap = headerResult.columnMap;

      // Parse data rows
      for (int i = headerRowIndex + 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        try {
          final entry = _parseRow(row, columnMap);
          if (entry != null) {
            allEntries.add(entry);
            fundNames.add(entry.fundName);
          }
        } catch (e) {
          errors.add('Sheet "$sheetName", Row ${i + 1}: $e');
        }
      }
    }

    return ExcelParseResult(
      entries: allEntries,
      fundNames: fundNames.toList()..sort(),
      errors: errors,
    );
  }

  /// Detect the header row and column mapping.
  static _HeaderResult? _detectHeaderRow(Sheet sheet) {
    // Try first few rows
    for (int rowIdx = 0; rowIdx < 3 && rowIdx < sheet.rows.length; rowIdx++) {
      final row = sheet.rows[rowIdx];
      final columnMap = _mapColumns(row);
      if (columnMap != null) {
        return _HeaderResult(rowIndex: rowIdx, columnMap: columnMap);
      }
    }
    return null;
  }

  /// Map column indices from header row.
  static _ColumnMap? _mapColumns(List<Data?> row) {
    int? fundCol;
    int? dateCol;
    int? navCol;
    int? offerCol;
    int? repurchaseCol;

    for (int i = 0; i < row.length; i++) {
      final cellValue = row[i]?.value?.toString().trim().toLowerCase() ?? '';

      if (cellValue.isEmpty) continue;

      if (_matchesAny(cellValue, ['fund', 'fund name', 'scheme', 'fund_name'])) {
        fundCol = i;
      } else if (_matchesAny(cellValue, [
        'validity date',
        'date',
        'nav date',
        'validity_date',
        'val date',
        'valdate',
      ])) {
        dateCol = i;
      } else if (cellValue == 'nav' ||
          cellValue == 'nav per unit' ||
          cellValue == 'nav_per_unit') {
        navCol = i;
      } else if (_matchesAny(cellValue, ['offer', 'offer price', 'sale', 'sale price'])) {
        offerCol = i;
      } else if (_matchesAny(cellValue, [
        'repurchase',
        'repurchase price',
        'redemption',
        'redemption price',
        'buyback',
      ])) {
        repurchaseCol = i;
      }
    }

    // Fund, Date, and NAV are required
    if (fundCol != null && dateCol != null && navCol != null) {
      return _ColumnMap(
        fund: fundCol,
        date: dateCol,
        nav: navCol,
        offer: offerCol,
        repurchase: repurchaseCol,
      );
    }

    return null;
  }

  static bool _matchesAny(String value, List<String> targets) {
    return targets.any((t) => value == t || value.contains(t));
  }

  /// Parse a single data row into a NavEntry.
  static NavEntry? _parseRow(List<Data?> row, _ColumnMap columns) {
    // Get fund name
    final fundRaw = _getCellString(row, columns.fund);
    if (fundRaw == null || fundRaw.isEmpty) return null;

    // Get date
    final dateRaw = _getCellValue(row, columns.date);
    DateTime? date;
    if (dateRaw is DateTime) {
      date = dateRaw;
    } else if (dateRaw != null) {
      date = AppDateUtils.tryParse(dateRaw.toString());
    }
    if (date == null) return null;

    // Get NAV
    final navRaw = _getCellValue(row, columns.nav);
    double? nav;
    if (navRaw is num) {
      nav = navRaw.toDouble();
    } else if (navRaw != null) {
      nav = NumberUtils.tryParse(navRaw.toString());
    }
    if (nav == null || nav <= 0) return null;

    // Get optional columns
    double? offer;
    if (columns.offer != null) {
      final offerRaw = _getCellValue(row, columns.offer!);
      if (offerRaw is num) {
        offer = offerRaw.toDouble();
      } else if (offerRaw != null) {
        offer = NumberUtils.tryParse(offerRaw.toString());
      }
    }

    double? repurchase;
    if (columns.repurchase != null) {
      final repRaw = _getCellValue(row, columns.repurchase!);
      if (repRaw is num) {
        repurchase = repRaw.toDouble();
      } else if (repRaw != null) {
        repurchase = NumberUtils.tryParse(repRaw.toString());
      }
    }

    return NavEntry(
      fundName: fundRaw.trim(),
      date: date,
      nav: nav,
      offerPrice: offer,
      repurchasePrice: repurchase,
    );
  }

  static String? _getCellString(List<Data?> row, int index) {
    if (index >= row.length) return null;
    return row[index]?.value?.toString();
  }

  static dynamic _getCellValue(List<Data?> row, int index) {
    if (index >= row.length) return null;
    return row[index]?.value;
  }
}

/// Result of parsing an Excel NAV file.
class ExcelParseResult {
  final List<NavEntry> entries;
  final List<String> fundNames;
  final List<String> errors;

  const ExcelParseResult({
    required this.entries,
    required this.fundNames,
    required this.errors,
  });

  bool get hasData => entries.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;

  /// Get entries for a specific fund.
  List<NavEntry> entriesForFund(String fundName) {
    return entries.where((e) => e.fundName == fundName).toList();
  }
}

class _HeaderResult {
  final int rowIndex;
  final _ColumnMap columnMap;

  const _HeaderResult({required this.rowIndex, required this.columnMap});
}

class _ColumnMap {
  final int fund;
  final int date;
  final int nav;
  final int? offer;
  final int? repurchase;

  const _ColumnMap({
    required this.fund,
    required this.date,
    required this.nav,
    this.offer,
    this.repurchase,
  });
}
