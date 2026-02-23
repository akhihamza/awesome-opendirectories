import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/transaction_entry.dart';
import '../../domain/entities/app_state.dart';
import 'app_providers.dart';

/// Combined state for the entire analysis workflow.
class AnalysisWorkflowState {
  final NavFileState navFile;
  final PdfFileState pdfFile;
  final AnalysisState analysis;
  final AnalysisPreferences preferences;

  const AnalysisWorkflowState({
    this.navFile = const NavFileState(),
    this.pdfFile = const PdfFileState(),
    this.analysis = const AnalysisState(),
    this.preferences = const AnalysisPreferences(),
  });

  AnalysisWorkflowState copyWith({
    NavFileState? navFile,
    PdfFileState? pdfFile,
    AnalysisState? analysis,
    AnalysisPreferences? preferences,
  }) {
    return AnalysisWorkflowState(
      navFile: navFile ?? this.navFile,
      pdfFile: pdfFile ?? this.pdfFile,
      analysis: analysis ?? this.analysis,
      preferences: preferences ?? this.preferences,
    );
  }

  /// Whether we have enough data to run analysis.
  bool get canAnalyze =>
      navFile.isLoaded &&
      preferences.selectedFund != null;

  /// All unique fund names from both NAV and PDF.
  List<String> get allFundNames {
    final names = <String>{
      ...navFile.fundNames,
      ...pdfFile.fundNames,
    };
    return names.toList()..sort();
  }
}

/// Notifier managing the entire analysis workflow.
class AnalysisNotifier extends StateNotifier<AnalysisWorkflowState> {
  final Ref _ref;

  AnalysisNotifier(this._ref) : super(const AnalysisWorkflowState());

  /// Pick and load a NAV Excel file.
  Future<void> loadNavFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.single.path;
    if (filePath == null) return;

    state = state.copyWith(
      navFile: state.navFile.copyWith(
        status: LoadingStatus.loading,
        filePath: filePath,
      ),
    );

    try {
      final navRepo = _ref.read(navRepositoryProvider);
      final parseResult = await navRepo.loadFromFile(filePath);

      state = state.copyWith(
        navFile: NavFileState(
          status: LoadingStatus.success,
          result: parseResult,
          filePath: filePath,
        ),
      );

      // Auto-select first fund if none selected
      if (state.preferences.selectedFund == null &&
          parseResult.fundNames.isNotEmpty) {
        state = state.copyWith(
          preferences: state.preferences.copyWith(
            selectedFund: parseResult.fundNames.first,
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(
        navFile: NavFileState(
          status: LoadingStatus.error,
          error: e.toString(),
          filePath: filePath,
        ),
      );
    }
  }

  /// Pick and load a PDF transaction statement.
  Future<void> loadPdfFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.single.path;
    if (filePath == null) return;

    state = state.copyWith(
      pdfFile: state.pdfFile.copyWith(
        status: LoadingStatus.loading,
        filePath: filePath,
      ),
    );

    try {
      final txnRepo = _ref.read(transactionRepositoryProvider);
      final parseResult = await txnRepo.loadFromFile(filePath);

      state = state.copyWith(
        pdfFile: PdfFileState(
          status: LoadingStatus.success,
          result: parseResult,
          filePath: filePath,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        pdfFile: PdfFileState(
          status: LoadingStatus.error,
          error: e.toString(),
          filePath: filePath,
        ),
      );
    }
  }

  /// Select a fund for analysis.
  void selectFund(String fundName) {
    state = state.copyWith(
      preferences: state.preferences.copyWith(selectedFund: fundName),
      analysis: const AnalysisState(), // Reset analysis
    );
  }

  /// Set the last N months filter.
  void setLastNMonths(int? months) {
    state = state.copyWith(
      preferences: state.preferences.copyWith(
        lastNMonths: months,
        clearLastNMonths: months == null,
      ),
    );
  }

  /// Toggle outlier filtering.
  void setFilterOutliers(bool enabled) {
    state = state.copyWith(
      preferences: state.preferences.copyWith(filterOutliers: enabled),
    );
  }

  /// Set outlier filter K value.
  void setOutlierK(double k) {
    state = state.copyWith(
      preferences: state.preferences.copyWith(outlierK: k),
    );
  }

  /// Add a manual transaction entry.
  void addManualTransaction(TransactionEntry entry) {
    final txnRepo = _ref.read(transactionRepositoryProvider);
    txnRepo.addManualEntry(entry);
  }

  /// Run the analysis.
  Future<void> runAnalysis() async {
    final fund = state.preferences.selectedFund;
    if (fund == null) return;

    state = state.copyWith(
      analysis: const AnalysisState(status: LoadingStatus.loading),
    );

    try {
      final navRepo = _ref.read(navRepositoryProvider);
      final txnRepo = _ref.read(transactionRepositoryProvider);
      final useCase = _ref.read(analyzeFundUseCaseProvider);

      final navHistory = navRepo.getEntriesForFund(fund);
      final transactions = txnRepo.getTransactionsForFund(fund);

      if (navHistory.isEmpty) {
        state = state.copyWith(
          analysis: const AnalysisState(
            status: LoadingStatus.error,
            error: 'No NAV data found for selected fund',
          ),
        );
        return;
      }

      final result = await useCase.execute(
        fundName: fund,
        navHistory: navHistory,
        transactions: transactions,
        outlierK: state.preferences.outlierK,
        filterOutliers: state.preferences.filterOutliers,
        lastNMonths: state.preferences.lastNMonths,
      );

      state = state.copyWith(
        analysis: AnalysisState(
          status: LoadingStatus.success,
          result: result,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        analysis: AnalysisState(
          status: LoadingStatus.error,
          error: e.toString(),
        ),
      );
    }
  }

  /// Export analysis to CSV.
  Future<String?> exportCsv() async {
    final result = state.analysis.result;
    if (result == null) return null;

    try {
      final useCase = _ref.read(exportCsvUseCaseProvider);
      return await useCase.execute(result);
    } catch (e) {
      return null;
    }
  }

  /// Save current portfolio to local storage.
  Future<void> savePortfolio() async {
    final fund = state.preferences.selectedFund;
    if (fund == null) return;

    final navRepo = _ref.read(navRepositoryProvider);
    final txnRepo = _ref.read(transactionRepositoryProvider);
    final portfolioRepo = _ref.read(portfolioRepositoryProvider);

    await portfolioRepo.save(
      fundName: fund,
      navFilePath: navRepo.currentFilePath ?? '',
      pdfFilePath: txnRepo.currentFilePath,
      transactions: txnRepo.getTransactionsForFund(fund),
    );
  }

  /// Reset all state.
  void reset() {
    _ref.read(navRepositoryProvider).clear();
    _ref.read(transactionRepositoryProvider).clear();
    state = const AnalysisWorkflowState();
  }
}

/// Provider for the analysis workflow.
final analysisNotifierProvider =
    StateNotifierProvider<AnalysisNotifier, AnalysisWorkflowState>((ref) {
  return AnalysisNotifier(ref);
});
