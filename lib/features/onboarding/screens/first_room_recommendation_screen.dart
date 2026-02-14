/// First Room Recommendation Screen
///
/// Final screen of the onboarding flow.
/// Shows recommended rooms with heat meters and glow effects.
library;

import 'package:flutter/material.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../core/theme/neon_colors.dart';
import '../widgets/neon_button.dart';
import '../widgets/heat_meter.dart';

class FirstRoomRecommendationScreen extends StatefulWidget {
  final VoidCallback? onJoinRoom;
  final VoidCallback? onSkip;
  final VoidCallback? onBack;

  const FirstRoomRecommendationScreen({
    super.key,
    this.onJoinRoom,
    this.onSkip,
    this.onBack,
  });

  @override
  State<FirstRoomRecommendationScreen> createState() =>
      _FirstRoomRecommendationScreenState();
}

class _FirstRoomRecommendationScreenState
    extends State<FirstRoomRecommendationScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _pulseController;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;

  // Mock room data
  final _rooms = [
    _RoomData(
      name: 'Friday Night Vibes',
      host: 'DJ_Maxwell',
      participants: 47,
      heat: 0.92,
      tags: ['Music', 'Chill', 'Dance'],
      isRecommended: true,
    ),
    _RoomData(
      name: 'Late Night Chat',
      host: 'NightOwl_Sara',
      participants: 23,
      heat: 0.75,
      tags: ['Talk', 'Friends', 'Chill'],
      isRecommended: false,
    ),
    _RoomData(
      name: 'Gaming Lounge',
      host: 'ProGamer99',
      participants: 35,
      heat: 0.83,
      tags: ['Gaming', 'Fun', 'Casual'],
      isRecommended: false,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _glowController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildWelcomeCard(),
                    const SizedBox(height: 24),
                    _buildRecommendedSection(),
                    const SizedBox(height: 24),
                    _buildOtherRoomsSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Bottom Navigation
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: DesignColors.textGray,
            ),
            onPressed: widget.onBack,
          ),
          Expanded(
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [NeonColors.neonOrange, DesignColors.gold],
                  ).createShader(bounds),
                  child: const Text(
                    'Your First Room',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Step 5 of 5',
                  style: TextStyle(
                    color: DesignColors.textGray.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignColors.gold.withValues(alpha: 0.15),
            NeonColors.neonOrange.withValues(alpha: 0.1),
            DesignColors.surfaceAlt.withValues(alpha: 0.5),
          ],
        ),
        border: Border.all(
          color: DesignColors.gold.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [DesignColors.gold, NeonColors.neonOrange],
              ),
            ),
            child: Icon(
              Icons.celebration,
              color: DesignColors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You\'re All Set!',
                  style: TextStyle(
                    color: DesignColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Jump into a room and start mingling',
                  style: TextStyle(
                    color: DesignColors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedSection() {
    final recommendedRoom = _rooms.firstWhere((r) => r.isRecommended);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.stars,
              color: DesignColors.gold,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'RECOMMENDED FOR YOU',
              style: TextStyle(
                color: DesignColors.gold,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: Listenable.merge([_glowAnimation, _pulseAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: _buildRecommendedRoomCard(recommendedRoom),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecommendedRoomCard(_RoomData room) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignColors.surfaceAlt,
            DesignColors.surfaceDark,
          ],
        ),
        border: Border.all(
          color: DesignColors.gold.withValues(alpha: _glowAnimation.value),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignColors.gold.withValues(alpha: _glowAnimation.value * 0.4),
            blurRadius: 30,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: NeonColors.neonOrange.withValues(alpha: _glowAnimation.value * 0.2),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  NeonColors.neonOrange.withValues(alpha: 0.3),
                  DesignColors.gold.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              children: [
                // Live indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.red,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Colors.white, size: 8),
                      SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // VIP badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      colors: [DesignColors.gold, NeonColors.neonOrange],
                    ),
                  ),
                  child: const Text(
                    '⭐ TOP PICK',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                const Spacer(),
                // Participants
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      color: DesignColors.white.withValues(alpha: 0.8),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${room.participants}',
                      style: TextStyle(
                        color: DesignColors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Room content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room name
                Text(
                  room.name,
                  style: TextStyle(
                    color: DesignColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                // Host
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [NeonColors.neonOrange, NeonColors.neonBlue],
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.person, color: Colors.white, size: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Hosted by ',
                      style: TextStyle(
                        color: DesignColors.textGray,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      room.host,
                      style: TextStyle(
                        color: NeonColors.neonOrange,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: room.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: NeonColors.neonBlue.withValues(alpha: 0.2),
                        border: Border.all(
                          color: NeonColors.neonBlue.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: NeonColors.neonBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Heat meter
                Row(
                  children: [
                    Text(
                      '🔥',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Room Heat',
                      style: TextStyle(
                        color: DesignColors.textGray,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    HeatIndicator(heatLevel: room.heat),
                  ],
                ),
                const SizedBox(height: 8),
                HeatMeter(
                  heatLevel: room.heat,
                  height: 8,
                ),
              ],
            ),
          ),

          // Join button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: OnboardingNeonButton(
              text: 'Join This Room',
              onPressed: widget.onJoinRoom,
              useGoldTrim: true,
              width: double.infinity,
              height: 50,
              icon: Icons.login,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherRoomsSection() {
    final otherRooms = _rooms.where((r) => !r.isRecommended).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.explore,
              color: NeonColors.neonBlue,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'MORE ROOMS',
              style: TextStyle(
                color: NeonColors.neonBlue,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...otherRooms.map((room) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildOtherRoomCard(room),
        )),
      ],
    );
  }

  Widget _buildOtherRoomCard(_RoomData room) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: DesignColors.surfaceAlt,
        border: Border.all(
          color: NeonColors.neonBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Room icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  NeonColors.neonBlue.withValues(alpha: 0.3),
                  NeonColors.neonOrange.withValues(alpha: 0.2),
                ],
              ),
            ),
            child: Center(
              child: Icon(
                Icons.meeting_room,
                color: NeonColors.neonBlue,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Room info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.name,
                  style: TextStyle(
                    color: DesignColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      color: DesignColors.textGray,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${room.participants}',
                      style: TextStyle(
                        color: DesignColors.textGray,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    HeatIndicator(heatLevel: room.heat, size: 14),
                  ],
                ),
              ],
            ),
          ),
          // Join button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: NeonColors.neonBlue.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              'Join',
              style: TextStyle(
                color: NeonColors.neonBlue,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            DesignColors.background.withValues(alpha: 0.0),
            DesignColors.background,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: widget.onSkip,
            child: Text(
              'Explore on my own',
              style: TextStyle(
                color: DesignColors.textGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomData {
  final String name;
  final String host;
  final int participants;
  final double heat;
  final List<String> tags;
  final bool isRecommended;

  const _RoomData({
    required this.name,
    required this.host,
    required this.participants,
    required this.heat,
    required this.tags,
    required this.isRecommended,
  });
}
