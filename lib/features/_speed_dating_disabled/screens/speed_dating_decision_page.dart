import 'dart:js_util' as js_util;
import 'package:mixmingle/helpers/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/design_constants.dart';
// TEMP DISABLED: import '../../../services/speed_dating_service.dart';
import '../../../providers/auth_providers.dart';

/// Speed Dating Decision Page
/// Post-call decision screen: Reconnect / Exchange Info / Pass
class SpeedDatingDecisionPage extends ConsumerStatefulWidget {
  final String sessionId;
  final String matchedUserId;
  final String matchedUserName;
  final String? matchedUserPhoto;

  const SpeedDatingDecisionPage({
    required this.sessionId,
    required this.matchedUserId,
    required this.matchedUserName,
    this.matchedUserPhoto,
    super.key,
  });

  @override
  ConsumerState<SpeedDatingDecisionPage> createState() => _SpeedDatingDecisionPageState();
}

class _SpeedDatingDecisionPageState extends ConsumerState<SpeedDatingDecisionPage>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  bool _isSubmitting = false;
  bool _hasDecided = false;
  String? _decision;
  bool? _mutualMatch;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _submitDecision(String decision) async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _decision = decision;
    });

    final user = ref.read(currentUserProvider).value;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Not signed in')),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    final service = SpeedDatingService();
    final result = await service.submitDecision(
      widget.sessionId,
      user.id,
      widget.matchedUserId,
      decision == 'like',
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
      _hasDecided = true;
      _mutualMatch = false; // Stub: always false since feature is disabled
    });

    // Show result, then navigate
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _hasDecided ? _buildResultView() : _buildDecisionView(),
        ),
      ),
    );
  }

  Widget _buildDecisionView() {
    return Column(
      children: [
        const Spacer(),

        // Profile photo
        CircleAvatar(
          radius: 80,
          backgroundColor: DesignColors.accent.withValues(alpha: 0.3),
          backgroundImage: widget.matchedUserPhoto != null
              ? NetworkImage(widget.matchedUserPhoto!)
              : null,
          child: widget.matchedUserPhoto == null
              ? const Icon(Icons.person, size: 80, color: Colors.white)
              : null,
        ),

        const SizedBox(height: 24),

        // Name
        Text(
          widget.matchedUserName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'How was your conversation?',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 16,
          ),
        ),

        const SizedBox(height: 48),

        // Decision buttons
        _buildDecisionButton(
          icon: Icons.favorite,
          label: 'Exchange Info',
          description: 'Share contact details if mutual',
          color: Colors.pink,
          decision: 'exchange',
        ),

        const SizedBox(height: 16),

        _buildDecisionButton(
          icon: Icons.refresh,
          label: 'Reconnect Later',
          description: 'Add to your connections',
          color: DesignColors.accent,
          decision: 'reconnect',
        ),

        const SizedBox(height: 16),

        _buildDecisionButton(
          icon: Icons.close,
          label: 'Pass',
          description: 'Move on to the next match',
          color: Colors.grey,
          decision: 'pass',
        ),

        const Spacer(flex: 2),

        // Privacy note
        Text(
          'Your decision is private until both parties respond',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDecisionButton({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required String decision,
  }) {
    final isSelected = _decision == decision;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSubmitting ? null : () => _submitDecision(decision),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.2),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected && _isSubmitting)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultView() {
    final isMutual = _mutualMatch == true && _decision != 'pass';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _bounceAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: isMutual ? _bounceAnimation.value : 1.0,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      isMutual
                          ? Colors.pink.withValues(alpha: 0.8)
                          : Colors.blue.withValues(alpha: 0.8),
                      isMutual
                          ? Colors.pink.withValues(alpha: 0.2)
                          : Colors.blue.withValues(alpha: 0.2),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isMutual ? Colors.pink : Colors.blue)
                          .withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  isMutual ? Icons.favorite : Icons.check,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 40),

        Text(
          isMutual ? "It's a Match! ðŸ’•" : 'Decision Submitted!',
          style: TextStyle(
            color: isMutual ? Colors.pink : Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        if (isMutual)
          Column(
            children: [
              Text(
                'You and ${widget.matchedUserName} both want to connect!',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to chat with this user
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  // In production: Navigate to chat screen with matchedUserId
                },
                icon: const Icon(Icons.chat),
                label: const Text('Start Chatting'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              Text(
                _decision == 'pass'
                    ? "No worries, there are more matches waiting!"
                    : "We'll let you know if they feel the same way.",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                'Returning to lobby...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
