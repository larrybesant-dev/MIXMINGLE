import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/messaging/models/message_model.dart';
import '../features/messaging/providers/messaging_provider.dart';
import '../presentation/providers/user_provider.dart';

/// A compact, draggable floating DM panel intended for use while the user is
/// in a live room. Rendered via an Overlay so it floats above all other widgets.
///
/// Usage (inside a ConsumerState):
/// ```dart
/// FloatingWhisperPanel.show(
///   context, ref,
///   conversationId: id,
///   peerName: username,
/// );
/// ```
class FloatingWhisperPanel {
  static OverlayEntry? _entry;

  static void show(
    BuildContext context,
    WidgetRef ref, {
    required String conversationId,
    required String peerName,
    String? peerAvatarUrl,
  }) {
    // Dismiss any existing panel first.
    dismiss();
    _entry = OverlayEntry(
      builder: (_) => _FloatingWhisperPanelWidget(
        conversationId: conversationId,
        peerName: peerName,
        peerAvatarUrl: peerAvatarUrl,
        onClose: dismiss,
        callerRef: ref,
      ),
    );
    Overlay.of(context).insert(_entry!);
  }

  static void dismiss() {
    _entry?.remove();
    _entry = null;
  }
}

class _FloatingWhisperPanelWidget extends ConsumerStatefulWidget {
  const _FloatingWhisperPanelWidget({
    required this.conversationId,
    required this.peerName,
    this.peerAvatarUrl,
    required this.onClose,
    required this.callerRef,
  });

  final String conversationId;
  final String peerName;
  final String? peerAvatarUrl;
  final VoidCallback onClose;
  final WidgetRef callerRef;

  @override
  ConsumerState<_FloatingWhisperPanelWidget> createState() =>
      _FloatingWhisperPanelWidgetState();
}

class _FloatingWhisperPanelWidgetState
    extends ConsumerState<_FloatingWhisperPanelWidget> {
  Offset _position = const Offset(16, 120);
  bool _expanded = true;
  final TextEditingController _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    try {
      final currentUser = ref.read(userProvider);
      if (currentUser == null) return;
      await ref.read(messagingControllerProvider).sendMessage(
            conversationId: widget.conversationId,
            senderId: currentUser.id,
            senderName: currentUser.username,
            senderAvatarUrl: currentUser.avatarUrl,
            content: text,
          );
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[FloatingWhisperPanel] sendMessage failed: $e\n$stack');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    // Panel dimensions
    const panelWidth = 280.0;
    const panelExpandedHeight = 340.0;
    const panelCollapsedHeight = 44.0;

    return Positioned(
      left: _position.dx.clamp(0, screenSize.width - panelWidth),
      top: _position.dy.clamp(0, screenSize.height - (_expanded ? panelExpandedHeight : panelCollapsedHeight)),
      width: panelWidth,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header / drag handle
            GestureDetector(
              onPanUpdate: (details) {
                setState(() => _position += details.delta);
              },
              child: Container(
                height: 44,
                color: const Color(0xFF282C36),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    const Icon(Icons.drag_indicator, size: 18, color: Color(0xFFB09080)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.peerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF2EBE0),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _expanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_up,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _expanded = !_expanded),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: widget.onClose,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded) ...[
              // Message list
              SizedBox(
                height: 240,
                child: _MessageList(
                  conversationId: widget.conversationId,
                ),
              ),
              // Input row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                color: Theme.of(context).colorScheme.surface,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        decoration: const InputDecoration(
                          hintText: 'Message…',
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Lightweight message list inside the floating panel.
class _MessageList extends ConsumerWidget {
  const _MessageList({required this.conversationId});

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(messagesStreamProvider(conversationId));
    return messagesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFFF6E84), size: 28),
              const SizedBox(height: 8),
              const Text(
                'Could not load messages.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFB09080), fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(messagesStreamProvider(conversationId)),
                child: const Text('Retry', style: TextStyle(color: Color(0xFFD4A853))),
              ),
            ],
          ),
        ),
      ),
      data: (messages) {
        if (messages.isEmpty) {
          return const Center(
            child: Text('No messages yet.', style: TextStyle(color: Color(0xFFB09080))),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (ctx, i) {
            final msg = messages[messages.length - 1 - i];
            return _FloatingMessageBubble(message: msg);
          },
        );
      },
    );
  }
}

class _FloatingMessageBubble extends StatelessWidget {
  const _FloatingMessageBubble({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${message.senderName}: ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
            ),
            TextSpan(
              text: message.content,
              style: const TextStyle(fontSize: 12, color: Color(0xFFF2EBE0)),
            ),
          ],
        ),
      ),
    );
  }
}
