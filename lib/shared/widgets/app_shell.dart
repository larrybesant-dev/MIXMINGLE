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
/// bottom nav bar (Home / Live / Explore / Circle / Profile).
class AppShell extends ConsumerWidget {
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
    '/explore',
    '/social',
    '/profile',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDesktopMessengerLayout =
        context.isExpandedLayout && useDesktopMessengerLayout;
    final unreadMsgs = ref.watch(unreadMessageCountProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: isDesktopMessengerLayout
          ? PreferredSize(
              preferredSize: const Size.fromHeight(72),
              child: _DesktopTopNav(
                selectedIndex: selectedIndex,
                unreadMsgs: unreadMsgs,
                onTap: (i) => context.go(_roots[i]),
              ),
            )
          : null,
      drawer: isDesktopMessengerLayout ? null : const MixVyDrawer(),
      body: child,
      bottomNavigationBar: isDesktopMessengerLayout
          ? null
          : Builder(
              builder: (context) => _VelvetBottomNav(
                selectedIndex: selectedIndex,
                unreadMsgs: unreadMsgs,
                compact: context.isCompactLayout,
                onTap: (i) => context.go(_roots[i]),
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
  });

  final int selectedIndex;
  final int unreadMsgs;
  final bool compact;
  final void Function(int) onTap;

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
                  _navItem(context, 0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                  _navItem(context, 1, Icons.graphic_eq_rounded, Icons.graphic_eq_rounded, 'Live'),
                  _navItem(context, 2, Icons.explore_outlined, Icons.explore_rounded, 'Explore'),
                  _navItem(context, 3, Icons.groups_2_outlined, Icons.groups_2_rounded, 'Circle'),
                  _navItem(context, 4, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
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
      (label: 'Live', icon: Icons.graphic_eq_rounded),
      (label: 'Explore', icon: Icons.explore_rounded),
      (label: 'Circle', icon: Icons.groups_2_rounded),
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
                            if (index == 0 && unreadMsgs > 0)
                              Positioned(
                                right: -8,
                                top: -8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1),
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
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w600,
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
