import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../shared/widgets/club_background.dart';
import '../../../shared/widgets/neon_components.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Permissions Request - Step 3 of onboarding
/// Requests Camera, Microphone, Notifications
class PermissionsRequestPage extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const PermissionsRequestPage({super.key, required this.onComplete});

  @override
  ConsumerState<PermissionsRequestPage> createState() =>
      _PermissionsRequestPageState();
}

class _PermissionsRequestPageState
    extends ConsumerState<PermissionsRequestPage> {
  bool _cameraGranted = false;
  bool _micGranted = false;
  bool _notificationsGranted = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final camera = await Permission.camera.status;
    final mic = await Permission.microphone.status;
    final notifications = await Permission.notification.status;

    setState(() {
      _cameraGranted = camera.isGranted;
      _micGranted = mic.isGranted;
      _notificationsGranted = notifications.isGranted;
    });
  }

  Future<void> _requestCamera() async {
    final status = await Permission.camera.request();
    setState(() => _cameraGranted = status.isGranted);
  }

  Future<void> _requestMicrophone() async {
    final status = await Permission.microphone.request();
    setState(() => _micGranted = status.isGranted);
  }

  Future<void> _requestNotifications() async {
    final status = await Permission.notification.request();
    setState(() => _notificationsGranted = status.isGranted);
  }

  Future<void> _savePermissionsToFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'permissions': {
          'camera': _cameraGranted,
          'microphone': _micGranted,
          'notifications': _notificationsGranted,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving permissions: $e');
    }
  }

  Future<void> _handleContinue() async {
    setState(() => _isLoading = true);

    try {
      // Save permission states to Firestore
      await _savePermissionsToFirestore();

      widget.onComplete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSkip() async {
    // Save denied permissions to Firestore
    await _savePermissionsToFirestore();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Permissions'),
          backgroundColor: DesignColors.accent,
          elevation: 0,
          actions: [
            TextButton(
              onPressed: _handleSkip,
              child: const Text(
                'Skip',
                style: TextStyle(color: DesignColors.white),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Title
                      NeonText(
                        'ENABLE FEATURES',
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        textColor: DesignColors.white,
                        glowColor: DesignColors.gold,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Allow access to unlock the full experience',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: DesignColors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Camera permission
                      NeonGlowCard(
                        glowColor: _cameraGranted
                            ? DesignColors.gold
                            : DesignColors.accent,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _cameraGranted
                                      ? Icons.videocam
                                      : Icons.videocam_off,
                                  size: 40,
                                  color: _cameraGranted
                                      ? DesignColors.gold
                                      : DesignColors.accent,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Camera',
                                        style: TextStyle(
                                          color: DesignColors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'For video rooms and speed dating',
                                        style: TextStyle(
                                          color: DesignColors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (!_cameraGranted) ...[
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _requestCamera,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: DesignColors.accent,
                                ),
                                child: const Text('Allow Access'),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Microphone permission
                      NeonGlowCard(
                        glowColor:
                            _micGranted ? DesignColors.gold : DesignColors.accent,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _micGranted ? Icons.mic : Icons.mic_off,
                                  size: 40,
                                  color: _micGranted
                                      ? DesignColors.gold
                                      : DesignColors.accent,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Microphone',
                                        style: TextStyle(
                                          color: DesignColors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Join live conversations',
                                        style: TextStyle(
                                          color: DesignColors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (!_micGranted) ...[
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _requestMicrophone,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: DesignColors.accent,
                                ),
                                child: const Text('Allow Access'),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Notifications permission
                      NeonGlowCard(
                        glowColor: _notificationsGranted
                            ? DesignColors.gold
                            : DesignColors.accent,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _notificationsGranted
                                      ? Icons.notifications_active
                                      : Icons.notifications_off,
                                  size: 40,
                                  color: _notificationsGranted
                                      ? DesignColors.gold
                                      : DesignColors.accent,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Notifications',
                                        style: TextStyle(
                                          color: DesignColors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Stay updated on matches and messages',
                                        style: TextStyle(
                                          color: DesignColors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (!_notificationsGranted) ...[
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _requestNotifications,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: DesignColors.accent,
                                ),
                                child: const Text('Allow Access'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Continue button
              Padding(
                padding: const EdgeInsets.all(24),
                child: NeonButton(
                  label: _isLoading ? 'SAVING...' : 'CONTINUE',
                  onPressed: _isLoading ? () {} : _handleContinue,
                  glowColor: DesignColors.gold,
                  isLoading: _isLoading,
                  height: 54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
