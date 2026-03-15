<<<<<<< HEAD
﻿// ignore_for_file: unused_element
import 'package:cloud_firestore/cloud_firestore.dart';
=======
>>>>>>> origin/develop
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixmingle/shared/models/report.dart' show ReportType;
import 'package:mixmingle/shared/models/moderation.dart' show UserReport;
import 'package:mixmingle/shared/widgets/club_background.dart';
import 'package:mixmingle/shared/widgets/glow_text.dart';
import 'package:mixmingle/shared/providers/all_providers.dart';
<<<<<<< HEAD
import 'package:mixmingle/services/admin/admin_service.dart';
=======
import 'ads_admin_page.dart';
>>>>>>> origin/develop

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 8, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const GlowText(
            text: 'Admin Dashboard',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            glowColor: Color(0xFFFF4C4C),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
<<<<<<< HEAD
          bottom: TabBar(
            controller: _tabs,
            indicatorColor: Colors.purpleAccent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.bar_chart, size: 18), text: 'Overview'),
              Tab(icon: Icon(Icons.people, size: 18), text: 'Users'),
              Tab(icon: Icon(Icons.discount, size: 18), text: 'Promos'),
              Tab(icon: Icon(Icons.meeting_room, size: 18), text: 'Rooms'),
              Tab(icon: Icon(Icons.flag, size: 18), text: 'Reports'),
              Tab(icon: Icon(Icons.block, size: 18), text: 'Bans'),
              Tab(icon: Icon(Icons.analytics, size: 18), text: 'Analytics'),
              Tab(icon: Icon(Icons.history, size: 18), text: 'Logs'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabs,
          children: const [
            _OverviewTab(),
            _UserModerationTab(),
            _PromoCodesTab(),
            _RoomModerationTab(),
            _ReportsTab(),
            _GlobalBansTab(),
            _AnalyticsTab(),
            _AdminLogsTab(),
=======
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Cards
              Row(
                children: [
                  Expanded(
                      child: _buildStatCard('Total Reports', '0', Icons.flag)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildStatCard('Pending', '0', Icons.pending)),
                ],
              ),
              const SizedBox(height: 16),

              // Ad Manager shortcut
              _buildNavCard(
                context,
                title: 'Ad Manager',
                subtitle: 'Manage advertisers, creatives & promo codes',
                icon: Icons.campaign_outlined,
                color: const Color(0xFFFF4C4C),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdsAdminPage(),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Pending Reports
              const GlowText(
                text: 'Pending Reports',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              const SizedBox(height: 12),

              FutureBuilder<List<UserReport>>(
                future: moderationService.getPendingReports(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  final reports = snapshot.data ?? [];
                  if (reports.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text('No pending reports'),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: reports
                        .map((report) => _buildReportCard(report))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white30, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      color: Colors.white.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFFF4C4C), size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
>>>>>>> origin/develop
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Overview Tab
// ===========================================================================

class _OverviewTab extends ConsumerStatefulWidget {
  const _OverviewTab();

  @override
  ConsumerState<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<_OverviewTab> {
  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final moderationService = ref.watch(moderationServiceProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats grid
          statsAsync.when(
            data: (stats) => _StatsRow(stats: stats),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
          const GlowText(
            text: 'Pending Reports',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<UserReport>>(
            future: moderationService.getPendingReports(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red));
              }
              final reports = snapshot.data ?? [];
              if (reports.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                      child: Text('No pending reports',
                          style: TextStyle(color: Colors.white54))),
                );
              }
              return Column(
                children: reports
                    .map((r) => _ReportCard(
                          report: r,
                          onReview: (status) => _reviewReport(r, status),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _reviewReport(UserReport report, String status) async {
    try {
      final moderationService = ref.read(moderationServiceProvider);
      final currentUser = ref.read(authServiceProvider).currentUser;
      await moderationService.reviewReport(
          report.id, currentUser?.uid ?? 'admin', status);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Report $status')));
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

class _StatsRow extends StatelessWidget {
  final Map<String, int> stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Users', stats['totalUsers'] ?? 0, Icons.people, Colors.blueAccent),
      ('Rooms', stats['activeRooms'] ?? 0, Icons.meeting_room, Colors.greenAccent),
      ('Gifts', stats['giftsTotal'] ?? 0, Icons.card_giftcard, Colors.pinkAccent),
      ('Reports', stats['pendingReports'] ?? 0, Icons.flag, Colors.redAccent),
    ];
    return Row(
      children: items
          .map((item) => Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: item.$4.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: item.$4.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    children: [
                      Icon(item.$3, color: item.$4, size: 22),
                      const SizedBox(height: 4),
                      Text('${item.$2}',
                          style: TextStyle(
                              color: item.$4,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text(item.$1,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 10)),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final UserReport report;
  final void Function(String status) onReview;
  const _ReportCard({required this.report, required this.onReview});

  Color _typeColor(ReportType t) => switch (t) {
        ReportType.spam => Colors.orange,
        ReportType.harassment => Colors.red,
        ReportType.inappropriateContent => Colors.purple,
        ReportType.hateSpeech => Colors.red[900]!,
        ReportType.violence => Colors.red[700]!,
        ReportType.scam => Colors.amber,
        ReportType.suspectedMinor => Colors.pink,
        ReportType.other => Colors.grey,
      };

  String _typeLabel(ReportType t) => switch (t) {
        ReportType.spam => 'SPAM',
        ReportType.harassment => 'HARASSMENT',
        ReportType.inappropriateContent => 'INAPPROPRIATE',
        ReportType.hateSpeech => 'HATE SPEECH',
        ReportType.violence => 'VIOLENCE',
        ReportType.scam => 'SCAM',
        ReportType.suspectedMinor => 'SUSPECTED MINOR',
        ReportType.other => 'OTHER',
      };

  String _fmt(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: _typeColor(report.type),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(_typeLabel(report.type),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                Text(_fmt(report.createdAt),
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Reporter: ${report.reporterId}',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text('Reported: ${report.reportedUserId}',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            if (report.description.isNotEmpty) ...[const SizedBox(height: 6),
              Text(report.description,
                  style: const TextStyle(color: Colors.white, fontSize: 13))],
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: ElevatedButton.icon(
                      onPressed: () => onReview('resolved'),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Resolve'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green))),
              const SizedBox(width: 8),
              Expanded(
                  child: ElevatedButton.icon(
                      onPressed: () => onReview('reviewed'),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Dismiss'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange))),
            ]),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// User Moderation Tab
// ===========================================================================

class _UserModerationTab extends ConsumerStatefulWidget {
  const _UserModerationTab();

  @override
  ConsumerState<_UserModerationTab> createState() => _UserModerationTabState();
}

class _UserModerationTabState extends ConsumerState<_UserModerationTab> {
  final _idCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  String _targetId = '';

  @override
  void dispose() {
    _idCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AdminTextField(
            ctrl: _idCtrl,
            hint: 'User ID',
            trailing: IconButton(
              icon: const Icon(Icons.search, color: Colors.white54),
              onPressed: () => setState(() => _targetId = _idCtrl.text.trim()),
            ),
          ),
          if (_targetId.isNotEmpty) ...[const SizedBox(height: 10),
            _AdminTextField(ctrl: _reasonCtrl, hint: 'Ban reason'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Btn('Ban 7d', Icons.block, Colors.orange,
                    () => _ban(const Duration(days: 7))),
                _Btn('Perm Ban', Icons.no_accounts, Colors.red,
                    () => _ban(null)),
                _Btn('Unban', Icons.check_circle, Colors.green, _unban),
                _Btn('Premium 30d', Icons.star, Colors.amber, _grantPremium),
                _Btn('+500 Coins', Icons.monetization_on, Colors.blueAccent,
                    _grantCoins),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _ban(Duration? d) async {
    final reason = _reasonCtrl.text.trim();
    if (reason.isEmpty) { _msg('Enter a reason first.'); return; }
    await ref.read(adminServiceProvider).banUser(_targetId, reason, duration: d);
    _msg('User banned.');
  }

  Future<void> _unban() async {
    await ref.read(adminServiceProvider).unbanUser(_targetId);
    _msg('User unbanned.');
  }

  Future<void> _grantPremium() async {
    await ref.read(adminServiceProvider).grantPremium(_targetId);
    _msg('30-day premium granted.');
  }

  Future<void> _grantCoins() async {
    await ref.read(adminServiceProvider).grantCoins(_targetId, 500);
    _msg('500 coins granted.');
  }

  void _msg(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }
}

// ===========================================================================
// Promo Codes Tab
// ===========================================================================

class _PromoCodesTab extends ConsumerStatefulWidget {
  const _PromoCodesTab();

  @override
  ConsumerState<_PromoCodesTab> createState() => _PromoCodesTabState();
}

class _PromoCodesTabState extends ConsumerState<_PromoCodesTab> {
  final _codeCtrl = TextEditingController();
  final _coinsCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    _coinsCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final promosAsync = ref.watch(promoCodesProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AdminCard(
            title: 'New Promo Code',
            child: Column(
              children: [
                _AdminTextField(ctrl: _codeCtrl, hint: 'Code (e.g. LAUNCH50)'),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                      child: _AdminTextField(
                          ctrl: _coinsCtrl,
                          hint: 'Coin bonus',
                          isNum: true)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _AdminTextField(
                          ctrl: _maxCtrl,
                          hint: 'Max uses',
                          isNum: true)),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent),
                    onPressed: _createCode,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Code'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('All Codes',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          promosAsync.when(
            data: (codes) => codes.isEmpty
                ? const Text('No codes yet.',
                    style: TextStyle(color: Colors.white54))
                : Column(
                    children: codes
                        .map((p) => _PromoTile(
                            promo: p,
                            onDeactivate: () => ref
                                .read(adminServiceProvider)
                                .deactivatePromoCode(p.code)))
                        .toList()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Text('$e', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _createCode() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    await ref.read(adminServiceProvider).createPromoCode(PromoCode(
          code: code,
          coinBonus: int.tryParse(_coinsCtrl.text.trim()) ?? 0,
          discountPercent: 0,
          maxUses: int.tryParse(_maxCtrl.text.trim()) ?? 100,
          usedCount: 0,
          isActive: true,
        ));
    _codeCtrl.clear();
    _coinsCtrl.clear();
    _maxCtrl.clear();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Code created!')));
    }
  }
}

class _PromoTile extends StatelessWidget {
  final PromoCode promo;
  final VoidCallback onDeactivate;
  const _PromoTile({required this.promo, required this.onDeactivate});

  @override
  Widget build(BuildContext context) {
    final active = promo.isActive;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: active
            ? Colors.green.withValues(alpha: 0.08)
            : Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: active
                ? Colors.green.withValues(alpha: 0.35)
                : Colors.grey.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.discount,
              color: active ? Colors.green : Colors.grey, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(promo.code,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text(
                    '${promo.coinBonus} coins • ${promo.usedCount}/${promo.maxUses} uses',
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          if (active)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red, size: 18),
              onPressed: onDeactivate,
            ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Room Moderation Tab
// ===========================================================================

class _RoomModerationTab extends ConsumerStatefulWidget {
  const _RoomModerationTab();

  @override
  ConsumerState<_RoomModerationTab> createState() =>
      _RoomModerationTabState();
}

class _RoomModerationTabState extends ConsumerState<_RoomModerationTab> {
  final _roomCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _roomCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _AdminCard(
        title: 'Close a Room',
        child: Column(
          children: [
            _AdminTextField(ctrl: _roomCtrl, hint: 'Room ID'),
            const SizedBox(height: 8),
            _AdminTextField(ctrl: _reasonCtrl, hint: 'Reason'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: _close,
                icon: const Icon(Icons.close),
                label: const Text('Close Room'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _close() async {
    final id = _roomCtrl.text.trim();
    final reason = _reasonCtrl.text.trim();
    if (id.isEmpty || reason.isEmpty) return;
    await ref.read(adminServiceProvider).closeRoom(id, reason);
    _roomCtrl.clear();
    _reasonCtrl.clear();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Room closed.')));
    }
  }
}

// ===========================================================================
// Shared helpers
// ===========================================================================

class _AdminCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _AdminCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _AdminTextField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final bool isNum;
  final Widget? trailing;
  const _AdminTextField(
      {required this.ctrl, required this.hint, this.isNum = false, this.trailing});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        suffixIcon: trailing,
      ),
    );
  }
}

<<<<<<< HEAD
class _Btn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _Btn(this.label, this.icon, this.color, this.onTap);
=======
  Future<void> _reviewReport(UserReport report, String status) async {
    try {
      final moderationService = ref.read(moderationServiceProvider);
      final currentUser = ref.read(authServiceProvider).currentUser;
      await moderationService.reviewReport(
          report.id, currentUser?.uid ?? 'admin', status);
>>>>>>> origin/develop

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: color),
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

// ===========================================================================
// Reports Tab
// ===========================================================================

class _ReportsTab extends ConsumerWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
              child: Text('Error: ${snap.error}',
                  style: const TextStyle(color: Colors.red)));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
              child: Text('No reports found',
                  style: TextStyle(color: Colors.white54)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final reportId = docs[i].id;
            return _ReportItemTile(
              reportId: reportId,
              data: data,
              onAction: (action) => _handleReportAction(
                  context, ref, reportId, data, action),
            );
          },
        );
      },
    );
  }

  Future<void> _handleReportAction(
    BuildContext context,
    WidgetRef ref,
    String reportId,
    Map<String, dynamic> data,
    String action,
  ) async {
    try {
      if (action == 'ban') {
        final reportedId = data['reportedUserId'] as String?;
        if (reportedId != null) {
          await ref.read(adminServiceProvider).banUser(reportedId, 'Banned via report', duration: null);
        }
      }
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .update({'status': action, 'reviewedAt': FieldValue.serverTimestamp()});
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Report $action')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

class _ReportItemTile extends StatelessWidget {
  final String reportId;
  final Map<String, dynamic> data;
  final void Function(String action) onAction;

  const _ReportItemTile({
    required this.reportId,
    required this.data,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? 'pending';
    final reportedId = data['reportedUserId'] as String? ?? '';
    final reporterId = data['reporterId'] as String? ?? '';
    final reason = data['reason'] as String? ?? data['description'] as String? ?? '';
    final type = data['type'] as String? ?? 'other';
    final isPending = status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPending
            ? Colors.red.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPending
              ? Colors.red.withValues(alpha: 0.3)
              : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(type.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isPending
                    ? Colors.orange.withValues(alpha: 0.2)
                    : Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                    color: isPending ? Colors.orange : Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text('Reporter: $reporterId',
              style: const TextStyle(color: Colors.white60, fontSize: 12)),
          Text('Reported: $reportedId',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(reason,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
          if (isPending) ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onAction('resolved'),
                  icon: const Icon(Icons.check, size: 14),
                  label: const Text('Resolve'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding:
                          const EdgeInsets.symmetric(vertical: 8)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onAction('dismissed'),
                  icon: const Icon(Icons.close, size: 14),
                  label: const Text('Dismiss'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade700,
                      padding:
                          const EdgeInsets.symmetric(vertical: 8)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onAction('ban'),
                  icon: const Icon(Icons.block, size: 14),
                  label: const Text('Ban User'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding:
                          const EdgeInsets.symmetric(vertical: 8)),
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}

// ===========================================================================
// Global Bans Tab
// ===========================================================================

class _GlobalBansTab extends ConsumerWidget {
  const _GlobalBansTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('global_bans')
          .orderBy('bannedAt', descending: true)
          .limit(200)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
              child: Text('No global bans',
                  style: TextStyle(color: Colors.white54)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final userId = docs[i].id;
            final reason = data['reason'] as String? ?? 'No reason';
            final expiresAt = data['expiresAt'];
            final isPermanent = expiresAt == null;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: Colors.red.withValues(alpha: 0.25)),
              ),
              child: Row(children: [
                const Icon(Icons.block, color: Colors.redAccent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userId,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      Text(reason,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                      Text(
                        isPermanent ? 'Permanent ban' : 'Temporary ban',
                        style: TextStyle(
                            color: isPermanent
                                ? Colors.redAccent
                                : Colors.orange,
                            fontSize: 11),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      _unban(context, ref, userId),
                  child: const Text('Unban',
                      style: TextStyle(color: Colors.greenAccent)),
                ),
              ]),
            );
          },
        );
      },
    );
  }

  Future<void> _unban(
      BuildContext context, WidgetRef ref, String userId) async {
    try {
      await ref.read(adminServiceProvider).unbanUser(userId);
      // Also remove from global_bans collection
      await FirebaseFirestore.instance
          .collection('global_bans')
          .doc(userId)
          .delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User unbanned')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

// ===========================================================================
// Analytics Tab
// ===========================================================================

class _AnalyticsTab extends ConsumerWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Platform Analytics',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _AnalyticsMetricCard(
            title: 'Total Users',
            icon: Icons.people,
            color: Colors.blueAccent,
            stream: FirebaseFirestore.instance
                .collection('users')
                .snapshots()
                .map((s) => s.size),
          ),
          const SizedBox(height: 8),
          _AnalyticsMetricCard(
            title: 'Active Rooms Right Now',
            icon: Icons.sensor_occupied,
            color: Colors.greenAccent,
            stream: FirebaseFirestore.instance
                .collection('rooms')
                .where('isActive', isEqualTo: true)
                .snapshots()
                .map((s) => s.size),
          ),
          const SizedBox(height: 8),
          _AnalyticsMetricCard(
            title: 'Pending Reports',
            icon: Icons.flag,
            color: Colors.redAccent,
            stream: FirebaseFirestore.instance
                .collection('reports')
                .where('status', isEqualTo: 'pending')
                .snapshots()
                .map((s) => s.size),
          ),
          const SizedBox(height: 8),
          _AnalyticsMetricCard(
            title: 'Global Bans',
            icon: Icons.block,
            color: Colors.orange,
            stream: FirebaseFirestore.instance
                .collection('global_bans')
                .snapshots()
                .map((s) => s.size),
          ),
          const SizedBox(height: 24),
          const Text(
            'Recent Room Activity',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('rooms')
                .orderBy('createdAt', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Text('No room data',
                    style: TextStyle(color: Colors.white54));
              }
              return Column(
                children: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final name = d['name'] as String? ?? doc.id;
                  final count = d['participantCount'] as int? ?? 0;
                  final isActive = d['isActive'] as bool? ?? false;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.meeting_room,
                          color: isActive ? Colors.greenAccent : Colors.white38,
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                        ),
                        Text(
                          '$count listeners',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AnalyticsMetricCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Stream<int> stream;

  const _AnalyticsMetricCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snap) {
        final value = snap.data ?? 0;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    style: TextStyle(
                        color: color,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ===========================================================================
// Admin Logs Tab
// ===========================================================================

class _AdminLogsTab extends ConsumerWidget {
  const _AdminLogsTab();

  String _fmt(Timestamp? ts) {
    if (ts == null) return '';
    final d = ts.toDate();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('admin_logs')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 60, color: Colors.white24),
                SizedBox(height: 12),
                Text('No admin logs yet',
                    style: TextStyle(color: Colors.white54)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final action = data['action'] as String? ?? 'action';
            final adminId = data['adminId'] as String? ?? 'admin';
            final subject = data['subject'] as String? ?? data['targetId'] as String? ?? '';
            final ts = data['timestamp'] as Timestamp?;
            final details = data['details'] as String? ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        action.toUpperCase(),
                        style: const TextStyle(
                            color: Colors.purpleAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _fmt(ts),
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Text('Admin: $adminId',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11)),
                  if (subject.isNotEmpty)
                    Text('Subject: $subject',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(details,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12)),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

