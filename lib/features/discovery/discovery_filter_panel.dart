import 'package:flutter/material.dart';
import '../../../core/design_system/design_constants.dart';

/// Bottom-sheet filter panel for Discovery page.
class DiscoveryFilterPanel extends StatefulWidget {
  final String currentCategory;
  final ValueChanged<String> onCategorySelected;

  const DiscoveryFilterPanel({
    super.key,
    required this.currentCategory,
    required this.onCategorySelected,
  });

  static Future<void> show(
    BuildContext context, {
    required String currentCategory,
    required ValueChanged<String> onCategorySelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DiscoveryFilterPanel(
        currentCategory: currentCategory,
        onCategorySelected: onCategorySelected,
      ),
    );
  }

  @override
  State<DiscoveryFilterPanel> createState() => _DiscoveryFilterPanelState();
}

class _DiscoveryFilterPanelState extends State<DiscoveryFilterPanel> {
  late String _selected;

  static const _categories = [
    'All', 'Music', 'Dating', 'Talk', 'Gaming', 'Study', 'News',
  ];
  static const _categoryIcons = {
    'All': Icons.apps_rounded,
    'Music': Icons.music_note,
    'Dating': Icons.favorite,
    'Talk': Icons.chat_bubble,
    'Gaming': Icons.sports_esports,
    'Study': Icons.school,
    'News': Icons.newspaper,
  };

  @override
  void initState() {
    super.initState();
    _selected = widget.currentCategory;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Filter by Category',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _categories.map((cat) {
              final selected = _selected == cat;
              return GestureDetector(
                onTap: () => setState(() => _selected = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? DesignColors.accent.withValues(alpha: 0.2)
                        : DesignColors.surfaceLight,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: selected
                          ? DesignColors.accent
                          : Colors.white12,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _categoryIcons[cat]!,
                        size: 16,
                        color: selected
                            ? DesignColors.accent
                            : Colors.white54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cat,
                        style: TextStyle(
                          color: selected
                              ? DesignColors.accent
                              : Colors.white70,
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                widget.onCategorySelected(_selected);
                Navigator.pop(context);
              },
              child: const Text(
                'Apply',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
