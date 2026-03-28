import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mixvy/core/services/first_run_service.dart';
import 'package:mixvy/services/analytics_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  final pages = const [
    _OnboardPage(
      title: "Welcome to MIXVY",
      subtitle: "Lifestyle. Community. Vibes.",
    ),
    _OnboardPage(
      title: "Connect",
      subtitle: "Meet people who match your energy.",
    ),
    _OnboardPage(
      title: "Experience",
      subtitle: "Events, rooms, and exclusive spaces.",
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _index = i),
            children: pages,
          ),
          Positioned(
            top: 56,
            right: 20,
            child: TextButton(
              onPressed: _index == pages.length - 1
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
            bottom: 112,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _index == i ? 26 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _index == i
                        ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () async {
                if (_index == pages.length - 1) {
                  final router = GoRouter.of(context);
                  await FirstRunService.markOnboardingSeen();
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
              child: Text(_index == pages.length - 1 ? "Get Started" : "Next"),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  final String title;
  final String subtitle;

  const _OnboardPage({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.75),
                  theme.colorScheme.secondary.withValues(alpha: 0.75),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.bolt, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 24),
          Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
