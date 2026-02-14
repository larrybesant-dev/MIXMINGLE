import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/feature_flags.dart';
import '../../core/design_system/design_constants.dart';
import '../../services/room_limit_manager.dart';

/// UI Widgets for displaying room publisher capacity status
///
/// Shows users how many video publishers are active and when limit is approaching

/// Provider for room capacity status
final roomCapacityProvider = StreamProvider.family<int, String>((ref, roomId) {
  final limitManager = RoomLimitManager();
  return limitManager.watchRoomCapacity(roomId);
});

/// Room capacity indicator - shows current publisher count vs limit
class RoomCapacityIndicator extends ConsumerWidget {
  final String roomId;
  final TextStyle? style;
  final Color? textColor;

  const RoomCapacityIndicator({
    super.key,
    required this.roomId,
    this.style,
    this.textColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capacityAsync = ref.watch(roomCapacityProvider(roomId));

    return capacityAsync.when(
      data: (publisherCount) {
        final limit = FeatureFlags.maxConcurrentAgoraConnections;
        final isNearLimit = publisherCount >= (limit * 0.75).ceil();
        final isAtLimit = publisherCount >= limit;

        final displayColor = isAtLimit
            ? DesignColors.error
            : isNearLimit
                ? DesignColors.warning
                : DesignColors.success;

        return Text(
          '👥 $publisherCount/$limit on camera',
          style: (style ?? const TextStyle(fontSize: 12)).copyWith(
            color: textColor ?? displayColor,
            fontWeight: isNearLimit ? FontWeight.bold : FontWeight.normal,
          ),
        );
      },
      loading: () => const Text('👥 Loading...'),
      error: (err, _) => const Text('👥 Error'),
    );
  }
}

/// Large capacity status card for room screens
class RoomCapacityCard extends ConsumerWidget {
  final String roomId;

  const RoomCapacityCard({
    super.key,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capacityAsync = ref.watch(roomCapacityProvider(roomId));

    return capacityAsync.when(
      data: (publisherCount) {
        final limit = FeatureFlags.maxConcurrentAgoraConnections;
        final percentage = ((publisherCount / limit) * 100).toInt();
        final isAtLimit = publisherCount >= limit;
        final isNearLimit = publisherCount >= (limit * 0.75).ceil();

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isAtLimit
                ? DesignColors.error.withValues(alpha: 0.1)
                : isNearLimit
                    ? DesignColors.warning.withValues(alpha: 0.1)
                    : DesignColors.success.withValues(alpha: 0.1),
            border: Border.all(
              color: isAtLimit
                  ? DesignColors.error
                  : isNearLimit
                      ? DesignColors.warning
                      : DesignColors.success,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '📹 Video Publishers',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '$publisherCount/$limit',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isAtLimit ? DesignColors.error : null,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Capacity bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: publisherCount / limit,
                  minHeight: 8,
                  backgroundColor: DesignColors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isAtLimit
                        ? DesignColors.error
                        : isNearLimit
                            ? DesignColors.warning
                            : DesignColors.success,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Status message
              if (isAtLimit)
                Text(
                  '🔴 Room is full! No more video publishers can join.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DesignColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                )
              else if (isNearLimit)
                Text(
                  '⚠️ Room is nearly full ($percentage% capacity). Quality may degrade.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DesignColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                )
              else
                Text(
                  '✅ Room has space for ${limit - publisherCount} more video publishers',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DesignColors.success,
                      ),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: SizedBox(
          height: 100,
          child: Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DesignColors.error.withValues(alpha: 0.1),
          border: Border.all(color: DesignColors.error),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Could not load room capacity',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: DesignColors.error,
              ),
        ),
      ),
    );
  }
}

/// Compact capacity badge for app bar or toolbar
class CapacityBadge extends ConsumerWidget {
  final String roomId;
  final bool showIcon;

  const CapacityBadge({
    super.key,
    required this.roomId,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capacityAsync = ref.watch(roomCapacityProvider(roomId));

    return capacityAsync.when(
      data: (publisherCount) {
        final limit = FeatureFlags.maxConcurrentAgoraConnections;
        final isAtLimit = publisherCount >= limit;
        final isNearLimit = publisherCount >= (limit * 0.75).ceil();

        final bgColor = isAtLimit
            ? DesignColors.error
            : isNearLimit
                ? DesignColors.warning
                : DesignColors.success;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcon) ...[
                Icon(
                  isAtLimit ? Icons.warning : Icons.videocam,
                  size: 14,
                  color: DesignColors.white,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                '$publisherCount/$limit',
                style: const TextStyle(
                  color: DesignColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: DesignColors.textGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1,
            valueColor: AlwaysStoppedAnimation<Color>(DesignColors.white),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Overlay warning when room is at capacity
class RoomFullOverlay extends ConsumerWidget {
  final String roomId;
  final VoidCallback? onDismiss;

  const RoomFullOverlay({
    super.key,
    required this.roomId,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capacityAsync = ref.watch(roomCapacityProvider(roomId));

    return capacityAsync.when(
      data: (publisherCount) {
        final limit = FeatureFlags.maxConcurrentAgoraConnections;
        final isAtLimit = publisherCount >= limit;

        if (!isAtLimit) {
          return const SizedBox.shrink();
        }

        return AnimatedOpacity(
          opacity: 1,
          duration: const Duration(milliseconds: 300),
          child: Container(
            color: DesignColors.overlay,
            child: Center(
              child: AlertDialog(
                title: const Text('🔴 Room is Full'),
                content: Text(
                  'This room has reached its maximum capacity of $limit video publishers. '
                  'No additional video streams can be added at this time.\n\n'
                  'You can still join as an audience member and chat.',
                ),
                actions: [
                  TextButton(
                    onPressed: onDismiss,
                    child: const Text('Understood'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Go Live button with capacity checking
class GoLiveButton extends ConsumerWidget {
  final String roomId;
  final String userId;
  final VoidCallback onPressed;
  final bool isEnabled;
  final String? label;
  final ButtonStyle? style;

  const GoLiveButton({
    super.key,
    required this.roomId,
    required this.userId,
    required this.onPressed,
    this.isEnabled = true,
    this.label,
    this.style,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capacityAsync = ref.watch(roomCapacityProvider(roomId));

    return capacityAsync.when(
      data: (publisherCount) {
        final limit = FeatureFlags.maxConcurrentAgoraConnections;
        final isAtLimit = publisherCount >= limit;

        return Tooltip(
          message: isAtLimit
              ? 'Room is at capacity ($publisherCount/$limit publishers). '
                  'Wait for someone to stop streaming before going live.'
              : 'Go Live! Start streaming video to the room',
          child: ElevatedButton.icon(
            onPressed: (isEnabled && !isAtLimit) ? onPressed : null,
            icon: const Icon(Icons.videocam),
            label: Text(label ?? 'Go Live'),
            style: style,
          ),
        );
      },
      loading: () => ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.videocam),
        label: Text(label ?? 'Loading...'),
      ),
      error: (err, _) => ElevatedButton.icon(
        onPressed: isEnabled ? onPressed : null,
        icon: const Icon(Icons.videocam),
        label: Text(label ?? 'Go Live'),
      ),
    );
  }
}
