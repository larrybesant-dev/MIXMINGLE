import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixmingle/shared/models/moderation_action.dart';
import 'package:mixmingle/services/moderation/auto_moderation_service.dart';
import 'package:mixmingle/shared/providers/providers.dart';

class ModActionsPanel extends ConsumerStatefulWidget {
  final String roomId;

  const ModActionsPanel({
    super.key,
    required this.roomId,
  });

  @override
  ConsumerState<ModActionsPanel> createState() => _ModActionsPanelState();
}

class _ModActionsPanelState extends ConsumerState<ModActionsPanel> {
  final _firestore = FirebaseFirestore.instance;
  final _autoModService = AutoModerationService();
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    _loadRoomState();
  }

  Future<void> _loadRoomState() async {
    final doc = await _firestore.collection('rooms').doc(widget.roomId).get();
    setState(() {
      _isLocked = doc.data()?['isLocked'] ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRoomControlSection(),
          const SizedBox(height: 24),
          _buildAutoModSection(),
          const SizedBox(height: 24),
          _buildQuickActionsSection(),
        ],
      ),
    );
  }

  Widget _buildRoomControlSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Room Controls',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Room Lockdown'),
              subtitle: Text(
                _isLocked
                    ? 'Room is locked - only moderators can join'
                    : 'Room is open to all users',
              ),
              value: _isLocked,
              onChanged: (value) => _toggleLockdown(value),
              secondary: Icon(
                _isLocked ? Icons.lock : Icons.lock_open,
                color: _isLocked ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoModSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Auto-Moderation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _autoModService.cleanupExpiredActions(widget.roomId),
              icon: const Icon(Icons.cleaning_services),
              label: const Text('Clean Up Expired Bans'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Auto-mod rules: Spam detection, banned words, repeated messages',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Ban Durations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildBanDurationChip('5 min', BanDuration.fiveMinutes),
                _buildBanDurationChip('1 hour', BanDuration.oneHour),
                _buildBanDurationChip('24 hours', BanDuration.twentyFourHours),
                _buildBanDurationChip('Permanent', BanDuration.permanent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanDurationChip(String label, BanDuration duration) {
    return Chip(
      label: Text(label),
      avatar: const Icon(Icons.timer, size: 16),
    );
  }

  Future<void> _toggleLockdown(bool locked) async {
    try {
      final roomService = ref.read(roomServiceProvider);
      if (locked) {
        await roomService.lockRoom(widget.roomId);
      } else {
        await roomService.unlockRoom(widget.roomId);
      }

      setState(() {
        _isLocked = locked;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locked ? 'Room locked' : 'Room unlocked'),
            backgroundColor: locked ? Colors.red : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle lockdown: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
