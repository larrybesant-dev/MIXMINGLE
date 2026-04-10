import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/layout/app_layout.dart';
import '../../core/theme.dart';
import '../../features/messaging/providers/messaging_provider.dart';
import '../../widgets/mixvy_drawer.dart';

/// Persistent shell wrapping every main app screen with a frosted Velvet Noir
/// bottom nav bar (Home / Rooms / Discover / Messages / Profile / Menu).
class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({required this.child, super.key});

  static int _indexForLocation(String location) {
    if (location.startsWith('/rooms'))    return 1;
    if (location.startsWith('/discover')) return 2;
    if (location.startsWith('/messages')) return 3;
    if (location.startsWith('/profile'))  return 4;
    return 0;
  }

  static const List<String> _roots = [
    '/',
    '/rooms',
    '/discover',
    '/messages',
    '/profile',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _indexForLocation(location);
    final unreadMsgs = ref.watch(unreadMessageCountProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const MixVyDrawer(),
      body: child,
      bottomNavigationBar: Builder(
        builder: (context) => _VelvetBottomNav(
          selectedIndex: selectedIndex,
          unreadMsgs: unreadMsgs,
          compact: context.isCompactLayout,
          onTap: (i) => context.go(_roots[i]),
          onMenuTap: () => Scaffold.of(context).openDrawer(),
        ),
      ),
    );
  }
}

// ── Velvet Noir bottom navigation bar ────────────────────────────────────────
class _VelvetBottomNav extends StatelessWidget {
  const _VelvetBottomNav({
    required this.selectedIndex,
    required this.unreadMsgs,
    required this.compact,
    required this.onTap,
    required this.onMenuTap,
  });

  final int selectedIndex;
  final int unreadMsgs;
  final bool compact;
  final void Function(int) onTap;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.20),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: compact ? 64 : 72,
              child: Row(
                children: [
                  _navItem(context, 0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                  _navItem(context, 1, Icons.meeting_room_outlined, Icons.meeting_room_rounded, 'Rooms'),
                  _navItem(context, 2, Icons.explore_outlined, Icons.explore_rounded, 'Discover'),
                  _navItemBadge(context, 3, Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Messages', unreadMsgs),
                  _navItem(context, 4, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
                  _navActionItem(context, Icons.menu_rounded, 'Menu', onMenuTap),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    int idx,
    IconData icon,
    IconData selectedIcon,
    String label,
  ) {
    final isSelected = selectedIndex == idx;
    final theme = Theme.of(context);
    final selectedColor = theme.colorScheme.primary;
    final idleColor = theme.colorScheme.onSurfaceVariant;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(idx),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 30,
              decoration: isSelected
                  ? BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          VelvetNoir.primary.withValues(alpha: 0.18),
                          VelvetNoir.primary.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    )
                  : null,
              child: Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? selectedColor : idleColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.raleway(
                fontSize: compact ? 10 : 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? selectedColor : idleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItemBadge(
      BuildContext context,
      int idx,
      IconData icon,
      IconData selectedIcon,
      String label,
      int count) {
    final isSelected = selectedIndex == idx;
    final theme = Theme.of(context);
    final selectedColor = theme.colorScheme.primary;
    final idleColor = theme.colorScheme.onSurfaceVariant;
    final badgeColor = theme.colorScheme.error;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(idx),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 30,
              decoration: isSelected
                  ? BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          VelvetNoir.primary.withValues(alpha: 0.18),
                          VelvetNoir.primary.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    )
                  : null,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(
                    isSelected ? selectedIcon : icon,
                    color: isSelected ? selectedColor : idleColor,
                    size: 22,
                  ),
                  if (count > 0)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.raleway(
                fontSize: compact ? 10 : 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? selectedColor : idleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navActionItem(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 30,
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.raleway(
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
