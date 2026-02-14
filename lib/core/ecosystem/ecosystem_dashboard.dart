/// Ecosystem Dashboard Widget
///
/// Displays ecosystem health, growth metrics, and expansion opportunities.
library;

import 'package:flutter/material.dart';

import 'ecosystem_growth_service.dart';

/// Dashboard for ecosystem growth management
class EcosystemDashboard extends StatefulWidget {
  const EcosystemDashboard({super.key});

  @override
  State<EcosystemDashboard> createState() => _EcosystemDashboardState();
}

class _EcosystemDashboardState extends State<EcosystemDashboard>
    with SingleTickerProviderStateMixin {
  final EcosystemGrowthService _growth = EcosystemGrowthService.instance;

  late TabController _tabController;

  EcosystemHealth? _health;
  List<RecruitmentCampaign> _campaigns = [];
  List<ExpansionOpportunity> _opportunities = [];
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
        _growth.getEcosystemHealth(),
        _growth.getRecruitmentCampaigns(),
        _growth.getExpansionOpportunities(),
      ]);

      if (mounted) {
        setState(() {
          _health = results[0] as EcosystemHealth;
          _campaigns = results[1] as List<RecruitmentCampaign>;
          _opportunities = results[2] as List<ExpansionOpportunity>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [EcosystemDashboard] Failed to load data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ecosystem Growth'),
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
            Tab(icon: Icon(Icons.health_and_safety), text: 'Health'),
            Tab(icon: Icon(Icons.trending_up), text: 'Growth'),
            Tab(icon: Icon(Icons.campaign), text: 'Campaigns'),
            Tab(icon: Icon(Icons.explore), text: 'Opportunities'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildHealthTab(),
                _buildGrowthTab(),
                _buildCampaignsTab(),
                _buildOpportunitiesTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateCampaignDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Campaign'),
      ),
    );
  }

  // ============================================================
  // HEALTH TAB
  // ============================================================

  Widget _buildHealthTab() {
    if (_health == null) {
      return const Center(child: Text('Health data unavailable'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Overall health score
          _buildOverallHealthCard(),
          const SizedBox(height: 16),

          // Health factors
          _buildHealthFactors(),
          const SizedBox(height: 24),

          // Ecosystem stats
          _buildEcosystemStats(),
        ],
      ),
    );
  }

  Widget _buildOverallHealthCard() {
    final score = _health!.overallScore;
    final color = _getHealthColor(score);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Ecosystem Health',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Health gauge
            SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 12,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        score.toStringAsFixed(0),
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                      ),
                      Text(
                        _getHealthLabel(score),
                        style: TextStyle(color: color),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getHealthColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  String _getHealthLabel(double score) {
    if (score >= 90) return 'Thriving';
    if (score >= 80) return 'Healthy';
    if (score >= 70) return 'Good';
    if (score >= 60) return 'Stable';
    if (score >= 40) return 'Needs Attention';
    return 'Critical';
  }

  Widget _buildHealthFactors() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Health Factors',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ..._health!.healthFactors.entries.map((entry) {
              final color = _getHealthColor(entry.value);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatFactorName(entry.key)),
                        Text(
                          '${entry.value.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: entry.value / 100,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
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

  String _formatFactorName(String name) {
    return name
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}')
        .trim()
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  Widget _buildEcosystemStats() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          title: 'Creators',
          value: '${_health!.activeCreators}',
          subtitle: '/ ${_health!.totalCreators} total',
          growth: _health!.creatorGrowthRate,
          icon: Icons.person,
          color: Colors.purple,
        ),
        _buildStatCard(
          title: 'Partners',
          value: '${_health!.activePartners}',
          subtitle: '/ ${_health!.totalPartners} total',
          growth: _health!.partnerGrowthRate,
          icon: Icons.handshake,
          color: Colors.blue,
        ),
        _buildStatCard(
          title: 'Apps',
          value: '${_health!.activeApps}',
          subtitle: '/ ${_health!.totalApps} total',
          growth: _health!.appGrowthRate,
          icon: Icons.apps,
          color: Colors.green,
        ),
        _buildStatCard(
          title: 'Retention',
          value: '${_health!.userRetention.toStringAsFixed(1)}%',
          subtitle: 'user retention',
          growth: 0,
          icon: Icons.people,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required double growth,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(title),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Row(
              children: [
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (growth != 0) ...[
                  const Spacer(),
                  Icon(
                    growth > 0 ? Icons.trending_up : Icons.trending_down,
                    size: 14,
                    color: growth > 0 ? Colors.green : Colors.red,
                  ),
                  Text(
                    '${growth.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: growth > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // GROWTH TAB
  // ============================================================

  Widget _buildGrowthTab() {
    if (_health == null) {
      return const Center(child: Text('Growth data unavailable'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Growth metrics
          _buildGrowthMetrics(),
          const SizedBox(height: 24),

          // Growth chart placeholder
          _buildGrowthChart(),
          const SizedBox(height: 24),

          // Quick actions
          _buildGrowthActions(),
        ],
      ),
    );
  }

  Widget _buildGrowthMetrics() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Revenue Growth',
            value: '${_health!.revenueGrowth.toStringAsFixed(1)}%',
            icon: Icons.trending_up,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'Creator Growth',
            value: '${_health!.creatorGrowthRate.toStringAsFixed(1)}%',
            icon: Icons.person_add,
            color: Colors.purple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'Partner Growth',
            value: '${_health!.partnerGrowthRate.toStringAsFixed(1)}%',
            icon: Icons.handshake,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Growth Trend',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Growth chart coming soon',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              avatar: const Icon(Icons.person_add, size: 18),
              label: const Text('Recruit Creators'),
              onPressed: () => _createRecruitmentCampaign(RecruitmentTarget.creator),
            ),
            ActionChip(
              avatar: const Icon(Icons.handshake, size: 18),
              label: const Text('Recruit Partners'),
              onPressed: () => _createRecruitmentCampaign(RecruitmentTarget.partner),
            ),
            ActionChip(
              avatar: const Icon(Icons.apps, size: 18),
              label: const Text('Recruit Apps'),
              onPressed: () => _createRecruitmentCampaign(RecruitmentTarget.app),
            ),
            ActionChip(
              avatar: const Icon(Icons.campaign, size: 18),
              label: const Text('Launch Campaign'),
              onPressed: _showCreateCampaignDialog,
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // CAMPAIGNS TAB
  // ============================================================

  Widget _buildCampaignsTab() {
    if (_campaigns.isEmpty) {
      return _buildEmptyState(
        icon: Icons.campaign,
        title: 'No Campaigns',
        subtitle: 'Create your first recruitment campaign',
        actionLabel: 'Create Campaign',
        onAction: _showCreateCampaignDialog,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _campaigns.length,
      itemBuilder: (context, index) {
        return _buildCampaignCard(_campaigns[index]);
      },
    );
  }

  Widget _buildCampaignCard(RecruitmentCampaign campaign) {
    final progress = campaign.targetCount > 0
        ? (campaign.recruitedCount / campaign.targetCount * 100)
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: _buildTargetIcon(campaign.target),
            title: Text(
              campaign.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${campaign.target.name.toUpperCase()} • ${campaign.type.name}'),
            trailing: _buildStatusChip(campaign.status),
          ),

          // Progress
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${campaign.recruitedCount} / ${campaign.targetCount} recruited',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${progress.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ],
            ),
          ),

          // Budget info
          if (campaign.budget > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    size: 14,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  Text(
                    'Budget: \$${campaign.spent.toStringAsFixed(0)} / \$${campaign.budget.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (campaign.status == CampaignStatus.active)
                  TextButton(
                    onPressed: () => _pauseCampaign(campaign),
                    child: const Text('Pause'),
                  )
                else if (campaign.status == CampaignStatus.paused)
                  TextButton(
                    onPressed: () => _resumeCampaign(campaign),
                    child: const Text('Resume'),
                  ),
                TextButton(
                  onPressed: () => _viewCampaignDetails(campaign),
                  child: const Text('View Details'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetIcon(RecruitmentTarget target) {
    final (color, icon) = switch (target) {
      RecruitmentTarget.creator => (Colors.purple, Icons.person),
      RecruitmentTarget.partner => (Colors.blue, Icons.handshake),
      RecruitmentTarget.app => (Colors.green, Icons.apps),
      RecruitmentTarget.enterprise => (Colors.orange, Icons.business),
    };

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.1),
      child: Icon(icon, color: color),
    );
  }

  Widget _buildStatusChip(CampaignStatus status) {
    final (color, label) = switch (status) {
      CampaignStatus.draft => (Colors.grey, 'Draft'),
      CampaignStatus.scheduled => (Colors.blue, 'Scheduled'),
      CampaignStatus.active => (Colors.green, 'Active'),
      CampaignStatus.paused => (Colors.orange, 'Paused'),
      CampaignStatus.completed => (Colors.purple, 'Completed'),
      CampaignStatus.canceled => (Colors.red, 'Canceled'),
    };

    return Chip(
      label: Text(label, style: TextStyle(color: color, fontSize: 10)),
      backgroundColor: color.withValues(alpha: 0.1),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  // ============================================================
  // OPPORTUNITIES TAB
  // ============================================================

  Widget _buildOpportunitiesTab() {
    if (_opportunities.isEmpty) {
      return const Center(child: Text('No opportunities identified'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _opportunities.length,
      itemBuilder: (context, index) {
        return _buildOpportunityCard(_opportunities[index]);
      },
    );
  }

  Widget _buildOpportunityCard(ExpansionOpportunity opportunity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: _buildOpportunityIcon(opportunity.type),
            title: Text(
              opportunity.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(opportunity.description),
            trailing: _buildPriorityChip(opportunity.priority),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                if (opportunity.region != null) ...[
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    opportunity.region!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 12),
                ],
                if (opportunity.vertical != null) ...[
                  Icon(
                    Icons.category,
                    size: 14,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    opportunity.vertical!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 12),
                ],
                const Spacer(),
                Icon(
                  Icons.attach_money,
                  size: 14,
                  color: Colors.green,
                ),
                Text(
                  '\$${(opportunity.potentialValue / 1000).toStringAsFixed(0)}K',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Confidence bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Text(
                  'Confidence: ',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Expanded(
                  child: LinearProgressIndicator(
                    value: opportunity.confidence,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(opportunity.confidence * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // Requirements and risks
          if (opportunity.requirements.isNotEmpty ||
              opportunity.risks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  if (opportunity.requirements.isNotEmpty)
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: opportunity.requirements.take(2).map((req) {
                          return Chip(
                            avatar: const Icon(Icons.check, size: 12),
                            label: Text(req, style: const TextStyle(fontSize: 10)),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),

          // Action
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _exploreOpportunity(opportunity),
                  child: const Text('Explore'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpportunityIcon(OpportunityType type) {
    final (color, icon) = switch (type) {
      OpportunityType.geographic => (Colors.blue, Icons.public),
      OpportunityType.vertical => (Colors.purple, Icons.category),
      OpportunityType.product => (Colors.green, Icons.inventory_2),
      OpportunityType.partnership => (Colors.orange, Icons.handshake),
      OpportunityType.acquisition => (Colors.red, Icons.merge_type),
    };

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.1),
      child: Icon(icon, color: color),
    );
  }

  Widget _buildPriorityChip(OpportunityPriority priority) {
    final (color, label) = switch (priority) {
      OpportunityPriority.critical => (Colors.red, 'Critical'),
      OpportunityPriority.high => (Colors.orange, 'High'),
      OpportunityPriority.medium => (Colors.blue, 'Medium'),
      OpportunityPriority.low => (Colors.grey, 'Low'),
    };

    return Chip(
      label: Text(label, style: TextStyle(color: color, fontSize: 10)),
      backgroundColor: color.withValues(alpha: 0.1),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  // ============================================================
  // HELPER WIDGETS
  // ============================================================

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Future<void> _showCreateCampaignDialog() async {
    final nameController = TextEditingController();
    RecruitmentTarget? selectedTarget;
    CampaignType? selectedType;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Campaign'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Campaign Name',
                  hintText: 'e.g., Q1 Creator Recruitment',
                ),
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setLocalState) => Column(
                  children: [
                    DropdownButtonFormField<RecruitmentTarget>(
                      initialValue: selectedTarget,
                      decoration: const InputDecoration(labelText: 'Target'),
                      items: RecruitmentTarget.values.map((target) {
                        return DropdownMenuItem(
                          value: target,
                          child: Text(target.name.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setLocalState(() => selectedTarget = value),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<CampaignType>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: CampaignType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.name.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setLocalState(() => selectedType = value),
                    ),
                  ],
                ),
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
    );

    if (result == true &&
        nameController.text.isNotEmpty &&
        selectedTarget != null) {
      await _createRecruitmentCampaign(
        selectedTarget!,
        name: nameController.text,
        type: selectedType ?? CampaignType.organic,
      );
    }

    nameController.dispose();
  }

  Future<void> _createRecruitmentCampaign(
    RecruitmentTarget target, {
    String? name,
    CampaignType type = CampaignType.organic,
  }) async {
    try {
      switch (target) {
        case RecruitmentTarget.creator:
          await _growth.recruitCreators(
            name: name ?? 'Creator Recruitment',
            type: type,
          );
          break;
        case RecruitmentTarget.partner:
          await _growth.recruitPartners(
            name: name ?? 'Partner Recruitment',
            type: type,
          );
          break;
        case RecruitmentTarget.app:
          await _growth.recruitApps(
            name: name ?? 'App Recruitment',
            type: type,
          );
          break;
        case RecruitmentTarget.enterprise:
          await _growth.recruitPartners(
            name: name ?? 'Enterprise Recruitment',
            type: type,
          );
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaign created!')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create campaign: $e')),
        );
      }
    }
  }

  Future<void> _pauseCampaign(RecruitmentCampaign campaign) async {
    final success = await _growth.pauseCampaign(campaign.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campaign paused')),
      );
      _loadData();
    }
  }

  Future<void> _resumeCampaign(RecruitmentCampaign campaign) async {
    final success = await _growth.resumeCampaign(campaign.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campaign resumed')),
      );
      _loadData();
    }
  }

  void _viewCampaignDetails(RecruitmentCampaign campaign) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening campaign: ${campaign.name}')),
    );
  }

  void _exploreOpportunity(ExpansionOpportunity opportunity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(opportunity.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(opportunity.description),
              const SizedBox(height: 16),
              if (opportunity.requirements.isNotEmpty) ...[
                const Text(
                  'Requirements:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...opportunity.requirements.map((r) => Text('• $r')),
                const SizedBox(height: 12),
              ],
              if (opportunity.risks.isNotEmpty) ...[
                const Text(
                  'Risks:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...opportunity.risks.map((r) => Text('• $r')),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opportunity added to roadmap')),
              );
            },
            child: const Text('Add to Roadmap'),
          ),
        ],
      ),
    );
  }
}
