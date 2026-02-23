import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/analysis_result.dart';

/// Bar chart showing monthly returns.
class MonthlyReturnChart extends StatelessWidget {
  final List<MonthlyReturn> returns;

  const MonthlyReturnChart({
    super.key,
    required this.returns,
  });

  @override
  Widget build(BuildContext context) {
    if (returns.isEmpty) {
      return const Center(child: Text('No monthly return data'));
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final maxReturn = returns.map((r) => r.returnPercent.abs()).reduce(max);
    final yMax = (maxReturn * 1.2).ceilToDouble();

    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 8),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: yMax,
          minY: -yMax,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _calculateInterval(yMax),
            getDrawingHorizontalLine: (value) => FlLine(
              color: colorScheme.outlineVariant.withOpacity(0.3),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toStringAsFixed(1)}%',
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
                  final index = value.toInt();
                  if (index < 0 || index >= returns.length) {
                    return const SizedBox.shrink();
                  }
                  // Show every Nth label to avoid overlap
                  final interval = (returns.length / 12).ceil();
                  if (index % interval != 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('MMM yy').format(returns[index].month),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 9,
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
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final data = returns[group.x.toInt()];
                return BarTooltipItem(
                  '${DateFormat('MMM yyyy').format(data.month)}\n${data.returnPercent.toStringAsFixed(2)}%',
                  TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          barGroups: returns.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            final isPositive = data.returnPercent >= 0;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: data.returnPercent,
                  color: isPositive
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFEF5350),
                  width: _calculateBarWidth(returns.length),
                  borderRadius: BorderRadius.vertical(
                    top: isPositive
                        ? const Radius.circular(4)
                        : Radius.zero,
                    bottom: isPositive
                        ? Radius.zero
                        : const Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        duration: const Duration(milliseconds: 300),
      ),
    );
  }

  double _calculateInterval(double maxVal) {
    if (maxVal <= 2) return 0.5;
    if (maxVal <= 5) return 1;
    if (maxVal <= 10) return 2;
    return 5;
  }

  double _calculateBarWidth(int count) {
    if (count <= 6) return 20;
    if (count <= 12) return 14;
    if (count <= 24) return 8;
    return 4;
  }
}
