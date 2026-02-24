import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../shared/providers/all_providers.dart';

// ---------------------------------------------------------------------------
// Data model for a single tour step
// ---------------------------------------------------------------------------

class _TourStep {
  const _TourStep({
    required this.emoji,
    required this.title,
    required this.body,
    required this.ctaIcon,
  });

  final String emoji;
  final String title;
  final String body;
  final IconData ctaIcon;
}

const List<_TourStep> _steps = [
  _TourStep(
    emoji: '👋',
    title: 'Welcome to Mix\u00a0& Mingle!',
    body:
        'You\'re in. This is a live video social platform where real '
        'conversations happen — no filters, no scripts, just vibes.',
    ctaIcon: Icons.waving_hand,
  ),
  _TourStep(
    emoji: '🎥',
    title: 'Jump into a Live Room',
    body:
        'Browse hundreds of live rooms by topic or mood. '
        'Tap the Rooms tab to watch, join the stage, or host your own show.',
    ctaIcon: Icons.videocam_outlined,
  ),
  _TourStep(
    emoji: '💬',
    title: 'Connect & Chat',
    body:
        'Follow people you vibe with, send DMs, and link up in group chats. '
        'Tap the Chats tab to start a conversation.',
    ctaIcon: Icons.chat_bubble_outline,
  ),
  _TourStep(
    emoji: '🚀',
    title: 'You\'re All Set',
    body:
        'Your profile is live. Go explore rooms, find your people, '
        'and make some noise. The stage is yours.',
    ctaIcon: Icons.rocket_launch_outlined,
  ),
];

// ---------------------------------------------------------------------------
// Provider to track overlay visibility for the current session
// ---------------------------------------------------------------------------

/// Notifier that controls whether the first-run welcome overlay is visible.
class WelcomeOverlayNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// Show the welcome overlay.
  void show() => state = true;

  /// Hide the welcome overlay.
  void hide() => state = false;
}

/// `true` while the welcome overlay is being displayed.
/// Activated by [HomePageElectric] once we confirm it’s a first-time user.
final welcomeOverlayVisibleProvider =
    NotifierProvider<WelcomeOverlayNotifier, bool>(
  WelcomeOverlayNotifier.new,
);

// ---------------------------------------------------------------------------
// Welcome overlay widget
// ---------------------------------------------------------------------------

/// Full-screen first-run welcome tour.
///
/// Shows [_steps] sequentially with a neon-themed card design.
/// When the user taps "Let's Go!" on the final step, the overlay marks
/// [UserProfile.onboardingComplete] as `true` in Firestore and collapses.
class OnboardingWelcomeOverlay extends ConsumerStatefulWidget {
  const OnboardingWelcomeOverlay({super.key});

  @override
  ConsumerState<OnboardingWelcomeOverlay> createState() =>
      _OnboardingWelcomeOverlayState();
}

class _OnboardingWelcomeOverlayState
    extends ConsumerState<OnboardingWelcomeOverlay>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _completing = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  bool get _isLastStep => _currentStep == _steps.length - 1;

  void _next() {
    if (_isLastStep) {
      _complete();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skip() => _complete();

  Future<void> _complete() async {
    if (_completing) return;
    setState(() => _completing = true);

    // Mark onboardingComplete = true in Firestore.
    try {
      final profile = await ref.read(currentUserProfileProvider.future);
      if (profile != null) {
        await ref
            .read(profileControllerProvider)
            .updateProfile(profile.copyWith(onboardingComplete: true));
      }
    } catch (_) {
      // Non-fatal — the overlay simply closes. The flag will be set next time.
    }

    if (mounted) {
      await _fadeController.reverse();
      if (mounted) {
        ref.read(welcomeOverlayVisibleProvider.notifier).hide();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        color: Colors.black.withValues(alpha: 0.85),
        child: SafeArea(
          child: Column(
            children: [
              // ── Skip button ────────────────────────────────────────────
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _skip,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: DesignColors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              // ── Step pages ────────────────────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentStep = i),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _steps.length,
                  itemBuilder: (_, index) => _StepCard(step: _steps[index]),
                ),
              ),

              // ── Dot indicator ─────────────────────────────────────────
              _DotIndicator(
                count: _steps.length,
                current: _currentStep,
              ),

              const SizedBox(height: 24),

              // ── Primary CTA ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _completing ? null : _next,
                    icon: _completing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(_isLastStep
                            ? Icons.rocket_launch_outlined
                            : Icons.arrow_forward_rounded),
                    label: Text(
                      _completing
                          ? 'Saving…'
                          : _isLastStep
                              ? 'Let\'s Go!'
                              : 'Next',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: DesignColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step card
// ---------------------------------------------------------------------------

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step});

  final _TourStep step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji hero
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: DesignColors.accent.withValues(alpha: 0.6),
                width: 2,
              ),
              color: DesignColors.accent.withValues(alpha: 0.12),
            ),
            alignment: Alignment.center,
            child: Text(
              step.emoji,
              style: const TextStyle(fontSize: 52),
            ),
          ),

          const SizedBox(height: 32),

          // Title
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 20),

          // Body
          Text(
            step.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dot indicator
// ---------------------------------------------------------------------------

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive
                ? DesignColors.accent
                : Colors.white.withValues(alpha: 0.3),
          ),
        );
      }),
    );
  }
}
