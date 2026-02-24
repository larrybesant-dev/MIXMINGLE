/// Marketplace Dashboard Widget
///
/// Displays creator services, earnings, and boosts information.
library;

import 'package:flutter/material.dart';

import 'marketplace_service.dart';

/// Dashboard displaying marketplace information for creators
class MarketplaceDashboard extends StatefulWidget {
  final String creatorId;

  const MarketplaceDashboard({
    super.key,
    required this.creatorId,
  });

  @override
  State<MarketplaceDashboard> createState() => _MarketplaceDashboardState();
}

class _MarketplaceDashboardState extends State<MarketplaceDashboard>
    with SingleTickerProviderStateMixin {
  final MarketplaceService _marketplace = MarketplaceService.instance;

  late TabController _tabController;

  List<CreatorService> _services = [];
  CreatorEarnings? _earnings;
  RevenueSplit? _revenueSplit;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        _marketplace.listCreatorServicesWithFilters(
          creatorId: widget.creatorId,
        ),
        _marketplace.getCreatorEarnings(widget.creatorId),
        _marketplace.creatorRevenueSplit(widget.creatorId),
      ]);

      if (mounted) {
        setState(() {
          _services = results[0] as List<CreatorService>;
          _earnings = results[1] as CreatorEarnings?;
          _revenueSplit = results[2] as RevenueSplit;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('âŒ [MarketplaceDashboard] Failed to load data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Marketplace'),
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
            Tab(icon: Icon(Icons.storefront), text: 'Services'),
            Tab(icon: Icon(Icons.attach_money), text: 'Earnings'),
            Tab(icon: Icon(Icons.trending_up), text: 'Boosts'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildServicesTab(),
                _buildEarningsTab(),
                _buildBoostsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateServiceDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Service'),
      ),
    );
  }

  // ============================================================
  // SERVICES TAB
  // ============================================================

  Widget _buildServicesTab() {
    if (_services.isEmpty) {
      return _buildEmptyState(
        icon: Icons.storefront,
        title: 'No Services Listed',
        subtitle: 'Create your first service to start earning',
        actionLabel: 'Create Service',
        onAction: _showCreateServiceDialog,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _services.length,
      itemBuilder: (context, index) {
        final service = _services[index];
        return _buildServiceCard(service);
      },
    );
  }

  Widget _buildServiceCard(CreatorService service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with image
          if (service.images.isNotEmpty)
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Icon(
                  _getCategoryIcon(service.category),
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        service.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    _buildStatusChip(service.status),
                  ],
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  service.description,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Price and stats
                Row(
                  children: [
                    // Price
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '\$${service.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Rating
                    if (service.reviewCount > 0) ...[
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${service.rating.toStringAsFixed(1)} (${service.reviewCount})',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 12),
                    ],

                    // Sales
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${service.currentBookings} sold',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Tags
                if (service.tags.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: service.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tag,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
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

  IconData _getCategoryIcon(ServiceCategory category) => switch (category) {
        ServiceCategory.coaching => Icons.school,
        ServiceCategory.consultation => Icons.question_answer,
        ServiceCategory.shoutout => Icons.campaign,
        ServiceCategory.collab => Icons.group,
        ServiceCategory.privateSession => Icons.lock,
        ServiceCategory.tutorial => Icons.play_circle,
        ServiceCategory.merchandise => Icons.inventory_2,
        ServiceCategory.digitalContent => Icons.download,
        ServiceCategory.other => Icons.more_horiz,
      };

  Widget _buildStatusChip(ServiceStatus status) {
    final (color, label) = switch (status) {
      ServiceStatus.draft => (Colors.grey, 'Draft'),
      ServiceStatus.pending => (Colors.orange, 'Pending'),
      ServiceStatus.active => (Colors.green, 'Active'),
      ServiceStatus.paused => (Colors.blue, 'Paused'),
      ServiceStatus.soldOut => (Colors.red, 'Sold Out'),
      ServiceStatus.archived => (Colors.grey, 'Archived'),
    };

    return Chip(
      label: Text(
        label,
        style: TextStyle(color: color, fontSize: 10),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  // ============================================================
  // EARNINGS TAB
  // ============================================================

  Widget _buildEarningsTab() {
    if (_earnings == null) {
      return _buildEmptyState(
        icon: Icons.attach_money,
        title: 'No Earnings Yet',
        subtitle: 'Start selling services to earn money',
        actionLabel: 'Create Service',
        onAction: _showCreateServiceDialog,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Earnings overview cards
          _buildEarningsOverview(),
          const SizedBox(height: 24),

          // Revenue split info
          if (_revenueSplit != null) ...[
            _buildRevenueSplitCard(),
            const SizedBox(height: 24),
          ],

          // Earnings chart placeholder
          _buildEarningsChart(),
        ],
      ),
    );
  }

  Widget _buildEarningsOverview() {
    return Row(
      children: [
        Expanded(
          child: _buildEarningsCard(
            title: 'Total Earnings',
            amount: _earnings!.totalEarnings,
            icon: Icons.account_balance_wallet,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildEarningsCard(
            title: 'Pending',
            amount: _earnings!.pendingEarnings,
            icon: Icons.pending,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
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
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueSplitCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Revenue Split',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                _buildTierBadge(_revenueSplit!.tier),
              ],
            ),
            const SizedBox(height: 16),

            // Split visualization
            Row(
              children: [
                Expanded(
                  flex: _revenueSplit!.creatorPercentage.toInt(),
                  child: Container(
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${_revenueSplit!.creatorPercentage.toStringAsFixed(0)}% You',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: _revenueSplit!.platformPercentage.toInt(),
                  child: Container(
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${_revenueSplit!.platformPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_revenueSplit!.partnerBonus != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      'Partner Bonus: +${_revenueSplit!.partnerBonus!.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierBadge(CreatorTier tier) {
    final (color, label) = switch (tier) {
      CreatorTier.starter => (Colors.grey, 'Starter'),
      CreatorTier.bronze => (const Color(0xFFCD7F32), 'Bronze'),
      CreatorTier.silver => (const Color(0xFFC0C0C0), 'Silver'),
      CreatorTier.gold => (const Color(0xFFFFD700), 'Gold'),
      CreatorTier.platinum => (const Color(0xFFE5E4E2), 'Platinum'),
      CreatorTier.diamond => (Colors.lightBlue, 'Diamond'),
      CreatorTier.legend => (Colors.purple, 'Legend'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Earnings Trend',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chart coming soon',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

  // ============================================================
  // BOOSTS TAB
  // ============================================================

  Widget _buildBoostsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Available boosts
          Text(
            'Available Boosts',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          _buildBoostCard(
            type: BoostType.visibility,
            title: 'Visibility Boost',
            description: 'Increase your service visibility by 2x for 7 days',
            price: 19.99,
            icon: Icons.visibility,
            color: Colors.blue,
          ),
          _buildBoostCard(
            type: BoostType.featuredPlacement,
            title: 'Featured Placement',
            description: 'Get featured on the marketplace homepage',
            price: 49.99,
            icon: Icons.star,
            color: Colors.amber,
          ),
          _buildBoostCard(
            type: BoostType.searchRanking,
            title: 'Search Ranking Boost',
            description: 'Improve your search ranking for 14 days',
            price: 29.99,
            icon: Icons.search,
            color: Colors.green,
          ),
          _buildBoostCard(
            type: BoostType.revenue,
            title: 'Revenue Boost',
            description: 'Get an additional 5% revenue share for 30 days',
            price: 99.99,
            icon: Icons.trending_up,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildBoostCard({
    required BoostType type,
    required String title,
    required String description,
    required double price,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: ElevatedButton(
          onPressed: () => _applyBoost(type),
          child: Text('\$${price.toStringAsFixed(2)}'),
        ),
      ),
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

  Future<void> _showCreateServiceDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    ServiceCategory? selectedCategory;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Service'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Service Title',
                  hintText: 'e.g., 1-on-1 Coaching Session',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe what you offer...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (USD)',
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setLocalState) => DropdownButtonFormField<ServiceCategory>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                  ),
                  items: ServiceCategory.values.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setLocalState(() => selectedCategory = value);
                  },
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
        titleController.text.isNotEmpty &&
        priceController.text.isNotEmpty &&
        selectedCategory != null) {
      try {
        await _marketplace.listCreatorServices(
          creatorId: widget.creatorId,
          creatorName: 'Creator', // Would get from user profile
          title: titleController.text,
          description: descriptionController.text,
          category: selectedCategory!,
          type: ServiceType.oneTime,
          price: double.parse(priceController.text),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Service created successfully!')),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create service: $e')),
          );
        }
      }
    }

    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
  }

  Future<void> _applyBoost(BoostType type) async {
    try {
      await _marketplace.creatorTierBoosts(
        creatorId: widget.creatorId,
        type: type,
        multiplier: 2.0,
        duration: const Duration(days: 7),
        reason: 'User purchased boost',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Boost applied successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to apply boost: $e')),
        );
      }
    }
  }
}
