import 'package:flutter/material.dart';
import '../theme/colors_v2.dart';
import '../theme/typography_v2.dart';
import '../theme/spacing.dart';

/// ElectricButton: primary CTA styled for the Electric Lounge design system.
/// Variants: primary, secondary, destructive, ghost; supports disabled.
class ElectricButton extends StatefulWidget {
  const ElectricButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = ElectricButtonVariant.primary,
    this.expand = false,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final ElectricButtonVariant variant;
  final bool expand;
  final bool isLoading;

  bool get isEnabled => onPressed != null && !isLoading;

  @override
  State<ElectricButton> createState() => _ElectricButtonState();
}

class _ElectricButtonState extends State<ElectricButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.isEnabled) _controller.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.isEnabled) _controller.reverse();
  }

  void _handleTapCancel() {
    if (widget.isEnabled) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final styles = _styleForVariant(widget.variant, context, enabled: widget.isEnabled);

    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: child,
        );
      },
      child: Opacity(
        opacity: widget.isEnabled ? 1.0 : 0.6,
        child: GestureDetector(
          onTap: widget.isEnabled ? () {
            debugPrint('ðŸ”˜ ElectricButton tapped: ${widget.label}');
            widget.onPressed?.call();
          } : null,
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: styles.gradient,
              color: styles.background,
              borderRadius: BorderRadius.circular(12),
              boxShadow: styles.shadows,
              border: styles.border,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.lg,
                vertical: Spacing.sm,
              ),
              child: Row(
                mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isLoading) ...[
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(styles.foreground),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                  ] else if (widget.icon != null) ...[
                    IconTheme(
                      data: IconThemeData(color: styles.foreground, size: 18),
                      child: widget.icon!,
                    ),
                    const SizedBox(width: Spacing.sm),
                  ],
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ElectricTypography.textTheme.titleMedium?.copyWith(
                        color: styles.foreground,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonStyles {
  const _ButtonStyles({
    required this.background,
    required this.gradient,
    required this.foreground,
    required this.shadows,
    required this.border,
  });

  final Color? background;
  final Gradient? gradient;
  final Color foreground;
  final List<BoxShadow> shadows;
  final BoxBorder? border;
}

enum ElectricButtonVariant { primary, secondary, destructive, ghost }

_ButtonStyles _styleForVariant(
  ElectricButtonVariant variant,
  BuildContext context, {
  required bool enabled,
}) {
  switch (variant) {
    case ElectricButtonVariant.primary:
      return _ButtonStyles(
        background: null,
        gradient: ElectricColors.neonPulse,
        foreground: ElectricColors.onSurfacePrimary,
        shadows: [
          BoxShadow(
            color: ElectricColors.neonMagenta.withValues(alpha: 0.45),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: ElectricColors.electricCyan.withValues(alpha: 0.35),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: ElectricColors.glassHighlight,
          width: 1.2,
        ),
      );

    case ElectricButtonVariant.secondary:
      return _ButtonStyles(
        background: ElectricColors.surfaceElevated,
        gradient: null,
        foreground: ElectricColors.onSurfacePrimary,
        shadows: [
          BoxShadow(
            color: ElectricColors.glassShadow,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: ElectricColors.glassBorder,
          width: 1,
        ),
      );

    case ElectricButtonVariant.destructive:
      return _ButtonStyles(
        background: ElectricColors.error,
        gradient: null,
        foreground: ElectricColors.onSurfacePrimary,
        shadows: [
          BoxShadow(
            color: ElectricColors.error.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: ElectricColors.error.withValues(alpha: 0.6),
          width: 1,
        ),
      );

    case ElectricButtonVariant.ghost:
      return _ButtonStyles(
        background: ElectricColors.surface.withValues(alpha: 0.0),
        gradient: null,
        foreground: ElectricColors.onSurfaceSecondary,
        shadows: [],
        border: Border.all(
          color: ElectricColors.glassBorder,
          width: 1,
        ),
      );
  }
}
