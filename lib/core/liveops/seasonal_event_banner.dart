/// Seasonal Event Banner Widget
///
/// Displays seasonal event banners, countdowns, and promotional
/// content for active and upcoming events.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'seasonal_event_service.dart';

/// Seasonal event banner widget
class SeasonalEventBanner extends StatefulWidget {
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final bool showCountdown;
  final bool compact;
  final EdgeInsets? margin;

  const SeasonalEventBanner({
    super.key,
    this.onTap,
    this.onDismiss,
    this.showCountdown = true,
    this.compact = false,
    this.margin,
  });

  @override
  State<SeasonalEventBanner> createState() => _SeasonalEventBannerState();
}

class _SeasonalEventBannerState extends State<SeasonalEventBanner>
    with SingleTickerProviderStateMixin {
  SeasonalEvent? _event;
  Timer? _countdownTimer;
  Duration _timeRemaining = Duration.zero;
  late AnimationController _shimmerController;
  StreamSubscription? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _loadEvent();
    _eventSubscription = SeasonalEventService.instance.currentEventStream.listen(
      (event) {
        if (mounted) {
          setState(() => _event = event);
          _startCountdown();
        }
      },
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _shimmerController.dispose();
    _eventSubscription?.cancel();
    super.dispose();
  }

  void _loadEvent() {
    _event = SeasonalEventService.instance.currentEvent;
    if (_event != null) {
      _startCountdown();
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    if (_event == null) return;

    _updateTimeRemaining();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateTimeRemaining(),
    );
  }

  void _updateTimeRemaining() {
    if (_event == null || !mounted) return;

    final remaining = _event!.endDate.difference(DateTime.now());
    setState(() {
      _timeRemaining = remaining.isNegative ? Duration.zero : remaining;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_event == null) {
      return const SizedBox.shrink();
    }

    if (widget.compact) {
      return _buildCompactBanner();
    }

    return _buildFullBanner();
  }

  Widget _buildFullBanner() {
    final primaryColor = _parseColor(_event!.primaryColor);
    final secondaryColor = _parseColor(_event!.secondaryColor);

    return Container(
      margin: widget.margin ?? const EdgeInsets.all(16),
      child: Stack(
        children: [
          // Background with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withAlpha(77),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(51),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getEventTypeName(_event!.type),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Event name
                      Text(
                        _event!.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Description
                      Text(
                        _event!.description,
                        style: TextStyle(
                          color: Colors.white.withAlpha(204),
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),

                      // Countdown or progress
                      if (widget.showCountdown) ...[
                        _buildCountdown(),
                        const SizedBox(height: 12),
                      ],

                      // Progress bar
                      _buildProgressBar(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Dismiss button
          if (widget.onDismiss != null)
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: widget.onDismiss,
              ),
            ),

          // Shimmer effect
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  return ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        colors: [
                          Colors.white.withAlpha(0),
                          Colors.white.withAlpha(51),
                          Colors.white.withAlpha(0),
                        ],
                        stops: const [0.3, 0.5, 0.7],
                        transform: GradientRotation(
                          _shimmerController.value * 3.14159 * 2,
                        ),
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.srcATop,
                    child: Container(color: Colors.white.withAlpha(13)),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactBanner() {
    final primaryColor = _parseColor(_event!.primaryColor);
    final secondaryColor = _parseColor(_event!.secondaryColor);

    return Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Event icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getEventIcon(_event!.type),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Event info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _event!.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.showCountdown)
                        Text(
                          _formatCountdown(_timeRemaining),
                          style: TextStyle(
                            color: Colors.white.withAlpha(179),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),

                // Arrow
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountdown() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCountdownUnit(_timeRemaining.inDays, 'Days'),
        _buildCountdownUnit(_timeRemaining.inHours % 24, 'Hours'),
        _buildCountdownUnit(_timeRemaining.inMinutes % 60, 'Mins'),
        _buildCountdownUnit(_timeRemaining.inSeconds % 60, 'Secs'),
      ],
    );
  }

  Widget _buildCountdownUnit(int value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(51),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(179),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    final progress = _event!.progressPercent / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_event!.daysRemaining} days left',
              style: TextStyle(
                color: Colors.white.withAlpha(179),
                fontSize: 12,
              ),
            ),
            Text(
              '${_event!.progressPercent.toStringAsFixed(0)}%',
              style: TextStyle(
                color: Colors.white.withAlpha(179),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withAlpha(51),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  String _formatCountdown(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h left';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m left';
    } else {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s left';
    }
  }

  String _getEventTypeName(SeasonalEventType type) {
    switch (type) {
      case SeasonalEventType.holiday:
        return 'HOLIDAY';
      case SeasonalEventType.celebration:
        return 'CELEBRATION';
      case SeasonalEventType.anniversary:
        return 'ANNIVERSARY';
      case SeasonalEventType.specialMode:
        return 'SPECIAL MODE';
      case SeasonalEventType.communityChallenge:
        return 'CHALLENGE';
      case SeasonalEventType.tournament:
        return 'TOURNAMENT';
      case SeasonalEventType.festival:
        return 'FESTIVAL';
      case SeasonalEventType.promotion:
        return 'PROMO';
    }
  }

  IconData _getEventIcon(SeasonalEventType type) {
    switch (type) {
      case SeasonalEventType.holiday:
        return Icons.celebration;
      case SeasonalEventType.celebration:
        return Icons.party_mode;
      case SeasonalEventType.anniversary:
        return Icons.cake;
      case SeasonalEventType.specialMode:
        return Icons.star;
      case SeasonalEventType.communityChallenge:
        return Icons.emoji_events;
      case SeasonalEventType.tournament:
        return Icons.military_tech;
      case SeasonalEventType.festival:
        return Icons.festival;
      case SeasonalEventType.promotion:
        return Icons.local_offer;
    }
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.deepPurple;
    }
  }
}

/// Small event badge for app bars and headers
class SeasonalEventBadge extends StatelessWidget {
  final VoidCallback? onTap;

  const SeasonalEventBadge({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final event = SeasonalEventService.instance.currentEvent;
    if (event == null || !event.isRunning) {
      return const SizedBox.shrink();
    }

    final primaryColor = _parseColor(event.primaryColor);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              event.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.deepPurple;
    }
  }
}

/// Floating action button for events
class SeasonalEventFAB extends StatelessWidget {
  final VoidCallback onPressed;

  const SeasonalEventFAB({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final event = SeasonalEventService.instance.currentEvent;
    if (event == null || !event.isRunning) {
      return const SizedBox.shrink();
    }

    final primaryColor = _parseColor(event.primaryColor);

    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: primaryColor,
      icon: const Icon(Icons.celebration),
      label: Text(
        event.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.deepPurple;
    }
  }
}
