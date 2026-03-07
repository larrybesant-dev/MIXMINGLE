import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/gift.dart';
import '../../../shared/providers/gift_providers.dart';

/// Overlays floating gift emojis on top of the room page.
///
/// Add this to your room widget's `Stack` as the topmost child:
/// ```dart
/// GiftOverlayWidget(roomId: roomId)
/// ```
class GiftOverlayWidget extends ConsumerStatefulWidget {
  final String roomId;
  const GiftOverlayWidget({super.key, required this.roomId});

  @override
  ConsumerState<GiftOverlayWidget> createState() => _GiftOverlayWidgetState();
}

class _GiftOverlayWidgetState extends ConsumerState<GiftOverlayWidget> {
  final List<_FloatingGift> _active = [];
  String? _lastSeenGiftId;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<SentGift>>>(
      roomGiftsProvider(widget.roomId),
      (_, next) {
        final gifts = next.value;
        if (gifts == null || gifts.isEmpty) return;
        final latest = gifts.first;
        if (latest.id != _lastSeenGiftId) {
          _lastSeenGiftId = latest.id;
          _spawnGift(latest);
        }
      },
    );

    return IgnorePointer(
      child: Stack(
        children: _active
            .map((fg) => _FloatingGiftWidget(
                  key: ValueKey(fg.id),
                  gift: fg,
                  onDone: () {
                    if (mounted) {
                      setState(() => _active.remove(fg));
                    }
                  },
                ))
            .toList(),
      ),
    );
  }

  void _spawnGift(SentGift sent) {
    if (!mounted) return;
    setState(() {
      _active.add(_FloatingGift(
        id: sent.id,
        emoji: sent.giftEmoji,
        label: '${sent.senderName} sent ${sent.giftName}',
      ));
      // Keep at most 4 simultaneous overlays.
      if (_active.length > 4) _active.removeAt(0);
    });
  }
}

class _FloatingGift {
  final String id;
  final String emoji;
  final String label;
  _FloatingGift({required this.id, required this.emoji, required this.label});
}

class _FloatingGiftWidget extends StatefulWidget {
  final _FloatingGift gift;
  final VoidCallback onDone;

  const _FloatingGiftWidget({
    super.key,
    required this.gift,
    required this.onDone,
  });

  @override
  State<_FloatingGiftWidget> createState() => _FloatingGiftWidgetState();
}

class _FloatingGiftWidgetState extends State<_FloatingGiftWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500));
    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_ctrl);
    _slide = Tween(begin: 0.0, end: -120.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 120,
      left: 16,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _slide.value),
          child: Opacity(
            opacity: _opacity.value,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.purpleAccent.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.gift.emoji,
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text(
                    widget.gift.label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
