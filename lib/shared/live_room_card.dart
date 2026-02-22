import 'design/design_colors.dart';
import 'glow_text.dart';
import 'package:flutter/material.dart';

class LiveRoomCard extends StatefulWidget {
  final String roomName;
  final String djName;
  final int viewerCount;
  final VoidCallback? onTap;
  final bool isLive;

  const LiveRoomCard({
    super.key,
    required this.roomName,
    required this.djName,
    required this.viewerCount,
    this.onTap,
    this.isLive = true,
  });

  @override
  State<LiveRoomCard> createState() => _LiveRoomCardState();
}

class _LiveRoomCardState extends State<LiveRoomCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isLive ? _pulseAnimation.value : 1.0,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: ClubColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isLive
                      ? ClubColors.glowingRed.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.isLive
                        ? ClubColors.glowingRed.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Room header with LIVE indicator
                    Row(
                      children: [
                        if (widget.isLive) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: ClubColors.glowingRed,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  color: Colors.white,
                                  size: 8,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'LIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: GlowText(
                            text: widget.roomName,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ClubColors.goldenYellow,
                            glowColor: ClubColors.glowingRed,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // DJ name
                    Text(
                      'DJ ${widget.djName}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Viewer count and equalizer bars
                    Row(
                      children: [
                        const Icon(
                          Icons.people,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.viewerCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        if (widget.isLive) ...[
                          _EqualizerBars(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EqualizerBars extends StatefulWidget {
  @override
  State<_EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<_EqualizerBars>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(4, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 400 + (index * 100)),
        vsync: this,
      )..repeat(reverse: true);
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(4, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              width: 3,
              height: 12 * _animations[index].value,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: ClubColors.glowingRed,
                borderRadius: BorderRadius.circular(1.5),
                boxShadow: [
                  BoxShadow(
                    color: ClubColors.glowingRed.withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}

