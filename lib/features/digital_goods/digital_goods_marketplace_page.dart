import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';

class DigitalGoodsMarketplacePage extends ConsumerWidget {
  final String userId;
  const DigitalGoodsMarketplacePage({required this.userId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Providers removed due to undefined types.

    return Scaffold(
      appBar: AppBar(title: const Text('Digital Goods Marketplace')),
      body: const Center(child: Text('Marketplace unavailable: providers removed due to undefined types.')),
    );
  }
}
