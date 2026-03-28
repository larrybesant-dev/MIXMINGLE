import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MixVyDrawer extends StatelessWidget {
  final String? userId;
  const MixVyDrawer({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.purple),
            child: const Text('MixVy Navigation', style: TextStyle(color: Colors.white, fontSize: 20)),
          ),
          ListTile(title: const Text('Home'), onTap: () => context.go('/')),
          ListTile(title: const Text('Discover'), onTap: () => context.go('/discover')),
          ListTile(title: const Text('Friends'), onTap: () => context.go('/friends')),
          ListTile(title: const Text('Profile'), onTap: () => context.go('/profile')),
          ListTile(title: const Text('Payments'), onTap: () => context.go('/payments')),
          ListTile(title: const Text('Notifications'), onTap: () => context.go('/notifications')),
          ListTile(title: const Text('Settings'), onTap: () => context.go('/settings')),
        ],
      ),
    );
  }
}
