/// Early Access Banner Widget
///
/// Displays the current launch phase status with a link to
/// provide feedback during beta phases.
library;

import 'package:flutter/material.dart';
import 'launch_service.dart';
import 'feedback_service.dart';

/// Banner widget showing early access status
class EarlyAccessBanner extends StatelessWidget {
  final LaunchPhase phase;
  final VoidCallback? onFeedbackTap;
  final VoidCallback? onDismiss;
  final bool dismissible;

  const EarlyAccessBanner({
    super.key,
    required this.phase,
    this.onFeedbackTap,
    this.onDismiss,
    this.dismissible = false,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show banner in production
    if (phase == LaunchPhase.production) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getBannerColors(),
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Phase badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getPhaseEmoji(),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getPhaseName(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Message
            Expanded(
              child: Text(
                _getPhaseMessage(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Feedback button
            if (onFeedbackTap != null) ...[
              const SizedBox(width: 8),
              _FeedbackButton(onTap: onFeedbackTap!),
            ],
            // Dismiss button
            if (dismissible && onDismiss != null) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 18),
                onPressed: onDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Color> _getBannerColors() {
    switch (phase) {
      case LaunchPhase.internalAlpha:
        return [const Color(0xFF6B46C1), const Color(0xFF9F7AEA)]; // Purple
      case LaunchPhase.closedBeta:
        return [const Color(0xFF3182CE), const Color(0xFF63B3ED)]; // Blue
      case LaunchPhase.openBeta:
        return [const Color(0xFF38A169), const Color(0xFF68D391)]; // Green
      case LaunchPhase.production:
        return [Colors.transparent, Colors.transparent];
    }
  }

  String _getPhaseEmoji() {
    switch (phase) {
      case LaunchPhase.internalAlpha:
        return '🔬';
      case LaunchPhase.closedBeta:
        return '🧪';
      case LaunchPhase.openBeta:
        return '🚀';
      case LaunchPhase.production:
        return '';
    }
  }

  String _getPhaseName() {
    switch (phase) {
      case LaunchPhase.internalAlpha:
        return 'ALPHA';
      case LaunchPhase.closedBeta:
        return 'BETA';
      case LaunchPhase.openBeta:
        return 'OPEN BETA';
      case LaunchPhase.production:
        return '';
    }
  }

  String _getPhaseMessage() {
    switch (phase) {
      case LaunchPhase.internalAlpha:
        return 'Internal testing - your feedback shapes the app!';
      case LaunchPhase.closedBeta:
        return 'Exclusive beta access - help us improve!';
      case LaunchPhase.openBeta:
        return 'Open beta - try new features, report issues!';
      case LaunchPhase.production:
        return '';
    }
  }
}

/// Feedback button with animation
class _FeedbackButton extends StatefulWidget {
  final VoidCallback onTap;

  const _FeedbackButton({required this.onTap});

  @override
  State<_FeedbackButton> createState() => _FeedbackButtonState();
}

class _FeedbackButtonState extends State<_FeedbackButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.feedback_outlined,
                size: 14,
                color: Colors.grey[800],
              ),
              const SizedBox(width: 4),
              Text(
                'Feedback',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stateful wrapper that loads phase from LaunchService
class EarlyAccessBannerLoader extends StatefulWidget {
  final VoidCallback? onFeedbackTap;
  final VoidCallback? onDismiss;
  final bool dismissible;

  const EarlyAccessBannerLoader({
    super.key,
    this.onFeedbackTap,
    this.onDismiss,
    this.dismissible = false,
  });

  @override
  State<EarlyAccessBannerLoader> createState() => _EarlyAccessBannerLoaderState();
}

class _EarlyAccessBannerLoaderState extends State<EarlyAccessBannerLoader> {
  LaunchPhase _phase = LaunchPhase.production;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPhase();
  }

  Future<void> _loadPhase() async {
    final phase = await LaunchService.instance.getCurrentPhase();
    if (mounted) {
      setState(() {
        _phase = phase;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _phase == LaunchPhase.production) {
      return const SizedBox.shrink();
    }

    return EarlyAccessBanner(
      phase: _phase,
      onFeedbackTap: widget.onFeedbackTap,
      onDismiss: widget.onDismiss,
      dismissible: widget.dismissible,
    );
  }
}

/// Feedback dialog for quick feedback submission
class FeedbackDialog extends StatefulWidget {
  final String userId;
  final String? screenName;

  const FeedbackDialog({
    super.key,
    required this.userId,
    this.screenName,
  });

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  final _controller = TextEditingController();
  FeedbackCategory _selectedCategory = FeedbackCategory.general;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.feedback_outlined, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Send Feedback',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category selector
            const Text(
              'Category',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: FeedbackCategory.values.map((category) {
                final isSelected = category == _selectedCategory;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(category.emoji),
                      const SizedBox(width: 4),
                      Text(category.displayName),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategory = category);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Message input
            const Text(
              'Your feedback',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Tell us what you think...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitFeedback,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Feedback'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitFeedback() async {
    final message = _controller.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await FeedbackService.instance.submitFeedback(
      userId: widget.userId,
      message: message,
      category: _selectedCategory,
      priority: FeedbackService.instance.detectPriority(message),
      screenName: widget.screenName,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);

      if (result.success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Feedback submitted!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Failed to submit')),
        );
      }
    }
  }
}

/// Show feedback dialog helper
Future<void> showFeedbackDialog(
  BuildContext context, {
  required String userId,
  String? screenName,
}) {
  return showDialog(
    context: context,
    builder: (context) => FeedbackDialog(
      userId: userId,
      screenName: screenName,
    ),
  );
}
