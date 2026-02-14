/// Creator Dashboard Widget
///
/// Displays creator program dashboard with stats, earnings,
/// tier progress, and quick actions.
library;

import 'package:flutter/material.dart';

import 'creator_program_service.dart';

/// Creator dashboard main widget
class CreatorDashboard extends StatefulWidget {
  final String creatorId;
  final VoidCallback? onRequestPayout;
  final VoidCallback? onViewAnalytics;
  final VoidCallback? onManageContent;

  const CreatorDashboard({
    super.key,
    required this.creatorId,
    this.onRequestPayout,
    this.onViewAnalytics,
    this.onManageContent,
  });

  @override
  State<CreatorDashboard> createState() => _CreatorDashboardState();
}

class _CreatorDashboardState extends State<CreatorDashboard> {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final data = await CreatorProgramService.instance.getDashboardData(
        widget.creatorId,
      );

      setState(() {
        _dashboardData = data;
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
      return const Center(child: CircularProgressIndicator());
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
            ElevatedButton(
              onPressed: _loadDashboardData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_dashboardData == null || _dashboardData!.isEmpty) {
      return const Center(child: Text('No dashboard data available'));
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildTierProgress(),
            const SizedBox(height: 24),
            _buildEarningsCard(),
            const SizedBox(height: 24),
            _buildStatsGrid(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildRecentEarnings(),
            const SizedBox(height: 24),
            _buildPerks(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final profile = _dashboardData!['profile'] as Map<String, dynamic>;
    final tier = _dashboardData!['tier'] as String;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage: profile['avatarUrl'] != null
                  ? NetworkImage(profile['avatarUrl'])
                  : null,
              child: profile['avatarUrl'] == null
                  ? const Icon(Icons.person, size: 32)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile['displayName'] ?? 'Creator',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildTierBadge(tier),
                      const SizedBox(width: 8),
                      Text(
                        profile['applicationStatus'] == 'approved'
                            ? 'Verified Creator'
                            : profile['applicationStatus'] ?? '',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                        ),
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

  Widget _buildTierBadge(String tier) {
    Color badgeColor;
    switch (tier) {
      case 'diamond':
        badgeColor = Colors.lightBlueAccent;
        break;
      case 'platinum':
        badgeColor = Colors.grey.shade400;
        break;
      case 'gold':
        badgeColor = Colors.amber;
        break;
      case 'silver':
        badgeColor = Colors.grey;
        break;
      case 'bronze':
        badgeColor = Colors.brown;
        break;
      default:
        badgeColor = Colors.grey.shade300;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        tier.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTierProgress() {
    final currentTier = _dashboardData!['tier'] as String;
    final nextTier = _dashboardData!['nextTier'] as String?;
    final requirements = _dashboardData!['tierRequirements'] as Map<String, dynamic>?;
    final stats = _dashboardData!['stats'] as Map<String, dynamic>;

    if (currentTier == 'diamond') {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.diamond, size: 48, color: Colors.lightBlueAccent),
              const SizedBox(height: 8),
              Text(
                'You\'ve reached the highest tier!',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tier Progress',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (nextTier != null)
                  Text(
                    'Next: ${nextTier.toUpperCase()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (requirements != null) ...[
              _buildProgressItem(
                'Followers',
                stats['followers'] ?? 0,
                requirements['minFollowers'] ?? 100,
              ),
              const SizedBox(height: 8),
              _buildProgressItem(
                'Weekly Hours',
                stats['weeklyStreamHours'] ?? 0,
                requirements['minWeeklyStreamHours'] ?? 5,
              ),
              const SizedBox(height: 8),
              _buildProgressItem(
                'Monthly Views',
                stats['monthlyViews'] ?? 0,
                requirements['minMonthlyViews'] ?? 500,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(String label, int current, int target) {
    final progress = (current / target).clamp(0.0, 1.0);
    final isComplete = current >= target;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              '$current / $target',
              style: TextStyle(
                color: isComplete ? Colors.green : null,
                fontWeight: isComplete ? FontWeight.bold : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation(
            isComplete ? Colors.green : Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsCard() {
    final earnings = _dashboardData!['earnings'] as Map<String, dynamic>;

    return Card(
      color: Theme.of(context).primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Earnings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.white70),
                  onPressed: () => _showEarningsInfo(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildEarningsMetric(
                    'This Month',
                    '\$${(earnings['thisMonthEarnings'] ?? 0).toStringAsFixed(2)}',
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white24,
                ),
                Expanded(
                  child: _buildEarningsMetric(
                    'Pending Payout',
                    '\$${(earnings['pendingPayout'] ?? 0).toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Lifetime: \$${(earnings['lifetimeEarnings'] ?? 0).toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (earnings['pendingPayout'] ?? 0) > 0
                    ? widget.onRequestPayout
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).primaryColor,
                ),
                child: const Text('Request Payout'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsMetric(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    final stats = _dashboardData!['stats'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Stats',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Followers',
              _formatNumber(stats['followers'] ?? 0),
              Icons.people,
            ),
            _buildStatCard(
              'Total Views',
              _formatNumber(stats['totalViews'] ?? 0),
              Icons.visibility,
            ),
            _buildStatCard(
              'Stream Hours',
              '${stats['totalStreamHours'] ?? 0}h',
              Icons.access_time,
            ),
            _buildStatCard(
              'Engagement',
              '${((stats['engagementRate'] ?? 0) * 100).toStringAsFixed(1)}%',
              Icons.trending_up,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
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

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Analytics',
                Icons.analytics,
                widget.onViewAnalytics,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Content',
                Icons.video_library,
                widget.onManageContent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback? onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentEarnings() {
    final recentEarnings = (_dashboardData!['recentEarnings'] as List?) ?? [];

    if (recentEarnings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Earnings',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentEarnings.length > 5 ? 5 : recentEarnings.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final earning = recentEarnings[index] as Map<String, dynamic>;
              return ListTile(
                leading: _buildEarningIcon(earning['type'] as String?),
                title: Text(earning['description'] ?? ''),
                trailing: Text(
                  '+\$${(earning['amount'] ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEarningIcon(String? type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'giftRevenue':
        icon = Icons.card_giftcard;
        color = Colors.pink;
        break;
      case 'subscriptionShare':
        icon = Icons.subscriptions;
        color = Colors.purple;
        break;
      case 'sponsorship':
        icon = Icons.handshake;
        color = Colors.blue;
        break;
      case 'referralBonus':
        icon = Icons.share;
        color = Colors.orange;
        break;
      case 'milestone':
        icon = Icons.emoji_events;
        color = Colors.amber;
        break;
      default:
        icon = Icons.attach_money;
        color = Colors.green;
    }

    return CircleAvatar(
      backgroundColor: color.withAlpha(51),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildPerks() {
    final perks = (_dashboardData!['perks'] as List?) ?? [];

    if (perks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Perks',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: perks.map<Widget>((perk) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(perk.toString())),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  void _showEarningsInfo() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How Earnings Work',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.card_giftcard, 'Gifts', 'Revenue from viewer gifts'),
            _buildInfoRow(Icons.subscriptions, 'Subscriptions', 'Monthly subscriber share'),
            _buildInfoRow(Icons.handshake, 'Sponsorships', 'Brand partnership income'),
            _buildInfoRow(Icons.share, 'Referrals', 'Bonus for referred creators'),
            const SizedBox(height: 16),
            Text(
              'Payouts are processed within 5-7 business days.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
