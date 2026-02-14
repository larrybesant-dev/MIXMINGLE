import 'package:flutter/material.dart';
import '../theme/colors_v2.dart';
import '../theme/typography_v2.dart';
import '../theme/spacing.dart';

/// Standardized input field for the Electric Lounge design system.
/// Provides consistent padding, neon-accent focus, and error styling.
class StandardInputField extends StatelessWidget {
  const StandardInputField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.validator,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.readOnly = false,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final int? minLines;
  final bool enabled;
  final bool readOnly;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = ElectricTypography.textTheme;

    final inputStyle = baseTextTheme.bodyLarge?.copyWith(
      color: ElectricColors.onSurfacePrimary,
      height: 1.4,
    );

    final labelStyle = baseTextTheme.labelMedium?.copyWith(
      color: ElectricColors.onSurfaceSecondary,
      letterSpacing: 0.1,
    );

    final hintStyle = baseTextTheme.bodyMedium?.copyWith(
      color: ElectricColors.onSurfaceMuted,
      height: 1.4,
    );

    final errorStyle = baseTextTheme.labelSmall?.copyWith(
      color: ElectricColors.error,
      height: 1.2,
      fontWeight: FontWeight.w600,
    );

    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: ElectricColors.glassBorder, width: 1),
    );

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      maxLines: maxLines,
      minLines: minLines,
      enabled: enabled,
      readOnly: readOnly,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: inputStyle,
      cursorColor: ElectricColors.electricCyan,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: labelStyle,
        hintStyle: hintStyle,
        errorText: errorText,
        errorStyle: errorStyle,
        filled: true,
        fillColor: ElectricColors.surfaceElevated.withValues(alpha: 0.65),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: baseBorder,
        enabledBorder: baseBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ElectricColors.electricCyan, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ElectricColors.error, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ElectricColors.error, width: 1.6),
        ),
      ),
    );
  }
}
