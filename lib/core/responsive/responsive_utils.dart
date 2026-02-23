import 'package:flutter/material.dart';

/// Responsive design utilities for different screen sizes and orientations
class Responsive {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  static bool isPortrait(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.portrait;

  /// Get responsive value based on screen size
  static T responsiveValue<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    return mobile;
  }

  /// Get responsive padding
  static EdgeInsets responsivePadding(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: const EdgeInsets.all(16),
      tablet: const EdgeInsets.all(24),
      desktop: const EdgeInsets.all(32),
    );
  }

  /// Get responsive margin
  static EdgeInsets responsiveMargin(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: const EdgeInsets.all(8),
      tablet: const EdgeInsets.all(16),
      desktop: const EdgeInsets.all(24),
    );
  }

  /// Get responsive font size
  static double responsiveFontSize(BuildContext context, double baseSize) {
    final scale = responsiveValue(
      context: context,
      mobile: 1.0,
      tablet: 1.1,
      desktop: 1.2,
    );
    return baseSize * scale;
  }

  /// Get responsive spacing
  static double responsiveSpacing(BuildContext context, double baseSpacing) {
    final scale = responsiveValue(
      context: context,
      mobile: 1.0,
      tablet: 1.2,
      desktop: 1.4,
    );
    return baseSpacing * scale;
  }

  /// Get responsive border radius
  static double responsiveBorderRadius(
      BuildContext context, double baseRadius) {
    final scale = responsiveValue(
      context: context,
      mobile: 1.0,
      tablet: 1.1,
      desktop: 1.2,
    );
    return baseRadius * scale;
  }

  /// Get responsive elevation
  static double responsiveElevation(
      BuildContext context, double baseElevation) {
    final scale = responsiveValue(
      context: context,
      mobile: 1.0,
      tablet: 1.2,
      desktop: 1.4,
    );
    return baseElevation * scale;
  }

  /// Get responsive icon size
  static double responsiveIconSize(BuildContext context, double baseSize) {
    final scale = responsiveValue(
      context: context,
      mobile: 1.0,
      tablet: 1.1,
      desktop: 1.2,
    );
    return baseSize * scale;
  }

  /// Get responsive max width for content containers
  static double responsiveMaxWidth(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: double.infinity,
      tablet: 600,
      desktop: 800,
    );
  }

  /// Get responsive grid columns
  static int responsiveGridColumns(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );
  }

  /// Get responsive aspect ratio for cards
  static double responsiveCardAspectRatio(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: 1.2,
      tablet: 1.5,
      desktop: 1.8,
    );
  }
}

/// Responsive layout widgets
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (Responsive.isDesktop(context) && desktop != null) {
          return desktop!;
        }
        if (Responsive.isTablet(context) && tablet != null) {
          return tablet!;
        }
        return mobile;
      },
    );
  }
}

/// Responsive container with automatic sizing
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? maxWidth;
  final AlignmentGeometry? alignment;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.maxWidth,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth =
        maxWidth ?? Responsive.responsiveMaxWidth(context);
    final effectivePadding = padding ?? Responsive.responsivePadding(context);
    final effectiveMargin = margin ?? Responsive.responsiveMargin(context);

    return Container(
      alignment: alignment,
      padding: effectivePadding,
      margin: effectiveMargin,
      constraints: BoxConstraints(
        maxWidth: effectiveMaxWidth,
      ),
      child: child,
    );
  }
}

/// Responsive grid view
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsetsGeometry? padding;

  const ResponsiveGridView({
    super.key,
    required this.children,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final columns = Responsive.responsiveGridColumns(context);
    final aspectRatio = Responsive.responsiveCardAspectRatio(context);

    return GridView.count(
      crossAxisCount: columns,
      childAspectRatio: childAspectRatio * aspectRatio,
      crossAxisSpacing: Responsive.responsiveSpacing(context, crossAxisSpacing),
      mainAxisSpacing: Responsive.responsiveSpacing(context, mainAxisSpacing),
      padding: padding ?? Responsive.responsivePadding(context),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }
}

/// Responsive text widget
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveStyle = style?.copyWith(
      fontSize: style?.fontSize != null
          ? Responsive.responsiveFontSize(context, style!.fontSize!)
          : null,
    );

    return Text(
      text,
      style: responsiveStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Responsive sized box
class ResponsiveSizedBox extends StatelessWidget {
  final double? width;
  final double? height;

  const ResponsiveSizedBox({
    super.key,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:
          width != null ? Responsive.responsiveSpacing(context, width!) : null,
      height: height != null
          ? Responsive.responsiveSpacing(context, height!)
          : null,
    );
  }
}

/// Responsive padding
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? Responsive.responsivePadding(context);
    return Padding(
      padding: effectivePadding,
      child: child,
    );
  }
}
