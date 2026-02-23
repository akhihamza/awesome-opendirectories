import 'package:flutter/material.dart';

/// Wrapper widget for chart sections with title and optional legend.
class ChartSection extends StatelessWidget {
  final String title;
  final Widget chart;
  final double height;
  final List<ChartLegendItem>? legend;

  const ChartSection({
    super.key,
    required this.title,
    required this.chart,
    this.height = 280,
    this.legend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (legend != null) ..._buildLegend(context),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: height,
              child: chart,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLegend(BuildContext context) {
    final theme = Theme.of(context);
    return legend!.map((item) {
      return Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 3,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              item.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

/// Legend item for chart sections.
class ChartLegendItem {
  final String label;
  final Color color;

  const ChartLegendItem({required this.label, required this.color});
}
