import 'package:equatable/equatable.dart';

import 'nav_entry.dart';
import 'transaction_entry.dart';

/// Monthly return data point.
class MonthlyReturn extends Equatable {
  final DateTime month;
  final double startNav;
  final double endNav;
  final double returnPercent;

  const MonthlyReturn({
    required this.month,
    required this.startNav,
    required this.endNav,
    required this.returnPercent,
  });

  @override
  List<Object?> get props => [month, startNav, endNav, returnPercent];
}

/// Cumulative portfolio snapshot at a point in time.
class PortfolioSnapshot extends Equatable {
  final DateTime date;
  final double cumulativeInvested;
  final double portfolioValue;

  const PortfolioSnapshot({
    required this.date,
    required this.cumulativeInvested,
    required this.portfolioValue,
  });

  @override
  List<Object?> get props => [date, cumulativeInvested, portfolioValue];
}

/// Complete analysis result for a fund.
class AnalysisResult extends Equatable {
  final String fundName;
  final double totalInvested;
  final double totalUnits;
  final double averageCost;
  final double latestNav;
  final DateTime latestNavDate;
  final double portfolioValue;
  final double unrealizedPnL;
  final double unrealizedPnLPercent;
  final double? xirr;
  final List<NavEntry> navHistory;
  final List<NavEntry> filteredNavHistory;
  final List<TransactionEntry> purchases;
  final List<MonthlyReturn> monthlyReturns;
  final List<PortfolioSnapshot> portfolioSnapshots;

  const AnalysisResult({
    required this.fundName,
    required this.totalInvested,
    required this.totalUnits,
    required this.averageCost,
    required this.latestNav,
    required this.latestNavDate,
    required this.portfolioValue,
    required this.unrealizedPnL,
    required this.unrealizedPnLPercent,
    this.xirr,
    required this.navHistory,
    required this.filteredNavHistory,
    required this.purchases,
    required this.monthlyReturns,
    required this.portfolioSnapshots,
  });

  @override
  List<Object?> get props => [
        fundName,
        totalInvested,
        totalUnits,
        averageCost,
        latestNav,
        portfolioValue,
        unrealizedPnL,
        xirr,
      ];
}
