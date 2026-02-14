/// Loading States & UX Polish Guide
///
/// This module demonstrates best practices for loading states and UX in the app.
/// The goal: Users should always know what's happening, and the app should never
/// feel broken or silent.
library;

import 'package:flutter/material.dart';
import '../../core/design_system/design_constants.dart';

/// Generic loading dialog with customizable message
class LoadingDialog extends StatelessWidget {
  final String message;
  final bool cancelable;
  final VoidCallback? onCancel;

  const LoadingDialog({
    super.key,
    required this.message,
    this.cancelable = false,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DesignColors.dialogBackground,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(DesignColors.accent),
              ),
            ),
          ),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: DesignColors.accent,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: cancelable
          ? [
              TextButton(
                onPressed: onCancel ?? () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ]
          : null,
    );
  }

  /// Show this dialog
  static Future<void> show(
    BuildContext context, {
    required String message,
    bool barrierDismissible = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => LoadingDialog(message: message),
    );
  }

  /// Hide the loading dialog
  static void hide(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
}

/// Error dialog with action buttons
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DesignColors.dialogBackground,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          const Icon(Icons.error, color: DesignColors.accent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: DesignTypography.body,
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: DesignTypography.body,
      ),
      actions: [
        if (onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onRetry!();
            },
            child: const Text('Retry'),
          ),
        TextButton(
          onPressed: onDismiss ?? () => Navigator.pop(context),
          child: const Text('Dismiss'),
        ),
      ],
    );
  }
}

/// Best practice: Always use explicit states for video room operations
///
/// Don't do this:
/// ```
/// if (loadingState.isLoading) {
///   showLoadingSpinner();
/// }
/// ```
///
/// Do this instead:
/// ```
/// switch (videoRoom.phase) {
///   case VideoRoomPhase.initializing:
///     return buildInitializingUI();
///   case VideoRoomPhase.joining:
///     return buildJoiningUI();
///   case VideoRoomPhase.joined:
///     return buildJoinedUI();
///   case VideoRoomPhase.error:
///     return buildErrorUI();
/// }
/// ```

/// Intentional delay constants for human-feeling UX
const Duration minimumLoadingTime = Duration(milliseconds: 300);
const Duration videoInitDelay = Duration(milliseconds: 150);
const Duration permissionRequestDelay = Duration(milliseconds: 200);
const Duration channelJoinDelay = Duration(milliseconds: 400);

/// Pattern: Show loading state for minimum time to avoid jarring UI
///
/// This prevents the loading spinner from flashing too quickly,
/// which feels broken to humans even though it's technically fast
Future<T> showProgressFor<T>(
  Future<T> operation, {
  Duration minimumDisplay = minimumLoadingTime,
}) async {
  final startTime = DateTime.now();
  final result = await operation;
  final elapsed = DateTime.now().difference(startTime);

  if (elapsed < minimumDisplay) {
    await Future.delayed(minimumDisplay - elapsed);
  }

  return result;
}

/// Pattern: Compose async operations with explicit transitions
///
/// Example:
/// ```dart
/// Future<void> initializeAndJoin() async {
///   state = state.copyWith(isInitializing: true);
///   try {
///     await _lifecycle.initialize();
///     state = state.copyWith(isInitializing: false, isInitialized: true);
///
///     state = state.copyWith(isJoining: true);
///     await _lifecycle.joinChannel(...);
///     state = state.copyWith(isJoining: false, isJoined: true);
///   } catch (e) {
///     state = state.copyWith(error: e.toString());
///   }
/// }
/// ```

/// Loading messages that should be shown based on operation
const Map<String, String> loadingMessages = {
  'initializing_sdk': '📱 Initializing video system...',
  'requesting_permissions': '🔐 Requesting camera & microphone permissions...',
  'joining_channel': '🔗 Joining conversation...',
  'leaving_channel': '👋 Leaving room...',
  'toggling_camera': '📹 Adjusting camera...',
  'toggling_mic': '🎤 Adjusting microphone...',
};

/// UX Patterns for Error Handling
///
/// 1. Permission Denied:
///    Show: "Camera access denied. Please enable in Settings."
///    Action: Link to app settings or suggest retry
///
/// 2. Network Error:
///    Show: "Connection lost. Retrying..."
///    Action: Auto-retry with exponential backoff
///
/// 3. Channel Full:
///    Show: "This room is currently full."
///    Action: Suggest joining different room or queuing
///
/// 4. Timeout:
///    Show: "Camera is taking too long to start. Try restarting the app."
///    Action: Retry or close

class UXPolishLibrary {
  /// Add subtle animations to state transitions
  /// - Fade in/out for loading spinners (300ms)
  /// - Slide transitions for dialogs (250ms)
  /// - Button press feedback (100ms delay before action)

  /// Add haptic feedback for important actions
  /// - Success: light impact
  /// - Error: medium impact
  /// - Warning: heavy impact

  /// Use color psychology
  /// - Red (#FF4C4C) for errors and critical actions
  /// - Green (#4CAF50) for success
  /// - Yellow (#FF9800) for warnings
  /// - Blue (#4A90E2) for informational

  /// Always show time-aware messages
  /// - "Connection interrupted (30s ago)"
  /// - "Loading for 5+ seconds..."
  /// - Helps users understand if something is actually stuck

  static void showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: DesignColors.success),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: DesignColors.accent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static void showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: DesignColors.accent),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: DesignColors.accent,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () {},
        ),
      ),
    );
  }
}



