/// Live Monitoring Dashboard Widget
///
/// Displays key app health metrics with color-coded status indicators.
library;

import 'package:flutter/material.dart';
import 'monitoring_service.dart';

/// Live monitoring dashboard showing app health metrics
class MonitoringDashboard extends StatefulWidget {
  const MonitoringDashboard({super.key});

  @override
  State<MonitoringDashboard> createState() => _MonitoringDashboardState();
}

class _MonitoringDashboardState extends State<MonitoringDashboard> {
  final MonitoringService _monitoringService = MonitoringService.instance;

  DashboardSnapshot? _snapshot;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final snapshot = await _monitoringService.getDashboardSnapshot();
      setState(() {
        _snapshot = snapshot;
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
        title: const Text('Live Monitoring'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
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
            Text('Loading metrics...'),
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
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final snapshot = _snapshot;
    if (snapshot == null) {
      return const Center(child: Text('No data available'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Overall Health Banner
          _OverallHealthBanner(status: snapshot.overallHealth),
          const SizedBox(height: 24),

          // Timestamp
          Text(
            'Last updated: ${_formatTimestamp(snapshot.timestamp)}',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Metrics Grid
          _MetricsGrid(
            crashMetrics: snapshot.crashMetrics,
            roomJoinMetrics: snapshot.roomJoinMetrics,
            videoMetrics: snapshot.videoMetrics,
            retentionMetrics: snapshot.retentionMetrics,
            conversionMetrics: snapshot.conversionMetrics,
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// Overall health status banner
class _OverallHealthBanner extends StatelessWidget {
  final HealthStatus status;

  const _OverallHealthBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getStatusColor(status), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getStatusIcon(status),
            color: _getStatusColor(status),
            size: 48,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'System Health',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                _getStatusText(status),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Metrics grid displaying all metric cards
class _MetricsGrid extends StatelessWidget {
  final CrashMetrics crashMetrics;
  final RoomJoinMetrics roomJoinMetrics;
  final VideoMetrics videoMetrics;
  final RetentionMetrics retentionMetrics;
  final ConversionMetrics conversionMetrics;

  const _MetricsGrid({
    required this.crashMetrics,
    required this.roomJoinMetrics,
    required this.videoMetrics,
    required this.retentionMetrics,
    required this.conversionMetrics,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row 1: Crash-Free & Room Join
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Crash-Free Sessions',
                value: '${crashMetrics.crashFreeRate.toStringAsFixed(1)}%',
                subtitle: '${crashMetrics.totalSessions} total sessions',
                icon: Icons.phone_android,
                status: crashMetrics.status,
                details: [
                  'Crashes: ${crashMetrics.crashCount}',
                  'Target: â‰¥99.5%',
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Room Join Success',
                value: '${roomJoinMetrics.successRate.toStringAsFixed(1)}%',
                subtitle: '${roomJoinMetrics.totalAttempts} attempts',
                icon: Icons.meeting_room,
                status: roomJoinMetrics.status,
                details: [
                  'Failed: ${roomJoinMetrics.failedJoins}',
                  'Avg time: ${(roomJoinMetrics.averageJoinTimeMs / 1000).toStringAsFixed(1)}s',
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2: Video & Retention
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Video Reliability',
                value: '${videoMetrics.reliabilityScore.toStringAsFixed(1)}%',
                subtitle: '${videoMetrics.totalSessions} video sessions',
                icon: Icons.videocam,
                status: videoMetrics.status,
                details: [
                  'Reconnects: ${videoMetrics.reconnects}',
                  'Freezes: ${videoMetrics.freezes}',
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'D7 Retention',
                value: '${retentionMetrics.d7Retention.toStringAsFixed(1)}%',
                subtitle:
                    'DAU/MAU: ${retentionMetrics.stickiness.toStringAsFixed(1)}%',
                icon: Icons.trending_up,
                status: retentionMetrics.status,
                details: [
                  'D1: ${retentionMetrics.d1Retention.toStringAsFixed(1)}%',
                  'D30: ${retentionMetrics.d30Retention.toStringAsFixed(1)}%',
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 3: Conversion (Full width)
        _MetricCard(
          title: 'VIP Conversion',
          value: '${conversionMetrics.conversionRate.toStringAsFixed(2)}%',
          subtitle: '${conversionMetrics.totalUsers} total users',
          icon: Icons.star,
          status: conversionMetrics.status,
          details: [
            'VIP: ${conversionMetrics.vipUsers} | VIP+: ${conversionMetrics.vipPlusUsers}',
            'New: +${conversionMetrics.newConversions} | Churned: -${conversionMetrics.churned} | Net: ${conversionMetrics.netGrowth >= 0 ? '+' : ''}${conversionMetrics.netGrowth}',
          ],
        ),
        const SizedBox(height: 24),

        // Active Users Section
        _ActiveUsersCard(retentionMetrics: retentionMetrics),

        const SizedBox(height: 24),

        // Failure Breakdown
        if (roomJoinMetrics.failuresByReason.isNotEmpty)
          _FailureBreakdownCard(failures: roomJoinMetrics.failuresByReason),
      ],
    );
  }
}

/// Individual metric card
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final HealthStatus status;
  final List<String> details;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.status,
    this.details = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(status).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
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
                    color: _getStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: _getStatusColor(status), size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(status),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ...details.map((detail) => Text(
                    detail,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

/// Status badge indicator
class _StatusBadge extends StatelessWidget {
  final HealthStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getShortStatusText(status),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Active users card
class _ActiveUsersCard extends StatelessWidget {
  final RetentionMetrics retentionMetrics;

  const _ActiveUsersCard({required this.retentionMetrics});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Users',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _UserCountTile(
                    label: 'DAU',
                    count: retentionMetrics.dau,
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _UserCountTile(
                    label: 'WAU',
                    count: retentionMetrics.wau,
                    color: Colors.purple,
                  ),
                ),
                Expanded(
                  child: _UserCountTile(
                    label: 'MAU',
                    count: retentionMetrics.mau,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// User count tile
class _UserCountTile extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _UserCountTile({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _formatCount(count),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

/// Failure breakdown card
class _FailureBreakdownCard extends StatelessWidget {
  final Map<String, int> failures;

  const _FailureBreakdownCard({required this.failures});

  @override
  Widget build(BuildContext context) {
    final sortedEntries = failures.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = failures.values.fold(0, (sum, count) => sum + count);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Failure Breakdown',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...sortedEntries.map((entry) {
              final percentage = (entry.value / total * 100).toStringAsFixed(1);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatFailureReason(entry.key),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '${entry.value} ($percentage%)',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: entry.value / total,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation(Colors.red),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatFailureReason(String reason) {
    return reason
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }
}

// ============================================================
// HELPER FUNCTIONS
// ============================================================

Color _getStatusColor(HealthStatus status) {
  switch (status) {
    case HealthStatus.healthy:
      return Colors.green;
    case HealthStatus.warning:
      return Colors.orange;
    case HealthStatus.degraded:
      return Colors.deepOrange;
    case HealthStatus.critical:
      return Colors.red;
    case HealthStatus.unknown:
      return Colors.grey;
  }
}

IconData _getStatusIcon(HealthStatus status) {
  switch (status) {
    case HealthStatus.healthy:
      return Icons.check_circle;
    case HealthStatus.warning:
      return Icons.warning;
    case HealthStatus.degraded:
      return Icons.error;
    case HealthStatus.critical:
      return Icons.dangerous;
    case HealthStatus.unknown:
      return Icons.help;
  }
}

String _getStatusText(HealthStatus status) {
  switch (status) {
    case HealthStatus.healthy:
      return 'All Systems Operational';
    case HealthStatus.warning:
      return 'Minor Issues Detected';
    case HealthStatus.degraded:
      return 'Performance Degraded';
    case HealthStatus.critical:
      return 'Critical Issues';
    case HealthStatus.unknown:
      return 'Status Unknown';
  }
}

String _getShortStatusText(HealthStatus status) {
  switch (status) {
    case HealthStatus.healthy:
      return 'OK';
    case HealthStatus.warning:
      return 'WARN';
    case HealthStatus.degraded:
      return 'SLOW';
    case HealthStatus.critical:
      return 'CRIT';
    case HealthStatus.unknown:
      return '???';
  }
}

/// Helper function to show monitoring dashboard as modal
Future<void> showMonitoringDashboard(BuildContext context) {
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
      builder: (context, controller) => const MonitoringDashboard(),
    ),
  );
}
