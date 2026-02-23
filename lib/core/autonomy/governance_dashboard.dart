/// Governance Dashboard
///
/// Dashboard widget for displaying policy health, enforcement metrics,
/// and community trends for platform governance.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'policy_engine.dart';
import 'community_ai_service.dart';

/// Governance dashboard widget
class GovernanceDashboard extends StatefulWidget {
  const GovernanceDashboard({super.key});

  @override
  State<GovernanceDashboard> createState() => _GovernanceDashboardState();
}

class _GovernanceDashboardState extends State<GovernanceDashboard> {
  final PolicyEngine _policyEngine = PolicyEngine.instance;
  final CommunityAIService _communityAI = CommunityAIService.instance;

  PolicyReport? _latestReport;
  List<EmergingTrend> _trends = [];
  List<CommunityShift> _shifts = [];
  bool _isLoading = true;
  String? _error;

  StreamSubscription<PolicyViolation>? _violationSubscription;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _setupStreams();
  }

  @override
  void dispose() {
    _violationSubscription?.cancel();
    super.dispose();
  }

  void _setupStreams() {
    _violationSubscription = _policyEngine.violationStream.listen((violation) {
      // Refresh data when new violations come in
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _policyEngine.loadPolicies();

      final results = await Future.wait([
        _policyEngine.generatePolicyReports(),
        _communityAI.detectEmergingTrends(),
        _communityAI.detectCommunityShifts(),
      ]);

      setState(() {
        _latestReport = results[0] as PolicyReport;
        _trends = results[1] as List<EmergingTrend>;
        _shifts = results[2] as List<CommunityShift>;
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Governance Dashboard')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDashboardData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Governance Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPolicyHealthSection(),
              const SizedBox(height: 24),
              _buildEnforcementMetricsSection(),
              const SizedBox(height: 24),
              _buildCommunityTrendsSection(),
              const SizedBox(height: 24),
              _buildRecommendationsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolicyHealthSection() {
    final healthScore = _calculateHealthScore();
    final healthColor = _getHealthColor(healthScore);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Policy Health',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildHealthIndicator(
                    label: 'Overall Health',
                    value: healthScore,
                    color: healthColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    label: 'Active Policies',
                    value: _policyEngine.getPolicies().where((p) => p.isActive).length.toString(),
                    icon: Icons.policy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    label: 'Total Violations',
                    value: _latestReport?.totalViolations.toString() ?? '0',
                    icon: Icons.warning_amber,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    label: 'Actions Enforced',
                    value: _latestReport?.actionsEnforced.toString() ?? '0',
                    icon: Icons.gavel,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthIndicator({
    required String label,
    required double value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            '${(value * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.grey, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnforcementMetricsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Enforcement Metrics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              label: 'Automated Detection Rate',
              value: _latestReport?.automatedDetectionRate ?? 0,
              format: 'percent',
            ),
            _buildMetricRow(
              label: 'False Positive Rate',
              value: _latestReport?.falsePositiveRate ?? 0,
              format: 'percent',
              threshold: 0.1,
            ),
            _buildMetricRow(
              label: 'Appeals Filed',
              value: (_latestReport?.appealsFiled ?? 0).toDouble(),
              format: 'count',
            ),
            _buildMetricRow(
              label: 'Appeals Granted',
              value: (_latestReport?.appealsGranted ?? 0).toDouble(),
              format: 'count',
            ),
            const SizedBox(height: 16),
            if (_latestReport?.violationsByCategory.isNotEmpty == true) ...[
              const Text(
                'Violations by Category',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ..._latestReport!.violationsByCategory.entries.map((entry) =>
                _buildCategoryBar(entry.key, entry.value),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow({
    required String label,
    required double value,
    required String format,
    double? threshold,
  }) {
    String displayValue;
    Color? color;

    switch (format) {
      case 'percent':
        displayValue = '${(value * 100).toStringAsFixed(1)}%';
        if (threshold != null && value > threshold) {
          color = Colors.red;
        }
        break;
      case 'count':
        displayValue = value.toInt().toString();
        break;
      default:
        displayValue = value.toString();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            displayValue,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar(String category, int count) {
    final maxCount = _latestReport?.violationsByCategory.values.reduce((a, b) => a > b ? a : b) ?? 1;
    final ratio = count / maxCount;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category, style: const TextStyle(fontSize: 12)),
              Text(count.toString(), style: const TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(_getCategoryColor(category)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityTrendsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Community Trends',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_trends.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No emerging trends detected'),
                ),
              )
            else
              ...(_trends.take(5).map(_buildTrendItem)),
            if (_shifts.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Community Shifts',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...(_shifts.take(3).map(_buildShiftItem)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrendItem(EmergingTrend trend) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            _getTrendIcon(trend.stage),
            color: _getTrendColor(trend.stage),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trend.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${trend.category.name} â€¢ ${trend.stage.name}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getTrendColor(trend.stage).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+${(trend.growthRate * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: _getTrendColor(trend.stage),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftItem(CommunityShift shift) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.swap_horiz, color: Colors.purple, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shift.description,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  shift.type.name,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            '${(shift.magnitude * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    final recommendations = _latestReport?.recommendations ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Recommendations',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recommendations.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No recommendations at this time'),
                ),
              )
            else
              ...recommendations.map((rec) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(rec)),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  double _calculateHealthScore() {
    if (_latestReport == null) return 0.8;

    double score = 1.0;

    // Deduct for false positive rate
    score -= _latestReport!.falsePositiveRate * 0.5;

    // Deduct for high violation count
    if (_latestReport!.totalViolations > 100) {
      score -= 0.1;
    }

    return score.clamp(0.0, 1.0);
  }

  Color _getHealthColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'content':
        return Colors.red;
      case 'behavior':
        return Colors.orange;
      case 'safety':
        return Colors.purple;
      case 'privacy':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getTrendIcon(TrendStage stage) {
    switch (stage) {
      case TrendStage.emerging:
        return Icons.new_releases;
      case TrendStage.growing:
        return Icons.trending_up;
      case TrendStage.peaking:
        return Icons.show_chart;
      case TrendStage.declining:
        return Icons.trending_down;
      case TrendStage.stable:
        return Icons.horizontal_rule;
    }
  }

  Color _getTrendColor(TrendStage stage) {
    switch (stage) {
      case TrendStage.emerging:
        return Colors.purple;
      case TrendStage.growing:
        return Colors.green;
      case TrendStage.peaking:
        return Colors.orange;
      case TrendStage.declining:
        return Colors.red;
      case TrendStage.stable:
        return Colors.blue;
    }
  }
}
