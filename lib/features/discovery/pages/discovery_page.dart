import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/discovery_provider.dart';
import '../widgets/discovery_tile_widget.dart';

class DiscoveryPage extends ConsumerWidget {
  const DiscoveryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoveries = ref.watch(discoveryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Discovery')),
      body: discoveries.when(
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return DiscoveryTileWidget(discovery: item);
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
