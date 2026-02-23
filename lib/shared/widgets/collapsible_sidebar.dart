
/// Collapsible Sidebar Widget - Base widget with collapse/expand animation and hover effects
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_system/design_constants.dart';
import '../constants/ui_constants.dart';

/// Reusable collapsible sidebar widget with smooth animations
class CollapsibleSidebar extends ConsumerStatefulWidget {
  final Widget child;
  final String title;
  final IconData icon;
  final double width;
  final double collapsedWidth;
  final bool isInitiallyCollapsed;
  final VoidCallback? onCollapsedChanged;

  const CollapsibleSidebar({
    required this.child,
    required this.title,
    required this.icon,
    this.width = WidgetSizes.sidebarWidth,
    this.collapsedWidth = 70,
    this.isInitiallyCollapsed = false,
    this.onCollapsedChanged,
    super.key,
  });

  @override
  ConsumerState<CollapsibleSidebar> createState() =>
      _CollapsibleSidebarState();
}

class _CollapsibleSidebarState extends ConsumerState<CollapsibleSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;
  late Animation<double> _opacityAnimation;
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.isInitiallyCollapsed;

    _animationController = AnimationController(
      duration: AnimationDurations.normal,
      vsync: this,
    );

    if (_isCollapsed) {
      _animationController.forward();
    }

    _widthAnimation = Tween<double>(
      begin: widget.width,
      end: widget.collapsedWidth,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: AppCurves.easeInOut),
    );

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: AppCurves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleCollapsed() {
    setState(() {
      _isCollapsed = !_isCollapsed;
    });

    if (_isCollapsed) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }

    widget.onCollapsedChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        return Container(
          width: _widthAnimation.value,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              right: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
            boxShadow: AppShadows.elevation2,
          ),
          child: Stack(
            children: [
              // Main content
              Opacity(
                opacity: _opacityAnimation.value,
                child: SingleChildScrollView(
                  child: widget.child,
                ),
              ),
              // Collapse button
              Positioned(
                top: Spacing.md,
                right: Spacing.md,
                child: _CollapseButton(
                  isCollapsed: _isCollapsed,
                  onPressed: _toggleCollapsed,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Collapse/Expand button with animation
class _CollapseButton extends StatelessWidget {
  final bool isCollapsed;
  final VoidCallback onPressed;

  const _CollapseButton({
    required this.isCollapsed,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      turns: isCollapsed ? 0.5 : 0,
      duration: AnimationDurations.normal,
      child: Material(
        color: DesignColors.accent,
        child: Tooltip(
          message: isCollapsed ? 'Expand' : 'Collapse',
          child: IconButton(
            icon: const Icon(Icons.chevron_left),
            iconSize: WidgetSizes.mediumIconSize,
            onPressed: onPressed,
            tooltip: isCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
          ),
        ),
      ),
    );
  }
}

/// Sidebar item with hover and selection effects
class SidebarItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isOnline;
  final int? badgeCount;
  final String? trailing;
  final Color? itemColor;

  const SidebarItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isSelected = false,
    this.isOnline = false,
    this.badgeCount,
    this.trailing,
    this.itemColor,
    super.key,
  });

  @override
  State<SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<SidebarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: AnimationDurations.fast,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(
      CurvedAnimation(parent: _hoverController, curve: AppCurves.easeOut),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 0.08,
    ).animate(
      CurvedAnimation(parent: _hoverController, curve: AppCurves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: Padding(
        padding: const EdgeInsets.only(
          left: Spacing.sm,
          right: Spacing.sm,
          bottom: Spacing.sm,
        ),
        child: GestureDetector(
          onTap: widget.onTap,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Stack(
              children: [
                // Background with opacity animation
                if (widget.isSelected)
                  AnimatedBuilder(
                    animation: _opacityAnimation,
                    builder: (context, _) {
                      return Container(
                        decoration: BoxDecoration(
                          color: widget.itemColor?.withValues(alpha: 0.12) ??
                              DesignColors.accent.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(BorderRadii.md),
                          border: Border.all(
                            color: widget.itemColor?.withValues(alpha: 0.3) ??
                                DesignColors.accent.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                      );
                    },
                  ),
                // Hover background
                if (_isHovered && !widget.isSelected)
                  Container(
                    decoration: BoxDecoration(
                      color: DesignColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(BorderRadii.md),
                    ),
                  ),
                // Content
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.md,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(BorderRadii.md),
                  ),
                  child: Row(
                    children: [
                      // Icon with online indicator
                      Stack(
                        children: [
                          Icon(
                            widget.icon,
                            size: WidgetSizes.mediumIconSize,
                            color: widget.itemColor ?? DesignColors.accent,
                          ),
                          if (widget.isOnline)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: DesignColors.accent,
                                  borderRadius:
                                      BorderRadius.circular(BorderRadii.circular),
                                  border: Border.all(
                                    color: DesignColors.accent,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: Spacing.md),
                      // Label
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.label,
                              style: AppTextStyles.body1.copyWith(
                                fontWeight: widget.isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.trailing != null)
                              Text(
                                widget.trailing!,
                                style: AppTextStyles.caption.copyWith(
                                  color: DesignColors.accent,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      // Badge
                      if (widget.badgeCount != null &&
                          widget.badgeCount! > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.sm,
                            vertical: Spacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: DesignColors.accent,
                            borderRadius:
                                BorderRadius.circular(BorderRadii.lg),
                          ),
                          child: Text(
                            widget.badgeCount.toString(),
                            style: const TextStyle(
                              color: DesignColors.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
