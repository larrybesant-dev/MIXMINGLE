/// Launch Readiness Report Widget
///
/// Displays a comprehensive pass/fail report of launch checklist items
/// with highlighted blockers and actionable recommendations.
library;

import 'package:flutter/material.dart';
import 'launch_checklist_service.dart';

/// Launch readiness report showing checklist results
class LaunchReadinessReport extends StatefulWidget {
  const LaunchReadinessReport({super.key});

  @override
  State<LaunchReadinessReport> createState() => _LaunchReadinessReportState();
}

class _LaunchReadinessReportState extends State<LaunchReadinessReport> {
  final LaunchChecklistService _checklistService = LaunchChecklistService.instance;

  FullChecklistReport? _report;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _runVerification();
  }

  Future<void> _runVerification() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final report = await _checklistService.runFullVerification();
      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Launch Readiness'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runVerification,
            tooltip: 'Re-run verification',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Running launch checklist...'),
            SizedBox(height: 8),
            Text(
              'This may take a moment',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _runVerification,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final report = _report;
    if (report == null) {
      return const Center(child: Text('No report available'));
    }

    return RefreshIndicator(
      onRefresh: _runVerification,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Launch Ready Banner
          _LaunchReadyBanner(report: report),
          const SizedBox(height: 24),

          // Summary Stats
          _SummaryStats(report: report),
          const SizedBox(height: 24),

          // Blockers Section (if any)
          if (report.blockers.isNotEmpty) ...[
            _BlockersSection(blockers: report.blockers),
            const SizedBox(height: 24),
          ],

          // Category Results
          ...report.results.map((result) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _CategoryCard(result: result),
          )),

          const SizedBox(height: 24),

          // Timestamp
          Text(
            'Report generated: ${_formatTimestamp(report.timestamp)}',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// Launch ready banner
class _LaunchReadyBanner extends StatelessWidget {
  final FullChecklistReport report;

  const _LaunchReadyBanner({required this.report});

  @override
  Widget build(BuildContext context) {
    final isReady = report.launchReady;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isReady
              ? [Colors.green.shade400, Colors.green.shade700]
              : [Colors.orange.shade400, Colors.red.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isReady ? Colors.green : Colors.red).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            isReady ? Icons.rocket_launch : Icons.warning_rounded,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            isReady ? 'READY TO LAUNCH! 🚀' : 'NOT READY YET',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isReady
                ? 'All ${report.totalCategories} categories passed verification'
                : '${report.blockers.length} items need attention',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

/// Summary stats row
class _SummaryStats extends StatelessWidget {
  final FullChecklistReport report;

  const _SummaryStats({required this.report});

  @override
  Widget build(BuildContext context) {
    final totalChecks = report.results.fold<int>(
      0,
      (sum, r) => sum + r.totalCount,
    );
    final passedChecks = report.results.fold<int>(
      0,
      (sum, r) => sum + r.passedCount,
    );
    final failedChecks = totalChecks - passedChecks;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Categories',
            value: '${report.passedCategories}/${report.totalCategories}',
            color: Colors.blue,
            icon: Icons.category,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Passed',
            value: passedChecks.toString(),
            color: Colors.green,
            icon: Icons.check_circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Failed',
            value: failedChecks.toString(),
            color: failedChecks > 0 ? Colors.red : Colors.grey,
            icon: Icons.cancel,
          ),
        ),
      ],
    );
  }
}

/// Individual stat card
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Blockers section
class _BlockersSection extends StatelessWidget {
  final List<String> blockers;

  const _BlockersSection({required this.blockers});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.block, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text(
                  'Launch Blockers (${blockers.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...blockers.map((blocker) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error,
                    size: 16,
                    color: Colors.red.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      blocker,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

/// Category result card
class _CategoryCard extends StatefulWidget {
  final ChecklistResult result;

  const _CategoryCard({required this.result});

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: widget.result.passed
              ? Colors.green.shade200
              : Colors.orange.shade200,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.result.passed
                          ? Colors.green.shade100
                          : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.result.passed
                          ? Icons.check_circle
                          : Icons.warning,
                      color: widget.result.passed
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.result.category,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.result.passedCount}/${widget.result.totalCount} checks passed',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                ...widget.result.checks.map((check) => _CheckItemRow(check: check)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Check item row
class _CheckItemRow extends StatelessWidget {
  final CheckItem check;

  const _CheckItemRow({required this.check});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            check.passed ? Icons.check : Icons.close,
            size: 18,
            color: check.passed ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  check.name,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  check.details,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper function to show launch readiness report as modal
Future<void> showLaunchReadinessReport(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => const LaunchReadinessReport(),
    ),
  );
}

/// Export report as shareable text
String generateReportText(FullChecklistReport report) {
  final buffer = StringBuffer();

  buffer.writeln('═══════════════════════════════════════');
  buffer.writeln('        LAUNCH READINESS REPORT');
  buffer.writeln('═══════════════════════════════════════');
  buffer.writeln();
  buffer.writeln('Status: ${report.launchReady ? "✅ READY TO LAUNCH" : "⚠️ NOT READY"}');
  buffer.writeln('Generated: ${report.timestamp}');
  buffer.writeln();
  buffer.writeln('SUMMARY');
  buffer.writeln('───────────────────────────────────────');
  buffer.writeln('Categories: ${report.passedCategories}/${report.totalCategories} passed');

  final totalChecks = report.results.fold<int>(0, (sum, r) => sum + r.totalCount);
  final passedChecks = report.results.fold<int>(0, (sum, r) => sum + r.passedCount);
  buffer.writeln('Checks: $passedChecks/$totalChecks passed');
  buffer.writeln('Blockers: ${report.blockers.length}');
  buffer.writeln();

  if (report.blockers.isNotEmpty) {
    buffer.writeln('BLOCKERS');
    buffer.writeln('───────────────────────────────────────');
    for (final blocker in report.blockers) {
      buffer.writeln('  ❌ $blocker');
    }
    buffer.writeln();
  }

  buffer.writeln('DETAILED RESULTS');
  buffer.writeln('───────────────────────────────────────');

  for (final result in report.results) {
    buffer.writeln();
    buffer.writeln('${result.passed ? "✅" : "⚠️"} ${result.category} (${result.passedCount}/${result.totalCount})');
    for (final check in result.checks) {
      buffer.writeln('  ${check.passed ? "✓" : "✗"} ${check.name}');
      buffer.writeln('    └─ ${check.details}');
    }
  }

  buffer.writeln();
  buffer.writeln('═══════════════════════════════════════');

  return buffer.toString();
}
