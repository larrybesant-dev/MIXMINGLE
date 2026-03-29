import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mixvy/core/services/first_run_service.dart';
import 'package:mixvy/presentation/providers/app_settings_provider.dart';
import 'package:mixvy/services/analytics_service.dart';

class _OnboardScene {
  const _OnboardScene({
    required this.kicker,
    required this.title,
    required this.subtitle,
    required this.hypeLine,
    required this.statValue,
    required this.statLabel,
    required this.perks,
    required this.icon,
    required this.glowColor,
  });

  final String kicker;
  final String title;
  final String subtitle;
  final String hypeLine;
  final String statValue;
  final String statLabel;
  final List<String> perks;
  final IconData icon;
  final Color glowColor;
}

class _OnboardingTheme {
  const _OnboardingTheme({
    required this.name,
    required this.accents,
    required this.background,
    required this.skipSurface,
    required this.cardSurface,
    required this.chipSurface,
    required this.bottomGlow,
    required this.extraOrb,
  });

  final String name;
  final List<Color> accents;
  final List<Color> background;
  final Color skipSurface;
  final Color cardSurface;
  final Color chipSurface;
  final Color bottomGlow;
  final Color extraOrb;
}

abstract final class _OnboardingThemes {
  static const minimalLuxe = _OnboardingTheme(
    name: 'Minimal Luxe',
    accents: [Color(0xFFD7A03B), Color(0xFF9CC3C9), Color(0xFFE07A5F)],
    background: [Color(0xFF1A1712), Color(0xFF10161D), Color(0xFF0C1218)],
    skipSurface: Color(0xFF1A2029),
    cardSurface: Color(0xFF121A24),
    chipSurface: Color(0xFF182230),
    bottomGlow: Color(0xFFD7A03B),
    extraOrb: Color(0xFF9CC3C9),
  );

  static const tropicalSunset = _OnboardingTheme(
    name: 'Tropical Sunset',
    accents: [Color(0xFFFF7A18), Color(0xFF1FCF9A), Color(0xFFFF4E72)],
    background: [Color(0xFF140A05), Color(0xFF0A1424), Color(0xFF041816)],
    skipSurface: Color(0xFF181E2C),
    cardSurface: Color(0xFF111A2A),
    chipSurface: Color(0xFF122034),
    bottomGlow: Color(0xFFFFC94D),
    extraOrb: Color(0xFF2CE6D1),
  );

  static const electricRetro = _OnboardingTheme(
    name: 'Electric Retro',
    accents: [Color(0xFF00D1B2), Color(0xFFFF5C35), Color(0xFFF2E94E)],
    background: [Color(0xFF120C1F), Color(0xFF171334), Color(0xFF1A1B1E)],
    skipSurface: Color(0xFF241F3A),
    cardSurface: Color(0xFF1D2138),
    chipSurface: Color(0xFF242944),
    bottomGlow: Color(0xFFFF5C35),
    extraOrb: Color(0xFF00D1B2),
  );
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;
  int _themeIndex = 1;
  bool _acceptedLegal = false;

  final List<_OnboardingTheme> _themeOptions = const [
    _OnboardingThemes.minimalLuxe,
    _OnboardingThemes.tropicalSunset,
    _OnboardingThemes.electricRetro,
  ];

  _OnboardingTheme get _theme => _themeOptions[_themeIndex];

  void _cycleTheme(int direction) {
    setState(() {
      _themeIndex = (_themeIndex + direction + _themeOptions.length) % _themeOptions.length;
    });
  }

  List<_OnboardScene> get _pages => [
    _OnboardScene(
      kicker: 'Live Rooms',
      title: 'Step Into The Hottest Rooms',
      subtitle: 'Drop into high-energy sets, discover rising DJs, and feel the crowd move in real time.',
      hypeLine: 'The dance floor is already moving. You are one tap away.',
      statValue: '12K+',
      statLabel: 'listeners online after 9PM',
      perks: ['Live DJ drops', 'Instant reactions', 'Zero awkward silence'],
      icon: Icons.graphic_eq_rounded,
      glowColor: _theme.accents[0],
    ),
    _OnboardScene(
      kicker: 'Community',
      title: 'Find Your Night Crew Fast',
      subtitle: 'Chat, react, and connect with people who match your exact party energy.',
      hypeLine: 'No small talk mode. Just good vibes and real connection.',
      statValue: '4.8★',
      statLabel: 'average room vibe rating',
      perks: ['Real-time chat', 'Host shoutouts', 'Friends in every room'],
      icon: Icons.groups_3_rounded,
      glowColor: _theme.accents[1],
    ),
    _OnboardScene(
      kicker: 'Creator Mode',
      title: 'Launch Your Own Party',
      subtitle: 'Start a room in seconds, build your audience, and turn tonight into your moment.',
      hypeLine: 'Your stage is ready. Hit go live and own the night.',
      statValue: '< 30s',
      statLabel: 'to start your first room',
      perks: ['Quick room setup', 'Creator badges', 'Momentum analytics'],
      icon: Icons.rocket_launch_rounded,
      glowColor: _theme.accents[2],
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _index == _pages.length - 1;
    final canContinue = !isLastPage || _acceptedLegal;

    return Scaffold(
      backgroundColor: _theme.background[1],
      body: Stack(
        children: [
          _NightBackdrop(index: _index, theme: _theme),
          PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _index = i),
            children: _pages.map((scene) => _OnboardPage(scene: scene, theme: _theme)).toList(growable: false),
          ),
          Positioned(
            top: 42,
            left: 16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _theme.cardSurface.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Previous theme',
                    onPressed: () => _cycleTheme(-1),
                    icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                  ),
                  Text(
                    _theme.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next theme',
                    onPressed: () => _cycleTheme(1),
                    icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 44,
            right: 20,
            child: FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: _theme.skipSurface.withValues(alpha: 0.72),
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
              onPressed: _index == _pages.length - 1
                  ? null
                  : () async {
                      final router = GoRouter.of(context);
                      await FirstRunService.markOnboardingSeen();
                      if (!mounted) return;
                      router.go('/login');
                    },
              child: const Text('Skip'),
            ),
          ),
          Positioned(
            bottom: 124,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _index == i ? 26 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _index == i ? Colors.white : Colors.white.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: _index == i
                        ? [
                            BoxShadow(
                              color: _pages[_index].glowColor.withValues(alpha: 0.85),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ),
          ),
          if (isLastPage)
            Positioned(
              bottom: 88,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _acceptedLegal,
                      activeColor: _pages[_index].glowColor,
                      side: const BorderSide(color: Colors.white70),
                      onChanged: (value) => setState(() => _acceptedLegal = value ?? false),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'I agree to the Terms of Service and Privacy Policy.',
                            style: TextStyle(color: Colors.white),
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: () => context.go('/legal/terms'),
                                child: const Text('Terms'),
                              ),
                              TextButton(
                                onPressed: () => context.go('/legal/privacy'),
                                child: const Text('Privacy'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 28,
            left: 20,
            right: 20,
            child: _NeonCtaButton(
              enabled: canContinue,
              color: _pages[_index].glowColor,
              label: isLastPage ? 'JOIN THE PARTY' : 'KEEP THE VIBE',
              onPressed: () async {
                if (isLastPage) {
                  final router = GoRouter.of(context);
                  await FirstRunService.markOnboardingSeen();
                  await ref.read(appSettingsControllerProvider.notifier).acceptCurrentLegal();
                  await AnalyticsService().logEvent('onboarding_complete');
                  if (!mounted) return;
                  router.go('/');
                } else {
                  _controller.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NightBackdrop extends StatelessWidget {
  const _NightBackdrop({required this.index, required this.theme});

  final int index;
  final _OnboardingTheme theme;

  @override
  Widget build(BuildContext context) {
    final glow = theme.accents[index % theme.accents.length];

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: theme.background,
            ),
          ),
        ),
        Positioned(
          top: -120,
          left: -80,
          child: _GlowOrb(size: 280, color: glow.withValues(alpha: 0.3)),
        ),
        Positioned(
          bottom: -140,
          right: -90,
          child: _GlowOrb(size: 320, color: theme.bottomGlow.withValues(alpha: 0.2)),
        ),
        Positioned(
          top: 160,
          right: -110,
          child: _GlowOrb(size: 220, color: theme.extraOrb.withValues(alpha: 0.12)),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 80,
            spreadRadius: 18,
          ),
        ],
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  final _OnboardScene scene;
  final _OnboardingTheme theme;

  const _OnboardPage({
    required this.scene,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 118, 22, 170),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 288),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: scene.glowColor.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: scene.glowColor.withValues(alpha: 0.65)),
                  ),
                  child: Text(
                    scene.kicker.toUpperCase(),
                    style: TextStyle(
                      color: scene.glowColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  scene.title,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.02,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  scene.subtitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  scene.hypeLine,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: scene.glowColor.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 620),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.cardSurface.withValues(alpha: 0.76),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                    boxShadow: [
                      BoxShadow(
                        color: scene.glowColor.withValues(alpha: 0.28),
                        blurRadius: 26,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scene.glowColor.withValues(alpha: 0.26),
                          border: Border.all(color: scene.glowColor.withValues(alpha: 0.75)),
                        ),
                        child: Icon(scene.icon, color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tonight on MixVy',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${scene.statValue} ${scene.statLabel}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: scene.perks
                      .map(
                        (perk) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.chipSurface.withValues(alpha: 0.68),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: scene.glowColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            perk,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NeonCtaButton extends StatelessWidget {
  const _NeonCtaButton({
    required this.label,
    required this.color,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final bool enabled;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final buttonColor = enabled ? color : Colors.white30;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            buttonColor,
            Color.alphaBlend(const Color(0x88110A23), buttonColor),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: enabled ? () => onPressed() : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
