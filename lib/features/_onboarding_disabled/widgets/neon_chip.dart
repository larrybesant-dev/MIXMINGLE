library;
import 'dart:js_util' as js_util;
import 'package:mixmingle/helpers/helpers.dart';
/// Onboarding Neon Chip
///
/// A selectable chip with neon border and gold glow when selected.
/// Used for mood selection and interest selection.

import 'package:flutter/material.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../core/theme/neon_colors.dart';

class NeonChip extends StatefulWidget {
  final String label;
  final String? emoji;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? selectedColor;
  final bool useGoldGlow;
  final double? width;
  final double height;

  const NeonChip({
    super.key,
    required this.label,
    this.emoji,
    this.isSelected = false,
    this.onTap,
    this.selectedColor,
    this.useGoldGlow = true,
    this.width,
    this.height = 48,
  });

  @override
  State<NeonChip> createState() => _NeonChipState();
}

class _NeonChipState extends State<NeonChip> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _glowAnimation = Tween<double>(
      begin: 0.4,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    if (widget.isSelected) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(NeonChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !_glowController.isAnimating) {
      _glowController.repeat(reverse: true);
    } else if (!widget.isSelected && _glowController.isAnimating) {
      _glowController.stop();
      _glowController.reset();
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = widget.selectedColor ??
        (widget.useGoldGlow ? DesignColors.gold : NeonColors.neonOrange);
    final unselectedColor = NeonColors.neonBlue.withValues(alpha: 0.4);

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final glowIntensity = widget.isSelected ? _glowAnimation.value : 0.0;

        return GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.width,
            height: widget.height,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: widget.isSelected
                  ? selectedColor.withValues(alpha: 0.2)
                  : DesignColors.surfaceAlt.withValues(alpha: 0.6),
              border: Border.all(
                color: widget.isSelected ? selectedColor : unselectedColor,
                width: widget.isSelected ? 2 : 1.5,
              ),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: selectedColor.withValues(alpha: glowIntensity * 0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: selectedColor.withValues(alpha: glowIntensity * 0.3),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.emoji != null) ...[
                  Text(
                    widget.emoji!,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.isSelected ? selectedColor : DesignColors.white,
                    fontSize: 14,
                    fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                if (widget.isSelected) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.check_circle,
                    color: selectedColor,
                    size: 18,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Grid wrapper for interest chips
class NeonChipGrid extends StatelessWidget {
  final List<NeonChipData> chips;
  final List<String> selectedIds;
  final Function(String) onToggle;
  final int crossAxisCount;
  final double spacing;

  const NeonChipGrid({
    super.key,
    required this.chips,
    required this.selectedIds,
    required this.onToggle,
    this.crossAxisCount = 2,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 2.5,
      ),
      itemCount: chips.length,
      itemBuilder: (context, index) {
        final chip = chips[index];
        return NeonChip(
          label: chip.label,
          emoji: chip.emoji,
          isSelected: selectedIds.contains(chip.id),
          onTap: () => onToggle(chip.id),
        );
      },
    );
  }
}

/// Data model for chip items
class NeonChipData {
  final String id;
  final String label;
  final String? emoji;

  const NeonChipData({
    required this.id,
    required this.label,
    this.emoji,
  });
}
