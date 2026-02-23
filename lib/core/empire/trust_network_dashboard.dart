/// Trust Network Dashboard Widget
///
/// Displays global trust metrics, cross-app violations, and appeals queue.
library;

import 'package:flutter/material.dart';

import 'network_trust_service.dart';

/// Dashboard for network trust monitoring
class TrustNetworkDashboard extends StatefulWidget {
  const TrustNetworkDashboard({super.key});

  @override
  State<TrustNetworkDashboard> createState() => _TrustNetworkDashboardState();
}

class _TrustNetworkDashboardState extends State<TrustNetworkDashboard>
    with SingleTickerProviderStateMixin {
  final NetworkTrustService _trust = NetworkTrustService.instance;

  late TabController _tabController;

  Map<String, dynamic> _statistics = {};
  List<NetworkBan> _recentBans = [];
  List<SafetySignal> _recentSignals = [];
  List<Appeal> _pendingAppeals = [];
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
        _trust.getTrustStatistics(),
        _trust.getPendingAppeals(limit: 20),
      ]);

      if (mounted) {
        setState(() {
          _statistics = results[0] as Map<String, dynamic>;
          _pendingAppeals = results[1] as List<Appeal>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('âŒ [TrustDashboard] Failed to load data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trust Network'),
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
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.gavel), text: 'Bans'),
            Tab(icon: Icon(Icons.warning), text: 'Signals'),
            Tab(icon: Icon(Icons.balance), text: 'Appeals'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildBansTab(),
                _buildSignalsTab(),
                _buildAppealsTab(),
              ],
            ),
    );
  }

  // ============================================================
  // OVERVIEW TAB
  // ============================================================

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stats cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Active Bans',
                  _statistics['activeBans']?.toString() ?? '0',
                  Icons.block,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Pending Appeals',
                  _statistics['pendingAppeals']?.toString() ?? '0',
                  Icons.balance,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Signals (30d)',
                  _statistics['recentSignals30d']?.toString() ?? '0',
                  Icons.warning,
                  Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Toxic (7d)',
                  _statistics['toxicContent7d']?.toString() ?? '0',
                  Icons.dangerous,
                  Colors.deepOrange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Quick actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.person_search, color: Colors.blue),
                    title: const Text('Lookup User Trust'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _showUserLookupDialog,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.text_snippet, color: Colors.purple),
                    title: const Text('Analyze Content'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _showContentAnalysisDialog,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.block, color: Colors.red),
                    title: const Text('Issue Network Ban'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _showIssueBanDialog,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Trust level distribution
          _buildTrustDistributionCard(),
        ],
      ),
    );
  }

  Widget _buildStatCard(
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
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

  Widget _buildTrustDistributionCard() {
    final levels = [
      (TrustLevel.trusted, Colors.green, 15),
      (TrustLevel.verified, Colors.lightGreen, 25),
      (TrustLevel.standard, Colors.blue, 40),
      (TrustLevel.limited, Colors.orange, 15),
      (TrustLevel.untrusted, Colors.red, 5),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trust Level Distribution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...levels.map((level) => _buildDistributionRow(
                  level.$1.name,
                  level.$3,
                  level.$2,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionRow(String label, int percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '$percentage%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BANS TAB
  // ============================================================

  Widget _buildBansTab() {
    if (_recentBans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No recent bans',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showIssueBanDialog,
              icon: const Icon(Icons.add),
              label: const Text('Issue Ban'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recentBans.length,
      itemBuilder: (context, index) {
        return _buildBanCard(_recentBans[index]);
      },
    );
  }

  Widget _buildBanCard(NetworkBan ban) {
    final color = _getBanColor(ban.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.block, color: color),
            ),
            title: Text(
              ban.userId,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(ban.reason.name),
            trailing: Chip(
              label: Text(
                ban.type.name.toUpperCase(),
                style: TextStyle(color: color, fontSize: 10),
              ),
              backgroundColor: color.withValues(alpha: 0.1),
              visualDensity: VisualDensity.compact,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(ban.issuedAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (ban.expiresAt != null) ...[
                  const Spacer(),
                  Text(
                    'Expires: ${_formatDateTime(ban.expiresAt!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getBanColor(BanType type) {
    switch (type) {
      case BanType.permanent:
        return Colors.red;
      case BanType.global:
        return Colors.deepOrange;
      case BanType.network:
        return Colors.orange;
      case BanType.local:
        return Colors.amber;
    }
  }

  // ============================================================
  // SIGNALS TAB
  // ============================================================

  Widget _buildSignalsTab() {
    if (_recentSignals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No recent safety signals',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recentSignals.length,
      itemBuilder: (context, index) {
        return _buildSignalCard(_recentSignals[index]);
      },
    );
  }

  Widget _buildSignalCard(SafetySignal signal) {
    final color = _getSeverityColor(signal.severity);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.warning, color: color),
        ),
        title: Text(
          signal.type.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(signal.description),
            const SizedBox(height: 4),
            Text(
              'From: ${signal.sourceApp}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${(signal.confidenceScore * 100).toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              signal.severity.name,
              style: TextStyle(fontSize: 10, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(ToxicitySeverity severity) {
    switch (severity) {
      case ToxicitySeverity.critical:
        return Colors.red;
      case ToxicitySeverity.severe:
        return Colors.deepOrange;
      case ToxicitySeverity.high:
        return Colors.orange;
      case ToxicitySeverity.medium:
        return Colors.amber;
      case ToxicitySeverity.low:
        return Colors.yellow.shade700;
    }
  }

  // ============================================================
  // APPEALS TAB
  // ============================================================

  Widget _buildAppealsTab() {
    if (_pendingAppeals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.done_all,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No pending appeals',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingAppeals.length,
      itemBuilder: (context, index) {
        return _buildAppealCard(_pendingAppeals[index]);
      },
    );
  }

  Widget _buildAppealCard(Appeal appeal) {
    final statusColor = _getAppealStatusColor(appeal.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.balance, color: statusColor),
            ),
            title: Text(
              'Appeal #${appeal.appealId.substring(0, 8)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              appeal.reason,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Chip(
              label: Text(
                appeal.status.name.toUpperCase(),
                style: TextStyle(color: statusColor, fontSize: 10),
              ),
              backgroundColor: statusColor.withValues(alpha: 0.1),
              visualDensity: VisualDensity.compact,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Text(
                  'Submitted: ${_formatDateTime(appeal.submittedAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                if (appeal.status == AppealStatus.pending) ...[
                  OutlinedButton(
                    onPressed: () => _reviewAppeal(appeal, AppealStatus.denied),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Deny'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _reviewAppeal(appeal, AppealStatus.approved),
                    child: const Text('Approve'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getAppealStatusColor(AppealStatus status) {
    switch (status) {
      case AppealStatus.pending:
        return Colors.orange;
      case AppealStatus.underReview:
        return Colors.blue;
      case AppealStatus.approved:
        return Colors.green;
      case AppealStatus.denied:
        return Colors.red;
      case AppealStatus.escalated:
        return Colors.purple;
    }
  }

  Future<void> _reviewAppeal(Appeal appeal, AppealStatus decision) async {
    try {
      await _trust.reviewAppeal(
        appealId: appeal.appealId,
        decision: decision,
        reviewedBy: 'admin', // In production, use actual admin ID
      );
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appeal ${decision.name}'),
            backgroundColor: decision == AppealStatus.approved ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // ============================================================
  // DIALOGS
  // ============================================================

  Future<void> _showUserLookupDialog() async {
    final controller = TextEditingController();
    UserTrustProfile? profile;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('User Trust Lookup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'User ID',
                  hintText: 'Enter user ID',
                ),
              ),
              const SizedBox(height: 16),
              if (profile != null) _buildProfileSummary(profile!),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () async {
                final result = await _trust.getUserTrustProfile(controller.text);
                setState(() => profile = result);
              },
              child: const Text('Lookup'),
            ),
          ],
        ),
      ),
    );

    controller.dispose();
  }

  Widget _buildProfileSummary(UserTrustProfile profile) {
    final levelColor = _getTrustLevelColor(profile.level);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: levelColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, color: levelColor),
              const SizedBox(width: 8),
              Text(
                profile.level.name.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: levelColor,
                ),
              ),
              const Spacer(),
              Text(
                'Score: ${profile.trustScore.toInt()}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text('${profile.confirmedViolations}'),
                  const Text('Violations', style: TextStyle(fontSize: 10)),
                ],
              ),
              Column(
                children: [
                  Text('${profile.appealsWon}'),
                  const Text('Won', style: TextStyle(fontSize: 10)),
                ],
              ),
              Column(
                children: [
                  Text('${profile.appealsLost}'),
                  const Text('Lost', style: TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTrustLevelColor(TrustLevel level) {
    switch (level) {
      case TrustLevel.trusted:
        return Colors.green;
      case TrustLevel.verified:
        return Colors.lightGreen;
      case TrustLevel.standard:
        return Colors.blue;
      case TrustLevel.limited:
        return Colors.orange;
      case TrustLevel.untrusted:
        return Colors.red;
      case TrustLevel.unknown:
        return Colors.grey;
    }
  }

  Future<void> _showContentAnalysisDialog() async {
    final controller = TextEditingController();
    ToxicityResult? result;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Content Analysis'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Content to analyze',
                    hintText: 'Enter text content',
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                if (result != null) _buildAnalysisResult(result!),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () async {
                final analysis = await _trust.federatedToxicityDetection(
                  contentId: 'test_${DateTime.now().millisecondsSinceEpoch}',
                  contentType: 'text',
                  content: controller.text,
                );
                setState(() => result = analysis);
              },
              child: const Text('Analyze'),
            ),
          ],
        ),
      ),
    );

    controller.dispose();
  }

  Widget _buildAnalysisResult(ToxicityResult result) {
    final color = result.isToxic ? Colors.red : Colors.green;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            result.isToxic ? Icons.dangerous : Icons.check_circle,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            result.isToxic ? 'TOXIC CONTENT' : 'CLEAN',
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            'Score: ${(result.overallScore * 100).toInt()}%',
          ),
          if (result.flaggedPhrases.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Flagged: ${result.flaggedPhrases.join(", ")}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showIssueBanDialog() async {
    final userIdController = TextEditingController();
    final descController = TextEditingController();
    BanType banType = BanType.local;
    SafetySignalType reason = SafetySignalType.harassment;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Issue Network Ban'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: userIdController,
                  decoration: const InputDecoration(
                    labelText: 'User ID',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<BanType>(
                  initialValue: banType,
                  decoration: const InputDecoration(labelText: 'Ban Type'),
                  items: BanType.values.map((t) {
                    return DropdownMenuItem(value: t, child: Text(t.name));
                  }).toList(),
                  onChanged: (v) => setState(() => banType = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<SafetySignalType>(
                  initialValue: reason,
                  decoration: const InputDecoration(labelText: 'Reason'),
                  items: SafetySignalType.values.map((r) {
                    return DropdownMenuItem(value: r, child: Text(r.name));
                  }).toList(),
                  onChanged: (v) => setState(() => reason = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                  ),
                  maxLines: 2,
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Issue Ban'),
            ),
          ],
        ),
      ),
    );

    if (result == true && userIdController.text.isNotEmpty) {
      await _trust.globalBanPropagation(
        userId: userIdController.text,
        type: banType,
        reason: reason,
        description: descController.text,
        issuedBy: 'admin',
      );
      _loadData();
    }

    userIdController.dispose();
    descController.dispose();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _formatDateTime(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
