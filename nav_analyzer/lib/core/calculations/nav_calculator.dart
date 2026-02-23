import '../models/nav_entry.dart';
import '../models/transaction_entry.dart';
import '../models/analysis_result.dart';
import '../utils/outlier_filter.dart';
import 'xirr.dart';

/// Core calculation engine for NAV analysis.
///
/// All methods are pure functions suitable for running in isolates.
class NavCalculator {
  NavCalculator._();

  /// Perform complete analysis for a fund.
  static AnalysisResult analyze({
    required String fundName,
    required List<NavEntry> navHistory,
    required List<TransactionEntry> transactions,
    required double outlierK,
    required bool filterOutliers,
    int? lastNMonths,
  }) {
    // Filter to only purchase transactions
    final purchases =
        transactions.where((t) => t.type.isPurchase).toList()
          ..sort((a, b) => a.priceDate.compareTo(b.priceDate));

    // Sort NAV history by date
    final sortedNav = List<NavEntry>.from(navHistory)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Apply time filter
    List<NavEntry> timeFilteredNav = sortedNav;
    if (lastNMonths != null && sortedNav.isNotEmpty) {
      final cutoff = DateTime(
        sortedNav.last.date.year,
        sortedNav.last.date.month - lastNMonths,
        sortedNav.last.date.day,
      );
      timeFilteredNav = sortedNav.where((e) => e.date.isAfter(cutoff)).toList();
    }

    // Apply outlier filter
    final filteredNav = filterOutliers
        ? OutlierFilter.filter(timeFilteredNav, k: outlierK)
        : timeFilteredNav;

    // Basic calculations
    final totalInvested = _totalInvested(purchases);
    final totalUnits = _totalUnits(purchases);
    final averageCost =
        totalUnits > 0 ? totalInvested / totalUnits : 0.0;

    final latestNav =
        sortedNav.isNotEmpty ? sortedNav.last.nav : 0.0;
    final latestNavDate = sortedNav.isNotEmpty
        ? sortedNav.last.date
        : DateTime.now();

    final portfolioValue = totalUnits * latestNav;
    final unrealizedPnL = portfolioValue - totalInvested;
    final unrealizedPnLPercent =
        totalInvested > 0 ? (unrealizedPnL / totalInvested) * 100 : 0.0;

    // XIRR
    final xirr = _calculateXirr(purchases, portfolioValue, latestNavDate);

    // Monthly returns
    final monthlyReturns = _calculateMonthlyReturns(filteredNav);

    // Portfolio snapshots
    final portfolioSnapshots =
        _calculatePortfolioSnapshots(sortedNav, purchases);

    return AnalysisResult(
      fundName: fundName,
      totalInvested: totalInvested,
      totalUnits: totalUnits,
      averageCost: averageCost,
      latestNav: latestNav,
      latestNavDate: latestNavDate,
      portfolioValue: portfolioValue,
      unrealizedPnL: unrealizedPnL,
      unrealizedPnLPercent: unrealizedPnLPercent,
      xirr: xirr,
      navHistory: sortedNav,
      filteredNavHistory: filteredNav,
      purchases: purchases,
      monthlyReturns: monthlyReturns,
      portfolioSnapshots: portfolioSnapshots,
    );
  }

  static double _totalInvested(List<TransactionEntry> purchases) {
    return purchases.fold(0.0, (sum, t) => sum + t.netAmount);
  }

  static double _totalUnits(List<TransactionEntry> purchases) {
    return purchases.fold(0.0, (sum, t) => sum + t.units);
  }

  /// Calculate XIRR using purchase cash flows and current valuation.
  static double? _calculateXirr(
    List<TransactionEntry> purchases,
    double currentValue,
    DateTime valuationDate,
  ) {
    if (purchases.isEmpty || currentValue <= 0) return null;

    final cashFlows = <CashFlow>[];

    // Each purchase is a negative cash flow (money going out)
    for (final p in purchases) {
      cashFlows.add(CashFlow(
        date: p.priceDate,
        amount: -p.netAmount,
      ));
    }

    // Current valuation is a positive cash flow (what you'd get if you sold)
    cashFlows.add(CashFlow(
      date: valuationDate,
      amount: currentValue,
    ));

    return XirrCalculator.calculate(cashFlows);
  }

  /// Calculate month-over-month returns from NAV data.
  static List<MonthlyReturn> _calculateMonthlyReturns(List<NavEntry> navData) {
    if (navData.length < 2) return [];

    // Group by month, take last entry of each month
    final monthEndNavs = <String, NavEntry>{};
    for (final entry in navData) {
      final key =
          '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}';
      if (!monthEndNavs.containsKey(key) ||
          entry.date.isAfter(monthEndNavs[key]!.date)) {
        monthEndNavs[key] = entry;
      }
    }

    final sortedKeys = monthEndNavs.keys.toList()..sort();
    final returns = <MonthlyReturn>[];

    for (int i = 1; i < sortedKeys.length; i++) {
      final prevEntry = monthEndNavs[sortedKeys[i - 1]]!;
      final currEntry = monthEndNavs[sortedKeys[i]]!;

      final returnPercent = prevEntry.nav > 0
          ? ((currEntry.nav - prevEntry.nav) / prevEntry.nav) * 100
          : 0.0;

      returns.add(MonthlyReturn(
        month: currEntry.date,
        startNav: prevEntry.nav,
        endNav: currEntry.nav,
        returnPercent: returnPercent,
      ));
    }

    return returns;
  }

  /// Build cumulative invested vs portfolio value snapshots.
  static List<PortfolioSnapshot> _calculatePortfolioSnapshots(
    List<NavEntry> navData,
    List<TransactionEntry> purchases,
  ) {
    if (navData.isEmpty || purchases.isEmpty) return [];

    final sortedPurchases = List<TransactionEntry>.from(purchases)
      ..sort((a, b) => a.priceDate.compareTo(b.priceDate));

    final snapshots = <PortfolioSnapshot>[];
    double cumulativeInvested = 0;
    double cumulativeUnits = 0;
    int purchaseIndex = 0;

    for (final navEntry in navData) {
      // Add any purchases on or before this date
      while (purchaseIndex < sortedPurchases.length &&
          !sortedPurchases[purchaseIndex].priceDate.isAfter(navEntry.date)) {
        cumulativeInvested += sortedPurchases[purchaseIndex].netAmount;
        cumulativeUnits += sortedPurchases[purchaseIndex].units;
        purchaseIndex++;
      }

      // Only add snapshots after first purchase
      if (cumulativeUnits > 0) {
        snapshots.add(PortfolioSnapshot(
          date: navEntry.date,
          cumulativeInvested: cumulativeInvested,
          portfolioValue: cumulativeUnits * navEntry.nav,
        ));
      }
    }

    return snapshots;
  }
}
