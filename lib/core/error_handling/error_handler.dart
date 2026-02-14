// ============================================================================
// PRODUCTION-READY ERROR HANDLING SYSTEM
// ============================================================================
// Comprehensive error handling with beautiful UI feedback
// Handles all common errors: network, auth, Firestore, Agora, permissions
// Production-ready with user-friendly messages
// ============================================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/design_system/design_constants.dart';

/// Error types for categorization
enum AppErrorType {
  network,
  authentication,
  firestore,
  agora,
  permission,
  storage,
  unknown,
}

/// Comprehensive error model
class AppError {
  final AppErrorType type;
  final String title;
  final String message;
  final String? technicalDetails;
  final bool isRetryable;
  final VoidCallback? onRetry;

  const AppError({
    required this.type,
    required this.title,
    required this.message,
    this.technicalDetails,
    this.isRetryable = false,
    this.onRetry,
  });

  /// Parse Firebase Auth errors
  factory AppError.fromFirebaseAuth(FirebaseAuthException e, {VoidCallback? onRetry}) {
    String title = 'Authentication Error';
    String message;

    switch (e.code) {
      case 'user-not-found':
        message = 'No account found with this email. Please sign up first.';
      case 'wrong-password':
        message = 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        message = 'This email is already registered. Try signing in instead.';
      case 'weak-password':
        message = 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        message = 'Invalid email address format.';
      case 'user-disabled':
        message = 'This account has been disabled. Contact support.';
      case 'too-many-requests':
        message = 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        message = 'This sign-in method is not enabled. Contact support.';
      case 'requires-recent-login':
        message = 'Please sign in again to complete this action.';
      case 'credential-already-in-use':
        message = 'This account is already linked to another user.';
      case 'network-request-failed':
        title = 'Network Error';
        message = 'No internet connection. Please check your network.';
      default:
        message = 'Authentication failed. Please try again.';
    }

    return AppError(
      type: e.code == 'network-request-failed'
          ? AppErrorType.network
          : AppErrorType.authentication,
      title: title,
      message: message,
      technicalDetails: '${e.code}: ${e.message}',
      isRetryable: e.code == 'network-request-failed' || e.code == 'too-many-requests',
      onRetry: onRetry,
    );
  }

  /// Parse Firestore errors
  factory AppError.fromFirestore(FirebaseException e, {VoidCallback? onRetry}) {
    String title = 'Database Error';
    String message;
    bool isRetryable = false;

    switch (e.code) {
      case 'permission-denied':
        message = 'You don\'t have permission to access this data.';
      case 'not-found':
        message = 'The requested data was not found.';
      case 'already-exists':
        message = 'This data already exists. Try updating instead.';
      case 'deadline-exceeded':
      case 'unavailable':
        message = 'Database is temporarily unavailable. Please try again.';
        isRetryable = true;
      case 'resource-exhausted':
        message = 'Too many requests. Please wait a moment.';
        isRetryable = true;
      case 'failed-precondition':
        message = 'Operation failed. Please refresh and try again.';
        isRetryable = true;
      case 'aborted':
        message = 'Operation was cancelled. Please try again.';
        isRetryable = true;
      case 'out-of-range':
        message = 'Invalid input value. Please check your data.';
      case 'data-loss':
        message = 'Data may be corrupted. Please contact support.';
      default:
        message = 'Database operation failed. Please try again.';
        isRetryable = true;
    }

    return AppError(
      type: AppErrorType.firestore,
      title: title,
      message: message,
      technicalDetails: '${e.code}: ${e.message}',
      isRetryable: isRetryable,
      onRetry: onRetry,
    );
  }

  /// Parse network errors
  factory AppError.network({VoidCallback? onRetry}) {
    return AppError(
      type: AppErrorType.network,
      title: 'No Internet Connection',
      message: 'Please check your internet connection and try again.',
      isRetryable: true,
      onRetry: onRetry,
    );
  }

  /// Parse Agora errors
  factory AppError.agora(String errorMessage, {VoidCallback? onRetry}) {
    return AppError(
      type: AppErrorType.agora,
      title: 'Video Chat Error',
      message: 'Failed to connect to video chat. Please try again.',
      technicalDetails: errorMessage,
      isRetryable: true,
      onRetry: onRetry,
    );
  }

  /// Parse permission errors
  factory AppError.permission(String permissionType) {
    return AppError(
      type: AppErrorType.permission,
      title: 'Permission Required',
      message: 'Please grant $permissionType permission to use this feature.',
      isRetryable: false,
    );
  }

  /// Parse storage errors
  factory AppError.storage(String errorMessage, {VoidCallback? onRetry}) {
    return AppError(
      type: AppErrorType.storage,
      title: 'Upload Error',
      message: 'Failed to upload file. Please try again.',
      technicalDetails: errorMessage,
      isRetryable: true,
      onRetry: onRetry,
    );
  }

  /// Generic unknown error
  factory AppError.unknown(Object error, {VoidCallback? onRetry}) {
    return AppError(
      type: AppErrorType.unknown,
      title: 'Unexpected Error',
      message: 'Something went wrong. Please try again.',
      technicalDetails: error.toString(),
      isRetryable: true,
      onRetry: onRetry,
    );
  }
}

/// Error Dialog Widget
class ErrorDialog extends StatelessWidget {
  final AppError error;
  final bool showTechnicalDetails;

  const ErrorDialog({
    super.key,
    required this.error,
    this.showTechnicalDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1D2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _getErrorColor(error.type),
          width: 2,
        ),
      ),
      title: Row(
        children: [
          Icon(
            _getErrorIcon(error.type),
            color: _getErrorColor(error.type),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            error.message,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
          if (showTechnicalDetails && error.technicalDetails != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                error.technicalDetails!,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (error.isRetryable && error.onRetry != null)
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              error.onRetry?.call();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: TextButton.styleFrom(
              foregroundColor: _getErrorColor(error.type),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'OK',
            style: TextStyle(color: DesignConstants.accentPurple),
          ),
        ),
      ],
    );
  }

  IconData _getErrorIcon(AppErrorType type) {
    switch (type) {
      case AppErrorType.network:
        return Icons.wifi_off;
      case AppErrorType.authentication:
        return Icons.lock_outline;
      case AppErrorType.firestore:
        return Icons.cloud_off;
      case AppErrorType.agora:
        return Icons.videocam_off;
      case AppErrorType.permission:
        return Icons.warning_amber;
      case AppErrorType.storage:
        return Icons.upload_file;
      case AppErrorType.unknown:
        return Icons.error_outline;
    }
  }

  Color _getErrorColor(AppErrorType type) {
    switch (type) {
      case AppErrorType.network:
        return Colors.orange;
      case AppErrorType.authentication:
        return Colors.red;
      case AppErrorType.firestore:
        return Colors.deepOrange;
      case AppErrorType.agora:
        return Colors.purple;
      case AppErrorType.permission:
        return Colors.amber;
      case AppErrorType.storage:
        return Colors.blue;
      case AppErrorType.unknown:
        return Colors.grey;
    }
  }
}

/// Error Snackbar Widget
class ErrorSnackbar {
  static void show(BuildContext context, AppError error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getIcon(error.type),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    error.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    error.message,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: _getColor(error.type),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: error.isRetryable && error.onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: error.onRetry!,
              )
            : null,
      ),
    );
  }

  static IconData _getIcon(AppErrorType type) {
    switch (type) {
      case AppErrorType.network:
        return Icons.wifi_off;
      case AppErrorType.authentication:
        return Icons.lock_outline;
      case AppErrorType.firestore:
        return Icons.cloud_off;
      case AppErrorType.agora:
        return Icons.videocam_off;
      case AppErrorType.permission:
        return Icons.warning_amber;
      case AppErrorType.storage:
        return Icons.upload_file;
      case AppErrorType.unknown:
        return Icons.error_outline;
    }
  }

  static Color _getColor(AppErrorType type) {
    switch (type) {
      case AppErrorType.network:
        return Colors.orange[700]!;
      case AppErrorType.authentication:
        return Colors.red[700]!;
      case AppErrorType.firestore:
        return Colors.deepOrange[700]!;
      case AppErrorType.agora:
        return Colors.purple[700]!;
      case AppErrorType.permission:
        return Colors.amber[700]!;
      case AppErrorType.storage:
        return Colors.blue[700]!;
      case AppErrorType.unknown:
        return Colors.grey[700]!;
    }
  }
}

/// Error Handler Service - Centralized error handling
class ErrorHandlerService {
  /// Show error dialog
  static void showDialog(BuildContext context, Object error, {VoidCallback? onRetry}) {
    final appError = _parseError(error, onRetry: onRetry);
    showGeneralDialog(
      context: context,
      pageBuilder: (context, anim1, anim2) => ErrorDialog(error: appError),
    );
  }

  /// Show error snackbar
  static void showSnackbar(BuildContext context, Object error, {VoidCallback? onRetry}) {
    final appError = _parseError(error, onRetry: onRetry);
    ErrorSnackbar.show(context, appError);
  }

  /// Parse any error to AppError
  static AppError _parseError(Object error, {VoidCallback? onRetry}) {
    if (error is AppError) {
      return error;
    } else if (error is FirebaseAuthException) {
      return AppError.fromFirebaseAuth(error, onRetry: onRetry);
    } else if (error is FirebaseException) {
      return AppError.fromFirestore(error, onRetry: onRetry);
    } else if (error.toString().contains('network') || error.toString().contains('connection')) {
      return AppError.network(onRetry: onRetry);
    } else {
      return AppError.unknown(error, onRetry: onRetry);
    }
  }
}

/// Extension for easy error handling in widgets
extension ErrorHandlingExtension on BuildContext {
  void showErrorDialog(Object error, {VoidCallback? onRetry}) {
    ErrorHandlerService.showDialog(this, error, onRetry: onRetry);
  }

  void showErrorSnackbar(Object error, {VoidCallback? onRetry}) {
    ErrorHandlerService.showSnackbar(this, error, onRetry: onRetry);
  }
}
