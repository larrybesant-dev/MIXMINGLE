/// Empire Dashboard Widget
///
/// Displays global DAU, platform charts, creator health, network load, and federation growth.
library;

import 'package:flutter/material.dart';

import 'empire_insights_service.dart';

/// Main empire analytics dashboard
class EmpireDashboard extends StatefulWidget {
  const EmpireDashboard({super.key});

  @override
  State<EmpireDashboard> createState() => _EmpireDashboardState();
}

class _EmpireDashboardState extends State<EmpireDashboard>
    with SingleTickerProviderStateMixin {
  final EmpireInsightsService _insights = EmpireInsightsService.instance;

  late TabController _tabController;

  DAUMetrics? _dauMetrics;
  CrossPlatformMetrics? _platformMetrics;
  CreatorEcosystemMetrics? _creatorMetrics;
  NetworkLoadMetrics? _networkMetrics;
  FederationGrowthMetrics? _federationMetrics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final snapshot = await _insights.getEmpireSnapshot();

      if (mounted) {
        setState(() {
          _dauMetrics = snapshot['dau'] as DAUMetrics;
          _platformMetrics = snapshot['platform'] as CrossPlatformMetrics;
          _creatorMetrics = snapshot['creator'] as CreatorEcosystemMetrics;
          _networkMetrics = snapshot['network'] as NetworkLoadMetrics;
          _federationMetrics = snapshot['federation'] as FederationGrowthMetrics;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [EmpireDashboard] Failed to load data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Empire Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'DAU'),
            Tab(icon: Icon(Icons.devices), text: 'Platforms'),
            Tab(icon: Icon(Icons.star), text: 'Creators'),
            Tab(icon: Icon(Icons.cloud), text: 'Network'),
            Tab(icon: Icon(Icons.hub), text: 'Federation'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDAUTab(),
                _buildPlatformsTab(),
                _buildCreatorsTab(),
                _buildNetworkTab(),
                _buildFederationTab(),
              ],
            ),
    );
  }

  // ============================================================
  // DAU TAB
  // ============================================================

  Widget _buildDAUTab() {
    if (_dauMetrics == null) {
      return const Center(child: Text('No DAU data available'));
    }

    final m = _dauMetrics!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Main DAU card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Daily Active Users',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _formatNumber(m.totalDAU.toDouble()),
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  Text(
                    _formatDate(m.date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // User breakdown
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'New Users',
                  m.newUsers.toString(),
                  Icons.person_add,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Returning',
                  m.returningUsers.toString(),
                  Icons.replay,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Retention',
                  '${(m.retentionRate * 100).toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Avg Session',
                  '${m.avgSessionDuration.toStringAsFixed(0)}m',
                  Icons.timer,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Platform breakdown
          if (m.byPlatform.isNotEmpty) _buildPlatformBreakdown(m.byPlatform),

          const SizedBox(height: 24),

          // Region breakdown
          if (m.byRegion.isNotEmpty) _buildRegionBreakdown(m.byRegion),
        ],
      ),
    );
  }

  Widget _buildPlatformBreakdown(Map<PlatformType, int> byPlatform) {
    final total = byPlatform.values.fold<int>(0, (a, b) => a + b);
    final sortedEntries = byPlatform.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'By Platform',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...sortedEntries.map((e) {
              final percentage = total > 0 ? e.value / total : 0.0;
              return _buildProgressRow(
                _getPlatformIcon(e.key),
                e.key.name,
                e.value,
                percentage,
                _getPlatformColor(e.key),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionBreakdown(Map<String, int> byRegion) {
    final total = byRegion.values.fold<int>(0, (a, b) => a + b);
    final sortedEntries = byRegion.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'By Region',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...sortedEntries.take(5).map((e) {
              final percentage = total > 0 ? e.value / total : 0.0;
              return _buildProgressRow(
                Icons.location_on,
                e.key,
                e.value,
                percentage,
                Colors.blue,
              );
            }),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PLATFORMS TAB
  // ============================================================

  Widget _buildPlatformsTab() {
    if (_platformMetrics == null) {
      return const Center(child: Text('No platform data available'));
    }

    final m = _platformMetrics!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Total and multi-platform
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Active',
                  _formatNumber(m.totalActiveUsers.toDouble()),
                  Icons.devices,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Multi-Platform',
                  _formatNumber(m.multiPlatformUsers.toDouble()),
                  Icons.sync_alt,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Per-platform cards
          ...PlatformType.values.map((platform) {
            final users = m.activeUsers[platform] ?? 0;
            final engagement = m.engagement[platform] ?? 0.0;
            final crashes = m.crashRate[platform] ?? 0.0;
            final loadTime = m.avgLoadTime[platform] ?? 0.0;

            return _buildPlatformDetailCard(
              platform,
              users,
              engagement,
              crashes,
              loadTime,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPlatformDetailCard(
    PlatformType platform,
    int users,
    double engagement,
    double crashRate,
    double loadTime,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(
          _getPlatformIcon(platform),
          color: _getPlatformColor(platform),
        ),
        title: Text(
          platform.name.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('$users active users'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Engagement', '${(engagement * 100).toInt()}%'),
                _buildStatColumn('Crash Rate', '${(crashRate * 100).toStringAsFixed(2)}%'),
                _buildStatColumn('Load Time', '${loadTime.toStringAsFixed(0)}ms'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  // ============================================================
  // CREATORS TAB
  // ============================================================

  Widget _buildCreatorsTab() {
    if (_creatorMetrics == null) {
      return const Center(child: Text('No creator data available'));
    }

    final m = _creatorMetrics!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Creator count
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Creators',
                  _formatNumber(m.totalCreators.toDouble()),
                  Icons.star,
                  Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Active (30d)',
                  _formatNumber(m.activeCreators.toDouble()),
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'New (30d)',
                  m.newCreators30d.toString(),
                  Icons.person_add,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Retention',
                  '${(m.creatorRetention * 100).toInt()}%',
                  Icons.replay,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Earnings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Creator Earnings',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn(
                        'Total Payout',
                        '\$${_formatNumber(m.totalPayout)}',
                      ),
                      _buildStatColumn(
                        'Average',
                        '\$${m.avgEarnings.toStringAsFixed(0)}',
                      ),
                      _buildStatColumn(
                        'Median',
                        '\$${m.medianEarnings.toStringAsFixed(0)}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Tier distribution
          _buildTierDistribution(m.byTier),
        ],
      ),
    );
  }

  Widget _buildTierDistribution(Map<CreatorTier, int> byTier) {
    final total = byTier.values.fold<int>(0, (a, b) => a + b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Creator Tiers',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...CreatorTier.values.map((tier) {
              final count = byTier[tier] ?? 0;
              final percentage = total > 0 ? count / total : 0.0;
              return _buildProgressRow(
                _getTierIcon(tier),
                tier.name,
                count,
                percentage,
                _getTierColor(tier),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NETWORK TAB
  // ============================================================

  Widget _buildNetworkTab() {
    if (_networkMetrics == null) {
      return const Center(child: Text('No network data available'));
    }

    final m = _networkMetrics!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Utilization gauges
          Row(
            children: [
              Expanded(child: _buildGauge('CPU', m.cpuUtilization, Colors.blue)),
              Expanded(child: _buildGauge('Memory', m.memoryUtilization, Colors.purple)),
              Expanded(child: _buildGauge('Bandwidth', m.bandwidthUtilization, Colors.orange)),
            ],
          ),
          const SizedBox(height: 24),

          // Key metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Connections',
                  _formatNumber(m.activeConnections.toDouble()),
                  Icons.link,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'RPS',
                  _formatNumber(m.requestsPerSecond.toDouble()),
                  Icons.speed,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Avg Latency',
                  '${m.avgLatency.toStringAsFixed(0)}ms',
                  Icons.timer,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'P99 Latency',
                  '${m.p99Latency.toStringAsFixed(0)}ms',
                  Icons.show_chart,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Edge nodes
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edge Nodes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('Online', '${m.edgeNodesOnline}'),
                      _buildStatColumn('Total', '${m.edgeNodesTotal}'),
                      _buildStatColumn(
                        'Health',
                        '${(m.edgeNodeHealth * 100).toStringAsFixed(0)}%',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: m.edgeNodeHealth,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      m.edgeNodeHealth > 0.9
                          ? Colors.green
                          : m.edgeNodeHealth > 0.7
                              ? Colors.orange
                              : Colors.red,
                    ),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Error rate
          Card(
            color: m.errorRate > 0.01
                ? Colors.red.withValues(alpha: 0.1)
                : Colors.green.withValues(alpha: 0.1),
            child: ListTile(
              leading: Icon(
                m.errorRate > 0.01 ? Icons.error : Icons.check_circle,
                color: m.errorRate > 0.01 ? Colors.red : Colors.green,
              ),
              title: const Text('Error Rate'),
              trailing: Text(
                '${(m.errorRate * 100).toStringAsFixed(3)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: m.errorRate > 0.01 ? Colors.red : Colors.green,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGauge(String label, double value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: value,
                    backgroundColor: color.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    strokeWidth: 8,
                  ),
                  Text(
                    '${(value * 100).toInt()}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FEDERATION TAB
  // ============================================================

  Widget _buildFederationTab() {
    if (_federationMetrics == null) {
      return const Center(child: Text('No federation data available'));
    }

    final m = _federationMetrics!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Partners
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Partners',
                  m.totalPartners.toString(),
                  Icons.handshake,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Active',
                  m.activePartners.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'New (Month)',
                  m.newPartnersMonth.toString(),
                  Icons.add_circle,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Reliability',
                  '${(m.federationReliability * 100).toStringAsFixed(1)}%',
                  Icons.verified,
                  Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Federated entities
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Federated Entities',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildEntityStat('Users', m.federatedUsers, Icons.person),
                      _buildEntityStat('Rooms', m.federatedRooms, Icons.meeting_room),
                      _buildEntityStat('Creators', m.federatedCreators, Icons.star),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Cross-app interactions
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.sync_alt, color: Colors.blue),
              ),
              title: const Text('Cross-App Interactions (24h)'),
              trailing: Text(
                _formatNumber(m.crossAppInteractions.toDouble()),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Partner satisfaction
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Partner Satisfaction',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ...List.generate(5, (i) {
                        return Icon(
                          i < m.partnerSatisfaction.floor()
                              ? Icons.star
                              : i < m.partnerSatisfaction
                                  ? Icons.star_half
                                  : Icons.star_border,
                          color: Colors.amber,
                          size: 28,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        m.partnerSatisfaction.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntityStat(String label, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          _formatNumber(count.toDouble()),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  // ============================================================
  // SHARED WIDGETS
  // ============================================================

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow(
    IconData icon,
    String label,
    int value,
    double percentage,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(label),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 50,
            child: Text(
              '${(percentage * 100).toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  IconData _getPlatformIcon(PlatformType platform) {
    switch (platform) {
      case PlatformType.ios:
        return Icons.phone_iphone;
      case PlatformType.android:
        return Icons.android;
      case PlatformType.web:
        return Icons.web;
      case PlatformType.desktop:
        return Icons.desktop_windows;
      case PlatformType.tv:
        return Icons.tv;
      case PlatformType.vr:
        return Icons.vrpano;
      case PlatformType.wearable:
        return Icons.watch;
    }
  }

  Color _getPlatformColor(PlatformType platform) {
    switch (platform) {
      case PlatformType.ios:
        return Colors.grey.shade700;
      case PlatformType.android:
        return Colors.green;
      case PlatformType.web:
        return Colors.blue;
      case PlatformType.desktop:
        return Colors.purple;
      case PlatformType.tv:
        return Colors.red;
      case PlatformType.vr:
        return Colors.orange;
      case PlatformType.wearable:
        return Colors.teal;
    }
  }

  IconData _getTierIcon(CreatorTier tier) {
    switch (tier) {
      case CreatorTier.starter:
        return Icons.star_border;
      case CreatorTier.rising:
        return Icons.star_half;
      case CreatorTier.established:
        return Icons.star;
      case CreatorTier.elite:
        return Icons.stars;
      case CreatorTier.legendary:
        return Icons.auto_awesome;
    }
  }

  Color _getTierColor(CreatorTier tier) {
    switch (tier) {
      case CreatorTier.starter:
        return Colors.grey;
      case CreatorTier.rising:
        return Colors.blue;
      case CreatorTier.established:
        return Colors.green;
      case CreatorTier.elite:
        return Colors.purple;
      case CreatorTier.legendary:
        return Colors.amber;
    }
  }

  String _formatNumber(double value) {
    if (value >= 1e9) return '${(value / 1e9).toStringAsFixed(1)}B';
    if (value >= 1e6) return '${(value / 1e6).toStringAsFixed(1)}M';
    if (value >= 1e3) return '${(value / 1e3).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
