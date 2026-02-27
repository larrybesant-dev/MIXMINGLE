// lib/features/admin/ads_admin_page.dart
//
// Admin panel for the MixMingle Ad Monetization system.
// Accessible only to users with the `admin` custom claim.
//
// Tabs:
//   1. Advertisers — view/add/pause/resume advertisers, top-up impressions
//   2. Ads          — view all ad creatives per advertiser
//   3. Promo Codes  — create promo codes

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/advertiser.dart';
import '../../shared/models/ad_entry.dart';
import '../../shared/models/promo_code.dart';
import '../../shared/providers/ads_providers.dart';
import '../../shared/widgets/club_background.dart';
import '../../shared/widgets/glow_text.dart';
import '../../core/analytics/analytics_service.dart';

class AdsAdminPage extends ConsumerStatefulWidget {
  const AdsAdminPage({super.key});

  @override
  ConsumerState<AdsAdminPage> createState() => _AdsAdminPageState();
}

class _AdsAdminPageState extends ConsumerState<AdsAdminPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    AnalyticsService.instance.logScreenView(screenName: 'screen_ads_admin');
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
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const GlowText(
            text: 'Ad Manager',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            glowColor: Color(0xFFFF4C4C),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              tooltip: 'Add Advertiser',
              onPressed: () => _showAddAdvertiserDialog(context),
            ),
          ],
          bottom: TabBar(
            controller: _tabs,
            indicatorColor: const Color(0xFFFF4C4C),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: const [
              Tab(text: 'Advertisers'),
              Tab(text: 'Ad Creatives'),
              Tab(text: 'Promo Codes'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabs,
          children: const [
            _AdvertisersTab(),
            _AdsTab(),
            _PromoCodesTab(),
          ],
        ),
      ),
    );
  }

  void _showAddAdvertiserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _AddAdvertiserDialog(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TAB 1 — ADVERTISERS
// ═══════════════════════════════════════════════════════════════════════════

class _AdvertisersTab extends ConsumerWidget {
  const _AdvertisersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(allAdvertisersProvider);

    return snap.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: Color(0xFFFF4C4C))),
      error: (e, _) => Center(
        child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
      ),
      data: (advertisers) {
        if (advertisers.isEmpty) {
          return const Center(
            child: Text(
              'No advertisers yet.\nTap + to add one.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: advertisers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _AdvertiserCard(advertiser: advertisers[i]),
        );
      },
    );
  }
}

class _AdvertiserCard extends ConsumerWidget {
  final Advertiser advertiser;
  const _AdvertiserCard({required this.advertiser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(adsServiceProvider);
    final statusColor = _statusColor(advertiser.billingStatus);

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      advertiser.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      advertiser.website,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Text(
                  advertiser.billingStatus.name.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Active indicator
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: advertiser.active ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            children: [
              _statChip(Icons.visibility_outlined,
                  '${advertiser.impressionsRemaining} impr.'),
              const SizedBox(width: 8),
              _statChip(Icons.ads_click, '${advertiser.clicksRemaining} clicks'),
              if (advertiser.promoCode != null) ...[
                const SizedBox(width: 8),
                _statChip(Icons.discount_outlined, advertiser.promoCode!),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Action buttons
          Row(
            children: [
              // Pause / Resume
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => advertiser.active
                      ? service.pauseAdvertiser(advertiser.id)
                      : service.resumeAdvertiser(advertiser.id),
                  icon: Icon(
                    advertiser.active ? Icons.pause : Icons.play_arrow,
                    size: 16,
                  ),
                  label: Text(advertiser.active ? 'Pause' : 'Resume'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: advertiser.active
                        ? Colors.orange
                        : Colors.greenAccent,
                    side: BorderSide(
                      color: advertiser.active
                          ? Colors.orange
                          : Colors.greenAccent,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Top-up impressions
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _showTopUpDialog(context, ref, advertiser),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Top-Up'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF4C4C),
                    side: const BorderSide(color: Color(0xFFFF4C4C)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white60),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  Color _statusColor(BillingStatus s) {
    switch (s) {
      case BillingStatus.paid:
        return Colors.blueAccent;
      case BillingStatus.promo:
        return Colors.purpleAccent;
      case BillingStatus.free:
        return Colors.greenAccent;
    }
  }

  void _showTopUpDialog(
      BuildContext context, WidgetRef ref, Advertiser advertiser) {
    final ctrl = TextEditingController(text: '1000');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Top-Up Impressions',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Impressions to add',
            labelStyle: const TextStyle(color: Colors.white60),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white30),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide:
                  const BorderSide(color: Color(0xFFFF4C4C)),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4C4C)),
            onPressed: () {
              final count = int.tryParse(ctrl.text) ?? 0;
              if (count > 0) {
                ref
                    .read(adsServiceProvider)
                    .addImpressions(advertiser.id, count);
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TAB 2 — AD CREATIVES
// ═══════════════════════════════════════════════════════════════════════════

class _AdsTab extends ConsumerWidget {
  const _AdsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(allAdsProvider);

    return snap.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: Color(0xFFFF4C4C))),
      error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      data: (ads) {
        if (ads.isEmpty) {
          return const Center(
            child: Text(
              'No ad creatives yet.',
              style: TextStyle(color: Colors.white60),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: ads.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _AdEntryCard(ad: ads[i]),
        );
      },
    );
  }
}

class _AdEntryCard extends ConsumerWidget {
  final AdEntry ad;
  const _AdEntryCard({required this.ad});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              ad.imageUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 64,
                height: 64,
                color: Colors.grey[900],
                child: const Icon(Icons.broken_image, color: Colors.white38),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ad.headline ?? ad.id,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Advertiser: ${ad.advertiserId}',
                  style:
                      const TextStyle(color: Colors.white60, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _Chip(ad.type.name.toUpperCase(), Colors.blueAccent),
                    const SizedBox(width: 4),
                    _Chip(
                        '${ad.impressionCount} impr.',
                        Colors.white38),
                    const SizedBox(width: 4),
                    _Chip(
                        '${ad.clickCount} clicks',
                        Colors.white38),
                    if (ad.ageRestricted) ...[
                      const SizedBox(width: 4),
                      const _Chip('18+', Colors.redAccent),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Active toggle
          Switch(
            value: ad.active,
            activeThumbColor: const Color(0xFFFF4C4C),
            onChanged: (val) {
              ref.read(adsServiceProvider).upsertAd(
                    AdEntry(
                      id: ad.id,
                      advertiserId: ad.advertiserId,
                      type: ad.type,
                      imageUrl: ad.imageUrl,
                      linkUrl: ad.linkUrl,
                      placements: ad.placements,
                      weight: ad.weight,
                      active: val,
                      ageRestricted: ad.ageRestricted,
                      headline: ad.headline,
                      ctaLabel: ad.ctaLabel,
                      impressionCount: ad.impressionCount,
                      clickCount: ad.clickCount,
                      createdAt: ad.createdAt,
                    ),
                  );
            },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TAB 3 — PROMO CODES
// ═══════════════════════════════════════════════════════════════════════════

class _PromoCodesTab extends ConsumerStatefulWidget {
  const _PromoCodesTab();

  @override
  ConsumerState<_PromoCodesTab> createState() => _PromoCodesTabState();
}

class _PromoCodesTabState extends ConsumerState<_PromoCodesTab> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: () => _showCreatePromoDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Promo Code'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4C4C),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          const Expanded(
            child: Center(
              child: Text(
                'Promo codes are stored in Firestore.\nUse the Firestore console to view all codes.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePromoDialog(BuildContext context) {
    final codeCtrl = TextEditingController();
    final advertiserCtrl = TextEditingController();
    final valueCtrl = TextEditingController(text: '5000');
    PromoType selectedType = PromoType.impressions;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('Create Promo Code',
              style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogField(
                    controller: codeCtrl,
                    label: 'Promo Code (e.g. STB2025)'),
                const SizedBox(height: 10),
                _DialogField(
                    controller: advertiserCtrl,
                    label: 'Advertiser ID'),
                const SizedBox(height: 10),
                DropdownButtonFormField<PromoType>(
                  initialValue: selectedType,
                  dropdownColor: const Color(0xFF1A1A2E),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Promo Type',
                    labelStyle: const TextStyle(color: Colors.white60),
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: Colors.white30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                          color: Color(0xFFFF4C4C)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: PromoType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.name),
                          ))
                      .toList(),
                  onChanged: (t) =>
                      setDlgState(() => selectedType = t!),
                ),
                const SizedBox(height: 10),
                _DialogField(
                    controller: valueCtrl,
                    label: 'Value (impressions / discount %)',
                    keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4C4C)),
              onPressed: () async {
                final code = codeCtrl.text.trim().toUpperCase();
                final advertiserId = advertiserCtrl.text.trim();
                final value = int.tryParse(valueCtrl.text) ?? 0;

                if (code.isEmpty || advertiserId.isEmpty) return;

                final promo = PromoCode(
                  code: code,
                  advertiserId: advertiserId,
                  type: selectedType,
                  value: value,
                  expiresAt: DateTime.now().add(const Duration(days: 365)),
                  active: true,
                );

                await ref
                    .read(adsServiceProvider)
                    .createPromoCode(promo);

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Promo code $code created!')),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ADD ADVERTISER DIALOG
// ═══════════════════════════════════════════════════════════════════════════

class _AddAdvertiserDialog extends ConsumerStatefulWidget {
  const _AddAdvertiserDialog();

  @override
  ConsumerState<_AddAdvertiserDialog> createState() =>
      _AddAdvertiserDialogState();
}

class _AddAdvertiserDialogState
    extends ConsumerState<_AddAdvertiserDialog> {
  final _idCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _promoCtrl = TextEditingController();
  final _impressionsCtrl = TextEditingController(text: '5000');
  final _clicksCtrl = TextEditingController(text: '200');
  BillingStatus _status = BillingStatus.paid;
  bool _loading = false;

  @override
  void dispose() {
    _idCtrl.dispose();
    _nameCtrl.dispose();
    _websiteCtrl.dispose();
    _promoCtrl.dispose();
    _impressionsCtrl.dispose();
    _clicksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: const Text('Add Advertiser',
          style: TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogField(controller: _idCtrl, label: 'Advertiser ID (slug)'),
            const SizedBox(height: 10),
            _DialogField(controller: _nameCtrl, label: 'Display Name'),
            const SizedBox(height: 10),
            _DialogField(
                controller: _websiteCtrl,
                label: 'Website URL',
                keyboardType: TextInputType.url),
            const SizedBox(height: 10),
            DropdownButtonFormField<BillingStatus>(
              initialValue: _status,
              dropdownColor: const Color(0xFF1A1A2E),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Billing Status',
                labelStyle: const TextStyle(color: Colors.white60),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white30),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      const BorderSide(color: Color(0xFFFF4C4C)),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: BillingStatus.values
                  .map((s) => DropdownMenuItem(
                      value: s, child: Text(s.name)))
                  .toList(),
              onChanged: (s) => setState(() => _status = s!),
            ),
            const SizedBox(height: 10),
            _DialogField(
                controller: _promoCtrl,
                label: 'Promo Code (optional)'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _DialogField(
                      controller: _impressionsCtrl,
                      label: 'Impressions',
                      keyboardType: TextInputType.number),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DialogField(
                      controller: _clicksCtrl,
                      label: 'Clicks',
                      keyboardType: TextInputType.number),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child:
              const Text('Cancel', style: TextStyle(color: Colors.white60)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4C4C)),
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final id = _idCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final website = _websiteCtrl.text.trim();

    if (id.isEmpty || name.isEmpty || website.isEmpty) return;

    setState(() => _loading = true);

    final advertiser = Advertiser(
      id: id,
      name: name,
      website: website,
      active: true,
      billingStatus: _status,
      promoCode:
          _promoCtrl.text.trim().isEmpty ? null : _promoCtrl.text.trim(),
      impressionsRemaining: int.tryParse(_impressionsCtrl.text) ?? 5000,
      clicksRemaining: int.tryParse(_clicksCtrl.text) ?? 200,
      createdAt: DateTime.now(),
    );

    await ref.read(adsServiceProvider).upsertAdvertiser(advertiser);

    setState(() => _loading = false);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Advertiser $name added!')),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  const _DialogField({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white30),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFFF4C4C)),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
