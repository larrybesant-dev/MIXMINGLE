import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/after_dark_provider.dart';
import '../theme/after_dark_theme.dart';
import '../../../features/messaging/providers/messaging_provider.dart';

const _edSurface    = EmberDark.surface;
const _edPrimary    = EmberDark.primary;
const _edPrimaryDim = EmberDark.primaryDim;
const _edOnVariant  = EmberDark.onSurfaceVariant;
const _edGhost      = Color(0x1A5A2A3A);

/// Persistent shell wrapping every After Dark screen.
class AfterDarkShell extends ConsumerWidget {
  final Widget child;
  const AfterDarkShell({required this.child, super.key});

  static int _indexForLocation(String location) {
    if (location.startsWith('/after-dark/lounges'))  return 1;
    if (location.startsWith('/after-dark/profile'))  return 2;
    return 0;
  }

  static const List<String> _roots = [
    '/after-dark',
    '/after-dark/lounges',
    '/after-dark/profile',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionActive = ref.watch(afterDarkSessionProvider);

    // Guard: if the session was cleared (app restart, manual lock, or direct URL
    // navigation) redirect immediately to the PIN unlock screen.
    if (!sessionActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/after-dark/unlock');
      });
      // Render a blank dark screen while the redirect fires.
      return const Scaffold(
        backgroundColor: EmberDark.surface,
        body: Center(
          child: CircularProgressIndicator(color: EmberDark.primary),
        ),
      );
    }

    final location      = GoRouterState.of(context).uri.toString();
    final selectedIndex = _indexForLocation(location);
    final unreadMsgs    = ref.watch(unreadMessageCountProvider);

    return Scaffold(
      backgroundColor: _edSurface,
      appBar: _AfterDarkTopBar(onExit: () {
        ref.read(afterDarkControllerProvider).lock();
        context.go('/');
      }),
      body: child,
      bottomNavigationBar: _AfterDarkBottomNav(
        selectedIndex: selectedIndex,
        unreadMsgs: unreadMsgs,
        onTap: (i) => context.go(_roots[i]),
      ),
    );
  }
}

// ── Top AppBar with branding + exit ──────────────────────────────────────────
class _AfterDarkTopBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onExit;
  const _AfterDarkTopBar({required this.onExit});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: EmberDark.surface,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [EmberDark.secondary, EmberDark.primary],
        ).createShader(bounds),
        child: Text(
          'After Dark',
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 24,
            letterSpacing: 0.4,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      actions: [
        Tooltip(
          message: 'Exit After Dark',
          child: TextButton.icon(
            onPressed: onExit,
            icon: const Icon(Icons.wb_sunny_outlined,
                size: 16, color: EmberDark.onSurfaceVariant),
            label: Text(
              'Exit',
              style: GoogleFonts.raleway(
                  fontSize: 12,
                  color: EmberDark.onSurfaceVariant,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Bottom navigation bar ─────────────────────────────────────────────────────
class _AfterDarkBottomNav extends StatelessWidget {
  const _AfterDarkBottomNav({
    required this.selectedIndex,
    required this.unreadMsgs,
    required this.onTap,
  });

  final int selectedIndex;
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
            color: Color(0xEE0C0508),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: _edGhost)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 68,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(0, Icons.whatshot_outlined, Icons.whatshot_rounded,
                      'Feed'),
                  _navItem(1, Icons.nightlife_outlined,
                      Icons.nightlife_rounded, 'Lounges'),
                  _createButton(context),
                  _navItem(2, Icons.person_outline_rounded,
                      Icons.person_rounded, 'Profile'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(
      int idx, IconData icon, IconData selectedIcon, String label) {
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
              width: 40,
              height: 32,
              decoration: isSelected
                  ? BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _edPrimary.withValues(alpha: 0.22),
                          _edPrimaryDim.withValues(alpha: 0.14),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    )
                  : null,
              child: Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? _edPrimary : _edOnVariant,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.raleway(
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? _edPrimary : _edOnVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _createButton(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => GoRouter.of(context).go('/after-dark/create-lounge'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_edPrimary, _edPrimaryDim],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _edPrimary.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.add_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(height: 2),
            Text(
              'Host',
              style: GoogleFonts.raleway(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _edPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
