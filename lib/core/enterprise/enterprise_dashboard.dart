/// Enterprise Dashboard Widget
///
/// Displays organization metrics, room controls, and billing overview.
library;

import 'package:flutter/material.dart';

import 'enterprise_service.dart';

/// Dashboard for enterprise/organization management
class EnterpriseDashboard extends StatefulWidget {
  final String orgId;

  const EnterpriseDashboard({
    super.key,
    required this.orgId,
  });

  @override
  State<EnterpriseDashboard> createState() => _EnterpriseDashboardState();
}

class _EnterpriseDashboardState extends State<EnterpriseDashboard>
    with SingleTickerProviderStateMixin {
  final EnterpriseService _enterprise = EnterpriseService.instance;

  late TabController _tabController;

  Organization? _org;
  List<OrgRoom> _rooms = [];
  OrgAnalytics? _analytics;
  OrgBilling? _billing;
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
        _enterprise.getOrganization(widget.orgId),
        _enterprise.getOrgRooms(widget.orgId),
        _enterprise.orgAnalytics(widget.orgId),
        _enterprise.orgBilling(widget.orgId),
      ]);

      if (mounted) {
        setState(() {
          _org = results[0] as Organization?;
          _rooms = results[1] as List<OrgRoom>;
          _analytics = results[2] as OrgAnalytics;
          _billing = results[3] as OrgBilling;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [EnterpriseDashboard] Failed to load data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_org?.name ?? 'Organization'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showOrgSettings,
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Metrics'),
            Tab(icon: Icon(Icons.meeting_room), text: 'Rooms'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Billing'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMetricsTab(),
                _buildRoomsTab(),
                _buildAnalyticsTab(),
                _buildBillingTab(),
              ],
            ),
    );
  }

  // ============================================================
  // METRICS TAB
  // ============================================================

  Widget _buildMetricsTab() {
    if (_org == null) {
      return const Center(child: Text('Organization not found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Organization info card
          _buildOrgInfoCard(),
          const SizedBox(height: 16),

          // Quick stats
          _buildQuickStats(),
          const SizedBox(height: 24),

          // Plan details
          _buildPlanCard(),
          const SizedBox(height: 16),

          // Status card
          _buildStatusCard(),
        ],
      ),
    );
  }

  Widget _buildOrgInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Org avatar
            CircleAvatar(
              radius: 36,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                _org!.name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 20),

            // Org details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _org!.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  if (_org!.domain != null)
                    Text(
                      _org!.domain!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  const SizedBox(height: 8),
                  _buildPlanBadge(_org!.plan),
                ],
              ),
            ),

            // Status indicator
            _buildStatusIndicator(_org!.status),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanBadge(OrgPlan plan) {
    final (color, label) = switch (plan) {
      OrgPlan.starter => (Colors.grey, 'Starter'),
      OrgPlan.professional => (Colors.blue, 'Professional'),
      OrgPlan.enterprise => (Colors.purple, 'Enterprise'),
      OrgPlan.custom => (Colors.amber, 'Custom'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(OrgStatus status) {
    final (color, label) = switch (status) {
      OrgStatus.pending => (Colors.orange, 'Pending'),
      OrgStatus.active => (Colors.green, 'Active'),
      OrgStatus.suspended => (Colors.red, 'Suspended'),
      OrgStatus.canceled => (Colors.grey, 'Canceled'),
    };

    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.people,
            label: 'Members',
            value: '${_org!.memberCount} / ${_org!.maxMembers}',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.meeting_room,
            label: 'Active Rooms',
            value: '${_analytics?.activeRooms ?? 0}',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.event,
            label: 'Total Rooms',
            value: '${_analytics?.totalRooms ?? 0}',
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard() {
    final limits = _getPlanFeatures(_org!.plan);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.workspace_premium,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Plan Features',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _showUpgradePlanDialog,
                  child: const Text('Upgrade'),
                ),
              ],
            ),
            const Divider(),
            ...limits.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        entry.value ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: entry.value ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(entry.key),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Map<String, bool> _getPlanFeatures(OrgPlan plan) => switch (plan) {
        OrgPlan.starter => {
            'Up to 10 members': true,
            'Up to 5 rooms': true,
            'Recording': false,
            'Advanced Analytics': false,
            'SSO Integration': false,
            'Priority Support': false,
          },
        OrgPlan.professional => {
            'Up to 50 members': true,
            'Up to 20 rooms': true,
            'Recording': true,
            'Advanced Analytics': true,
            'SSO Integration': false,
            'Priority Support': false,
          },
        OrgPlan.enterprise => {
            'Up to 500 members': true,
            'Up to 100 rooms': true,
            'Recording': true,
            'Advanced Analytics': true,
            'SSO Integration': true,
            'Priority Support': true,
          },
        OrgPlan.custom => {
            'Unlimited members': true,
            'Unlimited rooms': true,
            'Recording': true,
            'Advanced Analytics': true,
            'SSO Integration': true,
            'Dedicated Support': true,
          },
      };

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Account Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('Contact', _org!.primaryContactEmail),
            _buildInfoRow(
                'Created', _formatDate(_org!.createdAt)),
            if (_org!.renewsAt != null)
              _buildInfoRow('Renews', _formatDate(_org!.renewsAt!)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.month}/${date.day}/${date.year}';

  // ============================================================
  // ROOMS TAB
  // ============================================================

  Widget _buildRoomsTab() {
    return Column(
      children: [
        // Active rooms section
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Organization Rooms',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _showCreateRoomDialog,
                icon: const Icon(Icons.add),
                label: const Text('New Room'),
              ),
            ],
          ),
        ),

        // Room list
        Expanded(
          child: _rooms.isEmpty
              ? _buildEmptyRooms()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _rooms.length,
                  itemBuilder: (context, index) {
                    return _buildRoomCard(_rooms[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyRooms() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.meeting_room,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No Rooms Yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first room to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateRoomDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Room'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(OrgRoom room) {
    final isActive = room.endedAt == null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          child: Icon(
            _getRoomTypeIcon(room.type),
            color: isActive ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(room.title),
        subtitle: Row(
          children: [
            Icon(
              Icons.people,
              size: 14,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(width: 4),
            Text('${room.participantCount}/${room.maxParticipants}'),
            const SizedBox(width: 12),
            _buildAccessChip(room.access),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (room.recordingEnabled)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.fiber_manual_record, color: Colors.red, size: 12),
              ),
            isActive
                ? const Chip(
                    label: Text('Live', style: TextStyle(fontSize: 10)),
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  )
                : const Chip(
                    label: Text('Ended', style: TextStyle(fontSize: 10)),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
          ],
        ),
        onTap: () => _showRoomDetails(room),
      ),
    );
  }

  IconData _getRoomTypeIcon(OrgRoomType type) => switch (type) {
        OrgRoomType.meeting => Icons.videocam,
        OrgRoomType.webinar => Icons.ondemand_video,
        OrgRoomType.townHall => Icons.groups,
        OrgRoomType.training => Icons.school,
        OrgRoomType.interview => Icons.question_answer,
        OrgRoomType.event => Icons.celebration,
      };

  Widget _buildAccessChip(OrgRoomAccess access) {
    final (icon, label) = switch (access) {
      OrgRoomAccess.public => (Icons.public, 'Public'),
      OrgRoomAccess.orgOnly => (Icons.business, 'Org'),
      OrgRoomAccess.inviteOnly => (Icons.mail, 'Invite'),
      OrgRoomAccess.password => (Icons.lock, 'Private'),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 2),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  // ============================================================
  // ANALYTICS TAB
  // ============================================================

  Widget _buildAnalyticsTab() {
    if (_analytics == null) {
      return const Center(child: Text('No analytics available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatDate(_analytics!.periodStart)} - ${_formatDate(_analytics!.periodEnd)}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Key metrics grid
          _buildAnalyticsGrid(),
          const SizedBox(height: 24),

          // Room distribution
          _buildRoomDistribution(),
          const SizedBox(height: 24),

          // Usage chart placeholder
          _buildUsageChart(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildAnalyticsCard(
          title: 'Total Rooms',
          value: '${_analytics!.totalRooms}',
          icon: Icons.meeting_room,
          color: Colors.blue,
        ),
        _buildAnalyticsCard(
          title: 'Total Participants',
          value: '${_analytics!.totalParticipants}',
          icon: Icons.people,
          color: Colors.green,
        ),
        _buildAnalyticsCard(
          title: 'Unique Participants',
          value: '${_analytics!.uniqueParticipants}',
          icon: Icons.person,
          color: Colors.orange,
        ),
        _buildAnalyticsCard(
          title: 'Hours Streamed',
          value: '${_analytics!.totalHoursStreamed.toStringAsFixed(1)}h',
          icon: Icons.timer,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
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
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomDistribution() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rooms by Type',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (_analytics!.roomsByType.isEmpty)
              const Center(child: Text('No room data'))
            else
              ...OrgRoomType.values.map((type) {
                final count = _analytics!.roomsByType[type.name] ?? 0;
                final total = _analytics!.totalRooms;
                final percentage = total > 0 ? (count / total * 100) : 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(type.name.toUpperCase()),
                          Text('$count (${percentage.toStringAsFixed(0)}%)'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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

  Widget _buildUsageChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Usage Trend',
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
  // BILLING TAB
  // ============================================================

  Widget _buildBillingTab() {
    if (_billing == null) {
      return const Center(child: Text('Billing information unavailable'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current plan card
          _buildBillingOverview(),
          const SizedBox(height: 16),

          // Payment method
          _buildPaymentMethodCard(),
          const SizedBox(height: 24),

          // Recent invoices
          _buildInvoicesSection(),
        ],
      ),
    );
  }

  Widget _buildBillingOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current Plan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                _buildPlanBadge(_billing!.plan),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Cost',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${_billing!.monthlyAmount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Billing Cycle',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _billing!.cycle.name.toUpperCase(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Current Period: ${_formatDate(_billing!.currentPeriodStart)} - ${_formatDate(_billing!.currentPeriodEnd)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.credit_card),
        ),
        title: Text(
          _billing!.paymentMethodId != null
              ? 'Visa ending in 4242'
              : 'No payment method',
        ),
        subtitle: _billing!.paymentMethodId != null
            ? const Text('Expires 12/25')
            : const Text('Add a payment method to continue'),
        trailing: TextButton(
          onPressed: _updatePaymentMethod,
          child: Text(_billing!.paymentMethodId != null ? 'Update' : 'Add'),
        ),
      ),
    );
  }

  Widget _buildInvoicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Invoices',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (_billing!.recentInvoices.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt,
                      size: 32,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No invoices yet',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _billing!.recentInvoices.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final invoice = _billing!.recentInvoices[index];
                return ListTile(
                  title: Text('Invoice #${invoice.id}'),
                  subtitle: Text(_formatDate(invoice.issuedAt)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '\$${invoice.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      _buildInvoiceStatusChip(invoice.status),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildInvoiceStatusChip(InvoiceStatus status) {
    final (color, label) = switch (status) {
      InvoiceStatus.draft => (Colors.grey, 'Draft'),
      InvoiceStatus.pending => (Colors.orange, 'Pending'),
      InvoiceStatus.paid => (Colors.green, 'Paid'),
      InvoiceStatus.overdue => (Colors.red, 'Overdue'),
      InvoiceStatus.canceled => (Colors.grey, 'Canceled'),
    };

    return Chip(
      label: Text(label, style: TextStyle(color: color, fontSize: 10)),
      backgroundColor: color.withValues(alpha: 0.1),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  void _showOrgSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Organization settings coming soon')),
    );
  }

  Future<void> _showUpgradePlanDialog() async {
    final selectedPlan = await showDialog<OrgPlan>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: OrgPlan.values.map((plan) {
            final isCurrentPlan = plan == _org!.plan;
            return ListTile(
              title: Text(plan.name.toUpperCase()),
              trailing: isCurrentPlan
                  ? const Chip(label: Text('Current'))
                  : null,
              enabled: !isCurrentPlan,
              onTap: isCurrentPlan
                  ? null
                  : () => Navigator.pop(context, plan),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedPlan != null && mounted) {
      final success = await _enterprise.upgradePlan(widget.orgId, selectedPlan);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan upgraded successfully!')),
        );
        _loadData();
      }
    }
  }

  Future<void> _showCreateRoomDialog() async {
    final titleController = TextEditingController();
    OrgRoomType? selectedType;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Room'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Room Title',
                hintText: 'e.g., Weekly Team Meeting',
              ),
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setLocalState) => DropdownButtonFormField<OrgRoomType>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: 'Room Type'),
                items: OrgRoomType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setLocalState(() => selectedType = value);
                },
              ),
            ),
          ],
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
        selectedType != null) {
      try {
        await _enterprise.orgRooms(
          orgId: widget.orgId,
          title: titleController.text,
          type: selectedType!,
          hostId: 'current_user', // Would get from auth
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Room created successfully!')),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create room: $e')),
          );
        }
      }
    }

    titleController.dispose();
  }

  void _showRoomDetails(OrgRoom room) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening room: ${room.title}')),
    );
  }

  void _updatePaymentMethod() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment method update coming soon')),
    );
  }
}
