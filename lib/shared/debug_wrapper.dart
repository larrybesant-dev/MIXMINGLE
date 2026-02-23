import 'package:flutter/material.dart';
// Replaced with canonical relative import

/// Debug wrapper widget that catches and logs errors for individual widgets
class DebugWrapper extends StatefulWidget {
  final Widget child;
  final String? widgetName;
  final bool showErrorUI;

  const DebugWrapper({
    super.key,
    required this.child,
    this.widgetName,
    this.showErrorUI = true,
  });
  @override
  State<DebugWrapper> createState() => _DebugWrapperState();
}

class _DebugWrapperState extends State<DebugWrapper> {
  dynamic _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null && widget.showErrorUI) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          border: Border.all(color: Colors.red, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bug_report, color: Colors.red, size: 32),
            const SizedBox(height: 8),
            Text(
              'Widget Error in ${widget.widgetName ?? 'Unknown Widget'}',
              style: const TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                });
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    try {
      return widget.child;
    } catch (error) {
      // Error in ${widget.widgetName ?? 'Unknown Widget'} handled silently in production
      if (widget.showErrorUI) {
        setState(() {
          _error = error;
        });
        return widget
            .child; // This won't be reached due to setState, but for type safety
      } else {
        // Re-throw if not showing error UI
        rethrow;
      }
    }
  }
}

/// Extension method to easily wrap widgets with debug functionality
extension DebugExtension on Widget {
  Widget debugWrap([String? name, bool showErrorUI = true]) {
    return DebugWrapper(
      widgetName: name,
      showErrorUI: showErrorUI,
      child: this,
    );
  }
}
