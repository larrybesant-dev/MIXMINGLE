import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Performance optimization utilities for enhanced app performance
class PerformanceUtils {
  /// Cache for expensive computations
  static final Map<String, dynamic> _cache = {};

  /// Clear performance cache
  static void clearCache() {
    _cache.clear();
  }

  /// Cached computation with TTL (Time To Live)
  static T cached<T>(
    String key,
    T Function() computation, {
    Duration ttl = const Duration(minutes: 5),
  }) {
    final cacheKey =
        '${key}_${DateTime.now().millisecondsSinceEpoch ~/ ttl.inMilliseconds}';

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey] as T;
    }

    final result = computation();
    _cache[cacheKey] = result;
    return result;
  }

  /// Debounce function calls
  static VoidCallback debounce(
    VoidCallback callback, {
    Duration delay = const Duration(milliseconds: 300),
  }) {
    Timer? timer;
    return () {
      timer?.cancel();
      timer = Timer(delay, callback);
    };
  }

  /// Throttle function calls
  static VoidCallback throttle(
    VoidCallback callback, {
    Duration delay = const Duration(milliseconds: 100),
  }) {
    bool canCall = true;
    return () {
      if (canCall) {
        callback();
        canCall = false;
        Timer(delay, () => canCall = true);
      }
    };
  }

  /// Memory-efficient list view with recycling
  static Widget efficientListView({
    required List<Widget> children,
    ScrollController? controller,
    EdgeInsetsGeometry? padding,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }

  /// Optimized grid view for large datasets
  static Widget efficientGridView({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    int crossAxisCount = 2,
    double childAspectRatio = 1.0,
    double crossAxisSpacing = 8.0,
    double mainAxisSpacing = 8.0,
    EdgeInsetsGeometry? padding,
    ScrollController? controller,
  }) {
    return GridView.builder(
      controller: controller,
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }

  /// Lazy loading widget
  static Widget lazyLoad({
    required Widget child,
    VoidCallback? onLoad,
    double threshold = 100.0,
  }) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          final metrics = notification.metrics;
          if (metrics.pixels >= metrics.maxScrollExtent - threshold) {
            onLoad?.call();
          }
        }
        return false;
      },
      child: child,
    );
  }

  /// Optimized image loading with caching
  static Widget optimizedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? const CircularProgressIndicator();
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? const Icon(Icons.error);
      },
    );
  }

  /// Performance monitoring
  static void measurePerformance(
    String operation,
    VoidCallback operationCallback,
  ) {
    if (kDebugMode) {
      final stopwatch = Stopwatch()..start();
      operationCallback();
      stopwatch.stop();
      debugPrint('$operation took ${stopwatch.elapsedMilliseconds}ms');
    } else {
      operationCallback();
    }
  }

  /// Async operation with timeout
  static Future<T> withTimeout<T>(
    Future<T> future,
    Duration timeout, {
    T? defaultValue,
  }) {
    return future.timeout(
      timeout,
      onTimeout: () {
        debugPrint('Operation timed out after ${timeout.inMilliseconds}ms');
        return defaultValue as T;
      },
    );
  }

  /// Resource cleanup utility
  static void cleanupResources() {
    clearCache();
    // Add other cleanup operations here
  }
}

/// Performance monitoring widget
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const PerformanceMonitor({
    super.key,
    required this.child,
    this.enabled = kDebugMode,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor>
    with WidgetsBindingObserver {
  int _frameCount = 0;
  DateTime? _lastFrameTime;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      WidgetsBinding.instance.addObserver(this);
    }
  }

  @override
  void dispose() {
    if (widget.enabled) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    debugPrint('Memory pressure detected - consider optimizing memory usage');
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 50,
          right: 10,
          child: Container(
            padding: const EdgeInsets.all(8),
            color: Colors.black54,
            child: Text(
              'FPS: ${_calculateFPS()}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  double _calculateFPS() {
    final now = DateTime.now();
    if (_lastFrameTime == null) {
      _lastFrameTime = now;
      return 0.0;
    }

    _frameCount++;
    final timeDiff = now.difference(_lastFrameTime!).inMilliseconds;

    if (timeDiff >= 1000) {
      final fps = (_frameCount / timeDiff) * 1000;
      _frameCount = 0;
      _lastFrameTime = now;
      return fps;
    }

    return 0.0;
  }
}

/// Optimized scroll behavior
class OptimizedScrollBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child; // Remove scrollbars for better performance on mobile
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child; // Remove overscroll indicators for cleaner look
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}

/// Memory-efficient list item
class OptimizedListItem extends StatelessWidget {
  final Widget child;
  final bool isVisible;

  const OptimizedListItem({
    super.key,
    required this.child,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }
    return child;
  }
}
