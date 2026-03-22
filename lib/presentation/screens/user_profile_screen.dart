import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../widgets/mixvy_drawer.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authControllerProvider).uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      drawer: MixVyDrawer(userId: uid),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                  onPressed: () {},
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.settings),
                  label: const Text('Settings'),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          CircleAvatar(radius: 40, backgroundColor: Colors.purple),
          const SizedBox(height: 16),
          const Text('User Profile', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          const Text('Profile details and settings will be shown here.'),
        ],
      ),
    );
  }
}
