import 'package:flutter/material.dart';
import '../../core/theme/neon_colors.dart';
import 'neon_components.dart';

/// ============================================================================
/// NEON APP BAR - Consistent Brand Header
/// Dark theme header with neon accents and logo branding
/// ============================================================================

class NeonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final bool centerTitle;
  final double elevation;
  final Color backgroundColor;
  final Color textColor;
  final bool showLogo;

  const NeonAppBar({
    super.key,
    required this.title,
    this.actions,
    this.onBackPressed,
    this.centerTitle = true,
    this.elevation = 0,
    this.backgroundColor = NeonColors.darkBg2,
    this.textColor = Colors.white,
    this.showLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
      leading: Navigator.of(context).canPop()
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              color: NeonColors.neonBlue,
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : null,
      title: NeonText(
        title,
        fontSize: 20,
        fontWeight: FontWeight.w900,
        textColor: textColor,
        glowColor: NeonColors.neonOrange,
        glowRadius: 8,
      ),
      actions: actions,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              backgroundColor,
              backgroundColor.withValues(alpha: 0.9),
            ],
          ),
          border: Border(
            bottom: BorderSide(
              color: NeonColors.neonOrange.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}

/// Neon Bottom Navigation Bar
class NeonBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final List<NeonNavItem> items;

  const NeonBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NeonColors.darkBg2,
        border: Border(
          top: BorderSide(
            color: NeonColors.neonBlue.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: NeonColors.neonBlue.withValues(alpha: 0.2),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              items.length,
              (index) => _buildNavItem(
                context,
                items[index],
                index,
                selectedIndex == index,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    NeonNavItem item,
    int index,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () => onItemSelected(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? item.activeColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              color: isSelected ? item.activeColor : NeonColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected ? item.activeColor : NeonColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Navigation item model
class NeonNavItem {
  final IconData icon;
  final String label;
  final Color activeColor;

  NeonNavItem({
    required this.icon,
    required this.label,
    this.activeColor = NeonColors.neonBlue,
  });
}
