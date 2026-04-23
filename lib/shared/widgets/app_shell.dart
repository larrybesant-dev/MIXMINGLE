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
/// Home / Rooms / message / Groups / Profile.
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
    final unreadMsgs = ref.watch(unreadmessageCountProvider);
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
          : useDockedSidebar
              ? null
              : AppBar(
                  backgroundColor: VelvetNoir.surface,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  leading: Builder(
                    builder: (ctx) => IconButton(
                      icon: const Icon(
                        Icons.menu_rounded,
                        color: VelvetNoir.primary,
                      ),
                      tooltip: 'Open menu',
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  ),
                  title: Text(
                    'MIXVY',
                    style: GoogleFonts.playfairDisplay(
                      color: VelvetNoir.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      fontSize: 20,
                    ),
                  ),
                ),
      drawer: (isDesktopMessengerLayout || useDockedSidebar)
          ? null
          : const MixVyDrawer(),
      body: bodyContent,
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
      (label: 'message', icon: Icons.mail_rounded),
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
