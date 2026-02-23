import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'club_background.dart';
import 'glow_text.dart';
import 'neon_button.dart';

/// Global error boundary widget that catches and handles unhandled errors
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext context, FlutterErrorDetails error)?
      errorBuilder;
  final VoidCallback? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _errorDetails;
  String? _errorLocation;

  @override
  void initState() {
    super.initState();
    // Set up global error handling with enhanced logging
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);

      // Try to extract location information
      final stackTrace = details.stack.toString();
      final location = _extractLocationFromStack(stackTrace);

      // Defer setState to avoid calling it during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _errorDetails = details;
            _errorLocation = location;
          });
        }
      });

      // Enhanced logging removed for production
      widget.onError?.call();
    };
  }

  String _extractLocationFromStack(String stackTrace) {
    // Try to extract file and line information from stack trace
    final lines = stackTrace.split('\n');
    for (final line in lines) {
      if (line.contains('.dart')) {
        // Look for patterns like: file:///path/to/file.dart:123:45
        final fileMatch = RegExp(r'file:///.+\.dart:\d+:\d+').firstMatch(line);
        if (fileMatch != null) {
          return fileMatch.group(0)!;
        }

        // Look for patterns like: package:name/file.dart:123:45
        final packageMatch =
            RegExp(r'package:.+\.dart:\d+:\d+').firstMatch(line);
        if (packageMatch != null) {
          return packageMatch.group(0)!;
        }
      }
    }
    return 'Unknown location';
  }

  @override
  Widget build(BuildContext context) {
    if (_errorDetails != null) {
      return widget.errorBuilder?.call(context, _errorDetails!) ??
          _buildDefaultErrorWidget(context);
    }

    return widget.child;
  }

  Widget _buildDefaultErrorWidget(BuildContext context) {
    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFFF4C4C),
                size: 64,
              ),
              const SizedBox(height: 16),
              const GlowText(
                text: 'Oops! Something went wrong',
                fontSize: 24,
                color: Color(0xFFFF4C4C),
                glowColor: Color(0xFFFF4C4C),
              ),
              const SizedBox(height: 16),
              const GlowText(
                text:
                    'The app encountered an unexpected error.\nPlease try restarting the app.',
                fontSize: 16,
                color: Colors.white70,
                textAlign: TextAlign.center,
              ),
              if (_errorLocation != null) ...[
                const SizedBox(height: 16),
                GlowText(
                  text: 'Error Location: $_errorLocation',
                  fontSize: 12,
                  color: Colors.yellow,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              NeonButton(
                label: 'Try Again',
                onPressed: () {
                  setState(() {
                    _errorDetails = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Report error (you can integrate with error reporting service)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error reported. Thank you!'),
                    ),
                  );
                },
                child: const Text(
                  'Report Error',
                  style: TextStyle(color: Color(0xFFFFD700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Provider for handling async operation errors
final errorHandlerProvider = Provider<ErrorHandler>((ref) {
  return ErrorHandler();
});

class ErrorHandler {
  void handleError(BuildContext context, Object error,
      [StackTrace? stackTrace]) {
    debugPrint('Error handled: $error');
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }

    // Show user-friendly error message
    final String message = _getErrorMessage(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF4C4C),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            // You can implement retry logic here
          },
        ),
      ),
    );
  }

  String _getErrorMessage(Object error) {
    if (error is Exception) {
      // Handle specific exception types
      if (error.toString().contains('network')) {
        return 'Network error. Please check your connection.';
      }
      if (error.toString().contains('permission')) {
        return 'Permission denied. Please check app permissions.';
      }
      if (error.toString().contains('auth')) {
        return 'Authentication error. Please log in again.';
      }
    }

    // Generic error message
    return 'An error occurred. Please try again.';
  }
}
