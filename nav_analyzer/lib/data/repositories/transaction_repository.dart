import '../../core/models/transaction_entry.dart';
import '../parsers/pdf_transaction_parser.dart';

/// Repository for transaction data.
///
/// Manages loading, caching, and querying of transaction entries.
class TransactionRepository {
  PdfParseResult? _parseResult;
  String? _currentFilePath;

  // Manual entries added by user
  final List<TransactionEntry> _manualEntries = [];

  /// Whether transaction data has been loaded.
  bool get isLoaded =>
      (_parseResult != null && _parseResult!.hasData) ||
      _manualEntries.isNotEmpty;

  /// Get the current parse result.
  PdfParseResult? get parseResult => _parseResult;

  /// Get all available fund names from transactions.
  List<String> get fundNames {
    final names = <String>{};
    if (_parseResult != null) {
      names.addAll(_parseResult!.fundNames);
    }
    for (final entry in _manualEntries) {
      names.add(entry.fundName);
    }
    return names.toList()..sort();
  }

  /// Load transactions from a PDF file.
  Future<PdfParseResult> loadFromFile(String filePath) async {
    _currentFilePath = filePath;
    _parseResult = await PdfTransactionParser.parseFile(filePath);
    return _parseResult!;
  }

  /// Get all transactions for a specific fund.
  List<TransactionEntry> getTransactionsForFund(String fundName) {
    final parsed = _parseResult?.transactionsForFund(fundName) ?? [];
    final manual = _manualEntries.where((e) => e.fundName == fundName);
    return [...parsed, ...manual]
      ..sort((a, b) => a.priceDate.compareTo(b.priceDate));
  }

  /// Get only purchase transactions for a fund.
  List<TransactionEntry> getPurchasesForFund(String fundName) {
    return getTransactionsForFund(fundName)
        .where((t) => t.type.isPurchase)
        .toList();
  }

  /// Add a manually entered transaction.
  void addManualEntry(TransactionEntry entry) {
    _manualEntries.add(entry);
  }

  /// Remove a manual entry.
  void removeManualEntry(int index) {
    if (index >= 0 && index < _manualEntries.length) {
      _manualEntries.removeAt(index);
    }
  }

  /// Get all manual entries.
  List<TransactionEntry> get manualEntries =>
      List.unmodifiable(_manualEntries);

  /// Get current file path.
  String? get currentFilePath => _currentFilePath;

  /// Get raw PDF text for debugging.
  String? get rawText => _parseResult?.rawText;

  /// Clear all loaded data.
  void clear() {
    _parseResult = null;
    _currentFilePath = null;
    _manualEntries.clear();
  }
}
