import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/controllers/auth_controller.dart';

class MixVyDrawer extends ConsumerWidget {
  final String? userId;
  const MixVyDrawer({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.purple),
            child: const Text('MixVy Navigation', style: TextStyle(color: Colors.white, fontSize: 20)),
          ),
          ListTile(title: const Text('Home Feed'), onTap: () => context.go('/home')),
          ListTile(title: const Text('Chats'), onTap: () => context.go('/chats')),
          ListTile(title: const Text('Friends'), onTap: () => context.go('/friends')),
          if (userId != null)
            ListTile(title: const Text('Profile'), onTap: () => context.go('/profile/$userId')),
          ListTile(title: const Text('Payments'), onTap: () => context.go('/payments')),
          ListTile(title: const Text('Notifications'), onTap: () => context.go('/notifications')),
          ListTile(title: const Text('Live Room'), onTap: () => context.go('/live')),
          ListTile(title: const Text('Settings'), onTap: () => context.go('/settings')),
          ListTile(title: const Text('Moderation'), onTap: () => context.go('/moderation')),
          ListTile(title: const Text('Search'), onTap: () => context.go('/search')),
          ListTile(title: const Text('Invite Friends'), onTap: () => context.go('/invite')),
        ],
      ),
    );
  }
}
