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
/// bottom nav bar built around a simpler feed-first structure:
/// Home / Rooms / Messages / Groups / Profile.
class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  final int selectedIndex;
  final bool useDesktopMessengerLayout;

  const AppShell({
    required this.child,
    required this.selectedIndex,
    this.useDesktopMessengerLayout = false,
    super.key,
  });

  static const List<String> _roots = [
    '/discover',
    '/live',
    '/messages',
    '/groups',
    '/profile',
  ];

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _showDesktopSidebar = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktopMessengerLayout =
        context.isExpandedLayout && widget.useDesktopMessengerLayout;
    final unreadMsgs = ref.watch(unreadMessageCountProvider);
    final useDockedSidebar =
        context.screenWidth >= AppBreakpoints.expanded &&
        !isDesktopMessengerLayout;

    final bodyContent = useDockedSidebar
        ? Stack(
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: _showDesktopSidebar ? 310 : 0,
                    child: _showDesktopSidebar
                        ? DecoratedBox(
                            decoration: BoxDecoration(
                              color: VelvetNoir.surfaceLow.withValues(
                                alpha: 0.96,
                              ),
                              border: Border(
                                right: BorderSide(
                                  color: theme.colorScheme.outline.withValues(
                                    alpha: 0.16,
                                  ),
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 22,
                                  offset: const Offset(4, 0),
                                ),
                              ],
                            ),
                            child: SafeArea(
                              right: false,
                              child: MixVyDrawer(
                                embedded: true,
                                onClose: () {
                                  setState(() => _showDesktopSidebar = false);
                                },
                              ),
                            ),
                          )
                        : null,
                  ),
                  Expanded(child: widget.child),
                ],
              ),
              Positioned(
                left: _showDesktopSidebar ? 294 : 8,
                top: 18,
                child: _DesktopSidebarToggle(
                  isOpen: _showDesktopSidebar,
                  onTap: () {
                    setState(() => _showDesktopSidebar = !_showDesktopSidebar);
                  },
                ),
              ),
            ],
          )
        : widget.child;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: isDesktopMessengerLayout
          ? PreferredSize(
              preferredSize: const Size.fromHeight(72),
              child: _DesktopTopNav(
                selectedIndex: widget.selectedIndex,
                unreadMsgs: unreadMsgs,
                onTap: (i) => context.go(AppShell._roots[i]),
              ),
            )
          : null,
      drawer: (isDesktopMessengerLayout || useDockedSidebar)
          ? null
          : const MixVyDrawer(),
      body: bodyContent,
      bottomNavigationBar: isDesktopMessengerLayout
          ? null
          : Builder(
              builder: (context) => _VelvetBottomNav(
                selectedIndex: widget.selectedIndex,
                unreadMsgs: unreadMsgs,
                compact: context.isCompactLayout,
                onTap: (i) => context.go(AppShell._roots[i]),
                onMenuTap: useDockedSidebar
                    ? () {
                        setState(
                          () => _showDesktopSidebar = !_showDesktopSidebar,
                        );
                      }
                    : () => Scaffold.maybeOf(context)?.openDrawer(),
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
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.surface.withValues(alpha: 0.98),
                VelvetNoir.surfaceLow.withValues(alpha: 0.96),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.20),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: compact ? 64 : 72,
              child: Row(
                children: [
                  _navItem(
                    context,
                    0,
                    Icons.home_outlined,
                    Icons.home_rounded,
                    'Home',
                  ),
                  _navItem(
                    context,
                    1,
                    Icons.meeting_room_outlined,
                    Icons.meeting_room_rounded,
                    'Rooms',
                  ),
                  _navItem(
                    context,
                    2,
                    Icons.mail_outline_rounded,
                    Icons.mail_rounded,
                    'Messages',
                    badgeCount: unreadMsgs,
                  ),
                  _navItem(
                    context,
                    3,
                    Icons.groups_2_outlined,
                    Icons.groups_2_rounded,
                    'Groups',
                  ),
                  _navItem(
                    context,
                    4,
                    Icons.person_outline_rounded,
                    Icons.person_rounded,
                    'Profile',
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _menuButton(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuButton(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onMenuTap,
        child: Ink(
          width: compact ? 40 : 44,
          height: compact ? 40 : 44,
          decoration: BoxDecoration(
            color: VelvetNoir.surfaceHigh.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.20),
            ),
          ),
          child: Icon(
            Icons.menu_rounded,
            color: theme.colorScheme.onSurface,
            size: compact ? 20 : 22,
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
    String label, {
    int badgeCount = 0,
  }) {
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
              curve: Curves.easeOutCubic,
              width: isSelected ? 48 : 40,
              height: isSelected ? 34 : 30,
              decoration: isSelected
                  ? BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          VelvetNoir.primary.withValues(alpha: 0.24),
                          VelvetNoir.secondary.withValues(alpha: 0.12),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: VelvetNoir.primary.withValues(alpha: 0.22),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: VelvetNoir.primary.withValues(alpha: 0.10),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    )
                  : null,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isSelected ? selectedIcon : icon,
                    color: isSelected ? selectedColor : idleColor,
                    size: 22,
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -8,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: VelvetNoir.error,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
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
                letterSpacing: isSelected ? 0.2 : 0,
                color: isSelected ? selectedColor : idleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopSidebarToggle extends StatelessWidget {
  const _DesktopSidebarToggle({required this.isOpen, required this.onTap});

  final bool isOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: VelvetNoir.surfaceHigh.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            border: Border.all(
              color: VelvetNoir.primary.withValues(alpha: 0.28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Tooltip(
            message: isOpen ? 'Hide menu' : 'Show menu',
            child: Icon(
              isOpen ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
              color: VelvetNoir.primary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopTopNav extends StatelessWidget {
  const _DesktopTopNav({
    required this.selectedIndex,
    required this.unreadMsgs,
    required this.onTap,
  });

  final int selectedIndex;
  final int unreadMsgs;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final items = <({String label, IconData icon})>[
      (label: 'Home', icon: Icons.home_rounded),
      (label: 'Rooms', icon: Icons.meeting_room_rounded),
      (label: 'Messages', icon: Icons.mail_rounded),
      (label: 'Groups', icon: Icons.groups_2_rounded),
      (label: 'Profile', icon: Icons.person_rounded),
    ];

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: VelvetNoir.surfaceHigh.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: VelvetNoir.outlineVariant.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final selected = selectedIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.all(6),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? VelvetNoir.primary.withValues(alpha: 0.18)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: selected
                          ? Border.all(
                              color: VelvetNoir.primary.withValues(alpha: 0.35),
                            )
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              item.icon,
                              size: 18,
                              color: selected
                                  ? VelvetNoir.primary
                                  : VelvetNoir.onSurfaceVariant,
                            ),
                            if (index == 2 && unreadMsgs > 0)
                              Positioned(
                                right: -8,
                                top: -8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: VelvetNoir.error,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    unreadMsgs > 99 ? '99+' : '$unreadMsgs',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 7),
                        Text(
                          item.label,
                          style: GoogleFonts.raleway(
                            color: selected
                                ? VelvetNoir.primary
                                : VelvetNoir.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
