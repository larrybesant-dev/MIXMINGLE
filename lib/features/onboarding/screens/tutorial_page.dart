import 'package:flutter/material.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../shared/widgets/club_background.dart';
import '../../../shared/widgets/neon_components.dart';

/// Tutorial Walkthrough - Step 4 of onboarding
/// 4 swipeable cards explaining app features
class TutorialPage extends StatefulWidget {
  final VoidCallback onComplete;

  const TutorialPage({super.key, required this.onComplete});

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<TutorialCard> _cards = const [
    TutorialCard(
      icon: Icons.video_call,
      title: 'LIVE VIDEO ROOMS',
      description:
          'Join themed video rooms and chat with people who share your vibe. No matching required.',
      color: DesignColors.accent,
    ),
    TutorialCard(
      icon: Icons.speed,
      title: 'VIDEO SPEED DATING',
      description:
          '5-minute video dates with matched singles. Real conversations, instant chemistry.',
      color: DesignColors.gold,
    ),
    TutorialCard(
      icon: Icons.favorite,
      title: 'INSTANT MATCHES',
      description:
          'Like someone? Skip the awkward DMs. Start a live video chat right away.',
      color: Color(0xFFFF1493),
    ),
    TutorialCard(
      icon: Icons.electric_bolt,
      title: 'ALWAYS LIVE',
      description:
          'No endless swiping. No ghosting. Real people, real time. Start chatting now.',
      color: Color(0xFF00D9FF),
    ),
  ];

  void _nextPage() {
    if (_currentPage < _cards.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }

  void _skipTutorial() {
    widget.onComplete();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            TextButton(
              onPressed: _skipTutorial,
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: DesignColors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    return _buildCardPage(_cards[index]);
                  },
                ),
              ),

              // Page indicators
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _cards.length,
                    (index) => _buildPageIndicator(index),
                  ),
                ),
              ),

              // Next/Done button
              Padding(
                padding: const EdgeInsets.all(24),
                child: NeonButton(
                  label: _currentPage == _cards.length - 1
                      ? 'GET STARTED'
                      : 'NEXT',
                  onPressed: _nextPage,
                  glowColor: _cards[_currentPage].color,
                  height: 54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardPage(TutorialCard card) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  card.color.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: card.color.withOpacity(0.5),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Icon(
              card.icon,
              size: 60,
              color: card.color,
            ),
          ),
          const SizedBox(height: 48),

          // Title
          NeonText(
            card.title,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            textColor: DesignColors.white,
            glowColor: card.color,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Description
          Text(
            card.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: DesignColors.white,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    final isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: isActive
            ? _cards[_currentPage].color
            : DesignColors.white.withOpacity(0.3),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: _cards[_currentPage].color.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
    );
  }
}

class TutorialCard {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const TutorialCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
