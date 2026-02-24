// lib/features/room/widgets/room_hopping_view.dart
//
// RoomHoppingView – wraps multiple rooms in a PageView so users can
// swipe left/right to hop between rooms with a neon slide+fade transition.
//
// Usage:
//   RoomHoppingView(
//     rooms: nearbyRooms,
//     initialIndex: currentIndex,
//     roomBuilder: (ctx, room) => RoomPage(room: room),
//   )
// ─────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../../../core/motion/app_motion.dart';
import '../../../../core/theme/vibe_theme.dart';
import '../../../../shared/models/room.dart';

class RoomHoppingView extends StatefulWidget {
  /// Ordered list of rooms available to hop through.
  final List<Room> rooms;

  /// Index of the currently active room.
  final int initialIndex;

  /// Builder for the full room content.
  final Widget Function(BuildContext, Room) roomBuilder;

  /// Called when the user settles on a new room.
  final void Function(Room room, int index)? onRoomChanged;

  const RoomHoppingView({
    super.key,
    required this.rooms,
    required this.roomBuilder,
    this.initialIndex = 0,
    this.onRoomChanged,
  });

  @override
  State<RoomHoppingView> createState() => _RoomHoppingViewState();
}

class _RoomHoppingViewState extends State<RoomHoppingView> {
  late PageController _pageCtrl;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.rooms.length - 1);
    _pageCtrl = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    widget.onRoomChanged?.call(widget.rooms[index], index);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rooms.isEmpty) return const SizedBox.shrink();

    return Stack(
      children: [
        // ── Rooms page view ────────────────────────────────────
        PageView.builder(
          controller: _pageCtrl,
          itemCount: widget.rooms.length,
          onPageChanged: _onPageChanged,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (ctx, i) {
            // Only build ±1 pages from current for memory efficiency.
            if ((i - _currentIndex).abs() > 1) {
              return const SizedBox.shrink();
            }
            return _RoomHopPage(
              room: widget.rooms[i],
              isActive: i == _currentIndex,
              builder: widget.roomBuilder,
            );
          },
        ),

        // ── Hop indicators (dots) ──────────────────────────────
        if (widget.rooms.length > 1)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: _HopDots(
              count: widget.rooms.length,
              activeIndex: _currentIndex,
              rooms: widget.rooms,
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Single room page with entrance animation
// ─────────────────────────────────────────────────────────────────
class _RoomHopPage extends StatelessWidget {
  final Room room;
  final bool isActive;
  final Widget Function(BuildContext, Room) builder;

  const _RoomHopPage({
    required this.room,
    required this.isActive,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: AppMotion.normal,
      opacity: isActive ? 1.0 : 0.6,
      child: builder(context, room),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Navigation dots colored by vibe theme
// ─────────────────────────────────────────────────────────────────
class _HopDots extends StatelessWidget {
  final int count;
  final int activeIndex;
  final List<Room> rooms;

  const _HopDots({
    required this.count,
    required this.activeIndex,
    required this.rooms,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final vt = VibeTheme.of(vibeTag: rooms[i].vibeTag, energy: 50);
        final isActive = i == activeIndex;
        return AnimatedContainer(
          duration: AppMotion.fast,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? vt.primary : vt.primary.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(3),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: vt.glowColor.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Standalone named PageRoute for imperative navigation
// ─────────────────────────────────────────────────────────────────
class RoomHopPageRoute<T> extends PageRouteBuilder<T> {
  RoomHopPageRoute({
    required WidgetBuilder builder,
    bool slideFromRight = true,
  }) : super(
          transitionDuration: AppMotion.normal,
          reverseTransitionDuration: AppMotion.normal,
          pageBuilder: (ctx, _, __) => builder(ctx),
          transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
            final dx = slideFromRight ? 1.0 : -1.0;
            final slide = Tween<Offset>(
              begin: Offset(dx, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: AppMotion.transition,
            ));
            final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeIn,
              ),
            );
            return SlideTransition(
              position: slide,
              child: FadeTransition(opacity: fade, child: child),
            );
          },
        );
}
