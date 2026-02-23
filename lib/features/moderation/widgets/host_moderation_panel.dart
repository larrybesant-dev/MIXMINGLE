import 'package:flutter/material.dart';
import '../services/host_moderation_service.dart';

class HostModerationPanel extends StatefulWidget {
  final String moderatorId;
  final String targetUserId;
  final String roomId;
  final VoidCallback? onActionComplete;

  const HostModerationPanel({
    super.key,
    required this.moderatorId,
    required this.targetUserId,
    required this.roomId,
    this.onActionComplete,
  });

  @override
  State<HostModerationPanel> createState() => _HostModerationPanelState();
}

class _HostModerationPanelState extends State<HostModerationPanel> {
  final HostModerationService _moderationService = HostModerationService();
  bool _isLoading = false;

  Future<void> _performAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() => _isLoading = true);

    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
        widget.onActionComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _kickUser() async {
    final confirmed = await _showConfirmDialog(
      'Kick User',
      'Are you sure you want to kick this user from the room?',
    );
    if (confirmed == true) {
      await _performAction(
        () => _moderationService.kickUser(
          moderatorId: widget.moderatorId,
          targetUserId: widget.targetUserId,
          roomId: widget.roomId,
        ),
        'User kicked from room',
      );
    }
  }

  Future<void> _muteUser() async {
    await _performAction(
      () => _moderationService.muteUser(
        moderatorId: widget.moderatorId,
        targetUserId: widget.targetUserId,
        roomId: widget.roomId,
      ),
      'User muted',
    );
  }

  Future<void> _spotlightOverride() async {
    await _performAction(
      () => _moderationService.spotlightOverride(
        moderatorId: widget.moderatorId,
        targetUserId: widget.targetUserId,
        roomId: widget.roomId,
      ),
      'Spotlight set to user',
    );
  }

  Future<void> _removeSpotlight() async {
    await _performAction(
      () => _moderationService.removeSpotlight(
        moderatorId: widget.moderatorId,
        targetUserId: widget.targetUserId,
        roomId: widget.roomId,
      ),
      'Spotlight removed',
    );
  }

  Future<void> _warnUser() async {
    final message = await _showWarnDialog();
    if (message != null) {
      await _performAction(
        () => _moderationService.warnUser(
          moderatorId: widget.moderatorId,
          targetUserId: widget.targetUserId,
          roomId: widget.roomId,
          message: message.isNotEmpty ? message : null,
        ),
        'Warning sent to user',
      );
    }
  }

  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showWarnDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Warn User'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter warning message (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Send Warning'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Host Moderation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ModerationButton(
                  icon: Icons.exit_to_app,
                  label: 'Kick',
                  color: Colors.red,
                  onPressed: _kickUser,
                ),
                _ModerationButton(
                  icon: Icons.mic_off,
                  label: 'Mute',
                  color: Colors.orange,
                  onPressed: _muteUser,
                ),
                _ModerationButton(
                  icon: Icons.star,
                  label: 'Spotlight',
                  color: Colors.amber,
                  onPressed: _spotlightOverride,
                ),
                _ModerationButton(
                  icon: Icons.star_outline,
                  label: 'Remove Spotlight',
                  color: Colors.grey,
                  onPressed: _removeSpotlight,
                ),
                _ModerationButton(
                  icon: Icons.warning_amber,
                  label: 'Warn',
                  color: Colors.deepOrange,
                  onPressed: _warnUser,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ModerationButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ModerationButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
