import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/after_dark/providers/after_dark_provider.dart';
import '../features/auth/providers/admin_provider.dart';
import '../features/beta/beta_tester_provider.dart';
import '../presentation/providers/notification_provider.dart';

class MixVyDrawer extends ConsumerWidget {
  final String? userId;
  const MixVyDrawer({super.key, this.userId});

  Widget _sectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.62),
            ),
      ),
    );
  }

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
    final isAdmin = ref.watch(isAdminProvider).valueOrNull ?? false;
    final isBetaTester = ref.watch(isBetaTesterProvider).valueOrNull ?? false;
    final afterDarkEnabled = ref.watch(afterDarkEnabledProvider).valueOrNull ?? false;
    final afterDarkSessionActive = ref.watch(afterDarkSessionProvider);
    final afterDarkRoute = !afterDarkEnabled
        ? '/after-dark/setup'
        : (afterDarkSessionActive ? '/after-dark' : '/after-dark/unlock');

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
                  style: TextStyle(color: Color(0xFFF2EBE0), fontSize: 28, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Elevated. Social. Live.',
                  style: TextStyle(color: Color(0xFFF2EBE0).withValues(alpha: 0.75), fontSize: 14),
                ),
              ],
            ),
          ),
          _navItem(context, icon: Icons.home_rounded, title: 'Home', route: '/'),
          _navItem(context, icon: Icons.explore_rounded, title: 'Discover', route: '/discover'),
          _navItem(context, icon: Icons.meeting_room_outlined, title: 'Room Directory', route: '/rooms'),
          _sectionLabel(context, 'CREATE'),
          _navItem(context, icon: Icons.mic_external_on_rounded, title: 'Host Room', route: '/create-room'),
          _navItem(context, icon: Icons.article_outlined, title: 'New Post', route: '/create-post'),
          _navItem(context, icon: Icons.auto_stories_outlined, title: 'New Story', route: '/create-story'),
          _navItem(context, icon: Icons.group_add_outlined, title: 'New Group', route: '/create-group'),
          _sectionLabel(context, 'EXPLORE'),
          _navItem(context, icon: Icons.search_rounded, title: 'Search', route: '/search'),
          _navItem(context, icon: Icons.mail_rounded, title: 'Messages', route: '/messages'),
          _navItem(context, icon: Icons.bookmark_rounded, title: 'Bookmarks', route: '/bookmarks'),
          _navItem(context, icon: Icons.people_outline_rounded, title: 'Groups', route: '/groups'),
          _navItem(context, icon: Icons.trending_up_rounded, title: 'Trending', route: '/trending'),
          _navItem(context, icon: Icons.local_fire_department_rounded, title: 'Live Speed Dating', route: '/speed-dating'),
          _navItem(context, icon: Icons.nightlight_rounded, title: 'After Dark', route: afterDarkRoute),
          _navItem(context, icon: Icons.people_alt_rounded, title: 'Friends', route: '/friends'),
          _navItem(context, icon: Icons.person_rounded, title: 'Profile', route: '/profile'),
          _navItem(context, icon: Icons.verified_user_rounded, title: 'Get Verified', route: '/verification'),
          _navItem(context, icon: Icons.payments_rounded, title: 'Payments', route: '/payments'),
          _navItem(context, icon: Icons.notifications_active_rounded, title: 'Notifications', route: '/notifications', badgeCount: unreadCount),
          if (isBetaTester)
            _navItem(context, icon: Icons.science_outlined, title: 'Beta Feedback', route: '/beta-feedback'),
          if (isAdmin)
            _navItem(context, icon: Icons.admin_panel_settings_rounded, title: 'Moderation', route: '/moderation'),
          _navItem(context, icon: Icons.settings_rounded, title: 'Settings', route: '/settings'),
        ],
      ),
    );
  }
}
