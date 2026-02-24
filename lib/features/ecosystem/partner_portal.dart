/// Partner Portal Widget
///
/// Partner dashboard showing metrics, tools, and payouts.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'partner_program_service.dart';

/// Portal for partners to manage their program
class PartnerPortal extends StatefulWidget {
  final String userId;

  const PartnerPortal({
    super.key,
    required this.userId,
  });

  @override
  State<PartnerPortal> createState() => _PartnerPortalState();
}

class _PartnerPortalState extends State<PartnerPortal>
    with SingleTickerProviderStateMixin {
  final PartnerProgramService _partnerService = PartnerProgramService.instance;

  late TabController _tabController;

  Partner? _partner;
  PartnerAnalytics? _analytics;
  RevenueShare? _revenueShare;
  List<PartnerPayout> _payouts = [];
  bool _isLoading = true;
  bool _isRegistering = false;

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
      _partner = await _partnerService.getPartnerByUserId(widget.userId);

      if (_partner != null) {
        final results = await Future.wait([
          _partnerService.partnerAnalytics(_partner!.id),
          _partnerService.partnerRevenueShare(_partner!.id),
          _partnerService.getPartnerPayouts(_partner!.id),
        ]);

        if (mounted) {
          setState(() {
            _analytics = results[0] as PartnerAnalytics;
            _revenueShare = results[1] as RevenueShare;
            _payouts = results[2] as List<PartnerPayout>;
          });
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('âŒ [PartnerPortal] Failed to load data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_partner == null) {
      return _buildRegistrationView();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner Portal'),
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
            Tab(icon: Icon(Icons.link), text: 'Referrals'),
            Tab(icon: Icon(Icons.build), text: 'Tools'),
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'Payouts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildReferralsTab(),
          _buildToolsTab(),
          _buildPayoutsTab(),
        ],
      ),
    );
  }

  // ============================================================
  // REGISTRATION VIEW
  // ============================================================

  Widget _buildRegistrationView() {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Icon(
                Icons.handshake,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Join the Partner Program',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Earn commissions by referring users and businesses to our platform.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Benefits
              _buildBenefitsSection(),
              const SizedBox(height: 40),

              // CTA
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isRegistering ? null : _showRegistrationDialog,
                  icon: _isRegistering
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.person_add),
                  label: Text(_isRegistering ? 'Registering...' : 'Apply Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitsSection() {
    return Column(
      children: [
        _buildBenefitCard(
          icon: Icons.trending_up,
          title: 'Up to 30% Commission',
          description: 'Earn competitive revenue share on referred customers',
        ),
        _buildBenefitCard(
          icon: Icons.workspace_premium,
          title: 'Tier Rewards',
          description: 'Unlock higher tiers and bonuses as you grow',
        ),
        _buildBenefitCard(
          icon: Icons.analytics,
          title: 'Real-time Analytics',
          description: 'Track referrals, conversions, and earnings in real-time',
        ),
        _buildBenefitCard(
          icon: Icons.support_agent,
          title: 'Dedicated Support',
          description: 'Get priority support and resources to help you succeed',
        ),
      ],
    );
  }

  Widget _buildBenefitCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title),
        subtitle: Text(description),
      ),
    );
  }

  Future<void> _showRegistrationDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final companyController = TextEditingController();
    PartnerType? selectedType;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Partner Application'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'John Doe',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'john@example.com',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: companyController,
                decoration: const InputDecoration(
                  labelText: 'Company (Optional)',
                  hintText: 'Acme Inc.',
                ),
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setLocalState) => DropdownButtonFormField<PartnerType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Partner Type'),
                  items: PartnerType.values.map((type) {
                    final label = switch (type) {
                      PartnerType.affiliate => 'Affiliate - Earn on referrals',
                      PartnerType.reseller => 'Reseller - Sell our services',
                      PartnerType.integrator => 'Integrator - Build integrations',
                      PartnerType.agency => 'Agency - White-label solutions',
                      PartnerType.ambassador => 'Ambassador - Promote brand',
                    };
                    return DropdownMenuItem(value: type, child: Text(label));
                  }).toList(),
                  onChanged: (value) => setLocalState(() => selectedType = value),
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
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (result == true &&
        nameController.text.isNotEmpty &&
        emailController.text.isNotEmpty &&
        selectedType != null) {
      setState(() => _isRegistering = true);

      try {
        await _partnerService.registerPartner(
          userId: widget.userId,
          name: nameController.text,
          email: emailController.text,
          type: selectedType!,
          companyName:
              companyController.text.isNotEmpty ? companyController.text : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Application submitted! We\'ll review it shortly.'),
            ),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isRegistering = false);
        }
      }
    }

    nameController.dispose();
    emailController.dispose();
    companyController.dispose();
  }

  // ============================================================
  // OVERVIEW TAB
  // ============================================================

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Partner info card
          _buildPartnerInfoCard(),
          const SizedBox(height: 16),

          // Quick stats
          _buildQuickStats(),
          const SizedBox(height: 24),

          // Revenue share card
          if (_revenueShare != null) ...[
            _buildRevenueShareCard(),
            const SizedBox(height: 16),
          ],

          // Earnings summary
          _buildEarningsSummary(),
        ],
      ),
    );
  }

  Widget _buildPartnerInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                _partner!.name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _partner!.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _partner!.type.name.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _buildTierBadge(_partner!.tier),
                ],
              ),
            ),
            _buildStatusIndicator(_partner!.status),
          ],
        ),
      ),
    );
  }

  Widget _buildTierBadge(PartnerTier tier) {
    final (color, label) = switch (tier) {
      PartnerTier.bronze => (const Color(0xFFCD7F32), 'Bronze'),
      PartnerTier.silver => (const Color(0xFFC0C0C0), 'Silver'),
      PartnerTier.gold => (const Color(0xFFFFD700), 'Gold'),
      PartnerTier.platinum => (const Color(0xFFE5E4E2), 'Platinum'),
      PartnerTier.diamond => (Colors.lightBlue, 'Diamond'),
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

  Widget _buildStatusIndicator(PartnerStatus status) {
    final (color, label) = switch (status) {
      PartnerStatus.pending => (Colors.orange, 'Pending'),
      PartnerStatus.active => (Colors.green, 'Active'),
      PartnerStatus.suspended => (Colors.red, 'Suspended'),
      PartnerStatus.terminated => (Colors.grey, 'Terminated'),
    };

    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontSize: 10)),
      ],
    );
  }

  Widget _buildQuickStats() {
    if (_analytics == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.people,
            label: 'Referrals',
            value: '${_analytics!.totalReferrals}',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle,
            label: 'Conversions',
            value: '${_analytics!.conversions}',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.percent,
            label: 'Rate',
            value: '${_analytics!.conversionRate.toStringAsFixed(1)}%',
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
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueShareCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Your Commission Rate',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_revenueShare!.totalPercentage.toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                      ),
                      Text(
                        'Total Commission',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Base: ${_revenueShare!.basePercentage.toStringAsFixed(0)}%',
                    ),
                    if (_revenueShare!.bonusPercentage > 0)
                      Text(
                        'Bonus: +${_revenueShare!.bonusPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.amber),
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

  Widget _buildEarningsSummary() {
    if (_analytics == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Earnings Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            _buildEarningsRow(
              'Total Commissions',
              '\$${_analytics!.totalCommissions.toStringAsFixed(2)}',
              Colors.green,
            ),
            _buildEarningsRow(
              'Pending',
              '\$${_analytics!.pendingCommissions.toStringAsFixed(2)}',
              Colors.orange,
            ),
            _buildEarningsRow(
              'Lifetime',
              '\$${_partner!.lifetimeEarnings.toStringAsFixed(2)}',
              Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REFERRALS TAB
  // ============================================================

  Widget _buildReferralsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Referral link card
          _buildReferralLinkCard(),
          const SizedBox(height: 24),

          // Referral stats
          _buildReferralStats(),
          const SizedBox(height: 24),

          // Chart placeholder
          _buildReferralChart(),
        ],
      ),
    );
  }

  Widget _buildReferralLinkCard() {
    final referralCode = _partner!.referralCode ?? 'N/A';
    final referralLink = 'https://mixmingle.app/ref/$referralCode';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.link, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Your Referral Link',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Referral code
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      referralLink,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: referralLink));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied!')),
                      );
                    },
                    tooltip: 'Copy link',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Code badge
            Row(
              children: [
                Text(
                  'Code: ',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    referralCode,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _shareReferralLink,
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralStats() {
    if (_analytics == null) return const SizedBox.shrink();

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatTile(
          'Total Referrals',
          '${_analytics!.totalReferrals}',
          Icons.people_outline,
        ),
        _buildStatTile(
          'Active',
          '${_analytics!.activeReferrals}',
          Icons.person_outline,
        ),
        _buildStatTile(
          'Conversions',
          '${_analytics!.conversions}',
          Icons.check_circle_outline,
        ),
        _buildStatTile(
          'Revenue Generated',
          '\$${_analytics!.totalRevenue.toStringAsFixed(0)}',
          Icons.attach_money,
        ),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Referral Trend',
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
                      style: Theme.of(context).textTheme.bodySmall,
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

  void _shareReferralLink() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share dialog coming soon')),
    );
  }

  // ============================================================
  // TOOLS TAB
  // ============================================================

  Widget _buildToolsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Partner Tools',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        _buildToolCard(
          icon: Icons.code,
          title: 'Embed Widget',
          description: 'Embed our widget on your website',
          onTap: _showEmbedCode,
        ),
        _buildToolCard(
          icon: Icons.image,
          title: 'Marketing Assets',
          description: 'Download banners, logos, and promotional materials',
          onTap: _downloadAssets,
        ),
        _buildToolCard(
          icon: Icons.api,
          title: 'API Access',
          description: 'Access our API for custom integrations',
          onTap: _showApiDocs,
        ),
        _buildToolCard(
          icon: Icons.link,
          title: 'UTM Builder',
          description: 'Create trackable links for campaigns',
          onTap: _showUtmBuilder,
        ),
        _buildToolCard(
          icon: Icons.qr_code,
          title: 'QR Code Generator',
          description: 'Generate QR codes for your referral link',
          onTap: _generateQrCode,
        ),
        _buildToolCard(
          icon: Icons.support,
          title: 'Partner Support',
          description: 'Get help from our partner success team',
          onTap: _contactSupport,
        ),
      ],
    );
  }

  Widget _buildToolCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showEmbedCode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Embed Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                '<script src="https://mixmingle.app/widget.js?ref=${_partner!.referralCode}"></script>',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(
                text:
                    '<script src="https://mixmingle.app/widget.js?ref=${_partner!.referralCode}"></script>',
              ));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code copied!')),
              );
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _downloadAssets() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Marketing assets coming soon')),
    );
  }

  void _showApiDocs() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API documentation coming soon')),
    );
  }

  void _showUtmBuilder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('UTM builder coming soon')),
    );
  }

  void _generateQrCode() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR code generator coming soon')),
    );
  }

  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening support chat...')),
    );
  }

  // ============================================================
  // PAYOUTS TAB
  // ============================================================

  Widget _buildPayoutsTab() {
    return Column(
      children: [
        // Payout summary
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildPayoutSummary(),
        ),

        // Payout list
        Expanded(
          child: _payouts.isEmpty
              ? _buildEmptyPayouts()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _payouts.length,
                  itemBuilder: (context, index) {
                    return _buildPayoutCard(_payouts[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPayoutSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Balance',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${_analytics?.pendingCommissions.toStringAsFixed(2) ?? '0.00'}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed:
                  (_analytics?.pendingCommissions ?? 0) > 0 ? _requestPayout : null,
              icon: const Icon(Icons.account_balance_wallet),
              label: const Text('Withdraw'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPayouts() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No Payouts Yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Your payout history will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutCard(PartnerPayout payout) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getPayoutStatusColor(payout.status).withValues(alpha: 0.1),
          child: Icon(
            _getPayoutMethodIcon(payout.method),
            color: _getPayoutStatusColor(payout.status),
          ),
        ),
        title: Text('\$${payout.amount.toStringAsFixed(2)}'),
        subtitle: Text(
          '${payout.method.name.toUpperCase()} â€¢ ${_formatDate(payout.createdAt)}',
        ),
        trailing: _buildPayoutStatusChip(payout.status),
      ),
    );
  }

  Color _getPayoutStatusColor(PayoutStatus status) => switch (status) {
        PayoutStatus.pending => Colors.orange,
        PayoutStatus.processing => Colors.blue,
        PayoutStatus.completed => Colors.green,
        PayoutStatus.failed => Colors.red,
        PayoutStatus.canceled => Colors.grey,
      };

  IconData _getPayoutMethodIcon(PayoutMethod method) => switch (method) {
        PayoutMethod.bankTransfer => Icons.account_balance,
        PayoutMethod.paypal => Icons.payment,
        PayoutMethod.stripe => Icons.credit_card,
        PayoutMethod.crypto => Icons.currency_bitcoin,
      };

  Widget _buildPayoutStatusChip(PayoutStatus status) {
    final color = _getPayoutStatusColor(status);
    final label = status.name.toUpperCase();

    return Chip(
      label: Text(label, style: TextStyle(color: color, fontSize: 10)),
      backgroundColor: color.withValues(alpha: 0.1),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  String _formatDate(DateTime date) =>
      '${date.month}/${date.day}/${date.year}';

  Future<void> _requestPayout() async {
    PayoutMethod? selectedMethod;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Payout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Amount: \$${_analytics!.pendingCommissions.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setLocalState) => DropdownButtonFormField<PayoutMethod>(
                initialValue: selectedMethod,
                decoration: const InputDecoration(labelText: 'Payout Method'),
                items: PayoutMethod.values.map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Text(method.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) => setLocalState(() => selectedMethod = value),
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
            child: const Text('Request'),
          ),
        ],
      ),
    );

    if (result == true && selectedMethod != null && mounted) {
      try {
        await _partnerService.requestPayout(
          partnerId: _partner!.id,
          amount: _analytics!.pendingCommissions,
          method: selectedMethod!,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payout requested successfully!')),
        );
        _loadData();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to request payout: $e')),
        );
      }
    }
  }
}
