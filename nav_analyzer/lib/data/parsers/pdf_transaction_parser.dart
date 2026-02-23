import 'dart:io';
import 'dart:isolate';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../core/models/transaction_entry.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/number_utils.dart';

/// Parser for UBL-format PDF transaction statements.
///
/// Extracts fund names and transaction data from multi-page PDFs.
class PdfTransactionParser {
  PdfTransactionParser._();

  /// Parse transactions from a PDF file path.
  /// Runs heavy parsing in an isolate to avoid UI blocking.
  static Future<PdfParseResult> parseFile(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    return Isolate.run(() => _parseBytes(bytes));
  }

  /// Parse transactions from raw bytes.
  static PdfParseResult _parseBytes(List<int> bytes) {
    final document = PdfDocument(inputBytes: bytes);
    final errors = <String>[];

    // Extract all text from all pages
    final fullText = StringBuffer();
    for (int i = 0; i < document.pages.count; i++) {
      final page = document.pages[i];
      final extractor = PdfTextExtractor(document);
      final text = extractor.extractText(startPageIndex: i, endPageIndex: i);
      fullText.writeln(text);
    }
    document.dispose();

    final textContent = fullText.toString();

    // Detect fund names
    final fundNames = _extractFundNames(textContent);

    // Parse transactions per fund
    final allTransactions = <TransactionEntry>[];
    for (final fundName in fundNames) {
      try {
        final transactions = _parseTransactionsForFund(textContent, fundName);
        allTransactions.addAll(transactions);
      } catch (e) {
        errors.add('Fund "$fundName": $e');
      }
    }

    // If structured parsing fails, try line-by-line parsing
    if (allTransactions.isEmpty) {
      try {
        final fallbackTransactions = _fallbackLineParse(textContent, fundNames);
        allTransactions.addAll(fallbackTransactions);
      } catch (e) {
        errors.add('Fallback parsing failed: $e');
      }
    }

    return PdfParseResult(
      transactions: allTransactions,
      fundNames: fundNames,
      rawText: textContent,
      errors: errors,
    );
  }

  /// Extract fund names from PDF text.
  /// Looks for patterns like "For AL-AMEEN ISLAMIC ENERGY FUND - Class 'A'"
  static List<String> _extractFundNames(String text) {
    final fundNames = <String>{};

    // Pattern: "For <FUND NAME>"
    final forPattern = RegExp(
      r"For\s+(.+?(?:FUND|Fund|fund)(?:\s*-\s*Class\s*['"']?\w['"']?)?)",
      multiLine: true,
    );
    for (final match in forPattern.allMatches(text)) {
      final name = match.group(1)?.trim();
      if (name != null && name.length > 5) {
        fundNames.add(name);
      }
    }

    // Pattern: Fund name in all caps followed by common suffixes
    final capsPattern = RegExp(
      r"([A-Z][A-Z\s\-]+(?:FUND|INCOME|GROWTH|BALANCED)(?:\s*-\s*Class\s*['"']?\w['"']?)?)",
      multiLine: true,
    );
    for (final match in capsPattern.allMatches(text)) {
      final name = match.group(1)?.trim();
      if (name != null && name.length > 10 && !name.contains('\n')) {
        fundNames.add(name);
      }
    }

    return fundNames.toList()..sort();
  }

  /// Parse transactions for a specific fund from the text.
  static List<TransactionEntry> _parseTransactionsForFund(
    String text,
    String fundName,
  ) {
    final transactions = <TransactionEntry>[];

    // Split text into lines
    final lines = text.split('\n');

    // Transaction type keywords
    final typeKeywords = [
      'Initial Purchase',
      'Additional Purchase',
      'Conversion From',
      'Conversion To',
      'Redemption',
      'Dividend',
    ];

    bool inFundSection = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Check if we're entering a fund section
      if (line.contains(fundName) || _fuzzyMatchFund(line, fundName)) {
        inFundSection = true;
        continue;
      }

      // Check if we're leaving a fund section (another fund starts)
      if (inFundSection && line.startsWith('For ') && !line.contains(fundName)) {
        inFundSection = false;
        continue;
      }

      if (!inFundSection) continue;

      // Check if this line starts a transaction
      String? matchedType;
      for (final keyword in typeKeywords) {
        if (line.toLowerCase().contains(keyword.toLowerCase())) {
          matchedType = keyword;
          break;
        }
      }

      if (matchedType != null) {
        // Try to parse this transaction from current and following lines
        final context = _gatherContext(lines, i, 3);
        final transaction = _parseTransactionFromContext(
          context,
          fundName,
          matchedType,
        );
        if (transaction != null) {
          transactions.add(transaction);
        }
      }
    }

    return transactions;
  }

  /// Gather context lines for transaction parsing.
  static String _gatherContext(List<String> lines, int startIdx, int extra) {
    final buffer = StringBuffer();
    for (int i = startIdx; i < lines.length && i <= startIdx + extra; i++) {
      buffer.writeln(lines[i].trim());
    }
    return buffer.toString();
  }

  /// Parse a transaction from context text around a type keyword.
  static TransactionEntry? _parseTransactionFromContext(
    String context,
    String fundName,
    String typeStr,
  ) {
    final type = TransactionType.fromString(typeStr);

    // Extract numbers from the context
    final numbers = _extractNumbers(context);
    if (numbers.length < 4) return null;

    // Extract date from context
    final date = _extractDate(context);
    if (date == null) return null;

    // UBL format: Type | Gross | Net | NAV | Price Date | Units | Balance
    // Numbers order varies, but typically:
    // [grossAmount, netAmount, nav, units, balance]
    // We need at least: netAmount, nav, units

    // Heuristic: NAV is usually a small number (< 1000)
    // Units can be large or small
    // Gross/Net amounts are usually large

    double? gross;
    double? net;
    double? nav;
    double? units;
    double? balance;

    // Try to identify NAV (small value, typically < 500)
    for (int i = 0; i < numbers.length; i++) {
      if (numbers[i] > 0 && numbers[i] < 500 && nav == null) {
        nav = numbers[i];
        // Net is usually before NAV
        if (i >= 2) {
          gross = numbers[i - 2];
          net = numbers[i - 1];
        } else if (i >= 1) {
          net = numbers[i - 1];
          gross = net;
        }
        // Units and balance are after NAV
        if (i + 1 < numbers.length) units = numbers[i + 1];
        if (i + 2 < numbers.length) balance = numbers[i + 2];
        break;
      }
    }

    // Fallback: just use positional assignment
    if (nav == null && numbers.length >= 5) {
      gross = numbers[0];
      net = numbers[1];
      nav = numbers[2];
      units = numbers[3];
      balance = numbers[4];
    }

    if (net == null || nav == null || units == null) return null;

    return TransactionEntry(
      fundName: fundName,
      type: type,
      grossAmount: gross ?? net,
      netAmount: net,
      nav: nav,
      priceDate: date,
      units: units,
      balance: balance ?? units,
    );
  }

  /// Extract all numbers from text.
  static List<double> _extractNumbers(String text) {
    final pattern = RegExp(r'[\d,]+\.?\d*');
    final matches = pattern.allMatches(text);
    final numbers = <double>[];

    for (final match in matches) {
      final raw = match.group(0)!;
      final value = NumberUtils.tryParse(raw);
      if (value != null && value > 0) {
        numbers.add(value);
      }
    }

    return numbers;
  }

  /// Extract a date from text.
  static DateTime? _extractDate(String text) {
    // Common date patterns
    final patterns = [
      RegExp(r'\d{2}-[A-Za-z]{3}-\d{4}'),
      RegExp(r'\d{2}/\d{2}/\d{4}'),
      RegExp(r'\d{4}-\d{2}-\d{2}'),
      RegExp(r'\d{2}-\d{2}-\d{4}'),
      RegExp(r'\d{1,2}\s+[A-Za-z]{3,9}\s+\d{4}'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final dateStr = match.group(0)!;
        final parsed = AppDateUtils.tryParse(dateStr);
        if (parsed != null) return parsed;
      }
    }

    return null;
  }

  /// Fuzzy match a fund name (case-insensitive, ignoring extra spaces).
  static bool _fuzzyMatchFund(String line, String fundName) {
    final normalizedLine = line.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final normalizedFund = fundName.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    return normalizedLine.contains(normalizedFund);
  }

  /// Fallback line-by-line parser for unstructured text.
  static List<TransactionEntry> _fallbackLineParse(
    String text,
    List<String> fundNames,
  ) {
    final transactions = <TransactionEntry>[];
    final lines = text.split('\n');

    final fundName = fundNames.isNotEmpty ? fundNames.first : 'Unknown Fund';

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Check for transaction type keywords
      TransactionType? type;
      if (line.toLowerCase().contains('initial purchase')) {
        type = TransactionType.initialPurchase;
      } else if (line.toLowerCase().contains('additional purchase')) {
        type = TransactionType.additionalPurchase;
      } else if (line.toLowerCase().contains('conversion from')) {
        type = TransactionType.conversionFrom;
      } else if (line.toLowerCase().contains('redemption')) {
        type = TransactionType.redemption;
      }

      if (type == null) continue;

      // Gather this line and next few lines
      final context = _gatherContext(lines, i, 4);
      final numbers = _extractNumbers(context);
      final date = _extractDate(context);

      if (numbers.length >= 4 && date != null) {
        transactions.add(TransactionEntry(
          fundName: fundName,
          type: type,
          grossAmount: numbers[0],
          netAmount: numbers.length > 1 ? numbers[1] : numbers[0],
          nav: numbers.length > 2 ? numbers[2] : 0,
          priceDate: date,
          units: numbers.length > 3 ? numbers[3] : 0,
          balance: numbers.length > 4 ? numbers[4] : 0,
        ));
      }
    }

    return transactions;
  }
}

/// Result of parsing a PDF transaction statement.
class PdfParseResult {
  final List<TransactionEntry> transactions;
  final List<String> fundNames;
  final String rawText;
  final List<String> errors;

  const PdfParseResult({
    required this.transactions,
    required this.fundNames,
    required this.rawText,
    required this.errors,
  });

  bool get hasData => transactions.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;

  /// Get purchase-only transactions.
  List<TransactionEntry> get purchases =>
      transactions.where((t) => t.type.isPurchase).toList();

  /// Get transactions for a specific fund.
  List<TransactionEntry> transactionsForFund(String fundName) {
    return transactions.where((t) => t.fundName == fundName).toList();
  }
}
