/// Tip Overlay Widget
///
/// Floating action button for quick tipping in video/voice rooms.
/// Provides a one-tap way to send gifts to the room host or participants.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../providers/providers.dart';
import '../../../shared/widgets/gift_selector.dart';

/// Floating tip overlay button for rooms
///
/// Place this in a Stack positioned at bottom-right of the room screen.
/// Usage:
/// ```dart
/// Stack(
///   children: [
///     // ... room content
///     TipOverlay(
///       receiverId: hostUserId,
///       receiverName: hostName,
///       roomId: roomId,
///     ),
///   ],
/// )
/// ```
class TipOverlay extends ConsumerStatefulWidget {
  final String receiverId;
  final String receiverName;
  final String roomId;
  final bool showLabel;
  final EdgeInsets position;

  const TipOverlay({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.roomId,
    this.showLabel = false,
    this.position = const EdgeInsets.only(bottom: 16, right: 16),
  });

  @override
  ConsumerState<TipOverlay> createState() => _TipOverlayState();
}

class _TipOverlayState extends ConsumerState<TipOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isExpanded = false;

  final List<Map<String, dynamic>> _quickGifts = [
    {'emoji': '🌹', 'amount': 5, 'name': 'Rose'},
    {'emoji': '❤️', 'amount': 10, 'name': 'Heart'},
    {'emoji': '💎', 'amount': 25, 'name': 'Diamond'},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: widget.position.bottom,
      right: widget.position.right,
      left: widget.position.left,
      top: widget.position.top,
      child: _isExpanded ? _buildExpandedMenu() : _buildFab(),
    );
  }

  Widget _buildFab() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () => setState(() => _isExpanded = true),
        onLongPress: _openFullGiftSelector,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [DesignColors.gold, DesignColors.secondary],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: DesignColors.gold.withValues(alpha: 0.5),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.monetization_on,
                  color: Colors.white,
                  size: 28,
                ),
                if (widget.showLabel) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Tip',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedMenu() {
    final userAsync = ref.watch(currentUserProvider);
    final coinBalance = userAsync.when(
      data: (user) => user?.coinBalance ?? 0,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Quick gift buttons
        ..._quickGifts.map((gift) => _buildQuickGiftButton(gift, coinBalance)),

        const SizedBox(height: 8),

        // More gifts button
        _buildMoreGiftsButton(),

        const SizedBox(height: 8),

        // Close button
        GestureDetector(
          onTap: () => setState(() => _isExpanded = false),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DesignColors.surfaceLight,
              shape: BoxShape.circle,
              border: Border.all(color: DesignColors.divider),
            ),
            child: const Icon(
              Icons.close,
              color: DesignColors.textGray,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickGiftButton(Map<String, dynamic> gift, int balance) {
    final amount = gift['amount'] as int;
    final canAfford = balance >= amount;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: canAfford ? () => _sendQuickTip(gift) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: canAfford
                ? DesignColors.surfaceLight
                : DesignColors.surfaceLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: canAfford
                  ? DesignColors.gold.withValues(alpha: 0.5)
                  : DesignColors.divider,
            ),
            boxShadow: canAfford
                ? [
                    BoxShadow(
                      color: DesignColors.gold.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                gift['emoji'] as String,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                '$amount',
                style: TextStyle(
                  color: canAfford
                      ? DesignColors.gold
                      : DesignColors.textGray,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.monetization_on,
                size: 14,
                color: canAfford
                    ? DesignColors.gold
                    : DesignColors.textGray,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreGiftsButton() {
    return GestureDetector(
      onTap: _openFullGiftSelector,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [DesignColors.accent, DesignColors.tertiary],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: DesignColors.accent.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.card_giftcard, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'More Gifts',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendQuickTip(Map<String, dynamic> gift) async {
    final amount = gift['amount'] as int;
    final name = gift['name'] as String;

    try {
      await ref.read(sendTipProvider({
        'receiverId': widget.receiverId,
        'receiverName': widget.receiverName,
        'amount': amount,
        'message': '',
        'roomId': widget.roomId,
      }).future);

      if (mounted) {
        setState(() => _isExpanded = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sent $name to ${widget.receiverName}!'),
            backgroundColor: DesignColors.gold,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send tip: ${e.toString()}'),
            backgroundColor: DesignColors.error,
          ),
        );
      }
    }
  }

  void _openFullGiftSelector() {
    setState(() => _isExpanded = false);
    showDialog(
      context: context,
      builder: (_) => GiftSelector(
        receiverId: widget.receiverId,
        receiverName: widget.receiverName,
        roomId: widget.roomId,
      ),
    );
  }
}

/// Compact version of TipOverlay for tighter spaces
class TipOverlayCompact extends StatelessWidget {
  final String receiverId;
  final String receiverName;
  final String roomId;

  const TipOverlayCompact({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => GiftSelector(
          receiverId: receiverId,
          receiverName: receiverName,
          roomId: roomId,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [DesignColors.gold, DesignColors.secondary],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: DesignColors.gold.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.monetization_on,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
