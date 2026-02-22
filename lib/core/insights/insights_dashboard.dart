/// Business Insights Dashboard Widget
///
/// Visual dashboard for displaying business intelligence metrics,
/// cohort analysis, revenue forecasts, and actionable insights.
library;

import 'package:flutter/material.dart';

import 'insights_service.dart';

/// Main insights dashboard widget
class InsightsDashboard extends StatefulWidget {
  const InsightsDashboard({super.key});

  @override
  State<InsightsDashboard> createState() => _InsightsDashboardState();
}

class _InsightsDashboardState extends State<InsightsDashboard> {
  bool _isLoading = true;
  GrowthMetrics? _growthMetrics;
  RevenueForecast? _revenueForecast;
  List<ActionableInsight> _insights = [];
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
      final service = InsightsService.instance;

      final results = await Future.wait([
        service.growthMetrics(),
        service.revenueForecast(),
        service.generateInsights(),
      ]);

      setState(() {
        _growthMetrics = results[0] as GrowthMetrics;
        _revenueForecast = results[1] as RevenueForecast;
        _insights = results[2] as List<ActionableInsight>;
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
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text('Failed to load insights', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_error!, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Business Insights',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Key Metrics Row
            if (_growthMetrics != null) ...[
              Text(
                'Key Metrics',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildMetricsRow(),
              const SizedBox(height: 24),
            ],

            // Revenue Forecast
            if (_revenueForecast != null) ...[
              Text(
                'Revenue Forecast',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildRevenueForecastCard(),
              const SizedBox(height: 24),
            ],

            // Actionable Insights
            if (_insights.isNotEmpty) ...[
              Text(
                'Actionable Insights',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ..._insights.map(_buildInsightCard),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsRow() {
    final metrics = _growthMetrics!;
    return Row(
      children: [
        Expanded(child: _buildMetricCard(
          'New Users',
          metrics.newUsers.toString(),
          _formatPercent(metrics.growthRate),
          metrics.growthRate >= 0,
          Icons.person_add,
          Colors.blue,
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard(
          'Active Users',
          metrics.activeUsers.toString(),
          null,
          true,
          Icons.people,
          Colors.green,
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard(
          'Churn Rate',
          _formatPercent(metrics.churnRate),
          null,
          metrics.churnRate < 0.1,
          Icons.trending_down,
          metrics.churnRate < 0.1 ? Colors.green : Colors.red,
        )),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    String? trend,
    bool isPositive,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (trend != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 14,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                  Text(
                    trend,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueForecastCard() {
    final forecast = _revenueForecast!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  '${forecast.periodDays}-Day Forecast',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Predicted Revenue',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '\$${forecast.predictedRevenue.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Growth Rate',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      _formatPercent(forecast.growthRate),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: forecast.growthRate >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Confidence: \$${forecast.confidenceLower.toStringAsFixed(0)} - \$${forecast.confidenceUpper.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Top Revenue Drivers',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...forecast.topDrivers.take(3).map((driver) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(driver.name),
                  ),
                  Text(
                    '${(driver.contribution * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    driver.trend >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 16,
                    color: driver.trend >= 0 ? Colors.green : Colors.red,
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(ActionableInsight insight) {
    final priorityColor = _getPriorityColor(insight.priority);
    final typeIcon = _getTypeIcon(insight.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: priorityColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(typeIcon, color: priorityColor),
        ),
        title: Text(
          insight.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: priorityColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                insight.priority.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: priorityColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              insight.type.name,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.description),
                const SizedBox(height: 16),
                Text(
                  'Recommendations',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...insight.recommendations.map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text(rec)),
                    ],
                  ),
                )),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.trending_up, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Expected Impact: \$${insight.expectedImpact.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(InsightPriority priority) {
    switch (priority) {
      case InsightPriority.critical:
        return Colors.red;
      case InsightPriority.high:
        return Colors.orange;
      case InsightPriority.medium:
        return Colors.amber;
      case InsightPriority.low:
        return Colors.blue;
    }
  }

  IconData _getTypeIcon(InsightType type) {
    switch (type) {
      case InsightType.growth:
        return Icons.trending_up;
      case InsightType.retention:
        return Icons.people;
      case InsightType.revenue:
        return Icons.attach_money;
      case InsightType.engagement:
        return Icons.favorite;
      case InsightType.churn:
        return Icons.exit_to_app;
      case InsightType.opportunity:
        return Icons.lightbulb;
      case InsightType.risk:
        return Icons.warning;
    }
  }

  String _formatPercent(double value) {
    final sign = value >= 0 ? '+' : '';
    return '$sign${(value * 100).toStringAsFixed(1)}%';
  }
}

/// Compact insight card for embedding in other screens
class InsightSummaryCard extends StatelessWidget {
  final ActionableInsight insight;
  final VoidCallback? onTap;

  const InsightSummaryCard({
    super.key,
    required this.insight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(insight.priority);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      insight.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(InsightPriority priority) {
    switch (priority) {
      case InsightPriority.critical:
        return Colors.red;
      case InsightPriority.high:
        return Colors.orange;
      case InsightPriority.medium:
        return Colors.amber;
      case InsightPriority.low:
        return Colors.blue;
    }
  }
}

/// Growth metrics mini widget
class GrowthMetricsMini extends StatelessWidget {
  final GrowthMetrics metrics;

  const GrowthMetricsMini({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMiniMetric(context, 'Users', '+${metrics.newUsers}', Colors.blue),
        _buildMiniMetric(context, 'Active', '${metrics.activeUsers}', Colors.green),
        _buildMiniMetric(
          context,
          'Growth',
          '${(metrics.growthRate * 100).toStringAsFixed(1)}%',
          metrics.growthRate >= 0 ? Colors.green : Colors.red,
        ),
      ],
    );
  }

  Widget _buildMiniMetric(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
