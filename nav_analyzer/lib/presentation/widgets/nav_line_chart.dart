import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/nav_entry.dart';
import '../../core/models/transaction_entry.dart';

/// Interactive NAV line chart with purchase markers.
class NavLineChart extends StatelessWidget {
  final List<NavEntry> navData;
  final List<TransactionEntry> purchases;
  final bool showPurchaseMarkers;

  const NavLineChart({
    super.key,
    required this.navData,
    this.purchases = const [],
    this.showPurchaseMarkers = true,
  });

  @override
  Widget build(BuildContext context) {
    if (navData.isEmpty) {
      return const Center(child: Text('No NAV data available'));
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final sortedData = List<NavEntry>.from(navData)
      ..sort((a, b) => a.date.compareTo(b.date));

    final minDate = sortedData.first.date;
    final navValues = sortedData.map((e) => e.nav).toList();
    final minNav = navValues.reduce(min);
    final maxNav = navValues.reduce(max);
    final navPadding = (maxNav - minNav) * 0.1;

    // Build line spots
    final spots = sortedData.map((entry) {
      final x = entry.date.difference(minDate).inDays.toDouble();
      return FlSpot(x, entry.nav);
    }).toList();

    // Build purchase marker spots
    final purchaseSpots = <FlSpot>[];
    if (showPurchaseMarkers) {
      for (final purchase in purchases) {
        // Find closest NAV entry to purchase date
        NavEntry? closest;
        int? closestDiff;
        for (final nav in sortedData) {
          final diff = nav.date.difference(purchase.priceDate).inDays.abs();
          if (closestDiff == null || diff < closestDiff) {
            closestDiff = diff;
            closest = nav;
          }
        }
        if (closest != null) {
          final x = closest.date.difference(minDate).inDays.toDouble();
          purchaseSpots.add(FlSpot(x, closest.nav));
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 8),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _calculateInterval(minNav, maxNav),
            getDrawingHorizontalLine: (value) => FlLine(
              color: colorScheme.outlineVariant.withOpacity(0.3),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 56,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      value.toStringAsFixed(1),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: _calculateDateInterval(sortedData),
                getTitlesWidget: (value, meta) {
                  final date = minDate.add(Duration(days: value.toInt()));
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('MMM yy').format(date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: minNav - navPadding,
          maxY: maxNav + navPadding,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  final date = minDate.add(Duration(days: spot.x.toInt()));
                  return LineTooltipItem(
                    '${DateFormat('dd MMM yyyy').format(date)}\nNAV: ${spot.y.toStringAsFixed(4)}',
                    TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            // NAV line
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.2,
              color: colorScheme.primary,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: colorScheme.primary.withOpacity(0.08),
              ),
            ),
            // Purchase markers
            if (purchaseSpots.isNotEmpty)
              LineChartBarData(
                spots: purchaseSpots,
                isCurved: false,
                color: Colors.transparent,
                barWidth: 0,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) {
                    return FlDotCirclePainter(
                      radius: 5,
                      color: colorScheme.tertiary,
                      strokeWidth: 2,
                      strokeColor: colorScheme.onTertiary,
                    );
                  },
                ),
              ),
          ],
        ),
        duration: const Duration(milliseconds: 300),
      ),
    );
  }

  double _calculateInterval(double min, double max) {
    final range = max - min;
    if (range <= 0) return 1;
    final rawInterval = range / 5;
    final magnitude = pow(10, (log(rawInterval) / ln10).floor()).toDouble();
    return (rawInterval / magnitude).ceil() * magnitude;
  }

  double _calculateDateInterval(List<NavEntry> data) {
    if (data.length < 2) return 30;
    final totalDays =
        data.last.date.difference(data.first.date).inDays.toDouble();
    if (totalDays <= 90) return 7;
    if (totalDays <= 365) return 30;
    if (totalDays <= 730) return 60;
    return 90;
  }
}
