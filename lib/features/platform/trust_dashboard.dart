/// Trust Dashboard Widget
///
/// Displays certifications, violations, and trust scores.
library;

import 'package:flutter/material.dart';

import 'trust_framework.dart';

/// Dashboard for viewing trust and governance information
class TrustDashboard extends StatefulWidget {
  final String entityId;
  final EntityType entityType;

  const TrustDashboard({
    super.key,
    required this.entityId,
    required this.entityType,
  });

  @override
  State<TrustDashboard> createState() => _TrustDashboardState();
}

class _TrustDashboardState extends State<TrustDashboard>
    with SingleTickerProviderStateMixin {
  final TrustFrameworkService _trust = TrustFrameworkService.instance;

  late TabController _tabController;

  TrustScore? _trustScore;
  List<Certification> _certifications = [];
  List<Violation> _violations = [];
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
        _trust.getTrustScore(widget.entityId, widget.entityType),
        _trust.getCertifications(
          widget.entityId,
          entityType: widget.entityType,
        ),
        _trust.getViolations(
          widget.entityId,
          entityType: widget.entityType,
        ),
      ]);

      if (mounted) {
        setState(() {
          _trustScore = results[0] as TrustScore;
          _certifications = results[1] as List<Certification>;
          _violations = results[2] as List<Violation>;
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
        title: const Text('Trust & Safety'),
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
            Tab(icon: Icon(Icons.verified), text: 'Trust Score'),
            Tab(icon: Icon(Icons.workspace_premium), text: 'Certifications'),
            Tab(icon: Icon(Icons.warning), text: 'Violations'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTrustScoreTab(),
                _buildCertificationsTab(),
                _buildViolationsTab(),
              ],
            ),
    );
  }

  // ============================================================
  // TRUST SCORE TAB
  // ============================================================

  Widget _buildTrustScoreTab() {
    if (_trustScore == null) {
      return const Center(child: Text('Trust score unavailable'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Overall score card
          _buildOverallScoreCard(),
          const SizedBox(height: 24),

          // Score breakdown
          _buildScoreBreakdown(),
          const SizedBox(height: 24),

          // Trust factors
          _buildTrustFactors(),
        ],
      ),
    );
  }

  Widget _buildOverallScoreCard() {
    final score = _trustScore!.overallScore;
    final color = _getScoreColor(score);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Trust Score',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Circular score indicator
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
                        _getScoreLabel(score),
                        style: TextStyle(color: color),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  icon: Icons.workspace_premium,
                  value: '${_trustScore!.certificationCount}',
                  label: 'Certifications',
                  color: Colors.green,
                ),
                _buildStatItem(
                  icon: Icons.warning,
                  value: '${_trustScore!.violationCount}',
                  label: 'Violations',
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    if (score >= 20) return Colors.deepOrange;
    return Colors.red;
  }

  String _getScoreLabel(double score) {
    if (score >= 90) return 'Excellent';
    if (score >= 80) return 'Very Good';
    if (score >= 70) return 'Good';
    if (score >= 60) return 'Fair';
    if (score >= 40) return 'Needs Improvement';
    return 'At Risk';
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildScoreBreakdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score Breakdown',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ..._trustScore!.categoryScores.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key),
                        Text(
                          '${entry.value.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: _getScoreColor(entry.value),
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
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getScoreColor(entry.value),
                      ),
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

  Widget _buildTrustFactors() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trust Factors',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ..._trustScore!.factors.map((factor) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getScoreColor(factor.score).withValues(alpha: 0.1),
                  child: Text(
                    factor.score.toStringAsFixed(0),
                    style: TextStyle(
                      color: _getScoreColor(factor.score),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                title: Text(factor.name),
                subtitle: Text(factor.description),
                trailing: Text(
                  '${(factor.weight * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CERTIFICATIONS TAB
  // ============================================================

  Widget _buildCertificationsTab() {
    if (_certifications.isEmpty) {
      return _buildEmptyState(
        icon: Icons.workspace_premium,
        title: 'No Certifications',
        subtitle: 'Apply for certifications to build trust',
        actionLabel: 'View Requirements',
        onAction: _showCertificationRequirements,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _certifications.length,
      itemBuilder: (context, index) {
        return _buildCertificationCard(_certifications[index]);
      },
    );
  }

  Widget _buildCertificationCard(Certification cert) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: _buildCertificationIcon(cert.type),
            title: Text(
              cert.type.name.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Level ${cert.level}'),
            trailing: _buildCertificationStatusChip(cert.status),
          ),

          // Badges
          if (cert.badges.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 8,
                children: cert.badges.map((badge) {
                  return Chip(
                    avatar: const Icon(Icons.verified, size: 16),
                    label: Text(badge),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ),

          // Trust score and dates
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Icon(
                  Icons.security,
                  size: 14,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  'Trust: ${cert.trustScore.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  'Issued: ${_formatDate(cert.issuedAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (cert.expiresAt != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    'Expires: ${_formatDate(cert.expiresAt!)}',
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

  Widget _buildCertificationIcon(CertificationType type) {
    final (color, icon) = switch (type) {
      CertificationType.verified => (Colors.blue, Icons.verified),
      CertificationType.professional => (Colors.purple, Icons.star),
      CertificationType.premium => (Colors.amber, Icons.diamond),
      CertificationType.enterprise => (Colors.green, Icons.business),
      CertificationType.trusted => (Colors.teal, Icons.shield),
    };

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.1),
      child: Icon(icon, color: color),
    );
  }

  Widget _buildCertificationStatusChip(CertificationStatus status) {
    final (color, label) = switch (status) {
      CertificationStatus.pending => (Colors.orange, 'Pending'),
      CertificationStatus.active => (Colors.green, 'Active'),
      CertificationStatus.expired => (Colors.grey, 'Expired'),
      CertificationStatus.revoked => (Colors.red, 'Revoked'),
      CertificationStatus.suspended => (Colors.orange, 'Suspended'),
    };

    return Chip(
      label: Text(label, style: TextStyle(color: color, fontSize: 10)),
      backgroundColor: color.withValues(alpha: 0.1),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }

  // ============================================================
  // VIOLATIONS TAB
  // ============================================================

  Widget _buildViolationsTab() {
    if (_violations.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle,
        title: 'No Violations',
        subtitle: 'Great job! You have a clean record.',
        actionLabel: 'View Guidelines',
        onAction: _showCommunityGuidelines,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _violations.length,
      itemBuilder: (context, index) {
        return _buildViolationCard(_violations[index]);
      },
    );
  }

  Widget _buildViolationCard(Violation violation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: _buildSeverityIcon(violation.severity),
            title: Text(
              violation.ruleId,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(violation.description),
            trailing: _buildViolationStatusChip(violation.status),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.remove_circle,
                      size: 14,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Trust Impact: ${violation.trustScoreImpact}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(violation.occurredAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                if (violation.resolution != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(child: Text(violation.resolution!)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Actions
          if (violation.status == ViolationStatus.pending ||
              violation.status == ViolationStatus.confirmed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _appealViolation(violation),
                    child: const Text('Appeal'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _viewViolationDetails(violation),
                    child: const Text('View Details'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSeverityIcon(RuleSeverity severity) {
    final (color, icon) = switch (severity) {
      RuleSeverity.info => (Colors.blue, Icons.info),
      RuleSeverity.warning => (Colors.orange, Icons.warning),
      RuleSeverity.violation => (Colors.red, Icons.error),
      RuleSeverity.critical => (Colors.red.shade900, Icons.dangerous),
    };

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.1),
      child: Icon(icon, color: color),
    );
  }

  Widget _buildViolationStatusChip(ViolationStatus status) {
    final (color, label) = switch (status) {
      ViolationStatus.pending => (Colors.orange, 'Pending'),
      ViolationStatus.investigating => (Colors.blue, 'Investigating'),
      ViolationStatus.confirmed => (Colors.red, 'Confirmed'),
      ViolationStatus.dismissed => (Colors.green, 'Dismissed'),
      ViolationStatus.appealed => (Colors.purple, 'Appealed'),
      ViolationStatus.resolved => (Colors.grey, 'Resolved'),
    };

    return Chip(
      label: Text(label, style: TextStyle(color: color, fontSize: 10)),
      backgroundColor: color.withValues(alpha: 0.1),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
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
          ElevatedButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.month}/${date.day}/${date.year}';

  // ============================================================
  // ACTIONS
  // ============================================================

  void _showCertificationRequirements() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Certification Requirements'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: CertificationType.values.map((type) {
              return ExpansionTile(
                title: Text(type.name.toUpperCase()),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('â€¢ Verified identity'),
                        const Text('â€¢ Verified email'),
                        const Text('â€¢ Accept terms of service'),
                        if (type == CertificationType.professional)
                          const Text('â€¢ 1,000+ followers'),
                        if (type == CertificationType.premium)
                          const Text('â€¢ Premium subscription'),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCommunityGuidelines() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Community guidelines coming soon')),
    );
  }

  void _appealViolation(Violation violation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appeal Violation'),
        content: const Text(
          'Would you like to submit an appeal for this violation? '
          'Our team will review your case within 48 hours.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Appeal submitted')),
              );
            },
            child: const Text('Submit Appeal'),
          ),
        ],
      ),
    );
  }

  void _viewViolationDetails(Violation violation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Violation Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Rule: ${violation.ruleId}'),
              const SizedBox(height: 8),
              Text('Severity: ${violation.severity.name}'),
              const SizedBox(height: 8),
              Text('Description:\n${violation.description}'),
              if (violation.evidence.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Evidence:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...violation.evidence.map((e) => Text('â€¢ $e')),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
