import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../providers/providers.dart';
import '../../providers/room_providers.dart';
import '../../shared/club_background.dart';
import '../../shared/glow_text.dart';
import '../../shared/live_room_card.dart';
import '../../shared/neon_button.dart';
import '../../shared/loading_widgets.dart';
import '../../shared/widgets/auth_guard.dart';
import '../room/screens/voice_room_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 5.0, end: 15.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(roomsProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: const GlowText(
                  text: 'MIX & MINGLE',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD700),
                  glowColor: Color(0xFFFF4C4C),
                  glowRadius: 8,
                ),
              );
            },
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            _buildAnimatedIconButton(
              key: const Key('browse-rooms-btn'),
              icon: Icons.explore,
              onPressed: () => Navigator.of(context).pushNamed('/browse-rooms'),
              tooltip: 'Browse Rooms',
            ),
            _buildAnimatedIconButton(
              key: const Key('speed-dating-btn'),
              icon: Icons.favorite,
              onPressed: () => Navigator.of(context).pushNamed('/speed-dating-lobby'),
              tooltip: 'Speed Dating',
            ),
            _buildAnimatedIconButton(
              key: const Key('search-btn'),
              icon: Icons.search,
              onPressed: () => _showSearchDialog(context, ref),
              tooltip: 'Search',
            ),
            _buildAnimatedIconButton(
              key: const Key('notifications-btn'),
              icon: Icons.notifications,
              onPressed: () => Navigator.of(context).pushNamed('/notifications'),
              tooltip: 'Notifications',
            ),
            _buildAnimatedIconButton(
              key: const Key('profile-btn'),
              icon: Icons.person,
              onPressed: () => Navigator.of(context).pushNamed('/profile'),
              tooltip: 'Profile',
            ),
            _buildAnimatedIconButton(
              key: const Key('logout-btn'),
              icon: Icons.logout,
              onPressed: () => _showSignOutDialog(context, ref),
              tooltip: 'Sign Out',
            ),
          ],
        ),
        body: Stack(
          children: [
            // Animated background particles
            _buildBackgroundParticles(),

            Column(
              children: [
                // Hero section with club vibe
                _buildHeroSection(),

                // Search bar with enhanced styling
                _buildSearchSection(ref),

                // Live rooms section
                Expanded(
                  child: _buildRoomsSection(roomsAsync, searchQuery, ref),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildAnimatedIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    Key? key,
  }) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          key: key != null ? Key('${key.toString()}-container') : null,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                blurRadius: _glowAnimation.value,
                spreadRadius: 1,
              ),
            ],
          ),
          child: IconButton(
            key: key,
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
            tooltip: tooltip,
          ),
        );
      },
    );
  }

  Widget _buildBackgroundParticles() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(_pulseAnimation.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF1E1E2F).withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing background circles
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 150 * _pulseAnimation.value,
                height: 150 * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF4C4C).withValues(alpha: 0.1),
                  border: Border.all(
                    color: const Color(0xFFFF4C4C).withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
              );
            },
          ),

          // Main content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const GlowText(
                text: 'Welcome to the Club',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFD700),
                glowColor: Color(0xFFFF4C4C),
                glowRadius: 10,
              ),
              const SizedBox(height: 8),
              Text(
                'Join live rooms and connect with performers worldwide',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildQuickActionButton(
                    icon: Icons.play_circle_filled,
                    label: 'Go Live',
                    onPressed: () => Navigator.of(context).pushNamed('/go-live'),
                    color: const Color(0xFFFF4C4C),
                  ),
                  const SizedBox(width: 16),
                  _buildQuickActionButton(
                    icon: Icons.explore,
                    label: 'Browse',
                    onPressed: () => Navigator.of(context).pushNamed('/browse-rooms'),
                    color: const Color(0xFFFFD700),
                  ),
                  const SizedBox(width: 16),
                  _buildQuickActionButton(
                    icon: Icons.favorite,
                    label: 'Speed Date',
                    onPressed: () => Navigator.of(context).pushNamed('/speed-dating-lobby'),
                    color: const Color(0xFF9C27B0),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: _glowAnimation.value,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(label),
            style: ElevatedButton.styleFrom(
              backgroundColor: color.withValues(alpha: 0.2),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: color.withValues(alpha: 0.5)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchSection(WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) => ref.read(searchQueryProvider.notifier).update(value),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'ðŸ” Search live rooms, DJs, or genres...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFFFFD700)),
          suffixIcon: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value * 0.3 + 0.7,
                child: const Icon(Icons.music_note, color: Color(0xFFFF4C4C)),
              );
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFFFD700)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFFFD700)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFFF4C4C), width: 2),
          ),
          filled: true,
          fillColor: const Color(0xFF2A2A3E).withValues(alpha: 0.9),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildRoomsSection(
    AsyncValue<List<dynamic>> roomsAsync,
    String searchQuery,
    WidgetRef ref,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1E1E2F).withValues(alpha: 0.8),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const GlowText(
                  text: 'ðŸ”¥ LIVE NOW',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF4C4C),
                  glowColor: Color(0xFFFF4C4C),
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value * 0.2 + 0.8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4C4C).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFF4C4C)),
                        ),
                        child: roomsAsync.maybeWhen(
                          data: (rooms) => Text(
                            '${rooms.length} rooms',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: roomsAsync.when(
              data: (rooms) {
                final filteredRooms = rooms.where((room) {
                  return room.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                      room.description.toLowerCase().contains(searchQuery.toLowerCase());
                }).toList();

                if (filteredRooms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value * 0.1 + 0.9,
                              child: const Icon(
                                Icons.music_off,
                                size: 64,
                                color: Color(0xFFFF4C4C),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        const GlowText(
                          text: 'No live rooms found',
                          fontSize: 18,
                          color: Colors.white70,
                          glowColor: Color(0xFFFF4C4C),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to go live! ðŸŽ¤',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredRooms.length,
                  itemBuilder: (context, index) {
                    final room = filteredRooms[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: LiveRoomCard(
                        roomName: room.name,
                        djName: room.hostName,
                        viewerCount: room.viewerCount,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AuthGuard(child: VoiceRoomPage(room: room)),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const FullScreenLoader(
                message: 'Loading live rooms...',
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _pulseAnimation.value * 0.1,
                          child: const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Color(0xFFFF4C4C),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const GlowText(
                      text: 'Failed to load rooms',
                      fontSize: 18,
                      color: Color(0xFFFF4C4C),
                      glowColor: Color(0xFFFF4C4C),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    NeonButton(
                      onPressed: () => ref.invalidate(roomsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value * 0.1 + 0.9,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF4C4C), Color(0xFFFFD700)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4C4C).withValues(alpha: 0.6),
                  blurRadius: 20 * _pulseAnimation.value,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: FloatingActionButton(
              key: const Key('go-live-btn'),
              onPressed: () => Navigator.of(context).pushNamed('/go-live'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              tooltip: 'Go Live',
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        );
      },
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFFFD700), width: 2),
        ),
        title: const GlowText(
          text: 'Sign Out?',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFFD700),
          glowColor: Color(0xFFFF4C4C),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFFFFD700)),
            ),
          ),
          TextButton(
            onPressed: () async {
              final authService = ref.read(authServiceProvider);
              await authService.signOut();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Color(0xFFFF4C4C)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF2A2A3E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFFFD700), width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GlowText(
                text: 'Advanced Search',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFD700),
                glowColor: Color(0xFFFF4C4C),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => ref.read(searchQueryProvider.notifier).update(value),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search by name, DJ, or genre...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFFFD700)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFFD700)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFFD700)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFF4C4C), width: 2),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1E1E2F),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Close',
                      style: TextStyle(color: Color(0xFFFFD700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final double animationValue;

  ParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF4C4C).withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final random = math.Random(42); // Fixed seed for consistent pattern

    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = (random.nextDouble() * 3 + 1) * animationValue;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
