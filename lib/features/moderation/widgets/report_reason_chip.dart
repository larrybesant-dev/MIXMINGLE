import 'package:flutter/material.dart';

class ReportReasonChip extends StatelessWidget {
  final String reason;
  final bool isSelected;
  final ValueChanged<bool> onSelected;
  final Color? selectedColor;
  final Color? unselectedColor;

  const ReportReasonChip({
    super.key,
    required this.reason,
    required this.isSelected,
    required this.onSelected,
    this.selectedColor,
    this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(reason),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: selectedColor ?? Theme.of(context).colorScheme.primaryContainer,
      backgroundColor: unselectedColor,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : Theme.of(context).colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}

/// A group of report reason chips for easy selection
class ReportReasonChipGroup extends StatelessWidget {
  final List<String> reasons;
  final String? selectedReason;
  final ValueChanged<String?> onReasonSelected;
  final double spacing;
  final double runSpacing;

  const ReportReasonChipGroup({
    super.key,
    required this.reasons,
    required this.selectedReason,
    required this.onReasonSelected,
    this.spacing = 8,
    this.runSpacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: reasons.map((reason) {
        return ReportReasonChip(
          reason: reason,
          isSelected: selectedReason == reason,
          onSelected: (selected) {
            onReasonSelected(selected ? reason : null);
          },
        );
      }).toList(),
    );
  }
}
