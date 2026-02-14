/// Permissions Screen
///
/// Fourth screen of the onboarding flow.
/// User grants permissions for camera, microphone, and notifications.
library;

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../core/theme/neon_colors.dart';
import '../models/onboarding_data.dart';
import '../widgets/neon_button.dart';
import '../widgets/spotlight_permission_card.dart';

class PermissionsScreen extends StatefulWidget {
  final OnboardingData data;
  final Function(OnboardingData) onUpdate;
  final VoidCallback? onContinue;
  final VoidCallback? onBack;

  const PermissionsScreen({
    super.key,
    required this.data,
    required this.onUpdate,
    this.onContinue,
    this.onBack,
  });

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _cameraGranted = false;
  bool _micGranted = false;
  bool _notificationGranted = false;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentPermissions();
    _cameraGranted = widget.data.cameraPermissionGranted;
    _micGranted = widget.data.micPermissionGranted;
    _notificationGranted = widget.data.notificationPermissionGranted;
  }

  Future<void> _checkCurrentPermissions() async {
    try {
      final cameraStatus = await Permission.camera.status;
      final micStatus = await Permission.microphone.status;
      final notifStatus = await Permission.notification.status;

      if (!mounted) return;
      setState(() {
        _cameraGranted = cameraStatus.isGranted;
        _micGranted = micStatus.isGranted;
        _notificationGranted = notifStatus.isGranted;
      });
      _updateData();
    } catch (e) {
      // Permissions might not be available on web
      debugPrint('Permission check failed: $e');
    }
  }

  void _updateData() {
    widget.onUpdate(widget.data.copyWith(
      cameraPermissionGranted: _cameraGranted,
      micPermissionGranted: _micGranted,
      notificationPermissionGranted: _notificationGranted,
    ));
  }

  Future<void> _requestPermission(Permission permission) async {
    if (_isRequesting) return;
    setState(() => _isRequesting = true);

    try {
      final status = await permission.request();

      if (!mounted) return;
      setState(() {
        switch (permission) {
          case Permission.camera:
            _cameraGranted = status.isGranted;
          case Permission.microphone:
            _micGranted = status.isGranted;
          case Permission.notification:
            _notificationGranted = status.isGranted;
          default:
            break;
        }
      });
      _updateData();

      if (status.isPermanentlyDenied && mounted) {
        _showSettingsDialog(permission);
      }
    } catch (e) {
      // Show error message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not request permission: $e'),
          backgroundColor: DesignColors.surfaceAlt,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  void _showSettingsDialog(Permission permission) {
    final permissionName = switch (permission) {
      Permission.camera => 'Camera',
      Permission.microphone => 'Microphone',
      Permission.notification => 'Notifications',
      _ => 'Permission',
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DesignColors.surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: NeonColors.neonOrange.withValues(alpha: 0.3)),
        ),
        title: Text(
          '$permissionName Blocked',
          style: TextStyle(color: DesignColors.white),
        ),
        content: Text(
          'Please enable $permissionName access in your device settings to use this feature.',
          style: TextStyle(color: DesignColors.textGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Later',
              style: TextStyle(color: DesignColors.textGray),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text(
              'Open Settings',
              style: TextStyle(color: NeonColors.neonOrange),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestAllPermissions() async {
    if (!_cameraGranted) {
      await _requestPermission(Permission.camera);
    }
    if (!_micGranted) {
      await _requestPermission(Permission.microphone);
    }
    if (!_notificationGranted) {
      await _requestPermission(Permission.notification);
    }
  }

  bool get _hasMinimumPermissions => _cameraGranted || _micGranted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildDescription(),
                    const SizedBox(height: 32),
                    _buildPermissionCards(),
                    const SizedBox(height: 24),
                    _buildOptionalNote(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Bottom Navigation
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: DesignColors.textGray,
            ),
            onPressed: widget.onBack,
          ),
          Expanded(
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [NeonColors.neonOrange, NeonColors.neonBlue],
                  ).createShader(bounds),
                  child: const Text(
                    'Go Live Ready',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Step 3 of 5',
                  style: TextStyle(
                    color: DesignColors.textGray.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: DesignColors.surfaceAlt.withValues(alpha: 0.5),
        border: Border.all(
          color: NeonColors.neonBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  NeonColors.neonOrange.withValues(alpha: 0.3),
                  NeonColors.neonBlue.withValues(alpha: 0.3),
                ],
              ),
            ),
            child: Icon(
              Icons.live_tv,
              color: NeonColors.neonOrange,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enable VIP Features',
                  style: TextStyle(
                    color: DesignColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Grant permissions to join live rooms, chat with others, and stay updated.',
                  style: TextStyle(
                    color: DesignColors.textGray.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCards() {
    return Column(
      children: [
        // Camera Permission
        SpotlightPermissionCard(
          icon: Icons.videocam_outlined,
          title: 'Camera',
          description: 'Go live and show your vibe',
          isGranted: _cameraGranted,
          onRequest: () => _requestPermission(Permission.camera),
        ),

        const SizedBox(height: 16),

        // Microphone Permission
        SpotlightPermissionCard(
          icon: Icons.mic_outlined,
          title: 'Microphone',
          description: 'Join voice chats and conversations',
          isGranted: _micGranted,
          onRequest: () => _requestPermission(Permission.microphone),
        ),

        const SizedBox(height: 16),

        // Notification Permission
        SpotlightPermissionCard(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          description: 'Know when your friends go live',
          isGranted: _notificationGranted,
          onRequest: () => _requestPermission(Permission.notification),
        ),
      ],
    );
  }

  Widget _buildOptionalNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: DesignColors.surfaceDark.withValues(alpha: 0.5),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: DesignColors.textGray.withValues(alpha: 0.6),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You can change permissions anytime in Settings',
              style: TextStyle(
                color: DesignColors.textGray.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            DesignColors.background.withValues(alpha: 0.0),
            DesignColors.background,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Enable All button
          if (!_hasMinimumPermissions)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextButton.icon(
                onPressed: _isRequesting ? null : _requestAllPermissions,
                icon: Icon(
                  Icons.touch_app,
                  color: NeonColors.neonOrange,
                  size: 18,
                ),
                label: Text(
                  'Enable All at Once',
                  style: TextStyle(
                    color: NeonColors.neonOrange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // Status indicator
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatusDot(_cameraGranted),
                const SizedBox(width: 8),
                _buildStatusDot(_micGranted),
                const SizedBox(width: 8),
                _buildStatusDot(_notificationGranted),
              ],
            ),
          ),

          OnboardingNeonButton(
            text: _hasMinimumPermissions ? 'Continue' : 'Skip for Now',
            onPressed: widget.onContinue,
            useGoldTrim: _hasMinimumPermissions,
            width: double.infinity,
            height: 56,
            icon: Icons.arrow_forward,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDot(bool isGranted) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isGranted
            ? DesignColors.gold
            : DesignColors.textGray.withValues(alpha: 0.3),
        boxShadow: isGranted
            ? [
                BoxShadow(
                  color: DesignColors.gold.withValues(alpha: 0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}
