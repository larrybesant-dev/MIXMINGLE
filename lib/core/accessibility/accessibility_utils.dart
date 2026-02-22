import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Accessibility utilities for enhanced user experience
class AccessibilityUtils {
  /// Create semantic label for interactive elements
  static String createSemanticLabel({
    required String primaryLabel,
    String? secondaryLabel,
    String? hint,
    bool isSelected = false,
    bool isEnabled = true,
  }) {
    final parts = <String>[primaryLabel];

    if (secondaryLabel != null && secondaryLabel.isNotEmpty) {
      parts.add(secondaryLabel);
    }

    if (isSelected) {
      parts.add('selected');
    }

    if (!isEnabled) {
      parts.add('disabled');
    }

    if (hint != null && hint.isNotEmpty) {
      parts.add(hint);
    }

    return parts.join(', ');
  }

  /// Enhanced button with accessibility features
  static Widget accessibleButton({
    required Widget child,
    required VoidCallback onPressed,
    String? semanticLabel,
    String? tooltip,
    FocusNode? focusNode,
    bool autofocus = false,
    Key? key,
  }) {
    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: true,
      child: Tooltip(
        message: tooltip ?? '',
        child: ElevatedButton(
          key: key,
          onPressed: onPressed,
          focusNode: focusNode,
          autofocus: autofocus,
          child: child,
        ),
      ),
    );
  }

  /// Enhanced text field with accessibility features
  static Widget accessibleTextField({
    required TextEditingController controller,
    String? label,
    String? hint,
    String? errorText,
    TextInputType? keyboardType,
    bool obscureText = false,
    FocusNode? focusNode,
    ValueChanged<String>? onChanged,
    VoidCallback? onEditingComplete,
    Key? key,
  }) {
    return Semantics(
      label: createSemanticLabel(
        primaryLabel: label ?? '',
        hint: hint,
        secondaryLabel: errorText,
      ),
      textField: true,
      child: TextField(
        key: key,
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: errorText,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        focusNode: focusNode,
        onChanged: onChanged,
        onEditingComplete: onEditingComplete,
      ),
    );
  }

  /// Enhanced card with accessibility features
  static Widget accessibleCard({
    required Widget child,
    String? semanticLabel,
    VoidCallback? onTap,
    bool isSelected = false,
    Key? key,
  }) {
    return Semantics(
      label: semanticLabel,
      selected: isSelected,
      button: onTap != null,
      child: Card(
        key: key,
        child: InkWell(
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }

  /// Enhanced list tile with accessibility features
  static Widget accessibleListTile({
    required Widget title,
    Widget? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    bool isSelected = false,
    String? semanticLabel,
    Key? key,
  }) {
    return Semantics(
      label: semanticLabel ?? 'List item',
      selected: isSelected,
      button: onTap != null,
      child: ListTile(
        key: key,
        title: title,
        subtitle: subtitle,
        leading: leading,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  /// Enhanced switch with accessibility features
  static Widget accessibleSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
    String? semanticLabel,
    String? onLabel,
    String? offLabel,
    Key? key,
  }) {
    return Semantics(
      label: semanticLabel ?? 'Toggle switch',
      toggled: value,
      child: Switch(
        key: key,
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  /// Enhanced checkbox with accessibility features
  static Widget accessibleCheckbox({
    required bool? value,
    required ValueChanged<bool?> onChanged,
    String? semanticLabel,
    Key? key,
  }) {
    return Semantics(
      label: semanticLabel ?? 'Checkbox',
      checked: value == true,
      child: Checkbox(
        key: key,
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  /// Enhanced slider with accessibility features
  static Widget accessibleSlider({
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    String? semanticLabel,
    int? divisions,
    Key? key,
  }) {
    return Semantics(
      label: semanticLabel ?? 'Slider',
      value: '${value.round()}',
      increasedValue: '${(value + 1).clamp(min, max).round()}',
      decreasedValue: '${(value - 1).clamp(min, max).round()}',
      child: Slider(
        key: key,
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );
  }

  /// Screen reader announcement
  static void announce(BuildContext context, String message) {
    SemanticsService.sendAnnouncement(
        View.of(context), message, TextDirection.ltr);
  }

  /// Focus management utilities
  static void requestFocus(FocusNode focusNode) {
    focusNode.requestFocus();
  }

  static void unfocus(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  /// Enhanced focus traversal
  static Widget focusTraversalGroup({
    required Widget child,
    FocusTraversalPolicy? policy,
  }) {
    return FocusTraversalGroup(
      policy: policy ?? ReadingOrderTraversalPolicy(),
      child: child,
    );
  }

  /// Accessible dialog
  static Future<T?> showAccessibleDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    String? semanticLabel,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => Semantics(
        label: semanticLabel ?? 'Dialog',
        child: builder(context),
      ),
    );
  }

  /// Accessible bottom sheet
  static Future<T?> showAccessibleBottomSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    String? semanticLabel,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      builder: (context) => Semantics(
        label: semanticLabel ?? 'Bottom sheet',
        child: builder(context),
      ),
    );
  }

  /// High contrast mode detection
  static bool isHighContrastEnabled(BuildContext context) {
    final platformBrightness = MediaQuery.of(context).platformBrightness;
    return platformBrightness == Brightness.dark;
  }

  /// Large text scale detection
  static bool hasLargeTextScale(BuildContext context) {
    final textScale = MediaQuery.of(context).textScaler.scale(1.0);
    return textScale > 1.2;
  }

  /// Reduced motion preference detection
  static bool prefersReducedMotion(BuildContext context) {
    // Note: This is a simplified implementation
    // In a real app, you'd check system preferences
    return false;
  }

  /// Accessible navigation
  static void navigateWithAnnouncement({
    required BuildContext context,
    required String routeName,
    String? announcement,
  }) {
    Navigator.of(context).pushNamed(routeName);
    if (announcement != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        // ignore: use_build_context_synchronously
        announce(context, announcement);
      });
    }
  }

  /// Accessible app bar
  static PreferredSizeWidget accessibleAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
    Key? key,
  }) {
    return AppBar(
      key: key,
      title: Semantics(
        header: true,
        child: Text(title),
      ),
      actions: actions
          ?.map((action) => Semantics(
                button: true,
                child: action,
              ))
          .toList(),
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
    );
  }
}

/// Accessibility constants
class AccessibilityConstants {
  static const double minimumTouchTarget = 44.0;
  static const double minimumTextSize = 14.0;
  static const double recommendedTextSize = 16.0;
  static const double largeTextSize = 18.0;

  static const Duration announcementDelay = Duration(milliseconds: 500);
  static const Duration focusDelay = Duration(milliseconds: 100);
}

/// Extension methods for accessibility
extension AccessibilityExtensions on Widget {
  /// Add semantic label to any widget
  Widget withSemantics({
    String? label,
    String? hint,
    bool? button,
    bool? selected,
    bool? enabled,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: button,
      selected: selected,
      enabled: enabled,
      child: this,
    );
  }

  /// Add tooltip to any widget
  Widget withTooltip(String message) {
    return Tooltip(
      message: message,
      child: this,
    );
  }

  /// Make widget focusable
  Widget focusable({
    FocusNode? focusNode,
    bool autofocus = false,
    ValueChanged<bool>? onFocusChange,
  }) {
    return Focus(
      focusNode: focusNode,
      autofocus: autofocus,
      onFocusChange: onFocusChange,
      child: this,
    );
  }

  /// Add minimum touch target size
  Widget ensureMinimumTouchTarget({
    double minSize = AccessibilityConstants.minimumTouchTarget,
  }) {
    return SizedBox(
      width: minSize,
      height: minSize,
      child: this,
    );
  }
}
