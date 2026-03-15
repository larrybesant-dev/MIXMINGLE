import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Global Error Boundary Widget
/// Catches and displays all uncaught errors in the widget tree
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final void Function(FlutterErrorDetails)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _errorDetails;

  @override
  void initState() {
    super.initState();

    // Set up global error handler
    FlutterError.onError = (FlutterErrorDetails details) {
      if (mounted) {
        setState(() {
          _errorDetails = details;
        });
      }

      // Log error in debug mode
      if (kDebugMode) {
        FlutterError.presentError(details);
      }

      // Call custom error handler if provided
      widget.onError?.call(details);
    };
  }

  void _retry() {
    if (mounted) {
      setState(() {
        _errorDetails = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorDetails != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          backgroundColor: ClubColors.deepNavy,
          body: ErrorBoundaryScreen(
            errorDetails: _errorDetails!,
            onRetry: _retry,
          ),
        ),
      );
    }

    return widget.child;
  }
}

/// Error Boundary Screen
/// Displays branded error UI with retry option
class ErrorBoundaryScreen extends StatelessWidget {
  final FlutterErrorDetails errorDetails;
  final VoidCallback onRetry;

  const ErrorBoundaryScreen({
    super.key,
    required this.errorDetails,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final errorMessage = kDebugMode
        ? errorDetails.exceptionAsString()
        : 'An unexpected error occurred. Please try again.';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon with animation
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ClubColors.error.withValues(alpha: 0.1),
                border: Border.all(
                  color: ClubColors.error.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: ClubColors.error,
              ),
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              'Oops! Something Went Wrong',
              style: ClubTextStyles.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Error message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ClubColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ClubColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                errorMessage,
                style: ClubTextStyles.textTheme.bodyMedium?.copyWith(
                  color: ClubColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: kDebugMode ? null : 3,
                overflow: kDebugMode ? null : TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 32),

            // Retry button
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('RETRY'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ClubColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),

            if (kDebugMode) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Show full stack trace in debug mode
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Stack Trace'),
                      content: SingleChildScrollView(
                        child: Text(
                          errorDetails.stack.toString(),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('CLOSE'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('View Stack Trace'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Zone Error Handler
/// Catches errors outside the widget tree (async errors)
class ZoneErrorHandler {
  static void initialize() {
    // Catch zone errors (async errors)
    runZonedGuarded(() {
      // App will run here
    }, (error, stack) {
      if (kDebugMode) {
        debugPrint('Uncaught zone error: $error');
        debugPrint('Stack trace: $stack');
      }

      // Log to crash reporting service in production
      // Example: FirebaseCrashlytics.instance.recordError(error, stack);
    });
  }
}
