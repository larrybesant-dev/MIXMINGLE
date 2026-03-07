import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gift.dart';
import '../providers/gift_providers.dart';
import '../providers/auth_providers.dart';

/// Bottom-sheet gift picker.
///
/// Usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   builder: (_) => GiftPickerWidget(
///     roomId: roomId,
///     receiverId: receiverId,
///     receiverName: hostName,
///   ),
/// );
/// ```
class GiftPickerWidget extends ConsumerWidget {
  final String roomId;
  final String receiverId;
  final String receiverName;

  const GiftPickerWidget({
    super.key,
    required this.roomId,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(giftCatalogProvider);
    final coinBalance = ref.watch(coinBalanceProvider).value ?? 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D2B),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
              color: Colors.purpleAccent.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Gift ${receiverName.split(' ').first}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  const Icon(Icons.monetization_on,
                      color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text('$coinBalance',
                      style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Grid
            Expanded(
              child: catalogAsync.when(
                data: (catalog) => GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: catalog.length,
                  itemBuilder: (ctx, i) => _GiftCard(
                    gift: catalog[i],
                    roomId: roomId,
                    receiverId: receiverId,
                    receiverName: receiverName,
                  ),
                ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(
                    child: Text('Could not load gifts',
                        style: TextStyle(color: Colors.white54))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual gift card
// ---------------------------------------------------------------------------

class _GiftCard extends ConsumerWidget {
  final Gift gift;
  final String roomId;
  final String receiverId;
  final String receiverName;

  const _GiftCard({
    required this.gift,
    required this.roomId,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rarityColor = switch (gift.rarity) {
      GiftRarity.common => Colors.grey.shade400,
      GiftRarity.rare => Colors.blueAccent,
      GiftRarity.epic => Colors.purpleAccent,
      GiftRarity.legendary => Colors.amber,
    };

    return GestureDetector(
      onTap: () => _confirmSend(context, ref),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
              color: rarityColor.withValues(alpha: 0.5), width: 1.5),
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              rarityColor.withValues(alpha: 0.15),
              Colors.transparent
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(gift.emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 4),
            Text(gift.name,
                style:
                    const TextStyle(color: Colors.white, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monetization_on,
                    size: 10, color: Colors.amber),
                const SizedBox(width: 2),
                Text('${gift.coinCost}',
                    style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSend(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A3A),
        title: Text('Send ${gift.emoji} ${gift.name}?',
            style: const TextStyle(color: Colors.white)),
        content: Row(
          children: [
            const Icon(Icons.monetization_on, color: Colors.amber),
            const SizedBox(width: 8),
            Text('${gift.coinCost} coins',
                style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send Gift'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final me = ref.read(currentUserProvider).value;
      if (me == null) return;

      await ref.read(giftServiceProvider).sendGift(
            senderId: me.id,
            senderName: me.displayName ?? me.username,
            receiverId: receiverId,
            roomId: roomId,
            gift: gift,
          );

      if (context.mounted) {
        Navigator.pop(context); // close the picker
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${gift.emoji} ${gift.name} sent to $receiverName!'),
          backgroundColor: Colors.purple.shade700,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}
