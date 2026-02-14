/// Economy Dashboard Widget
///
/// Displays inflation metrics, creator market health, and economic stability indicators.
library;

import 'package:flutter/material.dart';

import 'dynamic_economy_service.dart';

/// Dashboard for economy monitoring
class EconomyDashboard extends StatefulWidget {
  const EconomyDashboard({super.key});

  @override
  State<EconomyDashboard> createState() => _EconomyDashboardState();
}

class _EconomyDashboardState extends State<EconomyDashboard>
    with SingleTickerProviderStateMixin {
  final DynamicEconomyService _economy = DynamicEconomyService.instance;

  late TabController _tabController;

  CoinSupplyMetrics? _supplyMetrics;
  CreatorMarketMetrics? _marketMetrics;
  EconomicStability? _stability;
  List<EconomyBoost> _activeBoosts = [];
  List<GiftPricing> _giftPricing = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      final results = await Future.wait([
        _economy.realTimeCoinInflationControl(),
        _economy.creatorMarketBalancing(),
        _economy.getEconomicStability(),
        _economy.getActiveBoosts(),
        _economy.getGiftPricing(),
      ]);

      if (mounted) {
        setState(() {
          _supplyMetrics = results[0] as CoinSupplyMetrics;
          _marketMetrics = results[1] as CreatorMarketMetrics;
          _stability = results[2] as EconomicStability;
          _activeBoosts = results[3] as List<EconomyBoost>;
          _giftPricing = results[4] as List<GiftPricing>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [EconomyDashboard] Failed to load data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Economy Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.monetization_on), text: 'Inflation'),
            Tab(icon: Icon(Icons.store), text: 'Market'),
            Tab(icon: Icon(Icons.balance), text: 'Stability'),
            Tab(icon: Icon(Icons.rocket_launch), text: 'Boosts'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildInflationTab(),
                _buildMarketTab(),
                _buildStabilityTab(),
                _buildBoostsTab(),
              ],
            ),
    );
  }

  // ============================================================
  // INFLATION TAB
  // ============================================================

  Widget _buildInflationTab() {
    if (_supplyMetrics == null) {
      return const Center(child: Text('No inflation data available'));
    }

    final m = _supplyMetrics!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Inflation rate indicator
          _buildInflationRateCard(m),
          const SizedBox(height: 16),

          // Supply breakdown
          _buildSupplyBreakdown(m),
          const SizedBox(height: 16),

          // Daily activity
          _buildDailyActivity(m),
        ],
      ),
    );
  }

  Widget _buildInflationRateCard(CoinSupplyMetrics m) {
    final color = _getInflationColor(m.trend);
    final icon = _getInflationIcon(m.trend);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Inflation Rate',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: color),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${m.inflationRate.toStringAsFixed(2)}%',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      m.trend.name.toUpperCase(),
                      style: TextStyle(color: color),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getInflationColor(InflationTrend trend) {
    switch (trend) {
      case InflationTrend.deflationary:
        return Colors.blue;
      case InflationTrend.stable:
        return Colors.green;
      case InflationTrend.moderate:
        return Colors.orange;
      case InflationTrend.high:
        return Colors.deepOrange;
      case InflationTrend.hyperinflation:
        return Colors.red;
    }
  }

  IconData _getInflationIcon(InflationTrend trend) {
    switch (trend) {
      case InflationTrend.deflationary:
        return Icons.trending_down;
      case InflationTrend.stable:
        return Icons.trending_flat;
      case InflationTrend.moderate:
      case InflationTrend.high:
      case InflationTrend.hyperinflation:
        return Icons.trending_up;
    }
  }

  Widget _buildSupplyBreakdown(CoinSupplyMetrics m) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Coin Supply',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildSupplyRow('Total Supply', m.totalSupply, Colors.grey),
            _buildSupplyRow('Circulating', m.circulatingSupply, Colors.green),
            _buildSupplyRow('Reserve', m.reserveSupply, Colors.blue),
            _buildSupplyRow('Burned', m.burnedSupply, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplyRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            _formatNumber(value),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyActivity(CoinSupplyMetrics m) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Activity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActivityCard(
                    'Minted',
                    m.mintedToday,
                    Icons.add_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActivityCard(
                    'Burned',
                    m.burnedToday,
                    Icons.remove_circle,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(
    String label,
    double value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            _formatNumber(value),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  // ============================================================
  // MARKET TAB
  // ============================================================

  Widget _buildMarketTab() {
    if (_marketMetrics == null) {
      return const Center(child: Text('No market data available'));
    }

    final m = _marketMetrics!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Market health
          _buildMarketHealthCard(m),
          const SizedBox(height: 16),

          // Creator metrics
          _buildCreatorMetrics(m),
          const SizedBox(height: 16),

          // Earnings distribution
          _buildEarningsDistribution(m),
          const SizedBox(height: 16),

          // Gift pricing
          _buildGiftPricingSection(),
        ],
      ),
    );
  }

  Widget _buildMarketHealthCard(CreatorMarketMetrics m) {
    final health = m.marketHealth;
    final color = _getHealthColor(health);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getHealthIcon(health),
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Creator Market Health',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    health.name.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Gini',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  m.giniCoefficient.toStringAsFixed(3),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getHealthColor(EconomyHealth health) {
    switch (health) {
      case EconomyHealth.thriving:
        return Colors.green;
      case EconomyHealth.healthy:
        return Colors.lightGreen;
      case EconomyHealth.stable:
        return Colors.blue;
      case EconomyHealth.stressed:
        return Colors.orange;
      case EconomyHealth.critical:
        return Colors.red;
    }
  }

  IconData _getHealthIcon(EconomyHealth health) {
    switch (health) {
      case EconomyHealth.thriving:
        return Icons.sentiment_very_satisfied;
      case EconomyHealth.healthy:
        return Icons.sentiment_satisfied;
      case EconomyHealth.stable:
        return Icons.sentiment_neutral;
      case EconomyHealth.stressed:
        return Icons.sentiment_dissatisfied;
      case EconomyHealth.critical:
        return Icons.sentiment_very_dissatisfied;
    }
  }

  Widget _buildCreatorMetrics(CreatorMarketMetrics m) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Creator Metrics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    'Total Creators',
                    m.totalCreators.toString(),
                    Icons.people,
                  ),
                ),
                Expanded(
                  child: _buildMetricTile(
                    'Active',
                    m.activeCreators.toString(),
                    Icons.person,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    'Total Earnings',
                    '\$${_formatNumber(m.totalEarnings)}',
                    Icons.attach_money,
                  ),
                ),
                Expanded(
                  child: _buildMetricTile(
                    'Average',
                    '\$${m.averageEarnings.toStringAsFixed(0)}',
                    Icons.analytics,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildEarningsDistribution(CreatorMarketMetrics m) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Earnings Distribution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDistributionStat(
                  'Median',
                  '\$${m.medianEarnings.toStringAsFixed(0)}',
                ),
                _buildDistributionStat(
                  'Top 10%',
                  '${m.topTenPercent.toStringAsFixed(1)}%',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Top 10% of creators earn ${m.topTenPercent.toStringAsFixed(1)}% of total earnings',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildGiftPricingSection() {
    if (_giftPricing.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gift Pricing',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ..._giftPricing.take(5).map((gift) => _buildGiftPriceRow(gift)),
          ],
        ),
      ),
    );
  }

  Widget _buildGiftPriceRow(GiftPricing gift) {
    final change = gift.priceChange;
    final changeColor = change > 0 ? Colors.green : change < 0 ? Colors.red : Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(gift.name),
          ),
          Expanded(
            child: Text(
              '${gift.currentPrice} coins',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  change > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: changeColor,
                ),
                Text(
                  '${change.abs().toStringAsFixed(1)}%',
                  style: TextStyle(color: changeColor, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STABILITY TAB
  // ============================================================

  Widget _buildStabilityTab() {
    if (_stability == null) {
      return const Center(child: Text('No stability data available'));
    }

    final s = _stability!;
    final healthColor = _getHealthColor(s.overallHealth);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Overall health
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Economic Stability',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: healthColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getHealthIcon(s.overallHealth),
                      color: healthColor,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.overallHealth.name.toUpperCase(),
                    style: TextStyle(
                      color: healthColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Key indicators
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Key Indicators',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildIndicatorRow(
                    'Velocity of Money',
                    s.velocityOfMoney.toStringAsFixed(2),
                    _getVelocityColor(s.velocityOfMoney),
                  ),
                  _buildIndicatorRow(
                    'Transaction Volume',
                    '\$${_formatNumber(s.transactionVolume)}',
                    Colors.blue,
                  ),
                  _buildIndicatorRow(
                    'Spending Rate',
                    '${(s.spendingRate * 100).toStringAsFixed(0)}%',
                    Colors.green,
                  ),
                ],
              ),
            ),
          ),

          // Warnings
          if (s.warnings.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.orange.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Warnings',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...s.warnings.map((w) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text('• $w'),
                        )),
                  ],
                ),
              ),
            ),
          ],

          // Recommendations
          if (s.recommendations.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.blue.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Recommendations',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...s.recommendations.map((r) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text('• $r'),
                        )),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIndicatorRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getVelocityColor(double velocity) {
    if (velocity < 2) return Colors.red;
    if (velocity < 4) return Colors.orange;
    if (velocity < 8) return Colors.green;
    return Colors.blue;
  }

  // ============================================================
  // BOOSTS TAB
  // ============================================================

  Widget _buildBoostsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active boosts
          Text(
            'Active Boosts',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          if (_activeBoosts.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.rocket,
                        size: 48,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No active boosts',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ..._activeBoosts.map((boost) => _buildBoostCard(boost)),
          const SizedBox(height: 24),

          // Create boost button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showCreateBoostDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Economy Boost'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoostCard(EconomyBoost boost) {
    final remaining = boost.endTime.difference(DateTime.now());
    final isExpiringSoon = remaining.inHours < 24;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.rocket_launch, color: Colors.purple),
            ),
            title: Text(
              boost.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(boost.description),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${boost.multiplier}x',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.purple,
                  ),
                ),
                const Text('multiplier', style: TextStyle(fontSize: 10)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Icon(
                  Icons.timer,
                  size: 14,
                  color: isExpiringSoon ? Colors.orange : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDuration(remaining),
                  style: TextStyle(
                    fontSize: 12,
                    color: isExpiringSoon ? Colors.orange : Colors.grey,
                  ),
                ),
                const Spacer(),
                Wrap(
                  spacing: 4,
                  children: boost.affectedSectors.map((sector) {
                    return Chip(
                      label: Text(
                        sector.name,
                        style: const TextStyle(fontSize: 10),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateBoostDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    double multiplier = 1.5;
    final selectedSectors = <MarketSector>{MarketSector.gifts};
    int durationHours = 24;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Economy Boost'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Boost Name',
                    hintText: 'e.g., Weekend Special',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Multiplier: '),
                    Expanded(
                      child: Slider(
                        value: multiplier,
                        min: 1.1,
                        max: 3.0,
                        divisions: 19,
                        label: '${multiplier.toStringAsFixed(1)}x',
                        onChanged: (v) => setState(() => multiplier = v),
                      ),
                    ),
                    Text('${multiplier.toStringAsFixed(1)}x'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Duration: '),
                    DropdownButton<int>(
                      value: durationHours,
                      items: [6, 12, 24, 48, 72].map((h) {
                        return DropdownMenuItem(
                          value: h,
                          child: Text('$h hours'),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => durationHours = v ?? 24),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Affected Sectors:'),
                ),
                Wrap(
                  spacing: 8,
                  children: MarketSector.values.map((sector) {
                    final isSelected = selectedSectors.contains(sector);
                    return FilterChip(
                      label: Text(sector.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedSectors.add(sector);
                          } else {
                            selectedSectors.remove(sector);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      await _economy.globalEventEconomyBoosts(
        name: nameController.text,
        description: descController.text,
        multiplier: multiplier,
        sectors: selectedSectors.toList(),
        duration: Duration(hours: durationHours),
      );

      _loadData();
    }

    nameController.dispose();
    descController.dispose();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _formatNumber(double value) {
    if (value >= 1e9) return '${(value / 1e9).toStringAsFixed(1)}B';
    if (value >= 1e6) return '${(value / 1e6).toStringAsFixed(1)}M';
    if (value >= 1e3) return '${(value / 1e3).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return 'Expired';
    if (duration.inDays > 0) return '${duration.inDays}d remaining';
    if (duration.inHours > 0) return '${duration.inHours}h remaining';
    return '${duration.inMinutes}m remaining';
  }
}
