import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';

class DigitalGoodsCreationPage extends ConsumerStatefulWidget {
  final String userId;
  const DigitalGoodsCreationPage({required this.userId, super.key});

  @override
  ConsumerState<DigitalGoodsCreationPage> createState() => _DigitalGoodsCreationPageState();
}

class _DigitalGoodsCreationPageState extends ConsumerState<DigitalGoodsCreationPage> {
  String name = '';
  String description = '';
  // Asset list removed due to undefined PackAsset type.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Overlay/Emoji Pack')),
      body: const Center(child: Text('Creation unavailable: asset logic removed due to undefined types.')),
    );
  }
}
