import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'digital_goods_providers.dart';
import 'models.dart';

class DigitalGoodsMarketplacePage extends ConsumerWidget {
  final String userId;
  const DigitalGoodsMarketplacePage({required this.userId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packsAsync = ref.watch(packsProvider);
    final purchasesAsync = ref.watch(userPurchasesProvider(userId));
    final tierAsync = ref.watch(userTierProvider(userId));

    return Scaffold(
      appBar: AppBar(title: Text('Digital Goods Marketplace')),
      body: packsAsync.when(
        data: (packs) {
          final purchasedIds = purchasesAsync.maybeWhen(
            data: (purchases) => purchases.map((p) => p.packId).toSet(),
            orElse: () => <String>{},
          );
          final userTier = tierAsync.maybeWhen(
            data: (tier) => tier,
            orElse: () => null,
          );
          return ListView.builder(
            itemCount: packs.length,
            itemBuilder: (context, index) {
              final pack = packs[index];
              final unlocked = userTier != null && isPackUnlocked(
                tier: userTier,
                pack: pack,
                purchasedPackIds: purchasedIds,
              );
              return ListTile(
                leading: Image.network(pack.previewImageUrl, width: 48, height: 48, fit: BoxFit.cover),
                title: Text(pack.name),
                subtitle: Text(pack.description),
                trailing: unlocked
                  ? Text('Unlocked', style: TextStyle(color: Colors.green))
                  : ElevatedButton(
                      child: Text('Buy'),
                      onPressed: () {
                        // TODO: Trigger Stripe purchase flow
                      },
                    ),
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading packs')), 
      ),
    );
  }
}
