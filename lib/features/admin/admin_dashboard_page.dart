// ignore_for_file: unused_element
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixmingle/shared/models/report.dart' show ReportType;
import 'package:mixmingle/shared/models/moderation.dart' show UserReport;
import 'package:mixmingle/shared/widgets/club_background.dart';
import 'package:mixmingle/shared/widgets/glow_text.dart';
import 'package:mixmingle/shared/providers/all_providers.dart';
import 'package:mixmingle/services/admin/admin_service.dart';

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
    _tabs = TabController(length: 4, vsync: this);
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
        ReportType.other => Colors.grey,
      };

  String _typeLabel(ReportType t) => switch (t) {
        ReportType.spam => 'SPAM',
        ReportType.harassment => 'HARASSMENT',
        ReportType.inappropriateContent => 'INAPPROPRIATE',
        ReportType.hateSpeech => 'HATE SPEECH',
        ReportType.violence => 'VIOLENCE',
        ReportType.scam => 'SCAM',
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

class _Btn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _Btn(this.label, this.icon, this.color, this.onTap);

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
