import 'package:flutter/material.dart';
import '../theme/colors_v2.dart';

/// NeonBadge: status indicator with neon glow and optional pulse animation.
class NeonBadge extends StatefulWidget {
  const NeonBadge({
    super.key,
    required this.status,
    this.size = NeonBadgeSize.small,
  });

  final NeonStatus status;
  final NeonBadgeSize size;

  @override
  State<NeonBadge> createState() => _NeonBadgeState();
}

class _NeonBadgeState extends State<NeonBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _pulse = Tween<double>(begin: 0.9, end: 1.12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    if (_shouldAnimate(widget.status)) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant NeonBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_shouldAnimate(widget.status) && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!_shouldAnimate(widget.status) && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _shouldAnimate(NeonStatus status) => status == NeonStatus.speaking;

  @override
  Widget build(BuildContext context) {
    final style = _styleForStatus(widget.status);
    final double dimension = widget.size == NeonBadgeSize.small ? 12 : 16;
    final double halo = widget.size == NeonBadgeSize.small ? 6 : 8;

    final badge = Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: style.fill,
        boxShadow: [
          BoxShadow(
            color: style.glow.withValues(alpha: 0.55),
            blurRadius: halo,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: style.glow.withValues(alpha: 0.25),
            blurRadius: halo * 1.6,
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: ElectricColors.glassHighlight,
          width: widget.size == NeonBadgeSize.small ? 1 : 1.2,
        ),
      ),
    );

    if (!_shouldAnimate(widget.status)) return badge;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulse.value,
          child: child,
        );
      },
      child: badge,
    );
  }
}

enum NeonBadgeSize { small, medium }

enum NeonStatus { online, busy, offline, speaking }

class _BadgeStyle {
  const _BadgeStyle({required this.fill, required this.glow});
  final Color fill;
  final Color glow;
}

_BadgeStyle _styleForStatus(NeonStatus status) {
  switch (status) {
    case NeonStatus.online:
      return const _BadgeStyle(fill: ElectricColors.successMint, glow: ElectricColors.successMint);
    case NeonStatus.busy:
      return const _BadgeStyle(fill: ElectricColors.hotOrange, glow: ElectricColors.hotOrange);
    case NeonStatus.offline:
      return _BadgeStyle(
        fill: ElectricColors.onSurfaceMuted.withValues(alpha: 0.9),
        glow: ElectricColors.onSurfaceMuted.withValues(alpha: 0.5),
      );
    case NeonStatus.speaking:
      return const _BadgeStyle(fill: ElectricColors.electricCyan, glow: ElectricColors.electricCyan);
  }
}
