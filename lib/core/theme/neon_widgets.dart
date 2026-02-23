import 'package:flutter/material.dart';
import 'colors.dart';

/// Neon Glow Box - elevated card with glow effect
class NeonGlowBox extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double glowSize;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final bool animate;
  final Duration duration;

  const NeonGlowBox({
    super.key,
    required this.child,
    this.glowColor = ClubColors.primary,
    this.glowSize = 16,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 12,
    this.animate = false,
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  Widget build(BuildContext context) {
    if (animate) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.3, end: 0.6),
        duration: duration,
        curve: Curves.easeInOut,
        builder: (context, opacity, child) {
          return Container(
            margin: margin,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: opacity),
                  blurRadius: glowSize,
                  spreadRadius: glowSize / 2,
                ),
              ],
            ),
            child: child,
          );
        },
        child: _buildInnerBox(),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.4),
            blurRadius: glowSize,
            spreadRadius: glowSize / 2,
          ),
        ],
      ),
      child: _buildInnerBox(),
    );
  }

  Widget _buildInnerBox() {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: ClubColors.cardBackground,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: glowColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: child,
    );
  }
}

/// Neon Text - text with glow effect
class NeonText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color glowColor;
  final double glowSize;
  final TextAlign textAlign;

  const NeonText(
    this.text, {
    super.key,
    this.style,
    this.glowColor = ClubColors.primary,
    this.glowSize = 8,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = Theme.of(context).textTheme.titleLarge ?? const TextStyle();
    final mergedStyle = (style ?? defaultStyle).copyWith(
      shadows: [
        BoxShadow(
          color: glowColor.withValues(alpha: 0.5),
          blurRadius: glowSize,
        ),
      ],
    );

    return Text(
      text,
      style: mergedStyle,
      textAlign: textAlign,
    );
  }
}

/// Neon Button - button with neon styling and glow
class NeonButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String? label;
  final Widget? child;
  final Color color;
  final double width;
  final double height;
  final EdgeInsetsGeometry padding;
  final bool fullWidth;
  final bool isLoading;

  const NeonButton({
    super.key,
    this.onPressed,
    this.label,
    this.child,
    this.color = ClubColors.primary,
    this.width = double.infinity,
    this.height = 56,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.fullWidth = false,
    this.isLoading = false,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.isLoading ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.fullWidth ? double.infinity : widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                widget.color,
                widget.color.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(
                  alpha: _isHovering ? 0.6 : 0.4,
                ),
                blurRadius: _isHovering ? 16 : 12,
                spreadRadius: _isHovering ? 2 : 0,
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : widget.child ??
                    Text(
                      widget.label ?? 'Button',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}

/// Neon Divider - glowing divider
class NeonDivider extends StatelessWidget {
  final Color color;
  final double height;
  final double thickness;
  final bool glow;

  const NeonDivider({
    super.key,
    this.color = ClubColors.secondary,
    this.height = 1,
    this.thickness = 1.5,
    this.glow = true,
  });

  @override
  Widget build(BuildContext context) {
    if (glow) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: CustomPaint(
          size: Size(double.infinity, height + thickness),
          painter: _GlowDividerPainter(color: color, thickness: thickness),
        ),
      );
    }

    return Divider(
      color: color,
      height: height,
      thickness: thickness,
    );
  }
}

class _GlowDividerPainter extends CustomPainter {
  final Color color;
  final double thickness;

  _GlowDividerPainter({
    required this.color,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    // Glow layer
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = thickness + 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      glowPaint,
    );

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(_GlowDividerPainter oldDelegate) => false;
}

/// Animated Neon Border - border with animation
class AnimatedNeonBorder extends StatefulWidget {
  final Widget child;
  final Color color;
  final double borderWidth;
  final double borderRadius;
  final Duration duration;

  const AnimatedNeonBorder({
    super.key,
    required this.child,
    this.color = ClubColors.secondary,
    this.borderWidth = 2,
    this.borderRadius = 12,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<AnimatedNeonBorder> createState() => _AnimatedNeonBorderState();
}

class _AnimatedNeonBorderState extends State<AnimatedNeonBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(
                  alpha: 0.3 + (0.4 * (0.5 + 0.5 * Curves.easeInOut.transform(_controller.value))),
                ),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: widget.color.withValues(
                  alpha: 0.4 + (0.6 * (0.5 + 0.5 * Curves.easeInOut.transform(_controller.value))),
                ),
                width: widget.borderWidth,
              ),
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
