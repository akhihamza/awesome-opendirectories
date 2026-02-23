import 'package:hive/hive.dart';

import 'transaction_entry.dart';

part 'portfolio.g.dart';

/// Persisted portfolio data for local storage.
@HiveType(typeId: 0)
class PortfolioData extends HiveObject {
  @HiveField(0)
  final String fundName;

  @HiveField(1)
  final String navFilePath;

  @HiveField(2)
  final String? pdfFilePath;

  @HiveField(3)
  final List<Map<String, dynamic>> transactionsJson;

  @HiveField(4)
  final DateTime lastUpdated;

  PortfolioData({
    required this.fundName,
    required this.navFilePath,
    this.pdfFilePath,
    required this.transactionsJson,
    required this.lastUpdated,
  });

  List<TransactionEntry> get transactions =>
      transactionsJson.map((j) => TransactionEntry.fromJson(j)).toList();
}
