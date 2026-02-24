/// Launch Countdown Widget
///
/// Displays countdown to public launch date with days remaining
/// and link to early access/beta signup.
library;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Launch countdown widget showing days remaining until public launch
class LaunchCountdownWidget extends StatefulWidget {
  final VoidCallback? onEarlyAccessTap;
  final bool showEarlyAccessLink;
  final Color? backgroundColor;
  final Color? textColor;

  const LaunchCountdownWidget({
    super.key,
    this.onEarlyAccessTap,
    this.showEarlyAccessLink = true,
    this.backgroundColor,
    this.textColor,
  });

  @override
  State<LaunchCountdownWidget> createState() => _LaunchCountdownWidgetState();
}

class _LaunchCountdownWidgetState extends State<LaunchCountdownWidget>
    with SingleTickerProviderStateMixin {
  DateTime? _launchDate;
  bool _isLoading = true;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadLaunchDate();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadLaunchDate() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('launch')
          .get();

      if (doc.exists && doc.data()?['launchDate'] != null) {
        setState(() {
          _launchDate = (doc.data()!['launchDate'] as Timestamp).toDate();
          _isLoading = false;
        });
      } else {
        // Default to 30 days from now for demo
        setState(() {
          _launchDate = DateTime.now().add(const Duration(days: 30));
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _launchDate = DateTime.now().add(const Duration(days: 30));
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final now = DateTime.now();
    final launchDate = _launchDate ?? now.add(const Duration(days: 30));
    final difference = launchDate.difference(now);
    final daysRemaining = difference.inDays;
    final hoursRemaining = difference.inHours % 24;
    final minutesRemaining = difference.inMinutes % 60;

    final isLaunched = daysRemaining <= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.backgroundColor != null
              ? [widget.backgroundColor!, widget.backgroundColor!.withValues(alpha: 0.8)]
              : isLaunched
                  ? [Colors.green.shade600, Colors.green.shade800]
                  : [Colors.purple.shade600, Colors.indigo.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isLaunched ? Colors.green : Colors.purple).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isLaunched
          ? _buildLaunchedContent(context)
          : _buildCountdownContent(
              context,
              daysRemaining,
              hoursRemaining,
              minutesRemaining,
            ),
    );
  }

  Widget _buildLaunchedContent(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.rocket_launch,
          size: 48,
          color: Colors.white,
        ),
        const SizedBox(height: 12),
        Text(
          'WE\'RE LIVE! ðŸŽ‰',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: widget.textColor ?? Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'MixMingle is now available for everyone!',
          style: TextStyle(
            color: (widget.textColor ?? Colors.white).withValues(alpha: 0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCountdownContent(
    BuildContext context,
    int days,
    int hours,
    int minutes,
  ) {
    return Column(
      children: [
        Text(
          'PUBLIC LAUNCH IN',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: (widget.textColor ?? Colors.white).withValues(alpha: 0.8),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),

        // Animated countdown
        ScaleTransition(
          scale: _pulseAnimation,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CountdownUnit(
                value: days,
                label: 'DAYS',
                textColor: widget.textColor,
              ),
              _CountdownSeparator(textColor: widget.textColor),
              _CountdownUnit(
                value: hours,
                label: 'HRS',
                textColor: widget.textColor,
              ),
              _CountdownSeparator(textColor: widget.textColor),
              _CountdownUnit(
                value: minutes,
                label: 'MIN',
                textColor: widget.textColor,
              ),
            ],
          ),
        ),

        if (widget.showEarlyAccessLink) ...[
          const SizedBox(height: 20),
          _EarlyAccessButton(
            onTap: widget.onEarlyAccessTap ?? () => _showEarlyAccessDialog(context),
            textColor: widget.textColor,
          ),
        ],
      ],
    );
  }

  void _showEarlyAccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Get Early Access'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Join our early access program to:'),
            SizedBox(height: 12),
            _BenefitRow(text: 'Be among the first to try new features'),
            _BenefitRow(text: 'Get exclusive early adopter badge'),
            _BenefitRow(text: 'Direct access to our team'),
            _BenefitRow(text: 'Shape the future of MixMingle'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToEarlyAccess(context);
            },
            child: const Text('Sign Up'),
          ),
        ],
      ),
    );
  }

  void _navigateToEarlyAccess(BuildContext context) {
    // Navigate to early access signup or show banner
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Early access signup coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _CountdownUnit extends StatelessWidget {
  final int value;
  final String label;
  final Color? textColor;

  const _CountdownUnit({
    required this.value,
    required this.label,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: textColor ?? Colors.white,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: (textColor ?? Colors.white).withValues(alpha: 0.7),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _CountdownSeparator extends StatelessWidget {
  final Color? textColor;

  const _CountdownSeparator({this.textColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        ':',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: (textColor ?? Colors.white).withValues(alpha: 0.5),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _EarlyAccessButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color? textColor;

  const _EarlyAccessButton({
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(
        Icons.flash_on,
        color: Colors.amber.shade300,
        size: 18,
      ),
      label: Text(
        'Get Early Access',
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: TextButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.15),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String text;

  const _BenefitRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

/// Compact countdown for app bar or small spaces
class CompactLaunchCountdown extends StatelessWidget {
  final DateTime? launchDate;
  final VoidCallback? onTap;

  const CompactLaunchCountdown({
    super.key,
    this.launchDate,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final targetDate = launchDate ?? now.add(const Duration(days: 30));
    final days = targetDate.difference(now).inDays;

    if (days <= 0) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade400, Colors.indigo.shade500],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.rocket_launch, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              '$days days',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating countdown banner for persistent display
class FloatingLaunchCountdown extends StatelessWidget {
  final DateTime? launchDate;
  final VoidCallback? onDismiss;
  final VoidCallback? onEarlyAccessTap;

  const FloatingLaunchCountdown({
    super.key,
    this.launchDate,
    this.onDismiss,
    this.onEarlyAccessTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final targetDate = launchDate ?? now.add(const Duration(days: 30));
    final days = targetDate.difference(now).inDays;

    if (days <= 0) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade500, Colors.indigo.shade600],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.rocket_launch, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Public launch in $days days!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: onEarlyAccessTap,
                    child: Text(
                      'Get early access â†’',
                      style: TextStyle(
                        color: Colors.amber.shade200,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (onDismiss != null)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                onPressed: onDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }
}

/// Helper to show days remaining
int showDaysRemaining(DateTime launchDate) {
  final now = DateTime.now();
  final difference = launchDate.difference(now);
  return difference.inDays;
}

/// Helper to format countdown string
String formatCountdown(DateTime launchDate) {
  final now = DateTime.now();
  final difference = launchDate.difference(now);

  if (difference.isNegative) {
    return 'Launched!';
  }

  final days = difference.inDays;
  final hours = difference.inHours % 24;
  final minutes = difference.inMinutes % 60;

  if (days > 0) {
    return '$days days, $hours hrs';
  } else if (hours > 0) {
    return '$hours hrs, $minutes min';
  } else {
    return '$minutes minutes';
  }
}
