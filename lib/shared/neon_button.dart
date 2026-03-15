import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

class NeonButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? glowColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final bool isLoading;

  const NeonButton({
    super.key,
    this.onPressed,
    required this.child,
    this.backgroundColor,
    this.glowColor,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.isLoading = false,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? ClubColors.glowingRed;
    final glowColor = widget.glowColor ?? bgColor;

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                bgColor.withValues(alpha: 0.8),
                bgColor,
                bgColor.withValues(alpha: 0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(
                    alpha: 0.3 + (_glowAnimation.value * 0.4)),
                blurRadius: 15 + (_glowAnimation.value * 10),
                spreadRadius: 2 + (_glowAnimation.value * 3),
              ),
              BoxShadow(
                color: glowColor.withValues(
                    alpha: 0.2 + (_glowAnimation.value * 0.3)),
                blurRadius: 30 + (_glowAnimation.value * 15),
                spreadRadius: 1,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: widget.padding ??
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
              ),
            ),
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : widget.child,
          ),
        );
      },
    );
  }
}
