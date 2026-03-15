import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/gifts_provider.dart';

class SendGiftWidget extends ConsumerWidget {
  final String roomId;
  final String userId;
  const SendGiftWidget({super.key, required this.roomId, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final giftsAsync = ref.watch(giftsProvider);
    return giftsAsync.when(
      data: (gifts) => Row(
        children: gifts.map((gift) => IconButton(
          icon: const Icon(Icons.card_giftcard),
          tooltip: gift.name,
          onPressed: () {
            // Send gift logic (deduct coins, animate, log transaction)
          },
        )).toList(),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => const Text('Error loading gifts'),
    );
  }
}
