import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../../providers/providers.dart';
import '../../providers/room_providers.dart';
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
  late AnimationController _floatController;
  late AnimationController _rotateController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat(reverse: true);

    _glowController = AnimationController(duration: const Duration(seconds: 3), vsync: this)..repeat(reverse: true);

    _floatController = AnimationController(duration: const Duration(seconds: 4), vsync: this)..repeat(reverse: true);

    _rotateController = AnimationController(duration: const Duration(seconds: 8), vsync: this)..repeat();

    _scaleController = AnimationController(duration: const Duration(seconds: 6), vsync: this)..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _glowAnimation = Tween<double>(
      begin: 8.0,
      end: 25.0,
    ).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));

    _floatAnimation = Tween<double>(
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(parent: _rotateController, curve: Curves.linear));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _floatController.dispose();
    _rotateController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(roomsProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Dynamic background with multiple layers
          _buildDynamicBackground(),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Spectacular header
                _buildSpectacularHeader(),

                // Action buttons row
                _buildActionButtonsRow(),

                // Search section
                _buildEnhancedSearchSection(ref),

                // Live rooms showcase
                Expanded(child: _buildSpectacularRoomsSection(roomsAsync, searchQuery, ref)),
              ],
            ),
          ),

          // Floating elements
          _buildFloatingElements(),

          // Overlay effects
          _buildOverlayEffects(),
        ],
      ),
    );
  }

  Widget _buildDynamicBackground() {
    return Stack(
      children: [
        // Base gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0A0A0F), Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F0F23)],
            ),
          ),
        ),

        // Animated geometric shapes
        AnimatedBuilder(
          animation: Listenable.merge([_rotateAnimation, _scaleAnimation]),
          builder: (context, child) {
            return CustomPaint(
              painter: GeometricShapesPainter(_rotateAnimation.value, _scaleAnimation.value),
              size: Size.infinite,
            );
          },
        ),

        // Laser beam effects
        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return CustomPaint(painter: LaserBeamsPainter(_glowAnimation.value), size: Size.infinite);
          },
        ),

        // Particle field
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return CustomPaint(painter: EnhancedParticlePainter(_pulseAnimation.value), size: Size.infinite);
          },
        ),
      ],
    );
  }

  Widget _buildSpectacularHeader() {
    return Container(
      height: 180,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated background rings
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: List.generate(3, (index) {
                  final delay = index * 0.3;
                  final scale = (_pulseAnimation.value + delay).clamp(0.5, 2.0);
                  return Container(
                    width: 120 + (index * 40),
                    height: 120 + (index * 40),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Color.lerp(
                          const Color(0xFFFF4C4C),
                          const Color(0xFFFFD700),
                          index / 2,
                        )!
                            .withValues(alpha: 0.3 - (index * 0.1)),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color.lerp(
                            const Color(0xFFFF4C4C),
                            const Color(0xFFFFD700),
                            index / 2,
                          )!
                              .withValues(alpha: 0.2),
                          blurRadius: 20 * scale,
                          spreadRadius: 5 * scale,
                        ),
                      ],
                    ),
                  );
                }),
              );
            },
          ),

          // Main title with dramatic effects
          AnimatedBuilder(
            animation: Listenable.merge([_pulseAnimation, _floatAnimation]),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatAnimation.value * 0.5),
                child: Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Main title
                      const GlowText(
                        text: 'MIX & MINGLE',
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD700),
                        glowColor: Color(0xFFFF4C4C),
                        glowRadius: 15,
                      ),

                      const SizedBox(height: 8),

                      // Subtitle with shimmer effect
                      AnimatedBuilder(
                        animation: _glowAnimation,
                        builder: (context, child) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  const Color(0xFFFFD700).withValues(alpha: 0.1),
                                  Colors.transparent,
                                ],
                              ),
                              border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5), width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                                  blurRadius: _glowAnimation.value,
                                ),
                              ],
                            ),
                            child: const Text(
                              'THE ULTIMATE CLUB EXPERIENCE',
                              style: TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Corner decorations
          Positioned(
            top: 10,
            left: 10,
            child: AnimatedBuilder(
              animation: _rotateAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotateAnimation.value,
                  child: const Icon(Icons.star, color: Color(0xFFFFD700), size: 20),
                );
              },
            ),
          ),

          Positioned(
            top: 10,
            right: 10,
            child: AnimatedBuilder(
              animation: _rotateAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: -_rotateAnimation.value,
                  child: const Icon(Icons.music_note, color: Color(0xFFFF4C4C), size: 20),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsRow() {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildSpectacularActionButton(
            icon: Icons.live_tv,
            label: 'GO LIVE',
            color: const Color(0xFFFF4C4C),
            onPressed: () => Navigator.of(context).pushNamed('/go-live'),
          ),
          const SizedBox(width: 12),
          _buildSpectacularActionButton(
            icon: Icons.explore,
            label: 'BROWSE',
            color: const Color(0xFFFFD700),
            onPressed: () => Navigator.of(context).pushNamed('/browse-rooms'),
          ),
          const SizedBox(width: 12),
          _buildSpectacularActionButton(
            icon: Icons.favorite,
            label: 'SPEED DATE',
            color: const Color(0xFF9C27B0),
            onPressed: () => Navigator.of(context).pushNamed('/speed-dating-lobby'),
          ),
        ],
      ),
    );
  }

  Widget _buildSpectacularActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _glowAnimation]),
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.1)]),
              border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: _glowAnimation.value, spreadRadius: 2),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: _pulseAnimation.value * 0.2 + 0.8,
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedSearchSection(WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [const Color(0xFF2A2A3E).withValues(alpha: 0.8), const Color(0xFF1E1E2F).withValues(alpha: 0.6)],
        ),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4), width: 1),
        boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.2), blurRadius: 15, spreadRadius: 1)],
      ),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return TextField(
            onChanged: (value) => ref.read(searchQueryProvider.notifier).update(value),
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'ðŸ” Discover live rooms, DJs & vibes...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
              prefixIcon: Transform.scale(
                scale: _pulseAnimation.value * 0.1 + 0.9,
                child: const Icon(Icons.search, color: Color(0xFFFFD700), size: 20),
              ),
              suffixIcon: AnimatedBuilder(
                animation: _rotateAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotateAnimation.value,
                    child: const Icon(Icons.music_note, color: Color(0xFFFF4C4C), size: 18),
                  );
                },
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpectacularRoomsSection(AsyncValue<List<dynamic>> roomsAsync, String searchQuery, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [const Color(0xFF1E1E2F).withValues(alpha: 0.9), const Color(0xFF16213E).withValues(alpha: 0.7)],
        ),
        border: Border.all(color: const Color(0xFFFF4C4C).withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          // Spectacular header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF4C4C).withValues(alpha: 0.2),
                  const Color(0xFFFFD700).withValues(alpha: 0.1),
                ],
              ),
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value * 0.2 + 0.8,
                      child: const Text('ðŸ”¥', style: TextStyle(fontSize: 24)),
                    );
                  },
                ),
                const SizedBox(width: 8),
                const GlowText(
                  text: 'LIVE NOW',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF4C4C),
                  glowColor: Color(0xFFFF4C4C),
                  glowRadius: 8,
                ),
                const Spacer(),
                roomsAsync.maybeWhen(
                  data: (rooms) => AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4C4C).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: const Color(0xFFFF4C4C).withValues(alpha: 0.5), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF4C4C).withValues(alpha: 0.3),
                              blurRadius: _glowAnimation.value * 0.5,
                            ),
                          ],
                        ),
                        child: Text(
                          '${rooms.length} ROOMS',
                          style: const TextStyle(
                            color: Color(0xFFFF4C4C),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      );
                    },
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Rooms content
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
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value * 0.3 + 0.7,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFFF4C4C).withValues(alpha: 0.3),
                                      const Color(0xFFFFD700).withValues(alpha: 0.2),
                                    ],
                                  ),
                                  border: Border.all(color: const Color(0xFFFF4C4C).withValues(alpha: 0.5), width: 2),
                                ),
                                child: const Icon(Icons.music_off, color: Color(0xFFFF4C4C), size: 40),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        const GlowText(
                          text: 'No live rooms found',
                          fontSize: 20,
                          color: Colors.white70,
                          glowColor: Color(0xFFFF4C4C),
                          glowRadius: 5,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to start the party! ðŸŽ¶',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredRooms.length,
                  itemBuilder: (context, index) {
                    final room = filteredRooms[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF2A2A3E).withValues(alpha: 0.8),
                            const Color(0xFF1E1E2F).withValues(alpha: 0.6),
                          ],
                        ),
                        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.2), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF4C4C).withValues(alpha: 0.1),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
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
              loading: () => const FullScreenLoader(message: 'Loading the party...'),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _rotateAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotateAnimation.value,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFFF4C4C).withValues(alpha: 0.3),
                                  const Color(0xFFFFD700).withValues(alpha: 0.2),
                                ],
                              ),
                            ),
                            child: const Icon(Icons.error_outline, color: Color(0xFFFF4C4C), size: 30),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    const GlowText(
                      text: 'Connection lost',
                      fontSize: 20,
                      color: Color(0xFFFF4C4C),
                      glowColor: Color(0xFFFF4C4C),
                      glowRadius: 5,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    NeonButton(onPressed: () => ref.invalidate(roomsProvider), child: const Text('RECONNECT')),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingElements() {
    return Stack(
      children: [
        // Floating action button
        Positioned(
          bottom: 24,
          right: 24,
          child: AnimatedBuilder(
            animation: Listenable.merge([_pulseAnimation, _glowAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value * 0.2 + 0.8,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [const Color(0xFFFF4C4C), const Color(0xFFFFD700)]),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF4C4C).withValues(alpha: 0.6),
                        blurRadius: _glowAnimation.value,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    onPressed: () => Navigator.of(context).pushNamed('/go-live'),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    tooltip: 'Go Live - Start the Party!',
                    child: const Icon(Icons.add, color: Colors.white, size: 32),
                  ),
                ),
              );
            },
          ),
        ),

        // Floating music notes
        ...List.generate(3, (index) {
          return Positioned(
            top: 100 + (index * 150.0),
            right: 20 + (index * 30.0),
            child: AnimatedBuilder(
              animation: Listenable.merge([_floatAnimation, _rotateAnimation]),
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatAnimation.value * (0.5 + index * 0.3)),
                  child: Transform.rotate(
                    angle: _rotateAnimation.value * (1 + index * 0.5),
                    child: Icon(
                      Icons.music_note,
                      color: Color.lerp(
                        const Color(0xFFFF4C4C),
                        const Color(0xFFFFD700),
                        index / 2,
                      )!
                          .withValues(alpha: 0.3),
                      size: 16 + index * 4,
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildOverlayEffects() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: _glowAnimation.value * 0.02, sigmaY: _glowAnimation.value * 0.02),
          child: Container(color: Colors.transparent),
        );
      },
    );
  }
}

class GeometricShapesPainter extends CustomPainter {
  final double rotation;
  final double scale;

  GeometricShapesPainter(this.rotation, this.scale);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw rotating geometric shapes
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.scale(scale);

    // Large circle
    paint.color = const Color(0xFFFF4C4C).withValues(alpha: 0.1);
    canvas.drawCircle(Offset.zero, 200, paint);

    // Medium circle
    paint.color = const Color(0xFFFFD700).withValues(alpha: 0.1);
    canvas.drawCircle(Offset.zero, 150, paint);

    // Small circle
    paint.color = const Color(0xFF9C27B0).withValues(alpha: 0.1);
    canvas.drawCircle(Offset.zero, 100, paint);

    // Hexagon
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi * 2) / 6;
      final x = math.cos(angle) * 80;
      final y = math.sin(angle) * 80;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    paint.color = const Color(0xFFFF4C4C).withValues(alpha: 0.05);
    canvas.drawPath(path, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(GeometricShapesPainter oldDelegate) {
    return oldDelegate.rotation != rotation || oldDelegate.scale != scale;
  }
}

class LaserBeamsPainter extends CustomPainter {
  final double intensity;

  LaserBeamsPainter(this.intensity);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final random = math.Random(42);

    // Draw laser beam effects
    for (int i = 0; i < 8; i++) {
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height * 0.3; // Top third
      final endX = startX + (random.nextDouble() - 0.5) * 200;
      final endY = size.height;

      paint.color = Color.lerp(
        const Color(0xFFFF4C4C),
        const Color(0xFFFFD700),
        random.nextDouble(),
      )!
          .withValues(alpha: intensity * 0.1);

      paint.strokeWidth = 1 + intensity * 0.1;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(LaserBeamsPainter oldDelegate) {
    return oldDelegate.intensity != intensity;
  }
}

class EnhancedParticlePainter extends CustomPainter {
  final double animationValue;

  EnhancedParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(42);

    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final particleSize = (random.nextDouble() * 4 + 1) * animationValue;
      final alpha = (random.nextDouble() * 0.5 + 0.1) * animationValue;

      paint.color = Color.lerp(
        const Color(0xFFFF4C4C),
        const Color(0xFFFFD700),
        random.nextDouble(),
      )!
          .withValues(alpha: alpha);

      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(EnhancedParticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
