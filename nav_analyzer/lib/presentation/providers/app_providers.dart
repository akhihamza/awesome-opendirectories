import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/nav_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/portfolio_repository.dart';
import '../../domain/usecases/analyze_fund_usecase.dart';
import '../../domain/usecases/export_csv_usecase.dart';

/// Repository providers (singletons).
final navRepositoryProvider = Provider<NavRepository>((ref) {
  return NavRepository();
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  return PortfolioRepository();
});

/// Use case providers.
final analyzeFundUseCaseProvider = Provider<AnalyzeFundUseCase>((ref) {
  return AnalyzeFundUseCase();
});

final exportCsvUseCaseProvider = Provider<ExportCsvUseCase>((ref) {
  return ExportCsvUseCase();
});

/// Theme mode provider.
final darkModeProvider = StateProvider<bool>((ref) => false);
