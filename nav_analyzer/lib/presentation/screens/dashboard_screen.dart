import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/utils/number_utils.dart';
import '../../core/utils/date_utils.dart';
import '../providers/analysis_notifier.dart';
import '../providers/app_providers.dart';
import '../widgets/widgets.dart';

/// Dashboard screen displaying analysis results and charts.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analysisNotifierProvider);
    final notifier = ref.read(analysisNotifierProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final result = state.analysis.result;
    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: const Center(child: Text('No analysis result available')),
      );
    }

    final pnlColor =
        result.unrealizedPnL >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFEF5350);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          result.fundName,
          style: const TextStyle(fontSize: 14),
        ),
        centerTitle: true,
        actions: [
          // Save portfolio
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save portfolio',
            onPressed: () async {
              await notifier.savePortfolio();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Portfolio saved')),
                );
              }
            },
          ),
          // Export CSV
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export CSV',
            onPressed: () async {
              final path = await notifier.exportCsv();
              if (context.mounted) {
                if (path != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Exported to $path'),
                      action: SnackBarAction(
                        label: 'Share',
                        onPressed: () => Share.shareXFiles([XFile(path)]),
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export failed')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary Cards Grid
            _buildSummaryGrid(context, result, pnlColor),

            const SizedBox(height: 24),

            // NAV Chart
            ChartSection(
              title: 'NAV History',
              chart: NavLineChart(
                navData: result.filteredNavHistory,
                purchases: result.purchases,
              ),
              height: 300,
              legend: [
                ChartLegendItem(
                  label: 'NAV',
                  color: colorScheme.primary,
                ),
                if (result.purchases.isNotEmpty)
                  ChartLegendItem(
                    label: 'Purchases',
                    color: colorScheme.tertiary,
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Monthly Returns Chart
            if (result.monthlyReturns.isNotEmpty) ...[
              ChartSection(
                title: 'Monthly Returns',
                chart: MonthlyReturnChart(
                  returns: result.monthlyReturns,
                ),
                height: 250,
                legend: const [
                  ChartLegendItem(
                    label: 'Positive',
                    color: Color(0xFF4CAF50),
                  ),
                  ChartLegendItem(
                    label: 'Negative',
                    color: Color(0xFFEF5350),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Portfolio Value Chart
            if (result.portfolioSnapshots.isNotEmpty) ...[
              ChartSection(
                title: 'Invested vs Portfolio Value',
                chart: PortfolioValueChart(
                  snapshots: result.portfolioSnapshots,
                ),
                height: 300,
                legend: [
                  ChartLegendItem(
                    label: 'Invested',
                    color: colorScheme.secondary,
                  ),
                  ChartLegendItem(
                    label: 'Value',
                    color: colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Transactions Table
            if (result.purchases.isNotEmpty) ...[
              _buildTransactionsCard(context, result),
              const SizedBox(height: 16),
            ],

            // Parse info
            _buildInfoCard(context, result),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(
      BuildContext context, dynamic result, Color pnlColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;

        final cards = [
          SummaryCard(
            title: 'Total Invested',
            value: NumberUtils.formatCurrency(result.totalInvested),
            icon: Icons.account_balance_wallet_outlined,
          ),
          SummaryCard(
            title: 'Total Units',
            value: NumberUtils.formatUnits(result.totalUnits),
            icon: Icons.inventory_2_outlined,
          ),
          SummaryCard(
            title: 'Latest NAV',
            value: NumberUtils.formatNumber(result.latestNav, decimals: 4),
            icon: Icons.show_chart,
            subtitle: AppDateUtils.format(result.latestNavDate),
          ),
          SummaryCard(
            title: 'Avg Cost',
            value: NumberUtils.formatNumber(result.averageCost, decimals: 4),
            icon: Icons.calculate_outlined,
          ),
          SummaryCard(
            title: 'Portfolio Value',
            value: NumberUtils.formatCurrency(result.portfolioValue),
            icon: Icons.pie_chart_outline,
          ),
          SummaryCard(
            title: 'Unrealized P/L',
            value:
                '${result.unrealizedPnL >= 0 ? '+' : ''}${NumberUtils.formatCurrency(result.unrealizedPnL)}',
            icon: result.unrealizedPnL >= 0
                ? Icons.trending_up
                : Icons.trending_down,
            valueColor: pnlColor,
            subtitle: '${result.unrealizedPnLPercent >= 0 ? '+' : ''}${NumberUtils.formatPercent(result.unrealizedPnLPercent)}',
          ),
          if (result.xirr != null)
            SummaryCard(
              title: 'XIRR',
              value: NumberUtils.formatPercent(result.xirr! * 100),
              icon: Icons.speed,
              valueColor: result.xirr! >= 0
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFEF5350),
              subtitle: 'Annualized return',
            ),
        ];

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.6,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: cards,
        );
      },
    );
  }

  Widget _buildTransactionsCard(BuildContext context, dynamic result) {
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
            Text(
              'Purchase History',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                headingRowHeight: 36,
                dataRowMinHeight: 32,
                dataRowMaxHeight: 40,
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Net Amount'), numeric: true),
                  DataColumn(label: Text('NAV'), numeric: true),
                  DataColumn(label: Text('Units'), numeric: true),
                ],
                rows: result.purchases.map<DataRow>((p) {
                  return DataRow(cells: [
                    DataCell(Text(
                      AppDateUtils.format(p.priceDate),
                      style: theme.textTheme.bodySmall,
                    )),
                    DataCell(Text(
                      p.type.name
                          .replaceAllMapped(
                            RegExp(r'[A-Z]'),
                            (m) => ' ${m.group(0)}',
                          )
                          .trim(),
                      style: theme.textTheme.bodySmall,
                    )),
                    DataCell(Text(
                      NumberUtils.formatNumber(p.netAmount),
                      style: theme.textTheme.bodySmall,
                    )),
                    DataCell(Text(
                      NumberUtils.formatNumber(p.nav, decimals: 4),
                      style: theme.textTheme.bodySmall,
                    )),
                    DataCell(Text(
                      NumberUtils.formatUnits(p.units),
                      style: theme.textTheme.bodySmall,
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, dynamic result) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analysis Info',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            _infoRow('NAV data points', '${result.navHistory.length}'),
            _infoRow('Filtered points', '${result.filteredNavHistory.length}'),
            _infoRow('Purchases', '${result.purchases.length}'),
            _infoRow(
              'Date range',
              result.navHistory.isNotEmpty
                  ? '${AppDateUtils.format(result.navHistory.first.date)} - '
                      '${AppDateUtils.format(result.navHistory.last.date)}'
                  : 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(value,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
