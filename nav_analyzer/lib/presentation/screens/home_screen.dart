import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/transaction_entry.dart';
import '../../domain/entities/app_state.dart';
import '../providers/analysis_notifier.dart';
import '../providers/app_providers.dart';
import '../widgets/manual_entry_dialog.dart';
import 'dashboard_screen.dart';

/// Home screen for uploading files and configuring analysis.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analysisNotifierProvider);
    final notifier = ref.read(analysisNotifierProvider.notifier);
    final isDark = ref.watch(darkModeProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NAV Analyzer'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => ref.read(darkModeProvider.notifier).state = !isDark,
            tooltip: isDark ? 'Light mode' : 'Dark mode',
          ),
          if (state.navFile.isLoaded)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: notifier.reset,
              tooltip: 'Reset',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Mutual Fund Analysis',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Upload NAV data and transaction statements for offline analysis',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // NAV File Upload
              _FileUploadCard(
                title: 'NAV Excel File',
                subtitle: 'MUFAP format (.xlsx)',
                icon: Icons.table_chart_outlined,
                status: state.navFile.status,
                filePath: state.navFile.filePath,
                resultInfo: state.navFile.isLoaded
                    ? '${state.navFile.result!.entries.length} entries, '
                        '${state.navFile.fundNames.length} funds'
                    : null,
                error: state.navFile.error,
                onTap: notifier.loadNavFile,
              ),

              const SizedBox(height: 16),

              // PDF File Upload
              _FileUploadCard(
                title: 'Transaction PDF',
                subtitle: 'UBL format statement (.pdf)',
                icon: Icons.picture_as_pdf_outlined,
                status: state.pdfFile.status,
                filePath: state.pdfFile.filePath,
                resultInfo: state.pdfFile.isLoaded
                    ? '${state.pdfFile.result!.transactions.length} transactions, '
                        '${state.pdfFile.fundNames.length} funds'
                    : null,
                error: state.pdfFile.error,
                onTap: notifier.loadPdfFile,
              ),

              // Manual entry option
              if (state.navFile.isLoaded) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add transaction manually'),
                    onPressed: () => _showManualEntryDialog(
                      context,
                      notifier,
                      state.allFundNames,
                      state.preferences.selectedFund,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Fund Selection
              if (state.allFundNames.isNotEmpty) ...[
                Text(
                  'Select Fund',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: state.preferences.selectedFund,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  isExpanded: true,
                  items: state.allFundNames
                      .map((f) => DropdownMenuItem(
                            value: f,
                            child: Text(
                              f,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) notifier.selectFund(v);
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Last N Months Slider
              if (state.navFile.isLoaded) ...[
                Row(
                  children: [
                    Text(
                      'Time Period',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      state.preferences.lastNMonths == null
                          ? 'All data'
                          : '${state.preferences.lastNMonths} months',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: (state.preferences.lastNMonths ?? 0).toDouble(),
                  min: 0,
                  max: 60,
                  divisions: 12,
                  label: state.preferences.lastNMonths == null ||
                          state.preferences.lastNMonths == 0
                      ? 'All'
                      : '${state.preferences.lastNMonths}mo',
                  onChanged: (v) {
                    notifier.setLastNMonths(v == 0 ? null : v.toInt());
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Outlier Filter
              if (state.navFile.isLoaded) ...[
                Row(
                  children: [
                    Text(
                      'Outlier Filter',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: state.preferences.filterOutliers,
                      onChanged: notifier.setFilterOutliers,
                    ),
                  ],
                ),
                if (state.preferences.filterOutliers) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'IQR multiplier (k)',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        state.preferences.outlierK.toStringAsFixed(1),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: state.preferences.outlierK,
                    min: 1.5,
                    max: 6.0,
                    divisions: 9,
                    label: state.preferences.outlierK.toStringAsFixed(1),
                    onChanged: notifier.setOutlierK,
                  ),
                ],
                const SizedBox(height: 24),
              ],

              // Analyze Button
              if (state.canAnalyze) ...[
                FilledButton.icon(
                  onPressed: state.analysis.status == LoadingStatus.loading
                      ? null
                      : () async {
                          await notifier.runAnalysis();
                          if (context.mounted &&
                              ref
                                  .read(analysisNotifierProvider)
                                  .analysis
                                  .hasResult) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const DashboardScreen(),
                              ),
                            );
                          }
                        },
                  icon: state.analysis.status == LoadingStatus.loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.analytics_outlined),
                  label: Text(
                    state.analysis.status == LoadingStatus.loading
                        ? 'Analyzing...'
                        : 'Run Analysis',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],

              // Error display
              if (state.analysis.status == LoadingStatus.error) ...[
                const SizedBox(height: 16),
                Card(
                  color: colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: colorScheme.onErrorContainer),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state.analysis.error ?? 'Analysis failed',
                            style: TextStyle(
                                color: colorScheme.onErrorContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showManualEntryDialog(
    BuildContext context,
    AnalysisNotifier notifier,
    List<String> fundNames,
    String? selectedFund,
  ) async {
    final result = await showDialog<TransactionEntry>(
      context: context,
      builder: (_) => ManualEntryDialog(
        fundName: selectedFund,
        fundNames: fundNames,
      ),
    );

    if (result != null) {
      notifier.addManualTransaction(result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction added')),
        );
      }
    }
  }
}

/// File upload card widget.
class _FileUploadCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final LoadingStatus status;
  final String? filePath;
  final String? resultInfo;
  final String? error;
  final VoidCallback onTap;

  const _FileUploadCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.status,
    this.filePath,
    this.resultInfo,
    this.error,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isSuccess = status == LoadingStatus.success;
    final isLoading = status == LoadingStatus.loading;
    final isError = status == LoadingStatus.error;

    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSuccess
                ? const Color(0xFF4CAF50).withOpacity(0.5)
                : isError
                    ? colorScheme.error.withOpacity(0.5)
                    : colorScheme.outlineVariant,
            width: isSuccess || isError ? 2 : 1,
          ),
          color: isSuccess
              ? const Color(0xFF4CAF50).withOpacity(0.04)
              : isError
                  ? colorScheme.error.withOpacity(0.04)
                  : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSuccess
                    ? const Color(0xFF4CAF50).withOpacity(0.12)
                    : colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      isSuccess ? Icons.check_circle : icon,
                      color: isSuccess
                          ? const Color(0xFF4CAF50)
                          : colorScheme.primary,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isSuccess && resultInfo != null
                        ? resultInfo!
                        : isError
                            ? error ?? 'Failed to load'
                            : subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isError
                          ? colorScheme.error
                          : colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (filePath != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _fileName(filePath!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.upload_file,
              color: colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  String _fileName(String path) {
    return path.split('/').last;
  }
}
