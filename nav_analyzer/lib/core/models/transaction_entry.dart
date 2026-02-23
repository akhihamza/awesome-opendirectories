import 'package:equatable/equatable.dart';

/// Types of transactions that can appear in the PDF statement.
enum TransactionType {
  initialPurchase,
  additionalPurchase,
  conversionFrom,
  redemption,
  conversionTo,
  dividend,
  unknown;

  /// Whether this transaction type represents a purchase/inflow.
  bool get isPurchase =>
      this == initialPurchase ||
      this == additionalPurchase ||
      this == conversionFrom;

  static TransactionType fromString(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.contains('initial') && lower.contains('purchase')) {
      return TransactionType.initialPurchase;
    }
    if (lower.contains('additional') && lower.contains('purchase')) {
      return TransactionType.additionalPurchase;
    }
    if (lower.contains('conversion') && lower.contains('from')) {
      return TransactionType.conversionFrom;
    }
    if (lower.contains('redemption')) {
      return TransactionType.redemption;
    }
    if (lower.contains('conversion') && lower.contains('to')) {
      return TransactionType.conversionTo;
    }
    if (lower.contains('dividend')) {
      return TransactionType.dividend;
    }
    return TransactionType.unknown;
  }
}

/// Represents a single transaction from the PDF statement.
class TransactionEntry extends Equatable {
  final String fundName;
  final TransactionType type;
  final double grossAmount;
  final double netAmount;
  final double nav;
  final DateTime priceDate;
  final double units;
  final double balance;

  const TransactionEntry({
    required this.fundName,
    required this.type,
    required this.grossAmount,
    required this.netAmount,
    required this.nav,
    required this.priceDate,
    required this.units,
    required this.balance,
  });

  TransactionEntry copyWith({
    String? fundName,
    TransactionType? type,
    double? grossAmount,
    double? netAmount,
    double? nav,
    DateTime? priceDate,
    double? units,
    double? balance,
  }) {
    return TransactionEntry(
      fundName: fundName ?? this.fundName,
      type: type ?? this.type,
      grossAmount: grossAmount ?? this.grossAmount,
      netAmount: netAmount ?? this.netAmount,
      nav: nav ?? this.nav,
      priceDate: priceDate ?? this.priceDate,
      units: units ?? this.units,
      balance: balance ?? this.balance,
    );
  }

  Map<String, dynamic> toJson() => {
        'fundName': fundName,
        'type': type.name,
        'grossAmount': grossAmount,
        'netAmount': netAmount,
        'nav': nav,
        'priceDate': priceDate.toIso8601String(),
        'units': units,
        'balance': balance,
      };

  factory TransactionEntry.fromJson(Map<String, dynamic> json) =>
      TransactionEntry(
        fundName: json['fundName'] as String,
        type: TransactionType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => TransactionType.unknown,
        ),
        grossAmount: (json['grossAmount'] as num).toDouble(),
        netAmount: (json['netAmount'] as num).toDouble(),
        nav: (json['nav'] as num).toDouble(),
        priceDate: DateTime.parse(json['priceDate'] as String),
        units: (json['units'] as num).toDouble(),
        balance: (json['balance'] as num).toDouble(),
      );

  @override
  List<Object?> get props =>
      [fundName, type, grossAmount, netAmount, nav, priceDate, units, balance];

  @override
  String toString() =>
      'TransactionEntry(${type.name}, net=$netAmount, units=$units, date=$priceDate)';
}
