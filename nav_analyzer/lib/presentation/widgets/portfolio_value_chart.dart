import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/analysis_result.dart';

/// Chart showing cumulative invested vs portfolio value over time.
class PortfolioValueChart extends StatelessWidget {
  final List<PortfolioSnapshot> snapshots;

  const PortfolioValueChart({
    super.key,
    required this.snapshots,
  });

  @override
  Widget build(BuildContext context) {
    if (snapshots.isEmpty) {
      return const Center(child: Text('No portfolio data available'));
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final minDate = snapshots.first.date;

    final allValues = [
      ...snapshots.map((s) => s.cumulativeInvested),
      ...snapshots.map((s) => s.portfolioValue),
    ];
    final minVal = allValues.reduce(min);
    final maxVal = allValues.reduce(max);
    final padding = (maxVal - minVal) * 0.1;

    // Downsample if too many points (keep ~200 points max)
    final displaySnapshots = _downsample(snapshots, 200);

    final investedSpots = displaySnapshots.map((s) {
      final x = s.date.difference(minDate).inDays.toDouble();
      return FlSpot(x, s.cumulativeInvested);
    }).toList();

    final valueSpots = displaySnapshots.map((s) {
      final x = s.date.difference(minDate).inDays.toDouble();
      return FlSpot(x, s.portfolioValue);
    }).toList();

    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 8),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: colorScheme.outlineVariant.withOpacity(0.3),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 64,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _formatCompact(value),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
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
          minY: max(0, minVal - padding),
          maxY: maxVal + padding,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  final date = minDate.add(Duration(days: spot.x.toInt()));
                  final label = spot.barIndex == 0 ? 'Invested' : 'Value';
                  return LineTooltipItem(
                    '$label: ${NumberFormat('#,##0').format(spot.y)}\n${DateFormat('dd MMM yyyy').format(date)}',
                    TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            // Cumulative invested line
            LineChartBarData(
              spots: investedSpots,
              isCurved: false,
              color: colorScheme.secondary,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              dashArray: [8, 4],
            ),
            // Portfolio value line
            LineChartBarData(
              spots: valueSpots,
              isCurved: true,
              curveSmoothness: 0.15,
              color: colorScheme.primary,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: colorScheme.primary.withOpacity(0.06),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 300),
      ),
    );
  }

  String _formatCompact(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }

  List<PortfolioSnapshot> _downsample(
      List<PortfolioSnapshot> data, int maxPoints) {
    if (data.length <= maxPoints) return data;

    final step = data.length / maxPoints;
    final result = <PortfolioSnapshot>[];
    for (double i = 0; i < data.length; i += step) {
      result.add(data[i.floor()]);
    }
    // Always include last point
    if (result.last != data.last) {
      result.add(data.last);
    }
    return result;
  }
}
