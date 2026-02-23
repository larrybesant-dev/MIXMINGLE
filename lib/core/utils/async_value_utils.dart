import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connectivity_provider.dart';
import '../../shared/widgets/empty_states.dart';
import '../../shared/widgets/loading_widgets.dart';
import 'app_logger.dart';

/// Safe AsyncValue builders with loading, error, and empty states
/// Ensures all AsyncValue.when() calls are properly handled
class SafeAsyncBuilder {
  /// Build UI from AsyncValue with all states handled
  static Widget build<T>({
    required AsyncValue<T> asyncValue,
    required Widget Function(T data) builder,
    Widget Function(Object error, StackTrace? stackTrace)? errorBuilder,
    Widget? loadingWidget,
    String? emptyMessage,
    IconData? emptyIcon,
    VoidCallback? onRetry,
  }) {
    return asyncValue.when(
      data: (data) {
        // Check for empty data
        if (data == null) {
          AppLogger.nullWarning('AsyncValue data', 'SafeAsyncBuilder');
          return emptyWidget(
            message: emptyMessage ?? 'No data available',
            icon: emptyIcon,
            onRetry: onRetry,
          );
        }

        // Check for empty lists
        if (data is List && data.isEmpty) {
          return emptyWidget(
            message: emptyMessage ?? 'No items found',
            icon: emptyIcon ?? Icons.inbox,
            onRetry: onRetry,
          );
        }

        return builder(data);
      },
      loading: () => loadingWidget ?? const LoadingSpinner(),
      error: (error, stackTrace) {
        AppLogger.error('AsyncValue error', error, stackTrace);

        if (errorBuilder != null) {
          return errorBuilder(error, stackTrace);
        }

        return errorWidget(
          error: error,
          onRetry: onRetry,
        );
      },
    );
  }

  /// Build UI from list AsyncValue with proper empty state
  static Widget buildList<T>({
    required AsyncValue<List<T>> asyncValue,
    required Widget Function(List<T> items) builder,
    Widget Function(Object error, StackTrace? stackTrace)? errorBuilder,
    Widget? loadingWidget,
    Widget? emptyWidget,
    String? emptyMessage,
    IconData? emptyIcon,
    VoidCallback? onRetry,
  }) {
    return asyncValue.when(
      data: (items) {
        if (items.isEmpty) {
          return emptyWidget ??
              SafeAsyncBuilder.emptyWidget(
                message: emptyMessage ?? 'No items found',
                icon: emptyIcon ?? Icons.inbox,
                onRetry: onRetry,
              );
        }
        return builder(items);
      },
      loading: () => loadingWidget ?? const LoadingSpinner(),
      error: (error, stackTrace) {
        AppLogger.error('AsyncValue list error', error, stackTrace);

        if (errorBuilder != null) {
          return errorBuilder(error, stackTrace);
        }

        return errorWidget(
          error: error,
          onRetry: onRetry,
        );
      },
    );
  }

  /// Default error widget
  static Widget errorWidget({
    required Object error,
    VoidCallback? onRetry,
  }) {
    // Check if network error
    if (ConnectivityNotifier.isNetworkError(error)) {
      return OfflineEmptyState(onRetry: onRetry);
    }

    return EmptyState(
      icon: Icons.error_outline,
      iconColor: const Color(0xFFFF4C4C),
      title: 'Something went wrong',
      message: _formatErrorMessage(error),
      actionLabel: onRetry != null ? 'Retry' : null,
      onAction: onRetry,
    );
  }

  /// Default empty widget
  static Widget emptyWidget({
    String? message,
    IconData? icon,
    VoidCallback? onRetry,
  }) {
    return EmptyState(
      icon: icon ?? Icons.inbox_outlined,
      title: 'Nothing here yet',
      message: message ?? 'No data available',
      actionLabel: onRetry != null ? 'Refresh' : null,
      onAction: onRetry,
    );
  }

  /// Format error message for users
  static String _formatErrorMessage(Object error) {
    final errorString = error.toString();

    if (errorString.contains('permission')) {
      return 'Permission denied. Please check app settings.';
    }

    if (errorString.contains('not found') || errorString.contains('404')) {
      return 'The requested item was not found.';
    }

    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    if (errorString.contains('auth')) {
      return 'Authentication error. Please log in again.';
    }

    return 'An unexpected error occurred. Please try again.';
  }
}

/// Extension methods for AsyncValue
extension AsyncValueSafeExtension<T> on AsyncValue<T> {
  /// Safely build UI with all states handled
  Widget buildSafe({
    required Widget Function(T data) builder,
    Widget Function(Object error, StackTrace? stackTrace)? errorBuilder,
    Widget? loadingWidget,
    String? emptyMessage,
    IconData? emptyIcon,
    VoidCallback? onRetry,
  }) {
    return SafeAsyncBuilder.build(
      asyncValue: this,
      builder: builder,
      errorBuilder: errorBuilder,
      loadingWidget: loadingWidget,
      emptyMessage: emptyMessage,
      emptyIcon: emptyIcon,
      onRetry: onRetry,
    );
  }
}

extension AsyncValueListSafeExtension<T> on AsyncValue<List<T>> {
  /// Safely build list UI with proper empty state
  Widget buildListSafe({
    required Widget Function(List<T> items) builder,
    Widget Function(Object error, StackTrace? stackTrace)? errorBuilder,
    Widget? loadingWidget,
    Widget? emptyWidget,
    String? emptyMessage,
    IconData? emptyIcon,
    VoidCallback? onRetry,
  }) {
    return SafeAsyncBuilder.buildList(
      asyncValue: this,
      builder: builder,
      errorBuilder: errorBuilder,
      loadingWidget: loadingWidget,
      emptyWidget: emptyWidget,
      emptyMessage: emptyMessage,
      emptyIcon: emptyIcon,
      onRetry: onRetry,
    );
  }
}
