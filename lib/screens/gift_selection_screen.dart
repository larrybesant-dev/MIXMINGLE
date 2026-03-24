import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gift_model.dart';
import '../presentation/providers/gift_provider.dart';

class GiftSelectionScreen extends ConsumerWidget {
  final void Function(GiftModel?)? onGiftSelected;
  const GiftSelectionScreen({super.key, this.onGiftSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gifts = ref.watch(giftListProvider);
    final selectedGift = ref.watch(selectedGiftProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Select a Gift')),
      body: ListView.builder(
        itemCount: gifts.length,
        itemBuilder: (context, index) {
          final gift = gifts[index];
          final isSelected = selectedGift?.id == gift.id;
          return ListTile(
            title: Text(gift.type ?? 'Gift'),
              subtitle: Text('Amount: ₤${gift.amount ?? 0}'),
            trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
            selected: isSelected,
            onTap: () {
              ref.read(selectedGiftProvider.notifier).state = gift;
              if (onGiftSelected != null) {
                onGiftSelected!(gift);
              }
              Navigator.pop(context, gift);
            },
          );
        },
      ),
    );
  }
}
