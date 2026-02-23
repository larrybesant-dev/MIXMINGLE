import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/connectivity_provider.dart';
import 'empty_states.dart';

/// Offline interceptor widget
/// Shows offline state when disconnected and prevents network actions
class OfflineInterceptor extends ConsumerWidget {
  final Widget child;
  final bool showOverlay;

  const OfflineInterceptor({
    super.key,
    required this.child,
    this.showOverlay = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityStateProvider);

    return connectivityAsync.when(
      data: (isOnline) {
        if (!isOnline && showOverlay) {
          return Stack(
            children: [
              child,
              Positioned.fill(
                child: Container(
                  color: Colors.black87,
                  child: const OfflineEmptyState(),
                ),
              ),
            ],
          );
        }
        return child;
      },
      loading: () => child,
      error: (_, __) => child,
    );
  }
}

/// Widget that disables itself when offline
class OnlineOnly extends ConsumerWidget {
  final Widget child;
  final VoidCallback? onOfflineTap;

  const OnlineOnly({
    super.key,
    required this.child,
    this.onOfflineTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = connectivityNotifier.isOnline;

    if (!isOnline) {
      return Opacity(
        opacity: 0.5,
        child: AbsorbPointer(
          child: GestureDetector(
            onTap: onOfflineTap ??
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('This action requires an internet connection'),
                      backgroundColor: Color(0xFFFF4C4C),
                    ),
                  );
                },
            child: child,
          ),
        ),
      );
    }

    return child;
  }
}

/// Banner that shows when offline
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityStateProvider);

    return connectivityAsync.when(
      data: (isOnline) {
        if (!isOnline) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: const Color(0xFFFF4C4C),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  'No internet connection',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
