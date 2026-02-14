// ============================================================================
// ELECTRIC LOUNGE DESIGN SYSTEM - Complete Export
// Official branding, colors, typography, components, and patterns
// ============================================================================

// Export all core design system components and configurations
export '../core/theme/neon_colors.dart';
export '../core/theme/neon_theme.dart';
export '../shared/widgets/branded_header.dart';
export '../shared/widgets/neon_components.dart'; // Includes NeonButton
export '../shared/widgets/neon_app_bar.dart';
export '../shared/widgets/glow_text.dart';
export '../shared/widgets/mix_mingle_logo.dart';

/// Design System Reference Guide
///
/// BRAND IDENTITY:
/// - Primary: Neon Orange (#FF7A3C) - "MIX" energy, passion, CTAs
/// - Secondary: Neon Blue (#00D9FF) - "MINGLE" connection, trust, accents
/// - Accent: Neon Purple (#BD00FF) - Premium, special features
/// - Background: Dark Navy (#0A0E27) - Deep nightclub atmosphere
/// - Card BG: Dark Blue (#15192D) - Surface elevation
///
/// COLOR PALETTE USAGE:
/// - Headlines: neonOrange or neonBlue with glow
/// - Body Text: textPrimary (white) on dark backgrounds
/// - Secondary Text: textSecondary (light gray-blue)
/// - CTAs: neonOrange buttons with glow shadows
/// - Borders: divider or subtle neon gradients
/// - States: errorRed, successGreen, warningYellow
///
/// COMPONENTS:
/// - BrandedHeader: Top-level branding with logo and animations
/// - NeonGlowCard: Elevated cards with neon border glow
/// - NeonButton: Primary CTAs with glow effects
/// - NeonText: Text with optional glow shadow effects
/// - NeonInputField: Forms with focus glow
/// - NeonDivider: Gradient dividers
/// - MixMingleLogo: Official text logo "MIX ♪ MINGLE"
///
/// ANIMATIONS:
/// - Logo Scale & Fade: Splash/intro screens
/// - Glow Pulse: Breathing glow on interactive elements
/// - Border Glow: Hover and focus states
/// - Elevation Animations: Card interactions
/// - Color Transitions: Smooth state changes
///
/// SPACING SYSTEM:
/// - xs: 8px
/// - sm: 12px
/// - md: 16px
/// - lg: 24px
/// - xl: 32px
///
/// TYPOGRAPHY:
/// - Display: 32px bold, neonOrange with glow
/// - Headline: 22px bold, neonBlue, neonOrange headings
/// - Title: 18-20px w600, textPrimary
/// - Body: 14-16px w400, textSecondary/Primary
/// - Label: 12-14px w500-600, with optional glow
///
/// IMPLEMENTATION GUIDELINES:
/// 1. Always use NeonColors.* for all color references
/// 2. Use NeonTheme.darkTheme in app.dart (already configured)
/// 3. Prefer BrandedHeader for top navigation
/// 4. Use NeonGlowCard for elevated surfaces
/// 5. Use NeonButton for all primary CTAs
/// 6. Apply glow effects to interactive elements
/// 7. Maintain consistent 2px-4px border widths
/// 8. Use 12-24px border radius for modern feel
///
/// PERFORMANCE NOTES:
/// - Glow effects use boxShadow (GPU accelerated)
/// - Animations use 200-2000ms durations (smooth but not sluggish)
/// - Logo animation scales from 0.5-1.0 with elasticOut curve
/// - Pulse effects use easeInOut curves for smoothness
/// - Use AnimatedBuilder for complex glow animations
/// - Profile animations on real devices before deployment
///
/// ACCESSIBILITY:
/// - All text meets WCAG AA contrast ratios
/// - Focus indicators use neonBlue glow
/// - Error states use errorRed (#FF1744)
/// - Interactive elements have minimum 48x48px tap targets
/// - Animations have 2s+ duration for clarity
///
/// RESPONSIVE DESIGN:
/// - Mobile: Full width with 16px horizontal padding
/// - Tablet: Constrained width, centered layout
/// - Desktop/Web: Max width 1200px, sidebar layouts
/// - Logo sizes scale with viewport width
/// - Typography uses responsive font sizes
///
/// DARK MODE:
/// - Currently dark-only (nightclub aesthetic)
/// - Light mode support ready in underlying theme system
/// - All colors maintain sufficient contrast in dark mode
/// - No adjust needed for future light theme support
///
/// FUTURE EXTENSIONS:
/// - Add rive animations for interactive elements
/// - Implement haptic feedback on button presses
/// - Create theme toggle provider (Riverpod)
/// - Add parallax effects to hero sections
/// - Implement micro-interactions library
