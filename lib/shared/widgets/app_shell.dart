import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/providers/notification_provider.dart';
import '../../features/messaging/providers/messaging_provider.dart';
import '../../widgets/mixvy_drawer.dart';

/// Persistent shell that wraps every main app screen with a bottom
/// NavigationBar (Home / Rooms / Messages / Notifications / Profile) and the
/// slide-out MixVyDrawer. Injected via go_router's ShellRoute so every route
/// inside the shell shares the same nav chrome without rebuilding it.
class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({required this.child, super.key});

  // Maps a route location prefix to a bottom-nav index.
  static int _indexForLocation(String location) {
    if (location.startsWith('/rooms')) return 1;
    if (location.startsWith('/messages')) return 2;
    if (location.startsWith('/notifications')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0; // Home for everything else
  }

  static const List<String> _roots = [
    '/',
    '/rooms',
    '/messages',
    '/notifications',
    '/profile',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _indexForLocation(location);
    final unreadNotifs = ref.watch(unreadNotificationCountProvider);
    final unreadMsgs = ref.watch(unreadMessageCountProvider);

    return Scaffold(
      drawer: const MixVyDrawer(),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => context.go(_roots[i]),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.meeting_room_outlined),
            selectedIcon: Icon(Icons.meeting_room_rounded),
            label: 'Rooms',
          ),
          NavigationDestination(
            icon: _badge(
              unreadMsgs,
              const Icon(Icons.chat_bubble_outline_rounded),
            ),
            selectedIcon: _badge(
              unreadMsgs,
              const Icon(Icons.chat_bubble_rounded),
            ),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: _badge(
              unreadNotifs,
              const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: _badge(
              unreadNotifs,
              const Icon(Icons.notifications_rounded),
            ),
            label: 'Alerts',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  static Widget _badge(int count, Widget icon) {
    if (count <= 0) return icon;
    return Badge(
      label: Text(count > 99 ? '99+' : '$count'),
      child: icon,
    );
  }
}
