import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../presentation/providers/notification_provider.dart';
import '../../features/messaging/providers/messaging_provider.dart';
import '../../widgets/mixvy_drawer.dart';
import '../../widgets/friends_panel_button.dart';

// ── Velvet Noir colour aliases ─────────────────────────────────────────────
const _npSurface     = Color(0xFF0D0A0C);
const _npPrimary     = Color(0xFFD4A853);
const _npOnVariant   = Color(0xFFB09080);
const _npError       = Color(0xFFFF6E84);
const _npGhost       = Color(0x14D4A853);

/// Persistent shell wrapping every main app screen with a frosted Neon Pulse
/// bottom nav bar (Home / Rooms / Create / Messages / Profile).
class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({required this.child, super.key});

  static int _indexForLocation(String location) {
    if (location.startsWith('/rooms'))    return 1;
    if (location.startsWith('/messages')) return 2;
    if (location.startsWith('/profile'))  return 3;
    return 0;
  }

  static const List<String> _roots = [
    '/',
    '/rooms',
    '/messages',
    '/profile',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _indexForLocation(location);
    final unreadNotifs = ref.watch(unreadNotificationCountProvider);
    final unreadMsgs   = ref.watch(unreadMessageCountProvider);

    return Scaffold(
      backgroundColor: _npSurface,
      drawer: const MixVyDrawer(),
      body: child,
      bottomNavigationBar: _NeonBottomNav(
        selectedIndex: selectedIndex,
        unreadNotifs: unreadNotifs,
        unreadMsgs: unreadMsgs,
        onTap: (i) => context.go(_roots[i]),
      ),
    );
  }
}

// ── Neon Pulse bottom navigation bar ─────────────────────────────────────────
class _NeonBottomNav extends StatelessWidget {
  const _NeonBottomNav({
    required this.selectedIndex,
    required this.unreadNotifs,
    required this.unreadMsgs,
    required this.onTap,
  });

  final int selectedIndex;
  final int unreadNotifs;
  final int unreadMsgs;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xE5130C0F), // surfaceLow at 90% opacity
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: _npGhost)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 68,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                  _friendsNavItem(context),
                  _navItem(1, Icons.meeting_room_outlined,
                      Icons.meeting_room_rounded, 'Rooms'),
                  _navItemBadge(2, Icons.chat_bubble_outline_rounded,
                      Icons.chat_bubble_rounded, 'Messages', unreadMsgs),
                  _navItem(3, Icons.person_outline_rounded,
                      Icons.person_rounded, 'Profile'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _friendsNavItem(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FriendsPanelButton.openPanel(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 32,
              child: const Icon(
                Icons.people_alt_outlined,
                color: _npOnVariant,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Friends',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: _npOnVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int idx, IconData icon, IconData selectedIcon, String label) {
    final isSelected = selectedIndex == idx;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(idx),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40, height: 32,
              decoration: isSelected
                  ? BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0x33D4A853), Color(0x228C6020)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    )
                  : null,
              child: Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? _npPrimary : _npOnVariant,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? _npPrimary : _npOnVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItemBadge(
      int idx, IconData icon, IconData selectedIcon, String label, int count) {
    final isSelected = selectedIndex == idx;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(idx),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40, height: 32,
              decoration: isSelected
                  ? BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0x33D4A853), Color(0x228C6020)],
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
                    color: isSelected ? _npPrimary : _npOnVariant,
                    size: 22,
                  ),
                  if (count > 0)
                    Positioned(
                      top: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: _npError,
                          shape: count > 9 ? BoxShape.rectangle : BoxShape.circle,
                          borderRadius: count > 9 ? BorderRadius.circular(8) : null,
                        ),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? _npPrimary : _npOnVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
