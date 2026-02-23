import 'package:equatable/equatable.dart';

/// Represents a single NAV data point from the Excel file.
class NavEntry extends Equatable {
  final String fundName;
  final DateTime date;
  final double nav;
  final double? offerPrice;
  final double? repurchasePrice;

  const NavEntry({
    required this.fundName,
    required this.date,
    required this.nav,
    this.offerPrice,
    this.repurchasePrice,
  });

  NavEntry copyWith({
    String? fundName,
    DateTime? date,
    double? nav,
    double? offerPrice,
    double? repurchasePrice,
  }) {
    return NavEntry(
      fundName: fundName ?? this.fundName,
      date: date ?? this.date,
      nav: nav ?? this.nav,
      offerPrice: offerPrice ?? this.offerPrice,
      repurchasePrice: repurchasePrice ?? this.repurchasePrice,
    );
  }

  Map<String, dynamic> toJson() => {
        'fundName': fundName,
        'date': date.toIso8601String(),
        'nav': nav,
        'offerPrice': offerPrice,
        'repurchasePrice': repurchasePrice,
      };

  factory NavEntry.fromJson(Map<String, dynamic> json) => NavEntry(
        fundName: json['fundName'] as String,
        date: DateTime.parse(json['date'] as String),
        nav: (json['nav'] as num).toDouble(),
        offerPrice: (json['offerPrice'] as num?)?.toDouble(),
        repurchasePrice: (json['repurchasePrice'] as num?)?.toDouble(),
      );

  @override
  List<Object?> get props => [fundName, date, nav, offerPrice, repurchasePrice];

  @override
  String toString() => 'NavEntry($fundName, $date, NAV=$nav)';
}
