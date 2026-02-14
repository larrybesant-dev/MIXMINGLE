import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/design_system/design_constants.dart';

/// SafeAvatar widget prevents CORS issues on Flutter Web by avoiding NetworkImage on web platform.
///
/// On web, returns CircleAvatar with Icon(Icons.person).
/// On mobile, uses NetworkImage if photoUrl is provided.
class SafeAvatar extends StatelessWidget {
  final String? photoUrl;
  final double radius;
  final Color? backgroundColor;
  final Widget? child;
  final String? fallbackInitial;
  final BoxBorder? border;
  final List<BoxShadow>? shadows;

  const SafeAvatar({
    super.key,
    this.photoUrl,
    this.radius = 20,
    this.backgroundColor,
    this.child,
    this.fallbackInitial,
    this.border,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    // On web or if no photoUrl, use fallback icon/initials
    if (kIsWeb || photoUrl == null || photoUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? DesignColors.accent,
        child: child ??
            Text(
              fallbackInitial ?? '?',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: DesignColors.accent,
              ),
            ),
      );
    }

    // On mobile platforms, use NetworkImage
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: NetworkImage(photoUrl!),
      child: child,
    );
  }
}

/// Helper function to create a SafeAvatar with just an initial character
SafeAvatar buildAvatarWithInitial({
  required String? photoUrl,
  required String initial,
  double radius = 20,
  Color? backgroundColor,
}) {
  return SafeAvatar(
    photoUrl: photoUrl,
    radius: radius,
    backgroundColor: backgroundColor,
    fallbackInitial: initial,
  );
}

/// Helper function to create a SafeAvatar with an icon
SafeAvatar buildAvatarWithIcon({
  required String? photoUrl,
  required IconData icon,
  double radius = 20,
  Color? backgroundColor,
  Color? iconColor,
}) {
  return SafeAvatar(
    photoUrl: photoUrl,
    radius: radius,
    backgroundColor: backgroundColor,
    child: Icon(icon, color: iconColor ?? DesignColors.accent),
  );
}



