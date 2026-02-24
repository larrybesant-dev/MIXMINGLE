import 'package:flutter/material.dart';
import '../theme/colors_v2.dart';
import '../theme/spacing.dart';
import '../theme/typography_v2.dart';

enum SectionHeaderLayout { horizontal, vertical }

/// Section header with optional subtitle, accent underline, and trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.layout = SectionHeaderLayout.horizontal,
    this.showAccent = true,
    this.accentWidth = 82,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final SectionHeaderLayout layout;
  final bool showAccent;
  final double accentWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final textTheme = ElectricTypography.textTheme;

    final titleStyle = textTheme.headlineSmall?.copyWith(
      color: ElectricColors.onSurfacePrimary,
      letterSpacing: -0.2,
    );

    final subtitleStyle = textTheme.titleSmall?.copyWith(
      color: ElectricColors.onSurfaceSecondary,
      height: 1.35,
    );

    final accent = showAccent
        ? Container(
            margin: EdgeInsets.only(top: subtitle != null ? Spacing.xs : Spacing.xs),
            height: 3,
            width: accentWidth,
            decoration: const BoxDecoration(
              gradient: ElectricColors.neonPulse,
              boxShadow: [
                BoxShadow(
                  color: Color(0x5524E8FF),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: titleStyle),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.xs),
            child: Text(subtitle!, style: subtitleStyle),
          ),
        if (showAccent) accent,
      ],
    );

    if (layout == SectionHeaderLayout.vertical) {
      return Padding(
        padding: padding ?? const EdgeInsets.symmetric(vertical: Spacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titleBlock,
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(top: Spacing.sm),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: trailing,
                ),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Row(
        crossAxisAlignment: subtitle != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Expanded(child: titleBlock),
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.only(left: Spacing.md),
              child: trailing,
            ),
        ],
      ),
    );
  }
}
