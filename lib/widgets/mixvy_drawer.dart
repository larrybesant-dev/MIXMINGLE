import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/providers/notification_provider.dart';

class MixVyDrawer extends ConsumerWidget {
  final String? userId;
  const MixVyDrawer({super.key, this.userId});

  Widget _navItem(BuildContext context, {required IconData icon, required String title, required String route, int badgeCount = 0}) {
    return ListTile(
      leading: badgeCount > 0
          ? Badge(
              label: Text(badgeCount > 99 ? '99+' : '$badgeCount'),
              child: Icon(icon, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9)),
            )
          : Icon(icon, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9)),
      title: Text(title),
      onTap: () => context.go(route),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'MixVy',
                  style: TextStyle(color: Color(0xFFECEDF6), fontSize: 28, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Urban live social network',
                  style: TextStyle(color: Color(0xFFECEDF6).withValues(alpha: 0.75), fontSize: 14),
                ),
              ],
            ),
          ),
          _navItem(context, icon: Icons.home_rounded, title: 'Home', route: '/'),
          _navItem(context, icon: Icons.explore_rounded, title: 'Discover', route: '/discover'),
          _navItem(context, icon: Icons.meeting_room_outlined, title: 'Room Directory', route: '/rooms'),
          _navItem(context, icon: Icons.search_rounded, title: 'Search', route: '/search'),
          _navItem(context, icon: Icons.mail_rounded, title: 'Messages', route: '/messages'),
          _navItem(context, icon: Icons.bookmark_rounded, title: 'Bookmarks', route: '/bookmarks'),
          _navItem(context, icon: Icons.people_outline_rounded, title: 'Groups', route: '/groups'),
          _navItem(context, icon: Icons.trending_up_rounded, title: 'Trending', route: '/trending'),
          _navItem(context, icon: Icons.local_fire_department_rounded, title: 'Live Speed Dating', route: '/speed-dating'),
          _navItem(context, icon: Icons.people_alt_rounded, title: 'Friends', route: '/friends'),
          _navItem(context, icon: Icons.person_rounded, title: 'Profile', route: '/profile'),
          _navItem(context, icon: Icons.verified_user_rounded, title: 'Get Verified', route: '/verification'),
          _navItem(context, icon: Icons.payments_rounded, title: 'Payments', route: '/payments'),
          _navItem(context, icon: Icons.notifications_active_rounded, title: 'Notifications', route: '/notifications', badgeCount: unreadCount),
          _navItem(context, icon: Icons.admin_panel_settings_rounded, title: 'Moderation', route: '/moderation'),
          _navItem(context, icon: Icons.settings_rounded, title: 'Settings', route: '/settings'),
        ],
      ),
    );
  }
}
