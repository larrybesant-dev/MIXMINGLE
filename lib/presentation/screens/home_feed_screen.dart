import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../widgets/mixvy_drawer.dart';

class HomeFeedScreen extends ConsumerWidget {
  const HomeFeedScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authControllerProvider).uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Home Feed')),
      drawer: MixVyDrawer(userId: uid),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('New Post'),
                  onPressed: () {},
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.meeting_room),
                  label: const Text('Create Room'),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(child: Text('U$index')),
                  title: Text('Post Title $index'),
                  subtitle: Text('This is a placeholder for a live post or event.'),
                  trailing: IconButton(icon: const Icon(Icons.chat), onPressed: () {}),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
