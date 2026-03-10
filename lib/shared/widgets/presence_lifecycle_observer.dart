// lib/core/widgets/presence_lifecycle_observer.dart
//
// PresenceLifecycleObserver
//
// Wraps the authenticated app to listen to Flutter's AppLifecycleState and
// drive PresenceService state transitions:
//
//   AppLifecycleState.resumed   → goOnline()
//   AppLifecycleState.inactive  → goAway()   (transitional, e.g. notification shade)
//   AppLifecycleState.paused    → goAway()   (app fully backgrounded)
//   AppLifecycleState.hidden    → goAway()   (app hidden, desktop/iPad)
//   AppLifecycleState.detached  → goOffline() (app is being terminated)
//
// This is the canonical implementation of PHASE 2 of the presence system.
// Do NOT add WidgetsBindingObserver to individual screens for presence purposes.
// ──────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/user_providers.dart';

/// Wraps the authenticated app widget tree and reacts to app lifecycle changes
/// to keep the user's presence state in sync with Firestore.
class PresenceLifecycleObserver extends ConsumerStatefulWidget {
  final Widget child;

  const PresenceLifecycleObserver({super.key, required this.child});

  @override
  ConsumerState<PresenceLifecycleObserver> createState() =>
      _PresenceLifecycleObserverState();
}

class _PresenceLifecycleObserverState
    extends ConsumerState<PresenceLifecycleObserver> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final presenceService = ref.read(presenceServiceProvider);
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground: mark online
        presenceService.goOnline();
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // App is backgrounded or partially obscured: mark away
        presenceService.goAway();
      case AppLifecycleState.detached:
        // App is shutting down: mark offline (best-effort synchronous write)
        presenceService.goOffline();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
