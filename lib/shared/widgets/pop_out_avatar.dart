// lib/shared/widgets/pop_out_avatar.dart
//
// Wraps any avatar (or any child widget) to make it open the user's profile
// in a Yahoo Messenger-style pop-out window on web, or navigate in-app
// on mobile / desktop.
//
// Usage:
//   PopOutAvatar(
//     uid: user.uid,
//     child: CircleAvatar(backgroundImage: NetworkImage(user.photoUrl)),
//   )
// ─────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/web/web_window_service.dart';

class PopOutAvatar extends StatelessWidget {
  /// The Firestore UID of the user whose profile should open.
  final String uid;

  /// The widget to wrap (typically a CircleAvatar).
  final Widget child;

  /// Optional tooltip.
  final String? tooltip;

  const PopOutAvatar({
    super.key,
    required this.uid,
    required this.child,
    this.tooltip,
  });

  void _handleTap(BuildContext context) {
    if (uid.isEmpty) return;

    if (kIsWeb) {
      // Web: open profile in a floating pop-out window
      WebWindowService.openProfile(uid: uid);
    } else {
      // Mobile / desktop: navigate in-app
      Navigator.pushNamed(
        context,
        '/profile/user',
        arguments: uid,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget w = GestureDetector(
      onTap: () => _handleTap(context),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: child,
      ),
    );

    if (tooltip != null) {
      w = Tooltip(message: tooltip!, child: w);
    }

    return w;
  }
}
