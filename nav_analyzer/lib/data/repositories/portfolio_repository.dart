import 'package:hive/hive.dart';

import '../../core/models/portfolio.dart';
import '../../core/models/transaction_entry.dart';

/// Repository for persisting portfolio data using Hive.
class PortfolioRepository {
  static const String _boxName = 'portfolios';
  Box<PortfolioData>? _box;

  /// Initialize the Hive box.
  Future<void> init() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PortfolioDataAdapter());
    }
    _box = await Hive.openBox<PortfolioData>(_boxName);
  }

  /// Get all saved portfolios.
  List<PortfolioData> getAll() {
    return _box?.values.toList() ?? [];
  }

  /// Get a portfolio by fund name.
  PortfolioData? getByFundName(String fundName) {
    try {
      return _box?.values.firstWhere((p) => p.fundName == fundName);
    } catch (_) {
      return null;
    }
  }

  /// Save a portfolio.
  Future<void> save({
    required String fundName,
    required String navFilePath,
    String? pdfFilePath,
    required List<TransactionEntry> transactions,
  }) async {
    final data = PortfolioData(
      fundName: fundName,
      navFilePath: navFilePath,
      pdfFilePath: pdfFilePath,
      transactionsJson: transactions.map((t) => t.toJson()).toList(),
      lastUpdated: DateTime.now(),
    );
    await _box?.put(fundName, data);
  }

  /// Delete a portfolio.
  Future<void> delete(String fundName) async {
    await _box?.delete(fundName);
  }

  /// Clear all portfolios.
  Future<void> clearAll() async {
    await _box?.clear();
  }
}
