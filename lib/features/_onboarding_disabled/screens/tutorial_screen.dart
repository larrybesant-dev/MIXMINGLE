library;
import 'dart:js_util' as js_util;
import 'package:mixmingle/helpers/helpers.dart';
/// Tutorial Screen
///
/// Fifth screen of the onboarding flow.
/// 4-step horizontal pager explaining app features.

import 'package:flutter/material.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../core/theme/neon_colors.dart';
// TEMP DISABLED: import '../models/onboarding_data.dart';
import '../widgets/neon_button.dart';

class TutorialScreen extends StatefulWidget {
  final OnboardingData data;
  final Function(OnboardingData) onUpdate;
  final VoidCallback? onContinue;
  final VoidCallback? onBack;

  const TutorialScreen({
    super.key,
    required this.data,
    required this.onUpdate,
    this.onContinue,
    this.onBack,
  });

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _arrowController;
  late Animation<double> _arrowAnimation;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _arrowController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _arrowAnimation = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _arrowController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _arrowController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < TutorialSteps.steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      widget.onBack?.call();
    }
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    widget.onUpdate(widget.data.copyWith(tutorialStep: page));
  }

  bool get _isLastPage => _currentPage == TutorialSteps.steps.length - 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: TutorialSteps.steps.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final step = TutorialSteps.steps[index];
                  return _buildTutorialPage(step, index);
                },
              ),
            ),

            // Page indicators and navigation
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
            onPressed: _previousPage,
          ),
          Expanded(
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [DesignColors.gold, NeonColors.neonOrange],
                  ).createShader(bounds),
                  child: const Text(
                    'How It Works',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Step 4 of 5',
                  style: TextStyle(
                    color: DesignColors.textGray.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Skip button
          TextButton(
            onPressed: widget.onContinue,
            child: Text(
              'Skip',
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

  Widget _buildTutorialPage(TutorialStep step, int index) {
    final colors = [
      NeonColors.neonOrange,
      NeonColors.neonBlue,
      DesignColors.gold,
      NeonColors.neonOrange,
    ];
    final color = colors[index % colors.length];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon container
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DesignColors.surfaceAlt,
                  border: Border.all(
                    color: color.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    step.icon,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 48),

          // Step number
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Text(
              'STEP ${index + 1}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Title
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [color, DesignColors.white],
            ).createShader(bounds),
            child: Text(
              step.title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            step.description,
            style: TextStyle(
              color: DesignColors.textGray.withValues(alpha: 0.9),
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page indicators
          _buildPageIndicators(),

          const SizedBox(height: 24),

          // Navigation row
          Row(
            children: [
              // Back arrow
              if (_currentPage > 0)
                AnimatedBuilder(
                  animation: _arrowAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(-_arrowAnimation.value, 0),
                      child: child,
                    );
                  },
                  child: IconButton(
                    onPressed: _previousPage,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: NeonColors.neonBlue.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: NeonColors.neonBlue,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: 48),

              const Spacer(),

              // Continue/Next button
              SizedBox(
                width: 180,
                child: OnboardingNeonButton(
                  text: _isLastPage ? 'Got it!' : 'Next',
                  onPressed: _isLastPage ? widget.onContinue : _nextPage,
                  useGoldTrim: _isLastPage,
                  height: 50,
                  icon: _isLastPage ? Icons.check : Icons.arrow_forward,
                ),
              ),

              const Spacer(),

              // Forward arrow (visual only)
              if (!_isLastPage)
                AnimatedBuilder(
                  animation: _arrowAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_arrowAnimation.value, 0),
                      child: child,
                    );
                  },
                  child: IconButton(
                    onPressed: _nextPage,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: NeonColors.neonOrange.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        color: NeonColors.neonOrange,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: 48),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        TutorialSteps.steps.length,
        (index) {
          final isActive = index == _currentPage;
          final isCompleted = index < _currentPage;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 32 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isActive
                  ? NeonColors.neonOrange
                  : isCompleted
                      ? DesignColors.gold.withValues(alpha: 0.7)
                      : DesignColors.textGray.withValues(alpha: 0.3),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: NeonColors.neonOrange.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          );
        },
      ),
    );
  }
}
