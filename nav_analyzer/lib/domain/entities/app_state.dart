import '../../core/models/analysis_result.dart';
import '../../data/parsers/excel_nav_parser.dart';
import '../../data/parsers/pdf_transaction_parser.dart';

/// Application-level state for the analysis workflow.
enum LoadingStatus { idle, loading, success, error }

/// State for the NAV file loading.
class NavFileState {
  final LoadingStatus status;
  final ExcelParseResult? result;
  final String? filePath;
  final String? error;

  const NavFileState({
    this.status = LoadingStatus.idle,
    this.result,
    this.filePath,
    this.error,
  });

  NavFileState copyWith({
    LoadingStatus? status,
    ExcelParseResult? result,
    String? filePath,
    String? error,
  }) {
    return NavFileState(
      status: status ?? this.status,
      result: result ?? this.result,
      filePath: filePath ?? this.filePath,
      error: error ?? this.error,
    );
  }

  bool get isLoaded => status == LoadingStatus.success && result != null;
  List<String> get fundNames => result?.fundNames ?? [];
}

/// State for the PDF file loading.
class PdfFileState {
  final LoadingStatus status;
  final PdfParseResult? result;
  final String? filePath;
  final String? error;

  const PdfFileState({
    this.status = LoadingStatus.idle,
    this.result,
    this.filePath,
    this.error,
  });

  PdfFileState copyWith({
    LoadingStatus? status,
    PdfParseResult? result,
    String? filePath,
    String? error,
  }) {
    return PdfFileState(
      status: status ?? this.status,
      result: result ?? this.result,
      filePath: filePath ?? this.filePath,
      error: error ?? this.error,
    );
  }

  bool get isLoaded => status == LoadingStatus.success && result != null;
  List<String> get fundNames => result?.fundNames ?? [];
}

/// State for the analysis.
class AnalysisState {
  final LoadingStatus status;
  final AnalysisResult? result;
  final String? error;

  const AnalysisState({
    this.status = LoadingStatus.idle,
    this.result,
    this.error,
  });

  AnalysisState copyWith({
    LoadingStatus? status,
    AnalysisResult? result,
    String? error,
  }) {
    return AnalysisState(
      status: status ?? this.status,
      result: result ?? this.result,
      error: error ?? this.error,
    );
  }

  bool get hasResult => status == LoadingStatus.success && result != null;
}

/// User preferences for the analysis.
class AnalysisPreferences {
  final String? selectedFund;
  final int? lastNMonths;
  final bool filterOutliers;
  final double outlierK;

  const AnalysisPreferences({
    this.selectedFund,
    this.lastNMonths,
    this.filterOutliers = false,
    this.outlierK = 1.5,
  });

  AnalysisPreferences copyWith({
    String? selectedFund,
    int? lastNMonths,
    bool? filterOutliers,
    double? outlierK,
    bool clearLastNMonths = false,
  }) {
    return AnalysisPreferences(
      selectedFund: selectedFund ?? this.selectedFund,
      lastNMonths: clearLastNMonths ? null : (lastNMonths ?? this.lastNMonths),
      filterOutliers: filterOutliers ?? this.filterOutliers,
      outlierK: outlierK ?? this.outlierK,
    );
  }
}
